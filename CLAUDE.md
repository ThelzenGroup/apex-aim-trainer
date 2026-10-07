# Apex Aim Lab

A Godot 4.7.2 project in statically typed GDScript. Development happens headlessly in a Linux container; the user plays Windows builds. `TESTING.md` is the user's test plan; `art/README.md` covers the Blender asset pipeline.

## Commands

```sh
tools/setup_godot.sh                                   # pinned editor + Windows templates
export PATH="$HOME/.local/share/godot-4.7.2:$PATH"
tools/run_tests.sh [filter]                            # import + all tests; fails on any script error
godot --headless --path . --export-release "Windows" build/windows/ApexAimLab.exe
```

- **Check the exported content.** Run this from outside the repo, so that the project folder isn't picked up instead of the build:
  `godot --headless --main-pack <repo>/build/windows/ApexAimLab.exe --quit-after 120 res://scenes/lab/load_lab.tscn`
- **Screenshots.** `--headless` never renders, so use Xvfb and the software GL renderer, then read the PNG frames:
  `xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-method gl_compatibility --rendering-driver opengl3 --write-movie /tmp/shot.png --fixed-fps 30 --quit-after 45 res://scenes/lab/load_lab.tscn`

## Godot 4 pitfalls

- Use Godot 4 syntax: `await` (not `yield`), `@export`, `CharacterBody3D`, `signal.connect(callable)`. A Godot 3 habit fails the parse step of `tools/run_tests.sh`.
- `Vector2` and `Vector3` hold 32-bit floats. Compare them with a tolerance, never with `==`.
- Calling an unknown method on a typed variable is a parse error. For duck typing, use `call()` and `get()`.
- `"" in some_string` is false. Use `is_empty()` or `contains()` instead.
- On glTF import, Godot strips a trailing `_Loop` from clip names (`Jump_Loop` becomes `Jump`). Every other looping clip must be set to loop in code (see `Bot.LOOPING_CLIPS`).
- Node3D `global_transform` only works once the node is in the tree.

## Project rules

- **Mouse look** reads `InputEventMouseMotion.screen_relative`, which carries raw counts while the mouse is captured.
  - Never use `relative`; the window's stretch factor scales it.
  - Turn the camera in `_input` or `_process`, never on the physics tick, and never put physics interpolation on the camera.
- **Engine-free math and rules** live in `src/core`, with tests in `tests/`: sensitivity, health and shields, weapon timing, scoring, ballistics, recoil, stick curves, aim assist and hit tests.
- **Scenarios** are data: a `ScenarioConfig` plus a `WeaponStats` resource in `data/`, run by `src/scenario/scenario.gd`.
  - Add new scenarios to `SCENARIOS` in `main_menu.gd`. Exported builds can't list `res://` folders reliably, because of `.remap` files.
  - `Scenario.force_trigger` and `ScenarioHistory.folder` exist for automated tests.
- **Hits** are analytic: `DummyHitboxes` plus `HitTest`, using the `HB_*` nodes and glTF extras from the bot models. Physics bodies are not used for hits.
- **Placeholder numbers** are marked as such in the code: bullet speed, recoil, bot speeds and aim-assist strength. Don't present them as Apex data.
- **Startup-only settings** (renderer, swapchain, frame queue) are written to `override.cfg` by `Settings.apply_startup_and_restart()`.
