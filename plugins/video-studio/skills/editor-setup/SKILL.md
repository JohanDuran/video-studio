---
name: editor-setup
description: "Install only the MangoAI editor, done by Claude end to end: checks Node.js and ffmpeg (installs them with one approval), warms the pinned MangoAI package, opens the editor and checks its version. No Docker, no media toolbox, no GPU, no Hugging Face. For a PC without an NVIDIA GPU or Docker, or someone who only wants to edit and export with Claude. Use when the user runs /editor-setup or asks to install just the editor; /studio-setup installs everything."
argument-hint: "[check]"
---

# Editor setup (MangoAI only)

Goal: the MangoAI editor working on this PC at the version this plugin pins, with nothing else installed. MangoAI is
the editor in a browser tab at `http://localhost:4780`: timeline, live preview, Claude's edits and requests, and the
final export (ffmpeg on the host). HyperFrames animations render inside it too (the renderer comes with the package).

**You (Claude) do the whole setup.** Run every check and install yourself and report each as ✓ / ✗. Rules as in
`studio-setup`: free tools only, **one approval** for all installs after the checks, and leave installs that need admin
rights to the user with the exact command. `check` as the argument → §1 only, change nothing.

What this does **not** set up, and what that means (say it once, plainly):
- **No media toolbox** (Docker): no transcription (so no word timings or word-timed captions from audio), no generated
  voices (Kokoro or cloned), no generated sounds or music, no FLUX images. The user brings their own recordings, voice,
  music and sounds. `/studio-setup` adds the toolbox later, any time.
- The plugin still lists a `media-toolbox` MCP server; it shows as not connected in `/mcp`. That's expected.

## 1. Check

Read `${CLAUDE_PLUGIN_ROOT}/versions.json` first (`mangoai.version`, `mangoai.package`, `mangoai.min_node`); use exactly
those, never `latest`.

| Check | How | If it fails |
|---|---|---|
| Node.js ≥ `mangoai.min_node` | `node --version` | `winget install -e --id OpenJS.NodeJS.LTS`, then a new Claude session (the editor's MCP server needs Node at start-up) |
| ffmpeg | `ffmpeg -version` | `winget install -e --id Gyan.FFmpeg`, then open a new terminal / session so it's on PATH |
| MangoAI tools loaded | `mcp__plugin_video-studio_mangoai__*` tools are available | Fixed by §2 |
| Editor version | after §2, `GET http://localhost:4780/api/health` | §3 |
| Duplicate MangoAI | `claude mcp get mangoai` shows a **user-scope** `mangoai`, or `~/.claude/settings.json` has a UserPromptSubmit hook running MangoAI's `hook.mjs` | `studio-setup` §1e |

Show one list (✓, what you'll install, what only they can do), ask once, then do it all.

## 2. Install the editor

Nothing to clone or register: this plugin's `.mcp.json` starts the pinned `mangoai` package through
`tools/mangoai-launch.mjs`, and `hooks/hooks.json` tells Claude what the user saved in the editor.

1. Warm the package so the MCP server starts fast (the first download can exceed its start-up timeout):
   `npx -y --package=<mangoai.package> mangoai version` → prints `mangoai.version`.
2. If MangoAI's tools weren't loaded this session (Node was missing or the download timed out): the user runs `/mcp`
   → `plugin:video-studio:mangoai` → reconnect, or starts a new session. Wait for them, then go on.

## 3. Check it works

1. Make a small test project so there's something to open: `<studio or home>/mangoai-test/` with a 5 s clip made by
   ffmpeg (`ffmpeg -f lavfi -i testsrc2=s=1280x720:d=5 -f lavfi -i sine=d=5 -shortest -pix_fmt yuv420p test.mp4`).
   Skip it if the user names a folder with their own footage.
2. `project_open` on that folder: it starts the editor server and opens the editor in their browser.
3. `GET http://localhost:4780/api/health` → `{"app":"mangoai","version":"<mangoai.version>"}`. Another version means
   an old editor server is still running: stop the process listening on port 4780 and run `project_open` again.
4. Ask the user to drag the clip on the timeline and press Save; `changes_since` should show their save. That proves
   the editor, Claude's tools and the hook all work.

## 4. Wrap up

Short summary: Node, ffmpeg and MangoAI versions; the editor link (http://localhost:4780); what they can do now (open
a folder with footage, ask Claude to cut, trim, add titles and HyperFrames animations, mix their own audio, export);
what's not installed and that `/studio-setup` adds it (toolbox for transcription, voices and sounds; the
channel profile that `/short`, `/explainer` and `/edit-recording` use). Offer to delete the test project.

Updates: after `claude plugin marketplace update video-studio`, run `/editor-setup` again; it warms the newly pinned
version.
