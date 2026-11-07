-- Options.lua
-- The settings window (/ehud), with General and Tracking tabs, and an entry
-- under Options > AddOns that opens it.

local _, ns = ...
local T = ns.Text
local C = ns.C

local WIDTH, HEIGHT = 380, 870
local CONTENT_TOP, CONTENT_BOTTOM = -64, 52
local window

---------------------------------------------------------------------------
-- Small widget builders with fallbacks, in case a template is missing
---------------------------------------------------------------------------

local function Backdrop(frame, bg, edge)
  if frame.SetBackdrop then
    frame:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\Buttons\\WHITE8X8",
      edgeSize = 1,
    })
    frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
    frame:SetBackdropBorderColor(edge[1], edge[2], edge[3], edge[4])
  else
    local t = frame:CreateTexture(nil, "BACKGROUND")
    t:SetAllPoints()
    t:SetColorTexture(bg[1], bg[2], bg[3], bg[4])
  end
end

local function NewFrame(kind, parent, template)
  if template then
    local ok, f = pcall(CreateFrame, kind, nil, parent, template)
    if ok and f then return f end
  end
  return CreateFrame(kind, nil, parent)
end

local function Header(parent, text, y)
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fs:SetPoint("TOPLEFT", 18, y)
  fs:SetText(text)
  local line = parent:CreateTexture(nil, "ARTWORK")
  line:SetColorTexture(1, 0.82, 0, 0.25)
  line:SetHeight(1)
  line:SetPoint("LEFT", fs, "RIGHT", 8, 0)
  line:SetPoint("RIGHT", parent, "RIGHT", -18, 0)
  fs.MoveTo = function(self, newY)
    self:ClearAllPoints()
    self:SetPoint("TOPLEFT", 18, newY)
  end
  return fs
end

-- A checkbox whose get/set can be swapped later (the Tracking tab reuses them).
-- maxWidth caps the label; longer text is cut off with "..." and shown in
-- full on hover. Default: the rest of the row.
local function Checkbox(parent, label, x, y, get, set, small, maxWidth)
  local cb = NewFrame("CheckButton", parent, "UICheckButtonTemplate")
  if not cb:GetNormalTexture() then
    cb:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    cb:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    cb:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    cb:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
    cb:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
  end
  local size = small and 20 or 24
  cb:SetSize(size, size)
  cb:SetPoint("TOPLEFT", x, y)
  if type(cb.Text) == "table" and cb.Text.SetText then cb.Text:SetText("") end
  cb.label = cb:CreateFontString(nil, "OVERLAY", small and "GameFontHighlightSmall" or "GameFontHighlight")
  cb.label:SetPoint("LEFT", cb, "RIGHT", 2, 0)
  cb.label:SetJustifyH("LEFT")
  if cb.label.SetWordWrap then cb.label:SetWordWrap(false) end
  if cb.label.SetMaxLines then cb.label:SetMaxLines(1) end
  cb.get, cb.set = get, set

  function cb:SetMaxWidth(w)
    self.maxWidth = w
    self.label:SetWidth(w)
  end
  cb:SetMaxWidth(maxWidth or (WIDTH - 18 - (x + size + 2)))

  function cb:SetLabel(text, enabled)
    self.fullText = text
    self.label:SetText(text)
    local shown = math.min(self.label:GetStringWidth() or 0, self.maxWidth)
    self:SetHitRectInsets(0, -(shown + 6), 0, 0)
    if enabled == false then
      self:Disable()
      self.label:SetTextColor(0.5, 0.5, 0.5)
    else
      self:Enable()
      self.label:SetTextColor(1, 1, 1)
    end
  end
  cb:SetLabel(label)

  cb:SetScript("OnClick", function(self)
    self.set(self:GetChecked() and true or false)
    ns.Changed()
  end)
  -- Full text on hover when the label had to be cut short.
  cb:SetScript("OnEnter", function(self)
    local cut = (self.label:GetStringWidth() or 0) > self.maxWidth
    if cut and GameTooltip then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(self.fullText, 1, 1, 1, 1, true)
      GameTooltip:Show()
    end
  end)
  cb:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
  cb.Refresh = function(self) self:SetChecked(self.get() and true or false) end
  return cb
end

-- A wrapped note of fixed width. Returns the font string and its height,
-- so the next control can be placed below however many lines it takes.
local function WrappedNote(parent, text, x, y, font)
  local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontDisableSmall")
  fs:SetPoint("TOPLEFT", x, y)
  fs:SetWidth(WIDTH - 18 - x)
  fs:SetJustifyH("LEFT")
  if fs.SetWordWrap then fs:SetWordWrap(true) end
  fs:SetText(text)
  local h = fs:GetStringHeight()
  if type(h) ~= "number" or h <= 0 then h = 12 * math.ceil(#text / 60) end
  return fs, h
end

local function Slider(parent, label, y, minV, maxV, step, fmt, get, set)
  local title = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  title:SetPoint("TOPLEFT", 22, y)
  title:SetText(label)

  local value = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  value:SetPoint("TOPRIGHT", -22, y)

  local s = CreateFrame("Slider", nil, parent)
  s:SetOrientation("HORIZONTAL")
  s:SetHeight(16)
  s:SetPoint("TOPLEFT", 22, y - 18)
  s:SetPoint("TOPRIGHT", -22, y - 18)
  s:SetMinMaxValues(minV, maxV)
  s:SetValueStep(step)
  if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
  s:EnableMouseWheel(true)

  local track = s:CreateTexture(nil, "BACKGROUND")
  track:SetColorTexture(0.25, 0.25, 0.28, 1)
  track:SetHeight(4)
  track:SetPoint("LEFT", 0, 0)
  track:SetPoint("RIGHT", 0, 0)

  s.fill = s:CreateTexture(nil, "ARTWORK")
  s.fill:SetColorTexture(0.25, 0.65, 0.95, 1)
  s.fill:SetHeight(4)
  s.fill:SetPoint("LEFT", 0, 0)

  local thumb = s:CreateTexture(nil, "OVERLAY")
  thumb:SetColorTexture(0.95, 0.95, 0.95, 1)
  thumb:SetSize(10, 16)
  s:SetThumbTexture(thumb)

  local function Show(v)
    value:SetText(string.format(fmt, v))
    local frac = (v - minV) / (maxV - minV)
    s.fill:SetWidth(math.max(1, frac * s:GetWidth()))
  end

  s:SetScript("OnValueChanged", function(self, v)
    v = math.floor(v / step + 0.5) * step
    Show(v)
    if self.updating then return end
    set(v)
    ns.Changed()
  end)
  s:SetScript("OnMouseWheel", function(self, delta)
    self:SetValue(math.max(minV, math.min(maxV, self:GetValue() + delta * step)))
  end)
  s:SetScript("OnSizeChanged", function(self) Show(self:GetValue()) end)

  s.Refresh = function(self)
    self.updating = true
    self:SetValue(get())
    self.updating = false
    Show(get())
  end
  return s
end

local function Button(parent, label, width, onClick)
  local btn = NewFrame("Button", parent, "UIPanelButtonTemplate")
  btn:SetSize(width, 24)
  btn:SetText(label)
  if not btn:GetFontString() then
    btn:SetNormalFontObject("GameFontNormal")
    btn:SetText(label)
    Backdrop(btn, { 0.2, 0.2, 0.22, 1 }, { 0.5, 0.5, 0.5, 1 })
  end
  btn:SetScript("OnClick", onClick)
  return btn
end

local function Tab(parent, text, x, onClick)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(86, 24)
  b:SetPoint("TOPLEFT", x, -36)
  b.bg = b:CreateTexture(nil, "BACKGROUND")
  b.bg:SetAllPoints()
  b.fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  b.fs:SetPoint("CENTER")
  b.fs:SetText(text)
  function b:SetSelected(on)
    if on then
      self.bg:SetColorTexture(0.12, 0.35, 0.6, 0.9)
      self.fs:SetTextColor(1, 1, 1)
    else
      self.bg:SetColorTexture(0.15, 0.15, 0.18, 1)
      self.fs:SetTextColor(0.7, 0.7, 0.7)
    end
  end
  b:SetScript("OnClick", onClick)
  return b
end

local function Content(parent)
  local c = CreateFrame("Frame", nil, parent)
  c:SetPoint("TOPLEFT", 0, CONTENT_TOP)
  c:SetPoint("BOTTOMRIGHT", 0, CONTENT_BOTTOM)
  return c
end

---------------------------------------------------------------------------
-- General tab: position, auto-hide, sections, keybinds, saving
---------------------------------------------------------------------------

local function SmallButton(parent, label, width, onClick)
  local b = Button(parent, label, width, onClick)
  b:SetHeight(22)
  b:RegisterForClicks("LeftButtonUp")
  return b
end

local function BuildGeneral(g)
  local db = function() return ns.db end
  local controls = {}
  local function add(c) controls[#controls + 1] = c return c end

  local y = -8
  Header(g, T("Display"), y)
  y = y - 24
  add(Checkbox(g, T("Lock HUD (unlock to drag the HUD and alerts)"), 18, y,
    function() return db().locked end, function(v) db().locked = v end))

  -- Nudge row: 1 pixel per click, 10 with Shift held.
  y = y - 30
  local lbl = g:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  lbl:SetPoint("TOPLEFT", 22, y - 4)
  lbl:SetText(T("Nudge"))
  local function step()
    local ok, v = C.Call(IsShiftKeyDown)
    return (ok and C.Plain(v) == true) and 10 or 1
  end
  local nudges = {
    { "<", -1, 0 }, { ">", 1, 0 }, { "^", 0, 1 }, { "v", 0, -1 },
  }
  local x = 76
  for _, n in ipairs(nudges) do
    local b = SmallButton(g, n[1], 30, function() ns.Nudge(n[2] * step(), n[3] * step()) end)
    b:SetPoint("TOPLEFT", x, y)
    x = x + 34
  end
  local center = SmallButton(g, T("Center"), 70, function() ns.CenterHorizontally() end)
  center:SetPoint("TOPLEFT", x + 6, y)
  WrappedNote(g, T("Shift-click moves 10 pixels. Center lines it up."), 76, y - 24)

  y = y - 50
  add(Slider(g, T("Scale"), y, 0.5, 2, 0.05, "%.2f",
    function() return db().scale end, function(v) db().scale = v end))
  y = y - 46
  add(Slider(g, T("Opacity out of combat"), y, 0, 100, 5, "%d%%",
    function() return db().oocAlpha * 100 end, function(v) db().oocAlpha = v / 100 end))

  y = y - 50
  Header(g, T("Auto-hide (never in combat)"), y)
  y = y - 24
  add(Checkbox(g, T("While mounted"), 18, y,
    function() return db().hideMounted end, function(v) db().hideMounted = v end, false, 146))
  add(Checkbox(g, T("While resting"), 196, y,
    function() return db().hideResting end, function(v) db().hideResting = v end, false, 140))
  y = y - 28
  add(Checkbox(g, T("Out of combat unless an enemy is targeted"), 18, y,
    function() return db().hideIdle end, function(v) db().hideIdle = v end))

  y = y - 38
  Header(g, T("Show"), y)
  local sections = {
    { "totems", T("Totem timers") }, { "swing", T("Swing timer") },
    { "buffs", T("Imbue and shield") }, { "procs", T("Cooldowns and Flurry") },
    { "dots", T("Flame Shock timer") }, { "reinc", T("Reincarnation") },
  }
  y = y - 24
  for i, sct in ipairs(sections) do
    local col = (i - 1) % 2
    add(Checkbox(g, sct[2], col == 0 and 18 or 196, y,
      function() return db().show[sct[1]] end, function(v) db().show[sct[1]] = v end,
      false, col == 0 and 146 or 140))
    if col == 1 then y = y - 28 end
  end

  y = y - 10
  Header(g, T("Keybinds"), y)
  y = y - 24
  local keyButtons = {}
  for _, a in ipairs(ns.Keys.ACTIONS) do
    local l = g:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    l:SetPoint("TOPLEFT", 22, y - 4)
    l:SetWidth(190)
    l:SetJustifyH("LEFT")
    if l.SetWordWrap then l:SetWordWrap(false) end
    l:SetText(a.label)
    local kb = ns.Keys.CreateKeyButton(g, a.id, 140)
    kb:SetPoint("TOPRIGHT", -22, y)
    keyButtons[#keyButtons + 1] = kb
    y = y - 26
  end
  local _, khH = WrappedNote(g, T("Click, then press a key. Right-click clears. These override WoW's own binding for that key."), 22, y - 2)
  function g.RefreshKeys()
    for _, kb in ipairs(keyButtons) do kb:Refresh() end
  end

  y = y - khH - 12
  Header(g, T("Settings"), y)
  y = y - 24
  add(Checkbox(g, T("Remember my settings between launches"), 18, y,
    function() return db().remember end,
    function(v)
      db().remember = v
      if v then
        ns.Persist.SaveNow()
      elseif not ns.Persist.Forget() then
        ns.Print(T("leave combat, then uncheck again to remove the macros."))
      end
    end))
  WrappedNote(g, T("Turn this on if your settings don't survive a restart. It also keeps them in macros named HanharHUD, HanharHUD2 and so on."), 46, y - 24)

  function g.Refresh()
    for _, c in ipairs(controls) do c:Refresh() end
    g.RefreshKeys()
  end
  g:SetScript("OnShow", g.Refresh)
end

---------------------------------------------------------------------------
-- Extras tab: optional features
---------------------------------------------------------------------------

local function BuildExtras(e)
  local db = function() return ns.db end
  local controls = {}
  local function add(c) controls[#controls + 1] = c return c end
  local y = -8
  local function Toggle(label, key, onSet)
    add(Checkbox(e, label, 18, y,
      function() return db()[key] end,
      function(v) db()[key] = v; if onSet then onSet(v) end end))
    y = y - 24
  end
  local function Note(text)
    local _, h = WrappedNote(e, text, 46, y + 2)
    y = y - h - 4
  end

  Header(e, T("Swing and Windfury"), y); y = y - 24
  Toggle(T("Show NOT ATTACKING on the swing bar"), "notAttacking")
  Toggle(T("Windfury stats in chat after each fight"), "wfStats")
  Toggle(T("Track Windfury records"), "wfRecords")

  y = y - 8
  Header(e, T("Totems and buffs"), y); y = y - 24
  Toggle(T("Warn when I'm out of range of my totems"), "totemRange")
  Toggle(T("Pre-pull reminder also checks shield and imbue"), "prepullBuffs")
  Toggle(T("Stormstrike debuff timer"), "ssTimer")

  y = y - 8
  Header(e, T("Leveling"), y); y = y - 24
  Toggle(T("Warn about old spell ranks on my action bars"), "rankCheck")
  local check = Button(e, T("Check my bars now"), 150, function()
    if ns.RankCheck then ns.RankCheck:ListAll() end
  end)
  check:SetPoint("TOPLEFT", 46, y)
  y = y - 32

  y = y - 4
  Header(e, T("Solo and group setups"), y); y = y - 24
  add(Checkbox(e, T("Separate solo and group setups"), 18, y,
    function() return db().autoProfile end,
    function(v) ns.Profiles:SetEnabled(v); e.Refresh() end))
  y = y - 24
  Note(T("Switches when you enter or leave a dungeon or raid. Covers position, sections, auto-hide, tracked spells and totems, and pre-pull stars."))
  y = y - 4
  -- Status on its own line, buttons below it, so nothing can overlap.
  local status = e:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  status:SetPoint("TOPLEFT", 46, y)
  status:SetWidth(WIDTH - 18 - 46)
  status:SetJustifyH("LEFT")
  y = y - 18
  local solo = Button(e, T("Use solo"), 90, function() ns.Profiles:Command("solo"); e.Refresh() end)
  solo:SetPoint("TOPLEFT", 46, y)
  local group = Button(e, T("Use group"), 90, function() ns.Profiles:Command("group"); e.Refresh() end)
  group:SetPoint("LEFT", solo, "RIGHT", 8, 0)
  y = y - 30

  y = y - 4
  Header(e, T("Guild chat and minimap"), y); y = y - 24
  Toggle(T("Answer HEH, Mark, Vark, 67 and Let It Ride"), "hehReply")
  Toggle(T("Show the minimap button"), "minimapButton")

  y = y - 8
  Header(e, T("Share and save"), y); y = y - 24
  add(Checkbox(e, T("Separate settings for this character"), 18, y,
    function() return db().perChar end,
    function(v) ns.Persist.SetPerCharacter(v); e.Refresh() end))
  y = y - 24
  Note(T("Off: all your shamans share one setup. Also turns on \"Remember my settings.\""))
  y = y - 2
  local exp = Button(e, T("Export setup"), 120, function() ns.Share:ShowExport() end)
  exp:SetPoint("TOPLEFT", 46, y)
  local imp = Button(e, T("Import setup"), 120, function() ns.Share:ShowImport() end)
  imp:SetPoint("LEFT", exp, "RIGHT", 8, 0)
  y = y - 34

  Header(e, T("Diagnostics"), y); y = y - 24
  Toggle(T("Keep a diagnostics log"), "diagnostics")
  Note(T("Records what the Forever client lets addons read, so the HUD can be tuned from real data. No chat or names."))
  y = y - 4
  local show = Button(e, T("Show summary"), 120, function() if ns.Diag then ns.Diag:Summary() end end)
  show:SetPoint("TOPLEFT", 46, y)

  function e.Refresh()
    for _, c in ipairs(controls) do c:Refresh() end
    local on = db().autoProfile
    local which = ns.Profiles.LABEL[db().activeProfile or "solo"]
    status:SetText(on and T("Now using: %s setup"):format(which) or T("Off: one setup everywhere"))
    solo:SetShown(on)
    group:SetShown(on)
  end
  e:SetScript("OnShow", e.Refresh)
end

---------------------------------------------------------------------------
-- Alerts tab: per-alert text and sound, alert text placement, timings
---------------------------------------------------------------------------

local function BuildAlerts(a)
  local db = function() return ns.db end
  local controls = {}
  local function add(c) controls[#controls + 1] = c return c end

  local y = -8
  Header(a, T("Alerts"), y)
  y = y - 24
  add(Checkbox(a, T("Play alert sounds (master switch)"), 18, y,
    function() return db().sound end, function(v) db().sound = v end))

  y = y - 30
  local function col(text, x)
    local fs = a:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetText(text)
  end
  col(T("Alert"), 22); col(T("Text"), 178); col(T("Sound"), 216); col(T("Which sound"), 262)
  y = y - 16

  for _, al in ipairs(ns.ALERTS) do
    local id = al.id
    local l = a:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    l:SetPoint("TOPLEFT", 22, y - 4)
    l:SetWidth(150)
    l:SetJustifyH("LEFT")
    if l.SetWordWrap then l:SetWordWrap(false) end
    l:SetText(al.label)
    add(Checkbox(a, "", 176, y,
      function() return db().alerts[id].text end, function(v) db().alerts[id].text = v end, true))
    add(Checkbox(a, "", 218, y,
      function() return db().alerts[id].sound end, function(v) db().alerts[id].sound = v end, true))
    -- Cycles through the sound list and plays the new choice.
    local pick = CreateFrame("Button", nil, a)
    pick:SetSize(96, 18)
    pick:SetPoint("TOPLEFT", 262, y - 1)
    pick.bg = pick:CreateTexture(nil, "BACKGROUND")
    pick.bg:SetAllPoints()
    pick.bg:SetColorTexture(0.18, 0.18, 0.22, 1)
    pick.text = pick:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    pick.text:SetPoint("LEFT", 4, 0)
    pick.text:SetPoint("RIGHT", -4, 0)
    if pick.text.SetWordWrap then pick.text:SetWordWrap(false) end
    pick.Refresh = function(self)
      local kit = db().alerts[id].kit or 1
      self.text:SetText((ns.SOUNDS[kit] or ns.SOUNDS[1]).label .. " >")
    end
    pick:SetScript("OnClick", function(self)
      local c = db().alerts[id]
      c.kit = ((c.kit or 1) % #ns.SOUNDS) + 1
      ns.PlaySoundChoice(c.kit)
      self:Refresh()
      ns.Changed()
    end)
    add(pick)
    y = y - 20
  end

  y = y - 14
  Header(a, T("Alert text"), y)
  y = y - 24
  y = y - 8
  add(Slider(a, T("Alert text size"), y, 12, 36, 1, "%d",
    function() return db().alertSize end, function(v) db().alertSize = v end))
  y = y - 40
  local _, mvH = WrappedNote(a, T("Unlock the HUD (General tab) to drag the alert text."), 22, y)

  y = y - mvH - 12
  Header(a, T("Timing"), y)
  y = y - 26
  add(Slider(a, T("Warn when imbue has less than"), y, 0, 300, 15, T("%d sec"),
    function() return db().imbueWarn end, function(v) db().imbueWarn = v end))
  y = y - 46
  add(Slider(a, T("Pulse totems in the last"), y, 0, 15, 1, T("%d sec"),
    function() return db().totemWarn end, function(v) db().totemWarn = v end))
  y = y - 46
  add(Slider(a, T("Flame Shock bar turns red in the last"), y, 0, 6, 1, T("%d sec"),
    function() return db().dotWarn end, function(v) db().dotWarn = v end))

  y = y - 44
  Header(a, T("Ready check"), y)
  y = y - 24
  add(Checkbox(a, T("Check my consumables and buffs on ready check"), 18, y,
    function() return db().rcEnabled end, function(v) db().rcEnabled = v end))
  y = y - 26
  local rcBoxes = {
    { T("Food"), "rcFood" }, { T("Flask"), "rcFlask" },
    { T("Elixirs"), "rcElixirs" }, { T("Raid buffs from my group"), "rcBuffs" },
    { T("Shield and imbue"), "rcSelf" },
  }
  for i, o in ipairs(rcBoxes) do
    local key = o[2]
    add(Checkbox(a, o[1], (i % 2 == 1) and 40 or 196, y,
      function() return db()[key] end, function(v) db()[key] = v end, true,
      (i % 2 == 1) and 130 or 144))
    if i % 2 == 0 or i == #rcBoxes then y = y - 22 end
  end
  y = y - 10
  add(Slider(a, T("Elixirs needed"), y, 1, 4, 1, "%d",
    function() return db().rcElixirCount end, function(v) db().rcElixirCount = v end))
  y = y - 40
  local test = Button(a, T("Check now"), 100, function() if ns.ReadyCheck then ns.ReadyCheck:Run() end end)
  test:SetPoint("TOPLEFT", 40, y)

  function a.Refresh()
    for _, c in ipairs(controls) do c:Refresh() end
  end
  a:SetScript("OnShow", a.Refresh)
end

---------------------------------------------------------------------------
-- Tracking tab: which cooldowns and totems to watch
---------------------------------------------------------------------------

local ELEMENT_NAMES = { T("Fire"), T("Earth"), T("Water"), T("Air"), T("Other") }
local OTHER_COLOR = { 0.8, 0.8, 0.8 }

local function BuildTracking(t)
  local pool, labels = {}, {}
  local usedBoxes, usedLabels
  local Star

  local cdHeader = Header(t, T("Cooldowns"), -8)
  local totemHeader = Header(t, T("Totems"), -100)
  local colYFinal

  local function Box(x, y, text, enabled, get, set, maxWidth)
    usedBoxes = usedBoxes + 1
    local cb = pool[usedBoxes]
    if not cb then
      cb = Checkbox(t, "", 0, 0, get, set, true)
      pool[usedBoxes] = cb
    end
    cb.get, cb.set = get, set
    cb:ClearAllPoints()
    cb:SetPoint("TOPLEFT", x, y)
    cb:SetMaxWidth(maxWidth or 140)
    cb:SetLabel(text, enabled)
    cb:Show()
    cb:Refresh()
  end

  -- Small star toggle: "remind me before a pull if this totem isn't down."
  local stars, usedStars = {}, 0
  local STAR = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1"
  local function PaintStar(b)
    local on = ns.IsTotemRequired(b.totem)
    b.tex:SetDesaturated(not on)
    b.tex:SetAlpha(on and 1 or 0.3)
  end
  function Star(x, y, name)
    usedStars = usedStars + 1
    local b = stars[usedStars]
    if not b then
      b = CreateFrame("Button", nil, t)
      b:SetSize(16, 16)
      b.tex = b:CreateTexture(nil, "ARTWORK")
      b.tex:SetAllPoints()
      b.tex:SetTexture(STAR)
      b:SetScript("OnClick", function(self)
        ns.db.totemsRequired[self.totem] = (not ns.IsTotemRequired(self.totem)) or nil
        PaintStar(self)
        ns.Changed()
      end)
      b:SetScript("OnEnter", function(self)
        if GameTooltip then
          GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
          GameTooltip:SetText(T("Pre-pull reminder"))
          GameTooltip:AddLine(T("In a dungeon or raid, warn me if this totem isn't down when I target an enemy out of combat."), 1, 1, 1, true)
          GameTooltip:Show()
        end
      end)
      b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
      stars[usedStars] = b
    end
    b.totem = name
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", x, y)
    PaintStar(b)
    b:Show()
  end

  local function Label(x, y, text, font, color)
    usedLabels = usedLabels + 1
    local fs = labels[usedLabels]
    if not fs then
      fs = t:CreateFontString(nil, "OVERLAY")
      labels[usedLabels] = fs
    end
    fs:SetFontObject(font)
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetPoint("RIGHT", t, "RIGHT", -18, 0)
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    if color then fs:SetTextColor(color[1], color[2], color[3]) else fs:SetTextColor(1, 1, 1) end
    fs:Show()
  end

  function t.Rebuild()
    usedBoxes, usedLabels, usedStars = 0, 0, 0
    colYFinal = nil
    local book = ns.Book

    -- Cooldowns, two columns
    local y = -32
    for i, e in ipairs(book.cooldowns) do
      local col = (i - 1) % 2
      local text = e.label .. (e.known and "" or T(" (not learned)"))
      Box(col == 0 and 18 or 196, y, text, e.known,
        function() return ns.IsCooldownTracked(e.key) end,
        function(v) ns.db.cooldowns[e.key] = v or nil end, col == 0 and 152 or 144)
      if col == 1 then y = y - 22 end
    end
    if #book.cooldowns % 2 == 1 then y = y - 22 end

    -- Totems, grouped by element in two columns
    y = y - 16
    totemHeader:MoveTo(y)
    y = y - 22
    Label(22, y, T("Unchecked totems are hidden and don't alert. Star a totem to be reminded in dungeons and raids if it isn't down when you target an enemy."),
      "GameFontDisableSmall")
    local noteH = labels[usedLabels]:GetStringHeight()
    if type(noteH) ~= "number" or noteH <= 0 then noteH = 36 end
    y = y - noteH - 8

    if #book.totems == 0 then
      Label(22, y, T("You don't know any totems yet."), "GameFontHighlightSmall")
      y = y - 20
    else
      local groups = { {}, {}, {}, {}, {} }
      for _, e in ipairs(book.totems) do
        table.insert(groups[book.ElementOf(e.name) or 5], e)
      end
      local colY = { y, y }
      for g = 1, 5 do
        local list = groups[g]
        if #list > 0 then
          local col = (g == 1 or g == 3) and 1 or (g == 2 or g == 4) and 2
            or (colY[1] >= colY[2] and 1 or 2)
          local x = (col == 1) and 18 or 196
          local color = ns.TOTEM_ELEMENTS[g] and ns.TOTEM_ELEMENTS[g].color or OTHER_COLOR
          Label(x + 2, colY[col], ELEMENT_NAMES[g], "GameFontNormalSmall", color)
          colY[col] = colY[col] - 16
          for _, e in ipairs(list) do
            Box(x, colY[col], (e.name:gsub(" Totem$", "")), true,
              function() return ns.IsTotemMonitored(e.name) end,
              function(v) ns.db.totemsOff[e.name] = (not v) or nil end, 126)
            Star(x + 152, colY[col] - 2, e.name)
            colY[col] = colY[col] - 20
          end
          colY[col] = colY[col] - 8
        end
      end
      colYFinal = colY
    end

    for i = usedBoxes + 1, #pool do pool[i]:Hide() end
    for i = usedLabels + 1, #labels do labels[i]:Hide() end
    for i = usedStars + 1, #stars do stars[i]:Hide() end
  end

  t:SetScript("OnShow", t.Rebuild)
  ns.Book.OnChange(function()
    if t:IsVisible() then t.Rebuild() end
  end)
end

---------------------------------------------------------------------------
-- The window
---------------------------------------------------------------------------

local function Build()
  local f = NewFrame("Frame", UIParent, "BackdropTemplate")
  _G.EnhanceHUDOptions = f
  f:SetSize(WIDTH, HEIGHT)
  f:SetPoint("CENTER")
  f:SetFrameStrata("DIALOG")
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  Backdrop(f, { 0.06, 0.06, 0.08, 0.95 }, { 0.3, 0.3, 0.35, 1 })
  f:Hide()
  pcall(table.insert, UISpecialFrames, "EnhanceHUDOptions") -- Esc closes it

  local bar = f:CreateTexture(nil, "ARTWORK")
  bar:SetColorTexture(0.12, 0.35, 0.6, 1)
  bar:SetPoint("TOPLEFT", 1, -1)
  bar:SetPoint("TOPRIGHT", -1, -1)
  bar:SetHeight(30)

  local logo
  if ns.MakeLogo then
    logo = ns.MakeLogo(f, 22, "OVERLAY")
  else
    logo = f:CreateTexture(nil, "OVERLAY")
    logo:SetSize(22, 22)
    logo:SetTexture("Interface\\AddOns\\HanharEnhancementHUD\\icon")
  end
  logo:SetPoint("LEFT", bar, "LEFT", 8, 0)

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("LEFT", logo, "RIGHT", 6, 0)
  title:SetText("|cffffffff" .. ns.NAME .. "|r")

  local sub = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  sub:SetPoint("LEFT", title, "RIGHT", 8, -1)
  sub:SetText("v" .. ns.VERSION)

  local close = NewFrame("Button", f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", 2, 2)
  if not close:GetNormalTexture() then
    close:SetSize(24, 24)
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetNormalFontObject("GameFontNormalLarge")
    close:SetText("x")
  end
  close:SetScript("OnClick", function() f:Hide() end)

  local general = Content(f)
  local tracking = Content(f)
  local alerts = Content(f)
  local extras = Content(f)
  BuildGeneral(general)
  BuildTracking(tracking)
  BuildAlerts(alerts)
  BuildExtras(extras)
  local pages = { general, tracking, alerts, extras }

  local tabs = {}
  local function Select(which)
    for i, page in ipairs(pages) do
      page:SetShown(i == which)
      tabs[i]:SetSelected(i == which)
    end
  end
  tabs[1] = Tab(f, T("General"), 12, function() Select(1) end)
  tabs[2] = Tab(f, T("Tracking"), 101, function() Select(2) end)
  tabs[3] = Tab(f, T("Alerts"), 190, function() Select(3) end)
  tabs[4] = Tab(f, T("Extras"), 279, function() Select(4) end)
  Select(1)

  local test = Button(f, T("Test mode"), 108, function() ns.StartTest() end)
  test:SetPoint("BOTTOMLEFT", 18, 16)
  local resetPos = Button(f, T("Reset position"), 116, function()
    ns.db.point = { "CENTER", "UIParent", "CENTER", 0, -180 }
    ns.Changed()
  end)
  resetPos:SetPoint("LEFT", test, "RIGHT", 8, 0)
  local resetAll = Button(f, T("Reset all"), 100, function()
    local remember = ns.db.remember
    ns.ResetDefaults()
    ns.db.remember = remember
    ns.Changed()
    if general:IsShown() then general.Refresh()
    elseif alerts:IsShown() then alerts.Refresh()
    elseif extras:IsShown() then extras.Refresh()
    else tracking.Rebuild() end
  end)
  resetAll:SetPoint("LEFT", resetPos, "RIGHT", 8, 0)

  f.general, f.tracking, f.alerts, f.extras, f.Select = general, tracking, alerts, extras, Select
  return f
end

function ns.ToggleOptions()
  window = window or Build()
  window:SetShown(not window:IsShown())
end

---------------------------------------------------------------------------
-- Options > AddOns entry
---------------------------------------------------------------------------

local function RegisterBlizzardPanel()
  local settings = rawget(_G, T("Settings"))
  if not (settings and settings.RegisterCanvasLayoutCategory and settings.RegisterAddOnCategory) then return end

  local panel = CreateFrame("Frame")
  panel.name = ns.NAME
  local t = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  t:SetPoint("TOPLEFT", 16, -16)
  t:SetText(ns.NAME)
  local d = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  d:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -8)
  d:SetText(T("All settings live in the %s window. You can also type /ehud."):format(ns.NAME))
  local b = Button(panel, T("Open settings"), 220, function()
    if HideUIPanel and SettingsPanel then pcall(HideUIPanel, SettingsPanel) end
    window = window or Build()
    window:Show()
  end)
  b:SetPoint("TOPLEFT", d, "BOTTOMLEFT", 0, -12)

  local ok, category = pcall(settings.RegisterCanvasLayoutCategory, panel, panel.name)
  if ok and category then pcall(settings.RegisterAddOnCategory, category) end
end

local ev = CreateFrame("Frame")
C.Register(ev, "PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
  if ns.disabled then return end
  ns.Safe("options", RegisterBlizzardPanel)
end)
