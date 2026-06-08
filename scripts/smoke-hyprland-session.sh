#!/bin/sh
# Runs in GitHub Actions only. Starts a headless Weston compositor, nests
# Hyprland inside it, verifies IPC and a real client, then exits cleanly.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="/tmp/e-smoke-$$"
rm -rf "$WORK"
mkdir -p "$WORK"

# The installed greeter contract must still enter the compositor directly.
grep -q -- '--cmd Hyprland' "$ROOT/shared/includes/etc/greetd/config.toml"

export HOME="$WORK/h"
export XDG_RUNTIME_DIR="$WORK/r"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_DESKTOP=Hyprland
export WAYLAND_DISPLAY=edemint-ci
export AQ_NO_KMS_REQUIREMENT=1
export EDEMINT_SMOKE_MARKER="$WORK/client-started"
mkdir -p "$XDG_RUNTIME_DIR" "$XDG_CONFIG_HOME/hypr"
chmod 0700 "$XDG_RUNTIME_DIR"

WESTON_LOG="$WORK/weston.log"
LOG="$WORK/hyprland.log"
export LOG
weston --backend=headless-backend.so --socket="$WAYLAND_DISPLAY" --idle-time=0 >"$WESTON_LOG" 2>&1 &
weston_pid=$!
cleanup_outer() {
    kill "$weston_pid" 2>/dev/null || true
    wait "$weston_pid" 2>/dev/null || true
    rm -rf "$WORK"
}
trap cleanup_outer EXIT INT TERM

for _attempt in $(seq 1 30); do
    [ -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ] && break
    if ! kill -0 "$weston_pid" 2>/dev/null; then
        cat "$WESTON_LOG" >&2
        exit 1
    fi
    sleep 1
done
[ -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ] || {
    cat "$WESTON_LOG" >&2
    exit 1
}

cat > "$XDG_CONFIG_HOME/hypr/smoke.conf" <<'EOF'
monitor = ,preferred,auto,1
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
# for the isolated nested smoke environment; installed sessions do not use it.
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
for _attempt in $(seq 1 45); do
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
    fail "nested monitor was not registered" "$monitors_json"
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

echo "Hyprland nested headless login/session smoke test passed."
