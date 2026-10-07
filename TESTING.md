# First-week engine tests

The engine report (`reports/Unity vs Godot for aim trainer.md`) picks Godot on the condition that seven checks pass on a real gaming PC. This build, **Apex Aim Lab**, runs them:

- **Test 1** runs automatically on every push (`tools/run_tests.sh` in GitHub Actions).
- **Tests 2–7** need your PC, and take about an hour in total.

## Get the build

1. On GitHub, open **Actions → Test and build**, pick the latest green run on this branch, and download **ApexAimLab-windows**.
2. Unzip `ApexAimLab.exe` into a folder of its own. The game writes an `override.cfg` next to it when you change startup settings.
3. Windows SmartScreen will warn that the file is unsigned. Click **More info → Run anyway**.

Logs go to `%APPDATA%\Godot\app_userdata\Apex Aim Lab\logs`; the menu's **Open the logs folder** button opens it.

- Press **L** in any lab to start or stop a log.
- Each log is a CSV with one row per frame plus a JSON file describing your PC and settings. A row holds the frame time, raw mouse counts and events, and how the frame's time split between CPU work (scripts and animation, physics, render) and the GPU.

## Before you start

- In the settings panel, click **Import from this PC's Apex settings**. It reads `mouse_sensitivity` and `cl_fovScale` from `Saved Games\Respawn\Apex`. You can also type the values in.
- Set your **mouse DPI**.
- Keep the defaults for the first pass:
  - exclusive fullscreen
  - V-Sync off
  - no frame cap
  - Direct3D 12
  - swapchain 2, frame queue 2

## The tests

| # | Lab | Pass if |
|---|---|---|
| 2 | Main menu | It starts on Direct3D 12 and on Vulkan, and shows your monitor's real refresh rate |
| 3 | Mouse lab | Your measured distance for a 360° turn matches Apex's within about 2% |
| 4 | Mouse lab | In gameplay, 1% lows stay at or above your refresh rate at every polling rate; with the visible cursor, no frame takes longer than 100 ms |
| 5 | Latency flash | The median click-to-flash time is no worse than Apex's on the same PC |
| 6 | Bot load | 1% lows stay at or above your refresh rate with 30 bots and 500 bullets per second |
| 7 | Controllers | Sticks reach ±1.0 with no engine deadzone, DualSense gyro reports values, and rumble works |

The thresholds are the report's suggestions, not industry standards.

### 2. Launch

1. Start the game. The top of the menu should show your GPU, `d3d12`, and your monitor's actual refresh rate.
2. Under **Latency (applies after restart)**, set the renderer to `vulkan` and click **Apply and restart**.
3. Check the same three lines again.

### 3. Sensitivity exactness

1. Open the **Mouse lab** and press **Home**. The view snaps to the red pillar and the counters reset.
2. Hold the mouse against a ruler. Move it right, slowly and steadily, until the crosshair is back on the red pillar. That is one full turn.
3. Note the distance, and repeat five times.
4. The HUD shows the cm per 360° that your settings predict. Your average should match it.
5. Do the same in Apex's Firing Range with the same sensitivity and DPI.
6. Compare the two averages.

**Turned right** shows the exact angle the game applied. It should land near 360.000° when the crosshair is back on the pillar.

### 4. Mouse polling stress

Repeat this at 1000, 2000, 4000 and 8000 Hz (set the rate in your mouse's software):

1. In the **Mouse lab**, press **L** to start logging.
2. Flick and swipe fast for about 20 seconds.
3. Press **Tab** to switch to the visible cursor, and sweep it over the menu for another 20 seconds.
4. Press **L** to stop.
5. Watch **1% low** and **worst frame** while you do it.

The visible-cursor step matters: a reported Godot 4.7.2 bug causes multi-second freezes with a visible cursor and fast mice.

Optional extras:
- Untick **Accumulated mouse input** in the settings. **Mouse events per second** then shows roughly the polling rate the game actually receives.
- If you have G-Sync or FreeSync, repeat with the **VRR frame cap** button.

### 5. Click-to-photon latency

You need a phone that films slow motion at 240 FPS, with the mouse and the screen in the same shot.

1. In the **Latency flash** lab, click at least 20 times, about once a second. Each click turns the screen white.
2. In the video, count frames from the mouse button going down to the screen turning white. One frame is 4.17 ms at 240 FPS.
3. Do the same in Apex's Firing Range: count from the click to the muzzle flash.
4. Repeat the lab with these variations:
   - swapchain **2 vs 3**: change it in the menu, then **Apply and restart**
   - V-Sync off vs the VRR cap: press **F**

### 6. Bot and projectile load

1. In the **Bot load** lab, press **L** and play for about 60 seconds. Shoot with the left mouse button as well.
2. Press **L** to stop.

The lab starts with 30 strafing dummies and an emitter firing 500 bullets per second.

- **P** changes the emitter rate.
- **[** and **]** change the number of bots.
- **H** shows the hitboxes.
- **Bullet hit tests** shows how many milliseconds bullet collision costs per physics tick.
- The **CPU / GPU** line shows where each frame's time goes. If 1% lows dip below your refresh rate, this line says whether the CPU or the graphics card is the limit.

Bullet speed, recoil and bot movement are placeholders, not Apex data yet.

### 7. Controllers

Test an Xbox pad and a DualSense, each over USB and over Bluetooth. Then repeat with Steam Input on: add `ApexAimLab.exe` to Steam as a non-Steam game and launch it from Steam.

In the **Controllers** lab, check that:

- each stick's length reaches 1.000 at the edge (watch **max**), and the centre reads close to 0 with no engine deadzone;
- triggers read from 0 to 1;
- **Q** and **E** make the controller rumble;
- on the DualSense, **G** turns the motion sensors on and the gyro numbers change when you tilt the pad. **C** starts and stops calibration.

## Also try: close-range tracking

The menu's **Train** section has the first real scenario.

- Ten targets appear one at a time, 8–15 m away, near where you're looking. They strafe and crouch-spam.
- Each has purple shields (100) and 100 health. Knock each one as fast as you can.
- **R** (or **X** on a controller) reloads.
- The results screen shows average and fastest time to knock, accuracy, headshot rate and damage per magazine. Every session is saved, so it also compares you with your previous runs.

The rifle's numbers, the bullet speed and the bots' movement are placeholders, so judge the *feel*, not the scores:
- Does aiming at Apex sensitivity feel right?
- Do bullet travel and hit feedback read clearly?
- Is anything distracting?

## What to send back

- the zipped logs folder
- your 360° distances, and the latency frame counts for the build and Apex
- anything odd: freezes, stutter, crashes, wrong refresh rate, a controller that isn't detected
- how close-range tracking felt, and your results screen
