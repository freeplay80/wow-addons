-- Totems.lua
-- Four element slots with timers. Only the totems you check on the
-- Tracking tab are shown; the rest are ignored, alerts included.
--
-- When the client lets us read the totem, we also pulse the last few
-- seconds and warn if a totem dies early. When the slot is secret (usually
-- in combat), Blizzard's cooldown widget draws the timer, and which totem is
-- in the slot comes from your own cast event.
--
-- Pre-pull reminder: totems starred on the Tracking tab are "required."
-- In a dungeon or raid, target an enemy out of combat while one isn't down
-- and you get a warning. It stays quiet in the open world.

local _, ns = ...
local T = ns.Text
local C = ns.C
local M = {}
ns.RegisterModule("totems", M)

-- Slot order matches GetTotemInfo: 1 Fire, 2 Earth, 3 Water, 4 Air.
local ELEMENTS = {
  { name = T("Fire"),  color = { 0.95, 0.35, 0.15 }, icon = "Interface\\Icons\\Spell_Fire_SearingTotem" },
  { name = T("Earth"), color = { 0.60, 0.45, 0.20 }, icon = "Interface\\Icons\\Spell_Nature_StoneSkinTotem" },
  { name = T("Water"), color = { 0.20, 0.55, 0.95 }, icon = "Interface\\Icons\\INV_Spear_04" },
  { name = T("Air"),   color = { 0.75, 0.90, 1.00 }, icon = "Interface\\Icons\\Spell_Nature_Windfury" },
}
ns.TOTEM_ELEMENTS = ELEMENTS

local TEST_TIMES = { 42, 115, 4, 88 }
local REMIND_EVERY = 20 -- seconds between reminders

local function StripRank(name)
  if type(name) ~= "string" then return nil end
  return (name:gsub("%s+[IVX]+$", ""))
end

function M:Init(parent)
  local f = CreateFrame("Frame", nil, parent)
  f:SetSize(236, 40)
  f:SetPoint("TOP", parent, "TOP", 0, -80)
  self.frame = f
  self.slots = {}
  self.castInSlot = {}
  self.up = {}        -- slot -> { name, expires } for whatever totem is down
  self.lastRemind = 0

  for i = 1, 4 do
    local s = ns.CreateIcon(f, 40, true)
    s.element = ELEMENTS[i]
    s.index = i

    -- Faded element icon underneath, so an empty slot still says what it is.
    s.empty = s:CreateTexture(nil, "BORDER")
    s.empty:SetAllPoints(s.icon)
    s.empty:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    s.empty:SetTexture(s.element.icon)
    s.empty:SetDesaturated(true)
    s.empty:SetAlpha(0.3)

    self.slots[i] = s
    self:SetEmpty(s)
  end
  self:Layout()

  local ev = CreateFrame("Frame")
  C.Register(ev, "PLAYER_TOTEM_UPDATE")
  C.Register(ev, "PLAYER_ENTERING_WORLD")
  C.Register(ev, "UNIT_SPELLCAST_SUCCEEDED", "player")
  C.Register(ev, "PLAYER_TARGET_CHANGED")
  ev:SetScript("OnEvent", function(_, event, a1, _, a3)
    ns.Safe("totems", function()
      if event == "UNIT_SPELLCAST_SUCCEEDED" then
        self:OnCast(a3)
        return
      elseif event == "PLAYER_TARGET_CHANGED" then
        self:CheckRequired()
        return
      end
      local slot = C.PlainNumber(a1)
      if event == "PLAYER_TOTEM_UPDATE" and slot and self.slots[slot] then
        self:LinkCast(slot)
        self:Refresh(slot)
      else
        for i = 1, 4 do self:Refresh(i) end
      end
    end)
  end)

  ns.Book.OnChange(function() self:Refilter() end)
end

function M:SetEnabled(on)
  self.enabled = on
  self.frame:SetShown(on)
end

-- Your own totem casts stay readable in combat.
function M:OnCast(spellID)
  local id = C.PlainNumber(spellID)
  if not id then return end
  local name = C.SpellName(id)
  if not ns.Book.IsTotemName(name) then return end
  self.lastCast = { name = name, t = GetTime() }
  local el = ns.Book.ElementOf(name)
  if el then self.castInSlot[el] = name end
end

-- A totem update right after a cast tells us which slot a new totem uses.
function M:LinkCast(slot)
  local lc = self.lastCast
  if lc and GetTime() - lc.t < 1 then
    if not ns.Book.ElementOf(lc.name) then ns.Book.Learn(lc.name, slot) end
    if ns.Book.ElementOf(lc.name) == slot then
      self.castInSlot[slot] = lc.name
      self.lastCast = nil
    end
  end
end

-- Hide a slot when you know totems of that element but unchecked all of them.
function M:SlotVisible(i)
  local knowsAny, anyOn = false, false
  for _, e in ipairs(ns.Book.totems) do
    if ns.Book.ElementOf(e.name) == i then
      knowsAny = true
      if ns.IsTotemMonitored(e.name) then anyOn = true end
    end
  end
  return anyOn or not knowsAny
end

function M:Layout()
  local visible = {}
  for i, s in ipairs(self.slots) do
    if ns.testMode or self:SlotVisible(i) then
      visible[#visible + 1] = s
      s:Show()
    else
      s:Hide()
      ns.SetPulse(s, false)
    end
  end
  local total = #visible * 40 + math.max(0, #visible - 1) * 12
  local x = (236 - total) / 2
  for _, s in ipairs(visible) do
    s:ClearAllPoints()
    s:SetPoint("LEFT", self.frame, "LEFT", x, 0)
    x = x + 52
  end
end

function M:Refilter()
  self:Layout()
  for i = 1, 4 do self:Refresh(i) end
end

function M:SetBorderBright(s, bright)
  if s.wasFar then -- out of range (Slot04): stay red until you're back
    s.border:SetColorTexture(0.9, 0.1, 0.1, 1)
    return
  end
  local c = s.element.color
  local k = bright and 1 or 0.4
  s.border:SetColorTexture(c[1] * k, c[2] * k, c[3] * k, 1)
end

function M:SetEmpty(s)
  s.active = false
  s.expires = nil
  s.icon:SetAlpha(0)
  s.cd:Clear()
  self:SetBorderBright(s, false)
  ns.SetPulse(s, false)
end

function M:Refresh(slot)
  if ns.testMode then return end
  local s = self.slots[slot]
  local ok, have, tname, start, duration, icon, _, spellID = C.Call(GetTotemInfo, slot)
  if not ok then return end

  if C.Secret(have) or C.Secret(start) or C.Secret(duration) then
    self.up[slot] = nil
    self.secretSlots = true
    self:RefreshSecret(s, slot, icon)
    return
  end
  s.secret = false

  if have and duration and duration > 0 then
    local id = C.PlainNumber(spellID)
    local name = (id and id > 0 and C.SpellName(id)) or StripRank(C.Plain(tname))
    if name then
      ns.Book.Learn(name, slot)
      self.castInSlot[slot] = name
    end
    self.up[slot] = { name = name, expires = start + duration }
    if name then
      ns.Book.durations = ns.Book.durations or {}
      ns.Book.durations[name] = duration
    end
    if name and not ns.IsTotemMonitored(name) then
      self:SetEmpty(s) -- not one you watch: treat the slot as empty, no alerts
      return
    end
    s.active = true
    s.expires = start + duration
    s.icon:SetTexture(C.Plain(icon) or s.element.icon)
    s.icon:SetAlpha(1)
    s.cd:SetCooldown(start, duration)
    self:SetBorderBright(s, true)
    return
  end

  self.up[slot] = nil
  -- Totem gone. If it had real time left, it was killed or knocked down.
  local diedEarly = s.active and s.expires and (s.expires - GetTime()) > 1.5
  self:SetEmpty(s)
  local okDead, dead = C.Call(UnitIsDeadOrGhost, "player")
  if diedEarly and self.enabled and not (okDead and C.Plain(dead)) then
    -- Short delay so swapping to a new totem of the same element doesn't alarm.
    C_Timer.After(0.3, function()
      if not s.active and not s.secret then
        local c = s.element.color
        ns.Alert(T("%s totem down!"):format(s.element.name), c[1], c[2], c[3], "totemDown")
      end
    end)
  end
end

-- The slot is secret: let Blizzard's widgets do everything.
function M:RefreshSecret(s, slot, icon)
  s.secret = true
  s.active = nil
  s.expires = nil
  ns.SetPulse(s, false)

  local name = self.castInSlot[slot]
  if name and not ns.IsTotemMonitored(name) then
    s.icon:SetAlpha(0)
    s.cd:Clear()
    self:SetBorderBright(s, false)
    return
  end

  self:SetBorderBright(s, true)
  pcall(s.icon.SetTexture, s.icon, icon)

  local okD, d = C.Call(GetTotemDuration, slot)
  if okD and d ~= nil and s.cd.SetCooldownFromDurationObject then
    pcall(s.cd.SetCooldownFromDurationObject, s.cd, d, true)
  end

  local _, have = C.Call(GetTotemInfo, slot)
  if s.icon.SetAlphaFromBoolean then
    pcall(s.icon.SetAlphaFromBoolean, s.icon, have, 1, 0)
  else
    s.icon:SetAlpha(1)
  end
end

-- Starred totems that aren't down right now.
function M:MissingRequired(now)
  local missing = {}
  for name in pairs(ns.db.totemsRequired) do
    if ns.Book.isTotem[name] then
      local isUp = false
      for _, u in pairs(self.up) do
        if u.name == name and u.expires > now then isUp = true end
      end
      if not isUp then missing[#missing + 1] = (name:gsub(" Totem$", "")) end
    end
  end
  table.sort(missing)
  return missing
end

function M:CheckRequired()
  if ns.inCombat or not self.enabled then return end
  local now = GetTime()
  if now - self.lastRemind < REMIND_EVERY then return end
  if not ns.InGroupInstance() then return end
  if not ns.HostileTarget() then return end
  self.secretSlots = false
  for i = 1, 4 do self:Refresh(i) end
  if self.secretSlots then return end -- can't see totems right now
  local missing = self:MissingRequired(now)
  local refresh = {}
  if ns.db.prepullBuffs then
    for _, m in ipairs(ns.modules) do
      if m.key == "buffs" and m.PrepullItems then refresh = m:PrepullItems(now, T) end
    end
  end
  local parts = {}
  if #missing > 0 then parts[#parts + 1] = T("Drop: ") .. table.concat(missing, ", ") end
  if #refresh > 0 then parts[#parts + 1] = T("Refresh: ") .. table.concat(refresh, ", ") end
  if #parts > 0 then
    self.lastRemind = now
    ns.Alert(table.concat(parts, ". "), 1, 0.8, 0.2, "prepull")
  end
end

function M:OnUpdate(now)
  if now < (self.nextTick or 0) then return end
  self.nextTick = now + 0.05
  for _, s in ipairs(self.slots) do
    if s.active and s.expires then
      local left = s.expires - now
      if left <= 0 then
        if ns.testMode then
          s.expires = now + 30
          s.cd:SetCooldown(now, 30)
        else
          self:SetEmpty(s)
        end
      else
        ns.SetPulse(s, left <= ns.db.totemWarn)
      end
    end
  end
end

function M:Test(on)
  local now = GetTime()
  self:Layout()
  for i, s in ipairs(self.slots) do
    if on then
      s.active = true
      s.secret = false
      s.expires = now + TEST_TIMES[i]
      s.icon:SetTexture(s.element.icon)
      s.icon:SetAlpha(1)
      s.cd:SetCooldown(now, TEST_TIMES[i])
      self:SetBorderBright(s, true)
    else
      self:SetEmpty(s)
      self:Refresh(i)
    end
  end
end
