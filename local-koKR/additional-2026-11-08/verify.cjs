const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { createHash } = require('node:crypto');
const { lua, lauxlib, lualib, to_luastring: ls, to_jsstring: js } = require('../../tests/quest-route/node_modules/fengari');
const dictionaries = require('./supplement.json');
const audit = require('./audit.json');
const root = __dirname;
const game = 'D:\\Blizzard Games\\World of Warcraft\\_forever_\\Interface\\AddOns';
const walk = (dir) => fs.readdirSync(dir, { withFileTypes: true }).flatMap(e => e.isDirectory() ? walk(path.join(dir, e.name)) : [path.join(dir, e.name)]);
const read = (type, file) => fs.readFileSync(type === 'game' ? path.join(game, file) : path.join(root, type, file), 'utf8').replace(/^\uFEFF/, '');
const hash = (file) => createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const luaQuote = (text) => JSON.stringify(text);
function vm(locale) {
  const L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);
  exec(L, 'GetLocale = function() return ' + luaQuote(locale) + ' end; unpack = table.unpack');
  return L;
}
function exec(L, code, name = 'checks', returns = 0) {
  let status = lauxlib.luaL_loadbuffer(L, ls(code), null, ls('@' + name));
  if (status === lua.LUA_OK) status = lua.lua_pcall(L, 0, returns, 0);
  assert.equal(status, lua.LUA_OK, status === lua.LUA_OK ? undefined : js(lua.lua_tostring(L, -1)));
}
function data(L, index) {
  index = lua.lua_absindex(L, index);
  switch (lua.lua_type(L, index)) {
    case lua.LUA_TSTRING: return js(lua.lua_tostring(L, index));
    case lua.LUA_TBOOLEAN: return lua.lua_toboolean(L, index);
    case lua.LUA_TNUMBER: return lua.lua_tonumber(L, index);
    case lua.LUA_TTABLE: {
      const out = {};
      lua.lua_pushnil(L);
      while (lua.lua_next(L, index)) {
        const key = data(L, -2);
        out[key] = data(L, -1);
        lua.lua_pop(L, 1);
      }
      return out;
    }
    default: throw new Error('Unexpected Lua value');
  }
}
function result(L, expression) {
  exec(L, 'return ' + expression, 'result', 1);
  const value = data(L, -1);
  lua.lua_pop(L, 1);
  return value;
}
const specifications = (text) => text.match(/%[-+ #0]*\d*(?:\.\d+)?[cdiouxXeEfgGqs%]/g) || [];
function formatCheck(en, ko) {
  assert.deepEqual(specifications(ko), specifications(en), 'Format arguments changed: ' + en);
}
const files = walk(path.join(root, 'source')).map(f => path.relative(path.join(root, 'source'), f));
assert.equal(files.length, 11);
let syntax = 0;
for (const file of files.filter(f => f.endsWith('.lua'))) {
  const L = vm('koKR');
  assert.equal(lauxlib.luaL_loadbuffer(L, ls(read('source', file)), null, ls('@' + file)), lua.LUA_OK, file);
  syntax++;
}

let keepCount = 0;
for (const locale of ['enUS', 'deDE', 'koKR']) {
  const tables = [];
  for (const type of ['original', 'source']) {
    const L = vm(locale);
    exec(L, 'ns = {}; (function(...)\n' + read(type, 'KeepOrSell/Locales/Locales.lua') + '\nend)("KeepOrSell", ns)');
    tables.push(result(L, 'ns.L'));
  }
  const [before, after] = tables;
  assert.deepEqual(Object.keys(before).sort(), Object.keys(after).sort());
  if (locale !== 'koKR') assert.deepEqual(before, after, locale + ' fallback changed');
  else {
    keepCount = Object.keys(after).length;
    const unchanged = new Set(['HINT_COUNT', 'HINT_UNSTACKED_ITEM', 'SETUP_SCRAP', 'SETUP_QUESTIE', 'HELP_BUTTON', 'HELP_KEEP_COMMAND_KEY', 'FILTER_SUM_OPTION', 'FILTER_RULES_CATEGORY', 'ALTS_SKILL', 'TIP_TSM']);
    for (const key of Object.keys(before)) {
      formatCheck(before[key], after[key]);
      assert(unchanged.has(key) || before[key] !== after[key], 'KeepOrSell missing: ' + key);
    }
    assert(after.WARN_DELETE.includes('파괴'));
    assert(after.OPT_DESTROY_TIP.includes('희귀 등급 이상'));
    assert(after.FILTER_RULE_USAGE.includes('<keep|profession|ah|disenchant|junk|clear>'));
    assert(after.FILTER_ERR_NOHEADER.includes('KeepOrSell filter 1'));
    assert(after.SETUP_SCAN_TIP.split('\n').length === before.SETUP_SCAN_TIP.split('\n').length);
  }
}
const keyMatches = [...fs.readFileSync(path.join(root, 'KeepOrSell-koKR.lua'), 'utf8').matchAll(/^    ([A-Z_0-9]+) = /gm)].map(m => m[1]);
assert.equal(new Set(keyMatches).size, keepCount, 'Duplicate or missing Korean key');

const questieFiles = [...new Set(audit.filter(e => Object.hasOwn(dictionaries.Questie, e.key) && e.addon === 'Questie').map(e => e.file))];
for (const file of questieFiles) {
  const versions = [];
  for (const type of ['original', 'source']) {
    const L = vm('koKR');
    exec(L, 'l10n = { translations = {} }; Expansions = { Current = 1, Era = 1, Tbc = 2 }; QuestieLoader = { ImportModule = function(_, name) return name == "Expansions" and Expansions or l10n end }');
    exec(L, read(type, file), file);
    versions.push(result(L, 'l10n.translations'));
  }
  const [before, after] = versions;
  assert.deepEqual(Object.keys(before).sort(), Object.keys(after).sort());
  for (const key of Object.keys(before)) {
    const expected = structuredClone(before[key]);
    if (Object.hasOwn(dictionaries.Questie, key)) {
      expected.koKR = dictionaries.Questie[key];
      formatCheck(key, expected.koKR);
    }
    assert.deepEqual(after[key], expected, file + ': ' + key);
  }
}

for (const addon of ['Leatrix_Plus', 'HanharEnhancementHUD']) {
  const file = addon === 'Leatrix_Plus' ? addon + '/Leatrix_Plus_Locale.lua' : addon + '/Locale.lua';
  for (const locale of ['enUS', 'deDE', 'koKR']) {
    const versions = [];
    for (const type of ['original', 'source']) {
      const L = vm(locale);
      exec(L, 'ns = {}; (function(...)\n' + read(type, file) + '\nend)(' + luaQuote(addon) + ', ns)');
      const values = {};
      for (const key of Object.keys(dictionaries[addon])) {
        values[key] = result(L, addon === 'Leatrix_Plus' ? 'ns.L[' + luaQuote(key) + ']' : 'ns.Text(' + luaQuote(key) + ')');
      }
      versions.push(values);
    }
    for (const [key, text] of Object.entries(versions[1])) {
      assert.equal(text, locale === 'koKR' ? dictionaries[addon][key] : versions[0][key]);
      formatCheck(key, text);
    }
  }
}

for (const locale of ['koKR', 'enUS', 'deDE']) {
  const L = vm(locale);
  exec(L, `
    QuestieTraceCore = { }
    QuestieTrace = { settings = { debug = false, dataCollectionConsent = false } }
    SlashCmdList = {}
    strsplit = function(_, text) return text:match("^(%S*)%s*(.*)$") end
    CreateFrame = function() return { RegisterEvent = function() end, SetScript = function() end } end
  `);
  exec(L, read('game', 'QuestieTrace/Modules/Localization/l10n.lua'), 'real QuestieTrace localization');
  exec(L, `
    local C = QuestieTraceCore
    C.Print = function(...) output = table.concat({...}, " ") end
    C.RegisterDump = function(dump) registeredDump = dump end
    C.GetDumpHelpLines = function() return {registeredDump.helpText} end
    C.RunDumpBySlash = function() return false end
    C.ShowConsentPrompt = function() consentOpened = true end
    C.ShowExportWindow = function() exportOpened = true end
    print = C.Print
  `);
  exec(L, read('source', 'QuestieTrace/Modules/Dumps/MapHierarchy.lua'), 'dump help');
  exec(L, read('source', 'QuestieTrace/QuestieTrace.lua'), 'QuestieTrace main');
  exec(L, `
    QuestieTraceCore.GetStatusData = function() return {
      isRunning = true, sessionName = "test-session", eventCount = 2, sessionDuration = 65,
    } end
    SlashCmdList.QUESTIETRACE("status")
    assert(output:find(GetLocale() == "koKR" and "기록 중" or "running", 1, true))
    assert(output:find(GetLocale() == "koKR" and "거부함" or "declined", 1, true))
    assert(output:find(GetLocale() == "koKR" and "1분 05초" or "1m 05s", 1, true))
    SlashCmdList.QUESTIETRACE("help")
    assert(output:find(GetLocale() == "koKR" and "지도 계층 자료 갱신" or "Refresh static", 1, true))
    SlashCmdList.QUESTIETRACE("debug")
    assert(QuestieTrace.settings.debug == true)
    assert(output:find(GetLocale() == "koKR" and "켜짐" or "enabled", 1, true))
    SlashCmdList.QUESTIETRACE("consent")
    SlashCmdList.QUESTIETRACE("export")
    assert(consentOpened and exportOpened)
    assert(QuestieTrace.settings.dataCollectionConsent == false)
  `, 'real slash dispatch and consent unchanged');
  for (const [key, ko] of Object.entries(dictionaries.QuestieTrace)) formatCheck(key, ko);
}

const englishMap = read('source', 'ForeverMap/ForeverMap.lua');
assert(englishMap.includes('SIZE = "Size: "'));
assert(englishMap.includes('L.SIZE = "크기: "'));
assert(englishMap.includes('row.sizeTxt:SetText(L.SIZE .. (data.textSize or 40))'));
const total = keepCount + Object.values(dictionaries).reduce((sum, dict) => sum + Object.keys(dict).length, 0) + 1;
const plan = files.map(relative => ({
  relative,
  before: hash(path.join(root, 'original', relative)),
  after: hash(path.join(root, 'source', relative)),
}));
for (const entry of plan) assert.notEqual(entry.before, entry.after, entry.relative);
fs.writeFileSync(path.join(root, 'install-plan.json'), JSON.stringify(plan, null, 2) + '\n');
const summary = { result: 'PASS', files: files.length, luaSyntax: syntax, keepOrSellKeys: keepCount, supplementalKeys: total - keepCount, totalKeys: total, gameUI: 'NOT_TESTED' };
fs.writeFileSync(path.join(root, 'verification.json'), JSON.stringify(summary, null, 2) + '\n');
console.log(JSON.stringify(summary));
