-- Slot08.lua: logo and minimap button
-- The logo is icon.tga: your dripping mask artwork with a blue lightning
-- bolt through it. To change it later, overwrite icon.tga and /reload.
--
-- Minimap button: drag it around the minimap edge. Left-click opens
-- settings, right-click locks or unlocks the HUD. Hide it on the Extras tab.

local _, ns = ...
local C = ns.C

local LOGO = "Interface\\AddOns\\HanharEnhancementHUD\\icon"

function ns.LogoBase()
  return LOGO
end

function ns.MakeLogo(parent, size, layer)
  local logo = parent:CreateTexture(nil, layer or "ARTWORK")
  logo:SetSize(size, size)
  logo:SetTexture(LOGO)
  return logo
end

---------------------------------------------------------------------------
-- Minimap button
---------------------------------------------------------------------------

local RADIUS_PAD = 10
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
local button

local function Place()
  local mm = rawget(_G, "Minimap")
  if not (button and mm) then return end
  local angle = math.rad(ns.db.minimapAngle or 215)
  local r = (mm:GetWidth() / 2) + RADIUS_PAD
  button:ClearAllPoints()
  button:SetPoint("CENTER", mm, "CENTER", math.cos(angle) * r, math.sin(angle) * r)
end

local function Build()
  local mm = rawget(_G, "Minimap")
  if not mm or button then return end

  button = CreateFrame("Button", "EnhanceHUDMinimapButton", mm)
  button:SetSize(31, 31)
  button:SetFrameStrata("MEDIUM")
  button:SetFrameLevel(8)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:RegisterForDrag("LeftButton")
  button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  local bg = button:CreateTexture(nil, "BACKGROUND")
  bg:SetSize(20, 20)
  bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  bg:SetPoint("CENTER")

  local logo = ns.MakeLogo(button, 19, "ARTWORK")
  logo:SetPoint("CENTER", 0, 1)
  -- Round the square icon so it sits inside the ring.
  if button.CreateMaskTexture then
    local mask = button:CreateMaskTexture()
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(logo)
    pcall(logo.AddMaskTexture, logo, mask)
  end

  local ring = button:CreateTexture(nil, "OVERLAY", nil, 7)
  ring:SetSize(53, 53)
  ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  ring:SetPoint("TOPLEFT")

  button:SetScript("OnClick", function(_, mouse)
    if mouse == "RightButton" then
      ns.db.locked = not ns.db.locked
      ns.Print(ns.db.locked and "locked." or "unlocked. Drag the HUD or the alert text.")
      ns.Changed()
    else
      ns.ToggleOptions()
    end
  end)

  -- Drag around the minimap edge.
  button:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
      local cx, cy = mm:GetCenter()
      local okC, x, y = C.Call(GetCursorPosition)
      if not (okC and cx and x) then return end
      local scale = mm:GetEffectiveScale()
      ns.db.minimapAngle = math.deg(atan2(y / scale - cy, x / scale - cx)) % 360
      Place()
    end)
  end)
  button:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    if ns.Persist then ns.Persist.SaveSoon() end
  end)

  button:SetScript("OnEnter", function(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText(ns.NAME .. " " .. ns.VERSION)
    GameTooltip:AddLine("Left-click: settings", 1, 1, 1)
    GameTooltip:AddLine("Right-click: " .. (ns.db.locked and "unlock" or "lock") .. " the HUD", 1, 1, 1)
    GameTooltip:AddLine("Drag: move this button", 1, 1, 1)
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
end

function ns.ApplyMinimapButton()
  if ns.db.minimapButton == false then
    if button then button:Hide() end
    return
  end
  Build()
  if button then
    Place()
    button:Show()
  end
end
