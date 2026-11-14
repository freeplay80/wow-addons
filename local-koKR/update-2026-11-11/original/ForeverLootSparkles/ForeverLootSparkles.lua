-- Quest item sparkles need outlineModeShowLootEffectWhenDisabled on. Graphics
-- presets reset it, so it is applied at login and again after every relevant
-- cvar change. The outline mode is the player's: up to 1.3.0 it was forced
-- off, which took away the Self Highlight outline (CurseForge issue #1).

local ADDON_NAME = ...;

local WANTED = {
	outlineModeShowLootEffectWhenDisabled = "1",
};

-- Written once when the option is switched off
local DISABLED = {
	outlineModeShowLootEffectWhenDisabled = "0",
};

local WATCHED = {
	graphicsquality = true,
	raidgraphicsquality = true,
};
for cvar in pairs(WANTED) do
	WATCHED[strlower(cvar)] = true;
end

local db;
-- Whether sparkles have been on at any point since the game started. Once on,
-- they stay visible until the next restart, even after the option is switched off.
local sparklesShown;
local applying = false;
local pendingAfterCombat = false;

local function IsEnabled()
	return db == nil or db.enabled ~= false;
end

local function SetAll(values)
	applying = true;
	for cvar, value in pairs(values) do
		local current = C_CVar.GetCVar(cvar);
		if current ~= nil and current ~= value then
			pcall(C_CVar.SetCVar, cvar, value);
		end
	end
	applying = false;
end

local function Apply()
	if not IsEnabled() then
		return;
	end
	if InCombatLockdown() then
		pendingAfterCombat = true;
		return;
	end
	SetAll(WANTED);
end

-- Up to 1.3.x the addon also made herbs, ore, corpses and quest objects sparkle
-- through Blizzard's soft targeting (SoftTarget.lua). That side broke self-cast
-- (CurseForge issue #10), left empty nameplates on corpses (#12) and showed
-- interact icons (#7), so it was removed. Its cvars are put back here: the
-- original values were saved in db.savedCVars.
local SOFT_TARGET_OPTIONS = { "sparkleOre", "sparkleHerbs", "sparkleQuest", "sparkleCorpseLoot" };

-- Value the addon set. These are the player's own settings too, so they only go
-- back while they still hold that value; a player who changed one keeps theirs.
-- Every other saved cvar is put back as it was.
local SOFT_TARGET_SET = {
	SoftTargetInteract = "3",
	SoftTargetIconGameObject = "1",
	SoftTargetIconInteract = "1",
	SoftTargetLowPriorityIcons = "1",
};

local cleanupPending = false;

-- Runs at login and again with the delayed pass, in case account-synced
-- settings arrive late; the saved values are dropped after the second run.
local function RestoreSoftTarget(final)
	if not (db and db.savedCVars) then
		return;
	end
	if InCombatLockdown() then
		cleanupPending = true;
		return;
	end
	applying = true;
	for cvar, value in pairs(db.savedCVars) do
		local current = C_CVar.GetCVar(cvar);
		local ours = SOFT_TARGET_SET[cvar];
		if value ~= false and current ~= nil and current ~= tostring(value)
			and (ours == nil or current == ours) then
			pcall(C_CVar.SetCVar, cvar, tostring(value));
		end
	end
	applying = false;
	if final then
		db.savedCVars = nil;
	end
end

local applyAt;
local timerFrame = CreateFrame("Frame");
timerFrame:Hide();
timerFrame:SetScript("OnUpdate", function(self)
	if GetTime() >= applyAt then
		self:Hide();
		Apply();
		RestoreSoftTarget(true);
	end
end);

local function ScheduleApply(delay)
	applyAt = GetTime() + delay;
	timerFrame:Show();
end

local function OnEnabledChanged(_, value)
	if value then
		sparklesShown = true;
		Apply();
	else
		pendingAfterCombat = false;
		timerFrame:Hide();
		SetAll(DISABLED);
		-- Switching off only takes effect after a full game restart (/reload is
		-- not enough). Told in chat: a shown predicate on a settings initializer
		-- runs addon code inside Blizzard's options search and taints it.
		if sparklesShown then
			print("|cffff8000Forever Loot Sparkles:|r restart the game to remove the sparkles. /reload is not enough.");
		end
	end
end

local function RegisterOptions()
	local category = Settings.RegisterVerticalLayoutCategory("Forever Loot Sparkles");

	local setting = Settings.RegisterAddOnSetting(category, "FOREVER_LOOT_SPARKLES_ENABLED", "enabled",
		db, Settings.VarType.Boolean, "Show quest item sparkles", Settings.Default.True);
	setting:SetValueChangedCallback(OnEnabledChanged);
	Settings.CreateCheckbox(category, setting,
		"Keeps the game's loot sparkle on, even after a graphics preset turns it off. Your outline mode is left as you set it. Switching this off takes effect after restarting the game.");

	Settings.RegisterAddOnCategory(category);
end

local frame = CreateFrame("Frame");
frame:RegisterEvent("ADDON_LOADED");
frame:RegisterEvent("PLAYER_LOGIN");
frame:RegisterEvent("PLAYER_REGEN_ENABLED");
pcall(frame.RegisterEvent, frame, "CVAR_UPDATE");
frame:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 == ADDON_NAME then
			self:UnregisterEvent("ADDON_LOADED");
			ForeverLootSparklesDB = ForeverLootSparklesDB or {};
			db = ForeverLootSparklesDB;
			for _, key in ipairs(SOFT_TARGET_OPTIONS) do
				db[key] = nil;
			end
			RegisterOptions();
			sparklesShown = IsEnabled();
		end
	elseif event == "PLAYER_LOGIN" then
		Apply();
		RestoreSoftTarget(false);
		ScheduleApply(5);
	elseif event == "PLAYER_REGEN_ENABLED" then
		if pendingAfterCombat then
			pendingAfterCombat = false;
			Apply();
		end
		if cleanupPending then
			cleanupPending = false;
			RestoreSoftTarget(true);
		end
	elseif not applying and type(arg1) == "string" and WATCHED[strlower(arg1)] then
		ScheduleApply(1);
	end
end);
