#!/system/bin/sh
# Late boot: re-assert saved mode and create CLI shortcut. No BT restart at boot.

MODDIR=${0%/*}
[ -f "$MODDIR/common.sh" ] || MODDIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
. "$MODDIR/common.sh"

i=0
while [ "$("$ANDROID_GETPROP" sys.boot_completed)" != "1" ] && [ "$i" -lt 120 ]; do
    sleep 1
    i=$((i + 1))
done
log "service: boot_completed=$("$ANDROID_GETPROP" sys.boot_completed)"

if [ -f "$MODE_MARKER" ]; then
    log "service: SOURCE mode"
    set_source_props || true
else
    log "service: SINK mode"
    set_sink_props || true
fi

rm -f /data/adb/a2dp-sink-y3 2>/dev/null || true
{
    echo '#!/system/bin/sh'
    echo "exec sh \"$MODDIR/action.sh\" \"\$@\""
} > /data/adb/a2dp-sink-y3 2>/dev/null && chmod 755 /data/adb/a2dp-sink-y3 2>/dev/null || true

show_status >> "$LOG_FILE" 2>&1
