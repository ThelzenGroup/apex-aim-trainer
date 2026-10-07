# Unity vs Godot: mouse input, input latency, frame pacing, high refresh rates and gamepads for an Apex-style aim trainer (state as of October 2026)

Research notes for the report writer. Current versions found:
- **Godot:** the latest stable release found is **4.7.2** (released 2026-08-18). 4.8 is in development; **4.8.dev5** came out 2026-09-10, and I found no 4.8 beta/RC/stable article as of these notes. [4.7.2 article](https://godotengine.org/article/maintenance-release-godot-4-7-2/), [4.8 dev5 article](https://godotengine.org/article/dev-snapshot-godot-4-8-dev-5/)
- **Unity:** the latest stable editor found is **6000.6.4f1** (released 2026-10-01), with 6000.7 in beta. [6000.6.4f1 release notes](https://unity.com/releases/editor/whats-new/6000.6.4f1), [6000.7.0b2](https://unity.com/releases/editor/beta/6000.7.0b2)
- **Unity Input System package:** the latest version found is **1.20.1** (released 2026-10-05). [CHANGELOG](https://github.com/Unity-Technologies/InputSystem/blob/develop/Packages/com.unity.inputsystem/CHANGELOG.md)

Method note: the egress proxy blocked these domains: godotengine.org, docs.godotengine.org, discussions.unity.com, docs.unity3d.com, issuetracker.unity.com, assetstore.unity.com and developer.nvidia.com. To work around this:
- Godot blog posts and docs were read from their GitHub source repos (godot-website, godot-docs, and the class XML in godotengine/godot).
- Unity Input System docs were read from the package's GitHub repo (`Documentation~`), along with the C# source.
- Facts from Unity Discussions, the Unity issue tracker, the Asset Store and NVIDIA pages come **only from search-result snippets** and are flagged that way below. The URLs given are the canonical public pages.

---

## Q1. Raw mouse input: WM_INPUT in captured/locked mode, how deltas are handled, high-polling (4-8 kHz) mice

### Takeaway
**Both engines read Windows raw input (WM_INPUT/RAWINPUT) for mouse deltas in captured/locked mode.** Both therefore deliver unaccelerated integer counts that are not affected by Windows pointer speed or Enhanced Pointer Precision.

**Godot has the clearer, verifiable story.** In captured mode, `InputEventMouseMotion.screen_relative` carries the summed raw `lLastX/lLastY` counts. Input accumulation adds counts together and never drops them. The 8 kHz performance problem on Windows was fixed in **4.7.2 (August 2026)**, with published benchmarks.

**Unity's Input System also uses RAWINPUT for `Mouse.delta` on Windows.** However, the high-polling-rate performance problem (main-thread message pump stalls at 4-8 kHz) is still listed as a **known issue in Unity 6000.6.4f1 / 6000.7 beta**.

### Cited Findings

**Godot: how raw input works on Windows**
- In `DisplayServerWindows`, raw mouse input is registered with `RegisterRawInputDevices`:
  - The flags are `rid.usUsage = 0x02` (generic mouse) and `dwFlags = 0`. There is no `RIDEV_NOLEGACY`, so legacy messages are still generated.
  - If registration fails, `use_raw_input = false`.
  - [display_server_windows.cpp (master)](https://github.com/godotengine/godot/blob/master/platform/windows/display_server_windows.cpp)
- Raw events are turned into mouse motion **only when `mouse_mode == MOUSE_MODE_CAPTURED`** (`_process_raw_input_event`).
  - For relative devices, the delta is `Vector2(p_raw.data.mouse.lLastX, p_raw.data.mouse.lLastY)`. These are raw device counts, stored in a float Vector2.
  - Absolute-mode devices (`MOUSE_MOVE_ABSOLUTE`, e.g. tablets or remote desktop) are converted from screen coordinates instead.
  - Each event sets both `relative` and `relative_screen_position` (= `screen_relative`) to that raw value. The cursor is re-centred with `SetCursorPos`.
  - [display_server_windows.cpp](https://github.com/godotengine/godot/blob/master/platform/windows/display_server_windows.cpp)
- Since the 4.7.2/4.8 fix, `process_raw_input()` drains the raw queue with `GetRawInputBuffer` in a loop ("Read until the raw queue is empty").
  - In captured mode, once more than `MAX_RAW_MOUSE_EVENTS_PER_FRAME` events have been seen (or when `coalesce_all_raw_mouse_motion` is set), motion is **summed** into `coalesced_raw_mouse_motion` and flushed as one event. Counts are added together, not discarded.
  - A code comment notes that Windows' raw queue has a **10,000-message limit**, which can be reached after a long stall.
  - [display_server_windows.cpp](https://github.com/godotengine/godot/blob/master/platform/windows/display_server_windows.cpp)
- When input accumulation merges two `InputEventMouseMotion` events, `InputEventMouseMotion::accumulate()` runs `relative += motion->get_relative(); screen_relative += motion->get_relative_screen_position();`. Velocity is overwritten with the latest value. [core/input/input_event.cpp](https://github.com/godotengine/godot/blob/master/core/input/input_event.cpp)

**Godot: documented API behaviour**
- `InputEventMouseMotion.relative` "is automatically scaled according to the content scale factor ... This means mouse sensitivity will appear different depending on resolution when using relative ... with MOUSE_MODE_CAPTURED. To avoid this, use screen_relative instead."
  - `screen_relative` is "not scaled according to the content scale factor ... This should be preferred over relative for mouse aiming when using the MOUSE_MODE_CAPTURED mouse mode, regardless of the project's stretch mode."
  - In captured mode, `velocity`/`screen_velocity` return `(0, 0)`.
  - [InputEventMouseMotion class reference](https://docs.godotengine.org/en/stable/classes/class_inputeventmousemotion.html) ([XML source](https://github.com/godotengine/godot/blob/master/doc/classes/InputEventMouseMotion.xml))
- `Input.use_accumulated_input` (default **true**): "similar input events sent by the operating system are accumulated ... merged and emitted when the frame is done rendering. Therefore, this limits the number of input method calls per second to the rendering FPS."
  - Disabling it gives "slightly more precise/reactive input at the cost of increased CPU usage."
  - `Input.flush_buffered_events()` lets you flush manually.
  - [Input class reference](https://docs.godotengine.org/en/stable/classes/class_input.html) ([XML](https://github.com/godotengine/godot/blob/master/doc/classes/Input.xml))
- The `InputEventMouseMotion` docs note that, by default, the event "is only emitted once per frame rendered at most. If you need more precise input reporting, set Input.use_accumulated_input to false." [InputEventMouseMotion XML](https://github.com/godotengine/godot/blob/master/doc/classes/InputEventMouseMotion.xml)
- Community guidance agrees: disabling accumulation "can translate into thousands of calls per second" depending on poll rate. [Yo Soy Freeman: Achieving better mouse input in Godot 4](https://yosoyfreeman.github.io/article/godot/tutorial/achieving-better-mouse-input-in-godot-4-the-perfect-camera-controller/)

**Godot: the high-polling-rate fix (official blog post, Hugo Locurcio, 2026-08-24)**
- The performance issue with high-polling-rate mice on Windows is "fixed in Godot, starting with ... Godot 4.7.2". The first dev snapshot with the fix is **4.8.dev3**; 4.7.1 does not have it. The PR is [GH-109639](https://github.com/godotengine/godot/pull/109639). [Godot blog: Fixing high polling rate mice on Windows](https://godotengine.org/article/fixing-high-polling-rate-mice-on-windows/) ([source markdown](https://github.com/godotengine/godot-website/blob/master/collections/_article/fixing-high-polling-rate-mice-on-windows.md))
- Root cause: "when requesting raw input in a Windows application, it will still receive legacy input events at the same time ... even when the application is currently in captured mouse mode." Requesting only raw input "breaks several parts of the application ... such as moving the window by dragging its title bar." [Godot blog](https://godotengine.org/article/fixing-high-polling-rate-mice-on-windows/)
- The fix has three parts. The approach was inspired by [PH3's blog on Windows input](https://ph3at.github.io/posts/Windows-Input/). [Godot blog](https://godotengine.org/article/fixing-high-polling-rate-mice-on-windows/)
  - Buffered raw reads in `DisplayServerWindows::process_raw_input()`.
  - `PeekMessageW()` is called so that `WM_INPUT` is not dispatched immediately.
  - `WM_MOUSEMOVE`/`WM_NCMOUSEMOVE` are dispatched at most once per frame.
- The blog's threshold: "As of 2026 and on recent Windows 11 versions, on most CPUs, this limit is generally somewhere between 1 kHz and 2 kHz. If your mouse sends much more updates than this limit, the framerate can drop to the single digits." Linux (Wayland and X11) "is generally not affected." [Godot blog](https://godotengine.org/article/fixing-high-polling-rate-mice-on-windows/)
- Benchmark (Ryzen 9 9950X3D, RTX 5090, Windows 11 24H2, 1080p at 480 Hz), moving the mouse quickly. [Godot blog](https://godotengine.org/article/fixing-high-polling-rate-mice-on-windows/)

  **No V-Sync:**

  | Mouse mode and poll rate | 4.7.1 | 4.8.dev3 |
  |---|---|---|
  | Captured, 8 kHz | <1 FPS (>1000 ms frames) | 1703 FPS (0.59 ms) |
  | Captured, 4 kHz | 1778 FPS, with large frametime deviations | 1962 FPS |
  | Visible cursor, 8 kHz | 173 FPS | 1103 FPS |

  - The 1% low FPS improved by a factor of **45.8**.

  **V-Sync at 480 Hz:**

  | Mouse mode and poll rate | 4.7.1 | 4.8.dev3 |
  |---|---|---|
  | Captured, 8 kHz | <1 FPS | 477 FPS (2.10 ms) |
  | Visible cursor, 8 kHz | 151 FPS | 477 FPS |
- The blog warns that with accumulation enabled (the default), `_input()` may be called once per rendered frame: for example 480 times per second on a 480 Hz V-Sync setup. With accumulation disabled it "can potentially mean 8,000 calls per second when using a mouse with 8 kHz polling rate." [Godot blog](https://godotengine.org/article/fixing-high-polling-rate-mice-on-windows/)
- The 4.7.2 changelog lists: "Input: Fix performance issues when moving the mouse with high polling rate on Windows (GH-109639)." [Godot 4.7.2 release](https://godotengine.org/article/maintenance-release-godot-4-7-2/) ([source](https://github.com/godotengine/godot-website/blob/master/collections/_article/maintenance-release-godot-4-7-2.md))

**Godot: issue history and a possible regression**
- [#80583](https://github.com/godotengine/godot/issues/80583), opened 2023-08-13 on 4.1.1: stutter at 1000 Hz that disappeared at 125 Hz, and `use_accumulated_input = true` did not help. Now closed.
- [#120390](https://github.com/godotengine/godot/issues/120390), opened 2026-06-18: 4 kHz/8 kHz mouse freezes on 4.5/4.6, again with `use_accumulated_input` not helping. Closed as a duplicate.
- **Possible regression:** [#122779](https://github.com/godotengine/godot/issues/122779), opened 2026-08-24, reports multi-second main-thread stalls in 4.7.2 that did not happen in 4.7.1.
  - It occurs with `MOUSE_MODE_VISIBLE` plus mouse movement (for example in menus), with 100% CPU inside `DisplayServerWindows::process_events()` and `NtUserPeekMessage`.
  - The reporter suspects the high-polling-rate rework. When fetched, the issue showed no maintainer response.

**Unity**
- The Input System's `MouseState.delta` source comment reads: "Screen-space motion delta of the mouse in pixels ... **On Windows, delta originates from RAWINPUT API.**"
  - It adds: "This value might not update every frame, particularly if your project is running at a high frame rates."
  - [Mouse.cs (Input System develop)](https://github.com/Unity-Technologies/InputSystem/blob/develop/Packages/com.unity.inputsystem/InputSystem/Runtime/Devices/Mouse.cs)
- `Mouse.delta` uses a dedicated `DeltaControl` type, added in Input System 1.4.0 (2022). [Input System CHANGELOG](https://github.com/Unity-Technologies/InputSystem/blob/develop/Packages/com.unity.inputsystem/CHANGELOG.md)
- The `SensitivityProcessor` was removed from `Pointer.delta` back in 0.0.14-preview (2018) because "the processor was causing many issues with mouse deltas." [CHANGELOG](https://github.com/Unity-Technologies/InputSystem/blob/develop/Packages/com.unity.inputsystem/CHANGELOG.md)
- Unity's docs say: "The Input System doesn't support input from multiple mice at the platform level." When the cursor is locked, "Unity resets the cursor to the center of the window every frame." [mouse-introduction.md](https://github.com/Unity-Technologies/InputSystem/blob/develop/Packages/com.unity.inputsystem/Documentation~/mouse-introduction.md), [query-mouse-devices.md](https://github.com/Unity-Technologies/InputSystem/blob/develop/Packages/com.unity.inputsystem/Documentation~/query-mouse-devices.md)
- **Search snippets only (forum posts):**
  - A forum post says Unity reads the Windows `RAWMOUSE` `lLastX/lLastY` and passes them on as integer counts. [Unity Discussions: Get Raw Mouse Delta from WM_INPUT? (#11)](https://discussions.unity.com/t/new-input-system-get-raw-mouse-delta-from-wm_input/857382/11)
  - The same thread complains that "the existing mouse delta only returns pixel coordinates, so you have to move your mouse at least 1 pixel to get any delta," which matters for tiny movements at high DPI. [Unity Discussions thread](https://discussions.unity.com/t/new-input-system-get-raw-mouse-delta-from-wm_input/857382)
  - These two claims conflict. The source comment ("RAWINPUT") supports the integer-counts reading.
- **Legacy Input Manager (search snippets):** a forum thread states that `Input.GetAxisRaw("Mouse X")` does not take OS mouse acceleration into account. [Unity Discussions: Delta Mouse Position with OS Smoothing/Acceleration](https://forum.unity.com/threads/delta-mouse-position-with-os-smoothing-acceleration.470725/) Separately, Unity 2023.2+ provides `Input.mousePositionDelta` for use with `CursorLockMode.Locked`. [Unity Scripting API: Input.mousePositionDelta](https://docs.unity3d.com/2023.2/Documentation/ScriptReference/Input-mousePositionDelta.html)

**Unity: high-polling-rate performance (search snippets only; forum and issue tracker pages were blocked)**
- In a Unity Discussions thread, the editor's main thread went from about 3 ms idle to:

  | Poll rate | Main-thread time (editor) |
  |---|---|
  | 2 kHz | 4 ms |
  | 4 kHz | 30 ms |
  | 8 kHz | 100 ms |

  - That is a drop from about 300 FPS to 30-40 FPS. Builds were better but still had about 0.5 s freezes at 8 kHz.
  - Unity staff explained that Unity uses raw input and reads it on the main thread. It calls the standard `PeekMessageW`/`DispatchMessageW` and "they hang."
  - Rate-limiting those calls would back up the queue and increase latency.
  - The underlying bottleneck is Windows translating raw input into legacy `WM_MOUSE*` messages.
  - The thread also says an 8 kHz issue was fixed on Windows Standalone in Unity 2021.2.0, but the performance problems remain.
  - [Unity Discussions: Performance degradation with high polling rate mouse](https://discussions.unity.com/t/performance-degradation-while-using-mouse-with-high-polling-rate-any-known-engine-version-without-the-problem/1508487?page=2)
- Unity issue tracker entry "High polling rate mice are causing performance issues (windows, editor)", referenced as UUM-1484 in snippets. [Unity Issue Tracker](https://issuetracker.unity.com/issues/292/high-polling-rate-mice-are-causing-performance-issues-windows-editor)
- The **6000.7.0b2** release notes list a known issue: Play Mode framerate drops significantly when moving a high-polling-rate mouse (**UUM-142550**). Snippets say the issue is still a known issue in **6000.6.4f1** (2026-10-01). [Unity 6000.7.0b2](https://unity.com/releases/editor/beta/6000.7.0b2), [Unity 6000.6.4f1](https://unity.com/releases/editor/whats-new/6000.6.4f1)
- The same Windows problem affects other engines and frameworks too, for example [SDL #8756](https://github.com/libsdl-org/SDL/issues/8756) and [osu! discussion #27718](https://github.com/ppy/osu/discussions/27718).

### Inferences
- **Godot preserves Apex-exact counts if you use `screen_relative`.**
  - With `MOUSE_MODE_CAPTURED` and `event.screen_relative`, each count maps exactly: yaw degrees = counts × 0.022 × sens.
  - Both accumulation and the new coalescing path add counts together, so no counts are lost and there is no rounding at the engine level. Raw counts are integers stored in floats, which are exact below 2^24.
  - Using `relative` instead would scale counts by the content-scale factor whenever a stretch mode is active, which would break cm/360.
  - GDScript `float` is 64-bit, so the yaw accumulator can be kept in double precision.
- **Accumulation trades sub-frame timing, not precision.** Leaving `use_accumulated_input` on loses only the timing of individual sub-frame motions, not the total distance. Camera rotation is applied per frame either way, so accumulation on is the sensible default for an aim trainer. Turning it off is only useful for per-event timestamp analytics.
- **Godot's raw path only exists in captured mode.** Visible or confined cursor modes use `WM_MOUSEMOVE`, which is affected by pointer speed. Menus and flick-to-target modes must keep the mouse captured to stay 1:1.
- **Unity's `Mouse.delta` should also be raw counts on Windows**, but this rests on a source comment plus forum posts. Two things should be verified empirically:
  - That there is no pixel quantisation or scaling, in both the windowed and exclusive-fullscreen player.
  - That the per-frame delta accumulation does not lose counts at 500 FPS, given the "might not update every frame" note.
- **For a 4-8 kHz-mouse audience on Windows:**
  - Godot ≥ 4.7.2 has a published, measured fix.
  - Unity still lists the issue as known in its current stable and beta releases.
  - Godot 4.7.2 may have a visible-cursor regression ([#122779](https://github.com/godotengine/godot/issues/122779)), which matters for menus.

### Gaps
- I could not open Unity's issue tracker or release notes directly. The UUM-1484/UUM-142550 statuses and the "still known in 6000.6.4f1" claim come from search snippets.
- I found no primary Unity documentation stating whether `Mouse.delta` in a locked-cursor Windows player is exactly raw counts, with no pixel rounding and no DPI scaling.
- I found no maintainer response or fix for Godot #122779, the visible-cursor stalls in 4.7.2.
- I did not verify whether Godot's `MAX_RAW_MOUSE_EVENTS_PER_FRAME` coalescing changes timestamps that an analytics layer might rely on.

---

## Q2. Input latency and frame pacing: input sampling vs frame, uncapped FPS, V-Sync off, measured latency, physics tick vs render

### Takeaway
**Both engines sample input once per frame, at the start of the frame or just before game logic. Both support V-Sync off and uncapped FPS.**

**Godot documents its latency controls explicitly:**
- V-Sync modes
- `swapchain_image_count` (2 or 3)
- `frame_queue_size` (default 2)
- `max_fps`, including a VRR cap formula
- Physics interpolation, which adds latency
- `use_accumulated_input`

**Unity exposes these:**
- Input System Update Mode: Dynamic, Fixed or Manual
- `InputSystem.pollingFrequency`
- `QualitySettings.vSyncCount`, `Application.targetFrameRate` and `QualitySettings.maxQueuedFrames` (default 2)

**No measured input-to-photon comparison between the two engines was found.**

### Cited Findings

**Godot**
- `display/window/vsync/vsync_mode` defaults to Enabled (1). Modes include Disabled, Adaptive and Mailbox. `--disable-vsync` forces V-Sync off from the command line. [ProjectSettings reference](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html) ([XML](https://github.com/godotengine/godot/blob/master/doc/classes/ProjectSettings.xml))
- `application/run/max_fps` (0 = unlimited) is also available at runtime as `Engine.max_fps`.
  - For VRR with V-Sync on, the docs give the cap formula `r - (r*r)/3600`. That works out to **224 FPS at 240 Hz, 324 at 360 Hz and 416 at 480 Hz**.
  - The docs say this yields "similar input lag as V-Sync disabled ... (usually less than 1 ms greater), but without any tearing."
  - [ProjectSettings](https://github.com/godotengine/godot/blob/master/doc/classes/ProjectSettings.xml), [Fixing jitter, stutter and input lag](https://docs.godotengine.org/en/latest/tutorials/rendering/jitter_stutter.html) ([rst](https://github.com/godotengine/godot-docs/blob/master/tutorials/rendering/jitter_stutter.rst))
- `rendering/rendering_device/vsync/frame_queue_size` (default **2**) is "the number of frames to track on the CPU side before stalling to wait for the GPU." It is read only at startup and cannot be changed at runtime. [ProjectSettings](https://github.com/godotengine/godot/blob/master/doc/classes/ProjectSettings.xml)
- `rendering/rendering_device/vsync/swapchain_image_count` (default **3**): "Double-buffering may give you the lowest lag/latency ... Triple buffering gives you higher framerate ... at the cost of up to 1 frame of latency." Mailbox mode needs triple buffering. [ProjectSettings](https://github.com/godotengine/godot/blob/master/doc/classes/ProjectSettings.xml)
  - Since Godot 4.3, setting the swapchain image count to 2 gives double-buffered V-Sync for lower latency (Forward+/Mobile). [jitter_stutter doc](https://docs.godotengine.org/en/latest/tutorials/rendering/jitter_stutter.html)
- **Physics and input latency:**
  - The docs say that raising physics ticks per second "can also reduce physics-induced input latency. This is especially noticeable when using physics interpolation (which improves smoothness but increases latency)." They suggest 120, 180 or 240 Hz.
  - The `--max-fps` command-line flag exists since 4.2.
  - [jitter_stutter doc](https://docs.godotengine.org/en/latest/tutorials/rendering/jitter_stutter.html)
  - `physics/common/physics_interpolation` defaults to **false**. When enabled, the renderer interpolates transforms "between the last two transforms." The default `physics_ticks_per_second` is 60. [ProjectSettings](https://github.com/godotengine/godot/blob/master/doc/classes/ProjectSettings.xml)
- The docs recommend **Exclusive Fullscreen** over Fullscreen on Windows, because it "allows Windows to reduce jitter and input lag." [jitter_stutter doc](https://docs.godotengine.org/en/latest/tutorials/rendering/jitter_stutter.html)
- **Agile input flushing:**
  - Added in 3.4. Input events are buffered and flushed "at key points of the cycle" (before each physics step) rather than once per frame. [Godot blog: Agile input processing (2021)](https://godotengine.org/article/agile-input-processing-is-here-for-smoother-gameplay/)
  - However, the setting `input_devices/buffering/agile_event_flushing` (default false) is "**Currently implemented only on Android**." On Windows, events are flushed once per process frame. [ProjectSettings](https://github.com/godotengine/godot/blob/master/doc/classes/ProjectSettings.xml)
- `rendering/driver/threads/thread_model` (multi-threaded rendering) is marked experimental: it has "several known bugs" and is "not recommended for use in production." Rendering on a separate thread "can cause a bit more jitter." [ProjectSettings](https://github.com/godotengine/godot/blob/master/doc/classes/ProjectSettings.xml)
- **Open frame-pacing issues (titles only):**
  - [#87020](https://github.com/godotengine/godot/issues/87020): V-Sync not obeyed since 4.3.dev1
  - [#95706](https://github.com/godotengine/godot/issues/95706): FPS not limited by refresh rate with V-Sync on
  - [#77596](https://github.com/godotengine/godot/issues/77596): visual input delay in exclusive fullscreen with V-Sync on
  - [#121104](https://github.com/godotengine/godot/issues/121104): XR frame pacing

**Unity**
- **When input is processed:**
  - In "Process Events In Dynamic Update" mode, queued events are processed "just before the next Update". In Fixed mode they are processed "just before the next FixedUpdate". Events that arrive during frame N are processed at the start of frame N+1.
  - Each event keeps its own timestamp.
  - [timing-input-events-queue.md](https://github.com/Unity-Technologies/InputSystem/blob/develop/Packages/com.unity.inputsystem/Documentation~/timing-input-events-queue.md)
  - "In cases where minimum latency is a necessity, set the update mode to Process Events in Dynamic Update, even if you're using code in FixedUpdate." [timing-select-mode.md](https://github.com/Unity-Technologies/InputSystem/blob/develop/Packages/com.unity.inputsystem/Documentation~/timing-select-mode.md)
  - Polling in `Update` is "sample-and-hold ... individual subframe information is discarded". Use event-driven callbacks to see every event. [timing-optimize-dynamic-update.md](https://github.com/Unity-Technologies/InputSystem/blob/develop/Packages/com.unity.inputsystem/Documentation~/timing-optimize-dynamic-update.md)
  - The Input System no longer supports processing input in both fixed and dynamic updates. You must choose one, and a Manual mode (`InputSystem.Update()`) exists. [CHANGELOG](https://github.com/Unity-Technologies/InputSystem/blob/develop/Packages/com.unity.inputsystem/CHANGELOG.md)
- **`InputSystem.pollingFrequency`:**
  - Since Input System 1.13.1 (2025-02-18), it is "initialized based on recommended polling frequency by the underlying platform on Unity versions newer than 6000.3.0a1."
  - "Increasing polling frequency beyond the default 60Hz leads to less probability of input loss and reduces input latency."
  - [CHANGELOG](https://github.com/Unity-Technologies/InputSystem/blob/develop/Packages/com.unity.inputsystem/CHANGELOG.md)
  - On Windows, XInput controllers are polled explicitly rather than delivered as events. [gamepad-polling.md](https://github.com/Unity-Technologies/InputSystem/blob/develop/Packages/com.unity.inputsystem/Documentation~/gamepad-polling.md)
- **Rendering settings (search snippets of the Unity Scripting API):**
  - With `QualitySettings.vSyncCount = 0` and `Application.targetFrameRate = -1`, content renders unsynchronised as fast as possible.
  - `targetFrameRate` is software-timed and "subject to microstuttering"; Unity recommends `vSyncCount > 0` for smooth pacing.
  - The defaults are `vSyncCount = 1` and `maxQueuedFrames = 2`.
  - Lowering `maxQueuedFrames` reduces input latency but can lower FPS. Setting it to 1 "essentially disable[s] pipelining."
  - [Application.targetFrameRate (6000.6)](https://docs.unity3d.com/6000.6/Documentation/ScriptReference/Application-targetFrameRate.html), [QualitySettings.vSyncCount](https://docs.unity3d.com/ScriptReference/QualitySettings-vSyncCount.html), [QualitySettings.maxQueuedFrames](https://docs.unity3d.com/400/Documentation/ScriptReference/QualitySettings-maxQueuedFrames.html)
  - A demo project shows Unity's rendering-latency settings visually. [TempoLabGames/UnityRenderingLatencyDemo](https://github.com/TempoLabGames/UnityRenderingLatencyDemo)

**Measured latency**
- A search for Unity-vs-Godot click-to-photon measurements found only opinion pieces, with no LDAT or high-speed-camera data. For example: "Both engines can be exceptionally tight when it comes to input latency." [Sunstrike Studios blog (opinion)](https://sunstrikestudios.com/en/blog/godot_vs_unity_in_2025/)
- A Godot proposal author reports keeping external latency-test data. They state that the hard-coded minimum `frame_queue_size` of 2 adds unwanted latency for action games. [godot-proposals #11200](https://github.com/godotengine/godot-proposals/issues/11200)

### Inferences
- **Engine choice matters less than settings.** For an aim trainer that reads mouse in `_process`/`Update` and rotates the camera per rendered frame, both engines give about one frame of sampling latency plus the render queue. The settings that matter most are:
  - V-Sync off or a VRR cap
  - Exclusive fullscreen
  - Queue depth: Godot `frame_queue_size`/`swapchain_image_count`, Unity `maxQueuedFrames`
- **Keep camera aim off the physics tick.** Mouse-look should be applied in the render-rate callback (Godot `_process`, Unity `Update` in Dynamic mode), not on the physics tick. Physics interpolation should not be applied to the camera, because it adds latency (per the Godot docs).
- **Godot's "agile flushing" is not available on Windows.** On PC, input is flushed once per frame, which is effectively equivalent to Unity's Dynamic Update mode.

### Gaps
- I found no published, controlled input-to-photon or click-to-photon measurements comparing Unity 6.x and Godot 4.x.
- I could not read Unity's current docs for `maxQueuedFrames` on D3D12/Vulkan; the snippets come from older doc versions. Unity's frame-pacing internals in 6.x (e.g. the 2020.2 deltaTime/frame-timing work) could not be verified from primary pages.
- The exact Godot versions for physics interpolation (2D vs 3D) were not re-verified this session. The ProjectSettings entry exists on master. The task brief says "4.3+"; my recollection is 2D in 4.3 and 3D in 4.4, but that is unverified.

---

## Q3. NVIDIA Reflex / AMD Anti-Lag support

### Takeaway
**Neither engine ships Reflex or Anti-Lag as a built-in, first-party feature in the sources found.**
- **Unity:** NVIDIA has historically offered a Reflex Unity plugin. A Unity Asset Store plugin, "Reflex Low Latency Plugin for Unity" (v1.0, August 2026, URP only), exists, but its publisher could not be confirmed as NVIDIA.
- **Godot:** there is no official Reflex/Anti-Lag support. A 2024 proposal for a low-latency mode (VK_NV_low_latency2 / VK_AMD_anti_lag) is still open.

### Cited Findings
- NVIDIA's Unity engine page describes Reflex in Unity as a low-latency mode that "aligns game engine work to complete just-in-time for rendering, eliminating the GPU render queue." NVIDIA's GTC blog notes that the "flash indicator was added to the Unity Plugin" for latency measurement. (Search snippets; NVIDIA pages were blocked.) [NVIDIA: Unity Engine](https://developer.nvidia.com/game-engines/unity-engine), [NVIDIA GTC blog](https://developer.nvidia.com/blog/leveling-up-graphics-amp-performance-with-rtx-dlss-and-reflex-at-nvidia-gtc/)
- **Unity Asset Store: "Reflex Low Latency Plugin for Unity"** (search snippets):
  - Version 1.0, released 2026-08-17, priced $4.99.
  - Built for Unity 6000.3.14.
  - Compatible with URP, but not HDRP or the Built-in pipeline.
  - The snippets did not identify the publisher.
  - [Asset Store listing](https://assetstore.unity.com/packages/tools/utilities/reflex-low-latency-plugin-for-unity-378338)
- NVIDIA says Reflex consists of Low Latency mode and **Reflex Frame Warp**, which "samples the latest mouse position and warps the rendered frame just before scan out." [NVIDIA Reflex SDK](https://developer.nvidia.com/performance-rendering-tools/reflex)
  - The Reflex integration path documented publicly in the sources found is Streamline's Reflex programming guide. [Streamline ProgrammingGuideReflex.md](https://github.com/NVIDIAGameWorks/Streamline/blob/main/docs/ProgrammingGuideReflex.md)
- A Unity Discussions thread asks whether Unity can integrate AMD/NVIDIA anti-lag technologies (title only). [Unity Discussions](https://discussions.unity.com/t/amd-and-nvidia-have-anti-lag-technologies-does-unity-have-a-way-to-include-these/833240)
- **Godot proposal #11200** ("Add low latency project setting for RenderingDevice", opened 2024-11-21 by KeyboardDanni) is still **open**, with no milestone. [godot-proposals #11200](https://github.com/godotengine/godot-proposals/issues/11200)
  - It proposes `rendering/rendering_device/low_latency_mode` with three values: PREFER_HIGH_FRAMERATE, PREFER_LOW_LATENCY_CONSISTENT and PREFER_LOW_LATENCY_AGGRESSIVE.
  - It would also add a `--low-latency` command-line flag.
  - It would use VK_NV_low_latency2 / VK_AMD_anti_lag (Reflex / Anti-Lag) where available.
  - It references PR #94898 and issue #75830.
- Godot's own docs point users to driver-level low-latency modes instead, such as the NVIDIA Control Panel "Ultra" setting. [jitter_stutter doc](https://docs.godotengine.org/en/latest/tutorials/rendering/jitter_stutter.html)

### Inferences
- **Godot:** Reflex would require a custom GDExtension or engine fork that hooks Vulkan/D3D12 present. None was found.
- **Unity:** a third-party or NVIDIA plugin path exists, at least for URP.
- **For an uncapped, CPU-bound aim trainer** that runs far above the refresh rate with V-Sync off, Reflex's benefit (removing the GPU queue in GPU-bound cases) is smaller. Keeping the engine's own frame queue short matters more.

### Gaps
- I could not confirm whether NVIDIA still distributes an official Unity Reflex plugin for Unity 6.x, which render pipelines and APIs it supports (DX11, DX12 or Vulkan), or who publishes the Asset Store plugin.
- I found no AMD Anti-Lag 2 SDK integration for either engine.
- I found no Godot community Reflex/Anti-Lag GDExtension.

---

## Q4. High-refresh rendering: caps, stutter or frame-time issues at 240-500 FPS

### Takeaway
**Godot (≥ 4.7.2) has published data showing nearly locked 480 FPS at 480 Hz V-Sync, and over 1,700 FPS uncapped, with an 8 kHz mouse.** Before 4.7.2, 4 kHz mice caused visible frame-time spikes and 8 kHz mice made it unplayable.

**Unity's main high-FPS risk found is the same Windows mouse message-pump issue,** which is still a known issue. Unity also notes that `Mouse.delta` "might not update every frame" at high frame rates.

**Neither engine has a documented hard FPS cap.**

### Cited Findings
- **Godot 4.8.dev3 (same fix as 4.7.2) at 480 Hz V-Sync:**
  - 477-478 FPS (about 2.09-2.10 ms) at every poll rate from 1 to 8 kHz, captured or visible.
  - Before the fix (4.7.1): 151 FPS (visible cursor at 8 kHz) and under 1 FPS (captured at 8 kHz).
  - Frame times over 16.7 ms were seen at 4 kHz.
  - "Slight deviations at framerates this high are expected, as each frame only has ~2.1 milliseconds to render."
  - [Godot blog](https://godotengine.org/article/fixing-high-polling-rate-mice-on-windows/)
- **Godot uncapped with no movement:** about 4,000 FPS (0.24 ms) in a test project, showing no engine-imposed cap. [Godot blog](https://godotengine.org/article/fixing-high-polling-rate-mice-on-windows/)
- **Godot VRR caps (from the doc table):**

  | Refresh rate | Recommended cap |
  |---|---|
  | 240 Hz | 224 FPS |
  | 360 Hz | 324 FPS |
  | 480 Hz | 416 FPS |

  - "At higher refresh rates, a lower cap is needed to ensure timing inaccuracies don't cause the display to engage V-Sync."
  - [jitter_stutter doc](https://docs.godotengine.org/en/latest/tutorials/rendering/jitter_stutter.html)
- **Unity's `Mouse.delta`/`position`** "might not update every frame, particularly if your project is running at a high frame rates." [Mouse.cs](https://github.com/Unity-Technologies/InputSystem/blob/develop/Packages/com.unity.inputsystem/InputSystem/Runtime/Devices/Mouse.cs)
- **Unity's `targetFrameRate`** is software-timed and subject to microstutter (search snippet). [Application.targetFrameRate](https://docs.unity3d.com/6000.6/Documentation/ScriptReference/Application-targetFrameRate.html)
- **Unity Play Mode framerate drops with high-polling mice:** UUM-142550, a known issue in 6000.7.0b2 (search snippet). [Unity 6000.7.0b2](https://unity.com/releases/editor/beta/6000.7.0b2)
- **Godot V-Sync/pacing issue titles:** [#87020](https://github.com/godotengine/godot/issues/87020) (V-Sync not obeyed since 4.3.dev1) and [#95706](https://github.com/godotengine/godot/issues/95706). I did not check their resolution status.

### Inferences
- **On Godot, an 8 kHz mouse plus a 480 Hz monitor is now viable on Windows**, provided the project targets ≥ 4.7.2, uses captured mode, and keeps `_input()` cheap.
- **On Unity, an 8 kHz mouse at very high FPS remains at risk** of message-pump frame spikes until Unity resolves UUM-142550 and related issues. A user-facing mitigation would be "set the mouse to ≤ 2 kHz."

### Gaps
- I found no published Unity 6.x frame-time data at 240-500 FPS with 4-8 kHz mice in a build (not the editor).
- I did not verify whether Godot's 4.7.2 visible-cursor regression ([#122779](https://github.com/godotengine/godot/issues/122779)) also affects captured mode.

---

## Q5. Gamepad support: APIs, DualSense, gyro, rumble, Steam Input, raw stick values

### Takeaway
**Godot moved to SDL3 for controller input on Windows, macOS and Linux in 4.5.** It added first-class gamepad motion-sensor APIs (gyro and accelerometer, with calibration) in **4.7**, and 4.8 dev snapshots add gyro auto-calibration. Raw stick values are available as linear floats from -1 to 1 with no engine deadzone at that layer.

**Unity's Input System supports Xbox pads (via XInput on Windows) and DualSense (via HID on Windows, macOS and Linux).**
- It **does not support DualShock 4/DualSense gyro or accelerometer on PC**, only on PlayStation consoles.
- Its sticks have a default `stickDeadzone` processor (0.125-0.925) applied.
- Gyro aiming in Unity therefore requires a third-party library.

### Cited Findings

**Godot**
- SDL3 input landed for 4.5 (it was in 4.5 beta 2, 2025-07-01) as a pre-approved feature-freeze exception. [Godot on X](https://x.com/godotengine/status/1940181624702038442), [Dev snapshot: Godot 4.5 beta 2](https://godotengine.org/article/dev-snapshot-godot-4-5-beta-2/)
- "Since Godot 4.5, the engine relies on SDL 3 for controller support on Windows, macOS, and Linux," replacing Godot's own joypad drivers (search snippet of the docs). [Controllers, gamepads, and joysticks doc](https://docs.godotengine.org/en/stable/tutorials/inputs/controllers_gamepads_joysticks.html)
- SDL3 was later extended to Android, iOS, visionOS and Web. [PR #109645](https://github.com/godotengine/godot/pull/109645), [PR #114316](https://github.com/godotengine/godot/pull/114316)
- **Joypad tracker issue:** [#105417](https://github.com/godotengine/godot/issues/105417)
- **Motion sensors:** [PR #111679](https://github.com/godotengine/godot/pull/111679) "Add support for joypad motion sensors" (by Nintorch) was merged on 2026-01-27 with the **Godot 4.7** milestone.
  - It adds `Input.has_joy_motion_sensors`, `get_joy_accelerometer`, `get_joy_gyroscope`, `get_joy_gravity` and `set_joy_motion_sensors_enabled`/`is_joy_motion_sensors_enabled`.
  - It also adds calibration methods: `start_/stop_/clear_joy_motion_sensors_calibration`, `is_joy_motion_sensors_calibrating/calibrated`, and `get_/set_joy_motion_sensors_calibration`.
  - It was tested on Windows with a Switch Pro controller; DualSense was "expected compatible."
  - Steam Deck built-in sensors need Valve/SDL passthrough.
  - These methods are marked `experimental` in the class reference. [Input.xml](https://github.com/godotengine/godot/blob/master/doc/classes/Input.xml)
  - The related PR "Introduce new joypad features provided by SDL3" (sensors, calibration, simulated gravity). [PR #107967](https://github.com/godotengine/godot/pull/107967)
- **4.8.dev4** (2026-08-26) adds "gamepad gyro auto-calibration" ([GH-121487](https://github.com/godotengine/godot/pull/121487)). **4.8.dev5** (2026-09-10) adds `Input.get_device_orientation()`, which returns a "hardware-fused quaternion" ([GH-119142](https://github.com/godotengine/godot/pull/119142)). [4.8 dev4](https://godotengine.org/article/dev-snapshot-godot-4-8-dev-4/), [4.8 dev5](https://godotengine.org/article/dev-snapshot-godot-4-8-dev-5/)
- **SDL driver details** ([drivers/sdl/joypad_sdl.cpp](https://github.com/godotengine/godot/blob/master/drivers/sdl/joypad_sdl.cpp)):
  - It uses `SDL_HINT_JOYSTICK_THREAD=1`.
  - It reports rumble capability via `SDL_PROP_JOYSTICK_CAP_RUMBLE_BOOLEAN`.
  - It detects sensors with `SDL_GamepadHasSensor(SDL_SENSOR_ACCEL/GYRO)` and reads them with `SDL_GetGamepadSensorData`.
  - It exposes **`steam_input_index`** (from `SDL_GetGamepadSteamHandle`) and `xinput_index` in the joypad info dictionary.
- **Raw stick values:**
  - Stick axes are mapped linearly from SDL's int16 range: `((value - SDL_JOYSTICK_AXIS_MIN) / (MAX - MIN) - 0.5) * 2`. Triggers use `value / SDL_JOYSTICK_AXIS_MAX` (0-1). [joypad_sdl.cpp](https://github.com/godotengine/godot/blob/master/drivers/sdl/joypad_sdl.cpp)
  - `Input.get_joy_axis(device, axis)` "Returns the current value of the joypad axis."
  - Deadzones are applied only at the action level, e.g. `Input.get_vector(..., deadzone = -1.0)` uses action deadzones. [Input.xml](https://github.com/godotengine/godot/blob/master/doc/classes/Input.xml)
- **Rumble:** `Input.start_joy_vibration(device, weak_magnitude, strong_magnitude, duration)`. [Input.xml](https://github.com/godotengine/godot/blob/master/doc/classes/Input.xml)
- **Unfocused window:** `input_devices/joypads/ignore_joypad_on_unfocused_application` (default false) covers "joypad input (including motion sensors)." [ProjectSettings](https://github.com/godotengine/godot/blob/master/doc/classes/ProjectSettings.xml)
- **Windows threading:** gamepad input on Windows is handled by a separate system and is unaffected by the mouse message-pump change. [Godot blog](https://godotengine.org/article/fixing-high-polling-rate-mice-on-windows/)
- **Community add-ons:**
  - [MadladV/godot-gyro](https://github.com/MadladV/godot-gyro): SDL3 motion controls / gyro-aim demo for Godot 4.5.
  - [rafaelvaloto/Godot-Dualsense](https://github.com/rafaelvaloto/Godot-Dualsense) and [parrssee/godot-dualsense](https://github.com/parrssee/godot-dualsense): HID GDExtensions for adaptive triggers, lightbar, touchpad, gyro and battery. Their docs note that basic buttons, sticks and rumble already work through Godot's built-in SDL3 backend.

**Unity (Input System package docs and source on GitHub)**
- **Xbox:** "On Windows and Universal Windows Platform, Unity uses the XInput API" (`XInputController`). [gamepads-xbox.md](https://github.com/Unity-Technologies/InputSystem/blob/develop/Packages/com.unity.inputsystem/Documentation~/gamepads-xbox.md)
  - Xbox One trigger motors (impulse triggers) are only supported on UWP and Xbox. [supported-devices-reference.md](https://github.com/Unity-Technologies/InputSystem/blob/develop/Packages/com.unity.inputsystem/Documentation~/supported-devices-reference.md)
- **PlayStation:**
  - `DualSenseGamepadHID` is "Supported on macOS, Windows." [gamepads-p.md](https://github.com/Unity-Technologies/InputSystem/blob/develop/Packages/com.unity.inputsystem/Documentation~/gamepads-p.md)
  - The device table adds: "PS5 DualSense is supported on Windows, macOS, and Linux via USB HID. Linux support begins with Unity Editor 6000.4 ... setting motor rumble and light bar color when connected over **Bluetooth** is currently not supported." [supported-devices-reference.md](https://github.com/Unity-Technologies/InputSystem/blob/develop/Packages/com.unity.inputsystem/Documentation~/supported-devices-reference.md)
  - It also states: "**Unity doesn't support the gyro or accelerometer on PS4/PS5 controllers on platforms other than the PlayStation consoles.**" [supported-devices-reference.md](https://github.com/Unity-Technologies/InputSystem/blob/develop/Packages/com.unity.inputsystem/Documentation~/supported-devices-reference.md)
  - IOCTL limitation: only one IOCTL command (rumble or lightbar) can be serviced at a time, so rapid successive calls are dropped. [gamepads-p.md](https://github.com/Unity-Technologies/InputSystem/blob/develop/Packages/com.unity.inputsystem/Documentation~/gamepads-p.md)
- **DualSense changelog history:**
  - Added on Mac/Windows in 1.2.0 (2021).
  - DualSense Edge vibration and lightbar fixed on Windows in 1.8.2 (2024).
  - DualSense misdetected as DS4 fixed in 1.11.0 (2024-09).
  - `DualSenseHIDInputReport` made public.
  - [CHANGELOG](https://github.com/Unity-Technologies/InputSystem/blob/develop/Packages/com.unity.inputsystem/CHANGELOG.md)
- **Switch:** Joy-Cons are "not currently supported on Windows and Mac." [supported-devices-reference.md](https://github.com/Unity-Technologies/InputSystem/blob/develop/Packages/com.unity.inputsystem/Documentation~/supported-devices-reference.md)
- **Stick deadzones and raw values:**
  - `Gamepad.leftStick`/`rightStick` are declared with `processors = "stickDeadzone"`. [Gamepad.cs](https://github.com/Unity-Technologies/InputSystem/blob/develop/Packages/com.unity.inputsystem/InputSystem/Runtime/Devices/Gamepad.cs)
  - The defaults are `m_DefaultDeadzoneMin = 0.125f` and `m_DefaultDeadzoneMax = 0.925f`. [InputSettings.cs](https://github.com/Unity-Technologies/InputSystem/blob/develop/Packages/com.unity.inputsystem/InputSystem/Runtime/InputSettings.cs)
- **Gamepad polling:** the platform-set frequency is "guaranteed to be at least 60 Hz" and can be overridden with `InputSystem.pollingFrequency`. Windows XInput pads are polled explicitly. [gamepad-polling.md](https://github.com/Unity-Technologies/InputSystem/blob/develop/Packages/com.unity.inputsystem/Documentation~/gamepad-polling.md)
- **Workarounds for gyro on PC (search snippets):**
  - Community DualSense packages and JoyShockLibrary.
  - A 2025 thread reports being unable to extend the Input System's existing HIDs to add gyro.
  - [Unity Discussions: Can't extend Input System's existing HIDs (gamepad gyro)](https://discussions.unity.com/t/cant-extend-input-systems-existing-hids-trying-to-implement-gamepad-gyro-support/1637221), [Unity Discussions: Using DS4 Gyro on Unity](https://discussions.unity.com/t/using-ds4-gyro-on-unity/782500)
- **GameInput:** no "GameInput" entry appears anywhere in the Input System CHANGELOG up to 1.20.1. [CHANGELOG](https://github.com/Unity-Technologies/InputSystem/blob/develop/Packages/com.unity.inputsystem/CHANGELOG.md)

### Inferences
- **Godot covers Xbox, DualSense, gyro and Steam Input identification out of the box.**
  - It gets broad SDL3 controller coverage, and SDL's HIDAPI drivers typically provide DualSense gyro and rumble.
  - Its first-party gyro API arrived in 4.7, so a project on ≥ 4.7 gets gyro without plugins (still marked experimental).
- **Unity needs a plugin for DualSense gyro on PC.** Options include a native plugin such as JoyShockLibrary or SDL3 via P/Invoke.
- **Custom Apex-style response curves are easy in Godot**, since raw linear axis floats come straight from SDL. Note that SDL/HIDAPI itself may apply calibration to the values.
- **In Unity, you must remove or override the default `stickDeadzone` processor** (or read `ReadUnprocessedValue()`) to get raw stick values for custom curves.

### Gaps
- I did not verify Unity's `InputControl.ReadUnprocessedValue()` behaviour from source this session; the API name comes from my general knowledge.
- I found no information on whether Unity 6.x on Windows uses Microsoft GameInput for any device class.
- I found no Steam Input-specific documentation for either engine. Godot exposes `steam_input_index`; Unity's Steam Input behaviour (e.g. Steam remapping a DualSense to XInput) was not researched.
- No DualSense gyro tests on Godot 4.7 stable were found. The PR says DualSense is "expected compatible," and testing was on a Switch Pro.

---

## Q6. Aim trainers and competitive FPS games that discuss input handling in either engine

### Takeaway
**Aim Lab/Aimlabs, the biggest commercial aim trainer, is built on Unity.** At least two open-source Godot 4 aim trainers exist, and VANTA (Godot 4.7.2) explicitly advertises raw input with no smoothing or acceleration.

**Godot's own blog on 8 kHz mice is the most detailed engine-side discussion found.** No Unity-side equivalent public write-up was found beyond forum threads.

### Cited Findings
- **Aimlabs** (State Space Labs) is built with Unity and can be calibrated to match specific games' sensitivity. [Wikipedia: Aimlabs](https://en.wikipedia.org/wiki/Aimlabs)
  - Users discuss cm/360 and the precision of sensitivity decimals. [Steam discussion: Aim Labs cm/360 and sensitivity decimal precision](https://steamcommunity.com/app/714010/discussions/0/3109144584160623007/)
- **VANTA** (MIT, Godot 4.7.2) says: "One coefficient, one multiplication, nothing else. Frame-time compensation, smoothing and acceleration are not implemented."
  - It provides cm/360 conversion and calibration profiles.
  - It explicitly avoids publishing unmeasured latency claims.
  - [aimtrainer-code/aim-trainer](https://github.com/aimtrainer-code/aim-trainer)
- **SAIM**, "an intentionally minimal aim trainer software made in Godot," emphasises low latency. [JagersEgo/SAIM](https://github.com/JagersEgo/SAIM)
- **Godot Source-movement project:** a community project replicating Source-engine movement in Godot documents its input handling (`player_input.gd`). [DeepWiki: GodotSourceEngineMovement input handling](https://deepwiki.com/atlrvrse/GodotSourceEngineMovement/2.2-input-handling-(player_input.gd))
- **The high-polling-rate problem is industry-wide on Windows.** Godot notes that "thousands of games suffer from this issue too." [Godot blog](https://godotengine.org/article/fixing-high-polling-rate-mice-on-windows/)
  - Similar discussions exist for SDL ([#8756](https://github.com/libsdl-org/SDL/issues/8756)), osu! ([#27718](https://github.com/ppy/osu/discussions/27718)) and Bevy ([#12679](https://github.com/bevyengine/bevy/issues/12679)).

### Inferences
- **Precedent exists for both engines.** Unity has shipped the market-leading aim trainer, so it is clearly viable. Godot ≥ 4.7.2 now has public, engine-level evidence for the exact hardware the target audience uses (8 kHz mice, 480 Hz monitors), plus open-source aim trainers to learn from.

### Gaps
- I found no public post-mortem from Aimlabs or other Unity FPS developers on Unity's raw mouse handling, latency tuning or 8 kHz issues.
- I found no publicly documented competitive FPS shipped on Godot that discusses its input pipeline.
- I did not check KovaaK's (Unreal) or 3D Aim Trainer for their engine or input notes.
