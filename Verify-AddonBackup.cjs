const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const cp = require('node:child_process');
const assert = require('node:assert/strict');
const root = __dirname;
const manifest = JSON.parse(fs.readFileSync(path.join(root, 'installed-addons-manifest.json'), 'utf8'));
const game = 'D:\\Blizzard Games\\World of Warcraft\\_forever_\\Interface\\AddOns';
const sha256 = (data) => crypto.createHash('sha256').update(data).digest('hex');
function walk(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const target = path.join(dir, entry.name);
    assert(!fs.lstatSync(target).isSymbolicLink(), 'Unexpected link: ' + target);
    return entry.isDirectory() ? walk(target) : [target];
  });
}
for (const entry of manifest.files) {
  const stored = path.join(root, 'AddOns', ...entry.relative.split('/'));
  const current = path.join(game, ...entry.relative.split('/'));
  assert.equal(sha256(fs.readFileSync(stored)), entry.sha256, 'Snapshot mismatch: ' + entry.relative);
  assert.equal(sha256(fs.readFileSync(current)), entry.sha256, 'Game file changed: ' + entry.relative);
}
const actual = walk(path.join(root, 'AddOns')).map(f => path.relative(path.join(root, 'AddOns'), f).split(path.sep).join('/')).sort();
assert.deepEqual(actual, manifest.files.map(e => e.relative).sort());
assert.deepEqual(fs.readdirSync(game, { withFileTypes: true }).filter(e => e.isDirectory()).map(e => e.name).sort(), manifest.addons.map(a => a.name).sort());
const secrets = /(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}|AKIA[0-9A-Z]{16}|-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----)/;
const translations = walk(path.join(root, 'local-koKR'));
for (const file of translations) {
  assert(!/(?:^|[\\/])(?:\.git|\.env(?:\.[^\\/]*)?|node_modules|SavedVariables)(?:[\\/]|$)/i.test(file));
  assert(!secrets.test(fs.readFileSync(file, 'utf8')), 'Possible credential: ' + file);
}
const git = (...args) => cp.execFileSync('git', args, { cwd: root, encoding: 'utf8' });
for (const folder of ['ForeverQuestHelper', 'ForeverTrainerHelper', 'ForeverFlightMap']) {
  const paths = walk(path.join(root, folder));
  for (const file of paths) {
    const relative = path.relative(path.join(root, folder), file);
    const installed = path.join(root, 'AddOns', folder, relative);
    assert(fs.existsSync(installed) && sha256(fs.readFileSync(file)) === sha256(fs.readFileSync(installed)), 'Development/installed source differs: ' + folder + '/' + relative);
  }
}
if (process.argv.includes('--index')) {
  const staged = new Map(git('ls-files', '--stage', '-z').split('\0').filter(Boolean).map(line => {
    const [mode, object, rest] = line.split(' ');
    assert(rest.startsWith('0\t'), 'Unmerged index entry');
    return [rest.slice(2), object];
  }));
  const algorithm = git('rev-parse', '--show-object-format').trim();
  for (const file of [...walk(path.join(root, 'AddOns')), ...translations]) {
    const relative = path.relative(root, file).split(path.sep).join('/');
    const content = fs.readFileSync(file);
    const object = crypto.createHash(algorithm).update(Buffer.from('blob ' + content.length + '\0')).update(content).digest('hex');
    assert.equal(staged.get(relative), object, 'Git backup differs from file bytes: ' + relative);
  }
}
console.log(JSON.stringify({ result: 'PASS', addons: manifest.addons.length, installedFiles: actual.length, translationFiles: translations.length, allSHA256Match: true, knownCredentialPatternsFound: false, gitIndexChecked: process.argv.includes('--index') }));
