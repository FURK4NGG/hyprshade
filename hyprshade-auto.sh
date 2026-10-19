#!/bin/bash

STATE_FILE="$HOME/.config/scripts/hyprshade-toggle-state"
OVERLAY="$HOME/.local/bin/night-screen-overlay.py"
ARG="${1:-}"

export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"

mkdir -p "$(dirname "$STATE_FILE")"

if [ ! -f "$STATE_FILE" ]; then
    printf '0\n' > "$STATE_FILE"
fi

STATE=$(cat "$STATE_FILE")

apply_filter() {
    python3 "$OVERLAY" start
}

disable_filter() {
    python3 "$OVERLAY" stop
}

apply_auto() {
    HOUR=$(date +%H)

    if [ "$HOUR" -ge 19 ] || [ "$HOUR" -lt 7 ]; then
        apply_filter
    else
        disable_filter
    fi
}

if [ "$ARG" = "time" ]; then
    case "$STATE" in
        0) apply_auto ;;
        1) disable_filter ;;
        2) apply_filter ;;
        *)
            echo "Invalid state: $STATE" >&2
            exit 1
            ;;
    esac
    exit $?
fi

case "$STATE" in
    0) NEXT=1 ;;
    1) NEXT=2 ;;
    2) NEXT=0 ;;
    *) NEXT=1 ;;
esac

printf '%s\n' "$NEXT" > "$STATE_FILE"

case "$NEXT" in
    0)
        apply_auto || exit 1
        notify-send "Night Screen" "Automatic mode enabled"
        ;;
    1)
        disable_filter || exit 1
        notify-send "Night Screen" "Filter disabled"
        ;;
    2)
        apply_filter || exit 1
        notify-send "Night Screen" "Filter always enabled"
        ;;
esac
