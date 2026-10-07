# AI-agent, headless-Linux, git-based workflow fit: Unity 6.x vs Godot 4.x (as of 7 Oct 2026)

Note on method: alongside the web and doc research, I ran hands-on checks in this exact agent container: Ubuntu 24.04.5, 4 cores, 15 GB RAM, no GPU, HTTPS through an egress proxy. Mesa 25.2.8 (llvmpipe, LLVM 20.1.2) and Xvfb were already installed. Everything was done in a scratch dir (`/tmp/claude-0/.../scratchpad/engine_check`) and nothing was installed system-wide. Claims marked **"Verified locally"** come from those runs, with the commands shown. Network caveats: the egress proxy blocked WebFetch to unity.com and docs.unity3d.com, but `curl` to them worked, so I read Unity pages that way. discussions.unity.com and GitHub's API for third-party repos were blocked (403), so GitHub star counts and Unity forum threads could not be read.

## 1. Installing and running the editor headlessly on Linux (size, method, RAM/disk, GPU-less operation)

### Takeaway
Godot 4.7.2 is a single 78 MB zip holding one 146 MB static-ish binary. It runs `--headless` with no GPU, no install and no account, and I verified this here. Unity 6.3 LTS needs a 4.54 GB download that installs to 8.73 GB (plus about 0.8 GB for the Windows Mono module) or a 5–6 GB compressed `unityci/editor` Docker image. Unity officially supports its Linux editor only on desktop Ubuntu with NVIDIA or AMD GPUs. Running it without a GPU is possible only through `-batchmode -nographics`, which turns off rendering.

### Cited Findings
**Godot**
- The latest Godot stable is **4.7.2**, dated 18 August 2026 on the download page. Linux x86_64 editor: `Godot_v4.7.2-stable_linux.x86_64.zip`. A separate .NET ("mono") editor build also exists. — [godotengine.org/download/linux](https://godotengine.org/download/linux/)
- **Verified locally:** the downloaded zip is 77,860,424 bytes and unzips to one executable, `Godot_v4.7.2-stable_linux.x86_64`, of 146,414,384 bytes. `ldd` shows it depends only on libc, libm, libdl, libpthread and librt. `./Godot_v4.7.2-stable_linux.x86_64 --headless --version` printed `4.7.2.stable.official.ed1daf0bf` in 0.05 s. Download URL: `https://downloads.godotengine.org/?version=4.7.2&flavor=stable&slug=linux.x86_64.zip&platform=linux.64`. — [godotengine.org/download/linux](https://godotengine.org/download/linux/)
- **Verified locally:** the .NET editor zip (`mono_linux_x86_64.zip`) has Content-Length 107,698,034 bytes. The export templates `.tpz` has Content-Length 1,281,349,702 bytes and took about 50 s to download here. — [godotengine.org/download/linux](https://godotengine.org/download/linux/)
- Official CLI docs: `--headless` means "Enable headless mode (--display-driver headless --audio-driver Dummy). Useful for servers and with --script." Also: "Using the --headless command line argument is required on platforms that do not have GPU access (such as continuous integration)." — [Godot docs: Command line tutorial](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)
- **Verified locally:** self-contained mode works. Putting an empty `._sc_` file next to the binary made Godot write its editor data, settings and export templates to `editor_data/` beside the binary instead of `~/.local/share/godot`. That makes it easy to cache in an ephemeral container. (Source for the binary: [godotengine.org](https://godotengine.org/download/linux/))
- **Verified locally:** the ALSA "cannot find card" errors in the container are harmless. Godot logs "All audio drivers failed, falling back to the dummy driver" and continues.

**Unity**
- The current Unity lines are **6000.3.25f1 LTS** (released 2026-09-24) and **6000.6.4f1** (unityci images published 2026-10-01). Unity's release API lists the Linux editor tarball `https://download.unity3d.com/download_unity/e1dba0a9aba4/LinuxEditorInstaller/Unity-6000.3.25f1.tar.xz` at **4.54 GB download and 8.73 GB installed**. The `windows-mono` module is 385 MB download and 769 MB installed; `linux-il2cpp` is 59 MB and 223 MB. — [Unity release API (6000.3.25f1, LINUX)](https://services.api.unity.com/unity/editor/release/v1/releases?version=6000.3.25f1&platform=LINUX&architecture=X86_64&limit=1)
- **Docker images (Docker Hub API, compressed sizes):** `unityci/editor:ubuntu-6000.3.25f1-windows-mono-3` 6.03 GB, `ubuntu-6000.3.25f1-base-3` 5.29 GB, `ubuntu-6000.6.4f1-windows-mono-3` 5.73 GB, `ubuntu-6000.0.84f1-windows-mono-3` 5.84 GB. The repo has 17,437 tags in total. — [Docker Hub unityci/editor tags](https://hub.docker.com/r/unityci/editor/tags); [API query](https://hub.docker.com/v2/repositories/unityci/editor/tags?page_size=100&name=ubuntu-6000.3)
- GameCI's images are "specialised for CI and command-line use", ship with Git and LFS, and support "Cross-version license activations". — [game.ci Docker images](https://game.ci/docs/docker/docker-images)
- **Install paths:**
  - The Unity Hub CLI runs "in headless mode with `-- --headless` on Windows and macOS, or with `--headless` on Linux", and "You must install the Hub first." — [Unity Hub CLI docs](https://docs.unity.com/en-us/hub/hub-cli)
  - **New (blog dated 2026-07-20):** a standalone **Unity CLI**, "a single self-contained binary" (`curl -fsSL https://public-cdn.cloud.unity3d.com/hub/prod/cli/install.sh | UNITY_CLI_CHANNEL=beta bash`). It installs editors and modules with `unity install 6000.2.10f1 -m android ios --accept-eula --yes`, emits JSON/TSV output, and "on a headless build agent, it authenticates with a service account via environment variables". It is still on the **beta** channel. — [Unity blog: Meet the Unity CLI](https://unity.com/blog/meet-the-unity-cli)
- Unity 6.3 system requirements:
  - Linux editor: "Ubuntu 22.04, Ubuntu 24.04", "OpenGL 3.2+ or Vulkan-capable, Nvidia and AMD GPUs", and "Gnome desktop environment running on top of X11 or Wayland... Nvidia official proprietary graphics driver, or AMD Mesa graphics driver".
  - RAM: "a minimum of 8 GB RAM is recommended."
  - Player: supported "running without emulation, container or compatibility layer". — [Unity 6.3 System requirements](https://docs.unity3d.com/6000.3/Documentation/Manual/system-requirements.html)
- `-nographics`: "When you run this in batch mode, Unity doesn't initialize the graphics device. You can then run automated workflows on machines that don't have a GPU... -nographics doesn't allow you to bake GI." `-batchmode` "suppresses dialog windows that require human interaction", and "only a single instance of Unity can run at a time" per project. — [Unity 6.3 Editor command line arguments](https://docs.unity3d.com/6000.3/Documentation/Manual/EditorCommandLineArguments.html)
- **Verified locally:** Docker is present in this container (`/usr/bin/docker`). I did not pull a Unity image, given the 5–6 GB compressed size and the license requirement.

### Inferences
- In a fresh ephemeral container, Godot's cold-start cost is about 78 MB (editor), plus about 1.28 GB once for templates; only the ~213 MB of Windows templates need extracting. Unity's is about 4.9 GB of downloads (editor plus windows-mono), or a 6 GB compressed image, before any project import. On a ~30 GB disk Unity fits, but the editor (~9.5 GB installed) plus a Library folder plus build output consumes a large share of it.
- Godot's binary can go into the repo's setup script, or a cached tool dir, with a single `curl` and `unzip`. Unity setup needs either Docker (pulling the image every session unless cached) or the beta Unity CLI or Hub, plus credentials (see section 2).
- Unity's Linux editor running in a GPU-less container is outside Unity's documented supported configurations. `-batchmode -nographics` is the supported way to run there, and it rules out rendering.

### Gaps
- I did not pull or run a Unity image, so uncompressed image size, Unity's RAM use and Unity startup time in this container are unmeasured.
- I found no official statement on whether the beta Unity CLI's service-account authentication works with **Unity Personal** (see section 2).

## 2. Licensing activation in CI and containers

### Takeaway
Godot needs no activation, account or seat. It is MIT-licensed and I ran it here with nothing set up. Unity Personal still requires an activated license for batchmode builds and tests in 2026. Command-line serial activation explicitly does not apply to Personal. The documented CI path (GameCI) is to activate once in the Unity Hub GUI on a desktop, export the `.ulf` file, and supply the `.ulf`, the Unity email and the password as secrets. Unity's new MCP server also requires a paid or trial AI subscription and a Unity Cloud-connected project.

### Cited Findings
- Unity 6.3 manual: "To use Unity, you need an activated license. The primary license activation method for Unity Pro and Unity Personal is the Unity Hub." Command-line activation (`-quit -batchmode -serial SB-XXXX-... -username ... -password ...`) is described "for Unity Pro", e.g. when "you use Unity in headless mode (without a GUI) for automated tasks, such as builds and tests." "**Note: The following procedures don't apply to Unity Personal. To activate a license for Unity Personal, log in to the Unity Hub.**" — [Unity 6.3: Manage your license through the command line](https://docs.unity3d.com/6000.3/Documentation/Manual/ManagingYourUnityLicense.html)
- GameCI (docs v4) says "All Unity actions require activation."
  - Personal-license recipe: install Unity Hub on a local machine, log in, then "Preferences > Licenses > Add > Get a free personal license" to create a `.ulf` (`~/.local/share/unity3d/Unity/Unity_lic.ulf` on Linux). Store `UNITY_LICENSE` (the .ulf contents), `UNITY_EMAIL` and `UNITY_PASSWORD` as secrets. "Licenses are not tied to a specific Unity version or platform."
  - It warns: "Even if a license appears in Unity Hub, a .ulf file may not have been created," and points users to Discord when the `.ulf` option is missing.
  - Pro: `UNITY_SERIAL` + email + password. A Licensing Server (floating license) can be given with `unityLicensingServer`. — [game.ci Activation](https://game.ci/docs/github/activation)
- On seats, GameCI says concurrent Linux, Windows and macOS build hosts "each consume an additional license seat... This is not an issue for free licenses." — [game.ci Docker images](https://game.ci/docs/docker/docker-images)
- The Unity CLI (beta, July 2026) offers `unity auth login` and service-account authentication for headless agents. — [Unity blog: Meet the Unity CLI](https://unity.com/blog/meet-the-unity-cli)
- Unity MCP requirements: "Unity 6 (6000.0) or later with the AI Assistant package", "A Unity project connected to Unity Cloud", and "An active trial or subscription to Unity's AI tools beta". (Blog datePublished 2026-05-11.) — [Unity blog: Unity AI open beta – MCP](https://unity.com/blog/unity-ai-mcp-how-to-get-started)
- **Verified locally (Godot):** every step (download, import, render, test, Windows export) ran with no account, key or network call to a license service. — [godotengine.org](https://godotengine.org/download/linux/)

### Inferences
- For an agent in an ephemeral container, Unity Personal means a human must first produce a `.ulf` in the Hub GUI on their own machine. The user's Windows PC can do this. The agent's environment then needs the `.ulf`, email and password as secrets, and every new container re-activates with them. That puts the human's Unity account credentials into the agent's environment, which is a security trade-off. Godot has no such step.
- The beta Unity CLI with service accounts may simplify this, but service accounts are typically an organization/paid feature. Treat it as unconfirmed for Personal until verified.

### Gaps
- I found no primary source confirming whether Unity Personal activation inside containers changed in 2026, for example whether Personal `.ulf` files are machine-bound and how often they must be refreshed. The GameCI Discord is the referenced source and was not accessible.
- I could not verify whether Unity CLI service-account authentication is available on Personal.

## 3. Building Windows builds from Linux headlessly

### Takeaway
Godot exports a Windows x86_64 .exe from Linux with one command, needing only the export templates. I verified it here: 6.1 s, a 110 MB single .exe. Unity on Linux can build Windows players only with the **Mono** scripting backend. Windows **IL2CPP** needs a Windows host with Visual Studio C++ tools: there is no `windows-il2cpp` module for the Linux editor and no Ubuntu-based `windows-il2cpp` image.

### Cited Findings
**Godot**
- CLI flags:
  - `--export-release <preset> <path>`: "The preset name should match one defined in 'export_presets.cfg'... The target directory must exist."
  - `--export-debug`, `--export-pack` (PCK/ZIP), and `--export-patch` (new in 4.x, "Export pack with changed files only").
  - "export templates must be installed for the editor (or a valid custom export template must be defined in the export preset)". — [Godot docs: Command line tutorial](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)
- Windows export docs: code signing on non-Windows hosts uses `osslsigncode`. The icon comes from the project icon (changing the PE icon and resources is a separate step). — [Godot docs: Exporting for Windows](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_windows.html)
- **Verified locally:**
  - Templates: the `.tpz` (a zip) contains `windows_release_x86_64.exe` (109.3 MB), `windows_debug_x86_64.exe` (103.2 MB) and console wrappers (0.2 MB). I extracted only those into `editor_data/export_templates/4.7.2.stable/`.
  - Preset: I hand-wrote a 14-line `export_presets.cfg` (`platform="Windows Desktop"`, `binary_format/embed_pck=true`, `application/modify_resources=false`).
  - Command: `godot --headless --path proj --export-release "Windows Desktop" proj/build/windows/AimTrainer.exe` finished in **6.1 s** with exit 0.
  - Output: a 109,923,904-byte `PE32+ executable (GUI) x86-64, for MS Windows`. — [godotengine.org downloads](https://godotengine.org/download/linux/)

**Unity**
- CLI: `-buildTarget <name>`, `-buildWindows64Player <pathname>`, `-standaloneBuildSubtarget`, `-build <pathName>` (builds from `-activeBuildProfile`), and `-executeMethod Class.Method` for custom `BuildPipeline.BuildPlayer` scripts. To fail a build, "throw an exception which causes Unity to exit with return code 1, or call EditorApplication.Exit". — [Unity 6.3 Editor command line arguments](https://docs.unity3d.com/6000.3/Documentation/Manual/EditorCommandLineArguments.html)
- Unity 6.3 system requirements, Windows player: "For development: IL2CPP scripting backend requires Visual Studio 2019 with C++ Tools component or later and Windows SDK version 10.0.19041.0 or newer." — [Unity 6.3 System requirements](https://docs.unity3d.com/6000.3/Documentation/Manual/system-requirements.html)
- Unity's release API lists the Linux-editor modules for 6000.3.25f1. They include `windows-mono` and `windows-server` but **no `windows-il2cpp`**; the IL2CPP module offered is `linux-il2cpp`. — [Unity release API](https://services.api.unity.com/unity/editor/release/v1/releases?version=6000.3.25f1&platform=LINUX&architecture=X86_64&limit=1)
- On Docker Hub, `windows-il2cpp` tags exist only as `windows-6000.x-windows-il2cpp-3` (Windows-container images, about 9.4 GB compressed). The Ubuntu tags offer `windows-mono`. — [Docker Hub unityci/editor](https://hub.docker.com/r/unityci/editor/tags)
- GameCI: "Some platforms require their respective operating systems in order to generate IL2CPP builds." — [game.ci Docker images](https://game.ci/docs/docker/docker-images)
- Unity's Linux IL2CPP cross-compiler (sysroot packages) lets you build **Linux** IL2CPP players from Windows, macOS or Linux. The docs describe no reverse path (Windows IL2CPP from Linux). — [Unity Linux IL2CPP cross-compiler (6000.0)](https://docs.unity.cn/Manual/linux-il2cpp-crosscompiler.html)

### Inferences
- For a PC aim trainer, Unity Mono Windows builds from Linux are fine for testing. If IL2CPP is wanted for release (for performance or obfuscation), it would need a Windows CI runner such as GitHub Actions `windows-latest` and an extra license activation there.
- I did not run the Godot .exe on Windows (no Wine here), but the PE header and size match a correctly built release template with an embedded PCK.

### Gaps
- I did not test whether the Godot-exported .exe launches on the user's Windows PC. That is the user's next step.
- I did not measure Unity Windows-Mono build time from Linux.

## 4. Automated testing headlessly

### Takeaway
Both engines have mature CLI test runners. In Godot, GUT 9.7.1 (for 4.7.x) and gdUnit4 v6.2.x (4.5–4.7.x) run with `godot --headless`, and a framework-free `extends SceneTree` script works too. That ran in 0.27 s here. A `--check-only` parse pass catches errors in 0.17 s. Unity Test Framework runs with `-batchmode -runTests -testPlatform EditMode|PlayMode|<BuildTarget>` and produces NUnit XML, but each run pays editor startup, script compile and license activation.

### Cited Findings
**Godot**
- **GUT:** "GUT versions 9.x are for Godot 4.x." Version table: **9.7.1 → Godot 4.7.x** (godot_4_7 branch), 9.6.1 → 4.6.x, 9.5.0 → 4.5.x. — [GUT README (bitwes/Gut)](https://github.com/bitwes/Gut)
- GUT CLI: `godot -d -s --path "$PWD" addons/gut/gut_cmdln.gd` with options `-gdir`, `-ginclude_subdirs`, `-gprefix` (default `test_`), `-gexit` and `-gexit_on_success`. — [GUT docs: Command Line](https://gut.readthedocs.io/en/latest/Command-Line.html)
- **gdUnit4** (now under the `godot-gdunit-labs` org): master is v6.2.1, supporting "v4.5 … v4.7, v4.7.1, v4.8.dev7"; v6.2.0 supports 4.5–4.7.1. — [gdUnit4 README](https://github.com/godot-gdunit-labs/gdUnit4)
- gdUnit4 CLI: set `GODOT_BIN`, then `./addons/gdUnit4/runtest.sh -a <dir|suite> [-i <suite|suite:test>]`. The underlying tool is `res://addons/gdUnit4/bin/GdUnitCmdTool.gd`. — [gdUnit4 docs: Command Line Tool](https://godot-gdunit-labs.github.io/gdUnit4/latest/advanced_testing/cmd/)
- `-s, --script <script>` runs a script. `--check-only` means "Only parse for errors and quit (use with --script)". — [Godot docs: Command line tutorial](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)
- **Verified locally:**
  - A 15-line `tests/run_tests.gd` (`extends SceneTree`) loads and instances `main.tscn` (including the imported .glb), asserts a node exists, and calls `quit(1 if failures else 0)`. Running it with `godot --headless --path proj -s res://tests/run_tests.gd` took **0.27 s** with **exit 0**.
  - `godot --headless --path proj --check-only -s res://bad_g3.gd` on a script containing Godot 3 `yield(...)` took **0.17 s** with **exit 1** and printed `SCRIPT ERROR: Parse Error: "yield" was removed in Godot 4. Use "await" instead.` — [Godot download](https://godotengine.org/download/linux/)

**Unity**
- Unity Test Framework CLI: `Unity -runTests -batchmode -projectPath PATH -testResults results.xml -testPlatform <X>`. `testPlatform` accepts `EditMode`, `PlayMode` ("Play Mode tests that run in the Editor") or "Any value from the BuildTarget enum" ("Play Mode tests that run on a player built for the specified platform"). Results use the NUnit XML format. Filters: `testFilter`, `testCategory`, `assemblyNames`; `runSynchronously` is EditMode only. — [Unity Test Framework: command line reference](https://docs.unity3d.com/Packages/com.unity.test-framework@1.4/manual/reference-command-line.html)
- Caveat: "If the Editor is running tests with the -runTests argument, then -quit causes the Editor to quit immediately, before in-progress tests have chance to complete." — [Unity 6.3 Editor command line arguments](https://docs.unity3d.com/6000.3/Documentation/Manual/EditorCommandLineArguments.html)
- GameCI wraps this as the `game-ci/unity-test-runner` action, which "already include[s]" activation and license return. — [game.ci Activation](https://game.ci/docs/github/activation)
- The new experimental `com.unity.pipeline` package lets the Unity CLI drive a **running** Editor ("triggering imports, running tests, custom tooling"). It works "with Unity 6.0 LTS and newer". — [Unity blog: Meet the Unity CLI](https://unity.com/blog/meet-the-unity-cli)

### Inferences
- Godot's full test loop (edit .gd, then run `--check-only` and the headless tests) takes under a second per iteration for a small project. Unity's equivalent cold `-batchmode -runTests` invocation includes editor boot, domain compile and license check. Community experience puts that at tens of seconds to minutes, though I found no primary benchmark (see Gaps).
- `--check-only` is a cheap, deterministic guard against the most common LLM failure mode in GDScript, Godot 3 syntax (see section 7).

### Gaps
- I could not measure Unity `-runTests` wall time here because of the license and image size. I found no authoritative published number for Unity batchmode test startup on a 4-core machine.

## 5. File formats, diffability, and import caches

### Takeaway
Godot's `.tscn`, `.tres`, `project.godot`, `export_presets.cfg` and `.import` files are INI-like text that an agent can write from scratch. I hand-wrote a scene that instanced the repo's .glb with no UIDs and no editor, and it loaded and rendered. Unity scenes and prefabs are multi-document UnityYAML with numeric class IDs, fileID anchors and GUID cross-references to `.meta` files. Generating those correctly without the editor is fragile, and merges need `UnityYAMLMerge`. Godot's cache is `.godot/` (676 KB to 2.8 MB in my test). Unity's is `Library/`; both are git-ignored and rebuilt on first open.

### Cited Findings
**Godot**
- TSCN is "human-readable and easy for version control systems to manage." Godot 4 files carry `format=3` (Godot 3 used `format=2`). The header has the form `[gd_scene format=3 uid="uid://cecaux1sm7mo0"]` with an optional `load_steps`, and string UIDs replaced integer IDs. — [Godot docs: TSCN file format](https://docs.godotengine.org/en/stable/engine_details/file_formats/tscn.html)
- `.godot/` "stores various project cache data" and should be in the VCS ignore list. "Godot 3.x and Godot 4.0 is entirely different" in which files to ignore. — [Godot docs: Version control systems](https://docs.godotengine.org/en/stable/tutorials/best_practices/version_control_systems.html)
- **Verified locally:**
  - **Hand-written scene:** I hand-wrote a ~50-line `main.tscn` with WorldEnvironment, a ProceduralSky, a shadowed DirectionalLight3D, a Camera3D, a PlaneMesh floor, a BoxMesh with a StandardMaterial3D override, and an instance of `res://models/dummy_medium.glb`. It has **no `uid=` attributes and no `load_steps`**. Godot loaded and rendered it without warnings. Godot did **not** rewrite the file on import or export (mtime unchanged).
  - **Import output:** `godot --headless --path proj --import` created `models/dummy_medium.glb.import`, a plain-text `[remap]/[deps]/[params]` file with about 40 import options such as `meshes/generate_lods=true` and `animation/fps=30`. Imported data went to `.godot/imported/*.scn`. Godot also created `*.gd.uid` sidecar files for each script (the 4.4+ UID system); these belong in git.
  - **Import timings:**
    - First import (fresh project, editor first run, one 1.8 MB .glb): **9.4 s** wall, and `.godot/` = **676 KB**.
    - Adding the repo's two 7.6 MB and 8.1 MB rig .glbs (`art/sources/UAL1_Standard.glb`, `UAL2_Standard.glb`): incremental import **7.5 s**, `.godot/` = **2.8 MB**.
    - No-op re-run of `--import`: **5.1 s**, mostly editor startup. — [Godot download](https://godotengine.org/download/linux/)

**Unity**
- UnityYAML: "Unity's Scene format uses a custom subset of the YAML data serialization language... The file writes each Object in a Scene as a separate YAML document. The --- sequence introduces each Object." Example headers are `--- !u!1 &6` with component lists like `- 4: {fileID: 8}`. — [Unity 6.3: Format of text serialized files](https://docs.unity3d.com/6000.3/Documentation/Manual/FormatDescription.html)
- `.meta` files: Unity "creates .meta files for each folder and file in your project's Assets folder". They contain "the unique ID assigned to the asset, and values for all the asset's import settings". "If an asset loses its .meta file, any reference to that asset is broken... Unity generates a new .meta file... as if it's a brand new asset." Example: "If a texture asset loses its .meta file, any materials that use that texture lose their reference." — [Unity 6.3: Asset metadata](https://docs.unity3d.com/6000.3/Documentation/Manual/AssetMetadata.html)
- Merging: "Use the UnityYAMLMerge tool to merge scene and prefab files in a semantically correct way." It ships with the editor (e.g. `.../Editor/Data/Tools/UnityYAMLMerge`). — [Unity 6.3: Smart merge](https://docs.unity3d.com/6000.3/Documentation/Manual/SmartMerge.html)
- `-consistencyCheck` "forces a reimport of all assets locally" (this shows the import cache in `Library/` is local and regenerable). — [Unity 6.3 Editor command line arguments](https://docs.unity3d.com/6000.3/Documentation/Manual/EditorCommandLineArguments.html)

### Inferences
- In practice, an agent working on Unity would write C# and then create scenes and prefabs **through editor scripts** run via `-executeMethod` (or the new Unity CLI `eval`), rather than emitting YAML by hand. Hand-written YAML must invent consistent fileIDs and must reference script GUIDs from `.meta` files that Unity generates. Generating `.meta` files out of band risks GUID collisions or broken references, which the meta-file docs warn about. This adds a round trip through a multi-second editor boot for every content change.
- Godot's text formats let the agent build levels (target spawners, ranges) directly as `.tscn` and review them in `git diff`. Combined with the 0.17 s `--check-only` and fast headless load tests, structural errors get caught cheaply.
- Commit `*.import` and `*.uid` files in Godot. Commit `*.meta` files in Unity. Git-ignore `.godot/` or `Library/`.

### Gaps
- I could not measure Unity first-import time or `Library/` size for a URP project in this container. I found no primary benchmark; community reports commonly cite minutes and gigabytes, but I did not verify that.

## 6. Headless rendering of screenshots without a GPU

### Takeaway
Godot renders real screenshots with no GPU, verified here. The Compatibility (OpenGL 3.3/4.5) renderer runs on Mesa llvmpipe under Xvfb in about 10 s per run. Forward+ (Vulkan) runs on Mesa lavapipe under Xvfb in about 24 s, including shader compilation. Both produced correct 1280×720 images with the .glb, shadows and sky. `--headless` itself uses a dummy renderer and cannot capture frames. Unity's documented GPU-less mode, `-batchmode -nographics`, explicitly does not initialize a graphics device, so it cannot produce screenshots. Running Unity on llvmpipe is outside its supported configurations and is unverified.

### Cited Findings
**Godot (all verified locally; binary from [godotengine.org](https://godotengine.org/download/linux/))**
- **Container stack:** Ubuntu 24.04 ships `libgl1-mesa-dri`/`mesa-libgallium` 25.2.8 (llvmpipe) and `xvfb`, both preinstalled here. For Vulkan, I fetched `mesa-vulkan-drivers_25.2.8-0ubuntu0.24.04.4_amd64.deb` (17.5 MB) from archive.ubuntu.com and unpacked it with `dpkg -x` into scratch, without installing it. I pointed `VK_ICD_FILENAMES` at a copy of `lvp_icd.json` with an absolute `library_path`.
- **Screenshot script:** `shot.gd` waits 5 frames, awaits `RenderingServer.frame_post_draw`, then calls `get_viewport().get_texture().get_image().save_png(path)` and `get_tree().quit()`.
- **Compatibility renderer:**
  - Command: `xvfb-run -a -s "-screen 0 1280x720x24" godot --path proj --rendering-method gl_compatibility --rendering-driver opengl3 --resolution 1280x720 -- out/shot_gl.png`
  - Log: `OpenGL API 4.5 (Core Profile) Mesa 25.2.8 - Compatibility - Using Device: Mesa - llvmpipe (LLVM 20.1.2, 256 bits)`
  - Result: **10.2 s** wall, 256 KB PNG, 1280×720, visually correct (glb mannequin, red cube, directional shadows, procedural sky).
- **Forward+ renderer:**
  - Command: `VK_ICD_FILENAMES=.../lvp_icd_abs.json xvfb-run -a ... godot --path proj --rendering-method forward_plus --rendering-driver vulkan ...`
  - Log: `Vulkan 1.4.318 - Forward+ - Using Device #0: Unknown - llvmpipe (LLVM 20.1.2, 256 bits)`
  - Result: **23.9 s** wall on first run (includes pipeline and shader compilation), 217 KB PNG, visually correct.
- **`--headless`:** the same scene run with `--headless` (`--display-driver headless`) **never produced a frame**. Awaiting `frame_post_draw` blocked until I killed it after 4 min 37 s. In headless mode the rendering server is a dummy.
- CLI doc: `--write-movie <file>` "Run the engine in a way that a movie is written (usually with .avi or .png extension)", with `--fixed-fps` forced and `--quit-after` to limit frames. This is an alternative to a custom screenshot script for deterministic frame capture. `--rendering-method`, `--rendering-driver`, `--gpu-index` and `--display-driver` are all CLI-selectable. — [Godot docs: Command line tutorial](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)

**Unity**
- `-nographics`: "Unity doesn't initialize the graphics device. You can then run automated workflows on machines that don't have a GPU." It also cannot bake GI. — [Unity 6.3 Editor command line arguments](https://docs.unity3d.com/6000.3/Documentation/Manual/EditorCommandLineArguments.html)
- The supported Linux editor configuration is NVIDIA or AMD GPUs with GNOME on X11 or Wayland. Players are supported "running without emulation, container or compatibility layer". — [Unity 6.3 System requirements](https://docs.unity3d.com/6000.3/Documentation/Manual/system-requirements.html)
- Unity issue-tracker titles, seen in search results only (pages are JS-rendered and I could not read their body text):
  - "[batchmode] If project is run in batchmode Unity doesn't render to Texture2D.ReadPixels" — [Unity Issue Tracker](https://issuetracker-mig.prd.it.unity3d.com/issues/batchmode-if-project-is-run-in-batchmode-unity-doesnt-render-to-texture2d-dot-readpixels)
  - "Calling Camera.Render in headless mode (batchmode) causes the scene/time to halt" — [Unity Issue Tracker](https://issuetracker-mig.prd.it.unity3d.com/issues/calling-camera-dot-render-in-headless-mode-batchmode-causes-the-scene-slash-time-to-halt)
- A forum thread, seen in search snippets only, reports "Forcing GfxDevice: Null" in batchmode. — [Unity Discussions: how to enable graphics device in batchmode](https://discussions.unity.com/t/how-to-enable-graphics-device-in-batchmode/177826)
- The Unity 7 roadmap mentions a browser-based "Scene Preview" that renders assets "in full in-game context", but as a cloud/web service, not a local headless render. — [Unity blog: Unite Seoul 2026 recap](https://unity.com/blog/unite-seoul-keynote-2026-recap)

### Inferences
- For "agent renders a frame and looks at the PNG", Godot works today in this exact container. The Compatibility renderer on llvmpipe is the fastest option (about 10 s including editor-less boot). Forward+ on lavapipe matches the Windows build's likely default renderer more closely, but is about 2.4× slower per cold run. A project can switch per run with CLI flags without changing `project.godot`.
- For Unity, the agent would need either an unsupported Xvfb + llvmpipe OpenGL setup, which may work but is unverified and unsupported, or a GPU runner. Otherwise visual checks fall back to the human on Windows.

### Gaps
- I did not test Unity with Xvfb + Mesa llvmpipe in this container. I found no primary source confirming or denying that the Unity 6 Linux editor or player renders correctly on llvmpipe.
- I did not test lavapipe performance for heavier scenes or a warm shader cache (repeat runs).

## 7. AI tooling (MCP, official AI integrations) and LLM code quality (GDScript 4 vs C#); Godot C# limits

### Takeaway
**Unity**
- **Official MCP server (open beta since May 2026):** it bridges to a *running, GUI Editor*. It needs an in-Editor click to accept connections, a Unity Cloud-linked project and a paid or trial AI subscription, which makes it a poor fit for a headless container.
- **Unity CLI (beta) and `com.unity.pipeline` (experimental, both July 2026):** these are more agent-friendly. They include `unity command eval` to run C# in a running Editor or Player.
- **Unity 7 (preview December 2026, release Q1 2027):** it promises a "free MCP, CLI, and API built in".

**Godot**
- **MCP:** Godot has no official MCP. Community MCP servers (e.g. Coding-Solo/godot-mcp, Node.js) drive the Godot CLI, so they work headlessly, though an agent can also just call the CLI directly.
- **LLM quality:** the main LLM risk with GDScript is drift into Godot 3 syntax from a smaller, older training corpus. Godot 4's parser catches this immediately.
- **C# in Godot:** it works on desktop with the .NET build and the .NET 8+ SDK, but still cannot export to web.

### Cited Findings
**Unity official AI**
- **MCP server (blog datePublished 2026-05-11):** "Unity's official MCP Server is included with the in-editor AI assistant package" (`com.unity.ai.assistant`, docs @2.11). Setup steps:
  - "In the Unity Editor, go to Edit > Project Settings > AI > Unity MCP. Check that Unity Bridge shows Running".
  - The relay binary on Linux is `~/.unity/relay/relay_linux`, passed `--mcp`.
  - "The first time your agent connects, Unity shows a Pending Connection message... select Accept."
  - Tools: scene hierarchy and GameObject CRUD, C# script create/edit, console logs, component values, build settings. Custom tools can be registered in C#.
  - Clients: Claude Code, Cursor, Windsurf, Claude Desktop. — [Unity blog: Unity AI open beta – MCP](https://unity.com/blog/unity-ai-mcp-how-to-get-started)
- Unity AI open beta launched on **4 May 2026** for Unity 6 users (search-result summaries; not fetched in full). — [gamedev.net](https://gamedev.net/news/4376-unity-ai-open-beta-how-to-get-started-with-mcp); [cinevva news](https://app.cinevva.com/news/2026-05-04-unity-ai-open-beta)
- **Unity CLI (2026-07-20):** "a standalone unity binary... No UI needed". The experimental `com.unity.pipeline` "lets the CLI drive a running Editor, or a dev Player build, over a local API". `[CliCommand]` exposes custom static methods. `unity command eval "<C#>"` is "compiled with Roslyn and run on the Editor's main thread... with no project-level recompile or domain reload required", is "gated behind a security token", and "eval answers in milliseconds against an instance that's already up". — [Unity blog: Meet the Unity CLI](https://unity.com/blog/meet-the-unity-cli)
- **Unity 7 (Unite Seoul, 21 July 2026):** "a platform rebuilt for a world where 'diverse teams of creators and coding agents' work side by side... more open (with a free MCP, CLI, and API built in)". "The Unity 7 Preview launches in December, with full release targeted for Q1 next year". "No breaking changes... Unity 7 is a direct continuation of Unity 6." — [Unity blog: Unite Seoul 2026 recap](https://unity.com/blog/unite-seoul-keynote-2026-recap); [Unity 7 page](https://unity.com/releases/unity-7)

**Godot MCP (community only)**
- **Coding-Solo/godot-mcp:**
  - Purpose: "enables AI agents to launch the Godot editor, run projects, capture debug output, and control project execution".
  - Tools: `launch_editor`, `run_project`, `add_node`, scene creation, "UID Management (for Godot 4.4+)".
  - Requires Node.js 18+.
  - It works through "Godot's built-in CLI commands directly" and a bundled `godot_operations.gd` script, i.e. a headless-compatible design. — [Coding-Solo/godot-mcp README](https://github.com/Coding-Solo/godot-mcp)
- **Other servers:** a 2026 roundup lists GDAI MCP (paid), Coding-Solo, bradypp and Godot Forge (test runner, API docs, LSP). It splits them into "file-level" servers and "engine-level" servers that bridge to a running engine. The source is a vendor blog (Summer Engine sells a competing product), so treat it as directional only. — [Summer Engine: Best Godot MCP server 2026](https://www.summerengine.com/blog/best-godot-mcp-server)

**LLM code quality**
- Godot 3 vs 4 drift (secondary blogs from search snippets, not fetched in full; vendor-affiliated):
  - Models "confidently emit old syntax: `yield(...)` instead of `await`, `KinematicBody` instead of `CharacterBody3D`, `export var` instead of `@export var`, old Tween node API instead of `create_tween()`, `connect("pressed", self, "_on_pressed")` instead of the callable form".
  - The same source claims "Claude Opus is the most reliable for Godot 4 GDScript in mid-2026".
  - Sources: [Summer Engine: Best AI for GDScript 2026](https://www.summerengine.com/blog/best-ai-for-gdscript); [Surmado: AI mistakes in Godot 4 code](https://www.surmado.com/blog/ai-mistakes-in-godot-4-code)
- **Training-data proxy:** Stack Overflow tag counts as of 2026-10-07. Note that Godot's community mostly uses its own forum, Reddit and Discord rather than SO.

  | Tag | Questions |
  |---|---|
  | `c#` | 1,621,605 |
  | `unity-game-engine` | 76,766 |
  | `godot` | 2,417 |
  | `gdscript` | 1,155 |
  | `godot4` | 676 |

  — [Stack Exchange API tag info](https://api.stackexchange.com/2.3/tags/gdscript/info?site=stackoverflow)
- **Verified locally:** Godot 4.7.2's parser rejects Godot 3 `yield` with an explicit migration hint ("'yield' was removed in Godot 4. Use 'await' instead.") in a 0.17 s `--check-only` run. — [Godot download](https://godotengine.org/download/linux/)

**Godot C#**
- Godot 4.7 stable docs: "Projects written in C# using Godot 4 currently cannot be exported to the web platform." Android and iOS are supported as of 4.2. "Godot 4.5 requires .NET 8 or later, but exporting to Android requires .NET 9 or later." The .NET SDK must be installed separately. — [Godot docs (4.7): C# basics](https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/c_sharp_basics.html)
- The .NET editor download is a separate 107.7 MB zip, and C# export needs the separate `mono_export_templates.tpz`. — [godotengine.org/download/linux](https://godotengine.org/download/linux/)

### Inferences
- **Unity:** for a headless agent, MCP is mostly irrelevant today. Batchmode `-executeMethod` scripts are the reliable path, with the Unity CLI and `com.unity.pipeline` as a promising beta. Unity's official MCP assumes a human at a GUI editor.
- **Godot:** the agent needs no MCP at all. The CLI (`--import`, `-s`, `--check-only`, `--export-release`, Xvfb rendering) covers the observe-act-verify loop, and community MCPs just wrap it.
- **Language choice:** LLMs have far more C#/Unity training data, which favors fluent Unity code. GDScript 4 errors are mostly version-drift errors that the parser catches instantly. Mitigations: a project `CLAUDE.md` with Godot 4 idioms, plus `--check-only` in the loop.
- **C# in Godot:** it would recover the C# data advantage but adds the .NET SDK (~200+ MB), `dotnet build` time, and the loss of web export. Web export is not needed for a Windows aim trainer.

### Gaps
- I found no rigorous, peer-reviewed benchmark comparing LLM accuracy on GDScript 4 vs Unity C#. The available evidence is anecdotal and vendor blogs.
- I could not read GitHub stars or activity for Godot MCP repos (the GitHub API was blocked for non-session repos).
- I did not test whether Unity's official MCP relay can attach to a `-batchmode` editor. The docs describe only the GUI flow.

## 8. Iteration speed (compile/domain reload vs GDScript) and the agent edit-run-check loop

### Takeaway
GDScript has no compile step. In this container a headless Godot run boots, loads the project and runs tests in about 0.3 s, a parse check takes 0.17 s, and an Xvfb render takes 10–24 s. Unity's loop on Mono still involves script compile plus domain reload after every code change. Unity's own figures show Play Mode entry dropping from 14–16 s to 3–6 s with Fast Enter Play Mode, which is the default for new projects from Unity 6.6. The CoreCLR "reload only what changed" model is deferred to **Unity 7 (2027)**.

### Cited Findings
- Unity docs: "By default Unity reloads the domain on entering Play mode... Unity also performs domain reload as part of an asset database refresh when it detects changes to scripts. This still happens even when domain reload on entering Play mode is disabled." — [Unity 6.3: Enter Play mode with domain reload disabled](https://docs.unity3d.com/6000.3/Documentation/Manual/domain-reloading.html)
- Unite Seoul 2026 (21 July 2026):
  - "Fast Enter Play Mode is becoming the default for new projects in Unity 6.6 and later". Examples: "LORDNINE... enters Play Mode 2.7 times faster (from 16 seconds down to 6)", "Boat Attack sample... from 4 seconds down to 1", and "Deep Rock Galactic: Survivor... 4.7x improvement (from 14 seconds down to 3)".
  - "Unity will be shipping CoreCLR, arriving in Unity 7 next year... CoreCLR, .NET 10, and C# 14".
  - "Instead of reloading an entire domain on every change, Unity will reload only what's necessary." — [Unity blog: Unite Seoul 2026 recap](https://unity.com/blog/unite-seoul-keynote-2026-recap)
- Earlier roadmap snippets, from search results; the Unity Discussions pages themselves were blocked:
  - "Unity 6.7 LTS will feature an experimental release of the CoreCLR Desktop Player (and will be the last Unity release built upon Mono)".
  - For CoreCLR the expectation is "performance parity... the big performance wins may not come until 6.9+". **These version labels predate the Unity 7 rebrand and may be superseded.** — [Unity Discussions: CoreCLR update June 2026](https://discussions.unity.com/t/coreclr-scripting-and-serialization-update-june-2026/1723299); [Unity Discussions: CoreCLR status March 2026](https://discussions.unity.com/t/coreclr-scripting-and-ecs-status-update-march-2026/1711852)
- The Unity CLI's `eval` gives millisecond answers against an already-running Editor without recompiling. "The usual change-and-check cycle (edit, recompile, relaunch) costs seconds at best." — [Unity blog: Meet the Unity CLI](https://unity.com/blog/meet-the-unity-cli)
- **Verified locally (Godot 4.7.2, 4 cores, no GPU):**

  | Step | Wall time |
  |---|---|
  | `--headless --version` | 0.05 s |
  | `--check-only -s script.gd` | 0.17 s |
  | Headless test script (load scene with .glb, assert, quit) | 0.27 s |
  | First `--import` of new project | 9.4 s |
  | Incremental import of two 8 MB .glbs | 7.5 s |
  | No-op `--import` | 5.1 s |
  | Windows `--export-release` | 6.1 s |
  | Xvfb + llvmpipe GL screenshot | 10.2 s |
  | Xvfb + lavapipe Vulkan Forward+ screenshot | 23.9 s |

  — [Godot download](https://godotengine.org/download/linux/)

### Inferences
- An agent in a stateless shell pays Unity's full editor boot, compile and license cost on every batchmode invocation. A persistent Editor driven via `com.unity.pipeline` and `eval` avoids that, but it is experimental and needs a long-lived editor process inside the container. Godot's per-invocation cost is small enough that a stateless "edit, run, read output, repeat" loop is natural, with dozens of iterations per minute for logic tests.
- For this project (an Apex-style aim trainer: mostly gameplay code, simple scenes, procedurally built .glb assets), Godot's loop advantage is large today. Unity's planned 2027 improvements (CoreCLR, Unity 7 MCP and CLI) may narrow it but are not shipped as of October 2026.

### Gaps
- I took no direct measurement of Unity script compile or domain reload time on a 4-core, GPU-less container. Unity's published numbers are Play Mode entry times on developer workstations.
- Godot hot reload *within a running editor or game* (live script reload over the debugger) was not tested. In this workflow the agent restarts the process each time, which already takes under a second for logic tests.
