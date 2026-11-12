#!/system/bin/sh
# Before Bluetooth starts: set profile props for the saved mode.

MODDIR=${0%/*}
[ -f "$MODDIR/common.sh" ] || MODDIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
. "$MODDIR/common.sh"

if [ -f "$MODE_MARKER" ]; then
    log "post-fs-data: SOURCE mode"
    set_source_props || true
else
    log "post-fs-data: SINK mode"
    set_sink_props || true
fi
