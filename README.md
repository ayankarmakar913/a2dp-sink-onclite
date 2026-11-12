# A2DP Sink/Source Switcher — Redmi 7/Y3 (onclite)

A Magisk/KernelSU/APatch module for **Redmi 7/Y3 (onclite)** that switches the phone between:
- **SOURCE mode** (normal): phone sends audio to Bluetooth headphones/speakers.
- **SINK mode** (receiver): phone receives A2DP audio from another device and plays it through the phone.

## BEFORE YOU FLASH — READ THIS

- **ONLY FOR:** **Redmi 7/Y3 (onclite)** running **crDroid 12 (Android 16)**. Do **NOT** flash this on other devices or different ROMs/Android versions unless you know exactly what you are doing and accept the risk.
- **Tested on:** **crDroidAndroid-16.0-20261108-onclite** (crDroid 12, Android 16), **Redmi 7/Y3 (onclite)**, rooted with **KernelSU**. Magisk/APatch-compatible layout.
- **ROM/BT stack specific:** relies on this ROM’s Bluetooth stack behavior (A2DP role properties, service handling). Other ROMs/builds may not work.
- **Root + runtime changes:** modifies Bluetooth profile properties, may enable an audio-focus overlay, and restarts the Bluetooth stack when switching modes.
- **Have recovery ready:** know how to disable/remove root modules if Bluetooth or boot behavior becomes problematic. Back up important data.

## ⚠️ WARNING — DO THIS AT YOUR OWN RISK

You are choosing to flash root-level code from the internet onto your device.
- **Do this at your own risk. Don’t blame me.**
- I am not responsible for bootloops, broken Bluetooth, lost pairings, bad audio, weird bugs, corrupted data, dead devices, thermonuclear incidents, alien invasions, timeline splits, or any other chaos.
- **If you somehow start a nuclear war because of an A2DP sink module, I don’t care — I will laugh at you.**
- You are the captain now. Only proceed if you understand what you’re doing.

## Install & control
1. Download the zip from [**Releases**](../../releases/latest) and install in **KernelSU/Magisk/APatch**. Reboot if required.
2. **WebUI** (if supported): module → **WebUI**.
   - **Toggle Source / Toggle Sink** (dynamic by current mode)
   - **Restart A2DP Sink** appears **only in SINK mode** (useful if reconnecting gets stuck)
   - *If your manager’s WebUI exec isn’t supported, the buttons may not run; use the Action button or commands below.*
3. **Action button** (if supported): toggles Source/Sink.
4. **Commands (root fallback):**
   ```sh
   su -c /data/adb/a2dp-sink-y3 status
   su -c /data/adb/a2dp-sink-y3 toggle     # Source <-> Sink
   su -c /data/adb/a2dp-sink-y3 on         # SINK (receiver)
   su -c /data/adb/a2dp-sink-y3 off        # SOURCE (normal output)
   su -c /data/adb/a2dp-sink-y3 restart    # restart Bluetooth in SINK mode
   su -c /data/adb/a2dp-sink-y3 diag [60]  # capture logs/state
   ```

**SINK mode:** connect a source device (phone/PC/TV) to **Redmi 7/Y3** and play audio. To switch to a different source device, disconnect the current device and connect the other one.

## No sound / troubleshooting
- **Quick fix:** toggle **Bluetooth OFF and ON** on both devices, then reconnect and play.
- **SINK mode (if a connection gets stuck):** open **WebUI** and tap **Restart A2DP Sink** (SINK mode), then reconnect. Fallback: `su -c /data/adb/a2dp-sink-y3 restart`.
- **Source-side issue:** **Forget & re-pair** the phone on the source device, reconnect for media audio, and check the source’s audio settings while connected.
- **Check state (while playing):**
  ```sh
  su -c '/data/adb/a2dp-sink-y3 status'
  su -c 'dumpsys bluetooth_manager 2>/dev/null | grep -E "A2DP (Source|Sink) State|Active peer|Connected|Streaming|State Machine" | head -15'
  ```
- **Diagnosis:** `su -c /data/adb/a2dp-sink-y3 diag 60` (capture while reproducing).

## Known limitations
- **Exclusive modes:** SOURCE and SINK are used separately (switch modes). Media audio only.
- **Device/ROM specific:** behavior may vary on different ROMs/builds.

## Uninstall / recovery
Disable/remove the module in your root manager and reboot. Or: `su -c /data/adb/a2dp-sink-y3 off`.

## Repo contents
- Module source (scripts, `webroot/`)
- `LICENSE` — MIT

## Disclaimer
Provided **as-is**, with **no warranty**. **Use at your own risk. Don’t blame me.** If international diplomacy collapses over a Bluetooth codec negotiation, I will still laugh at you.
