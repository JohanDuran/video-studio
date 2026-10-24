---
name: explainer
description: "Make a faceless explainer video about a topic, with no footage: script, Kokoro voiceover from the media toolbox, word timings, and invented visuals per scene (typography, diagrams, data-viz) built in HyperFrames and rendered locally. 16:9 by default, 9:16 on request. Use when the user runs /explainer <topic> or asks for an explainer, concept breakdown, how-to or listicle video without recordings."
argument-hint: "<topic> [vertical]"
---

# /explainer — faceless explainer

Topic: `$ARGUMENTS`. Add `vertical` for 9:16; default 16:9 at 1920×1080.

Before anything: read the profile (`video-toolkit` §0) and follow `editing-rules`. This skill drives the HyperFrames
explainer workflow from the `hyperframes` skill (installed by `/studio-setup`) but swaps every paid step for the toolbox:

| HyperFrames step | Use instead |
|---|---|
| HeyGen TTS / voices | toolbox `speak` with `voice.default` / `voice.speed` |
| HeyGen / hosted transcription | toolbox `transcribe` (word timings) |
| `media-use resolve --type bgm\|sfx`, generated music | toolbox `sfx_search` → `sfx_generate` |
| AI image/video generation, avatars | skip; use typography, shapes, diagrams, icons, data-viz |
| `hyperframes cloud render`, lambda, cloudrun, `auth login` | toolbox `render_hyperframes` (local) |

If HyperFrames isn't installed, stop and offer `/studio-setup`.

Project folder: `<studio>/<ProjectName>/`, HyperFrames project in `<project>/animations/`.

## Steps

1. **Brief** — audience, length (default 60–120 s; 30–60 s vertical), tone, language from the profile. Write `plan.md`
   with the beats (one idea per scene). **Agree it with the user.**
2. **Script** → `script.json` (one spoken line per entry, grouped by scene).
3. **Voice** — `speak` per line, trim silences, join (`video-toolkit` §3) → `audio/narration.wav`; user listens.
4. **Word timings** — `transcribe` the narration (`language`, `vocab` from the profile) → `transcripts/narration.words.tsv`.
   Scene starts and animation triggers come from these words.
5. **Visuals** — follow the HyperFrames skills (`hyperframes` for the explainer workflow and motion,
   `hyperframes-registry` before hand-building a named effect) to build one sub-composition per scene, timed to the
   words. Put the narration and a music bed (from the sound library, ~ −22 dB under the voice) in the composition.
6. **Check** — `npx hyperframes check` / snapshots; show the user key frames before the full render.
7. **Render** — `render_hyperframes` (format `mp4`, fps 30 or 60) into `<project>/renders/`. Check loudness ≈ −14 LUFS,
   peak ≤ −1 dB.
8. Optional: import into Resolve for hand tweaks (`video-toolkit` §5).

Done = an approved MP4 in `<project>/renders/`, with the HyperFrames project kept so scenes can be re-timed after a new
voice take.
