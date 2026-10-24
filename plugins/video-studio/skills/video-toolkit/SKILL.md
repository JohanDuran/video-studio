---
name: video-toolkit
description: Everything Claude can use to make and edit videos with the video-studio plugin — the media-toolbox MCP (transcription, TTS, SFX/music, ffmpeg, HyperFrames render, vertical Shorts from short.json), the DaVinci Resolve and Blender MCPs, screen recording with ffmpeg, browser capture, and the proven workflows and gotchas. Read before planning or producing any video, Short, voiceover, screen recording, overlay, render or Resolve assembly, and before saying a capability doesn't exist.
---

# Video toolkit

What exists and how to use it. The rules (free tools only, non-destructive, folder layout) are in the
`editing-rules` skill — follow both.

## 0. Read the profile first

1. Read `~/.video-studio/config.json` (`%USERPROFILE%\.video-studio\config.json` on Windows). It holds
   `{"studio": "<studio folder>"}`.
2. Read `<studio>/studio.json`. It has the user's channel, recordings layout, voice, transcription vocab,
   screen geometry, toolbox settings and `house_rules`. Every value below that says "from the profile" comes from there.
3. If either file is missing, tell the user and offer `/studio-setup`. Don't guess personal settings.

Project files always go in `<studio>/<ProjectName>/` (same name as the Resolve project when there is one).

## 1. Inventory

| What | Kind | Use it for |
|---|---|---|
| **media-toolbox** | MCP server (Docker, `http://localhost:8765/mcp`, from this plugin) | Transcription, TTS, SFX/music + sound library, ffmpeg/ffprobe, HyperFrames render, vertical Shorts |
| **davinci-resolve** | MCP server (third-party, installed by `/studio-setup`) | Projects, media pool, timelines, placing clips, rendering in Resolve (free 21.0.x via the in-app bridge) |
| **blender** | MCP server (optional, `uvx mcp-for-blender`, from this plugin) | 3D scenes/renders (`execute_blender_code`, `look`) |
| **Browser tools** | Claude in Chrome / built-in browser | Demos you then screen-record; research; the toolbox dashboard |
| **ffmpeg / ffprobe** on the host | CLI | Screen recording (`gdigrab` on Windows), quick edits, analysis. The toolbox has its own ffmpeg in Docker |
| **HyperFrames** | skills (`hyperframes`, `motion-graphics`, `faceless-explainer`, …) + toolbox `render_hyperframes` | Designed motion graphics/overlays (HTML → MP4, or MOV with alpha). Local render only |

## 2. Media toolbox (the main engine)

- A Docker Compose stack: a `gateway` (dashboard + REST + MCP, job queue) and workers for WhisperX, Stable Audio,
  Kokoro TTS (GPU) and a CPU `render` worker (ffmpeg + HyperFrames + Chrome + Shorts engine).
  Where it lives on this PC: `toolbox.repo_dir` in the profile. Its settings are in that folder's `.env`.
- **If its tools are missing / `toolbox_status` fails:** Docker Desktop isn't running → ask the user to start it,
  or run `docker compose up -d` in `toolbox.repo_dir`.
- **Paths:** pass normal Windows paths under the user's home folder. It never writes into its protected folders
  (the recordings folder from the profile).
- **GPU:** one GPU job at a time; the gateway unloads other models first. First load ~15–30 s. Without an NVIDIA GPU,
  transcription/SFX/TTS are unavailable but ffmpeg, HyperFrames renders and Shorts still work.
- **Dashboard** http://localhost:8765: Overview (workers, GPU), Jobs (logs, outputs, audio players),
  Run a tool (forms), Sound library (audition, keep/reject), Shorts (shot thumbnails, rebuild, preview).
- Long jobs: tools wait up to `wait_seconds`; otherwise use `wait_for_job` / `job_status`.
- The full `short.json` format, with an annotated example, is in the toolbox repo's `docs/short-spec.md`.

### Tools (MCP)

| Tool | Notes |
|---|---|
| `transcribe(files, out_dir, language, vocab)` | WhisperX large-v3, word timings → `<name>.json/.srt/.words.tsv`. Pass `vocab` from the profile |
| `timeline_transcript(project_dir, timeline)` | Map per-file transcripts onto a captured Resolve timeline (timeline time) |
| `speak(text, voice, speed, out_path)` | Kokoro-82M. Voice and speed from the profile (`voice.default`, `voice.speed`) |
| `sfx_search` → `sfx_generate` → `sfx_mark` / `sfx_scan` | Shared sound library (`toolbox.sfx_library`, + `index.jsonl`). Search first; record verdicts; never delete |
| `ffmpeg(args)`, `ffprobe(path)` | Container ffmpeg; Windows paths are converted (not inside filter strings) |
| `render_hyperframes(project_dir, format, fps, …)` | Local HyperFrames render (`mov` = alpha) |
| `short_info(project_dir)` | Instant: resolved shots/times/outputs of a `short.json` |
| `short_build(project_dir, parts, only)` | Shots (V1) + overlay (V2) + narration (A1) + bed (A2); returns a Resolve `timeline` placement |
| `short_preview(project_dir)` | Composite MP4 with sound + contact sheet (one frame per shot) — essentially the finished video |
| `short_frames(src, times, region)` | Labelled frame grid from a recording, to plan crops/moments |
| `toolbox_status`, `list_jobs`, `job_status`, `wait_for_job`, `cancel_job` | Housekeeping |

## 3. Vertical Short pipeline (summary — `/short` runs it)

Hook in the first 2 s, fast pace, no dead air, ~20–60 s. Plan → script → voice (`speak`, trim silences) →
word timings (`transcribe` the narration) → footage → `short.json` (anchor every cut, zoom, label and SFX to words,
e.g. `word:so - 0.05`, `word:use#2`) → `short_build` → `short_preview` → privacy check → final.
Anchoring to words means a new voice take re-times the whole edit by rebuilding.

Voice clean-up per line before joining (~0.1 s gaps):
`ffmpeg -i vo.wav -af "silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.02,areverse,silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.06,areverse,apad=pad_dur=0.12" -ar 48000 -ac 1 trim_vo.wav`

Loudness target ≈ −14 LUFS, peak ≤ −1 dB (check with `ebur128=peak=true`).

## 4. Screen recording & capture (Windows)

- Record the whole screen with geometry from the profile (`screen`):
  `ffmpeg -f gdigrab -draw_mouse 0 -framerate 30 -i desktop -t 300 -c:v libx264 -preset ultrafast -crf 12 -pix_fmt yuv420p capture\x.mkv`
  (run in the background; `-draw_mouse 1` when clicks matter). Stop it with `Stop-Process` on the ffmpeg PID, then
  remux `ffmpeg -i x.mkv -c copy x_fixed.mkv`. MKV survives being killed.
- **gdigrab timestamps drift from wall clock** — never trust logged times; find moments with contact sheets
  (`fps=1/2,…,tile`) or scene detection (`select='gt(scene,0.02)',showinfo` on a crop).
- **Ask the user for a hands-off window** before recording, and say what will move on screen — otherwise their
  own browsing gets recorded.
- Bring a window to front: PowerShell `ShowWindow(h,3)` + `WScript.Shell.AppActivate(pid)` + `SetForegroundWindow`.
  Close windows you opened with `CloseMainWindow()`.
- Claude in Chrome shows an orange border and its own cursor while acting — good on-camera proof. Its tabs may open
  in the background; click the tab before recording.
- Clean dashboard footage: `chrome --app=http://localhost:8765/#/overview` (no tabs), maximize, close afterwards.
- Claude app footage: the Terminal panel (open with `mcp__terminal__open_terminal_tab`, run a visible job) is a
  tall strip on the right — a natural vertical crop.
- When reading app config files, never print a whole file that may hold tokens.

## 5. DaVinci Resolve via MCP (free 21.0.x)

- The free edition needs the **in-app bridge**: the user opens a project (not just the Project Manager) and runs
  **Workspace → Scripts → Utility → resolve_bridge**. A scripting-unavailable error = bridge not running.
- New project: `project_manager create`; set `timelineFrameRate`, `timelineResolutionWidth/Height` **before**
  importing media. **`timelinePlaybackFrameRate` can't be set by the API** → ask the user: Project Settings → Master
  Settings → Playback frame rate = timeline rate; otherwise playback audio sounds broken (renders are fine).
- Import: `media_pool safe_import_media`; build: `create_timeline_from_clips` /
  `append_to_timeline` with `clip_infos [{clip_id, start_frame, end_frame, record_frame}]`, `track_index`,
  `media_type` (1 video, 2 audio). `end_frame` is **exclusive** (pass the frame count, not count − 1).
  Leave `record_frame_mode` at its default so `record_frame` counts from the timeline start;
  `"absolute"` adds the start a second time (clips land an hour late).
- The timeline starts at 01:00:00:00, i.e. frame `fps × 3600` (108000 at 30 fps, 216000 at 60 fps).
- **Read the live timeline before placing anything** (`timeline get_items`), and read items back afterwards to compare
  starts and durations to the plan (`detect_gaps_overlaps`). Overlapping clips can't share a track — use the next empty one.
- Swap a clip's media: `media_pool_item replace_clip(clip_id, path)` (use new file names to avoid stale caches).
- Render: `render prepare_delivery_job` (e.g. target `"tiktok"` = H.264 1080×1920) with an existing `target_dir`,
  `require_temp_target: false`, `MarkIn` = timeline start frame, `MarkOut` = start + frames − 1 (inclusive), then
  `start`, then `verify_output(expected_frames)`.
- Clip volume writes are ignored by the API → pre-mix music/SFX into one WAV with ffmpeg (`adelay` + `volume` + `amix`),
  voice alone on A1.
- For automated Shorts Resolve is optional (the preview is the final). Use it when the user wants to tweak by hand,
  and for long-form edits (multicam, color, Fairlight).

## 6. Audio

- Search the library first (`sfx_search`); generate with Stable Audio (~1 min per batch of 3 on a mid-range GPU);
  send variations to the user to audition; record verdicts with `sfx_mark`. Library files are never deleted.
- Stable Audio is good for SFX, ambience and loops, weak at vocals and full songs. Write prompts as plain
  descriptions ("cow mooing in a field, farm ambience, realistic, close"). Outputs can peak at 0 dB — check with
  `volumedetect` and lower clip gain rather than editing the WAVs.
- Measure a sound's peak position for timing: `astats=metadata=1:reset=1:length=0.05` + `ametadata=print`.
- Levels: narration ≈ −14 LUFS; music bed ~ −22 to −24 dB under; SFX −5…−12 dB; mix peak ≤ −1 dB.
- If audio "sounds broken" in Resolve but fine outside → playback frame rate mismatch (§5), not the files.
  Measure before blaming TTS (clipping, clicks, null test).
- Kokoro voices: listen before committing. Its male voices are its weakest and speed-ups make them worse;
  keep speed near 1.0 unless the user picked otherwise.

## 7. Channel context

Use `channel` from the profile (name, language, what the channel is about). Before picking a topic, check the
channel's latest uploads for the current direction. Never put anything from `channel.never_show` in a video.
