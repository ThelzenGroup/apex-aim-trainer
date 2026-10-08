# Apex Aim Trainer

An aim trainer built around how Apex Legends plays: projectile weapons, recoil patterns, Titanfall-style target movement, high health pools, and hitboxes sized to Apex's legends.

The project currently holds **Apex Aim Lab**, a Godot 4.7.2 build with two parts:

- the engine-validation labs; [TESTING.md](TESTING.md) explains how to get the Windows build and run the tests
- four training scenarios with Season 30 weapons, against shielded, strafing targets, scored and saved per session

## Training

The menu's **Train** section holds the scenarios. In each one, ten targets with purple shields (100 shield plus 100 health) appear one at a time near where you are looking. They strafe at Apex's walking speed and sometimes crouch-spam or jump. Knock each one as fast as you can. **R** (or **X** on a controller) reloads.

| Scenario | Weapon | Range |
|---|---|---|
| Close-range tracking | R-99 | 8–15 m |
| Close-range tracking | Volt | 8–15 m |
| Mid-range tracking | R-301 | 20–35 m |
| Mid-range tracking | Flatline | 20–35 m |

Weapons carry level 3 magazines. The results screen shows average and fastest time to knock, time to first hit, accuracy, headshot rate and damage per magazine, and compares you with your previous runs.

**What is Apex data:**
- damage per hitbox (head, body, legs)
- fire rate and magazine sizes
- tactical and empty reload times
- bullet speed (except the Volt's)
- shields and health
- walking and crouch-walking speed
- sensitivity and FOV

The weapon numbers are from Season 30, and each file in `data/weapons/` names its source.

**What is still a placeholder:**
- recoil patterns and bullet drop
- the Volt's bullet speed
- how the bots time their direction changes and how fast they accelerate
- aim-assist strength

On screens wider than 21:9, **Limit view to 21:9** in the settings adds black bars at the sides. Use it if your Apex shows 21:9 on your monitor.

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
