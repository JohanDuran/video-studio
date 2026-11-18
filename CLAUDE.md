# video-studio: notes for Claude

**This repo is one of three that work together** and it is the one that ties them: the plugin pins the media-toolbox
and MangoAI releases in `plugins/video-studio/versions.json`, registers both MCP servers (`.mcp.json`), ships MangoAI's
hook (`hooks/`) and installs everything through `/studio-setup`. Read [ECOSYSTEM.md](ECOSYSTEM.md) before changing a
skill that calls another repo's tools, the launcher, the pins or the setup: it lists the contracts, the compatibility
table and the release order.

- Run `node scripts/check-ecosystem.mjs` after touching `versions.json`, the manifests or the hook copy; CI runs it too.
- Plugin version: `versions.json` `plugin`, `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` agree.
- `hooks/mangoai-hook.mjs` is a copy of MangoAI's `packages/mcp/hook.mjs`; change it there first.
- Skills address the user's tools generically: no personal channel names or paths in examples.
