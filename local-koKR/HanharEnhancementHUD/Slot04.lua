-- Slot04.lua: totem range
-- Tells you when you've walked out of range of your own totems.
--
-- How it knows:
--   1. Distance. When you drop a totem, EnhanceHUD notes where you were
--      standing, then compares that to where you are now.
--   2. Buff check. If your position can't be read (possible in combat or
--      in instances), it checks for the totem's buff on you, when the client
--      allows it.
-- If neither is available it says nothing rather than guess.
--
-- Out of range: the totem slot shows FAR with a red border, and in combat
-- you get "Out of range: Windfury, Strength of Earth. Resummon!"
-- /ehud rangecheck prints what the check can see, for troubleshooting.

local _, ns = ...
local Text = ns.Text
local C = ns.C

local R = { drops = {}, far = {} }
ns.TotemRange = R

local DEFAULT_RANGE = 20   -- yards; most totem buffs in the original game
local DEFAULT_LIFE = 120   -- seconds, until a real duration is learned
local RANGE = {
  ["Tremor Totem"] = 30, ["Tranquil Air Totem"] = 30, ["Grounding Totem"] = 30,
}
-- Totems whose range is about the enemy, not you.
local IGNORE = {
  ["Searing Totem"] = true, ["Magma Totem"] = true, ["Fire Nova Totem"] = true,
  ["Earthbind Totem"] = true, ["Stoneclaw Totem"] = true, ["Sentry Totem"] = true,
}
-- Buff names for the backup check.
local BUFF = {
  ["Strength of Earth Totem"] = "Strength of Earth", ["Stoneskin Totem"] = "Stoneskin",
  ["Grace of Air Totem"] = "Grace of Air", ["Fire Resistance Totem"] = "Fire Resistance",
  ["Frost Resistance Totem"] = "Frost Resistance", ["Nature Resistance Totem"] = "Nature Resistance",
  ["Tranquil Air Totem"] = "Tranquil Air", ["Windwall Totem"] = "Windwall",
}

local function Position()
  local ok, a, b, _, map = C.Call(UnitPosition, "player")
  if not ok then return nil end
  a, b, map = C.PlainNumber(a), C.PlainNumber(b), C.PlainNumber(map)
  if a and b then return a, b, map end
  return nil
end

local function Watched(name)
  return name and not IGNORE[name] and ns.IsTotemMonitored(name)
end

-- Your own totem cast: remember where you stood.
local lastCast
local function OnCast(spellID)
  local id = C.PlainNumber(spellID)
  local name = id and C.SpellName(id)
  if not ns.Book.IsTotemName(name) then return end
  local x, y, map = Position()
  local drop = { name = name, x = x, y = y, map = map, t = GetTime() }
  lastCast = drop
  local el = ns.Book.ElementOf(name)
  if el then
    R.drops[el] = drop
    R.far[el] = nil
  end
end

-- A totem update right after the cast tells us the slot for new totems.
local function OnTotemUpdate(slot)
  slot = C.PlainNumber(slot)
  if not slot then return end
  if lastCast and GetTime() - lastCast.t < 1 and not ns.Book.ElementOf(lastCast.name) then
    R.drops[slot] = lastCast
    R.far[slot] = nil
    lastCast = nil
    return
  end
  -- If the client says the slot is empty, forget that drop.
  local ok, have = C.Call(GetTotemInfo, slot)
  if ok and not C.Secret(have) and not have then
    R.drops[slot] = nil
    R.far[slot] = nil
  end
end

function R:Life(name)
  return (ns.Book.durations and ns.Book.durations[name]) or DEFAULT_LIFE
end

-- true = out of range, false = in range, nil = can't tell.
function R:Check(drop, x, y, map)
  if x and drop.x then
    if map and drop.map and map ~= drop.map then return true end
    local dx, dy = x - drop.x, y - drop.y
    return math.sqrt(dx * dx + dy * dy) > (RANGE[drop.name] or DEFAULT_RANGE)
  end
  local buff = BUFF[drop.name]
  if buff then
    local b, readable = C.FindBuff(C.NameSet(buff))
    if readable then return b == nil end
  end
  return nil
end

function R:Tick()
  if not (ns.db and ns.db.totemRange and ns.db.show.totems) then
    for slot in pairs(self.far) do self.far[slot] = nil end
    self:Paint()
    return
  end
  local now = GetTime()
  local x, y, map = Position()
  local newlyFar -- made only when there's something to say
  for slot = 1, 4 do
    local drop = self.drops[slot]
    if drop and now - drop.t > self:Life(drop.name) then
      self.drops[slot], drop = nil, nil
    end
    local out = nil
    if drop and Watched(drop.name) then out = self:Check(drop, x, y, map) end
    if out and not self.far[slot] then
      newlyFar = newlyFar or {}
      newlyFar[#newlyFar + 1] = (drop.name:gsub(" Totem$", ""))
    end
    self.far[slot] = out or nil
  end
  if newlyFar and ns.inCombat then
    ns.Alert(Text("Out of range: %s. Resummon!"):format(table.concat(newlyFar, ", ")), 1, 0.35, 0.2, "totemRange")
  end
  self:Paint()
end

-- FAR label and red border on the totem slots.
-- Only touches a slot when its in/out state changes. While a slot is
-- FAR, Totems keeps its border red (see SetBorderBright there).
local T
function R:Paint()
  if not T then
    for _, m in ipairs(ns.modules) do if m.key == "totems" then T = m end end
  end
  if not (T and T.slots) then return end
  for slot, s in ipairs(T.slots) do
    local out = (self.far[slot] or (ns.testMode and slot == 4)) and true or false
    if out ~= (s.wasFar or false) then
      s.wasFar = out
      if not s.far then
        s.far = s.overlay:CreateFontString(nil, "OVERLAY", "GameFontRedSmall")
        s.far:SetPoint("TOP", 0, -2)
        s.far:SetText(Text("FAR"))
      end
      s.far:SetShown(out)
      T:SetBorderBright(s, s.active or s.secret)
    end
  end
end

function R:Debug()
  local x, y, map = Position()
  ns.Print(x and string.format(Text("your position is readable (map %s)."), tostring(map))
    or Text("your position can't be read right now; using the buff check where possible."))
  for slot = 1, 4 do
    local d = self.drops[slot]
    if d then
      local dist = (x and d.x) and math.sqrt((x - d.x) ^ 2 + (y - d.y) ^ 2) or nil
      ns.Print(string.format(Text("  %s: %s, range %d yd, %s"), d.name,
        dist and Text("%.1f yd away"):format(dist) or Text("distance unknown"),
        RANGE[d.name] or DEFAULT_RANGE,
        Text(IGNORE[d.name] and "not checked (hits enemies, not you)" or (self.far[slot] and "OUT OF RANGE" or "ok"))))
    end
  end
end

local ev = CreateFrame("Frame")
C.Register(ev, "UNIT_SPELLCAST_SUCCEEDED", "player")
C.Register(ev, "PLAYER_TOTEM_UPDATE")
ev:SetScript("OnEvent", function(_, event, a1, _, a3)
  if not ns.initialized then return end
  ns.Safe("range", function()
    if event == "UNIT_SPELLCAST_SUCCEEDED" then OnCast(a3) else OnTotemUpdate(a1) end
  end)
end)

if C_Timer and C_Timer.NewTicker then
  local function Tick() R:Tick() end
  C_Timer.NewTicker(0.5, function()
    if ns.initialized then ns.Safe("range", Tick) end
  end)
end
