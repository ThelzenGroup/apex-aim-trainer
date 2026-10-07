# Apex Aim Trainer

An aim trainer built around how Apex Legends plays: projectile weapons, recoil patterns, Titanfall-style target movement, high health pools, and hitboxes sized to Apex's legends.

The project currently holds **Apex Aim Lab**, a Godot 4.7.2 build for validating the engine choice. [TESTING.md](TESTING.md) explains how to get the Windows build and run the tests.

## Layout

| Path | Contents |
|---|---|
| `src/core/` | Engine-free math: Apex sensitivity and FOV, ballistics, recoil, stick curves, aim assist, ray-hitbox tests |
| `src/game/` | Look controller, strafing bots, analytic hitboxes, projectiles |
| `src/lab/`, `scenes/` | The test labs and main menu |
| `tests/` | Headless tests; run them with `tools/run_tests.sh` |
| `assets/models/` | Target dummies (`.glb`) with animations and bone-attached hitboxes |
| `art/` | Scripts and config that build those assets ([art/README.md](art/README.md)) |
| `reports/`, `research_notes/` | The Unity vs Godot engine research |
