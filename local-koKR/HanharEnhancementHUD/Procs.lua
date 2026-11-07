-- Procs.lua
-- A row of cooldown icons for whatever you pick on the Tracking tab
-- (Stormstrike, shocks, Fire Nova). Icons turn red when your target is out
-- of that spell's range, plus the Flurry buff in the top-right corner.
--
-- Cooldown numbers are secret in combat, so the timers are drawn by
-- Blizzard's Cooldown widget from a duration object; the addon only reads
-- the never-secret "is it on cooldown" flags. The WINDFURY! alert lives in
-- Swing.lua.

local _, ns = ...
local C = ns.C
local M = {}
ns.RegisterModule("procs", M)

local FLURRY_ID = 16257
local FALLBACK_FLURRY = "Interface\\Icons\\Ability_GhoulFrenzy"
local SIZE, GAP = 32, 4

local TEST_FLURRY = { count = 2 }

function M:Init(parent)
  self.flurry = ns.CreateIcon(parent, SIZE)
  self.flurry:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)

  self.row = CreateFrame("Frame", nil, parent)
  self.row:SetSize(236, SIZE)
  self.row:SetPoint("TOP", parent, "TOP", 0, -40)
  self.pool = {}
  self.icons = {}
  self.nextTick = 0

  self.flurryDue = true
  self.nextFlurryRead = 0

  local ev = CreateFrame("Frame")
  C.Register(ev, "SPELL_UPDATE_COOLDOWN")
  C.Register(ev, "PLAYER_ENTERING_WORLD")
  ev:SetScript("OnEvent", function()
    ns.Safe("procs", function() self:UpdateCooldowns() end)
  end)

  -- Flurry is only re-read when your buffs change (or combat starts or
  -- ends, which changes what the client lets addons see).
  local aura = CreateFrame("Frame")
  C.Register(aura, "UNIT_AURA", "player")
  C.Register(aura, "PLAYER_REGEN_ENABLED")
  C.Register(aura, "PLAYER_REGEN_DISABLED")
  aura:SetScript("OnEvent", function()
    self.flurryDue = true
    self.nextTick = 0
  end)

  ns.Book.OnChange(function() self:Refilter() end)
  self:Refilter()
end

-- Rebuild the icon row from the spells you chose to track.
function M:Refilter()
  self.flurryName, self.flurryIcon = C.SpellInfo(FLURRY_ID)
  self.flurryName = self.flurryName or "Flurry"
  self.flurry.icon:SetTexture(self.flurryIcon or FALLBACK_FLURRY)

  local list = {}
  for _, e in ipairs(ns.Book.cooldowns) do
    if e.known and ns.IsCooldownTracked(e.key) then list[#list + 1] = e end
  end

  self.icons = {}
  for i, e in ipairs(list) do
    local ic = self.pool[i]
    if not ic then
      ic = ns.CreateIcon(self.row, SIZE, true)
      self.pool[i] = ic
    end
    ic.spell = e.name
    local _, icon = C.SpellInfo(e.name)
    ic.icon:SetTexture(icon or e.icon)
    self.icons[i] = ic
  end
  for i = #list + 1, #self.pool do
    self.pool[i]:Hide()
  end

  local n = #self.icons
  local x = (236 - (n * SIZE + math.max(0, n - 1) * GAP)) / 2
  for _, ic in ipairs(self.icons) do
    ic:ClearAllPoints()
    ic:SetPoint("LEFT", self.row, "LEFT", x, 0)
    ic:Show()
    x = x + SIZE + GAP
  end

  self:RefreshVisibility()
  self:UpdateCooldowns()
end

function M:RefreshVisibility()
  self.row:SetShown(self.enabled or false)
  self.flurry:SetShown(self.enabled or false)
end

function M:SetEnabled(on)
  self.enabled = on
  self:RefreshVisibility()
end

-- Grey while cooling down, red when your target is out of range, bright
-- and green-bordered when ready.
local function Paint(ic)
  local state = ic.onCD and 1 or (ic.outOfRange and 2 or 3)
  if ic._paint == state then return end
  ic._paint = state
  if state == 1 then
    ic.icon:SetVertexColor(0.5, 0.5, 0.5)
    ns.SetBorder(ic, ns.COLORS.off)
  elseif state == 2 then
    ic.icon:SetVertexColor(1, 0.3, 0.3)
    ns.SetBorder(ic, ns.COLORS.bad)
  else
    ic.icon:SetVertexColor(1, 1, 1)
    ns.SetBorder(ic, ns.COLORS.ok)
  end
end

local function Dim(ic, onCD)
  ic.onCD = onCD
  Paint(ic)
end

function M:UpdateCooldowns()
  if ns.testMode then return end
  for _, ic in ipairs(self.icons) do
    Dim(ic, ns.ApplySpellCooldown(ic, ic.spell))
  end
end

-- Range checks stay readable in combat on Forever. Spells with no target
-- (Fire Nova) or melee spells answer "in range", so they never turn red.
function M:UpdateRange()
  local hostile = ns.HostileTarget()
  for _, ic in ipairs(self.icons) do
    local out = false
    if hostile and C_Spell and C_Spell.IsSpellInRange then
      local ok, inRange = pcall(C_Spell.IsSpellInRange, ic.spell, "target")
      out = ok and C.Plain(inRange) == false
    end
    if ns.testMode then out = (ic == self.icons[2]) end
    if out ~= ic.outOfRange then
      ic.outOfRange = out
      Paint(ic)
    end
  end
end

function M:OnUpdate(now)
  if now < self.nextTick then return end
  self.nextTick = now + 0.2
  self:UpdateRange()

  local fl = self.flurry
  local b, readable = self.flurryBuff, self.flurryReadable
  if ns.testMode then
    b, readable = TEST_FLURRY, true
  elseif self.flurryDue or now >= self.nextFlurryRead then
    self.flurryDue = false
    self.nextFlurryRead = now + 5
    b, readable = C.FindBuff(C.NameSet(self.flurryName))
    self.flurryBuff, self.flurryReadable = b, readable
  end

  if b then
    ns.SetDesat(fl.icon, false)
    ns.SetAlphaC(fl.icon, 1)
    ns.SetText(fl.count, (b.count and b.count > 0) and b.count or "")
    ns.SetBorder(fl, ns.COLORS.warn)
  else
    -- Not up, or hidden by the client in combat: show it dimmed either way.
    ns.SetDesat(fl.icon, true)
    ns.SetAlphaC(fl.icon, readable and 0.35 or 0.2)
    ns.SetText(fl.count, "")
    ns.SetBorder(fl, ns.COLORS.off)
  end
end

function M:Test(on)
  local now = GetTime()
  for i, ic in ipairs(self.icons) do
    if on then
      ic.cd:SetCooldown(now, (i == 1) and 20 or 6)
      Dim(ic, true)
    else
      ic.cd:Clear()
      Dim(ic, false)
    end
  end
  if not on then self:UpdateCooldowns() end
end
