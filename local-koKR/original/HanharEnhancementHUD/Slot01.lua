-- Slot01.lua: Windfury records
-- Personal bests, fed by the swing timer's Windfury detection:
--   * most procs in one fight
--   * best proc rate in one fight (fights with at least 15 swings)
--   * longest streak of back-to-back swings that each proc'd
-- A new record prints one line in chat. Toggle on the General tab or with
-- /ehud records on | off. /ehud records shows them; /ehud records reset
-- clears them.

local _, ns = ...

local R = {}
ns.WFRecords = R

local MIN_SWINGS_FOR_RATE = 15

-- Per-fight streak tracking.
local streak, bestStreak = 0, 0
local curProcced, prevProcced = false, false

function R:Records()
  local db = ns.db
  if type(db.wfBest) ~= "table" then db.wfBest = { procs = 0, rate = 0, streak = 0 } end
  return db.wfBest
end

function R:StartFight()
  streak, bestStreak = 0, 0
  curProcced, prevProcced = false, false
end

-- Called by Swing.lua for every normal (non-extra) swing.
function R:Swing()
  if not curProcced then streak = 0 end
  prevProcced = curProcced
  curProcced = false
end

-- Called by Swing.lua for every Windfury extra attack.
function R:Proc()
  if curProcced then return end -- one proc per swing counts once
  curProcced = true
  streak = prevProcced and (streak + 1) or 1
  if streak > bestStreak then bestStreak = streak end
end

function R:EndFight(swings, procs)
  if not (ns.db and ns.db.wfRecords) or swings < 3 then return end
  local best = self:Records()
  local news = {}

  if procs > best.procs then
    news[#news + 1] = string.format("%d %s in one fight (was %d)", procs, procs == 1 and "proc" or "procs", best.procs)
    best.procs = procs
  end
  if swings >= MIN_SWINGS_FOR_RATE then
    local rate = math.floor(procs / swings * 100 + 0.5)
    if rate > best.rate then
      news[#news + 1] = string.format("%d%% proc rate over %d swings (was %d%%)", rate, swings, best.rate)
      best.rate = rate
    end
  end
  if bestStreak > best.streak and bestStreak >= 2 then
    news[#news + 1] = string.format("%d swings in a row with a proc (was %d)", bestStreak, best.streak)
    best.streak = bestStreak
  end

  if #news > 0 then
    ns.Print("|cffffd100New Windfury record:|r " .. table.concat(news, "; ") .. ".")
    if ns.Persist then ns.Persist.SaveSoon() end
  end
end

function R:Show()
  local best = self:Records()
  ns.Print(string.format("Windfury records: %d procs in one fight, %d%% best rate (%d+ swings), %d-swing proc streak.",
    best.procs, best.rate, MIN_SWINGS_FOR_RATE, best.streak))
  if not ns.db.wfRecords then ns.Print("records are off. /ehud records on to track them.") end
end

function R:Reset()
  ns.db.wfBest = { procs = 0, rate = 0, streak = 0 }
  ns.Print("Windfury records cleared.")
  if ns.Persist then ns.Persist.SaveSoon() end
end

-- /ehud records [on|off|reset] is routed here from Core.lua.
function R:Command(arg)
  arg = (arg or ""):lower()
  if arg == "on" or arg == "off" then
    ns.db.wfRecords = (arg == "on")
    ns.Print("Windfury records " .. arg .. ".")
    ns.Changed()
  elseif arg == "reset" then
    self:Reset()
  else
    self:Show()
  end
end
