# The video-studio ecosystem: three repos, one product

video-studio is made of three repositories that are developed separately and **released together**. A change in one
can break the other two, so read this before changing anything listed under *Contracts*.

| Repo | Role | Ships as |
|---|---|---|
| [video-studio](https://github.com/JohanDuran/video-studio) (this repo) | The front door: Claude Code plugin with the skills, `/studio-setup`, the MCP registrations and the MangoAI hook. Pins the other two | Plugin marketplace (`claude plugin install video-studio@video-studio`) |
| [media-toolbox](https://github.com/JohanDuran/media-toolbox) | Makes media: Docker stack with WhisperX, Kokoro, Chatterbox, Stable Audio, FLUX, ffmpeg behind one gateway (dashboard, REST, MCP) | Images on ghcr.io + `get.ps1` (no clone), per release tag |
| [MangoAI](https://github.com/JohanDuran/MangoAI) | Edits and renders: the editor (browser tab), its server, its MCP server and hook | The `mangoai` npm package (GitHub release tarball; npm when published), per release tag |

```
 user ──/studio-setup──► video-studio plugin ──.mcp.json──► media-toolbox MCP  (http://localhost:8765/mcp)
                                │                └────────► MangoAI MCP       (npx mangoai mcp → editor on :4780)
                                └──hooks.json──► MangoAI hook (reports the user's saves)
                         MangoAI server ──REST──► media-toolbox (Toolbox tab: sounds, voice lines, transcription)
```

## Setup for a new user

1. `claude plugin marketplace add JohanDuran/video-studio` and `claude plugin install video-studio@video-studio`.
2. New session, `/studio-setup`. Claude does the rest: checks the machine, installs the toolbox release pinned in
   `plugins/video-studio/versions.json` (no clone), warms the pinned MangoAI package, writes the profile. The user only
   does what needs them: Docker Desktop, a Hugging Face login, approving the installs.

## Compatibility

`plugins/video-studio/versions.json` is the source of truth; this table is its history.

| video-studio | media-toolbox | MangoAI | Notes |
|---|---|---|---|
| 0.9.0 | v0.5.0 (min v0.5.0) | 0.2.0 | First release-pinned set: toolbox installs without a clone and reports its `version`; MangoAI runs from its package; the plugin registers MangoAI and its hook |
| 0.8.0 | v0.4.0 | clone of `main` | MangoAI registered by hand (`npm run claude-setup`) |

## Contracts (what one repo relies on in another)

Change any of these only together with the repos that use them, and bump versions as in *Releasing*.

| # | Contract | Owned by | Used by |
|---|---|---|---|
| 1 | MCP tool names, parameters and results (`transcribe`, `speak`, `speak_clone`, `sfx_*`, `image_generate`, `ffmpeg`, `short_info`, jobs …), `gateway/app/mcp_tools.py` | media-toolbox | video-studio skills |
| 2 | REST API: `GET /api/state`, `POST /api/jobs`, `POST /api/jobs/{id}/wait`, `GET /api/library`, `POST /api/library/mark` | media-toolbox | MangoAI `packages/server/src/toolbox.ts` |
| 3 | Address `http://localhost:8765`, MCP at `/mcp` | media-toolbox | plugin `.mcp.json`, MangoAI (`MANGO_TOOLBOX_URL`) |
| 4 | `version` in `/api/state` and `toolbox_status` | media-toolbox | `/studio-setup` version checks |
| 5 | Installer: `get.ps1 -Version`, `install.ps1` parameters, install folder `~/.video-studio/media-toolbox`, `VIDEO_STUDIO_SETUP=1`, the files `get.ps1` downloads | media-toolbox | `/studio-setup` §1a, `scripts/check-ecosystem.mjs` |
| 6 | The `short.json` format, `docs/short-spec.md` | media-toolbox | MangoAI importer/exporter (`packages/core/src/import/shortJson.ts`), `/short` skill |
| 7 | MCP tool names and behaviour (`project_open`, `project_state`, `edit`, `apply_ops`, `comp_*`, `export` …) | MangoAI | video-studio skills |
| 8 | CLI `mangoai mcp`, `mangoai start`, `mangoai version`; package name and tarball `mangoai-<v>.tgz` on release `v<v>` | MangoAI | plugin `tools/mangoai-launch.mjs`, `versions.json` |
| 9 | Hook `packages/mcp/hook.mjs` and what it reads (`~/.mangoai/projects.json`, `<project>/.mangoai/claude.json`) | MangoAI | plugin `hooks/mangoai-hook.mjs` (a copy; CI checks it matches) |
| 10 | `GET http://localhost:4780/api/health` → `{app: "mangoai", version}` | MangoAI | `/studio-setup` |
| 11 | `MANGOAI_REPO` / `MANGOAI_PACKAGE` (run a clone / another build) | plugin launcher + MangoAI `bin` | developers |
| 12 | Studio pointer `~/.video-studio/config.json` (`studio`, `channels`, `default_channel`) and the studio layout (`sfx_library/`, `voices/`, `recordings/`, `_scratch/`) | video-studio (`/studio-setup`) | MangoAI server (`studioRoot`), media-toolbox `.env` defaults |

## Releasing

Order matters, because the plugin pins the other two:

1. **media-toolbox**: merge, bump nothing in code (the tag is the version), push tag `vX.Y.Z`. The `images` workflow
   builds and pushes every image with `TOOLBOX_BUILD_VERSION=vX.Y.Z`.
2. **MangoAI**: bump `packages/core/src/version.ts` and `packages/cli/package.json` (the build refuses a mismatch),
   merge, push tag `vX.Y.Z`. The `release` workflow builds the package, attaches `mangoai-X.Y.Z.tgz` to the GitHub
   release and publishes to npm when the `NPM_TOKEN` secret is set. If the hook changed, copy it to this plugin.
3. **video-studio**: update `plugins/video-studio/versions.json` (and `plugin.json` / `marketplace.json` versions),
   add a row to the table above, run `node scripts/check-ecosystem.mjs` (all `ok`), merge.
   Users get it with `claude plugin marketplace update video-studio` and `/studio-setup update`.

A change that stays inside one repo and touches no contract needs only that repo's own release (or none).
