-- Swing.lua
-- Main-hand swing timer driven by the client's PLAYER_SWING event (Forever
-- has no readable combat log). Enhancement in Forever is two-handed, so
-- there is no off-hand bar. A main-hand swing that lands well before the timer
-- is due is treated as a Windfury extra attack: it fires the WINDFURY!
-- alert and leaves the timer alone.
--
-- Also: a NOT ATTACKING warning when your weapon stops swinging in combat
-- (out of range, facing the wrong way, or auto-attack off), and a
-- Windfury proc summary in chat after each fight.

local _, ns = ...
local C = ns.C
local M = {}
ns.RegisterModule("swing", M)

local SWING_MAIN = 0
local EXTRA_ATTACK_WINDOW = 0.5 -- fraction of weapon speed
local IDLE_FACTOR = 1.5         -- no swing for this many weapon speeds = idle
local IDLE_GRACE = 2            -- seconds after the pull before we judge

function M:Init(parent)
  self.mh = ns.CreateBar(parent, 236, 14, { 0.95, 0.75, 0.25 }, "Main hand")
  self.mh:SetPoint("TOP", parent, "TOP", 0, -128)
  ns.SetShownC(self.mh, false)
  self.timer = { bar = self.mh }
  self.fight = { swings = 0, procs = 0 }
  self.session = { swings = 0, procs = 0 }

  self.idleText = self.mh:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  self.idleText:SetPoint("CENTER", 0, 0)
  self.idleText:SetText("NOT ATTACKING")
  self.idleText:SetTextColor(1, 0.25, 0.25)
  ns.SetShownC(self.idleText, false)
  self:RefreshSpeeds()

  local ev = CreateFrame("Frame")
  C.Register(ev, "PLAYER_SWING")
  C.Register(ev, "UNIT_ATTACK_SPEED", "player")
  C.Register(ev, "PLAYER_ENTERING_WORLD")
  C.Register(ev, "PLAYER_EQUIPMENT_CHANGED")
  ev:SetScript("OnEvent", function(_, event, a1, a2)
    ns.Safe("swing", function()
      if event == "PLAYER_SWING" then
        self:OnSwing(a1, a2)
      elseif event == "UNIT_ATTACK_SPEED" then
        self:OnSpeedChange()
      else
        self:RefreshSpeeds()
      end
    end)
  end)
end

function M:SetEnabled(on)
  self.enabled = on
  if not on then ns.SetShownC(self.mh, false) end
end

-- Weapon speeds are secret in some situations; keep the last plain value.
function M:RefreshSpeeds()
  local ok, mh = C.Call(UnitAttackSpeed, "player")
  if not ok then return end
  local m = C.PlainNumber(mh)
  if m and m > 0 then self.speed = m end
end

function M:OnSwing(duration, swingType)
  if ns.Diag then ns.Diag:Note("swingEvent", C.Secret(duration) and "secret" or "ok") end
  if C.PlainNumber(swingType) ~= SWING_MAIN then return end
  local d = C.PlainNumber(duration)
  local speed = (d and d > 0) and d or self.speed
  if not speed then return end

  local t = self.timer
  local now = GetTime()
  if t.start and t.speed and (now - t.start) < t.speed * EXTRA_ATTACK_WINDOW then
    ns.OnWindfury()
    self.fight.procs = self.fight.procs + 1
    if ns.WFRecords then ns.WFRecords:Proc() end
    return
  end
  t.start = now
  t.speed = speed
  self.fight.swings = self.fight.swings + 1
  if ns.WFRecords then ns.WFRecords:Swing() end
end

-- Haste or slow effects: keep the same percent of the swing done.
function M:OnSpeedChange()
  local old = self.speed
  self:RefreshSpeeds()
  local new, t = self.speed, self.timer
  if t.start and t.speed and new and new ~= old then
    local frac = (GetTime() - t.start) / t.speed
    if frac < 1 then t.start = GetTime() - frac * new end
    t.speed = new
  end
end

function M:OnCombatStart()
  self.combatStart = GetTime()
  self.fight = { swings = 0, procs = 0 }
  self.idleWarned = false
  if ns.WFRecords then ns.WFRecords:StartFight() end
end

function M:OnCombatEnd()
  ns.SetShownC(self.idleText, false)
  local f, s = self.fight, self.session
  s.swings, s.procs = s.swings + f.swings, s.procs + f.procs
  if ns.db.wfStats and f.swings >= 3 then
    local rate = f.procs / f.swings * 100
    local srate = s.swings > 0 and (s.procs / s.swings * 100) or 0
    ns.Print(string.format("Windfury: %d %s in %d swings (%d%%). Session: %d in %d (%d%%).",
      f.procs, f.procs == 1 and "proc" or "procs", f.swings, math.floor(rate + 0.5),
      s.procs, s.swings, math.floor(srate + 0.5)))
  end
  if ns.WFRecords then ns.WFRecords:EndFight(f.swings, f.procs) end
  if ns.Diag then ns.Diag:FightEnded(f.swings, f.procs, self.combatStart and (GetTime() - self.combatStart)) end
end

-- In combat with an enemy targeted but no swing for a while: say so.
function M:CheckIdle(now)
  local t = self.timer
  local speed = t.speed or self.speed
  local idle = false
  if ns.db.notAttacking and ns.inCombat and speed and self.combatStart
      and now - self.combatStart > IDLE_GRACE and ns.HostileTarget() then
    local last = t.start or self.combatStart
    idle = now - last > speed * IDLE_FACTOR
  end
  if ns.testMode then idle = false end
  if idle then
    ns.SetShownC(self.mh, true)
    self.mh:SetValue(0)
    ns.SetBarTime(self.mh, 0)
    ns.SetShownC(self.idleText, true)
    if not self.idleWarned then
      self.idleWarned = true
      ns.Alert("NOT ATTACKING", 1, 0.25, 0.25, "notAttacking")
    end
  else
    ns.SetShownC(self.idleText, false)
    self.idleWarned = false
  end
  return idle
end

function M:OnUpdate(now)
  local t, bar = self.timer, self.mh
  if self:CheckIdle(now) then return end
  if not (t.start and t.speed) then
    ns.SetShownC(bar, false)
    return
  end
  local elapsed = now - t.start
  if ns.testMode and elapsed >= t.speed then
    t.start = now
    elapsed = 0
  end
  local left = t.speed - elapsed
  if left <= 0 and not ns.inCombat then
    ns.SetShownC(bar, false)
    t.start = nil
  else
    ns.SetShownC(bar, true)
    bar:SetValue(math.min(elapsed / t.speed, 1))
    ns.SetBarTime(bar, left)
  end
end

function M:Test(on)
  if on then
    self.timer.start, self.timer.speed = GetTime(), 3.4
  else
    self.timer.start = nil
  end
end
