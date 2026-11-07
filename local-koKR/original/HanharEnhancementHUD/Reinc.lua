-- Reinc.lua
-- Reincarnation cooldown with your Ankh count in the corner. The border
-- turns red when you're out of Ankhs, and you get a warning the moment the
-- last one is used or sold.

local _, ns = ...
local C = ns.C
local M = {}
ns.RegisterModule("reinc", M)

local REINCARNATION_ID = 20608
local ANKH_ITEM = 17030
local FALLBACK_ICON = "Interface\\Icons\\Spell_Nature_Reincarnation"

function M:Init(parent)
  self.icon = ns.CreateIcon(parent, 32, true)
  self.icon:SetPoint("TOPLEFT", parent, "TOPLEFT", 72, 0)
  self.icon.count:SetFontObject("NumberFontNormal")
  self.ankhs = nil
  self:Resolve()

  local ev = CreateFrame("Frame")
  C.Register(ev, "SPELLS_CHANGED")
  C.Register(ev, "SPELL_UPDATE_COOLDOWN")
  C.Register(ev, "BAG_UPDATE_DELAYED")
  C.Register(ev, "PLAYER_ENTERING_WORLD")
  ev:SetScript("OnEvent", function(_, event)
    ns.Safe("reinc", function()
      if event == "SPELLS_CHANGED" then self:Resolve() end
      if event == "BAG_UPDATE_DELAYED" or event == "PLAYER_ENTERING_WORLD" then self:UpdateAnkhs() end
      self:UpdateCooldown()
    end)
  end)
end

function M:Resolve()
  self.name = C.SpellName(REINCARNATION_ID) or "Reincarnation"
  self.known = C.KnowsSpell(self.name)
  local _, icon = C.SpellInfo(self.name)
  self.icon.icon:SetTexture(icon or FALLBACK_ICON)
  self:RefreshVisibility()
end

function M:RefreshVisibility()
  self.icon:SetShown((self.enabled and (self.known or ns.testMode)) or false)
end

function M:SetEnabled(on)
  self.enabled = on
  self:RefreshVisibility()
end

function M:CountAnkhs()
  if not (C_Item and C_Item.GetItemCount) then return nil end
  local ok, n = pcall(C_Item.GetItemCount, ANKH_ITEM)
  return ok and C.PlainNumber(n) or nil
end

function M:UpdateAnkhs()
  if not self.known then return end
  local n = self:CountAnkhs()
  if n == nil then return end
  if self.ankhs and self.ankhs > 0 and n == 0 and self.enabled then
    ns.Alert("Out of Ankhs!", 1, 0.3, 0.3, "ankhs")
  elseif self.ankhs == nil and n == 0 and self.enabled then
    ns.Print("you have no Ankhs, so Reincarnation won't work.")
  end
  self.ankhs = n
  self:Paint()
end

function M:UpdateCooldown()
  if not self.known or ns.testMode then return end
  self.onCD = ns.ApplySpellCooldown(self.icon, self.name)
  self:Paint()
end

function M:Paint()
  local ic, n = self.icon, self.ankhs
  if ns.testMode then n = 0 end
  ic.count:SetText(n and tostring(n) or "")
  if n == 0 then
    ic.count:SetTextColor(1, 0.3, 0.3)
    ns.SetBorder(ic, ns.COLORS.bad)
  else
    ic.count:SetTextColor(1, 1, 1)
    ns.SetBorder(ic, self.onCD and ns.COLORS.off or ns.COLORS.ok)
  end
  ic.icon:SetVertexColor(self.onCD and 0.5 or 1, self.onCD and 0.5 or 1, self.onCD and 0.5 or 1)
end

function M:Test(on)
  self:RefreshVisibility()
  if on then
    self.icon.cd:SetCooldown(GetTime(), 3600)
    self.onCD = true
  else
    self.icon.cd:Clear()
    self.onCD = false
    self:UpdateCooldown()
  end
  self:Paint()
end
