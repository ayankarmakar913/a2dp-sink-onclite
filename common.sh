#!/system/bin/sh
# Shared helpers for A2DP Sink/Source switcher (Redmi Y3 / onclite).
#
# Exclusive modes:
#   source mode (default): normal Bluetooth output
#   sink mode            : phone receives A2DP audio
#
# Marker semantics:
#   /data/adb/a2dp_sink_redmiy3.disabled exists -> source mode
#   marker absent                               -> sink mode

SELF=$0
if command -v readlink >/dev/null 2>&1; then
    _resolved=$(readlink -f "$SELF" 2>/dev/null) && [ -n "$_resolved" ] && SELF=$_resolved
fi
MODDIR=${MODDIR:-$(dirname "$SELF")}
case "$MODDIR" in
    /*) ;;
    *) MODDIR=$(cd "$MODDIR" 2>/dev/null && pwd) || MODDIR=${0%/*} ;;
esac

LOG_FILE=${LOG_FILE:-/data/adb/a2dp_sink_redmiy3.log}
MODE_MARKER=/data/adb/a2dp_sink_redmiy3.disabled
PATH=/data/adb/ksu/bin:/data/adb/ap/bin:/data/adb/magisk:/debug_ramdisk:$PATH

ANDROID_SVC=/system/bin/svc
ANDROID_AM=/system/bin/am
ANDROID_CMD=/system/bin/cmd
ANDROID_DUMPSYS=/system/bin/dumpsys
ANDROID_GETPROP=/system/bin/getprop

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE" 2>/dev/null
}

resetprop_bin() {
    if command -v resetprop >/dev/null 2>&1; then
        command -v resetprop
        return 0
    fi
    for p in /data/adb/ksu/bin/resetprop /data/adb/ap/bin/resetprop \
             /data/adb/magisk/resetprop /debug_ramdisk/resetprop; do
        if [ -x "$p" ]; then
            echo "$p"
            return 0
        fi
    done
    return 1
}

set_prop() {
    "$_rp" "$1" "$2"
}

overlay_list() {
    "$ANDROID_CMD" overlay list --user 0 2>/dev/null
}

ensure_audio_focus_overlay() {
    [ -x "$ANDROID_CMD" ] || return 1
    _i=0
    while [ "$_i" -lt 5 ]; do
        overlay_list >/dev/null 2>&1 && break
        sleep 1
        _i=$((_i + 1))
    done
    if ! overlay_list | grep -q 'A2dpSinkFocus'; then
        _out=$("$ANDROID_CMD" overlay fabricate --target com.android.bluetooth \
            --name A2dpSinkFocus \
            com.android.bluetooth:bool/a2dp_sink_automatically_request_audio_focus \
            0x12 0xffffffff 2>&1)
        [ -n "$_out" ] && echo "$_out" >> "$LOG_FILE"
    fi
    _i=0
    while [ "$_i" -lt 5 ]; do
        "$ANDROID_CMD" overlay enable --user 0 com.android.shell:A2dpSinkFocus >> "$LOG_FILE" 2>&1 && break
        sleep 1
        _i=$((_i + 1))
    done
    _val=$("$ANDROID_CMD" overlay lookup --user 0 com.android.bluetooth \
        com.android.bluetooth:bool/a2dp_sink_automatically_request_audio_focus 2>/dev/null | tail -1)
    if [ "$_val" = "true" ]; then
        log "audio focus overlay enabled (value=true)"
        return 0
    fi
    log "WARNING: audio focus overlay lookup returned '$_val'"
    return 1
}

disable_audio_focus_overlay() {
    [ -x "$ANDROID_CMD" ] || return 1
    overlay_list | grep -q 'A2dpSinkFocus' || return 0
    "$ANDROID_CMD" overlay disable --user 0 com.android.shell:A2dpSinkFocus >> "$LOG_FILE" 2>&1 || true
    log "audio focus overlay disabled"
    return 0
}

set_sink_props() {
    _rp=$(resetprop_bin) || { log "ERROR: resetprop not found"; return 1; }
    set_prop bluetooth.profile.a2dp.source.enabled false
    set_prop bluetooth.profile.a2dp.sink.enabled true
    set_prop persist.bluetooth.a2dp.source.enabled false
    set_prop persist.bluetooth.a2dp.sink.enabled true
    set_prop bluetooth.profile.avrcp.target.enabled true
    set_prop bluetooth.profile.avrcp.controller.enabled false
    ensure_audio_focus_overlay || log "WARNING: audio focus overlay is not active"
    log "mode=sink props: source=$("$ANDROID_GETPROP" bluetooth.profile.a2dp.source.enabled) sink=$("$ANDROID_GETPROP" bluetooth.profile.a2dp.sink.enabled)"
    [ "$("$ANDROID_GETPROP" bluetooth.profile.a2dp.sink.enabled)" = "true" ] && \
        [ "$("$ANDROID_GETPROP" bluetooth.profile.a2dp.source.enabled)" = "false" ]
}

set_source_props() {
    _rp=$(resetprop_bin) || return 1
    set_prop bluetooth.profile.a2dp.source.enabled true
    set_prop bluetooth.profile.a2dp.sink.enabled false
    set_prop persist.bluetooth.a2dp.source.enabled true
    set_prop persist.bluetooth.a2dp.sink.enabled false
    set_prop bluetooth.profile.avrcp.target.enabled true
    set_prop bluetooth.profile.avrcp.controller.enabled false
    log "mode=source props: source=$("$ANDROID_GETPROP" bluetooth.profile.a2dp.source.enabled) sink=$("$ANDROID_GETPROP" bluetooth.profile.a2dp.sink.enabled)"
    [ "$("$ANDROID_GETPROP" bluetooth.profile.a2dp.source.enabled)" = "true" ] && \
        [ "$("$ANDROID_GETPROP" bluetooth.profile.a2dp.sink.enabled)" = "false" ]
}

bt_service_cmd() {
    _out=$("$ANDROID_SVC" bluetooth "$1" 2>&1)
    _rc=$?
    echo "$_out" >> "$LOG_FILE"
    [ "$_rc" -eq 0 ] && echo "$_out" | grep -q 'Success'
}

force_stop_bluetooth() {
    _out=$("$ANDROID_AM" force-stop com.android.bluetooth 2>&1)
    _rc=$?
    [ -n "$_out" ] && echo "$_out" >> "$LOG_FILE"
    return "$_rc"
}

sink_state_is() {
    "$ANDROID_DUMPSYS" bluetooth_manager 2>/dev/null | grep -qi "A2DP Sink State: $1"
}

current_mode() {
    if [ "$("$ANDROID_GETPROP" bluetooth.profile.a2dp.sink.enabled)" = "true" ]; then
        echo sink
    else
        echo source
    fi
}

restart_bluetooth() {
    _mode=${1:-sink}
    case "$_mode" in
        sink|enabled)    _mode=sink;   _expect=Enabled ;;
        source|disabled) _mode=source; _expect=Disabled ;;
        *) log "ERROR: restart_bluetooth: unknown mode $_mode"; return 1 ;;
    esac

    _attempt=1
    while [ "$_attempt" -le 2 ]; do
        log "restarting Bluetooth for $_mode mode (attempt $_attempt)"
        _ok=0; i=0
        while [ "$i" -lt 3 ]; do
            bt_service_cmd disable && { _ok=1; break; }
            sleep 1; i=$((i + 1))
        done
        [ "$_ok" -eq 1 ] || log "WARNING: could not disable Bluetooth cleanly"
        sleep 2
        i=0
        while [ "$i" -lt 3 ]; do
            force_stop_bluetooth && break
            sleep 1; i=$((i + 1))
        done
        sleep 1
        if [ "$_mode" = sink ]; then
            set_sink_props >/dev/null 2>&1 || log "WARNING: could not set sink props"
        else
            set_source_props >/dev/null 2>&1 || log "WARNING: could not set source props"
        fi
        _ok=0; i=0
        while [ "$i" -lt 3 ]; do
            bt_service_cmd enable && { _ok=1; break; }
            sleep 1; i=$((i + 1))
        done
        [ "$_ok" -eq 1 ] || log "WARNING: could not enable Bluetooth cleanly"
        if [ "$_mode" = sink ]; then
            set_sink_props >/dev/null 2>&1 || true
        else
            set_source_props >/dev/null 2>&1 || true
        fi
        i=0
        while [ "$i" -lt 30 ]; do
            if sink_state_is "$_expect"; then
                sleep 2
                if sink_state_is "$_expect"; then
                    log "A2DP Sink is $_expect"
                    return 0
                fi
            fi
            sleep 1; i=$((i + 1))
        done
        log "WARNING: A2DP Sink did not become $_expect (attempt $_attempt)"
        _attempt=$((_attempt + 1))
        sleep 2
    done
    return 1
}

show_status() {
    _mode=$(current_mode)
    echo "=== A2DP mode status (Redmi Y3) ==="
    if [ "$_mode" = "sink" ]; then
        echo "mode:                      SINK (phone receives audio)"
    else
        echo "mode:                      SOURCE (normal Bluetooth output)"
    fi
    echo "source property:           $("$ANDROID_GETPROP" bluetooth.profile.a2dp.source.enabled)"
    echo "sink property:             $("$ANDROID_GETPROP" bluetooth.profile.a2dp.sink.enabled)"
    echo "AVRCP target property:     $("$ANDROID_GETPROP" bluetooth.profile.avrcp.target.enabled)"
    echo "AVRCP controller property: $("$ANDROID_GETPROP" bluetooth.profile.avrcp.controller.enabled)"
    _peer=$("$ANDROID_DUMPSYS" bluetooth_manager 2>/dev/null |
        grep -A1 'A2DP Sink State: Enabled' | grep 'Active peer:' | head -1 | awk '{print $3}')
    case "$_peer" in ""|null|00:00:00:00:00:00) _peer=none ;; esac
    echo "sink active peer:          $_peer"
    echo
    "$ANDROID_DUMPSYS" bluetooth_manager 2>/dev/null | grep -E 'A2DP Source State|A2DP Sink State|SDP A2DP sink'
}
