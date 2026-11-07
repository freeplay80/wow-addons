// Apply the version-specific display-only patch to a fresh local staging copy.
const fs = require('node:fs');
const path = require('node:path');
const root = path.join(__dirname, 'HanharEnhancementHUD');
const groups = new Map();
const dictionary = new Map();
let keys;
for (const line of fs.readFileSync(path.join(__dirname, 'Hanhar-ui.txt'), 'utf8').split(/\r?\n/)) {
  if (!line.trim()) continue;
  if (line.startsWith('# ')) {
    groups.set(line.slice(2), keys = new Map());
    continue;
  }
  const [en, ko] = line.split('\t');
  if (!keys || !en || !ko || keys.has(en) || (dictionary.has(en) && dictionary.get(en) !== ko)) {
    throw new Error('Bad translation entry: ' + line);
  }
  keys.set(en, ko);
  dictionary.set(en, ko);
}
const luaTokens = /--\[(=*)\[[\s\S]*?\]\1\]|--[^\r\n]*|\[(=*)\[[\s\S]*?\]\2\]|"(?:\\[\s\S]|[^"\\])*"|'(?:\\[\s\S]|[^'\\])*'/g;
const staged = new Map();
for (const [file, strings] of groups) {
  if (file === 'Dynamic') continue;
  const source = fs.readFileSync(path.join(root, file + '.lua'), 'utf8');
  const used = new Set();
  let modified = source.replace(luaTokens, (token) => {
    if (token[0] !== '"' || !strings.has(token.slice(1, -1))) return token;
    used.add(token.slice(1, -1));
    return 'T(' + token + ')';
  });
  if (used.size !== strings.size) {
    throw new Error(file + ': missing ' + [...strings.keys()].filter((key) => !used.has(key)).join(', '));
  }
  modified = modified.replace(/^(local [^\r\n]+, ns = \.\.\.)(\r?\n)/m, '$1$2local T = ns.Text$2');
  if (!modified.includes('local T = ns.Text')) throw new Error('Missing namespace in ' + file);
  staged.set(file + '.lua', modified);
}
const quote = (s) => '"' + s + '"';
const entries = [...dictionary].map(([en, ko]) => '  [' + quote(en) + '] = ' + JSON.stringify(ko) + ',');
staged.set('Locale.lua', [
  'local _, ns = ...',
  '',
  'local koKR = {',
  ...entries,
  '}',
  '',
  'local texts = GetLocale() == "koKR" and koKR or nil',
  'function ns.Text(english)',
  '  return texts and texts[english] or english',
  'end',
  '',
].join('\n'));
for (const [file, data] of staged) fs.writeFileSync(path.join(root, file), data);
console.log('Localized ' + dictionary.size + ' phrases across ' + (staged.size - 1) + ' files.');
