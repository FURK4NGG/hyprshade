#!/usr/bin/env bash
set -Eeuo pipefail

APP_NAME="Hyprshade Night Screen"
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_SRC="$PROJECT_DIR/hyprshade-auto.sh"
SCRIPT_DST="$HOME/.local/bin/hyprshade-auto.sh"
STATE_DIR="$HOME/.config/scripts"
STATE_FILE="$STATE_DIR/hyprshade-toggle-state"
USER_SYSTEMD_DIR="$HOME/.config/systemd/user"
SHADER_DIR="$HOME/.config/hypr/shaders"
SHADER_NAME="night_screen.frag"
SHADER_SRC=""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
RESET='\033[0m'

step() { printf "\n${BLUE}==>${RESET} %s\n" "$*"; }
ok()   { printf "${GREEN}[OK]${RESET} %s\n" "$*"; }
warn() { printf "${YELLOW}[WARNING]${RESET} %s\n" "$*"; }
err()  { printf "${RED}[ERROR]${RESET} %s\n" "$*" >&2; }
die()  { err "$*"; exit 1; }

trap 'rc=$?; err "Installation stopped unexpectedly (line: $LINENO, exit code: $rc)."; exit "$rc"' ERR

printf '%s\n' \
    '====================================' \
    "  $APP_NAME Installer" \
    '===================================='

step "Checking source files"

[[ -f "$SCRIPT_SRC" ]] ||
    die "hyprshade-auto.sh was not found in $PROJECT_DIR. Run this installer from the FURK4NGG/hyprshade repository directory."

command -v pacman >/dev/null 2>&1 ||
    die "pacman was not found. This installer is intended for Arch Linux."

ok "Found hyprshade-auto.sh in $PROJECT_DIR"

step "Installing required packages"

sudo pacman -S --needed python python-pip python-pipx curl unzip

ok "Required Arch Linux packages are installed."

step "Downloading and installing Hyprshade 4.0.1"

HYPRSHADE_URL="https://github.com/loqusion/hyprshade/archive/refs/tags/4.0.1.zip"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

curl -fL "$HYPRSHADE_URL" -o "$TMP_DIR/hyprshade-4.0.1.zip"

unzip -q "$TMP_DIR/hyprshade-4.0.1.zip" -d "$TMP_DIR"

HYPRSHADE_SOURCE="$TMP_DIR/hyprshade-4.0.1"

[[ -d "$HYPRSHADE_SOURCE" ]] ||
    die "The downloaded archive did not contain the expected hyprshade-4.0.1 directory."

[[ -f "$HYPRSHADE_SOURCE/pyproject.toml" ||
   -f "$HYPRSHADE_SOURCE/setup.py" ||
   -f "$HYPRSHADE_SOURCE/setup.cfg" ]] ||
    die "No Python package metadata was found in the downloaded Hyprshade archive."

export PATH="$HOME/.local/bin:$HOME/.local/pipx/bin:$PATH"

command -v pipx >/dev/null 2>&1 ||
    die "pipx was not found after installing python-pipx. Check the package installation."

pipx uninstall hyprshade >/dev/null 2>&1 || true

pipx install "$HYPRSHADE_SOURCE"

export PATH="$HOME/.local/bin:$HOME/.local/pipx/bin:$PATH"

if ! command -v hyprshade >/dev/null 2>&1; then
    warn "hyprshade was installed by pipx but is not currently on PATH. Trying pipx's default executable directory."
    export PATH="$(python -m site --user-base)/bin:$PATH"
fi

command -v hyprshade >/dev/null 2>&1 ||
    die "The hyprshade command is not available on PATH. Ensure ~/.local/bin is on PATH and open a new shell."

VERSION_OUTPUT="$(hyprshade --version 2>&1)"

printf '%s\n' "$VERSION_OUTPUT"

[[ "$VERSION_OUTPUT" == *"4.0.1"* ]] ||
    die "Expected Hyprshade 4.0.1, but got: $VERSION_OUTPUT"

ok "Hyprshade 4.0.1 is installed."

step "Installing the toggle script"

mkdir -p "$HOME/.local/bin" "$STATE_DIR" "$USER_SYSTEMD_DIR"

install -m 755 "$SCRIPT_SRC" "$SCRIPT_DST"

bash -n "$SCRIPT_DST"

ok "Installed and syntax-checked: $SCRIPT_DST"

step "Installing the shader file, if available"

if [[ -f "$PROJECT_DIR/$SHADER_NAME" ]]; then
    SHADER_SRC="$PROJECT_DIR/$SHADER_NAME"
elif [[ -f "$PROJECT_DIR/shaders/$SHADER_NAME" ]]; then
    SHADER_SRC="$PROJECT_DIR/shaders/$SHADER_NAME"
fi

if [[ -n "$SHADER_SRC" ]]; then
    mkdir -p "$SHADER_DIR"
    install -m 644 "$SHADER_SRC" "$SHADER_DIR/$SHADER_NAME"
    ok "Installed shader: $SHADER_DIR/$SHADER_NAME"
else
    warn "$SHADER_NAME was not found in the repository root or shaders/ directory; no shader file was copied."
fi

step "Installing systemd user service and timer"

SERVICE_SRC="$PROJECT_DIR/hyprshade-auto.service"
TIMER_SRC="$PROJECT_DIR/hyprshade-auto.timer"

if [[ -f "$SERVICE_SRC" ]]; then
    install -m 644 "$SERVICE_SRC" "$USER_SYSTEMD_DIR/hyprshade-auto.service"
else
    cat > "$USER_SYSTEMD_DIR/hyprshade-auto.service" <<'SERVICE'
[Unit]
Description=Hyprshade automatic mode check

[Service]
Type=oneshot
ExecStart=%h/.local/bin/hyprshade-auto.sh time
SERVICE

    chmod 644 "$USER_SYSTEMD_DIR/hyprshade-auto.service"
    ok "Created hyprshade-auto.service"
fi

if [[ -f "$TIMER_SRC" ]]; then
    install -m 644 "$TIMER_SRC" "$USER_SYSTEMD_DIR/hyprshade-auto.timer"
else
    cat > "$USER_SYSTEMD_DIR/hyprshade-auto.timer" <<'TIMER'
[Unit]
Description=Check Hyprshade mode every minute

[Timer]
OnBootSec=30s
OnUnitActiveSec=60s
AccuracySec=5s
Unit=hyprshade-auto.service

[Install]
WantedBy=timers.target
TIMER

    chmod 644 "$USER_SYSTEMD_DIR/hyprshade-auto.timer"
    ok "Created hyprshade-auto.timer"
fi

step "Checking the state file"

if [[ -f "$STATE_FILE" ]]; then
    chmod 600 "$STATE_FILE"
    ok "Preserved existing mode state: $STATE_FILE"
else
    ok "The mode state file will be created automatically when the toggle script runs."
fi

step "Enabling the timer"

systemctl --user daemon-reload
systemctl --user enable --now hyprshade-auto.timer

ok "hyprshade-auto.timer is enabled and running."

printf '\n====================================\n'
printf "${GREEN}Installation completed.${RESET}\n"
printf 'Hyprshade: %s\n' "$VERSION_OUTPUT"
printf 'Toggle script: %s\n' "$SCRIPT_DST"
printf 'State file (auto-generated): %s\n' "$STATE_FILE"
printf 'Timer status: systemctl --user status hyprshade-auto.timer\n'
printf 'To switch modes: %s\n' "$SCRIPT_DST"
printf '====================================\n'
