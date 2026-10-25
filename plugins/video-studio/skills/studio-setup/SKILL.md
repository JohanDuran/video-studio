---
name: studio-setup
description: "Set up or update the video-studio profile and tools on this PC: checks Docker and the media toolbox, the NVIDIA GPU and the Hugging Face login for Stable Audio, asks the user a few questions and writes a channel profile <studio>/<channel>/studio.json plus the ~/.video-studio/config.json pointer, adds more channels (one folder each), installs the HyperFrames skills globally, and installs the DaVinci Resolve MCP with its free-edition bridge. Use when the user runs /studio-setup, when the studio profile is missing, or when they want to change their channel, voice, recordings or screen settings, or add another channel."
argument-hint: "[check | channel | voice | recordings | ...]"
---

# Studio setup

Goal: a working toolchain plus one profile per channel at `<studio>/<channel>/studio.json`, which every other
video-studio skill reads (they find it as `video-toolkit` §0 says). Shared things stay at the studio root:
`sfx_library/`, `recordings/`, `_scratch/`.

Run the steps in order. Report each check as ✓ / ✗ with the fix. Safe to run again:

- **A profile already exists** (found the `video-toolkit` §0 way, or listed in the pointer): show which channel(s)
  exist and ask: **update a channel** (load it, show it, only ask about what they want to change) or **add a new channel**
  (§2b). An argument narrows it: `channel` → add a channel; `voice`, `recordings`, … → that section of the current
  channel; `check` → §1 only, changes nothing.
- **Older single-channel studio** (`studio.json` directly in the studio root): it keeps working. When the user adds a
  second channel, offer to move the first one into its own `<studio>/<channel>/` folder (its `studio.json` and project
  folders), and warn that Resolve projects then need their media relinked.

Rules for this skill: free tools only (see `editing-rules`). Never type tokens, passwords or license
acceptances for the user — they do those themselves. Ask before installing anything.

## 1. Check the machine

Run these and collect the results before asking anything:

| Check | How | If it fails |
|---|---|---|
| Docker | `docker version --format '{{.Server.Version}}'` | Ask the user to install/start Docker Desktop (WSL 2 backend on Windows) |
| Media toolbox | `toolbox_status` MCP tool (or open http://localhost:8765) | Not installed → §1a. Installed but down → start Docker Desktop, or `docker compose up -d` in its folder |
| NVIDIA GPU | `nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader` | No GPU → the toolbox runs CPU-only: no transcription, TTS or SFX generation; ffmpeg, HyperFrames renders and Shorts still work |
| Node.js ≥ 20 | `node --version` | Needed for HyperFrames and the Resolve MCP installer → install Node LTS |
| ffmpeg on the host | `ffmpeg -version` | Needed for screen recording → `winget install Gyan.FFmpeg` |
| uv (optional) | `uvx --version` | Only for the Blender MCP → `winget install astral-sh.uv` |
| Hugging Face login | `hf auth whoami` (or `uvx --from huggingface_hub hf auth whoami`) | §1b |

### 1a. Install the media toolbox

The engine is the separate `media-toolbox` repository (link in the video-studio README, `${CLAUDE_PLUGIN_ROOT}/../../README.md`
when installed from the marketplace; ask the user if you can't find it). With their OK:

1. Clone it, e.g. into `%USERPROFILE%\Documents\Projects\media-toolbox`.
2. Run its installer from that folder: `powershell -ExecutionPolicy Bypass -File install.ps1 -StudioDir "<studio>" -RecordingsDir "<recordings>"`
   (add `-NoGpu` without an NVIDIA GPU). Read its README first — the options may have changed. It writes `.env`,
   pulls the images and starts the stack.
3. Re-run `toolbox_status`. The MCP server `media-toolbox` comes from this plugin's `.mcp.json`; if Claude Code shows it
   as failed, the stack isn't up yet — `/mcp` → reconnect once it is.

### 1b. Hugging Face (Stable Audio only)

Stable Audio Open 1.0 is gated. The user must, themselves:
1. Accept the license on https://huggingface.co/stabilityai/stable-audio-open-1.0 (free account).
2. Run `hf auth login` in their own terminal and paste a read token. The toolbox uses the token saved under
   `%USERPROFILE%\.cache\huggingface`.
Transcription and TTS need no account. Skip this if they don't want generated sound effects.

## 2. Ask the questions

Ask in one or two rounds (use the question tool where available), with sensible defaults shown:

1. **Studio folder** — where projects and the sound library live. Default `%USERPROFILE%\media-studio`
   (match the toolbox's `-StudioDir` if already installed: read `OUTPUTS_DIR` / `SFX_LIBRARY` from its `.env`).
2. **Channel** — name, handle, main language, one line on what it's about, anything that must never appear on screen.
   Its folder is `<studio>/<channel-slug>/` (lowercase, dashes, e.g. `jdkoder`); confirm the name.
3. **Recordings** (optional) — default folder `<studio>/recordings`, for any source (screen recorder, camera, phone).
   Suggest pointing their recorder's output there; if they keep recordings elsewhere, use that folder instead.
   Ask whether the camera is a separate file. Then probe one recent file with `ffprobe` to find which audio stream is the mic
   (`mic_audio_stream`) and note any extra tracks in `audio_streams_note`. Record the camera file naming pattern if separate.
4. **Voice** — offer 3–4 Kokoro voices for their language, `speak` one line with each into the studio's scratch folder
   (`<studio>/_setup/`), let them listen and pick; also the speed (default 1.0).
   English picks to audition: `af_heart`, `af_bella`, `am_fenrir`, `am_michael`, `bm_george`. Spanish: `ef_dora`, `em_alex`.
5. **Transcription vocab** — names and jargon they say often (products, people, their channel name).
6. **Screen** — read it rather than asking: resolution and scale via PowerShell
   (`Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Screen]::PrimaryScreen`), taskbar position,
   and the usable app area. Confirm with the user.
7. **Resolve** — edition (free/Studio) and version, timeline fps they usually use.

### 2b. Adding another channel

Skip the machine checks (run `toolbox_status` only). Copy `recordings`, `screen`, `toolbox` and `resolve` from an
existing channel's profile and ask only whether any of them differ for this channel. Then ask the channel-specific
questions: **Channel** (2), **Voice** (4), **Transcription vocab** (5), and any standing preferences for `house_rules`.
Start `house_rules` empty unless the user wants rules copied from another channel.

## 3. Write the profile

1. Start from `${CLAUDE_PLUGIN_ROOT}/templates/studio.json` (this plugin's `templates/studio.json`). Fill in the answers;
   keep unknowns empty rather than inventing them. Set `toolbox.repo_dir`, `toolbox.gpu`, `toolbox.gpu_vram_gb` and
   `toolbox.sfx_library` from §1.
2. Write `<studio>/<channel-slug>/studio.json`, creating the folder if needed. Set `studio_dir` to the studio root and
   `channel_dir` to the channel folder. On a re-run, merge — never drop `house_rules`.
3. Write the pointer `%USERPROFILE%\.video-studio\config.json` (forward slashes):
   `{"studio": "<studio root>", "default_channel": "<channel folder>", "channels": {"<Channel name>": "<channel folder>"}}`.
   Adding a channel adds it to `channels`; ask whether it should become `default_channel` (the one used when a chat is
   opened outside any channel folder). Keep any keys already there.
4. If the toolbox's `.env` disagrees with the profile (vocab, protected recordings folder, sound library), tell the user
   which lines to change and offer to edit `.env` and restart with `docker compose up -d`.

## 4. HyperFrames skills (global)

With the user's OK:

```
npx skills add heygen-com/hyperframes -g -a claude-code --skill '*' -y
```

Check with `npx skills ls -g`. Restart Claude Code to load them. Remind them: local renders only — this plugin never uses
HyperFrames cloud rendering, HeyGen credits or `hyperframes auth login`.

## 5. DaVinci Resolve MCP

Third-party server: samuelgursky/davinci-resolve-mcp (MIT). With the user's OK:

1. Resolve must be installed (free edition is fine). **Stay on 21.0.x** — don't update to 21.1+: it made Python scripting
   Studio-only and the free-edition connection stops working. Tell them to decline Resolve's update prompts.
2. Run `npx davinci-resolve-mcp setup` and follow its prompts; pick **Claude Code** when it asks which clients to configure.
3. **Free edition:** external scripting is Studio-only, so the server talks to Resolve through an in-app bridge script.
   Install it with the bridge installer from the davinci-resolve-mcp folder the setup created
   (`python scripts/install_resolve_bridge.py`), restart Resolve, open a project, then run
   **Workspace → Scripts → Utility → resolve_bridge**. This has to be done each time Resolve starts, with a project open.
   Studio edition instead: Preferences → General → External scripting using → Local.
4. Restart Claude Code, then test with `project_manager get_current`.

## 6. Recording indicator (Windows)

A floating pill that is always on top: red **REC m:ss** while a host screen recording runs (any `ffmpeg` with
`gdigrab`/`ddagrab` in its command line), then green **DONE** with a chime when it stops (it hides after 2 min, or on
click). The user can drag it, and it remembers where. It is excluded from screen capture, so it never appears in
recordings. It lets the user know when Claude has finished recording, since they can't use the PC meanwhile. With
their OK:

1. Copy `${CLAUDE_PLUGIN_ROOT}/tools/rec-indicator/` to `<studio>/tools/rec-indicator/`. Use a stable folder, because the
   plugin's own path changes with each version. On a re-run, overwrite the copy so it stays current.
2. Start it: `wscript.exe "<studio>\tools\rec-indicator\start-hidden.vbs"`. A second launch exits, because it runs
   as a single instance.
3. Start-at-login is the user's step (a startup entry is persistent config): **Win+R** → `shell:startup` →
   right-click-drag `start-hidden.vbs` into that folder → **Create shortcuts here**.

To check it, record about 5 s with `gdigrab`: the pill should show red during the recording and green after it.

## 7. Blender (optional)

This plugin already registers `blender` (`uvx mcp-for-blender`). It needs uv and Blender with the MCP add-on running;
point the user to the mcp-for-blender README for the add-on. Skip if they don't do 3D.

## 8. Wrap up

Show a short summary: what's working, what's skipped, where the profile is, and the next step — `/short <topic>`,
`/edit-recording` or `/explainer <topic>`. Explain how channels are picked: open the chat in a channel's folder
(`<studio>/<channel>/`) to work on that channel; a chat opened anywhere else uses the default channel. Another channel
can be added any time with `/studio-setup channel`.
