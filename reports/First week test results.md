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
| 3 | Sensitivity exactness | ⚠️ Not measured; accepted risk | The build predicts 37.11 cm per 360°, and the math matches an independent sensitivity converter. A ruler check against Apex wasn't done. |
| 4 | Mouse polling stress | ✅ Pass at 1 kHz | Mouse lab: 952 FPS average, 1% low 586, worst frame 2.5 ms, no stalls. 2–8 kHz not tested (the mouse appears to be 1 kHz). |
| 5 | Click-to-photon latency | ⚠️ Not filmed; accepted risk | Frame caps behave: locked 240 FPS (std dev 0.21 ms) and the VRR cap at 224 FPS (std dev 0.08 ms) |
| 6 | Bot and projectile load | ✅ Pass after a fix | First run: 365 FPS average, 1% low 203. After the fix: 573 average, 1% low 259 (target 240). The worst frame was 6.2 ms in both runs. |
| 7 | Controllers | ⚠️ Not run; accepted risk | |

## What the first run changed

Test 6 first missed its target because 30 animated bots cost about 2 ms per frame. Bullets weren't the cause: frames with a physics tick were only 0.3 ms slower.

The fix had two parts:
- The finger bones were folded into the hands (65 to 25 bones), which cut animation CPU by about 20–25% in benchmarks.
- The importer's 510 unused hitbox attachments are removed at runtime.

Rerun with the fix, frames over 4.17 ms dropped from 1.9% to 0.2%.

The first logs also showed a telemetry bug, since fixed: the `process_ms` and `physics_ms` columns repeated Godot's worst-of-last-second value instead of a per-frame time. The analysis tool flags logs from that build. GPU time is about 0.9 ms per frame with 30 bots, so the bot load is CPU-bound.

## Decision

**Godot is confirmed.** The test phase closed on 8 October 2026 with the results above:
- Tests 1, 2, 4 and 6 passed.
- The frame-pacing half of test 5 passed.
- Nothing failed.

### Accepted risks

The remaining checks need someone at the PC with a ruler, a slow-motion camera or controllers, so they were not run. They are now accepted risks rather than blockers:

- **Test 3, sensitivity.** The build turns 0.022° × sensitivity per raw mouse count, Source's yaw that Apex uses. It reads raw counts, so the window's scaling doesn't affect them. The cm-per-360° formula matches an independent converter (800 DPI at sensitivity 1.5 gives 34.6 cm). What remains is a physical side-by-side with Apex.
- **Test 5, latency.** Frame caps and pacing are good. Absolute click-to-photon latency against Apex was not filmed.
- **Test 7, controllers.** The stick, gyro and rumble code is untested on real pads.
- **32:9 field of view.** The build widens the view on ultrawide screens, as Apex does on 16:9 and 21:9 (147° horizontal at this PC's FOV). Some players report that Apex shows 21:9 with black bars on 32:9. **Limit view to 21:9** in the settings reproduces that and is off by default.

## Since then

- **Real weapon data replaced the placeholder rifle.** The R-99, Volt, R-301 and Flatline now use Season 30 numbers:
  - damage by hitbox;
  - fire rate and magazine sizes;
  - tactical and empty reloads;
  - bullet speed, except the Volt's.
- **Placeholders that remain** are listed in the README: recoil patterns, bullet drop and the Volt's bullet speed.
- **Bots** strafe at Apex's walking and crouch-walking speeds with a weapon out.
- **Training** now has four scenarios: close range (8–15 m) with the R-99 and the Volt, and mid range (20–35 m) with the R-301 and the Flatline.
