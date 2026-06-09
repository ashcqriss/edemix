#!/bin/sh
# Runs in GitHub Actions only. Starts a software-rendered Weston parent,
# verifies a real nested Hyprland session, IPC, Wayland client, and clean exit.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="/tmp/e-smoke-$$"
rm -rf "$WORK"
mkdir -p "$WORK"

grep -q -- '--cmd Hyprland' "$ROOT/shared/includes/etc/greetd/config.toml"

export HOME="$WORK/h"
export XDG_RUNTIME_DIR="$WORK/r"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_DESKTOP=Hyprland
export AQ_NO_MODIFIERS=1
export AQ_MGPU_NO_EXPLICIT=1
export AQ_TRACE=1
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe
export WLR_RENDERER_ALLOW_SOFTWARE=1
export HYPRLAND_NO_CRASHREPORTER=1
export EDEMINT_SMOKE_MARKER="$WORK/client-started"
unset DISPLAY
mkdir -p "$XDG_RUNTIME_DIR" "$XDG_CONFIG_HOME/hypr"
chmod 0700 "$XDG_RUNTIME_DIR"

WESTON_LOG="$WORK/weston.log"
LOG="$WORK/hyprland.log"
export LOG
weston -B headless --renderer=pixman --socket=wayland-parent --idle-time=0 --no-config >"$WESTON_LOG" 2>&1 &
weston_pid=$!
cleanup_outer() {
    kill "$weston_pid" 2>/dev/null || true
    wait "$weston_pid" 2>/dev/null || true
    rm -rf "$WORK"
}
trap cleanup_outer EXIT INT TERM

for _attempt in $(seq 1 20); do
    [ -S "$XDG_RUNTIME_DIR/wayland-parent" ] && break
    if ! kill -0 "$weston_pid" 2>/dev/null; then
        cat "$WESTON_LOG" >&2
        exit 1
    fi
    sleep 1
done
[ -S "$XDG_RUNTIME_DIR/wayland-parent" ] || {
    cat "$WESTON_LOG" >&2
    exit 1
}
export WAYLAND_DISPLAY=wayland-parent

cat > "$XDG_CONFIG_HOME/hypr/smoke.conf" <<'EOF'
monitor = ,preferred,auto,1
debug {
    disable_logs = false
    disable_stdout_logs = false
}
misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
    disable_hyprland_guiutils_check = true
}
animations {
    enabled = false
}
exec-once = foot --title=edemint-session-smoke sh -c "touch $EDEMINT_SMOKE_MARKER; sleep 15"
EOF

dbus-run-session -- sh -eu <<'EOF'
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
    printf '%s\n' '--- compositor stdout/stderr ---' >&2
    cat "$LOG" >&2
    for runtime_log in "$XDG_RUNTIME_DIR"/hypr/*/hyprland.log; do
        [ -r "$runtime_log" ] || continue
        printf '%s\n' "--- runtime log: $runtime_log ---" >&2
        cat "$runtime_log" >&2
    done
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
