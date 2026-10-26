---
name: short
description: "Build a vertical Short (9:16, ~20–60 s) from an approved plan.md with the media toolbox: script, Kokoro voiceover, word timings, footage only where the plan calls for it, a short.json edit, short_build and short_preview, a privacy check, then the final render or a Resolve assembly. Starts with the plan skill when there's no approved plan. Use when the user runs /short <topic> or asks for a Short, Reel or TikTok."
argument-hint: "<topic>"
---

# /short — vertical Short

Topic: `$ARGUMENTS`.

**Plan first.** Look for `plan.md` in the project folder (the working folder, or the project named in the arguments).
- `Status: approved` → build exactly that plan: its beats, sources, narration and format. If something in it turns
  out impossible, stop and ask before changing the plan.
- Missing, or still a draft → don't build. Run the `plan` skill with the topic (it discusses the idea with the user and
  picks the tools per beat), and continue here only once the plan is approved.


Before anything: read the profile (`video-toolkit` §0) and follow `editing-rules`. Check `toolbox_status`;
if it fails, stop and help the user start Docker. The `short.json` format is in the toolbox repo's
`docs/short-spec.md` (`toolbox.repo_dir` in the profile) — read it before writing the spec.

Project folder: `<channel folder>/<ProjectName>/` (`video-toolkit` §0; agree a short PascalCase or snake_case name with the user).

## Steps

Use only the tools the plan's beats need: music, SFX, graphics, captions, footage types and Resolve are all optional.
Skip any part of a step that the video doesn't need.

1. **Shot list** — from the approved plan, write `shot_list.md`: per spoken line, what's on screen and its source
   (an existing file, a HyperFrames render, a Blender render, a still, or a screen capture the plan asks for).
   Hook in the first 2 s, fast pace, no dead air.
2. **Script** → `script.json`: one short spoken line per entry.
3. **Voice** — `speak` each line with `voice.default` / `voice.speed` into `audio/lines/`, trim each line's silences
   (filter in `video-toolkit` §3), join with ~0.1 s gaps → `audio/narration.wav`. Let the user listen to it.
4. **Word timings** — `transcribe` `audio/narration.wav` with `language` from the profile and `vocab` =
   `transcription.vocab` plus any new names in the script → `transcripts/narration.words.tsv`.
5. **Visual sources, as the plan says** — for each beat, only the source the plan chose:
   - existing recordings or camera/phone clips: find regions and moments with `short_frames` or contact sheets;
   - HyperFrames graphics: build and `render_hyperframes` them into `edit/` (they become shot sources);
   - Blender renders or stills: produce them into `edit/` or `capture/`;
   - photos the plan marks as parallax shots: crop each to the photo itself, run `image_depth` on all of them in one
     call, then `parallax` per still (default depth mode, `size` 1080x1920, `fps` 30, `duration` = the beat plus
     ~0.5 s, `center` aimed at the subject) into `edit/`. Look at first/middle/last frames before using a clip, then
     use it as a full-frame shot source (`video-toolkit` §2a);
   - screen capture **only for beats the plan marks as screen recording**: record into `capture/`
     (`video-toolkit` §4) after asking for a hands-off window. Never record the screen on your own initiative.
6. **`short.json`** — sources, crop regions, privacy blurs, anchors (`word:so - 0.05`, `word:use#2`), shots back to
   back with zoom keys, graphics (Head/Big/Tag/shape cards), captions, audio (music bed + SFX timed by their measured
   peak). Search the sound library before generating anything; send new SFX variations to the user to audition and
   record verdicts with `sfx_mark`.
7. **Build** — `short_info` (sanity check) → `short_build` → `short_preview`. Read the contact sheet and check frames;
   fix single shots with `only`. Show the preview to the user.
8. **Privacy check** — every shot's first AND last frame (zooms and parallax moves change what's visible) for anything in
   `channel.never_show`: town/addresses, device name, email, other chats/tabs, other people's content. Prefer frozen
   stills where the user scrolled; blur with `blur` rects.
9. **Final** — either the preview render is the final (check loudness ≈ −14 LUFS, peak ≤ −1 dB with
   `ebur128=peak=true`), or assemble in Resolve with the returned `timeline` (V1 shots, V2 overlay, A1 voice, A2 bed)
   and render 1080×1920 (`video-toolkit` §5).

Changing the voice later: regenerate narration + word timings, rebuild — every cut is anchored to words, so the edit
re-times itself.

Done = a 1080×1920 MP4 in `<project>/renders/` the user approved, plus `short.json` so it can be rebuilt.
