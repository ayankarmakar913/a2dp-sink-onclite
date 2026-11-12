#!/system/bin/sh
# Action button / CLI helper for Redmi Y3 A2DP switcher.
# Usage: action.sh [toggle|on|off|status|diag [seconds]|restart] (default: toggle)

MODDIR=${0%/*}
[ -f "$MODDIR/common.sh" ] || MODDIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
. "$MODDIR/common.sh"

ACTION=${1:-toggle}

if [ "$ACTION" = "toggle" ]; then
    if [ "$(current_mode)" = "sink" ]; then
        ACTION=off
        echo "Currently in SINK mode; switching to normal output..."
    else
        ACTION=on
        echo "Currently in SOURCE mode; switching to receiver..."
    fi
fi

case "$ACTION" in
    status)
        show_status
        ;;
    off|source|normal)
        touch "$MODE_MARKER" 2>/dev/null || true
        echo "Switching to SOURCE (normal Bluetooth output) mode..."
        set_source_props || { echo "Could not set Bluetooth properties. Is root available?"; exit 1; }
        restart_bluetooth source || true
        echo
        show_status
        echo
        echo "Normal Bluetooth output restored. Sink disabled. Reconnect headphones/earbuds if needed."
        ;;
    on|sink|receiver)
        echo "Switching to SINK (receiver) mode..."
        set_sink_props || { echo "Could not set Bluetooth properties. Is root available?"; exit 1; }
        rm -f "$MODE_MARKER" 2>/dev/null || true
        restart_bluetooth sink || true
        echo
        show_status
        echo
        echo "Sink mode enabled. Bluetooth output (source) is disabled."
        echo "Pair/connect from the source device to Redmi Y3 and play audio."
        ;;
    diag|diagnose)
        DURATION=${2:-60}
        case "$DURATION" in ''|*[!0-9]*) DURATION=60 ;; esac
        [ "$DURATION" -lt 15 ] && DURATION=15
        [ "$DURATION" -gt 600 ] && DURATION=600
        OUT=/data/adb/a2dp_sink_redmiy3_diag_$(date '+%Y%m%d_%H%M%S').txt
        BASE=${OUT%.txt}
        echo "Capturing diagnostics for ${DURATION}s. Reproduce the issue now."
        {
            echo "=== mode snapshot $(date) ==="
            show_status
            echo
            echo "=== relevant properties ==="
            "$ANDROID_GETPROP" | grep -E 'bluetooth\.profile\.(a2dp|avrcp)|a2dp' | sort
        } > "$OUT" 2>&1
        /system/bin/logcat -d -v time > "${BASE}.before.logcat" 2>/dev/null
        /system/bin/logcat -c >/dev/null 2>&1 || true
        i=0
        while [ "$i" -lt "$DURATION" ]; do
            sleep 5; i=$((i + 5))
            {
                echo
                echo "=== t+${i}s $(date '+%H:%M:%S') ==="
                "$ANDROID_DUMPSYS" bluetooth_manager 2>/dev/null | grep -E 'A2DP Source State|A2DP Sink State|Active peer|Connected|Streaming|State Machine|Configured codec|SEP codec' | head -30
                echo "--- crash tail ---"
                /system/bin/logcat -b crash -d -v time 2>/dev/null | tail -5
            } >> "$OUT" 2>&1
        done
        /system/bin/logcat -d -v time > "${BASE}.logcat" 2>/dev/null
        "$ANDROID_DUMPSYS" bluetooth_manager > "${BASE}.bluetooth.txt" 2>&1
        "$ANDROID_DUMPSYS" audio > "${BASE}.audio.txt" 2>&1
        echo "Saved: $OUT ${BASE}.logcat ${BASE}.bluetooth.txt ${BASE}.audio.txt"
        echo
        show_status
        ;;
    restart|restart-sink)
        echo "Restarting A2DP sink (Bluetooth restart, SINK mode)..."
        set_sink_props || { echo "Could not set sink properties."; exit 1; }
        rm -f "$MODE_MARKER" 2>/dev/null || true
        restart_bluetooth sink || true
        echo
        show_status
        echo
        echo "Sink restarted. Reconnect the source device if needed."
        ;;
    *)
        echo "Usage: $0 [toggle|on|off|status|diag [seconds]|restart]"
        echo "  toggle  : switch between SOURCE and SINK mode"
        echo "  on/off  : SINK (receive audio) / SOURCE (normal output)"
        echo "  status  : show current mode"
        echo "  restart : restart Bluetooth in SINK mode"
        echo "  diag    : capture logs/state while reproducing an issue"
        exit 1
        ;;
esac
