#!/system/bin/sh
# Best-effort cleanup: restore normal Bluetooth output and remove helpers.

MODDIR=${0%/*}
[ -f "$MODDIR/common.sh" ] || MODDIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
. "$MODDIR/common.sh" 2>/dev/null || true

disable_audio_focus_overlay 2>/dev/null || true
set_source_props 2>/dev/null || true
rm -f "$MODE_MARKER" /data/adb/a2dp-sink-y3 "$LOG_FILE" 2>/dev/null || true
log "uninstall: restored SOURCE mode and cleaned up" 2>/dev/null || true
