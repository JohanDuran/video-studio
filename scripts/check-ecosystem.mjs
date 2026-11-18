#!/usr/bin/env node
// Checks that this plugin agrees with the MangoAI and media-toolbox releases it pins (plugins/video-studio/versions.json).
// Run in CI and before a release: node scripts/check-ecosystem.mjs   (needs network; GITHUB_TOKEN helps with rate limits)
// See ECOSYSTEM.md for what each check protects.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const plugin = path.join(repo, 'plugins', 'video-studio');
const read = (f) => fs.readFileSync(f, 'utf-8');
const pins = JSON.parse(read(path.join(plugin, 'versions.json')));
const manifest = JSON.parse(read(path.join(plugin, '.claude-plugin', 'plugin.json')));
const market = JSON.parse(read(path.join(repo, '.claude-plugin', 'marketplace.json')));
const headers = process.env.GITHUB_TOKEN ? { Authorization: `Bearer ${process.env.GITHUB_TOKEN}` } : {};
let failed = 0;
const ok = (m) => console.log(`ok    ${m}`);
const bad = (m) => {
  failed++;
  console.log(`FAIL  ${m}`);
};
async function get(url) {
  const r = await fetch(url, { headers, redirect: 'follow' });
  return { status: r.status, text: r.ok ? await r.text() : '' };
}

// 1. One plugin version everywhere
const v = [pins.plugin, manifest.version, market.metadata.version, market.plugins[0].version];
new Set(v).size === 1 ? ok(`plugin version ${pins.plugin}`) : bad(`plugin versions differ: versions.json, plugin.json, marketplace.json = ${v.join(', ')}`);

// 2. The pinned MangoAI release exists and its tarball matches the version
const m = pins.mangoai;
if (!m.package.includes(`/v${m.version}/`) || !m.package.endsWith(`mangoai-${m.version}.tgz`)) bad(`mangoai.package doesn't point at v${m.version}`);
const tgz = await fetch(m.package, { method: 'HEAD', redirect: 'follow' });
tgz.ok ? ok(`MangoAI ${m.version} release tarball`) : bad(`MangoAI tarball ${m.package} → ${tgz.status} (release not published yet?)`);

// 3. The bundled hook is MangoAI's hook at that version
const hook = await get(`https://raw.githubusercontent.com/JohanDuran/MangoAI/v${m.version}/packages/mcp/hook.mjs`);
const strip = (s) => s.replace(/\r\n/g, '\n').split('\n').filter((l) => !l.startsWith('// COPY of') && !/^\/\/ (MangoAI repo|<project>)/.test(l)).join('\n');
const local = read(path.join(plugin, 'hooks', 'mangoai-hook.mjs'));
if (hook.status !== 200) bad(`MangoAI v${m.version} hook.mjs → ${hook.status}`);
else strip(hook.text) === strip(local) ? ok('hooks/mangoai-hook.mjs matches MangoAI') : bad(`hooks/mangoai-hook.mjs differs from MangoAI v${m.version}/packages/mcp/hook.mjs: copy it over`);

// 4. The pinned toolbox release has the files the setup downloads
const t = pins.media_toolbox;
if (!t.get_script.includes(`/${t.version}/`)) bad(`media_toolbox.get_script doesn't point at ${t.version}`);
for (const f of ['get.ps1', 'install.ps1', 'docker-compose.yml', '.env.example', 'docs/short-spec.md']) {
  const r = await fetch(`https://raw.githubusercontent.com/JohanDuran/media-toolbox/${t.version}/${f}`, { method: 'HEAD', headers });
  r.ok ? ok(`media-toolbox ${t.version}/${f}`) : bad(`media-toolbox ${t.version}/${f} → ${r.status} (tag not pushed yet?)`);
}

process.exitCode = failed ? 1 : 0;
console.log(failed ? `\n${failed} problem(s)` : '\nall pieces agree');
