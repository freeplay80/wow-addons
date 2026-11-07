-- Persist.lua
-- The Forever beta writes SavedVariables but never reads them back, so
-- settings reset every launch. As an opt-in workaround, the HUD can keep
-- its settings in one general macro named "HanharHUD", which does survive a
-- restart. The macro body is a harmless "/ehud cfg ..." line. A second
-- macro, "HanharHUD2", holds the Tracking tab choices. With solo and group
-- setups on, "HanharHUD3" and "HanharHUD4" hold the setup you're not in.
-- With per-character settings on, the same four live in this character's
-- macros instead, named HanharChar to HanharChar4.
-- Before 2.2.0 these were EnhanceHUD1-4 and EHUDchar1-4. Those are read once,
-- rewritten under the new names, then removed.

local _, ns = ...
local T = ns.Text
local C = ns.C

local MACRO_NAME = "HanharHUD"
local MACRO2_NAME = "HanharHUD2" -- tracking choices
local MACRO3_NAME = "HanharHUD3" -- the other solo/group setup (settings)
local MACRO4_NAME = "HanharHUD4" -- the other solo/group setup (tracking)
local MACRO_ICON = 134400 -- question mark
local VERSION = "1"
local SHOW_ORDER = { "totems", "swing", "buffs", "procs", "dots", "reinc" }

local P = {}
ns.Persist = P

local function b(v) return v and "1" or "0" end

-- Order matters for saved strings: only ever add to the end.
local KEY_ACTIONS = { "toggle", "lock", "test", "options" }
P.KEY_ACTIONS = KEY_ACTIONS

local function AlertsCode(db)
  local out = ""
  for _, a in ipairs(ns.ALERTS) do
    local c = db.alerts[a.id] or {}
    out = out .. b(c.text) .. b(c.sound) .. tostring(math.min(9, c.kit or 1))
  end
  return out
end

local function DecodeAlerts(code, db)
  if type(code) ~= "string" then return end
  for i, a in ipairs(ns.ALERTS) do
    local chunk = code:sub(i * 3 - 2, i * 3)
    if #chunk == 3 then
      db.alerts[a.id] = db.alerts[a.id] or {}
      local c = db.alerts[a.id]
      c.text = chunk:sub(1, 1) == "1"
      c.sound = chunk:sub(2, 2) == "1"
      c.kit = tonumber(chunk:sub(3, 3)) or 1
    end
  end
end

-- Key names can contain punctuation; store anything unusual as ~hex.
local function EscapeKey(k)
  return (k:gsub("[^%w%-]", function(ch) return string.format("~%02X", ch:byte()) end))
end
local function UnescapeKey(k)
  return (k:gsub("~(%x%x)", function(h) return string.char(tonumber(h, 16)) end))
end

function P.Encode(db)
  local p = db.point
  local show = ""
  for _, k in ipairs(SHOW_ORDER) do show = show .. b(db.show[k]) end
  local ap = db.alertPoint
  return string.format("/ehud cfg %s;%s;%s;%d;%d;%.2f;%.2f;%d;%d;%s;%s;%s;%s;%s;%d;%s;%s;%s;%d;%d;%d;%s;%s%s%s;%d;%s;%s;%s;%d;%d;%s;%s;%s;%s;%s;%s;%s;%s;%s;%d;%s",
    VERSION, p[1], p[3], math.floor(p[4] + 0.5), math.floor(p[5] + 0.5),
    db.scale, db.oocAlpha, db.imbueWarn, db.totemWarn,
    b(db.sound), b(db.alerts.windfury and db.alerts.windfury.text), show, b(db.locked), b(db.hehReply), db.dotWarn, b(db.notAttacking), b(db.wfStats),
    b(db.wfRecords), (db.wfBest and db.wfBest.procs) or 0, (db.wfBest and db.wfBest.rate) or 0,
    (db.wfBest and db.wfBest.streak) or 0,
    AlertsCode(db), b(db.hideMounted), b(db.hideResting), b(db.hideIdle),
    db.alertSize, "0", ap[1], ap[3], math.floor(ap[4] + 0.5), math.floor(ap[5] + 0.5),
    ns.VERSION, b(db.totemRange),
    b(db.autoProfile), db.activeProfile == "group" and "g" or "s",
    b(db.ssTimer), b(db.prepullBuffs), b(db.rankCheck), b(db.diagnostics),
    b(db.minimapButton ~= false), math.floor((db.minimapAngle or 215) + 0.5),
    b(db.rcEnabled) .. b(db.rcFood) .. b(db.rcFlask) .. b(db.rcElixirs) .. b(db.rcBuffs)
      .. b(db.rcSelf) .. tostring(math.min(9, db.rcElixirCount or 2)))
end

-- Applies an encoded string to db. Returns true if it parsed.
function P.Decode(str, db)
  if type(str) ~= "string" then return false end
  local body = str:match("cfg%s+([%w%.;%-_]+)")
  if not body then return false end
  db.alerts = db.alerts or {}
  db.show = db.show or {}
  local f = {}
  for part in body:gmatch("[^;]+") do f[#f + 1] = part end
  if f[1] ~= VERSION or #f < 13 then return false end

  local x, y = tonumber(f[4]), tonumber(f[5])
  if x and y then db.point = { f[2], "UIParent", f[3], x, y } end
  db.scale = tonumber(f[6]) or db.scale
  db.oocAlpha = tonumber(f[7]) or db.oocAlpha
  db.imbueWarn = tonumber(f[8]) or db.imbueWarn
  db.totemWarn = tonumber(f[9]) or db.totemWarn
  db.sound = f[10] == "1"
  if db.alerts and db.alerts.windfury then db.alerts.windfury.text = f[11] == "1" end
  for i, k in ipairs(SHOW_ORDER) do
    local bit = f[12]:sub(i, i)
    if bit ~= "" then db.show[k] = bit == "1" end -- older saves have fewer sections
  end
  db.locked = f[13] == "1"
  if f[14] then db.hehReply = f[14] == "1" end
  if tonumber(f[15]) then db.dotWarn = tonumber(f[15]) end
  if f[16] then db.notAttacking = f[16] == "1" end
  if f[17] then db.wfStats = f[17] == "1" end
  if f[18] then db.wfRecords = f[18] == "1" end
  if tonumber(f[19]) then
    db.wfBest = { procs = tonumber(f[19]) or 0, rate = tonumber(f[20]) or 0, streak = tonumber(f[21]) or 0 }
  end
  DecodeAlerts(f[22], db)
  if f[23] and #f[23] == 3 then
    db.hideMounted = f[23]:sub(1, 1) == "1"
    db.hideResting = f[23]:sub(2, 2) == "1"
    db.hideIdle = f[23]:sub(3, 3) == "1"
  end
  db.alertSize = tonumber(f[24]) or db.alertSize
  -- f[25] was "alerts to chat", which no longer exists; it's ignored.
  local ax, ay = tonumber(f[28]), tonumber(f[29])
  if f[26] and f[27] and ax and ay then db.alertPoint = { f[26], "UIParent", f[27], ax, ay } end
  if f[30] then db.lastVersion = f[30] end
  if f[31] then db.totemRange = f[31] == "1" end
  if f[32] then db.autoProfile = f[32] == "1" end
  if f[33] then db.activeProfile = (f[33] == "g") and "group" or "solo" end
  if f[34] then db.ssTimer = f[34] == "1" end
  if f[35] then db.prepullBuffs = f[35] == "1" end
  if f[36] then db.rankCheck = f[36] == "1" end
  if f[37] then db.diagnostics = f[37] == "1" end
  if f[38] then db.minimapButton = f[38] == "1" end
  if tonumber(f[39]) then db.minimapAngle = tonumber(f[39]) end
  -- f[40] was alert chat channels (removed in 2.0.2); only a 7-character
  -- ready-check code is read from it.
  if f[40] and #f[40] == 7 then
    local r = f[40]
    db.rcEnabled, db.rcFood, db.rcFlask = r:sub(1, 1) == "1", r:sub(2, 2) == "1", r:sub(3, 3) == "1"
    db.rcElixirs, db.rcBuffs, db.rcSelf = r:sub(4, 4) == "1", r:sub(5, 5) == "1", r:sub(6, 6) == "1"
    db.rcElixirCount = tonumber(r:sub(7, 7)) or db.rcElixirCount
  end
  return true
end

-- Tracking choices, by spell ID so they survive a language change.
-- Catalog cooldowns (Stormstrike, shocks, Fire Nova) are saved as k1..k5.
local function CooldownCode(key)
  for i, c in ipairs(ns.Book.CATALOG) do
    if c.key == key then return "k" .. i end
  end
  local id = ns.Book.ids[key]
  return id and tostring(id) or nil
end

function P.Encode2(db)
  local c, t, r = {}, {}, {}
  for name, on in pairs(db.totemsRequired or {}) do
    local id = on and ns.Book.ids[name]
    if id then r[#r + 1] = tostring(id) end
  end
  table.sort(r)
  for key, on in pairs(db.cooldowns or {}) do
    local code = on and CooldownCode(key)
    if code then c[#c + 1] = code end
  end
  for name, off in pairs(db.totemsOff or {}) do
    local id = off and ns.Book.ids[name]
    if id then t[#t + 1] = tostring(id) end
  end
  table.sort(c)
  table.sort(t)
  local k = {}
  for i, action in ipairs(KEY_ACTIONS) do
    k[i] = db.keys[action] and EscapeKey(db.keys[action]) or ""
  end
  return "/ehud cfg2 c=" .. table.concat(c, ",") .. ";t=" .. table.concat(t, ",")
    .. ";r=" .. table.concat(r, ",") .. ";b=" .. table.concat(k, ",")
end

function P.Decode2(str, db)
  if type(str) ~= "string" then return false end
  local c, t = str:match("c=([%w,]*)"), str:match("t=([%d,]*)")
  if not c or not t then return false end
  db.cooldowns = {}
  for code in c:gmatch("[^,]+") do
    local k = tonumber(code:match("^k(%d+)$") or "")
    local entry = k and ns.Book.CATALOG[k]
    if entry then
      db.cooldowns[entry.key] = true
    else
      local id = tonumber(code)
      local name = id and C.SpellName(id)
      if name then
        ns.Book.ids[name] = ns.Book.ids[name] or id
        db.cooldowns[name] = true
      end
    end
  end
  local function Names(list, into)
    for code in (list or ""):gmatch("[^,]+") do
      local id = tonumber(code)
      local name = id and C.SpellName(id)
      if name then
        ns.Book.ids[name] = ns.Book.ids[name] or id
        into[name] = true
      end
    end
  end
  db.totemsOff = {}
  Names(t, db.totemsOff)
  db.totemsRequired = {}
  Names(str:match("r=([%d,]*)"), db.totemsRequired)
  local keys = str:match("b=([%w%-~,]*)")
  if keys then
    db.keys = {}
    local i = 0
    for part in (keys .. ","):gmatch("([^,]*),") do
      i = i + 1
      if KEY_ACTIONS[i] and part ~= "" then db.keys[KEY_ACTIONS[i]] = UnescapeKey(part) end
    end
  end
  return true
end

-- Two sets of macro names: account-wide (general macros) and, when
-- "Separate settings for this character" is on, this character's own.
local SETS = {
  account = { MACRO_NAME, MACRO2_NAME, MACRO3_NAME, MACRO4_NAME },
  character = { "HanharChar", "HanharChar2", "HanharChar3", "HanharChar4" },
}
-- Names used before 2.2.0.
local LEGACY = {
  account = { "EnhanceHUD", "EnhanceHUD2", "EnhanceHUD3", "EnhanceHUD4" },
  character = { "EHUDchar", "EHUDchar2", "EHUDchar3", "EHUDchar4" },
}
local migrateFrom -- a LEGACY set to remove once the new macros are written

local function Names(db)
  return (db and db.perChar) and SETS.character or SETS.account
end

local function MacroIndex(name)
  local ok, idx = C.Call(GetMacroIndexByName, name)
  return ok and C.PlainNumber(idx) or 0
end

local function ReadMacro(name)
  local idx = MacroIndex(name)
  if idx <= 0 then return nil end
  local ok, body = C.Call(GetMacroBody, idx)
  return ok and C.Plain(body) or nil
end

-- Reads one set of macros into db. Returns true if the main one parsed.
local function LoadSet(names, db)
  if not P.Decode(ReadMacro(names[1]), db) then return false end
  P.Decode2(ReadMacro(names[2]), db)
  if db.autoProfile and ns.Profiles then
    local other = ns.Profiles:Other(db.activeProfile or "solo")
    local temp = { show = {}, alerts = {}, keys = {}, point = {} }
    if P.Decode(ReadMacro(names[3]), temp) then
      P.Decode2(ReadMacro(names[4]), temp)
      db.profiles = db.profiles or {}
      db.profiles[other] = ns.Profiles:Snapshot(temp)
    end
  end
  return true
end

-- Called at login: this character's settings win, then the account's.
-- Returns true if settings were restored.
-- Old macro names are checked right after the new ones of the same kind,
-- so a character's own settings still win over the account's.
function P.Load(db)
  local order = {
    { SETS.character, true }, { LEGACY.character, true, true },
    { SETS.account, false }, { LEGACY.account, false, true },
  }
  for _, o in ipairs(order) do
    if LoadSet(o[1], db) then
      db.remember, db.perChar = true, o[2]
      if o[3] then
        migrateFrom = o[1]
        P.SaveSoon()
      end
      return true
    end
  end
  return false
end

local pending, warned = false, false

function P.WriteMacro(name, body, perCharacter)
  local idx = MacroIndex(name)
  if idx > 0 then
    return (C.Call(EditMacro, idx, nil, nil, body))
  end
  local okC, made = C.Call(CreateMacro, name, MACRO_ICON, body, perCharacter and true or nil)
  return okC and made ~= nil
end

local function InCombat()
  local ok, v = C.Call(InCombatLockdown)
  return ok and C.Plain(v) == true
end

local function DeleteSet(names)
  for _, name in ipairs(names) do
    local idx = MacroIndex(name)
    if idx > 0 then C.Call(DeleteMacro, idx) end
  end
end

function P.SaveNow()
  pending = false
  local db = ns.db
  if not db or not db.remember then return end
  if InCombat() then pending = true return end

  local names, perChar = Names(db), db.perChar
  local ok = P.WriteMacro(names[1], P.Encode(db), perChar)
  ok = P.WriteMacro(names[2], P.Encode2(db), perChar) and ok
  -- The setup you're not in right now, if solo/group setups are on.
  local other = db.autoProfile and db.profiles and ns.Profiles
    and db.profiles[ns.Profiles:Other(db.activeProfile or "solo")]
  if other then
    local temp = setmetatable({}, { __index = db })
    for k, v in pairs(other) do temp[k] = v end
    ok = P.WriteMacro(names[3], P.Encode(temp), perChar) and ok
    ok = P.WriteMacro(names[4], P.Encode2(temp), perChar) and ok
  end
  if ok and migrateFrom then
    DeleteSet(migrateFrom)
    migrateFrom = nil
    ns.Print(T("moved your saved settings to macros named %s. The old %s macros are gone."):format(
      names[1], perChar and "EHUDchar" or "EnhanceHUD"))
  end
  if not ok and not warned then
    warned = true
    ns.Print(T("couldn't save settings to a macro. Your %s macro slots may be full."):format(
      T(perChar and "character" or "general")))
  end
end

-- Debounced save, so dragging a slider doesn't rewrite the macro 40 times.
local timerRunning = false
function P.SaveSoon()
  if not ns.db or not ns.db.remember or timerRunning then return end
  timerRunning = true
  C_Timer.After(1, function()
    timerRunning = false
    P.SaveNow()
  end)
end

-- Stop remembering: removes the macros for the current mode.
function P.Forget()
  if InCombat() then return false end
  DeleteSet(Names(ns.db))
  DeleteSet((ns.db and ns.db.perChar) and LEGACY.character or LEGACY.account)
  migrateFrom = nil
  return true
end

-- "Separate settings for this character."
-- On: this character's current settings move into its own macros.
-- Off: its macros are removed and the account-wide settings come back.
function P.SetPerCharacter(on)
  local db = ns.db
  if InCombat() then
    ns.Print(T("leave combat to change where settings are saved."))
    return false
  end
  if on then
    db.perChar, db.remember = true, true
    P.SaveNow()
    ns.Print(T("this character now keeps its own settings."))
  else
    DeleteSet(SETS.character)
    DeleteSet(LEGACY.character)
    if migrateFrom == LEGACY.character then migrateFrom = nil end
    db.perChar = false
    local fromOld = false
    local loaded = LoadSet(SETS.account, db)
    if not loaded and LoadSet(LEGACY.account, db) then loaded, fromOld = true, true end
    if loaded then
      if fromOld then migrateFrom = LEGACY.account; P.SaveSoon() end
      ns.Print(T("back to your account-wide settings."))
    else
      P.SaveNow()
      ns.Print(T("this character now uses account-wide settings."))
    end
    ns.Changed()
  end
  return true
end

-- Finish a save that was blocked by combat.
local ev = CreateFrame("Frame")
C.Register(ev, "PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function()
  if pending then P.SaveNow() end
end)
