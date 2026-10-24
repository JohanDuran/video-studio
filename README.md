# video-studio

A Claude Code plugin for making and editing videos with **free, local tools**: vertical Shorts, long-form recording
edits in DaVinci Resolve, and faceless explainers. Claude does the editing work; you approve each step.

It works from any folder. Your personal settings (channel, voice, recordings layout, screen) live in one profile file,
not in the plugin.

## What you get

| Command | What it does |
|---|---|
| `/studio-setup` | Checks Docker, the media toolbox, your GPU and Hugging Face login; asks a few questions and writes your profile; installs the HyperFrames skills and the DaVinci Resolve MCP |
| `/short <topic>` | Vertical Short: plan → script → voiceover → word timings → `short.json` → build + preview → privacy check → render |
| `/edit-recording` | Long-form edit: transcribe → cut proposals → apply in Resolve → HyperFrames overlays timed to words → SFX → render |
| `/explainer <topic>` | Faceless explainer: script → voiceover → scenes built in HyperFrames → local render |

Background skills Claude reads on its own: `video-toolkit` (every capability and gotcha) and `editing-rules`
(free tools only, raw recordings are read-only, non-destructive edits, folder layout, your house rules).

MCP servers registered by the plugin: `media-toolbox` (`http://localhost:8765/mcp`) and `blender`
(`uvx mcp-for-blender`, optional). The DaVinci Resolve MCP is installed by `/studio-setup` with its own installer.

## Requirements

- **Windows 10/11 with an NVIDIA GPU** is the tested setup (8 GB VRAM is enough). Without a GPU, ffmpeg, HyperFrames
  renders and Shorts still work, but transcription, voiceover and sound generation don't.
- [Claude Code](https://claude.com/claude-code), Docker Desktop, Node.js 20+, ffmpeg.
- The **media-toolbox** engine: https://github.com/JohanDuran/media-toolbox (Docker stack: WhisperX, Kokoro TTS,
  Stable Audio Open, ffmpeg, HyperFrames renderer, Shorts engine). `/studio-setup` walks you through installing it.
- Optional: DaVinci Resolve **free 21.0.x** (don't update to 21.1+, which made scripting Studio-only), Blender + uv,
  a free Hugging Face account for Stable Audio.

## Install

```
claude plugin marketplace add <path-or-git-url-of-this-repo>
claude plugin install video-studio@video-studio
```

Then start Claude Code in any folder and run `/studio-setup`.

## Your profile

`/studio-setup` writes two files:

- `<studio>/studio.json` — your profile (template: `plugins/video-studio/templates/studio.json`): channel name and
  language, recordings folder and which audio stream is the mic, whether the camera is a separate file, default voice and
  speed, transcription vocabulary, screen geometry, toolbox and Resolve settings, and `house_rules` — standing
  preferences Claude adds to as you state them.
- `~/.video-studio/config.json` — `{"studio": "<path to your studio folder>"}`, so the plugin finds the profile from
  any working folder.

Every video gets its own folder: `<studio>/<ProjectName>/` (named after the Resolve project when there is one).
Generated sounds are shared across videos in the toolbox's sound library.

## Free tools only

The plugin never uses paid services: HyperFrames renders locally (no HeyGen cloud rendering or credits), voice is
Kokoro, transcription is WhisperX, sound effects are Stable Audio Open, editing is free DaVinci Resolve.

Third-party pieces it installs or calls: [HyperFrames](https://github.com/heygen-com/hyperframes) skills,
[davinci-resolve-mcp](https://github.com/samuelgursky/davinci-resolve-mcp), mcp-for-blender. Check their licenses;
Stable Audio Open has its own license on Hugging Face.

## License

MIT — see [LICENSE](LICENSE).
