-- Slot10.lua: ready-check consumables and buffs
-- When a ready check starts (or on /ehud readycheck), EnhanceHUD checks:
--   Food        the Well Fed buff
--   Flask       any flask
--   Elixirs     at least N elixir-type buffs (N set on the Alerts tab)
--   Raid buffs  only from classes in your group: Fortitude (priest), Mark of
--               the Wild (druid), Arcane Intellect (mage), a Blessing
--               (paladin)
--   Your own    Lightning Shield and weapon imbue
-- Anything under 5 minutes counts as a warning. Results show on screen in
-- a small checklist plus one alert line; nothing goes to chat.
-- Buff names are matched in English, like the rest of the buff checks.

local _, ns = ...
local C = ns.C

local RC = {}
ns.ReadyCheck = RC

local SOON = 300 -- seconds: "expiring soon"
local SHOW_FOR = 20

local ICON_OK = "|TInterface\\RaidFrame\\ReadyCheck-Ready:14|t"
local ICON_BAD = "|TInterface\\RaidFrame\\ReadyCheck-NotReady:14|t"
local ICON_WARN = "|TInterface\\RaidFrame\\ReadyCheck-Waiting:14|t"

-- Buff names by pattern (plain text, matched anywhere in the name).
local FOOD = { "Well Fed" }
local FLASK = { "Flask of", "Distilled Wisdom", "Supreme Power", "Chromatic Resistance" }
local ELIXIR = {
  "Elixir", "Mongoose", "Giants", "Greater Agility", "Juju", "Firewater",
  "Rage of Ages", "Scorpok", "Spirit of Zanza", "Greater Intellect", "Fire Power",
  "Shadow Power", "Frost Power", "Greater Arcane", "Superior Defense", "Greater Armor",
}

-- Raid buffs, keyed by the class that provides them. IDs give local names;
-- English names are the fallback.
local RAID_BUFFS = {
  PRIEST  = { label = "Fortitude",        ids = { 1243, 21562 }, names = { "Power Word: Fortitude", "Prayer of Fortitude" } },
  DRUID   = { label = "Mark of the Wild", ids = { 1126, 21849 }, names = { "Mark of the Wild", "Gift of the Wild" } },
  MAGE    = { label = "Arcane Intellect", ids = { 1459, 23028 }, names = { "Arcane Intellect", "Arcane Brilliance" } },
  PALADIN = { label = "Blessing",         pattern = "Blessing of" },
}

local function Matches(name, patterns)
  for _, p in ipairs(patterns) do
    if name:find(p, 1, true) then return true end
  end
  return false
end

-- Every helpful aura on you: { name = secondsLeft or false }.
-- Returns nil if the client won't show auras right now.
local function MyBuffs()
  if C.AurasLocked() then return nil end
  if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then return nil end
  local out, now = {}, GetTime()
  for i = 1, 40 do
    local ok, a = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
    if not ok or C.Secret(a) then return nil end
    if a == nil then break end
    local name = C.Plain(a.name)
    if type(name) == "string" then
      local e = C.PlainNumber(a.expirationTime)
      out[name] = (e and e > 0) and (e - now) or false
    end
  end
  return out
end

-- Classes in your group, not counting you.
local function GroupClasses()
  local classes = {}
  local function add(unit)
    local ok, _, file = C.Call(UnitClass, unit)
    file = ok and C.Plain(file)
    if type(file) == "string" then classes[file] = true end
  end
  local okN, n = C.Call(GetNumGroupMembers)
  n = okN and C.PlainNumber(n) or 0
  local okR, raid = C.Call(IsInRaid)
  if okR and C.Plain(raid) == true then
    for i = 1, n do
      local ok, isMe = C.Call(UnitIsUnit, "raid" .. i, "player")
      if not (ok and C.Plain(isMe) == true) then add("raid" .. i) end
    end
  else
    for i = 1, math.max(0, n - 1) do add("party" .. i) end
  end
  return classes
end

-- Best match in a category: status "ok", "soon" or "missing", plus detail.
local function Best(buffs, test)
  local bestLeft, found, foundName = -1, false, nil
  for name, left in pairs(buffs) do
    if test(name) then
      found = true
      local l = left or math.huge
      if l > bestLeft then bestLeft, foundName = l, name end
    end
  end
  if not found then return "missing" end
  if bestLeft ~= math.huge and bestLeft < SOON then
    return "soon", string.format("%s, %s left", foundName, ns.FormatTime(bestLeft))
  end
  return "ok", foundName
end

-- Runs the whole check. Returns rows { label, status, detail }, or nil and
-- a reason when buffs can't be read.
function RC:Check()
  local db = ns.db
  local buffs = MyBuffs()
  if not buffs then return nil, "the game isn't letting addons read buffs right now" end
  local rows = {}
  local function row(label, status, detail) rows[#rows + 1] = { label = label, status = status, detail = detail } end

  if db.rcFood then
    local st, d = Best(buffs, function(n) return Matches(n, FOOD) end)
    row("Food", st, d)
  end
  if db.rcFlask then
    local st, d = Best(buffs, function(n) return Matches(n, FLASK) end)
    row("Flask", st, d)
  end
  if db.rcElixirs and (db.rcElixirCount or 0) > 0 then
    local have, soon = 0, false
    for name, left in pairs(buffs) do
      if Matches(name, ELIXIR) and not Matches(name, FLASK) then
        have = have + 1
        if left and left < SOON then soon = true end
      end
    end
    local need = db.rcElixirCount
    local st = (have >= need) and (soon and "soon" or "ok") or "missing"
    row("Elixirs", st, string.format("%d of %d", have, need))
  end
  if db.rcBuffs then
    local classes = GroupClasses()
    for class, rb in pairs(RAID_BUFFS) do
      if classes[class] then
        local names = {}
        for i, id in ipairs(rb.ids or {}) do names[#names + 1] = C.SpellName(id) or rb.names[i] end
        local st, d = Best(buffs, function(n)
          if rb.pattern then return n:find(rb.pattern, 1, true) ~= nil end
          return Matches(n, names)
        end)
        row(rb.label, st, d)
      end
    end
  end
  if db.rcSelf then
    local B
    for _, m in ipairs(ns.modules) do if m.key == "buffs" then B = m end end
    if B and B.PrepullItems then
      local refresh = B:PrepullItems(GetTime())
      local shield, imbue = "ok", "ok"
      for _, item in ipairs(refresh) do
        if item:find("Lightning Shield") then shield = item:find("charge") and "soon" or "missing" end
        if item:find("imbue") then imbue = item:find("left") and "soon" or "missing" end
      end
      if C.KnowsSpell(B.lsName) then row("Lightning Shield", shield) end
      row("Weapon imbue", imbue)
    end
  end
  return rows
end

---------------------------------------------------------------------------
-- On-screen checklist
---------------------------------------------------------------------------

local panel, hideAt

local function Build()
  local f = CreateFrame("Frame", "EnhanceHUDReadyCheck", UIParent, "BackdropTemplate")
  f:SetSize(260, 40)
  f:SetFrameStrata("HIGH")
  if f.SetBackdrop then
    f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    f:SetBackdropColor(0.05, 0.05, 0.07, 0.85)
    f:SetBackdropBorderColor(0.12, 0.35, 0.6, 1)
  end
  f:EnableMouse(true)
  f:SetScript("OnMouseUp", function(self) self:Hide() end) -- click to dismiss
  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.title:SetPoint("TOPLEFT", 10, -8)
  f.lines = {}
  f:SetScript("OnUpdate", function(self)
    if hideAt and GetTime() > hideAt then self:Hide() end
  end)
  f:Hide()
  return f
end

local COLORS = { ok = "|cff33ff33", soon = "|cffffd100", missing = "|cffff4040" }
local ICONS = { ok = ICON_OK, soon = ICON_WARN, missing = ICON_BAD }

function RC:Show(rows, reason)
  panel = panel or Build()
  panel:ClearAllPoints()
  panel:SetPoint("TOP", ns.alertFrame or UIParent, "BOTTOM", 0, -6)
  for _, l in ipairs(panel.lines) do l:Hide() end

  local missing, soon = {}, {}
  if not rows then
    panel.title:SetText("Ready check: couldn't check")
    rows = { { label = reason or "buffs unreadable", status = "soon" } }
  else
    panel.title:SetText("Ready check")
  end
  for i, r in ipairs(rows) do
    local l = panel.lines[i]
    if not l then
      l = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      l:SetPoint("TOPLEFT", 12, -8 - i * 18)
      l:SetJustifyH("LEFT")
      if l.SetWordWrap then l:SetWordWrap(false) end
      panel.lines[i] = l
    end
    local detail = r.detail and ("  |cffaaaaaa" .. r.detail .. "|r") or ""
    l:SetText(ICONS[r.status] .. " " .. COLORS[r.status] .. r.label .. "|r" .. detail)
    l:Show()
    if r.status == "missing" then missing[#missing + 1] = r.label end
    if r.status == "soon" then soon[#soon + 1] = r.label end
  end
  panel:SetHeight(18 + #rows * 18 + 10)
  -- Width follows the longest line (and the title), within limits.
  local widest = panel.title:GetStringWidth() or 0
  for i = 1, #rows do
    local sw = panel.lines[i]:GetStringWidth()
    if type(sw) == "number" and sw > widest then widest = sw end
  end
  panel:SetWidth(math.max(220, math.min(480, widest + 26)))
  hideAt = GetTime() + SHOW_FOR
  panel:Show()

  if #missing > 0 then
    ns.Alert("Missing: " .. table.concat(missing, ", "), 1, 0.3, 0.3, "readyCheck")
  elseif #soon > 0 then
    ns.Alert("Running low: " .. table.concat(soon, ", "), 1, 0.82, 0.1, "readyCheck")
  else
    ns.Alert("Ready: all consumables and buffs up", 0.3, 1, 0.3, "readyCheck")
  end
end

function RC:Run()
  local rows, reason = self:Check()
  self:Show(rows, reason)
end

local ev = CreateFrame("Frame")
C.Register(ev, "READY_CHECK")
C.Register(ev, "READY_CHECK_FINISHED")
ev:SetScript("OnEvent", function(_, event)
  if not (ns.initialized and ns.db.rcEnabled) then return end
  if event == "READY_CHECK" then
    ns.Safe("readycheck", function() RC:Run() end)
  elseif panel and panel:IsShown() then
    hideAt = math.min(hideAt or 0, GetTime() + 5) -- linger briefly after it ends
  end
end)
