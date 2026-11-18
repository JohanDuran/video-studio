#!/usr/bin/env node
// Starts MangoAI's MCP server for this plugin (see .mcp.json), at the MangoAI version pinned in versions.json.
//   default        npx runs the pinned `mangoai` package (the GitHub release tarball, or npm), cached after the first run
//   MANGOAI_REPO   path to a MangoAI clone: run its sources instead (for MangoAI development)
//   MANGOAI_PACKAGE  any npm spec to run instead of the pinned one (e.g. mangoai@0.3.0-beta.1, a .tgz path)
// stdio passes straight through: this process is only a launcher. Part of the three-piece setup in ECOSYSTEM.md.
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const pins = JSON.parse(fs.readFileSync(path.join(root, 'versions.json'), 'utf-8'));
const sub = process.argv[2] ?? 'mcp';

let cmd;
let args;
const repo = process.env.MANGOAI_REPO;
const tsx = repo && path.join(repo, 'node_modules', 'tsx', 'dist', 'cli.mjs');
if (repo && fs.existsSync(tsx)) {
  const main = { mcp: 'packages/mcp/src/main.ts', start: 'packages/server/src/main.ts' }[sub];
  cmd = process.execPath;
  args = [tsx, path.join(repo, main)];
} else {
  if (repo) process.stderr.write(`MANGOAI_REPO=${repo} has no node_modules (run npm install there); using the pinned package.\n`);
  const spec = process.env.MANGOAI_PACKAGE || pins.mangoai.package || `mangoai@${pins.mangoai.version}`;
  cmd = 'npx';
  args = ['-y', `--package=${spec}`, 'mangoai', sub];
}

// npx is npx.cmd on Windows, which needs a shell; quote arguments that contain spaces.
const win = process.platform === 'win32' && cmd === 'npx';
const child = spawn(win ? `npx ${args.map((a) => (/[\s"]/.test(a) ? `"${a}"` : a)).join(' ')}` : cmd, win ? [] : args, {
  stdio: 'inherit',
  shell: win,
  windowsHide: true,
});
child.on('exit', (code, signal) => process.exit(signal ? 1 : (code ?? 0)));
for (const s of ['SIGINT', 'SIGTERM']) process.on(s, () => child.kill(s));
