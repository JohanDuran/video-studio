---
name: video-toolkit
description: Everything Claude can use to make and edit videos with the video-studio plugin — the MangoAI editor (live preview, hand and Claude edits, requests, the final render of short.json / cut.json projects), the media-toolbox MCP (transcription, TTS and cloned voices, SFX/music, ffmpeg, optional FLUX image generation), screen recording with ffmpeg, browser capture, and the proven workflows and gotchas. Read before planning or producing any video, Short, voiceover, screen recording, overlay, long-form edit or render, and before saying a capability doesn't exist.
---

# Video toolkit

What exists and how to use it. The rules (free tools only, non-destructive, folder layout) are in the
`editing-rules` skill — follow both.

**Every tool here is optional.** This skill tells you what's available so you know your options; it never requires
you to use any of it. Pick a tool only when you judge the video or the task needs it, and leave the rest alone. A
simpler video that uses two tools well beats one that uses ten because they exist. When a tool might help but
isn't clearly needed, mention it to the user as an option instead of using it.

## 0. Read the profile first

A studio can hold several channels. Each channel has its own folder with its own `studio.json` (the profile);
the studio root holds what channels share (`sfx_library/`, `recordings/`, `_scratch/`):

```
<studio>/                 e.g. ~/media-studio
  sfx_library/  recordings/  _scratch/      shared
  <channel>/studio.json   one profile per channel, its videos next to it: <channel>/<ProjectName>/
```

Find the profile in this order and use the first that exists:

1. **Nearest `studio.json`**: in the current working folder or any folder above it (like git finds its repo).
   This is how the user picks a channel: they open the chat in that channel's folder or one of its projects.
2. **Default channel**: `~/.video-studio/config.json` (`%USERPROFILE%\.video-studio\config.json` on Windows)
   → `default_channel`, a channel folder → its `studio.json`.
3. **Older single-channel setups**: the same pointer's `studio` → `<studio>/studio.json`.
4. None → tell the user and offer `/studio-setup`. Don't guess personal settings.

The folder holding the chosen `studio.json` is the **channel folder**. Start by saying which channel you're using
("Using channel My Channel, profile at …") so a wrong pick is caught early. If the pointer lists several `channels` and
the working folder is outside all of them, ask which channel the video is for.

The profile has the channel, recordings layout, voice, transcription vocab, screen geometry, toolbox settings and
`house_rules`. Every value below that says "from the profile" comes from there.

Project files always go in `<channel folder>/<ProjectName>/`.

## 1. Inventory

| What | Kind | Use it for |
|---|---|---|
| **MangoAI** | Editor (browser tab, `http://localhost:4780`) + MCP server `mangoai` and a hook, both registered by this plugin (the pinned `mangoai` npm package, see `versions.json`) | **Editing and rendering**: opens `short.json` / `cut.json` projects, live preview with HyperFrames comps, hand edits, the user's requests, exports the final MP4 (§1b) |
| **media-toolbox** | MCP server (Docker, `http://localhost:8765/mcp`, from this plugin) | **The GPU models**: transcription, TTS / cloned voices, SFX/music + sound library, FLUX images; also ffmpeg/ffprobe and the Shorts helpers. No HyperFrames since v0.4.0 |
| **Claude in Chrome** | Browser extension (`mcp__claude-in-chrome__*`), the user's real Chrome | **The only browser for live websites**: research, demos you then screen-record. Never the built-in browser or Playwright/Puppeteer for external sites, since they get flagged as bots (`editing-rules` §6) |
| **ffmpeg / ffprobe** on the host | CLI | Screen recording (`gdigrab` on Windows), quick edits, analysis. The toolbox has its own ffmpeg in Docker |
| **HyperFrames** | skills (`hyperframes`, `hyperframes-cli`, `hyperframes-registry`, `media-use`, …) + MangoAI `comp_render` | Designed motion graphics/overlays (HTML → MP4, or MOV with alpha). Local render only |

## 1b. Who does what: MangoAI edits, the toolbox makes media

One owner per job, so nothing is built twice:

| Job | Owner |
|---|---|
| Voice (Kokoro, cloned), word timings, SFX/music, FLUX images | **toolbox** (GPU models, §2) |
| Preview, edit (by hand or by Claude, Shorts to long recordings), requests, the final render | **MangoAI** |
| Any HyperFrames render (whole-shot graphics, overlays, single-composition videos) | **MangoAI** `comp_render` |
| ffmpeg one-offs | host ffmpeg, or toolbox `ffmpeg` |

The toolbox's `short_build` / `short_preview` are **deprecated**: MangoAI opens a folder with a `short.json`, plays
it live and exports it with the same look and loudness. Don't use them for new videos.

**MangoAI** (any `mangoai` tool starts its server; repo github.com/JohanDuran/MangoAI; a developer's clone runs instead when `MANGOAI_REPO` is set):

- A project is a folder with `cut.json` (MangoAI's format, `docs/PROJECT_FORMAT.md` in its repo) or a `short.json`
  (imported; the first Save writes `cut.json` next to it, `short.json` is never changed; MangoAI keeps reading and
  writing the toolbox's short.json format, a contract between the repos: `ECOSYSTEM.md`). Its state goes in
  `.mangoai/`, exports in `renders/`.
- **Tools:** `project_open` (opens the editor tab), `project_state` (tracks, clips with resolved times, `problems`,
  revision), `changes_since`, `selection`, `frame` (live composite at t, needs the tab open), `edit` (move, trim,
  split, ripple, cut ranges, link to words…), `apply_ops` (low-level), `requests_list` / `request_update`,
  `comp_create` / `comp_versions` / `comp_stills` / `comp_edit_done` (HyperFrames comps), `comp_render` (any
  HyperFrames folder → MP4/MOV/WebM file, the only HyperFrames renderer), `transcript`, `export`
  (cached: only changed parts re-render), `export_plan`, `restore_revision`. (`export_otio` exists for other editors; this studio doesn't use it.)
- **Revisions:** every edit passes `base` = the revision you read; a stale base is refused with what changed. The
  user's unsaved edits in the tab are kept on top of yours.
- **The hook** tells you, on the user's next message, what they saved and asked for since you last looked. Read it
  with `changes_since` / `requests_list`, then act. Before editing a comp: `comp_versions` snapshot.
- **Toolbox tab** (in the editor): the user can search/generate sounds, voice a line and transcribe a clip there;
  it calls the toolbox and puts the results on the timeline.
- **Comps:** HyperFrames pages in `animations/<name>/`, sized to the frame; MangoAI renders them with transparency,
  so put any background on the root element, not `body`.

## 2. Media toolbox (the GPU models)

- A Docker Compose stack: a `gateway` (dashboard + REST + MCP, job queue) and workers for WhisperX, Stable Audio,
  Kokoro TTS, `voice-clone` (Chatterbox Turbo, cloned voices) on the GPU, and a CPU `render` worker (ffmpeg + the
  deprecated Shorts engine). With the optional `flux` profile, also `comfyui` (FLUX image generation) and
  the `image` worker that drives it.
  Where it lives on this PC: `toolbox.repo_dir` in the profile (`%USERPROFILE%\.video-studio\media-toolbox` for the
  no-clone install). Its settings are in that folder's `.env`. The release it should run is `media_toolbox.version`
  in `${CLAUDE_PLUGIN_ROOT}/versions.json`; `toolbox_status` reports the running `version`.
- **If its tools are missing / `toolbox_status` fails:** Docker Desktop isn't running → ask the user to start it,
  or run `docker compose up -d` in `toolbox.repo_dir`.
- **Paths:** pass normal Windows paths under the user's home folder. It never writes into its protected folders
  (the recordings folder from the profile).
- **GPU:** one GPU job at a time; the gateway unloads other models first. First load ~15–30 s. Without an NVIDIA GPU,
  transcription/SFX/TTS/depth maps/cutouts are unavailable but ffmpeg, HyperFrames renders and Shorts still work.
- **`render_hyperframes`, `parallax`, `image_depth` or `image_cutout` missing:** removed in toolbox v0.4.0 on
  purpose. HyperFrames renders are MangoAI `comp_render`; stills get a slow zoom instead of parallax.
- **A tool missing, or `toolbox_status` older than `media_toolbox.min`:** the toolbox is out of date. With the
  user's OK, run `/studio-setup update` (it re-runs the pinned installer, keeps `.env`, pulls the new images).
- **`image_generate` missing or failing with "the image worker isn't running":** FLUX is an opt-in profile. With the
  user's OK: set `COMPOSE_PROFILES=gpu,flux` in the `.env` in `toolbox.repo_dir`, then `docker compose up -d` there. The first start downloads ~11.5 GB of models.
- **Dashboard** http://localhost:8765: Overview (workers, GPU), Jobs (logs, outputs, audio players),
  Run a tool (forms), Sound library (audition, keep/reject), Shorts (shot thumbnails; its build/preview buttons use the
  deprecated builder, so preview and export in MangoAI instead).
- Long jobs: tools wait up to `wait_seconds`; otherwise use `wait_for_job` / `job_status`.
- The full `short.json` format, with an annotated example, is in the toolbox repo's `docs/short-spec.md`.

### Tools (MCP)

| Tool | Notes |
|---|---|
| `transcribe(files, out_dir, language, vocab)` | WhisperX large-v3, word timings → `<name>.json/.srt/.words.tsv`. Pass `vocab` from the profile |
| `speak(text, voice, speed, out_path)` | Kokoro-82M. Voice and speed from the profile (`voice.default`, `voice.speed`) |
| `speak_clone(text, voice, ref_path, seed, out_path)` | A cloned voice (Chatterbox Turbo, English). `voice` = a profile in `<studio_dir>/voices/`. Only when the user chose it. See §2c |
| `sfx_search` → `sfx_generate` → `sfx_mark` / `sfx_scan` | Shared sound library (`toolbox.sfx_library`, + `index.jsonl`). Search first; record verdicts; never delete |
| `ffmpeg(args)`, `ffprobe(path)` | Container ffmpeg; Windows paths are converted (not inside filter strings) |
| `short_info(project_dir)` | Instant: resolved shots/times/outputs of a `short.json` |
| `short_build(project_dir, parts, only)` | **Deprecated** (MangoAI renders Shorts, §1b). Shots (V1) + overlay (V2) + narration (A1) + bed (A2) |
| `short_preview(project_dir)` | **Deprecated** (MangoAI previews live, §1b). Composite MP4 + contact sheet |
| `short_frames(src, times, region)` | Labelled frame grid from a recording, to plan crops/moments |
| `image_generate(prompt, size, quality, count, seed, …)` | FLUX.1 [dev] images (optional `flux` profile) → `<name>_s<seed>.png` + `.json`. See §2b |
| `toolbox_status`, `list_jobs`, `job_status`, `wait_for_job`, `cancel_job` | Housekeeping |

### 2b. Generated images (FLUX)

An optional tool, for when a beat needs an image that doesn't exist and can't be shown any other way: a concept
illustration, a background behind a HyperFrames graphic, a thumbnail idea, an imagined scene. Most videos don't need
it. Real things (a listing, a product, a person, an app) are shown from their real source, never generated.

- **It's slow-ish**, so explore cheaply. `quality: draft` (default) is ~28 s per image at 1024×576. Make 2–4 drafts
  with `count`, look at them (read the PNGs), then re-run the chosen seed with `quality: final` (~45 s, 1344×768
  for 16:9). The first image after another GPU tool ran takes ~30 s longer (model load).
- **`size`**: `16:9`, `9:16` (Shorts), `1:1`, `4:3`, `3:4`, `thumbnail` (final is cropped to 1280×720), or `WxH`
  (256–2048).
- **Prompts**: descriptive sentences (subject, setting, light, style), not tag lists. Put text that should appear in
  the image in quotes; FLUX renders short words well and long text badly, so add real text as HyperFrames type
  instead. No negative prompts, no transparent backgrounds.
- **Outputs**: pass `out_dir` as the project's `edit/` or `images/` folder (default: the toolbox outputs). Each PNG
  has a `.json` with prompt and seed, so any image can be re-made at another size.
- `turbo` (default on, 8 steps) is ~3× faster than plain FLUX (`turbo: false`, 20 steps) with similar quality; turn
  it off only to compare.

### 2c. Cloned voices (`speak_clone`)

An option for narration, **picked by the user** in the plan, never by Claude. Kokoro stays the default.

- **Profiles:** `<studio_dir>/voices/<name>.wav` (+ `<name>.txt` with its source), and `voice.clone` in a channel profile
  names that channel's own clone. Call `speak_clone` without `voice` to list the profiles. Only consented voices
  (`editing-rules`).
- **A good profile:** 10–20 s of one person's clean speech, recorded the way the voiceover should sound (the clone
  copies pace, energy and accent), mono, loudness-normalized (`loudnorm=I=-18:TP=-1.5`). Only the first ~15 s are used.
- **Numbers are spelled out automatically** (`$43,300`, `7.32%`, `2026`, `3rd`). To force a reading, write it as
  words. `spell_numbers: false` turns it off.
- **Speed:** ~25 s cold start, then ~1 s per 3 s of speech, ~4 GB VRAM. It has no speed setting: change the pace in the
  script (shorter sentences) or in the edit.
- **Consistency:** use one `seed` for all lines of a video. If a line sounds off (a slurred word, an odd stress), redo
  just that line with another `seed`, or reword it.
- **English only.** For another language, use Kokoro or the user's own recording.
- Every output carries Resemble's inaudible Perth watermark. Remind the user of YouTube's "altered or synthetic
  content" disclosure when the video uses a realistic clone.

## 3. Vertical Short pipeline (summary — `/short` runs it)

Every new video starts with the `plan` skill: an approved `plan.md` that picked a visual source per beat. Nothing
is recorded or generated before that, and the screen is recorded only for beats the plan marks as screen recording.

Hook in the first 2 s, fast pace, no dead air, ~20–60 s. Approved plan → script → voice (the plan's choice: `speak`, `speak_clone` or the user's takes; trim silences) →
word timings (`transcribe` the narration) → each beat's visual source as planned (existing footage, HyperFrames
renders, stills (with a slow zoom), planned screen captures) → `short.json` (anchor every cut, zoom, label and SFX to words,
e.g. `word:so - 0.05`, `word:use#2`) → MangoAI `project_open` (live preview, `frame` checks) → privacy check →
hand fixes / requests → MangoAI `export`. Anchoring to words means a new voice take re-times the whole edit.

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
- **Recording indicator:** `/studio-setup` installs a floating pill at `<studio>\tools\rec-indicator`. It shows red
  **REC** while any host `gdigrab`/`ddagrab` ffmpeg runs, then green **DONE** with a chime when it stops, so the user
  knows when they can use the PC again. It picks up recordings by itself, so there is nothing to call. Normally it
  never appears in captures. While the user is watching through a remote viewer (Chrome Remote Desktop, RDP, …), it
  docks on the taskbar strip and **is** in the raw capture, below `screen.app_area`: crop to the app area. If it isn't running (look for a `powershell.exe` whose command line contains `rec-indicator`),
  start it with `wscript.exe "<studio>\tools\rec-indicator\start-hidden.vbs"` before recording.
- Bring a window to front: PowerShell `ShowWindow(h,3)` + `WScript.Shell.AppActivate(pid)` + `SetForegroundWindow`.
  Close windows you opened with `CloseMainWindow()`.
- **Browser footage = Claude in Chrome only.** Don't use the built-in browser, or a Playwright/Puppeteer script with a
  fresh Chrome profile, for external sites: they get flagged as bots. If the extension isn't connected, ask the user
  to connect it.
- Claude in Chrome shows an orange border and its own cursor while acting — good on-camera proof. Its tabs may open
  in the background; click the tab and maximize Chrome before recording.
- Clean dashboard footage: `chrome --app=http://localhost:8765/#/overview` (no tabs), maximize, close afterwards.
- Claude app footage: the Terminal panel (open with `mcp__terminal__open_terminal_tab`, run a visible job) is a
  tall strip on the right — a natural vertical crop.
- When reading app config files, never print a whole file that may hold tokens.

## 5. Long-form edits (recordings)

`/edit-recording` does them in MangoAI: a `cut.json` with the recording on V1 and the mic on A1 (copied out with
ffmpeg when it isn't the file's first audio stream, since MangoAI plays only that one), the camera on V2 when it's a
separate file. Transcribe the voice and link the clip to its words, then cut with `edit` `cut_ranges` / `cut_pauses` /
`cut_fillers`: they cut every unlocked track, so picture, voice and camera stay in sync. Overlays are comps linked to
words, so later cuts move them too. `project_state` / `transcript` take `from`/`to` for long timelines; `sections`
work as chapters.

## 6. Audio

- Search the library first (`sfx_search`); generate with Stable Audio (~1 min per batch of 3 on a mid-range GPU);
  send variations to the user to audition; record verdicts with `sfx_mark`. Library files are never deleted.
- Stable Audio is good for SFX, ambience and loops, weak at vocals and full songs. Write prompts as plain
  descriptions ("cow mooing in a field, farm ambience, realistic, close"). Outputs can peak at 0 dB — check with
  `volumedetect` and lower clip gain rather than editing the WAVs.
- Measure a sound's peak position for timing: `astats=metadata=1:reset=1:length=0.05` + `ametadata=print`.
- Levels: narration ≈ −14 LUFS; music bed ~ −22 to −24 dB under; SFX −5…−12 dB; mix peak ≤ −1 dB.
- Measure before blaming TTS (clipping, clicks, null test).
- Kokoro voices: listen before committing. Its male voices are its weakest and speed-ups make them worse;
  keep speed near 1.0 unless the user picked otherwise.

## 7. Channel context

Use `channel` from the profile (name, language, what the channel is about). Before picking a topic, check the
channel's latest uploads for the current direction. Never put anything from `channel.never_show` in a video.
