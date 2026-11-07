const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const dictionaries = require('./supplement.json');
const audit = require('./audit.json');
const root = __dirname;
const read = (relative) => fs.readFileSync(path.join(root, 'original', relative), 'utf8');
const write = (relative, data) => {
  const newline = read(relative).includes('\r\n') ? '\r\n' : '\n';
  fs.writeFileSync(path.join(root, 'source', relative), data.replace(/\r?\n/g, newline));
};
const luaQuote = (value) => JSON.stringify(value).replace(/\\u([0-9a-f]{4})/gi, (_, h) => String.fromCharCode(parseInt(h, 16)));
const entries = (data) => Object.entries(data).map(([key, value]) => '  [' + luaQuote(key) + '] = ' + luaQuote(value) + ',').join('\n');
const marker = '-- Local Korean UI supplement (2026-11-08)';
function append(relative, block) {
  const data = read(relative);
  assert(!data.includes(marker), 'Already patched: ' + relative);
  write(relative, data + '\n' + marker + '\n' + block + '\n');
}
const keepFile = 'KeepOrSell/Locales/Locales.lua';
const keep = read(keepFile);
assert(keep.endsWith('ns.L = L\r\n') || keep.endsWith('ns.L = L\n'));
write(keepFile, keep.replace('ns.L = L', fs.readFileSync(path.join(root, 'KeepOrSell-koKR.lua'), 'utf8') + '\nns.L = L'));
const keepToc = 'KeepOrSell/KeepOrSell.toc';
write(keepToc, read(keepToc).replace('## Title: KeepOrSell', '## Title: KeepOrSell\n## Notes-koKR: 퀘스트 아이템, 전문 기술 재료, 경매 가치에 따라 가방을 보관·경매장·잡동사니 등으로 분류합니다. 가방 가치 표시와 값싼 잡동사니 파괴 버튼을 제공하며 Baganator, Auctionator, Scrap, Questie와 연동합니다.'));

const mapFile = 'ForeverMap/ForeverMap.lua';
let map = read(mapFile);
assert(map.includes('row.sizeTxt:SetText("Size: " .. (data.textSize or 40))'));
map = map.replace('    LOADED = "Loaded",', '    LOADED = "Loaded",\n    SIZE = "Size: ",');
map = map.replace('    L.LOADED = "로드 완료"', '    L.LOADED = "로드 완료"\n    L.SIZE = "크기: "');
map = map.replace('row.sizeTxt:SetText("Size: " .. (data.textSize or 40))', 'row.sizeTxt:SetText(L.SIZE .. (data.textSize or 40))');
write(mapFile, map);

append('Leatrix_Plus/Leatrix_Plus_Locale.lua', 'if GameLocale == "koKR" then\n  local korean = {\n' + entries(dictionaries.Leatrix_Plus) + '\n  }\n  for key, text in pairs(korean) do L[key] = text end\nend');
const byFile = new Map();
for (const [key, value] of Object.entries(dictionaries.Questie)) {
  const found = audit.filter((entry) => entry.addon === 'Questie' && entry.key === key);
  assert.equal(found.length, 1, key);
  if (!byFile.has(found[0].file)) byFile.set(found[0].file, {});
  byFile.get(found[0].file)[key] = value;
}
for (const [file, data] of byFile) {
  append(file, 'local korean = {\n' + entries(data) + '\n}\nfor key, text in pairs(korean) do\n  l10n.translations[key].koKR = text\nend');
}

const hudFile = 'HanharEnhancementHUD/Locale.lua';
append(hudFile, 'if GetLocale() == "koKR" then\n  local korean = {\n' + entries(dictionaries.HanharEnhancementHUD) + '\n  }\n  for key, text in pairs(korean) do koKR[key] = text end\nend');

const traceFile = 'QuestieTrace/QuestieTrace.lua';
let trace = read(traceFile);
const sectionStart = trace.indexOf('-- Slash commands');
const sectionEnd = trace.indexOf('SLASH_QUESTIETRACE1');
assert(sectionStart > 0 && sectionEnd > sectionStart);
const traceTexts = {...dictionaries.QuestieTrace};
const dumpKey = '/qlt dumpmap - Refresh static C_Map hierarchy dump';
delete traceTexts[dumpKey];
let section = trace.slice(sectionStart, sectionEnd);
section = section.replace('string.format("%dm %02ds", mins, secs)', 'l10n("%dm %02ds", mins, secs)');
// Only the display strings inside the slash-command section are changed.
const used = new Set(['%dm %02ds']);
section = section.replace(/"(?:\\.|[^"\\])*"/g, (token) => {
  const value = JSON.parse(token);
  if (!Object.hasOwn(traceTexts, value) || value === '%dm %02ds') return token;
  used.add(value);
  return 'l10n(' + token + ')';
});
assert.equal(used.size, Object.keys(traceTexts).length);
const register = 'local l10n = Core.l10n\nlocal koreanCommands = {\n' + entries(traceTexts) + '\n}\nfor key, text in pairs(koreanCommands) do\n  l10n.translations[key] = { enUS = true, koKR = text }\nend\n\n';
trace = trace.slice(0, sectionStart) + marker + '\n' + register + section + trace.slice(sectionEnd);
write(traceFile, trace);
const dumpFile = 'QuestieTrace/Modules/Dumps/MapHierarchy.lua';
let dump = read(dumpFile);
assert(dump.includes('local Core = QuestieTraceCore'));
dump = dump.replace('local Core = QuestieTraceCore', 'local Core = QuestieTraceCore\n\n' + marker + '\nCore.l10n.translations[' + luaQuote(dumpKey) + '] = { enUS = true, koKR = ' + luaQuote(dictionaries.QuestieTrace[dumpKey]) + ' }');
assert(dump.includes('helpText = ' + luaQuote(dumpKey)));
dump = dump.replace('helpText = ' + luaQuote(dumpKey), 'helpText = Core.l10n(' + luaQuote(dumpKey) + ')');
write(dumpFile, dump);
console.log('Prepared 11 staged files. No installed files changed.');
