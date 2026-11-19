# video-studio

A Claude Code plugin for making and editing videos with **free, local tools**: vertical Shorts, long-form recording
edits and faceless explainers, all in the MangoAI editor. Claude does the editing work; you approve each step.

It works from any folder. Your personal settings (channel, voice, recordings layout, screen) live in one profile file,
not in the plugin.

## Get started (4 steps)

1. Have [Claude Code](https://claude.com/claude-code) and, on Windows 10/11,
   [Docker Desktop](https://www.docker.com/products/docker-desktop/) running.
2. `claude plugin marketplace add JohanDuran/video-studio`
3. `claude plugin install video-studio@video-studio`
4. Start a new Claude Code session and run **`/studio-setup`**. Claude checks your PC, installs the media toolbox and
   the MangoAI editor at the versions this plugin is tested with, asks a few questions and writes your profile. You
   approve the installs once and do only what needs you (Docker Desktop, an optional Hugging Face login).

## One product, three repos

| Repo | What it does |
|---|---|
| **video-studio** (this repo) | The plugin: skills, `/studio-setup`, and it registers and pins the other two |
| [media-toolbox](https://github.com/JohanDuran/media-toolbox) | Makes media in Docker: transcription, voices (Kokoro, cloned), sound effects, FLUX images, ffmpeg |
| [MangoAI](https://github.com/JohanDuran/MangoAI) | The editor: timeline you and Claude share, HyperFrames graphics, render and export |

They are released together: [`plugins/video-studio/versions.json`](plugins/video-studio/versions.json) pins the
toolbox and MangoAI releases, and [ECOSYSTEM.md](ECOSYSTEM.md) has the compatibility table and the contracts between
them. **A change in one repo can break the others**: read ECOSYSTEM.md before changing tools, APIs or setup.

## What you get

| Command | What it does |
|---|---|
| `/studio-setup` | Claude sets up everything: checks Docker, your GPU and Hugging Face login, installs the media toolbox (no clone) and warms MangoAI at the pinned versions, asks a few questions and writes your profile; installs the HyperFrames skills. `/studio-setup update` after a plugin update brings the other pieces to the new versions |
| `/editor-setup` | Installs only the MangoAI editor (Node.js, ffmpeg, the pinned MangoAI): no Docker, GPU or toolbox. For editing and exporting your own footage with Claude; add the rest later with `/studio-setup` |
| `/plan [idea]` | **Start here for every new video.** Discusses the idea with you (goal, audience, format, what footage you already have), picks the right tool for each beat (screen recording only where a real screen is the point; otherwise existing footage, HyperFrames graphics, stills) with the reasons, and writes `plan.md`. Produces nothing until you approve |
| `/short <topic>` | Vertical Short from the approved plan: script → voiceover → word timings → each beat's visuals as planned → `short.json` → live preview and hand fixes in MangoAI → privacy check → export |
| `/edit-recording` | Long-form edit in MangoAI: set up a project from the recording → transcribe → cut proposals → apply on the timeline (you watch and fix live) → (plan for additions) → HyperFrames overlays and captions tied to words → SFX and music → export |
| `/explainer <topic>` | Faceless explainer from the approved plan: script → voiceover → scenes built in HyperFrames → assembled and exported in MangoAI |

`/short`, `/explainer` and `/edit-recording` check for an approved `plan.md` first; without one they start with `/plan`.

Background skills Claude reads on its own: `video-toolkit` (every capability and gotcha) and `editing-rules`
(free tools only, raw recordings are read-only, non-destructive edits, folder layout, your house rules).

MCP servers registered by the plugin: `media-toolbox` (`http://localhost:8765/mcp`), `mangoai` (the pinned `mangoai`
package through `npx`, via `tools/mangoai-launch.mjs`), plus MangoAI's hook that tells Claude what you saved in the
editor.

**Who does what:** the [MangoAI](https://github.com/JohanDuran/MangoAI) editor previews, edits and renders the videos
(you and Claude edit the same timeline); the media toolbox runs the GPU models (voice, transcription, sounds, images).

**Recording indicator** (`tools/rec-indicator`, Windows): when Claude screen-records, a floating red **REC** pill stays
on top of everything, then turns green **DONE** with a chime when the recording stops, so you know when you can use
the PC again. It never shows up in the recording. If you watch the PC through Chrome Remote Desktop or another remote
viewer, it moves to the taskbar instead, so you can see it, and stays outside the part of the screen your videos use.
`/studio-setup` installs it.

## Requirements

- **Windows 10/11 with an NVIDIA GPU** is the tested setup (8 GB VRAM is enough). Without a GPU, ffmpeg, HyperFrames
  renders and Shorts still work, but transcription, voiceover and sound generation don't.
- [Claude Code](https://claude.com/claude-code) and Docker Desktop. `/studio-setup` installs the rest with your OK:
  Node.js 22+, ffmpeg, the **media-toolbox** (Docker stack: WhisperX, Kokoro TTS, Chatterbox cloned voices, Stable
  Audio Open, FLUX images, ffmpeg) and the **MangoAI** editor (runs on the host with Node).
- Optional: a free Hugging Face account for Stable Audio.

## Install

Run these in a terminal (PowerShell, or the terminal panel in the Claude desktop app):

```bash
claude plugin marketplace add JohanDuran/video-studio
```

```bash
claude plugin install video-studio@video-studio
```

Then start a **new** Claude Code session in any folder (plugins load when a session starts) and run `/studio-setup`.

> **Claude desktop app:** typing `/plugin marketplace add …` in a chat opens the plugin manager window instead of
> running the command, so use the terminal commands above. In the Claude Code CLI, the same steps also work as
> `/plugin marketplace add JohanDuran/video-studio` and `/plugin install video-studio@video-studio`.

Update later with `claude plugin marketplace update video-studio` and `claude plugin update video-studio@video-studio`,
then `/studio-setup update` so the toolbox and MangoAI match the new plugin.

**Developing MangoAI?** Set `MANGOAI_REPO` to your clone (a user environment variable) and the plugin runs it instead
of the pinned package. `MANGOAI_PACKAGE` runs any other build (an npm spec or a `.tgz`).

## Your profile

`/studio-setup` writes two files:

- `<studio>/<channel>/studio.json` — the channel's profile (template: `plugins/video-studio/templates/studio.json`):
  channel name and language, recordings folder and which audio stream is the mic, whether the camera is a separate file,
  default voice and speed (plus an optional cloned voice, `voice.clone`), transcription vocabulary, screen geometry, toolbox settings, and `house_rules` —
  standing preferences Claude adds to as you state them.
- `~/.video-studio/config.json` — the studio root, your channels and the default one, so the plugin finds a profile
  from any working folder.

```
~/media-studio/            the studio
  sfx_library/  recordings/  voices/  _scratch/   shared by all channels (voices/ = cloned-voice profiles)
  my-channel/              studio.json + one folder per video: my-channel/<ProjectName>/
  second-channel/          its own studio.json, voice, house rules, videos
```

**Several channels:** add one with `/studio-setup channel`. To work on a channel, open the chat in its folder (or one of
its video folders): the plugin uses the nearest `studio.json` above where the chat runs, like git finds its repo. A
chat opened anywhere else uses the default channel. Generated sounds and raw recordings are shared across channels.

## Free tools only

The plugin never uses paid services: HyperFrames renders locally (no HeyGen cloud rendering or credits), voice is
Kokoro, a local Chatterbox clone of your own voice, or you (you pick it per video). Transcription is WhisperX, sound
effects are Stable Audio Open, editing and rendering is MangoAI.

Third-party pieces it installs or calls: [HyperFrames](https://github.com/heygen-com/hyperframes) (skills, and its
renderer inside MangoAI) and the models in the media toolbox (WhisperX, Kokoro, Chatterbox, Stable Audio Open, FLUX.1
[dev]). Check their licenses; Stable Audio Open and FLUX.1 [dev] have their own model licenses on Hugging Face.

## License

MIT — see [LICENSE](LICENSE).
