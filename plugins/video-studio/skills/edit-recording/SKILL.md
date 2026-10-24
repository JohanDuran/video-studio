---
name: edit-recording
description: "Edit a long-form screen or camera recording in DaVinci Resolve with Claude: transcribe the mic, map the transcript to the timeline, propose cuts (filler, long pauses, retakes), apply the approved ones, add HyperFrames overlays timed to spoken words, mix SFX, and render. Use when the user runs /edit-recording or asks to edit, tighten or add graphics to a recording or Resolve timeline."
argument-hint: "[Resolve project or recording file]"
---

# /edit-recording — long-form edit

Target: `$ARGUMENTS` (a Resolve project name, a recording file, or empty = the project open in Resolve).

Before anything: read the profile (`video-toolkit` §0) and follow `editing-rules` — the recordings folder is
read-only, no audio/picture processing unless asked, propose before applying. Check `toolbox_status`, and that the
Resolve MCP answers `project_manager get_current` (free edition: the user must run Workspace → Scripts → Utility →
resolve_bridge with the project open).

Project folder: `<channel folder>/<ResolveProject>/` (`video-toolkit` §0).

## Steps

1. **Get the timeline** — current project + timeline from Resolve. If there's no project yet, create one from the
   recordings: set timeline fps (`recordings.fps` / `resolve.timeline_fps`) and resolution **before** importing, then
   ask the user to set Playback frame rate to match (the API can't). Import the screen file(s) and, if
   `recordings.separate_camera_file`, the camera files (`recordings.camera_file_pattern`).
2. **Capture the layout** — read the timeline items (Audio 1 = the voice track) into `timeline/<timeline>.audio1.json`.
   A session may span several files that Audio 1 plays back to back; note every source file it uses.
   If extra recorder audio tracks (desktop audio, a duplicate mic) are on the timeline, point them out and leave them.
3. **Transcribe** — `transcribe` every source file Audio 1 uses (mic = `recordings.mic_audio_stream`, `vocab` from the
   profile) into `transcripts/`, then `timeline_transcript` → `<timeline>.timeline.json/.srt/.txt` in timeline time.
   Re-run this after any edit that moves or trims Audio 1.
4. **Propose cuts** — filler words, long pauses, false starts and retakes, with timeline timecodes and the words around
   each cut, in a table. **Wait for the user to approve** (all, some, or adjusted).
5. **Apply cuts** — non-destructively in Resolve (on a duplicated timeline, e.g. `<timeline>_cut`), then read the
   items back and check for gaps/overlaps. Re-run step 3's `timeline_transcript` on the new timeline.
6. **Overlays** — propose cards (titles, callouts, lower thirds, subscribe) anchored to spoken words. Measure face-safe
   zones from the camera clips first. Build a HyperFrames project in `animations/` (use the `hyperframes` skills;
   local render only), render `mov` with alpha at the timeline fps via `render_hyperframes`, import, and place each on
   an empty video track at the word's record frame. Overlapping cards go on separate tracks. Read back and compare.
7. **Sound** — SFX for overlays: `sfx_search` first, then `sfx_generate`; user auditions; `sfx_mark` the verdicts.
   Pre-mix each overlay's cues into one WAV with ffmpeg (the API ignores clip volume) and place it on an empty audio
   track, never Audio 1.
8. **Render** — `render prepare_delivery_job` (YouTube 1080p/4K at the timeline fps) into `<project>/renders/`,
   `start`, `verify_output`. Check loudness on the result.

Done = an approved render in `<project>/renders/`, with transcripts and overlay projects kept for later changes.
