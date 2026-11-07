-- Core.lua
-- Settings and defaults, the HUD frame, shared widgets, the alert system,
-- visibility (auto-hide), shared helpers and the /ehud command.
-- Feature code lives in the other files; see README.txt for the map.

local ADDON, ns = ...
local T = ns.Text

-- The version lives here, not in the .toc: changing the .toc needs a full
-- game restart, and everything else only needs /reload.
ns.VERSION = "2.2.6"
ns.NAME = T("Hanhar Enhancement HUD")
local C = ns.C

ns.defaults = {
  point = { "CENTER", "UIParent", "CENTER", 0, -180 },
  scale = 1.0,
  locked = true,     -- start locked so the HUD can't be dragged by accident
  sound = true,      -- master switch for alert sounds
  oocAlpha = 0.6,    -- HUD opacity out of combat
  imbueWarn = 60,    -- seconds left on weapon imbue before warning
  totemWarn = 5,     -- seconds left on a totem before it pulses
  dotWarn = 3,       -- Flame Shock bar turns red with this many seconds left
  show = { totems = true, swing = true, buffs = true, procs = true, dots = true, reinc = true },
  remember = false,  -- also keep settings in a macro (the beta forgot them on restart)
  hehReply = true,   -- answer HEH, Mark, Vark, 67 and Let It Ride in guild chat
  notAttacking = true, -- warn when your weapon stops swinging in combat
  wfStats = true,    -- Windfury proc summary after each fight
  wfRecords = true,  -- track Windfury personal bests
  totemRange = true, -- FAR label and warning when you leave your totems
  diagnostics = true,  -- log what the client allows (see Slot05.lua)
  rankCheck = true,    -- warn about old spell ranks on your bars
  prepullBuffs = true, -- pre-pull reminder also checks shield and imbue
  ssTimer = true,      -- Stormstrike debuff bar
  autoProfile = false, -- separate solo and group setups
  minimapButton = true,
  perChar = false,     -- this character keeps its own settings macros
  -- Ready check (Slot10.lua)
  rcEnabled = true, rcFood = true, rcFlask = true, rcElixirs = true,
  rcBuffs = true, rcSelf = true, rcElixirCount = 2,
  minimapAngle = 215,  -- degrees around the minimap edge

  -- Auto-hide (never in combat, never while the HUD is unlocked)
  hideMounted = true,
  hideResting = true,
  hideIdle = false,  -- out of combat with no enemy targeted

  -- Alert text: its own movable frame, or chat
  alertPoint = { "CENTER", "UIParent", "CENTER", 0, 60 },
  alertSize = 20,

  -- Per-alert settings; filled from ns.ALERTS below
  alerts = {},

  -- Keybinds by action ("toggle", "lock", "test", "options"); nil = unbound
  keys = {},
}

-- Every alert EnhanceHUD can raise. `sound` is the default.
ns.ALERTS = {
  { id = "windfury",      label = T("WINDFURY!"),            sound = false },
  { id = "totemDown",     label = T("Totem down"),           sound = true },
  { id = "prepull",       label = T("Pre-pull totems"),      sound = true },
  { id = "imbueMissing",  label = T("No weapon imbue"),      sound = true },
  { id = "imbueExpiring", label = T("Imbue expiring"),       sound = true },
  { id = "fsExpired",     label = T("Flame Shock expired"),  sound = true },
  { id = "ankhs",         label = T("Out of Ankhs"),         sound = true },
  { id = "notAttacking",  label = T("NOT ATTACKING"),        sound = false },
  { id = "totemRange",    label = T("Totems out of range"),  sound = true },
  { id = "readyCheck",    label = T("Ready check"),          sound = true },
}
for _, a in ipairs(ns.ALERTS) do
  ns.defaults.alerts[a.id] = { text = true, sound = a.sound, kit = 1 }
end

-- Sounds you can pick per alert.
ns.SOUNDS = {
  { label = T("Raid warning"), kit = (SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8959 },
  { label = T("Ready check"),  kit = (SOUNDKIT and SOUNDKIT.READY_CHECK) or 8960 },
  { label = T("Alarm"),        kit = (SOUNDKIT and SOUNDKIT.ALARM_CLOCK_WARNING_3) or 12889 },
  { label = T("Map ping"),     kit = (SOUNDKIT and SOUNDKIT.MAP_PING) or 3175 },
}

function ns.PlaySoundChoice(index)
  local s = ns.SOUNDS[index] or ns.SOUNDS[1]
  pcall(PlaySound, s.kit, "Master")
end

ns.modules = {}

-- Runs fn under pcall. The first error from each section is printed once;
-- the rest are swallowed so they can't flood the client's 100-error cap.
local reported = {}
function ns.Safe(key, fn, ...)
  local ok, err = pcall(fn, ...)
  if not ok and ns.Diag and ns.db then pcall(ns.Diag.Error, ns.Diag, key, tostring(err)) end
  if not ok and not reported[key] then
    reported[key] = true
    DEFAULT_CHAT_FRAME:AddMessage("|cff3fa9f5" .. ns.NAME .. "|r: " ..
      T("the %s section hit an error and will keep trying quietly: %s"):format(T(key), tostring(err)))
  end
  return ok
end

function ns.RegisterModule(key, mod)
  mod.key = key
  table.insert(ns.modules, mod)
end

local function Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cff3fa9f5" .. ns.NAME .. "|r: " .. msg)
end
ns.Print = Print

local function CopyDefaults(src, dst)
  for k, v in pairs(src) do
    if type(v) == "table" then
      if type(dst[k]) ~= "table" then dst[k] = {} end
      CopyDefaults(v, dst[k])
    elseif dst[k] == nil then
      dst[k] = v
    end
  end
  return dst
end

function ns.FormatTime(sec)
  if sec >= 60 then return string.format("%dm", math.ceil(sec / 60)) end
  if sec >= 10 then return string.format("%d", math.floor(sec)) end
  if sec > 0 then return string.format("%.1f", sec) end
  return ""
end

---------------------------------------------------------------------------
-- Main frame
---------------------------------------------------------------------------

local hud = CreateFrame("Frame", "EnhanceHUDFrame", UIParent)
hud:SetSize(236, 180)
hud:SetClampedToScreen(true)
hud:SetMovable(true)
hud:RegisterForDrag("LeftButton")
hud:SetScript("OnDragStart", function(self)
  if not ns.db.locked then self:StartMoving() end
end)
hud:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  local p, _, rp, x, y = self:GetPoint()
  ns.db.point = { p, "UIParent", rp, x, y }
  if ns.Persist then ns.Persist.SaveSoon() end
end)
hud:Hide()
ns.hud = hud

ns.unlockBG = hud:CreateTexture(nil, "BACKGROUND")
ns.unlockBG:SetPoint("TOPLEFT", -4, 4)
ns.unlockBG:SetPoint("BOTTOMRIGHT", 4, -4)
ns.unlockBG:SetColorTexture(0.0, 0.25, 0.7, 0.3)

ns.unlockLabel = hud:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
ns.unlockLabel:SetPoint("TOP", hud, "BOTTOM", 0, -8)
ns.unlockLabel:SetText(T("Drag to move. Type /ehud lock when done."))

---------------------------------------------------------------------------
-- Shared widgets
---------------------------------------------------------------------------

-- Square icon with a colored border, cooldown swirl, center timer and count.
-- blizzardNumbers: let the Cooldown widget draw the countdown itself. It can
-- show secret timings that addon code isn't allowed to read.
function ns.CreateIcon(parent, size, blizzardNumbers)
  local f = CreateFrame("Frame", nil, parent)
  f:SetSize(size, size)

  f.border = f:CreateTexture(nil, "BACKGROUND")
  f.border:SetAllPoints()
  f.border:SetColorTexture(0, 0, 0, 1)

  f.icon = f:CreateTexture(nil, "ARTWORK")
  f.icon:SetPoint("TOPLEFT", 2, -2)
  f.icon:SetPoint("BOTTOMRIGHT", -2, 2)
  f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

  f.cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
  f.cd:SetAllPoints(f.icon)
  if f.cd.SetDrawEdge then f.cd:SetDrawEdge(false) end
  if f.cd.SetHideCountdownNumbers then f.cd:SetHideCountdownNumbers(not blizzardNumbers) end

  local overlay = CreateFrame("Frame", nil, f)
  overlay:SetAllPoints()
  overlay:SetFrameLevel(f.cd:GetFrameLevel() + 2)
  f.overlay = overlay

  f.text = overlay:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
  f.text:SetPoint("CENTER", 0, 0)

  f.count = overlay:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
  f.count:SetPoint("BOTTOMRIGHT", -2, 2)

  return f
end

ns.COLORS = {
  ok = { 0.2, 0.8, 0.3 },
  warn = { 1.0, 0.8, 0.1 },
  bad = { 0.9, 0.15, 0.15 },
  off = { 0, 0, 0 },
}

function ns.SetBorder(icon, color)
  if icon._border == color then return end
  icon._border = color
  icon.border:SetColorTexture(color[1], color[2], color[3], 1)
end

---------------------------------------------------------------------------
-- Change-only setters. Every call into the game's UI costs more than Lua
-- work, and most frames change nothing, so these skip repeat values.
-- A widget should be written through these everywhere or nowhere.
---------------------------------------------------------------------------

function ns.SetText(fs, text)
  if fs._txt ~= text then fs._txt = text; fs:SetText(text) end
end

function ns.SetFont(fs, fontObject)
  if fs._font ~= fontObject then fs._font = fontObject; fs:SetFontObject(fontObject) end
end

function ns.SetTex(tex, path)
  if tex._tex ~= path then tex._tex = path; tex:SetTexture(path) end
end

function ns.SetDesat(tex, on)
  on = on and true or false
  if tex._desat ~= on then tex._desat = on; tex:SetDesaturated(on) end
end

function ns.SetAlphaC(region, a)
  if region._alpha ~= a then region._alpha = a; region:SetAlpha(a) end
end

function ns.SetShownC(frame, on)
  on = on and true or false
  if frame._vis ~= on then frame._vis = on; frame:SetShown(on) end
end

function ns.SetTextColorC(fs, r, g, b)
  local key = r * 1e6 + g * 1e3 + b
  if fs._tc ~= key then fs._tc = key; fs:SetTextColor(r, g, b) end
end

function ns.SetBarColor(bar, c)
  if bar._color ~= c then bar._color = c; bar:SetStatusBarColor(c[1], c[2], c[3]) end
end

-- Bar countdown text in tenths of a second, only rebuilt when it changes.
-- "0.0" to "59.9", built once each and reused, so bars make no garbage.
local TENTHS = {}
function ns.SetBarTime(bar, left)
  local tenths = left > 0 and math.floor(left * 10) or -1
  if bar._tenths ~= tenths then
    bar._tenths = tenths
    local text = ""
    if tenths >= 0 then
      text = TENTHS[tenths]
      if not text then
        text = string.format("%.1f", tenths / 10)
        if tenths < 600 then TENTHS[tenths] = text end
      end
    end
    bar.time:SetText(text)
  end
end

function ns.CreateBar(parent, w, h, color, label)
  local bar = CreateFrame("StatusBar", nil, parent)
  bar:SetSize(w, h)
  bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  bar:SetStatusBarColor(color[1], color[2], color[3])
  bar:SetMinMaxValues(0, 1)
  bar:SetValue(0)

  local bg = bar:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0, 0, 0, 0.6)

  bar.label = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  bar.label:SetPoint("LEFT", 4, 0)
  bar.label:SetText(label or "")

  bar.time = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  bar.time:SetPoint("RIGHT", -4, 0)
  return bar
end

-- Pulsing borders for anything that needs attention.
local pulsing = {}
function ns.SetPulse(icon, on)
  if on then
    pulsing[icon] = true
  elseif pulsing[icon] then
    pulsing[icon] = nil
    icon.border:SetAlpha(1)
  end
end

---------------------------------------------------------------------------
-- Alerts
---------------------------------------------------------------------------

-- Alerts live in their own frame so they still show when the HUD is
-- hidden, and so they can be moved and resized separately.
local alertFrame = CreateFrame("Frame", "EnhanceHUDAlert", UIParent)
alertFrame:SetSize(640, 40)
alertFrame:SetClampedToScreen(true)
alertFrame:SetMovable(true)
alertFrame:SetFrameStrata("HIGH")
alertFrame:RegisterForDrag("LeftButton")
alertFrame:SetScript("OnDragStart", function(self)
  if not ns.db.locked then self:StartMoving() end
end)
alertFrame:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  local p, _, rp, x, y = self:GetPoint()
  ns.db.alertPoint = { p, "UIParent", rp, x, y }
  if ns.Persist then ns.Persist.SaveSoon() end
end)
ns.alertFrame = alertFrame

alertFrame.bg = alertFrame:CreateTexture(nil, "BACKGROUND")
alertFrame.bg:SetAllPoints()
alertFrame.bg:SetColorTexture(0.7, 0.2, 0.1, 0.3)
alertFrame.bg:Hide()

local alert = alertFrame:CreateFontString(nil, "OVERLAY")
alert:SetFont(STANDARD_TEXT_FONT, 20, "THICKOUTLINE")
alert:SetPoint("CENTER")
-- Long alerts (like the pre-pull list) wrap instead of running off screen.
local ALERT_WIDTH = 640
alert:SetWidth(ALERT_WIDTH)
alert:SetJustifyH("CENTER")
if alert.SetWordWrap then alert:SetWordWrap(true) end
alert:Hide()

local function FitAlertFrame()
  local h = alert:GetStringHeight()
  if type(h) ~= "number" or h <= 0 then h = ns.db.alertSize end
  alertFrame:SetHeight(h + 16)
end
local alertUntil = 0

alertFrame:SetScript("OnUpdate", function()
  if not alert:IsShown() or not ns.db.locked then return end
  local left = alertUntil - GetTime()
  if left <= 0 then
    alert:Hide()
  elseif left < 0.5 then
    alert:SetAlpha(left / 0.5)
  end
end)

-- id: one of ns.ALERTS. Its settings decide text, sound and which sound.
function ns.Alert(msg, r, g, b, id)
  local cfg = id and ns.db.alerts[id]
  local showText = not cfg or cfg.text
  local playSound = cfg and cfg.sound and ns.db.sound
  -- Alerts are on-screen text only; EnhanceHUD never posts them to chat.
  if showText then
    alert:SetText(msg)
    alert:SetTextColor(r or 1, g or 0.8, b or 0.2)
    alert:SetAlpha(1)
    alert:Show()
    FitAlertFrame()
    -- Longer messages stay up a little longer so they can be read.
    alertUntil = GetTime() + 1.6 + math.min(2, #msg / 40)
  end
  if playSound then ns.PlaySoundChoice(cfg.kit) end
end

function ns.ApplyAlertFrame()
  local db = ns.db
  local p = db.alertPoint
  alertFrame:ClearAllPoints()
  alertFrame:SetPoint(p[1], UIParent, p[3], p[4], p[5])
  alert:SetFont(STANDARD_TEXT_FONT, db.alertSize, "THICKOUTLINE")
  FitAlertFrame()
  -- Unlocked: show a sample so it can be dragged into place.
  local unlocked = not db.locked
  alertFrame:EnableMouse(unlocked)
  alertFrame.bg:SetShown(unlocked)
  if unlocked then
    alert:SetText(T("Alert text: drag me"))
    alert:SetTextColor(1, 0.8, 0.2)
    alert:SetAlpha(1)
    alert:Show()
  elseif alertUntil < GetTime() then
    alert:Hide()
  end
end

function ns.OnWindfury()
  if ns.db.show.procs then
    ns.Alert(T("WINDFURY!"), 0.45, 0.85, 1, "windfury")
  end
end

---------------------------------------------------------------------------
-- Update loop
---------------------------------------------------------------------------

hud:SetScript("OnUpdate", function()
  local now = GetTime()

  if next(pulsing) then
    local a = 0.3 + 0.7 * math.abs(math.sin(now * 4))
    for icon in pairs(pulsing) do icon.border:SetAlpha(a) end
  end

  local show, mods = ns.db.show, ns.modules
  for i = 1, #mods do
    local m = mods[i]
    if show[m.key] and m.OnUpdate then ns.Safe(m.key, m.OnUpdate, m, now) end
  end
end)

---------------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------------

local function yes(fn)
  local ok, v = C.Call(fn)
  return ok and C.Plain(v) == true
end

-- Why the HUD is hidden right now, or nil if it's showing.
function ns.HideReason()
  local db = ns.db
  if ns.testMode or not db.locked then return nil end
  if ns.userHidden then return "hidden" end
  if ns.inCombat then return nil end
  if db.hideMounted and yes(IsMounted) then return "mounted" end
  if db.hideResting and yes(IsResting) then return "resting" end
  if db.hideIdle and not ns.HostileTarget() then return "idle" end
  return nil
end

-- Hidden = alpha 0, not :Hide(), so timers keep running underneath.
function ns.UpdateCombatAlpha()
  if not ns.db then return end
  if ns.HideReason() then
    ns.SetAlphaC(hud, 0)
  elseif ns.inCombat or ns.testMode or not ns.db.locked then
    ns.SetAlphaC(hud, 1)
  else
    ns.SetAlphaC(hud, ns.db.oocAlpha)
  end
end

-- Mount, rest and target changes don't all have reliable events on this
-- client, so check four times a second.
if C_Timer and C_Timer.NewTicker then
  C_Timer.NewTicker(0.25, function()
    if ns.initialized then ns.Safe("visibility", ns.UpdateCombatAlpha) end
  end)
end

-- Move the HUD by a few pixels (nudge buttons).
function ns.Nudge(dx, dy)
  local p = ns.db.point
  p[4], p[5] = p[4] + dx, p[5] + dy
  ns.Changed()
end

-- Center the HUD left-to-right, keeping its height on screen.
function ns.CenterHorizontally()
  local _, cy = hud:GetCenter()
  local _, uy = UIParent:GetCenter()
  if not cy or not uy then return end
  local y = cy - uy * UIParent:GetEffectiveScale() / hud:GetEffectiveScale()
  ns.db.point = { "CENTER", "UIParent", "CENTER", 0, math.floor(y + 0.5) }
  ns.Changed()
end

function ns.ApplySettings()
  local db = ns.db
  local p = db.point
  hud:ClearAllPoints()
  hud:SetPoint(p[1], UIParent, p[3], p[4], p[5])
  hud:SetScale(db.scale)
  hud:EnableMouse(not db.locked)
  ns.unlockBG:SetShown(not db.locked)
  ns.unlockLabel:SetShown(not db.locked)
  ns.Safe("alerts", ns.ApplyAlertFrame)
  if ns.ApplyMinimapButton then ns.Safe("minimap", ns.ApplyMinimapButton) end
  if ns.ApplyKeybinds then ns.Safe("keybinds", ns.ApplyKeybinds) end
  for _, m in ipairs(ns.modules) do
    ns.Safe(m.key, m.SetEnabled, m, db.show[m.key])
    if m.Refilter then ns.Safe(m.key, m.Refilter, m) end
  end
  ns.UpdateCombatAlpha()
end

-- Called by the options window and slash commands after any change.
function ns.Changed()
  ns.ApplySettings()
  if ns.Persist then ns.Persist.SaveSoon() end
end

-- What to watch, by name. Cooldowns use the Tracking tab's keys
-- ("Fire Nova", "Earth Shock"...); totems are all watched unless unchecked.
function ns.DefaultTracking(db)
  if type(db.cooldowns) ~= "table" then
    db.cooldowns = {}
    for k in pairs(ns.Book.DEFAULT_COOLDOWNS) do db.cooldowns[k] = true end
  end
  if type(db.totemsOff) ~= "table" then db.totemsOff = {} end
  if type(db.totemsRequired) ~= "table" then db.totemsRequired = {} end
end

function ns.IsTotemRequired(name)
  return ns.db.totemsRequired[name] == true
end

-- True inside a dungeon or raid instance.
function ns.InGroupInstance()
  local ok, inside, kind = C.Call(IsInInstance)
  if not ok or C.Plain(inside) ~= true then return false end
  kind = C.Plain(kind)
  return kind == "party" or kind == "raid"
end

-- True when you have a living enemy targeted. If the client won't say
-- whether it's attackable (possible in combat), assume it is.
local hostileAt, hostileValue = -1, false
function ns.HostileTarget()
  local now = GetTime()
  if now - hostileAt < 0.1 then return hostileValue end
  hostileAt = now
  hostileValue = ns.ReadHostileTarget()
  return hostileValue
end

function ns.ReadHostileTarget()
  local okE, exists = C.Call(UnitExists, "target")
  if not (okE and C.Plain(exists) == true) then return false end
  local okD, dead = C.Call(UnitIsDead, "target")
  if okD and C.Plain(dead) == true then return false end
  local okA, can = C.Call(UnitCanAttack, "player", "target")
  can = okA and C.Plain(can)
  if can == nil then return true end
  return can == true
end

-- Draws a spell's cooldown on an icon without touching secret numbers.
-- Returns true while the spell is cooling down (global cooldown ignored).
function ns.ApplySpellCooldown(ic, spell)
  local info = C.SpellCooldown(spell)
  local onCD = false
  if info and not info.secret then
    onCD = info.duration > 1.5
    if onCD then ic.cd:SetCooldown(info.start, info.duration) else ic.cd:Clear() end
  elseif info then
    onCD = (info.active == true) and (info.onGCD ~= true)
    if onCD then
      if not C.SetCooldownFromSpell(ic.cd, spell) then ic.cd:Clear() end
    else
      ic.cd:Clear()
    end
  end
  return onCD
end

function ns.IsCooldownTracked(key)
  return ns.db.cooldowns[key] == true
end

function ns.IsTotemMonitored(name)
  return not ns.db.totemsOff[name]
end

function ns.ResetDefaults()
  wipe(ns.db)
  CopyDefaults(ns.defaults, ns.db)
  ns.DefaultTracking(ns.db)
end

function ns.StartTest()
  ns.testMode = true
  for _, m in ipairs(ns.modules) do
    if m.Test then ns.Safe(m.key, m.Test, m, true) end
  end
  ns.UpdateCombatAlpha()
  ns.Alert(T("WINDFURY!"), 0.45, 0.85, 1, "windfury")
  C_Timer.After(15, function()
    ns.testMode = false
    for _, m in ipairs(ns.modules) do
      if m.Test then ns.Safe(m.key, m.Test, m, false) end
    end
    ns.UpdateCombatAlpha()
  end)
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_TARGET_CHANGED")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_REGEN_DISABLED")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function(_, event, arg1)
  if event == "PLAYER_TARGET_CHANGED" then
    hostileAt = -1 -- re-read on the next ask
    return
  elseif event == "ADDON_LOADED" then
    if arg1 == ADDON then
      HanharEnhancementHUDDB = CopyDefaults(ns.defaults, HanharEnhancementHUDDB or {})
      ns.db = HanharEnhancementHUDDB
    end
  elseif event == "PLAYER_LOGIN" then
    local _, class = UnitClass("player")
    if class ~= "SHAMAN" then
      ns.disabled = true
      return
    end
    ns.Safe("spellbook", ns.Book.Rebuild)
    local restored = ns.Persist and ns.Safe("settings", ns.Persist.Load, ns.db) and ns.db.remember
    ns.DefaultTracking(ns.db)
    for _, m in ipairs(ns.modules) do ns.Safe(m.key, m.Init, m, hud) end
    ns.initialized = true
    ns.ApplySettings()
    hud:Show()
    Print(restored and T("loaded with your saved settings. Type /ehud for settings.") or T("loaded. Type /ehud for settings."))
  elseif not ns.initialized then
    return
  elseif event == "PLAYER_REGEN_DISABLED" then
    ns.inCombat = true
    ns.UpdateCombatAlpha()
    for _, m in ipairs(ns.modules) do
      if m.OnCombatStart and ns.db.show[m.key] then ns.Safe(m.key, m.OnCombatStart, m) end
    end
  elseif event == "PLAYER_REGEN_ENABLED" then
    ns.inCombat = false
    ns.UpdateCombatAlpha()
    for _, m in ipairs(ns.modules) do
      if m.OnCombatEnd then ns.Safe(m.key, m.OnCombatEnd, m) end
    end
  end
end)

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------

local MODULE_NAMES = { totems = true, swing = true, buffs = true, procs = true, dots = true, reinc = true }

local function Help()
  Print(T("/ehud opens the settings window. Other commands:"))
  Print(T("  /ehud lock | unlock  - lock or move the HUD"))
  Print(T("  /ehud test  - show sample data for 15 seconds"))
  Print(T("  /ehud scale 1.2  - resize (0.5 to 2)"))
  Print(T("  /ehud fade 0.6  - out-of-combat opacity (0 to 1)"))
  Print(T("  /ehud imbue 60  - seconds before imbue warning"))
  Print(T("  /ehud sound  - toggle warning sounds"))
  Print(T("  /ehud wf  - toggle the WINDFURY! alert"))
  Print(T("  /ehud totems | swing | buffs | procs | dots | reinc  - toggle a section"))
  Print(T("  /ehud stats  - toggle the Windfury summary after fights"))
  Print(T("  /ehud records [on | off | reset]  - Windfury personal bests"))
  Print(T("  /ehud swingwarn  - toggle the NOT ATTACKING warning"))
  Print(T("  /ehud heh (or mark, vark, 67, ride)  - toggle the guild chat replies"))
  Print(T("  /ehud reset  - restore default position and settings"))
  Print(T("  /ehud rangecheck  - show what the totem range check can see"))
  Print(T("  /ehud ranks  - list old spell ranks on your action bars"))
  Print(T("  /ehud diag [clear | on | off]  - diagnostics summary"))
  Print(T("  /ehud minimap  - show or hide the minimap button"))
  Print(T("  /ehud readycheck  - run the ready-check checklist now"))
  Print(T("  /ehud export | import  - share your setup with another shaman"))
  Print(T("  /ehud setup solo | group  - switch setups (when solo/group setups are on)"))
  Print(T("  /ehud version  - show the installed version"))
  Print(T("  /ehud help  - this list"))
end

SLASH_ENHANCEHUD1 = "/ehud"
SLASH_ENHANCEHUD2 = "/hanhar"
SlashCmdList.ENHANCEHUD = function(input)
  local cmd, rest = (input or ""):match("^%s*(%S*)%s*(.-)%s*$")
  cmd = (cmd or ""):lower()
  local db = ns.db

  -- The guild chat replies work on every character.
  if (cmd == "heh" or cmd == "mark" or cmd == "vark" or cmd == "67" or cmd == "ride") and db then
    db.hehReply = not db.hehReply
    Print(T("guild chat replies (HEH, Mark, Vark, 67, Let It Ride) %s."):format(T(db.hehReply and "on" or "off")))
    if ns.Persist then ns.Persist.SaveSoon() end
    return
  end

  if ns.disabled then
    Print(T("the HUD only runs on shaman characters. /ehud heh still toggles the guild chat replies."))
    return
  end
  if not ns.initialized then return end
  local num = tonumber(rest)

  if cmd == "version" then
    Print(T("version %s."):format(ns.VERSION))
    return
  elseif cmd == "" or cmd == "options" or cmd == "config" then
    ns.ToggleOptions()
    return
  elseif cmd == "cfg" or cmd == "cfg2" then
    -- Body of the settings macros; clicking one just re-applies the settings.
    if cmd == "cfg" then ns.Persist.Decode("cfg " .. rest, db) else ns.Persist.Decode2(rest, db) end
    ns.ApplySettings()
    return
  elseif cmd == "imbuecheck" then
    for _, m in ipairs(ns.modules) do
      if m.DebugImbue then ns.Safe("buffs", m.DebugImbue, m) end
    end
    return
  elseif cmd == "lock" then
    db.locked = true
    Print(T("locked."))
  elseif cmd == "unlock" or cmd == "move" then
    db.locked = false
    Print(T("unlocked. Drag the blue box, then /ehud lock."))
  elseif cmd == "test" then
    ns.StartTest()
    Print(T("test mode for 15 seconds."))
    return
  elseif cmd == "scale" and num then
    db.scale = math.max(0.5, math.min(2, num))
    Print(T("scale ") .. db.scale)
  elseif cmd == "fade" and num then
    db.oocAlpha = math.max(0, math.min(1, num))
    Print(T("out-of-combat opacity ") .. db.oocAlpha)
  elseif cmd == "imbue" and num then
    db.imbueWarn = math.max(0, num)
    Print(T("imbue warning at %s seconds."):format(tostring(db.imbueWarn)))
  elseif cmd == "records" then
    if ns.WFRecords then ns.WFRecords:Command(rest) end
    return
  elseif cmd == "export" then
    if ns.Share then ns.Share:ShowExport() end
    return
  elseif cmd == "import" then
    if ns.Share then ns.Share:ShowImport() end
    return
  elseif cmd == "readycheck" or cmd == "rc" then
    if ns.ReadyCheck then ns.ReadyCheck:Run() end
    return
  elseif cmd == "minimap" then
    db.minimapButton = not db.minimapButton
    Print(T("minimap button %s."):format(T(db.minimapButton and "shown" or "hidden")))
  elseif cmd == "diag" then
    if ns.Diag then ns.Diag:Command(rest) end
    return
  elseif cmd == "ranks" then
    if ns.RankCheck then ns.RankCheck:ListAll() end
    return
  elseif cmd == "setup" then
    if ns.Profiles then ns.Profiles:Command(rest) end
    return
  elseif cmd == "rangecheck" then
    if ns.TotemRange then ns.TotemRange:Debug() end
    return
  elseif cmd == "stats" then
    db.wfStats = not db.wfStats
    Print(T("Windfury summary %s."):format(T(db.wfStats and "on" or "off")))
  elseif cmd == "swingwarn" then
    db.notAttacking = not db.notAttacking
    Print(T("NOT ATTACKING warning %s."):format(T(db.notAttacking and "on" or "off")))
  elseif cmd == "sound" then
    db.sound = not db.sound
    Print(T("sounds %s."):format(T(db.sound and "on" or "off")))
  elseif cmd == "wf" then
    local a = db.alerts.windfury
    a.text = not a.text
    Print(T("Windfury alert %s."):format(T(a.text and "on" or "off")))
  elseif MODULE_NAMES[cmd] then
    db.show[cmd] = not db.show[cmd]
    Print(T(cmd) .. " " .. T(db.show[cmd] and "shown" or "hidden") .. ".")
  elseif cmd == "reset" then
    local remember = db.remember
    ns.ResetDefaults()
    db.remember = remember
    Print(T("reset to defaults."))
  else
    Help()
    return
  end
  ns.Changed()
end
