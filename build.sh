#!/bin/sh
# Build the flashable module zip.
set -eu
cd "$(dirname "$0")"

OUT=../A2DP-Sink-RedmiY3-v1.0.0.zip
rm -f "$OUT"

chmod 644 module.prop README.md LICENSE 2>/dev/null || true
chmod 755 ./*.sh 2>/dev/null || true

zip -9r "$OUT" \
    module.prop \
    customize.sh \
    post-fs-data.sh \
    service.sh \
    action.sh \
    uninstall.sh \
    common.sh \
    README.md \
    LICENSE \
    webroot

echo "Built: $(cd .. && pwd)/$(basename "$OUT")"
