-- Dots.lua
-- Debuff timers on your target:
--   * Flame Shock: how long until you need to reapply it.
--   * Stormstrike: how long its nature damage bonus lasts, so you can time
--     shocks inside it. (Its charges can be used up early by nature
--     attacks, which the client doesn't show mid-fight, so the bar may
--     outlast the bonus.)
--
-- In combat, Forever hides your target's debuffs from addons, so each timer
-- starts from your own cast (which stays readable). The length comes from
-- the debuff itself whenever the client lets us read it, then from the
-- spell's tooltip, then the classic 12 seconds. Each target is timed
-- separately, so switching targets shows that target's timers.
--
-- Limit: a resisted spell can't be told apart from one that landed while
-- you're in combat, so a bar may run for a spell that missed.

local _, ns = ...
local T = ns.Text
local C = ns.C
local M = {}
ns.RegisterModule("dots", M)

local LAST = "last" -- key used when the target's GUID can't be read
local REAPPLY_COLOR = { 0.9, 0.15, 0.15 }

local SPECS = {
  { key = "flameShock", id = 8050, fallback = "Flame Shock", default = 12,
    color = { 1.0, 0.45, 0.1 }, warn = { 0.95, 0.2, 0.15 }, y = -148,
    alert = { T("Flame Shock expired"), 1, 0.45, 0.1, "fsExpired" }, reapply = true,
    enabled = function() return true end },
  { key = "stormstrike", id = 17364, fallback = "Stormstrike", default = 12,
    color = { 0.45, 0.6, 1.0 }, warn = { 0.3, 0.4, 0.8 }, y = -166,
    enabled = function() return ns.db.ssTimer end },
}

local function TargetKey()
  local ok, guid = C.Call(UnitGUID, "target")
  guid = ok and C.Plain(guid)
  if type(guid) == "string" and guid ~= "" then return guid end
  return LAST
end

function M:Init(parent)
  self.trackers = {}
  for i, spec in ipairs(SPECS) do
    local t = { spec = spec, timers = {} }
    t.bar = ns.CreateBar(parent, 236, 14, spec.color, spec.fallback)
    t.bar:SetPoint("TOP", parent, "TOP", 0, spec.y)
    ns.SetShownC(t.bar, false)
    self.trackers[i] = t
  end
  -- Older code and tests look at the Flame Shock bar directly.
  self.bar = self.trackers[1].bar
  self:Resolve()

  local ev = CreateFrame("Frame")
  C.Register(ev, "UNIT_SPELLCAST_SUCCEEDED", "player")
  C.Register(ev, "PLAYER_TARGET_CHANGED")
  C.Register(ev, "SPELLS_CHANGED")
  ev:SetScript("OnEvent", function(_, event, _, _, spellID)
    ns.Safe("dots", function()
      if event == "UNIT_SPELLCAST_SUCCEEDED" then
        self:OnCast(spellID)
      elseif event == "SPELLS_CHANGED" then
        self:Resolve()
      else
        self.nextTick = 0 -- new target: redraw right away
      end
    end)
  end)
end

function M:Resolve()
  for _, t in ipairs(self.trackers) do
    t.name = C.SpellName(t.spec.id) or t.spec.fallback
    t.known = C.KnowsSpell(t.name)
    t.bar.label:SetText(t.name)
  end
end

function M:SetEnabled(on)
  self.enabled = on
  if not on then
    for _, t in ipairs(self.trackers) do ns.SetShownC(t.bar, false) end
  end
end

-- Reads your debuff on the target if the client allows it.
-- Returns duration, expirationTime (plain numbers) or nil.
local function ReadDebuff(name)
  if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then return nil end
  for i = 1, 40 do
    local ok, a = pcall(C_UnitAuras.GetAuraDataByIndex, "target", i, "HARMFUL|PLAYER")
    if not ok or C.Secret(a) then return nil end
    if a == nil then return nil end
    local n = C.Plain(a.name)
    if n == nil then return nil end
    if n == name then
      local d, e = C.PlainNumber(a.duration), C.PlainNumber(a.expirationTime)
      if d and d > 0 and e and e > 0 then return d, e end
      return nil
    end
  end
end

local function Duration(t)
  if t.learned then return t.learned end
  if C_Spell and C_Spell.GetSpellDescription then
    local ok, text = pcall(C_Spell.GetSpellDescription, t.name)
    text = ok and C.Plain(text)
    if type(text) == "string" then
      local n = tonumber(text:match("over (%d+) sec") or text:match("for (%d+) sec")
        or text:match("[Ll]asts (%d+) sec"))
      if n and n > 0 then return n end
    end
  end
  return t.spec.default
end

function M:OnCast(spellID)
  local id = C.PlainNumber(spellID)
  if not id then return end
  local name = C.SpellName(id)
  for _, t in ipairs(self.trackers) do
    if name == t.name then
      local key = TargetKey()
      local timer = { start = GetTime(), duration = Duration(t), warned = false }
      t.timers[key] = timer
      if key ~= LAST then t.timers[LAST] = timer end
      -- A moment later the debuff may be readable: use its real timing.
      C_Timer.After(0.3, function()
        local d, e = ReadDebuff(t.name)
        if d then
          t.learned = d
          timer.start, timer.duration = e - d, d
        end
      end)
    end
  end
  -- Kept for older callers.
  self.learned = self.trackers[1].learned
end

local function Current(t, now)
  local key = TargetKey()
  local timer = t.timers[key]
  if not timer and key ~= LAST then return nil end -- never cast on this target
  if timer and now - timer.start > timer.duration + 5 then
    t.timers[key] = nil
    return nil
  end
  return timer
end

local function Draw(t, timer, now)
  local bar, spec = t.bar, t.spec
  if not timer then
    ns.SetShownC(bar, false)
    return
  end
  local left = timer.start + timer.duration - now
  if left <= 0 then
    if spec.alert and not timer.warned and ns.inCombat and not ns.testMode then
      timer.warned = true
      local a = spec.alert
      ns.Alert(a[1], a[2], a[3], a[4], a[5])
    end
    if not spec.reapply or left < -3 then
      ns.SetShownC(bar, false)
      return
    end
    ns.SetShownC(bar, true)
    bar:SetValue(0)
    ns.SetBarColor(bar, REAPPLY_COLOR)
    if bar._tenths ~= -2 then bar._tenths = -2; bar.time:SetText(T("REAPPLY")) end
    return
  end
  ns.SetShownC(bar, true)
  bar:SetValue(left / timer.duration)
  ns.SetBarTime(bar, left)
  ns.SetBarColor(bar, (left <= ns.db.dotWarn) and spec.warn or spec.color)
end

function M:OnUpdate(now)
  if now < (self.nextTick or 0) then return end
  self.nextTick = now + 0.05
  self.learned = self.trackers[1].learned
  for _, t in ipairs(self.trackers) do
    if not t.spec.enabled() then
      ns.SetShownC(t.bar, false)
    else
      local timer
      if ns.testMode then
        if not t.test or now - t.test.start >= t.test.duration then
          t.test = { start = now, duration = t.spec.default }
        end
        timer = t.test
      else
        timer = Current(t, now)
      end
      Draw(t, timer, now)
    end
  end
end

function M:Test(on)
  for _, t in ipairs(self.trackers) do
    t.test = nil
    if not on then ns.SetShownC(t.bar, false) end
  end
end
