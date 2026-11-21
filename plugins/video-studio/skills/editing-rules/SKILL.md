---
name: editing-rules
description: Standing rules for making and editing video with the video-studio plugin — free tools only (the MangoAI editor, HyperFrames local render, ffmpeg, the local media toolbox), never touch raw recordings, work non-destructively, keep project files in the studio folder, plus the user's own house rules from their studio profile. Read before any editing, HyperFrames, animation, audio, color, render or Shorts task, before opening any website for a video (Claude in Chrome only), and before suggesting any tool, upgrade or paid feature.
---

# Editing rules

Follow these without re-asking. For what tools exist and how to use them, read `video-toolkit`.

## 0. Profile and house rules

- Find the channel's profile as `video-toolkit` §0 says: the nearest `studio.json` above the working folder, else the
  default channel from `~/.video-studio/config.json`.
  Missing → offer `/studio-setup`.
- `house_rules` in the profile are the user's own decisions (for example "don't touch the mic sound").
  They override the defaults below. When the user states a new standing preference, append it to `house_rules`
  as one short line with the reason and the date, and tell them you saved it.

## 1. Everything must be free

- **The editor is MangoAI.** Every edit (Shorts, explainers, long recordings) happens in a MangoAI project the user
  can watch and fix live. Don't bring in other editors or 3D tools (DaVinci Resolve, Blender, Premiere, CapCut):
  they aren't part of this studio.
- **HyperFrames: local rendering only.** MangoAI renders: comps on its timeline at `export`, any other HyperFrames
  folder with `comp_render`. (The toolbox has no HyperFrames since v0.4.0.) `npx hyperframes render` is the fallback.
  - Never run `hyperframes cloud render`, `lambda`, `cloudrun`, or `hyperframes auth login`.
  - Never use HeyGen-credit features: HeyGen TTS/voices, avatars, `media-use resolve --type bgm|sfx`
    (needs the heygen CLI), or AI image/music/video generation that costs credits. Use the toolbox instead:
    `speak` / `speak_clone` for voice, `sfx_search`/`sfx_generate` for sound, `transcribe` for transcripts.
  - If a HyperFrames workflow step needs one of these, skip it or use the free alternative and say so.
  - Don't push the HyperFrames desktop app or `hyperframes open`: the pipeline is Claude + the MangoAI editor (live
    preview, edits, export) + the toolbox. The web Studio preview is fine for the user's own small tweaks.
- **One owner per job** (`video-toolkit` §1b): the media toolbox makes voices, transcripts, sounds and images;
  MangoAI previews, edits and renders. Don't use the toolbox's deprecated `short_build` / `short_preview` for new
  videos.
- **Other tools:** prefer what's installed (ffmpeg, Node, Docker). Don't sign up for or connect paid services.
- **Voice: the user chooses it** (in the plan), never Claude. The options are Kokoro (local, Apache 2.0) via `speak`
  with the profile's voice and speed; a cloned voice via `speak_clone` (Chatterbox Turbo, local, MIT) with a profile
  from `<studio_dir>/voices/`; or the user's own recording. Don't use non-commercial TTS weights for channel videos.
- **Cloned voices need consent.** Only clone the user's own voice, or a voice whose owner gave written permission.
  Never clone anyone from their videos, podcasts or interviews, whatever the user asks. When a video uses a realistic
  cloned voice, remind the user to tick YouTube's "altered or synthetic content" box at upload.
- **Transcription:** WhisperX via toolbox `transcribe`, not HeyGen's. No speaker diarization unless asked.
- **Generated SFX/music:** Stable Audio Open 1.0 via toolbox `sfx_generate` (its Hugging Face license is accepted
  during `/studio-setup`).
- **Real photos stay real:** on real-estate or product videos the photo must be the real one, unaltered except for
  crop, zoom and color. (Depth maps, cutouts and parallax were removed from the toolbox in v0.4.0.)
- **Generated images:** local FLUX.1 [dev] via toolbox `image_generate` is free and allowed. Its weights are
  non-commercial, but under its license the images it makes may be used in monetized videos. Never generate or
  edit images that stand in for real things (a listing, a property, a product, a person, a screenshot of an app):
  those always come from their real source. Don't use paid image services.

## 2. Folder layout

```
<studio>/
  sfx_library/       shared generated sounds + index.jsonl (reused across videos and channels; toolbox.sfx_library)
  recordings/        shared raw recordings, when recordings.folder points here: read-only
  _scratch/          toolbox outputs with no project folder
  <channel>/         one folder per channel
    studio.json      that channel's profile
    <ProjectName>/   one folder per video
      recordings/      this video's footage when recordings.folder is <project>/recordings (the default): read-only
      plan.md, script.json, short.json, cut.json (the MangoAI edit)
      audio/           narration, mixes, mic tracks copied out of recordings
      capture/         screen recordings made for this video
      transcripts/     per-file transcripts (words.tsv)
      animations/      HyperFrames comps
      renders/, audio_preview/, .mangoai/ (the editor's cache and revisions)
```

A single-channel studio may keep `studio.json` and the project folders directly in `<studio>/`; that still works.

- Agree the project name with the user (short, e.g. the date and topic). Create the folder the first time it's needed.
- Never write project files into the studio root, another channel's folder, or next to source recordings.

## 3. Raw recordings are read-only

- The recordings folder (`recordings.folder`; `<project>/recordings` means each project's `recordings/`, and the
  studio's shared `recordings/` is read-only too) is never written to: no overwrites, deletes, renames or sidecar files.
  Processed media goes into the project folder as copies, and the MangoAI clip then points at the copy.
- Use `recordings.mic_audio_stream` for transcription. If a recording has extra audio tracks (desktop audio,
  a duplicate of the mic), point it out and don't remove or mute them without asking.

## 4. Leave alone unless asked

- **Audio:** don't EQ, denoise, compress or normalize the user's voice unless they ask.
- **Picture:** don't grade or sharpen unless they ask.

## 5. How to work

- **Preview before committing:** for audio/visual changes, render a short before/after sample into
  `<project>/audio_preview/` (or similar) and let the user decide.
- **Propose, then apply:** show proposed cuts, trigger points and overlay placements before changing a timeline.
- **Overlays:** HyperFrames comps on a MangoAI graphics track (`comp_create`, linked to the spoken word); export
  renders them. If another session may be working in `animations/`, build one-off overlays as their own HyperFrames
  project in a sibling folder.
- **Face-safe zones:** when there's a camera image, measure where the face sits (tile frames with ffmpeg) before
  placing cards; never cover the face.
- **Privacy:** never show anything from `channel.never_show`. Screen recordings capture whatever was on screen —
  check every crop at its first and last frame.
- **Sound library:** search before generating, record the user's verdicts with `sfx_mark`, never delete library
  files (rejected ones included). Place picks on their own audio track, never the voice track (A1).

## 6. Websites go through Claude in Chrome

- For any live website during video work (research, looking up listings or products, pages to screen-record), use
  **Claude in Chrome** (`mcp__claude-in-chrome__*`). It drives the user's real Chrome with their own sign-ins and
  history, so sites don't flag it as a bot. This overrides the app's default of the built-in browser.
- Never use these for external sites: the built-in browser (`mcp__Claude_Browser__*`), Playwright, Puppeteer,
  Selenium, headless Chrome, or a script that starts Chrome with a new or temporary profile. Sites like Zillow
  detect them as bots and block them or show a CAPTCHA.
- If Claude in Chrome isn't connected, stop and ask the user to open Chrome and check the extension. Don't fall back to
  another browser.
- Local pages are exempt, and any browser is fine for them: HyperFrames preview/Studio, the toolbox dashboard on
  localhost, and the toolbox's own render Chrome in Docker.
