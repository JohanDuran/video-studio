---
name: edit-recording
description: "Edit a long-form screen or camera recording in the MangoAI editor with Claude: set up a project from the recording, transcribe the mic, propose cuts (filler words, long pauses, false starts, retakes), apply the approved ones on the timeline, add HyperFrames overlays and captions tied to spoken words, mix sound effects and music, and export. The user watches and fixes everything live in the editor. Use when the user runs /edit-recording or asks to edit, tighten or add graphics to a recording."
argument-hint: "[recording file(s) or project folder]"
---

# /edit-recording — long-form edit in MangoAI

Target: `$ARGUMENTS` — one or more recording files, an existing project folder (with `cut.json`), or empty = ask which
recording (list the newest files in `recordings.dir`).

Before anything: read the profile (`video-toolkit` §0) and follow `editing-rules`: the recordings folder is read-only,
no audio or picture processing unless asked, propose before applying. Check `toolbox_status` (transcription and
sounds need it; without it, see *No toolbox* below).

Project folder: `<channel folder>/<project-name>/` (`video-toolkit` §0), e.g. the recording's date and topic.

**Plan first.** If `plan.md` in the project folder has `Status: approved`, follow it: its goal, which parts to keep,
which overlays, graphics, B-roll and sounds to add, and with which tool. Without an approved plan, steps 1–4 (setting
up, transcribing, proposing cuts) are fine because they change nothing in the recording, and they inform the plan.
But before adding overlays, new footage, a new screen recording or sound effects, run the `plan` skill: the recording
is the "what already exists", and the plan decides what each part needs. Never record new screen footage unless the
plan calls for it.

## Steps

Steps 6–8 are optional: do them when the plan or the user wants them. A recording that only needs tightening ends at
step 5 plus the export.

1. **Look at the recording(s)** — `ffprobe` each file: duration, resolution, fps, and the audio streams. The mic is
   `recordings.mic_audio_stream` from the profile; confirm it by ear if unsure (cut 5 s of each stream to
   `<project>/_scratch/` and let the user listen). Note extra tracks (desktop audio, a duplicate mic): leave them out
   unless the user wants them. With `recordings.separate_camera_file`, find the matching camera file
   (`recordings.camera_file_pattern`). A session may be several files played back to back.
2. **Set up the project** — MangoAI only plays a file's first audio stream, so when the mic isn't stream 0, copy just
   that stream into the project, untouched: `ffmpeg -i <rec> -map 0:a:<n> -c:a pcm_s16le <project>/audio/<rec>.mic.wav`
   (this extracts, it doesn't process). Then write `<project>/cut.json` (format in MangoAI's `docs/PROJECT_FORMAT.md`):
   - `width`/`height`/`fps` from the recording (long-form: usually 1920×1080 at the recording's fps), a `title`.
   - `sources`: the recording(s) by path (recordings stay where they are; reading them is fine).
   - Track **V1** (`video`, role `screen`): the recording(s), back to back.
   - Track **A1** (`audio`, role `voice`): the mic (the recording itself when the mic is stream 0, else the `.mic.wav`),
     clip for clip in step with V1.
   - With a camera file: track **V2** above V1, in sync with the screen (same start when the recorder started both;
     otherwise line them up by their audio and check with `frame`). Ask how it should sit (corner card, side by side,
     full frame at times) and set it up with the clip's fields (`cardW` width, `cy` vertical centre, `region` crop; see
     `PROJECT_FORMAT.md`). If the layout they want isn't possible with those, say so and offer the closest; check with
     `frame`.

   `project_open` the folder: the editor opens for the user. Check `project_state` and a couple of `frame`s.
3. **Transcribe** — `transcribe` each voice source (`vocab` from the profile) into `<project>/transcripts/`, register it
   (`apply_ops` `set_transcript`) and give the A1 clip `transcript: "<name>"` so its words follow it on the timeline.
   The user can also do it from the editor's **Toolbox** tab → Transcribe. Then `transcript` shows the words in
   timeline time, and the editor's Transcript tab shows them to the user.
4. **Propose cuts** — filler words, long pauses, false starts and retakes, with timeline times and the words around
   each cut, in a table. Long recordings: work through them a chapter at a time (`transcript` with `from`/`to`).
   **Wait for the user to approve** (all, some, or adjusted). They can also cut by selecting words in the Transcript tab.
5. **Apply cuts** — with `edit`: `cut_ranges` for the approved list (cuts every unlocked track, so picture, voice and
   camera stay in sync), or `cut_pauses` / `cut_fillers` when the user approved those as rules. Each is one undoable
   change the user sees at once. Read back with `project_state` and `transcript`: no gaps, no clipped words; check the
   joins by ear in the editor (the user plays them) and fix with `trim` or the editor. Optionally mark chapters as
   `sections` (they also help the user navigate a long timeline).
6. **Overlays** — propose cards (titles, callouts, lower thirds, subscribe) anchored to spoken words. Look at the
   camera's position first so cards don't cover a face. For each: `comp_create` with its range (and box), write the
   HyperFrames comp (use the `hyperframes` skills; local render only), `comp_stills` to check, `comp_edit_done`, and
   link its start to the word (`edit` `link` → `word:…`) so it follows later cuts. Overlapping cards go on separate
   graphics tracks (comp_create picks a free one).
7. **Captions** (if wanted) — a `captions` track draws the transcript words; set its style. Check a few `frame`s.
8. **Sound** — sound effects for overlays: `sfx_search` first, then `sfx_generate`; the user auditions; `sfx_mark` the
   verdicts. Place them on their own audio tracks (role `sfx`), never on A1. Music on its own track with `duck` so it
   dips under the voice. Set levels with `gain`.
9. **Export** — `export_plan` first and go through its checks with the user (missing files, black gaps, open requests,
   captions off). Then `export` into `<project>/renders/` (loudness from `master`, default −14 LUFS, fine for YouTube).
   Later changes re-render only what changed.

Throughout: the user can fix anything by hand in the editor and Save; read `changes_since` (the hook also tells you)
before your next edit, and pass `base` = the revision you last read. Requests the user draws in the editor
(`requests_list`) are part of the job: answer them with `request_update`.

Done = an approved export in `<project>/renders/`, with `cut.json`, transcripts and overlay comps kept for later changes.

## No toolbox (editor-only install)

Without the media toolbox there's no transcription, so no word list, word-timed cuts, `cut_fillers` or word-linked
overlays. Still possible: set up the project (steps 1–2), let the user cut in the editor (I/O range → ripple delete, or
`cut_ranges` with times they give you), place overlays by time, mix the user's own music and sounds, and export. Say
what's missing once, and that `/studio-setup` adds the toolbox if they get a GPU.
