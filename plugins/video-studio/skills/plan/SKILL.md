---
name: plan
description: "Plan a new video together with the user before anything is produced: discuss the idea, goal, audience, platform and what material already exists, then choose for each beat the tool that fits (screen recording, existing footage, camera/phone clips, HyperFrames motion graphics, Blender 3D, stills, Kokoro voice or the user's own voice, music/SFX) and write plan.md with the reasons. Produces only a plan — nothing is recorded, voiced or rendered. Use when the user runs /plan, wants a new video, has a video idea to discuss, or runs /short, /explainer or /edit-recording without an approved plan."
argument-hint: "[idea or topic]"
---

# /plan — plan a video together

Idea: `$ARGUMENTS` (may be empty, vague, or just a feeling — that's fine).

This is a **conversation, not a pipeline.** The output is an approved `plan.md`. Nothing gets recorded, voiced,
generated or rendered in this skill. Don't start the screen recorder, don't call `speak`, `sfx_generate`,
`render_hyperframes` or `short_build`, don't open Resolve projects.

Before anything: read the profile (`video-toolkit` §0) — channel, language, house rules, recordings folder,
whether there's a GPU (`toolbox.gpu`) — and follow `editing-rules`.

## 1. Understand the idea (talk first)

Ask, in one or two short rounds (use the question tool where available; skip what the user already said):

- **Goal** — what should a viewer think, feel or do after watching? One sentence.
- **Audience** — who, and what they already know.
- **Platform and format** — YouTube long-form (16:9), Shorts/Reels/TikTok (9:16), or both. Rough length.
- **What already exists** — recordings in `recordings.folder`, camera or phone clips, screenshots, earlier renders,
  a Resolve project, or nothing. Look in the recordings folder and the channel folder instead of asking when you can
  (list files, `ffprobe` durations, `short_frames` contact sheets) — read-only.
- **The user's part** — will they be on camera, speak the narration themselves, or prefer Kokoro? Any time limits?

Then **discuss the idea**: say what you think the strongest angle and hook are, offer one or two alternatives, and point
out anything that won't work well (too long for a Short, nothing visual to show, needs footage that doesn't exist).
Let the user push back and change direction. Keep going until the idea is agreed — then plan.

## 2. Pick the tools per beat

Break the video into beats (one idea each; hook first). For **every beat** choose its visual source and say why.
Pick from what this setup can actually do (`video-toolkit` §1). The table is a menu, not a checklist: choose only
what each beat needs, and it's fine for a video to use just one or two of these.

| Source | Good for | Needs |
|---|---|---|
| **Screen recording** (ffmpeg, Claude driving the browser or apps) | Showing a real app, a real result, "watch it happen" proof | Something real on screen worth showing; a hands-off window from the user; a privacy check |
| **Existing footage** (recordings folder, camera, phone) | Reusing what's already shot; the user's face and voice | The files exist — confirm them |
| **New camera/phone footage** | Presence, reactions, real-world objects | The user films it — list exactly what to shoot |
| **HyperFrames motion graphics** | Concepts, steps, lists, numbers, comparisons, diagrams, titles, captions | Nothing but time to build; local render only |
| **Blender 3D** | Objects, products, spatial ideas, a mascot | Blender + the MCP running; slower |
| **Stills / screenshots / diagrams** | A single moment, a before/after, a quote | The image, or a screenshot taken in step 3 |
| **Still → parallax shot** (`image_depth` + `parallax`) | A photo that should feel like footage: a listing's exterior or rooms, a product, a place | A real photo (large, cropped to the photo itself). GPU for the depth map; ~30 s render per shot |
| **Generated image** (`image_generate`, FLUX) | A concept or imagined scene with no real source, a background for a graphic, thumbnail ideas | The toolbox's `flux` profile; ~30–45 s per image. Never for real things (a listing, a product, a person) |
| **Narration** | Kokoro (`voice.default`) for fast iteration, or the user's own voice | Kokoro needs the GPU tools; the user's voice needs a recording session |
| **Music & SFX** | Pace and emphasis | Sound library first (`sfx_search`), Stable Audio if nothing fits |

Rules of thumb:
- **Don't plan a screen recording unless a real screen is the point of the beat.** An idea, a number or a concept is
  usually a HyperFrames graphic, not a recording.
- Prefer material that already exists over new material; prefer graphics over footage that's hard to get.
- **Parallax is an option, not a default.** When a photo would sit on screen for a while and some motion would help,
  you can suggest a parallax shot (name the move, e.g. "push-in on the front door") and let the user choose. A static
  still, a zoom in `short.json`, or no photo at all are just as valid. Don't use it on text-heavy screenshots (prices,
  fact tables, maps): depth moves warp text.
- Respect `house_rules` and `channel.never_show`.
- Mark everything that needs the **user's hands** (filming, speaking, clicking during a demo).

Also list the tools you're **not** using and why (e.g. "No screen recording: nothing on screen to show").

## 3. Write `plan.md`

Agree a project name (the Resolve project name when there will be one). Create `<channel folder>/<ProjectName>/` and
write `plan.md`:

```markdown
# <Title>
Status: draft            ← becomes "approved" only when the user says so
Channel: <name> · Format: 9:16 Short | 16:9 video · Target length: ~45 s · Language: en

## Goal and audience
## Hook (first 2 s)
## Beats
| # | Beat (what's said) | Visual | Source / tool | Why this tool | ~s |
|---|---|---|---|---|---|
## Narration
Kokoro <voice> at <speed> | user's own voice
## Music and SFX
## Not used, and why
## What the user needs to do
(film X, record voice, hands-off window for the demo at beat 3, …)
## Build route
/short | /explainer | /edit-recording | mixed (say which parts go where)
## Open questions
```

## 4. Stop for approval

Show the plan's beats table and the "what you need to do" list. Ask the user to approve or change it. Edit until
they approve, then set `Status: approved` and record the date. Then offer the build route from the plan
(`/short`, `/explainer` or `/edit-recording`, run in this project folder) — don't start it on your own.

Done = an approved `plan.md` in the project folder, and nothing produced yet.
