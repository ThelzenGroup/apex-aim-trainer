# Apex Aim Trainer

An aim trainer built around how Apex Legends plays: projectile weapons, recoil patterns, Titanfall-style target movement, high health pools, and hitboxes sized to Apex's legends.

The project currently holds **Apex Aim Lab**, a Godot 4.7.2 build with two parts:

- the engine-validation labs; [TESTING.md](TESTING.md) explains how to get the Windows build and run the tests
- a first training scenario, close-range tracking against shielded, strafing targets, scored and saved per session

## Layout

| Path | Contents |
|---|---|
| `src/core/` | Engine-free rules and math: Apex sensitivity and FOV, health and shields, weapon timing, scoring, ballistics, recoil, stick curves, aim assist, ray-hitbox tests |
| `src/game/` | Look controller, strafing bots, analytic hitboxes, projectiles, feedback sounds |
| `src/scenario/`, `data/` | Training scenarios and their weapon and scenario settings (`.tres`) |
| `src/lab/`, `scenes/` | The test labs and main menu |
| `tests/` | Headless tests; run them with `tools/run_tests.sh` |
| `assets/models/` | Target dummies (`.glb`) with animations and bone-attached hitboxes |
| `art/` | Scripts and config that build those assets ([art/README.md](art/README.md)) |
| `reports/`, `research_notes/` | The Unity vs Godot engine research |
