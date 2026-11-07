-- Slot09.lua: share your setup
-- Export turns your whole setup into one line of text another shaman can
-- paste into Import. Keybinds, Windfury records and how you save settings
-- are personal, so an import never changes those.
-- /ehud export and /ehud import open the same windows as the Extras tab.

local _, ns = ...

local S = {}
ns.Share = S

local PREFIX = "EHUD:"

function S:Export()
  local P = ns.Persist
  local one = P.Encode(ns.db):gsub("^/ehud cfg ", "")
  local two = P.Encode2(ns.db):gsub("^/ehud cfg2 ", "")
  -- Drop keybinds from the shared copy.
  two = two:gsub(";b=[^;]*", "")
  return PREFIX .. one .. "|" .. two
end

-- Returns true, or false and a reason.
function S:Import(text)
  if type(text) ~= "string" then return false, "nothing to import" end
  text = text:gsub("^%s+", ""):gsub("%s+$", "")
  local one, two = text:match("^" .. PREFIX .. "([^|]+)|(.*)$")
  if not one then return false, "that isn't a Hanhar Enhancement HUD setup string" end

  local db = ns.db
  local keep = {
    keys = db.keys, wfBest = db.wfBest, lastVersion = db.lastVersion,
    remember = db.remember, perChar = db.perChar,
  }
  local test = { show = {}, alerts = {}, keys = {}, point = {} }
  if not ns.Persist.Decode("cfg " .. one, test) then
    return false, "that setup string is damaged or from a newer version"
  end
  ns.Persist.Decode("cfg " .. one, db)
  ns.Persist.Decode2(two, db)
  for k, v in pairs(keep) do db[k] = v end
  ns.Changed()
  return true
end

---------------------------------------------------------------------------
-- Popup with a text box
---------------------------------------------------------------------------

local popup

local function Build()
  local f = CreateFrame("Frame", "EnhanceHUDShare", UIParent, "BackdropTemplate")
  f:SetSize(460, 170)
  f:SetPoint("CENTER", 0, 120)
  f:SetFrameStrata("FULLSCREEN_DIALOG")
  f:EnableMouse(true)
  f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  if f.SetBackdrop then
    f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    f:SetBackdropColor(0.06, 0.06, 0.08, 0.97)
    f:SetBackdropBorderColor(0.12, 0.35, 0.6, 1)
  end
  f:Hide()
  pcall(table.insert, UISpecialFrames, "EnhanceHUDShare")

  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  f.title:SetPoint("TOPLEFT", 14, -12)

  f.help = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  f.help:SetPoint("TOPLEFT", 14, -36)
  f.help:SetPoint("RIGHT", -14, 0)
  f.help:SetJustifyH("LEFT")

  local ok, box = pcall(CreateFrame, "EditBox", nil, f, "InputBoxTemplate")
  if not ok or not box then box = CreateFrame("EditBox", nil, f) end
  box:SetFontObject("ChatFontNormal")
  box:SetSize(424, 24)
  box:SetPoint("TOPLEFT", 20, -62)
  box:SetAutoFocus(false)
  if box.SetMaxLetters then box:SetMaxLetters(0) end
  box:SetScript("OnEscapePressed", function(self) self:ClearFocus(); f:Hide() end)
  f.box = box

  local function Btn(label, width)
    local okB, b = pcall(CreateFrame, "Button", nil, f, "UIPanelButtonTemplate")
    if not okB or not b then b = CreateFrame("Button", nil, f) end
    b:SetSize(width, 24)
    b:SetText(label)
    return b
  end
  f.apply = Btn("Apply", 90)
  f.apply:SetPoint("BOTTOMRIGHT", -110, 14)
  f.close = Btn("Close", 90)
  f.close:SetPoint("BOTTOMRIGHT", -14, 14)
  f.close:SetScript("OnClick", function() f:Hide() end)

  f.status = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  f.status:SetPoint("BOTTOMLEFT", 14, 46)
  f.status:SetPoint("RIGHT", -14, 0)
  f.status:SetJustifyH("LEFT")
  return f
end

function S:ShowExport()
  popup = popup or Build()
  popup.title:SetText("Share your Hanhar Enhancement HUD setup")
  popup.help:SetText("Press Ctrl+C to copy, then paste it to a guildmate. Keybinds and records aren't included.")
  popup.apply:Hide()
  popup.status:SetText("")
  popup.box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  popup.box:SetScript("OnTextChanged", nil)
  local text = self:Export()
  popup.box:SetText(text)
  popup:Show()
  popup.box:SetFocus()
  popup.box:HighlightText()
  -- Keep the text intact if a key is pressed by accident.
  popup.box:SetScript("OnTextChanged", function(box, user)
    if user then box:SetText(text); box:HighlightText() end
  end)
end

function S:ShowImport()
  popup = popup or Build()
  popup.title:SetText("Import a Hanhar Enhancement HUD setup")
  popup.help:SetText("Paste a setup string (Ctrl+V), then click Apply. Your keybinds and records stay as they are.")
  popup.box:SetScript("OnTextChanged", nil)
  popup.box:SetText("")
  popup.status:SetText("")
  local function Apply()
    local ok, why = S:Import(popup.box:GetText())
    if ok then
      popup.status:SetText("|cff33ff33Setup imported.|r")
      ns.Print("setup imported.")
      if EnhanceHUDOptions and EnhanceHUDOptions:IsShown() then
        EnhanceHUDOptions:Hide(); EnhanceHUDOptions:Show()
      end
    else
      popup.status:SetText("|cffff5555" .. why .. ".|r")
    end
  end
  popup.apply:SetScript("OnClick", Apply)
  popup.box:SetScript("OnEnterPressed", Apply)
  popup.apply:Show()
  popup:Show()
  popup.box:SetFocus()
end
