#!/bin/bash

STATE_FILE="$HOME/.config/scripts/hyprshade-toggle-state"
SHADER="$HOME/.config/scripts/night_screen.frag"
HOUR=$(date +%H)
ARG="$1"

if [ ! -f "$STATE_FILE" ]; then
    echo 0 > "$STATE_FILE" || exit 1
    chmod 600 "$STATE_FILE"
fi

STATE=$(cat "$STATE_FILE")

if [ -n "$ARG" ]; then
    case "$ARG" in
      exec-start)
        case "$STATE" in
            0)STATE=2 ;;
            1)STATE=0 ;;
            2)STATE=1 ;;
        esac
        ;;
      -h|help|-help|--help|*)
        echo "Kullanim/Usage:"
        echo "  $0        -> Toggle Night Screen   (otomatik/kapali/hep acik) , (automatic/closed/always open)"
        echo "  $0 time   -> Recall Auto Night Screen (execute once per hour)  !sadece otomatik moddayken calisir/works only in auto mode!"
        exit 0
        ;;
    esac
fi

case "$STATE" in
    0)
        # DEFAULT (AUTO)
        systemctl --user daemon-reload
        systemctl --user enable --now hyprshade-auto.timer
        if [ "$HOUR" -ge 19 ] || [ "$HOUR" -lt 7 ]; then
            hyprshade on "$SHADER"
        else
            hyprshade off
        fi

        if [ "$ARG" = "time" ]; then
            echo 0 > "$STATE_FILE"
            echo "Night Screen called"
        else
            echo 1 > "$STATE_FILE"
            notify-send "Night Screen" "auto mode is active"
            echo "Night Screen auto mode is active"
        fi
        ;;
    1)
        # KAPALI
        systemctl --user stop hyprshade-auto.service
        systemctl --user disable hyprshade-auto.service
        systemctl --user stop hyprshade-auto.timer
        systemctl --user disable hyprshade-auto.timer
        hyprshade off
        echo 2 > "$STATE_FILE"
        notify-send "Night Screen" "effect is deactive"
        echo "Night Screen effect is deactive"
        ;;
    2)
        # HEP AÇIK
        systemctl --user stop hyprshade-auto.service
        systemctl --user disable hyprshade-auto.service
        systemctl --user stop hyprshade-auto.timer
        systemctl --user disable hyprshade-auto.timer
        hyprshade on "$SHADER"
        echo 0 > "$STATE_FILE"
        notify-send "Night Screen" "effect is active"
        echo "Night Screen effect is active"
        ;;
esac
