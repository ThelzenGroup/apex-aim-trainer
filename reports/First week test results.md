# First-week test results

Results from the test PC, from the logs sent back on 7–8 October 2026. These are the checks from `TESTING.md` and the engine report. `tools/analyze_logs.py` produces the numbers below from the CSV logs.

## Test PC

| | |
|---|---|
| CPU / GPU | AMD Ryzen 5 5600X (12 threads) / AMD Radeon RX 6800 |
| OS | Windows 11 (build 26200) |
| Display | 3840×1080 (32:9) at 240 Hz, exclusive fullscreen |
| Mouse | about 1,000 Hz (980 events/s while moving), 1600 DPI |
| Apex settings | sensitivity 0.7; `cl_fovScale` 1.47732 (imported) |

## Status

| # | Test | Status | Evidence |
|---|---|---|---|
| 1 | Toolchain and bot import | ✅ Pass | Runs in CI on every push |
| 2 | Launch | ✅ Pass | Direct3D 12 and Vulkan both ran; GPU and 240 Hz detected; no errors in the Godot logs |
| 3 | Sensitivity exactness | ⏳ Needs ruler numbers | The build predicts 37.11 cm per 360°. Needs the measured distance in the build and in Apex. The logs show two long sweeps (~765° and ~720°), not separate 360° measurements. |
| 4 | Mouse polling stress | ✅ Pass at 1 kHz | Mouse lab: 952 FPS average, 1% low 586, worst frame 2.5 ms, no stalls. 2–8 kHz not tested (the mouse appears to be 1 kHz). |
| 5 | Click-to-photon latency | ⏳ Needs slow-motion video | Frame caps behave: locked 240 FPS (std dev 0.21 ms) and the VRR cap at 224 FPS (std dev 0.08 ms) |
| 6 | Bot and projectile load | ✅ Pass after a fix | First run: 365 FPS average, 1% low 203. After the fix: 573 average, 1% low 259 (target 240). The worst frame was 6.2 ms in both runs. |
| 7 | Controllers | ⏳ Not run | |

## What the first run changed

Test 6 first missed its target because 30 animated bots cost about 2 ms per frame. Bullets weren't the cause: frames with a physics tick were only 0.3 ms slower.

The fix had two parts:
- The finger bones were folded into the hands (65 to 25 bones), which cut animation CPU by about 20–25% in benchmarks.
- The importer's 510 unused hitbox attachments are removed at runtime.

Rerun with the fix, frames over 4.17 ms dropped from 1.9% to 0.2%.

The first logs also showed a telemetry bug, since fixed: the `process_ms` and `physics_ms` columns repeated Godot's worst-of-last-second value instead of a per-frame time. The analysis tool flags logs from that build. GPU time is about 0.9 ms per frame with 30 bots, so the bot load is CPU-bound.

## Still open

- Test 3: measure cm per 360° with a ruler in both the build and Apex.
- Test 5: film clicks in slow motion in both the build and Apex.
- Test 7: Xbox pad and DualSense, over USB and Bluetooth.
- Check the 32:9 field of view against Apex. The build assumes Apex widens the view on ultrawide screens, which gives 147° horizontal at this FOV.
- Feedback on how close-range tracking feels.
