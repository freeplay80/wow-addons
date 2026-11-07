-- Compat.lua
-- Safe wrappers for the World of Warcraft: Forever client (Retail engine,
-- interface 16001) with Midnight-style "secret values." Forever has no
-- Classic-era globals (GetSpellInfo, UnitBuff), so there are no fallbacks.
--
-- Rules this file enforces for the rest of the addon:
--   * Never compare, add or boolean-test a value that might be secret.
--     Check it with C.Secret / C.Plain first.
--   * Every game read goes through pcall, because some reads throw in combat.
--   * Secret timings go straight to Blizzard widgets (duration objects),
--     never through Lua math.

local _, ns = ...
local C = {}
ns.C = C

local issecretvalue = rawget(_G, "issecretvalue")
local issecrettable = rawget(_G, "issecrettable")

function C.Secret(v)
  if issecretvalue and issecretvalue(v) then return true end
  if issecrettable and type(v) == "table" and issecrettable(v) then return true end
  return false
end

-- The value if Lua may use it, otherwise nil.
function C.Plain(v)
  if C.Secret(v) then return nil end
  return v
end

function C.PlainNumber(v)
  v = C.Plain(v)
  if type(v) == "number" then return v end
  return nil
end

-- pcall that tolerates a missing function.
function C.Call(fn, ...)
  if type(fn) ~= "function" then return false end
  return pcall(fn, ...)
end

-- Registering an event this client doesn't have throws, so guard it.
function C.Register(frame, event, unit)
  if unit then
    return pcall(frame.RegisterUnitEvent, frame, event, unit)
  end
  return pcall(frame.RegisterEvent, frame, event)
end

-- name, iconID, spellID for a spell ID or name, or nil.
function C.SpellInfo(spell)
  if C_Spell and C_Spell.GetSpellInfo then
    local ok, info = pcall(C_Spell.GetSpellInfo, spell)
    if ok and type(info) == "table" and not C.Secret(info) then
      return C.Plain(info.name), C.Plain(info.iconID), C.PlainNumber(info.spellID)
    end
  end
  return nil
end

function C.SpellName(spellID)
  if C_Spell and C_Spell.GetSpellName then
    local ok, name = pcall(C_Spell.GetSpellName, spellID)
    if ok then return C.Plain(name) end
    return nil
  end
  return (C.SpellInfo(spellID))
end

-- True when the player has this spell (looked up by name).
function C.KnowsSpell(name)
  if not name then return false end
  local found, _, id = C.SpellInfo(name)
  if not found then return false end
  if id and C_SpellBook and C_SpellBook.IsSpellKnownOrInSpellBook then
    local ok, known = pcall(C_SpellBook.IsSpellKnownOrInSpellBook, id)
    known = ok and C.Plain(known)
    if known ~= nil then return known == true end
  end
  return true
end

-- Cooldown state without touching secret numbers.
-- Returns a table: { start, duration } when readable, or { secret = true }.
-- `active` and `onGCD` are never secret on this client.
function C.SpellCooldown(spell)
  if C_Spell and C_Spell.GetSpellCooldown then
    local ok, info = pcall(C_Spell.GetSpellCooldown, spell)
    if not ok or type(info) ~= "table" or C.Secret(info) then return nil end
    local r = {
      active = C.Plain(info.isActive),
      onGCD = C.Plain(info.isOnGCD),
      start = C.PlainNumber(info.startTime),
      duration = C.PlainNumber(info.duration),
    }
    r.secret = (r.start == nil or r.duration == nil)
    return r
  end
end

-- Hand a spell's cooldown to a Cooldown widget as a duration object.
function C.SetCooldownFromSpell(cd, spell)
  if not (C_Spell and C_Spell.GetSpellCooldownDuration and cd.SetCooldownFromDurationObject) then
    return false
  end
  local ok, d = pcall(C_Spell.GetSpellCooldownDuration, spell, true)
  if not ok or d == nil then return false end
  return (pcall(cd.SetCooldownFromDurationObject, cd, d, true))
end

-- Finds the player's first helpful aura named in `wanted`.
-- Returns aura, readable. When the client refuses aura reads (in combat),
-- readable is false and the caller should keep what it knew before.
-- True while the client refuses aura reads from addons (usually combat).
-- Checking first avoids a thrown error on every read.
function C.AurasLocked()
  if not (C_Secrets and C_Secrets.ShouldAurasBeSecret) then return false end
  local ok, v = pcall(C_Secrets.ShouldAurasBeSecret)
  return ok and C.Plain(v) == true
end

-- Reusable one-name lookup sets, so callers don't build a table per check.
local sets = {}
function C.NameSet(name)
  local s = sets[name]
  if not s then
    s = { [name] = true }
    sets[name] = s
  end
  return s
end

function C.FindBuff(wanted)
  if C.AurasLocked() then return nil, false end
  if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
    for i = 1, 40 do
      local ok, a = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
      if not ok or C.Secret(a) then return nil, false end
      if a == nil then break end
      local name = C.Plain(a.name)
      if name == nil then return nil, false end
      if wanted[name] then
        return {
          name = name,
          icon = C.Plain(a.icon),
          count = C.PlainNumber(a.applications),
          duration = C.PlainNumber(a.duration),
          expirationTime = C.PlainNumber(a.expirationTime),
        }, true
      end
    end
    return nil, true
  end
  return nil, false
end

