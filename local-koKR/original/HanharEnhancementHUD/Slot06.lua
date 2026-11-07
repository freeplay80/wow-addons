-- Slot06.lua: outdated rank warning
-- Forever lists every rank of a spell separately, and your action bars
-- keep the rank you placed. After training, EnhanceHUD checks your bars
-- (out of combat) and tells you which buttons still hold an old rank:
--   "Earth Shock is rank 3 on bar 1, button 5. You know rank 4."
-- It speaks up when you learn a new rank, at login, and when a new
-- outdated button appears. /ehud ranks checks on demand.
-- Toggle on the Extras tab.

local _, ns = ...
local C = ns.C

local RC = {}
ns.RankCheck = RC

local SLOTS = 180 -- every action slot, including extra bars
local reported = {} -- slot -> "name:rank" already mentioned

local function InCombat()
  local ok, v = C.Call(InCombatLockdown)
  return ok and C.Plain(v) == true
end

function RC:Find()
  local B = ns.Book
  local list = {}
  for slot = 1, SLOTS do
    local ok, kind, id = pcall(GetActionInfo, slot)
    kind, id = ok and C.Plain(kind), ok and C.PlainNumber(id)
    if kind == "spell" and id then
      local name = B.nameOf[id]
      local rank, top = B.rankOf[id], name and B.maxRank[name]
      if name and rank and top and rank < top then
        list[#list + 1] = { slot = slot, name = name, rank = rank, top = top }
      end
    end
  end
  return list
end

local function Where(slot)
  return string.format("bar %d, button %d", math.floor((slot - 1) / 12) + 1, (slot - 1) % 12 + 1)
end

-- force: report everything, even what was already mentioned.
function RC:Check(force)
  if not (ns.db and (ns.db.rankCheck or force)) then return end
  if InCombat() then
    if force then ns.Print("leave combat to check your action bars.") end
    return
  end
  local list = self:Find()
  local lines = {}
  local now = {}
  for _, o in ipairs(list) do
    local key = o.name .. ":" .. o.rank
    now[o.slot] = key
    if force or reported[o.slot] ~= key then
      lines[#lines + 1] = string.format("%s is rank %d on %s. You know rank %d.", o.name, o.rank, Where(o.slot), o.top)
    end
  end
  reported = now
  if #lines > 0 then
    ns.Print("|cffffd100Outdated ranks on your bars:|r")
    for i = 1, math.min(#lines, 8) do ns.Print("  " .. lines[i]) end
    if #lines > 8 then ns.Print(string.format("  ...and %d more. /ehud ranks lists them all.", #lines - 8)) end
    if ns.Diag then ns.Diag:Fact("outdatedRanks", #list) end
  elseif force then
    ns.Print("every spell on your bars is the highest rank you know.")
  end
end

function RC:ListAll()
  if InCombat() then ns.Print("leave combat to check your action bars.") return end
  local list = self:Find()
  if #list == 0 then
    ns.Print("every spell on your bars is the highest rank you know.")
    return
  end
  ns.Print("|cffffd100Outdated ranks on your bars:|r")
  for _, o in ipairs(list) do
    ns.Print(string.format("  %s is rank %d on %s. You know rank %d.", o.name, o.rank, Where(o.slot), o.top))
  end
end

-- Batch bursts of bar and spellbook events into one check.
local queued = false
local function Queue(delay, force)
  if queued then return end
  queued = true
  C_Timer.After(delay, function()
    queued = false
    ns.Safe("ranks", function() RC:Check(force) end)
  end)
end

local ev = CreateFrame("Frame")
C.Register(ev, "PLAYER_LOGIN")
C.Register(ev, "SPELLS_CHANGED")
C.Register(ev, "ACTIONBAR_SLOT_CHANGED")
C.Register(ev, "PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    C_Timer.After(5, function() if ns.initialized then ns.Safe("ranks", function() RC:Check(false) end) end end)
  elseif ns.initialized then
    Queue(2, false)
  end
end)
