---
name: studio-setup
description: "Set up or update everything video-studio needs on this PC, done by Claude end to end: checks Docker, installs the media toolbox (no clone, pinned release), warms the MangoAI editor this plugin registers, checks the versions of the three pieces (plugin, media-toolbox, MangoAI) and removes an old duplicate MangoAI registration; checks the NVIDIA GPU and the Hugging Face login for Stable Audio, asks the user a few questions and writes a channel profile <studio>/<channel>/studio.json plus the ~/.video-studio/config.json pointer, adds more channels (one folder each), and installs the HyperFrames skills globally. Use when the user runs /studio-setup, when the studio profile is missing, or when they want to change their channel, voice, recordings or screen settings, or add another channel."
argument-hint: "[check | channel | voice | recordings | ...]"
---

# Studio setup

Goal: a working toolchain plus one profile per channel at `<studio>/<channel>/studio.json`, which every other
video-studio skill reads (they find it as `video-toolkit` §0 says). Shared things stay at the studio root:
`sfx_library/`, `recordings/`, `voices/`, `_scratch/`.

**You (Claude) do the whole setup.** The user installed this plugin and ran `/studio-setup`; they should not have to
clone repos, read READMEs or type commands. Run every check and install yourself, in the background for long ones,
and only hand the user the steps that are theirs by rule (below). Report each check as ✓ / ✗ and what you did.

Safe to run again:

- **A profile already exists** (found the `video-toolkit` §0 way, or listed in the pointer): run §1 (it also catches
  version drift after a plugin update), then ask: **update a channel** (load it, show it, only ask about what they
  want to change) or **add a new channel** (§2b). An argument narrows it: `channel` → add a channel; `voice`,
  `recordings`, … → that section of the current channel; `check` → §1 only, changes nothing; `update` → §1 + §1d.
- **Older single-channel studio** (`studio.json` directly in the studio root): it keeps working. When the user adds a
  second channel, offer to move the first one into its own `<studio>/<channel>/` folder (its `studio.json` and project
  folders); MangoAI projects keep working when moved, except media referenced by a relative path outside the folder.

Rules for this skill: free tools only (see `editing-rules`). **One approval for the installs:** after §1, show the
list of what you'll install or change and ask once; then do all of it without asking per step. Never type tokens,
passwords or license acceptances for the user, never sign in for them, and leave OS installs that need admin rights
or a reboot (Docker Desktop, WSL) to them, with the exact command to run.

## 0. The three pieces and their versions

video-studio is one of three pieces released together (`ECOSYSTEM.md` at the root of the video-studio repo has the
contract between them):

| Piece | What it is | How it gets on this PC |
|---|---|---|
| **video-studio** (this plugin) | skills, setup, MCP registrations, the MangoAI hook | the user installed it |
| **media-toolbox** | Docker stack: WhisperX, Kokoro, Chatterbox, Stable Audio, FLUX, ffmpeg; MCP at `http://localhost:8765/mcp` | §1a installs it, no clone |
| **MangoAI** | the editor (browser tab at `http://localhost:4780`) + MCP server + hook | already registered by this plugin's `.mcp.json` and `hooks/hooks.json`; runs the pinned npm package via `npx` (§1c) |

Read the pinned versions first: `${CLAUDE_PLUGIN_ROOT}/versions.json` (`mangoai.version`, `mangoai.package`,
`mangoai.min_node`, `media_toolbox.version`, `media_toolbox.min`, `media_toolbox.get_script`). Use exactly those,
never `latest`.

## 1. Check the machine

Run these and collect the results before asking anything:

| Check | How | If it fails |
|---|---|---|
| Docker | `docker version --format '{{.Server.Version}}'` | Not installed: the user runs `winget install -e --id Docker.DockerDesktop` (admin, may need a reboot and WSL 2), starts Docker Desktop once and tells you. Installed but not running: ask them to start it, then re-check |
| Media toolbox | `toolbox_status` MCP tool, or `GET http://localhost:8765/api/state` | Not answering → §1a. Answering: compare its `version` with `media_toolbox.min` (no `version` field, or `dev` from a clone, counts as older/unknown: say so) → §1d |
| NVIDIA GPU | `nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader` | No GPU → install the toolbox with `-NoGpu`: no transcription, TTS, SFX generation or FLUX images; ffmpeg, MangoAI renders and Shorts still work |
| Node.js ≥ `mangoai.min_node` | `node --version` | Needed for MangoAI and HyperFrames → `winget install -e --id OpenJS.NodeJS.LTS`, then a new session |
| ffmpeg on the host | `ffmpeg -version` | Needed by MangoAI and for screen recording → `winget install -e --id Gyan.FFmpeg` |
| Hugging Face login | `hf auth whoami` | §1b (only for generated sounds) |
| MangoAI | its tools are loaded (`mcp__plugin_video-studio_mangoai__*`), and after a `project_state` call `GET http://localhost:4780/api/health` reports `version` = `mangoai.version` | §1c |
| Duplicate MangoAI | `claude mcp get mangoai` shows a **user-scope** `mangoai`, or `~/.claude/settings.json` has a UserPromptSubmit hook running MangoAI's `hook.mjs` | §1e |

Then show the user one list: what's ✓, what you'll install or change (with the commands), and what only they can do.
Ask once; on a yes, do all of it.

**No NVIDIA GPU, or no Docker and they don't want it:** offer the editor alone instead (`/editor-setup`: Node, ffmpeg
and MangoAI, nothing else). Without a GPU the toolbox adds little beyond the sound library, and Docker is the heaviest
install. They can come back to `/studio-setup` later.

### 1a. Install the media toolbox (no clone)

1. Studio and recordings folders first: ask §2 questions 1 and 3 now if you don't know them (defaults
   `%USERPROFILE%\media-studio` and `<studio>\recordings`).
2. Run the bootstrap for the pinned release **in the background** (the first pull is several GB; say it takes a while
   and carry on with §2 meanwhile):

   ```powershell
   $env:VIDEO_STUDIO_SETUP = "1"
   & ([scriptblock]::Create((irm "<media_toolbox.get_script>"))) -Version <media_toolbox.version> -StudioDir "<studio>" -RecordingsDir "<recordings>"
   ```

   Add `-NoGpu` without an NVIDIA GPU. It downloads that release's compose file into
   `%USERPROFILE%\.video-studio\media-toolbox`, writes `.env` (kept on re-runs), pins the images to the release, pulls
   them and starts the stack. That folder is the profile's `toolbox.repo_dir`.
3. When it finishes, check `GET http://localhost:8765/api/state`. The MCP server `media-toolbox` comes from this
   plugin's `.mcp.json` and only connected at session start if the stack was already up, so tell the user to run
   `/mcp` → `plugin:video-studio:media-toolbox` → reconnect (or start a new session). Until then use the REST API.

**Developers with a clone** (`toolbox.repo_dir` has a `.git` folder): leave the clone and its branch alone. Report the
version and, with their OK, run `install.ps1 -Version <media_toolbox.version>` in it to pin the images.

### 1b. Hugging Face (Stable Audio only)

Stable Audio Open 1.0 is gated. The user must, themselves:
1. Accept the license on https://huggingface.co/stabilityai/stable-audio-open-1.0 (free account).
2. Run `hf auth login` in their own terminal and paste a read token (no `hf` command yet: `winget install -e --id
   Python.Python.3.12`, then `pip install -U "huggingface_hub[cli]"`). The toolbox uses the token saved under
   `%USERPROFILE%\.cache\huggingface`.
Transcription and TTS need no account. Skip this if they don't want generated sound effects.

### 1c. MangoAI

Nothing to clone or register: this plugin's `.mcp.json` runs `tools/mangoai-launch.mjs`, which starts the pinned
`mangoai` package with `npx`, and `hooks/hooks.json` adds the hook that reports the user's saves.

1. Needs Node ≥ `mangoai.min_node` and ffmpeg (§1).
2. Warm the npx cache so the MCP server starts fast (the first download can exceed the MCP start-up timeout):
   `npx -y --package=<mangoai.package> mangoai version` → prints `mangoai.version`.
3. If MangoAI's tools weren't loaded this session (Node was missing, or the download timed out): `/mcp` →
   `plugin:video-studio:mangoai` → reconnect, or a new session.
4. Check: `project_state` on any project folder starts the editor server; `GET http://localhost:4780/api/health` →
   `{"app":"mangoai","version":"<mangoai.version>"}`. The editor is at http://localhost:4780.

**MangoAI developers** working on a clone: set a user environment variable instead of registering the clone
(`[Environment]::SetEnvironmentVariable('MANGOAI_REPO', '<clone folder>', 'User')`, then restart Claude). The
launcher then runs the clone's sources. `MANGOAI_PACKAGE=<npm spec or .tgz path>` runs another build.

### 1d. Version drift (after a plugin update, or `/studio-setup update`)

Compare what runs with `versions.json`:
- Toolbox older than `media_toolbox.min` → re-run §1a step 2 with the new version (keeps `.env`, pulls the new
  images, restarts). Check `list_jobs` first and wait if a job is running.
- MangoAI follows the plugin by itself (the launcher pins it). If `/api/health` reports another version, an old editor
  server is still running: stop the process listening on port 4780 and call `project_state` again.
- Tell the user what changed and anything the compatibility table in `ECOSYSTEM.md` says about it.

### 1e. Old user-level MangoAI registration

Before this plugin registered MangoAI, `npm run claude-setup` in a clone added a user-scope `mangoai` MCP server and a
hook. With both, Claude sees every MangoAI tool twice and gets each save report twice. As part of the one approval:
1. `claude mcp remove --scope user mangoai`.
2. Back up `~/.claude/settings.json`, then remove only the UserPromptSubmit hook entry whose command runs MangoAI's
   `hook.mjs`. Leave everything else as it is.
3. If they develop MangoAI from that clone, set `MANGOAI_REPO` to it (§1c) so they keep running their own code.

## 2. Ask the questions

Ask in one or two rounds (use the question tool where available), with sensible defaults shown:

1. **Studio folder** — where projects and the sound library live. Default `%USERPROFILE%\media-studio`
   (match the toolbox's `-StudioDir` if already installed: read `OUTPUTS_DIR` / `SFX_LIBRARY` from its `.env`).
2. **Channel** — name, handle, main language, one line on what it's about, anything that must never appear on screen.
   Its folder is `<studio>/<channel-slug>/` (lowercase, dashes, e.g. `my-channel`); confirm the name.
3. **Recordings** (optional) — where the footage for a video goes, from any source (screen recorder, camera, phone).
   Default `<project>/recordings`: each video's project folder keeps its own recordings, so a project is self-contained
   and nobody has to work out which file in a shared pile belongs to which video. Write `"folder": "<project>/recordings"`.
   The alternative is one shared folder (`<studio>/recordings` or wherever their recorder already saves); then write
   that path. Either way the recordings are read-only.
   Ask whether the camera is a separate file. Then probe one recent file with `ffprobe` to find which audio stream is the mic
   (`mic_audio_stream`) and note any extra tracks in `audio_streams_note`. Record the camera file naming pattern if separate.
4. **Voice** — offer 3–4 Kokoro voices for their language, `speak` one line with each into the studio's scratch folder
   (`<studio>/_setup/`), let them listen and pick; also the speed (default 1.0).
   English picks to audition: `af_heart`, `af_bella`, `am_fenrir`, `am_michael`, `bm_george`. Spanish: `ef_dora`, `em_alex`.
   **Optional cloned voice (English):** if the user wants their own voice available too, take 10–20 s of their clean
   speech: a new recording, or a stretch of one of their videos (good mic, no music; `transcribe` helps find a fluent
   stretch). Cut it with `ffmpeg` (mono, `loudnorm=I=-18:TP=-1.5`) to `<studio>/voices/<channel-slug>.wav`, with a
   `.txt` noting the source. Let them hear one `speak_clone` line, then set `voice.clone` to the profile name. Only
   the user's own voice, or one whose owner gave written consent. The clone is an option they pick per video, not
   the default.
5. **Transcription vocab** — names and jargon they say often (products, people, their channel name).
6. **Screen** — read it rather than asking: resolution and scale via PowerShell
   (`Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Screen]::PrimaryScreen`), taskbar position,
   and the usable app area. Confirm with the user.

### 2b. Adding another channel

Skip the machine checks (run `toolbox_status` only). Copy `recordings`, `screen` and `toolbox` from an
existing channel's profile and ask only whether any of them differ for this channel. Then ask the channel-specific
questions: **Channel** (2), **Voice** (4), **Transcription vocab** (5), and any standing preferences for `house_rules`.
Start `house_rules` empty unless the user wants rules copied from another channel.

## 3. Write the profile

1. Start from `${CLAUDE_PLUGIN_ROOT}/templates/studio.json` (this plugin's `templates/studio.json`). Fill in the answers;
   keep unknowns empty rather than inventing them. Set `toolbox.repo_dir` (the toolbox folder:
   `%USERPROFILE%\.video-studio\media-toolbox` for the no-clone install, or the clone), `toolbox.version`,
   `toolbox.gpu`, `toolbox.gpu_vram_gb` and `toolbox.sfx_library` from §1.
2. Write `<studio>/<channel-slug>/studio.json`, creating the folder if needed. Set `studio_dir` to the studio root and
   `channel_dir` to the channel folder. On a re-run, merge — never drop `house_rules`.
3. Write the pointer `%USERPROFILE%\.video-studio\config.json` (forward slashes):
   `{"studio": "<studio root>", "default_channel": "<channel folder>", "channels": {"<Channel name>": "<channel folder>"}}`.
   Adding a channel adds it to `channels`; ask whether it should become `default_channel` (the one used when a chat is
   opened outside any channel folder). Keep any keys already there.
4. If the toolbox's `.env` disagrees with the profile (vocab, protected recordings folder, sound library), tell the user
   which lines to change and offer to edit `.env` and restart with `docker compose up -d` in `toolbox.repo_dir`.

## 4. HyperFrames skills (global)

Part of the one approval:

```
npx skills add heygen-com/hyperframes -g -a claude-code --skill '*' -y
```

Check with `npx skills ls -g`. Restart Claude Code to load them. Remind them: local renders only — this plugin never uses
HyperFrames cloud rendering, HeyGen credits or `hyperframes auth login`.

## 5. Recording indicator (Windows)

A floating pill that is always on top: red **REC m:ss** while a host screen recording runs (any `ffmpeg` with
`gdigrab`/`ddagrab` in its command line), then green **DONE** with a chime when it stops (it hides after 2 min, or on
click). The user can drag it, and it remembers where. It lets the user know when Claude has finished recording, since
they can't use the PC meanwhile.

Normally it is excluded from screen capture, so it never appears in recordings. A remote viewer is a capture too
(Chrome Remote Desktop, RDP, TeamViewer, RustDesk, Parsec, Sunshine), so while one is in use the pill would be invisible
to the user. In that case it switches by itself: it stays capturable and docks at the left end of the bottom taskbar
strip, outside the profile's `screen.app_area`, so edits that crop to the app area drop it. With their OK:

1. Copy `${CLAUDE_PLUGIN_ROOT}/tools/rec-indicator/` to `<studio>/tools/rec-indicator/`. Use a stable folder, because the
   plugin's own path changes with each version. On a re-run, overwrite the copy so it stays current.
2. Start it: `wscript.exe "<studio>\tools\rec-indicator\start-hidden.vbs"`. A second launch exits, because it runs
   as a single instance.
3. Start-at-login is the user's step (a startup entry is persistent config): **Win+R** → `shell:startup` →
   right-click-drag `start-hidden.vbs` into that folder → **Create shortcuts here**.

To check it, record about 5 s with `gdigrab`: the pill should show red during the recording and green after it.

## 6. Wrap up

Show a short summary: what's working (with the versions running: plugin, toolbox, MangoAI), what's skipped, what
the user still has to do themselves (Docker Desktop, Hugging Face, a `/mcp` reconnect or new session), where the
profile is, and the next step — `/short <topic>`,
`/edit-recording` or `/explainer <topic>`. Explain how channels are picked: open the chat in a channel's folder
(`<studio>/<channel>/`) to work on that channel; a chat opened anywhere else uses the default channel. Another channel
can be added any time with `/studio-setup channel`.
