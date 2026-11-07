-- Slot03.lua: AddOns menu entry and "What's new"
--
-- 1. Adds EnhanceHUD to the AddOns dropdown by the minimap, which opens
--    the settings window. Registered from code, so no .toc change.
-- 2. After an update, prints one line in chat saying what changed. The
--    last version seen is kept in a client setting (survives /reload) and
--    in the settings macro (survives a restart, when "Remember" is on).

local _, ns = ...
local T = ns.Text
local C = ns.C

-- Newest first. Add a line here with every version bump.
ns.CHANGES = {
  { "2.2.6", "\"Let It Ride\" works like HEH, Mark, Vark and 67: say it in guild chat and you get Let it Ride back" },
  { "2.2.5", "ready for the live WoW Forever launch" },
  { "2.2.4", "\"67\" works like HEH, Mark and Vark: say 67 in guild chat and you get 67 back" },
  { "2.2.3", "\"Vark\" works like HEH and Mark: say Vark in guild chat and you get Vark back" },
  { "2.2.2", "\"Mark\" works like HEH: say Mark in guild chat and you get Mark back, volleys included" },
  { "2.2.1", "HEH volleys: when a guildmate also runs the addon, HEHs go back and forth, up to 3 replies each" },
  { "2.2.0", "the addon folder is now HanharEnhancementHUD, and saved settings moved to macros named HanharHUD (moved for you automatically)" },
  { "2.1.3", "new name: Hanhar Enhancement HUD (/ehud and your saved settings are unchanged)" },
  { "2.1.2", "streamlined: the HUD only redraws what changed and rereads buffs when they change, cutting per-frame work by more than 95 percent out of combat" },
  { "2.1.1", "all text sized to fit: labels, notes, alerts and the ready-check panel" },
  { "2.1.0", "ready-check checklist for food, flask, elixirs, raid buffs, Lightning Shield and imbue (Alerts tab)" },
  { "2.0.2", "alerts are on-screen text only; the send-to-chat option is gone" },
  { "2.0.0", "share your setup (Extras > Export/Import), per-character settings, mana and enemy-cast checks in diagnostics, faster and tidier code, new README" },
  { "1.9.2", "new icon: dripping mask with a blue lightning bolt" },
  { "1.9.1", "Bloodlust and lightning bolt icon, minimap button" },
  { "1.9.0", "diagnostics log, outdated rank warning, pre-pull check for Lightning Shield and imbue, Stormstrike debuff timer, solo and group setups, new Extras tab" },
  { "1.8.1", "EnhanceHUD icon in the AddOns list and minimap menu; Tracking tab options on their own lines" },
  { "1.8.0", "totem range warning, auto-hide (mounted, resting, idle), nudge buttons, per-alert text and sound, movable alert text, keybinds, AddOns menu entry" },
  { "1.7.0", "Windfury records; pre-pull totem reminders only in dungeons and raids" },
  { "1.6.1", "updates now load with /reload instead of a restart" },
}

local CVAR = "enhanceHUDLastVersion"

local function RegisterCompartment()
  local f = rawget(_G, "AddonCompartmentFrame")
  if not (f and f.RegisterAddon) then return end
  pcall(f.RegisterAddon, f, {
    text = ns.NAME,
    icon = ns.LogoBase and ns.LogoBase() or "Interface\\AddOns\\HanharEnhancementHUD\\icon",
    notCheckable = true,
    func = function() ns.ToggleOptions() end,
    funcOnEnter = function(button)
      if GameTooltip then
        GameTooltip:SetOwner(button, "ANCHOR_LEFT")
        GameTooltip:SetText(ns.NAME .. " " .. ns.VERSION)
        GameTooltip:AddLine(T("Click to open settings."), 1, 1, 1)
        GameTooltip:Show()
      end
    end,
    funcOnLeave = function() if GameTooltip then GameTooltip:Hide() end end,
  })
end

local function LastSeen()
  if C_CVar and C_CVar.RegisterCVar then pcall(C_CVar.RegisterCVar, CVAR, "") end
  local fromCVar
  if C_CVar and C_CVar.GetCVar then
    local ok, v = pcall(C_CVar.GetCVar, CVAR)
    fromCVar = ok and C.Plain(v) or nil
  end
  if fromCVar == "" then fromCVar = nil end
  return fromCVar or ns.db.lastVersion
end

local function Remember()
  if C_CVar and C_CVar.SetCVar then pcall(C_CVar.SetCVar, CVAR, ns.VERSION) end
  ns.db.lastVersion = ns.VERSION
  if ns.Persist then ns.Persist.SaveSoon() end
end

local function WhatsNew()
  local last = LastSeen()
  if last and last ~= ns.VERSION then
    for _, entry in ipairs(ns.CHANGES) do
      if entry[1] == ns.VERSION then
        ns.Print(T("|cffffd100What's new in %s:|r %s."):format(entry[1], T(entry[2])))
        break
      end
    end
  end
  Remember()
end

local ev = CreateFrame("Frame")
C.Register(ev, "PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
  ns.Safe("menu", RegisterCompartment)
  -- Run after Core has loaded settings (and the macro) on the same event.
  C_Timer.After(1, function()
    if ns.db then ns.Safe("whatsnew", WhatsNew) end
  end)
end)
