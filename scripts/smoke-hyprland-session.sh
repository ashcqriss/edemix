#!/bin/sh
# Runs in GitHub Actions only. Starts Hyprland on a virtual KMS device,
# verifies IPC and a real Wayland client, then exits cleanly.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="/tmp/e-smoke-$$"
rm -rf "$WORK"
mkdir -p "$WORK"

# The installed greeter contract must still enter the compositor directly.
grep -q -- '--cmd Hyprland' "$ROOT/shared/includes/etc/greetd/config.toml"

DRM_DEVICE="${EDEMINT_DRM_DEVICE:-/dev/dri/card0}"
[ -c "$DRM_DEVICE" ] || {
    echo "Virtual DRM device is unavailable: $DRM_DEVICE" >&2
    exit 1
}

export HOME="$WORK/h"
export XDG_RUNTIME_DIR="$WORK/r"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_DESKTOP=Hyprland
export AQ_DRM_DEVICES="$DRM_DEVICE"
export AQ_NO_MODIFIERS=1
export AQ_MGPU_NO_EXPLICIT=1
export LIBGL_ALWAYS_SOFTWARE=1
export MESA_LOADER_DRIVER_OVERRIDE=kms_swrast
export GALLIUM_DRIVER=llvmpipe
export WLR_RENDERER_ALLOW_SOFTWARE=1
export HYPRLAND_NO_CRASHREPORTER=1
export SEATD_VTBOUND=0
export LIBSEAT_BACKEND=seatd
export SEATD_SOCK=/run/seatd.sock
export EDEMINT_SMOKE_MARKER="$WORK/client-started"
unset DISPLAY WAYLAND_DISPLAY
mkdir -p "$XDG_RUNTIME_DIR" "$XDG_CONFIG_HOME/hypr" /run
chmod 0700 "$XDG_RUNTIME_DIR"

SEATD_LOG="$WORK/seatd.log"
LOG="$WORK/hyprland.log"
export LOG
seatd -g video -l debug >"$SEATD_LOG" 2>&1 &
seatd_pid=$!
cleanup_outer() {
    kill "$seatd_pid" 2>/dev/null || true
    wait "$seatd_pid" 2>/dev/null || true
    rm -rf "$WORK"
}
trap cleanup_outer EXIT INT TERM

for _attempt in $(seq 1 20); do
    [ -S "$SEATD_SOCK" ] && break
    if ! kill -0 "$seatd_pid" 2>/dev/null; then
        cat "$SEATD_LOG" >&2
        exit 1
    fi
    sleep 1
done
[ -S "$SEATD_SOCK" ] || {
    cat "$SEATD_LOG" >&2
    exit 1
}

cat > "$XDG_CONFIG_HOME/hypr/smoke.conf" <<'EOF'
monitor = ,preferred,auto,1
debug {
    disable_logs = false
}
misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
}
animations {
    enabled = false
}
exec-once = foot --title=edemint-session-smoke sh -c "touch $EDEMINT_SMOKE_MARKER; sleep 15"
EOF

dbus-run-session -- sh -eu <<'EOF'
# The CI container runs as root. Hyprland requires this explicit opt-in only
# for the isolated virtual-KMS smoke environment; installed sessions do not.
Hyprland --config "$XDG_CONFIG_HOME/hypr/smoke.conf" --i-am-really-stupid >"$LOG" 2>&1 &
compositor=$!
cleanup() {
    kill "$compositor" 2>/dev/null || true
    wait "$compositor" 2>/dev/null || true
}
fail() {
    printf 'Hyprland smoke failure: %s\n' "$1" >&2
    if [ -n "${2:-}" ]; then
        printf '%s\n' "$2" >&2
    fi
    printf '%s\n' '--- compositor log ---' >&2
    cat "$LOG" >&2
    exit 1
}
trap cleanup EXIT INT TERM

signature=""
for _attempt in $(seq 1 60); do
    signature_dir="$(find "$XDG_RUNTIME_DIR/hypr" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -n 1 || true)"
    if [ -n "$signature_dir" ] && [ -S "$signature_dir/.socket.sock" ]; then
        signature="$(basename "$signature_dir")"
        break
    fi
    kill -0 "$compositor" 2>/dev/null || fail "compositor exited before IPC became available"
    sleep 1
done
[ -n "$signature" ] || fail "IPC instance signature did not become ready"
export HYPRLAND_INSTANCE_SIGNATURE="$signature"

if ! version_output="$(hyprctl version 2>&1)"; then
    fail "hyprctl version failed" "$version_output"
fi
[ -n "$version_output" ] || fail "hyprctl version returned no data"
printf 'Hyprland IPC version response:\n%s\n' "$version_output"

if ! monitors_json="$(hyprctl -j monitors 2>&1)"; then
    fail "monitor IPC query failed" "$monitors_json"
fi
if ! printf '%s\n' "$monitors_json" | jq -e 'type == "array" and length >= 1' >/dev/null; then
    fail "virtual monitor was not registered" "$monitors_json"
fi

for _attempt in $(seq 1 30); do
    [ -e "$EDEMINT_SMOKE_MARKER" ] && break
    kill -0 "$compositor" 2>/dev/null || fail "compositor exited before the client started"
    sleep 1
done
[ -e "$EDEMINT_SMOKE_MARKER" ] || fail "Wayland client did not execute its startup command"

if ! clients_json="$(hyprctl -j clients 2>&1)"; then
    fail "client IPC query failed" "$clients_json"
fi
if ! printf '%s\n' "$clients_json" | jq -e \
    'type == "array" and any(.[]; (.title // "") == "edemint-session-smoke" or (.class // "") == "foot")' \
    >/dev/null; then
    fail "the launched Foot client was not visible through IPC" "$clients_json"
fi

hyprctl dispatch exit >/dev/null
wait "$compositor"
trap - EXIT INT TERM
EOF

echo "Hyprland virtual-KMS login/session smoke test passed."
