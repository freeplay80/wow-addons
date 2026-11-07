-- Slot05.lua: diagnostics log
-- Records what the Forever client lets addons read, in and out of combat,
-- in the open world and in instances, so EnhanceHUD can be tuned from real
-- data. The beta never reads saved variables back, but it does write them
-- to disk on logout and /reload, so this ends up in:
--   WTF\Account\<account>\SavedVariables\EnhanceHUD.lua
-- Checks include your position, buffs, totems, cooldowns, weapon speed,
-- imbue, mana, swing events, and your target's GUID, range, debuffs and
-- spellcasts.
-- It records no chat, names or anything personal: only yes/no counts,
-- short fight summaries (length, swings, procs, zone) and addon errors.
--
-- /ehud diag shows a summary. /ehud diag clear wipes it.
-- Toggle on the Extras tab.

local _, ns = ...
local C = ns.C

local D = {}
ns.Diag = D

local MAX_FIGHTS = 25
local MAX_ERRORS = 20

function D:Store()
  local db = ns.db
  if type(db.diag) ~= "table" then db.diag = {} end
  local d = db.diag
  d.probes = d.probes or {}
  d.fights = d.fights or {}
  d.errors = d.errors or {}
  d.notes = d.notes or {}
  return d
end

local function Context()
  local where = ns.InGroupInstance() and "instance" or "world"
  return (ns.inCombat and "combat" or "ooc") .. "-" .. where
end

-- Count one observation: result is "ok", "secret", "blocked" or "none".
function D:Note(probe, result, ctx)
  if not (ns.db and ns.db.diagnostics) then return end
  local p = self:Store().probes
  ctx = ctx or Context()
  p[ctx] = p[ctx] or {}
  p[ctx][probe] = p[ctx][probe] or {}
  local row = p[ctx][probe]
  row[result] = (row[result] or 0) + 1
end

-- Record a free-form fact once (e.g. which imbue source worked).
function D:Fact(key, value)
  if not (ns.db and ns.db.diagnostics) then return end
  self:Store().notes[key] = value
end

function D:Error(key, err)
  if not (ns.db and ns.db.diagnostics) then return end
  local e = self:Store().errors
  for _, row in ipairs(e) do
    if row.key == key and row.err == err then
      row.count = row.count + 1
      return
    end
  end
  if #e < MAX_ERRORS then
    e[#e + 1] = { key = key, err = err, count = 1, version = ns.VERSION }
  end
end

-- The reads each sample tries. Built once, so sampling makes no garbage
-- of its own. "target" probes only run with an enemy targeted.
local function CooldownName(i)
  return (ns.Book.cooldowns[i] and ns.Book.cooldowns[i].name) or "Earth Shock"
end

local PROBES = {
  { "position",    function() return (UnitPosition("player")) end },
  { "playerAura",  function()
      local a = C_UnitAuras.GetAuraDataByIndex("player", 1, "HELPFUL")
      return a and a.name
    end },
  { "totemSlot",   function() return (GetTotemInfo(2)) end },
  { "attackSpeed", function() return (UnitAttackSpeed("player")) end },
  { "cooldown",    function() return C_Spell.GetSpellCooldown(CooldownName(1)).duration end },
  { "legacyImbue", function() return (GetWeaponEnchantInfo()) end },
  -- For a possible low-mana warning (mana is power type 0).
  { "mana",        function() return UnitPower("player", 0) end },
  { "manaPercent", function() return UnitPowerPercent("player", 0) end },
  { "targetGUID",  function() return UnitGUID("target") end, true },
  { "spellRange",  function() return C_Spell.IsSpellInRange(CooldownName(2), "target") end, true },
  -- For a possible interrupt alert: can addons see what the enemy casts?
  { "targetCast",  function()
      local name = UnitCastingInfo("target")
      if name == nil then name = UnitChannelInfo("target") end
      return name or false -- false = readable, just not casting
    end, true },
  { "targetDebuff", function()
      local a = C_UnitAuras.GetAuraDataByIndex("target", 1, "HARMFUL|PLAYER")
      return a and a.name or false
    end, true },
}

function D:Sample()
  if not (ns.db and ns.db.diagnostics) then return end
  local ctx = Context()
  local hostile = ns.HostileTarget()
  for i = 1, #PROBES do
    local probe = PROBES[i]
    if hostile or not probe[3] then
      -- Try the read and classify it.
      local ok, v = pcall(probe[2])
      local result = (not ok) and "blocked" or (v == nil and "none") or (C.Secret(v) and "secret") or "ok"
      self:Note(probe[1], result, ctx)
    end
  end
end

function D:FightEnded(swings, procs, duration)
  if not (ns.db and ns.db.diagnostics) then return end
  local f = self:Store().fights
  local okZ, zone = C.Call(GetRealZoneText)
  table.insert(f, 1, {
    when = date and date("%m-%d %H:%M") or "",
    zone = okZ and C.Plain(zone) or "?",
    instance = ns.InGroupInstance(),
    seconds = math.floor((duration or 0) + 0.5),
    swings = swings, procs = procs,
    version = ns.VERSION,
  })
  while #f > MAX_FIGHTS do table.remove(f) end
end

function D:Summary()
  local d = self:Store()
  ns.Print("diagnostics are " .. (ns.db.diagnostics and "on" or "off") .. ". What the client allowed:")
  for ctx, probes in pairs(d.probes) do
    local parts = {}
    for probe, row in pairs(probes) do
      local total, ok = 0, row.ok or 0
      for _, n in pairs(row) do total = total + n end
      parts[#parts + 1] = string.format("%s %d%%", probe, math.floor(ok / total * 100 + 0.5))
    end
    table.sort(parts)
    ns.Print("  " .. ctx .. ": " .. table.concat(parts, ", "))
  end
  ns.Print(string.format("  %d fights logged, %d distinct errors.", #d.fights, #d.errors))
end

function D:Command(arg)
  arg = (arg or ""):lower()
  if arg == "clear" then
    ns.db.diag = nil
    ns.Print("diagnostics cleared.")
  elseif arg == "on" or arg == "off" then
    ns.db.diagnostics = (arg == "on")
    ns.Print("diagnostics " .. arg .. ".")
    ns.Changed()
  else
    self:Summary()
  end
end

-- Client details once per login.
local ev = CreateFrame("Frame")
C.Register(ev, "PLAYER_LOGIN")
C.Register(ev, "UNIT_SPELLCAST_SUCCEEDED", "player")
ev:SetScript("OnEvent", function(_, event, _, _, spellID)
  if not ns.initialized then return end
  ns.Safe("diag", function()
    if event == "PLAYER_LOGIN" then
      local ok, version, build, _, interface = C.Call(GetBuildInfo)
      D:Fact("client", ok and string.format("%s build %s interface %s", tostring(version), tostring(build), tostring(interface)) or "?")
      D:Fact("addonVersion", ns.VERSION)
    else
      -- Is your own cast's spell ID readable? Several features depend on it.
      D:Note("castSpellID", C.Secret(spellID) and "secret" or (spellID and "ok" or "none"))
    end
  end)
end)

-- Sample every two seconds in combat, every ten out of combat.
local elapsed = 0
local function Sample() D:Sample() end
if C_Timer and C_Timer.NewTicker then
  C_Timer.NewTicker(2, function()
    if not ns.initialized then return end
    elapsed = elapsed + 2
    if ns.inCombat or elapsed >= 10 then
      elapsed = 0
      ns.Safe("diag", Sample)
    end
  end)
end
