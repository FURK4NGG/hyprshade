#!/usr/bin/env bash
set -Eeuo pipefail

STATE_DIR="$HOME/.config/scripts"
STATE_FILE="$STATE_DIR/hyprshade-toggle-state"
BACKEND_FILE="$STATE_DIR/hyprshade-toggle-backend"

OVERLAY="$HOME/.local/bin/night-screen-overlay.py"
SHADER="night_screen"
ARG="${1:-}"

mkdir -p "$STATE_DIR"

# Default mode: automatic
if [[ ! -f "$STATE_FILE" ]]; then
    printf '0\n' > "$STATE_FILE"
fi

# Default backend: native Hyprshade
if [[ ! -f "$BACKEND_FILE" ]]; then
    printf 'native\n' > "$BACKEND_FILE"
fi

get_state() {
    cat "$STATE_FILE"
}

get_backend() {
    cat "$BACKEND_FILE"
}

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Night Screen" "$1" || true
    fi
}

apply_filter() {
    case "$(get_backend)" in
        native)
            command -v hyprshade >/dev/null 2>&1 || {
                echo "[ERROR] The hyprshade command was not found." >&2
                return 1
            }

            hyprshade on "$SHADER"
            ;;

        overlay)
            [[ -f "$OVERLAY" ]] || {
                echo "[ERROR] Overlay script was not found: $OVERLAY" >&2
                return 1
            }

            python3 "$OVERLAY" start
            ;;

        *)
            echo "[ERROR] Invalid backend: $(get_backend)" >&2
            return 1
            ;;
    esac
}

disable_filter() {
    case "$(get_backend)" in
        native)
            hyprshade off
            ;;

        overlay)
            [[ -f "$OVERLAY" ]] || {
                echo "[ERROR] Overlay script was not found: $OVERLAY" >&2
                return 1
            }

            python3 "$OVERLAY" stop
            ;;

        *)
            echo "[ERROR] Invalid backend: $(get_backend)" >&2
            return 1
            ;;
    esac
}

apply_auto() {
    local hour
    hour="$(date +%H)"
    hour=$((10#$hour))

    if (( hour >= 19 || hour < 7 )); then
        apply_filter
    else
        disable_filter
    fi
}

apply_current_state() {
    case "$(get_state)" in
        0)
            apply_auto
            ;;
        1)
            disable_filter
            ;;
        2)
            apply_filter
            ;;
        *)
            echo "[ERROR] Invalid mode: $(get_state)" >&2
            return 1
            ;;
    esac
}

# Check the mode without cycling it.
if [[ "$ARG" == "time" ]]; then
    apply_current_state
    exit $?
fi

# Select the rendering backend.
if [[ "$ARG" == "backend" ]]; then
    case "${2:-}" in
        native)
            printf 'native\n' > "$BACKEND_FILE"
            ;;
        overlay)
            [[ -f "$OVERLAY" ]] || {
                echo "[ERROR] Overlay script was not found: $OVERLAY" >&2
                exit 1
            }
            printf 'overlay\n' > "$BACKEND_FILE"
            ;;
        *)
            echo "Usage: $0 backend {native|overlay}" >&2
            exit 2
            ;;
    esac

    apply_current_state
    notify "Backend: $(get_backend)"
    exit $?
fi

# Cycle: automatic (0) -> disabled (1) -> always on (2).
case "$(get_state)" in
    0) NEXT=1 ;;
    1) NEXT=2 ;;
    2) NEXT=0 ;;
    *) NEXT=1 ;;
esac

printf '%s\n' "$NEXT" > "$STATE_FILE"

case "$NEXT" in
    0)
        apply_auto
        notify "Automatic mode enabled"
        ;;
    1)
        disable_filter
        notify "Filter disabled"
        ;;
    2)
        apply_filter
        notify "Filter always enabled"
        ;;
esac
