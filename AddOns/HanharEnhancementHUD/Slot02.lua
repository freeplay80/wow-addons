-- Slot02.lua: keybinds
-- Keys are bound from Lua with override bindings, so they don't need a
-- Bindings.xml file (which would mean a game restart). Set them on the
-- General tab: click a button, press the key.
--
-- Override bindings win over your normal WoW keybinds for the same key
-- while EnhanceHUD is loaded. They can't change during combat; changes
-- made in combat apply as soon as it ends.

local _, ns = ...
local T = ns.Text
local C = ns.C

local K = {}
ns.Keys = K

K.ACTIONS = {
  { id = "toggle",  label = T("Show or hide the HUD") },
  { id = "lock",    label = T("Lock or unlock the HUD") },
  { id = "test",    label = T("Test mode") },
  { id = "options", label = T("Open settings") },
}

local RUN = {
  toggle = function()
    ns.userHidden = not ns.userHidden
    ns.UpdateCombatAlpha()
    ns.Print(ns.userHidden and T("HUD hidden. Press the key again to show it.") or T("HUD shown."))
  end,
  lock = function()
    ns.db.locked = not ns.db.locked
    ns.Print(ns.db.locked and T("locked.") or T("unlocked. Drag the HUD or the alert text."))
    ns.Changed()
  end,
  test = function() ns.StartTest() end,
  options = function() ns.ToggleOptions() end,
}

-- One hidden button per action; bindings "click" them.
local owner = CreateFrame("Frame", "EnhanceHUDKeyOwner", UIParent)
local buttons = {}
for _, a in ipairs(K.ACTIONS) do
  local name = "EnhanceHUDKey_" .. a.id
  local b = CreateFrame("Button", name, UIParent)
  b:Hide()
  b:SetScript("OnClick", function() ns.Safe("keybinds", RUN[a.id]) end)
  buttons[a.id] = name
end

local pending = false

local function InCombat()
  local ok, v = C.Call(InCombatLockdown)
  return ok and C.Plain(v) == true
end

function ns.ApplyKeybinds()
  if InCombat() then pending = true return end
  pending = false
  C.Call(ClearOverrideBindings, owner)
  for _, a in ipairs(K.ACTIONS) do
    local key = ns.db.keys[a.id]
    if key and key ~= "" then
      C.Call(SetOverrideBindingClick, owner, true, key, buttons[a.id], "LeftButton")
    end
  end
end

local ev = CreateFrame("Frame")
C.Register(ev, "PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function()
  if pending and ns.initialized then ns.Safe("keybinds", ns.ApplyKeybinds) end
end)

-- Turns a key press into a binding string like "SHIFT-F" or "CTRL-ALT-3".
local MODIFIER_KEYS = {
  LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true,
  LALT = true, RALT = true, LMETA = true, RMETA = true,
}

function K.ComboFromKey(key)
  if not key or MODIFIER_KEYS[key] then return nil end
  local function down(fn)
    local ok, v = C.Call(fn)
    return ok and C.Plain(v) == true
  end
  local combo = ""
  if down(IsAltKeyDown) then combo = combo .. "ALT-" end
  if down(IsControlKeyDown) then combo = combo .. "CTRL-" end
  if down(IsShiftKeyDown) then combo = combo .. "SHIFT-" end
  return combo .. key
end

-- The key-capture button used on the General tab.
-- Left-click, then press a key to bind it. Esc cancels. Right-click clears.
function K.CreateKeyButton(parent, actionId, width)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(width or 130, 22)
  b.bg = b:CreateTexture(nil, "BACKGROUND")
  b.bg:SetAllPoints()
  b.bg:SetColorTexture(0.18, 0.18, 0.22, 1)
  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.text:SetPoint("LEFT", 4, 0)
  b.text:SetPoint("RIGHT", -4, 0)
  if b.text.SetWordWrap then b.text:SetWordWrap(false) end
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")

  function b:Refresh()
    if self.capturing then
      self.text:SetText(T("Press a key..."))
      self.bg:SetColorTexture(0.12, 0.35, 0.6, 1)
    else
      self.text:SetText(ns.db.keys[actionId] or T("Not bound"))
      self.bg:SetColorTexture(0.18, 0.18, 0.22, 1)
    end
  end

  local function Stop(self)
    self.capturing = false
    self:EnableKeyboard(false)
    self:SetScript("OnKeyDown", nil)
    self:Refresh()
  end

  b:SetScript("OnClick", function(self, mouse)
    if mouse == "RightButton" then
      ns.db.keys[actionId] = nil
      Stop(self)
      ns.Changed()
      return
    end
    if InCombat() then
      ns.Print(T("leave combat to set a keybind."))
      return
    end
    self.capturing = true
    self:EnableKeyboard(true)
    if self.SetPropagateKeyboardInput then pcall(self.SetPropagateKeyboardInput, self, false) end
    self:SetScript("OnKeyDown", function(btn, key)
      if key == "ESCAPE" then Stop(btn) return end
      local combo = K.ComboFromKey(key)
      if not combo then return end -- a modifier alone: keep waiting
      -- One key per action: drop it from any other action first.
      for id, k in pairs(ns.db.keys) do
        if k == combo then ns.db.keys[id] = nil end
      end
      ns.db.keys[actionId] = combo
      Stop(btn)
      ns.Changed()
      if parent.RefreshKeys then parent.RefreshKeys() end
    end)
    self:Refresh()
  end)
  b:SetScript("OnHide", function(self) if self.capturing then Stop(self) end end)
  b:Refresh()
  return b
end
