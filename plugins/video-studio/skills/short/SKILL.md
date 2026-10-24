---
name: short
description: "Make a vertical Short (9:16, ~20–60 s) about a topic with the media toolbox: plan, script, Kokoro voiceover, word timings, screen footage, a short.json edit, short_build and short_preview, a privacy check, then the final render or a Resolve assembly. Use when the user runs /short <topic> or asks for a Short, Reel or TikTok."
argument-hint: "<topic>"
---

# /short — vertical Short

Topic: `$ARGUMENTS` (if empty, propose 3 topics that fit the channel and let the user pick).

Before anything: read the profile (`video-toolkit` §0) and follow `editing-rules`. Check `toolbox_status`;
if it fails, stop and help the user start Docker. The `short.json` format is in the toolbox repo's
`docs/short-spec.md` (`toolbox.repo_dir` in the profile) — read it before writing the spec.

Project folder: `<channel folder>/<ProjectName>/` (`video-toolkit` §0; agree a short PascalCase or snake_case name with the user).

## Steps

1. **Plan** — fit `channel.about` and `channel.language`; check the channel's latest uploads for direction.
   Hook in the first 2 s, fast pace, no dead air, 20–60 s. Write `plan.md` and `shot_list.md` (what's on screen per
   line, which footage it needs). **Stop and agree the plan with the user** before producing anything.
2. **Script** → `script.json`: one short spoken line per entry.
3. **Voice** — `speak` each line with `voice.default` / `voice.speed` into `audio/lines/`, trim each line's silences
   (filter in `video-toolkit` §3), join with ~0.1 s gaps → `audio/narration.wav`. Let the user listen to it.
4. **Word timings** — `transcribe` `audio/narration.wav` with `language` from the profile and `vocab` =
   `transcription.vocab` plus any new names in the script → `transcripts/narration.words.tsv`.
5. **Footage** — reuse existing recordings or record new ones into `capture/` (`video-toolkit` §4; ask for a hands-off
   window first). Use `short_frames` or contact sheets to find regions and moments.
6. **`short.json`** — sources, crop regions, privacy blurs, anchors (`word:so - 0.05`, `word:use#2`), shots back to
   back with zoom keys, graphics (Head/Big/Tag/shape cards), captions, audio (music bed + SFX timed by their measured
   peak). Search the sound library before generating anything; send new SFX variations to the user to audition and
   record verdicts with `sfx_mark`.
7. **Build** — `short_info` (sanity check) → `short_build` → `short_preview`. Read the contact sheet and check frames;
   fix single shots with `only`. Show the preview to the user.
8. **Privacy check** — every shot's first AND last frame (zoom changes what's visible) for anything in
   `channel.never_show`: town/addresses, device name, email, other chats/tabs, other people's content. Prefer frozen
   stills where the user scrolled; blur with `blur` rects.
9. **Final** — either the preview render is the final (check loudness ≈ −14 LUFS, peak ≤ −1 dB with
   `ebur128=peak=true`), or assemble in Resolve with the returned `timeline` (V1 shots, V2 overlay, A1 voice, A2 bed)
   and render 1080×1920 (`video-toolkit` §5).

Changing the voice later: regenerate narration + word timings, rebuild — every cut is anchored to words, so the edit
re-times itself.

Done = a 1080×1920 MP4 in `<project>/renders/` the user approved, plus `short.json` so it can be rebuilt.
