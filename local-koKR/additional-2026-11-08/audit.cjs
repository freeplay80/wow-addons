const fs = require('node:fs');
const path = require('node:path');
const { lua, lauxlib, lualib, to_luastring: ls, to_jsstring: js } = require('../../tests/quest-route/node_modules/fengari');
const game = 'D:\\Blizzard Games\\World of Warcraft\\_forever_\\Interface\\AddOns';
function walk(dir) { return fs.readdirSync(dir, { withFileTypes: true }).flatMap(e => e.isDirectory() ? walk(path.join(dir, e.name)) : [path.join(dir, e.name)]); }
function run(L, source, name) {
  if (lauxlib.luaL_loadbuffer(L, ls(source), null, ls('@' + name)) !== lua.LUA_OK ||
      lua.lua_pcall(L, 0, 0, 0) !== lua.LUA_OK) throw new Error(name + ': ' + js(lua.lua_tostring(L, -1)));
}
const missing = [];
for (const addon of ['Questie', 'QuestieTrace']) {
  const L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);
  let current;
  lua.lua_pushjsfunction(L, () => {
    const key = js(lua.lua_tostring(L, 1));
    missing.push({ addon, file: path.relative(game, current), key });
    return 0;
  });
  lua.lua_setglobal(L, ls('missing'));
  run(L, 'l10n = { translations = {} }; Expansions = { Current = 1, Era = 1, Tbc = 2, Wrath = 3, Cata = 4, Mop = 5 }; QuestieLoader = { ImportModule = function(_, name) if name == "Expansions" then return Expansions end return l10n end }; QuestieTraceCore = { l10n = l10n }; GetLocale = function() return "koKR" end', 'stubs');
  const localeDir = addon === 'Questie' ? 'Localization/Translations' : 'Modules/Localization/Translations';
  for (const file of walk(path.join(game, addon, localeDir)).filter(f => f.endsWith('.lua'))) {
    current = file;
    run(L, 'l10n.translations = {}', 'reset');
    run(L, fs.readFileSync(file, 'utf8').replace(/^\uFEFF/, ''), file);
    run(L, 'for k,v in pairs(l10n.translations) do if not v.koKR and k:find("[A-Za-z]") then missing(k) end end', 'find missing');
  }
}
const leatrixSource = fs.readFileSync(path.join(game, 'Leatrix_Plus/Leatrix_Plus.lua'), 'utf8');
const localeSource = fs.readFileSync(path.join(game, 'Leatrix_Plus/Leatrix_Plus_Locale.lua'), 'utf8');
const koreanBlock = localeSource.slice(localeSource.indexOf('if GameLocale == "koKR" then'), localeSource.indexOf('if GameLocale == "zhCN" then'));
const korean = new Set([...koreanBlock.matchAll(/L\["((?:\\.|[^"\\])*)"\]\s*=/g)].map(m => m[1]));
for (const key of new Set([...leatrixSource.matchAll(/L\["((?:\\.|[^"\\])*)"\]/g)].map(m => m[1]))) {
  if (!korean.has(key)) missing.push({ addon: 'Leatrix_Plus', file: 'Leatrix_Plus/Leatrix_Plus_Locale.lua', key });
}
fs.writeFileSync(path.join(__dirname, 'audit.json'), JSON.stringify(missing, null, 2));
console.log(JSON.stringify(missing.reduce((a, x) => ({...a, [x.addon]: (a[x.addon] || 0) + 1 }), {})));
