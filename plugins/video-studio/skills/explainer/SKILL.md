---
name: explainer
description: "Make a faceless explainer video about a topic, with no footage: script, a voiceover in the voice the user picks (Kokoro or a cloned voice from the media toolbox, or their own recording), word timings, and invented visuals per scene (typography, diagrams, data-viz) built in HyperFrames, assembled and rendered locally in the MangoAI editor. 16:9 by default, 9:16 on request. Use when the user runs /explainer <topic> or asks for an explainer, concept breakdown, how-to or listicle video without recordings."
argument-hint: "<topic> [vertical]"
---

# /explainer — faceless explainer

Topic: `$ARGUMENTS`. Add `vertical` for 9:16; default 16:9 at 1920×1080.

**Plan first.** Look for `plan.md` in the project folder (the working folder, or the project named in the arguments).
- `Status: approved` → build exactly that plan: its beats, sources, narration and format. If something in it turns
  out impossible, stop and ask before changing the plan.
- Missing, or still a draft → don't build. Run the `plan` skill with the topic (it discusses the idea with the user and
  picks the tools per beat), and continue here only once the plan is approved.


Before anything: read the profile (`video-toolkit` §0) and follow `editing-rules`. This skill drives the HyperFrames
explainer workflow from the `hyperframes` skill (installed by `/studio-setup`) but swaps every paid step for the toolbox:

| HyperFrames step | Use instead |
|---|---|
| HeyGen TTS / voices | the voice the plan names, which the user chose: toolbox `speak` (Kokoro), `speak_clone` (a cloned voice profile), or the user's own recording |
| HeyGen / hosted transcription | toolbox `transcribe` (word timings) |
| `media-use resolve --type bgm\|sfx`, generated music | toolbox `sfx_search` → `sfx_generate` |
| AI image/video generation, avatars | Usually typography, shapes, diagrams, icons, data-viz. When a scene needs an image that doesn't exist, toolbox `image_generate` (local FLUX, optional, `video-toolkit` §2b). A real photo the plan names goes in a scene as a photo card with a slow zoom. No avatars or generated video |
| `hyperframes cloud render`, lambda, cloudrun, `auth login` | MangoAI `export` (local; one comp per scene), or MangoAI `comp_render` (local) for a single composition |

If HyperFrames isn't installed, or MangoAI's tools (`mcp__plugin_video-studio_mangoai__*`, or `mcp__mangoai__*` from an older user-level install) are missing, stop and offer `/studio-setup`.

Project folder: `<channel folder>/<ProjectName>/` (`video-toolkit` §0), HyperFrames project in `<project>/animations/`.

## Steps

Use only the tools the plan needs: a music bed, SFX, registry blocks or footage are options, not requirements.
Skip any part of a step that the video doesn't need.

1. **Brief** — take audience, length, tone, format and the beats (one idea per scene) from the approved `plan.md`.
   If the plan routes some beats to footage or Blender, build those as the plan says and place them as scenes.
2. **Script** → `script.json` (one spoken line per entry, grouped by scene).
3. **Voice** — per line with the plan's narration voice (`speak`, `speak_clone` or the user's takes; if the plan
   doesn't say, ask), trim silences, join (`video-toolkit` §3) → `audio/narration.wav`; user listens.
4. **Word timings** — `transcribe` the narration (`language`, `vocab` from the profile) → `transcripts/narration.words.tsv`.
   Scene starts and animation triggers come from these words.
5. **Visuals** — follow the HyperFrames skills (`hyperframes` for the explainer workflow and motion,
   `hyperframes-registry` before hand-building a named effect) to build **one composition per scene** in
   `animations/<scene>/index.html`, sized to the frame (1920×1080, or 1080×1920 vertical), with
   `data-duration` = the scene's length and any background on the root element, not `body` (MangoAI renders comps
   with transparency, so a `body` background comes out black). No audio inside the comps.
6. **Assemble in MangoAI** — write `<project>/cut.json` (format: MangoAI `docs/PROJECT_FORMAT.md`):
   `width`/`height`/`fps`, `transcripts: {"narration": "transcripts/narration.words.tsv"}`, a `graphics` track with
   one `comp` clip per scene (`comp: "animations/<scene>"`, `start`/`end` anchored to words, e.g.
   `"word:imagine - 0.1"`), an `audio` track `role: "voice"` with the narration clip (`transcript: "narration"`), and
   optionally a `role: "music"` track with a bed from the sound library (`loop: true`, gain ~ −22 dB). Then
   `project_open`: fix every `problems` entry, check `frame` at each scene's start and on key words, and give the
   user the editor link to watch it live (`http://localhost:4780/?dir=<project folder>`). Scene tweaks: `comp_stills`
   on one scene, the user's requests via `requests_list`.
7. **Render** — MangoAI `export` → `<project>/renders/<project>-r<revision>.mp4` (only changed scenes re-render). Check
   loudness ≈ −14 LUFS, peak ≤ −1 dB. (One single HyperFrames composition instead of scenes: MangoAI `comp_render`,
   format `mp4`, fps 30 or 60.)
8. Optional: finish in Resolve: `export_otio`, then File → Import → Timeline (`video-toolkit` §5).

Done = an approved MP4 in `<project>/renders/`, with `cut.json` and the scene comps kept so scenes can be re-timed after
a new voice take (the words reload and the anchored scenes follow).
