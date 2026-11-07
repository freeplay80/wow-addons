const fs = require('node:fs');
const path = require('node:path');
const { createHash } = require('node:crypto');
const assert = require('node:assert/strict');
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('../tests/quest-route/node_modules/fengari');
const install = 'D:\\Blizzard Games\\World of Warcraft\\_forever_\\Interface\\AddOns';
const state = lauxlib.luaL_newstate();
lualib.luaL_openlibs(state);
const plan = [];
let syntaxCount = 0;
const decode = (bytes) => new TextDecoder('utf-8', { fatal: true }).decode(bytes);
const hash = (bytes) => createHash('sha256').update(bytes).digest('hex');

function run(source, name, compileOnly = false) {
  const result = lauxlib.luaL_loadbuffer(state, to_luastring(source), null, to_luastring('@' + name));
  assert.equal(result, lua.LUA_OK, result === lua.LUA_OK ? undefined : to_jsstring(lua.lua_tostring(state, -1)));
  if (compileOnly) { lua.lua_pop(state, 1); return; }
  const exec = lua.lua_pcall(state, 0, 0, 0);
  assert.equal(exec, lua.LUA_OK, exec === lua.LUA_OK ? undefined : to_jsstring(lua.lua_tostring(state, -1)));
}

for (const addon of ['Lueur', 'ForeverLootSparkles', 'HanharEnhancementHUD']) {
  const toc = addon + '.toc';
  const lines = decode(fs.readFileSync(path.join(__dirname, addon, toc))).split(/\r?\n/);
  assert(lines.some((line) => line.startsWith('## Notes-koKR: ')));
  const order = lines.map((line) => line.trim()).filter((line) => line && !line.startsWith('#'));
  assert(order.includes(addon === 'Lueur' ? 'Locales\\koKR.lua' : 'Locale.lua'));
  assert(order.indexOf('Locale.lua') < order.indexOf(addon === 'ForeverLootSparkles' ? addon + '.lua' : 'Core.lua') || addon === 'Lueur');
  for (const name of [...order, toc]) {
    const relative = path.join(addon, name);
    const data = fs.readFileSync(path.join(__dirname, relative));
    if (name.endsWith('.lua')) {
      run(decode(data), relative, true);
      syntaxCount++;
    }
    const live = path.join(install, relative);
    const before = fs.existsSync(live) ? hash(fs.readFileSync(live)) : null;
    const after = hash(data);
    if (before !== after) plan.push({ relative, before, after });
  }
}
const moduleSource = (addon, file, ns, tail = '') =>
  '((function(...)\n' + decode(fs.readFileSync(path.join(__dirname, addon, file))) + '\n' + tail +
  '\nend))("' + addon + '", ' + ns + ')\n';

run(`
  locale = "koKR"
  GetLocale = function() return locale end
  LueurNS = {}
  FLS = {}
  HUD = {}
  local function frame()
    return setmetatable({}, { __index = function(_, key)
      if key == "CreateTexture" or key == "CreateFontString" then return frame end
      if key == "SetText" then return function(_, text) lastText = text end end
      if key == "GetStringHeight" then return function() return 18 end end
      if key == "SetScript" then return function(self, name, handler) self[name] = handler end end
      if key == "RegisterEvent" then return function(self, event)
        if event == "ADDON_LOADED" then loadFrame = self end
      end end
      return function() end
    end })
  end
  CreateFrame = frame
  UIParent = frame()
  STANDARD_TEXT_FONT = "test"
  SlashCmdList = {}
  GetTime = function() return 10 end
  strlower = string.lower
  C_CVar = { GetCVar = function() return "1" end, SetCVar = function() end }
  GetInventoryItemTexture = function() return 100 end
  printed = {}
  print = function(value) printed[#printed + 1] = value end
  DEFAULT_CHAT_FRAME = { AddMessage = function(_, value) print(value) end }
  labels, tooltips, callbacks = {}, {}, {}
  Settings = {
    VarType = { Boolean = "boolean" }, Default = { True = true },
    RegisterVerticalLayoutCategory = function() return {} end,
    RegisterAddOnSetting = function(_, _, key, _, _, label)
      labels[key] = label
      return { key = key, SetValueChangedCallback = function(_, cb) callbacks[key] = cb end }
    end,
    CreateCheckbox = function(_, setting, tooltip) tooltips[setting.key] = tooltip end,
    RegisterInitializer = function() end, RegisterAddOnCategory = function() end,
  }
  CreateSettingsListSectionHeaderInitializer = function(title) labels.section = title end
`, 'mock');
const lueur = 'Lueur';
const loot = 'ForeverLootSparkles';
const hanhar = 'HanharEnhancementHUD';
for (const file of ['Locales.lua', 'enUS.lua', 'koKR.lua']) {
  run(moduleSource(lueur, path.join('Locales', file), 'LueurNS'), file);
}
run(`
  local function formatTokens(value)
    local tokens = {}
    for token in value:gmatch("%%[-+ #0-9.]*[aAcdeEfgGiouqsxX%%]") do tokens[#tokens + 1] = token end
    return table.concat(tokens)
  end
  CheckFormat = function(en, ko) assert(formatTokens(en) == formatTokens(ko), en) end
  local en, ko = LueurNS.LOCALES.enUS, LueurNS.LOCALES.koKR
  for key, text in pairs(en) do
    assert(type(text) == type(ko[key]), key)
    if type(text) == "string" then CheckFormat(text, ko[key]) end
  end
  assert(#en.HELP == #ko.HELP)
  for i, help in ipairs(en.HELP) do
    assert(help:match("^(.-) —") == ko.HELP[i]:match("^(.-) —") or help:find("^/lueur language "))
    local function placeholders(line)
      local result = {}
      for name in line:gmatch("{([^}]+)}") do result[#result + 1] = name end
      return table.concat(result, ",")
    end
    assert(placeholders(help) == placeholders(ko.HELP[i]))
  end
  assert(LueurNS.L.SETTINGS == "설정")
  LueurNS.UseLanguage("enUS")
  assert(LueurNS.L.SETTINGS == "Settings")
  LueurNS.UseLanguage("auto")
  assert(LueurNS.L.SETTINGS == "설정")
  locale = "jaJP"
  assert(LueurNS.L.SETTINGS == "Settings")
  locale = "koKR"
`, 'Lueur locale and help');
for (const language of ['koKR', 'enUS']) {
  run('locale = "' + language + '"', 'locale');
  for (const file of ['Locale.lua', loot + '.lua', 'SoftTarget.lua']) {
    run(moduleSource(loot, file, 'FLS'), file);
  }
  run(`
    loadFrame:OnEvent("ADDON_LOADED", "ForeverLootSparkles")
    assert(labels.enabled == (locale == "koKR" and "퀘스트 아이템 반짝임 표시" or "Show quest item sparkles"))
    assert(labels.sparkleOre == (locale == "koKR" and "광맥" or "Ore veins"))
    assert(labels.sparkleCorpseLoot == (locale == "koKR" and "전리품이 남은 시체" or "Corpses with loot"))
    assert(tooltips.sparkleQuest:find(locale == "koKR" and "상호작용 범위" or "soft targeting", 1, true))
    assert(ForeverLootSparklesDB.sparkleOre ~= nil)
    callbacks.enabled(nil, false)
    assert(printed[#printed]:find(locale == "koKR" and "다시 실행하세요" or "/reload is not enough", 1, true))
  `, 'ForeverLootSparkles settings');
  run('HUD = {}', 'fresh namespace');
  const toc = decode(fs.readFileSync(path.join(__dirname, hanhar, hanhar + '.toc')));
  for (const file of toc.split(/\r?\n/).filter((line) => line.endsWith('.lua') && !line.startsWith('#'))) {
    run(moduleSource(hanhar, file, 'HUD', file === 'Locale.lua' ? 'for en, ko in pairs(koKR) do CheckFormat(en, ko) end' : ''), file);
  }
  run(`
    loadFrame:OnEvent("ADDON_LOADED", "HanharEnhancementHUD")
    HUD.initialized = true
    SlashCmdList.ENHANCEHUD("help")
    assert(printed[#printed]:find(locale == "koKR" and "명령어 목록" or "this list", 1, true))
    HUD.OnWindfury()
    assert(lastText == (locale == "koKR" and "질풍!" or "WINDFURY!"))
    local buff
    for _, m in ipairs(HUD.modules) do if m.key == "buffs" then buff = m end end
    buff.imbue = { known = true, present = false }
    buff.shield = { present = true, count = 1 }
    HUD.C.KnowsSpell = function() return true end
    local tokens = buff:PrepullItems(10)
    assert(tokens[1] == "imbue" and tokens[2] == "Lightning Shield (1 charge)")
    local display = buff:PrepullItems(10, HUD.Text)
    assert(display[1] == (locale == "koKR" and "무기 강화" or tokens[1]))
    assert(display[2] == (locale == "koKR" and "번개 보호막 (1회 남음)" or tokens[2]))
    HUD.TotemRange:Debug()
    assert(printed[#printed]:find(locale == "koKR" and "현재 위치" or "your position", 1, true))
  `, 'Hanhar settings IDs, HUD alert, command and ready-check tokens');
}

fs.writeFileSync(path.join(__dirname, 'install-plan.json'), JSON.stringify(plan, null, 2) + '\n');
console.log(syntaxCount + ' Lua files parsed; locale, formatting and game API mocks passed (koKR and enUS).');
console.log(plan.length + ' files to install: ' + plan.map(({ relative }) => relative).join(', '));
