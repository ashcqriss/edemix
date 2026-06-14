#!/bin/sh
# Validates the shipped login wiring and Hyprland configuration without starting
# a graphical session. The full compositor/client smoke remains hardware-gated.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HYPR_SOURCE="$ROOT/shared/includes/etc/skel/.config/hypr"
GREETER_CONFIG="$ROOT/shared/includes/etc/greetd/config.toml"
DESKTOP_PACKAGES="$ROOT/shared/package-lists/desktop.list.chroot"
REQUIRED_PACKAGES="$ROOT/shared/includes/usr/share/edemint/required-desktop.packages"
WORK="/tmp/e-hypr-contract-$$"

cleanup() {
    rm -rf "$WORK"
}
trap cleanup EXIT INT TERM

for required in \
    "$HYPR_SOURCE/hyprland.conf" \
    "$HYPR_SOURCE/profile.conf" \
    "$HYPR_SOURCE/effects.conf" \
    "$HYPR_SOURCE/glass.conf" \
    "$HYPR_SOURCE/edemint-settings.conf" \
    "$GREETER_CONFIG" \
    "$DESKTOP_PACKAGES" \
    "$REQUIRED_PACKAGES"; do
    [ -r "$required" ] || {
        echo "Required Hyprland session file is missing: $required" >&2
        exit 1
    }
done

grep -Eq 'tuigreet .*--cmd Hyprland' "$GREETER_CONFIG"
grep -Eq 'agreety --cmd Hyprland' "$GREETER_CONFIG"
grep -Eq '^greetd([[:space:]]|$)' "$DESKTOP_PACKAGES"
grep -Eq '^hyprland[[:space:]]+trixie-backports([[:space:]]|$)' "$REQUIRED_PACKAGES"

export HOME="$WORK/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_RUNTIME_DIR="$WORK/runtime"
mkdir -p "$XDG_CONFIG_HOME/hypr" "$XDG_RUNTIME_DIR"
chmod 0700 "$XDG_RUNTIME_DIR"
cp -R "$HYPR_SOURCE/." "$XDG_CONFIG_HOME/hypr/"

Hyprland --version
if ! verification="$(Hyprland --verify-config \
    --config "$XDG_CONFIG_HOME/hypr/hyprland.conf" \
    --i-am-really-stupid 2>&1)"; then
    printf '%s\n' 'Hyprland rejected the shipped Edemint configuration:' >&2
    printf '%s\n' "$verification" >&2
    exit 1
fi
printf '%s\n' "$verification"

# Also prove the "Full" frosted/liquid-glass profile parses. edemint-setup
# enables it by repointing effects.conf at glass.conf; verify that composed
# config too, so a bad blur/animation/layerrule keyword fails CI rather than a
# user's first "Full" login.
cat > "$XDG_CONFIG_HOME/hypr/effects.conf" <<'EOF'
source = ~/.config/hypr/glass.conf
EOF
if ! glass_verification="$(Hyprland --verify-config \
    --config "$XDG_CONFIG_HOME/hypr/hyprland.conf" \
    --i-am-really-stupid 2>&1)"; then
    printf '%s\n' 'Hyprland rejected the Edemint glass effect profile:' >&2
    printf '%s\n' "$glass_verification" >&2
    exit 1
fi
printf '%s\n' "$glass_verification"
printf '%s\n' 'Hyprland configuration, glass profile, and login contract passed.'
