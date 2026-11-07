// Snapshot addon files only; never traverses the game's WTF, logs or account settings.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const sourceRoot = 'D:\\Blizzard Games\\World of Warcraft\\_forever_\\Interface\\AddOns';
const destinationRoot = path.join(__dirname, 'AddOns');
const manifestFile = path.join(__dirname, 'installed-addons-manifest.json');
const rootStat = fs.lstatSync(sourceRoot);
assert(rootStat.isDirectory() && !rootStat.isSymbolicLink());
const digest = (data) => crypto.createHash('sha256').update(data).digest('hex');
const forbidden = /^(?:\.git|\.env(?:\..*)?|credentials(?:\..*)?|WTF|SavedVariables|node_modules)$/i;
const secretPattern = /(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}|AKIA[0-9A-Z]{16}|-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----)/;
const entries = [];
const addons = [];

function collect(dir, segments) {
  const stat = fs.lstatSync(dir);
  assert(!stat.isSymbolicLink(), 'Link not allowed: ' + segments.join('/'));
  if (stat.isDirectory()) {
    for (const child of fs.readdirSync(dir, { withFileTypes: true })) {
      assert(!forbidden.test(child.name), 'Review required: ' + [...segments, child.name].join('/'));
      collect(path.join(dir, child.name), [...segments, child.name]);
    }
    return;
  }
  assert(stat.isFile(), 'Unexpected file type');
  assert(stat.size < 50 * 1024 * 1024, 'Review large file: ' + segments.join('/'));
  const content = fs.readFileSync(dir);
  const relative = segments.join('/');
  assert(!secretPattern.test(content.toString('utf8')), 'Possible credential in ' + relative);
  entries.push({ relative, bytes: content.length, sha256: digest(content), content });
}

for (const addon of fs.readdirSync(sourceRoot, { withFileTypes: true }).filter(e => e.isDirectory()).sort((a,b) => a.name.localeCompare(b.name))) {
  assert(!forbidden.test(addon.name), 'Unexpected addon directory: ' + addon.name);
  const start = entries.length;
  collect(path.join(sourceRoot, addon.name), [addon.name]);
  const addonFiles = entries.slice(start);
  assert(addonFiles.some(e => e.relative.endsWith('.toc')), 'Missing TOC: ' + addon.name);
  addons.push({ name: addon.name, files: addonFiles.length, bytes: addonFiles.reduce((s,e) => s + e.bytes,0) });
}
assert(entries.length > 0);
let previous = new Map();
if (fs.existsSync(destinationRoot)) {
  assert(process.argv.includes('--refresh'), 'Snapshot exists; use --refresh only after comparing changes.');
  assert(!fs.lstatSync(destinationRoot).isSymbolicLink());
  const old = JSON.parse(fs.readFileSync(manifestFile, 'utf8'));
  previous = new Map(old.files.map(e => [e.relative, e]));
  const incoming = new Set(entries.map(e => e.relative));
  for (const prior of old.files) {
    assert(incoming.has(prior.relative), 'Source file removed; review before deleting: ' + prior.relative);
    const target = path.join(destinationRoot, ...prior.relative.split('/'));
    assert.equal(digest(fs.readFileSync(target)), prior.sha256, 'Snapshot edited separately: ' + prior.relative);
  }
} else {
  fs.mkdirSync(destinationRoot);
}
for (const entry of entries) {
  const target = path.join(destinationRoot, ...entry.relative.split('/'));
  fs.mkdirSync(path.dirname(target), { recursive: true });
  if (fs.existsSync(target)) {
    assert(previous.has(entry.relative), 'Unexpected snapshot file: ' + entry.relative);
    assert(!fs.lstatSync(target).isSymbolicLink());
  }
  fs.writeFileSync(target, entry.content, { flag: previous.has(entry.relative) ? 'w' : 'wx' });
  assert.equal(digest(fs.readFileSync(target)), entry.sha256);
  // Ensure the game copy did not change while it was being snapshotted.
  assert.equal(digest(fs.readFileSync(path.join(sourceRoot, ...entry.relative.split('/')))), entry.sha256, 'Game file changed: ' + entry.relative);
}
const manifest = {
  snapshotDate: '2026-11-08',
  source: '_forever_/Interface/AddOns',
  description: 'Installed addon files including local Korean translations. No WTF or account settings.',
  addons,
  files: entries.map(({ content, ...entry }) => entry),
};
fs.writeFileSync(manifestFile, JSON.stringify(manifest, null, 2) + '\n');
console.log(JSON.stringify({
  addons: addons.length,
  files: entries.length,
  bytes: entries.reduce((sum,e) => sum + e.bytes,0),
  largestBytes: Math.max(...entries.map(e => e.bytes)),
  allHashesMatch: true,
  destination: destinationRoot,
  names: addons.map(a => a.name),
}));
