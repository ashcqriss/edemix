#!/bin/sh
# Runs in GitHub Actions only. Starts Hyprland with a headless wlroots backend,
# verifies IPC and a real Wayland client, then exits the compositor cleanly.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT INT TERM

# The installed greeter contract must still enter the compositor directly.
grep -q -- '--cmd Hyprland' "$ROOT/shared/includes/etc/greetd/config.toml"

export HOME="$WORK/home"
export XDG_RUNTIME_DIR="$WORK/runtime"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=Hyprland
export WLR_BACKENDS=headless
export WLR_RENDERER=pixman
export WLR_LIBINPUT_NO_DEVICES=1
export EDEMINT_SMOKE_MARKER="$WORK/client-started"
mkdir -p "$XDG_RUNTIME_DIR" "$XDG_CONFIG_HOME/hypr"
chmod 0700 "$XDG_RUNTIME_DIR"

cat > "$XDG_CONFIG_HOME/hypr/smoke.conf" <<'EOF'
monitor = HEADLESS-1,1280x720@60,0x0,1
misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
}
animations {
    enabled = false
}
exec-once = foot --title=edemint-session-smoke sh -c "touch $EDEMINT_SMOKE_MARKER; sleep 15"
EOF

LOG="$WORK/hyprland.log"
export LOG

dbus-run-session -- sh -eu <<'EOF'
# The CI container runs as root. Hyprland requires this explicit opt-in only
# for the isolated headless smoke environment; installed sessions do not use it.
Hyprland --config "$XDG_CONFIG_HOME/hypr/smoke.conf" --i-am-really-stupid >"$LOG" 2>&1 &
compositor=$!
cleanup() {
    kill "$compositor" 2>/dev/null || true
    wait "$compositor" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

signature=""
for _attempt in $(seq 1 45); do
    signature_dir="$(find "$XDG_RUNTIME_DIR/hypr" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -n 1 || true)"
    if [ -n "$signature_dir" ]; then
        signature="$(basename "$signature_dir")"
        break
    fi
    if ! kill -0 "$compositor" 2>/dev/null; then
        cat "$LOG" >&2
        exit 1
    fi
    sleep 1
done
[ -n "$signature" ] || { cat "$LOG" >&2; exit 1; }
export HYPRLAND_INSTANCE_SIGNATURE="$signature"

hyprctl -j version | jq -e '.hash != null or .tag != null' >/dev/null
hyprctl -j monitors | jq -e 'length >= 1' >/dev/null

for _attempt in $(seq 1 30); do
    [ -e "$EDEMINT_SMOKE_MARKER" ] && break
    sleep 1
done
[ -e "$EDEMINT_SMOKE_MARKER" ] || { cat "$LOG" >&2; exit 1; }
hyprctl -j clients | jq -e 'any(.[]; .title == "edemint-session-smoke")' >/dev/null

hyprctl dispatch exit >/dev/null
wait "$compositor"
trap - EXIT INT TERM
EOF

echo "Hyprland headless login/session smoke test passed."
