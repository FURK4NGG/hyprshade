#!/bin/bash

STATE_FILE="$HOME/.config/scripts/hyprshade-toggle-state"
SHADER="night_screen"
ARG="${1:-}"
HOUR=$(date +%H)

mkdir -p "$(dirname "$STATE_FILE")" || exit 1
if [ ! -f "$STATE_FILE" ]; then
    printf '0\n' > "$STATE_FILE" || exit 1
    chmod 600 "$STATE_FILE"
fi

STATE=$(cat "$STATE_FILE")

apply_auto() {
    HOUR=$(date +%H)
    if [ "$HOUR" -ge 19 ] || [ "$HOUR" -lt 7 ]; then
        hyprshade on "$SHADER"
    else
        hyprshade off
    fi
}

# The systemd timer calls this with "time". It must apply the current
# mode without changing the saved mode or sending a toggle notification.
if [ "$ARG" = "time" ]; then
    case "$STATE" in
        0)
            apply_auto || exit 1
            echo "Night Screen called"
            ;;
        1)
            hyprshade off
            ;;
        2)
            hyprshade on "$SHADER"
            ;;
        *)
            echo "Invalid Night Screen state: $STATE" >&2
            exit 1
            ;;
    esac
    exit $?
fi

if [ -n "$ARG" ]; then
    case "$ARG" in
        exec-start)
            # Preserve the existing exec-start behavior as a mode cycle.
            case "$STATE" in
                1) NEXT=2 ;; # disabled -> always on
                2) NEXT=0 ;; # always on -> automatic
                0) NEXT=1 ;; # automatic -> disabled
                *) NEXT=1 ;;
            esac
            ;;
        -h|help|-help|--help)
            echo "Kullanim/Usage:"
            echo "  $0        -> Toggle Night Screen   (kapali/hep acik/otomatik) , (disabled/always on/automatic)"
            echo "  $0 time   -> Recall Auto Night Screen (execute once per hour)  !sadece otomatik moddayken calisir/works only in auto mode!"
            exit 0
            ;;
        *)
            echo "Kullanim/Usage:"
            echo "  $0        -> Toggle Night Screen   (kapali/hep acik/otomatik) , (disabled/always on/automatic)"
            echo "  $0 time   -> Recall Auto Night Screen (execute once per hour)  !sadece otomatik moddayken calisir/works only in auto mode!"
            exit 0
            ;;
    esac
else
    # Requested cycle: disabled -> always on -> automatic -> disabled.
    case "$STATE" in
        1) NEXT=2 ;;
        2) NEXT=0 ;;
        0) NEXT=1 ;;
        *) NEXT=1 ;;
    esac
fi

printf '%s\n' "$NEXT" > "$STATE_FILE" || exit 1

case "$NEXT" in
    0)
        # AUTOMATIC
        systemctl --user daemon-reload
        systemctl --user enable --now hyprshade-auto.timer
        if ! apply_auto; then
            exit 1
        fi
        notify-send "Night Screen" "auto mode is active"
        echo "Night Screen auto mode is active"
        ;;
    1)
        # DISABLED
        systemctl --user stop hyprshade-auto.timer || true
        hyprshade off || exit 1
        notify-send "Night Screen" "effect is deactive"
        echo "Night Screen effect is deactive"
        ;;
    2)
        # ALWAYS ON
        systemctl --user stop hyprshade-auto.timer || true
        hyprshade on "$SHADER" || exit 1
        notify-send "Night Screen" "effect is active"
        echo "Night Screen effect is active"
        ;;
esac
