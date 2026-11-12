# A2DP Sink/Source Switcher — Redmi Y3 (onclite)

A Magisk/KernelSU/APatch module for **Redmi Y3 (onclite)** to switch between:
- **SOURCE mode** (normal): phone sends audio to Bluetooth headphones/speakers.
- **SINK mode** (receiver): phone receives A2DP audio from another device and plays it through the phone.

**Device/ROM specific. Use at your own risk.**

## Compatibility
- **Only supported/tested on:** **crDroid 12 (Android 16)** for **Redmi Y3 (onclite)**.
- **Tested build:** `crDroidAndroid-16.0-20261108-onclite`.
- Other ROMs, Android versions, kernels, or builds may not work as expected.

## Notes
- **Root required.** The module changes Bluetooth profile properties, may enable an audio-focus overlay, and restarts the Bluetooth stack when switching modes.
- **Exclusive modes:** the phone runs as A2DP source *or* sink (not both at the same time).

## Install & control
1. Flash the module zip in **KernelSU / Magisk / APatch** and reboot if required.
2. **WebUI** (if supported by your manager): **Toggle Source / Toggle Sink** (dynamic) and **Restart A2DP Sink** (shown in SINK mode).
3. **Module Action button** (if available): toggles Source/Sink.
4. **CLI (root):**
   ```sh
   su -c /data/adb/a2dp-sink-y3 status
   su -c /data/adb/a2dp-sink-y3 toggle
   su -c /data/adb/a2dp-sink-y3 on      # SINK (receiver)
   su -c /data/adb/a2dp-sink-y3 off     # SOURCE (normal output)
   su -c /data/adb/a2dp-sink-y3 restart # restart Bluetooth in SINK mode
   su -c /data/adb/a2dp-sink-y3 diag [60]
   ```

## Usage tips
- **Switching modes** restarts Bluetooth; reconnect devices as needed.
- **SINK mode:** pair/connect from the source device to **Redmi Y3**, select it for media output, and play audio.
- If there is **no sound in SINK mode**, try **Restart A2DP Sink** (WebUI/CLI) or toggle Bluetooth off/on on both devices, then reconnect.
- Collect diagnostics with `su -c /data/adb/a2dp-sink-y3 diag 60` while reproducing an issue.

## Uninstall / recovery
Disable or remove the module in your root manager and reboot. Best-effort cleanup restores normal (SOURCE) behavior and removes the helper command.

## Disclaimer
Provided **as is**, without warranty. Modifying Bluetooth/system behavior can cause issues on some ROMs — back up important data and know how to disable modules in recovery if needed.
