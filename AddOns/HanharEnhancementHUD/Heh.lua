-- Heh.lua
-- When someone else says "HEH" in guild chat, answer with "HEH". "Mark",
-- "Vark" and "67" work the same way and get the same word back, and
-- "Let It Ride" gets "Let it Ride".
-- Works on every character, not just shamans.
--
-- Volleys: when a guildmate also runs this addon, the replies go back and
-- forth. They say HEH, you answer, their addon answers, yours answers
-- again, and so on. Each word keeps its own volley.
--
-- Guardrails:
--   * Only a message that is just the word or phrase (any capitalization,
--     extra spaces or trailing punctuation allowed) counts. "Mark my words"
--     doesn't.
--   * Never answers your own messages.
--   * Each reply waits 1.5 seconds, so the volley reads like people typing
--     and stays well under the game's chat spam limits.
--   * At most 3 replies from you per volley, so two people running this
--     can't set off an endless loop. A volley ends after 30 seconds with
--     no HEH in guild chat; the next HEH starts a new one.
--   * Skips anything the client hides during chat lockdown (boss fights
--     and other restricted moments).

local _, ns = ...
local C = ns.C

local DELAY = 1.5       -- seconds before each reply
local MAX_REPLIES = 3   -- your replies per volley
local QUIET = 30        -- seconds without a HEH that end a volley

-- Each word that starts a volley, written the way you answer it.
local WORDS = { heh = "HEH", mark = "Mark", vark = "Vark", ["67"] = "67", ["let it ride"] = "Let it Ride" }

-- Per word: your replies this volley, when the word was last seen, and
-- whether a reply is already on its way.
local volleys = {}
for word in pairs(WORDS) do volleys[word] = { replies = 0, last = -math.huge, pending = false } end

-- The word (or phrase) a message is, or nil. Spaces between words count as one.
local function WordOf(text)
  local t = text:lower():gsub("^%s+", ""):gsub("[%s%p]+$", ""):gsub("%s+", " ")
  return WORDS[t] and t or nil
end

local function IsMe(sender)
  local ok, me = C.Call(UnitName, "player")
  me = ok and C.Plain(me)
  if not me then return true end -- can't tell: stay quiet
  local short = sender:match("^([^%-]+)") or sender
  return short == me
end

local function InLockdown()
  if not (C_ChatInfo and C_ChatInfo.InChatMessagingLockdown) then return false end
  local ok, v = pcall(C_ChatInfo.InChatMessagingLockdown)
  return not ok or C.Plain(v) ~= false
end

-- The only chat the addon ever posts: these replies, to guild chat.
local function Send(text)
  if C_ChatInfo and C_ChatInfo.SendChatMessage then
    return pcall(C_ChatInfo.SendChatMessage, text, "GUILD")
  end
  return C.Call(SendChatMessage, text, "GUILD")
end

local function OnGuildChat(text, sender)
  if not (ns.db and ns.db.hehReply) then return end
  text, sender = C.Plain(text), C.Plain(sender)
  if type(text) ~= "string" or type(sender) ~= "string" then return end
  local word = WordOf(text)
  if not word then return end
  local v = volleys[word]

  -- Any message with the word, yours included, keeps its volley alive.
  local now = GetTime()
  if now - v.last > QUIET then v.replies = 0 end
  v.last = now

  if IsMe(sender) then return end
  if v.pending or v.replies >= MAX_REPLIES then return end
  if InLockdown() then return end

  v.pending = true
  v.replies = v.replies + 1
  C_Timer.After(DELAY, function()
    v.pending = false
    if ns.db and ns.db.hehReply and not InLockdown() then Send(WORDS[word]) end
  end)
end

local ev = CreateFrame("Frame")
C.Register(ev, "CHAT_MSG_GUILD")
ev:SetScript("OnEvent", function(_, _, text, sender)
  ns.Safe("heh", OnGuildChat, text, sender)
end)
