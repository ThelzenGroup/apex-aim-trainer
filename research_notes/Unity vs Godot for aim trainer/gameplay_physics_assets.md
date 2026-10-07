# Unity vs Godot: FPS gameplay systems, physics, animation/hitboxes, glTF asset pipeline and rendering performance for an Apex-style aim trainer

Research date: 2026-10-07. Version baseline used throughout:
- **Godot**: latest stable is **4.7.2** (18 Aug 2026); 4.7 stable shipped 18 Jun 2026; 4.8 is at dev7 (29 Sep 2026) — [Godot download archive](https://godotengine.org/download/archive/). Godot 4.6 shipped in January 2026 — [Digital Production](https://digitalproduction.com/2026/01/28/godot-4-6-arrives-with-major-cg-friendly-updates/).
- **Unity**: LTS lines are **6000.3 (Unity 6.3 LTS, latest 6000.3.25f1, 24 Sep 2026)** and 6000.0 (Unity 6.0 LTS, 6000.0.84f1); newest "supported" (non-LTS) release is **6000.6.4f1 (Unity 6.6, 1 Oct 2026)**; 6000.7 is in beta and a 7000.0 alpha exists — [Unity release API](https://services.api.unity.com/unity/editor/release/v1/releases?limit=15&order=RELEASE_DATE_DESC), [Unity editor archive](https://unity.com/releases/editor/archive).
- **Unity glTFast** (`com.unity.cloud.gltfast`): latest released version **6.19.0 (19 May 2026)**; main branch is 6.20.1-pre.1; minimum Unity version raised to 6.0 LTS in 6.19.0 — [glTFast CHANGELOG](https://github.com/Unity-Technologies/com.unity.cloud.gltfast/blob/main/Packages/com.unity.cloud.gltfast/CHANGELOG.md), [package.json](https://github.com/Unity-Technologies/com.unity.cloud.gltfast/blob/main/Packages/com.unity.cloud.gltfast/package.json).

Method note: several pages were read directly from source (Godot's `modules/gltf` C++ at tag 4.7.2-stable, glTFast changelog, controller repos' source files) rather than from secondary summaries.

## 1. Character movement: mature open-source Source/Quake-style controllers, and CharacterController vs CharacterBody3D

### Takeaway
Both engines have usable open-source Source/Quake movement code, but neither has an Apex-specific one (slides, slide-jumps, tap-strafes are custom work in either engine). On the **Godot** side, the most current and best-documented option is **SUCC** (MIT, Godot 4.6+, last commit Aug 2026, built on `CharacterBody3D`). On the **Unity** side, the best-known option is **Olezen/UnitySourceMovement**, a port of Fragsurf (MIT, ~389 stars, last commit March 2020). It skips Unity's `CharacterController` and uses its own kinematic-Rigidbody, trace and depenetration code. Godot's `CharacterBody3D` exposes more of the needed tuning knobs (velocity, floor snap, slide iterations, motion modes) than Unity's capsule-only `CharacterController`.

### Cited Findings
**Unity – open-source Source-style controllers**
- **Olezen/UnitySourceMovement** describes itself as "Source engine-like movement in Unity, based on Fragsurf by cr4yz (Jake E.)". 389 stars, 58 forks, 25 open issues. — [GitHub](https://github.com/Olezen/UnitySourceMovement)
- Its README lists "strafe jumping, surfing, bunnyhopping, swimming, crouching and jump-crouching (optional), as well as sliding (optional)". The player can push rigidbodies. An experimental step offset was added on 15 Aug 2019. It is based on the original Fragsurf Character Controller (https://github.com/AwesomeX/Fragsurf-Character-Controller/). — [README](https://github.com/Olezen/UnitySourceMovement)
- License is MIT (© 2019 Ole Ellefsen Farner). The last commit on master is dated 20 Mar 2020. — [LICENSE](https://github.com/Olezen/UnitySourceMovement/blob/master/LICENSE) (commit date from a shallow clone of the repo)
- Implementation: `SurfCharacter.cs` adds a **kinematic Rigidbody** (`rb.isKinematic = true`) and a Box or Capsule collider. `SurfPhysics.cs` resolves collisions with `Physics.OverlapCapsuleNonAlloc` / `Physics.OverlapBoxNonAlloc` plus `Physics.ComputePenetration`, with its own `TraceUtil/Tracer.cs`. It does **not** use `CharacterController`. — [SurfPhysics.cs](https://github.com/Olezen/UnitySourceMovement/blob/master/Modified%20fragsurf/Movement/SurfPhysics.cs), [SurfCharacter.cs](https://github.com/Olezen/UnitySourceMovement/blob/master/Modified%20fragsurf/Movement/SurfCharacter.cs)
- **Fragsurf 2** is a full surf/bhop game built in Unity/C# with source code published "for reference, education, experimenting, and modding". "Movement stays true to Source", and it can load Source `.bsp` maps. — [Fragsurf-2 on GitHub](https://github.com/Fragsurf/Fragsurf-2)
- Smaller Unity ports:
  - **Kevin-Kwan/Lets-Surf** (23 stars): a "Source Engine physics and movement ported to Unity 3D" bhop/surf/air-strafe demo with a PlayerController. — [GitHub](https://github.com/Kevin-Kwan/Lets-Surf)
  - **rogerli2020/SourceEngineMovementUnity** (7 stars, created Jul 2025): "A minimalist extension to Unity's Character Controller that enables Source and Quake style movement, such as bhopping and surfing." — [GitHub](https://github.com/rogerli2020/SourceEngineMovementUnity)
  - **xezno/UnityMovement**: "Modular Source (2004) / Quake-like movement for Unity". — [GitHub](https://github.com/xezno/UnityMovement)

**Godot – open-source Source/Quake-style controllers**
- **SUCC (SurfsUp Character Controller)**, bearlikelion: "A Godot 4 character controller that feels like Quake, Half-Life, Quake 2, Half-Life 2 or SurfsUp, by swapping one resource file". It covers bunnyhopping, surfing, air strafing, momentum-preserving stair stepping and Source-style crouch jumping. It is written in statically typed GDScript, "ported from the original engine source", and is the controller from the Steam game *SurfsUp*. MIT license, Godot 4.6+ badge. — [README](https://github.com/bearlikelion/SUCC)
  - Presets: `default_config.tres` (SurfsUp 400 u/s), `goldsrc.tres`, `quake.tres`, `quake2.tres`, `source.tres` (HL2: gravity 600, jump impulse 160, walk 190). Includes a test gym with lanes for "stairs, slopes, bhop, crouch, surf and slide", a speedometer in metres and engine units, multiplayer authority checks, and no autoloads or singletons. — [README](https://github.com/bearlikelion/SUCC)
  - Implementation: `class_name SUCC extends CharacterBody3D`. It runs in `_physics_process`, uses `move_and_slide()` and `floor_snap_length = config.step_height + FLOOR_COL_MARGIN`, and adds a GDScript port of Source's `ClipVelocity` ("Source ClipVelocity (gamemovement.cpp): strip velocity heading into each contact"). — [succ.gd](https://github.com/bearlikelion/SUCC/blob/main/addons/SUCC/scripts/succ.gd)
  - Repo created Apr 2026, 39 stars, last commit 3 Aug 2026. Distributed via the Godot Asset Store. — [GitHub](https://github.com/bearlikelion/SUCC)
- **0xspig/3dCharacterController**: "Godot 3D Character Controller with BHops, air strafing, and old style kinematic movement". 78 stars, **archived**. Its asset-library listing targets Godot 3.2 (the obsolete Godot 3 API). — [GitHub](https://github.com/0xspig/3dCharacterController), [Asset Library](https://godotengine.org/asset-library/asset/edit/2441)
- **tf2_like_character_controller**: a TF2-style controller with air strafing, made for Godot 3.5 (old API). — [itch.io](https://profpatonildo.itch.io/tf2-like-character-controller-for-godot-engine)
- **moonwirer/bhop3d-CSharp**: "A source-like movement controller for Godot" (1 star). — [GitHub](https://github.com/moonwirer/bhop3d-CSharp)

**Unity `CharacterController` (Unity 6.3 docs)**
- It is a capsule collider "mainly used for third-person or first-person player control that does not make use of Rigidbody physics". Properties: Slope Limit, Step Offset, Skin Width (recommended at 10% of radius; low values "can cause the character to get stuck"), Min Move Distance, Center, Radius, Height, and Layer Overrides. — [Unity Manual: Character Controller](https://docs.unity3d.com/6000.3/Documentation/Manual/class-CharacterController.html)
- The manual's own rationale: "The traditional Doom-style first person controls are not physically realistic… use of Rigidbodies and physics to create this behavior is impractical… The solution is the specialized Character Controller." — [Unity Manual](https://docs.unity3d.com/6000.3/Documentation/Manual/class-CharacterController.html)
- API surface:
  - Methods: `Move`, `SimpleMove`.
  - Properties: `isGrounded`, `collisionFlags`, `velocity`, `skinWidth`, `slopeLimit`, `stepOffset`, `minMoveDistance`, `enableOverlapRecovery`, `detectCollisions`.
  - Message: `OnControllerColliderHit`.
  - [Unity Scripting API: CharacterController](https://docs.unity3d.com/6000.3/Documentation/ScriptReference/CharacterController.html)

**Godot `CharacterBody3D` (stable docs)**
- "Specialized class for physics bodies that are meant to be user-controlled. They are not affected by physics at all, but they affect other physics bodies in their path." — [Godot docs: CharacterBody3D](https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html)
- Properties relevant to Source-style movement: `floor_constant_speed`, `floor_max_angle`, `floor_snap_length`, `floor_stop_on_slope`, `max_slides`, `motion_mode` (`MOTION_MODE_GROUNDED` / `MOTION_MODE_FLOATING`), `safe_margin`, `wall_min_slide_angle`, plus platform velocity handling (`platform_on_leave`, `get_platform_velocity()`). Methods include `move_and_slide()` and `apply_floor_snap()`. — [Godot docs: CharacterBody3D](https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html)

### Inferences
- **Apex-specific mechanics need custom code in both engines.** Source air-acceleration and friction (`PM_Accelerate`, `PM_AirAccelerate`, `PM_Friction`) are covered by existing controllers. Slides with speed boost and decay, slide-jumps, crouch-spam and tap-strafes (a high air-accel/strafe-input exploit) are not. SUCC's preset system (one `.tres` resource per feel) is a convenient place to add an "apex" preset, and its test gym can be extended.
- **The Unity side is older.** The Fragsurf-derived code dates from 2019–2020, before Unity 6, but uses only stable core APIs (`ComputePenetration`, `Overlap*NonAlloc`), so it is likely to port with minor changes. SUCC was written for Godot 4.6+ and is maintained.
- For bots, both engines can reuse the player movement code driven by AI input. With a custom kinematic controller (Fragsurf style) in Unity, each bot pays for its own overlap and penetration queries. In Godot, each bot pays for a `move_and_slide()` (up to `max_slides` iterations). At "many bots", a simplified bot mover (e.g., ground-plane-only on a flat arena) may be preferable in either engine.
- Unity's `CharacterController` supports only a capsule and offers no friction or acceleration model (you supply the motion vector). Godot's `CharacterBody3D` accepts any collision shape and keeps a `velocity` property. Source movement does its own velocity integration in both cases, so the difference matters mostly for floor snapping and stair stepping, where Godot offers more built-in parameters.

### Gaps
- I did not test any controller's feel or accuracy against real Source or Apex behaviour. SUCC links an "engine-accuracy" page ([docs](https://bearlikelion.github.io/SUCC/explanation/engine-accuracy/)), which I did not read.
- I found no open-source Apex-specific (slide/tap-strafe) movement implementation for either engine.
- The current activity and license of Fragsurf-2 were not verified (the repo page was found only via search).

## 2. Physics engines: defaults, ray/shape-cast queries, CCD for fast projectiles, tick rate and interpolation

### Takeaway
- **Unity** 6.x's built-in 3D physics is still an NVIDIA PhysX integration. It offers batched, job-parallel `RaycastCommand`/`SpherecastCommand`, three CCD modes and flexible simulation timing (`SimulationMode.FixedUpdate/Update/Script`).
- **Godot** integrated Jolt as an experimental option in **4.4**, made it the default for **new** 3D projects in **4.6** (experimental label removed), and 4.7.x continues this. Godot's queries go through `PhysicsDirectSpaceState3D` (`intersect_ray` etc.), which is only safe to call inside `_physics_process`.
- 3D physics interpolation arrived in Godot **4.4** and was moved to the SceneTree in **4.5**.
- For non-hitscan bullets, the usual approach is a per-tick segment ray/shape cast from the previous to the current bullet position. That is inherently continuous and makes rigid-body CCD unnecessary in either engine.

### Cited Findings
**Unity**
- "Unity's default built-in 3D physics system is an integration of the Nvidia PhysX engine." The wording is the same in the Unity 6.3 LTS and Unity 6.6 manuals. — [Unity 6.3 Manual: Built-in 3D physics](https://docs.unity3d.com/6000.3/Documentation/Manual/PhysicsOverview.html), [Unity 6.6 Manual](https://docs.unity3d.com/6000.6/Documentation/Manual/PhysicsOverview.html)
- Unity 6.3 added **low-level 2D** physics APIs (Box2D v3, `UnityEngine.LowLevelPhysics2D`). No equivalent 3D physics change is listed in the 6.3 or 6.6 "What's New" pages. — [What's New in Unity 6.3](https://docs.unity3d.com/6000.3/Documentation/Manual/WhatsNewUnity63.html), [What's New in Unity 6.6](https://docs.unity3d.com/6000.6/Documentation/Manual/WhatsNewUnity66.html)
- **RaycastCommand**: "Struct used to set up a raycast command to be performed asynchronously during a job… they will be performed asynchronously and in parallel to each other. The results for a command at index N… are stored at index N * maxHits in the results buffer." — [Unity Scripting API: RaycastCommand](https://docs.unity3d.com/6000.3/Documentation/ScriptReference/RaycastCommand.html)
- **SpherecastCommand** is the same batched pattern for sphere casts, with `QueryParameters` to control trigger and back-face hits. Only `BatchQuery.ExecuteSpherecastJob` is logged in the profiler. — [Unity Scripting API: SpherecastCommand](https://docs.unity3d.com/6000.3/Documentation/ScriptReference/SpherecastCommand.html)
- **CCD**: CCD modes "use predictive algorithms to calculate collisions that happen between physics timesteps".
  - "CCD is supported for Box, Sphere and Capsule colliders. It is intended as a safety net… it does not always deliver physically accurate collision results."
  - There are two algorithms behind three modes: Continuous Speculative (speculative), and Continuous / Continuous Dynamic (sweep-based).
  - [Unity Manual: CCD](https://docs.unity3d.com/6000.3/Documentation/Manual/ContinuousCollisionDetection.html)
- **Simulation timing**: `Physics.simulationMode` is a `SimulationMode` with these values (FixedUpdate is the default):
  - `FixedUpdate`: simulate immediately after `MonoBehaviour.FixedUpdate`.
  - `Update`: simulate immediately after `MonoBehaviour.Update`.
  - `Script`: simulate manually via `Physics.Simulate`.
  - [Unity Scripting API: SimulationMode](https://docs.unity3d.com/6000.3/Documentation/ScriptReference/SimulationMode.html), [Physics.simulationMode](https://docs.unity3d.com/6000.3/Documentation/ScriptReference/Physics-simulationMode.html)
- `Time.fixedDeltaTime` is "The interval in seconds of in-game time at which physics and other fixed frame rate updates… are performed". Unity quantizes the value "to align with the internal high-resolution grid". — [Unity Scripting API: Time.fixedDeltaTime](https://docs.unity3d.com/6000.3/Documentation/ScriptReference/Time-fixedDeltaTime.html)
- **Rigidbody interpolation**: the `Interpolate` / `Extrapolate` options on a Rigidbody (None by default) smooth jitter when the physics rate is below the frame rate. Interpolate "has a time lag of one physics update". When enabled, "the physics system takes control of the Rigidbody's transform", so direct transform changes need `Physics.SyncTransforms`. — [Unity Manual: Apply interpolation to a Rigidbody](https://docs.unity3d.com/6000.3/Documentation/Manual/rigidbody-interpolation.html)

**Godot**
- **4.4**: "The Jolt extension has been used as the de facto physics engine by many Godot developers since its inception in late 2022, so it only made sense to integrate it into the engine directly… you have to enable this alternative to Godot Physics in the project settings." It was labelled experimental. — [Godot 4.4 release page](https://godotengine.org/releases/4.4/)
- **4.6**: "Remember when we integrated Jolt Physics as an experimental option in 4.4? … it has proven itself ready for production… we're confident enough to remove the experimental label and make Jolt the default physics engine for all new 3D projects. Existing projects aren't affected." — [Godot 4.6 release page](https://godotengine.org/releases/4.6/)
- **Project setting nuance**: `physics/3d/physics_engine = "DEFAULT"`, and "DEFAULT is currently equivalent to GodotPhysics3D, but may change in future releases… Jolt Physics is the default for projects created starting in Godot 4.6". In other words, new projects get Jolt written explicitly into `project.godot`, while "DEFAULT" still means GodotPhysics3D. — [Godot docs: ProjectSettings](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html)
- **Jolt docs**:
  - Jolt was "added as an alternative… in 4.4"; "By default, new projects will use it". The GDExtension version is now in maintenance mode; "the only thing missing at this point is related joints".
  - Documented differences:
    - Unsupported soft-limit joint properties.
    - Collision margins ("convex radius") that "shrink the shape, and then the shell is applied". They are controlled by *Physics > Jolt Physics 3D > Collisions > Collision Margin Fraction* and "can sometimes result in odd collision normals when performing shape queries".
    - Baumgarte stabilization that is position-only.
    - Ghost-collision mitigation (active edge detection, enhanced internal edge removal).
    - `face_index` from `intersect_ray()`/`RayCast3D` is always -1 unless *Queries > Enable Ray Cast Face Index* is set (about 25% more memory for ConcavePolygonShape3D).
    - Kinematic RigidBody3D contacts against static bodies are opt-in.
  - [Godot docs: Using Jolt Physics](https://docs.godotengine.org/en/stable/tutorials/physics/using_jolt_physics.html)
- 4.6 also added automatic generation of a matching `CollisionShape3D` (box, sphere, cylinder, capsule) from primitive meshes via the Mesh menu. — [Godot 4.6 release page](https://godotengine.org/releases/4.6/)
- **Ray/shape queries**: "Godot physics runs by default in the same thread as game logic, but may be set to run on a separate thread… the only time accessing space is safe is during the `Node._physics_process()` callback." Queries go through `get_world_3d().direct_space_state` and `intersect_ray(query)`. — [Godot docs: Ray-casting](https://docs.godotengine.org/en/stable/tutorials/physics/ray-casting.html)
- **CCD**: `RigidBody3D.continuous_cd` (default false): "Continuous collision detection tries to predict where a moving body will collide… misses fewer impacts by small, fast-moving objects." — [Godot docs: RigidBody3D](https://docs.godotengine.org/en/stable/classes/class_rigidbody3d.html)
- **Tick rate**:
  - `physics/common/physics_ticks_per_second = 60` (default). "CPU usage scales approximately with the physics tick rate". It is read only at startup; at runtime use `Engine.physics_ticks_per_second`.
  - `physics/common/max_physics_steps_per_frame = 8`.
  - `physics/common/physics_interpolation = false` (default).
  - [Godot docs: ProjectSettings](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html)
- **Interpolation history**:
  - 4.3 introduced 2D physics interpolation. — [Godot 4.3 release page](https://godotengine.org/releases/4.3/)
  - 4.4 added 3D physics interpolation: "creates additional frames between the last physics position and the current one… especially on displays with a high refresh rate". — [Godot 4.4 release page](https://godotengine.org/releases/4.4/)
  - 4.5 moved 3D interpolation from RenderingServer to SceneTree, because "it proved impossible to query the RenderingServer for interpolated transforms", while keeping the user API. — [Godot 4.5 release page](https://godotengine.org/releases/4.5/)
- **Interpolation guidance**: move objects in `_physics_process()`, and call `Node.reset_physics_interpolation` after teleporting to prevent "streaking". — [Godot docs: Physics interpolation quick start](https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/physics_interpolation_quick_start_guide.html)

### Inferences
- **Projectiles with travel time and drop**: simulate each bullet analytically (position plus velocity with gravity) on a fixed tick, and cast a segment (or thin sphere) from the previous to the next position against a hitbox-only layer. This needs no rigid bodies and no CCD, and is equally accurate in both engines.
  - Unity can batch all live bullets into one `RaycastCommand`/`SpherecastCommand` job per tick, a structural advantage for "many projectiles".
  - Godot has no batched query API in the docs reviewed. Each `intersect_ray` is an individual call, cheap from GDExtension/C# but adding per-call overhead from GDScript.
- **Jolt shape-query caveat**: Jolt's collision-margin behaviour ("odd collision normals when performing shape queries") matters if bullets are thick sphere casts against small hitboxes. Per the docs, the margin shrinks the shape and then adds a shell, so the overall size stays the same but **box edges and corners get rounded**. Sphere and capsule hitboxes are naturally round, so they should be little affected (unverified; test needed). For box hitboxes (e.g., Apex-style torso boxes), consider lowering *Collision Margin Fraction*.
- **Tick rate at 240–500 FPS**: either run the gameplay tick at 60–128 Hz with interpolation (Godot 4.4+ built-in; Unity per-Rigidbody, while CharacterController movement in `Update` needs no interpolation), or simulate movement per rendered frame.
  - Godot: raising `physics_ticks_per_second` to 240+ is possible, but CPU cost scales roughly linearly.
  - Unity: `SimulationMode.Script` plus `Physics.Simulate` gives explicit control of when queries see updated colliders.

### Gaps
- I found no primary source stating the exact PhysX SDK version in Unity 6.x. A secondary search snippet says Unity upgraded "to PhysX 4.1 from PhysX 3.4" ([Unity blog author page](https://blog.unity.com/pt/author/cap-anthony)), but I could not verify the date or the version that applies today.
- I found no published benchmark comparing raycast throughput (rays/ms) of Unity PhysX vs Godot Jolt for thousands of queries against hundreds of moving kinematic colliders.
- The Jolt version bundled in Godot 4.7.2 was not checked.

## 3. Animation and skinned-mesh hitboxes: attaching colliders to animated bones; accuracy and performance pitfalls

### Takeaway
- **Unity**: hitboxes are ordinary primitive colliders (Box/Sphere/Capsule) on child GameObjects of bone transforms; the Animator writes bone transforms and the colliders follow. The main pitfalls are:
  - **transform-to-physics sync timing** (call `Physics.SyncTransforms` after animation if querying in Update/LateUpdate);
  - **Animator culling modes** that stop updating transforms when the renderer is not visible.
- **Godot**: a `BoneAttachment3D` (child of `Skeleton3D`) copies a bone's global transform, and `Area3D`/`StaticBody3D` + `CollisionShape3D` nodes are placed under it. `PhysicalBone3D` under `PhysicalBoneSimulator3D` (4.3+) is the ragdoll path. The pitfall is update order: `Skeleton3D.modifier_callback_mode_process` defaults to *idle* (process frame), not physics.
- Godot's skeleton tooling has expanded fast:
  - `SkeletonModifier3D` in 4.3;
  - `SpringBoneSimulator3D` in 4.4;
  - `BoneConstraint3D` / `AimModifier3D` / `CopyTransformModifier3D` in 4.5;
  - a new IK framework in 4.6.

### Cited Findings
**Godot**
- `BoneAttachment3D` "selects a bone in a Skeleton3D and attaches to it… will either dynamically copy or override the 3D transform of the selected bone".
  - Properties: `bone_idx`, `bone_name`, `override_pose` (default false), `use_external_skeleton`, `external_skeleton`.
  - It also has a `physics_interpolation_mode` (inherited from Node).
  - [Godot docs: BoneAttachment3D](https://docs.godotengine.org/en/stable/classes/class_boneattachment3d.html)
- `Skeleton3D.modifier_callback_mode_process` defaults to **1 = MODIFIER_CALLBACK_MODE_PROCESS_IDLE**. The other values are `..._PHYSICS = 0` ("process modification during physics frames") and `..._MANUAL = 2` ("Use advance() to process the modification manually"). — [Godot docs: Skeleton3D](https://docs.godotengine.org/en/stable/classes/class_skeleton3d.html)
- `PhysicalBone3D` "is a physics body that can be used to make bones in a Skeleton3D react to physics". "In order to detect physical bones with raycasts, the SkeletonModifier3D.active property of the parent PhysicalBoneSimulator3D must be true and the Skeleton3D's bone must be assigned to PhysicalBone3D correctly." — [Godot docs: PhysicalBone3D](https://docs.godotengine.org/en/stable/classes/class_physicalbone3d.html)
- `PhysicalBoneSimulator3D`: "Node that can be the parent of PhysicalBone3D and can apply the simulation results to Skeleton3D." — [Godot docs: PhysicalBoneSimulator3D](https://docs.godotengine.org/en/stable/classes/class_physicalbonesimulator3d.html). A ragdoll demo exists in the official demo projects ([3d/ragdoll_physics](https://github.com/godotengine/godot-demo-projects/tree/master/3d/ragdoll_physics)).
- Release history:
  - 4.3: new abstract `SkeletonModifier3D` node to move bones from script, plus "new skeletal animation import options" for retargeting. — [Godot 4.3 release page](https://godotengine.org/releases/4.3/)
  - 4.4: `SpringBoneSimulator3D` (jiggle physics) built on `SkeletonModifier3D`. — [Godot 4.4 release page](https://godotengine.org/releases/4.4/)
  - 4.5: `BoneConstraint3D`, `AimModifier3D`, `CopyTransformModifier3D`, `ConvertTransformModifier3D`. — [Godot 4.5 release page](https://godotengine.org/releases/4.5/)
  - 4.6: "Brand new IK framework": `IKModifier3D` with `TwoBoneIK3D`, `SplineIK3D`, `FABRIK3D`, `CCDIK3D`, `JacobianIK3D`. — [Godot 4.6 release page](https://godotengine.org/releases/4.6/)

**Unity**
- `Physics.SyncTransforms`: "When a Transform component changes, any Rigidbody or Collider on that Transform or its children may need to be repositioned… Use this function to flush those changes to the physics engine manually."
  - "Don't use it in FixedUpdate() — Unity already syncs transforms automatically before each physics step."
  - "Do use it after Transform changes in Update()/LateUpdate() if you're immediately performing a physics query."
  - "Don't overuse it — it's expensive if called every frame unnecessarily."
  - [Unity Scripting API: Physics.SyncTransforms](https://docs.unity3d.com/6000.3/Documentation/ScriptReference/Physics.SyncTransforms.html)
- `AnimatorCullingMode` values:
  - `AlwaysAnimate`: "Object is animated even when offscreen."
  - `CullUpdateTransforms`: "Retarget, IK and write of Transforms are disabled when renderers are not visible."
  - `CullCompletely`: "Animation is completely disabled when renderers are not visible."
  - [Unity Scripting API: AnimatorCullingMode](https://docs.unity3d.com/6000.3/Documentation/ScriptReference/AnimatorCullingMode.html)
- Unity 6.3: "the overall time spent evaluating Legacy Animation has decreased by up to 30%" (relevant because glTFast's runtime path uses the legacy `Animation` component). It also added `Animator.ResetControllerState` for pooling Animators. — [What's New in Unity 6.3](https://docs.unity3d.com/6000.3/Documentation/Manual/WhatsNewUnity63.html)
- Unity 6.6: "The Animation Rigging package is now a core package." — [What's New in Unity 6.6](https://docs.unity3d.com/6000.6/Documentation/Manual/WhatsNewUnity66.html)

### Inferences
- **Hit precision depends on update order more than on the engine.**
  - Unity: the Animator updates bones after `Update`, while `FixedUpdate` physics sees transforms synced at the next step. Bullets tested in `FixedUpdate` therefore hit last frame's pose, and bullets tested in `LateUpdate` need `Physics.SyncTransforms()` first.
  - Godot: set the bots' `AnimationPlayer`/`AnimationTree` and `Skeleton3D` to physics-process mode, so the `BoneAttachment3D` → collider transforms are current when `_physics_process` runs the bullet queries. (`AnimationMixer.callback_mode_process` is the corresponding animation-side property; I did not re-verify its exact name in this session.)
- **Culling must be disabled for bots.** Use `AlwaysAnimate` in Unity, or bots behind the player or off-screen will have frozen hitboxes. Godot has no equivalent automatic culling of skeleton updates in the docs reviewed.
- **Cost at scale**: 17 hitboxes × N bots means 17N collider transform updates per tick in either engine. If profiling shows this is costly, the hitbox data (shape, radius, height, size per bone) is already in the JSON sidecar. Engine-agnostic analytic ray-vs-capsule/sphere/OBB tests against bone matrices (`Skeleton3D.get_bone_global_pose()` in Godot; bone `Transform.localToWorldMatrix` in Unity) would remove physics-engine overhead and Jolt margin effects entirely.
- `PhysicalBone3D`/ragdoll is not needed for hit detection. It only matters if bots ragdoll on death.

### Gaps
- I found no benchmark of `BoneAttachment3D` count vs frame time, or of Unity colliders-on-bones sync cost, for hundreds of animated characters.
- I did not verify whether Godot's `BoneAttachment3D` updates its transform on the same notification as skeleton pose updates when the skeleton runs in physics mode (exact frame-lag behaviour). This needs a test.

## 4. glTF import: Unity glTFast vs Godot native importer (extras, joint-parented nodes, animations, import scripts, retargeting)

### Takeaway
Godot is clearly ahead for this specific asset.

**Godot (4.4+)**
- The native importer automatically stores glTF `extras` as node metadata (`get_meta("extras")`) on nodes, meshes and materials (PR #86183), and per-bone extras as Skeleton3D bone meta (PR #87150).
- A non-joint node parented to a joint, such as the HB_ hitbox meshes, becomes a child of an auto-generated `BoneAttachment3D` under the `Skeleton3D`.
- `EditorScenePostImport` scripts can convert these into collision shapes at import time.

**Unity**
- Unity has no built-in glTF importer; the official path is the **glTFast** package. It reproduces the node hierarchy and skins, but **does not expose extras by default**. Reading them requires the glTFast Add-on API with the Newtonsoft JSON variant (`GLTFast.Newtonsoft.GltfImport`, `ImportAddon`, `GameObjectInstantiator.NodeCreated`).
- glTFast's Mecanim animation import is only partial: "won't be assigned and cannot be played back without further work".
- There is no Humanoid Avatar from glTF, so `AvatarBuilder.BuildHumanAvatar` would be needed for Humanoid retargeting.

### Cited Findings
**Godot**
- PR #86183, "Import/export GLTF extras to `node->meta` and back", merged 30 Aug 2024, milestone 4.4. — [godotengine/godot#86183](https://github.com/godotengine/godot/pull/86183)
- PR #87150, "Add per-bone meta to Skeleton3D", merged 17 Sep 2024, milestone 4.4. — [godotengine/godot#87150](https://github.com/godotengine/godot/pull/87150)
- PR #87584, "Retain meta data set on importer nodes", milestone 4.3. — [godotengine/godot#87584](https://github.com/godotengine/godot/pull/87584)
- Source check: `_attach_extras_to_meta()` (`p_node->set_meta("extras", p_extras)`) is absent in `gltf_document.cpp` at 4.2-stable and 4.3-stable and present at 4.4-stable and 4.7.2-stable. It is applied to nodes, meshes and materials. — [gltf_document.cpp @ 4.7.2-stable](https://github.com/godotengine/godot/blob/4.7.2-stable/modules/gltf/gltf_document.cpp), [@ 4.3-stable](https://github.com/godotengine/godot/blob/4.3-stable/modules/gltf/gltf_document.cpp), [@ 4.4-stable](https://github.com/godotengine/godot/blob/4.4-stable/modules/gltf/gltf_document.cpp)
- Generated scene nodes receive the glTF node's metadata via `current_node->merge_meta_from(*gltf_node)`. — [gltf_document.cpp @ 4.7.2-stable](https://github.com/godotengine/godot/blob/4.7.2-stable/modules/gltf/gltf_document.cpp)
- Joint extras: "Store bone-level GLTF extras in skeleton per bone meta" → `skeleton->set_bone_meta(bone_index, "extras", ...)`. — [skin_tool.cpp @ 4.7.2-stable](https://github.com/godotengine/godot/blob/4.7.2-stable/modules/gltf/skin_tool.cpp)
- **Joint-parented non-joint nodes**: `_attach_node_to_skeleton()` contains the comments "If we have a node in need of attaching, we need a BoneAttachment3D. This happens when a node in Blender has Relations -> Parent set to a bone" and "If the parent is a Skeleton3D, we need to make a BoneAttachment3D".
  - `_generate_bone_attachment()` creates a `BoneAttachment3D` named after the bone, adds it as a child of the `Skeleton3D`, sets `bone_name`, and merges the joint node's meta.
  - Skinned meshes "should be attached directly to the skeleton without a BoneAttachment3D".
  - A `_generate_bone_attachment_compat_4pt4` path also exists, indicating that attachment behaviour changed after 4.4 and is kept for compatibility.
  - [gltf_document.cpp @ 4.7.2-stable](https://github.com/godotengine/godot/blob/4.7.2-stable/modules/gltf/gltf_document.cpp)
- **Import scripts**: the import dialog's *Import Script > Path* runs a script extending `EditorScenePostImport` with `_post_import(scene)` after import. Imported Skeleton3D/skin structure is also documented there. — [Godot docs: Import configuration](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html)
- The same page (Blender `.blend` import options) says "Custom Properties: If checked, imports custom properties from Blender as glTF extras. This data can then be used from an editor plugin that uses `GLTFDocument.register_gltf_document_extension()`". This wording predates the automatic extras→meta import and is somewhat outdated. — [Godot docs: Import configuration](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html)
- **Name suffixes**: `-col`, `-convcol`, `-colonly`, `-convcolonly` create collision shapes from meshes, and `-noimp` removes nodes. They can be disabled with `nodes/use_node_type_suffixes` or `nodes/use_name_suffixes`. — [Godot docs: Node type customization using name suffixes](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/node_type_customization.html)
- **Animation**: 4.4 added a glTF extension (KHR_animation_pointer / glTF Object Model) so imported animations can target arbitrary properties. Previously glTF imports could only animate position, rotation, scale and blend-shape weights. — [Godot 4.4 release page](https://godotengine.org/releases/4.4/)
- **Retargeting**: the import dialog's "Retarget" section uses a `BoneMap` and `SkeletonProfile`. "Godot has a preset called SkeletonProfileHumanoid for humanoid models", with auto-mapping, a "Unique Node" option and a "Rest Fixer". — [Godot docs: Retargeting 3D Skeletons](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html). Additional retargeting import options were added in 4.3. — [Godot 4.3 release page](https://godotengine.org/releases/4.3/)
- Community confirmation: Blender custom properties appear under mesh properties as `metadata/extras` and are read with `get_meta()`. — [Godot Forum](https://forum.godotengine.org/t/gltf-import-how-does-one-get-metadata-extras/105711)

**Unity glTFast**
- Editor import: glTF/GLB files in `Assets` are imported "to native Unity prefabs" via Unity's `ScriptedImporter`. glTFast registers itself as the default importer for `.gltf`/`.glb`; scripting define `GLTFAST_FORCE_DEFAULT_IMPORTER_OFF` turns that off. — [glTFast docs: Editor Import](https://docs.unity3d.com/Packages/com.unity.cloud.gltfast@6.9/manual/ImportEditor.html)
- Features table (6.9.1 docs):
  - Supported: node hierarchies; Joints and Weights (up to 4 per vertex); Skins; Morph targets.
  - Animation "via legacy Animation System ✅".
  - Animation "via Mecanim ☑️" with the footnote "Animation clips can be imported Mecanim compatible, but they won't be assigned and cannot be played back without further work".
  - `KHR_animation_pointer` is listed with no import support mark.
  - [glTFast docs: Features](https://docs.unity3d.com/Packages/com.unity.cloud.gltfast@6.9/manual/features.html)
- **Extras**: "Optional extras and extensions object properties are supported. glTFast uses Newtonsoft JSON parser to access these additional properties. See glTFast Add-on API for an example." — [glTFast docs: Features](https://docs.unity3d.com/Packages/com.unity.cloud.gltfast@6.9/manual/features.html)
- The documented way to read node extras:
  1. Add `com.unity.nuget.newtonsoft-json`.
  2. Register an `ImportAddon<T>` via `ImportAddonRegistry.RegisterImportAddon`.
  3. Use `GLTFast.Newtonsoft.GltfImport`.
  4. Hook `GameObjectInstantiator.NodeCreated`.
  5. Read `(gltf.Nodes[i] as GLTFast.Newtonsoft.Schema.Node).extras` and add your own component.
  - The example is a **runtime** import (`gltfImport.Load(Uri)` → `InstantiateMainSceneAsync`).
  - [glTFast docs: Use glTFast Add-on API (custom extras)](https://docs.unity3d.com/Packages/com.unity.cloud.gltfast@6.9/manual/UseCaseCustomExtras.html)
- Changelog items relevant to this rig:
  - "Mecanim (non-legacy) is now the default for importing animation clips at design-time".
  - "An Animator component is added to the scene root GameObject when Mecanim is used".
  - "SkinnedMeshRenderer's rootBone property is now set to the lowest common ancestor node of all joints".
  - "Re-normalize bone weights".
  - [glTFast CHANGELOG](https://github.com/Unity-Technologies/com.unity.cloud.gltfast/blob/main/Packages/com.unity.cloud.gltfast/CHANGELOG.md)
- 6.19.0 (2026-05-19):
  - Added add-on interfaces to "Import glTF animations to custom animation systems" (`IAnimationProcessor`, `IAnimationProcessorFactory`), plus `INodeHierarchyInfo` and `IGltfAccessors`.
  - Made animation-curve import "much faster".
  - Minimum Unity raised to 6.0 LTS.
  - 6.18.0 added `IPostJsonDeserialization`.
  - The unreleased changelog says Playables support was removed from the animation feature list.
  - [glTFast CHANGELOG](https://github.com/Unity-Technologies/com.unity.cloud.gltfast/blob/main/Packages/com.unity.cloud.gltfast/CHANGELOG.md)
- Humanoid retargeting in Unity needs an Avatar. `AvatarBuilder.BuildHumanAvatar` creates "a humanoid avatar… using the supplied HumanDescription object which specifies the muscle space range limits and retargeting parameters". — [Unity Scripting API: AvatarBuilder.BuildHumanAvatar](https://docs.unity3d.com/6000.3/Documentation/ScriptReference/AvatarBuilder.BuildHumanAvatar.html)

### Inferences
- **Godot pipeline for this asset (fully native)**:
  - The `.glb` imports with a `Skeleton3D`, a skinned `MeshInstance3D`, an `AnimationPlayer` with 17 clips, and 17 `BoneAttachment3D` nodes, each holding an `HB_<region>_<part>` node whose `get_meta("extras")` contains `hitbox_region`, `hitbox_shape`, `radius`/`height`/`size`.
  - A ~30-line `EditorScenePostImport` script can replace each HB_ mesh with `Area3D` + `CollisionShape3D` (`CapsuleShape3D`/`SphereShape3D`/`BoxShape3D`) built from those extras, and set collision layers.
  - Caveat: if two HB_ nodes share a bone, the importer reuses one `BoneAttachment3D` per bone (based on `scene_nodes` caching). Behaviour should be confirmed on the real file.
  - Caveat from source reading: a *plain joint's* extras are also merged into the `Skeleton3D` node's own meta, so joint-level extras collide on the Skeleton3D node. This is irrelevant here because hitbox extras are on non-joint nodes.
- **Unity pipeline**:
  - glTFast's editor import should yield bone GameObjects with HB_ child GameObjects, because it instantiates every glTF node in hierarchy (not verified on this file).
  - Extras are not attached automatically. Easiest options:
    - (a) an editor script/AssetPostprocessor that reads the existing **JSON sidecar** and adds `CapsuleCollider`/`SphereCollider`/`BoxCollider` to the matching HB_ GameObjects by name;
    - (b) a glTFast import add-on (documented only for runtime import).
  - Animation: either accept legacy `Animation` components, or wire the imported Mecanim clips into an AnimatorController manually.
  - Alternative: re-export the bots as FBX from Blender to use Unity's native ModelImporter (Humanoid/Generic rigs, Avatar). Custom-property transport via FBX was not researched.
- **Retargeting is probably unnecessary**: all 17 clips are authored on the same 65-bone rig. It only matters if third-party humanoid animations are added later; there, Godot's `SkeletonProfileHumanoid` works directly on glTF, while Unity's Humanoid path is FBX-centric.

### Gaps
- I did not confirm whether glTFast import add-ons (`ImportAddon`) run during **Editor (design-time)** `ScriptedImporter` imports, or only at runtime.
- I did not test the actual `.glb` (65 bones, 17 clips, 17 HB_ nodes) in either engine. Behaviour with multiple attachments per bone and transform/scale baking of hitbox nodes needs a smoke test.
- The alternative Unity importer UnityGLTF (Khronos) and whether it maps extras to components was not researched.

## 5. Rendering performance for simple scenes at very high FPS (240–500 FPS)

### Takeaway
I found no credible, recent head-to-head frame-time benchmark (Unity 6.x URP vs Godot 4.6/4.7) for simple 3D scenes at hundreds of FPS. This is a gap that a quick in-house prototype benchmark should fill.

From documentation:
- **Godot** offers **Forward+** (desktop default), **Mobile** ("Fewer features, but renders simple scenes faster") and **Compatibility** (OpenGL, "best performance possible on all devices… don't need advanced rendering features"). Godot 4.6 made **Direct3D 12** the default driver for new Windows projects, and 4.7 added a render-pass memory optimisation.
- **Unity** 6.x centres on URP/HDRP with a shared Render Graph (6.3). Dynamic batching is obsolete as of 6.6. GPU Resident Drawer is available.

### Cited Findings
- **Godot renderers**:
  - Forward+: "The most advanced renderer, suited for desktop platforms only. Used by default on desktop platforms" (Vulkan, Direct3D 12 or Metal via RenderingDevice).
  - Mobile: "Fewer features, but renders simple scenes faster. Suited for mobile and desktop platforms."
  - Compatibility: OpenGL, recommended when "You want the best performance possible on all devices and don't need advanced rendering features".
  - Since 4.4, if Vulkan is unsupported the engine falls back to Direct3D 12 and vice versa.
  - [Godot docs: Overview of renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)
- Godot 4.6: "With Direct3D 12 now pretty much on par with Vulkan, new Windows projects default to Direct3D 12 for more stable driver support… keeping existing projects unchanged." 4.6 also added script profiling via Tracy, Perfetto and Instruments. — [Godot 4.6 release page](https://godotengine.org/releases/4.6/)
- Godot 4.7: "by giving each pass their own unique environment uniform memory pool, we could speed up the rendering process", because a shared pool "added copy dependencies that often bottlenecked the whole process". The Vulkan Mobile renderer "matches or even outperforms our Compatibility renderer in a number of benchmarks" (XR context). — [Godot 4.7 release page](https://godotengine.org/releases/4.7/)
- Godot 4.6 positions itself as kicking off "a period of polish… and doubled-down effort on performance optimization". — [Godot 4.6 release page](https://godotengine.org/releases/4.6/)
- Unity 6.3: "Both the Universal Render Pipeline (URP) and the High Definition Render Pipeline (HDRP) now use the same underlying Render Graph compiler and API". Also added `MeshRenderer/SkinnedMeshRenderer.SetShaderUserValue` (`unity_RendererUserValue`) for per-renderer variation without breaking batching, usable with the GPU Resident Drawer. — [What's New in Unity 6.3](https://docs.unity3d.com/6000.3/Documentation/Manual/WhatsNewUnity63.html)
- Unity 6.6: "Dynamic batching is now obsolete." It also added reading the depth buffer from GPU memory in URP (DX12/Vulkan only), and made the Performance Testing package a core package. — [What's New in Unity 6.6](https://docs.unity3d.com/6000.6/Documentation/Manual/WhatsNewUnity66.html)
- Unity's render pipeline feature comparison (URP vs HDRP vs Built-in) is maintained in the manual. — [Unity Manual: Render pipeline feature comparison](https://docs.unity3d.com/6000.3/Documentation/Manual/render-pipelines-feature-comparison.html)
- A general web search for Godot 4 vs Unity 6 empty-scene frame-time benchmarks returned only forum anecdotes and SEO articles, with no reproducible numbers. — e.g. [Godot Forum thread "Godot 4 vs Unity 2023? (graphical performance)"](https://forum.godotengine.org/t/godot-4-vs-unity-2023-graphical-performance/74109) (not relied upon)

### Inferences
- At 240–500 FPS the frame budget is 2–4 ms, and for a simple arena **CPU-side per-frame overhead** (scene traversal, script callbacks, animation of N skinned bots, physics queries) will dominate rather than GPU shading.
- Godot candidates: Forward+ or Mobile on D3D12/Vulkan. Mobile may be lighter for a simple scene per the docs.
- Unity: URP with GPU Resident Drawer is the natural choice. HDRP is over-specified for an aim trainer.
- **Skinned bots are the main rendering variable.** Many skinned meshes (65 bones each) means CPU or GPU skinning cost in both engines. Measure with the actual bot count.
- **Language overhead is a second variable.** Unity C# (IL2CPP/Mono) vs Godot GDScript/C#/GDExtension for per-bullet and per-bot logic at 500 Hz. Use typed GDScript or C#/GDExtension for hot loops in Godot.

### Gaps
- I found no primary-source benchmark of frame time (ms) for a simple 3D scene in Unity 6.x URP vs Godot 4.6/4.7 Forward+/Mobile on Windows. Recommendation: build an identical test scene (arena + 20–50 animated bots + 500 bullets/s) in both engines and profile.
- I did not check whether either engine has a known frame-pacing or present-mode cap that limits FPS above monitor refresh. That belongs to the input/latency researcher's scope.

## 6. Existing FPS templates, shooter samples and aim-trainer projects as starting points

### Takeaway
Neither engine has an official Apex-like starting point.

**Godot** has more relevant open-source material for this project:
- **LibreAim**, an open-source FPS aim trainer in Godot (now hosted on Codeberg).
- **SUCC** (Source movement).
- **Kenney's Starter Kit FPS** (Godot 4.6, CC0 assets).
- **chafmere/Godot4-FPS-Template**, with resource-based weapons, hitscan *and* projectile components and spray profiles.
- **Whimfoome/godot-FirstPersonStarter** (about 1,000 stars).

**Unity** has the official **FPS Microgame** (Unity Learn / Asset Store) and the Fragsurf lineage for movement. I found no notable open-source Unity aim trainer.

### Cited Findings
- **LibreAim**: "Free and open source FPS aim trainer made with Godot. Project now moved to Codeberg." 180 stars on the GitHub mirror, GDScript. — [GitHub: Nokorpo/LibreAim](https://github.com/Nokorpo/LibreAim)
- **Kenney Starter Kit FPS**: "a basic template for a first person shooter in Godot 4.6". It includes a character controller, weapons and weapon switching, enemies, and CC0 sprites and models. Weapons are resources with cooldown, damage and spread. — [GitHub: KenneyNL/Starter-Kit-FPS](https://github.com/KenneyNL/Starter-Kit-FPS)
- **chafmere/Godot4-FPS-Template** (118 stars): weapons are `Weapon_Resource`s run by a state machine. "The projectiles, whether hit scan or projectile are a separate component… And the spray profiles for each weapon." It has external documentation. — [GitHub](https://github.com/chafmere/Godot4-FPS-Template)
- **Whimfoome/godot-FirstPersonStarter** (1,023 stars): "FPS (First Person Shooter) controller template for Godot 4" with acceleration/deceleration, slopes, sprint, air control and joypad support. The badge says Godot v4.2. — [GitHub](https://github.com/Whimfoome/godot-FirstPersonStarter)
- **Official Godot demo projects (3d/)** contain no FPS demo. Relevant pieces: `kinematic_character`, `physics_interpolation`, `physics_tests`, `ragdoll_physics`, `rigidbody_character`, `occlusion_culling_mesh_lod`. — [godot-demo-projects/3d](https://github.com/godotengine/godot-demo-projects/tree/master/3d) (directory listing from a shallow clone)
- **Unity FPS Microgame**: a downloadable project (Asset Store) plus Unity Learn courses. Mods include "make weaponized projectiles, create custom enemies", level design, and tuning "hit points and damage, modify player mechanics like speed and jump strength". — [Unity Learn: FPS Microgame](https://learn.unity.com/project/fps-template), [GameFromScratch](https://gamefromscratch.com/unity-release-new-fps-template-and-tutorial-series/)
- **Unity community FPS projects using Source movement**:
  - **huabrandon0/unity-fps-1**: a CS-inspired multiplayer FPS using "Source Engine movement code". — [GitHub](https://github.com/huabrandon0/unity-fps-1)
  - The Fragsurf-derived controllers listed in section 1.
- A GitHub search for Unity/C# aim-trainer repositories returned no relevant projects (results were unrelated). — [GitHub search via API, query "aim trainer unity language:C#"] (negative result)

### Inferences
- **Godot starting point**: SUCC (movement, MIT) + chafmere template ideas (projectile components, spray profiles) + LibreAim (aim-trainer UX and scoring). Kenney's kit is mostly useful for its CC0 assets.
- **Unity starting point**: Olezen/UnitySourceMovement (movement, MIT) + FPS Microgame (projectile weapon framework). The Microgame is a beginner learning project and is not designed for 500 FPS projectile volume.
- Licenses should be confirmed before copying code (SUCC and UnitySourceMovement are MIT; the others were not checked).

### Gaps
- I did not check the LibreAim Codeberg repository's Godot version, license or features: the raw README path returned 404 on GitHub and Codeberg.
- I did not verify whether the Unity FPS Microgame has been updated for Unity 6.x.
- I did not check licenses for chafmere's template, Whimfoome's starter (code) or Fragsurf-2.
