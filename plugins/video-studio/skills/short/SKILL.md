---
name: short
description: "Build a vertical Short (9:16, ~20–60 s) from an approved plan.md: script, a voiceover in the voice the user picked (Kokoro, a cloned voice or their own) and word timings from the media toolbox, footage only where the plan calls for it, a short.json edit, then preview, hand fixes and the final export in the MangoAI editor, with a privacy check. Starts with the plan skill when there's no approved plan. Use when the user runs /short <topic> or asks for a Short, Reel or TikTok."
argument-hint: "<topic>"
---

# /short — vertical Short

Topic: `$ARGUMENTS`.

**Plan first.** Look for `plan.md` in the project folder (the working folder, or the project named in the arguments).
- `Status: approved` → build exactly that plan: its beats, sources, narration and format. If something in it turns
  out impossible, stop and ask before changing the plan.
- Missing, or still a draft → don't build. Run the `plan` skill with the topic (it discusses the idea with the user and
  picks the tools per beat), and continue here only once the plan is approved.


Before anything: read the profile (`video-toolkit` §0) and follow `editing-rules`. Two tools, one job each
(`video-toolkit` §1b): the **media toolbox** makes the voice, word timings, sounds and images (GPU models), and
**MangoAI** previews, edits and renders the video. Check `toolbox_status`; if it fails, stop and help the user start
Docker. Check MangoAI's tools are there (`mcp__plugin_video-studio_mangoai__*`, or `mcp__mangoai__*` from an older user-level install); if not, stop and point to `/studio-setup` (MangoAI
section). The `short.json` format is in the toolbox repo's `docs/short-spec.md` (`toolbox.repo_dir` in the
profile) — read it before writing the spec.

Project folder: `<channel folder>/<ProjectName>/` (`video-toolkit` §0; agree a short PascalCase or snake_case name with the user).

## Steps

Use only the tools the plan's beats need: music, SFX, graphics, captions, and footage types are all optional.
Skip any part of a step that the video doesn't need.

1. **Shot list** — from the approved plan, write `shot_list.md`: per spoken line, what's on screen and its source
   (an existing file, a HyperFrames render, a still, or a screen capture the plan asks for).
   Hook in the first 2 s, fast pace, no dead air.
2. **Script** → `script.json`: one short spoken line per entry.
3. **Voice** — the voice the plan's `## Narration` names (the user chose it; if it's missing, ask, don't pick).
   Voice each line into `audio/lines/`: Kokoro → `speak` with that voice and speed; cloned voice → `speak_clone` with
   `voice=<profile>` (numbers are spelled out for you; keep one `seed` for the whole script); user records it → their
   takes, cut per line. Trim each line's silences (filter in `video-toolkit` §3), join with ~0.1 s gaps →
   `audio/narration.wav`. Let the user listen to it.
4. **Word timings** — `transcribe` `audio/narration.wav` with `language` from the profile and `vocab` =
   `transcription.vocab` plus any new names in the script → `transcripts/narration.words.tsv`.
5. **Visual sources, as the plan says** — for each beat, only the source the plan chose:
   - existing recordings or camera/phone clips: find regions and moments with `short_frames` or contact sheets;
   - HyperFrames graphics that are whole shots: build them in `animations/<name>/`, then MangoAI `comp_render`
     (`folder`, `output: <project>/edit/<name>.mp4`, or `format: mov` for a transparent overlay) into `edit/`
     (short.json uses them as shot sources). Graphics over the edit can instead be added after step 7 as MangoAI comps
     (`comp_create`): they play live and MangoAI renders them at export (put any background on the root element,
     not `body`: comps render with transparency);
   - stills: produce them into `edit/` or `capture/`;
   - photos: a still in short.json with zoom keys (a slow push), or a HyperFrames photo card. No parallax tool any
     more;
   - images the plan marks as generated: `image_generate` with `size: 9:16` into `edit/`, drafts first, then the
     chosen seed as `final` (`video-toolkit` §2b);
   - screen capture **only for beats the plan marks as screen recording**: record into `capture/`
     (`video-toolkit` §4) after asking for a hands-off window. Never record the screen on your own initiative.
6. **`short.json`** — sources, crop regions, privacy blurs, anchors (`word:so - 0.05`, `word:use#2`), shots back to
   back with zoom keys, graphics (Head/Big/Tag/shape cards), captions, audio (music bed + SFX timed by their measured
   peak). Search the sound library before generating anything; send new SFX variations to the user to audition and
   record verdicts with `sfx_mark`.
7. **Open in MangoAI** — `project_open` on the project folder. It imports `short.json` (never changes it) and opens
   the editor tab: live preview, no render. Read `project_state`: fix every entry in `problems` (an anchor that
   doesn't resolve, a missing file) in `short.json`, which re-imports on the next open, until there are none. Check
   frames with `frame` (the live composite, graphics included) at each section's start and on key words. Give the
   user the editor link (`http://localhost:4780/?dir=<project folder>`) to watch it there.
8. **Privacy check** — `frame` at every shot's first AND last frame (zooms change what's visible)
   for anything in `channel.never_show`: town/addresses, device name, email, other chats/tabs, other people's content.
   Prefer frozen stills where the user scrolled; blur with `blur` rects.
9. **Hand fixes and requests** — the user can now trim, move, nudge and re-level by hand, or point at something
   and leave a request (R in the editor). From here on, edit with MangoAI's tools (`edit`, `apply_ops`, `comp_*`,
   with `base` = the current revision), not by rewriting `short.json`: the first Save wrote `cut.json`, which is now
   the project. Before each turn's work, the MangoAI hook tells you what the user saved and asked; read it with
   `changes_since` / `requests_list`.
10. **Final** — `export` (only changed parts re-render; `renders/<project>-r<revision>.mp4`). **Fallback, unattended
    runs included:** if MangoAI can't open or export the project (a tool error twice in a row), build with the
    toolbox's deprecated `short_build` → `short_preview` instead, copy `edit/preview.mp4` to `renders/`, and log
    what failed (it still works; never skip a scheduled post because of MangoAI). Check loudness
    ≈ −14 LUFS, peak ≤ −1 dB (`ebur128=peak=true`) and show the user.

Changing the voice later: regenerate narration + word timings (same file names). MangoAI reloads the words and
everything anchored to them re-times itself.

Done = a 1080×1920 MP4 in `<project>/renders/` the user approved, plus `cut.json` (and the original `short.json`) so
it can be re-edited and re-exported.
