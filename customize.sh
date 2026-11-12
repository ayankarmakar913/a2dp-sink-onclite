#!/system/bin/sh
# Installer hook: ensure scripts are executable and default to SOURCE mode.

MODDIR=${MODPATH:-${0%/*}}

chmod 755 "$MODDIR"/post-fs-data.sh 2>/dev/null
chmod 755 "$MODDIR"/service.sh 2>/dev/null
chmod 755 "$MODDIR"/action.sh 2>/dev/null
chmod 755 "$MODDIR"/uninstall.sh 2>/dev/null
chmod 755 "$MODDIR"/common.sh 2>/dev/null

# Start in normal (source) output mode after installation.
touch /data/adb/a2dp_sink_redmiy3.disabled 2>/dev/null || true
