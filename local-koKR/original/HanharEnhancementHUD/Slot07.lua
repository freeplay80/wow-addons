-- Slot07.lua: solo and group setups
-- With "Separate solo and group setups" on, EnhanceHUD keeps two sets of
-- choices and swaps them when you enter or leave a dungeon or raid:
--   position, scale, opacity, sections shown, auto-hide, tracked cooldowns,
--   tracked totems, pre-pull stars, Stormstrike bar, pre-pull buff check.
-- Alerts, keybinds and records are shared by both.
--
-- Whatever you change applies to the setup you're in. The first time you
-- enter the other kind of area, it starts as a copy of your current setup.
-- /ehud setup solo | group switches by hand.

local _, ns = ...
local C = ns.C

local P = {}
ns.Profiles = P

P.KEYS = {
  "point", "scale", "oocAlpha", "show", "hideMounted", "hideResting", "hideIdle",
  "cooldowns", "totemsOff", "totemsRequired", "ssTimer", "prepullBuffs",
}
P.LABEL = { solo = "Solo", group = "Group" }

local function Copy(v)
  if type(v) ~= "table" then return v end
  local t = {}
  for k, x in pairs(v) do t[k] = Copy(x) end
  return t
end

function P:Snapshot(from)
  from = from or ns.db
  local t = {}
  for _, k in ipairs(self.KEYS) do t[k] = Copy(from[k]) end
  return t
end

function P:Apply(t)
  for _, k in ipairs(self.KEYS) do
    if t[k] ~= nil then ns.db[k] = Copy(t[k]) end
  end
end

function P:Other(name)
  return name == "group" and "solo" or "group"
end

function P:Wanted()
  return ns.InGroupInstance() and "group" or "solo"
end

local function InCombat()
  local ok, v = C.Call(InCombatLockdown)
  return ok and C.Plain(v) == true
end

local pending = false

function P:Switch(target, quiet)
  local db = ns.db
  db.profiles = db.profiles or {}
  local current = db.activeProfile or "solo"
  if target == current then return end
  if InCombat() then pending = true return end
  db.profiles[current] = self:Snapshot()
  if db.profiles[target] then self:Apply(db.profiles[target]) end
  db.activeProfile = target
  ns.Changed()
  if not quiet then ns.Print("switched to your " .. self.LABEL[target]:lower() .. " setup.") end
end

function P:Auto()
  if not (ns.db and ns.db.autoProfile) then return end
  self:Switch(self:Wanted())
end

-- Called when the Extras tab checkbox changes.
function P:SetEnabled(on)
  local db = ns.db
  db.autoProfile = on
  db.profiles = db.profiles or {}
  if on then
    db.activeProfile = self:Wanted()
    db.profiles[db.activeProfile] = self:Snapshot()
    ns.Print("solo and group setups on. You're editing your " .. self.LABEL[db.activeProfile]:lower() .. " setup.")
  end
  ns.Changed()
end

function P:Command(arg)
  arg = (arg or ""):lower()
  if arg ~= "solo" and arg ~= "group" then
    ns.Print("you're on your " .. self.LABEL[ns.db.activeProfile or "solo"]:lower()
      .. " setup. /ehud setup solo or /ehud setup group switches.")
    return
  end
  if not ns.db.autoProfile then
    ns.Print("turn on \"Separate solo and group setups\" on the Extras tab first.")
    return
  end
  self:Switch(arg)
end

local ev = CreateFrame("Frame")
C.Register(ev, "PLAYER_ENTERING_WORLD")
C.Register(ev, "ZONE_CHANGED_NEW_AREA")
C.Register(ev, "PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function(_, event)
  if not ns.initialized then return end
  if event == "PLAYER_REGEN_ENABLED" and not pending then return end
  pending = false
  -- Give the client a moment to report the new instance.
  C_Timer.After(1, function() ns.Safe("setups", function() P:Auto() end) end)
end)
