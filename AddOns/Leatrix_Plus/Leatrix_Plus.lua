----------------------------------------------------------------------
-- 	Leatrix Plus 1.60.29 (6th November 2026)
----------------------------------------------------------------------

--	01:Functions 02:Locks,  03:Restart 40:Player
--	60:Events    62:Profile 70:Logout  80:Commands, 90:Panel

----------------------------------------------------------------------
-- 	Leatrix Plus
----------------------------------------------------------------------

	-- Create global table
	_G.LeaPlusDB = _G.LeaPlusDB or {}

	-- Create locals
	local LeaPlusLC, LeaPlusCB, LeaConfigList, LeaLockList = {}, {}, {}, {}
	local GameLocale = GetLocale()
	local void

	-- Version
	LeaPlusLC["AddonVer"] = "1.60.29"

	-- Get locale table
	local void, Leatrix_Plus = ...
	local L = Leatrix_Plus.L

	-- Check Wow version is valid
	do
		local gameversion, gamebuild, gamedate, gametocversion = GetBuildInfo()
		if gametocversion and gametocversion < 16000 then
			-- Game client is not Forever
			C_Timer.After(2, function()
				print(L["LEATRIX PLUS: WRONG VERSION INSTALLED!"])
			end)
			return
		end
		if gametocversion and gametocversion >= 16002 then -- 1.60.2
			LeaPlusLC.NewPatch = true
		end
	end

	-- Check for ElvUI
	if C_AddOns.IsAddOnLoaded("ElvUI") then LeaPlusLC.ElvUI = unpack(ElvUI) end

----------------------------------------------------------------------
--	L00: Leatrix Plus
----------------------------------------------------------------------

	-- Initialise variables
	LeaPlusLC["ShowErrorsFlag"] = 1
	LeaPlusLC["NumberOfPages"] = 9
	LeaPlusLC["MainPanelHeight"] = 370
	LeaPlusLC["RaidColors"] = RAID_CLASS_COLORS

	-- Create event frame
	local LpEvt = CreateFrame("FRAME")
	LpEvt:RegisterEvent("ADDON_LOADED")
	LpEvt:RegisterEvent("PLAYER_LOGIN")

	-- Set bindings translations
	_G.BINDING_NAME_LEATRIX_PLUS_GLOBAL_TOGGLE = L["Toggle panel"]
	_G.BINDING_NAME_LEATRIX_PLUS_GLOBAL_RARE = L["Announce rare"]
	_G.BINDING_NAME_LEATRIX_PLUS_GLOBAL_MOUNTSPECIAL = L["Mount special"]

	-- Disable sticky editbox
	-- Open 2 chat windows
	-- Press enter in general chat to open editbox, type anything but don't press enter
	-- Undock the second chat window and dock it again
	-- Press enter in general chat to open editbox, type anything but don't press enter
	-- Right-click General chat tab and enter Edit Mode

----------------------------------------------------------------------
--	L01: Functions
----------------------------------------------------------------------

	-- Create a random global name that changes every time the addon loads
	function LeaPlusLC:CreateRandomName()
		local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
		local name
		repeat
			local parts = {"F"} -- Start with a letter
			for i = 1, 16 do
				local n = math.random(#chars)
				parts[#parts + 1] = chars:sub(n, n)
			end
			name = table.concat(parts)
		until not _G[name] -- Make sure the name is not already in use
		return name
	end

	-- Print text
	function LeaPlusLC:Print(text)
		DEFAULT_CHAT_FRAME:AddMessage(L[text], 1.0, 0.85, 0.0)
	end

	-- Lock and unlock an item
	function LeaPlusLC:LockItem(item, lock)
		if lock then
			item:Disable()
			item:SetAlpha(0.3)
		else
			item:Enable()
			item:SetAlpha(1.0)
		end
	end

	-- Hide configuration panels
	function LeaPlusLC:HideConfigPanels()
		for k, v in pairs(LeaConfigList) do
			v:Hide()
		end
	end

	-- Create a close button without using a template
	function LeaPlusLC:CreateCloseButton(parent, w, h, anchor, x, y)
		local btn = CreateFrame("BUTTON", nil, parent)
		btn:SetSize(w, h)
		btn:SetPoint(anchor, x, y)
		btn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
		btn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
		btn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
		btn:SetDisabledTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Disabled")
		return btn
	end

	-- Decline a shared quest if needed
	function LeaPlusLC:CheckIfQuestIsSharedAndShouldBeDeclined()
		if LeaPlusLC["NoSharedQuests"] == "On" then
			local npcName = UnitName("questnpc")
			if not canaccessvalue(npcName) then return end
			if npcName and UnitIsPlayer(npcName) then
				if UnitInParty(npcName) or UnitInRaid(npcName) then
					if not LeaPlusLC:FriendCheck(npcName) then
						DeclineQuest()
						return
					end
				end
			end
		end
	end

	-- Display on-screen message
	function LeaPlusLC:DisplayMessage(self)
		ActionStatus:DisplayMessage(self)
	end

	-- Show a single line prefilled editbox with copy functionality
	function LeaPlusLC:ShowSystemEditBox(word, focuschat)
		if not LeaPlusLC.FactoryEditBox then
			-- Create frame for first time
			local eFrame = CreateFrame("FRAME", nil, UIParent)
			LeaPlusLC.FactoryEditBox = eFrame
			eFrame:SetSize(700, 110)
			eFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
			eFrame:SetFrameStrata("FULLSCREEN_DIALOG")
			eFrame:SetFrameLevel(5000)
			eFrame:SetScript("OnMouseDown", function(self, btn)
				if btn == "RightButton" then
					eFrame:Hide()
				end
			end)
			-- Add background color
			eFrame.t = eFrame:CreateTexture(nil, "BACKGROUND")
			eFrame.t:SetAllPoints()
			eFrame.t:SetColorTexture(0.05, 0.05, 0.05, 0.9)
			-- Add copy title
			eFrame.f = eFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
			eFrame.f:SetPoint("TOPLEFT", x, y)
			eFrame.f:SetPoint("TOPLEFT", eFrame, "TOPLEFT", 12, -52)
			eFrame.f:SetWidth(676)
			eFrame.f:SetJustifyH("LEFT")
			eFrame.f:SetWordWrap(false)
			-- Add copy label
			eFrame.c = eFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
			eFrame.c:SetPoint("TOPLEFT", x, y)
			eFrame.c:SetText(L["Press CTRL/C to copy"])
			eFrame.c:SetPoint("TOPLEFT", eFrame, "TOPLEFT", 12, -82)
			-- Add cancel label
			eFrame.x = eFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
			eFrame.x:SetPoint("TOPRIGHT", x, y)
			eFrame.x:SetText(L["Right-click to close"])
			eFrame.x:SetPoint("TOPRIGHT", eFrame, "TOPRIGHT", -12, -82)
			-- Create editbox
			eFrame.b = CreateFrame("EditBox", nil, eFrame, "InputBoxTemplate")
			eFrame.b:ClearAllPoints()
			eFrame.b:SetPoint("TOPLEFT", eFrame, "TOPLEFT", 16, -12)
			eFrame.b:SetSize(672, 24)
			eFrame.b:SetFontObject("GameFontNormalLarge")
			eFrame.b:SetTextColor(1.0, 1.0, 1.0, 1)
			eFrame.b:SetBlinkSpeed(0)
			eFrame.b:SetHitRectInsets(99, 99, 99, 99)
			eFrame.b:SetAutoFocus(true)
			eFrame.b:SetAltArrowKeyMode(true)
			-- Editbox texture
			eFrame.t = CreateFrame("FRAME", nil, eFrame.b, "BackdropTemplate")
			eFrame.t:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 }})
			eFrame.t:SetPoint("LEFT", -6, 0)
			eFrame.t:SetWidth(eFrame.b:GetWidth() + 6)
			eFrame.t:SetHeight(eFrame.b:GetHeight())
			eFrame.t:SetBackdropColor(1.0, 1.0, 1.0, 0.3)
			-- Handler
			eFrame.b:SetScript("OnKeyDown", function(void, key)
				if key == "C" and (IsControlKeyDown() or IsMetaKeyDown()) then
					C_Timer.After(0.1, function()
						eFrame:Hide()
						LeaPlusLC:DisplayMessage(L["Copied to clipboard."], true)
						if LeaPlusLC.FactoryEditBoxFocusChat then
							local eBox = ChatFrameUtil.ChooseBoxForSend()
							ChatFrameUtil.ActivateChat(eBox)
						end
					end)
				end
			end)
			-- Prevent changes
			eFrame.b:SetScript("OnEscapePressed", function() eFrame:Hide() end)
			eFrame.b:SetScript("OnEnterPressed", eFrame.b.HighlightText)
			eFrame.b:SetScript("OnMouseDown", eFrame.b.ClearFocus)
			eFrame.b:SetScript("OnMouseUp", eFrame.b.HighlightText)
			eFrame.b:SetFocus(true)
			eFrame.b:HighlightText()
			eFrame:Show()
		end
		if focuschat then LeaPlusLC.FactoryEditBoxFocusChat = true else LeaPlusLC.FactoryEditBoxFocusChat = nil end
		LeaPlusLC.FactoryEditBox:Show()
		LeaPlusLC.FactoryEditBox.b:SetText(word)
		LeaPlusLC.FactoryEditBox.b:HighlightText()
		LeaPlusLC.FactoryEditBox.b:SetScript("OnChar", function() LeaPlusLC.FactoryEditBox.b:SetFocus(true) LeaPlusLC.FactoryEditBox.b:SetText(word) LeaPlusLC.FactoryEditBox.b:HighlightText() end)
		LeaPlusLC.FactoryEditBox.b:SetScript("OnKeyUp", function() LeaPlusLC.FactoryEditBox.b:SetFocus(true) LeaPlusLC.FactoryEditBox.b:SetText(word) LeaPlusLC.FactoryEditBox.b:HighlightText() end)
	end

	-- Load a string variable or set it to default if it's not set to "On" or "Off"
	function LeaPlusLC:LoadVarChk(var, def)
		if LeaPlusDB[var] and type(LeaPlusDB[var]) == "string" and LeaPlusDB[var] == "On" or LeaPlusDB[var] == "Off" then
			LeaPlusLC[var] = LeaPlusDB[var]
		else
			LeaPlusLC[var] = def
			LeaPlusDB[var] = def
		end
	end

	-- Load a numeric variable and set it to default if it's not within a given range
	function LeaPlusLC:LoadVarNum(var, def, valmin, valmax)
		if LeaPlusDB[var] and type(LeaPlusDB[var]) == "number" and LeaPlusDB[var] >= valmin and LeaPlusDB[var] <= valmax then
			LeaPlusLC[var] = LeaPlusDB[var]
		else
			LeaPlusLC[var] = def
			LeaPlusDB[var] = def
		end
	end

	-- Load an anchor point variable and set it to default if the anchor point is invalid
	function LeaPlusLC:LoadVarAnc(var, def)
		if LeaPlusDB[var] and type(LeaPlusDB[var]) == "string" and LeaPlusDB[var] == "CENTER" or LeaPlusDB[var] == "TOP" or LeaPlusDB[var] == "BOTTOM" or LeaPlusDB[var] == "LEFT" or LeaPlusDB[var] == "RIGHT" or LeaPlusDB[var] == "TOPLEFT" or LeaPlusDB[var] == "TOPRIGHT" or LeaPlusDB[var] == "BOTTOMLEFT" or LeaPlusDB[var] == "BOTTOMRIGHT" then
			LeaPlusLC[var] = LeaPlusDB[var]
		else
			LeaPlusLC[var] = def
			LeaPlusDB[var] = def
		end
	end

	-- Load a string variable and set it to default if it is not a string (used with minimap exclude list)
	function LeaPlusLC:LoadVarStr(var, def)
		if LeaPlusDB[var] and type(LeaPlusDB[var]) == "string" then
			LeaPlusLC[var] = LeaPlusDB[var]
		else
			LeaPlusLC[var] = def
			LeaPlusDB[var] = def
		end
	end

	-- Show tooltips for checkboxes
	function LeaPlusLC:TipSee()
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		local parent = self:GetParent()
		if parent:GetParent() and parent:GetParent():GetObjectType() == "ScrollFrame" then
			-- Scrolling frame tooltips have different parent
			parent = self:GetParent():GetParent():GetParent():GetParent()
		end
		local pscale = parent:GetEffectiveScale()
		local gscale = UIParent:GetEffectiveScale()
		local tscale = GameTooltip:GetEffectiveScale()
		local gap = ((UIParent:GetRight() * gscale) - (parent:GetRight() * pscale))
		if gap < (250 * tscale) then
			GameTooltip:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)
		else
			GameTooltip:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
		end
		GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
	end

	-- Show tooltips for dropdown menu tooltips
	function LeaPlusLC:ShowDropTip()
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		local parent = self:GetParent():GetParent():GetParent()
		local pscale = parent:GetEffectiveScale()
		local gscale = UIParent:GetEffectiveScale()
		local tscale = GameTooltip:GetEffectiveScale()
		local gap = ((UIParent:GetRight() * gscale) - (parent:GetRight() * pscale))
		if gap < (250 * tscale) then
			GameTooltip:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)
		else
			GameTooltip:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
		end
		GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
	end

	-- Show tooltips for configuration buttons and dropdown menus
	function LeaPlusLC:ShowTooltip()
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		local parent = LeaPlusLC["PageF"]
		local pscale = parent:GetEffectiveScale()
		local gscale = UIParent:GetEffectiveScale()
		local tscale = GameTooltip:GetEffectiveScale()
		local gap = ((UIParent:GetRight() * gscale) - (LeaPlusLC["PageF"]:GetRight() * pscale))
		if gap < (250 * tscale) then
			GameTooltip:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)
		else
			GameTooltip:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
		end
		GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
	end

	-- Show tooltips for interface settings (not currently used)
	function LeaPlusLC:ShowFacetip()
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
	end

	-- Create configuration button
	function LeaPlusLC:CfgBtn(name, parent)
		local CfgBtn = CreateFrame("BUTTON", nil, parent)
		LeaPlusCB[name] = CfgBtn
		CfgBtn:SetWidth(20)
		CfgBtn:SetHeight(20)
		CfgBtn:SetPoint("LEFT", parent.f, "RIGHT", 0, 0)

		CfgBtn.t = CfgBtn:CreateTexture(nil, "BORDER")
		CfgBtn.t:SetAllPoints()
		CfgBtn.t:SetTexture("Interface\\WorldMap\\Gear_64.png")
		CfgBtn.t:SetTexCoord(0, 0.50, 0, 0.50);
		CfgBtn.t:SetVertexColor(1.0, 0.82, 0, 1.0)

		CfgBtn:SetHighlightTexture("Interface\\WorldMap\\Gear_64.png")
		CfgBtn:GetHighlightTexture():SetTexCoord(0, 0.50, 0, 0.50);

		CfgBtn.tiptext = L["Click to configure the settings for this option."]
		CfgBtn:SetScript("OnEnter", LeaPlusLC.ShowTooltip)
		CfgBtn:SetScript("OnLeave", GameTooltip_Hide)
	end

	-- Create a help button to the right of a fontstring
	function LeaPlusLC:CreateHelpButton(frame, panel, parent, tip)
		LeaPlusLC:CfgBtn(frame, panel)
		LeaPlusCB[frame]:ClearAllPoints()
		LeaPlusCB[frame]:SetPoint("LEFT", parent, "RIGHT", -parent:GetWidth() + parent:GetStringWidth(), 0)
		LeaPlusCB[frame]:SetSize(25, 25)
		LeaPlusCB[frame].t:SetTexture("Interface\\COMMON\\help-i.blp")
		LeaPlusCB[frame].t:SetTexCoord(0, 1, 0, 1)
		LeaPlusCB[frame].t:SetVertexColor(0.9, 0.8, 0.0)
		LeaPlusCB[frame]:SetHighlightTexture("Interface\\COMMON\\help-i.blp")
		LeaPlusCB[frame]:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)
		LeaPlusCB[frame].tiptext = L[tip]
		LeaPlusCB[frame]:SetScript("OnEnter", LeaPlusLC.TipSee)
	end

	-- Show a footer
	function LeaPlusLC:MakeFT(frame, text, left, width, bottom)
		local footer = LeaPlusLC:MakeTx(frame, text, left, bottom)
		footer:SetWidth(width); footer:SetJustifyH("LEFT"); footer:SetWordWrap(true); footer:ClearAllPoints()
		footer:SetPoint("BOTTOMLEFT", left, bottom)
		return footer
	end

	-- Capitalise first character in a string
	function LeaPlusLC:CapFirst(str)
		return gsub(string.lower(str), "^%l", strupper)
	end

	-- Toggle Zygor addon
	function LeaPlusLC:ZygorToggle()
		if select(2, C_AddOns.GetAddOnInfo("ZygorGuidesViewer")) then
			if not C_AddOns.IsAddOnLoaded("ZygorGuidesViewer") then
				if LeaPlusLC:PlayerInCombat() then
					return
				else
					C_AddOns.EnableAddOn("ZygorGuidesViewer")
					ReloadUI();
				end
			else
				C_AddOns.DisableAddOn("ZygorGuidesViewer")
				ReloadUI();
			end
		else
			-- Zygor cannot be found
			LeaPlusLC:Print("Zygor addon not found.");
		end
		return
	end

	-- Show memory usage stat
	function LeaPlusLC:ShowMemoryUsage(frame, anchor, x, y)

		-- Create frame
		local memframe = CreateFrame("FRAME", nil, frame)
		memframe:ClearAllPoints()
		memframe:SetPoint(anchor, x, y)
		memframe:SetWidth(100)
		memframe:SetHeight(20)

		-- Create labels
		local pretext = memframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		pretext:SetPoint("TOPLEFT", 0, 0)
		pretext:SetText(L["Memory Usage"])

		local memtext = memframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		memtext:SetPoint("TOPLEFT", 0, 0 - 30)

		-- Create stat
		local memstat = memframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		memstat:SetPoint("BOTTOMLEFT", memtext, "BOTTOMRIGHT")
		memstat:SetText("(calculating...)")

		-- Create update script
		local memtime = -1
		memframe:SetScript("OnUpdate", function(self, elapsed)
			if memtime > 2 or memtime == -1 then
				UpdateAddOnMemoryUsage();
				memtext = GetAddOnMemoryUsage("Leatrix_Plus")
				memtext = math.floor(memtext + .5) .. " KB"
				memstat:SetText(memtext);
				memtime = 0;
			end
			memtime = memtime + elapsed;
		end)

		-- Release memory
		LeaPlusLC.ShowMemoryUsage = nil

	end

	-- Check if player is in LFG queue
	function LeaPlusLC:IsInLFGQueue()
		if 	GetLFGMode(LE_LFG_CATEGORY_LFD) or
			GetLFGMode(LE_LFG_CATEGORY_LFR) or
			GetLFGMode(LE_LFG_CATEGORY_RF) or
			GetLFGMode(LE_LFG_CATEGORY_SCENARIO) or
			GetLFGMode(LE_LFG_CATEGORY_FLEXRAID) then
			return true
		end
	end

	-- Check if player is in combat
	function LeaPlusLC:PlayerInCombat()
		if (UnitAffectingCombat("player")) then
			LeaPlusLC:Print("You cannot do that in combat.")
			return true
		end
	end

	--  Hide panel and pages
	function LeaPlusLC:HideFrames()

		-- Hide option pages
		for i = 0, LeaPlusLC["NumberOfPages"] do
			if LeaPlusLC["Page"..i] then
				LeaPlusLC["Page"..i]:Hide();
			end;
		end

		-- Hide options panel
		LeaPlusLC["PageF"]:Hide();

	end

	-- Find out if Leatrix Plus is showing (main panel or config panel)
	function LeaPlusLC:IsPlusShowing()
		if LeaPlusLC["PageF"]:IsShown() then return true end
		for k, v in pairs(LeaConfigList) do
			if v:IsShown() then
				return true
			end
		end
	end

	-- Check if a name is in your friends list, guild or community (does not check realm as realm is unknown for some checks)
	function LeaPlusLC:FriendCheck(name, guid)

		-- Do nothing if name is empty (such as whispering from the Battle.net app)
		if not name then return end

		-- Update friends list
		C_FriendList.ShowFriends()

		-- Remove realm (since we have GUID checking)
		name = strsplit("-", name, 2)

		-- Check character friends
		for i = 1, C_FriendList.GetNumFriends() do
			-- Return true is character name matches and GUID matches if there is one (realm is not checked)
			local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
			local charFriendName = C_FriendList.GetFriendInfoByIndex(i).name
			charFriendName = strsplit("-", charFriendName, 2)
			if (name == charFriendName) and (guid and (guid == friendInfo.guid) or true) then
				return true
			end
		end

		-- Check Battle.net friends
		local numfriends = BNGetNumFriends()
		for i = 1, numfriends do
			local numtoons = C_BattleNet.GetFriendNumGameAccounts(i)
			for j = 1, numtoons do
				local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(i, j)
				local characterName = gameAccountInfo.characterName
				local client = gameAccountInfo.clientProgram
				if client == "WoW" and characterName == name then
					return true
				end
			end
		end

		-- Check guild members if guild is enabled (new members may need to press J to refresh roster)
		if LeaPlusLC["FriendlyGuild"] == "On" then
			local gCount = GetNumGuildMembers()
			for i = 1, gCount do
				local gName, void, void, void, void, void, void, void, gOnline, void, void, void, void, gMobile, void, void, gGUID = GetGuildRosterInfo(i)
				if gOnline and not gMobile then
					gName = strsplit("-", gName, 2)
					-- Return true if character name matches including GUID if there is one
					if (name == gName) and (guid and (guid == gGUID) or true) then
						return true
					end
				end
			end
		end

		-- Check communities if communities is enabled
		if LeaPlusLC["FriendlyCommunities"] == "On" then
			local communities = C_Club.GetSubscribedClubs()
			for void, community in pairs(communities) do
				if community.clubType == Enum.ClubType.Character then
					local cMemberIds = CommunitiesUtil.GetMemberIdsSortedByName(community.clubId)
					local cMembersInfo = CommunitiesUtil.GetMemberInfo(community.clubId, cMemberIds)
					for void, member in pairs(cMembersInfo) do
						if member and member.name and member.presence and member.presence ~= Enum.ClubMemberPresence.Offline and member.presence ~= Enum.ClubMemberPresence.OnlineMobile then
							local cName = strsplit("-", member.name, 2)
							-- Return true if character name matches including GUID if there is one
							if (name == cName) and (guid and member.guid and (guid == member.guid) or true) then
								return true
							end
						end
					end
				end
			end
		end

	end

----------------------------------------------------------------------
--	L02: Locks
----------------------------------------------------------------------

	-- Function to set lock state for configuration buttons
	function LeaPlusLC:LockOption(option, item, reloadreq)
		if reloadreq then
			-- Option change requires UI reload
			if LeaPlusLC[option] ~= LeaPlusDB[option] or LeaPlusLC[option] == "Off" then
				LeaPlusLC:LockItem(LeaPlusCB[item], true)
			else
				LeaPlusLC:LockItem(LeaPlusCB[item], false)
			end
		else
			-- Option change does not require UI reload
			if LeaPlusLC[option] == "Off" then
				LeaPlusLC:LockItem(LeaPlusCB[item], true)
			else
				LeaPlusLC:LockItem(LeaPlusCB[item], false)
			end
		end
	end

--	Set lock state for configuration buttons
	function LeaPlusLC:SetDim()
		LeaPlusLC:LockOption("AutomateQuests", "AutomateQuestsBtn", false)			-- Automate quests
		LeaPlusLC:LockOption("AutoAcceptRes", "AutoAcceptResBtn", false)			-- Accept resurrection
		LeaPlusLC:LockOption("AutoReleasePvP", "AutoReleasePvPBtn", false)			-- Release in PvP
		LeaPlusLC:LockOption("AutoSellJunk", "AutoSellJunkBtn", true)				-- Sell junk automatically
		LeaPlusLC:LockOption("AutoRepairGear", "AutoRepairBtn", false)				-- Repair automatically
		LeaPlusLC:LockOption("InviteFromWhisper", "InvWhisperBtn", false)			-- Invite from whispers
		LeaPlusLC:LockOption("NoChatButtons", "NoChatButtonsBtn", true)				-- Hide chat buttons
		LeaPlusLC:LockOption("FilterChatMessages", "FilterChatMessagesBtn", true)	-- Filter chat messages
		LeaPlusLC:LockOption("QuestFontChange", "QuestTextBtn", true)				-- Resize quest text
		LeaPlusLC:LockOption("MinimapModder", "ModMinimapBtn", true)				-- Enhance minimap
		LeaPlusLC:LockOption("TipModEnable", "MoveTooltipButton", true)				-- Enhance tooltip
		LeaPlusLC:LockOption("EnhanceDressup", "EnhanceDressupBtn", true)			-- Enhance dressup
		LeaPlusLC:LockOption("EnhanceFlightMap", "EnhanceFlightMapBtn", true)		-- Enhance flight map
		LeaPlusLC:LockOption("ShowBorders", "ModBordersBtn", true)					-- Show borders
		LeaPlusLC:LockOption("ShowPlayerChain", "ModPlayerChain", true)				-- Show player chain
		LeaPlusLC:LockOption("ShowInfoCards", "ShowInfoCardsBtn", true)				-- Show info cards
		LeaPlusLC:LockOption("ShowWowheadLinks", "ShowWowheadLinksBtn", true)		-- Show Wowhead links
		LeaPlusLC:LockOption("ShowFlightTimes", "ShowFlightTimesBtn", true)			-- Show flight times
		LeaPlusLC:LockOption("ManageWidgetTop", "ManageWidgetTopButton", true)		-- Manage widget top
		LeaPlusLC:LockOption("ClassColFrames", "ClassColFramesBtn", true)			-- Class colored frames
		LeaPlusLC:LockOption("SetWeatherDensity", "SetWeatherDensityBtn", false)	-- Set weather density
		LeaPlusLC:LockOption("MuteGameSounds", "MuteGameSoundsBtn", false)			-- Mute game sounds
		LeaPlusLC:LockOption("MuteMountSounds", "MuteMountSoundsBtn", false)		-- Mute mount sounds
		LeaPlusLC:LockOption("MuteCustomSounds", "MuteCustomSoundsBtn", false)		-- Mute custom sounds
		LeaPlusLC:LockOption("FasterLooting", "FasterLootingBtn", true)				-- Faster auto loot
		LeaPlusLC:LockOption("NoTransforms", "NoTransformsBtn", false)				-- Remove transforms
		LeaPlusLC:LockOption("SetEditModeLayout", "SetEditModeLayoutBtn", false)	-- Set edit mode layout
	end

----------------------------------------------------------------------
--	L03: Restarts
----------------------------------------------------------------------

	-- Set the reload button state
	function LeaPlusLC:ReloadCheck()

		-- Automation
		if	(LeaPlusLC["AutoSellJunk"]			~= LeaPlusDB["AutoSellJunk"])			-- Sell junk automatically

		-- Chat
		or	(LeaPlusLC["UseEasyChatResizing"]	~= LeaPlusDB["UseEasyChatResizing"])	-- Use easy resizing
		or	(LeaPlusLC["NoCombatLogTab"]		~= LeaPlusDB["NoCombatLogTab"])			-- Hide the combat log
		or	(LeaPlusLC["NoChatButtons"]			~= LeaPlusDB["NoChatButtons"])			-- Hide chat buttons
		or	(LeaPlusLC["NoSocialButton"]		~= LeaPlusDB["NoSocialButton"])			-- Hide social button
		or	(LeaPlusLC["UnclampChat"]			~= LeaPlusDB["UnclampChat"])			-- Unclamp chat frame
		or	(LeaPlusLC["MoveChatEditBoxToTop"]	~= LeaPlusDB["MoveChatEditBoxToTop"])	-- Move editbox to top
		or	(LeaPlusLC["MoreChatFontSizes"]		~= LeaPlusDB["MoreChatFontSizes"])		-- More chat font sizes
		or	(LeaPlusLC["NoStickyChat"]			~= LeaPlusDB["NoStickyChat"])			-- Disable sticky chat
		or	(LeaPlusLC["UseArrowKeysInChat"]	~= LeaPlusDB["UseArrowKeysInChat"])		-- Use arrow keys in chat
		or	(LeaPlusLC["NoChatFade"]			~= LeaPlusDB["NoChatFade"])				-- Disable chat fade
		or	(LeaPlusLC["RecentChatWindow"]		~= LeaPlusDB["RecentChatWindow"])		-- Recent chat window
		or	(LeaPlusLC["FilterChatMessages"]	~= LeaPlusDB["FilterChatMessages"])		-- Filter chat messages
		or	(LeaPlusLC["RestoreChatMessages"]	~= LeaPlusDB["RestoreChatMessages"])	-- Restore chat messages

		-- Text
		or	(LeaPlusLC["HideErrorMessages"]		~= LeaPlusDB["HideErrorMessages"])		-- Hide error messages
		or	(LeaPlusLC["NoHitIndicators"]		~= LeaPlusDB["NoHitIndicators"])		-- Hide portrait numbers
		or	(LeaPlusLC["HideZoneText"]			~= LeaPlusDB["HideZoneText"])			-- Hide zone text
		or	(LeaPlusLC["HideKeybindText"]		~= LeaPlusDB["HideKeybindText"])		-- Hide keybind text
		or	(LeaPlusLC["HideMacroText"]			~= LeaPlusDB["HideMacroText"])			-- Hide macro text

		or	(LeaPlusLC["QuestFontChange"]		~= LeaPlusDB["QuestFontChange"])		-- Resize quest text

		-- Interface
		or	(LeaPlusLC["MinimapModder"]			~= LeaPlusDB["MinimapModder"])			-- Enhance minimap
		or	(LeaPlusLC["SquareMinimap"]			~= LeaPlusDB["SquareMinimap"])			-- Square minimap
		or	(LeaPlusLC["HideMiniAddonMenu"]		~= LeaPlusDB["HideMiniAddonMenu"])		-- Hide addon menu
		or	(LeaPlusLC["UnclampMinimap"]		~= LeaPlusDB["UnclampMinimap"])			-- Unclamp minimap cluster
		or	(LeaPlusLC["MinimapButtonBag"]		~= LeaPlusDB["MinimapButtonBag"])		-- Minimap button bag
		or	(LeaPlusLC["MiniExcludeList"]		~= LeaPlusDB["MiniExcludeList"])		-- Minimap exclude list
		or	(LeaPlusLC["TipModEnable"]			~= LeaPlusDB["TipModEnable"])			-- Enhance tooltip
		or	(LeaPlusLC["TipNoHealthBar"]		~= LeaPlusDB["TipNoHealthBar"])			-- Tooltip hide health bar
		or	(LeaPlusLC["EnhanceDressup"]		~= LeaPlusDB["EnhanceDressup"])			-- Enhance dressup
		or	(LeaPlusLC["DressupMoreZoomOut"]	~= LeaPlusDB["DressupMoreZoomOut"])		-- Enhance dressup increase zoom out distance
		or	(LeaPlusLC["EnhanceFlightMap"]		~= LeaPlusDB["EnhanceFlightMap"])		-- Enhance flight map
		or	(LeaPlusLC["ShowVolume"]			~= LeaPlusDB["ShowVolume"])				-- Show volume slider
		or	(LeaPlusLC["DurabilityStatus"]		~= LeaPlusDB["DurabilityStatus"])		-- Show durability status
		or	(LeaPlusLC["ShowRaidToggle"]		~= LeaPlusDB["ShowRaidToggle"])			-- Show raid button
		or	(LeaPlusLC["ShowTrainAllButton"]	~= LeaPlusDB["ShowTrainAllButton"])		-- Show train all button
		or	(LeaPlusLC["ShowBorders"]			~= LeaPlusDB["ShowBorders"])			-- Show borders
		or	(LeaPlusLC["ShowPlayerChain"]		~= LeaPlusDB["ShowPlayerChain"])		-- Show player chain
		or	(LeaPlusLC["ShowDruidPowerBar"]		~= LeaPlusDB["ShowDruidPowerBar"])		-- Show druid power bar
		or	(LeaPlusLC["ShowReadyTimer"]		~= LeaPlusDB["ShowReadyTimer"])			-- Show ready timer
		or	(LeaPlusLC["ShowRangeColoring"]		~= LeaPlusDB["ShowRangeColoring"])		-- Show range coloring
		or	(LeaPlusLC["ShowInfoCards"]			~= LeaPlusDB["ShowInfoCards"])			-- Show info cards
		or	(LeaPlusLC["ShowWowheadLinks"]		~= LeaPlusDB["ShowWowheadLinks"])		-- Show Wowhead links
		or	(LeaPlusLC["ShowFlightTimes"]		~= LeaPlusDB["ShowFlightTimes"])		-- Show flight times

		-- Frames
		or	(LeaPlusLC["ManageWidgetTop"]		~= LeaPlusDB["ManageWidgetTop"])		-- Manage widget top
		or	(LeaPlusLC["ClassColFrames"]		~= LeaPlusDB["ClassColFrames"])			-- Class colored frames

		or	(LeaPlusLC["NoAlerts"]				~= LeaPlusDB["NoAlerts"])				-- Hide alerts
		or	(LeaPlusLC["HideCleanupBtns"]		~= LeaPlusDB["HideCleanupBtns"])		-- Hide clean-up buttons
		or	(LeaPlusLC["HideBossBanner"]		~= LeaPlusDB["HideBossBanner"])			-- Hide boss banner
		or	(LeaPlusLC["HideEventToasts"]		~= LeaPlusDB["HideEventToasts"])		-- Hide event toasts
		or	(LeaPlusLC["NoClassBar"]			~= LeaPlusDB["NoClassBar"])				-- Hide stance bar
		or	(LeaPlusLC["NoRestedSleep"]			~= LeaPlusDB["NoRestedSleep"])			-- Hide rested sleep

		-- System
		or	(LeaPlusLC["NoRestedEmotes"]		~= LeaPlusDB["NoRestedEmotes"])			-- Silence rested emotes
		or	(LeaPlusLC["KeepAudioSynced"]		~= LeaPlusDB["KeepAudioSynced"])		-- Keep audio synced
		or	(LeaPlusLC["FasterLooting"]			~= LeaPlusDB["FasterLooting"])			-- Faster auto loot
		or	(LeaPlusLC["FasterMovieSkip"]		~= LeaPlusDB["FasterMovieSkip"])		-- Faster movie skip
		or	(LeaPlusLC["CombatPlates"]			~= LeaPlusDB["CombatPlates"])			-- Combat plates
		or	(LeaPlusLC["EasyItemDestroy"]		~= LeaPlusDB["EasyItemDestroy"])		-- Easy item destroy

		-- Settings
		or	(LeaPlusLC["AddonLanguage"]			~= LeaPlusDB["AddonLanguage"])			-- Addon language
		or	(LeaPlusLC["SimpleAddonListing"]	~= LeaPlusDB["SimpleAddonListing"])		-- Simple addon listing

		then
			-- Enable the reload button
			LeaPlusLC:LockItem(LeaPlusCB["ReloadUIButton"], false)
			LeaPlusCB["ReloadUIButton"].f:Show()
		else
			-- Disable the reload button
			LeaPlusLC:LockItem(LeaPlusCB["ReloadUIButton"], true)
			LeaPlusCB["ReloadUIButton"].f:Hide()
		end

	end

----------------------------------------------------------------------
--	L40: Player
----------------------------------------------------------------------

	function LeaPlusLC:Player()

		----------------------------------------------------------------------
		-- Show info cards
		----------------------------------------------------------------------

		if LeaPlusLC["ShowInfoCards"] == "On" then

			-- Watch for Ctrl being pressed and only then give the card's link box the keyboard so CTRL/C copies the link
			-- (made now, while loading, as setting it up is not allowed in combat after loading)
			do
				local watcher = CreateFrame("Frame", nil, UIParent)
				watcher:SetPropagateKeyboardInput(true)
				watcher:EnableKeyboard(true)
				-- Every key always goes on to the game (the watcher never keeps a key, Escape closes the card through the game's own list of windows)
				watcher:SetScript("OnKeyDown", function(self, key)
					local card = LeaPlusLC.IDCard
					if not card or not card:IsShown() then return end
					if (key == "LCTRL" or key == "RCTRL" or key == "LMETA" or key == "RMETA") and card.url and not card.edit:HasFocus() then
						card.ctrlFocus = true
						card.edit:SetFocus()
						card.edit:HighlightText()
					end
				end)
			end

			-- Show the info card for whatever is under the mouse (arg1 is retry or upgrade when it runs itself again)
			local function ShowInfoCard(arg1, forceUnit)
				-- Secret values: the game can hide some values from addons (such as in combat, encounters and arenas)
				-- Anything that can be hidden is passed through Safe, which gives nil for a hidden value so it is left out
				local function IsSecret(v) return issecretvalue and issecretvalue(v) or false end
				local function Safe(...)
					local count = select("#", ...)
					if count == 1 then
						local v = ...
						if IsSecret(v) then return nil end
						return v
					end
					local values = {...}
					for i = 1, count do if IsSecret(values[i]) then values[i] = nil end end
					return unpack(values, 1, count)
				end
				-- Tables the game does not let addons read are left out too
				local function SafeTable(t)
					if type(t) == "table" and not IsSecret(t) and (not canaccesstable or canaccesstable(t)) then return t end
				end
				-- Auras: when auras are hidden, the game does not let addons read them at all (asking is an error), so check first
				local function AurasHidden()
					return C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret() or false
				end
				-- Get a buff or debuff by its index: gives the aura (nil if it is hidden), and true when there are no more to look at
				local function GetAura(unit, index, harmful)
					if AurasHidden() then return nil, true end
					if C_Secrets and C_Secrets.ShouldUnitAuraIndexBeSecret and C_Secrets.ShouldUnitAuraIndexBeSecret(unit, index, harmful and "HARMFUL" or "HELPFUL") then return nil, false end
					local aura
					if harmful then aura = C_UnitAuras.GetDebuffDataByIndex(unit, index) else aura = C_UnitAuras.GetBuffDataByIndex(unit, index) end
					if not aura then return nil, true end
					return SafeTable(aura), false
				end
				-- Size of one screen pixel (borders this thin stay sharp and do not vanish when frames are moved)
				local function OnePixel()
					local physicalHeight = select(2, GetPhysicalScreenSize())
					if not physicalHeight or physicalHeight == 0 then return 1 end
					return (768 / physicalHeight) / UIParent:GetEffectiveScale()
				end
				-- Round a size or offset to whole screen pixels
				local function PixelRound(v)
					local px = OnePixel()
					return math.floor(v / px + 0.5) * px
				end
				-- Line a frame up with the screen pixels (position and size) so thin borders are always drawn
				local function SnapToPixels(frame)
					local px = OnePixel()
					local left, bottom, width, height = frame:GetLeft(), frame:GetBottom(), frame:GetWidth(), frame:GetHeight()
					if not (left and bottom) then return end
					local function Round(v) return math.floor(v / px + 0.5) * px end
					frame:ClearAllPoints()
					frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", Round(left), Round(bottom))
					frame:SetSize(Round(width), Round(height))
				end
				-- Attach the model viewer to the right side of the card, and keep the card and viewer on the screen together
				local function AttachViewer()
					local card, viewer = LeaPlusLC.IDCard, LeaPlusLC.IDViewer
					if not card or not viewer then return end
					local gap = PixelRound(8)
					viewer:ClearAllPoints()
					if viewer.offscreen then
						-- Switched off with the checkbox: kept loaded but off the screen, so ticking the box shows it straight away
						viewer:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", -4000, -4000)
						return
					end
					if viewer.fullscreen then
						-- Fullscreen: fill the whole screen (over the card)
						viewer:SetAllPoints(UIParent)
						return
					end
					viewer:SetPoint("BOTTOMLEFT", card, "BOTTOMRIGHT", gap, 0)
					if not viewer:IsShown() then return end
					-- Move the card if the viewer would go off the right or top of the screen
					local cardLeft, cardBottom = card:GetLeft(), card:GetBottom()
					if not cardLeft then return end
					local overRight = (cardLeft + card:GetWidth() + gap + viewer:GetWidth()) - UIParent:GetRight()
					local overTop = (cardBottom + viewer:GetHeight()) - UIParent:GetTop()
					if overRight > 0 or overTop > 0 then
						card:ClearAllPoints()
						card:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", math.max(0, cardLeft - math.max(0, overRight)), math.max(0, cardBottom - math.max(0, overTop)))
						SnapToPixels(card)
					end
				end
				-- Flat button in the ID card style (dark with an accent coloured border and text)
				local function FlatButton(parent, width, height, text)
					local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
					button:SetSize(width, height)
					button:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = OnePixel()})
					button:SetBackdropColor(1, 1, 1, 0.05)
					button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
					button.label:SetPoint("CENTER", button, "CENTER", 0, 0)
					button.label:SetText(text)
					button:SetScript("OnEnter", function(self) self:SetBackdropColor(1, 1, 1, 0.14) end)
					button:SetScript("OnLeave", function(self) self:SetBackdropColor(1, 1, 1, 0.05) end)
					button:SetScript("OnMouseDown", function(self) self.label:SetPoint("CENTER", self, "CENTER", 1, -1) end)
					button:SetScript("OnMouseUp", function(self) self.label:SetPoint("CENTER", self, "CENTER", 0, 0) end)
					function button:SetAccent(r, g, b)
						self:SetBackdropBorderColor(r, g, b, 0.7)
						self.label:SetTextColor(r, g, b)
					end
					function button:SetLabel(newText) self.label:SetText(newText) end
					button:SetAccent(1, 0.82, 0)
					return button
				end
				-- Model viewer: a 3D model (players, NPCs and wearable items) with flavour text
				-- The model is only ever changed while the viewer is showing, and changes that need the model wait until it has loaded
				local viewerAnims = {0, 4, 5, 143, 119, 26, 25, 27, 28, 108, 120, 51, 124, 52, 125, 126, 62, 63, 41, 42, 43, 44, 132, 38, 14, 115, 193, 48, 110, 109, 134, 197, 0} -- Same as Enhance dressup
				local function ShowViewer(info)
					local card = LeaPlusLC.IDCard
					local view = info and info.view
					local viewer = LeaPlusLC.IDViewer
					if not view then if viewer then viewer:Hide() end return end
					if not viewer then
						viewer = CreateFrame("Frame", nil, card, "BackdropTemplate")
						viewer:Hide()
						viewer:SetSize(PixelRound(380), PixelRound(520))
						viewer:SetPoint("BOTTOMLEFT", card, "BOTTOMRIGHT", PixelRound(8), 0)
						viewer:SetFrameStrata("FULLSCREEN_DIALOG")
						viewer:SetFrameLevel(card:GetFrameLevel() + 50) -- Above the card and its buttons
						viewer:EnableMouse(true)
						viewer:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = OnePixel()})
						viewer:SetBackdropColor(0.06, 0.06, 0.08, 0.96)
						-- Drawn into its own buffer, so 3D models open behind it (such as the character frame's model) cannot show through the model as a silhouette
						-- (set once here and left on, as turning it off again leaves the model blank)
						if viewer.SetIsFrameBuffer then viewer:SetIsFrameBuffer(true) end
						viewer.title = viewer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
						viewer.title:SetPoint("TOPLEFT", viewer, "TOPLEFT", 14, -14)
						viewer.title:SetPoint("RIGHT", viewer, "RIGHT", -110, 0)
						viewer.title:SetJustifyH("LEFT")
						viewer.title:SetWordWrap(false)
						-- Gear button (takes equipped items off and puts them back on)
						viewer.gear = FlatButton(viewer, 86, 22, L["Show gear"])
						local showGearWidth = viewer.gear.label:GetStringWidth()
						viewer.gear:SetLabel(L["Hide gear"])
						viewer.gear:SetWidth(PixelRound(math.max(86, showGearWidth + 20, viewer.gear.label:GetStringWidth() + 20))) -- Wide enough for both labels in every language
						viewer.gear:SetPoint("TOPRIGHT", viewer, "TOPRIGHT", -10, -10)
						-- Fullscreen button (shows the viewer over the whole screen, Escape or the button again puts it back)
						viewer.full = FlatButton(viewer, 86, 22, L["Exit fullscreen"])
						local exitWidth = viewer.full.label:GetStringWidth()
						viewer.full:SetLabel(L["Fullscreen"])
						viewer.full:SetWidth(math.max(exitWidth, viewer.full.label:GetStringWidth()) + 20) -- Wide enough for both labels
						viewer.full:SetScript("OnClick", function() viewer:SetFullscreen(not viewer.fullscreen) end)
						-- Place the fullscreen button left of the gear button (or in the corner when there is no gear button), and keep the title clear of them
						function viewer:LayoutButtons()
							-- Fullscreen button on the far right, then the gear button (players and items), then the scene button (fullscreen only)
							self.full:ClearAllPoints()
							self.full:SetPoint("TOPRIGHT", self, "TOPRIGHT", -10, -10)
							self.gear:ClearAllPoints()
							self.gear:SetPoint("RIGHT", self.full, "LEFT", -6, 0)
							local used = 10 + self.full:GetWidth() + (self.gear:IsShown() and (6 + self.gear:GetWidth()) or 0) + 14
							if self.sceneBtn then
								self.sceneBtn:ClearAllPoints()
								self.sceneBtn:SetPoint("RIGHT", self.gear:IsShown() and self.gear or self.full, "LEFT", -6, 0)
								if self.sceneBtn:IsShown() then used = used + 6 + self.sceneBtn:GetWidth() end
							end
							self.title:ClearAllPoints()
							self.title:SetPoint("TOPLEFT", self, "TOPLEFT", 14, -14)
							if self.fullscreen and self.sceneBtn then
								self.title:SetWidth(math.min(self.title.GetUnboundedStringWidth and self.title:GetUnboundedStringWidth() or self.title:GetStringWidth(), 320) + 2) -- Only as wide as the name (the flavour text follows it)
							else
								self.title:SetPoint("RIGHT", self, "RIGHT", -used, 0)
							end
						end
						viewer.gear:HookScript("OnShow", function() viewer:LayoutButtons() end)
						viewer.gear:HookScript("OnHide", function() viewer:LayoutButtons() end)
						-- Model area
						viewer.stage = viewer:CreateTexture(nil, "BORDER")
						viewer.stage:SetPoint("TOPLEFT", viewer, "TOPLEFT", 12, -42)
						viewer.stage:SetColorTexture(0, 0, 0, 0.45)
						-- Model frames: two dressing room models for players and items (one wearing gear, one without, so the gear button
						-- just swaps between them and nothing reloads or moves), and a plain model for NPCs and pets
						-- (creature models in a dressing room model can crash the game)
						viewer.dressModel = CreateFrame("DressUpModel", nil, viewer)
						viewer.nakedModel = CreateFrame("DressUpModel", nil, viewer)
						viewer.creatureModel = CreateFrame("PlayerModel", nil, viewer)
						viewer.dressModel.twin, viewer.nakedModel.twin = viewer.nakedModel, viewer.dressModel
						for void, model in ipairs({viewer.dressModel, viewer.nakedModel, viewer.creatureModel}) do
						if model.SetKeepModelOnHide then model:SetKeepModelOnHide(true) end -- Keep the model when it is hidden (for the gear swap)
						model:SetAllPoints(viewer.stage)
						model:EnableMouse(true)
						model:EnableMouseWheel(true)
						model:Hide()
						-- Run a function once the model has loaded (or straight away if it already has)
						function model:WhenLoaded(func)
							if self.loaded then C_Timer.After(0, function() if self.loaded and self:IsVisible() then func() end end) return end
							self.onLoaded = func
							C_Timer.After(0.3, function() -- In case the loaded event does not fire
								if self.onLoaded == func and self:IsVisible() then self.loaded = true self.onLoaded = nil func() end
							end)
						end
						model:SetScript("OnModelLoaded", function(self)
							self.loaded = true
							local func = self.onLoaded
							self.onLoaded = nil
							if func then C_Timer.After(0, function() if self.loaded and self:IsVisible() then func() end end) end -- Next frame, not in the middle of loading
						end)
						-- Left button turns, right button moves, middle button turns and tilts freely, mouse wheel zooms
						model:SetScript("OnMouseDown", function(self, btn)
							if btn == "LeftButton" then self.turning = GetCursorPosition() elseif btn == "RightButton" then self.panX, self.panY = GetCursorPosition() elseif btn == "MiddleButton" then self.freeX, self.freeY = GetCursorPosition() end
						end)
						model:SetScript("OnMouseUp", function(self, btn)
							if btn == "LeftButton" then self.turning = nil elseif btn == "RightButton" then self.panX, self.panY = nil, nil elseif btn == "MiddleButton" then self.freeX, self.freeY = nil, nil end
						end)
						model:SetScript("OnHide", function(self) self.turning, self.panX, self.panY, self.freeX, self.freeY = nil, nil, nil, nil, nil end)
						model:SetScript("OnUpdate", function(self, elapsed)
							if not self.loaded then return end
							local changed
							-- Smooth zoom (eases towards the zoom chosen with the mouse wheel by moving the model towards the camera)
							-- Camera distance functions are not used as they can crash the game while a model is loading
							local target = self.zoomTarget or 0
							if math.abs(target - (self.zoom or 0)) > 0.001 then
								self.zoom = (self.zoom or 0) + (target - (self.zoom or 0)) * math.min(1, elapsed * 10)
								self:SetPosition(self.zoom, self.offsetY or 0, self.offsetZ or 0)
								changed = true
							end
							if self.turning then
								local x = GetCursorPosition()
								self.facing = (self.facing or 0) + (x - self.turning) * 0.012
								self.turning = x
								self:SetFacing(self.facing)
								changed = true
							end
							if self.freeX then
								-- Middle button: left and right turns, up and down tilts
								local x, y = GetCursorPosition()
								self.facing = (self.facing or 0) + (x - self.freeX) * 0.012
								self.pitch = (self.pitch or 0) - (y - self.freeY) * 0.012
								self.freeX, self.freeY = x, y
								self:SetFacing(self.facing)
								if self.SetPitch then self:SetPitch(self.pitch) end
								changed = true
							end
							if self.panX then
								local x, y = GetCursorPosition()
								local step = 0.004 * math.max(0.3, 1 - (self.zoom or 0) * 0.3)
								self.offsetY = (self.offsetY or 0) + (x - self.panX) * step
								self.offsetZ = (self.offsetZ or 0) + (y - self.panY) * step
								self.panX, self.panY = x, y
								self:SetPosition(self.zoom or 0, self.offsetY, self.offsetZ)
								changed = true
							end
							-- Keep the other dressing room model (gear on or off) the same, so swapping gear does not move anything
							local twin = self.twin
							if changed and twin and twin.loaded then
								twin.facing, twin.pitch, twin.zoom, twin.zoomTarget, twin.offsetY, twin.offsetZ = self.facing, self.pitch, self.zoom, self.zoomTarget, self.offsetY, self.offsetZ
								twin:SetFacing(twin.facing or 0)
								if twin.SetPitch then twin:SetPitch(twin.pitch or 0) end
								twin:SetPosition(twin.zoom or 0, twin.offsetY or 0, twin.offsetZ or 0)
							end
						end)
						model:SetScript("OnMouseWheel", function(self, delta)
							if not self.loaded then return end
							self.zoomTarget = math.max(-1.5, math.min(2.5, (self.zoomTarget or 0) + delta * 0.3))
						end)
						end
						viewer.model = viewer.dressModel
						-- Controls button (pointing at it shows how to turn, move, tilt and zoom the model)
						viewer.hint = FlatButton(viewer, 70, 20, L["Controls"])
						viewer.hint:SetWidth(viewer.hint.label:GetStringWidth() + 20)
						viewer.hint:SetPoint("BOTTOMRIGHT", viewer.stage, "BOTTOMRIGHT", -10, 10)
						-- Controls popup (made the first time the button is pointed at)
						function viewer:ShowControls()
							local tip = self.controlsTip
							if not tip then
								tip = CreateFrame("Frame", nil, self, "BackdropTemplate")
								self.controlsTip = tip
								tip:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = OnePixel()})
								tip:SetBackdropColor(0.06, 0.06, 0.08, 0.98)
								tip.heading = tip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
								tip.heading:SetPoint("TOPLEFT", tip, "TOPLEFT", 14, -12)
								tip.heading:SetText(L["Model controls"])
								local rows = {
									{L["Left-drag"], L["Turn"]},
									{L["Right-drag"], L["Move"]},
									{L["Middle-drag"], L["Turn and tilt"]},
									{L["Mouse wheel"], L["Zoom"]},
								}
								tip.keys, tip.actions = {}, {}
								local keyWidth, actionWidth = 0, 0
								for i, row in ipairs(rows) do
									local key = tip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
									key:SetPoint("TOPLEFT", tip, "TOPLEFT", 14, -36 - (i - 1) * 18)
									key:SetText(row[1])
									local action = tip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
									action:SetText(row[2])
									action:SetTextColor(0.8, 0.8, 0.8)
									tip.keys[i], tip.actions[i] = key, action
									keyWidth = math.max(keyWidth, key:GetStringWidth())
									actionWidth = math.max(actionWidth, action:GetStringWidth())
								end
								for i, action in ipairs(tip.actions) do
									action:SetPoint("LEFT", tip.keys[i], "LEFT", keyWidth + 18, 0)
								end
								tip:SetSize(math.max(tip.heading:GetStringWidth(), keyWidth + 18 + actionWidth) + 28, 36 + #rows * 18 + 6)
							end
							-- Colours follow the viewer (key names in the accent colour)
							local r, g, b = unpack(self.accent or {1, 0.82, 0})
							tip:SetBackdropBorderColor(r, g, b, 0.55)
							tip.heading:SetTextColor(r, g, b)
							for void, key in ipairs(tip.keys) do key:SetTextColor(r, g, b) end
							-- Above the button, lined up with its right edge
							tip:ClearAllPoints()
							tip:SetPoint("BOTTOMRIGHT", self.hint, "TOPRIGHT", 0, 6)
							tip:SetFrameLevel(self:GetFrameLevel() + 30)
							tip:Show()
						end
						local function HideControls() if viewer.controlsTip then viewer.controlsTip:Hide() end end
						viewer.hint:HookScript("OnEnter", function() viewer:ShowControls() end)
						viewer.hint:HookScript("OnLeave", HideControls)
						viewer.hint:HookScript("OnHide", HideControls)
						-- Waiting for a player (shown when they can no longer be found, the model loads when the mouse is over them again)
						viewer.waitText = viewer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
						viewer.waitText:SetPoint("LEFT", viewer.stage, "LEFT", 20, 0)
						viewer.waitText:SetPoint("RIGHT", viewer.stage, "RIGHT", -20, 0)
						viewer.waitText:SetWordWrap(true)
						viewer.waitText:Hide()
						viewer:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
						function viewer:CheckWaiting()
							if not self:IsShown() or self.waitGUID == nil then return end
							if not UnitExists("mouseover") then return end
							-- Match by GUID, or by name when the GUID cannot be read
							local guid = UnitGUID("mouseover")
							local match
							if guid and not (issecretvalue and issecretvalue(guid)) and self.waitGUID then
								match = guid == self.waitGUID
							else
								local name, realm = UnitName("mouseover")
								if name and not (issecretvalue and (issecretvalue(name) or (realm and issecretvalue(realm)))) then
									match = name == self.waitName or (realm and realm ~= "" and (name .. " " .. realm) == self.waitName)
								end
							end
							if match then
								local cardInfo = LeaPlusLC.IDCard and LeaPlusLC.IDCard.info
								if cardInfo and cardInfo.view and cardInfo.name == self.waitName then
									cardInfo.view.unit = "mouseover"
									cardInfo.view.fresh = true
									self.lastLoad = nil -- Load straight away
									cardInfo.openViewer = true
									ShowViewer(cardInfo)
									cardInfo.view.fresh = nil
									cardInfo.openViewer = nil
								end
							end
						end
						viewer:SetScript("OnEvent", function(self) self:CheckWaiting() end)
						-- Animation slider (same animations as Enhance dressup)
						-- Gear slot buttons (players and items): click one to take that piece off the model, click again to put it back on
						viewer.hiddenSlots, viewer.slotInfo, viewer.slotButtons = {}, {}, {}
						viewer.slotRow = CreateFrame("Frame", nil, viewer)
						viewer.slotRow:SetPoint("TOPLEFT", viewer.stage, "BOTTOMLEFT", 0, -8)
						viewer.slotRow:SetPoint("TOPRIGHT", viewer.stage, "BOTTOMRIGHT", 0, -8)
						viewer.slotRow:SetHeight(22)
						viewer.slotRow:Hide()
						local slotList = {{1, "HeadSlot"}, {3, "ShoulderSlot"}, {15, "BackSlot"}, {5, "ChestSlot"}, {4, "ShirtSlot"}, {19, "TabardSlot"}, {9, "WristSlot"}, {10, "HandsSlot"}, {6, "WaistSlot"}, {7, "LegsSlot"}, {8, "FeetSlot"}, {16, "MainHandSlot"}, {17, "SecondaryHandSlot"}, {18, "RangedSlot"}}
						for void, entry in ipairs(slotList) do
							local slotID, slotName = entry[1], entry[2]
							local ok, slotNumber, emptyTexture = pcall(GetInventorySlotInfo, slotName) -- Slots this game does not have are left out
							if ok and slotNumber then
								local button = CreateFrame("Button", nil, viewer.slotRow, "BackdropTemplate")
								button.slotID, button.slotName, button.emptyTexture = slotID, slotName, emptyTexture
								button.label = _G[strupper(slotName)] or slotName
								button:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = OnePixel()})
								button:SetBackdropColor(0, 0, 0, 0.6)
								button:SetBackdropBorderColor(1, 1, 1, 0.15)
								button.icon = button:CreateTexture(nil, "ARTWORK")
								button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", OnePixel(), -OnePixel())
								button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -OnePixel(), OnePixel())
								button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
								button:SetScript("OnEnter", function(self)
									GameTooltip:SetOwner(self, "ANCHOR_TOP")
									GameTooltip:AddLine(self.label, 1, 1, 1)
									if not viewer.slotInfo[self.slotID] then
										GameTooltip:AddLine(L["Nothing to show in this slot"], 0.6, 0.6, 0.65)
									elseif viewer.gearOff then
										GameTooltip:AddLine(L["Click Show gear first"], 0.6, 0.6, 0.65)
									elseif viewer.hiddenSlots[self.slotID] then
										GameTooltip:AddLine(L["Click to show"], 0.6, 0.6, 0.65)
									else
										GameTooltip:AddLine(L["Click to hide"], 0.6, 0.6, 0.65)
									end
									GameTooltip:Show()
								end)
								button:SetScript("OnLeave", function() GameTooltip:Hide() end)
								button:SetScript("OnClick", function(self)
									local info = viewer.slotInfo[self.slotID]
									local model = viewer.dressModel
									if not info or viewer.gearOff or not model.loaded then return end
									if viewer.hiddenSlots[self.slotID] then
										-- Put it back on
										viewer.hiddenSlots[self.slotID] = nil
										if info.transmog and model.SetItemTransmogInfo then
											pcall(model.SetItemTransmogInfo, model, info.transmog, self.slotID)
										elseif info.link then
											pcall(model.TryOn, model, info.link, (self.slotID == 16 or self.slotID == 17) and strupper(self.slotName) or nil)
										end
									else
										-- Take it off
										viewer.hiddenSlots[self.slotID] = true
										pcall(model.UndressSlot, model, self.slotID)
									end
									viewer:UpdateSlots()
									if GameTooltip:IsOwned(self) then self:GetScript("OnEnter")(self) end
								end)
								tinsert(viewer.slotButtons, button)
							end
						end
						-- Show each button as worn, taken off or empty
						function viewer:UpdateSlots()
							local r, g, b = unpack(self.accent or {1, 0.82, 0})
							for void, button in ipairs(self.slotButtons) do
								local info = self.slotInfo[button.slotID]
								local hidden = self.hiddenSlots[button.slotID] and true or false
								local worn = info and not hidden and not self.gearOff
								button.icon:SetTexture((info and info.icon) or button.emptyTexture or 136528)
								button.icon:SetDesaturated(not worn)
								button.icon:SetAlpha(not info and 0.3 or worn and 1 or 0.45)
								if worn then button:SetBackdropBorderColor(r, g, b, 0.7) else button:SetBackdropBorderColor(1, 1, 1, 0.15) end
							end
						end
						-- Read what the model is wearing in each slot (so a piece can be put back on after it is taken off)
						function viewer:ReadSlots(model, unit)
							wipe(self.slotInfo)
							wipe(self.hiddenSlots)
							local GetIcon = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
							for void, button in ipairs(self.slotButtons) do
								local slotID = button.slotID
								local info = {}
								if model.GetItemTransmogInfo then
									local ok, transmog = pcall(model.GetItemTransmogInfo, model, slotID)
									local appearanceID = ok and SafeTable(transmog) and Safe(transmog.appearanceID)
									if type(appearanceID) == "number" and appearanceID > 0 then
										info.transmog = transmog
										if C_TransmogCollection and C_TransmogCollection.GetSourceInfo then
											local source = SafeTable(C_TransmogCollection.GetSourceInfo(appearanceID))
											local itemID = source and Safe(source.itemID)
											if itemID and GetIcon then info.icon = Safe(GetIcon(itemID)) end
										end
									end
								end
								if unit and Safe(UnitExists(unit)) then
									info.link = Safe(GetInventoryItemLink(unit, slotID))
									if not info.icon then info.icon = Safe(GetInventoryItemTexture(unit, slotID)) end
								end
								if info.link and not info.icon and GetIcon then info.icon = Safe(GetIcon(info.link)) end
								if info.transmog or info.link then self.slotInfo[slotID] = info end
							end
							self:UpdateSlots()
						end
						-- A player the game has not drawn in the viewer before can report the model as loaded before their gear has arrived, so the slot
						-- buttons would stay empty until the key is pressed again: read them again a few times until something is found (up to 2 seconds)
						function viewer:RetrySlots(model, unit, loadID)
							local tries = 0
							local function Retry()
								if next(self.slotInfo) or self.loadID ~= loadID or not self:IsShown() or next(self.hiddenSlots) then return end
								tries = tries + 1
								self:ReadSlots(model, unit)
								if next(self.slotInfo) then self:ApplyInspectGear() self:CheckReveal() end
								if not next(self.slotInfo) and tries < 10 then C_Timer.After(0.2, Retry) end
							end
							C_Timer.After(0.2, Retry)
						end
						-- Other players: the game does not always put every weapon on the model (such as the main hand of a dual wielder) until
						-- they have been inspected, so the weapons read by the card's own inspect are put on the model and on the slot buttons
						function viewer:ApplyInspectGear()
							local view = self.view
							if not self:IsShown() or not view or view.mode ~= "unit" or not view.isPlayer or not view.guid then return end
							local gear = LeaPlusLC.IDGear and LeaPlusLC.IDGear[view.guid]
							local model = self.dressModel
							if not gear or not model.loaded then return end
							local GetIcon = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
							-- Weapons are put straight into their own hand slot as appearances (trying them on makes the game treat the player
							-- as unable to dual wield, so a weapon in one hand pushes out the other)
							local weapons = {}
							if model.SetItemTransmogInfo then
								for void, slotID in ipairs({16, 17}) do
									if gear[slotID] then
										-- The weapon's look as shown on the player (such as a transmog), if the game gives it, otherwise the item's own look
										local look = gear.looks and SafeTable(gear.looks[slotID])
										local lookID = look and Safe(look.appearanceID)
										if type(lookID) == "number" and lookID > 0 then
											weapons[slotID] = look
										elseif C_TransmogCollection and C_TransmogCollection.GetItemInfo and ItemUtil and ItemUtil.CreateItemTransmogInfo then
											local ok, void, sourceID = pcall(C_TransmogCollection.GetItemInfo, gear[slotID])
											sourceID = ok and Safe(sourceID)
											if type(sourceID) == "number" and sourceID > 0 then
												local made, transmog = pcall(ItemUtil.CreateItemTransmogInfo, sourceID)
												if made and transmog then weapons[slotID] = transmog end
											end
										end
									end
								end
							end
							local function Wield()
								if self.view ~= view or not model.loaded then return end
								for void, slotID in ipairs({16, 17}) do
									if weapons[slotID] and not self.hiddenSlots[slotID] then pcall(model.SetItemTransmogInfo, model, weapons[slotID], slotID) end
								end
							end
							if weapons[16] or weapons[17] then
								Wield()
								C_Timer.After(0.3, Wield) -- Again a moment later in case the game was still dressing the model
							end
							-- Fill in the slot buttons (weapons use the same appearances, so clicking to put one back on keeps both showing)
							for void, button in ipairs(self.slotButtons) do
								local slotID = button.slotID
								local link, info = gear[slotID], self.slotInfo[slotID]
								if link and (not info or not info.link or weapons[slotID]) then
									info = info or {}
									info.link = link
									if weapons[slotID] then info.transmog = weapons[slotID] end
									if not info.icon and GetIcon then info.icon = Safe(GetIcon(link)) end
									self.slotInfo[slotID] = info
								end
							end
							self:UpdateSlots()
						end
						-- Other players whose model comes up without a main hand (such as a paired weapon shown in both hands, which the game only gives
						-- after an inspect) are kept hidden with a message until their inspect has come back, then shown complete (players who look
						-- complete straight away are shown at once)
						function viewer:HoldModel(guid)
							self.holdGUID = guid
							self.holdID = (self.holdID or 0) + 1
							local holdID = self.holdID
							self.dressModel:SetAlpha(0)
							self.nakedModel:SetAlpha(0)
							-- Keep waiting while the inspect is on the way (up to 6 seconds), or while its reply is waiting for the player to be pointed at again
							local started = GetTime()
							local function Check()
								if self.holdID ~= holdID then return end
								local wait = LeaPlusLC.IDTalentWait
								if wait and wait.guid == guid then
									self.waitText:SetFormattedText(L["Move your mouse over %s to show their model."], self.title:GetText() or "")
									self.waitText:Show()
									C_Timer.After(0.5, Check)
									return
								end
								local card = LeaPlusLC.IDCard
								local pending = card and card:IsShown() and (card.inspectGUID == guid or card.gearReadingGUID == guid)
								if pending and GetTime() - started < 6 then C_Timer.After(0.5, Check) return end
								self:RevealModel()
							end
							C_Timer.After(1, Check)
						end
						function viewer:RevealModel()
							if not self.holdGUID then return end
							self.holdGUID = nil
							self.holdID = (self.holdID or 0) + 1
							self.dressModel:SetAlpha(1)
							self.nakedModel:SetAlpha(1)
							if self.waitGUID == nil then self.waitText:Hide() end
						end
						-- Show the model once it has a main hand, once the inspect has finished, or once no inspect is on the way
						function viewer:CheckReveal()
							local guid = self.holdGUID
							if not guid then return end
							local view = self.view
							if not self:IsShown() or not view or view.guid ~= guid then self:RevealModel() return end
							local gear = LeaPlusLC.IDGear and LeaPlusLC.IDGear[guid]
							local card = LeaPlusLC.IDCard
							local wait = LeaPlusLC.IDTalentWait
							local pending = card and card:IsShown() and (card.inspectGUID == guid or card.gearReadingGUID == guid or (wait and wait.guid == guid))
							if self.slotInfo[16] or (gear and gear.complete) or not pending then
								local holdID = self.holdID
								C_Timer.After(0.1, function() if self.holdID == holdID then self:RevealModel() end end) -- Give the weapons a moment to be drawn
							else
								-- Still waiting, so say so
								if not (wait and wait.guid == guid) then self.waitText:SetText(RETRIEVING_DATA or SEARCH_LOADING_TEXT or "...") end
								self.waitText:Show()
							end
						end
						viewer:HookScript("OnHide", function(self) self:RevealModel() end)
						viewer.animLabel = viewer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
						viewer.animLabel:SetPoint("TOPLEFT", viewer.stage, "BOTTOMLEFT", 2, -14)
						viewer.animLabel:SetText(L["Animation"])
						LeaPlusLC["IDViewerAnim"] = 1 -- Not saved
						LeaPlusLC:MakeSL(viewer, "IDViewerAnim", "", 1, #viewerAnims - 1, 1, 0, 0, "%.0f")
						viewer.anim = LeaPlusCB["IDViewerAnim"]
						viewer.anim:ClearAllPoints()
						viewer.anim:SetPoint("LEFT", viewer.animLabel, "RIGHT", 12, 0)
						viewer.anim:SetScript("OnEnter", nil)
						viewer.anim:SetScript("OnLeave", nil)
						if viewer.anim.SetObeyStepOnDrag then viewer.anim:SetObeyStepOnDrag(true) end -- Move in whole steps while dragging
						viewer.anim:HookScript("OnValueChanged", function(self, setting)
							setting = math.floor(setting + 0.5)
							-- Only change the animation when the step changes (restarting it on every small movement makes it jerky)
							if setting == viewer.lastAnim then return end
							local model = viewer.model
							if model and model.loaded and model:IsVisible() and viewerAnims[setting] then
								viewer.lastAnim = setting
								model:SetAnimation(viewerAnims[setting])
							end
						end)
						-- Flavour text
						viewer.text = viewer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
						viewer.text:SetPoint("TOPLEFT", viewer.animLabel, "BOTTOMLEFT", 0, -14)
						viewer.text:SetPoint("RIGHT", viewer, "RIGHT", -14, 0)
						viewer.text:SetJustifyH("LEFT")
						viewer.text:SetWordWrap(true)
						viewer.text:SetTextColor(1, 0.82, 0)
						-- Keep the model area filling the frame above the slider and text
						function viewer:Layout()
							local full = self.fullscreen and self.sceneBtn
							-- Flavour text: on one line along the top in fullscreen, normal lines under the slider otherwise
							local raw = self.flavourRaw
							if raw then self.text:SetText(full and (raw:gsub("\n", "     ")) or raw) end
							local count = #self.slotButtons
							local gap = 2
							if full then
								-- Fullscreen: the gear slot buttons, a shorter animation slider and the flavour text go along the top, so the model area reaches the bottom
								self.stage:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -12, 12)
								self.stageBottom = 12
								local size = 22
								self.slotRow:ClearAllPoints()
								self.slotRow:SetSize(math.max(1, count * (size + gap) - gap), size)
								self.slotRow:SetPoint("RIGHT", self.sceneBtn, "LEFT", -20, 0)
								for i, button in ipairs(self.slotButtons) do
									button:SetSize(size, size)
									button:ClearAllPoints()
									button:SetPoint("LEFT", self.slotRow, "LEFT", (i - 1) * (size + gap), 0)
								end
								self.anim:SetWidth(120)
								self.anim:ClearAllPoints()
								self.anim:SetPoint("RIGHT", self.slotRow:IsShown() and self.slotRow or self.sceneBtn, "LEFT", -40, 0) -- Room for the number after the slider
								self.animLabel:ClearAllPoints()
								self.animLabel:SetPoint("RIGHT", self.anim, "LEFT", -10, 0)
								self.text:ClearAllPoints()
								self.text:SetPoint("LEFT", self.title, "RIGHT", 16, 0)
								self.text:SetPoint("RIGHT", self.animLabel, "LEFT", -20, 0)
								self.text:SetWordWrap(false)
								-- Controls button in the bottom-right corner of the model area
								self.hint:ClearAllPoints()
								self.hint:SetPoint("BOTTOMRIGHT", self.stage, "BOTTOMRIGHT", -10, 10)
							else
								-- Controls button in the bottom-right corner of the model area (same as fullscreen)
								self.hint:ClearAllPoints()
								self.hint:SetPoint("BOTTOMRIGHT", self.stage, "BOTTOMRIGHT", -10, 10)
								-- Normal: gear slot buttons, then the animation slider, then the flavour text, all under the model area
								self.slotRow:ClearAllPoints()
								self.slotRow:SetPoint("TOPLEFT", self.stage, "BOTTOMLEFT", 0, -8)
								self.slotRow:SetPoint("TOPRIGHT", self.stage, "BOTTOMRIGHT", 0, -8)
								self.slotRow:SetHeight(22)
								-- The label was attached to the slider in fullscreen, so free it first (the slider is then attached to the label)
								self.animLabel:ClearAllPoints()
								self.animLabel:SetPoint("TOPLEFT", self.stage, "BOTTOMLEFT", 2, -14)
								self.anim:ClearAllPoints()
								self.anim:SetPoint("LEFT", self.animLabel, "RIGHT", 12, 0)
								self.text:ClearAllPoints()
								self.text:SetPoint("TOPLEFT", self.animLabel, "BOTTOMLEFT", 0, -14)
								self.text:SetPoint("RIGHT", self, "RIGHT", -14, 0)
								self.text:SetWordWrap(true)
								local text = Safe(self.text:GetText())
								local textHeight = (text and text ~= "") and (self.text:GetStringHeight() + 14) or 0
								local slotsHeight = self.slotRow:IsShown() and 30 or 0
								self.stage:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -12, 44 + textHeight + slotsHeight)
								self.stageBottom = 44 + textHeight + slotsHeight
								-- Animation slider goes under the gear slot buttons when they are showing
								self.animLabel:ClearAllPoints()
								self.animLabel:SetPoint("TOPLEFT", slotsHeight > 0 and self.slotRow or self.stage, "BOTTOMLEFT", 2, -14)
								-- Gear slot buttons share the width of the row (centred)
								if count > 0 then
									local rowWidth = self:GetWidth() - 24
									local size = math.max(10, math.min(22, math.floor((rowWidth - gap * (count - 1)) / count)))
									local left = math.floor((rowWidth - (size * count + gap * (count - 1))) / 2)
									for i, button in ipairs(self.slotButtons) do
										button:SetSize(size, size)
										button:ClearAllPoints()
										button:SetPoint("LEFT", self.slotRow, "LEFT", left + (i - 1) * (size + gap), 0)
									end
								end
								self.anim:SetWidth(math.min(500, math.max(80, self:GetWidth() - 24 - self.animLabel:GetStringWidth() - 70)))
							end
							if self.LayoutScene then self:LayoutScene() end
						end
						viewer:SetScript("OnSizeChanged", function(self) self:Layout() end)
						-- Gear button
						viewer.gear:SetScript("OnClick", function()
							local from = viewer.model
							local to = from and from.twin
							if not (from and to and from.loaded and to.loaded) then return end
							viewer.gearOff = not viewer.gearOff
							-- Swap to the other model, with the same turn, position, zoom and animation (nothing reloads, so nothing moves)
							to.facing, to.pitch, to.zoom, to.zoomTarget, to.offsetY, to.offsetZ = from.facing, from.pitch, from.zoom, from.zoomTarget, from.offsetY, from.offsetZ
							to:Show()
							to:SetFacing(to.facing or 0)
							if to.SetPitch then to:SetPitch(to.pitch or 0) end
							to:SetPosition(to.zoom or 0, to.offsetY or 0, to.offsetZ or 0)
							local setting = math.floor(viewer.anim:GetValue() + 0.5)
							if viewerAnims[setting] then to:SetAnimation(viewerAnims[setting]) end
							from:Hide()
							viewer.model = to
							viewer.gear:SetLabel(viewer.gearOff and L["Show gear"] or L["Hide gear"])
							viewer:UpdateSlots()
						end)
						viewer:Layout()
						-- Fullscreen on or off (the same viewer is made to fill the screen, so the model, slider and gear buttons all keep working)
						function viewer:SetFullscreen(on)
							on = on and true or false
							if on == (self.fullscreen or false) then return end
							local card = LeaPlusLC.IDCard
							if on then
								self.normalWidth = self:GetWidth()
								self.fullscreen = true
								-- In fullscreen the viewer goes under the card's layer (so the card can be shown over it when pointing at the name)
								-- and the card waits off the screen (still open, so Escape, the keys and the model updates all work as normal)
								self:SetParent(UIParent)
								self:SetFrameStrata("FULLSCREEN")
								card.savedPoints = {}
								for i = 1, card:GetNumPoints() do card.savedPoints[i] = {card:GetPoint(i)} end
								self:HideCard()
							else
								self.fullscreen = nil
								self:EndHoverCard() -- In case the card is showing from the name
								-- Back on top of the card, and the card back where it was
								self:SetParent(card)
								self:SetFrameStrata("FULLSCREEN_DIALOG")
								self:SetFrameLevel(card:GetFrameLevel() + 50)
								if card.savedPoints and card.savedPoints[1] then
									card:ClearAllPoints()
									for void, point in ipairs(card.savedPoints) do card:SetPoint(unpack(point)) end
								end
								card.savedPoints = nil
								card:SetClampedToScreen(true)
								self:ClearAllPoints()
								self:SetSize(self.normalWidth or PixelRound(380), self.normalHeight or PixelRound(520))
							end
							if on then self.randomScene = nil end -- A new random loading screen each time
							self:SetBackdropColor(0.06, 0.06, 0.08, on and 1 or 0.96) -- Solid in fullscreen so nothing behind shows through
							self.full:SetLabel(on and L["Exit fullscreen"] or L["Fullscreen"])
							AttachViewer()
							self:Layout()
							if not on then
								-- Back to normal size: fit the height to the flavour text again (it was on one line in fullscreen)
								local text = Safe(self.text:GetText())
								self.normalHeight = PixelRound(42 + 380 + 44 + (self.slotRow:IsShown() and 30 or 0) + ((text and text ~= "") and (self.text:GetStringHeight() + 14) or 0))
								self:SetHeight(self.normalHeight)
								AttachViewer()
							end
							self:ApplyScene()
							self:ApplyLevels()
							self:LayoutButtons()
							self:HideJournalModels(on)
						end
						-- The game draws the collection journal's own 3D previews over the fullscreen viewer, so they are made see-through
						-- while fullscreen is open, then put back as they were (only their transparency is changed, nothing else on them)
						function viewer:HideJournalModels(hide)
							if hide then
								self.journalModels = self.journalModels or {}
								-- The mount preview, the pet card preview and the three battle pet slots
								local scenes = {
									MountJournal and MountJournal.MountDisplay and MountJournal.MountDisplay.ModelScene,
									PetJournalPetCard and PetJournalPetCard.modelScene,
								}
								local loadout = PetJournal and PetJournal.Loadout
								if loadout then
									for i = 1, 3 do
										local plate = loadout["Pet" .. i]
										if plate and plate.modelScene then tinsert(scenes, plate.modelScene) end
									end
								end
								for void, scene in pairs(scenes) do
									if scene and not (scene.IsForbidden and scene:IsForbidden()) and self.journalModels[scene] == nil then
										self.journalModels[scene] = scene:GetAlpha()
										scene:SetAlpha(0)
									end
								end
							elseif self.journalModels then
								for scene, alpha in pairs(self.journalModels) do scene:SetAlpha(alpha) end
								wipe(self.journalModels)
							end
						end
						-- Background scenes for fullscreen (plain colours, racial dressing room backgrounds and class talent backgrounds)
						-- Each picture is made of pieces: position and size of each piece in the picture, then its texture coordinates
						local loadLayout = {w = 1024, h = 768, fit = true, pieces = {{0, 0, 1024, 768, 0, 1, 0, 1}}} -- Loading screens (4:3, shown whole: fit = true, or topCrop = 0.27 to fill the area and crop the logo off)
						local wideLayout = {w = 1600, h = 900, pieces = {{0, 0, 1600, 900, 0, 1, 0, 1}}} -- Widescreen loading screens (the game stretches the whole picture across a widescreen, so it is shown at 16:9)
						local letterboxLayout = {w = 1600, h = 900, pieces = {{0, 0, 1600, 900, 0.157, 0.843, 0.157, 0.843}}} -- WoW Forever loading screens (16:9 with black bands painted across the top and bottom): the bands are cropped off and the sides are trimmed to match, so they fill the same 16:9 space as the other loading screens
						local logoLayout = {w = 1600, h = 900, pieces = {{0, 0, 1600, 900, 0.22, 0.78, 0.29, 0.85}}} -- Legion and Battle for Azeroth loading screens: the logo and the frame painted across the top and bottom are cropped off, and the sides are trimmed to match, so they fill the same 16:9 space
						-- Check a picture is in the game (by its file ID, or by trying to load it)
						local probe = viewer:CreateTexture(nil, "BACKGROUND")
						probe:Hide()
						local function FileExists(path)
							if GetFileIDFromPath then return GetFileIDFromPath(path) ~= nil end
							local loaded = probe:SetTexture(path)
							probe:SetTexture(nil)
							if loaded == false then return false end
							return true
						end
						local scenes, sceneByKey = {}, {}
						local function AddScene(scene)
							-- Some pictures have more than one possible file name, the first one in the game is used
							if scene.candidates then
								for void, base in ipairs(scene.candidates) do
									if FileExists(base) then scene.files = {base} break end
								end
								if not scene.files then return end
							end
							if scene.files and not FileExists(scene.files[1]) then return end -- Scenes this game does not have are left out
							tinsert(scenes, scene)
							if scene.key then sceneByKey[scene.key] = scene end
						end
						sceneByKey.random = {key = "random", name = L["Random"]} -- Not in the list: used when no scene has been chosen (a different loading screen each time fullscreen is opened)
						AddScene({key = "none", name = L["None"]})
						AddScene({header = L["Patterns"]})
						AddScene({key = "grey", name = L["Studio grey"], gradient = {0.10, 0.10, 0.11, 0.42, 0.42, 0.45}})
						AddScene({key = "night", name = L["Night sky"], gradient = {0.10, 0.16, 0.32, 0.01, 0.02, 0.06}})
						AddScene({key = "sunset", name = L["Sunset"], gradient = {0.85, 0.45, 0.20, 0.18, 0.06, 0.10}})
						-- Loading screens grouped by expansion (file names from the community listfile, only widescreen ones are used)
						-- Each entry: zone ID for the game's own zone name (or nil), English name, then the files to try in order
						-- A file marked wide, letterbox or logo is widescreen (letterbox and logo ones are cropped); any other file is a 4:3 one, and only its widescreen version (Wide on the end) is used if the game has one
						local function ExpansionName(number, english) return _G["EXPANSION_NAME" .. number] or L[english] end
						local function AddLoadingScreen(screen)
							local zoneName = screen[1] and GetRealZoneText and Safe(GetRealZoneText(screen[1]))
							if type(zoneName) ~= "string" or zoneName == "" then zoneName = L[screen[2]] end
							local base, files, layout = "Interface\\Glues\\LoadingScreens\\"
							for void, candidate in ipairs(screen[3]) do
								local file, kind = candidate[1], candidate[2]
								if kind == "wide" or kind == "letterbox" or kind == "logo" then
									if FileExists(base .. file) then files, layout = {base .. file}, kind == "letterbox" and letterboxLayout or kind == "logo" and logoLayout or wideLayout end
								elseif FileExists(base .. file .. "Wide") then
									files, layout = {base .. file .. "Wide"}, wideLayout
								end
								if files then break end
							end
							if files then AddScene({key = "load" .. screen[3][1][1], name = zoneName .. (screen[4] or ""), layout = layout, files = files, isLoad = true}) end
						end
						for void, group in ipairs({
							{L["WoW Forever"], {
								{1, "Kalimdor", {{"Camelot160\\Main\\loadscreen_camelot_kalimdor", "letterbox"}}},
								{0, "Eastern Kingdoms", {{"Camelot160\\Main\\loadscreen_camelot_easternkingdom", "letterbox"}}},
								{nil, "Dalaran", {{"Camelot160\\Main\\loadscreen_camelot_dalaran", "letterbox"}}},
								{nil, "Old Ironforge", {{"Camelot160\\Main\\loadscreen_camelot_oldironforge", "letterbox"}}},
								{nil, "Ruins of Lordaeron", {{"Camelot160\\Main\\loadscreen_camelot_ruinsoflordaeron", "letterbox"}}},
								{nil, "Zephras Isle", {{"Camelot160\\Main\\loadscreen_camelot_zephrasisle", "letterbox"}}},
								{nil, "Excavation", {{"Camelot160\\Main\\loadscreen_camelot_excavation", "letterbox"}}},
							}},
							{ExpansionName(6, "Legion"), {
								{nil, "Broken Isles", {{"LoadingScreen_BrokenIsles_Wide", "logo"}}},
								{nil, "Mardum", {{"loadingscreen_mardumwide", "logo"}}},
								{nil, "Death Knight Order Hall", {{"LoadScreen_DeathKnightOrderHall_wide", "logo"}}},
								{nil, "Demon Hunter Order Hall", {{"LoadingScreen_DemonHunterOrderHall_wide", "logo"}}},
								{nil, "Druid Order Hall", {{"LoadingScreen_DruidOrderHall_Wide", "logo"}}},
								{nil, "Hunter Order Hall", {{"LoadScreen_HunterOrderHall_wide", "logo"}}},
								{nil, "Monk Order Hall", {{"LoadScreen_MonkOrderHall_Wide_NoLOGO", "logo"}}},
								{nil, "Priest Order Hall", {{"LoadScreen_PriestOrderHall_wide", "logo"}}},
								{nil, "Warlock Order Hall", {{"LoadScreen_WarlockOrderHall_wide", "logo"}}},
								{nil, "Mage Artifact", {{"LoadScreen_MageArtifact", "logo"}}},
								{nil, "Shaman Artifact", {{"Loadingscreen_shamanartifact_wide", "logo"}}},
								{nil, "Niskara", {{"Loadingscreen_Niskara_wide", "logo"}}},
								{nil, "Light's Hope Chapel", {{"LoadingScreen_LightHopesChapel_wide", "logo"}}},
								{nil, "Eye of Azshara", {{"LoadScreen_NagaDungeon", "logo"}}},
								{nil, "Darkheart Thicket", {{"LoadingScreen_NightmareDungeon_wide", "logo"}}},
								{nil, "Neltharion's Lair", {{"LoadingScreen_NeltharionsLair_wide", "logo"}}},
								{nil, "Halls of Valor", {{"LoadingScreen_HallsofValor_wide", "logo"}}},
								{nil, "Helheim", {{"LoadingScreen_Helheimship_wide", "logo"}}},
								{nil, "Black Rook Hold", {{"LoadingScreen_BlackrookHold_wide", "logo"}}},
								{nil, "Vault of the Wardens", {{"LoadingScreen_VaultOfTheWardens_wide", "logo"}}},
								{nil, "Violet Hold", {{"Loadingscreen_VioletHold_wide", "logo"}}},
								{nil, "Court of Stars", {{"LoadScreen_SuramarCityDungeon", "logo"}}},
								{nil, "Suramar Catacombs", {{"LoadScreen_SuramarCatacombs_wide", "logo"}}},
								{nil, "Return to Karazhan", {{"LoadingScreen_ReturntoKarazhan", "logo"}}},
								{nil, "Cathedral of Eternal Night", {{"LoadScreen_TombOfSargerasDUNGEON_wide", "logo"}}},
								{nil, "The Emerald Nightmare", {{"LoadScreen_EmeraldNightmareRaid_wide", "logo"}}},
								{nil, "Emerald Dreamway", {{"LoadingScreen_EmeraldDreamway_wide", "logo"}}},
								{nil, "Trial of Valor", {{"LoadingScreen_TrialsofValor", "logo"}}},
								{nil, "The Nighthold", {{"LoadScreen_SuramarRaid", "logo"}}},
								{nil, "Tomb of Sargeras", {{"LoadScreen_TombOfSargerasRAID_wide", "logo"}}},
								{nil, "Argus", {{"LoadingScreen_Argus3", "logo"}}},
								{nil, "Krokuun", {{"LoadingScreen_Krokuun_wide", "logo"}}},
								{nil, "Mac'Aree", {{"LoadingScreen_MacAree_wide", "logo"}}},
								{nil, "Seat of the Triumvirate", {{"LoadingScreen_ArgusDungeon_Widescreen", "logo"}}},
								{nil, "Antorus, the Burning Throne", {{"LoadingScreen_ArgusRaid_Widescreen", "logo"}}},
								{nil, "Chromie's Scenario", {{"LoadScreen_ChromieScenario_wide", "logo"}}},
								{nil, "Black Rook Hold Arena", {{"LoadingScreen_BlackrookHoldArena_wide", "logo"}}},
								{nil, "Blade's Edge Arena", {{"LoadingScreen_BladesEdgeArena_wide", "logo"}}},
								{nil, "Nagrand Arena", {{"LoadingScreen_NagrandArena_wide", "logo"}}},
								{nil, "Val'sharah Arena", {{"LoadingScreen_ArenaValSharah_wide", "logo"}}},
								{529, "Arathi Basin", {{"Loadingscreen_ArathiBasinwinter", "logo"}}, " (winter)"},
							}},
							{ExpansionName(7, "Battle for Azeroth"), {
								{489, "Warsong Gulch", {{"loadscreen_warsonggulch_update_wide", "logo"}}},
								{529, "Arathi Basin", {{"loadingscreen_arathibasin_update_wide", "logo"}}},
							}},
						}) do
							AddScene({header = group[1]})
							for void, screen in ipairs(group[2]) do AddLoadingScreen(screen) end
						end
						-- Leave out headings with nothing under them
						for i = #scenes, 1, -1 do
							if scenes[i].header and (not scenes[i + 1] or scenes[i + 1].header) then tremove(scenes, i) end
						end
						-- Chosen scene (saved)
						if LeaPlusLC.IDViewerScene == nil then LeaPlusLC.IDViewerScene = LeaPlusDB and LeaPlusDB["IDViewerScene"] or "random" end
						-- Scene area: fills the model area, clipped to it, under the models
						viewer.sceneFrame = CreateFrame("Frame", nil, viewer)
						viewer.sceneFrame:SetAllPoints(viewer.stage)
						viewer.sceneFrame:SetClipsChildren(true)
						viewer.sceneFrame:Hide()
						viewer.sceneCanvas = CreateFrame("Frame", nil, viewer.sceneFrame)
						-- Softening: the picture is drawn several times, each slightly offset and blended evenly, which smooths out the blocks of low quality pictures
						local softOffsets = {{0, 0}, {1, 0}, {-1, 0}, {0, 1}, {0, -1}, {1, 1}, {-1, -1}, {1, -1}, {-1, 1}}
						viewer.sceneLayers = {}
						for k = 1, #softOffsets do
							viewer.sceneLayers[k] = {}
							for i = 1, 4 do viewer.sceneLayers[k][i] = viewer.sceneCanvas:CreateTexture(nil, "BACKGROUND", nil, k - 9) end -- Later copies on top
						end
						viewer.sceneDim = viewer.sceneCanvas:CreateTexture(nil, "OVERLAY")
						viewer.sceneDim:SetAllPoints(viewer.sceneCanvas)
						viewer.sceneDim:SetColorTexture(0, 0, 0, 1)
						viewer.sceneGradient = viewer.sceneFrame:CreateTexture(nil, "BACKGROUND")
						viewer.sceneGradient:SetAllPoints()
						viewer.sceneGradient:SetTexture("Interface\\Buttons\\WHITE8X8")
						-- Text in the model area is moved to its own layer so it stays above the scene and the models
						viewer.overlay = CreateFrame("Frame", nil, viewer)
						viewer.overlay:SetAllPoints(viewer)
						viewer.hint:SetParent(viewer.overlay)
						viewer.waitText:SetParent(viewer.overlay)
						-- Scene button (only shown in fullscreen)
						viewer.sceneBtn = FlatButton(viewer, 200, 22, "")
						viewer.sceneBtn.label:SetWidth(188)
						viewer.sceneBtn.label:SetWordWrap(false)
						viewer.sceneBtn:Hide()
						viewer.sceneBtn:SetScript("OnClick", function() viewer:ToggleScenePopup() end)
						viewer.sceneBtn:HookScript("OnShow", function() viewer:LayoutButtons() end)
						viewer.sceneBtn:HookScript("OnHide", function() viewer:LayoutButtons() end)
						-- Keep the layers in order: scene, then models, then text and buttons, then the scene list
						function viewer:ApplyLevels()
							local base = self:GetFrameLevel()
							self.sceneFrame:SetFrameLevel(base + 1)
							self.sceneCanvas:SetFrameLevel(base + 2)
							for void, model in ipairs({self.dressModel, self.nakedModel, self.creatureModel}) do model:SetFrameLevel(base + 5) end
							self.overlay:SetFrameLevel(base + 6)
							self.gear:SetFrameLevel(base + 7)
							self.full:SetFrameLevel(base + 7)
							self.sceneBtn:SetFrameLevel(base + 7)
							self.hint:SetFrameLevel(base + 7)
							if self.scenePopup then self.scenePopup:SetFrameLevel(base + 20) end
						end
						-- Size the scene picture to fill the model area (edges are cropped so nothing is stretched)
						function viewer:LayoutScene()
							local scene = self.currentScene
							if not scene or not scene.layout or not self.sceneFrame:IsShown() then return end
							local w, h = self:GetWidth() - 24, self:GetHeight() - 42 - (self.stageBottom or 44)
							if w <= 0 or h <= 0 then return end
							local layout = scene.layout
							local scale = math.min(w / layout.w, h / layout.h) -- Never zoomed in: the whole picture is always shown (dark bars where it does not reach)
							self.sceneCanvas:SetSize(layout.w * scale, layout.h * scale)
							self.sceneCanvas:ClearAllPoints()
							self.sceneCanvas:SetPoint("CENTER", self.sceneFrame, "CENTER", 0, 0)
							local spread = scene.soft and (scale * 0.75) or 0 -- About one picture pixel
							for k, layer in ipairs(self.sceneLayers) do
								local used = k == 1 or scene.soft
								for i, piece in ipairs(layer) do
									local spec = layout.pieces[i]
									if used and spec then
										piece:ClearAllPoints()
										piece:SetPoint("TOPLEFT", self.sceneCanvas, "TOPLEFT", spec[1] * scale + softOffsets[k][1] * spread, -spec[2] * scale + softOffsets[k][2] * spread)
										piece:SetSize(spec[3] * scale, spec[4] * scale)
									end
								end
							end
						end
						-- Show the chosen scene (fullscreen only)
						function viewer:ApplyScene()
							local scene = sceneByKey[self.previewKey or LeaPlusLC.IDViewerScene] or sceneByKey.random -- Hovered scene in the list, or the chosen one (a saved scene no longer in the list uses the default)
							local label = scene.name
							if scene.key == "random" then
								-- Pick a loading screen (a new one each time fullscreen is opened, or when Random is chosen again)
								if not self.randomScene then
									local choices = {}
									for void, entry in ipairs(scenes) do if entry.isLoad then tinsert(choices, entry) end end
									self.randomScene = choices[1] and choices[math.random(#choices)] or sceneByKey.none
								end
								scene = self.randomScene
								label = L["Random"] .. ": " .. scene.name
							end
							self.currentScene = scene
							self.sceneBtn:SetLabel(L["Scene"] .. ": " .. label)
							self.sceneBtn:SetShown(self.fullscreen and true or false)
							if not self.fullscreen and self.scenePopup then self.scenePopup:Hide() end
							local show = self.fullscreen and scene.key ~= "none"
							self.sceneFrame:SetShown(show and true or false)
							if not show then return end
							if scene.gradient then
								local g = scene.gradient
								self.sceneCanvas:Hide()
								self.sceneGradient:Show()
								self.sceneGradient:SetGradient("VERTICAL", CreateColor(g[1], g[2], g[3], 1), CreateColor(g[4], g[5], g[6], 1))
							else
								self.sceneGradient:Hide()
								self.sceneCanvas:Show()
								for k, layer in ipairs(self.sceneLayers) do
									local used = k == 1 or scene.soft
									for i, piece in ipairs(layer) do
										local spec = scene.layout.pieces[i]
										if used and spec then
											piece:SetTexture(scene.files[i], nil, nil, "TRILINEAR") -- Smooth filtering when the picture is enlarged
											piece:SetTexCoord(spec[5], spec[6], spec[7], spec[8])
											piece:SetAlpha(1 / k) -- Each copy blended in evenly with the ones under it
											piece:Show()
										else
											piece:Hide()
										end
									end
								end
								self.sceneDim:SetAlpha(scene.soft and 0.25 or 0) -- Softened pictures are darkened a little so the model stands out
								self:LayoutScene()
							end
						end
						-- Scene list (Leatrix's own list, not the game's dropdown menus)
						function viewer:ToggleScenePopup()
							local popup = self.scenePopup
							if popup and popup:IsShown() then popup:Hide() return end
							if not popup then
								popup = CreateFrame("Frame", nil, self, "BackdropTemplate")
								self.scenePopup = popup
								popup:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = OnePixel()})
								popup:SetBackdropColor(0.06, 0.06, 0.08, 0.98)
								popup:SetBackdropBorderColor(1, 1, 1, 0.15)
								popup:EnableMouse(true)
								popup.rows = {}
								local rowHeight, colWidth = 18, 190
								local maxRows = math.max(10, math.floor((self:GetHeight() - 70) / rowHeight)) -- Columns nearly as tall as the screen, so the list is as narrow as possible
								local col, row, mostRows = 0, 0, 0
								for i, scene in ipairs(scenes) do
									-- Start a new column when this one is full (a heading always has at least one entry under it)
									if row >= maxRows or (scene.header and row >= maxRows - 1) then col, row = col + 1, 0 end
									if scene.header then
										local text = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
										text:SetPoint("TOPLEFT", popup, "TOPLEFT", 14 + col * colWidth, -13 - row * rowHeight)
										text:SetText(scene.header)
									else
										local button = CreateFrame("Button", nil, popup)
										button:SetSize(colWidth - 8, rowHeight)
										button:SetPoint("TOPLEFT", popup, "TOPLEFT", 8 + col * colWidth, -10 - row * rowHeight)
										button.selected = button:CreateTexture(nil, "BACKGROUND")
										button.selected:SetAllPoints()
										button.selected:SetColorTexture(1, 1, 1, 0.12)
										button:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
										button:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.08)
										button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
										button.text:SetPoint("LEFT", button, "LEFT", 6, 0)
										button.text:SetPoint("RIGHT", button, "RIGHT", -4, 0)
										button.text:SetJustifyH("LEFT")
										button.text:SetWordWrap(false)
										button.text:SetText(scene.name)
										button.key = scene.key
										-- Pointing at a scene shows it straight away (pointing at Random shows another random loading screen)
										button:SetScript("OnEnter", function(self)
											if viewer.previewKey == self.key and self.key ~= "random" then return end
											viewer.previewKey = self.key
											if self.key == "random" then viewer.randomScene = nil end
											viewer:ApplyScene()
										end)
										-- Clicking keeps the scene being shown
										button:SetScript("OnClick", function(self)
											LeaPlusLC.IDViewerScene = self.key
											if LeaPlusDB then LeaPlusDB["IDViewerScene"] = self.key end
											popup.confirmed = true
											popup:Hide()
										end)
										tinsert(popup.rows, button)
									end
									row = row + 1
									mostRows = math.max(mostRows, row)
								end
								popup:SetSize((col + 1) * colWidth + 8, mostRows * rowHeight + 20)
								popup:SetPoint("TOPRIGHT", self, "TOPRIGHT", -10, -36) -- Far right, just under the buttons
								-- Like the game's own menus, the list stays open until something else is clicked (or Escape is pressed)
								popup:RegisterEvent("GLOBAL_MOUSE_DOWN")
								popup:SetScript("OnEvent", function(self, event)
									if event == "GLOBAL_MOUSE_DOWN" and self:IsShown() and not self:IsMouseOver() and not viewer.sceneBtn:IsMouseOver() then self:Hide() end
								end)
								-- Scenes only change while pointing at the list: moving the pointer off it puts the chosen scene back (until one is clicked)
								popup:SetScript("OnUpdate", function(self)
									if viewer.previewKey and not self:IsMouseOver() then
										viewer.previewKey = nil
										viewer.randomScene = self.randomBefore
										viewer:ApplyScene()
									end
								end)
								-- Closing the list keeps a clicked scene, otherwise goes back to the scene that was showing before
								popup:SetScript("OnHide", function()
									if not popup.confirmed then viewer.randomScene = popup.randomBefore end
									popup.confirmed, popup.randomBefore = nil, nil
									viewer.previewKey = nil
									viewer:ApplyScene()
								end)
							end
							for void, button in ipairs(popup.rows) do button.selected:SetShown(button.key == LeaPlusLC.IDViewerScene or (button.key == "random" and not sceneByKey[LeaPlusLC.IDViewerScene])) end
							popup.confirmed, popup.randomBefore = nil, self.randomScene -- Remember the random loading screen in case nothing is clicked
							self:ApplyLevels()
							popup:Show()
						end
						viewer:ApplyLevels()
						-- Fullscreen: the card waits off the screen, and pointing at the name shows it just under the name
						function viewer:HideCard()
							local card = LeaPlusLC.IDCard
							card:SetClampedToScreen(false) -- Otherwise the game pulls it back onto the screen (into the bottom-left corner)
							card:ClearAllPoints()
							card:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", -4000, -4000)
						end
						viewer.titleHover = CreateFrame("Frame", nil, viewer)
						viewer.titleHover:SetAllPoints(viewer.title)
						viewer.titleHover:EnableMouse(true)
						-- Highlight behind the name while pointing at it (fullscreen only, so it is clear the name shows the card)
						viewer.titleHover.highlight = viewer:CreateTexture(nil, "ARTWORK") -- On the viewer itself so it sits behind the name
						viewer.titleHover.highlight:SetPoint("TOPLEFT", viewer.titleHover, "TOPLEFT", -6, 4)
						viewer.titleHover.highlight:SetPoint("BOTTOMRIGHT", viewer.titleHover, "BOTTOMRIGHT", 6, -4)
						viewer.titleHover.highlight:SetColorTexture(1, 1, 1, 0.12)
						viewer.titleHover.highlight:Hide()
						-- The card shown from the name is for reading only: the buff list, close button, 3D model box, hints and clicks are all left out
						local function CardControls(card)
							return {card.close, card.modelCheck, card.modelCheck.label, card.hint, card.hint2, LeaPlusLC.AuraPicker}
						end
						local function PlainCard(card, plain)
							if plain then
								card.plainHidden = {}
								for i, control in ipairs(CardControls(card)) do
									if control and control:IsShown() then card.plainHidden[i] = true control:Hide() end
								end
							elseif card.plainHidden then
								for i, control in ipairs(CardControls(card)) do
									if control and card.plainHidden[i] then control:Show() end
								end
								card.plainHidden = nil
							end
							card:EnableMouse(not plain)
							card.edit:EnableMouse(not plain)
						end
						viewer.titleHover:SetScript("OnEnter", function()
							if not viewer.fullscreen or viewer.cardShowing then return end
							viewer.titleHover.highlight:Show()
							local card = LeaPlusLC.IDCard
							PlainCard(card, true)
							card:ClearAllPoints()
							card:SetPoint("TOPLEFT", viewer.title, "BOTTOMLEFT", 8, -20)
							card:SetClampedToScreen(true)
							SnapToPixels(card) -- Line up with screen pixels (the name is not on whole pixels, so thin borders such as the bottom of the sounds button could be lost)
							card:Raise()
							viewer.cardShowing, viewer.cardAway = true, 0
						end)
						-- The card goes as soon as the pointer leaves the name (and everything on it comes back for when fullscreen ends)
						function viewer:EndHoverCard()
							if not self.cardShowing then return end
							self.cardShowing = nil
							self.titleHover.highlight:Hide()
							PlainCard(LeaPlusLC.IDCard, false)
							if self.fullscreen then self:HideCard() end
						end
						-- The card stays while the pointer is over the name or the card, and goes a short moment after it leaves both
						viewer.titleHover:SetScript("OnUpdate", function(self, elapsed)
							if not viewer.cardShowing then return end
							if self:IsMouseOver() or LeaPlusLC.IDCard:IsMouseOver() then
								viewer.cardAway = 0
							else
								viewer.cardAway = viewer.cardAway + elapsed
								if viewer.cardAway > 0.3 then viewer:EndHoverCard() end
							end
						end)
						viewer:HookScript("OnHide", function(self) if self.fullscreen then self:SetFullscreen(false) end end)
						viewer:LayoutButtons()
						LeaPlusLC.IDViewer = viewer
					end
					-- Nothing changes on the model unless the viewer is showing (or being opened now)
					if not info.openViewer and not viewer:IsShown() then return end
					-- Do not change models more than about three times a second (pressing the key quickly loads the last one)
					local now = GetTime()
					if viewer.lastLoad and now - viewer.lastLoad < 0.35 then
						viewer.pendingInfo = info
						info.openViewer = true
						if not viewer.pendingTimer then
							viewer.pendingTimer = true
							C_Timer.After(0.35 - (now - viewer.lastLoad), function()
								viewer.pendingTimer = nil
								local pending = viewer.pendingInfo
								viewer.pendingInfo = nil
								if pending and LeaPlusLC.IDCard and LeaPlusLC.IDCard:IsShown() and LeaPlusLC.IDCard.info == pending then ShowViewer(pending) end
							end)
						end
						return
					end
					viewer.lastLoad = now
					-- Choose the model frames (NPCs and pets use the plain model, players and items use the two dressing room models)
					local useCreature = view.mode == "unit" and not view.isPlayer
					local models = useCreature and {viewer.creatureModel} or {viewer.dressModel, viewer.nakedModel}
					for void, other in ipairs(useCreature and {viewer.dressModel, viewer.nakedModel} or {viewer.creatureModel}) do
						other:Hide()
						other.loaded, other.onLoaded = false, nil
					end
					-- Find the unit again by its GUID (the mouse may have moved since the card was shown)
					local unit
					if view.mode == "unit" then
						if view.guid and issecretvalue and issecretvalue(view.guid) then view.guid = nil end
						-- Shown at the same moment as the card: use the card's own unit (searching again can fail for new characters)
						if view.fresh and view.unit and UnitExists(view.unit) then unit = view.unit end
						if not unit and view.guid then
							local tokens = {"mouseover", view.unit or "mouseover", "target", "focus", "targettarget", "pet", "party1", "party2", "party3", "party4"}
							for i = 1, 40 do tinsert(tokens, "nameplate" .. i) end
							if IsInRaid() then for i = 1, 40 do tinsert(tokens, "raid" .. i) end end
							for void, token in ipairs(tokens) do
								local tokenGUID = UnitExists(token) and UnitGUID(token)
								if tokenGUID and not (issecretvalue and issecretvalue(tokenGUID)) and tokenGUID == view.guid then unit = token break end
							end
						end
					end
					-- Show the viewer first, then load the model
					local r, g, b = unpack(info.color or {1, 0.82, 0})
					viewer:SetBackdropBorderColor(r, g, b, 0.55)
					viewer.gear:SetAccent(r, g, b)
					viewer.hint:SetAccent(r, g, b)
					viewer.accent = {r, g, b}
					viewer.title:SetText(info.name or "")
					if info.nameColor then viewer.title:SetTextColor(unpack(info.nameColor)) else viewer.title:SetTextColor(1, 1, 1) end
					viewer.flavourRaw = view.text or ""
					viewer.text:SetText(view.text or "")
					if info.offscreen ~= nil then viewer.offscreen = info.offscreen end
					viewer.slotRow:SetShown(not useCreature and viewer.dressModel.UndressSlot ~= nil) -- Gear slot buttons for players and items
					viewer:Show()
					do
						local text = view.text
						viewer.normalHeight = PixelRound(42 + 380 + 44 + (viewer.slotRow:IsShown() and 30 or 0) + ((text and text ~= "") and (viewer.text:GetStringHeight() + 14) or 0))
						if not viewer.fullscreen then viewer:SetHeight(viewer.normalHeight) end
					end
					AttachViewer()
					viewer:Layout()
					viewer.view = view
					viewer.gearOff = (view.mode == "item") -- Items are shown on your character with your own gear off
					viewer.gear:SetLabel(viewer.gearOff and L["Show gear"] or L["Hide gear"])
					viewer.gear:SetShown(not useCreature) -- NPCs and pets have no gear to change
					wipe(viewer.slotInfo) wipe(viewer.hiddenSlots) viewer:UpdateSlots() -- Filled in once the model has loaded
					viewer:LayoutButtons()
					viewer:RevealModel() -- Start from a shown model (it is hidden again below for players whose inspect is on the way)
					-- A player who cannot be found right now: wait until the mouse is over them again
					if view.mode == "unit" and not unit and not view.npcID and not view.displayID then
						viewer.waitGUID = view.guid or false
						viewer.waitName = info.name
						for void, m in ipairs({viewer.dressModel, viewer.nakedModel, viewer.creatureModel}) do m:Hide() m.loaded = false end
						viewer.hint:Hide()
						viewer.gear:Hide()
						viewer.waitText:SetFormattedText(L["Move your mouse over %s to show their model."], info.name or "")
						viewer.waitText:Show()
						-- Also check a few times a second, as the game can be slow to register the character under the mouse
						if not viewer.waitTicker then
							viewer.waitTicker = C_Timer.NewTicker(0.2, function(ticker)
								if not viewer:IsShown() or viewer.waitGUID == nil then ticker:Cancel() viewer.waitTicker = nil return end
								viewer:CheckWaiting()
							end)
						end
						return
					end
					-- Cannot be seen (too far away, offline and so on): do not load a model (it can make the game pause), just say so
					if view.mode == "unit" and unit and not Safe(UnitIsVisible(unit)) then
						viewer.waitGUID = nil
						for void, m in ipairs({viewer.dressModel, viewer.nakedModel, viewer.creatureModel}) do m:Hide() m.loaded = false end
						viewer.hint:Hide()
						viewer.gear:Hide()
						viewer.waitText:SetFormattedText(L["No model is available for %s right now."], info.name or "")
						viewer.waitText:Show()
						return
					end
					viewer.waitGUID = nil
					viewer.waitText:Hide()
					viewer.hint:Show()
					if view.mode == "unit" and view.isPlayer and unit and view.guid and not Safe(UnitIsUnit(unit, "player")) then viewer:HoldModel(view.guid) end
					viewer.loadID = (viewer.loadID or 0) + 1 -- Changes from an earlier model are ignored
					local loadID = viewer.loadID
					viewer.lastAnim = nil
					-- The model shown first (items start with your gear off)
					local active = useCreature and viewer.creatureModel or (viewer.gearOff and viewer.nakedModel or viewer.dressModel)
					viewer.model = active
					for void, model in ipairs(models) do
						model.loaded, model.onLoaded = false, nil
						model.facing, model.zoom, model.zoomTarget, model.turning, model.panX, model.panY, model.offsetY, model.offsetZ = 0, 0, 0, nil, nil, nil, 0, 0
						model.pitch, model.freeX, model.freeY = 0, nil, nil
						local function Finish()
							if not model:IsVisible() or viewer.loadID ~= loadID then return end
							model:SetFacing(0)
							if model.SetPitch then model:SetPitch(0) end
							model:SetPosition(0, 0, 0)
							if model == viewer.nakedModel and model.Undress then model:Undress() end
							if view.mode == "item" and view.link then model:TryOn(view.link) end
							if view.mode == "item" and view.links then for void, link in ipairs(view.links) do model:TryOn(link) end end -- Appearance sets (every piece of the set)
							-- Both dressing room models are loaded while showing (safest), then the one not in use is hidden
							if model == viewer.dressModel then
								viewer:ReadSlots(model, (view.mode == "unit" and unit) or "player")
								if view.mode == "unit" and not next(viewer.slotInfo) then viewer:RetrySlots(model, unit, loadID) end
								viewer:ApplyInspectGear()
								viewer:CheckReveal()
							end
							if model ~= viewer.model then model:Hide() end
						end
						model:Show()
						if view.mode == "unit" and unit then
							model:SetUnit(unit)
						elseif view.mode == "unit" and view.displayID then
							model:SetDisplayInfo(view.displayID) -- Display ID (such as Leatrix Maps boss icons, works for creatures not seen yet)
						elseif view.mode == "unit" then
							model:SetCreature(tonumber(view.npcID))
						else
							model:SetUnit("player")
						end
						model:WhenLoaded(Finish)
					end
					viewer.anim:SetValue(1)
				end
				-- ID card: shows the icon, name, ID and Wowhead link for what is under the mouse
				local function ShowIDCard(info)
					-- Leave out anything the game hides, so the card never shows or measures a hidden value
					info.name, info.sub, info.note, info.id, info.url, info.icon, info.unit = Safe(info.name, info.sub, info.note, info.id, info.url, info.icon, info.unit)
					if info.view then
						local view = info.view
						view.text, view.icon, view.link, view.guid, view.npcID, view.unit = Safe(view.text, view.icon, view.link, view.guid, view.npcID, view.unit)
					end
					local card = LeaPlusLC.IDCard
					if not card then
						card = CreateFrame("Frame", "LeaPlusGlobalInfoCard", UIParent, "BackdropTemplate")
						card:Hide()
						-- Escape closes the card (the game closes it like other windows, so no key is ever kept from the game)
						table.insert(UISpecialFrames, "LeaPlusGlobalInfoCard")
						card:SetSize(480, 140)
						card:SetPoint("TOP", UIParent, "BOTTOM", 0, UIParent:GetHeight() * 0.28) -- Lower part of the screen, above the action bars
						SnapToPixels(card)
						card:SetFrameStrata("FULLSCREEN_DIALOG")
						card:SetFrameLevel(5000)
						card:SetClampedToScreen(true)
						card:EnableMouse(true)
						card:SetScript("OnMouseDown", function(self, btn) if btn == "RightButton" then self:Hide() end end)
						card:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = OnePixel()})
						card:SetBackdropColor(0.06, 0.06, 0.08, 0.96)
						-- Soft glow along the top in the accent colour
						card.glow = card:CreateTexture(nil, "BORDER")
						card.glow:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -1)
						card.glow:SetPoint("TOPRIGHT", card, "TOPRIGHT", -1, -1)
						card.glow:SetHeight(70)
						card.glow:SetTexture("Interface\\Buttons\\WHITE8X8")
						-- Icon with a thin accent border
						card.iconBorder = card:CreateTexture(nil, "ARTWORK")
						card.iconBorder:SetSize(58, 58)
						card.iconBorder:SetPoint("TOPLEFT", card, "TOPLEFT", 20, -16)
						card.icon = card:CreateTexture(nil, "OVERLAY")
						card.icon:SetPoint("TOPLEFT", card.iconBorder, "TOPLEFT", 2, -2)
						card.icon:SetPoint("BOTTOMRIGHT", card.iconBorder, "BOTTOMRIGHT", -2, 2)
						-- 3D portrait for players and NPCs (a plain model framed on the face, over the flat portrait)
						card.portraitBg = card:CreateTexture(nil, "ARTWORK", nil, 2) -- Dark backdrop behind the 3D portrait (instead of the round flat portrait)
						card.portraitBg:SetAllPoints(card.icon)
						card.portraitBg:SetTexture("Interface\\Buttons\\WHITE8X8")
						card.portraitBg:SetGradient("VERTICAL", CreateColor(0.03, 0.03, 0.04, 1), CreateColor(0.14, 0.14, 0.17, 1))
						card.portraitBg:Hide()
						card.portrait = CreateFrame("PlayerModel", nil, card)
						card.portrait:SetAllPoints(card.icon)
						card.portrait:Hide()
						card.portrait:SetScript("OnModelLoaded", function(self)
							local id = self.loadID
							-- Frame the face on the next frame (never in the middle of loading)
							C_Timer.After(0, function()
								if self.loadID == id and self:IsVisible() then
									self:SetPortraitZoom(1)
									self:SetPosition(0, 0, 0)
									self:SetFacing(0)
								end
							end)
						end)
						-- Type (top right), name and details
						card.kind = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
						card.kind:SetPoint("TOPRIGHT", card, "TOPRIGHT", -36, -16)
						card.title = card:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
						card.title:SetPoint("TOPLEFT", card.iconBorder, "TOPRIGHT", 14, -4)
						card.title:SetPoint("RIGHT", card.kind, "LEFT", -10, 0)
						card.title:SetJustifyH("LEFT")
						card.title:SetWordWrap(false)
						card.sub = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
						card.sub:SetPoint("TOPLEFT", card.title, "BOTTOMLEFT", 0, -8)
						card.sub:SetPoint("RIGHT", card, "RIGHT", -16, 0)
						card.sub:SetJustifyH("LEFT")
						card.sub:SetWordWrap(false)
						card.sub:SetTextColor(0.62, 0.62, 0.66)
						-- Details line (guild, item level, sell price, rewards and so on), it can wrap onto more lines
						card.detail = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
						card.detail:SetPoint("TOPLEFT", card.sub, "BOTTOMLEFT", 0, -6)
						card.detail:SetWidth(372)
						card.detail:SetJustifyH("LEFT")
						card.detail:SetWordWrap(true)
						card.detail:SetTextColor(0.78, 0.78, 0.82)
						card.talents = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
						card.talents:SetWidth(372)
						card.talents:SetJustifyH("LEFT")
						card.talents:SetWordWrap(false)
						-- Add a part to the details line (parts that arrive later, such as item level from an inspect, are added too)
						function card:AddDetail(text)
							if not text or text == "" then return end
							tinsert(self.detailParts, text)
							self.detail:SetText(table.concat(self.detailParts, "    "))
							self:Relayout()
						end
						-- Item level for other players has its own place in the details, so a waiting message can be shown there and replaced
						-- once the item level is read (nil removes it)
						function card:SetItemLevelDetail(text)
							if text == "" then text = nil end
							local index = self.itemLevelPart
							if index and self.detailParts[index] then
								if text then self.detailParts[index] = text else tremove(self.detailParts, index) self.itemLevelPart = nil end
							elseif text then
								tinsert(self.detailParts, text)
								self.itemLevelPart = #self.detailParts
							else
								return
							end
							self.detail:SetText(table.concat(self.detailParts, "    "))
							self:Relayout()
						end
						-- Place the lines, the link box and set the card height to fit the text
						-- Make the card wider when the bottom row (3D model checkbox, copy hint, sounds button and right-click hint) does not fit, such as in some languages
						-- (measured with the longest text each hint can show, so the card does not change width when a hint message shows)
						function card:FitWidth()
							if not self.measure then self.measure = self:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall") self.measure:Hide() end
							local function TextWidth(...)
								local w = 0
								for i = 1, select("#", ...) do self.measure:SetText(select(i, ...)) w = math.max(w, self.measure:GetStringWidth() or 0) end
								return w
							end
							local left = 22 -- (based on what the card has, not what is showing, as some of it is hidden on the card shown from the name in fullscreen)
							if self.info and self.info.view then left = left + 11 + 6 + (self.modelCheck.label:GetStringWidth() or 0) + 18 end
							if self.url then left = left + TextWidth(L["Press CTRL/C to copy"], L["Copied to clipboard."]) end
							local right = 18 + (self.sounds:IsShown() and (TextWidth(L["Right-click to close"], L["Requires Leatrix Sounds"]) + 14 + self.sounds:GetWidth()) or TextWidth(L["Right-click to close"]))
							self:SetWidth(PixelRound(math.max(480, left + 20 + right)))
						end
						function card:Relayout()
							local hasDetail = #self.detailParts > 0
							self.detail:SetShown(hasDetail)
							self.talents:ClearAllPoints()
							self.talents:SetPoint("TOPLEFT", hasDetail and self.detail or self.sub, "BOTTOMLEFT", 0, -6)
							self.talents:SetShown(self.talentsReserved)
							local textBottom = 20 + (self.title:GetStringHeight() or 20) + 8 + (self.sub:GetStringHeight() or 12)
							if hasDetail then textBottom = textBottom + 6 + (self.detail:GetStringHeight() or 12) end
							if self.talentsReserved then textBottom = textBottom + 6 + math.max(10, self.talents:GetStringHeight() or 10) end
							local contentBottom = math.max(74, textBottom)
							self.box:ClearAllPoints()
							self.box:SetPoint("TOPLEFT", self, "TOPLEFT", 20, -(contentBottom + 14))
							self.box:SetPoint("RIGHT", self, "RIGHT", -16, 0)
							self:SetHeight(PixelRound(self.url and (contentBottom + 14 + 28 + 24) or (contentBottom + 26)))
						end
						-- Close button
						card.close = FlatButton(card, 22, 22, "X")
						card.close:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -10)
						card.close:SetScript("OnClick", function() card:Hide() end)
						-- Link box
						card.box = CreateFrame("Frame", nil, card, "BackdropTemplate")
						card.box:SetPoint("TOPLEFT", card, "TOPLEFT", 20, -88)
						card.box:SetPoint("RIGHT", card, "RIGHT", -16, 0)
						card.box:SetHeight(28)
						card.box:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = OnePixel()})
						card.box:SetBackdropColor(0, 0, 0, 0.6)
						card.box:SetBackdropBorderColor(1, 1, 1, 0.12)
						card.edit = CreateFrame("EditBox", nil, card.box)
						card.edit:SetPoint("TOPLEFT", card.box, "TOPLEFT", 10, 0)
						card.edit:SetPoint("BOTTOMRIGHT", card.box, "BOTTOMRIGHT", -10, 0)
						card.edit:SetFontObject("ChatFontNormal")
						card.edit:SetTextColor(0.82, 0.88, 1)
						card.edit:SetAutoFocus(false)
						card.edit:SetAltArrowKeyMode(true)
						if card.edit.SetHighlightColor then card.edit:SetHighlightColor(0, 0, 0, 0) end -- The link is selected (so CTRL/C copies it) but the selection is not shown
						-- The link box's own text (and its blinking cursor) is pushed out of sight, and the link is shown as plain text instead
						card.edit:SetTextInsets(5000, 0, 0, 0)
						card.edit:SetTextColor(0, 0, 0, 0)
						card.urlText = card.box:CreateFontString(nil, "OVERLAY", "ChatFontNormal")
						card.urlText:SetPoint("LEFT", card.box, "LEFT", 10, 0)
						card.urlText:SetPoint("RIGHT", card.box, "RIGHT", -10, 0)
						card.urlText:SetJustifyH("LEFT")
						card.urlText:SetWordWrap(false)
						card.urlText:SetTextColor(0.82, 0.88, 1)
						-- Hints
						card.hint = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
						card.hint:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 22, 10) -- Same level as the right-click hint
						-- Checkbox to show or hide the model viewer (only shown for things with a 3D model, the choice is saved)
						card.modelCheck = CreateFrame("Button", nil, card, "BackdropTemplate")
						card.modelCheck:SetSize(PixelRound(11), PixelRound(11))
						card.modelCheck:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 22, 11)
						card.modelCheck:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = OnePixel()})
						card.modelCheck:SetBackdropColor(0, 0, 0, 0.6)
						card.modelCheck.tick = card.modelCheck:CreateTexture(nil, "OVERLAY")
						card.modelCheck.tick:SetPoint("TOPLEFT", card.modelCheck, "TOPLEFT", PixelRound(2), -PixelRound(2))
						card.modelCheck:SetHitRectInsets(-2, -80, -4, -4) -- The label can be clicked too
						card.modelCheck.tick:SetPoint("BOTTOMRIGHT", card.modelCheck, "BOTTOMRIGHT", -PixelRound(2), PixelRound(2))
						card.modelCheck.label = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
						card.modelCheck.label:SetPoint("LEFT", card.modelCheck, "RIGHT", 6, 0)
						card.modelCheck.label:SetText(L["3D model"])
						function card.modelCheck:Update()
							local on = LeaPlusLC.IDModelOn
							self.tick:SetShown(on)
							self.label:SetTextColor(on and 0.85 or 0.5, on and 0.85 or 0.5, on and 0.85 or 0.5)
						end
						card.modelCheck:SetScript("OnEnter", function(self) self.label:SetTextColor(1, 1, 1) end)
						card.modelCheck:SetScript("OnLeave", function(self) self:Update() end)
						card.modelCheck:SetScript("OnClick", function(self)
							LeaPlusLC.IDModelOn = not LeaPlusLC.IDModelOn
							if LeaPlusDB then LeaPlusDB["IDModelOn"] = LeaPlusLC.IDModelOn end
							self:Update()
							local viewer = LeaPlusLC.IDViewer
							if card.info then card.info.offscreen = not LeaPlusLC.IDModelOn end
							if viewer and viewer:IsShown() then
								-- Already loaded, so just move it on or off the screen
								viewer.offscreen = not LeaPlusLC.IDModelOn
								AttachViewer()
							elseif LeaPlusLC.IDModelOn and card.info and card.info.view then
								card.info.openViewer = true
								ShowViewer(card.info)
								card.info.openViewer = nil
							end
						end)
						card.hint2 = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
						card.hint2:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -18, 10)
						card.hint2:SetText(L["Right-click to close"])
						-- Sounds button (shows the sounds for what is on the card in Leatrix Sounds, or says Leatrix Sounds is needed if it is not loaded)
						card.sounds = FlatButton(card, 60, 16, L["Sounds"])
						card.sounds:SetWidth(PixelRound(math.max(60, card.sounds.label:GetStringWidth() + 20)))
						card.sounds:SetPoint("RIGHT", card.hint2, "LEFT", -14, 0)
						card.sounds:Hide()
						card.sounds:SetScript("OnClick", function()
							local open = card.soundsOpen
							if not open then
								-- Leatrix Sounds is not installed or not enabled, so say so for a few seconds where the right-click hint is
								card.soundsMsgID = (card.soundsMsgID or 0) + 1
								local id = card.soundsMsgID
								card.hint2:SetText("|cffffd800" .. L["Requires Leatrix Sounds"] .. "|r")
								card.hint2:Show() -- The hint is hidden on the card shown from the name in fullscreen, so show it for the message
								C_Timer.After(3, function()
									if card.soundsMsgID == id then
										card.hint2:SetText(L["Right-click to close"])
										if card.plainHidden then card.hint2:Hide() end -- Hidden again if the card is still the fullscreen one
									end
								end)
								return
							end
							card:Hide() -- The Leatrix Sounds panel opens instead (the card would be in front of it)
							open()
						end)
						-- Keep the link unchanged and selected (CTRL/C copies it and closes the card)
						local function Reselect() card.edit:SetText(card.url or "") card.edit:HighlightText() end
						card.edit:SetScript("OnChar", Reselect)
						-- Put the link straight back if anything changes it (such as CTRL/X cutting it or pasting over it)
						card.edit:SetScript("OnTextChanged", function(self, userInput)
							if userInput and self:GetText() ~= (card.url or "") then Reselect() end
						end)
						local function IsCtrlKey(key) return key == "LCTRL" or key == "RCTRL" or key == "LMETA" or key == "RMETA" end
						card.edit:SetScript("OnKeyUp", function(self, key)
							Reselect()
							-- Letting go of Ctrl gives the keyboard back to the game (when Leatrix is watching for Ctrl)
							if card.ctrlFocus and IsCtrlKey(key) then card.ctrlFocus = nil self:ClearFocus() end
						end)
						-- Holding Ctrl gives the link box the keyboard so CTRL/C copies the link (the Ctrl watcher is made when Leatrix Plus loads)
						-- Clicking the link box does not take the keyboard (only holding Ctrl does), so the character can still be moved
						card.edit:SetScript("OnEditFocusGained", function(self)
							if not card.ctrlFocus then self:ClearFocus() end
						end)
						card.edit:SetScript("OnMouseUp", function(self) self:HighlightText() end)
						card.edit:SetScript("OnEnterPressed", function(self) self:HighlightText() end)
						card.edit:SetScript("OnEscapePressed", function() local viewer = LeaPlusLC.IDViewer if viewer and viewer.scenePopup and viewer.scenePopup:IsShown() then viewer.scenePopup:Hide() elseif viewer and viewer.fullscreen then viewer:SetFullscreen(false) else card:Hide() end end)
						card.edit:SetScript("OnKeyDown", function(self, key)
							if key == "C" and (IsControlKeyDown() or IsMetaKeyDown()) then
								card.hint:SetText("|cff40ff40" .. L["Copied to clipboard."] .. "|r")
								C_Timer.After(0.4, function() card:Hide() end)
								return
							end
							-- The link box has the keyboard, so pass the info card key binding through (shows whatever is now under the mouse)
							local combo = (IsAltKeyDown() and "ALT-" or "") .. (IsControlKeyDown() and "CTRL-" or "") .. (IsShiftKeyDown() and "SHIFT-" or "") .. ((IsMetaKeyDown and IsMetaKeyDown()) and "META-" or "") .. key
							if LeaPlusLC["ShowInfoCards"] == "On" and LeaPlusLC["InfoCardKey"] ~= "" and combo == LeaPlusLC["InfoCardKey"] then
								ShowInfoCard()
								-- Ctrl is still held, so the link box keeps the keyboard (for the new card, or the old one if no new card was shown such as pointing at a mailbox)
								-- Letting go of Ctrl gives it back to the game as usual
								return
							end
							-- Any other key (not Ctrl itself) gives the keyboard back so the next press reaches the game
							if card.ctrlFocus and not IsCtrlKey(key) and key ~= "LSHIFT" and key ~= "RSHIFT" and key ~= "LALT" and key ~= "RALT" then
								card.ctrlFocus = nil
								self:ClearFocus()
							end
						end)
						-- Fade in
						card.fade = card:CreateAnimationGroup()
						local fadeIn = card.fade:CreateAnimation("Alpha")
						fadeIn:SetFromAlpha(0)
						fadeIn:SetToAlpha(1)
						fadeIn:SetDuration(0.15)
						card:SetScript("OnShow", function() card.fade:Play() end)
						-- The link box only keeps the keyboard while Ctrl is held (letting go of Ctrl is not always seen by the link box, so check every frame)
						card:SetScript("OnUpdate", function(self)
							if not self.ctrlFocus then return end
							-- (Ctrl is not checked for a moment after the card is shown, as the game can report it as not held while the key is being handled)
							local ctrlHeld = IsControlKeyDown() or (IsMetaKeyDown and IsMetaKeyDown()) or (GetTime() - (self.ctrlFocusTime or 0) < 0.2)
							if not ctrlHeld or not self.url or not self.edit:IsShown() then
								self.ctrlFocus = nil
								if self.edit:HasFocus() then self.edit:ClearFocus() end
							elseif not self.edit:HasFocus() then
								-- Ctrl is still held but the link box does not have the keyboard (such as when it could not be given while the info card key was being handled), so give it now
								self.edit:SetFocus()
								self.edit:HighlightText()
							end
						end)
						-- Closing the card always gives the keyboard back to the game
						card:SetScript("OnHide", function(self)
							local viewer = LeaPlusLC.IDViewer
							if viewer and viewer.fullscreen then viewer:SetFullscreen(false) end -- The viewer is not inside the card in fullscreen, so end fullscreen with the card
							self.ctrlFocus = nil
							if self.edit:HasFocus() then self.edit:ClearFocus() end
						end)
						LeaPlusLC.IDCard = card
					end
					-- Back to the normal lines (a card for a hidden aura uses its own lines, see ShowHiddenAuraCard)
					card.hiddenMode = nil
					card.title:Show()
					card.sub:Show()
					card.urlText:Show()
					card.edit:Show()
					if card.hiddenTitle then
						card.hiddenTitle:Hide()
						card.hiddenSub:Hide()
						card.hiddenUrlText:Hide()
					end
					-- Accent colour
					local r, g, b = unpack(info.color or {1, 0.82, 0})
					card.iconBorder:SetColorTexture(r, g, b, 0.9)
					card:SetBackdropBorderColor(r, g, b, 0.55)
					card.glow:SetVertexColor(1, 1, 1, 1)
					card.glow:SetGradient("VERTICAL", CreateColor(r, g, b, 0), CreateColor(r, g, b, 0.16))
					-- Icon or portrait
					card.icon:SetTexture(nil)
					-- (round portraits and class icons are cropped to the square inside the circle, to match the square 3D portrait)
					local function InnerSquare(left, right, top, bottom)
						local w, h = right - left, bottom - top
						return left + w * 0.15, right - w * 0.15, top + h * 0.15, bottom - h * 0.15
					end
					if info.unit and UnitExists(info.unit) then
						SetPortraitTexture(card.icon, info.unit)
						card.icon:SetTexCoord(InnerSquare(0, 1, 0, 1))
					elseif info.icon == "Interface\\TargetingFrame\\UI-Classes-Circles" and info.iconCoords then
						card.icon:SetTexture(info.icon)
						card.icon:SetTexCoord(InnerSquare(unpack(info.iconCoords)))
					else
						card.icon:SetTexture(info.icon or 134400)
						card.icon:SetTexCoord(unpack(info.iconCoords or {0.08, 0.92, 0.08, 0.92}))
					end
					-- Text
					card.kind:SetText(strupper(info.kind or ""))
					card.kind:SetTextColor(r, g, b)
					card.title:SetText(info.name or "")
					if info.nameColor then card.title:SetTextColor(unpack(info.nameColor)) else card.title:SetTextColor(1, 1, 1) end
					card.sub:SetText(info.sub or (L["ID"] .. " |cffffffff" .. tostring(info.id or "") .. "|r" .. (info.note and ("    " .. info.note) or "")))
					card.hint:SetText(L["Press CTRL/C to copy"])
					card.talents:SetText("")
					card.talentsReadID = (card.talentsReadID or 0) + 1 -- Stops talent reads for an earlier card from changing this one
					card.talentsReserved = info.talents and true or false
					card.detailParts = {}
					card.itemLevelPart = nil
					card.gearReadingGUID = nil
					LeaPlusLC.IDTalentWait = nil -- A reply kept for the last player is no longer needed
					card.detail:SetText("")
					for void, part in ipairs(info.details or {}) do if part and not IsSecret(part) and part ~= "" then tinsert(card.detailParts, part) end end
					card.detail:SetText(table.concat(card.detailParts, "    "))
					card.inspectGUID = nil
					-- Model viewer (only for things that can be shown as a 3D model, kept up to date while it is open)
					if info.view and info.view.mode == "icon" then info.view = nil end
					card.info = info
					card.close:SetAccent(r, g, b)
					-- Link (some cards, such as players on Forever, have no link)
					card.url = info.url
					card.edit:SetText(info.url or "")
					card.urlText:SetText(info.url or "")
					card.box:SetShown(info.url ~= nil)
					card.hint:SetShown(info.url ~= nil)
					-- Model viewer checkbox (the copy hint moves along to make room for it)
					card.modelCheck:SetShown(info.view ~= nil)
					card.modelCheck.label:SetShown(info.view ~= nil)
					card.modelCheck:SetBackdropBorderColor(r, g, b, 0.8)
					card.modelCheck.tick:SetColorTexture(r, g, b, 1)
					card.modelCheck:Update()
					card.hint:ClearAllPoints()
					if info.view then
						card.hint:SetPoint("LEFT", card.modelCheck.label, "RIGHT", 18, 0)
					else
						card.hint:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 22, 10)
					end
					-- (a new card puts back the right-click hint, in case the Leatrix Sounds message is showing)
					card.soundsMsgID = (card.soundsMsgID or 0) + 1
					card.hint2:SetText(L["Right-click to close"])
					card.hint2:Show()
					-- Sounds button: Leatrix Sounds reads what it needs now (while the mouse is still over it) and gives back what to run when the button is clicked
					-- (nothing if it has no sounds for this or the game is hiding the details, and the button is hidden then)
					-- If Leatrix Sounds is not loaded, the button is still shown for anything that can have sounds, and clicking it says Leatrix Sounds is needed
					local soundsLoaded = C_AddOns.IsAddOnLoaded("Leatrix_Sounds")
					card.soundsOpen = info.sounds and soundsLoaded and LeaSoundsGlobalGetSounds and LeaSoundsGlobalGetSounds(info.sounds) or nil
					card.sounds:SetAccent(r, g, b)
					card.sounds:SetShown(card.soundsOpen ~= nil or (info.sounds ~= nil and not soundsLoaded))
					card:Relayout()
					card:FitWidth()
					card:Show()
					if not card.snapped then card.snapped = true SnapToPixels(card) end -- Line up with screen pixels when first shown
					-- 3D portrait (loaded now the card is showing, for players and NPCs)
					local portrait = card.portrait
					portrait.loadID = (portrait.loadID or 0) + 1
					-- (only for characters you can see: loading a model for someone far away can make the game pause)
					if info.unit and UnitExists(info.unit) and Safe(UnitIsVisible(info.unit)) and not (info.iconCoords) then
						portrait:Show()
						portrait:SetUnit(info.unit)
					elseif info.view and info.view.displayID and not info.view.isPlayer then
						portrait:Show()
						portrait:SetDisplayInfo(info.view.displayID)
					elseif info.view and info.view.npcID and not info.view.isPlayer then
						portrait:Show()
						portrait:SetCreature(tonumber(info.view.npcID))
					else
						portrait:Hide()
					end
					-- With a 3D portrait, show a plain dark backdrop instead of the round flat portrait underneath
					card.icon:SetShown(not portrait:IsShown())
					card.portraitBg:SetShown(portrait:IsShown())
					if portrait:IsShown() then
						-- In case the loaded event does not fire (such as a model that was already loaded)
						local id = portrait.loadID
						C_Timer.After(0.3, function()
							if portrait.loadID == id and portrait:IsVisible() then
								portrait:SetPortraitZoom(1)
								portrait:SetPosition(0, 0, 0)
								portrait:SetFacing(0)
							end
						end)
					end
					-- Update the model viewer now the card is showing
					local viewer = LeaPlusLC.IDViewer
					if info.view then
						-- Things with a 3D model open the model viewer, loaded now while the mouse is still over them
						-- (off the screen when the 3D model box is unticked, so ticking it shows the model straight away)
						info.offscreen = not LeaPlusLC.IDModelOn
						info.openViewer = true
						info.view.fresh = true
						ShowViewer(info)
						info.view.fresh = nil
						info.openViewer = nil
					elseif viewer and viewer:IsShown() then
						viewer:Hide()
					end
					card:Raise()
					-- The keyboard stays with the game (holding Ctrl gives it to the link box)
					-- If Ctrl is already held (such as from pressing CTRL/A to show the card), give the link box the keyboard now so CTRL/C works straight away
					-- (otherwise the Ctrl watcher only sees Ctrl again when key repeat sends it, which is a short delay)
					-- (while the info card key is being handled the game reports Ctrl as not held, so the key itself is checked too)
					if card.url and (IsControlKeyDown() or (IsMetaKeyDown and IsMetaKeyDown()) or LeaPlusLC.IDKeyHasCtrl) then
						card.ctrlFocus = true
						card.ctrlFocusTime = GetTime()
						card.edit:SetFocus()
					else
						card.ctrlFocus = nil
						card.edit:ClearFocus()
					end
					card.edit:HighlightText()
				end
				-- Card for a buff or debuff the game has hidden from addons (such as in combat or a PvP match)
				-- The hidden name, ID and link are never read, only passed straight to the game to show them. They use their own lines,
				-- as anything that has shown a hidden value stays hidden (and the normal lines are measured for the layout).
				-- The link cannot be copied, as the game does not let a link box show a hidden value.
				local function ShowHiddenAuraCard(auraID, auraName)
					-- Set up the card as normal with blank lines (these set the layout), then show the hidden values over them
					ShowIDCard({kind = L["Aura"], name = " ", sub = " ", url = " ", icon = 134400, color = {0.6, 0.6, 0.65}})
					local card = LeaPlusLC.IDCard
					if not card.hiddenTitle then
						card.hiddenTitle = card:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
						card.hiddenTitle:SetPoint("TOPLEFT", card.title, "TOPLEFT", 0, 0)
						card.hiddenTitle:SetPoint("RIGHT", card.title, "RIGHT", 0, 0)
						card.hiddenTitle:SetJustifyH("LEFT")
						card.hiddenTitle:SetWordWrap(false)
						card.hiddenTitle:SetTextColor(1, 1, 1)
						card.hiddenSub = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
						card.hiddenSub:SetPoint("TOPLEFT", card.sub, "TOPLEFT", 0, 0)
						card.hiddenSub:SetPoint("RIGHT", card.sub, "RIGHT", 0, 0)
						card.hiddenSub:SetJustifyH("LEFT")
						card.hiddenSub:SetWordWrap(false)
						card.hiddenSub:SetTextColor(0.62, 0.62, 0.66)
						card.hiddenUrlText = card.box:CreateFontString(nil, "OVERLAY", "ChatFontNormal")
						card.hiddenUrlText:SetPoint("LEFT", card.urlText, "LEFT", 0, 0)
						card.hiddenUrlText:SetPoint("RIGHT", card.urlText, "RIGHT", 0, 0)
						card.hiddenUrlText:SetJustifyH("LEFT")
						card.hiddenUrlText:SetWordWrap(false)
						card.hiddenUrlText:SetTextColor(0.82, 0.88, 1)
					end
					-- Show the hidden values in place of the normal lines
					card.hiddenMode = true
					card.title:Hide()
					card.sub:Hide()
					card.urlText:Hide()
					card.edit:ClearFocus()
					card.edit:Hide()
					card.url = nil -- Nothing to copy (holding Ctrl does nothing)
					card.hint:SetText(L["The link cannot be copied right now"])
					card.hiddenTitle:SetText(auraName or "")
					card.hiddenSub:SetText(L["ID"] .. " |cffffffff" .. auraID .. "|r    |cff8a8a90" .. L["Details are hidden right now"] .. "|r")
					card.hiddenUrlText:SetText("https://" .. LeaPlusLC.WowheadLock .. "/spell=" .. auraID)
					card.hiddenTitle:Show()
					card.hiddenSub:Show()
					card.hiddenUrlText:Show()
				end
				local function SpellIcon(spellID)
					return (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID)) or (GetSpellTexture and GetSpellTexture(spellID))
				end
				-- Flavour text helpers for the model viewer
				local function SpellText(spellID)
					local text = Safe((C_Spell and C_Spell.GetSpellDescription and C_Spell.GetSpellDescription(spellID)) or (GetSpellDescription and GetSpellDescription(spellID)))
					if type(text) == "string" and text ~= "" then return text end
				end
				local function TooltipLines(tooltip)
					local lines = {}
					local name = tooltip and tooltip.GetName and tooltip:GetName()
					if not name then return lines end
					for i = 1, tooltip:NumLines() do
						local line = _G[name .. "TextLeft" .. i]
						local text = line and line:GetText()
						text = Safe(text)
						if type(text) == "string" then tinsert(lines, (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))) end
					end
					return lines
				end
				local function ItemFlavour(tooltip)
					for void, text in ipairs(TooltipLines(tooltip)) do
						if text:find('^"') then return text end -- Flavour text is the quoted line
					end
				end
				local function NPCText(tooltip)
					local parts = {}
					local lines = TooltipLines(tooltip)
					if lines[2] and lines[2]:find("^<") then tinsert(parts, lines[2]) end -- Title such as <Innkeeper>
					local creatureType = Safe(UnitCreatureType("mouseover"))
					if type(creatureType) == "string" then tinsert(parts, creatureType) end
					if #parts > 0 then return table.concat(parts, "\n") end
				end
				local function PlayerText(unit)
					local parts = {}
					local guildName = Safe(GetGuildInfo(unit))
					if type(guildName) == "string" then tinsert(parts, "<" .. guildName .. ">") end
					local race = Safe(UnitRace(unit))
					if type(race) == "string" then tinsert(parts, race .. " " .. (Safe(UnitClass(unit)) or "")) end
					if #parts > 0 then return table.concat(parts, "\n") end
				end
				local function QuestText(questID)
					local objectives = SafeTable(C_QuestLog.GetQuestObjectives(questID))
					if not objectives then return end
					local parts = {}
					for void, objective in ipairs(objectives) do
						local text = SafeTable(objective) and Safe(objective.text)
						if type(text) == "string" and text ~= "" then tinsert(parts, text) end
					end
					if #parts > 0 then return table.concat(parts, "\n") end
				end
				-- Items that show on a character (only these open the model viewer)
				local hiddenSlots = {INVTYPE_AMMO = true, INVTYPE_FINGER = true, INVTYPE_NECK = true, INVTYPE_TRINKET = true, INVTYPE_RELIC = true, INVTYPE_BAG = true, INVTYPE_QUIVER = true, INVTYPE_NON_EQUIP = true, INVTYPE_NON_EQUIP_IGNORE = true, [""] = true}
				local function IsEquippable(itemLink)
					local dressable = (C_Item and C_Item.IsDressableItemByID) or IsDressableItem
					if dressable then
						local result = Safe(dressable(itemLink))
						if result ~= nil then return result end
					end
					local check = (C_Item and C_Item.IsEquippableItem) or IsEquippableItem
					if not (check and Safe(check(itemLink))) then return false end
					local GetInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
					local equipLoc = GetInfoInstant and Safe(select(4, GetInfoInstant(itemLink)))
					return equipLoc ~= nil and not hiddenSlots[equipLoc]
				end
				local colorBuff, colorDebuff, colorSpell, colorQuest = {0.3, 0.9, 0.4}, {1, 0.35, 0.35}, {0.35, 0.65, 1}, {1, 0.82, 0}
				-- Forever uses surnames where other games use realm names (Forever is interface version 1.6x)
				local tocVersion = select(4, GetBuildInfo()) or 0
				local isForever = tocVersion >= 16000 and tocVersion < 20000
				-- Talent tree names for each class, left to right (Forever has one spec per class, so the game does not name the trees)
				local talentTreeNames = {
					WARRIOR = {L["Arms"], L["Fury"], L["Protection"]},
					PALADIN = {L["Holy"], L["Protection"], L["Retribution"]},
					HUNTER = {L["Beast Mastery"], L["Marksmanship"], L["Survival"]},
					ROGUE = {L["Assassination"], L["Combat"], L["Subtlety"]},
					PRIEST = {L["Discipline"], L["Holy"], L["Shadow"]},
					SHAMAN = {L["Elemental Combat"], L["Enhancement"], L["Restoration"]},
					MAGE = {L["Arcane"], L["Fire"], L["Frost"]},
					WARLOCK = {L["Affliction"], L["Demonology"], L["Destruction"]},
					DRUID = {L["Balance"], L["Feral Combat"], L["Restoration"]},
				}
				-- Talent summary: the talent trees with points in them, most points first (such as Frost 31   Arcane 20)
				-- Forever keeps the three trees side by side in one modern talent tree, so talents are grouped by
				-- their position (a new tree starts where the gap between columns is much wider than usual)
				-- Find a player by their GUID (the mouse may have moved off them since the key was pressed)
				local function FindUnitByGUID(guid, first)
					if not guid then return nil end
					local tokens = {first or "mouseover", "mouseover", "target", "focus", "targettarget"}
					for i = 1, 4 do tinsert(tokens, "party" .. i) end
					if IsInRaid and IsInRaid() then for i = 1, 40 do tinsert(tokens, "raid" .. i) end end
					for i = 1, 40 do tinsert(tokens, "nameplate" .. i) end
					for void, token in ipairs(tokens) do
						if UnitExists(token) and Safe(UnitGUID(token)) == guid then return token end
					end
				end
				local function TalentSummary(configID, classFile)
					if not configID or not C_Traits or not C_Traits.GetConfigInfo then return nil end
					local config = SafeTable(C_Traits.GetConfigInfo(configID))
					local treeIDs = config and SafeTable(config.treeIDs)
					if not treeIDs or not Safe(treeIDs[1]) then return nil end
					local nodes = {}
					for void, treeID in ipairs(treeIDs) do
						treeID = Safe(treeID)
						for void, nodeID in ipairs(treeID and SafeTable(C_Traits.GetTreeNodes(treeID)) or {}) do
							local node = SafeTable(C_Traits.GetNodeInfo(configID, Safe(nodeID)))
							if node and type(Safe(node.posX)) == "number" then tinsert(nodes, node) end
						end
					end
					-- Points per column (use purchased ranks, or active ranks if nothing was purchased, such as some inspect data)
					local function Columns(field)
						local columns, total = {}, 0
						for void, node in ipairs(nodes) do
							local points = Safe(node[field])
							if type(points) ~= "number" then points = 0 end
							columns[node.posX] = (columns[node.posX] or 0) + points
							total = total + points
						end
						return columns, total
					end
					local columns, total = Columns("ranksPurchased")
					if total == 0 then columns, total = Columns("activeRank") end
					local xs = {}
					for x in pairs(columns) do tinsert(xs, x) end
					table.sort(xs)
					if #xs == 0 then return nil end
					if total == 0 then return "|cff8a8a90" .. L["No talents"] .. "|r" end
					-- Split the columns into trees where the gap is much wider than the usual gap between columns
					local gaps = {}
					for i = 2, #xs do tinsert(gaps, xs[i] - xs[i - 1]) end
					table.sort(gaps)
					local usualGap = gaps[math.ceil(#gaps / 2)] or 0
					local trees = {{points = 0, order = 1}}
					for i, x in ipairs(xs) do
						if i > 1 and xs[i] - xs[i - 1] > usualGap * 1.5 then tinsert(trees, {points = 0, order = #trees + 1}) end
						trees[#trees].points = trees[#trees].points + columns[x]
					end
					-- Name the trees (left to right)
					local names = classFile and talentTreeNames[classFile]
					for i, tree in ipairs(trees) do
						tree.name = names and names[i] or (L["Tree"] .. " " .. i)
					end
					table.sort(trees, function(x, y) if x.points ~= y.points then return x.points > y.points end return x.order < y.order end)
					local parts = {}
					for i, tree in ipairs(trees) do
						if tree.points > 0 then tinsert(parts, (i == 1 and "|cffffffff" or "|cffa0a0a8") .. tree.name .. " " .. tree.points .. "|r") end
					end
					return table.concat(parts, "    ")
				end
				-- Details for the card (each returns a list of short parts; anything the game hides or does not have is left out)
				local function NotSecret(v) return v ~= nil and not IsSecret(v) end
				local function Grey(text) return "|cff8a8a90" .. text .. "|r" end
				-- Money with gold, silver and copper icons
				local function CoinText(copper)
					-- Size the coin icons to the card's details text (the default size suits larger text, so the icons sit low)
					local card = LeaPlusLC.IDCard
					local fontSize = card and card.detail and select(2, card.detail:GetFont())
					fontSize = fontSize and math.floor(fontSize + 0.5) or nil
					if C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString then return C_CurrencyInfo.GetCoinTextureString(copper, fontSize) end
					if GetCoinTextureString then return GetCoinTextureString(copper, fontSize) end
					local gold, silver, bronze = math.floor(copper / 10000), math.floor(copper % 10000 / 100), copper % 100
					local text = {}
					if gold > 0 then tinsert(text, gold .. "|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:2:0|t") end
					if silver > 0 then tinsert(text, silver .. "|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:2:0|t") end
					if bronze > 0 or #text == 0 then tinsert(text, bronze .. "|TInterface\\MoneyFrame\\UI-CopperIcon:12:12:2:0|t") end
					return table.concat(text, " ")
				end
				-- Players: guild, relationship to you, PvP
				local function PlayerDetails(unit, guid)
					local parts = {}
					unit, guid = Safe(unit, guid)
					local hasUnit = unit and UnitExists(unit)
					-- Guild
					if hasUnit then
						local guildName, rankName = Safe(GetGuildInfo(unit))
						if guildName and guildName ~= "" then tinsert(parts, "|cff40ff40" .. guildName .. "|r" .. (rankName and rankName ~= "" and (" " .. rankName) or "")) end
					end
					-- Relationship to you
					local relation = {}
					if hasUnit and not Safe(UnitIsUnit(unit, "player")) then -- Nothing to say about your own character
						if Safe(UnitInRaid(unit)) or Safe(UnitInParty(unit)) then tinsert(relation, L["In your group"]) end
						if UnitIsInMyGuild and Safe(UnitIsInMyGuild(unit)) then tinsert(relation, L["Guildmate"]) end
					end
					if guid and C_FriendList and C_FriendList.IsFriend and Safe(C_FriendList.IsFriend(guid)) then tinsert(relation, L["Friend"]) end
					if #relation > 0 then tinsert(parts, "|cff66bbff" .. table.concat(relation, ", ") .. "|r") end
					-- PvP
					if hasUnit then
						local pvp = {}
						if UnitIsPVPFreeForAll and Safe(UnitIsPVPFreeForAll(unit)) then tinsert(pvp, L["Free for all PvP"])
						elseif Safe(UnitIsPVP(unit)) then tinsert(pvp, L["PvP"]) end
						if UnitPVPRank and GetPVPRankInfo then
							local rank = Safe(UnitPVPRank(unit))
							if type(rank) == "number" and rank >= 5 then
								local rankName = Safe(GetPVPRankInfo(rank, unit))
								if rankName and rankName ~= "" then tinsert(pvp, rankName) end
							end
						end
						if #pvp > 0 then tinsert(parts, "|cffff6060" .. table.concat(pvp, ", ") .. "|r") end
					end
					return parts
				end
				-- Average item level of a unit's equipped gear (shirt and tabard are left out, a two-hand weapon counts twice)
				local function AverageItemLevel(unit)
					if Safe(UnitIsUnit(unit, "player")) and GetAverageItemLevel then
						local void, equipped = Safe(GetAverageItemLevel())
						if type(equipped) == "number" and equipped > 0 then
							-- Match the character sheet: never below the minimum item level, and always round down
							local minLevel = C_PaperDollInfo and C_PaperDollInfo.GetMinItemLevel and Safe(C_PaperDollInfo.GetMinItemLevel())
							if type(minLevel) == "number" and minLevel > equipped then equipped = minLevel end
							return math.floor(equipped)
						end
					end
					local total, count, mainHandTwoHand, offHand = 0, 0, false, false
					local GetInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
					local GetLevel = (C_Item and C_Item.GetDetailedItemLevelInfo) or GetDetailedItemLevelInfo
					for slot = 1, 18 do
						if slot ~= 4 then
							local link = Safe(GetInventoryItemLink(unit, slot))
							if link then
								local level = Safe(GetLevel and GetLevel(link) or select(4, GetInfo(link)))
								if type(level) == "number" and level > 0 then
									total, count = total + level, count + 1
									if slot == 16 and Safe(select(9, GetInfo(link))) == "INVTYPE_2HWEAPON" then mainHandTwoHand = level end
									if slot == 17 then offHand = true end
								end
							end
						end
					end
					if mainHandTwoHand and not offHand then total, count = total + mainHandTwoHand, count + 1 end
					if count == 0 then return nil end
					return math.floor(total / count)
				end
				-- Items: item level, binding, sell price, item set
				local function ItemDetails(itemLink, tooltip)
					local parts = {}
					local GetInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
					local void, itemLevel, sellPrice, bindType
					void, void, void, itemLevel, void, void, void, void, void, void, sellPrice, void, void, bindType = Safe(GetInfo(itemLink))
					local GetLevel = (C_Item and C_Item.GetDetailedItemLevelInfo) or GetDetailedItemLevelInfo
					itemLevel = (GetLevel and Safe(GetLevel(itemLink))) or itemLevel
					if type(itemLevel) == "number" and itemLevel > 0 then tinsert(parts, L["Item level"] .. " |cffffffff" .. itemLevel .. "|r") end
					-- Binding (soulbound if the tooltip says so, otherwise how it binds)
					local lines = TooltipLines(tooltip)
					local bound
					for void, text in ipairs(lines) do
						if text == ITEM_SOULBOUND or (ITEM_ACCOUNTBOUND and text == ITEM_ACCOUNTBOUND) then bound = text break end
					end
					if not bound then
						if bindType == 1 then bound = ITEM_BIND_ON_PICKUP
						elseif bindType == 2 then bound = ITEM_BIND_ON_EQUIP
						elseif bindType == 3 then bound = ITEM_BIND_ON_USE
						elseif bindType == 4 then bound = ITEM_BIND_QUEST end
					end
					if bound then tinsert(parts, bound) end
					-- Sell price
					if type(sellPrice) == "number" then
						if sellPrice > 0 then
							tinsert(parts, L["Sells for"] .. " " .. CoinText(sellPrice))
						else
							tinsert(parts, Grey(L["Cannot be sold"]))
						end
					end
					-- Item set (the tooltip line with the set name and pieces, such as "Battlegear of Might (2/8)")
					for void, text in ipairs(lines) do
						local setName, have, total = text:match("^(.-) %((%d+)/(%d+)%)$")
						if setName and setName ~= "" then
							tinsert(parts, "|cffffd100" .. L["Set"] .. ": " .. setName .. " (" .. have .. "/" .. total .. ")|r")
							break
						end
					end
					return parts
				end
				-- Spells: rank
				local function SpellDetails(spellID)
					local parts = {}
					local subtext = Safe((C_Spell and C_Spell.GetSpellSubtext and C_Spell.GetSpellSubtext(spellID)) or (GetSpellSubtext and GetSpellSubtext(spellID)))
					if type(subtext) == "string" and subtext ~= "" then tinsert(parts, subtext) end
					return parts
				end
				-- Buffs and debuffs: who cast it
				local function AuraDetails(sourceUnit, spellID)
					local parts = {}
					sourceUnit = Safe(sourceUnit)
					-- For the buff frame, look up the caster from your own auras
					if not sourceUnit and spellID and C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID and not AurasHidden() then
						local aura = SafeTable(C_UnitAuras.GetPlayerAuraBySpellID(spellID))
						if aura then sourceUnit = Safe(aura.sourceUnit) end
					end
					if type(sourceUnit) ~= "string" or not UnitExists(sourceUnit) then return parts end
					if Safe(UnitIsUnit(sourceUnit, "player")) then
						tinsert(parts, L["Cast by"] .. " |cffffffff" .. L["You"] .. "|r")
					else
						local name = Safe(UnitName(sourceUnit))
						if name then
							local classFile = Safe(UnitIsPlayer(sourceUnit)) and Safe(select(2, UnitClass(sourceUnit)))
							local color = classFile and RAID_CLASS_COLORS[classFile]
							tinsert(parts, L["Cast by"] .. " " .. (color and string.format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, name) or ("|cffffffff" .. name .. "|r")))
						end
					end
					return parts
				end
				-- Quests: level (coloured by difficulty), complete, group or elite, rewards
				local function QuestDetails(questID)
					local parts = {}
					local index = C_QuestLog.GetLogIndexForQuestID and Safe(C_QuestLog.GetLogIndexForQuestID(questID))
					local info = index and SafeTable(C_QuestLog.GetInfo(index))
					local level = info and Safe(info.level)
					local suggestedGroup = info and Safe(info.suggestedGroup)
					if type(suggestedGroup) ~= "number" then suggestedGroup = 0 end
					if type(level) == "number" and level > 0 then
						local color = GetQuestDifficultyColor and GetQuestDifficultyColor(level)
						local text = L["Level"] .. " " .. level
						tinsert(parts, color and string.format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, text) or text)
					end
					if C_QuestLog.IsComplete and Safe(C_QuestLog.IsComplete(questID)) then tinsert(parts, "|cff40ff40" .. L["Complete"] .. "|r") end
					-- Group size, elite, dungeon and so on
					local tag = C_QuestLog.GetQuestTagInfo and SafeTable(C_QuestLog.GetQuestTagInfo(questID))
					local tagName = tag and Safe(tag.tagName)
					if type(tagName) == "string" and tagName ~= "" then
						tinsert(parts, "|cffff9020" .. tagName .. ((suggestedGroup > 1) and (" (" .. suggestedGroup .. ")") or "") .. "|r")
					elseif suggestedGroup > 1 then
						tinsert(parts, "|cffff9020" .. L["Group"] .. " (" .. suggestedGroup .. ")|r")
					end
					-- Rewards (money, experience, items and item choices)
					local rewards = {}
					local money = GetQuestLogRewardMoney and Safe(GetQuestLogRewardMoney(questID))
					if type(money) == "number" and money > 0 then tinsert(rewards, CoinText(money)) end
					local xp = GetQuestLogRewardXP and Safe(GetQuestLogRewardXP(questID))
					if type(xp) == "number" and xp > 0 then tinsert(rewards, xp .. " " .. L["XP"]) end
					local function ItemIcons(count, getInfo)
						local icons = {}
						count = Safe(count)
						for i = 1, type(count) == "number" and count or 0 do
							local void, texture, number = Safe(getInfo(i, questID))
							if texture then tinsert(icons, "|T" .. texture .. ":14:14|t" .. ((type(number) == "number" and number > 1) and ("x" .. number) or "")) end
						end
						return table.concat(icons, " ")
					end
					if GetNumQuestLogRewards and GetQuestLogRewardInfo then
						local icons = ItemIcons(GetNumQuestLogRewards(questID), GetQuestLogRewardInfo)
						if icons ~= "" then tinsert(rewards, icons) end
					end
					if GetNumQuestLogChoices and GetQuestLogChoiceInfo then
						local icons = ItemIcons(GetNumQuestLogChoices(questID), GetQuestLogChoiceInfo)
						if icons ~= "" then tinsert(rewards, L["Choose"] .. " " .. icons) end
					end
					if #rewards > 0 then tinsert(parts, L["Rewards"] .. ": " .. table.concat(rewards, "  ")) end
					return parts
				end
				-- Show the talent summary on the card (other players are inspected first)
				local function ShowPlayerTalents(unit)
					local card = LeaPlusLC.IDCard
					unit = Safe(unit)
					if not card or not unit or not UnitExists(unit) then return end
					local classFile = Safe(select(2, UnitClass(unit)))
					if Safe(UnitIsUnit(unit, "player")) then
						card.talents:SetText(TalentSummary(C_ClassTalents and C_ClassTalents.GetActiveConfigID and Safe(C_ClassTalents.GetActiveConfigID()), classFile) or "")
						local itemLevel = AverageItemLevel("player")
						if itemLevel then card:AddDetail(L["Item level"] .. " |cffffffff" .. itemLevel .. "|r") end
						return
					end
					local guid = Safe(UnitGUID(unit))
					if not guid or not NotifyInspect or not CanInspect or not Safe(CanInspect(unit)) then return end
					if InspectFrame and InspectFrame:IsShown() then return end -- Do not disturb the inspect window
					card.inspectGUID = guid
					card.inspectClassFile = classFile
					card.inspectUnit = unit
					card.inspectTime = GetTime() -- Each inspect starts with fresh gear for the model viewer
					card.talents:SetText("|cff8a8a90" .. L["Reading talents..."] .. "|r")
					card:SetItemLevelDetail("|cff8a8a90" .. L["Item level"] .. " ...|r") -- Shown until the inspect has come back
					if not LeaPlusLC.IDCardInspect then
						LeaPlusLC.IDCardInspect = CreateFrame("Frame")
						LeaPlusLC.IDCardInspect:SetScript("OnEvent", function(self, event, readyGUID)
							local c = LeaPlusLC.IDCard
							readyGUID = Safe(readyGUID)
							if not c or not c.inspectGUID or not readyGUID or readyGUID ~= c.inspectGUID then return end
							c.inspectGUID = nil
							LeaPlusLC.IDInspectPending = nil
							self:UnregisterEvent("INSPECT_READY")
							local inspectConfigID = Constants and Constants.TraitConsts and Constants.TraitConsts.INSPECT_TRAIT_CONFIG_ID or -1
							local classFile, firstUnit = c.inspectClassFile, c.inspectUnit
							-- Talents are only ever read live from the player, so the card needs to find them when the answer arrives
							-- They are read straight away and again shortly after (in case the game had not finished updating them), and the inspect data is only cleared after the last read
							-- If the player cannot be found when the answer arrives, the card does not keep looking for them
							c.talentsReadID = (c.talentsReadID or 0) + 1
							local readID = c.talentsReadID
							local delays = {0, 0.3, 1}
							local itemLevelDone = false
							local function ClearInspect()
								if ClearInspectPlayer and not LeaPlusLC.IDInspectPending and not (InspectFrame and InspectFrame:IsShown()) then ClearInspectPlayer() end
							end
							-- Stop if the card has been closed or is showing something else now
							local function CardChanged()
								return not c:IsShown() or c.talentsReadID ~= readID
							end
							-- Gear for the model viewer (the weapons, and how they look on the player such as a transmog or a paired weapon), read while
							-- the inspect data is there and kept after it is cleared, and the viewer is updated if it shows this player
							c.gearReadingGUID = readyGUID
							local function ReadGear(unit)
								LeaPlusLC.IDGear = LeaPlusLC.IDGear or {}
								local gear = LeaPlusLC.IDGear[readyGUID]
								if not gear or gear.inspectTime ~= c.inspectTime then gear = {inspectTime = c.inspectTime} LeaPlusLC.IDGear = {[readyGUID] = gear} end -- Only the player just inspected is kept
								local RequestLoad = C_Item and C_Item.RequestLoadItemDataByID
								local complete, newWeapon = true, false
								for slot = 1, 19 do
									local link = Safe(GetInventoryItemLink(unit, slot))
									if link then
										if not gear[slot] then
											gear[slot] = link
											if slot == 16 or slot == 17 then newWeapon = true end
										end
									else
										local itemID = GetInventoryItemID and Safe(GetInventoryItemID(unit, slot))
										if itemID then
											complete = false
											if RequestLoad then pcall(RequestLoad, itemID) end
										end
									end
								end
								if not gear.looks and C_TransmogCollection and C_TransmogCollection.GetInspectItemTransmogInfoList then
									local ok, looks = pcall(C_TransmogCollection.GetInspectItemTransmogInfoList)
									if ok and SafeTable(looks) and next(looks) then gear.looks = looks newWeapon = true end
								end
								if complete then gear.complete = true end
								local viewer = LeaPlusLC.IDViewer
								if viewer and (newWeapon or complete) then viewer:ApplyInspectGear() viewer:CheckReveal() end
							end
							-- The last read: use whatever gear could be read
							local function FinishGear()
								c.gearReadingGUID = nil
								local gear = LeaPlusLC.IDGear and LeaPlusLC.IDGear[readyGUID]
								if gear then gear.complete = true end
								local viewer = LeaPlusLC.IDViewer
								if viewer then viewer:ApplyInspectGear() viewer:CheckReveal() end
							end
							-- Read the talents from the player if they can be found (gives true when they were read)
							local function ReadLive()
								-- Find the player again (the pointer may have moved off them since the key was pressed)
								local foundUnit = FindUnitByGUID(readyGUID, firstUnit)
								if not foundUnit then return false end
								ReadGear(foundUnit)
								c.talents:SetText(TalentSummary(inspectConfigID, classFile) or "")
								-- Average item level from the inspected gear (added once)
								if not itemLevelDone then
									itemLevelDone = true
									local itemLevel = AverageItemLevel(foundUnit)
									c:SetItemLevelDetail(itemLevel and (L["Item level"] .. " |cffffffff" .. itemLevel .. "|r") or nil)
								end
								return true
							end
							local function ReadTalents(step)
								if CardChanged() then ClearInspect() return end
								if not ReadLive() and step == 1 then
									-- The player could not be found when the answer arrived (the pointer moved off them or they went out of range)
									-- The reply is kept, and the talents and item level are read as soon as the player can be found again (pointed at, targeted or their nameplate shown)
									local name = c.title:GetText() or ""
									c.talents:SetText("|cff8a8a90" .. string.format(L["Move your mouse over %s to show their talents."], name) .. "|r")
									if not itemLevelDone then c:SetItemLevelDetail("|cff8a8a90" .. string.format(L["Move your mouse over %s to show their item level."], name) .. "|r") end
									LeaPlusLC.IDTalentWait = {guid = readyGUID, resume = function() ReadTalents(1) end}
									c.gearReadingGUID = nil
									if LeaPlusLC.IDViewer then LeaPlusLC.IDViewer:CheckReveal() end
									if not LeaPlusLC.IDTalentWatch then
										local watch = CreateFrame("Frame")
										LeaPlusLC.IDTalentWatch = watch
										watch:SetScript("OnEvent", function()
											local wait, card = LeaPlusLC.IDTalentWait, LeaPlusLC.IDCard
											if not wait then return end
											if not card or not card:IsShown() then LeaPlusLC.IDTalentWait = nil return end
											if not FindUnitByGUID(wait.guid) then return end
											LeaPlusLC.IDTalentWait = nil
											wait.resume()
										end)
										watch:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
										watch:RegisterEvent("PLAYER_TARGET_CHANGED")
										watch:RegisterEvent("NAME_PLATE_UNIT_ADDED")
										watch:RegisterEvent("GROUP_ROSTER_UPDATE")
									end
									return
								end
								-- Read again shortly after while the player can still be found (a later read that cannot find them leaves the talents as they are)
								if step < #delays then
									C_Timer.After(delays[step + 1] - delays[step], function() ReadTalents(step + 1) end)
								else
									FinishGear()
									ClearInspect()
								end
							end
							ReadTalents(1)
						end)
					end
					LeaPlusLC.IDCardInspect:RegisterEvent("INSPECT_READY")
					-- Only ask the server once per player at a time (asking again quickly can be ignored, so the answer never comes)
					local pending = LeaPlusLC.IDInspectPending
					if not (pending and pending.guid == guid and GetTime() - pending.time < 4) then
						LeaPlusLC.IDInspectPending = {guid = guid, time = GetTime()}
						NotifyInspect(unit)
					end
					C_Timer.After(4, function()
						local c = LeaPlusLC.IDCard
						if c and c.inspectGUID == guid then
							c.inspectGUID = nil
							LeaPlusLC.IDCardInspect:UnregisterEvent("INSPECT_READY")
							c.talents:SetText("|cff8a8a90" .. L["Talents are not available right now."] .. "|r")
							c:SetItemLevelDetail(nil) -- No reply, so no item level
						end
					end)
				end
				-- Retries happen when a new player or creature has not finished loading (see the unknown tooltip below)
				if arg1 ~= "retry" and arg1 ~= "upgrade" then
					LeaPlusLC.IDRetries, LeaPlusLC.IDUpgrades = 0, 0
					-- Remember what was under the mouse when the key was pressed (retries only show a card for that, never for something else)
					LeaPlusLC.IDPressID = (LeaPlusLC.IDPressID or 0) + 1
					LeaPlusLC.IDPressFocus = GetMouseFoci and GetMouseFoci()[1] or nil
					LeaPlusLC.IDPressHadUnit = Safe(UnitExists("mouseover")) and true or false
					LeaPlusLC.IDPressGUID = Safe(UnitGUID("mouseover"))
					-- Whether the key was pressed on a unit at all (a mailbox, the ground and so on are not units)
					local tipData = GameTooltip:IsShown() and SafeTable(GameTooltip.GetTooltipData and GameTooltip:GetTooltipData())
					LeaPlusLC.IDPressOnUnit = LeaPlusLC.IDPressHadUnit or (tipData and Safe(tipData.type) == Enum.TooltipDataType.Unit) or false
				elseif arg1 == "retry" then
					-- The mouse has moved on to something else since the key was pressed, so give up (the key was not pressed for that)
					local focus = GetMouseFoci and GetMouseFoci()[1] or nil
					if focus ~= LeaPlusLC.IDPressFocus then LeaPlusLC.IDRetries = 0 return end
					if LeaPlusLC.IDPressHadUnit and not Safe(UnitExists("mouseover")) then LeaPlusLC.IDRetries = 0 return end
					local guid = Safe(UnitGUID("mouseover"))
					if LeaPlusLC.IDPressGUID and guid and guid ~= LeaPlusLC.IDPressGUID then LeaPlusLC.IDRetries = 0 return end
					-- The key was pressed on a unit the game was hiding, and the unit now under the mouse can be read, so it is a different unit
					if LeaPlusLC.IDPressHadUnit and not LeaPlusLC.IDPressGUID and guid then LeaPlusLC.IDRetries = 0 return end
					-- The key was not pressed on a unit (such as a mailbox), and the mouse is now over one, so it is a different thing
					if not LeaPlusLC.IDPressOnUnit and Safe(UnitExists("mouseover")) then LeaPlusLC.IDRetries = 0 return end
				end
				-- Model viewer option (on unless it has been switched off with the checkbox on the card)
				if LeaPlusLC.IDModelOn == nil then LeaPlusLC.IDModelOn = not (LeaPlusDB and LeaPlusDB["IDModelOn"] == false) end
				-- Find the unit frame under the mouse (used by the aura picker below)
				if LeaPlusLC.AuraPicker then LeaPlusLC.AuraPicker:Hide() end
				local pickerUnit
				if not forceUnit then -- Not when a player was given
					local mouseFocus = GetMouseFoci and GetMouseFoci()[1]
					while mouseFocus and not pickerUnit do
						if mouseFocus.IsForbidden and mouseFocus:IsForbidden() then break end
						local unit = Safe(mouseFocus.unit)
						if type(unit) == "string" and UnitExists(unit) then pickerUnit = unit end
						mouseFocus = mouseFocus:GetParent()
					end
				end
				if pickerUnit and LeaPlusLC.IDCard then LeaPlusLC.IDCard:Hide() end
				-- Show the card for what is under the mouse
				local function ShowCardForMouse()
					-- Show info card for tooltip
					if not LeaPlusLC.WowheadLock then
						-- Set Wowhead link prefix
						if GameLocale == "deDE" then LeaPlusLC.WowheadLock = "wowhead.com/forever/de"
						elseif GameLocale == "esMX" then LeaPlusLC.WowheadLock = "wowhead.com/forever/mx"
						elseif GameLocale == "esES" then LeaPlusLC.WowheadLock = "wowhead.com/forever/es"
						elseif GameLocale == "frFR" then LeaPlusLC.WowheadLock = "wowhead.com/forever/fr"
						elseif GameLocale == "itIT" then LeaPlusLC.WowheadLock = "wowhead.com/forever/it"
						elseif GameLocale == "ptBR" then LeaPlusLC.WowheadLock = "wowhead.com/forever/pt"
						elseif GameLocale == "ruRU" then LeaPlusLC.WowheadLock = "wowhead.com/forever/ru"
						elseif GameLocale == "koKR" then LeaPlusLC.WowheadLock = "wowhead.com/forever/ko"
						elseif GameLocale == "zhCN" then LeaPlusLC.WowheadLock = "wowhead.com/forever/cn"
						elseif GameLocale == "zhTW" then LeaPlusLC.WowheadLock = "wowhead.com/forever/tw"
						else							 LeaPlusLC.WowheadLock = "wowhead.com/forever"
						end
					end
					if not LeaPlusLC.BlizzardLock then
						-- Set Blizzard link prefix (https://wowpedia.fandom.com/wiki/Localization) (region will be added by website automatically)
							if GameLocale == "deDE" then LeaPlusLC.BlizzardLock = "https://worldofwarcraft.com/de-de/character/eu/" -- Germany
						elseif GameLocale == "frFR" then LeaPlusLC.BlizzardLock = "https://worldofwarcraft.com/fr-fr/character/eu/" -- France
						elseif GameLocale == "itIT" then LeaPlusLC.BlizzardLock = "https://worldofwarcraft.com/it-it/character/eu/" -- Italy
						elseif GameLocale == "ruRU" then LeaPlusLC.BlizzardLock = "https://worldofwarcraft.com/ru-ru/character/eu/" -- Russia
						elseif GameLocale == "koKR" then LeaPlusLC.BlizzardLock = "https://worldofwarcraft.com/ko-kr/character/kr/" -- Korea
						elseif GameLocale == "zhTW" then LeaPlusLC.BlizzardLock = "https://worldofwarcraft.com/zh-tw/character/tw/" -- Tiawan
						elseif GameLocale == "esES" and GetCurrentRegion() == 1 then LeaPlusLC.BlizzardLock = "https://worldofwarcraft.com/es-es/character/us/" -- Spain (esES connected to US)
						elseif GameLocale == "esES" and GetCurrentRegion() == 3 then LeaPlusLC.BlizzardLock = "https://worldofwarcraft.com/es-es/character/eu/" -- Spain (esES connected to EU)
						elseif GameLocale == "esMX" and GetCurrentRegion() == 1 then LeaPlusLC.BlizzardLock = "https://worldofwarcraft.com/es-mx/character/us/" -- Mexico (esMX connected to US)
						elseif GameLocale == "esMX" and GetCurrentRegion() == 3 then LeaPlusLC.BlizzardLock = "https://worldofwarcraft.com/es-mx/character/eu/" -- Spain (esMX connected to EU)
						elseif GameLocale == "ptBR" and GetCurrentRegion() == 1 then LeaPlusLC.BlizzardLock = "https://worldofwarcraft.com/pt-br/character/us/" -- Brazil (ptBR connected to US)
						elseif GameLocale == "ptBR" and GetCurrentRegion() == 3 then LeaPlusLC.BlizzardLock = "https://worldofwarcraft.com/pt-br/character/eu/" -- Portugal (ptBR connected to US)
						elseif GameLocale == "enUS" and GetCurrentRegion() == 3 then LeaPlusLC.BlizzardLock = "https://worldofwarcraft.com/en-gb/character/eu/" -- UK (enUS connected to Europe)
						else 														 LeaPlusLC.BlizzardLock = "https://worldofwarcraft.com/en-us/character/us/" -- US (default)
						end
					end
					if isForever and LeaPlusLC.ForeverLock == nil then
						-- Set Forever armory link prefix (Forever characters have a first name and surname but no realm in the link)
						local foreverRegion = ({[1] = "us", [2] = "kr", [3] = "eu", [4] = "tw"})[GetCurrentRegion()]
						local foreverLang = ({deDE = "de-de", frFR = "fr-fr", itIT = "it-it", ruRU = "ru-ru", koKR = "ko-kr", zhTW = "zh-tw", esES = "es-es", esMX = "es-mx", ptBR = "pt-br"})[GameLocale] or "en-us"
						LeaPlusLC.ForeverLock = foreverRegion and ("https://worldofwarcraft.blizzard.com/" .. foreverLang .. "/forever/" .. foreverRegion .. "/armory/character/") or false -- No Forever armory for China
					end
					-- Forever armory link from first name and surname (Star Dog becomes star-dog)
					local function ForeverArmoryLink(firstName, surname)
						if not LeaPlusLC.ForeverLock or type(firstName) ~= "string" or firstName == "" then return nil end
						local fullName = (type(surname) == "string" and surname ~= "") and (firstName .. " " .. surname) or firstName
						return LeaPlusLC.ForeverLock .. strlower(fullName):gsub("'", ""):gsub("%s+", "-")
					end
					-- Player card (for the player under the mouse, or the player given to ShowInfoCard such as from the dressing room)
					local function ShowPlayerCard(unitFocus)
						-- Show armory link
						local name, realm = Safe(UnitName(unitFocus))
						local surname = isForever and realm or nil -- On Forever, the second name is the surname
						local class = Safe(UnitClassBase(unitFocus))
						local color = class and RAID_CLASS_COLORS[class]
						if not color then return end
						if not realm then realm = Safe(GetNormalizedRealmName()) end
						if not (name and realm) then return end
						-- Debug
						-- local realm = "StrandoftheAncients" -- Debug
						-- Chinese armory not available
						if GameLocale == "zhCN" then return end
						-- Fix non-standard names
							if realm == "Area52" then realm = "Area-52"
						elseif realm == "AzjolNerub" then realm = "AzjolNerub"
						elseif realm == "Chantséternels" then realm = "Chants-Éternels"
						elseif realm == "ConfrérieduThorium" then realm = "Confrérie-du-Thorium"
						elseif realm == "ConseildesOmbres" then realm = "Conseil-des-Ombres"
						elseif realm == "CultedelaRivenoire" then realm = "Culte-de-la-Rive-noire"
						elseif realm == "DerRatvonDalaran" then realm = "Der-Rat-von-Dalaran"
						elseif realm == "DieewigeWacht" then realm = "Die-ewige-Wacht"
						elseif realm == "FestungderStürme" then realm = "Festung-der-Stürme"
						elseif realm == "KultderVerdammten" then realm = "Kult-der-Verdammten"
						elseif realm == "LaCroisadeécarlate" then realm = "La-Croisade-Écarlate"
						elseif realm == "MarécagedeZangar" then realm = "Marécage-de-Zangar"
						elseif realm == "Pozzodell'Eternità" then realm = "Pozzo-dellEternità"
						elseif realm == "Templenoir" then realm = "Temple-noir"
						elseif realm == "VanCleef" then realm = "Vancleef"
						elseif realm == "ZirkeldesCenarius" then realm = "Zirkel-des-Cenarius"
						-- Fix Russian names
						elseif realm == "СвежевательДуш" then realm = "Свежеватель-Душ"
						elseif realm == "СтражСмерти" then realm = "Страж-Смерти"
						elseif realm == "Ревущийфьорд" then realm = "Ревущий-фьорд"
						elseif realm == "ТкачСмерти" then realm = "Ткач-Смерти"
						elseif realm == "Борейскаятундра" then realm = "Борейская-тундра"
						elseif realm == "Ясеневыйлес" then realm = "Ясеневый-лес"
						elseif realm == "ПиратскаяБухта" then realm = "Пиратская-Бухта"
						elseif realm == "ВечнаяПесня" then realm = "Вечная-Песня"
						elseif realm == "ЧерныйШрам" then realm = "Черный-Шрам"
						elseif realm == "ВестникРока" then realm = "Вестник-Рока"
						-- Fix all other names
						else
							-- Realm name is not one of the above so fix it
							realm = realm:gsub("(%l[of])(%u)", "-%1-%2") -- Add hyphen after of if capital follows of (CavernsofTime becomes Cavernsof-Time)
							realm = realm:gsub("(ofthe)", "-of-the-") -- Replace ofthe with -of-the- (ShrineoftheDormantFlame becomes Shrine-of-the-DormantFlame)
							realm = realm:gsub("(%l)(%u)", "%1 %2") -- Add space before capital letters (CavernsofTime becomes Cavernsof Time)
							realm = realm:gsub(" ", "-") -- Replace space with hyphen (Cavernsof Time becomes Cavernsof-Time)
							realm = realm:gsub("'", "") -- Remove apostrophe
							realm = realm:gsub("[(]", "-") -- Replace opening parentheses with hyphen
							realm = realm:gsub("[)]", "") -- Remove closing parentheses
						end
						-- print(realm) -- Debug
						local armoryLink
						if isForever then armoryLink = ForeverArmoryLink(name, surname) else armoryLink = LeaPlusLC.BlizzardLock .. strlower(realm) .. "/" .. strlower(name) end
						realm = realm:gsub("-", " ") -- Replace hyphen with space
						local playerColor = {color.r, color.g, color.b}
						local playerLevel = Safe(UnitLevel(unitFocus))
						if isForever and type(playerLevel) == "number" and playerLevel > 0 and playerLevel < 10 then armoryLink = nil end -- Forever armory does not list characters under level 10
						local playerName, realmText = name, realm
						if surname and surname ~= "" then playerName = name .. " " .. surname end
						if isForever then realmText = "" end -- Forever realms are hidden from players
						local playerNote = realmText
						if type(playerLevel) == "number" and playerLevel > 0 then playerNote = L["Level"] .. " " .. playerLevel .. " " .. (Safe(UnitClass(unitFocus)) or "") .. (realmText ~= "" and ("    " .. realmText) or "") end
						local unitGUID = Safe(UnitGUID(unitFocus))
						ShowIDCard({sounds = {unit = unitFocus}, kind = L["Player"], name = playerName, sub = playerNote, url = armoryLink, unit = unitFocus, color = playerColor, nameColor = playerColor, view = {mode = "unit", isPlayer = true, unit = unitFocus, guid = unitGUID, text = PlayerText(unitFocus)}, talents = true, details = PlayerDetails(unitFocus, unitGUID)})
						ShowPlayerTalents(unitFocus)
					end
					-- A player was given, so show their card and nothing else
					if forceUnit then
						if Safe(UnitExists(forceUnit)) and Safe(UnitIsPlayer(forceUnit)) then ShowPlayerCard(forceUnit) end
						return
					end
					-- Leatrix Maps dungeon map boss icons (the icon holds its boss row: {"boss", x, y, npc ID, name, level, display ID, style})
					-- Only icons that own the Leatrix Maps dungeon tooltip are used, so nothing else with a row field is mistaken for one
					do
						local pin = GetMouseFoci and GetMouseFoci()[1]
						local mapTip = LeaMapsDungeonTooltip
						if pin and mapTip and not (pin.IsForbidden and pin:IsForbidden()) and mapTip:IsShown() and mapTip:IsOwned(pin) then
							local row = pin.row
							if type(row) == "table" and row[1] == "boss" and type(row[4]) == "number" and type(row[5]) == "string" then
								local npcID, displayID, level, style = row[4], tonumber(row[7]), tonumber(row[6]), row[8]
								-- Split the title from the name (Oggleflint <Ragefire Chieftain>)
								local bossName, bossTitle = row[5]:match("^(.-)%s*(<.+>)$")
								if not bossName or bossName == "" then bossName, bossTitle = row[5], nil end
								local isRare = style == 2 or style == 4
								local bossNote
								if style == 3 or not level then bossNote = L["Level"] .. " ??" else bossNote = L["Level"] .. " " .. level end
								bossNote = bossNote .. " " .. (isRare and L["Rare"] or L["Boss"])
								local hostile = FACTION_BAR_COLORS and FACTION_BAR_COLORS[2]
								local bossColor = hostile and {hostile.r, hostile.g, hostile.b} or {1, 0.82, 0}
								ShowIDCard({sounds = {npcID = npcID, displayID = displayID, name = bossName}, kind = L["NPC"], name = bossName, id = npcID, url = "https://" .. LeaPlusLC.WowheadLock .. "/npc=" .. npcID, color = bossColor, nameColor = bossColor, note = bossNote, view = {mode = "unit", npcID = npcID, displayID = displayID, text = bossTitle}})
								return
							end
						end
					end
					-- Leatrix Maps dungeon and raid icons on the zone map (the card shows the name, level range and a Wowhead search link)
					do
						local dungeonName, dungeonDesc, minLevel, maxLevel, dungeonKind, dungeonMaps
						-- Icons drawn by Leatrix Maps itself have no mouse input, so use the icon that owns the Leatrix Maps map tooltip
						local poiTip = LeaMapsPOITooltip
						local owner = poiTip and poiTip:IsShown() and poiTip:GetOwner()
						if owner and not (owner.IsForbidden and owner:IsForbidden()) and owner.isLeaMapsPin and type(owner.data) == "table" then
							local data = owner.data
							if (data[1] == "Dungeon" or data[1] == "Raid" or data[1] == "Dunraid") and type(data[4]) == "string" then
								dungeonName, dungeonDesc, minLevel, maxLevel, dungeonKind = data[4], data[5], tonumber(data[7]), tonumber(data[8]), data[1]
								dungeonMaps = owner.DungeonMaps
							end
						end
						-- Icons added to the game map by Leatrix Maps (the icon under the mouse)
						if not dungeonName then
							local pin = GetMouseFoci and GetMouseFoci()[1]
							if pin and not (pin.IsForbidden and pin:IsForbidden()) and pin.pinTemplate == "LeaMapsGlobalPinTemplate" then
								local atlas = pin.Texture and pin.Texture.GetAtlas and pin.Texture:GetAtlas()
								local pinName = type(pin.name) == "string" and pin.name or (type(pin.DungeonTitle) == "string" and pin.DungeonTitle)
								if pinName and (atlas == "Dungeon" or atlas == "Raid" or pin.DungeonMaps) then
									-- The name can include the level range in colour, such as The Deadmines (18-23)
									local plain = pinName:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
									local base, low, high = plain:match("^(.-)%s*%((%d+)%-(%d+)%)$")
									if not base then base, low = plain:match("^(.-)%s*%((%d+)%)$") high = low end
									dungeonName = type(pin.DungeonTitle) == "string" and pin.DungeonTitle or ((base and base ~= "") and base or plain)
									minLevel, maxLevel = tonumber(low), tonumber(high)
									dungeonDesc = pin.description
									dungeonKind = atlas == "Raid" and "Raid" or atlas == "Dungeon" and "Dungeon" or "Dunraid"
									dungeonMaps = pin.DungeonMaps
								end
							end
						end
						if type(dungeonName) == "string" and dungeonName ~= "" then
							-- Level range, coloured the same way as the map tooltip
							local levelText
							if minLevel and maxLevel then
								local playerLevel = UnitLevel("player") or 0
								local color
								if playerLevel < minLevel then color = GetQuestDifficultyColor(minLevel) elseif playerLevel > maxLevel then color = GetQuestDifficultyColor(maxLevel - 2) else color = QuestDifficultyColors and QuestDifficultyColors["difficult"] end
								levelText = L["Level"] .. " " .. ((minLevel ~= maxLevel) and (minLevel .. "-" .. maxLevel) or maxLevel)
								if color then levelText = string.format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, levelText) end
							end
							-- Icons with several dungeons and raids (such as Blackrock Mountain) list them in the description
							local desc
							if dungeonKind == "Dunraid" and type(dungeonDesc) == "string" then
								desc = strtrim((dungeonDesc:gsub("|n", " "):gsub("%s+", " ")))
								if desc == "" then desc = nil end
							end
							local kindText = dungeonKind == "Raid" and L["Raid"] or dungeonKind == "Dunraid" and (L["Dungeon"] .. " / " .. L["Raid"]) or L["Dungeon"]
							local icon = dungeonKind == "Raid" and "Interface\\Icons\\INV_Misc_Head_Dragon_01" or "Interface\\Icons\\INV_Misc_Bone_Skull_02"
							-- Wowhead zone for the dungeon (Leatrix Maps gives the instance map IDs, Wowhead uses zone IDs)
							-- Icons with several instances link to the zone they are all in (such as Blackrock Mountain)
							local zoneID
							if type(dungeonMaps) == "table" and #dungeonMaps > 0 then
								if not LeaPlusLC.IDDungeonZones then
									LeaPlusLC.IDDungeonZones = {[33] = 209, [34] = 717, [36] = 1581, [43] = 718, [47] = 491, [48] = 719, [70] = 1337, [90] = 721, [109] = 1477, [129] = 722, [189] = 796, [209] = 1176, [229] = 1583, [230] = 1584, [249] = 2159, [269] = 2366, [289] = 2057, [309] = 1977, [329] = 2017, [349] = 2100, [389] = 2437, [409] = 2717, [429] = 2557, [469] = 2677, [509] = 3429, [531] = 3428, [532] = 3457, [533] = 3456, [534] = 3606, [540] = 3714, [542] = 3713, [543] = 3562, [544] = 3836, [545] = 3715, [546] = 3716, [547] = 3717, [548] = 3607, [550] = 3845, [552] = 3848, [553] = 3847, [554] = 3849, [555] = 3789, [556] = 3791, [557] = 3792, [558] = 3790, [560] = 2367, [564] = 3959, [565] = 3923, [568] = 3805, [574] = 206, [575] = 1196, [576] = 4265, [578] = 4228, [580] = 4075, [585] = 4131, [595] = 4100, [599] = 4264, [600] = 4196, [601] = 4277, [602] = 4272, [603] = 4273, [604] = 4416, [608] = 4415, [615] = 4493, [616] = 4500, [619] = 4494, [624] = 4603, [631] = 4812, [632] = 4809, [649] = 4722, [650] = 4723, [658] = 4813, [668] = 4820, [724] = 4987, [2959] = 16560, [2998] = 16732, [2999] = 16611, [3065] = 16919}
									LeaPlusLC.IDDungeonParents = {[229] = 25, [230] = 25, [409] = 25, [469] = 25}
								end
								if #dungeonMaps == 1 then
									zoneID = LeaPlusLC.IDDungeonZones[dungeonMaps[1]]
								else
									zoneID = LeaPlusLC.IDDungeonParents[dungeonMaps[1]]
									for i = 2, #dungeonMaps do
										if LeaPlusLC.IDDungeonParents[dungeonMaps[i]] ~= zoneID then zoneID = nil break end
									end
								end
							end
							local dungeonURL
							if zoneID then
								dungeonURL = "https://" .. LeaPlusLC.WowheadLock .. "/zone=" .. zoneID
							else
								-- Zone not known, so link to a search for its name
								local query = dungeonName:gsub("([^%w%-_%.~ ])", function(c) return string.format("%%%02X", string.byte(c)) end):gsub(" ", "+")
								dungeonURL = "https://" .. LeaPlusLC.WowheadLock .. "/search?q=" .. query
							end
							ShowIDCard({kind = kindText, name = dungeonName, id = zoneID, note = zoneID and levelText or nil, sub = not zoneID and (levelText or "") or nil, url = dungeonURL, icon = icon, color = {1, 0.82, 0}, details = {desc}})
							return
						end
					end
					-- Quest tracker (the list of quests under the minimap)
					local questID, questTitle
					do
						-- Modern tracker: look for a quest ID on the frame under the mouse or its parents
						local frame = GetMouseFoci and GetMouseFoci()[1]
						while frame and not questID do
							if frame.IsForbidden and frame:IsForbidden() then break end
							local id = Safe(frame.questID)
							if not id and Safe(frame.id) and frame.GetDebugName then
								local debugName = Safe(frame:GetDebugName())
								if type(debugName) == "string" and debugName:find("Quest") then id = Safe(frame.id) end
							end
							if type(id) == "number" then
								local title = Safe(C_QuestLog.GetTitleForQuestID(id))
								if title then questID, questTitle = id, title end
							end
							frame = frame:GetParent()
						end
						-- Classic tracker: find the hovered line and walk up to its quest title
						if not questID and QuestWatchFrame and QuestWatchFrame:IsShown() and QuestWatchFrame:IsMouseOver() then
							local hovered
							for i = 1, 50 do
								local watchLine = _G["QuestWatchLine" .. i]
								if not watchLine then break end
								if watchLine:IsShown() and watchLine:IsMouseOver() then hovered = i break end
							end
							if hovered then
								local titles = {}
								for i = 1, (Safe(C_QuestLog.GetNumQuestLogEntries()) or 0) do
									local info = SafeTable(C_QuestLog.GetInfo(i))
									local title, id = info and Safe(info.title), info and Safe(info.questID)
									if info and not Safe(info.isHeader) and type(title) == "string" and id then titles[title] = id end
								end
								for i = hovered, 1, -1 do
									local text = Safe(_G["QuestWatchLine" .. i]:GetText())
									if type(text) == "string" then
										text = strtrim((text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")))
										if titles[text] then questID, questTitle = titles[text], text break end
									end
								end
							end
						end
					end
					if questID then
						ShowIDCard({kind = L["Quest"], name = questTitle, id = questID, url = "https://" .. LeaPlusLC.WowheadLock .. "/quest=" .. questID, icon = "Interface\\Icons\\INV_Scroll_03", color = colorQuest, view = {mode = "icon", icon = "Interface\\Icons\\INV_Scroll_03", text = QuestText(questID)}, details = QuestDetails(questID)})
						return
					end
					-- Mount journal, pet journal, toy box and appearances (the journal's own buttons hold the mount, pet, toy or appearance, and their tooltips are not found as items, spells or units below)
					-- The buttons, models and pet card are only read, never changed
					do
						local focus = GetMouseFoci and GetMouseFoci()[1]
						if focus and CollectionsJournal and CollectionsJournal:IsShown() and not (focus.IsForbidden and focus:IsForbidden()) then
							local mountJournal = MountJournal and MountJournal:IsShown() and MountJournal
							local petJournal = PetJournal and PetJournal:IsShown() and PetJournal
							local toyBox = ToyBox and ToyBox:IsShown() and ToyBox
							local wardrobe = WardrobeCollectionFrame and WardrobeCollectionFrame:IsVisible() and WardrobeCollectionFrame
							local mountID, petID, speciesID, toyID, visualID, visualCollected, sourceID, setID
							-- Look at the frame under the mouse and the frames it is in (such as a pet's icon, which is in the pet's button)
							local frame = focus
							for i = 1, 5 do
								if not frame or frame == CollectionsJournal or (frame.IsForbidden and frame:IsForbidden()) then break end
								if mountJournal then
									local m = Safe(frame.mountID)
									if frame == mountJournal.MountDisplay then m = Safe(mountJournal.selectedMountID) end -- The large mount preview shows the chosen mount
									if type(m) == "number" and m > 0 then mountID = m break end
								end
								if petJournal then
									local p, s = Safe(frame.petID), Safe(frame.speciesID)
									if type(p) == "string" and p ~= "" then petID = p end
									if type(s) == "number" and s > 0 then speciesID = s end
									if petID or speciesID then break end
								end
								if toyBox then
									local t = Safe(frame.itemID) -- (empty slots on the last page have -1)
									if type(t) == "number" and t > 0 then toyID = t break end
								end
								if wardrobe then
									-- Appearances: a model holds its appearance, a piece in a set's details holds its source, a set in the list holds its set
									local visualInfo = SafeTable(frame.visualInfo)
									local v = visualInfo and Safe(visualInfo.visualID)
									if type(v) == "number" and v > 0 then
										if not Safe(visualInfo.isHideVisual) then visualID, visualCollected = v, Safe(visualInfo.isCollected) end -- (not the hidden appearance, which is not an item)
										break
									end
									local s = Safe(frame.sourceID)
									if type(s) == "number" and s > 0 then sourceID = s break end
									local t = Safe(frame.setID)
									if type(t) == "number" and t > 0 then setID = t break end
									-- The large set preview and its details show the chosen set
									local sets = wardrobe.SetsCollectionFrame
									if sets and (frame == sets.Model or frame == sets.DetailsFrame) then
										local chosen = Safe(sets.selectedSetID)
										if type(chosen) == "number" and chosen > 0 then setID = chosen break end
									end
								end
								frame = frame.GetParent and frame:GetParent()
							end
							-- Item link and icon for an appearance source (the game gives a table, older games give separate values)
							local function SourceLinkIcon(id)
								if not (C_TransmogCollection and C_TransmogCollection.GetAppearanceSourceInfo) then return end
								local r1, void, void, r4, void, r6 = C_TransmogCollection.GetAppearanceSourceInfo(id)
								local t = SafeTable(r1)
								if t then return Safe(t.itemLink), Safe(t.icon) end
								r4, r6 = Safe(r4, r6)
								return type(r6) == "string" and r6 or nil, r4
							end
							-- Appearance model: an appearance can come from several items, so use the item its tooltip is showing (Tab changes it),
							-- otherwise one you have collected, otherwise the first
							if visualID and C_TransmogCollection and C_TransmogCollection.GetAllAppearanceSources and C_TransmogCollection.GetSourceInfo then
								local sources = SafeTable(C_TransmogCollection.GetAllAppearanceSources(visualID))
								if sources then
									local tipName
									if GameTooltip:IsShown() then
										local text = Safe(GameTooltipTextLeft1:GetText())
										if type(text) == "string" then tipName = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") end
									end
									local first, collected, shown
									for void, id in ipairs(sources) do
										id = Safe(id)
										local info = type(id) == "number" and SafeTable(C_TransmogCollection.GetSourceInfo(id))
										if info then
											first = first or id
											if not collected and Safe(info.isCollected) then collected = id end
											if tipName and Safe(info.name) == tipName then shown = id break end
										end
									end
									sourceID = shown or collected or first
								end
							end
							-- Appearance card (the same as an item card, using the appearance's source for the item as it may not be in your bags)
							if sourceID and C_TransmogCollection and C_TransmogCollection.GetSourceInfo then
								local source = SafeTable(C_TransmogCollection.GetSourceInfo(sourceID))
								local itemID = source and Safe(source.itemID)
								if type(itemID) == "number" and itemID > 0 then
									local itemLink, sourceIcon = SourceLinkIcon(sourceID)
									local GetInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
									local itemName, infoLink, itemQuality, void, void, void, void, void, void, itemIcon = Safe(GetInfo(itemLink or itemID))
									itemLink = itemLink or infoLink
									itemName = itemName or Safe(source.name)
									itemQuality = itemQuality or Safe(source.quality)
									itemIcon = itemIcon or sourceIcon or (C_Item and C_Item.GetItemIconByID and Safe(C_Item.GetItemIconByID(itemID))) or (GetItemIcon and Safe(GetItemIcon(itemID)))
									if type(itemName) == "string" and itemName ~= "" then
										local qualityColor = type(itemQuality) == "number" and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[itemQuality]
										local nameColor = qualityColor and {qualityColor.r, qualityColor.g, qualityColor.b} or {1, 1, 1}
										local appearanceID = visualID or Safe(source.visualID)
										if type(appearanceID) ~= "number" or appearanceID <= 0 then appearanceID = nil end
										local appearanceDetails = itemLink and ItemDetails(itemLink) or {}
										local isCollected = visualCollected
										if isCollected == nil then isCollected = Safe(source.isCollected) end
										if isCollected ~= nil then tinsert(appearanceDetails, 1, isCollected and L["Collected"] or L["Not collected"]) end
										local tryLink = itemLink or ("item:" .. itemID)
										local appearanceView = {mode = IsEquippable(tryLink) and "item" or "icon", link = tryLink, icon = itemIcon}
										ShowIDCard({sounds = {itemID = itemID}, kind = L["Appearance"], name = itemName, id = itemID, note = appearanceID and (L["Appearance ID"] .. " |cffffffff" .. appearanceID .. "|r") or nil, url = "https://" .. LeaPlusLC.WowheadLock .. "/item=" .. itemID, icon = itemIcon, color = nameColor, nameColor = nameColor, view = appearanceView, details = appearanceDetails})
										return
									end
								end
							end
							-- Appearance set card (the model viewer shows every piece of the set on your character)
							if setID and C_TransmogSets and C_TransmogSets.GetSetInfo then
								local setInfo = SafeTable(C_TransmogSets.GetSetInfo(setID))
								local setName = setInfo and Safe(setInfo.name)
								if type(setName) == "string" and setName ~= "" then
									local links, total, owned, setIcon = {}, 0, 0, nil
									local pieces = C_TransmogSets.GetSetPrimaryAppearances and SafeTable(C_TransmogSets.GetSetPrimaryAppearances(setID))
									if pieces then
										for void, piece in ipairs(pieces) do
											piece = SafeTable(piece)
											local id = piece and Safe(piece.appearanceID)
											if type(id) == "number" and id > 0 then
												total = total + 1
												if Safe(piece.collected) then owned = owned + 1 end
												local link, icon = SourceLinkIcon(id)
												tinsert(links, link or id) -- (the model can try on a source by its ID too)
												setIcon = setIcon or icon
											end
										end
									end
									local setDetails = {}
									if total > 0 then tinsert(setDetails, L["Collected"] .. " |cffffffff" .. owned .. "/" .. total .. "|r") end
									local label, description = Safe(setInfo.label), Safe(setInfo.description)
									if type(label) == "string" and label ~= "" then tinsert(setDetails, label) end
									if type(description) == "string" and description ~= "" then tinsert(setDetails, description) end
									setIcon = setIcon or "Interface\\Icons\\INV_Chest_Cloth_17"
									ShowIDCard({kind = L["Appearance set"], name = setName, id = setID, url = "https://" .. LeaPlusLC.WowheadLock .. "/transmog-set=" .. setID, icon = setIcon, color = {1, 0.5, 0.8}, view = #links > 0 and {mode = "item", links = links, icon = setIcon} or nil, details = setDetails})
									return
								end
							end
							-- Toy card (the same as an item card, using the toy box for the name, icon and link as the toy may not be in your bags)
							if toyID and C_ToyBox and C_ToyBox.GetToyInfo then
								local void, toyName, toyIcon, void, void, toyQuality = Safe(C_ToyBox.GetToyInfo(toyID))
								local toyLink = C_ToyBox.GetToyLink and Safe(C_ToyBox.GetToyLink(toyID))
								local GetInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
								local itemName, itemLink, itemQuality, void, void, void, void, void, void, itemIcon = Safe(GetInfo(toyID))
								toyLink = (type(toyLink) == "string" and toyLink ~= "") and toyLink or itemLink
								toyName = (type(toyName) == "string" and toyName ~= "") and toyName or itemName
								toyIcon = toyIcon or itemIcon
								toyQuality = toyQuality or itemQuality
								if toyName then
									local qualityColor = toyQuality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[toyQuality]
									local nameColor = qualityColor and {qualityColor.r, qualityColor.g, qualityColor.b} or {1, 1, 1}
									-- The toy's own tooltip (only if it is the one the toy box is showing for this toy)
									local toyTip = GameTooltip:IsShown() and GameTooltip:GetOwner() == focus and GameTooltip or nil
									local toyDetails = toyLink and ItemDetails(toyLink, toyTip) or {}
									if PlayerHasToy then
										local hasToy = Safe(PlayerHasToy(toyID))
										if hasToy ~= nil then tinsert(toyDetails, 1, hasToy and L["Collected"] or L["Not collected"]) end
									end
									local toyView = {mode = toyLink and IsEquippable(toyLink) and "item" or "icon", link = toyLink, icon = toyIcon, text = ItemFlavour(toyTip)}
									ShowIDCard({sounds = {itemID = toyID}, kind = L["Toy"], name = toyName, id = toyID, url = "https://" .. LeaPlusLC.WowheadLock .. "/item=" .. toyID, icon = toyIcon, color = nameColor, nameColor = nameColor, view = toyView, details = toyDetails})
									return
								end
							end
							-- Mount card (linked to the mount's spell on Wowhead, which is also what Leatrix Sounds uses for its sounds)
							if mountID and C_MountJournal and C_MountJournal.GetMountInfoByID then
								local mountName, spellID, mountIcon, void, void, void, void, void, void, void, isCollected = Safe(C_MountJournal.GetMountInfoByID(mountID))
								if mountName then
									local displayID, description
									if C_MountJournal.GetMountInfoExtraByID then displayID, description = Safe(C_MountJournal.GetMountInfoExtraByID(mountID)) end
									if (type(displayID) ~= "number" or displayID <= 0) and C_MountJournal.GetMountAllCreatureDisplayInfoByID then
										local all = SafeTable(C_MountJournal.GetMountAllCreatureDisplayInfoByID(mountID))
										displayID = all and all[1] and Safe(all[1].creatureDisplayID)
									end
									if type(displayID) ~= "number" or displayID <= 0 then displayID = nil end
									if type(description) ~= "string" or description == "" then description = nil end
									if type(spellID) ~= "number" or spellID <= 0 then spellID = nil end
									local mountColor = {0.8, 0.6, 1}
									local mountDetails = {}
									if isCollected ~= nil then tinsert(mountDetails, isCollected and L["Collected"] or L["Not collected"]) end
									ShowIDCard({sounds = spellID and {spellID = spellID}, kind = L["Mount"], name = mountName, id = spellID or mountID, note = spellID and (L["Mount ID"] .. " |cffffffff" .. mountID .. "|r") or nil, url = spellID and ("https://" .. LeaPlusLC.WowheadLock .. "/spell=" .. spellID) or nil, icon = mountIcon, color = mountColor, view = displayID and {mode = "unit", displayID = displayID, text = description} or nil, details = mountDetails})
									return
								end
							end
							-- Pet card (a collected pet uses its own name and look, a pet which is not collected uses its species)
							if (petID or speciesID) and C_PetJournal then
								local petName, petIcon, creatureID, displayID, description, customName, collected
								if petID and C_PetJournal.GetPetInfoByPetID then
									local s, cName, void, void, void, disp, void, pName, pIcon, void, cID, void, desc = Safe(C_PetJournal.GetPetInfoByPetID(petID))
									if s then speciesID, customName, displayID, petName, petIcon, creatureID, description, collected = s, cName, disp, pName, pIcon, cID, desc, true end
								end
								if speciesID and C_PetJournal.GetPetInfoBySpeciesID then
									local sName, sIcon, void, cID, void, sDesc, void, void, void, void, void, sDisp = Safe(C_PetJournal.GetPetInfoBySpeciesID(speciesID))
									petName, petIcon, creatureID, description, displayID = petName or sName, petIcon or sIcon, creatureID or cID, description or sDesc, displayID or sDisp
									if collected == nil and C_PetJournal.GetNumCollectedInfo then
										local count = Safe(C_PetJournal.GetNumCollectedInfo(speciesID))
										if type(count) == "number" then collected = count > 0 end
									end
								end
								if type(petName) == "string" and petName ~= "" then
									if type(creatureID) ~= "number" or creatureID <= 0 then creatureID = nil end
									if type(displayID) ~= "number" or displayID <= 0 then displayID = nil end
									if type(description) ~= "string" or description == "" then description = nil end
									-- A pet with its own name shows that, with the species name next to the ID
									local title, petNote = petName, nil
									if type(customName) == "string" and customName ~= "" then title, petNote = customName, petName end
									local petColor = {0.4, 0.85, 0.85}
									local petDetails = {}
									if collected ~= nil then tinsert(petDetails, collected and L["Collected"] or L["Not collected"]) end
									ShowIDCard({sounds = (creatureID or displayID) and {npcID = creatureID, displayID = displayID, name = title} or nil, kind = L["Pet"], name = title, id = creatureID or speciesID, note = petNote, url = creatureID and ("https://" .. LeaPlusLC.WowheadLock .. "/npc=" .. creatureID) or nil, icon = petIcon, color = petColor, view = (creatureID or displayID) and {mode = "unit", npcID = creatureID, displayID = displayID, text = description} or nil, details = petDetails})
									return
								end
							end
						end
					end
					-- ItemRefTooltip or GameTooltip
					local tooltip
					if ItemRefTooltip:IsMouseMotionFocus() then tooltip = ItemRefTooltip else tooltip = GameTooltip end
					-- Process tooltip
					if not tooltip:IsShown() then return end
					-- Buff or debuff (tooltip data, such as the buff frame)
					local tipData = SafeTable(tooltip.GetTooltipData and tooltip:GetTooltipData())
					if tipData and Safe(tipData.type) == Enum.TooltipDataType.UnitAura then
						local auraID = tipData.id
						if IsSecret(auraID) then
							-- Hidden by the game: show its name, ID and link without reading them
							local titleLine = _G[tooltip:GetName() .. "TextLeft1"]
							ShowHiddenAuraCard(auraID, titleLine and titleLine:GetText())
							return
						end
						if auraID then
							local auraName = Safe((C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(auraID)) or (GetSpellInfo and GetSpellInfo(auraID))) or Safe(GameTooltipTextLeft1:GetText()) or ""
							-- Debuff if the player or target has a debuff with this spell ID, otherwise buff
							local auraType = "Buff"
							for void, unit in ipairs({"player", "target"}) do
								if UnitExists(unit) then
									for i = 1, 40 do
										local aura, done = GetAura(unit, i, true)
										if done then break end
										if aura and Safe(aura.spellId) == auraID then auraType = "Debuff" break end
									end
								end
							end
							pickerUnit = nil -- Aura found so the aura picker is not needed
							ShowIDCard({sounds = {spellID = auraID}, kind = L[auraType], name = auraName, id = auraID, url = "https://" .. LeaPlusLC.WowheadLock .. "/spell=" .. auraID, icon = SpellIcon(auraID), color = auraType == "Debuff" and colorDebuff or colorBuff, view = {mode = "icon", icon = SpellIcon(auraID), text = SpellText(auraID)}, details = AuraDetails(nil, auraID)})
							return
						end
					end
					-- Item
					local itemLink = Safe(select(2, tooltip:GetItem()))
					if itemLink then
						local itemID = Safe(GetItemInfoFromHyperlink(itemLink))
						if itemID then
							local GetInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
							local itemName, void, itemQuality, void, void, void, void, void, void, itemIcon = Safe(GetInfo(itemLink))
							local qualityColor = itemQuality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[itemQuality]
							local nameColor = qualityColor and {qualityColor.r, qualityColor.g, qualityColor.b} or {1, 1, 1}
							itemIcon = itemIcon or (C_Item and C_Item.GetItemIconByID and Safe(C_Item.GetItemIconByID(itemID))) or (GetItemIcon and Safe(GetItemIcon(itemID)))
							ShowIDCard({sounds = {itemID = itemID}, kind = L["Item"], name = itemName or itemLink, id = itemID, url = "https://" .. LeaPlusLC.WowheadLock .. "/item=" .. itemID, icon = itemIcon, color = nameColor, nameColor = nameColor, view = {mode = IsEquippable(itemLink) and "item" or "icon", link = itemLink, icon = itemIcon, text = ItemFlavour(tooltip)}, details = ItemDetails(itemLink, tooltip)})
							return
						end
					end
					-- Spell
					local name, spellID = Safe(tooltip:GetSpell())
					if name and spellID then
						ShowIDCard({sounds = {spellID = spellID}, kind = L["Spell"], name = name, id = spellID, url = "https://" .. LeaPlusLC.WowheadLock .. "/spell=" .. spellID, icon = SpellIcon(spellID), color = colorSpell, view = {mode = "icon", icon = SpellIcon(spellID), text = SpellText(spellID)}, details = SpellDetails(spellID)})
						return
					end
					-- Buff or debuff (match the tooltip title against auras on likely units)
					if not WorldFrame:IsMouseMotionFocus() then
						local titleLine = _G[tooltip:GetName() .. "TextLeft1"]
						local auraTitle = titleLine and Safe(titleLine:GetText())
						if auraTitle then
							local auraUnits = {}
							local tipUnit = Safe(select(2, tooltip:GetUnit()))
							if tipUnit then tinsert(auraUnits, tipUnit) end
							for void, unit in ipairs({"player", "target", "focus", "pet", "party1", "party2", "party3", "party4"}) do tinsert(auraUnits, unit) end
							for void, unit in ipairs(auraUnits) do
								if UnitExists(unit) then
									for void, auraType in ipairs({"Buff", "Debuff"}) do
										for i = 1, 40 do
											local aura, done = GetAura(unit, i, auraType == "Debuff")
											if done then break end
											local auraName, auraID = aura and Safe(aura.name), aura and Safe(aura.spellId)
											if auraName and auraID and auraName == auraTitle then
												local auraIcon = Safe(aura.icon) or SpellIcon(auraID)
												pickerUnit = nil -- Aura found so the aura picker is not needed
												ShowIDCard({sounds = {spellID = auraID}, kind = L[auraType], name = auraName, id = auraID, url = "https://" .. LeaPlusLC.WowheadLock .. "/spell=" .. auraID, icon = auraIcon, color = auraType == "Debuff" and colorDebuff or colorBuff, view = {mode = "icon", icon = auraIcon, text = SpellText(auraID)}, details = AuraDetails(aura.sourceUnit, auraID)})
												return
											end
										end
									end
								end
							end
						end
					end
					-- NPC (the name can be hidden in combat, the card is still shown)
					local npcName = Safe(UnitName("mouseover"))
					local npcGuid = Safe(UnitGUID("mouseover"))
					if not npcGuid then
						-- The mouseover unit is not always set yet, so use the creature in the tooltip itself
						local unitData = SafeTable(tooltip.GetTooltipData and tooltip:GetTooltipData())
						local dataGUID = unitData and Safe(unitData.type) == Enum.TooltipDataType.Unit and Safe(unitData.guid)
						if type(dataGUID) == "string" and (dataGUID:find("^Creature%-") or dataGUID:find("^Vehicle%-") or dataGUID:find("^Pet%-")) then
							npcGuid = dataGUID
							if not npcName then
								local title = Safe(GameTooltipTextLeft1:GetText())
								if type(title) == "string" then npcName = title:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") end
							end
						end
					end
					if type(npcGuid) == "string" then
						local void, void, void, void, void, npcID = strsplit("-", npcGuid)
						if npcID then
							local reaction = Safe(UnitReaction("mouseover", "player"))
							local reactionColor = reaction and FACTION_BAR_COLORS and FACTION_BAR_COLORS[reaction]
							local npcColor = reactionColor and {reactionColor.r, reactionColor.g, reactionColor.b} or {1, 0.82, 0}
							local npcLevel = Safe(UnitLevel("mouseover"))
							local npcNote
							if type(npcLevel) == "number" then
								if npcLevel > 0 then npcNote = L["Level"] .. " " .. npcLevel else npcNote = L["Level"] .. " ??" end
							end
							local classification = Safe(UnitClassification("mouseover"))
							if npcNote and (classification == "elite" or classification == "worldboss") then npcNote = npcNote .. " " .. L["Elite"] elseif npcNote and classification == "rareelite" then npcNote = npcNote .. " " .. L["Rare Elite"] elseif npcNote and classification == "rare" then npcNote = npcNote .. " " .. L["Rare"] end
							ShowIDCard({sounds = {unit = "mouseover", npcID = npcID, name = npcName}, kind = L["NPC"], name = npcName or L["Name not available right now"], id = npcID, url = "https://" .. LeaPlusLC.WowheadLock .. "/npc=" .. npcID, unit = "mouseover", color = npcColor, nameColor = npcColor, note = npcNote, view = {mode = "unit", unit = "mouseover", guid = npcGuid, npcID = npcID, text = NPCText(tooltip)}})
							return
						end
					end
					-- Pet, player and unknown tooltip (this must be last)
					if not GameTooltipTextLeft1:GetText() then return end
					-- Show armory link for players outside zhCN
					local unitFocus
					if WorldFrame:IsMouseMotionFocus() then unitFocus = "mouseover" else unitFocus = Safe(select(2, GameTooltip:GetUnit())) end
					if not unitFocus and UnitExists("mouseover") then unitFocus = "mouseover" end
					if unitFocus and Safe(UnitIsPlayer(unitFocus)) then
						ShowPlayerCard(unitFocus)
						return
					end
					-- Unknown tooltip
					-- A new player or creature can take a moment to load, so try again a few times before giving up
					if (UnitExists("mouseover") or WorldFrame:IsMouseMotionFocus() or GameTooltip:GetUnit()) and (LeaPlusLC.IDRetries or 0) < 4 then
						LeaPlusLC.IDRetries = (LeaPlusLC.IDRetries or 0) + 1
						local pressID = LeaPlusLC.IDPressID
						C_Timer.After(0.15, function() if LeaPlusLC.IDPressID == pressID then ShowInfoCard("retry") end end) -- Not if the key has been pressed again since
						return
					end
					LeaPlusLC.IDRetries = 0
					-- A player the game has not finished loading as a unit: always show a player card using the player in the tooltip itself
					-- (fill in what is known now, then refresh the card once the game has loaded the player)
					local unitData = SafeTable(GameTooltip.GetTooltipData and GameTooltip:GetTooltipData())
					local dataGUID = unitData and Safe(unitData.type) == Enum.TooltipDataType.Unit and Safe(unitData.guid)
					if type(dataGUID) == "string" and dataGUID:find("^Player%-") then
						local localizedClass, classFile, playerName, playerRealm
						if GetPlayerInfoByGUID then
							local void
							localizedClass, classFile, void, void, void, playerName, playerRealm = Safe(GetPlayerInfoByGUID(dataGUID))
						end
						if not classFile and Safe(UnitGUID("mouseover")) == dataGUID then
							classFile, localizedClass = Safe(UnitClassBase("mouseover")), Safe(UnitClass("mouseover"))
						end
						local classColor = classFile and RAID_CLASS_COLORS[classFile]
						local playerColor = classColor and {classColor.r, classColor.g, classColor.b} or {0.6, 0.6, 0.65}
						-- Name (the tooltip title already includes the surname on Forever)
						local titleName = (Safe(GameTooltipTextLeft1:GetText()) or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
						local displayName, realmText = titleName, isForever and "" or (Safe(GetRealmName()) or "") -- Forever realms are hidden from players
						if playerName and playerName ~= "" then
							displayName = playerName
							if isForever and playerRealm and playerRealm ~= "" then displayName = playerName .. " " .. playerRealm
							elseif playerRealm and playerRealm ~= "" then realmText = playerRealm end
						end
						if displayName == "" then displayName = L["Name not available right now"] end
						local armoryLink
						if isForever then
							armoryLink = ForeverArmoryLink(playerName, playerRealm)
							local mouseLevel = Safe(UnitGUID("mouseover")) == dataGUID and Safe(UnitLevel("mouseover"))
							if type(mouseLevel) == "number" and mouseLevel > 0 and mouseLevel < 10 then armoryLink = nil end -- Forever armory does not list characters under level 10
						elseif GameLocale ~= "zhCN" and playerName and playerName ~= "" then
							local realmSlug = ((playerRealm and playerRealm ~= "") and playerRealm or Safe(GetNormalizedRealmName()) or ""):gsub("(%l)(%u)", "%1-%2"):gsub("'", ""):gsub(" ", "-")
							armoryLink = LeaPlusLC.BlizzardLock .. strlower(realmSlug) .. "/" .. strlower(playerName)
						end
						local coords = classFile and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classFile]
						local subText = localizedClass and (localizedClass .. (realmText ~= "" and ("    " .. realmText) or "")) or realmText
						ShowIDCard({kind = L["Player"], name = displayName, sub = subText, url = armoryLink, icon = coords and "Interface\\TargetingFrame\\UI-Classes-Circles" or 134400, iconCoords = coords, color = playerColor, nameColor = playerColor, view = {mode = "unit", isPlayer = true, guid = dataGUID}, details = PlayerDetails(nil, dataGUID)})
						-- Refresh the card shortly (twice at most) while the mouse is still over the same player, to get the full card
						if (LeaPlusLC.IDUpgrades or 0) < 2 then
							LeaPlusLC.IDUpgrades = (LeaPlusLC.IDUpgrades or 0) + 1
							C_Timer.After(0.4, function()
								if LeaPlusLC.IDCard and LeaPlusLC.IDCard:IsShown() and Safe(UnitGUID("mouseover")) == dataGUID then
									LeaPlusLC.IDRetries = 0
									ShowInfoCard("upgrade")
								end
							end)
						end
						return
					end
					-- Anything else is not known, so show nothing
				end
				ShowCardForMouse()
				-- Aura picker: list the buffs and debuffs of the hovered unit frame (addons cannot tell which aura icon is under the mouse)
				local function ShowAuraPicker()
					-- Collect auras (auras the game hides are left out)
					local auras = {}
					for void, auraType in ipairs({"Buff", "Debuff"}) do
						for i = 1, 40 do
							local aura, done = GetAura(pickerUnit, i, auraType == "Debuff")
							if done then break end
							local auraName, auraID, auraIcon = aura and Safe(aura.name), aura and Safe(aura.spellId), aura and Safe(aura.icon)
							if auraName and auraID and auraIcon then
								tinsert(auras, {auraType = auraType, name = auraName, spellID = auraID, icon = auraIcon, source = Safe(aura.sourceUnit)})
							end
						end
					end
					if #auras == 0 then return end
					-- Show the card for an aura and mark it in the list
					local picker
					local function ShowAuraLink(info)
						ShowIDCard({sounds = {spellID = info.spellID}, kind = L[info.auraType], name = info.name, id = info.spellID, url = "https://" .. LeaPlusLC.WowheadLock .. "/spell=" .. info.spellID, icon = info.icon, color = info.auraType == "Debuff" and colorDebuff or colorBuff, view = {mode = "icon", icon = info.icon, text = SpellText(info.spellID)}, details = AuraDetails(info.source, info.spellID)})
						if LeaPlusLC.AuraPicker then
							for void, row in ipairs(LeaPlusLC.AuraPicker.rows) do row.selected:SetShown(row.info == info) end
						end
					end
					-- If nothing else is showing (such as a buff icon), start with the first aura
					local startWithFirst = not LeaPlusLC.IDCard or not LeaPlusLC.IDCard:IsShown()
					if startWithFirst then ShowAuraLink(auras[1]) end
					local card = LeaPlusLC.IDCard
					-- Create the picker (a child of the card so it closes with it)
					local cols, rowHeight = 2, 26
					local colWidth = (480 - 24) / cols
					picker = LeaPlusLC.AuraPicker
					if not picker then
						picker = CreateFrame("Frame", nil, card, "BackdropTemplate")
						LeaPlusLC.AuraPicker = picker
						picker:SetPoint("BOTTOMLEFT", card, "TOPLEFT", 0, 6) -- Above the card so it does not cover the action bars
						picker:SetPoint("BOTTOMRIGHT", card, "TOPRIGHT", 0, 6)
						picker:EnableMouse(true)
						picker:SetScript("OnMouseDown", function(self, btn) if btn == "RightButton" then card:Hide() end end)
						picker:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = OnePixel()})
						picker:SetBackdropColor(0.06, 0.06, 0.08, 0.96)
						picker:SetBackdropBorderColor(1, 1, 1, 0.12)
						picker.title = picker:CreateFontString(nil, "OVERLAY", "GameFontNormal")
						picker.title:SetPoint("TOPLEFT", picker, "TOPLEFT", 14, -10)
						picker.hint = picker:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
						picker.hint:SetPoint("TOPRIGHT", picker, "TOPRIGHT", -14, -12)
						picker.hint:SetText(L["Click a buff or debuff to show its link."])
						picker.rows = {}
					end
					-- Name (on Forever, players' second name is their surname)
					local pickerName, pickerSurname = Safe(UnitName(pickerUnit))
					if isForever and pickerName and pickerSurname and pickerSurname ~= "" and Safe(UnitIsPlayer(pickerUnit)) then pickerName = pickerName .. " " .. pickerSurname end
					picker.title:SetText(pickerName or "")
					-- Fill the rows
					for i, info in ipairs(auras) do
						local row = picker.rows[i]
						if not row then
							row = CreateFrame("Button", nil, picker)
							row:SetSize(colWidth - 4, rowHeight - 2)
							row.bg = row:CreateTexture(nil, "BACKGROUND")
							row.bg:SetAllPoints()
							row.bg:SetColorTexture(1, 1, 1, 0.03)
							row.selected = row:CreateTexture(nil, "BORDER")
							row.selected:SetAllPoints()
							row.selected:SetColorTexture(1, 1, 1, 0.1)
							row.icon = row:CreateTexture(nil, "ARTWORK")
							row.icon:SetSize(rowHeight - 6, rowHeight - 6)
							row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)
							row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
							row.text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
							row.text:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
							row.text:SetPoint("RIGHT", row, "RIGHT", -6, 0)
							row.text:SetJustifyH("LEFT")
							row.text:SetWordWrap(false)
							row:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
							row:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.08)
							row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
							row:SetScript("OnClick", function(self, btn)
								if btn == "RightButton" then card:Hide() else ShowAuraLink(self.info) end
							end)
							picker.rows[i] = row
						end
						row.info = info
						row.icon:SetTexture(info.icon)
						if info.auraType == "Debuff" then row.text:SetTextColor(1, 0.45, 0.45) else row.text:SetTextColor(0.45, 1, 0.55) end
						row.text:SetText(info.name .. "  |cff8a8a90" .. info.spellID .. "|r")
						row.selected:SetShown(startWithFirst and i == 1)
						row:ClearAllPoints()
						row:SetPoint("TOPLEFT", picker, "TOPLEFT", 12 + ((i - 1) % cols) * colWidth, -34 - math.floor((i - 1) / cols) * rowHeight)
						row:Show()
					end
					for i = #auras + 1, #picker.rows do picker.rows[i]:Hide() end
					picker:SetHeight(34 + math.ceil(#auras / cols) * rowHeight + 10)
					picker:Show()
				end
				if pickerUnit then ShowAuraPicker() end
			end

			-- Hidden button that the key clicks (the key is bound to it in the addon code, no Bindings.xml entry needed)
			local InfoButton = CreateFrame("Button", "LeaPlusGlobalInfoButton", UIParent)
			InfoButton:Hide()
			InfoButton:RegisterForClicks("AnyDown")
			InfoButton:SetScript("OnClick", function()
				-- The game reports Ctrl as not held while a key binding is being handled, so remember whether the key includes Ctrl
				local key = LeaPlusLC["InfoCardKey"] or ""
				LeaPlusLC.IDKeyHasCtrl = (key:find("CTRL%-") or key:find("META%-")) and true or nil
				ShowInfoCard()
				LeaPlusLC.IDKeyHasCtrl = nil
			end)

			-- Show the card for a player unit (used by the dressing room)
			LeaPlusLC.ShowInfoCardForUnit = function(unit) ShowInfoCard(nil, unit) end

			-- Create configuration panel
			local InfoCardPanel = LeaPlusLC:CreatePanel("Show info cards", "InfoCardPanel")

			-- Key section
			LeaPlusLC:MakeTx(InfoCardPanel, "Key", 16, -72)
			local keyText = LeaPlusLC:MakeWD(InfoCardPanel, "", 16, -92)
			keyText:SetWidth(530)

			local setBtn = LeaPlusLC:CreateButton("InfoCardSetKeyBtn", InfoCardPanel, "Set key", "TOPLEFT", 16, -116, 0, 25, true, "Click, then press the key you want to use.|n|nYou can include Shift, Ctrl or Alt.|n|nPress Escape to cancel.|n|nThis does not change your saved key bindings.  If the key already does something, it will go back to doing that when you clear the key or turn this option off.")
			local clearBtn = LeaPlusLC:CreateButton("InfoCardClearKeyBtn", InfoCardPanel, "Clear key", "TOPLEFT", 16, -116, 0, 25, true, "Click to remove the key.  Anything the key did before will work again.")
			clearBtn:ClearAllPoints()

			-- Make the set key button wide enough for both of its labels
			setBtn.f:SetText(L["Press a key"])
			local wideLabel = setBtn.f:GetStringWidth()
			setBtn.f:SetText(L["Set key"])
			setBtn:SetWidth(math.max(wideLabel, setBtn.f:GetStringWidth()) + 20)
			clearBtn:SetPoint("LEFT", setBtn, "RIGHT", 10, 0)

			-- How to use section
			LeaPlusLC:MakeTx(InfoCardPanel, "How to use", 16, -162)
			local howText = LeaPlusLC:MakeWD(InfoCardPanel, "Point at a player, NPC, item, spell, buff or quest and press the key.  A card will show its details and a link to it on Wowhead.|n|nWhile the card is showing, hold Ctrl and press C to copy the link, then paste it into your web browser.", 16, -182)
			howText:SetWidth(530)
			howText:SetWordWrap(true)
			howText:SetSpacing(2)

			-- Show the current key
			local function KeyName(key)
				return GetBindingText and GetBindingText(key) or key
			end

			local listening = false
			local applyPending = false

			-- Apply the keybind
			local function ApplyKey()
				if InCombatLockdown() then
					applyPending = true
					return
				end
				applyPending = false
				ClearOverrideBindings(InfoCardPanel)
				if LeaPlusLC["ShowInfoCards"] == "On" and LeaPlusLC["InfoCardKey"] ~= "" then
					SetOverrideBindingClick(InfoCardPanel, false, LeaPlusLC["InfoCardKey"], "LeaPlusGlobalInfoButton")
				end
			end

			local function Refresh()
				if listening then
					keyText:SetText(L["Press the key you want to use (Escape to cancel)."])
					setBtn:SetText(L["Press a key"])
					return
				end
				setBtn:SetText(L["Set key"])
				local text
				if LeaPlusLC["InfoCardKey"] ~= "" then
					text = L["Current key"] .. ": |cff00ff00" .. KeyName(LeaPlusLC["InfoCardKey"]) .. "|r"
					clearBtn:Enable()
				else
					text = L["Current key"] .. ": |cffff8080" .. L["None"] .. "|r"
					clearBtn:Disable()
				end
				keyText:SetText(text)
			end

			local function StopListening()
				listening = false
				setBtn:EnableKeyboard(false)
				Refresh()
			end

			-- Capture the next key pressed
			local modifierKeys = {LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LALT = true, RALT = true, LMETA = true, RMETA = true}

			setBtn:SetScript("OnKeyDown", function(self, key)
				if not listening then return end
				if modifierKeys[key] then return end
				if key == "ESCAPE" then
					StopListening()
					return
				end
				if InCombatLockdown() then
					StopListening()
					LeaPlusLC:Print("You cannot do that in combat.")
					return
				end
				local combo = (IsAltKeyDown() and "ALT-" or "") .. (IsControlKeyDown() and "CTRL-" or "") .. (IsShiftKeyDown() and "SHIFT-" or "") .. (IsMetaKeyDown and IsMetaKeyDown() and "META-" or "") .. key
				local oldAction = GetBindingAction(combo)
				LeaPlusLC["InfoCardKey"] = combo
				ApplyKey()
				if oldAction and oldAction ~= "" then
					local oldName = _G["BINDING_NAME_" .. oldAction] or oldAction
					LeaPlusLC:Print(L["Key set to"] .. " " .. KeyName(combo) .. ".  " .. L["It normally does"] .. " " .. oldName .. ", " .. L["and will again when you clear the key."])
				else
					LeaPlusLC:Print(L["Key set to"] .. " " .. KeyName(combo) .. ".")
				end
				StopListening()
			end)

			-- Setting a key script turns keyboard input on by itself, so turn it off until the button is clicked
			setBtn:EnableKeyboard(false)

			setBtn:SetScript("OnClick", function()
				if InCombatLockdown() then
					LeaPlusLC:Print("You cannot do that in combat.")
					return
				end
				if listening then
					StopListening()
				else
					listening = true
					setBtn:EnableKeyboard(true)
					setBtn:SetPropagateKeyboardInput(false)
					Refresh()
				end
			end)

			clearBtn:SetScript("OnClick", function()
				if InCombatLockdown() then
					LeaPlusLC:Print("You cannot do that in combat.")
					return
				end
				LeaPlusLC["InfoCardKey"] = ""
				ApplyKey()
				Refresh()
			end)

			-- Turning the option on or off sets or removes the key
			LeaPlusCB["ShowInfoCards"]:HookScript("OnClick", ApplyKey)

			InfoCardPanel:HookScript("OnShow", Refresh)
			InfoCardPanel:HookScript("OnHide", function() if listening then StopListening() end end)
			InfoCardPanel:RegisterEvent("UPDATE_BINDINGS")
			InfoCardPanel:RegisterEvent("PLAYER_REGEN_DISABLED")
			InfoCardPanel:RegisterEvent("PLAYER_REGEN_ENABLED")
			InfoCardPanel:SetScript("OnEvent", function(self, event)
				if event == "PLAYER_REGEN_DISABLED" then
					-- Entering combat, stop listening so key presses reach the game
					if listening then StopListening() end
				elseif event == "PLAYER_REGEN_ENABLED" then
					-- Set the key if it could not be set during combat
					if applyPending then ApplyKey() end
				elseif InfoCardPanel:IsShown() then
					Refresh()
				end
			end)

			-- Set the key now
			ApplyKey()

			-- Help and reset buttons hidden
			InfoCardPanel.h:Hide()
			InfoCardPanel.r:Hide()

			-- Back button handler
			InfoCardPanel.b:SetScript("OnClick", function()
				InfoCardPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page5"]:Show()
				return
			end)

			-- Show configuration panel when options panel button is clicked
			LeaPlusCB["ShowInfoCardsBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile (nothing to set)
				else
					InfoCardPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		-- Show range coloring
		----------------------------------------------------------------------

		if LeaPlusLC["ShowRangeColoring"] == "On" then

			-- Colors (red, green, blue, desaturate)
			local stateColors = {
				normal		= {1.0, 1.0, 1.0, false},	-- Usable
				range		= {1.0, 0.3, 0.1, true},	-- Out of range
				mana		= {0.1, 0.3, 1.0, true},	-- Not enough mana
				unusable	= {0.4, 0.4, 0.4, false},	-- Not usable
			}

			-- Upvalues
			local IsActionInRange, IsUsableAction, GetActionInfo, GetMacroInfo, GetMacroSpell = IsActionInRange, IsUsableAction, GetActionInfo, GetMacroInfo, GetMacroSpell
			local IsSpellUsable = C_Spell and C_Spell.IsSpellUsable or IsUsableSpell
			local hooksecurefunc, pairs, strsub, issecretvalue = hooksecurefunc, pairs, strsub, issecretvalue

			-- Function to check for secret values (secret values can never be compared or tested)
			local function IsSecret(a, b, c)
				if not issecretvalue then return false end
				return issecretvalue(a) or issecretvalue(b) or issecretvalue(c)
			end

			-- Button data is stored locally (nothing is written onto the game's action buttons)
			local iconStates = {}		-- Icon texture -> last applied state
			local hotkeyStates = {}		-- Hotkey text -> last applied state
			local actionButtons = {}	-- Button -> true if it is one of the game's action buttons (false if not)
			local petButtons = {}		-- Pet buttons

			-- Function to check if a button is one of the game's action buttons (read from the game's own list, then remembered)
			local function IsActionButton(button)
				local known = actionButtons[button]
				if known ~= nil then return known end
				local found = false
				ActionBarButtonEventsFrame:ForEachFrame(function(frame) if frame == button then found = true end end)
				actionButtons[button] = found
				return found
			end

			----------------------------------------------------------------------
			-- Coloring
			----------------------------------------------------------------------

			-- Function to color an icon
			local function SetIconState(icon, state)
				iconStates[icon] = state
				local c = stateColors[state]
				icon:SetVertexColor(c[1], c[2], c[3])
				icon:SetDesaturated(c[4])
			end

			-- Function to color a hotkey
			local function SetHotkeyState(hotkey, state)
				hotkeyStates[hotkey] = state
				local c = stateColors[state]
				hotkey:SetVertexColor(c[1], c[2], c[3])
			end

			-- Function to get the state of an action slot (second return is true if out of range)
			-- (returns nil if anything needed is a secret value so the button is left alone)
			local function GetActionState(slot)
				if not slot or IsSecret(slot) then return end
				local isUsable, notEnoughMana
				-- Macros with names starting with # use the macro spell for the mana check
				local actionType, id = GetActionInfo(slot)
				if not IsSecret(actionType, id) and actionType == "macro" then
					local name = GetMacroInfo(id)
					if name and not IsSecret(name) and strsub(name, 1, 1) == "#" then
						local spellID = GetMacroSpell(id)
						if spellID and not IsSecret(spellID) then
							isUsable, notEnoughMana = IsSpellUsable(spellID)
						end
					end
				end
				if isUsable == nil then
					isUsable, notEnoughMana = IsUsableAction(slot)
				end
				local inRange = IsActionInRange(slot)
				if IsSecret(isUsable, notEnoughMana, inRange) then return end
				local outOfRange = inRange == false
				if isUsable then
					return outOfRange and "range" or "normal", outOfRange
				elseif notEnoughMana then
					return "mana", outOfRange
				end
				return "unusable", outOfRange
			end

			-- Function to get the state of a pet action
			local function GetPetActionState(index)
				local void, void, void, void, void, void, spellID, checksRange, inRange = GetPetActionInfo(index)
				if IsSecret(spellID, checksRange, inRange) then return end
				local outOfRange = checksRange and not inRange
				local isUsable, notEnoughMana
				if spellID then
					isUsable, notEnoughMana = IsSpellUsable(spellID)
				else
					isUsable, notEnoughMana = GetPetActionSlotUsable(index), false
				end
				if IsSecret(isUsable, notEnoughMana) then return end
				if isUsable then
					return outOfRange and "range" or "normal"
				elseif notEnoughMana then
					return "mana"
				end
				return "unusable"
			end

			-- Function to color an action button (runs after the game colors it)
			local function UpdateActionButton(button)
				local state, outOfRange = GetActionState(button.action)
				if not state then return end
				SetIconState(button.icon, state)
				SetHotkeyState(button.HotKey, outOfRange and "range" or "normal")
			end

			-- Function to update range coloring when the game says the range has changed
			-- (only switches between usable and out of range, other states are left alone)
			local function UpdateRange(button, checksRange, inRange)
				if not (petButtons[button] or IsActionButton(button)) or IsSecret(checksRange, inRange) then return end
				local outOfRange = checksRange and not inRange
				local icon, hotkey = button.icon, button.HotKey
				local state = iconStates[icon]
				if state == "normal" and outOfRange then
					SetIconState(icon, "range")
				elseif state == "range" and not outOfRange then
					SetIconState(icon, "normal")
				end
				state = hotkeyStates[hotkey]
				if state == "normal" and outOfRange then
					SetHotkeyState(hotkey, "range")
				elseif state == "range" and not outOfRange then
					SetHotkeyState(hotkey, "normal")
				end
			end

			-- Function to color the pet bar
			local function UpdatePetBar(bar)
				if not PetHasActionBar() then return end
				for index, button in pairs(bar.actionButtons) do
					local icon = button.icon
					if icon:IsVisible() then
						local state = GetPetActionState(index)
						if state then
							SetIconState(icon, state)
						end
					end
				end
			end

			----------------------------------------------------------------------
			-- Setup
			----------------------------------------------------------------------

			-- Nothing is hooked onto the action buttons themselves (they are secure), only the game's shared functions and events are used,
			-- and the game's own attack flash is left alone

			-- Function to check if the game has colored an icon since it was last colored here (it colors a button when the button changes)
			local abs = math.abs
			local function IconWasReset(icon)
				local state = iconStates[icon]
				if not state then return true end
				local c = stateColors[state]
				local r, g, b = icon:GetVertexColor()
				if IsSecret(r, g, b) then return false end
				return abs(r - c[1]) > 0.01 or abs(g - c[2]) > 0.01 or abs(b - c[3]) > 0.01
			end

			-- Action buttons: the game updates a button's cooldown straight after it colors the button when the button changes, so the
			-- button is colored again after that (cooldowns also change on their own every global cooldown, so the button is only colored
			-- again if the game has actually changed its color, which is a single quick check)
			hooksecurefunc("ActionButton_UpdateCooldown", function(button)
				local icon = button.icon
				if icon and IconWasReset(icon) and IsActionButton(button) then UpdateActionButton(button) end
			end)

			-- Range changes are event driven (the game calls this from ACTION_RANGE_CHECK_UPDATE)
			hooksecurefunc("ActionButton_UpdateRangeIndicator", UpdateRange)

			-- Usable changes (such as running out of mana): the game colors the buttons for these slots, so they are colored again a moment later
			local usableFrame = CreateFrame("FRAME")
			local dirtySlots, usableQueued = {}, false
			local function UpdateDirtySlots()
				usableQueued = false
				ActionBarButtonEventsFrame:ForEachFrame(function(button)
					local slot = button.action
					if slot and not IsSecret(slot) and dirtySlots[slot] then UpdateActionButton(button) end
				end)
				wipe(dirtySlots)
			end
			usableFrame:RegisterEvent("ACTION_USABLE_CHANGED")
			usableFrame:SetScript("OnEvent", function(self, event, changes)
				if type(changes) ~= "table" or IsSecret(changes) then return end
				for void, change in ipairs(changes) do
					local slot = change.slot
					if slot and not IsSecret(slot) then dirtySlots[slot] = true end
				end
				if not usableQueued then
					usableQueued = true
					C_Timer.After(0, UpdateDirtySlots)
				end
			end)

			-- Pet bar: colored again a moment after the game updates it (when the pet bar changes or pet power changes)
			if PetActionBar and PetActionBar.actionButtons then
				for void, button in pairs(PetActionBar.actionButtons) do
					petButtons[button] = true
				end
				local petFrame = CreateFrame("FRAME")
				local petQueued = false
				local function UpdatePetLater()
					if petQueued then return end
					petQueued = true
					C_Timer.After(0, function()
						petQueued = false
						UpdatePetBar(PetActionBar)
					end)
				end
				petFrame:RegisterEvent("PET_BAR_UPDATE")
				petFrame:RegisterEvent("PET_BAR_UPDATE_USABLE")
				petFrame:RegisterEvent("PET_UI_UPDATE")
				petFrame:RegisterUnitEvent("UNIT_PET", "player")
				petFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", "pet")
				petFrame:SetScript("OnEvent", UpdatePetLater)
			end

			-- Color everything once at startup
			C_Timer.After(1 / 30, function()
				ActionBarButtonEventsFrame:ForEachFrame(UpdateActionButton)
				if PetActionBar and PetActionBar.actionButtons then
					UpdatePetBar(PetActionBar)
				end
			end)

		end

		----------------------------------------------------------------------
		-- Simple addon list
		----------------------------------------------------------------------

		if LeaPlusLC["SimpleAddonListing"] == "On" then

			-- Strip Wow color codes
			local function StripColors(s) return (s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") end

			-- Build, filter, sort and feed the list in one pass
			local function UpdateList()
				local provider   = CreateTreeDataProvider()
				local filter     = AddonList.SearchBox:GetText():lower()
				local groups     = {}

				for i = 1, C_AddOns.GetNumAddOns() do
					local name, title = C_AddOns.GetAddOnInfo(i)
					local group = C_AddOns.GetAddOnMetadata(i, "Group") or name
					local searchable = (StripColors(title or name) .. StripColors(group)):lower()

					if filter == "" or searchable:find(filter, 1, true) then
						groups[group] = groups[group] or {parent = {addonIndex = i}, children = {}}
						if name == group then
							groups[group].parent = {addonIndex = i}
						else
							table.insert(groups[group].children, {addonIndex = i})
						end
					end
				end

				-- Sort groups alphabetically (ignoring color codes)
				local sortedGroups = {}
				for g in pairs(groups) do table.insert(sortedGroups, g) end
				table.sort(sortedGroups, function(a, b) return StripColors(a):lower() < StripColors(b):lower() end)

				-- Insert sorted groups and their sorted children into the provider
				for void, gName in ipairs(sortedGroups) do
					local node = provider:Insert(groups[gName].parent)

					local ch = groups[gName].children
					table.sort(ch, function(a, b)
						local aT = StripColors(select(2, C_AddOns.GetAddOnInfo(a.addonIndex)) or ""):lower()
						local bT = StripColors(select(2, C_AddOns.GetAddOnInfo(b.addonIndex)) or ""):lower()
						return aT < bT
					end)

					for void, child in ipairs(ch) do node:Insert(child) end
				end

				AddonList.ScrollBox:SetDataProvider(provider, ScrollBoxConstants.RetainScrollPosition)
				AddonList.ScrollBox:Show()
			end

			AddonList.SearchBox:HookScript("OnTextChanged", UpdateList)
			hooksecurefunc("AddonList_Update", UpdateList)
			AddonList:HookScript("OnShow", function()
				AddonList.ScrollBox:Hide()
				C_Timer.After(0, UpdateList)
			end)

		end

		----------------------------------------------------------------------
		-- Set edit mode layout
		----------------------------------------------------------------------

		do

			-- Create configuration panel
			local LayoutPanel = LeaPlusLC:CreatePanel("Set edit mode layout", "LayoutPanel")

			local titleTX = LeaPlusLC:MakeTx(LayoutPanel, "Layout name", 16, -72)
			local LayoutBox = LeaPlusLC:CreateEditBox("LayoutBox", LayoutPanel, 500, 40, "TOPLEFT", 20, -92, "LayoutBox", "LayoutBox")

			LeaPlusLC:CreateHelpButton("EditModeLayoutNameHelpButton", LayoutPanel, titleTX, "If the edit mode layout name that you enter here exists, that layout will be applied when you login to any character on your account.")

			-- Apply the layout on login if it is not already active
			if LeaPlusLC["SetEditModeLayout"] == "On" then

				local function TryApplyLayout()
					local wanted = strtrim(tostring(LeaPlusLC["EditModeLayoutName"] or "")):lower()
					if wanted == "" then return true end
					if not EditModeManagerFrame or not EditModeManagerFrame.layoutInfo then return false end
					local layouts = EditModeManagerFrame:GetLayouts()
					if type(layouts) ~= "table" or #layouts == 0 then return false end
					local active = EditModeManagerFrame:GetActiveLayoutInfo()
					for index, layout in ipairs(layouts) do
						if layout.layoutName and layout.layoutName:lower() == wanted then
							if not (active and active.layoutName and active.layoutName:lower() == wanted) then
								C_EditMode.SetActiveLayout(index)
								LeaPlusLC:Print(L["Edit Mode layout"] .. " '" .. layout.layoutName .. "' " .. L["applied"])
							end
							return true
						end
					end
					return true
				end

				-- Layouts already loaded (e.g. after /reload)
				if not TryApplyLayout() then
					-- Cold login: wait until the layouts arrive, then apply once
					local f = CreateFrame("Frame")
					local done = false
					f:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
					f:SetScript("OnEvent", function(self)
						C_Timer.After(0, function()
							if done then return end
							if TryApplyLayout() then
								done = true
								self:UnregisterAllEvents()
							end
						end)
					end)
				end

			end

			-- Function to save the keyword
			local function SetEditModeName()
				local LayoutText = LayoutBox:GetText()
				if LayoutText and LayoutText ~= "" then
					LeaPlusLC["EditModeLayoutName"] = strtrim(LayoutBox:GetText())
				else
					LeaPlusLC["EditModeLayoutName"] = ""
				end
			end

			-- Save the keyword when it changes
			LayoutBox:SetScript("OnTextChanged", SetEditModeName)

			-- Refresh editbox with trimmed keyword when edit focus is lost (removes additional spaces)
			LayoutBox:SetScript("OnEditFocusLost", function()
				LayoutBox:SetText(LeaPlusLC["EditModeLayoutName"])
			end)

			-- Help button hidden
			LayoutPanel.h:Hide()

			-- Back button handler
			LayoutPanel.b:SetScript("OnClick", function()
				-- Save the keyword
				SetEditModeName()
				-- Show the options panel
				LayoutPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page8"]:Show()
				return
			end)

			-- Add reset button
			LayoutPanel.r:SetScript("OnClick", function()
				-- Reset the keyword to default
				LeaPlusLC["EditModeLayoutName"] = ""
				-- Set the editbox to default
				LayoutBox:SetText("")
				-- Save the keyword
				SetEditModeName()
				-- Refresh panel
				LayoutPanel:Hide(); LayoutPanel:Show()
			end)

			-- Ensure keyword is a string on startup
			LeaPlusLC["EditModeLayoutName"] = tostring(LeaPlusLC["EditModeLayoutName"] or "")

			-- Set editbox value when shown
			LayoutBox:HookScript("OnShow", function()
				LayoutBox:SetText(LeaPlusLC["EditModeLayoutName"])
			end)

			-- Configuration button handler
			LeaPlusCB["SetEditModeLayoutBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["EditModeLayoutName"] = "Main"
					LayoutBox:SetText(LeaPlusLC["EditModeLayoutName"])
					SetEditModeName()
				else
					-- Show panel
					LayoutPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		-- Block requested invites (no reload required)
		----------------------------------------------------------------------

		do

			local frame = CreateFrame("FRAME")
			frame:SetScript("OnEvent", function()
				if LeaPlusLC["NoRequestedInvites"] == "On" then
					local groupInvitePopUp = StaticPopup_FindVisible("GROUP_INVITE_CONFIRMATION")
					if groupInvitePopUp and groupInvitePopUp.data then
						local void, name, guid = GetInviteConfirmationInfo(groupInvitePopUp.data)
						if LeaPlusLC:FriendCheck(name, guid) then
							return
						else
							-- If not a friend, decline
							RespondToInviteConfirmation(groupInvitePopUp.data, false)
							StaticPopup_Hide("GROUP_INVITE_CONFIRMATION")
						end
					end
				end
			end)

			-- Function to set event
			local function SetEvent()
				if LeaPlusLC["NoRequestedInvites"] == "On" then
					frame:RegisterEvent("GROUP_INVITE_CONFIRMATION")
				else
					frame:UnregisterEvent("GROUP_INVITE_CONFIRMATION")
				end
			end

			-- Set event on startup if enabled and when option is clicked
			if LeaPlusLC["NoRequestedInvites"] == "On" then SetEvent() end
			LeaPlusCB["NoRequestedInvites"]:HookScript("OnClick", SetEvent)

		end

		----------------------------------------------------------------------
		-- Block friend requests (no reload required)
		----------------------------------------------------------------------

		do

			-- Function to decline friend requests
			local function DeclineReqs()
				if LeaPlusLC["NoFriendRequests"] == "On" then
					for i = BNGetNumFriendInvites(), 1, -1 do
						local inviteInfo = C_BattleNet.GetFriendInviteInfo(i)
						if inviteInfo.inviteID and inviteInfo.accountName then
							BNDeclineFriendInvite(inviteInfo.inviteID)
							C_Timer.After(0.1, function()
								LeaPlusLC:Print(L["A friend request from"] .. " " .. inviteInfo.accountName .. " " .. L["was automatically declined."])
							end)
						end
					end
				end
			end

			-- Event frame for incoming friend requests
			local DecEvt = CreateFrame("FRAME")
			DecEvt:SetScript("OnEvent", DeclineReqs)

			-- Function to register or unregister the event
			local function ControlEvent()
				if LeaPlusLC["NoFriendRequests"] == "On" then
					DecEvt:RegisterEvent("BN_FRIEND_INVITE_ADDED")
					DeclineReqs()
				else
					DecEvt:UnregisterEvent("BN_FRIEND_INVITE_ADDED")
				end
			end

			-- Set event status when option is clicked and on startup
			LeaPlusCB["NoFriendRequests"]:HookScript("OnClick", ControlEvent)
			ControlEvent()

		end

		----------------------------------------------------------------------
		--	Block duels (no reload required)
		----------------------------------------------------------------------

		do

			-- Handler for event
			local frame = CreateFrame("FRAME")
			frame:SetScript("OnEvent", function(self, event, arg1)
				if not LeaPlusLC:FriendCheck(arg1) then
					CancelDuel()
					StaticPopup_Hide("DUEL_REQUESTED")
					return
				end
			end)

			-- Function to set event
			local function SetEvent()
				if LeaPlusLC["NoDuelRequests"] == "On" then
					frame:RegisterEvent("DUEL_REQUESTED")
				else
					frame:UnregisterEvent("DUEL_REQUESTED")
				end
			end

			-- Set event on startup if enabled and when option is clicked
			if LeaPlusLC["NoDuelRequests"] == "On" then SetEvent() end
			LeaPlusCB["NoDuelRequests"]:HookScript("OnClick", SetEvent)

		end

		----------------------------------------------------------------------
		--	Invite from whispers (no reload required)
		----------------------------------------------------------------------

		do

			local frame = CreateFrame("FRAME")
			frame:SetScript("OnEvent", function(self, event, arg1, arg2, ...)
				if not canaccessvalue(arg1) or not canaccessvalue(arg2) then return end
				if (not UnitExists("party1") or UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) and strlower(strtrim(arg1)) == strlower(LeaPlusLC["InvKey"]) then
					if not LeaPlusLC:IsInLFGQueue() then
						if event == "CHAT_MSG_WHISPER" then
							local void, void, void, void, void, void, void, void, void, guid = ...
							if LeaPlusLC:FriendCheck(arg2, guid) or LeaPlusLC["InviteFriendsOnly"] == "Off" then
								-- If whisper name is same realm, remove realm name
								local theWhisperName, theWhisperRealm = strsplit("-", arg2, 2)
								if theWhisperRealm then
									local void, theCharRealm = UnitFullName("player")
									if theCharRealm then
										if theWhisperRealm == theCharRealm then arg2 = theWhisperName end
									end
								end

								-- Invite whisper player
								C_PartyInfo.InviteUnit(arg2)
							end
						elseif event == "CHAT_MSG_BN_WHISPER" then
							local presenceID = select(11, ...)
							if presenceID and BNIsFriend(presenceID) then
								local index = BNGetFriendIndex(presenceID)
								if index then
									local accountInfo = C_BattleNet.GetFriendAccountInfo(index)
									local gameAccountInfo = accountInfo.gameAccountInfo
									local gameAccountID = gameAccountInfo.gameAccountID
									if gameAccountID then
										C_BattleNet.InviteFriend(gameAccountID)
									end
								end
							end
						end
					end
				end
				return
			end)

			-- Function to set event
			local function SetEvent()
				if LeaPlusLC["InviteFromWhisper"] == "On" then
					frame:RegisterEvent("CHAT_MSG_WHISPER")
					frame:RegisterEvent("CHAT_MSG_BN_WHISPER")
				else
					frame:UnregisterEvent("CHAT_MSG_WHISPER")
					frame:UnregisterEvent("CHAT_MSG_BN_WHISPER")
				end
			end

			-- Set event on startup if enabled and when option is clicked
			if LeaPlusLC["InviteFromWhisper"] == "On" then SetEvent() end
			LeaPlusCB["InviteFromWhisper"]:HookScript("OnClick", SetEvent)

			-- Create configuration panel
			local InvPanel = LeaPlusLC:CreatePanel("Invite from whispers", "InvPanel")

			-- Add editbox
			LeaPlusLC:MakeTx(InvPanel, "Settings", 16, -72)
			LeaPlusLC:MakeCB(InvPanel, "InviteFriendsOnly", "Restrict to friends", 16, -92, false, "If checked, group invites will only be sent to friends.|n|nIf unchecked, group invites will be sent to everyone.")

			LeaPlusLC:MakeTx(InvPanel, "Keyword", 356, -72)
			local KeyBox = LeaPlusLC:CreateEditBox("KeyBox", InvPanel, 140, 10, "TOPLEFT", 356, -92, "KeyBox", "KeyBox")

			-- Function to show the keyword in the option tooltip
			local function SetKeywordTip()
				LeaPlusCB["InviteFromWhisper"].tiptext = gsub(LeaPlusCB["InviteFromWhisper"].tiptext, "(|cffffffff)[^|]*(|r)",  "%1" .. LeaPlusLC["InvKey"] .. "%2")
			end

			-- Function to save the keyword
			local function SetInvKey()
				local keytext = KeyBox:GetText()
				if keytext and keytext ~= "" then
					LeaPlusLC["InvKey"] = strtrim(KeyBox:GetText())
				else
					LeaPlusLC["InvKey"] = "inv"
				end
				-- Show the keyword in the option tooltip
				SetKeywordTip()
			end

			-- Show the keyword in the option tooltip on startup
			SetKeywordTip()

			-- Save the keyword when it changes
			KeyBox:SetScript("OnTextChanged", SetInvKey)

			-- Refresh editbox with trimmed keyword when edit focus is lost (removes additional spaces)
			KeyBox:SetScript("OnEditFocusLost", function()
				KeyBox:SetText(LeaPlusLC["InvKey"])
			end)

			-- Help button hidden
			InvPanel.h:Hide()

			-- Back button handler
			InvPanel.b:SetScript("OnClick", function()
				-- Save the keyword
				SetInvKey()
				-- Show the options panel
				InvPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page2"]:Show()
				return
			end)

			-- Add reset button
			InvPanel.r:SetScript("OnClick", function()
				-- Settings
				LeaPlusLC["InviteFriendsOnly"] = "Off"
				-- Reset the keyword to default
				LeaPlusLC["InvKey"] = "inv"
				-- Set the editbox to default
				KeyBox:SetText("inv")
				-- Save the keyword
				SetInvKey()
				-- Refresh panel
				InvPanel:Hide(); InvPanel:Show()
			end)

			-- Ensure keyword is a string on startup
			LeaPlusLC["InvKey"] = tostring(LeaPlusLC["InvKey"]) or "inv"

			-- Set editbox value when shown
			KeyBox:HookScript("OnShow", function()
				KeyBox:SetText(LeaPlusLC["InvKey"])
			end)

			-- Configuration button handler
			LeaPlusCB["InvWhisperBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["InviteFriendsOnly"] = "On"
					LeaPlusLC["InvKey"] = "inv"
					KeyBox:SetText(LeaPlusLC["InvKey"])
					SetInvKey()
				else
					-- Show panel
					InvPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		--	Party from friends (no reload required)
		----------------------------------------------------------------------

		do

			local frame = CreateFrame("FRAME")
			frame:SetScript("OnEvent", function(self, event, arg1, ...)

				-- If a friend, accept if you're accepting friends and not queued
				local void, void, void, void, void, guid = ...
				if (LeaPlusLC["AcceptPartyFriends"] == "On" and LeaPlusLC:FriendCheck(arg1, guid)) then
					if not LeaPlusLC:IsInLFGQueue() then
						AcceptGroup()
						StaticPopup_ForEachShownDialog(function(self)
							if self.which == "PARTY_INVITE" then
								self.inviteAccepted = 1
								StaticPopup_Hide("PARTY_INVITE")
								return
							elseif self.which == "PARTY_INVITE_XREALM" then
								self.inviteAccepted = 1
								StaticPopup_Hide("PARTY_INVITE_XREALM")
								return
							end
						end)
						-- Confirm invite to party sync group request
						if QuestSessionManager.ConfirmInviteToGroupReceivedDialog.ButtonContainer.Confirm:IsShown() then
							QuestSessionManager.ConfirmInviteToGroupReceivedDialog.ButtonContainer.Confirm:Click()
						end
						return
					end
				end
				return

			end)

			-- Function to set event
			local function SetEvent()
				if LeaPlusLC["AcceptPartyFriends"] == "On" then
					frame:RegisterEvent("PARTY_INVITE_REQUEST")
				else
					frame:UnregisterEvent("PARTY_INVITE_REQUEST")
				end
			end

			-- Set event on startup if enabled and when option is clicked
			if LeaPlusLC["AcceptPartyFriends"] == "On" then SetEvent() end
			LeaPlusCB["AcceptPartyFriends"]:HookScript("OnClick", SetEvent)

		end
		----------------------------------------------------------------------
		--	Block party invites (no reload required)
		----------------------------------------------------------------------

		do

			local frame = CreateFrame("FRAME")
			frame:SetScript("OnEvent", function(self, event, arg1, ...)
				-- If not a friend and you're blocking invites, decline
				local void, void, void, void, void, guid = ...
				if LeaPlusLC["NoPartyInvites"] == "On" then
					if LeaPlusLC:FriendCheck(arg1, guid) then
						return
					else
						DeclineGroup()
						StaticPopup_Hide("PARTY_INVITE")
						StaticPopup_Hide("PARTY_INVITE_XREALM")
						-- Decline invite to party sync group request
						if QuestSessionManager.ConfirmInviteToGroupReceivedDialog.ButtonContainer.Decline:IsShown() then
							QuestSessionManager.ConfirmInviteToGroupReceivedDialog.ButtonContainer.Decline:Click()
						end
						return
					end
				end
				return
			end)

			-- Function to set event
			local function SetEvent()
				if LeaPlusLC["NoPartyInvites"] == "On" then
					frame:RegisterEvent("PARTY_INVITE_REQUEST")
				else
					frame:UnregisterEvent("PARTY_INVITE_REQUEST")
				end
			end

			-- Set event on startup if enabled and when option is clicked
			if LeaPlusLC["NoPartyInvites"] == "On" then SetEvent() end
			LeaPlusCB["NoPartyInvites"]:HookScript("OnClick", SetEvent)

		end

		----------------------------------------------------------------------
		--	Automatic summon (no reload required)
		----------------------------------------------------------------------

		do

			-- Event function
			local frame = CreateFrame("FRAME")
			frame:SetScript("OnEvent", function(self, event, arg1)
				if not UnitAffectingCombat("player") then
					local sName = C_SummonInfo.GetSummonConfirmSummoner()
					local sLocation = C_SummonInfo.GetSummonConfirmAreaName()
					LeaPlusLC:Print(L["The summon from"] .. " " .. sName .. " (" .. sLocation .. ") " .. L["will be automatically accepted in 10 seconds unless cancelled."])
					C_Timer.After(10, function()
						local sNameNew = C_SummonInfo.GetSummonConfirmSummoner()
						local sLocationNew = C_SummonInfo.GetSummonConfirmAreaName()
						if sName == sNameNew and sLocation == sLocationNew then
							-- Automatically accept summon after 10 seconds if summoner name and location have not changed
							C_SummonInfo.ConfirmSummon()
							StaticPopup_Hide("CONFIRM_SUMMON")
						end
					end)
				end
				return
			end)

			-- Function to set event
			local function SetEvent()
				if LeaPlusLC["AutoAcceptSummon"] == "On" then
					frame:RegisterEvent("CONFIRM_SUMMON")
				else
					frame:UnregisterEvent("CONFIRM_SUMMON")
				end
			end

			-- Set event on startup if enabled and when option is clicked
			if LeaPlusLC["AutoAcceptSummon"] == "On" then SetEvent() end
			LeaPlusCB["AutoAcceptSummon"]:HookScript("OnClick", SetEvent)

		end

		----------------------------------------------------------------------
		--	Disable loot warnings (no reload required)
		----------------------------------------------------------------------

		do

			local frame = CreateFrame("FRAME")
			frame:SetScript("OnEvent", function(self, event, arg1, arg2, ...)

				-- Disable warnings for attempting to roll Need or Disenchant on loot
				if event == "CONFIRM_LOOT_ROLL" or event == "CONFIRM_DISENCHANT_ROLL" then
					ConfirmLootRoll(arg1, arg2)
					StaticPopup_Hide("CONFIRM_LOOT_ROLL")
					return
				end

				-- Disable warning for attempting to loot a Bind on Pickup item
				if event == "LOOT_BIND_CONFIRM" then
					ConfirmLootSlot(arg1, arg2)
					StaticPopup_Hide("LOOT_BIND",...)
					return
				end

				-- Disable warning for attempting to vendor an item within its refund window
				if event == "MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL" then
					SellCursorItem()
					return
				end

				-- Disable warning for attempting to mail an item within its refund window
				if event == "MAIL_LOCK_SEND_ITEMS" then
					RespondMailLockSendItem(arg1, true)
					return
				end

			end)

			-- Function to set event
			local function SetEvent()
				if LeaPlusLC["NoConfirmLoot"] == "On" then
					frame:RegisterEvent("CONFIRM_LOOT_ROLL")
					frame:RegisterEvent("CONFIRM_DISENCHANT_ROLL")
					frame:RegisterEvent("LOOT_BIND_CONFIRM")
					frame:RegisterEvent("MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL")
					frame:RegisterEvent("MAIL_LOCK_SEND_ITEMS")
				else
					frame:UnregisterEvent("CONFIRM_LOOT_ROLL")
					frame:UnregisterEvent("CONFIRM_DISENCHANT_ROLL")
					frame:UnregisterEvent("LOOT_BIND_CONFIRM")
					frame:UnregisterEvent("MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL")
					frame:UnregisterEvent("MAIL_LOCK_SEND_ITEMS")
				end
			end

			-- Set event on startup if enabled and when option is clicked
			if LeaPlusLC["NoConfirmLoot"] == "On" then SetEvent() end
			LeaPlusCB["NoConfirmLoot"]:HookScript("OnClick", SetEvent)

		end

		----------------------------------------------------------------------
		-- Mute mount sounds (no reload required)
		----------------------------------------------------------------------

		do

			-- Get mute table
			local mountTable = Leatrix_Plus["mountTable"]

			-- Give table file level scope (its used during logout and for wipe and admin commands)
			LeaPlusLC["mountTable"] = mountTable

			-- Load saved settings or set default values
			for k, v in pairs(mountTable) do
				if LeaPlusDB[k] and type(LeaPlusDB[k]) == "string" and LeaPlusDB[k] == "On" or LeaPlusDB[k] == "Off" then
					LeaPlusLC[k] = LeaPlusDB[k]
				else
					LeaPlusLC[k] = "Off"
					LeaPlusDB[k] = "Off"
				end
			end

			-- Create configuration panel
			local MountPanel = LeaPlusLC:CreatePanel("Mute mount sounds", "MountPanel")

			-- Add checkboxes
			LeaPlusLC:MakeTx(MountPanel, "Mounts", 16, -72)
			LeaPlusLC:MakeCB(MountPanel, "MuteAirships", "Airships", 16, -92, false, "If checked, airships will be muted.")
			LeaPlusLC:MakeCB(MountPanel, "MuteHorsesteps", "Horsesteps", 16, -112, false, "If checked, footsteps for horse mounts will be muted.")
			LeaPlusLC:MakeCB(MountPanel, "MuteMechSteps", "Mechsteps", 16, -132, false, "If checked, footsteps for mechanical mounts will be muted.")
			LeaPlusLC:MakeCB(MountPanel, "MuteStriders", "Mechstriders", 16, -152, false, "If checked, mechanostriders will be quieter.")
			LeaPlusLC:MakeCB(MountPanel, "MuteZeppelins", "Zeppelins", 16, -172, false, "If checked, zeppelins will be muted.")

			-- Set click width for sounds checkboxes
			for k, v in pairs(mountTable) do
				LeaPlusCB[k].f:SetWidth(90)
				if LeaPlusCB[k].f:GetStringWidth() > 90 then
					LeaPlusCB[k]:SetHitRectInsets(0, -80, 0, 0)
				else
					LeaPlusCB[k]:SetHitRectInsets(0, -LeaPlusCB[k].f:GetStringWidth() + 4, 0, 0)
				end
			end

			-- Function to mute and unmute sounds
			local function SetupMute()
				for k, v in pairs(mountTable) do
					if LeaPlusLC["MuteMountSounds"] == "On" and LeaPlusLC[k] == "On" then
						for i, e in pairs(v) do
							local file, soundID = e:match("([^,]+)%#([^,]+)")
							MuteSoundFile(soundID)
						end
					else
						for i, e in pairs(v) do
							local file, soundID = e:match("([^,]+)%#([^,]+)")
							UnmuteSoundFile(soundID)
						end
					end
				end
			end

			-- Setup mute on startup if option is enabled
			if LeaPlusLC["MuteMountSounds"] == "On" then SetupMute() end

			-- Mute sounds when UNIT_FACTION is loaded (required for Soar)
			local delayMute = CreateFrame("FRAME")
			delayMute:RegisterEvent("UNIT_FACTION")
			delayMute:SetScript("OnEvent", function() if LeaPlusLC["MuteMountSounds"] == "On" then SetupMute() end end)

			-- Setup mute when options are clicked
			for k, v in pairs(mountTable) do
				LeaPlusCB[k]:HookScript("OnClick", SetupMute)
			end
			LeaPlusCB["MuteMountSounds"]:HookScript("OnClick", SetupMute)

			-- Help button hidden
			MountPanel.h:Hide()

			-- Back button handler
			MountPanel.b:SetScript("OnClick", function()
				MountPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page7"]:Show()
				return
			end)

			-- Reset button handler
			MountPanel.r:SetScript("OnClick", function()

				-- Reset checkboxes
				for k, v in pairs(mountTable) do
					LeaPlusLC[k] = "Off"
				end
				SetupMute()

				-- Refresh panel
				MountPanel:Hide(); MountPanel:Show()

			end)

			-- Show panal when options panel button is clicked
			LeaPlusCB["MuteMountSoundsBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					for k, v in pairs(mountTable) do
						LeaPlusLC[k] = "On"
					end
					SetupMute()
				else
					MountPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		-- Mute game sounds (no reload required)
		----------------------------------------------------------------------

		do

			-- Get mute table
			local muteTable = Leatrix_Plus["muteTable"]

			-- Give table file level scope (its used during logout and for wipe and admin commands)
			LeaPlusLC["muteTable"] = muteTable

			-- Load saved settings or set default values
			for k, v in pairs(muteTable) do
				if LeaPlusDB[k] and type(LeaPlusDB[k]) == "string" and LeaPlusDB[k] == "On" or LeaPlusDB[k] == "Off" then
					LeaPlusLC[k] = LeaPlusDB[k]
				else
					LeaPlusLC[k] = "Off"
					LeaPlusDB[k] = "Off"
				end
			end

			-- Create configuration panel
			local SoundPanel = LeaPlusLC:CreatePanel("Mute game sounds", "SoundPanel")

			-- Add checkboxes
			LeaPlusLC:MakeTx(SoundPanel, "General", 16, -72)
			LeaPlusLC:MakeCB(SoundPanel, "MuteChimes", "Chimes", 16, -92, false, "If checked, clock hourly chimes will be muted.")
			LeaPlusLC:MakeCB(SoundPanel, "MuteFizzle", "Fizzle", 16, -112, false, "If checked, the spell fizzle sounds will be muted.")
			LeaPlusLC:MakeCB(SoundPanel, "MuteInterface", "Interface", 16, -132, false, "If checked, the interface button sound, the chat frame tab click sound and the game menu toggle sound will be muted.")
			LeaPlusLC:MakeCB(SoundPanel, "MuteLogin", "Login", 16, -152, false, "If checked, login screen sounds will be muted when you logout of the game.|n|nNote that login screen sounds will not be muted when you initially launch the game.|n|nThey will only be muted when you logout of the game.  This includes manually logging out as well as being forcefully logged out by the game server for reasons such as being away for an extended period of time.")
			LeaPlusLC:MakeCB(SoundPanel, "MuteReady", "Ready", 16, -172, false, "If checked, the ready check sound will be muted.")
			LeaPlusLC:MakeCB(SoundPanel, "MuteTrains", "Trains", 16, -192, false, "If checked, train sounds will be muted.")
			LeaPlusLC:MakeCB(SoundPanel, "MuteVaults", "Vaults", 16, -212, false, "If checked, the mechanical guild vault idle sound will be muted.")

			LeaPlusLC:MakeTx(SoundPanel, "Items", 150, -72)
			LeaPlusLC:MakeCB(SoundPanel, "MutePiccolo", "Piccolo", 150, -92, false, "If checked, Piccolo of the Flaming Fire wil be muted.|n|nNote that enabling this will also mute the harp sound of the warlock seduction spell.")

			LeaPlusLC:MakeTx(SoundPanel, "Misc", 150, -132)
			LeaPlusLC:MakeCB(SoundPanel, "MuteYawns", "Yawns", 150, -152, false, "If checked, yawns from hunter pet cats will be muted.")

			-- Set click width for sounds checkboxes
			for k, v in pairs(muteTable) do
				LeaPlusCB[k].f:SetWidth(90)
				if LeaPlusCB[k].f:GetStringWidth() > 90 then
					LeaPlusCB[k]:SetHitRectInsets(0, -80, 0, 0)
				else
					LeaPlusCB[k]:SetHitRectInsets(0, -LeaPlusCB[k].f:GetStringWidth() + 4, 0, 0)
				end
			end

			-- Function to mute and unmute sounds
			local function SetupMute()
				for k, v in pairs(muteTable) do
					if LeaPlusLC["MuteGameSounds"] == "On" and LeaPlusLC[k] == "On" then
						for i, e in pairs(v) do
							local file, soundID = e:match("([^,]+)%#([^,]+)")
							MuteSoundFile(soundID)
						end
					else
						for i, e in pairs(v) do
							local file, soundID = e:match("([^,]+)%#([^,]+)")
							UnmuteSoundFile(soundID)
						end
					end
				end
			end

			-- Setup mute on startup if option is enabled
			if LeaPlusLC["MuteGameSounds"] == "On" then SetupMute() end

			-- Setup mute when options are clicked
			for k, v in pairs(muteTable) do
				LeaPlusCB[k]:HookScript("OnClick", SetupMute)
			end
			LeaPlusCB["MuteGameSounds"]:HookScript("OnClick", SetupMute)

			-- Help button hidden
			SoundPanel.h:Hide()

			-- Back button handler
			SoundPanel.b:SetScript("OnClick", function()
				SoundPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page7"]:Show()
				return
			end)

			-- Reset button handler
			SoundPanel.r:SetScript("OnClick", function()

				-- Reset checkboxes
				for k, v in pairs(muteTable) do
					LeaPlusLC[k] = "Off"
				end
				SetupMute()

				-- Refresh panel
				SoundPanel:Hide(); SoundPanel:Show()

			end)

			-- Show panal when options panel button is clicked
			LeaPlusCB["MuteGameSoundsBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					for k, v in pairs(muteTable) do
						LeaPlusLC[k] = "On"
					end
					LeaPlusLC["MuteReady"] = "Off"
					LeaPlusLC["MuteVigor"] = "Off"
					SetupMute()
				else
					SoundPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

			----------------------------------------------------------------------
			-- Login setting
			----------------------------------------------------------------------

			-- Handle sounds that get muted or unmuted when logging out
			local muteLogoutTable = Leatrix_Plus["muteLogoutTable"]
			local logoutEvent = CreateFrame("FRAME")
			logoutEvent:RegisterEvent("PLAYER_LOGOUT")

			-- Mute or unmute sounds when logging out
			logoutEvent:SetScript("OnEvent", function()
				if LeaPlusLC["MuteGameSounds"] == "On" and LeaPlusLC["MuteLogin"] == "On" then
					-- Mute logout table sounds on logout
					for void, soundID in pairs(muteLogoutTable) do
						MuteSoundFile(soundID)
					end
				else
					-- Unmute logout table sounds on logout
					for void, soundID in pairs(muteLogoutTable) do
						UnmuteSoundFile(soundID)
					end
				end
			end)

			-- Unmute sounds when logging in
			for void, soundID in pairs(muteLogoutTable) do
				UnmuteSoundFile(soundID)
			end

		end

		----------------------------------------------------------------------
		-- Faster movie skip
		----------------------------------------------------------------------

		if LeaPlusLC["FasterMovieSkip"] == "On" then

			-- Allow space bar, escape key and enter key to cancel cinematic without confirmation
			CinematicFrame:HookScript("OnKeyDown", function(self, key)
				if key == "ESCAPE" then
					if CinematicFrame:IsShown() and CinematicFrame.closeDialog and CinematicFrameCloseDialogConfirmButton then
						CinematicFrameCloseDialog:Hide()
					end
				end
			end)
			CinematicFrame:HookScript("OnKeyUp", function(self, key)
				if key == "SPACE" or key == "ESCAPE" or key == "ENTER" then
					if CinematicFrame:IsShown() and CinematicFrame.closeDialog and CinematicFrameCloseDialogConfirmButton then
						CinematicFrameCloseDialogConfirmButton:Click()
					end
				end
			end)
			MovieFrame:HookScript("OnKeyUp", function(self, key)
				if key == "SPACE" or key == "ESCAPE" or key == "ENTER" then
					if MovieFrame.CloseDialog.Buttons.ConfirmButton then
						MovieFrame.CloseDialog.Buttons.ConfirmButton:Click()
					end
				end
			end)

		end

		----------------------------------------------------------------------
		-- Wowhead Links
		----------------------------------------------------------------------

		if LeaPlusLC["ShowWowheadLinks"] == "On" then

			-- Create configuration panel
			local WowheadPanel = LeaPlusLC:CreatePanel("Show Wowhead links", "WowheadPanel")

			LeaPlusLC:MakeTx(WowheadPanel, "Settings", 16, -72)
			LeaPlusLC:MakeCB(WowheadPanel, "WowheadLinkComments", "Links go directly to the comments section", 16, -92, false, "If checked, Wowhead links will go directly to the comments section.")

			-- Help button hidden
			WowheadPanel.h:Hide()

			-- Back button handler
			WowheadPanel.b:SetScript("OnClick", function()
				WowheadPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page5"]:Show()
				return
			end)

			-- Reset button handler
			WowheadPanel.r:SetScript("OnClick", function()

				-- Reset controls
				LeaPlusLC["WowheadLinkComments"] = "Off"

				-- Refresh configuration panel
				WowheadPanel:Hide(); WowheadPanel:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			LeaPlusCB["ShowWowheadLinksBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["WowheadLinkComments"] = "Off"
				else
					WowheadPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

			-- Get localised Wowhead URL
			local wowheadLoc
			if GameLocale == "deDE" then wowheadLoc = "wowhead.com/forever/de"
			elseif GameLocale == "esMX" then wowheadLoc = "wowhead.com/forever/mx"
			elseif GameLocale == "esES" then wowheadLoc = "wowhead.com/forever/es"
			elseif GameLocale == "frFR" then wowheadLoc = "wowhead.com/forever/fr"
			elseif GameLocale == "itIT" then wowheadLoc = "wowhead.com/forever/it"
			elseif GameLocale == "ptBR" then wowheadLoc = "wowhead.com/forever/pt"
			elseif GameLocale == "ruRU" then wowheadLoc = "wowhead.com/forever/ru"
			elseif GameLocale == "koKR" then wowheadLoc = "wowhead.com/forever/ko"
			elseif GameLocale == "zhCN" then wowheadLoc = "wowhead.com/forever/cn"
			elseif GameLocale == "zhTW" then wowheadLoc = "wowhead.com/forever/tw"
			else							 wowheadLoc = "wowhead.com/forever"
			end

			----------------------------------------------------------------------
			-- Legacy challenges (achievements frame in other games)
			----------------------------------------------------------------------

			-- Achievement link function
			EventUtil.ContinueOnAddOnLoaded("Blizzard_LegacySystem",function()

				local scrollBox = LegacySystemFrame.ChallengesPage.DetailPane.ScrollBox

				-- Create editbox (bottom right of the frame, in the same strata as the challenge list and above it)
				local aEB = CreateFrame("EditBox", nil, LegacySystemFrame.ChallengesPage)
				aEB:SetFrameStrata(scrollBox:GetFrameStrata())
				aEB:SetFrameLevel(scrollBox:GetFrameLevel() + 100)
				aEB:ClearAllPoints()
				aEB:SetPoint("TOP", LegacySystemFrame.ChallengesPage.LegacyChallengePointSummary, "BOTTOM", 0, 6)
				aEB:SetHeight(16)
				aEB:SetFontObject("GameFontNormalSmall")
				aEB:SetBlinkSpeed(0)
				aEB:SetJustifyH("CENTER")
				aEB:SetAutoFocus(false)
				aEB:EnableKeyboard(false)
				aEB:SetHitRectInsets(45, 45, 0, 0)
				aEB:SetScript("OnKeyDown", function() end)
				aEB:SetScript("OnMouseUp", function()
					if aEB:IsMouseOver() then
						aEB:HighlightText()
					else
						aEB:HighlightText(0, 0)
					end
				end)
				aEB:Hide()

				-- Create hidden font string (used for setting width of editbox)
				aEB.z = aEB:CreateFontString(nil, 'ARTWORK', 'GameFontNormalSmall')
				aEB.z:Hide()

				-- Store last link in case editbox is cleared
				local lastAchievementLink

				-- Function to set editbox value
				local function SetAchievementFunc(achievementID)
					if achievementID then
						-- Set editbox text
						if LeaPlusLC["WowheadLinkComments"] == "On" then
							aEB:SetText("https://" .. wowheadLoc .. "/achievement=" .. achievementID .. "#comments")
						else
							aEB:SetText("https://" .. wowheadLoc .. "/achievement=" .. achievementID)
						end
						lastAchievementLink = aEB:GetText()
						-- Set hidden fontstring then resize editbox to match
						aEB.z:SetText(aEB:GetText())
						aEB:SetWidth(aEB.z:GetStringWidth() + 90)
						-- Get achievement title for tooltip
						local achievementLink = GetAchievementLink(achievementID)
						if achievementLink then
							aEB.tiptext = achievementLink:match("%[(.-)%]") .. "|n" .. L["Press CTRL/C to copy."]
						end
						-- Show the editbox
						aEB:Show()
					end
				end

				-- Function to hook a challenge button (Init runs when a challenge is clicked and when the list is set up)
				local hookedButtons = setmetatable({}, {__mode = "k"})
				local function HookChallengeButton(button)
					if button and button.Init and not hookedButtons[button] then
						hookedButtons[button] = true
						hooksecurefunc(button, "Init", function(self, elementData)
							if elementData and elementData.selected then
								SetAchievementFunc(elementData.id)
							end
						end)
					end
				end

				-- Hook challenge buttons that already exist and any new ones the list creates
				scrollBox:ForEachFrame(HookChallengeButton)
				ScrollUtil.AddAcquiredFrameCallback(scrollBox, function(o, button) HookChallengeButton(button) end, aEB)

				-- Create tooltip
				aEB:HookScript("OnEnter", function()
					aEB:HighlightText()
					aEB:SetFocus()
					GameTooltip:SetOwner(aEB, "ANCHOR_BOTTOM", 0, -10)
					GameTooltip:SetText(aEB.tiptext, nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)

				aEB:HookScript("OnLeave", function()
					-- Set link text again if it's changed since it was set
					if aEB:GetText() ~= lastAchievementLink then aEB:SetText(lastAchievementLink) end
					aEB:HighlightText(0, 0)
					aEB:ClearFocus()
					GameTooltip:Hide()
				end)

			end)

			----------------------------------------------------------------------
			-- World map frame
			----------------------------------------------------------------------

			-- Hide the title text
			WorldMapFrameTitleText:Hide()

			-- Create editbox
			local mEB = CreateFrame("EditBox", nil, WorldMapFrame.BorderFrame)
			mEB:SetFrameLevel(501)
			mEB:ClearAllPoints()
			mEB:SetPoint("TOPLEFT", 100, -4)
			mEB:SetHeight(16)
			mEB:SetFontObject("GameFontNormal")
			mEB:SetBlinkSpeed(0)
			mEB:SetAutoFocus(false)
			mEB:EnableKeyboard(false)
			mEB:SetHitRectInsets(0, 90, 0, 0)
			mEB:SetScript("OnKeyDown", function() end)
			mEB:SetScript("OnMouseUp", function()
				if mEB:IsMouseOver() then
					mEB:HighlightText()
				else
					mEB:HighlightText(0, 0)
				end
			end)

			-- Create hidden font string (used for setting width of editbox)
			mEB.z = mEB:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
			mEB.z:Hide()

			-- Function to set editbox value
			local function SetQuestInBox()
				local questID
				if QuestMapFrame.DetailsFrame:IsShown() then
					-- Get quest ID from currently showing quest in details panel
					questID = QuestMapFrame_GetDetailQuestID()
				else
					-- Get quest ID from currently selected quest on world map
					questID = C_SuperTrack.GetSuperTrackedQuestID()
				end
				if questID then
					-- Hide editbox if quest ID is invalid
					if questID == 0 then mEB:Hide() else mEB:Show() end
					-- Set editbox text
					if LeaPlusLC["WowheadLinkComments"] == "On" then
						mEB:SetText("https://" .. wowheadLoc .. "/quest=" .. questID .. "#comments")
					else
						mEB:SetText("https://" .. wowheadLoc .. "/quest=" .. questID)
					end
					-- Set hidden fontstring then resize editbox to match
					mEB.z:SetText(mEB:GetText())
					mEB:SetWidth(mEB.z:GetStringWidth() + 90)
					-- Get quest title for tooltip
					local questLink = GetQuestLink(questID) or nil
					if questLink then
						mEB.tiptext = questLink:match("%[(.-)%]") .. "|n" .. L["Press CTRL/C to copy."]
					else
						mEB.tiptext = ""
						if mEB:IsMouseOver() and GameTooltip:IsShown() then GameTooltip:Hide() end
					end
				end
			end

			-- Set URL when super tracked quest changes and on startup
			mEB:RegisterEvent("SUPER_TRACKING_CHANGED")
			mEB:SetScript("OnEvent", SetQuestInBox)
			SetQuestInBox()

			-- Set URL when quest details frame is shown or hidden
			hooksecurefunc("QuestMapFrame_ShowQuestDetails", SetQuestInBox)
			hooksecurefunc("QuestMapFrame_CloseQuestDetails", SetQuestInBox)

			-- Create tooltip
			mEB:HookScript("OnEnter", function()
				mEB:HighlightText()
				mEB:SetFocus()
				GameTooltip:SetOwner(mEB, "ANCHOR_BOTTOM", 0, -10)
				GameTooltip:SetText(mEB.tiptext, nil, nil, nil, nil, true)
				GameTooltip:Show()
			end)

			mEB:HookScript("OnLeave", function()
				mEB:HighlightText(0, 0)
				mEB:ClearFocus()
				GameTooltip:Hide()
				SetQuestInBox()
			end)

			-- Set position for Leatrix Maps 'Simple map frame' setting (the link goes to the left of the map filter button,
			-- right-justified towards it, so the spare width used to stop the text scrolling is on the left)
			EventUtil.ContinueOnAddOnLoaded("Leatrix_Maps",function()
				if LeaMapsDB and LeaMapsDB["SimpleMapFrame"] and LeaMapsDB["SimpleMapFrame"] == "On" then
					local filterButton = WorldMapFrame.WorldMapTrackingOptionsButton
					mEB:ClearAllPoints()
					if filterButton then
						mEB:SetPoint("RIGHT", filterButton, "LEFT", -4, 0)
						mEB:SetJustifyH("RIGHT")
						mEB:SetHitRectInsets(90, 0, 0, 0)
					else
						mEB:SetPoint("TOPLEFT", WorldMapFrame.ScrollContainer, "TOPLEFT", 98, -4)
					end
				end
			end)

		end

		----------------------------------------------------------------------
		-- Enhance dressup
		----------------------------------------------------------------------

		if LeaPlusLC["EnhanceDressup"] == "On" and not LeaLockList["EnhanceDressup"] then

			-- Create configuration panel
			local DressupPanel = LeaPlusLC:CreatePanel("Enhance dressup", "DressupPanel")

			LeaPlusLC:MakeTx(DressupPanel, "Dressing room", 16, -72)
			LeaPlusLC:MakeCB(DressupPanel, "DressupItemButtons", "Show item buttons", 16, -92, false, "If checked, item buttons will be shown in the dressing room.  You can click the item buttons to hide individual items on the model and click them again to show them.")
			LeaPlusLC:MakeCB(DressupPanel, "DressupAnimControl", "Show animation slider", 16, -112, false, "If checked, an animation slider will be shown in the dressing room.")

			LeaPlusLC:MakeTx(DressupPanel, "Transmogrify character preview", 16, -152)
			LeaPlusLC:MakeCB(DressupPanel, "DressupMoreZoomOut", "Increase zoom out distance", 16, -172, true, "If checked, you will be able to zoom out further with the transmogrify character preview.")
			LeaPlusLC:MakeCB(DressupPanel, "DressupTransmogAnim", "Show animation slider", 16, -192, false, "If checked, an animation slider will be shown in the transmogrify character preview.")

			LeaPlusLC:MakeTx(DressupPanel, "Zoom speed", 356, -72)
			LeaPlusLC:MakeSL(DressupPanel, "DressupFasterZoom", "Drag to set the character model zoom speed.", 1, 10, 1, 356, -92, "%.0f")

			-- Refresh zoom speed slider when changed
			LeaPlusCB["DressupFasterZoom"]:HookScript("OnValueChanged", function()
				LeaPlusCB["DressupFasterZoom"].f:SetFormattedText("%.0f%%", LeaPlusLC["DressupFasterZoom"] * 100)
			end)

			-- Set zoom speed when dressup model is zoomed (wardrobe is set in wardrobe section further down)
			DressUpFrame.ModelScene:SetScript("OnMouseWheel", function(self, delta)
				for i = 1, LeaPlusLC["DressupFasterZoom"] do
					if DressUpFrame.ModelScene.activeCamera then
						DressUpFrame.ModelScene.activeCamera:OnMouseWheel(delta)
					end
				end
			end)

			-- Set zoom speed when character frame model is zoomed
			CharacterModelScene:SetScript("OnMouseWheel", function(self, delta)
				for i = 1, LeaPlusLC["DressupFasterZoom"] do
					if CharacterModelScene.activeCamera then
						CharacterModelScene.activeCamera:OnMouseWheel(delta)
					end
				end
			end)

			-- Help button hidden
			DressupPanel.h:Hide()

			-- Back button handler
			DressupPanel.b:SetScript("OnClick", function()
				DressupPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page5"]:Show()
				return
			end)

			-- Reset button handler
			DressupPanel.r.tiptext = DressupPanel.r.tiptext .. "|n|n" .. L["Note that this will not reset settings that require a UI reload."]
			DressupPanel.r:SetScript("OnClick", function()

				-- Reset controls
				LeaPlusLC["DressupFasterZoom"] = 3

				-- Refresh configuration panel
				DressupPanel:Hide(); DressupPanel:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			LeaPlusCB["EnhanceDressupBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["DressupFasterZoom"] = 3
				else
					DressupPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

			----------------------------------------------------------------------
			-- Item buttons
			----------------------------------------------------------------------

			-- Shared with the bottom buttons (further down)
			local DressupGear = {}

			-- Secret values: the game can hide some values from addons (such as in instances), so anything that could be hidden is checked first
			local function Safe(v)
				if issecretvalue and issecretvalue(v) then return nil end
				return v
			end

			-- The player model in the dressing room (nil when it shows something else, such as a mount)
			local function GetActor()
				return DressUpFrame.ModelScene:GetPlayerActor()
			end

			-- Give a button the same look as the item slots in the character sheet (the icon is btn.t)
			local function PaperDollButton(btn, size)
				btn:SetSize(size, size)
				local bg = btn:CreateTexture(nil, "BACKGROUND")
				bg:SetAllPoints()
				bg:SetColorTexture(0, 0, 0, 0.7) -- Behind the icon (portraits are round, so this fills the corners)
				btn.t = btn:CreateTexture(nil, "BORDER")
				btn.t:SetAllPoints()
				btn:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
				local border = btn:GetNormalTexture()
				border:ClearAllPoints()
				border:SetSize(size * 64 / 37, size * 64 / 37)
				border:SetPoint("CENTER", 0, -size / 37)
				btn:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
				btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
			end

			-- Show a message in the dressing room, at the top of the model on a dark background, which fades out after a few seconds
			do
				local msgFrame = CreateFrame("Frame", nil, DressUpFrame)
				msgFrame:SetFrameStrata("HIGH")
				msgFrame:SetPoint("TOPLEFT", DressUpFrame, "TOPLEFT", 52, -68)
				msgFrame:SetPoint("TOPRIGHT", DressUpFrame, "TOPRIGHT", -54, -68)
				msgFrame:SetHeight(30)
				msgFrame:Hide()
				local bg = msgFrame:CreateTexture(nil, "BACKGROUND")
				bg:SetAllPoints()
				bg:SetColorTexture(0, 0, 0, 0.75)
				local text = msgFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
				text:SetPoint("TOPLEFT", 6, -6)
				text:SetPoint("TOPRIGHT", -6, -6)
				text:SetJustifyH("CENTER")
				local fade = msgFrame:CreateAnimationGroup()
				local alpha = fade:CreateAnimation("Alpha")
				alpha:SetFromAlpha(1)
				alpha:SetToAlpha(0)
				alpha:SetStartDelay(3)
				alpha:SetDuration(0.5)
				fade:SetScript("OnFinished", function() msgFrame:Hide() end)
				function DressupGear.Message(message)
					text:SetText(message)
					msgFrame:SetHeight(text:GetStringHeight() + 12) -- Fits the text (long messages go over two lines)
					fade:Stop()
					msgFrame:SetAlpha(1)
					msgFrame:Show()
					fade:Play()
				end
				DressUpFrame:HookScript("OnHide", function() fade:Stop() msgFrame:Hide() end)
			end

			do

				local buttons, slotOrder = {}, {}
				local slotInfo, hiddenSlots, nudeSaved = {}, {}, {} -- Appearance in each slot (transmog info), slots taken off, slots to put back on after nude
				local mode -- What the model shows: me, target, myOutfitOnTarget or targetOutfitOnMe
				local nudeBtn -- The all items button at the bottom of the left column

				-- Set what the model shows (the bottom buttons show it)
				local function SetMode(newMode)
					mode = newMode
					if DressupGear.OnModeChanged then DressupGear.OnModeChanged() end
				end
				function DressupGear.GetMode() return mode end

				-- Slot buttons (slot name, icon shown when the game has no empty slot picture)
				local leftSlots = {{"HeadSlot", "INV_Misc_Desecrated_ClothHelm"}, {"ShoulderSlot", "INV_Misc_Desecrated_ClothShoulder"}, {"BackSlot", "INV_Misc_Cape_01"}, {"ChestSlot", "INV_Misc_Desecrated_ClothChest"}, {"ShirtSlot", "INV_Shirt_01"}, {"TabardSlot", "INV_Shirt_GuildTabard_01"}, {"WristSlot", "INV_Misc_Desecrated_ClothBracer"}}
				local rightSlots = {{"HandsSlot", "INV_Misc_Desecrated_ClothGlove"}, {"WaistSlot", "INV_Misc_Desecrated_ClothBelt"}, {"LegsSlot", "INV_Misc_Desecrated_ClothPants"}, {"FeetSlot", "INV_Misc_Desecrated_ClothBoots"}, {"MainHandSlot", "INV_Sword_01"}, {"SecondaryHandSlot", "INV_Shield_01"}}

				-- The appearance the model shows in a slot (nil if none, or if the game is hiding it)
				local function ModelAppearance(actor, slotID)
					local ok, transmog = pcall(actor.GetItemTransmogInfo, actor, slotID)
					if not ok or type(transmog) ~= "table" then return end
					local appearanceID = Safe(transmog.appearanceID)
					if type(appearanceID) == "number" and appearanceID > 0 then return transmog end
				end

				-- Put an appearance on the model (weapons go straight into their own hand, so a dual wielder keeps both)
				local function DressSlot(slotID)
					local actor, transmog = GetActor(), slotInfo[slotID]
					if not actor or not transmog then return end
					pcall(actor.SetItemTransmogInfo, actor, transmog, slotID, slotID ~= INVSLOT_MAINHAND)
				end

				-- Show each button as worn, taken off or empty
				local function UpdateSlots()
					for void, button in ipairs(buttons) do
						local transmog = slotInfo[button.slotID]
						local hidden = hiddenSlots[button.slotID]
						button.link = nil
						if transmog then
							local appearanceID = transmog.appearanceID
							if C_TransmogCollection.IsAppearanceHiddenVisual(appearanceID) then
								button.t:SetAtlas("transmog-icon-hidden")
							else
								local source = C_TransmogCollection.GetAppearanceSourceInfo(appearanceID)
								button.t:SetTexture(source and source.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
								button.link = source and source.itemLink
							end
						else
							button.t:SetTexture(button.emptyTexture)
						end
						button.t:SetDesaturated(hidden and true or false)
						button.t:SetAlpha(hidden and 0.45 or 1)
					end
					-- All items button: in colour with a red cross while anything is showing, grey once everything is off
					if nudeBtn then
						local anyShown = DressupGear.AnyShown()
						nudeBtn.t:SetDesaturated(not anyShown)
						nudeBtn.t:SetAlpha(anyShown and 1 or 0.45)
						nudeBtn.badge:SetShown(anyShown)
					end
				end

				-- Read what the model is wearing (slots taken off with the buttons stay taken off until something is put in them)
				local function Refresh()
					local actor = GetActor()
					if not actor then return end
					for void, slotID in ipairs(slotOrder) do
						local transmog = ModelAppearance(actor, slotID)
						if transmog then
							slotInfo[slotID] = transmog
							hiddenSlots[slotID] = nil
						elseif not hiddenSlots[slotID] then
							slotInfo[slotID] = nil
						end
					end
					UpdateSlots()
				end
				DressupGear.Refresh = Refresh

				-- Start again (the model has been reset or shows someone else)
				local function Reset(newMode)
					wipe(slotInfo) wipe(hiddenSlots) wipe(nudeSaved)
					SetMode(newMode)
					Refresh()
				end
				DressupGear.Reset = Reset

				-- Follow the model while the dressing room is open: a new model (opened or reset) starts again, and anything put on or taken off
				-- (such as an item tried on with Ctrl-click) shows on the buttons
				-- This is a light check a few times a second, rather than hooking the dressing room's own functions: on retail, a function hooked
				-- with hooksecurefunc can read as missing while the taint log is on, which breaks the dressing room itself
				local lastActor, ticker
				local function Check()
					local actor = GetActor()
					if actor ~= lastActor then
						lastActor = actor
						if actor then Reset("me") end
					elseif actor then
						Refresh()
					end
				end
				DressUpFrame:HookScript("OnShow", function()
					if ticker then ticker:Cancel() end
					lastActor = nil
					ticker = C_Timer.NewTicker(0.2, Check)
					Check()
				end)
				DressUpFrame:HookScript("OnHide", function()
					if ticker then ticker:Cancel() ticker = nil end
				end)

				-- The model changes when the dressing room shows me or the target (so it does not count as the dressing room being reset)
				function DressupGear.NoteActor() lastActor = GetActor() end

				----------------------------------------------------------------------
				-- Slot buttons
				----------------------------------------------------------------------

				local function SlotTip(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
					if not (self.link and pcall(GameTooltip.SetHyperlink, GameTooltip, self.link)) then
						GameTooltip:SetText(self.label, 1, 1, 1)
					end
					if not slotInfo[self.slotID] then
						GameTooltip:AddLine(L["Nothing to show in this slot"], 0.6, 0.6, 0.65)
					elseif hiddenSlots[self.slotID] then
						GameTooltip:AddLine(L["Click to show"], 0.6, 0.6, 0.65)
					else
						GameTooltip:AddLine(L["Click to hide"], 0.6, 0.6, 0.65)
					end
					GameTooltip:Show()
				end

				-- A column for each set of slot buttons (down each side of the model, like the character sheet)
				-- The columns are inside the reset button, so they only show when the dressing room shows a character (not a mount or pet)
				local columns = {}
				local step = 33 -- Distance from one slot button to the next (the same spacing as the character sheet, scaled to these smaller buttons)
				local function MakeColumn(anchor, x, y)
					local column = CreateFrame("Frame", nil, DressUpFrameResetButton)
					column:SetFrameStrata("HIGH")
					column:SetPoint(anchor, DressUpFrame, anchor, x, y)
					column:SetWidth(38)
					column.count = 0
					tinsert(columns, column)
					return column
				end
				local leftColumn = MakeColumn("TOPLEFT", 8, -64)
				local rightColumn = MakeColumn("TOPRIGHT", -10, -64)

				-- The frame each slot sits in on the character sheet (with a tab towards the model), if this game has it
				local slotFrameFile = "Interface\\CharacterFrame\\Char-Paperdoll-Parts"
				local hasSlotFrames = GetFileIDFromPath and GetFileIDFromPath(slotFrameFile) and true or false
				local function AddSlotFrame(btn, column)
					if not hasSlotFrames then return end
					local frame = column:CreateTexture(nil, "BACKGROUND") -- On the column, so it is always behind every slot button
					frame:SetTexture(slotFrameFile)
					local scale = btn:GetWidth() / 37 -- The character sheet slots are 37 wide
					if column == leftColumn then
						frame:SetTexCoord(0.20703125, 0.39843750, 0.59375000, 0.93750000)
						frame:SetSize(49 * scale, 44 * scale)
						frame:SetPoint("TOPLEFT", btn, "TOPLEFT", -4 * scale, 0)
					else
						frame:SetTexCoord(0.00390625, 0.19921875, 0.59375000, 0.93750000)
						frame:SetSize(50 * scale, 44 * scale)
						frame:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 4 * scale, 0)
					end
				end

				local function MakeSlotButton(entry, column)

					-- Slots this game does not have are left out
					local slotName, fallbackIcon = entry[1], entry[2]
					local ok, slotID, emptyTexture = pcall(C_PaperDollInfo.GetInventorySlotInfo, slotName)
					if not ok or not slotID then return end

					-- Create slot button
					local slotBtn = CreateFrame("Button", nil, column)
					slotBtn:SetFrameLevel(column:GetFrameLevel() + 2)
					PaperDollButton(slotBtn, 30)
					AddSlotFrame(slotBtn, column)
					slotBtn.slotID = slotID
					slotBtn.label = _G[strupper(slotName)] or slotName
					slotBtn.emptyTexture = emptyTexture or ("Interface\\Icons\\" .. fallbackIcon)
					slotBtn:SetPoint("TOP", column, "TOP", 0, -4 - step * column.count)
					column.count = column.count + 1
					column:SetHeight(8 + step * column.count - (step - 30))
					slotBtn:RegisterForClicks("LeftButtonUp")
					slotBtn:SetMotionScriptsWhileDisabled(true)

					-- Slot button click: take the item off, click again to put it back on
					slotBtn:SetScript("OnClick", function(self)
						local slot = self.slotID
						if not slotInfo[slot] then return end
						if hiddenSlots[slot] then
							hiddenSlots[slot] = nil
							DressSlot(slot)
						else
							hiddenSlots[slot] = true
							local actor = GetActor()
							if actor then pcall(actor.UndressSlot, actor, slot) end
						end
						UpdateSlots()
						if GameTooltip:IsOwned(self) then SlotTip(self) end
					end)

					-- Slot button tooltip
					slotBtn:SetScript("OnEnter", SlotTip)
					slotBtn:SetScript("OnLeave", GameTooltip_Hide)

					-- Add slot button to table
					tinsert(buttons, slotBtn)
					tinsert(slotOrder, slotID)

				end

				-- Show left column slot buttons
				for i, entry in ipairs(leftSlots) do
					MakeSlotButton(entry, leftColumn)
				end

				-- Show right column slot buttons
				for i, entry in ipairs(rightSlots) do
					MakeSlotButton(entry, rightColumn)
				end

				-- All items button (nude) at the bottom of the left column
				do
					local column = leftColumn
					nudeBtn = CreateFrame("Button", nil, column)
					nudeBtn:SetFrameLevel(column:GetFrameLevel() + 2)
					PaperDollButton(nudeBtn, 30)
					AddSlotFrame(nudeBtn, column)
					nudeBtn:SetPoint("TOP", column, "TOP", 0, -4 - step * column.count)
					column.count = column.count + 1
					column:SetHeight(8 + step * column.count - (step - 30))
					nudeBtn.t:SetTexture("Interface\\Icons\\INV_Shirt_01")

					-- Red cross in the corner while anything is on (click to take it all off)
					nudeBtn.badge = nudeBtn:CreateTexture(nil, "OVERLAY", nil, 2)
					nudeBtn.badge:SetSize(14, 14)
					nudeBtn.badge:SetPoint("BOTTOMRIGHT", nudeBtn, "BOTTOMRIGHT", 1, -1)
					nudeBtn.badge:SetAtlas("common-icon-redx")

					local function NudeTip(self)
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						GameTooltip:SetText(L["All items"], 1, 1, 1)
						if DressupGear.AnyShown() then
							GameTooltip:AddLine(L["Click to remove all items"], 0.6, 0.6, 0.65)
						else
							GameTooltip:AddLine(L["Click to put all items back on"], 0.6, 0.6, 0.65)
						end
						GameTooltip:Show()
					end
					nudeBtn:RegisterForClicks("LeftButtonUp")
					nudeBtn:SetScript("OnEnter", NudeTip)
					nudeBtn:SetScript("OnLeave", GameTooltip_Hide)
					nudeBtn:SetScript("OnClick", function(self)
						DressupGear.ToggleNude()
						if GameTooltip:IsOwned(self) then NudeTip(self) end
					end)
				end

				----------------------------------------------------------------------
				-- Nude (used by the nude button)
				----------------------------------------------------------------------

				-- Is anything still showing (true when nothing is known about the gear, so nude always takes everything off)
				function DressupGear.AnyShown()
					if not next(slotInfo) then return true end
					for slotID in pairs(slotInfo) do
						if not hiddenSlots[slotID] then return true end
					end
					return false
				end

				-- Take everything off, click again to put back on what was showing before
				function DressupGear.ToggleNude()
					local actor = GetActor()
					if not actor then return end
					if DressupGear.AnyShown() then
						wipe(nudeSaved)
						for slotID in pairs(slotInfo) do
							if not hiddenSlots[slotID] then nudeSaved[slotID] = true; hiddenSlots[slotID] = true end
						end
						pcall(actor.Undress, actor)
					else
						local all = not next(nudeSaved) -- Nothing remembered, so put everything back on
						for void, slotID in ipairs(slotOrder) do
							if slotInfo[slotID] and (all or nudeSaved[slotID]) then
								hiddenSlots[slotID] = nil
								DressSlot(slotID)
							end
						end
						wipe(nudeSaved)
					end
					UpdateSlots()
				end

				----------------------------------------------------------------------
				-- Outfits (my outfit on target, target outfit on me)
				----------------------------------------------------------------------

				-- Put a list of appearances on the model (in their own slots, so a dual wielder keeps both weapons)
				local function ApplyList(actor, list)
					for slotID, transmog in ipairs(list) do
						local appearanceID = type(transmog) == "table" and Safe(transmog.appearanceID)
						if type(appearanceID) == "number" and appearanceID > 0 then
							pcall(actor.SetItemTransmogInfo, actor, transmog, slotID, slotID ~= INVSLOT_MAINHAND)
						end
					end
				end

				-- Read the appearances a model is wearing (nil if the game is hiding them)
				local function ReadList(actor)
					local ok, list = pcall(actor.GetItemTransmogInfoList, actor)
					if not ok or type(list) ~= "table" then return end
					if (issecretvalue and issecretvalue(list)) or (canaccesstable and not canaccesstable(list)) then return end
					return list
				end

				-- Show my outfit on the target
				function DressupGear.MyOutfitOnTarget()
					local actor = GetActor()
					if not actor or not Safe(UnitIsPlayer("target")) then return end
					actor:SetModelByUnit("player", true, true)
					local list = ReadList(actor)
					actor:SetModelByUnit("target", true, true)
					C_Timer.After(0.01, function()
						actor = GetActor()
						if not actor or not Safe(UnitIsPlayer("target")) then return end
						actor:SetModelByUnit("target", true, true)
						if list then
							actor:Undress()
							ApplyList(actor, list)
						else
							DressupGear.Message(L["Their gear could not be read."])
						end
						Reset("myOutfitOnTarget")
						DressupGear.NoteActor()
						C_Timer.After(0.2, Refresh)
					end)
				end

				-- Show the target's outfit on me
				function DressupGear.TargetOutfitOnMe()
					local actor = GetActor()
					if not actor or not Safe(UnitIsPlayer("target")) then return end
					actor:SetModelByUnit("target", true, true)
					C_Timer.After(0.01, function()
						actor = GetActor()
						if not actor then return end
						local list = ReadList(actor)
						actor:SetModelByUnit("player", true, true)
						if list then
							actor:Undress()
							ApplyList(actor, list)
						else
							DressupGear.Message(L["Their gear could not be read."])
						end
						Reset("targetOutfitOnMe")
						DressupGear.NoteActor()
						C_Timer.After(0.2, Refresh)
					end)
				end

				-- Show me or the target
				function DressupGear.ShowUnit(unit, newMode)
					local actor = GetActor()
					if not actor then return end
					actor:SetModelByUnit(unit, true, true)
					C_Timer.After(0.1, function()
						actor = GetActor()
						if not actor then return end
						actor:SetModelByUnit(unit, true, true)
						Reset(newMode)
						DressupGear.NoteActor()
						C_Timer.After(0.2, Refresh)
					end)
				end

				-- The unit shown in the dressing room (nil if it cannot be found any more)
				function DressupGear.GetUnit()
					if mode == "target" or mode == "myOutfitOnTarget" then
						if Safe(UnitIsPlayer("target")) then return "target" end
						return
					end
					return "player"
				end

				-- Function to set item buttons
				local function ToggleItemButtons()
					-- The buttons are inside the columns, so showing or hiding the columns does the buttons too
					for i = 1, #columns do columns[i]:SetShown(LeaPlusLC["DressupItemButtons"] == "On" and columns[i].count > 0) end
				end

				-- Assign file level scope to function
				LeaPlusLC.ToggleItemButtons = ToggleItemButtons

				-- Set item buttons for option click, startup, reset click and preset click
				LeaPlusCB["DressupItemButtons"]:HookScript("OnClick", ToggleItemButtons)
				ToggleItemButtons()
				DressupPanel.r:HookScript("OnClick", function()
					LeaPlusLC["DressupItemButtons"] = "On"
					ToggleItemButtons()
					DressupPanel:Hide(); DressupPanel:Show()
				end)
				LeaPlusCB["EnhanceDressupBtn"]:HookScript("OnClick", function()
					if IsShiftKeyDown() and IsControlKeyDown() then
						LeaPlusLC["DressupItemButtons"] = "On"
						ToggleItemButtons()
					end
				end)

				UpdateSlots()

			end

			----------------------------------------------------------------------
			-- Animation slider (must be before bottom row buttons)
			----------------------------------------------------------------------

			local animTable = {0, 4, 5, 143, 119, 26, 25, 27, 28, 108, 120, 51, 124, 52, 125, 126, 62, 63, 41, 42, 43, 44, 132, 38, 14, 115, 193, 48, 110, 109, 134, 197, 0}
			local lastSetting

			LeaPlusLC["DressupAnim"] = 0 -- Defined here since the setting is not saved
			LeaPlusLC:MakeSL(DressUpFrame, "DressupAnim", "", 1, #animTable - 1, 1, 356, -92, "%.0f")
			LeaPlusCB["DressupAnim"]:ClearAllPoints()
			LeaPlusCB["DressupAnim"]:SetPoint("BOTTOM", 26, 44) -- Above the bottom bar (the title goes to the left of it and the number to the right)
			LeaPlusCB["DressupAnim"]:SetParent(DressUpFrameResetButton) -- So it only shows with reset button
			LeaPlusCB["DressupAnim"]:SetWidth(150)
			LeaPlusCB["DressupAnim"]:SetFrameLevel(DressUpFrame.ModelScene:GetFrameLevel() + 5)
			LeaPlusCB["DressupAnim"]:HookScript("OnValueChanged", function(self, setting)
				local playerActor = DressUpFrame.ModelScene:GetPlayerActor()
				setting = math.floor(setting + 0.5)
				if playerActor and setting ~= lastSetting then
					lastSetting = setting
					playerActor:SetAnimation(animTable[setting], 0, 1, 1)
					-- print(animTable[setting]) -- Debug
				end
			end)

			-- Title for the slider (part of the slider, so it hides with it)
			local animTitle = LeaPlusCB["DressupAnim"]:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
			animTitle:SetPoint("RIGHT", LeaPlusCB["DressupAnim"], "LEFT", -4, 1) -- Up a pixel, so the lower case letters line up with the middle of the bar
			animTitle:SetText(L["Animation"])

			-- Function to show animation control
			local function SetAnimationSlider()
				if LeaPlusLC["DressupAnimControl"] == "On" then
					LeaPlusCB["DressupAnim"]:Show()
				else
					LeaPlusCB["DressupAnim"]:Hide()
				end
				LeaPlusCB["DressupAnim"]:SetValue(1)
			end

			-- Set animation control with option, startup, preset and reset
			LeaPlusCB["DressupAnimControl"]:HookScript("OnClick", SetAnimationSlider)
			SetAnimationSlider()
			LeaPlusCB["EnhanceDressupBtn"]:HookScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					LeaPlusLC["DressupAnimControl"] = "On"
					SetAnimationSlider()
				end
			end)
			DressupPanel.r:HookScript("OnClick", function()
				LeaPlusLC["DressupAnimControl"] = "On"
				SetAnimationSlider()
				DressupPanel:Hide(); DressupPanel:Show()
			end)

			-- Reset animation when dressup frame is shown and model is reset
			DressUpFrame:HookScript("OnShow", SetAnimationSlider)
			DressUpFrameResetButton:HookScript("OnClick", SetAnimationSlider)

			-- Skin slider for ElvUI
			if LeaPlusLC.ElvUI then
				_G.LeaPlusGlobalDressupAnim = LeaPlusCB["DressupAnim"]
				LeaPlusLC.ElvUI:GetModule("Skins"):HandleSliderFrame(_G.LeaPlusGlobalDressupAnim, false)
			end

			----------------------------------------------------------------------
			-- Bottom row buttons
			----------------------------------------------------------------------

			-- Function to modify a button tooltip
			local function SetButton(where, tip)
				where:HookScript("OnEnter", function()
					GameTooltip:SetOwner(where, "ANCHOR_NONE")
					GameTooltip:SetPoint("BOTTOM", where, "TOP", 0, 10)
					GameTooltip:SetText(L[tip], nil, nil, nil, nil, true)
				end)
				where:HookScript("OnLeave", GameTooltip_Hide)
			end

			SetButton(DressUpFrameCancelButton, "Close")
			SetButton(DressUpFrameResetButton, "Reset")
			SetButton(DressUpFrame.LinkButton, "Link outfit")

			-- Function to set the animation again after the model has changed
			local function ResetAnimation()
				C_Timer.After(0.2, function()
					local playerActor = DressUpFrame.ModelScene:GetPlayerActor()
					if not playerActor then return end
					playerActor:SetAnimation(0)
					C_Timer.After(0.1, function()
						playerActor:SetAnimation(animTable[math.floor(LeaPlusCB["DressupAnim"]:GetValue() + 0.5)], 0, 1, 1)
					end)
				end)
			end

			-- Bottom bar: picture buttons in the same style as the slot buttons, then Reset and Close
			-- The bar is inside the reset button, so it only shows when the dressing room shows a character (not a mount or pet)
			local size, gap = 30, 6
			local mePics, targetPics, shades = {}, {}, {}
			local barLevel = DressUpFrame.ModelScene:GetFrameLevel() + 5 -- Above the model

			-- Grey out a button's pictures when it is disabled
			local function Shade(btn)
				local on = btn:IsEnabled()
				for void, pic in ipairs({btn.t, btn.badge}) do
					pic:SetDesaturated(not on)
					pic:SetAlpha(on and 1 or 0.45)
				end
			end

			-- Create a bar button (title and optional text for the tooltip, isMode for buttons that stay lit while the model shows that)
			local barCount = 0
			local function MakeBarButton(title, text, isMode)
				local btn = CreateFrame(isMode and "CheckButton" or "Button", nil, DressUpFrameResetButton)
				PaperDollButton(btn, size)
				if isMode then
					btn:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight")
					btn:GetCheckedTexture():SetBlendMode("ADD")
				end
				btn:SetFrameLevel(barLevel)
				btn:SetPoint("BOTTOMLEFT", DressUpFrame, "BOTTOMLEFT", 12 + barCount * (size + gap), 7)
				barCount = barCount + 1
				btn:SetMotionScriptsWhileDisabled(true) -- Tooltip shows while greyed out
				btn:SetScript("OnEnter", function(self)
					GameTooltip:SetOwner(self, "ANCHOR_NONE")
					GameTooltip:SetPoint("BOTTOM", self, "TOP", 0, 10)
					GameTooltip:SetText(L[title], 1, 1, 1)
					if text then GameTooltip:AddLine(L[text], nil, nil, nil, true) end
					if self.why and not self:IsEnabled() then GameTooltip:AddLine(self.why, 1, 0.3, 0.3, true) end
					GameTooltip:Show()
				end)
				btn:SetScript("OnLeave", GameTooltip_Hide)
				-- Small round picture in the corner (whose gear is being worn)
				btn.badge = btn:CreateTexture(nil, "OVERLAY", nil, 2)
				btn.badge:SetSize(15, 15)
				btn.badge:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 3, -3)
				btn.badge:Hide()
				btn:SetScript("OnEnable", Shade)
				btn:SetScript("OnDisable", Shade)
				tinsert(shades, btn)
				return btn
			end

			-- Make a picture round (portraits)
			local circle = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
			local function MakeRound(btn, pic)
				local mask = btn:CreateMaskTexture()
				mask:SetTexture(circle, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
				mask:SetAllPoints(pic)
				pic:AddMaskTexture(mask)
			end

			-- Show a small portrait in the corner of a button (with a dark ring so it stands apart from the big picture)
			local function AddBadge(btn, list)
				local ring = btn:CreateTexture(nil, "OVERLAY", nil, 1)
				ring:SetTexture(circle)
				ring:SetVertexColor(0, 0, 0, 1)
				ring:SetSize(18, 18)
				ring:SetPoint("CENTER", btn.badge, "CENTER")
				MakeRound(btn, btn.badge)
				btn.badge:Show()
				tinsert(list, btn.badge)
			end

			-- Link: Blizzard's own button, given the same look (see below), so it comes first in the bar
			barCount = 1

			local meBtn = MakeBarButton("Show me", nil, true)
			tinsert(mePics, meBtn.t)

			local targetBtn = MakeBarButton("Show target", nil, true)
			tinsert(targetPics, targetBtn.t)

			local myGearBtn = MakeBarButton("Show my gear on target", nil, true)
			tinsert(targetPics, myGearBtn.t)
			AddBadge(myGearBtn, mePics)

			local theirGearBtn = MakeBarButton("Show target gear on me", nil, true)
			tinsert(mePics, theirGearBtn.t)
			AddBadge(theirGearBtn, targetPics)

			local infoBtn = MakeBarButton("Show info card", nil, false)
			infoBtn.t:SetTexture("Interface\\Icons\\INV_Misc_Note_02")

			-- Link, Reset and Close, given the same look as the other buttons
			-- These are Blizzard's own buttons, so they are only re-skinned (their red art is made see-through and pictures are laid
			-- over it): clicking them still runs Blizzard's own code (the link menu, including copying to the clipboard, stays Blizzard's),
			-- nothing is replaced and nothing is written onto them
			local skinParts = {}
			local function SkinBlizzardButton(btn, file, picSize, isAtlas)
				btn:SetText("")
				btn:SetSize(size, size)
				for void, region in ipairs({btn:GetRegions()}) do
					if region:IsObjectType("Texture") then region:SetAlpha(0) end -- Stays see-through when the game changes the art (pressed, disabled)
				end
				local parts = {}
				parts.bg = btn:CreateTexture(nil, "BACKGROUND", nil, 7)
				parts.bg:SetAllPoints()
				parts.bg:SetColorTexture(0, 0, 0, 0.7)
				parts.pic = btn:CreateTexture(nil, "BORDER")
				parts.pic:SetSize(picSize, picSize)
				parts.pic:SetPoint("CENTER")
				if isAtlas then parts.pic:SetAtlas(file) else parts.pic:SetTexture(file) end
				parts.border = btn:CreateTexture(nil, "ARTWORK")
				parts.border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
				parts.border:SetSize(size * 64 / 37, size * 64 / 37)
				parts.border:SetPoint("CENTER", 0, -size / 37)
				parts.pushed = btn:CreateTexture(nil, "OVERLAY")
				parts.pushed:SetAllPoints()
				parts.pushed:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
				parts.pushed:Hide()
				parts.glow = btn:CreateTexture(nil, "OVERLAY")
				parts.glow:SetAllPoints()
				parts.glow:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
				parts.glow:SetBlendMode("ADD")
				parts.glow:Hide()
				skinParts[btn] = parts
				btn:HookScript("OnEnter", function() parts.glow:Show() end)
				btn:HookScript("OnLeave", function() parts.glow:Hide() parts.pushed:Hide() end)
				btn:HookScript("OnMouseDown", function(self) if self:IsEnabled() then parts.pushed:Show() end end)
				btn:HookScript("OnMouseUp", function() parts.pushed:Hide() end)
				btn:SetFrameLevel(barLevel)
			end

			-- Link: a chain link (first in the bar)
			local linkPicture = "Interface\\Buttons\\UI-LinkProfession-Up"
			if not (GetFileIDFromPath and GetFileIDFromPath(linkPicture)) then linkPicture = "Interface\\Icons\\INV_Letter_15" end -- In case this game does not have it
			SkinBlizzardButton(DressUpFrame.LinkButton, linkPicture, 22)
			DressUpFrame.LinkButton:ClearAllPoints()
			DressUpFrame.LinkButton:SetPoint("BOTTOMLEFT", DressUpFrame, "BOTTOMLEFT", 12, 7)

			-- Close: a red cross
			SkinBlizzardButton(DressUpFrameCancelButton, "common-icon-redx", 18, true)
			DressUpFrameCancelButton:ClearAllPoints()
			DressUpFrameCancelButton:SetPoint("BOTTOMRIGHT", DressUpFrame, "BOTTOMRIGHT", -12, 7)

			-- Reset: a circular arrow
			SkinBlizzardButton(DressUpFrameResetButton, "Interface\\Buttons\\UI-RefreshButton", 20)
			DressUpFrameResetButton:ClearAllPoints()
			DressUpFrameResetButton:SetPoint("RIGHT", DressUpFrameCancelButton, "LEFT", -gap, 0)

			-- Grey background behind the bottom bar (the frame's own grey, raised to cover the bottom of the model area, as the bar
			-- buttons are taller than Blizzard's own buttons and the edge of the model area would otherwise run through them)
			do
				local barBg = CreateFrame("Frame", nil, DressUpFrameResetButton) -- Inside the reset button like the bar buttons, so it hides with them
				barBg:SetFrameLevel(barLevel - 1) -- Above the model, below the buttons
				barBg:SetPoint("LEFT", DressUpFrame.Inset or DressUpFrame, "LEFT", DressUpFrame.Inset and 0 or 4, 0)
				barBg:SetPoint("RIGHT", DressUpFrame.Inset or DressUpFrame, "RIGHT", DressUpFrame.Inset and 0 or -4, 0)
				barBg:SetPoint("BOTTOM", DressUpFrame, "BOTTOM", 0, 3)
				barBg:SetPoint("TOP", meBtn, "TOP", 0, 4)
				local tex = barBg:CreateTexture(nil, "BACKGROUND")
				tex:SetAllPoints()
				local frameBg = DressUpFrame.Bg
				local atlas = frameBg and frameBg.GetAtlas and frameBg:GetAtlas()
				if atlas then
					tex:SetAtlas(atlas)
					tex:SetHorizTile(frameBg:GetHorizTile())
					tex:SetVertTile(frameBg:GetVertTile())
				elseif frameBg and frameBg:GetTexture() then
					tex:SetTexture(frameBg:GetTexture(), frameBg:GetHorizTile() and "REPEAT" or nil, frameBg:GetVertTile() and "REPEAT" or nil)
					tex:SetHorizTile(frameBg:GetHorizTile())
					tex:SetVertTile(frameBg:GetVertTile())
				else
					tex:SetColorTexture(0.1, 0.1, 0.1, 1)
				end
				if frameBg then tex:SetVertexColor(frameBg:GetVertexColor()) end

				-- Border line along the top of the grey, copied from the bottom border of the model area (the inset), so it looks the
				-- same as the default line (the pieces keep their own positions, moved from the bottom of the inset to the top of the grey)
				local inset = DressUpFrame.Inset
				local source = inset and inset.NineSlice
				local keys = {"BottomLeftCorner", "BottomEdge", "BottomRightCorner"}
				if not (source and source.BottomEdge) then
					source = inset
					keys = {"InsetBorderBottomLeft", "InsetBorderBottom", "InsetBorderBottomRight"}
				end
				local copies = {}
				for void, key in ipairs(keys) do
					local piece = source and source[key]
					if piece and piece.GetTexture then
						local t = barBg:CreateTexture(nil, "BORDER")
						local pieceAtlas = piece.GetAtlas and piece:GetAtlas()
						if pieceAtlas then
							t:SetAtlas(pieceAtlas)
						else
							t:SetTexture(piece:GetTexture())
							t:SetTexCoord(piece:GetTexCoord())
						end
						t:SetHorizTile(piece:GetHorizTile())
						t:SetVertTile(piece:GetVertTile())
						t:SetVertexColor(piece:GetVertexColor())
						t:SetSize(piece:GetSize())
						copies[piece] = t
					end
				end
				if next(copies) then
					for piece, t in pairs(copies) do
						for i = 1, piece:GetNumPoints() do
							local point, relativeTo, relativePoint, x, y = piece:GetPoint(i)
							if copies[relativeTo] then
								-- Anchored to another piece, so anchor to its copy
								t:SetPoint(point, copies[relativeTo], relativePoint, x, y)
							else
								-- Anchored to the inset, so anchor to the top of the grey instead of the bottom of the inset
								t:SetPoint(point, barBg, (gsub(relativePoint, "BOTTOM", "TOP")), x, y)
							end
						end
					end
				else
					-- No border pieces found, so draw a plain line
					local line = barBg:CreateTexture(nil, "BORDER")
					line:SetColorTexture(0.35, 0.35, 0.35, 1)
					line:SetPoint("TOPLEFT"); line:SetPoint("TOPRIGHT")
					line:SetHeight(2)
				end
			end

			-- Update the buttons: pictures, greyed out ones and the one for what the model shows
			local modeButtons = {me = meBtn, target = targetBtn, myOutfitOnTarget = myGearBtn, targetOutfitOnMe = theirGearBtn}
			local function UpdateButtons()
				local hasTarget = Safe(UnitIsPlayer("target")) and true or false
				for void, pic in ipairs(mePics) do SetPortraitTexture(pic, "player") end
				for void, pic in ipairs(targetPics) do
					if hasTarget then SetPortraitTexture(pic, "target") else pic:SetTexture("Interface\\CharacterFrame\\TempPortrait") end
				end
				for void, btn in ipairs({targetBtn, myGearBtn, theirGearBtn}) do
					btn:SetEnabled(hasTarget)
					btn.why = L["Target a player to use this."]
				end
				infoBtn:SetEnabled(LeaPlusLC.ShowInfoCardForUnit ~= nil)
				if LeaPlusLC["ShowInfoCards"] == "On" then
					infoBtn.why = L["Reload your UI to use this."]
				else
					infoBtn.why = L["This needs Show info cards to be turned on in Leatrix Plus."]
				end
				local mode = DressupGear.GetMode()
				for key, btn in pairs(modeButtons) do btn:SetChecked(key == mode) end
				for void, btn in ipairs(shades) do Shade(btn) end
			end
			DressupGear.OnModeChanged = UpdateButtons

			-- Clicks (each then shows what the model really shows, as clicking a check button would otherwise flip it)
			meBtn:SetScript("OnClick", function()
				DressupGear.ShowUnit("player", "me")
				ResetAnimation()
				UpdateButtons()
			end)
			targetBtn:SetScript("OnClick", function()
				if Safe(UnitIsPlayer("target")) then
					DressupGear.ShowUnit("target", "target")
					ResetAnimation()
				end
				UpdateButtons()
			end)
			myGearBtn:SetScript("OnClick", function()
				DressupGear.MyOutfitOnTarget()
				ResetAnimation()
				UpdateButtons()
			end)
			theirGearBtn:SetScript("OnClick", function()
				DressupGear.TargetOutfitOnMe()
				ResetAnimation()
				UpdateButtons()
			end)
			infoBtn:SetScript("OnClick", function()
				if not LeaPlusLC.ShowInfoCardForUnit then return end
				local unit = DressupGear.GetUnit()
				if unit then
					LeaPlusLC.ShowInfoCardForUnit(unit)
				else
					DressupGear.Message(L["Target that player to show their info card."])
				end
			end)

			-- Only watch the target while the dressing room is open
			local watcher = CreateFrame("Frame")
			watcher:SetScript("OnEvent", UpdateButtons)
			DressUpFrame:HookScript("OnShow", function()
				watcher:RegisterEvent("PLAYER_TARGET_CHANGED")
				watcher:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "player", "target")
				UpdateButtons()
			end)
			DressUpFrame:HookScript("OnHide", function() watcher:UnregisterAllEvents() end)
			UpdateButtons()

			-- Change player actor to player when reset button is clicked (needed because target button changes it)
			DressUpFrameResetButton:HookScript("OnClick", function()
				local playerActor = DressUpFrame.ModelScene:GetPlayerActor()
				if playerActor then playerActor:SetModelByUnit("player", true, true) end
				-- Start the slot buttons again (the game can reuse the same model, so the light check may not see the reset)
				C_Timer.After(0.1, function() DressupGear.Reset("me") DressupGear.NoteActor() end)
			end)

			----------------------------------------------------------------------
			-- Controls
			----------------------------------------------------------------------

			-- Hide controls for character frame
			CharacterModelScene.ControlFrame:HookScript("OnShow", function()
				CharacterModelScene.ControlFrame:Hide()
			end)

			-- Hide controls for dressing room
			DressUpFrame.ModelScene.ControlFrame:HookScript("OnShow", DressUpFrame.ModelScene.ControlFrame.Hide)

			-- Hide controls for shop
			ModelPreviewFrame.Display.ModelScene.ControlFrame:HookScript("OnShow", function()
				if StorePreviewFrame and StorePreviewFrame:IsShown() then
					ModelPreviewFrame.Display.ModelScene.ControlFrame:Hide()
				end
			end)

			-- Hide controls for mount journal
			EventUtil.ContinueOnAddOnLoaded("Blizzard_Collections",function()
				MountJournal.MountDisplay.ModelScene.ControlFrame:HookScript("OnShow", function()
					MountJournal.MountDisplay.ModelScene.ControlFrame:Hide()
				end)
			end)

			-- Hide controls for housing dashboard
			EventUtil.ContinueOnAddOnLoaded("Blizzard_HousingDashboard", function()
				HousingDashboardFrame.CatalogContent.PreviewFrame.ModelSceneControls:HookScript("OnShow", function()
					HousingDashboardFrame.CatalogContent.PreviewFrame.ModelSceneControls:Hide()
				end)
			end)

			----------------------------------------------------------------------
			-- Wardrobe and inspect system
			----------------------------------------------------------------------

			-- Set zoom speed for mount and pet journal
			EventUtil.ContinueOnAddOnLoaded("Blizzard_Collections",function()

				-- Set zoom speed for mount journal
				MountJournal.MountDisplay.ModelScene:SetScript("OnMouseWheel", function(self, delta)
					for i = 1, LeaPlusLC["DressupFasterZoom"] do
						if MountJournal.MountDisplay.ModelScene.activeCamera then
							MountJournal.MountDisplay.ModelScene.activeCamera:OnMouseWheel(delta)
						end
					end
				end)

			end)

			EventUtil.ContinueOnAddOnLoaded("Blizzard_Transmog",function()

				-- Hide positioning controls for wardrobe
				TransmogFrame.CharacterPreview.ModelScene.ControlFrame:HookScript("OnShow", TransmogFrame.CharacterPreview.ModelScene.ControlFrame.Hide)

				-- Set zoom speed for wardrobe
				TransmogFrame.CharacterPreview.ModelScene:SetScript("OnMouseWheel", function(self, delta)
					for i = 1, LeaPlusLC["DressupFasterZoom"] do
						if TransmogFrame.CharacterPreview.ModelScene.activeCamera then
							TransmogFrame.CharacterPreview.ModelScene.activeCamera:OnMouseWheel(delta)
						end
					end
				end)

				-- Increase zoom out distance
				if LeaPlusLC["DressupMoreZoomOut"] == "On" then
					hooksecurefunc(TransmogFrame.CharacterPreview.ModelScene, "TransitionToModelSceneID", function(self)
						local activeCamera = self:GetActiveCamera()
						if activeCamera then
							local currentZoom = activeCamera:GetZoomDistance()
							activeCamera:SetMaxZoomDistance(5)
							activeCamera:SetZoomDistance(currentZoom)
						end
					end)
				end

				----------------------------------------------------------------------
				-- Transmogrify animation slider
				----------------------------------------------------------------------

				do

					local transmogAnimTable = {0, 4, 5, 143, 119, 26, 25, 27, 28, 108, 120, 51, 124, 52, 125, 126, 62, 63, 41, 42, 43, 44, 132, 38, 14, 115, 193, 48, 110, 109, 134, 197, 0}
					local transmogLastSetting

					LeaPlusLC["TransmogAnim"] = 0 -- Defined here since the setting is not saved
					LeaPlusLC:MakeSL(TransmogFrame, "TransmogAnim", "", 1, #transmogAnimTable - 1, 1, 356, -92, "%.0f")
					LeaPlusCB["TransmogAnim"]:ClearAllPoints()
					LeaPlusCB["TransmogAnim"]:SetPoint("BOTTOM", 0, 6)
					LeaPlusCB["TransmogAnim"]:SetWidth(216)
					LeaPlusCB["TransmogAnim"]:SetFrameLevel(5)
					LeaPlusCB["TransmogAnim"]:HookScript("OnValueChanged", function(self, setting)
						local playerActor = TransmogFrame.CharacterPreview.ModelScene:GetPlayerActor()
						setting = math.floor(setting + 0.5)
						if playerActor and setting ~= lastSetting then
							lastSetting = setting
							playerActor:SetAnimation(transmogAnimTable[setting], 0, 1, 1)
						end
					end)

					-- Function to show animation control
					local function SetAnimationSlider()
						if LeaPlusLC["DressupTransmogAnim"] == "On" then
							LeaPlusCB["TransmogAnim"]:Show()
						else
							LeaPlusCB["TransmogAnim"]:Hide()
						end
						LeaPlusCB["TransmogAnim"]:SetValue(1)
					end

					-- Set animation control with option, startup, preset and reset
					LeaPlusCB["DressupTransmogAnim"]:HookScript("OnClick", SetAnimationSlider)
					SetAnimationSlider()
					LeaPlusCB["EnhanceDressupBtn"]:HookScript("OnClick", function()
						if IsShiftKeyDown() and IsControlKeyDown() then
							LeaPlusLC["DressupTransmogAnim"] = "On"
							SetAnimationSlider()
						end
					end)
					DressupPanel.r:HookScript("OnClick", function()
						LeaPlusLC["DressupTransmogAnim"] = "Off"
						SetAnimationSlider()
						DressupPanel:Hide(); DressupPanel:Show()
					end)

					-- Reset animation when slider is shown
					LeaPlusCB["TransmogAnim"]:HookScript("OnShow", SetAnimationSlider)

					-- Skin slider for ElvUI
					if LeaPlusLC.ElvUI then
						_G.LeaPlusGlobalTransmogAnim = LeaPlusCB["TransmogAnim"]
						LeaPlusLC.ElvUI:GetModule("Skins"):HandleSliderFrame(_G.LeaPlusGlobalTransmogAnim, false)
					end

				end

			end)

			-- Inspect System
			EventUtil.ContinueOnAddOnLoaded("Blizzard_InspectUI",function()
				-- Hide positioning controls
				InspectModelFrameControlFrame:HookScript("OnShow", InspectModelFrameControlFrame.Hide)
			end)

		end

		----------------------------------------------------------------------
		-- Automate gossip (no reload required)
		----------------------------------------------------------------------

		do

			-- Function to skip gossip
			local function SkipGossip(skipAltKeyRequirement)
				if not skipAltKeyRequirement and not IsAltKeyDown() then return end
				local gossipInfoTable = C_GossipInfo.GetOptions()
				if gossipInfoTable and #gossipInfoTable == 1 and C_GossipInfo.GetNumAvailableQuests() == 0 and C_GossipInfo.GetNumActiveQuests() == 0 and gossipInfoTable[1] then
					if gossipInfoTable[1].gossipOptionID then
						C_GossipInfo.SelectOption(gossipInfoTable[1].gossipOptionID)
					else
						-- Some gossip options dont have a gossip option ID (such as Suspicious Noble NPCs in Court of Stars, Suramar)
						if GossipFrame and GossipFrame:IsShown() then GossipFrame:SelectGossipOption(1) end
					end
				end
			end

			-- Create gossip event frame
			local gossipFrame = CreateFrame("FRAME")

			-- Function to setup events
			local function SetupEvents()
				if LeaPlusLC["AutomateGossip"] == "On" then
					gossipFrame:RegisterEvent("GOSSIP_SHOW")
				else
					gossipFrame:UnregisterEvent("GOSSIP_SHOW")
				end
			end

			-- Setup events when option is clicked and on startup (if option is enabled)
			LeaPlusCB["AutomateGossip"]:HookScript("OnClick", SetupEvents)
			if LeaPlusLC["AutomateGossip"] == "On" then SetupEvents() end

			-- Create tables for specific NPC IDs (these are automatically selected with no alt key requirement)
			local npcTable = {

				-- Stable masters (https://www.wowhead.com/forever/npcs?filter=27%3B1%3B0)
				10053, 13617, 10085, 10054, 6749, 9981, 9978, 10061, 9984, 14741, 9982, 10063, 10050, 10059, 10045, 10048, 11069, 10060, 9989, 10047, 10051, 13616, 9980, 9987, 10056, 228176, 10046, 9985, 15131, 10062, 9988, 9983, 10058, 10049, 9979, 9986, 11105, 9977, 11119, 10052, 10055, 11117, 11104, 16094, 9976, 10057, 15722, 251953,

				-- Banker (https://www.wowhead.com/forever/npcs?filter=19;1;0)
				257036, 241862, 258880, 257292, 2455, 3309, 2456, 2461, 4549, 3496, 8356, 2458, 2996, 8357, 2457, 2460, 2459, 5060, 4155, 4208, 257294, 260543, 5099, 7799, 13917, 3318, 4550, 3320, 2625, 275210, 4209, 275212, 275251, 8123, 8119, 8124, 275240, 275243, 275253, 275216, 275252, 275214, 260567,

				-- Flightmaster (https://www.wowhead.com/forever/npcs?filter=21;1;0)
				3615, 352, 257087, 16227, 2226, 1572, 931, 523, 1573, 2432, 11900, 255993, 12616, 3310, 2299, 4267, 2995, 12636, 12617, 10378, 8019, 8610, 1571, 4321, 12740, 4551, 10583, 15178, 3838, 4407, 4312, 7824, 3841, 2859, 8609, 2858, 6726, 4319, 2835, 41861, 12577, 2941, 10897, 6706, 7823, 12596, 260626, 13177, 11901, 6026, 12578, 4317, 2409, 11899, 8018, 8020, 2851, 15177, 2389, 2861, 1387, 11138, 3305, 4314, 11139,

				-- Trainer (https://www.wowhead.com/forever/npcs?filter=28;1;0)
				264936, 248197, 3448, 234, 272045, 3446, 4949, 66, 253372, 5494, 11870, 254151, 252475, 257944, 11867, 246152, 257006, 5567, 1286, 3365, 1253, 11865, 2988, 251684, 253092, 252383, 3649, 1285, 3419, 255940, 4217, 3389, 256732, 253590, 252476, 258098, 12042, 11072, 255877, 246344, 11869, 8508, 5504, 340, 252378, 249713, 11044, 1346, 252380, 11868, 246389, 2704, 5811, 254082, 1275, 3614, 843, 1300, 252390, 248200, 3482, 4568, 1103, 11074, 251905, 3523, 252359, 252373, 1937, 5482, 3032, 265756, 5153, 265574, 244808, 252800, 253576, 3432, 3033, 251993, 5941, 4606, 3363, 344, 253395, 927, 3355, 11026, 5101, 5497, 11098, 240, 266881, 276067, 5491, 5513, 3064, 514, 251992, 6306, 10266, 257021, 1317, 2327, 2132, 3373, 4611, 5515, 260093, 3605, 267336, 254081, 5157, 257019, 3606, 3702, 1232, 205729, 258785, 254345, 11068, 257004, 3391, 4576, 11073, 3069, 254084, 253004, 267327, 257020, 1383, 5695, 5165, 5511, 3191, 247226, 1226, 256083, 3401, 251913, 1231, 257003, 4160, 270459, 5885, 252376, 7088, 5880, 1340, 3595, 2855, 1241, 251991, 257446, 1632, 2836, 377, 8363, 6286, 4219, 3484, 3332, 3171, 1682, 6094, 11028, 5783, 257024, 247223, 4156, 1692, 252382, 5564, 4605, 256507, 4218, 11866, 3344, 1651, 1215, 2129, 1470, 6301, 1243, 3293, 3347, 13084, 928, 914, 5690, 252389, 5115, 11557, 257007, 3338, 4258, 3087, 4607, 461, 5127, 2329, 5150, 3549, 5499, 1700, 10993, 3007, 5159, 5149, 3490, 3703, 251972, 1466, 376, 251507, 3036, 1297, 5939, 4616, 267326, 261, 252479, 3404, 3602, 247227, 3065, 1702, 267338, 3429, 1703, 3661, 1070, 3600, 3066, 491, 5122, 3173, 6018, 251978, 4582, 3658, 1246, 265944, 233, 1325, 4212, 5505, 5173, 3001, 1465, 267332, 3345, 3407, 251374, 4210, 11406, 3352, 5137, 3399, 3026, 8140, 1669, 2080, 271483, 3464, 1699, 252388, 911, 5943, 5174, 3488, 2131, 2128, 3168, 3067, 2326, 3009, 251964, 957, 2399, 11066, 2391, 3967, 3607, 6291, 5148, 254088, 3601, 1698, 10219, 3038, 5518, 3044, 13417, 252377, 895, 11052, 7311, 5479, 3408, 3175, 3412, 257008, 151, 2123, 3348, 5116, 2798, 3016, 267329, 459, 5161, 258113, 3013, 6297, 918, 3041, 267325, 251389, 3172, 251379, 8306, 5498, 1228, 4614, 1386, 235, 11046, 3081, 1681, 4182, 8362, 167, 11065, 3494, 248415, 3326, 251977, 3596, 4609, 9465, 2627, 1218, 3063, 3062, 11096, 11048, 5144, 4552, 3153, 5492, 3357, 257018, 267333, 257005, 4573, 4090, 925, 4193, 5480, 3170, 252084, 2130, 3137, 260562, 257022, 5759, 11049, 5496, 7944, 328, 4598, 10930, 3174, 11081, 3060, 262560, 4596, 3154, 4563, 3028, 4092, 6251, 3047, 4087, 5142, 5489, 3965, 5883, 246797, 2485, 2127, 3354, 1430, 5147, 460, 837, 5172, 8736, 3603, 3327, 5612, 917, 913, 254086, 3706, 10278, 5784, 267334, 1234, 252449, 1691, 5884, 5506, 267324, 1356, 5117, 5177, 3169, 7867, 5516, 3449, 6299, 908, 1229, 1292, 5882, 4211, 3599, 11037, 2998, 267330, 3030, 11084, 259250, 8934, 3324, 5164, 295, 3061, 11025, 375, 11017, 3040, 4588, 4595, 7315, 3290, 4205, 3179, 3039, 3707, 267328, 1323, 262558, 6287, 10276, 4163, 5493, 926, 252379, 5113, 198, 1404, 7948, 3704, 11401, 4565, 3403, 3478, 5392, 3593, 6387, 267335, 3353, 14740, 3045, 5566, 2857, 3049, 6014, 28694, 4204, 11047, 3328, 3034, 916, 251376, 5500, 3031, 5495, 5938, 251373, 812, 7312, 2114, 3046, 3059, 6740, 11071, 1382, 3156, 5958, 2390, 4593, 1355, 6707, 3181, 256655, 4586, 3881, 6929, 1901, 944, 8153, 2878, 1668, 5114, 7232, 5123, 3495, 4254, 4584, 1411, 4146, 11070, 267337, 3157, 912, 3406, 1701, 11083, 6791, 3555, 1697, 3598, 246795, 3604, 3184, 4732, 1963, 2119, 4165, 4608, 8142, 13283, 4564, 12025, 4591, 254087, 6289, 5484, 2122, 11031, 2124, 915, 791, 331, 3597, 1680, 906, 4583, 2834, 11397, 5171, 11050, 5957, 11178, 988, 3043, 8126, 3155, 4594, 3481, 5611, 10277, 4567, 1645, 257422, 7868, 5517, 267331, 8738, 3545, 255891, 227, 2126, 7313, 3609, 2818, 3011, 1458, 3004, 11029, 3048, 6290, 7954, 10054, 3594, 4091, 3325, 5994, 10090, 2367, 986, 258930, 1473, 11067, 7866, 10088, 8308, 4256, 5501, 3322, 3337, 3008, 11041, 5166, 275322, 254411, 8146, 4213, 5143, 11051, 1683, 223, 4214, 3934, 4566, 2489, 3479, 5141, 4773, 7953, 6300, 5167, 3557, 5145, 985, 4772, 1214, 4203, 7870, 11097, 3042, 7871, 9981, 4089, 11042, 2987, 3165, 3610, 2879, 7087, 3185, 987, 1198, 6295, 4215, 3477, 9584, 12961, 2492, 7089, 268238, 271480, 8674, 3963, 4266, 3487, 260558, 3518, 257037, 2046, 6747, 4223, 3177, 275321, 6292, 1676, 4752, 5109, 7406, 8128, 4192, 7869, 6737, 1237, 10045, 11177, 3688, 5502, 9856, 8724, 4898, 10086, 372, 5146, 10089, 3023, 3611, 8141, 6288, 4138, 11069, 4578, 4183, 4195, 2856, 3698, 3291, 3491, 4753, 2837, 8144, 4159, 4320, 3622, 3480, 543, 8358, 6790, 11146, 1670, 8722, 15659, 8673, 1362, 256658, 3486, 8931, 3964, 12032, 9980, 2999, 3136, 3620, 6734, 3306, 3315, 8670, 1385, 4167, 3080, 12030, 259585, 3162, 7230, 4900, 8719, 3003, 3690, 3613, 3624, 7946, 5509, 7231, 7949, 3612, 249968, 2410, 211033, 3955, 4554, 1077, 14754, 256734, 263570, 1074, 956, 11833, 3368, 2055, 5767, 3027, 4225, 12736, 251968, 261366, 256730, 5768, 2094, 268745, 3142, 3313, 3556, 3005, 10216, 1646, 3682, 264078, 2679, 242498, 3413, 277, 3323, 3410, 4307, 267310, 5483, 271465, 955, 1239, 2104, 415, 2784, 248198, 262471, 1938, 3029, 270581, 259013, 7161, 3367, 263, 8361, 270438, 3954, 3387, 1257, 1298, 3497, 4265, 4721, 3134, 951, 256731, 382, 3537, 392, 257421, 2393, 1250, 3333, 3341, 3015, 270582, 258878, 6735, 3701, 253844, 10118, 4201, 2832, 256384, 254089, 228, 248242, 4200, 271613, 5160, 4305, 1343, 3442, 4189, 3489, 2216, 1078, 256389, 5111, 3516, 3616, 2682, 3691, 3845, 777, 1093, 2215, 12043, 197, 256400, 3014, 237, 5565, 272, 894, 289, 265, 1440, 252448, 238, 4169, 8305, 270844, 10537, 7317, 3366, 10369, 3187, 341, 4553, 311, 264, 8307, 259012, 6667, 1242, 279, 2948, 5817, 3562, 5128, 381, 2930, 270280, 3400, 3583, 253285, 12737, 8364, 3178, 3666, 3608, 465, 3339, 343, 4170, 3164, 3536, 4173, 3958, 2383, 254358, 663, 1247, 1154, 1091, 3018, 3483, 249235, 1287, 274, 3961, 3012, 960, 3962, 12196, 1459, 2401, 12962, 10053, 6028, 1448, 1374, 3492, 3650, 2481, 1289, 5512, 244512, 1274, 3519, 4194, 1685, 8359, 271478, 6928, 11857, 342, 259287, 270278, 3292, 4084, 5121, 2394, 251, 2111, 3096, 4775, 4241, 3097, 3085, 1464, 244, 3342, 1687, 7714, 6736, 2388, 9553, 222, 3517, 3567, 11864, 1678, 8723, 2839, 3331, 1456, 1089, 3543, 5944, 6577, 7731, 2997, 1474, 3485, 11137, 1673, 2366, 3644, 2229, 2078, 9859, 3493, 5103, 6746, 1471, 15012, 1461, 4221, 3163, 1452, 2352, 5107, 226, 3572, 8669, 14964, 6739, 10085, 10063, 3319, 9549, 3411, 6730, 3078, 3167, 3952, 8720, 1453, 10048, 6727, 2483, 3498, 2814, 3317, 3953, 3552, 3515, 3969, 793, 3937, 3935, 4191, 15686, 1462, 1686, 3025, 5124, 8671, 5620, 5102, 2140, 8360, 954, 9983, 3318, 3329, 4190, 8398, 3089, 265003, 258306, 256386, 5940, 1684, 12757, 11861, 54, 734, 4877, 3139, 3693, 11860, 4046, 3453, 2437, 4177, 12696, 9099, 10052, 4878, 3390, 1092, 3960, 10056, 1672, 4630, 3933, 9987, 9984, 8672, 2461, 1213, 2456, 10380, 3361, 1650, 6749, 74, 5871, 9551, 3022,

				-- Vendor Level 1-40 (https://www.wowhead.com/forever/npcs/min-level:1/max-level:40?filter=29;1;0)
				4554, 14450, 272045, 66, 5494, 4617, 257006, 3027, 1286, 1684, 3005, 1285, 255940, 3367, 268745, 228, 3014, 4562, 3323, 8508, 4585, 3556, 4555, 4574, 12033, 3346, 844, 252380, 3025, 4086, 3410, 1275, 1318, 3614, 843, 5565, 252390, 3482, 5942, 251905, 4561, 214070, 5757, 242498, 271465, 3012, 7683, 265756, 265574, 1257, 5162, 5483, 277, 9087, 3955, 5758, 2118, 251993, 3550, 217689, 5101, 4189, 1298, 2786, 214101, 3682, 5158, 276067, 254089, 251992, 256736, 256384, 4225, 5519, 214096, 3313, 3605, 256400, 5817, 267336, 251537, 257019, 3530, 254358, 3497, 5940, 1309, 257004, 3164, 12246, 253004, 267327, 257020, 251913, 257003, 256389, 1302, 213077, 252376, 4307, 251991, 1351, 10118, 8363, 1347, 1308, 1682, 465, 274, 5783, 257024, 2682, 1692, 256507, 4615, 3405, 6301, 1243, 955, 4265, 5128, 5151, 2679, 3335, 3531, 3490, 3485, 1297, 1321, 1250, 1247, 214098, 1287, 252479, 3954, 958, 3366, 12245, 254360, 8361, 257421, 491, 5122, 3658, 233, 1303, 1325, 3029, 3350, 1465, 258306, 10216, 3528, 3562, 1312, 265575, 1669, 271483, 252388, 216672, 3488, 2697, 3168, 4575, 5163, 2683, 4553, 3537, 3364, 4612, 1441, 2393, 1698, 6731, 3044, 3532, 5110, 4775, 1694, 5848, 214099, 7976, 3369, 3187, 257008, 151, 3348, 3016, 5411, 4194, 267325, 5503, 1313, 1440, 3081, 3489, 3608, 4182, 8362, 3351, 2685, 2381, 167, 2134, 5175, 5748, 1148, 1454, 4305, 267333, 257005, 2265, 257022, 483, 4879, 5100, 5111, 6730, 6367, 267334, 252449, 1691, 4200, 14846, 267324, 4229, 3960, 1456, 3015, 222, 54, 2264, 3483, 8403, 3186, 3159, 267330, 5510, 3368, 8934, 295, 4589, 3533, 264078, 777, 211653, 267328, 1323, 3539, 258568, 5138, 6741, 262471, 4604, 8666, 3178, 9549, 5160, 4169, 226, 8681, 5178, 3413, 5754, 734, 3577, 6740, 1474, 8307, 4610, 152, 251364, 3881, 4897, 6929, 3134, 2383, 4577, 14847, 1668, 4602, 5123, 4896, 3495, 3498, 5816, 3958, 3529, 3499, 267337, 3333, 3314, 829, 1294, 3097, 3090, 6791, 1697, 1448, 5154, 2672, 2668, 4165, 3091, 12043, 9553, 1261, 4220, 2810, 791, 3587, 272437, 4241, 1326, 4453, 5944, 217412, 1289, 6746, 384, 1459, 2135, 3552, 3481, 5611, 3358, 3018, 4892, 2394, 259860, 5132, 1645, 257422, 3548, 267331, 12962, 3400, 3409, 3096, 3166, 16458, 5512, 3072, 2921, 227, 3609, 3361, 10369, 1263, 2113, 1672, 5193, 3334, 2816, 3951, 5188, 960, 6735, 3542, 2115, 4173, 3077, 8665, 3534, 4731, 836, 8137, 4256, 5133, 3133, 4083, 258, 3322, 790, 3561, 3076, 5191, 3163, 14637, 6576, 4216, 3411, 258548, 2117, 894, 3934, 5688, 3078, 2357, 3479, 3356, 4228, 1349, 2116, 2481, 6300, 225, 2698, 793, 3002, 222261, 13699, 1469, 1685, 1214, 4203, 5620, 5514, 4168, 4188, 6739, 5698, 2401, 7564, 8398, 3053, 5169, 13433, 1291, 3578, 2812, 251965, 3165, 2352, 3610, 2832, 1198, 4235, 1678, 5103, 1452, 8401, 3477, 6928, 1301, 789, 4186, 268238, 271480, 1460, 3167, 8359, 14480, 1673, 259863, 6374, 258572, 4266, 3158, 271478, 3956, 7733, 4590, 2997, 3487, 954, 3536, 4730, 3010, 13420, 208920, 222685, 1320, 3518, 5189, 4230, 2046, 258415, 271006, 1462, 4181, 1238, 3493, 13436, 3962, 4187, 6747, 3589, 1381, 1295, 1299, 272646, 2684, 2819, 4191, 4569, 1687, 6328, 2397, 4170, 1463, 259962, 14860, 4223, 5820, 3085, 4556, 1273, 6736, 6574, 13418, 260560, 5871, 12031, 4085, 5520, 9551, 9676, 3177, 3492, 216902, 7978, 258466, 2140, 28776, 1104, 8139, 4877, 12028, 5049, 5109, 3551, 3541, 14845, 4192, 4259, 4226, 3572, 3180, 3093, 6737, 1305, 1237, 2821, 13435, 3359, 74, 4190, 4557, 2814, 4603, 12027, 2808, 11287, 1319, 258463, 1304, 956, 3020, 4082, 1348, 1324, 6727, 6272, 7736, 1686, 372, 3017, 2380, 2364, 3543, 4597, 5821, 2669, 3023, 1149, 1146, 4222, 8404, 3611, 4084, 1453, 3969, 5112, 1464, 5814, 252020, 78, 3937, 3135, 1322, 5819, 1461, 4183, 8364, 268663, 4195, 3349, 3554, 2366, 5152, 3522, 3019, 5125, 2137, 1333, 2820, 3291, 240568, 7714, 3491, 2483, 3544, 251365, 5749, 8305, 8737, 5108, 1407, 15124, 1650, 1350, 6376, 4981, 12960, 4894, 4164, 5102, 3088, 8150, 216924, 1671, 13434, 4171, 4878, 3480, 2136, 267000, 3553, 13431, 4172, 1450, 6373, 29537, 190, 4587, 8358, 3160, 6790, 4231, 4558, 5107, 5753, 1670, 13429, 3319, 14844, 3092, 8129, 1315, 4234, 1240, 5106, 6028, 6091, 8360, 3591, 1362, 4885, 3086, 12045, 3933, 3486, 3316, 11116, 8931, 12196, 9179, 4888, 3073, 1339, 207743, 259861, 222684, 4581, 4221, 3953, 2999, 1690, 1341, 3952, 3075, 267001, 1314, 4601, 1213, 3540, 8152, 5170, 9501, 6734, 2388, 4876, 3884, 3331, 3161, 945, 4599, 3022, 3935, 3315, 4167, 3080, 1147, 6738, 3021, 3683, 5129, 5190, 13018, 3317, 1249, 3342, 5812, 4899, 28989, 3592, 6496, 3162, 5140, 1310, 3095, 12776, 7737, 11106, 3590, 29491, 5121, 6027, 8122, 5870, 5156, 959, 9555, 8878, 4233, 6495, 1457, 10380, 3138, 5124, 9099, 5508, 4889, 8117, 11137, 29049, 14481, 3003, 4232, 3547, 3948, 6930, 11103, 32413, 13430, 15353, 203475, 3613, 4571, 4592, 3684, 4570, 6298, 3079, 896, 3882, 32631, 2365, 3705, 5750, 5886, 7731, 9356, 7744, 11118, 3329, 3360, 8118, 4580, 3321, 5126, 262469, 3074, 4560, 29547, 5120, 4240, 14963, 4600, 5155, 1311, 5509, 3588, 218115, 3961, 3330, 15354, 4559, 4175, 4891, 5569, 4043, 4886, 3970, 4177, 3883, 4185, 4875, 4236, 5119, 8121, 15125, 32424, 3959, 7485, 13432, 3089, 4954, 14961, 32403, 3612, 14962, 14964, 252080, 256372, 254151, 253139, 253140, 254695, 256672, 257595, 261313, 255894, 275623, 272435, 256675, 32333, 251997, 256657, 275603, 260343, 275626, 275625, 251975, 271005, 275622, 275598, 251999, 265730, 252040, 251955, 32426, 252083, 252019, 275596, 251976, 28990, 32337, 251973, 252000, 251980, 251981, 5695, 256742, 4963,

				-- Vendor Level 41-200 (https://www.wowhead.com/forever/npcs/min-level:41/max-level:200?filter=29;1;0)
				248201, 248197, 256734, 256730, 14754, 14753, 256735, 248202, 233428, 248199, 227853, 263570, 233335, 264797, 4217, 263384, 256732, 2626, 340, 256733, 2934, 248200, 214954, 2805, 256729, 3682, 248196, 6779, 248198, 13476, 15078, 247226, 12792, 12943, 11557, 14581, 14301, 12782, 11036, 247227, 12777, 5173, 12944, 9499, 2664, 230319, 11189, 5594, 256731, 14322, 230317, 12805, 15127, 13278, 240248, 255897, 6777, 1307, 240654, 4047, 32287, 6382, 12919, 265576, 8125, 15126, 13219, 14921, 10667, 12799, 14740, 11278, 13217, 7854, 16376, 13216, 13698, 12022, 14624, 2699, 10618, 2670, 11555, 2663, 5139, 2848, 13218, 2482, 989, 15734, 6548, 7947, 7775, 15419, 8679, 12942, 11536, 2688, 6568, 2839, 12783, 10856, 2806, 11188, 11874, 2084, 12384, 12795, 15179, 260570, 15282, 240604, 260487, 10361, 8161, 2843, 7955, 3779, 4782, 260559, 14738, 15176, 12957, 12958, 255895, 15736, 7852, 983, 1316, 10857, 2846, 2480, 230565, 16256, 14731, 3362, 3625, 9544, 10379, 12021, 2687, 15012, 2803, 12959, 8145, 12096, 15864, 9552, 15174, 7940, 2908, 3685, 2303, 11056, 12793, 11038, 12941, 1695, 15199, 240633, 8131, 1328, 11703, 4890, 222687, 255151, 16015, 12956, 11057, 4255, 3708, 260565, 2849, 15011, 1296, 12097, 235164, 6567, 11187, 6807, 12781, 984, 2842, 7942, 3298, 1471, 2847, 2840, 222408, 240631, 14437, 980, 8678, 9636, 5815, 3689, 4257, 15315, 12029, 8160, 14736, 240632, 11185, 8158, 259766, 240607, 260566, 3000, 5134, 43411, 8143, 241664, 12024, 2622, 5135, 3500, 17070, 12784, 14739, 11182, 14737, 11184, 238376, 17068, 15197, 4180, 2845, 7943, 2844, 15175, 15471, 14522, 7952, 9548, 15006, 981, 12023, 8157, 15898, 8178, 12796, 8177, 12785, 8159, 2225, 3546, 10293, 241663, 3621, 12026, 10364, 222413, 4884, 12019, 14337, 4184, 230566, 4883, 222686, 10367, 12794, 982, 2838, 8176, 3343, 241019, 11186, 17598, 7945, 243855, 5570, 7879, 14371, 4893, 11183, 12807, 7941, 242183, 3700, 7772, 3312, 243815, 8116, 277945, 263569, 263230, 265346, 265577, 5398, 265347, 263440, 248809, 270545, 244512,

				-- Battlemaster (https://www.wowhead.com/forever/npcs?filter=20;1;0)
				347, 3890, 12198, 14981, 15106, 10360, 15007, 857, 2804, 2302, 15006, 12197, 14942, 907, 15008, 7410, 14990, 14991, 7427, 15105, 15102, 14982, 5118, 15103, 263645, 268048, 263349, 268047, 263643, 263647, 263646,

				-- LeaPlusLC.NewPatch - Class trainer (https://www.wowhead.com/forever/npcs?filter=24;1;0)
				4217, 258098, 5504, 4568, 3032, 3033, 4606, 5497, 5491, 5515, 260093, 5165, 3401, 5885, 4219, 4218, 3344, 928, 914, 5115, 4607, 461, 5149, 376, 3036, 6018, 4582, 5505, 5173, 3407, 11406, 3352, 5148, 3038, 3044, 13417, 7311, 5479, 3408, 5116, 918, 3041, 5498, 3326, 5144, 5492, 5480, 5496, 4563, 4092, 3047, 4087, 5142, 5489, 5883, 3354, 5147, 5172, 3327, 5506, 5117, 5516, 5882, 3030, 3324, 3040, 4595, 7315, 4205, 3039, 4163, 5113, 11401, 4565, 3403, 3353, 3045, 3049, 6014, 3328, 3034, 3031, 5495, 7312, 3046, 10881, 4593, 1901, 5114, 4584, 4146, 3406, 4608, 13283, 4564, 5484, 331, 4583, 5171, 3043, 4594, 4567, 3048, 4091, 3325, 5994, 5166, 5143, 4566, 5167, 5145, 3042, 4089, 10879, 252359, 258785, 254411, 10880, 4214, 2198, 10878, 4090, 10088,

				-- Miscellaneous
				132969,	-- Katy Stampwhistle (toy)
				104201,	-- Katy Stampwhistle (npc)

			}

			-- Event handler
			gossipFrame:SetScript("OnEvent", function()
				-- Special treatment for specific NPCs
				local npcGuid = UnitGUID("npc") or nil -- target does not work with soft targeting
				if npcGuid and canaccessvalue(npcGuid) and not IsShiftKeyDown() then
					local void, void, void, void, void, npcID = strsplit("-", npcGuid)
					if npcID then
						-- Open rogue doors in Dalaran (Broken Isles) automatically
						if npcID == "96782"		-- Lucian Trias
						or npcID == "93188"		-- Mongar
						or npcID == "97004"		-- "Red" Jack Findle
						then
							SkipGossip()
							return
						end
						-- Skip gossip with no alt key requirement
						if tContains(npcTable, tonumber(npcID))
						then
							SkipGossip(true) 	-- true means skip alt key requirement
							return
						end
					end
				end
				-- Process gossip
				SkipGossip()
			end)

		end

		----------------------------------------------------------------------
		--	Faster looting
		----------------------------------------------------------------------

		if LeaPlusLC["FasterLooting"] == "On" then

			-- Create configuration panel
			local FasterLootPanel = LeaPlusLC:CreatePanel("Faster auto loot", "FasterLootPanel")

			LeaPlusLC:MakeTx(FasterLootPanel, "Delay", 16, -72)
			LeaPlusLC:MakeSL(FasterLootPanel, "LeaPlusFasterLootDelay", "Drag to set the delay between looting items.|n|nLower is faster but may not always give the best results.|n|nIt's recommended that you leave this setting at 0.3 but feel free to try lower values if you wish.", 0.1, 0.3, 0.1, 16, -92, "%.1f")
			LeaPlusLC:MakeFT(FasterLootPanel, "The default delay setting is 0.3.  Lower is faster but may not always give the best results.  It's recommended that you leave this setting at 0.3.", 16, 510, 96)

			-- Help button hidden
			FasterLootPanel.h:Hide()

			-- Back button handler
			FasterLootPanel.b:SetScript("OnClick", function()
				FasterLootPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page7"]:Show()
				return
			end)

			-- Reset button handler
			FasterLootPanel.r:SetScript("OnClick", function()

				-- Reset slider
				LeaPlusLC["LeaPlusFasterLootDelay"] = 0.3

				-- Refresh side panel
				FasterLootPanel:Hide(); FasterLootPanel:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			LeaPlusCB["FasterLootingBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["LeaPlusFasterLootDelay"] = 0.3
					FasterLootPanel:Hide(); FasterLootPanel:Show()
				else
					FasterLootPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

			-- Time delay
			local tDelay = 0

			-- Fast loot function
			local function FastLoot()
				if GetTime() - tDelay >= LeaPlusLC["LeaPlusFasterLootDelay"] then
					tDelay = GetTime()
					if GetCVarBool("autoLootDefault") ~= IsModifiedClick("AUTOLOOTTOGGLE") then
						if TSMDestroyBtn and TSMDestroyBtn:IsShown() and TSMDestroyBtn:GetButtonState() == "DISABLED" then tDelay = GetTime() return end
						for i = GetNumLootItems(), 1, -1 do
							LootSlot(i)
						end
						tDelay = GetTime()
					end
				end
			end

			-- Event frame
			local faster = CreateFrame("Frame")
			faster:RegisterEvent("LOOT_READY")
			faster:SetScript("OnEvent", FastLoot)

		end

		----------------------------------------------------------------------
		--	Hide event toasts
		----------------------------------------------------------------------

		if LeaPlusLC["HideEventToasts"] == "On" then

			-- Hide event toasts when shown except toasts with a close button (Torghast final scores)
			hooksecurefunc(EventToastManagerFrame, "Show", function()
				if not EventToastManagerFrame.HideButton:IsShown() then
					if EventToastManagerFrame.currentDisplayingToast then
						if IsInJailersTower() then
							-- Show floor summary
							local title = EventToastManagerFrame.currentDisplayingToast.Title:GetText() or nil
							if title and strfind(title, JAILERS_TOWER_SCENARIO_FLOOR) then
								-- Add right-click to close floor summary
								EventToastManagerFrame.currentDisplayingToast:SetScript("OnMouseDown", function(self, btn)
									if btn == "RightButton" then
										EventToastManagerFrame:CloseActiveToasts()
										return
									end
								end)
								return
							end
						end
						EventToastManagerFrame.currentDisplayingToast:OnAnimatedOut()
					end
				end
			end)

			-- Force zone text to show while EventToastManagerFrame is showing
			ZoneTextFrame:HookScript("OnEvent", function(self, event)
				if EventToastManagerFrame:IsShown() then
					if event == "ZONE_CHANGED_NEW_AREA" and not ZoneTextFrame:IsShown() then
						FadingFrame_Show(ZoneTextFrame)
					elseif event == "ZONE_CHANGED_INDOORS" and not SubZoneTextFrame:IsShown() then
						FadingFrame_Show(SubZoneTextFrame)
					end
				end
			end)

		end

		----------------------------------------------------------------------
		--	Hide boss banner
		----------------------------------------------------------------------

		if LeaPlusLC["HideBossBanner"] == "On" then
			BossBanner:UnregisterEvent("ENCOUNTER_LOOT_RECEIVED")
			BossBanner:UnregisterEvent("BOSS_KILL")
		end

		----------------------------------------------------------------------
		--	Hide clean-up buttons
		----------------------------------------------------------------------

		if LeaPlusLC["HideCleanupBtns"] == "On" and not LeaLockList["HideCleanupBtns"] then
			-- Hide backpack clean-up button and make item search box longer
			BagItemAutoSortButton:HookScript("OnShow", BagItemAutoSortButton.Hide)
			hooksecurefunc(ContainerFrame1, "SetSearchBoxPoint", function()
				if BagItemSearchBox:GetWidth() ~= 120 then
					BagItemSearchBox:SetWidth(120)
				end
			end)

			-- Hide bank frame clean-up button and make item search box longer
			BankPanel.AutoSortButton:HookScript("OnShow", BankPanel.AutoSortButton.Hide)
			BankItemSearchBox:ClearAllPoints()
			BankItemSearchBox:SetPoint("TOPRIGHT", BankFrame, "TOPRIGHT", -27, -33)
			BankItemSearchBox:SetWidth(120)
		end

		----------------------------------------------------------------------
		--	Automate quests (no reload required)
		----------------------------------------------------------------------

		do

			-- Create configuration panel
			local QuestPanel = LeaPlusLC:CreatePanel("Automate quests", "QuestPanel")

			LeaPlusLC:MakeTx(QuestPanel, "Settings", 16, -72)
			LeaPlusLC:MakeCB(QuestPanel, "AutoQuestRegular", "Accept regular quests automatically", 16, -92, false, "If checked, regular quests will be accepted automatically.|n|nThis does not apply to daily or weekly quests.")
			LeaPlusLC:MakeCB(QuestPanel, "AutoQuestDaily", "Accept daily quests automatically", 16, -112, false, "If checked, daily quests will be accepted automatically.")
			LeaPlusLC:MakeCB(QuestPanel, "AutoQuestWeekly", "Accept weekly quests automatically", 16, -132, false, "If checked, weekly quests will be accepted automatically.")
			LeaPlusLC:MakeCB(QuestPanel, "AutoQuestCompleted", "Turn-in completed quests automatically", 16, -152, false, "If checked, completed quests will be turned-in automatically.")
			LeaPlusLC:MakeCB(QuestPanel, "AutoQuestShift", "Require override key for quest automation", 16, -172, false, "If checked, you will need to hold the override key down for quests to be automated.|n|nIf unchecked, holding the override key will prevent quests from being automated.")

			-- Add dropdown menu
			LeaPlusLC:CreateDropdown("AutoQuestKeyMenu", "Override key", 146, "TOPLEFT", QuestPanel, "TOPLEFT", 356, -92, false, {{L["SHIFT"], 1}, {L["ALT"], 2}, {L["CONTROL"], 3}, {L["CMD (MAC)"], 4}})

			-- Help button hidden
			QuestPanel.h:Hide()

			-- Back button handler
			QuestPanel.b:SetScript("OnClick", function()
				QuestPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page1"]:Show();
				return
			end)

			-- Reset button handler
			QuestPanel.r:SetScript("OnClick", function()

				-- Reset checkboxes
				LeaPlusLC["AutoQuestShift"] = "Off"
				LeaPlusLC["AutoQuestRegular"] = "On"
				LeaPlusLC["AutoQuestDaily"] = "On"
				LeaPlusLC["AutoQuestWeekly"] = "On"
				LeaPlusLC["AutoQuestCompleted"] = "On"
				LeaPlusLC["AutoQuestKeyMenu"] = 1

				-- Refresh panel
				QuestPanel:Hide(); QuestPanel:Show()

			end)

			-- Show panal when options panel button is clicked
			LeaPlusCB["AutomateQuestsBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["AutoQuestShift"] = "Off"
					LeaPlusLC["AutoQuestRegular"] = "On"
					LeaPlusLC["AutoQuestDaily"] = "On"
					LeaPlusLC["AutoQuestWeekly"] = "On"
					LeaPlusLC["AutoQuestCompleted"] = "On"
					LeaPlusLC["AutoQuestKeyMenu"] = 1
				else
					QuestPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

			-- Function to determine if override key is being held
			local function IsOverrideKeyDown()
				if LeaPlusLC["AutoQuestKeyMenu"] == 1 and IsShiftKeyDown()
				or LeaPlusLC["AutoQuestKeyMenu"] == 2 and IsAltKeyDown()
				or LeaPlusLC["AutoQuestKeyMenu"] == 3 and IsControlKeyDown()
				or LeaPlusLC["AutoQuestKeyMenu"] == 4 and IsMetaKeyDown()
				then
					return true
				end
			end

			-- Funcion to ignore specific NPCs
			local function isNpcBlocked(actionType)
				local npcGuid = UnitGUID("npc") or nil -- npc works when cvar SoftTargetInteract set to 3 (was target)
				if npcGuid and canaccessvalue(npcGuid) then
					local void, void, void, void, void, npcID = strsplit("-", npcGuid)
					if npcID then
						-- Ignore specific NPCs for selecting, accepting and turning-in quests (required if automation has consequences)
						if npcID == "15192" 	-- Anachronos (Caverns of Time)
						or npcID == "119388" 	-- Chieftain Hatuun (Krokul Hovel, Krokuun)
						or npcID == "6566" 		-- Estelle Gendry (Heirloom Curator, Undercity)
						or npcID == "45400" 	-- Fiona's Caravan (Eastern Plaguelands)
						or npcID == "18166" 	-- Khadgar (Allegiance to Aldor/Scryer, Shattrath)
						or npcID == "55402" 	-- Korgol Crushskull (Darkmoon Faire, Pit Master)
						or npcID == "6294" 		-- Krom Stoutarm (Heirloom Curator, Ironforge)
						or npcID == "109227" 	-- Meliah Grayfeather (Tradewind Roost, Highmountain)
						or npcID == "99183" 	-- Renegade Ironworker (Tanaan Jungle, repeatable quest)
						or npcID == "114719" 	-- Trader Caelen (Obliterum Forge, Dalaran, Broken Isles)
						-- Seals of Fate
						or npcID == "111243" 	-- Archmage Lan'dalock (Seal quest, Dalaran)
						or npcID == "87391" 	-- Fate-Twister Seress (Seal quest, Stormshield)
						or npcID == "88570"		-- Fate-Twister Tiklal (Seal quest, Horde)
						or npcID == "142063" 	-- Tezran (Seal quest, Boralus Harbor, Alliance)
						or npcID == "141584" 	-- Zurvan (Seal quest, Dazar'alor, Horde)
						-- Wartime Donations (Alliance)
						or npcID == "142994" 	-- Brandal Darkbeard (Boralus)
						or npcID == "142995" 	-- Charlane (Boralus)
						or npcID == "142993" 	-- Chelsea Strand (Boralus)
						or npcID == "142998" 	-- Faella (Boralus)
						or npcID == "143004" 	-- Larold Kyne (Boralus)
						or npcID == "143005" 	-- Liao (Boralus)
						or npcID == "143007" 	-- Mae Wagglewand (Boralus)
						or npcID == "143008" 	-- Norber Togglesprocket (Boralus)
						or npcID == "142685" 	-- Paymaster Vauldren (Boralus)
						or npcID == "142700" 	-- Quartermaster Peregrin (Boralus)
						or npcID == "142997" 	-- Senedras (Boralus)
						-- Wartime Donations (Horde)
						or npcID == "142970" 	-- Kuma Longhoof (Dazar'alor)
						or npcID == "142969" 	-- Logarr (Dazar'alor)
						or npcID == "142973" 	-- Mai-Lu (Dazar'alor)
						or npcID == "142977" 	-- Meredith Swane (Dazar'alor)
						or npcID == "142981" 	-- Merill Redgrave (Dazar'alor)
						or npcID == "142157" 	-- Paymaster Grintooth (Dazar'alor)
						or npcID == "142158" 	-- Quartermaster Rauka (Dazar'alor)
						or npcID == "142975" 	-- Seamstress Vessa (Dazar'alor)
						or npcID == "142983" 	-- Swizzle Fizzcrank (Dazar'alor)
						or npcID == "142992" 	-- Uma'wi (Dazar'alor)
						or npcID == "142159" 	-- Zen'kin (Dazar'alor)
						-- Dragonflight
						or npcID == "193110" 	-- Khadin <Master Artisan> (Ohn'ahran Plains)
						then
							return true
						end
						-- Ignore specific NPCs for selecting quests only (only used for items that have no other purpose)
						if actionType == "Select" then
							if npcID == "87706" 	-- Gazmolf Futzwangler (Reputation quests, Nagrand, Draenor)
							or npcID == "70022" 	-- Ku'ma (Isle of Giants, Pandaria)
							or npcID == "12944" 	-- Lokhtos Darkbargainer (Thorium Brotherhood, Blackrock Depths)
							or npcID == "87393" 	-- Sallee Silverclamp (Reputation quests, Nagrand, Draenor)
							or npcID == "10307" 	-- Witch Doctor Mau'ari (E'Ko quests, Winterspring)
							then
								return true
							end
						end
					end
				end
			end

			-- Function to check if quest ID is blocked
			local function IsQuestIDBlocked(questID)
				if questID then
					if questID == 43923		-- Starlight Rose
					or questID == 43924		-- Leyblood
					or questID == 43925		-- Runescale Koi
					or questID == 71162		-- Waygate: Algeth'era (Thaelin Darkanvil, Dragonflight)
					or questID == 71165		-- Waygate: Eon's Fringe (Thaelin Darkanvil, Dragonflight)
					or questID == 71138		-- Waygate: Rusza'thar Reach (Thaelin Darkanvil, Dragonflight)
					or questID == 71178		-- Waygate: Shady Sanctuary (Thaelin Darkanvil, Dragonflight)
					or questID == 71157		-- Waygate: Skytop Observatory (Thaelin Darkanvil, Dragonflight)
					or questID == 71161		-- Waygate: Vakthros (Thaelin Darkanvil, Dragonflight)

					-- Khuri (The Dragon Isles) (Catch and Release quests) (don't select and accept quest if requirements aren't met including bank storage)
					or questID == 70199 and C_Item.GetItemCount(194730, true, true, true) < 20 -- Scalebelly Mackerel
					or questID == 70200 and C_Item.GetItemCount(194966, true, true, true) < 20 -- Thousandbite Piranha
					or questID == 70201 and C_Item.GetItemCount(194967, true, true, true) < 20 -- Aileron Seamoth
					or questID == 70202 and C_Item.GetItemCount(194968, true, true, true) < 20 -- Cerulean Spinefish
					or questID == 70203 and C_Item.GetItemCount(194969, true, true, true) < 20 -- Temporal Dragonhead
					or questID == 70935 and C_Item.GetItemCount(194970, true, true, true) < 20 -- Islefin Dorado

					then
						return true
					end
				end
			end

			-- Function to check if a required item is account-bound
			local function IsItemAccountBound(itemID)
				local tooltipData = C_TooltipInfo.GetItemByID(itemID)
				for row, line in ipairs(tooltipData.lines) do
					if tooltipData.lines[row] and tooltipData.lines[row].leftText and (tooltipData.lines[row].leftText == ITEM_BNETACCOUNTBOUND or tooltipData.lines[row].leftText == ITEM_BIND_TO_BNETACCOUNT or tooltipData.lines[row].leftText == ITEM_BIND_TO_ACCOUNT or tooltipData.lines[row].leftText == ITEM_ACCOUNTBOUND) then
						return true
					end
				end
			end

			-- Function to check if quest requires currency or a crafting reagent or required item is account-bound
			local function QuestRequiresCurrency()
				for i = 1, 6 do
					local progItem = _G["QuestProgressItem" ..i] or nil
					if progItem and progItem:IsShown() and progItem.type == "required" then
						if progItem.objectType == "currency" then
							-- Quest requires currency so do nothing
							return true
						elseif progItem.objectType == "item" then
							-- Quest requires an item
							local name, texture, numItems, void, void, itemID = GetQuestItemInfo("required", i)
							if name and itemID then
								local void, void, void, void, void, void, void, void, void, void, void, void, void, void, void, void, isCraftingReagent = C_Item.GetItemInfo(itemID)
								if isCraftingReagent or IsItemAccountBound(itemID) then
									-- Item is a crafting reagent or account-bound so do nothing
									return true
								end
							end
						end
					end
				end
			end

			-- Function to check if quest requires gold
			local function QuestRequiresGold()
				local goldRequiredAmount = GetQuestMoneyToGet()
				if goldRequiredAmount and goldRequiredAmount > 0 then
					return true
				end
			end

			-- Function to check if quest ID has requirements met
			local function DoesQuestHaveRequirementsMet(qID)
				if qID and qID ~= "" then

					if not qID then

					-- Scourgestones
					elseif qID == 62293 then
						-- Quest Darkened Scourgestones requires 25 Darkened Scourgestones
						if C_Item.GetItemCount(180720) >= 25 then return true end

					elseif qID == 62292 then
						-- Quest Pitch Black Scourgestones requires 25 Pitch Black Scourgestones
						if C_Item.GetItemCount(183200) >= 25 then return true end

					elseif qID == 10325 or qID == 10326 then
						-- Requires 10 More Marks of Kil'jaeden
						if C_Item.GetItemCount(29425) >= 10 then return true end

					elseif qID == 10655 or qID == 10828 then
						-- Requires 1 Marks of Sargeras (if more than 10, leave for More Marks of Sargeras)
						if C_Item.GetItemCount(30809) >= 1 and C_Item.GetItemCount(30809) < 10 then return true end

					elseif qID == 10654 or qID == 10827 then
						-- Requires 10 Marks of Sargeras
						if C_Item.GetItemCount(30809) >= 10 then return true end

					elseif qID == 10412 or qID == 10415 then
						-- Requires 10 Firewing Signets
						if C_Item.GetItemCount(29426) >= 10 then return true end

					elseif qID == 10659 or qID == 10822 then
						-- Requires 1 Sunfury Signet (if more than 10, leave for More Sunfury Signets)
						if C_Item.GetItemCount(30810) >= 1 and C_Item.GetItemCount(30810) < 10 then return true end

					elseif qID == 10658 or qID == 10823 then
						-- Requires 10 Sunfury Signets
						if C_Item.GetItemCount(30810) >= 10 then return true end

					else return true
					end
				end
			end

			-- Create event frame
			local qFrame = CreateFrame("FRAME")

			-- Function to setup events
			local function SetupEvents()
				if LeaPlusLC["AutomateQuests"] == "On" then
					qFrame:RegisterEvent("QUEST_DETAIL")
					qFrame:RegisterEvent("QUEST_ACCEPT_CONFIRM")
					qFrame:RegisterEvent("QUEST_PROGRESS")
					qFrame:RegisterEvent("QUEST_COMPLETE")
					qFrame:RegisterEvent("QUEST_GREETING")
					qFrame:RegisterEvent("QUEST_AUTOCOMPLETE")
					qFrame:RegisterEvent("GOSSIP_SHOW")
					qFrame:RegisterEvent("QUEST_FINISHED")
				else
					qFrame:UnregisterAllEvents()
				end
			end

			-- Setup events when option is clicked and on startup (if option is enabled)
			LeaPlusCB["AutomateQuests"]:HookScript("OnClick", SetupEvents)
			if LeaPlusLC["AutomateQuests"] == "On" then SetupEvents() end

			-- Store quest frequency values
			local regularQuest = Enum.QuestFrequency.Default
			local dailyQuest = Enum.QuestFrequency.Daily
			local weeklyQuest = Enum.QuestFrequency.Weekly

			-- Event handler
			qFrame:SetScript("OnEvent", function(self, event, arg1)

				-- Block shared quests if option is enabled
				if event == "QUEST_DETAIL" then
					LeaPlusLC:CheckIfQuestIsSharedAndShouldBeDeclined()
				end

				-- Clear progress items when quest interaction has ceased
				if event == "QUEST_FINISHED" then
					for i = 1, 6 do
						local progItem = _G["QuestProgressItem" ..i] or nil
						if progItem and progItem:IsShown() then
							progItem:Hide()
						end
					end
					return
				end

				-- Check for SHIFT key modifier
				if LeaPlusLC["AutoQuestShift"] == "On" and not IsOverrideKeyDown() then return
				elseif LeaPlusLC["AutoQuestShift"] == "Off" and IsOverrideKeyDown() then return
				end

				----------------------------------------------------------------------
				-- Accept quests automatically
				----------------------------------------------------------------------

				-- Accept quests with a quest detail window
				if event == "QUEST_DETAIL" then
					if LeaPlusLC["AutoQuestRegular"] == "On" or LeaPlusLC["AutoQuestDaily"] == "On" or LeaPlusLC["AutoQuestWeekly"] == "On" then
						-- Don't accept quests if option is not enabled
						if LeaPlusLC["AutoQuestRegular"] == "Off" and not QuestIsDaily() and not QuestIsWeekly() then return end
						-- Don't accept daily quests if option is not enabled
						if LeaPlusLC["AutoQuestDaily"] == "Off" and QuestIsDaily() then return end
						-- Don't accept weekly quests if option is not enabled
						if LeaPlusLC["AutoQuestWeekly"] == "Off" and QuestIsWeekly() then return end
						-- Don't accept blocked quests
						if isNpcBlocked("Accept") then return end
						-- Accept quest
						if QuestGetAutoAccept() then
							-- Quest has already been accepted by Wow so close the quest detail window
							CloseQuest()
						else
							-- Quest has not been accepted by Wow so accept it
							AcceptQuest()
							--HideUIPanel(QuestFrame)
						end
					end
				end

				-- Accept quests which require confirmation (such as sharing escort quests)
				if event == "QUEST_ACCEPT_CONFIRM" then
					if LeaPlusLC["AutoQuestRegular"] == "On" then
						ConfirmAcceptQuest()
						StaticPopup_Hide("QUEST_ACCEPT")
					end
				end

				----------------------------------------------------------------------
				-- Turn-in quests automatically
				----------------------------------------------------------------------

				-- Turn-in progression quests
				if event == "QUEST_PROGRESS" and IsQuestCompletable() then
					if LeaPlusLC["AutoQuestCompleted"] == "On" then
						-- Don't continue quests for blocked NPCs
						if isNpcBlocked("Complete") then return end
						-- Don't continue if quest requires currency
						if QuestRequiresCurrency() then return end
						-- Don't continue if quest requires gold
						if QuestRequiresGold() then return end
						-- Continue quest
						CompleteQuest()
					end
				end

				-- Turn in completed quests if only one reward item is being offered
				if event == "QUEST_COMPLETE" then
					if LeaPlusLC["AutoQuestCompleted"] == "On" then
						-- Don't complete quests for blocked NPCs
						if isNpcBlocked("Complete") then return end
						-- Don't complete if quest requires currency
						if QuestRequiresCurrency() then return end
						-- Don't complete if quest requires gold
						if QuestRequiresGold() then return end
						-- Complete quest
						if GetNumQuestChoices() <= 1 then
							GetQuestReward(GetNumQuestChoices())
						end
					end
				end

				-- Show quest dialog for quests that use the objective tracker (it will be completed automatically)
				if event == "QUEST_AUTOCOMPLETE" then
					if LeaPlusLC["AutoQuestCompleted"] == "On" then
						local index = C_QuestLog.GetLogIndexForQuestID(arg1)
						local info = C_QuestLog.GetInfo(index)
						if info and info.isAutoComplete then
							local questID = C_QuestLog.GetQuestIDForLogIndex(index)
							C_QuestLog.SetSelectedQuest(questID)
							ShowQuestComplete(C_QuestLog.GetSelectedQuest())
						end
					end
				end

				----------------------------------------------------------------------
				-- Select quests automatically
				----------------------------------------------------------------------

				if event == "GOSSIP_SHOW" or event == "QUEST_GREETING" then

					-- Select quests
					if UnitExists("npc") or QuestFrameGreetingPanel:IsShown() then

						-- Do nothing if there is a gossip option with a color code (such as skip ahead)
						local gossipInfoTable = C_GossipInfo.GetOptions()
						for i = 1, #gossipInfoTable do
							local nameText = gossipInfoTable[i].name
							if nameText then
								if string.find(strupper(nameText), "|C") or string.find(strupper(nameText), "<")then
									if not string.find(nameText, "FF0008E8") then -- Purple text such as Darkmoon Faire daily quests
										return
									end
								end
							end
						end

						-- Don't select quests for blocked NPCs
						if isNpcBlocked("Select") then return end

						-- Select quests
						if event == "QUEST_GREETING" then
							-- Select quest greeting completed quests
							if LeaPlusLC["AutoQuestCompleted"] == "On" then
								for i = 1, GetNumActiveQuests() do
									local title, isComplete = GetActiveTitle(i)
									if title and isComplete then
										return SelectActiveQuest(i)
									end
								end
							end
							-- Select quest greeting available quests
							if LeaPlusLC["AutoQuestRegular"] == "On" or LeaPlusLC["AutoQuestDaily"] == "On" or LeaPlusLC["AutoQuestWeekly"] == "On" then
								for i = 1, GetNumAvailableQuests() do
									local title, isComplete = GetAvailableTitle(i)
									if title and not isComplete then
										local isTrivial, frequency, isRepeatable, isLegendary = GetAvailableQuestInfo(i)
										if frequency ~= regularQuest or LeaPlusLC["AutoQuestRegular"] == "On" then
											if frequency ~= dailyQuest or LeaPlusLC["AutoQuestDaily"] == "On" then
												if frequency ~= weeklyQuest or LeaPlusLC["AutoQuestWeekly"] == "On" then
													return SelectAvailableQuest(i)
												end
											end
										end
									end
								end
							end
						else
							-- Select gossip completed quests
							if LeaPlusLC["AutoQuestCompleted"] == "On" then
								local gossipQuests = C_GossipInfo.GetActiveQuests()
								for titleIndex, questInfo in ipairs(gossipQuests) do
									if questInfo.title and questInfo.isComplete then
										if questInfo.questID then
											return C_GossipInfo.SelectActiveQuest(questInfo.questID)
										end
									end
								end
							end
							-- Select gossip available quests
							if LeaPlusLC["AutoQuestRegular"] == "On" or LeaPlusLC["AutoQuestDaily"] == "On" or LeaPlusLC["AutoQuestWeekly"] == "On" then
								local GossipQuests = C_GossipInfo.GetAvailableQuests()
								for titleIndex, questInfo in ipairs(GossipQuests) do
									if questInfo.frequency ~= regularQuest or LeaPlusLC["AutoQuestRegular"] == "On" then
										if questInfo.frequency ~= dailyQuest or LeaPlusLC["AutoQuestDaily"] == "On" then
											if questInfo.frequency ~= weeklyQuest or LeaPlusLC["AutoQuestWeekly"] == "On" then
												if questInfo.questID and not IsQuestIDBlocked(questInfo.questID) and DoesQuestHaveRequirementsMet(questInfo.questID) then
													return C_GossipInfo.SelectAvailableQuest(questInfo.questID)
												end
											end
										end
									end
								end
							end
						end
					end
				end

			end)

		end

		----------------------------------------------------------------------
		--	Sell junk automatically
		----------------------------------------------------------------------

		if LeaPlusLC["AutoSellJunk"] == "On" then

			-- Hide the sell all junk items button
			MerchantSellAllJunkButton:HookScript("OnShow", function() MerchantSellAllJunkButton:Hide() end)

			-- Create sell junk banner
			local StartMsg = CreateFrame("FRAME", nil, MerchantFrame)
			StartMsg:ClearAllPoints()
			StartMsg:SetPoint("BOTTOMLEFT", 4, 4)
			StartMsg:SetSize(160, 22)
			StartMsg:SetToplevel(true)
			StartMsg:Hide()

			StartMsg.s = StartMsg:CreateTexture(nil, "BACKGROUND")
			StartMsg.s:SetAllPoints()
			StartMsg.s:SetColorTexture(0.1, 0.1, 0.1, 1.0)

			StartMsg.f = StartMsg:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
			StartMsg.f:SetAllPoints();
			StartMsg.f:SetText(L["SELLING JUNK"])

			-- Declarations
			local IterationCount, totalPrice = 500, 0
			local SellJunkTicker

			-- Create custom NewTicker function (from Wrath)
			local function LeaPlusNewTicker(duration, callback, iterations)
				local ticker = setmetatable({}, TickerMetatable)
				ticker._remainingIterations = iterations
				ticker._callback = function()
					if (not ticker._cancelled) then
						callback(ticker)
						--Make sure we weren't cancelled during the callback
						if (not ticker._cancelled) then
							if (ticker._remainingIterations) then
								ticker._remainingIterations = ticker._remainingIterations - 1
							end
							if (not ticker._remainingIterations or ticker._remainingIterations > 0) then
								C_Timer.After(duration, ticker._callback)
							end
						end
					end
				end
				C_Timer.After(duration, ticker._callback)
				return ticker
			end

			-- Create configuration panel
			local SellJunkFrame = LeaPlusLC:CreatePanel("Sell junk automatically", "SellJunkFrame")
			LeaPlusLC:MakeTx(SellJunkFrame, "Settings", 16, -72)
			LeaPlusLC:MakeCB(SellJunkFrame, "AutoSellShowSummary", "Show vendor summary in chat", 16, -92, false, "If checked, a vendor summary will be shown in chat when junk is automatically sold.")
			LeaPlusLC:MakeCB(SellJunkFrame, "AutoSellNoGreyGear", "Exclude all unbound grey gear", 16, -112, false, L["If checked, grey gear that is not soulbound to your character will not be sold.|n|nUse this setting if you plan to sell grey gear in the auction house."])

			-- Help button hidden
			SellJunkFrame.h:Hide()

			-- Back button handler
			SellJunkFrame.b:SetScript("OnClick", function()
				SellJunkFrame:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page1"]:Show();
				return
			end)

			-- Reset button handler
			SellJunkFrame.r.tiptext = SellJunkFrame.r.tiptext .. "|n|n" .. L["Note that this will not reset your exclusions list."]
			SellJunkFrame.r:SetScript("OnClick", function()

				-- Reset checkboxes
				LeaPlusLC["AutoSellShowSummary"] = "On"
				LeaPlusLC["AutoSellNoGreyGear"] = "Off"

				-- Refresh panel
				SellJunkFrame:Hide(); SellJunkFrame:Show()

			end)

			-- Show panal when options panel button is clicked
			LeaPlusCB["AutoSellJunkBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["AutoSellShowSummary"] = "On"
					LeaPlusLC["AutoSellNoGreyGear"] = "Off"
				else
					SellJunkFrame:Show()
					LeaPlusLC:HideFrames()
				end
			end)

			-- Function to stop selling
			local function StopSelling()
				if SellJunkTicker then SellJunkTicker._cancelled = true; end
				StartMsg:Hide()
				SellJunkFrame:UnregisterEvent("ITEM_LOCKED")
				SellJunkFrame:UnregisterEvent("UI_ERROR_MESSAGE")
			end

			-- Create excluded box
			local titleTX = LeaPlusLC:MakeTx(SellJunkFrame, "Exclusions", 356, -72)
			titleTX:SetWidth(200)
			titleTX:SetWordWrap(false)
			titleTX:SetJustifyH("LEFT")

			-- Show help button for exclusions
			LeaPlusLC:CreateHelpButton("SellJunkExcludeHelpButton", SellJunkFrame, titleTX, "Enter item IDs separated by commas.  Item IDs can be found in item tooltips while this panel is showing.|n|nJunk items entered here will not be sold automatically.|n|nWhite items entered here will be sold automatically.|n|nThe editbox tooltip will show you more information about the items you have entered.")

			local eb = CreateFrame("Frame", nil, SellJunkFrame, "BackdropTemplate")
			eb:SetSize(200, LeaPlusLC.MainPanelHeight - 180)
			eb:SetPoint("TOPLEFT", 350, -92)
			eb:SetBackdrop({
				bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
				edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight",
				edgeSize = 16,
				insets = {left = 8, right = 6, top = 8, bottom = 8},
			})
			eb:SetBackdropBorderColor(1.0, 0.85, 0.0, 0.5)

			eb.scroll = CreateFrame("ScrollFrame", nil, eb, "LeaPlusSellJunkScrollFrameTemplate")
			eb.scroll:SetPoint("TOPLEFT", eb, 12, -10)
			eb.scroll:SetPoint("BOTTOMRIGHT", eb, -30, 10)
			eb.scroll:SetPanExtent(16)

			-- Create character count
			eb.scroll.CharCount = eb.scroll:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
			eb.scroll.CharCount:Hide()

			eb.Text = eb.scroll.EditBox
			eb.Text:SetWidth(150)
			eb.Text:SetPoint("TOPLEFT", eb.scroll)
			eb.Text:SetPoint("BOTTOMRIGHT", eb.scroll, -12, 0)
			eb.Text:SetMaxLetters(2000)
			eb.Text:SetFontObject(GameFontNormalLarge)
			eb.Text:SetAutoFocus(false)
			eb.scroll:SetScrollChild(eb.Text)

			-- Set focus on the editbox text when clicking the editbox
			eb:SetScript("OnMouseDown", function()
				eb.Text:SetFocus()
				eb.Text:SetCursorPosition(eb.Text:GetMaxLetters())
			end)

			-- Function to create whitelist
			local whiteList = {}
			local function UpdateWhiteList()
				wipe(whiteList)

				-- These items cannot be sold but the game thinks they can be
				-- https://www.wowhead.com/items/quest/min-level:1/max-level:1/quality:0?filter=64;3;1

				-- Continued Waygate Exploration
				whiteList[200590] = "Carefully Rolled Message"
				whiteList[200593] = "Sealed Expedition Note"
				whiteList[200594] = "Thaelin's Second Favorite Comb"
				whiteList[200595] = "Odorous Parchment"
				whiteList[200596] = "Letter from Thaelin Darkanvil"

				-- Dirty Old Satchel
				whiteList[200592] = "Dirty Old Satchel"
				whiteList[200606] = "Previously Owned Map"

				-- Rock Buddy (item cannot be sold but sell price is reported as 1)
				whiteList[228431] = "Rock Buddy"

				-- End of whitelist

				local whiteString = eb.Text:GetText()
				if whiteString and whiteString ~= "" then
					whiteString = whiteString:gsub("[^,%d]", "")
					local tList = {strsplit(",", whiteString)}
					for i = 1, #tList do
						if tList[i] then
							tList[i] = tonumber(tList[i])
							if tList[i] then
								whiteList[tList[i]] = true
							end
						end
					end
				end

				LeaPlusLC["AutoSellExcludeList"] = whiteString
				eb.Text:SetText(LeaPlusLC["AutoSellExcludeList"])

			end

			-- Save the excluded list when it changes and at startup
			eb.Text:SetScript("OnTextChanged", UpdateWhiteList)
			eb.Text:SetText(LeaPlusLC["AutoSellExcludeList"])
			UpdateWhiteList()

			-- Create whitelist on startup and option, reset or preset is clicked
			UpdateWhiteList()
			SellJunkFrame.r:HookScript("OnClick", UpdateWhiteList)
			LeaPlusCB["AutoSellJunkBtn"]:HookScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile (just the whitelist part)
					UpdateWhiteList()
				end
			end)

			-- Editbox tooltip
			local tipPrefix = ""

			-- Function to make tooltip string
			local function MakeTooltipString()

				local keepMsg = ""
				local sellMsg = ""
				local dupMsg = ""
				local novalueMsg = ""
				local incompatMsg = ""

				local tipString = eb.Text:GetText()
				if tipString and tipString ~= "" then
					tipString = tipString:gsub("[^,%d]", "")
					local tipList = {strsplit(",", tipString)}
					for i = 1, #tipList do
						if tipList[i] then
							tipList[i] = tonumber(tipList[i])
							if tipList[i] and tipList[i] > 0 and tipList[i] < 999999999 then
								local void, tLink, Rarity, void, void, void, void, void, void, void, ItemPrice = C_Item.GetItemInfo(tipList[i])
								if tLink and tLink ~= "" then
									local linkCol = string.sub(tLink, 1, 7)
									if linkCol then
										local linkName = tLink:match("%[(.-)%]")
										if linkName and ItemPrice then
											if ItemPrice > 0 then
												if Rarity == 0 then
													-- Junk item
													if string.find(keepMsg, "%(" .. tipList[i] .. "%)") then
														-- Duplicate (ID appears more than once in list)
														dupMsg = dupMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
													else
														-- Add junk item to keep list
														keepMsg = keepMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
													end
												elseif Rarity == 1 then
													-- White item
													if string.find(sellMsg, "%(" .. tipList[i] .. "%)") then
														-- Duplicate (ID appears more than once in list)
														dupMsg = dupMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
													else
														-- Add non-junk item to sell list
														sellMsg = sellMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
													end
												else
													-- Incompatible item (not junk or white)
													if string.find(incompatMsg, "%(" .. tipList[i] .. "%)") then
														-- Duplicate (ID appears more than once in list)
														dupMsg = dupMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
													else
														-- Add item to incompatible list
														incompatMsg = incompatMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
													end
												end
											else
												-- Item has no sell price so cannot be sold
												if string.find(novalueMsg, "%(" .. tipList[i] .. "%)") then
													-- Duplicate (ID appears more than once in list)
													dupMsg = dupMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
												else
													-- Add item to cannot be sold list
													novalueMsg = novalueMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
												end
											end
										end
									end
								end
							end
						end
					end
				end

				if keepMsg ~= "" then keepMsg = "|n" .. L["Keep"] .. "|n" .. keepMsg end
				if sellMsg ~= "" then sellMsg = "|n" .. L["Sell"] .. "|n" .. sellMsg end
				if dupMsg ~= "" then dupMsg = "|n" .. L["Duplicates"] .. "|n" .. dupMsg end
				if novalueMsg ~= "" then novalueMsg = "|n" .. L["Cannot be sold"] .. "|n" .. novalueMsg end
				if incompatMsg ~= "" then incompatMsg = "|n" .. L["Incompatible"] .. "|n" .. incompatMsg end

				eb.tiptext = L["Exclusions"] .. "|n" .. keepMsg .. sellMsg .. dupMsg .. novalueMsg .. incompatMsg
				eb.Text.tiptext = L["Exclusions"] .. "|n" .. keepMsg .. sellMsg .. dupMsg .. novalueMsg .. incompatMsg
				if eb.tiptext == L["Exclusions"] .. "|n" then eb.tiptext = eb.tiptext .. "|n" .. L["Nothing to see here."] end
				if eb.Text.tiptext == L["Exclusions"] .. "|n" then eb.Text.tiptext = "-" end

				if GameTooltip:IsShown() then
					if eb:IsMouseOver() or eb.Text:IsMouseOver() then
						GameTooltip:SetText(eb.tiptext, nil, nil, nil, nil, false)
					end
				end

			end

			eb.Text:HookScript("OnTextChanged", MakeTooltipString)
			eb.Text:HookScript("OnTextChanged", function()
				C_Timer.After(0.1, function()
					MakeTooltipString()
				end)
			end)

			-- Show the button tooltip for the editbox
			eb:SetScript("OnEnter", MakeTooltipString)
			eb:HookScript("OnEnter", LeaPlusLC.TipSee)
			eb:HookScript("OnEnter", function() GameTooltip:SetText(eb.tiptext, nil, nil, nil, nil, false) end)
			eb:SetScript("OnLeave", GameTooltip_Hide)
			eb.Text:SetScript("OnEnter", MakeTooltipString)
			eb.Text:HookScript("OnEnter", LeaPlusLC.ShowDropTip)
			eb.Text:HookScript("OnEnter", function() GameTooltip:SetText(eb.tiptext, nil, nil, nil, nil, false) end)
			eb.Text:SetScript("OnLeave", GameTooltip_Hide)

			-- Show item ID in item tooltips while configuration panel is showing
			TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(self)
				if self ~= GameTooltip then return end
				if SellJunkFrame:IsShown() then
					local void, itemLink = self:GetItem()
					if itemLink then
						local itemID = GetItemInfoFromHyperlink(itemLink)
						if itemID then self:AddLine(L["Item ID"] .. ": " .. itemID) end
					end
				end
			end)

			-- Vendor function
			local function SellJunkFunc()

				-- Variables
				local SoldCount, Rarity, ItemPrice = 0, 0, 0
				local CurrentItemLink, classID, void
				local itemTypeWeapon = Enum.ItemClass.Weapon
				local itemTypeArmor = Enum.ItemClass.Armor

				-- Traverse bags and sell grey items
				for BagID = 0, 5 do
					for BagSlot = 1, C_Container.GetContainerNumSlots(BagID) do
						CurrentItemLink = C_Container.GetContainerItemLink(BagID, BagSlot)
						if CurrentItemLink then
							void, void, Rarity, void, void, void, void, void, void, void, ItemPrice, classID = C_Item.GetItemInfo(CurrentItemLink)
							-- Don't sell whitelisted items
							local itemID = GetItemInfoFromHyperlink(CurrentItemLink)
							if itemID and whiteList[itemID] then
								if Rarity == 0 then
									-- Junk item to keep
									Rarity = 20
									ItemPrice = 0
								elseif Rarity == 1 then
									-- White item to sell
									Rarity = 0
								end
							end
							-- Exclude grey gear
							if Rarity == 0 and classID and (classID == itemTypeWeapon or classID == itemTypeArmor) then -- Weapon or armor
								local isSoulBound = C_Item.IsBound(ItemLocation:CreateFromBagAndSlot(BagID, BagSlot))
								-- local isWarboundUntilEquipped = C_Item.IsBoundToAccountUntilEquip(ItemLocation:CreateFromBagAndSlot(BagID, BagSlot))
								if not isSoulBound then
									-- Item is not soulbound (soulbound gear cannot be sold to others)
									if LeaPlusLC["AutoSellNoGreyGear"] == "On" then
										-- Exclude all grey gear is checked so do not sell
										Rarity = 20
										ItemPrice = 0
									end
								end
							end
							-- Continue
							local cInfo = C_Container.GetContainerItemInfo(BagID, BagSlot)
							local itemCount = cInfo.stackCount
							if Rarity == 0 and ItemPrice ~= 0 then
								SoldCount = SoldCount + 1
								if MerchantFrame:IsShown() then
									-- If merchant frame is open, vendor the item
									C_Container.UseContainerItem(BagID, BagSlot)
									-- Perform actions on first iteration
									if SellJunkTicker._remainingIterations == IterationCount then
										-- Calculate total price
										totalPrice = totalPrice + (ItemPrice * itemCount)
									end
								else
									-- If merchant frame is not open, stop selling
									StopSelling()
									return
								end
							end
						end
					end
				end

				-- Stop selling if no items were sold for this iteration or iteration limit was reached
				if SoldCount == 0 or SellJunkTicker and SellJunkTicker._remainingIterations == 1 then
					StopSelling()
					if totalPrice > 0 and LeaPlusLC["AutoSellShowSummary"] == "On" then
						LeaPlusLC:Print(L["Sold junk for"] .. " " .. C_CurrencyInfo.GetCoinText(totalPrice) .. ".")
					end
				end

			end

			-- Event handler
			SellJunkFrame:RegisterEvent("MERCHANT_SHOW")
			SellJunkFrame:RegisterEvent("MERCHANT_CLOSED")
			SellJunkFrame:SetScript("OnEvent", function(self, event, arg1, arg2)
				if event == "MERCHANT_SHOW" then
					-- Check for vendors that refuse to buy items
					SellJunkFrame:RegisterEvent("UI_ERROR_MESSAGE")
					-- Reset variable
					totalPrice = 0
					-- Do nothing if shift key is held down
					if IsShiftKeyDown() then return end
					-- Cancel existing ticker if present
					if SellJunkTicker then SellJunkTicker._cancelled = true; end
					-- Sell grey items using ticker (ends when all grey items are sold or iteration count reached)
					SellJunkTicker = LeaPlusNewTicker(0.2, SellJunkFunc, IterationCount)
					SellJunkFrame:RegisterEvent("ITEM_LOCKED")
				elseif event == "ITEM_LOCKED" then
					StartMsg:Show()
					SellJunkFrame:UnregisterEvent("ITEM_LOCKED")
				elseif event == "MERCHANT_CLOSED" then
					-- If merchant frame is closed, stop selling
					StopSelling()
				elseif event == "UI_ERROR_MESSAGE" then
					if arg2 and (arg2 == ERR_VENDOR_DOESNT_BUY or arg2 == ERR_TOO_MUCH_GOLD) then
						-- Vendor refuses to buy items or player at gold limit
						StopSelling()
					end
				end
			end)

		end

		----------------------------------------------------------------------
		--	Repair automatically (no reload required)
		----------------------------------------------------------------------

		do

			-- Repair when suitable merchant frame is shown
			local function RepairFunc()
				if IsShiftKeyDown() then return end
				if CanMerchantRepair() then -- If merchant is capable of repair
					-- Process repair
					local RepairCost, CanRepair = GetRepairAllCost()
					if CanRepair then -- If merchant is offering repair
						if LeaPlusLC["AutoRepairGuildFunds"] == "On" and IsInGuild() then
							-- Guilded character and guild repair option is enabled
							if CanGuildBankRepair() then
								-- Character has permission to repair so try guild funds but fallback on character funds (if daily gold limit is reached)
								RepairAllItems(1)
								RepairAllItems()
							else
								-- Character does not have permission to repair so use character funds
								RepairAllItems()
							end
						else
							-- Unguilded character or guild repair option is disabled
							RepairAllItems()
						end
						-- Show cost summary
						if LeaPlusLC["AutoRepairShowSummary"] == "On" then
							LeaPlusLC:Print(L["Repaired for"] .. " " .. C_CurrencyInfo.GetCoinText(RepairCost) .. ".")
						end
					end
				end
			end

			-- Create event frame
			local RepairFrame = CreateFrame("FRAME")

			-- Function to setup event
			local function SetupEvent()
				if LeaPlusLC["AutoRepairGear"] == "On" then
					RepairFrame:RegisterEvent("MERCHANT_SHOW")
				else
					RepairFrame:UnregisterEvent("MERCHANT_SHOW")
				end
			end

			-- Setup event when option is clicked and on startup (if option is enabled)
			LeaPlusCB["AutoRepairGear"]:HookScript("OnClick", SetupEvent)
			if LeaPlusLC["AutoRepairGear"] == "On" then SetupEvent() end

			-- Event handler
			RepairFrame:SetScript("OnEvent", RepairFunc)

			-- Create configuration panel
			local RepairPanel = LeaPlusLC:CreatePanel("Repair automatically", "RepairPanel")

			LeaPlusLC:MakeTx(RepairPanel, "Settings", 16, -72)
			LeaPlusLC:MakeCB(RepairPanel, "AutoRepairGuildFunds", "Repair using guild funds if available", 16, -92, false, "If checked, repair costs will be taken from guild funds for characters that are guilded and have permission to repair.")
			LeaPlusLC:MakeCB(RepairPanel, "AutoRepairShowSummary", "Show repair summary in chat", 16, -112, false, "If checked, a repair summary will be shown in chat when your gear is automatically repaired.")

			-- Help button hidden
			RepairPanel.h:Hide()

			-- Back button handler
			RepairPanel.b:SetScript("OnClick", function()
				RepairPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page1"]:Show();
				return
			end)

			-- Reset button handler
			RepairPanel.r:SetScript("OnClick", function()

				-- Reset checkboxes
				LeaPlusLC["AutoRepairGuildFunds"] = "On"
				LeaPlusLC["AutoRepairShowSummary"] = "On"

				-- Refresh panel
				RepairPanel:Hide(); RepairPanel:Show()

			end)

			-- Show panal when options panel button is clicked
			LeaPlusCB["AutoRepairBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["AutoRepairGuildFunds"] = "On"
					LeaPlusLC["AutoRepairShowSummary"] = "On"
				else
					RepairPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		-- Hide the combat log
		----------------------------------------------------------------------

		if LeaPlusLC["NoCombatLogTab"] == "On" and not LeaLockList["NoCombatLogTab"] then

			-- Function to setup the combat log tab
			local function SetupCombatLogTab()
				ChatFrame2Tab:EnableMouse(false)
				ChatFrame2Tab:SetText(" ") -- Needs to be something for chat settings to function
				ChatFrame2Tab:SetScale(0.01)
				ChatFrame2Tab:SetWidth(0.01)
				ChatFrame2Tab:SetHeight(0.01)
			end

			local frame = CreateFrame("FRAME")
			frame:SetScript("OnEvent", SetupCombatLogTab)

			-- Ensure combat log is docked
			if ChatFrame2.isDocked then
				-- Set combat log attributes when chat windows are updated
				frame:RegisterEvent("UPDATE_CHAT_WINDOWS")
				-- Set combat log tab placement when tabs are assigned by the client
				hooksecurefunc("FCF_SetTabPosition", function()
					ChatFrame2Tab:SetPoint("BOTTOMLEFT", ChatFrame1Tab, "BOTTOMRIGHT", 0, 0)
				end)
				SetupCombatLogTab()
			else
				-- If combat log is undocked, do nothing but show warning
				C_Timer.After(1, function()
					LeaPlusLC:Print("Combat log cannot be hidden while undocked.")
				end)
			end

		end

		----------------------------------------------------------------------
		--	Show player chain
		----------------------------------------------------------------------

		if LeaPlusLC["ShowPlayerChain"] == "On" and not LeaLockList["ShowPlayerChain"] then

			-- Ensure chain doesnt clip through pet portrait and rune frame
			PetPortrait:GetParent():SetFrameLevel(4)

			local container = PlayerFrame.PlayerFrameContainer
			local portrait = container.PlayerPortrait

			----------------------------------------------------------------------
			-- Modern chains
			----------------------------------------------------------------------

			local modernChain = container:CreateTexture(nil, "OVERLAY")
			modernChain:SetTexCoord(1, 0, 0, 1) -- Flip horizontally (target frame art faces the other way)

			-- Atlas, x offset, y offset
			local modernStyles = {
				[1] = {"UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold", 0, -3}, -- Elite
				[2] = {"UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold-Winged", -11, -8}, -- Boss
				[3] = {"UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Silver", 0, -3}, -- Rare
			}

			----------------------------------------------------------------------
			-- Classic chains and round rest glow
			----------------------------------------------------------------------

			-- Classic textures are for a 64x64 portrait so they are scaled to the 60x60 player portrait
			local classicScale = 60 / 64

			local classicChain = container:CreateTexture(nil, "OVERLAY")
			classicChain:SetSize(113 * classicScale, 99 * classicScale)
			classicChain:SetPoint("TOPLEFT", portrait, "CENTER", -73 * classicScale, 44 * classicScale)

			-- Texture, left, right, top, bottom
			local classicStyles = {
				[4] = {"Interface\\TargetingFrame\\UI-TargetingFrame-Rare.blp", 1, 0.5567, 0, 0.78125}, -- Rare
				[5] = {"Interface\\TargetingFrame\\UI-TargetingFrame-Elite.blp", 1, 0.5567, 0, 0.78125}, -- Elite
				[6] = {"Interface\\AddOns\\Leatrix_Plus\\Leatrix_Plus.blp", 0, 0.4414, 0.125, 0.5156}, -- Rare elite (dragon)
			}

			-- Round rest glow (portrait part of the classic status texture, slightly smaller to hug the portrait)
			local glowScale = classicScale * 0.95
			local roundGlow = container:CreateTexture(nil, "OVERLAY", nil, -1)
			roundGlow:SetTexture("Interface\\CharacterFrame\\UI-Player-Status")
			roundGlow:SetTexCoord(0, 78 / 256, 0, 68 / 128)
			roundGlow:SetSize(78 * glowScale, 68 * glowScale)
			roundGlow:SetPoint("CENTER", portrait, "CENTER", 0, 1)
			roundGlow:SetBlendMode("ADD")
			roundGlow:Hide()

			-- Modern glow: the round glow replaces its left (portrait) part, its right part still covers the bars
			local statusTexture = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.StatusTexture
			local statusAtlas = "UI-HUD-UnitFrame-Player-PortraitOn-Status"
			local glowCrop = 70 -- Pixels removed from the left of the modern glow

			local function UseClassicGlow()
				return classicStyles[LeaPlusLC["PlayerChainMenu"]] and PlayerFrame.state == "player"
			end

			-- Crop the modern glow for classic chains, or restore it (texture coordinates are relative to the atlas)
			local function UpdateModernGlow()
				if PlayerFrame.state ~= "player" then
					statusTexture:SetTexCoord(0, 1, 0, 1) -- Vehicle art uses its own glow, remove any crop
					return
				end
				local info = C_Texture.GetAtlasInfo(statusAtlas)
				if not info then return end
				local crop = UseClassicGlow() and glowCrop or 0
				statusTexture:SetTexCoord(crop / info.width, 1, 0, 1)
				statusTexture:SetSize(info.width - crop, info.height)
				statusTexture:ClearAllPoints()
				statusTexture:SetPoint("TOPLEFT", container, "TOPLEFT", 18 + crop, -14)
			end

			-- Copy the modern glow's pulse to the round glow (only runs while the round glow is shown)
			local glowSync = CreateFrame("Frame")
			glowSync:Hide()
			glowSync:SetScript("OnUpdate", function()
				local alpha = statusTexture:GetAlpha()
				if not (issecretvalue and issecretvalue(alpha)) then roundGlow:SetAlpha(alpha) end
			end)

			-- Show the round glow with the same color as the modern glow
			local function UpdateRoundGlow()
				local r, g, b = statusTexture:GetVertexColor()
				if not (issecretvalue and issecretvalue(r)) then roundGlow:SetVertexColor(r, g, b) end
				local shown = statusTexture:IsShown()
				if issecretvalue and issecretvalue(shown) then shown = false end
				roundGlow:SetShown(UseClassicGlow() and shown)
				glowSync:SetShown(roundGlow:IsShown())
			end

			-- Used by class colored frames (chain and rest glow in class color)
			LeaPlusLC.PlayerChainTextures = {modernChain, classicChain}
			LeaPlusLC.PlayerRoundGlow = roundGlow
			LeaPlusLC.UpdateRoundGlow = UpdateRoundGlow

			-- Keep in sync with Blizzard's updates
			hooksecurefunc("PlayerFrame_UpdateStatus", UpdateRoundGlow) -- Resting/combat color and visibility
			hooksecurefunc("PlayerFrame_ToPlayerArt", UpdateModernGlow) -- Blizzard resets the glow anchor here
			hooksecurefunc("PlayerFrame_ToVehicleArt", UpdateModernGlow)

			----------------------------------------------------------------------
			-- Set chain style
			----------------------------------------------------------------------

			local function SetChainStyle()
				local chain = LeaPlusLC["PlayerChainMenu"]
				local modern, classic = modernStyles[chain], classicStyles[chain]
				modernChain:SetShown(modern ~= nil)
				classicChain:SetShown(classic ~= nil)
				if modern then
					modernChain:SetAtlas(modern[1], true)
					modernChain:ClearAllPoints()
					modernChain:SetPoint("TOPLEFT", modern[2], modern[3])
				elseif classic then
					classicChain:SetTexture(classic[1])
					classicChain:SetTexCoord(classic[2], classic[3], classic[4], classic[5])
				end
				UpdateModernGlow()
				UpdateRoundGlow()
				if LeaPlusLC.UpdateChainColor then LeaPlusLC.UpdateChainColor() end -- Class colored frames
			end

			----------------------------------------------------------------------
			-- Configuration panel
			----------------------------------------------------------------------

			local ChainPanel = LeaPlusLC:CreatePanel("Show player chain", "ChainPanel")

			LeaPlusLC:CreateDropdown("PlayerChainMenu", "Chain style", 180, "TOPLEFT", ChainPanel, "TOPLEFT", 16, -92, false, {{L["MODERN ELITE"], 1}, {L["MODERN BOSS"], 2}, {L["MODERN RARE"], 3}, {L["CLASSIC RARE"], 4}, {L["CLASSIC ELITE"], 5}, {L["CLASSIC RARE ELITE"], 6}})

			-- Set style when dropdown menu is updated and on startup
			LeaPlusCB["PlayerChainMenu"]:RegisterCallback("OnMenuClose", SetChainStyle)
			SetChainStyle()

			-- Help button hidden
			ChainPanel.h:Hide()

			-- Back button handler
			ChainPanel.b:SetScript("OnClick", function()
				ChainPanel:Hide()
				LeaPlusLC["PageF"]:Show()
				LeaPlusLC["Page5"]:Show()
			end)

			-- Reset button handler
			ChainPanel.r:SetScript("OnClick", function()
				LeaPlusLC["PlayerChainMenu"] = 1
				ChainPanel:Hide(); ChainPanel:Show()
				SetChainStyle()
			end)

			-- Show the panel when the configuration button is clicked
			LeaPlusCB["ModPlayerChain"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					LeaPlusLC["PlayerChainMenu"] = 1
					SetChainStyle()
				else
					LeaPlusLC:HideFrames()
					ChainPanel:Show()
				end
			end)

		end

		----------------------------------------------------------------------
		-- Show raid frame toggle button
		----------------------------------------------------------------------

		if LeaPlusLC["ShowRaidToggle"] == "On" and not LeaLockList["ShowRaidToggle"] then

			-- Check to make sure raid toggle button exists
			if CompactRaidFrameManagerDisplayFrameHiddenModeToggle then

				-- Move the button (function runs after PLAYER_ENTERING_WORLD and PARTY_LEADER_CHANGED)
				hooksecurefunc("CompactRaidFrameManager_UpdateOptionsFlowContainer", function()
					if CompactRaidFrameManager and CompactRaidFrameManagerDisplayFrameHiddenModeToggle then
						local void, void, void, void, y = CompactRaidFrameManager:GetPoint()
						CompactRaidFrameManagerDisplayFrameHiddenModeToggle:SetWidth(40)
						CompactRaidFrameManagerDisplayFrameHiddenModeToggle:ClearAllPoints()
						CompactRaidFrameManagerDisplayFrameHiddenModeToggle:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, y + 32)
						CompactRaidFrameManagerDisplayFrameHiddenModeToggle:SetParent(UIParent)
						CompactRaidFrameManagerDisplayFrameHiddenModeToggle:SetHitRectInsets(0, 0, 0, 0)
					end
				end)

			end

		end

		----------------------------------------------------------------------
		-- Hide portrait numbers
		----------------------------------------------------------------------

		if LeaPlusLC["NoHitIndicators"] == "On" and not LeaLockList["NoHitIndicators"] then
			PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HitIndicator:Hide()
			hooksecurefunc(PetHitIndicator, "Show", PetHitIndicator.Hide)
		end

		----------------------------------------------------------------------
		-- Class colored frames
		----------------------------------------------------------------------

		if LeaPlusLC["ClassColFrames"] == "On" and not LeaLockList["ClassColFrames"] then

			-- Create background frame for player frame
			local PlayFN = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain:CreateTexture(nil, "BACKGROUND")
			PlayFN:SetAtlas("UI-HUD-UnitFrame-Target-PortraitOn-Type", true)
			PlayFN:SetTexCoord(1, 0, 0, 1)
			PlayFN:ClearAllPoints()
			PlayFN:SetPoint("TOPLEFT", 75, -25)

			-- Make the name background end where the health bar ends, like the target frame (on Forever the fixed size above
			-- stops short of the end of the player name box). A frame of our own takes the left and top from the position above
			-- and the right from the health bar, and the name background takes its width from that frame.
			do
				local main = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain
				local healthBar = PlayerFrame.healthbar or (PlayerFrame_GetHealthBar and PlayerFrame_GetHealthBar()) or (main.HealthBarsContainer and main.HealthBarsContainer.HealthBar)
				if healthBar then
					local nameArea = CreateFrame("Frame", nil, PlayerFrame.PlayerFrameContent.PlayerFrameContentMain)
					nameArea:SetPoint("TOPLEFT", PlayerFrame.PlayerFrameContent.PlayerFrameContentMain, "TOPLEFT", 75, -25)
					nameArea:SetPoint("BOTTOMRIGHT", healthBar, "TOPRIGHT", 0, 0)
					-- The name background fills the name box down to the health bar, like the target frame (the frame border
					-- covers the bottom edge)
					PlayFN:ClearAllPoints()
					PlayFN:SetPoint("TOPLEFT", nameArea, "TOPLEFT", 0, 0)
					PlayFN:SetPoint("BOTTOMRIGHT", nameArea, "BOTTOMRIGHT", 0, 0)
					-- The art has an empty strip at one end (hidden under the frame edge on the target frame), which is on the
					-- right once the art is flipped for the player frame, and an empty part at the bottom, so both are cut off
					-- (the art is still flipped)
					PlayFN:SetTexCoord(1, 0.06, 0, 0.68)
				end
			end

			local c = LeaPlusLC["RaidColors"][select(2, UnitClass("player"))]
			if c then PlayFN:SetVertexColor(c.r, c.g, c.b) end

			-- Function to tint frame border (desaturate first so the gold does not mix with the class color)
			local function TintFrameBorder(tex, col)
				if not tex then return end
				if col then
					tex:SetDesaturated(true)
					tex:SetVertexColor(col.r, col.g, col.b)
				else
					tex:SetDesaturated(false)
					tex:SetVertexColor(1, 1, 1)
				end
			end

			-- Function to set player frame border color
			local function PlayerBorderCol()
				local col = LeaPlusLC["ClassColPlayerBorder"] == "On" and c or nil
				TintFrameBorder(PlayerFrame.PlayerFrameContainer.FrameTexture, col)
				TintFrameBorder(PlayerFrame.PlayerFrameContainer.AlternatePowerFrameTexture, col)
				TintFrameBorder(PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerPortraitCornerIcon, col)
			end

			-- Refresh player frame border color when player frame art is changed (such as leaving a vehicle)
			if PlayerFrame_ToPlayerArt then
				hooksecurefunc("PlayerFrame_ToPlayerArt", function()
					if LeaPlusLC["ClassColPlayerBorder"] == "On" then
						PlayerBorderCol()
					end
				end)
			end

			-- Function to set the round rest glow color (used by classic chains, it copies the color of the resting glow)
			local restTinted
			local function RoundGlowCol()
				local glow = LeaPlusLC.PlayerRoundGlow
				if not glow then return end
				if restTinted and c then
					glow:SetDesaturated(true)
					glow:SetVertexColor(c.r, c.g, c.b)
				else
					glow:SetDesaturated(false)
					if LeaPlusLC.UpdateRoundGlow then LeaPlusLC.UpdateRoundGlow() end -- Copy the resting or combat glow color again
				end
			end

			-- Function to set player frame resting glow color (resting glow only, combat glow stays red)
			local function RestGlowCol()
				local st = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.StatusTexture
				if not st then return end
				if LeaPlusLC["ClassColPlayerBorder"] == "On" and c then
					local r, g, b = st:GetVertexColor()
					if issecretvalue and issecretvalue(g) then return end
					if restTinted or g > 0.5 then
						-- Resting glow (Blizzard gold or already tinted)
						st:SetDesaturated(true)
						st:SetVertexColor(c.r, c.g, c.b)
						restTinted = true
					end
				elseif restTinted then
					-- Option turned off so restore Blizzard resting glow
					st:SetDesaturated(false)
					st:SetVertexColor(1.0, 0.88, 0.25, 1.0)
					restTinted = nil
				end
				RoundGlowCol()
			end

			-- Refresh resting glow color after Blizzard sets it
			if PlayerFrame_UpdateStatus then
				hooksecurefunc("PlayerFrame_UpdateStatus", function()
					if LeaPlusLC["ClassColPlayerBorder"] == "On" and c then
						local st = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.StatusTexture
						if not st then return end
						local r, g, b = st:GetVertexColor()
						if issecretvalue and issecretvalue(g) then return end
						if g > 0.5 then
							-- Blizzard set resting glow
							st:SetDesaturated(true)
							st:SetVertexColor(c.r, c.g, c.b)
							restTinted = true
						else
							-- Blizzard set combat glow
							st:SetDesaturated(false)
							restTinted = nil
						end
						RoundGlowCol()
					end
				end)
			end

			-- Function to set player chain color (Forever has modern and classic chains, given by show player chain if enabled)
			local function ChainCol()
				local chains = LeaPlusLC.PlayerChainTextures
				if not chains then return end
				for i, chainTex in ipairs(chains) do
					if LeaPlusLC["ClassColChain"] == "On" and c then
						chainTex:SetDesaturated(true)
						chainTex:SetVertexColor(c.r, c.g, c.b)
					else
						chainTex:SetDesaturated(false)
						chainTex:SetVertexColor(1, 1, 1, 1)
					end
				end
			end

			-- Refresh player chain color when the chain style is changed
			LeaPlusLC.UpdateChainColor = ChainCol

			-- Create color function for target and focus frames
			local function TargetFrameCol()
				local targetCol, focusCol
				if UnitIsPlayer("target") then
					local void, target = UnitClass("target")
					if canaccessvalue(target) then
						targetCol = LeaPlusLC["RaidColors"][target]
					end
				end
				if UnitIsPlayer("focus") then
					local void, focus = UnitClass("focus")
					if canaccessvalue(focus) then
						focusCol = LeaPlusLC["RaidColors"][focus]
					end
				end
				-- Name backgrounds
				if LeaPlusLC["ClassColTarget"] == "On" then
					if targetCol then TargetFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor:SetVertexColor(targetCol.r, targetCol.g, targetCol.b) end
					if focusCol then FocusFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor:SetVertexColor(focusCol.r, focusCol.g, focusCol.b) end
				end
				-- Frame borders
				local borderOn = LeaPlusLC["ClassColTargetBorder"] == "On"
				TintFrameBorder(TargetFrame.TargetFrameContainer.FrameTexture, borderOn and targetCol or nil)
				TintFrameBorder(FocusFrame.TargetFrameContainer.FrameTexture, borderOn and focusCol or nil)
			end

			local ColTar = CreateFrame("FRAME")
			ColTar:SetScript("OnEvent", TargetFrameCol) -- Events are registered if target option is enabled

			-- Refresh color if focus frame size changes
			if FocusFrame_SetSmallSize then
				hooksecurefunc(FocusFrame, "SetSmallSize", function()
					if LeaPlusLC["ClassColTarget"] == "On" or LeaPlusLC["ClassColTargetBorder"] == "On" then
						TargetFrameCol()
					end
				end)
			end

			-- Create configuration panel
			local ClassFrame = LeaPlusLC:CreatePanel("Class colored frames", "ClassFrame")

			LeaPlusLC:MakeTx(ClassFrame, "Player frame", 16, -72)
			LeaPlusLC:MakeCB(ClassFrame, "ClassColPlayer", "Show player name background in class color", 16, -92, false, "If checked, the background behind the player name will be shown in class color.")
			LeaPlusLC:MakeCB(ClassFrame, "ClassColPlayerBorder", "Show player frame border in class color", 16, -112, false, "If checked, the player frame border including the ring around the portrait will be shown in class color.")
			LeaPlusLC:MakeCB(ClassFrame, "ClassColChain", "Show player chain in class color", 16, -132, false, "If checked, the player chain will be shown in class color.|n|nThis requires the show player chain option to be enabled.")

			LeaPlusLC:MakeTx(ClassFrame, "Target and focus frames", 16, -172)
			LeaPlusLC:MakeCB(ClassFrame, "ClassColTarget", "Show target and focus name background in class color", 16, -192, false, "If checked, the background behind the target name and focus name will be shown in class color.")
			LeaPlusLC:MakeCB(ClassFrame, "ClassColTargetBorder", "Show target and focus frame border in class color", 16, -212, false, "If checked, the target frame border and focus frame border including the ring around the portrait will be shown in class color.")

			-- Help button hidden
			ClassFrame.h:Hide()

			-- Back button handler
			ClassFrame.b:SetScript("OnClick", function()
				ClassFrame:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page6"]:Show()
				return
			end)

			-- Function to set class colored frames
			local function SetClassColFrames()
				-- Player frame
				if LeaPlusLC["ClassColPlayer"] == "On" then
					PlayFN:Show()
				else
					PlayFN:Hide()
				end
				PlayerBorderCol()
				RestGlowCol()
				ChainCol()
				-- Target and focus frames
				if LeaPlusLC["ClassColTarget"] ~= "On" then
					TargetFrame.CheckFaction(TargetFrame) -- Reset target frame colors
					TargetFrame.CheckFaction(FocusFrame) -- Reset focus frame colors
				end
				if LeaPlusLC["ClassColTarget"] == "On" or LeaPlusLC["ClassColTargetBorder"] == "On" then
					ColTar:RegisterEvent("GROUP_ROSTER_UPDATE")
					ColTar:RegisterEvent("PLAYER_TARGET_CHANGED")
					ColTar:RegisterEvent("PLAYER_FOCUS_CHANGED")
					ColTar:RegisterEvent("UNIT_FACTION")
					TargetFrameCol()
				else
					ColTar:UnregisterAllEvents()
					TintFrameBorder(TargetFrame.TargetFrameContainer.FrameTexture, nil) -- Reset target frame border
					TintFrameBorder(FocusFrame.TargetFrameContainer.FrameTexture, nil) -- Reset focus frame border
				end
			end

			-- Run function when options are clicked and on startup
			LeaPlusCB["ClassColPlayer"]:HookScript("OnClick", SetClassColFrames)
			LeaPlusCB["ClassColTarget"]:HookScript("OnClick", SetClassColFrames)
			LeaPlusCB["ClassColPlayerBorder"]:HookScript("OnClick", SetClassColFrames)
			LeaPlusCB["ClassColTargetBorder"]:HookScript("OnClick", SetClassColFrames)
			LeaPlusCB["ClassColChain"]:HookScript("OnClick", SetClassColFrames)
			SetClassColFrames()

			-- Reset button handler
			ClassFrame.r:SetScript("OnClick", function()

				-- Reset checkboxes
				LeaPlusLC["ClassColPlayer"] = "On"
				LeaPlusLC["ClassColTarget"] = "On"
				LeaPlusLC["ClassColPlayerBorder"] = "Off"
				LeaPlusLC["ClassColTargetBorder"] = "Off"
				LeaPlusLC["ClassColChain"] = "Off"

				-- Update colors and refresh configuration panel
				SetClassColFrames()
				ClassFrame:Hide(); ClassFrame:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			LeaPlusCB["ClassColFramesBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["ClassColPlayer"] = "On"
					LeaPlusLC["ClassColTarget"] = "On"
					LeaPlusLC["ClassColPlayerBorder"] = "Off"
					LeaPlusLC["ClassColTargetBorder"] = "Off"
					LeaPlusLC["ClassColChain"] = "Off"
					SetClassColFrames()
				else
					ClassFrame:Show()
					LeaPlusLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		--	Quest text size
		----------------------------------------------------------------------

		if LeaPlusLC["QuestFontChange"] == "On" then

			-- Create configuration panel
			local QuestTextPanel = LeaPlusLC:CreatePanel("Resize quest text", "QuestTextPanel")

			LeaPlusLC:MakeTx(QuestTextPanel, "Text size", 16, -72)
			LeaPlusLC:MakeSL(QuestTextPanel, "LeaPlusQuestFontSize", "Drag to set the font size of quest text.", 10, 30, 1, 16, -92, "%.0f")

			-- Function to update the font size
			local function QuestSizeUpdate()
				local a, b, c = QuestFont:GetFont()
				QuestTitleFont:SetFont(a, LeaPlusLC["LeaPlusQuestFontSize"] + 3, c)
				QuestFont:SetFont(a, LeaPlusLC["LeaPlusQuestFontSize"] + 1, c)
				local d, e, f = QuestFontNormalSmall:GetFont()
				QuestFontNormalSmall:SetFont(d, LeaPlusLC["LeaPlusQuestFontSize"], f)
			end

			-- Set text size when slider changes and on startup
			LeaPlusCB["LeaPlusQuestFontSize"]:HookScript("OnValueChanged", QuestSizeUpdate)
			QuestSizeUpdate()

			-- Help button hidden
			QuestTextPanel.h:Hide()

			-- Back button handler
			QuestTextPanel.b:SetScript("OnClick", function()
				QuestTextPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page4"]:Show()
				return
			end)

			-- Reset button handler
			QuestTextPanel.r:SetScript("OnClick", function()

				-- Reset slider
				LeaPlusLC["LeaPlusQuestFontSize"] = 12
				QuestSizeUpdate()

				-- Refresh side panel
				QuestTextPanel:Hide(); QuestTextPanel:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			LeaPlusCB["QuestTextBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["LeaPlusQuestFontSize"] = 18
					QuestSizeUpdate()
				else
					QuestTextPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		--	Show durability status
		----------------------------------------------------------------------

		if LeaPlusLC["DurabilityStatus"] == "On" then

			-- Create durability button
			local cButton = CreateFrame("BUTTON", nil, PaperDollFrame)
			cButton:ClearAllPoints()
			cButton:SetPoint("BOTTOMRIGHT", CharacterFrameLeftPaneHost, "BOTTOMRIGHT", -6, 6)
			cButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
			cButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
			cButton:SetSize(28, 28)
			cButton:SetFrameLevel(100)

			-- Create durability tables
			local Slots = {"HeadSlot", "ShoulderSlot", "ChestSlot", "WristSlot", "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "MainHandSlot", "SecondaryHandSlot"}
			local SlotsFriendly = {INVTYPE_HEAD, INVTYPE_SHOULDER, INVTYPE_CHEST, INVTYPE_WRIST, INVTYPE_HAND, INVTYPE_WAIST, INVTYPE_LEGS, INVTYPE_FEET, INVTYPE_WEAPONMAINHAND, INVTYPE_WEAPONOFFHAND}

			-- Show durability status in tooltip or status line (tip or status)
			local function ShowDuraStats(where)

				local duravaltotal, duramaxtotal, durapercent = 0, 0, 0
				local valcol, id, duraval, duramax

				if where == "tip" then
					-- Creare layout
					GameTooltip:AddLine("|cffffffff")
					GameTooltip:AddLine("|cffffffff")
					GameTooltip:AddLine("|cffffffff")
					_G["GameTooltipTextLeft1"]:SetText("|cffffffff"); _G["GameTooltipTextRight1"]:SetText("|cffffffff")
					_G["GameTooltipTextLeft2"]:SetText("|cffffffff"); _G["GameTooltipTextRight2"]:SetText("|cffffffff")
					_G["GameTooltipTextLeft3"]:SetText("|cffffffff"); _G["GameTooltipTextRight3"]:SetText("|cffffffff")
				end

				local validItems = false

				-- Traverse equipment slots
				for k, slotName in ipairs(Slots) do
					if C_PaperDollInfo.GetInventorySlotInfo(slotName) then
						id = C_PaperDollInfo.GetInventorySlotInfo(slotName)
						duraval, duramax = GetInventoryItemDurability(id)
						if duraval ~= nil then

							-- At least one item has durability stat
							validItems = true

							-- Add to tooltip
							if where == "tip" then
								durapercent = tonumber(format("%.0f", duraval / duramax * 100))
								valcol = (durapercent >= 80 and "|cff00FF00") or (durapercent >= 60 and "|cff99FF00") or (durapercent >= 40 and "|cffFFFF00") or (durapercent >= 20 and "|cffFF9900") or (durapercent >= 0 and "|cffFF2000") or ("|cffFFFFFF")
								_G["GameTooltipTextLeft1"]:SetText(L["Durability"])
								_G["GameTooltipTextLeft2"]:SetText(_G["GameTooltipTextLeft2"]:GetText() .. SlotsFriendly[k] .. "|n")
								_G["GameTooltipTextRight2"]:SetText(_G["GameTooltipTextRight2"]:GetText() ..  valcol .. durapercent .. "%" .. "|r|n")
							end

							duravaltotal = duravaltotal + duraval
							duramaxtotal = duramaxtotal + duramax
						end
					end
				end
				if duravaltotal > 0 and duramaxtotal > 0 then
					durapercent = duravaltotal / duramaxtotal * 100
				else
					durapercent = 0
				end

				if where == "tip" then

					if validItems == true then
						-- Show overall durability in the tooltip
						if durapercent >= 80 then valcol = "|cff00FF00"	elseif durapercent >= 60 then valcol = "|cff99FF00"	elseif durapercent >= 40 then valcol = "|cffFFFF00"	elseif durapercent >= 20 then valcol = "|cffFF9900"	elseif durapercent >= 0 then valcol = "|cffFF2000" else return end
						_G["GameTooltipTextLeft3"]:SetText(L["Overall"] .. " " .. valcol)
						_G["GameTooltipTextRight3"]:SetText(valcol .. string.format("%.0f", durapercent) .. "%")

						-- Show lines of the tooltip
						GameTooltipTextLeft1:Show(); GameTooltipTextRight1:Show()
						GameTooltipTextLeft2:Show(); GameTooltipTextRight2:Show()
						GameTooltipTextLeft3:Show(); GameTooltipTextRight3:Show()
						GameTooltipTextRight2:SetJustifyH"RIGHT";
						GameTooltipTextRight3:SetJustifyH"RIGHT";
						GameTooltip:Show()
					else
						-- No items have durability stat
						GameTooltip:ClearLines()
						GameTooltip:AddLine("" .. L["Durability"],1.0, 0.85, 0.0)
						GameTooltip:AddLine("" .. L["No items with durability equipped."], 1, 1, 1)
						GameTooltip:Show()
					end

				elseif where == "status" then
					if validItems == true then
						-- Show simple status line instead
						if tonumber(durapercent) >= 0 then -- Ensure character has some durability items equipped
							LeaPlusLC:Print(L["You have"] .. " " .. string.format("%.0f", durapercent) .. "%" .. " " .. L["durability"] .. ".")
						end
					end

				end
			end

			-- Hover over the durability button to show the durability tooltip
			cButton:SetScript("OnEnter", function()
				GameTooltip:SetOwner(cButton, "ANCHOR_RIGHT")
				GameTooltip:SetMinimumWidth(0) -- Needed due to MoP mage reset specialisation and choose frost
				ShowDuraStats("tip")
			end)
			cButton:SetScript("OnLeave", GameTooltip_Hide)

			-- Create frame to watch events
			local DeathDura = CreateFrame("FRAME")
			DeathDura:RegisterEvent("PLAYER_DEAD")
			DeathDura:SetScript("OnEvent", function(self, event)
				ShowDuraStats("status")
				DeathDura:UnregisterEvent("PLAYER_DEAD")
				C_Timer.After(2, function()
					DeathDura:RegisterEvent("PLAYER_DEAD")
				end)
			end)

			hooksecurefunc("AcceptResurrect", function()
				-- Player has ressed without releasing
				ShowDuraStats("status")
			end)

		end

		----------------------------------------------------------------------
		--	Hide zone text
		----------------------------------------------------------------------

		if LeaPlusLC["HideZoneText"] == "On" then
			ZoneTextFrame:SetScript("OnShow", ZoneTextFrame.Hide);
			SubZoneTextFrame:SetScript("OnShow", SubZoneTextFrame.Hide);
		end

		----------------------------------------------------------------------
		--	Disable sticky chat
		----------------------------------------------------------------------

		if LeaPlusLC["NoStickyChat"] == "On" and not LeaLockList["NoStickyChat"] then
			-- These taint if set to anything other than nil
			ChatTypeInfo.WHISPER.sticky = nil
			ChatTypeInfo.BN_WHISPER.sticky = nil
			ChatTypeInfo.CHANNEL.sticky = nil
		end

		----------------------------------------------------------------------
		--	Hide stance bar
		----------------------------------------------------------------------

		if LeaPlusLC["NoClassBar"] == "On" and not LeaLockList["NoClassBar"] then
			local stancebar = CreateFrame("FRAME", nil, UIParent)
			stancebar:Hide()
			StanceBar:UnregisterAllEvents()
			StanceBar:SetParent(stancebar)
		end

		----------------------------------------------------------------------
		--	Disable chat fade
		----------------------------------------------------------------------

		if LeaPlusLC["NoChatFade"] == "On" and not LeaLockList["NoChatFade"] then
			-- Process normal and existing chat frames
			for i = 1, 50 do
				if _G["ChatFrame" .. i] then
					_G["ChatFrame" .. i]:SetFading(false)
				end
			end
			-- Process temporary frames
			hooksecurefunc("FCF_OpenTemporaryWindow", function()
				local cf = FCF_GetCurrentChatFrame():GetName() or nil
				if cf then
					_G[cf]:SetFading(false)
				end
			end)
		end

		----------------------------------------------------------------------
		-- Enhance flight map
		----------------------------------------------------------------------

		if LeaPlusLC["EnhanceFlightMap"] == "On" then

			-- Create flight map border
			local border = TaxiFrame:CreateTexture(nil, "BACKGROUND")
			border:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background-Dark")
			border:SetPoint("TOPLEFT", 18, -73)
			border:SetPoint("BOTTOMRIGHT", -45, 83)
			border:SetVertexColor(0, 0, 0, 1)

			-- Set flight map properties
			TaxiFrame:SetFrameStrata("FULLSCREEN_DIALOG")
			TaxiFrame:SetHitRectInsets(18, 45, 73, 83)
			TaxiFrame:SetClampedToScreen(true)
			TaxiFrame:SetClampRectInsets(200, -200, -300, 300)

			-- Position flight map when shown
			hooksecurefunc(TaxiFrame, "SetPoint", function(self, ...)
				local a, void, r, x, y = TaxiFrame:GetPoint()
				x = tonumber(string.format("%.2f", x))
				y = tonumber(string.format("%.2f", y))
				local xb = tonumber(string.format("%.2f", LeaPlusLC["FlightMapX"]))
				local yb = tonumber(string.format("%.2f", LeaPlusLC["FlightMapY"]))
				if a ~= LeaPlusLC["FlightMapA"] or r ~= LeaPlusLC["FlightMapR"] or x ~= xb or y ~= yb then
					TaxiFrame:ClearAllPoints()
					TaxiFrame:SetPoint(LeaPlusLC["FlightMapA"], UIParent, LeaPlusLC["FlightMapR"], LeaPlusLC["FlightMapX"], LeaPlusLC["FlightMapY"])
				end
			end)

			-- Set flight point buttons size
			TaxiFrame:HookScript("OnShow", function()
				for i = 1, NUM_TAXI_BUTTONS do
					local button = _G["TaxiButton"..i]
					if button and button:IsVisible() then
						_G["TaxiButton" .. i]:SetSize(LeaPlusLC["LeaPlusTaxiIconSize"], LeaPlusLC["LeaPlusTaxiIconSize"])
						if button:GetHighlightTexture() then button:GetHighlightTexture():SetSize(LeaPlusLC["LeaPlusTaxiIconSize"] * 2, LeaPlusLC["LeaPlusTaxiIconSize"] * 2) end
						if button:GetPushedTexture() then button:GetPushedTexture():SetSize(LeaPlusLC["LeaPlusTaxiIconSize"] * 2, LeaPlusLC["LeaPlusTaxiIconSize"] * 2) end
				   end
				end
			end)

			--UIPanelWindows["TaxiFrame"].width = 0

			-- Create configuration panel
			local TaxiPanel = LeaPlusLC:CreatePanel("Enhance flight map", "TaxiPanel")

			LeaPlusLC:MakeTx(TaxiPanel, "Map scale", 356, -72)
			LeaPlusLC:MakeSL(TaxiPanel, "LeaPlusTaxiMapScale", "Drag to set the scale of the flight map.", 1, 3, 0.05, 356, -92, "%.0f")

			LeaPlusLC:MakeTx(TaxiPanel, "Icon size", 356, -132)
			LeaPlusLC:MakeSL(TaxiPanel, "LeaPlusTaxiIconSize", "Drag to set the size of the icons.", 16, 32, 1, 356, -152, "%.0f")

			LeaPlusLC:MakeTx(TaxiPanel, "Position", 16, -72)
			TaxiPanel.txt = LeaPlusLC:MakeWD(TaxiPanel, "Hold ALT and drag the flight map to move it.", 16, -92, 500)
			TaxiPanel.txt:SetWordWrap(true)
			TaxiPanel.txt:SetWidth(300)

			-- Function to set flight map scale
			local function SetFlightMapScale()
				TaxiFrame:SetScale(LeaPlusLC["LeaPlusTaxiMapScale"])
				LeaPlusCB["LeaPlusTaxiMapScale"].f:SetFormattedText("%.0f%%", LeaPlusLC["LeaPlusTaxiMapScale"] * 100)
			end

			-- Function to set icon size (used for reset and when slider changes)
			local function SetFlightMapIconSize()
				for i = 1, NUM_TAXI_BUTTONS do
					local button = _G["TaxiButton"..i]
					if button and button:IsVisible() then
						_G["TaxiButton" .. i]:SetSize(LeaPlusLC["LeaPlusTaxiIconSize"], LeaPlusLC["LeaPlusTaxiIconSize"])
						if button:GetHighlightTexture() then button:GetHighlightTexture():SetSize(LeaPlusLC["LeaPlusTaxiIconSize"] * 2, LeaPlusLC["LeaPlusTaxiIconSize"] * 2) end
						if button:GetPushedTexture() then button:GetPushedTexture():SetSize(LeaPlusLC["LeaPlusTaxiIconSize"] * 2, LeaPlusLC["LeaPlusTaxiIconSize"] * 2) end
				   end
				end
				LeaPlusCB["LeaPlusTaxiIconSize"].f:SetFormattedText("%.0f%%", LeaPlusLC["LeaPlusTaxiIconSize"] * 6.25)
			end

			-- Set flight map scale when slider changes and on startup
			LeaPlusCB["LeaPlusTaxiMapScale"]:HookScript("OnValueChanged", SetFlightMapScale)
			LeaPlusCB["LeaPlusTaxiIconSize"]:HookScript("OnValueChanged", SetFlightMapIconSize)
			SetFlightMapScale()

			-- Help button tooltip
			TaxiPanel.h.tiptext = L["This panel will close automatically if you enter combat."]

			-- Back button handler
			TaxiPanel.b:SetScript("OnClick", function()
				TaxiPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page5"]:Show()
				return
			end)

			-- Reset button handler
			TaxiPanel.r:SetScript("OnClick", function()

				-- Reset slider
				LeaPlusLC["LeaPlusTaxiMapScale"] = 1
				LeaPlusLC["LeaPlusTaxiIconSize"] = 16
				SetFlightMapScale()
				LeaPlusLC["FlightMapA"] = "TOPLEFT"
				LeaPlusLC["FlightMapR"] = "TOPLEFT"
				LeaPlusLC["FlightMapX"] = 16
				LeaPlusLC["FlightMapY"] = -48
				TaxiFrame:ClearAllPoints()
				TaxiFrame:SetPoint(LeaPlusLC["FlightMapA"], UIParent, LeaPlusLC["FlightMapR"], LeaPlusLC["FlightMapX"], LeaPlusLC["FlightMapY"])

				-- Refresh side panel
				TaxiPanel:Hide(); TaxiPanel:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			LeaPlusCB["EnhanceFlightMapBtn"]:SetScript("OnClick", function()
				if LeaPlusLC:PlayerInCombat() then
					return
				else
					if IsShiftKeyDown() and IsControlKeyDown() then
						-- Preset profile
						LeaPlusLC["LeaPlusTaxiMapScale"] = 1
						LeaPlusLC["LeaPlusTaxiIconSize"] = 16
						LeaPlusLC["FlightMapA"] = "TOPLEFT"
						LeaPlusLC["FlightMapR"] = "TOPLEFT"
						LeaPlusLC["FlightMapX"] = 16
						LeaPlusLC["FlightMapY"] = -48
						SetFlightMapScale()
						SetFlightMapIconSize()
					else
						TaxiPanel:Show()
						LeaPlusLC:HideFrames()
					end
				end
			end)

			-- Hide the configuration panel if combat starts
			TaxiPanel:SetScript("OnUpdate", function()
				if UnitAffectingCombat("player") then
					TaxiPanel:Hide()
				end
			end)

			-- Move the flight map
			TaxiFrame:SetMovable(true)
			TaxiFrame:RegisterForDrag("LeftButton")
			TaxiFrame:SetScript("OnDragStart", function()
				if IsAltKeyDown() then
					TaxiFrame:StartMoving()
				end
			end)
			TaxiFrame:SetScript("OnDragStop", function()
				TaxiFrame:StopMovingOrSizing()
				TaxiFrame:SetUserPlaced(false)
				LeaPlusLC["FlightMapA"], void, LeaPlusLC["FlightMapR"], LeaPlusLC["FlightMapX"], LeaPlusLC["FlightMapY"] = TaxiFrame:GetPoint()
			end)

			-- ElvUI fixes
			if LeaPlusLC.ElvUI then
				if TaxiFrame.backdrop then
					border:ClearAllPoints()
					border:SetPoint("TOPLEFT", 22, -70)
					border:SetPoint("BOTTOMRIGHT", -44, 88)
					TaxiFrame:SetHitRectInsets(22, 44, 70, 88)
					TaxiFrame.backdrop:SetAlpha(0)
				end
			end

		end

		----------------------------------------------------------------------
		--	Use easy chat frame resizing
		----------------------------------------------------------------------

		if LeaPlusLC["UseEasyChatResizing"] == "On" and not LeaLockList["UseEasyChatResizing"] then
			ChatFrame1Tab:HookScript("OnMouseDown", function(self,arg1)
				if arg1 == "LeftButton" then
					if select(8, GetChatWindowInfo(1)) then
						ChatFrame1:StartSizing("TOP")
					end
				end
			end)
			ChatFrame1Tab:SetScript("OnMouseUp", function(self,arg1)
				if arg1 == "LeftButton" then
					ChatFrame1:StopMovingOrSizing()
					FCF_SavePositionAndDimensions(ChatFrame1)
				end
			end)
		end

		----------------------------------------------------------------------
		--	Hide error messages
		----------------------------------------------------------------------

		if LeaPlusLC["HideErrorMessages"] == "On" then

			--	Error message events
			local OrigErrHandler = UIErrorsFrame:GetScript('OnEvent')
			UIErrorsFrame:SetScript('OnEvent', function (self, event, id, err, ...)
				if event == "UI_ERROR_MESSAGE" then
					-- Hide error messages
					if LeaPlusLC["ShowErrorsFlag"] == 1 then
						if 	err == ERR_INV_FULL or
							err == ERR_QUEST_LOG_FULL or
							err == ERR_RAID_GROUP_ONLY	or
							err == ERR_PARTY_LFG_BOOT_LIMIT or
							err == ERR_PARTY_LFG_BOOT_DUNGEON_COMPLETE or
							err == ERR_PARTY_LFG_BOOT_IN_COMBAT or
							err == ERR_PARTY_LFG_BOOT_IN_PROGRESS or
							err == ERR_PARTY_LFG_BOOT_LOOT_ROLLS or
							err == ERR_PARTY_LFG_TELEPORT_IN_COMBAT or
							err == ERR_PET_SPELL_DEAD or
							err == ERR_PLAYER_DEAD or
							err == SPELL_FAILED_TARGET_NO_POCKETS or
							err == ERR_ALREADY_PICKPOCKETED or
							err:find(format(ERR_PARTY_LFG_BOOT_NOT_ELIGIBLE_S, ".+")) then
								return OrigErrHandler(self, event, id, err, ...)
						end
					else
						return OrigErrHandler(self, event, id, err, ...)
					end
				elseif event == 'UI_INFO_MESSAGE'  then
					-- Show information messages
					return OrigErrHandler(self, event, id, err, ...)
				end
			end)

			-- Hide ping system errors
			UIParent:UnregisterEvent("PING_SYSTEM_ERROR")

		end

		----------------------------------------------------------------------
		-- Easy item destroy
		----------------------------------------------------------------------

		if LeaPlusLC["EasyItemDestroy"] == "On" then

			-- Get the type "DELETE" into the field to confirm text
			local TypeDeleteLine = gsub(DELETE_GOOD_ITEM, "[\r\n]", "@")
			local void, TypeDeleteLine = strsplit("@", TypeDeleteLine, 2)

			-- Add hyperlinks to regular item destroy
			-- Taint previously in Midnight: Enter Stockade, loot junk, go vendor with transmog items Lisbeth Schneider 58.2 67.0 Stormwind, auto sell, close and shift reopen
			StaticPopupDialogs["DELETE_ITEM"].OnHyperlinkEnter = StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkEnter
			StaticPopupDialogs["DELETE_ITEM"].OnHyperlinkLeave = StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkLeave
			StaticPopupDialogs["DELETE_QUEST_ITEM"].OnHyperlinkEnter = StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkEnter
			StaticPopupDialogs["DELETE_QUEST_ITEM"].OnHyperlinkLeave = StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkLeave
			StaticPopupDialogs["DELETE_GOOD_QUEST_ITEM"].OnHyperlinkEnter = StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkEnter
			StaticPopupDialogs["DELETE_GOOD_QUEST_ITEM"].OnHyperlinkLeave = StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkLeave

			-- Hide editbox and set item link
			local easyDelFrame = CreateFrame("FRAME")
			easyDelFrame:RegisterEvent("DELETE_ITEM_CONFIRM")
			easyDelFrame:SetScript("OnEvent", function()
				if StaticPopup1EditBox:IsShown() then
					-- Item requires player to type delete so hide editbox and show link
					StaticPopup1EditBox:Hide()
					StaticPopup1Button1:Enable()
					local link = select(3, GetCursorInfo())
					if link then
						-- Custom link for battle pets
						local linkType, linkOptions, name = LinkUtil.ExtractLink(link)
						if linkType == "battlepet" then
							local speciesID, level, breedQuality = strsplit(":", linkOptions)
							local qualityColor = BAG_ITEM_QUALITY_COLORS[tonumber(breedQuality)]
							link = qualityColor:WrapTextInColorCode(name .. " (" .. L["Level"] .. " " .. level .. ")")
						end
						StaticPopup1Text:SetText(gsub(StaticPopup1Text:GetText(), gsub(TypeDeleteLine, "@", ""), "") .. link)
					end
				else
					-- Item does not require player to type delete so just show item link
					StaticPopup1:SetHeight(StaticPopup1:GetHeight() + 40)
					StaticPopup1EditBox:Hide()
					StaticPopup1Button1:Enable()
					local link = select(3, GetCursorInfo())
					if link then
						-- Custom link for battle pets
						local linkType, linkOptions, name = LinkUtil.ExtractLink(link)
						if linkType == "battlepet" then
							local speciesID, level, breedQuality = strsplit(":", linkOptions)
							local qualityColor = BAG_ITEM_QUALITY_COLORS[tonumber(breedQuality)]
							link = qualityColor:WrapTextInColorCode(name .. " (" .. L["Level"] .. " " .. level .. ")")
						end
						StaticPopup1Text:SetText(gsub(StaticPopup1Text:GetText(), gsub(TypeDeleteLine, "@", ""), "") .. "|n|n" .. link .. "|n|n")
					end
				end
			end)

		end

		----------------------------------------------------------------------
		-- Unclamp chat frame
		----------------------------------------------------------------------

		if LeaPlusLC["UnclampChat"] == "On" and not LeaLockList["UnclampChat"] then

			-- Process normal and existing chat frames on startup
			for i = 1, 50 do
				if _G["ChatFrame" .. i] then
					_G["ChatFrame" .. i]:SetClampedToScreen(false)
					_G["ChatFrame" .. i]:SetClampRectInsets(0, 0, 0, 0)
				end
			end

			-- Process new chat frames and combat log
			hooksecurefunc("FloatingChatFrame_UpdateBackgroundAnchors", function(self)
				self:SetClampRectInsets(0, 0, 0, 0)
			end)

			-- Process temporary chat frames
			hooksecurefunc("FCF_OpenTemporaryWindow", function()
				local cf = FCF_GetCurrentChatFrame():GetName() or nil
				if cf then
					_G[cf]:SetClampRectInsets(0, 0, 0, 0)
				end
			end)

		end

		----------------------------------------------------------------------
		-- Keep audio synced
		----------------------------------------------------------------------

		if LeaPlusLC["KeepAudioSynced"] == "On" then

			SetCVar("Sound_OutputDriverIndex", "0")
			local event = CreateFrame("FRAME")
			event:RegisterEvent("VOICE_CHAT_OUTPUT_DEVICES_UPDATED")
			event:SetScript("OnEvent", function()
				if not CinematicFrame:IsShown() and not MovieFrame:IsShown() then -- Dont restart sound system during cinematic
					SetCVar("Sound_OutputDriverIndex", "0")
					Sound_GameSystem_RestartSoundSystem()
				end
			end)

		end

		----------------------------------------------------------------------
		-- Mute custom sounds (no reload required)
		----------------------------------------------------------------------

		do

			-- Create configuration panel
			local MuteCustomPanel = LeaPlusLC:CreatePanel("Mute custom sounds", "MuteCustomPanel")

			local titleTX = LeaPlusLC:MakeTx(MuteCustomPanel, "Editor", 16, -72)
			titleTX:SetWidth(534)
			titleTX:SetWordWrap(false)
			titleTX:SetJustifyH("LEFT")

			-- Show help button for title
			LeaPlusLC:CreateHelpButton("MuteGameSoundsCustomHelpButton", MuteCustomPanel, titleTX, "Enter sound file IDs separated by comma then click the Mute button.|n|nIf you wish, you can enter a brief note for each file ID but do not include numbers in your notes.|n|nFor example, you can enter 'DevAura 569679, RetAura 568744' to mute the Devotion Aura and Retribution Aura spells.|n|nUse Leatrix Sounds to find, test and play sound file IDs.")

			-- Add large editbox
			local eb = CreateFrame("Frame", nil, MuteCustomPanel, "BackdropTemplate")
			eb:SetSize(548, LeaPlusLC.MainPanelHeight - 180)
			eb:SetPoint("TOPLEFT", 10, -92)
			eb:SetBackdrop({
				bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
				edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight",
				edgeSize = 16,
				insets = { left = 8, right = 6, top = 8, bottom = 8 },
			})
			eb:SetBackdropBorderColor(1.0, 0.85, 0.0, 0.5)

			eb.scroll = CreateFrame("ScrollFrame", nil, eb, "LeaPlusMuteCustomSoundsScrollFrameTemplate")
			eb.scroll:SetPoint("TOPLEFT", eb, 12, -10)
			eb.scroll:SetPoint("BOTTOMRIGHT", eb, -30, 10)
			eb.scroll:SetPanExtent(16)

			-- Create character count
			eb.scroll.CharCount = eb.scroll:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
			eb.scroll.CharCount:Hide()

			eb.Text = eb.scroll.EditBox
			eb.Text:SetWidth(494)
			eb.Text:SetHeight(230)
			eb.Text:SetPoint("TOPLEFT", eb.scroll)
			eb.Text:SetPoint("BOTTOMRIGHT", eb.scroll, -12, 0)
			eb.Text:SetMaxLetters(2000)
			eb.Text:SetFontObject(GameFontNormalLarge)
			eb.Text:SetAutoFocus(false)
			eb.scroll:SetScrollChild(eb.Text)

			-- Set focus on the editbox text when clicking the editbox
			eb:SetScript("OnMouseDown", function()
				eb.Text:SetFocus()
				eb.Text:SetCursorPosition(eb.Text:GetMaxLetters())
			end)

			-- Function to save the custom sound list
			local function SaveString(self, userInput)
				local keytext = eb.Text:GetText()
				if keytext and keytext ~= "" then
					LeaPlusLC["MuteCustomList"] = strtrim(eb.Text:GetText())
				else
					LeaPlusLC["MuteCustomList"] = ""
				end
			end

			-- Save the custom sound list when it changes and at startup
			eb.Text:SetScript("OnTextChanged", SaveString)
			eb.Text:SetText(LeaPlusLC["MuteCustomList"])
			SaveString()

			-- Help button hidden
			MuteCustomPanel.h:Hide()

			-- Back button handler
			MuteCustomPanel.b:SetScript("OnClick", function()
				MuteCustomPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page7"]:Show()
				return
			end)

			-- Reset button hidden
			MuteCustomPanel.r:Hide()

			-- Show configuration panal when options panel button is clicked
			LeaPlusCB["MuteCustomSoundsBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["MuteCustomList"] = "Devotion Aura 569679, Retribution Aura 568744"
					eb.Text:SetText(LeaPlusLC["MuteCustomList"])
				else
					MuteCustomPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

			-- Function to mute custom sound list
			local function MuteCustomListFunc(unmute, userInput)
				-- local mutedebug = true -- Debug
				local counter = 0
				local muteString = LeaPlusLC["MuteCustomList"]
				if muteString and muteString ~= "" then
					muteString = muteString:gsub("%s", ",")
					muteString = muteString:gsub("[\n]", ",")
					muteString = muteString:gsub("[^,%d]", "")
					if mutedebug then print(muteString) end
					local tList = {strsplit(",", muteString)}
					if mutedebug then ChatFrame1:Clear() end
					for i = 1, #tList do
						if tList[i] then
							tList[i] = tonumber(tList[i])
							if tList[i] and tList[i] < 20000000 then
								if mutedebug then print(tList[i]) end
								if unmute then
									UnmuteSoundFile(tList[i])
								else
									MuteSoundFile(tList[i])
								end
								counter = counter + 1
							end
						end
					end
					if userInput then
						if unmute then
							if counter == 1 then
								LeaPlusLC:Print(L["Unmuted"] .. " " .. counter .. " " .. L["sound"] .. ".")
							else
								LeaPlusLC:Print(L["Unmuted"] .. " " .. counter .. " " .. L["sounds"] .. ".")
							end
						else
							if counter == 1 then
								LeaPlusLC:Print(L["Muted"] .. " " .. counter .. " " .. L["sound"] .. ".")
							else
								LeaPlusLC:Print(L["Muted"] .. " " .. counter .. " " .. L["sounds"] .. ".")
							end
						end
					end
				end
			end

			-- Mute custom list on startup if option is enabled
			if LeaPlusLC["MuteCustomSounds"] == "On" then
				MuteCustomListFunc()
			end

			-- Mute or unmute when option is clicked
			LeaPlusCB["MuteCustomSounds"]:HookScript("OnClick", function()
				if LeaPlusLC["MuteCustomSounds"] == "On" then
					MuteCustomListFunc(false, false)
				else
					MuteCustomListFunc(true, false)
				end
			end)

			-- Add mute button
			local MuteCustomNowButton = LeaPlusLC:CreateButton("MuteCustomNowButton", MuteCustomPanel, "Mute", "BOTTOMLEFT", 16, 53, 0, 25, true, "Click to mute sounds in the list.")
			LeaPlusCB["MuteCustomNowButton"]:SetScript("OnClick", function() MuteCustomListFunc(false, true) end)

			-- Add unmute button
			local UnmuteCustomNowButton = LeaPlusLC:CreateButton("UnmuteCustomNowButton", MuteCustomPanel, "Unmute", "BOTTOMLEFT", 16, 53, 0, 25, true, "Click to unmute sounds in the list.")
			LeaPlusCB["UnmuteCustomNowButton"]:ClearAllPoints()
			LeaPlusCB["UnmuteCustomNowButton"]:SetPoint("LEFT", MuteCustomNowButton, "RIGHT", 10, 0)
			LeaPlusCB["UnmuteCustomNowButton"]:SetScript("OnClick", function() MuteCustomListFunc(true, true) end)

			----------------------------------------------------------------------
			-- Sound finder
			----------------------------------------------------------------------

			do

				-- Create configuration panel
				local SoundFinderPanel = LeaPlusLC:CreatePanel("Mute custom sounds", "SoundFinderPanel")

				-- Locals
				local SoundMax = 9000000
				local lo, hi, mid, found
				local history = {}
				local queue = {}
				local playHandle
				local queueTotal, queueDone = 0, 0
				local restarted, restartWhenDone, allMuted
				local foundText = ""

				-- Add sound finder button to the mute custom sounds panel (left of the back to main menu button)
				local MuteCustomFindButton = LeaPlusLC:CreateButton("MuteCustomFindButton", MuteCustomPanel, "Sound Finder", "BOTTOMLEFT", 16, 53, 0, 25, true, "Click to toggle the sound finder.")
				LeaPlusCB["MuteCustomFindButton"]:ClearAllPoints()
				LeaPlusCB["MuteCustomFindButton"]:SetPoint("RIGHT", MuteCustomPanel.b, "LEFT", -10, 0)
				LeaPlusCB["MuteCustomFindButton"]:SetScript("OnClick", function()
					SoundFinderPanel:Show(); MuteCustomPanel:Hide()
					return
				end)

				-- Add second sound finder button to the sound finder panel (same position as the first one)
				local MuteCustomFindButton2 = LeaPlusLC:CreateButton("MuteCustomFindButton2", SoundFinderPanel, "Sound Finder", "BOTTOMLEFT", 16, 53, 0, 25, true, "Click to toggle the sound finder.")
				LeaPlusCB["MuteCustomFindButton2"]:ClearAllPoints()
				LeaPlusCB["MuteCustomFindButton2"]:SetPoint("RIGHT", SoundFinderPanel.b, "LEFT", -10, 0)
				LeaPlusCB["MuteCustomFindButton2"]:SetScript("OnClick", function()
					SoundFinderPanel:Hide(); MuteCustomPanel:Show()
					return
				end)

				-- Panel contents
				local titleTX = LeaPlusLC:MakeTx(SoundFinderPanel, "Sound finder", 16, -72)
				LeaPlusLC:CreateHelpButton("SoundFinderHelpButton", SoundFinderPanel, titleTX, "The sound finder lets you find the file ID of a sound that is playing in game.|n|nPlay the sound you want to find and click the start button.  Each step mutes half of the remaining sound files.  Click the heard button if you can still hear the sound or the silent button if you cannot.|n|nFor sound effects (such as an ability or emote), play the sound again after each step.  For music or ambience, click the sound system restart button after each step.|n|nWhen the sound file is found, its ID is shown in the editbox on the right so that you can copy it.")

				local status = LeaPlusLC:MakeWD(SoundFinderPanel, "", 16, -96)
				local prompt = LeaPlusLC:MakeWD(SoundFinderPanel, "", 16, -116)

				-- Step progress bar (gold gradient fill with a border, a spark at the fill edge and a shine that sweeps across the fill)
				local bar = CreateFrame("StatusBar", nil, SoundFinderPanel)
				bar:SetSize(538, 22)
				bar:SetPoint("TOPLEFT", 16, -140)
				bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
				bar:GetStatusBarTexture():SetGradient("VERTICAL", CreateColor(0.85, 0.45, 0, 1), CreateColor(1, 0.9, 0.3, 1))
				bar:SetMinMaxValues(0, 1)
				bar:SetValue(0)
				bar.value, bar.target = 0, 0

				bar.bg = bar:CreateTexture(nil, "BACKGROUND")
				bar.bg:SetAllPoints()
				bar.bg:SetColorTexture(0, 0, 0, 0.6)

				-- Border
				bar.border = CreateFrame("Frame", nil, bar, "BackdropTemplate")
				bar.border:SetPoint("TOPLEFT", -4, 4)
				bar.border:SetPoint("BOTTOMRIGHT", 4, -4)
				bar.border:SetBackdrop({edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12})
				bar.border:SetBackdropBorderColor(1, 0.82, 0, 0.8)
				bar.border:SetFrameLevel(bar:GetFrameLevel() + 3)

				-- Shine (clipped to the filled part of the bar)
				bar.clip = CreateFrame("Frame", nil, bar)
				bar.clip:SetPoint("TOPLEFT", bar:GetStatusBarTexture(), "TOPLEFT")
				bar.clip:SetPoint("BOTTOMRIGHT", bar:GetStatusBarTexture(), "BOTTOMRIGHT")
				bar.clip:SetClipsChildren(true)
				bar.shineL = bar.clip:CreateTexture(nil, "OVERLAY")
				bar.shineL:SetTexture("Interface\\Buttons\\WHITE8X8")
				bar.shineL:SetSize(30, 22)
				bar.shineL:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 0), CreateColor(1, 1, 1, 0.45))
				bar.shineR = bar.clip:CreateTexture(nil, "OVERLAY")
				bar.shineR:SetTexture("Interface\\Buttons\\WHITE8X8")
				bar.shineR:SetSize(30, 22)
				bar.shineR:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 0.45), CreateColor(1, 1, 1, 0))
				bar.shineR:SetPoint("LEFT", bar.shineL, "RIGHT")
				bar.shineX = -60

				-- Spark at the edge of the fill
				bar.spark = bar:CreateTexture(nil, "OVERLAY")
				bar.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
				bar.spark:SetBlendMode("ADD")
				bar.spark:SetSize(24, 44)
				bar.spark:SetPoint("CENTER", bar:GetStatusBarTexture(), "RIGHT", 0, 0)

				bar.text = bar.border:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
				bar.text:SetPoint("CENTER")

				-- Animate the bar (fill slides to the new value and the shine sweeps across)
				bar:SetScript("OnUpdate", function(self, elapsed)
					-- Slide fill towards target
					if self.value ~= self.target then
						local step = elapsed * 2
						if math.abs(self.target - self.value) <= step then self.value = self.target
						elseif self.target > self.value then self.value = self.value + step
						else self.value = self.value - step end
						self:SetValue(self.value)
					end
					-- Spark only shows while the bar is part filled
					self.spark:SetShown(self.value > 0 and self.value < 1)
					-- Sweep the shine across the fill
					self.shineX = self.shineX + elapsed * 160
					if self.shineX > 538 + 200 then self.shineX = -60 end
					self.shineL:SetPoint("LEFT", self.clip, "LEFT", self.shineX, 0)
				end)

				-- Start, heard it and silent buttons
				local startBtn = LeaPlusLC:CreateButton("SoundFinderStartButton", SoundFinderPanel, "Start", "TOPLEFT", 16, -170, 0, 25, true, "Click to start a new search.")
				local heardBtn = LeaPlusLC:CreateButton("SoundFinderHeardButton", SoundFinderPanel, "Heard it", "TOPLEFT", 0, 0, 0, 25, true, "Click if you can still hear the sound.")
				heardBtn:ClearAllPoints(); heardBtn:SetPoint("LEFT", startBtn, "RIGHT", 10, 0)
				local silentBtn = LeaPlusLC:CreateButton("SoundFinderSilentButton", SoundFinderPanel, "Silent", "TOPLEFT", 0, 0, 0, 25, true, "Click if you can no longer hear the sound.")
				silentBtn:ClearAllPoints(); silentBtn:SetPoint("LEFT", heardBtn, "RIGHT", 10, 0)
				local undoBtn = LeaPlusLC:CreateButton("SoundFinderUndoButton", SoundFinderPanel, "Undo", "TOPLEFT", 0, 0, 0, 25, true, "Click to undo your last heard it or silent answer.")
				undoBtn:ClearAllPoints(); undoBtn:SetPoint("LEFT", silentBtn, "RIGHT", 10, 0)

				-- Add icons to the start, heard it and silent buttons (button text is moved right to make room)
				for i, v in pairs({{startBtn, "common-search-magnifyingglass"}, {heardBtn, "lootroll-icon-checkmark"}, {silentBtn, "auctionhouse-ui-filter-redx"}, {undoBtn, "common-icon-undo"}}) do
					local btn, atlas = v[1], v[2]
					btn.icon = btn:CreateTexture(nil, "OVERLAY")
					btn.icon:SetSize(14, 14)
					btn.icon:SetPoint("LEFT", 8, 0)
					btn.icon:SetAtlas(atlas)
					btn:SetWidth(btn:GetWidth() + 16)
					btn:GetFontString():ClearAllPoints()
					btn:GetFontString():SetPoint("CENTER", 8, 0)
				end

				-- Function to create a small icon button
				local function MakeIconButton(atlas, tip)
					local btn = CreateFrame("Button", nil, SoundFinderPanel)
					btn:SetSize(24, 24)
					btn.icon = btn:CreateTexture(nil, "ARTWORK")
					btn.icon:SetAllPoints()
					btn.icon:SetAtlas(atlas)
					btn.icon:SetVertexColor(1, 0.82, 0)
					btn.tiptext = L[tip]
					btn:SetScript("OnEnter", function(self)
						self.icon:SetVertexColor(1, 1, 1)
						LeaPlusLC.TipSee(self)
					end)
					btn:SetScript("OnLeave", function(self)
						self.icon:SetVertexColor(1, 0.82, 0)
						GameTooltip:Hide()
					end)
					btn:SetScript("OnMouseDown", function(self) self.icon:SetPoint("TOPLEFT", 1, -1); self.icon:SetPoint("BOTTOMRIGHT", 1, -1) end)
					btn:SetScript("OnMouseUp", function(self) self.icon:SetAllPoints() end)
					return btn
				end

				-- Restart sound system, mute all and unmute all buttons (right side of the button row)
				local unmuteAllBtn = MakeIconButton("voicechat-icon-speaker", "Click to unmute every sound file in the game.  This ends the current search and also unmutes sounds muted by Leatrix Plus or other addons (reload your UI to restore them).")
				unmuteAllBtn:SetPoint("TOPRIGHT", -16, -170)
				local muteAllBtn = MakeIconButton("voicechat-icon-speaker-mute", "Click to mute every sound file in the game.  This ends the current search and sounds stay muted when the panel is closed.")
				muteAllBtn:SetPoint("RIGHT", unmuteAllBtn, "LEFT", -8, 0)
				local restartBtn = MakeIconButton("UI-RefreshButton", "Click to restart the sound system.  Use this after each step if you are looking for music or ambience (sounds that are already playing are not muted until the sound system is restarted).")
				restartBtn:SetPoint("RIGHT", muteAllBtn, "LEFT", -8, 0)

				-- Sound file ID editbox (read only, text is highlighted so it can be copied) and play button (top right above the progress bar)
				local playBtn = LeaPlusLC:CreateButton("SoundFinderPlayButton", SoundFinderPanel, "Play", "TOPRIGHT", -16, -108, 0, 25, true, "Click to play the sound file that was found.")
				local idBox = LeaPlusLC:CreateEditBox("SoundFinderIDBox", SoundFinderPanel, 116, 10, "TOPLEFT", 0, 0, "SoundFinderIDBox", "SoundFinderIDBox")
				idBox:ClearAllPoints(); idBox:SetPoint("RIGHT", playBtn, "LEFT", -10, 0)
				local idTitle = LeaPlusLC:MakeTx(SoundFinderPanel, "Sound file ID", 0, 0)
				idTitle:ClearAllPoints()
				idTitle:SetPoint("TOPLEFT", idBox, "TOPLEFT", -4, 16)
				idBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
				idBox:SetScript("OnMouseUp", function(self) self:HighlightText() end)
				idBox:SetScript("OnTextChanged", function(self, userInput)
					if userInput then
						self:SetText(foundText)
						self:HighlightText()
					end
				end)

				-- Function to update the step progress bar (steps answered and steps left)
				local function UpdateBar()
					local done, total = 0, math.ceil(math.log(SoundMax) / math.log(2))
					if lo then
						done = #history - 1
						if found then total = done else total = done + math.ceil(math.log(hi - lo + 1) / math.log(2)) end
					end
					bar.target = total > 0 and done / total or 0
					bar.text:SetText(L["Step"] .. " " .. done .. " / " .. total)
				end

				-- Function to update the panel
				local function UpdatePanel()
					UpdateBar()
					local busy = #queue > 0
					if busy then
						status:SetText(L["Please wait..."] .. " |cffffffff" .. math.floor(queueDone / queueTotal * 100) .. "%")
						prompt:SetText("")
					elseif found then
						foundText = tostring(lo)
						idBox:SetText(foundText)
						status:SetText(L["Sound file found"] .. ": |cffffffff" .. foundText)
						prompt:SetText(L["Click Play to check it."])
					elseif lo then
						status:SetText(L["Searching"] .. " |cffffffff" .. lo .. " - " .. hi .. "|r (" .. (hi - lo + 1) .. ")")
						prompt:SetText(L["Can you still hear the sound?"])
					else
						status:SetText(L["Play the sound you want to find."])
						prompt:SetText(L["Then click Start."])
					end
					LeaPlusLC:LockItem(startBtn, busy)
					LeaPlusLC:LockItem(heardBtn, busy or not lo or found)
					LeaPlusLC:LockItem(silentBtn, busy or not lo or found)
					LeaPlusLC:LockItem(undoBtn, busy or not lo or #history < 2)
					LeaPlusLC:LockItem(restartBtn, busy)
					LeaPlusLC:LockItem(muteAllBtn, busy)
					LeaPlusLC:LockItem(unmuteAllBtn, busy)
					LeaPlusLC:LockItem(playBtn, foundText == "")
					LeaPlusLC:LockItem(idBox, foundText == "")
				end

				-- Worker frame to mute and unmute sound files in small chunks each frame (prevents the game from freezing)
				local worker = CreateFrame("FRAME")
				worker:Hide()
				worker:SetScript("OnUpdate", function()
					local stopTime = debugprofilestop() + 8
					while queue[1] and debugprofilestop() < stopTime do
						local job = queue[1]
						local func = job.mute and MuteSoundFile or UnmuteSoundFile
						local last = math.min(job.first + 4999, job.last)
						for i = job.first, last do
							func(i)
						end
						queueDone = queueDone + last - job.first + 1
						job.first = last + 1
						if job.first > job.last then tremove(queue, 1) end
					end
					if not queue[1] then
						-- Queue finished (restart sound system if it was restarted during a search that has now been closed)
						worker:Hide()
						queueTotal, queueDone = 0, 0
						if restartWhenDone then
							restartWhenDone = false
							Sound_GameSystem_RestartSoundSystem()
						end
					end
					if SoundFinderPanel:IsShown() then UpdatePanel() end
				end)

				-- Function to queue a range of sound files to mute or unmute
				local function SetMuted(first, last, mute)
					tinsert(queue, {first = first, last = last, mute = mute})
					queueTotal = queueTotal + last - first + 1
					worker:Show()
				end

				-- Function to reverse all steps (unmutes everything the finder muted)
				local function ResetSteps()
					for i = #history, 1, -1 do
						local entry = history[i]
						if entry.first then SetMuted(entry.first, entry.last, not entry.mute) end
					end
					wipe(history)
					lo, hi, mid, found = nil, nil, nil, false
				end

				-- Restart button
				restartBtn:SetScript("OnClick", function()
					restarted = true
					Sound_GameSystem_RestartSoundSystem()
				end)

				-- Mute all button (ends the search without reversing it as everything is muted anyway)
				muteAllBtn:SetScript("OnClick", function()
					wipe(history)
					lo, hi, mid, found = nil, nil, nil, false
					allMuted = true
					SetMuted(1, SoundMax, true)
					UpdatePanel()
				end)

				-- Unmute all button (ends the search without reversing it as everything is unmuted anyway)
				unmuteAllBtn:SetScript("OnClick", function()
					wipe(history)
					lo, hi, mid, found = nil, nil, nil, false
					allMuted = false
					SetMuted(1, SoundMax, false)
					UpdatePanel()
				end)

				-- Start button (mute the upper half of all sound files)
				startBtn:SetScript("OnClick", function()
					ResetSteps()
					foundText = ""
					idBox:SetText("")
					lo, hi, found = 1, SoundMax, false
					mid = math.floor((lo + hi) / 2)
					if allMuted then
						-- Everything is muted so unmute the lower half instead
						tinsert(history, {first = lo, last = mid, mute = false})
						SetMuted(lo, mid, false)
					else
						tinsert(history, {first = mid + 1, last = hi, mute = true})
						SetMuted(mid + 1, hi, true)
					end
					UpdatePanel()
				end)

				-- Heard it button (sound is in the lower half so mute the upper half of that)
				heardBtn:SetScript("OnClick", function()
					local entry = {lo = lo, hi = hi, mid = mid}
					hi = mid
					if lo == hi then
						found = true
					else
						mid = math.floor((lo + hi) / 2)
						entry.first, entry.last, entry.mute = mid + 1, hi, true
						SetMuted(mid + 1, hi, true)
					end
					tinsert(history, entry)
					UpdatePanel()
				end)

				-- Silent button (sound is in the muted upper half so unmute the lower half of that)
				silentBtn:SetScript("OnClick", function()
					local entry = {lo = lo, hi = hi, mid = mid}
					lo = mid + 1
					if lo == hi then
						found = true
						entry.first, entry.last, entry.mute = lo, lo, false
					else
						mid = math.floor((lo + hi) / 2)
						entry.first, entry.last, entry.mute = lo, mid, false
					end
					SetMuted(entry.first, entry.last, false)
					tinsert(history, entry)
					UpdatePanel()
				end)

				-- Undo button (reverses the last heard it or silent answer)
				undoBtn:SetScript("OnClick", function()
					if #history < 2 then return end
					local entry = tremove(history)
					if entry.first then SetMuted(entry.first, entry.last, not entry.mute) end
					lo, hi, mid = entry.lo, entry.hi, entry.mid
					if found then
						found = false
						foundText = ""
						idBox:SetText("")
						if playHandle then StopSound(playHandle); playHandle = nil end
					end
					UpdatePanel()
				end)

				-- Play button
				playBtn:SetScript("OnClick", function()
					idBox:ClearFocus()
					local soundID = tonumber(foundText)
					if not soundID then return end
					if playHandle then StopSound(playHandle) end
					local willPlay
					willPlay, playHandle = PlaySoundFile(soundID, "Master")
					if not willPlay then LeaPlusLC:Print(L["Sound file could not be played"] .. ": |cffffffff" .. foundText) end
				end)

				-- Bubbles that float up the panel (they rise faster while sound files are being muted)
				local bubbles = {}
				local bubbleTop, bubbleBottom = LeaPlusLC.MainPanelHeight - 68, 48
				for i = 1, 24 do
					local b = SoundFinderPanel:CreateTexture(nil, "BORDER", nil, 7)
					b:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
					b:SetVertexColor(0.6, 0.85, 1)
					bubbles[i] = b
				end

				-- Function to send a bubble back to the bottom of the panel
				local function ResetBubble(b, anywhere)
					b.size = math.random(4, 14)
					b.x = math.random(12, 556 - b.size)
					b.y = anywhere and math.random(bubbleBottom, bubbleTop) or bubbleBottom - b.size
					b.speed = math.random(12, 32)
					b.wobble = math.random(2, 6)
					b.phase = math.random() * 6.28
					b:SetSize(b.size, b.size)
				end
				for i, b in ipairs(bubbles) do ResetBubble(b, true) end

				-- Move bubbles each frame
				SoundFinderPanel:SetScript("OnUpdate", function(self, elapsed)
					local boost = #queue > 0 and 3 or 1
					for i, b in ipairs(bubbles) do
						b.y = b.y + b.speed * boost * elapsed
						if b.y > bubbleTop then ResetBubble(b) end
						b.phase = b.phase + elapsed * 2
						-- Fade in at the bottom and out at the top
						local alpha = 0.3
						local height = b.y - bubbleBottom
						if height < 20 then alpha = alpha * math.max(height, 0) / 20 elseif b.y > bubbleTop - 40 then alpha = alpha * (bubbleTop - b.y) / 40 end
						b:SetAlpha(alpha)
						b:SetPoint("BOTTOMLEFT", b.x + math.sin(b.phase) * b.wobble, b.y)
					end
				end)

				-- Update panel when shown
				SoundFinderPanel:HookScript("OnShow", UpdatePanel)

				-- Unmute everything the finder muted when the panel is hidden (continues in the background)
				SoundFinderPanel:SetScript("OnHide", function()
					ResetSteps()
					if restarted then restartWhenDone = true; restarted = false end
					if playHandle then StopSound(playHandle); playHandle = nil end
				end)

				-- Help button hidden
				SoundFinderPanel.h:Hide()

				-- Reset button hidden
				SoundFinderPanel.r:Hide()

				-- Back button handler
				SoundFinderPanel.b:SetScript("OnClick", function()
					SoundFinderPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page7"]:Show()
					return
				end)

			end

			----------------------------------------------------------------------
			-- Rest of things
			----------------------------------------------------------------------

			-- Add play sound file editbox
			local willPlay, musicHandle
			local MuteCustomSoundsStopButton = LeaPlusLC:CreateButton("MuteCustomSoundsStopButton", MuteCustomPanel, "Stop", "TOPRIGHT", -18, -66, 0, 25, true, "")
			MuteCustomSoundsStopButton:SetScript("OnClick", function()
				if musicHandle then StopSound(musicHandle) end
			end)

			local MuteCustomSoundsPlayButton = LeaPlusLC:CreateButton("MuteCustomSoundsPlayButton", MuteCustomPanel, "Play", "TOPRIGHT", -18, -66, 0, 25, true, "")
			MuteCustomSoundsPlayButton:ClearAllPoints()
			MuteCustomSoundsPlayButton:SetPoint("RIGHT", MuteCustomSoundsStopButton, "LEFT", -10, 0)

			local MuteCustomSoundsSoundBox = LeaPlusLC:CreateEditBox("MuteCustomSoundsSoundBox", eb, 80, 8, "TOPRIGHT", -10, 20, "PlaySoundBox", "PlaySoundBox")
			MuteCustomSoundsSoundBox:SetNumeric(true)
			MuteCustomSoundsSoundBox:ClearAllPoints()
			MuteCustomSoundsSoundBox:SetPoint("RIGHT", MuteCustomSoundsPlayButton, "LEFT", -10, 0)
			MuteCustomSoundsPlayButton:SetScript("OnClick", function()
				MuteCustomSoundsSoundBox:GetText()
				if musicHandle then StopSound(musicHandle) end
				willPlay, musicHandle = PlaySoundFile(MuteCustomSoundsSoundBox:GetText(), "Master")
			end)

			-- Add mousewheel support to the editbox
			MuteCustomSoundsSoundBox:SetScript("OnMouseWheel", function(self, delta)
				local endSound = tonumber(MuteCustomSoundsSoundBox:GetText())
				if endSound then
					if delta == 1 then endSound = endSound + 1 else endSound = endSound - 1 end
					if endSound < 1 then endSound = 1 elseif endSound >= 10000000 then endSound = 10000000 end
					MuteCustomSoundsSoundBox:SetText(endSound)
					MuteCustomSoundsPlayButton:Click()
				end
			end)

			local titlePlayer = LeaPlusLC:MakeTx(MuteCustomPanel, "Player", 16, -72)
			titlePlayer:ClearAllPoints()
			titlePlayer:SetPoint("TOPLEFT", MuteCustomSoundsSoundBox, "TOPLEFT", -4, 16)
			LeaPlusLC:CreateHelpButton("MuteGameSoundsCustomPlayHelpButton", MuteCustomPanel, titlePlayer, "If you want to listen to a sound file, enter the sound file ID into the editbox and click the play button.|n|nYou can scroll the mousewheel over the editbox to play neighbouring sound files.")
		end

		----------------------------------------------------------------------
		-- Hide rested sleep
		----------------------------------------------------------------------

		if LeaPlusLC["NoRestedSleep"] == "On" and not LeaLockList["NoRestedSleep"] then
			PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerRestLoop.RestTexture:SetTexture("")
		end

		----------------------------------------------------------------------
		-- Block shared quests (no reload needed)
		----------------------------------------------------------------------

		do

			local eFrame = CreateFrame("FRAME")
			eFrame:SetScript("OnEvent", LeaPlusLC.CheckIfQuestIsSharedAndShouldBeDeclined)

			-- Function to set event
			local function SetSharedQuestsFunc()
				if LeaPlusLC["NoSharedQuests"] == "On" then
					eFrame:RegisterEvent("QUEST_DETAIL")
				else
					eFrame:UnregisterEvent("QUEST_DETAIL")
				end
			end

			-- Set event when option is clicked and on startup
			LeaPlusCB["NoSharedQuests"]:HookScript("OnClick", SetSharedQuestsFunc)
			SetSharedQuestsFunc()

		end

		----------------------------------------------------------------------
		-- Restore chat messages
		----------------------------------------------------------------------

		if LeaPlusLC["RestoreChatMessages"] == "On" and not LeaLockList["RestoreChatMessages"] then

			local historyFrame = CreateFrame("FRAME")
			historyFrame:RegisterEvent("PLAYER_LOGIN")
			historyFrame:RegisterEvent("PLAYER_LOGOUT")

			local FCF_IsChatWindowIndexActive = FCF_IsChatWindowIndexActive
			local GetMessageInfo = GetMessageInfo
			local GetNumMessages = GetNumMessages

			-- Save chat messages on logout
			historyFrame:SetScript("OnEvent", function(self, event)
				if event == "PLAYER_LOGOUT" then
					local name, realm = UnitFullName("player")
					if not realm then realm = GetNormalizedRealmName() end
					if name and realm then
						LeaPlusDB["ChatHistoryName"] = name .. "-" .. realm
						LeaPlusDB["ChatHistoryTime"] = GetServerTime()
						for i = 1, 50 do
							if i ~= 2 and _G["ChatFrame" .. i] then
								if FCF_IsChatWindowIndexActive(i) then
									LeaPlusDB["ChatHistory" .. i] = {}
									local chtfrm = _G["ChatFrame" .. i]
									local NumMsg = chtfrm:GetNumMessages()
									local StartMsg = 1
									if NumMsg > 256 then StartMsg = NumMsg - 255 end
									for iMsg = StartMsg, NumMsg do
										local chatMessage, r, g, b, chatTypeID = chtfrm:GetMessageInfo(iMsg)
										if chatMessage and canaccessvalue(chatMessage) then
											if r and g and b then
												local colorCode = RGBToColorCode(r, g, b)
												chatMessage = colorCode .. chatMessage
											end
											tinsert(LeaPlusDB["ChatHistory" .. i], chatMessage)
										end
									end
								end
							end
						end
					end
				end
			end)

			-- Restore chat messages on login
			local name, realm = UnitFullName("player")
			if not realm then realm = GetNormalizedRealmName() end
			if name and realm then
				if LeaPlusDB["ChatHistoryName"] and LeaPlusDB["ChatHistoryTime"] then
					local timeDiff = GetServerTime() - LeaPlusDB["ChatHistoryTime"]
					if LeaPlusDB["ChatHistoryName"] == name .. "-" .. realm and timeDiff and timeDiff < 10 then -- reload must be done within 15 seconds

						-- Store chat messages from current session and clear chat
						for i = 1, 50 do
							if i ~= 2 and _G["ChatFrame" .. i] and FCF_IsChatWindowIndexActive(i) then
								LeaPlusDB["ChatTemp" .. i] = {}
								local chtfrm = _G["ChatFrame" .. i]
								local NumMsg = chtfrm:GetNumMessages()
								for iMsg = 1, NumMsg do
									local chatMessage, r, g, b, chatTypeID = chtfrm:GetMessageInfo(iMsg)
									if chatMessage and canaccessvalue(chatMessage) then
										if r and g and b then
											local colorCode = RGBToColorCode(r, g, b)
											chatMessage = colorCode .. chatMessage
										end
										tinsert(LeaPlusDB["ChatTemp" .. i], chatMessage)
									end
								end
								chtfrm:Clear()
							end
						end

						-- Restore chat messages from previous session
						for i = 1, 50 do
							if i ~= 2 and _G["ChatFrame" .. i] and LeaPlusDB["ChatHistory" .. i] and FCF_IsChatWindowIndexActive(i) then
								LeaPlusDB["ChatHistory" .. i .. "Count"] = 0
								-- Add previous session messages to chat
								for k = 1, #LeaPlusDB["ChatHistory" .. i] do
									if LeaPlusDB["ChatHistory" .. i][k] ~= string.match(LeaPlusDB["ChatHistory" .. i][k], "|cffffd800" .. L["Restored"] .. " " .. ".*" .. " " .. L["message"] .. ".*.|r") then
										_G["ChatFrame" .. i]:AddMessage(LeaPlusDB["ChatHistory" .. i][k])
										LeaPlusDB["ChatHistory" .. i .. "Count"] = LeaPlusDB["ChatHistory" .. i .. "Count"] + 1
									end
								end
								-- Show how many messages were restored
								if LeaPlusDB["ChatHistory" .. i .. "Count"] == 1 then
									_G["ChatFrame" .. i]:AddMessage("|cffffd800" .. L["Restored"] .. " " .. LeaPlusDB["ChatHistory" .. i .. "Count"] .. " " .. L["message from previous session"] .. ".|r")
								else
									_G["ChatFrame" .. i]:AddMessage("|cffffd800" .. L["Restored"] .. " " .. LeaPlusDB["ChatHistory" .. i .. "Count"] .. " " .. L["messages from previous session"] .. ".|r")
								end
							else
								-- No messages to restore
								LeaPlusDB["ChatHistory" .. i] = nil
							end
						end

						-- Restore chat messages from this session
						for i = 1, 50 do
							if i ~= 2 and _G["ChatFrame" .. i] and LeaPlusDB["ChatTemp" .. i] and FCF_IsChatWindowIndexActive(i) then
								for k = 1, #LeaPlusDB["ChatTemp" .. i] do
									_G["ChatFrame" .. i]:AddMessage(LeaPlusDB["ChatTemp" .. i][k])
								end
							end
						end

					end
				end
			end

		else

			-- Option is disabled so clear any messages from saved variables
			LeaPlusDB["ChatHistoryName"] = nil
			LeaPlusDB["ChatHistoryTime"] = nil
			for i = 1, 50 do
				LeaPlusDB["ChatHistory" .. i] = nil
				LeaPlusDB["ChatTemp" .. i] = nil
				LeaPlusDB["ChatHistory" .. i .. "Count"] = nil
			end

		end

		----------------------------------------------------------------------
		--	More chat font sizes
		----------------------------------------------------------------------

		if LeaPlusLC["MoreChatFontSizes"] == "On" and not LeaLockList["MoreChatFontSizes"] then

			local extraSizes = {22, 26, 28, 30, 32, 34, 36, 38, 40}

			Menu.ModifyMenu("MENU_FCF_TAB", function(owner, rootDescription)
				local chatFrame = FCF_GetChatFrameByID(owner:GetID())
				if not chatFrame then return end

				-- Find Blizzard's font size submenu (it contains a radio for the first chat font size)
				local fontMenu
				for void, element in rootDescription:EnumerateElementDescriptions() do
					for void, child in element:EnumerateElementDescriptions() do
						if child.IsRadio and child:IsRadio() and child:GetData() == CHAT_FONT_HEIGHTS[1] then
							fontMenu = element
							break
						end
					end
					if fontMenu then break end
				end
				if not fontMenu then return end

				-- Tick the size in use (font height is checked for secrets before it is compared)
				local function IsSelected(size)
					local void, height = chatFrame:GetFont()
					if not height or (issecretvalue and issecretvalue(height)) then return false end
					return math.floor(height + 0.5) == size
				end

				-- Set and save the font size the same way Blizzard's own options do
				local function SetSelected(size)
					FCF_SetChatWindowFontSize(nil, chatFrame, size)
				end

				-- Insert each extra size in order, skipping any size Blizzard already has
				for void, size in ipairs(extraSizes) do
					local index, exists = 1, false
					for i, child in fontMenu:EnumerateElementDescriptions() do
						local data = child:GetData()
						if data == size then exists = true; break end
						if type(data) == "number" and data < size then index = i + 1 end
					end
					if not exists then
						fontMenu:Insert(MenuUtil.CreateRadio(format(FONT_SIZE_TEMPLATE, size), IsSelected, SetSelected, size), index)
					end
				end
			end)

			-- Apply the main chat window font size to the guild and community chat (and GM chat)
			-- Blizzard only copies it when the communities addon loads or when a size is chosen from the menu,
			-- so if the communities addon loads before saved chat sizes are applied at login, it keeps the default size
			local function SyncCommunityChatFont()
				if not DEFAULT_CHAT_FRAME then return end
				local void, fontSize = FCF_GetChatWindowInfo(DEFAULT_CHAT_FRAME:GetID())
				if not fontSize or fontSize <= 0 then return end
				local fontFile, void, fontFlags = DEFAULT_CHAT_FRAME:GetFont()
				if not fontFile then return end
				if CommunitiesFrame and CommunitiesFrame.Chat and CommunitiesFrame.Chat.MessageFrame then
					CommunitiesFrame.Chat.MessageFrame:SetFont(fontFile, fontSize, fontFlags)
				end
				if GMChatFrame then
					GMChatFrame:SetFont(fontFile, fontSize, fontFlags)
				end
			end

			local fontSyncFrame = CreateFrame("FRAME")
			fontSyncFrame:RegisterEvent("UPDATE_CHAT_WINDOWS")
			fontSyncFrame:RegisterEvent("ADDON_LOADED")
			fontSyncFrame:SetScript("OnEvent", function(self, event, addonName)
				if event == "ADDON_LOADED" and addonName ~= "Blizzard_Communities" and addonName ~= "Blizzard_GMChatUI" then return end
				SyncCommunityChatFont()
			end)

			-- Apply now in case chat sizes were already applied before this ran
			SyncCommunityChatFont()

		end

		----------------------------------------------------------------------
		-- Enhance minimap
		----------------------------------------------------------------------

		if LeaPlusLC["MinimapModder"] == "On" and not LeaLockList["MinimapModder"] then

			-- Set minimap shape (need to do this first)
			if LeaPlusLC["SquareMinimap"] == "On" then
				-- Square minimap is enabled so use square shape
				_G.GetMinimapShape = function() return "SQUARE" end
			else
				-- Square minimap is disabled so use round shape
				_G.GetMinimapShape = function() return "ROUND" end
			end

			local miniFrame = CreateFrame("FRAME")
			local LibDBIconStub = LibStub("LibDBIcon-1.0")
			if LeaPlusLC["SquareMinimap"] == "On" then
				LibDBIconStub:SetButtonRadius(0.165)
			else
				LibDBIconStub:SetButtonRadius(1)
			end

			----------------------------------------------------------------------
			-- Button test mode
			----------------------------------------------------------------------

			-- Create a ton of minimap buttons for test purposes
			local useMinimapButtonTestMode = false
			if useMinimapButtonTestMode then
				local numberOfTestButtons = 50
				local miniTable = {}
				for i = 1, numberOfTestButtons do
					miniTable[i] = LibStub("LibDataBroker-1.1"):NewDataObject("Leatrix_Plus" .. i, {
						type = "data source",
						text = "Test Addon " .. i,
						icon = "Interface\\HELPFRAME\\ReportLagIcon-Movement",
						OnClick = function(self, btn)
							LeaPlusGlobalMiniBtnClickFunc(btn)
						end,
						OnTooltipShow = function(tooltip)
							if not tooltip or not tooltip.AddLine then return end
							tooltip:AddLine("Test Addon " .. i)
						end,
					})
					miniTable[i].minimapPos = i * 50
				end
				for i = 1, numberOfTestButtons do
					LibStub("LibDBIcon-1.0", true):Register("Leatrix_Plus" .. i, miniTable[i], miniTable[i])
				end
			end

			----------------------------------------------------------------------
			-- Configuration panel
			----------------------------------------------------------------------

			-- Create configuration panel
			local SideMinimap = LeaPlusLC:CreatePanel("Enhance minimap", "SideMinimap")

			-- Add checkboxes
			LeaPlusLC:MakeTx(SideMinimap, "Settings", 16, -72)
			LeaPlusLC:MakeCB(SideMinimap, "HideMiniAddonButtons", "Hide addon buttons", 16, -92, false, "If checked, addon buttons will be hidden while the pointer is not over the minimap.")
			LeaPlusLC:MakeCB(SideMinimap, "MinimapButtonBag", "Minimap button bag", 16, -112, true, "If checked, minimap buttons for addons will be collected and placed in a bag which you can toggle by right-clicking the minimap.|n|nThis setting will help you declutter the minimap without the need to install a separate addon to do that.")
			LeaPlusLC:MakeCB(SideMinimap, "SquareMinimap", "Square minimap", 16, -132, true, "If checked, the minimap shape will be square.|n|nMinimap rotation (a setting in Edit Mode) is not recommended with a square minimap.")
			LeaPlusLC:MakeCB(SideMinimap, "HideMiniAddonMenu", "Hide addon menu", 16, -152, true, "If checked, the addon menu will be hidden.|n|nThe addon menu appears as a number in the corner of the minimap if you have any addons installed which make use of it.")
			LeaPlusLC:MakeCB(SideMinimap, "UnclampMinimap", "Unclamp minimap cluster", 16, -172, true, "If checked, you will be able to drag the minimap cluster to the edge of the screen using Edit Mode.|n|nWhile positioning the minimap with Edit Mode, you may need to disable Snap to position the minimap precisely.")

			-- Add excluded button
			local MiniExcludedButton = LeaPlusLC:CreateButton("MiniExcludedButton", SideMinimap, "Buttons", "TOPLEFT", 16, -72, 0, 25, true, "Click to toggle the addon buttons editor.")
			LeaPlusCB["MiniExcludedButton"]:ClearAllPoints()
			LeaPlusCB["MiniExcludedButton"]:SetPoint("LEFT", SideMinimap.r, "RIGHT", 10, 0)

			-- Set exclude button visibility
			local function SetExcludeButtonsFunc()
				if LeaPlusLC["HideMiniAddonButtons"] == "On" or LeaPlusLC["MinimapButtonBag"] == "On" then
					LeaPlusLC:LockItem(LeaPlusCB["MiniExcludedButton"], false)
				else
					LeaPlusLC:LockItem(LeaPlusCB["MiniExcludedButton"], true)
				end
			end
			LeaPlusCB["HideMiniAddonButtons"]:HookScript("OnClick", SetExcludeButtonsFunc)
			SetExcludeButtonsFunc()

			-- Add effects dropdown
			LeaPlusLC:CreateDropdown("MinimapEffect", "Visual effect", 150, "TOPLEFT", SideMinimap, "TOPLEFT", 356, -92, false, {{L["None"], 1}, {L["Arcane"], 2}, {L["Rune"], 3}, {L["Vortex"], 4}, {L["Inferno"], 5}, {L["Snow"], 6}, {L["Storm"], 7}, {L["Corona"], 8}, {L["Aurora"], 9}, {L["Starfield"], 10}, {L["Chronometer"], 11}, {L["Heartbeat"], 12}, {L["Fireworks"], 13}, {L["Crystals"], 14}, {L["Neon"], 15}, {L["Marquee"], 16}, {L["Glitch"], 17}, {L["Lava"], 18}, {L["Fuse"], 19}, {L["Rain"], 20}, {L["Prism"], 21}, {L["Candy"], 22}, {L["Rainbow"], 23}, {L["Fireflies"], 24}, {L["Synthwave"], 25}, {L["Collider"], 26}, {L["Bubbles"], 27}, {L["Acid"], 28}, {L["Shadow"], 29}, {L["Radar"], 30}, {L["Tesla"], 31}, {L["Meteor"], 32}, {L["Tube"], 33}})

			LeaPlusLC:MakeTx(SideMinimap, "Border width", 356, -142)
			LeaPlusLC:MakeSL(SideMinimap, "MinimapBorderWidth", "Drag to set the square minimap border width.", 1, 10, 1, 356, -152, "%.0f")

			LeaPlusLC:MakeTx(SideMinimap, "Cluster scale", 356, -192)
			LeaPlusLC:MakeSL(SideMinimap, "MiniClusterScale", "Drag to set the cluster scale.", 0.5, 2, 0.1, 356, -202, "%.2f")

			----------------------------------------------------------------------
			-- Hide addon menu
			----------------------------------------------------------------------

			if LeaPlusLC["HideMiniAddonMenu"] == "On" then

				-- Hide compartment menu when it is shown and on startup
				AddonCompartmentFrame:HookScript("OnShow", AddonCompartmentFrame.Hide)
				AddonCompartmentFrame:Hide()

			end

			----------------------------------------------------------------------
			-- Unclamp minimap cluster
			----------------------------------------------------------------------

			if LeaPlusLC["UnclampMinimap"] == "On" then
				MinimapCluster:SetClampedToScreen(false)
			end

			----------------------------------------------------------------------
			-- Addon buttons editor
			----------------------------------------------------------------------

			do

				-- Create configuration panel
				local ExcludedButtonsPanel = LeaPlusLC:CreatePanel("Enhance minimap", "ExcludedButtonsPanel")
				local boxWidth = 272

				-- Add second excluded button
				local MiniExcludedButton2 = LeaPlusLC:CreateButton("MiniExcludedButton2", ExcludedButtonsPanel, "Buttons", "TOPLEFT", 16, -72, 0, 25, true, "Click to toggle the addon buttons editor.")
				LeaPlusCB["MiniExcludedButton2"]:ClearAllPoints()
				LeaPlusCB["MiniExcludedButton2"]:SetPoint("LEFT", ExcludedButtonsPanel.r, "RIGHT", 10, 0)
				LeaPlusCB["MiniExcludedButton2"]:SetScript("OnClick", function()
					ExcludedButtonsPanel:Hide(); SideMinimap:Show()
					return
				end)

				-- Add large editbox
				local titleTX = LeaPlusLC:MakeTx(ExcludedButtonsPanel, "Editor", 16, -72)
				titleTX:SetWidth(boxWidth - 14) -- 534
				titleTX:SetWordWrap(false)
				titleTX:SetJustifyH("LEFT")

				-- Add help button
				LeaPlusLC:CreateHelpButton("MinimapButtonsAvailableHelpButton", ExcludedButtonsPanel, titleTX, "If you use the 'Hide addon buttons' or 'Minimap button bag' settings but you want some addon buttons to remain visible around the minimap, enter the button names into the editbox below separated by commas.|n|nChanges will require a UI reload to take effect.")

				local eb = CreateFrame("Frame", nil, ExcludedButtonsPanel, "BackdropTemplate")
				eb:SetSize(boxWidth, LeaPlusLC.MainPanelHeight - 180) -- 548
				eb:SetPoint("TOPLEFT", 10, -92)
				eb:SetBackdrop({
					bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
					edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight",
					edgeSize = 16,
					insets = { left = 8, right = 6, top = 8, bottom = 8 },
				})
				eb:SetBackdropBorderColor(1.0, 0.85, 0.0, 0.5)

				eb.scroll = CreateFrame("ScrollFrame", nil, eb, "LeaPlusEnhanceMinimapExcludeButtonsScrollFrameTemplate")
				eb.scroll:SetPoint("TOPLEFT", eb, 12, -10)
				eb.scroll:SetPoint("BOTTOMRIGHT", eb, -30, 10)
				eb.scroll:SetPanExtent(16)

				-- Create character count
				eb.scroll.CharCount = eb.scroll:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
				eb.scroll.CharCount:Hide()

				eb.Text = eb.scroll.EditBox
				eb.Text:SetWidth(boxWidth - 54) -- 494
				eb.Text:SetHeight(230)
				eb.Text:SetPoint("TOPLEFT", eb.scroll)
				eb.Text:SetPoint("BOTTOMRIGHT", eb.scroll, -12, 0)
				eb.Text:SetMaxLetters(1200)
				eb.Text:SetFontObject(GameFontNormalLarge)
				eb.Text:SetAutoFocus(false)
				eb.scroll:SetScrollChild(eb.Text)

				-- Set focus on the editbox text when clicking the editbox
				eb:SetScript("OnMouseDown", function()
					eb.Text:SetFocus()
					eb.Text:SetCursorPosition(eb.Text:GetMaxLetters())
				end)

				-- Debug
				-- eb.Text:SetText("Leatrix_Plus\nLeatrix_Maps\nBugSack\nLeatrix_Plus\nLeatrix_Maps\nBugSack\nLeatrix_Plus\nLeatrix_Maps\nBugSack\nLeatrix_Plus\nLeatrix_Maps\nBugSack\nLeatrix_Plus\nLeatrix_Maps\nBugSack")

				-- Function to save the excluded list
				local function SaveString(self, userInput)
					local keytext = eb.Text:GetText()
					if keytext and keytext ~= "" then
						LeaPlusLC["MiniExcludeList"] = strtrim(eb.Text:GetText())
					else
						LeaPlusLC["MiniExcludeList"] = ""
					end
					if userInput then
						LeaPlusLC:ReloadCheck()
					end
				end

				-- Save the excluded list when it changes and at startup
				eb.Text:SetScript("OnTextChanged", SaveString)
				eb.Text:SetText(LeaPlusLC["MiniExcludeList"])
				SaveString()

				-- Add large editbox for available addons
				local titleAbTX = LeaPlusLC:MakeTx(ExcludedButtonsPanel, "Available button names", boxWidth + 20, -72)
				titleAbTX:SetWidth(boxWidth - 14)
				titleAbTX:SetWordWrap(false)
				titleAbTX:SetJustifyH("LEFT")

				-- Add help button
				LeaPlusLC:CreateHelpButton("MinimapButtonsAvailableHelpButton", ExcludedButtonsPanel, titleAbTX, "This is a list of available addon button names.  You can use this list to copy and paste button names that you want into the editor.|n|nThis listing is automatically generated and cannot be edited.")

				local ab = CreateFrame("Frame", nil, ExcludedButtonsPanel, "BackdropTemplate")
				ab:SetSize(boxWidth, LeaPlusLC.MainPanelHeight - 180) -- 548
				ab:SetPoint("TOPLEFT", 286, -92)
				ab:SetBackdrop({
					bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
					edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight",
					edgeSize = 16,
					insets = { left = 8, right = 6, top = 8, bottom = 8 },
				})
				ab:SetBackdropBorderColor(1.0, 0.85, 0.0, 0.5)
				ab:SetBackdropColor(0, 0, 0, 0.5)

				ab.scroll = CreateFrame("ScrollFrame", nil, ab, "LeaPlusEnhanceMinimapExcludeButtonsScrollFrameTemplate")
				ab.scroll:SetPoint("TOPLEFT", ab, 12, -10)
				ab.scroll:SetPoint("BOTTOMRIGHT", ab, -30, 10)
				ab.scroll:SetPanExtent(16)

				-- Create character count
				ab.scroll.CharCount = ab.scroll:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
				ab.scroll.CharCount:Hide()

				ab.Text = ab.scroll.EditBox
				ab.Text:SetWidth(boxWidth - 54) -- 494
				ab.Text:SetHeight(230)
				ab.Text:SetPoint("TOPLEFT", ab.scroll)
				ab.Text:SetPoint("BOTTOMRIGHT", ab.scroll, -12, 0)
				ab.Text:SetMaxLetters(1200)
				ab.Text:SetFontObject(GameFontNormalLarge)
				ab.Text:SetAutoFocus(false)
				ab.scroll:SetScrollChild(ab.Text)

				-- Set focus on the editbox text when clicking the editbox
				ab:SetScript("OnMouseDown", function()
					ab.Text:SetFocus()
					ab.Text:SetCursorPosition(ab.Text:GetMaxLetters())
				end)

				-- Function to make string with list of buttons
				local function MakeAddonString()
					local msg = ""
					local numAddons = C_AddOns.GetNumAddOns()
					local buttons = LibDBIconStub:GetButtonList()
					table.sort(buttons)
					for i = 1, #buttons do
						local button = LibDBIconStub:GetMinimapButton(buttons[i])
						local buttonName = buttons[i]
						msg = msg .. buttonName .. ",|n|n"
					end
					if msg ~= "" then
					else
						msg = L["No supported addons."]
					end
					ab.Text:SetText(msg)
				end

				ab.Text:HookScript("OnShow", MakeAddonString)
				ab.Text:HookScript("OnTextChanged", function(self, userInput)
					if userInput then MakeAddonString() end
				end)

				-- Hide help button
				ExcludedButtonsPanel.h:Hide()

				-- Back button handler
				ExcludedButtonsPanel.b:SetScript("OnClick", function()
					ExcludedButtonsPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page5"]:Show()
					return
				end)

				-- Reset button handler
				ExcludedButtonsPanel.r:SetScript("OnClick", function()

					-- Reset controls
					LeaPlusLC["MiniExcludeList"] = ""
					eb.Text:SetText(LeaPlusLC["MiniExcludeList"])

					-- Refresh configuration panel
					ExcludedButtonsPanel:Hide(); ExcludedButtonsPanel:Show()
					LeaPlusLC:ReloadCheck()

				end)

				-- Show configuration panal when options panel button is clicked
				LeaPlusCB["MiniExcludedButton"]:SetScript("OnClick", function()
					if IsShiftKeyDown() and IsControlKeyDown() then
						-- Preset profile
						LeaPlusLC["MiniExcludeList"] = "BugSack, Leatrix_Plus"
						LeaPlusLC:ReloadCheck()
					else
						ExcludedButtonsPanel:Show()
						SideMinimap:Hide()
					end
				end)

			end

			----------------------------------------------------------------------
			-- Minimap cluster scale
			----------------------------------------------------------------------

			-- Function to set the minimap cluster scale
			local function SetClusterScale()
				MinimapCluster:SetScale(LeaPlusLC["MiniClusterScale"])
				-- Set slider formatted text
				LeaPlusCB["MiniClusterScale"].f:SetFormattedText("%.0f%%", LeaPlusLC["MiniClusterScale"] * 100)
			end

			-- Set minimap scale when slider is changed and on startup
			LeaPlusCB["MiniClusterScale"]:HookScript("OnValueChanged", SetClusterScale)
			SetClusterScale()

			----------------------------------------------------------------------
			-- Minimap effects
			----------------------------------------------------------------------

			do

				local square = LeaPlusLC["SquareMinimap"] == "On"
				local TAU = math.pi * 2
				local sin, cos, abs, max, floor, atan2 = math.sin, math.cos, math.abs, math.max, math.floor, math.atan2
				local DOT = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"
				local WHITE = "Interface\\Buttons\\WHITE8X8"

				-- Function to get a point at angle a (0 is right, anticlockwise) on the minimap edge, d pixels outside it
				local function EdgeAt(a, d)
					local half = Minimap:GetWidth() / 2 + (d or 0)
					local x, y = cos(a), sin(a)
					if square then
						local m = max(abs(x), abs(y))
						return x / m * half, y / m * half
					end
					return x * half, y * half
				end

				-- Function to get a point at position t (0 to 1, evenly spaced around the edge) on the minimap edge, d pixels outside it
				local function EdgeT(t, d)
					local half = Minimap:GetWidth() / 2 + (d or 0)
					t = t % 1
					if not square then
						return cos(t * TAU) * half, sin(t * TAU) * half
					end
					local s = (t * 4 + 0.5) % 4
					local side = floor(s)
					local p = (s - side) * 2 - 1
					if side == 0 then return half, p * half
					elseif side == 1 then return -p * half, half
					elseif side == 2 then return -half, -p * half
					else return p * half, -half end
				end

				-- Function to create a texture
				local function Tex(parent, file, layer, sub, r, g, b, a)
					local t = parent:CreateTexture(nil, layer or "ARTWORK", nil, sub or 0)
					t:SetTexture(file)
					t:SetBlendMode("ADD")
					t:SetVertexColor(r or 1, g or 1, b or 1, a or 1)
					return t
				end

				-- Function to create a glow around the minimap edge
				local function MakeGlow(parent, size, r, g, b, a, spread)
					local p = {}
					if not square then
						spread = spread or 0.15
						for k = 1, 6 do
							local t = Tex(parent, DOT, "BACKGROUND", 0, r, g, b, a * 0.3)
							t:SetPoint("CENTER")
							p[k] = t
						end
						p.Layout = function()
							local w = Minimap:GetWidth()
							for k = 1, 6 do local s = w * (1 + spread * k / 6); p[k]:SetSize(s, s) end
						end
					else
						local c = 16 * size
						local function Piece(file, l, rr, tt, bb) local t = Tex(parent, "Interface\\Common\\" .. file, "BACKGROUND", 0, r, g, b, a); t:SetTexCoord(l, rr, tt, bb); return t end
						local tl = Piece("GlowBorder-Corner", 0, 1, 0, 1); tl:SetSize(c, c); tl:SetPoint("TOPLEFT", -c / 2, c / 2)
						local tr = Piece("GlowBorder-Corner", 1, 0, 0, 1); tr:SetSize(c, c); tr:SetPoint("TOPRIGHT", c / 2, c / 2)
						local bl = Piece("GlowBorder-Corner", 0, 1, 1, 0); bl:SetSize(c, c); bl:SetPoint("BOTTOMLEFT", -c / 2, -c / 2)
						local br = Piece("GlowBorder-Corner", 1, 0, 1, 0); br:SetSize(c, c); br:SetPoint("BOTTOMRIGHT", c / 2, -c / 2)
						local top = Piece("GlowBorder-Top", 0, 1, 0, 1); top:SetPoint("TOPLEFT", tl, "TOPRIGHT"); top:SetPoint("BOTTOMRIGHT", tr, "BOTTOMLEFT")
						local bottom = Piece("GlowBorder-Top", 0, 1, 1, 0); bottom:SetPoint("TOPLEFT", bl, "TOPRIGHT"); bottom:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT")
						local left = Piece("GlowBorder-Left", 0, 1, 0, 1); left:SetPoint("TOPLEFT", tl, "BOTTOMLEFT"); left:SetPoint("BOTTOMRIGHT", bl, "TOPRIGHT")
						local right = Piece("GlowBorder-Left", 1, 0, 0, 1); right:SetPoint("TOPLEFT", tr, "BOTTOMLEFT"); right:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT")
						-- Pieces in order around the edge (used for colour flow)
						p = {right, tr, top, tl, left, bl, bottom, br}
					end
					return p
				end

				-- Function to create an animation group (added to the effect so it starts and stops with it)
				local function Group(e, region, looping)
					local ag = region:CreateAnimationGroup()
					ag:SetLooping(looping or "REPEAT")
					tinsert(e.groups, ag)
					return ag
				end

				-- Function to create an animation
				local function Anim(ag, kind, duration, order, delay)
					local an = ag:CreateAnimation(kind)
					an:SetDuration(duration)
					an:SetOrder(order or 1)
					if delay then an:SetStartDelay(delay) end
					return an
				end

				-- Function to convert a hue (0 to 1) to a soft colour
				local function Hue(h)
					h = (h % 1) * 6
					local i, f = floor(h), h - floor(h)
					local r, g, b
					if i == 0 then r, g, b = 1, f, 0 elseif i == 1 then r, g, b = 1 - f, 1, 0 elseif i == 2 then r, g, b = 0, 1, f
					elseif i == 3 then r, g, b = 0, 1 - f, 1 elseif i == 4 then r, g, b = f, 0, 1 else r, g, b = 1, 0, 1 - f end
					return 0.3 + 0.7 * r, 0.3 + 0.7 * g, 0.3 + 0.7 * b
				end

				-- Function to get the outward direction (angle) at position t on the edge
				local function EdgeNormal(t)
					if not square then return (t % 1) * TAU end
					local x, y = EdgeT(t, 0)
					if abs(abs(x) - abs(y)) < 3 then return atan2(y, x) end -- Corner
					if abs(x) > abs(y) then return x > 0 and 0 or math.pi end
					return y > 0 and TAU / 4 or -TAU / 4
				end

				-- Helpers passed to each effect
				local helpers = {square = square, Tex = Tex, Anim = Anim, Group = Group, MakeGlow = MakeGlow, EdgeAt = EdgeAt, EdgeT = EdgeT, EdgeNormal = EdgeNormal, Hue = Hue}

				-- Function to get an effect (the effects are only loaded the first time an effect other than None is selected)
				local effects, effectList
				local function GetEffect(index)
					if index == 1 then return end -- None
					if not effectList then
						effectList = Leatrix_Plus.LoadMinimapEffects()
						effects = {}
					end
					if not effects[index] and effectList[index] then
						local e = {groups = {}, build = effectList[index], gen = 0}
						-- Front layer (above the minimap) and back layer (behind the minimap)
						e.frame = CreateFrame("Frame", nil, Minimap); e.frame:SetAllPoints(); e.frame:SetFrameLevel(Minimap:GetFrameLevel() + 2); e.frame:Hide()
						e.back = CreateFrame("Frame", nil, Minimap); e.back:SetAllPoints(); e.back:SetFrameLevel(max(Minimap:GetFrameLevel() - 1, 0)); e.back:Hide()
						effects[index] = e
					end
					return effects[index]
				end

				-- Function to start an effect (built the first time it is selected)
				local function StartEffect(e)
					if not e.built then e.build(e, helpers); e.built = true end
					if e.Layout then e.Layout() end
					e.frame:Show(); e.back:Show()
					for i = 1, #e.groups do e.groups[i]:Play() end
					if e.OnStart then e.OnStart() end
				end

				-- Function to stop an effect
				local function StopEffect(e)
					e.gen = e.gen + 1
					if e.OnStop then e.OnStop() end
					for i = 1, #e.groups do e.groups[i]:Stop() end
					e.frame:Hide(); e.back:Hide()
				end

				-- Function to show the selected effect (does nothing if the selected effect is already showing)
				local current, currentIndex = nil, 1
				local function SetMinimapEffect()
					local index = LeaPlusLC["MinimapEffect"]
					if index == currentIndex then return end
					currentIndex = index
					if current then StopEffect(current); current = nil end
					local e = GetEffect(index)
					if e then StartEffect(e); current = e end
				end

				-- Set effect when the dropdown menu is closed and on startup
				LeaPlusCB["MinimapEffect"]:RegisterCallback("OnMenuClose", SetMinimapEffect)
				SetMinimapEffect()

				-- Rebuild the effect positions if the minimap size changes
				Minimap:HookScript("OnSizeChanged", function()
					if current then StopEffect(current); StartEffect(current) end
				end)

				-- Assign file level scope (used in reset)
				LeaPlusLC.SetMinimapEffect = SetMinimapEffect

			end

			----------------------------------------------------------------------
			-- Minimap button bag
			----------------------------------------------------------------------

			if LeaPlusLC["MinimapButtonBag"] == "On" then

				-- Lock out hide minimap buttons
				LeaPlusLC:LockItem(LeaPlusCB["HideMiniAddonButtons"], true)
				LeaPlusCB["HideMiniAddonButtons"].tiptext = LeaPlusCB["HideMiniAddonButtons"].tiptext .. "|n|n|cff00AAFF" .. L["Cannot be used with Minimap button bag."]

				-- Create button frame
				local bFrame = CreateFrame("FRAME", nil, UIParent)
				bFrame:ClearAllPoints()
				bFrame:SetPoint("TOPLEFT", Minimap, "TOPRIGHT", 4, 4)
				bFrame:SetClampedToScreen(true)
				bFrame:Hide()

				-- Set top level to ensure button frame shows on top of frames such as the main action bar
				bFrame:SetToplevel(true)

				-- Set button frame scale to match minimap cluster scale
				bFrame:SetScale(MinimapCluster:GetScale())
				MinimapCluster:HookScript("OnSizeChanged", function()
					bFrame:SetScale(MinimapCluster:GetScale())
				end)

				LeaPlusLC.bFrame = bFrame -- Used in LibDBIcon callback
				_G["LeaPlusGlobalMinimapCombinedButtonFrame"] = bFrame -- For third party addons

				-- Hide button frame automatically
				local ButtonFrameTicker
				bFrame:HookScript("OnShow", function()
					if ButtonFrameTicker then ButtonFrameTicker:Cancel() end
					ButtonFrameTicker = C_Timer.NewTicker(2, function()
						if not bFrame:IsMouseOver() and not Minimap:IsMouseOver() then
							bFrame:Hide()
							if ButtonFrameTicker then ButtonFrameTicker:Cancel() end
						end
					end, 15)
				end)

				-- Position LibDBIcon tooltips when shown
				LibDBIconTooltip:HookScript("OnShow", function()
					GameTooltip:Hide()
					LibDBIconTooltip:ClearAllPoints()
					if bFrame:GetPoint() == "BOTTOMLEFT" then
						LibDBIconTooltip:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", 0, -6)
					else
						LibDBIconTooltip:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -6)
					end
				end)

				-- Function to position GameTooltip below the minimap
				local function SetButtonTooltip()
					GameTooltip:ClearAllPoints()
					if bFrame:GetPoint() == "BOTTOMLEFT" then
						GameTooltip:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", 0, -6)
					else
						GameTooltip:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -6)
					end
				end

				LeaPlusLC.SetButtonTooltip = SetButtonTooltip -- Used in LibDBIcon callback

				-- Hide existing LibDBIcon icons
				local buttons = LibDBIconStub:GetButtonList()
				for i = 1, #buttons do
					local button = LibDBIconStub:GetMinimapButton(buttons[i])
					local buttonName = strlower(buttons[i])
					if not strfind(strlower(LeaPlusDB["MiniExcludeList"]), buttonName) then
						button:Hide()
						button:SetScript("OnShow", function() if not bFrame:IsShown() then button:Hide() end end)
						-- Create background texture
						local bFrameBg = button:CreateTexture(nil, "BACKGROUND")
						bFrameBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
						bFrameBg:SetPoint("CENTER")
						bFrameBg:SetSize(30, 30)
						bFrameBg:SetVertexColor(0, 0, 0, 0.5)
					end
					-- Move GameTooltip to below the minimap in case the button uses it
					button:HookScript("OnEnter", SetButtonTooltip)
					-- Special case for MoveAny because it doesn't have button.db
					if buttonName == "moveany" then
						button.db = button.db or {}
						if not button.db.hide then button.db.hide = false end
					end
				end

				-- Hide new LibDBIcon icons
				-- LibDBIcon_IconCreated: Done in LibDBIcon callback function

				-- Create minimap button bag frame
				local mbtn = CreateFrame("Frame", nil, Minimap)
				mbtn:ClearAllPoints()
				mbtn:SetAllPoints()
				mbtn:EnableMouse(true)
				mbtn:SetPassThroughButtons("LeftButton", "MiddleButton")
				mbtn:SetPropagateMouseMotion(true)
				mbtn:Show()

				-- Toggle button frame
				mbtn:SetScript("OnMouseUp", function(frame, button)
					if button == "LeftButton" or button == "RightButton" then
						if bFrame:IsShown() then
							bFrame:Hide()
						else bFrame:Show()
							-- Position button frame
							local side
							local m = Minimap:GetCenter()
							local b = Minimap:GetEffectiveScale()
							local w = GetScreenWidth()
							local s = UIParent:GetEffectiveScale()
							bFrame:ClearAllPoints()
							if m * b > (w * s / 2) then
								side = "Right"
								bFrame:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMLEFT", -10, -0)
							else
								side = "Left"
								bFrame:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMRIGHT", 10, 0)
							end
							-- Show button frame
							local x, y, row, col = 0, 0, 0, 0
							local buttons = LibDBIconStub:GetButtonList()
							-- Sort the button table
							table.sort(buttons, function(a, b)
								if string.find(a, "LeaPlusCustomIcon_") then
									a = string.gsub(a, "LeaPlusCustomIcon_", "")
								end
								if string.find(b, "LeaPlusCustomIcon_") then
									b = string.gsub(b, "LeaPlusCustomIcon_", "")
								end
								return a:lower() < b:lower()
							end)
							-- Calculate buttons per row
							local buttonsPerRow
							local totalButtons = #buttons
								if totalButtons > 36 then buttonsPerRow = 10
							elseif totalButtons > 32 then buttonsPerRow = 9
							elseif totalButtons > 28 then buttonsPerRow = 8
							elseif totalButtons > 24 then buttonsPerRow = 7
							elseif totalButtons > 20 then buttonsPerRow = 6
							elseif totalButtons > 16 then buttonsPerRow = 5
							elseif totalButtons > 12 then buttonsPerRow = 4
							elseif totalButtons > 8 then buttonsPerRow = 3
							elseif totalButtons > 4 then buttonsPerRow = 2
							else
								buttonsPerRow = 1
							end
							-- Build button grid
							for i = 1, totalButtons do
								local buttonName = strlower(buttons[i])
								if not strfind(strlower(LeaPlusDB["MiniExcludeList"]), buttonName) then
									local button = LibDBIconStub:GetMinimapButton(buttons[i])
									if button.db then
										if buttonName == "armory" then button.db.hide = false end -- Armory addon sets hidden to true
										if not button.db.hide then
											button:SetParent(bFrame)
											button:ClearAllPoints()
											if side == "Left" then
												-- Minimap is on left side of screen
												button:SetPoint("TOPLEFT", bFrame, "TOPLEFT", x, y)
												col = col + 1; if col >= buttonsPerRow then col = 0; row = row + 1; x = 0; y = y - 30 else x = x + 30 end
											else
												-- Minimap is on right side of screen (changed from TOPRIGHT to TOPLEFT and x - 30 to x + 30 to make sorting work)
												button:SetPoint("TOPLEFT", bFrame, "TOPLEFT", x, y)
												col = col + 1; if col >= buttonsPerRow then col = 0; row = row + 1; x = 0; y = y - 30 else x = x + 30 end
											end
											if totalButtons <= buttonsPerRow then
												bFrame:SetWidth(totalButtons * 30)
											else
												bFrame:SetWidth(buttonsPerRow * 30)
											end
											local void, void, void, void, e = button:GetPoint()
											bFrame:SetHeight(0 - e + 30)
											LibDBIconStub:Show(buttons[i])
										end
									end
								end
							end
						end
					end
				end)

			end

			----------------------------------------------------------------------
			-- Square minimap
			----------------------------------------------------------------------

			if LeaPlusLC["SquareMinimap"] == "On" then

				-- Set button layout
				AddonCompartmentFrame:SetFrameLevel(4)

				-- Debug
				-- AddonCompartmentFrame:SetText("56")

				-- Create black border around map
				local miniBorder = CreateFrame("Frame", nil, Minimap, "BackdropTemplate")
				miniBorder:SetAlpha(1)

				-- Adjust border width using slider control
				local function SetMinimapBorderWidth()
					miniBorder:ClearAllPoints()
					miniBorder:SetPoint("TOPLEFT", -LeaPlusLC["MinimapBorderWidth"], LeaPlusLC["MinimapBorderWidth"])
					miniBorder:SetPoint("BOTTOMRIGHT", LeaPlusLC["MinimapBorderWidth"], -LeaPlusLC["MinimapBorderWidth"])
					miniBorder:SetBackdrop({
						edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
						edgeSize = LeaPlusLC["MinimapBorderWidth"],
					})
				end

				-- Set border width when slider is changed and on startup
				LeaPlusCB["MinimapBorderWidth"]:HookScript("OnValueChanged", SetMinimapBorderWidth)
				SetMinimapBorderWidth()

				-- Set minimap position (local setting = MinimapCluster:GetSettingValueBool(Enum.EditModeMinimapSetting.HeaderUnderneath))
				Minimap:ClearAllPoints()
				Minimap:SetPoint("CENTER", MinimapCluster, "TOP", 14, -124)

				-- Hide the default compass border
				MinimapCompassTexture:Hide()

				-- Mask texture
				Minimap:SetMaskTexture('Interface\\ChatFrame\\ChatFrameBackground')

				-- Keep the square look (rotation, FarmHud and other addons can change the mask or show the rings)
				local SQUARE_MASK = "Interface\\ChatFrame\\ChatFrameBackground"
				local applyingMask = false

				-- Hide the compass rings and apply the square mask
				local function ApplySquareLook()
					MinimapCompassTexture:Hide()
					if MinimapCompassTextureUnderlay then MinimapCompassTextureUnderlay:Hide() end
					applyingMask = true
					Minimap:SetMaskTexture(SQUARE_MASK)
					applyingMask = false
				end

				-- Apply the square look now and again after Blizzard's own code has finished running
				local function ReapplySquare()
					ApplySquareLook()
					C_Timer.After(0, ApplySquareLook)
				end

				-- Put the square mask back if anything changes it
				hooksecurefunc(Minimap, "SetMaskTexture", function()
					if not applyingMask then ApplySquareLook() end
				end)

				-- Keep the rings hidden if anything shows them
				hooksecurefunc(MinimapCompassTexture, "Show", ApplySquareLook)
				if MinimapCompassTextureUnderlay then
					hooksecurefunc(MinimapCompassTextureUnderlay, "Show", ApplySquareLook)
				end

				-- Reapply the square look on loading screens and when minimap rotation is toggled
				local squareWatcher = CreateFrame("Frame")
				squareWatcher:RegisterEvent("CVAR_UPDATE")
				squareWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
				squareWatcher:SetScript("OnEvent", function(self, event, cvar)
					if event == "PLAYER_ENTERING_WORLD" or (cvar and strlower(cvar) == "rotateminimap") then
						ReapplySquare()
					end
				end)
				ReapplySquare()

				-- Fix textures
				Minimap:SetArchBlobRingScalar(0)
				Minimap:SetArchBlobRingAlpha(0)
				Minimap:SetQuestBlobRingScalar(0)
				Minimap:SetQuestBlobRingAlpha(0)

				-- Mail indicator (move it into the top-left corner of the square minimap)
				local function SetIndicatorPosition()
					local indicator = MinimapCluster.IndicatorFrame
					indicator:SetScale(0.75)
					miniFrame.ClearAllPoints(indicator)
					indicator:SetPoint("CENTER", Minimap, "TOPLEFT", 0, -10)
					indicator:SetFrameLevel(Minimap:GetFrameLevel() + 5)
				end
				SetIndicatorPosition()
				hooksecurefunc(MinimapCluster, "SetHeaderUnderneath", SetIndicatorPosition)
				hooksecurefunc("MiniMapIndicatorFrame_UpdatePosition", SetIndicatorPosition)

				-- Zoom in button
				miniFrame.ClearAllPoints(Minimap.ZoomIn)
				Minimap.ZoomIn:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 0, 0)

				miniFrame.ClearAllPoints(Minimap.ZoomOut)
				Minimap.ZoomOut:SetPoint("RIGHT", Minimap.ZoomIn, "LEFT", -6, 0)

				-- Expansion button
				ExpansionLandingPageMinimapButton.border = ExpansionLandingPageMinimapButton:CreateTexture(nil, "OVERLAY")
				ExpansionLandingPageMinimapButton.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
				ExpansionLandingPageMinimapButton.border:SetSize(52, 52)
				ExpansionLandingPageMinimapButton.border:SetPoint("TOPLEFT", 0, 0)

				ExpansionLandingPageMinimapButton.background = ExpansionLandingPageMinimapButton:CreateTexture(nil, "BACKGROUND")
				ExpansionLandingPageMinimapButton.background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
				ExpansionLandingPageMinimapButton.background:SetAllPoints()
				ExpansionLandingPageMinimapButton:SetHitRectInsets(-0.2, 0.2, 0, 0)

				miniFrame.SetSize(ExpansionLandingPageMinimapButton, 30, 30)
				hooksecurefunc(ExpansionLandingPageMinimapButton, "SetSize", function()
					miniFrame.SetSize(ExpansionLandingPageMinimapButton, 30, 30)
				end)

				-- Set expansion button on startup (needed for Dragonflight button)
				miniFrame.ClearAllPoints(ExpansionLandingPageMinimapButton)
				ExpansionLandingPageMinimapButton:SetPoint("TOPLEFT", MinimapBackdrop, "TOPLEFT", -7, -150)
				ExpansionLandingPageMinimapButton.LoopingGlow:SetAtlas("Mage-ArcaneCharge-CircleGlow", true)

				-- Set expansion button when icon is updated (needed for Shadowlands button)
				hooksecurefunc(ExpansionLandingPageMinimapButton, "UpdateIcon", function()
					miniFrame.ClearAllPoints(ExpansionLandingPageMinimapButton)
					ExpansionLandingPageMinimapButton:SetPoint("TOPLEFT", MinimapBackdrop, "TOPLEFT", -7, -150)
					ExpansionLandingPageMinimapButton.LoopingGlow:SetAtlas("Mage-ArcaneCharge-CircleGlow", true)
				end)

				ExpansionLandingPageMinimapButton.AlertBG:ClearAllPoints()
				ExpansionLandingPageMinimapButton.AlertBG:SetPoint("RIGHT", ExpansionLandingPageMinimapButton, "CENTER", -4, 0)
				ExpansionLandingPageMinimapButton.AlertText:ClearAllPoints()
				ExpansionLandingPageMinimapButton.AlertText:SetPoint("RIGHT", ExpansionLandingPageMinimapButton, "LEFT", -8, 0)
				ExpansionLandingPageMinimapButton:SetHitRectInsets(0, 0, 0, 0)

				-- Setup hybrid minimap when available
				EventUtil.ContinueOnAddOnLoaded("Blizzard_HybridMinimap",function()
					HybridMinimap.MapCanvas:SetUseMaskTexture(false)
					HybridMinimap.CircleMask:SetTexture("Interface\\BUTTONS\\WHITE8X8")
					HybridMinimap.MapCanvas:SetUseMaskTexture(true)
				end)

				-- Hide the day and night indicator
				MinimapCluster.DielFrame:Hide()

			else

				-- Square minimap is disabled so disable border width slider
				LeaPlusLC:LockItem(LeaPlusCB["MinimapBorderWidth"], true)
				LeaPlusCB["MinimapBorderWidth"].tiptext = LeaPlusCB["MinimapBorderWidth"].tiptext .. "|cff00AAFF|n|n" .. L["This slider requires 'Square minimap' to be enabled."] .. "|r"

			end

			----------------------------------------------------------------------
			-- Replace non-standard buttons
			----------------------------------------------------------------------

			-- Replace non-standard buttons for addons that don't use the standard LibDBIcon library
			do

				-- Make LibDBIcon buttons for addons that don't use LibDBIcon
				local CustomAddonTable = {}
				LeaPlusDB["CustomAddonButtons"] = LeaPlusDB["CustomAddonButtons"] or {}

				-- Function to create a LibDBIcon button
				local function CreateBadButton(name)

					-- Get non-standard button texture
					local finalTex = "Interface\\HELPFRAME\\HelpIcon-KnowledgeBase"

					if _G[name .. "Icon"] then
						if _G[name .. "Icon"]:GetObjectType() == "Texture" then
							local gTex = _G[name .. "Icon"]:GetTexture()
							if gTex then
								finalTex = gTex
							end
						end
					else
						for i = 1, select('#', _G[name]:GetRegions()) do
							local region = select(i, _G[name]:GetRegions())
							if region.GetTexture then
								local x, y = region:GetSize()
								if x and x < 30 then
									finalTex = region:GetTexture()
								end
							end
						end
					end

					if not finalTex then finalTex = "Interface\\HELPFRAME\\HelpIcon-KnowledgeBase" end

					-- Function to anchor the tooltip to the custom button or the minimap
					local function ReanchorTooltip(tip, myButton)
						tip:ClearAllPoints()
						if LeaPlusLC["MinimapButtonBag"] == "On" then
							if LeaPlusLC.bFrame and LeaPlusLC.bFrame:GetPoint() == "BOTTOMLEFT" then
								tip:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", 0, -6)
							else
								tip:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -6)
							end
						else
							if Minimap:GetCenter() * Minimap:GetEffectiveScale() > (GetScreenWidth() * UIParent:GetEffectiveScale() / 2) then
								tip:SetPoint("TOPRIGHT", myButton, "BOTTOMRIGHT", 0, -6)
							else
								tip:SetPoint("TOPLEFT", myButton, "BOTTOMLEFT", 0, -6)
							end
						end
					end

					local zeroButton = LibStub("LibDataBroker-1.1"):NewDataObject("LeaPlusCustomIcon_" .. name, {
						type = "data source",
						text = name,
						icon = finalTex,
						OnClick = function(self, btn)
							if _G[name] then
								if string.find(name, "LibDBIcon") then
									-- It's a fake LibDBIcon
									local mouseUp = _G[name]:GetScript("OnMouseUp")
									if mouseUp then
										mouseUp(self, btn)
									end
								else
									-- It's a genuine LibDBIcon
									local clickUp = _G[name]:GetScript("OnClick")
									if clickUp then
										_G[name]:Click(btn)
									end
								end
							end
						end,
					})
					LeaPlusDB["CustomAddonButtons"][name] = LeaPlusDB["CustomAddonButtons"][name] or {}
					LeaPlusDB["CustomAddonButtons"][name].hide = false
					CustomAddonTable[name] = name
					local icon = LibStub("LibDBIcon-1.0", true)
					icon:Register("LeaPlusCustomIcon_" .. name, zeroButton, LeaPlusDB["CustomAddonButtons"][name])
					-- Custom buttons
					if name == "AllTheThings-Minimap" then
						-- AllTheThings
						local myButton = LibStub("LibDBIcon-1.0"):GetMinimapButton("LeaPlusCustomIcon_" .. name)
						myButton.icon:SetTexture("Interface\\AddOns\\AllTheThings\\assets\\logo_tiny")
						myButton:HookScript("OnEnter", function()
							_G[name]:GetScript("OnEnter")(_G[name], true)
							ReanchorTooltip(GameTooltip, myButton)
						end)
						myButton:HookScript("OnLeave", function()
							_G[name]:GetScript("OnLeave")()
						end)
					elseif name == "OOMinimapButton" then
						-- OmniumObservator
						local myButton = LibStub("LibDBIcon-1.0"):GetMinimapButton("LeaPlusCustomIcon_" .. name)
						myButton:HookScript("OnEnter", function()
							_G[name]:GetScript("OnEnter")(_G[name], true)
						end)
						myButton:HookScript("OnLeave", function()
							_G[name]:GetScript("OnLeave")()
						end)
					elseif name == "LibDBIcon10_WoWtility" then
						-- Wowtility
						local myButton = LibStub("LibDBIcon-1.0"):GetMinimapButton("LeaPlusCustomIcon_" .. name)
						myButton.icon:SetTexture("Interface\\AddOns\\WoWtility\\WoWtility.blp")
						myButton:SetScript("OnClick", function(self, btn) LibDBIcon10_WoWtility:Click(btn) end)
						myButton:HookScript("OnEnter", function()
							_G[name]:GetScript("OnEnter")(_G[name], true)
						end)
						myButton:HookScript("OnLeave", function()
							_G[name]:GetScript("OnLeave")()
						end)
					elseif name == "AltoholicMinimapButton" then
						-- Altoholic
						local myButton = LibStub("LibDBIcon-1.0"):GetMinimapButton("LeaPlusCustomIcon_" .. name)
						myButton.icon:SetTexture("Interface\\Icons\\INV_Drink_13")
						myButton:HookScript("OnEnter", function()
							_G[name]:GetScript("OnEnter")(_G[name], true)
							ReanchorTooltip(AddonFactory_Tooltip, myButton)
						end)
						myButton:HookScript("OnLeave", function()
							_G[name]:GetScript("OnLeave")()
						end)
					elseif name == "WIM3MinimapButton" then
						-- WIM
						local myButton = LibStub("LibDBIcon-1.0"):GetMinimapButton("LeaPlusCustomIcon_" .. name)
						myButton:HookScript("OnEnter", function()
							_G[name]:GetScript("OnEnter")(_G[name], true)
							GameTooltip:SetOwner(myButton, "ANCHOR_TOP")
							GameTooltip:AddLine(name)
							GameTooltip:Show()
							ReanchorTooltip(GameTooltip, myButton)
						end)
						myButton:HookScript("OnLeave", function()
							_G["WIM3MinimapButton"]:GetScript("OnLeave")()
							GameTooltip:Hide()
						end)
					elseif name == "ZygorGuidesViewerMapIcon" then
						-- Zygor (uses LibDBIcon10_LeaPlusCustomIcon_ZygorGuidesViewerMapIcon)
						local myButton = LibStub("LibDBIcon-1.0"):GetMinimapButton("LeaPlusCustomIcon_" .. name)
						myButton.icon:SetTexture("Interface\\AddOns\\ZygorGuidesViewer\\Skins\\minimap-icon.tga")
						hooksecurefunc(myButton.icon, "UpdateCoord", function()
							myButton.icon:SetTexCoord(0, 0.5, 0, 0.25)
						end)
						myButton.icon:SetTexCoord(0, 0.5, 0, 0.25)
						myButton:HookScript("OnEnter", function()
							_G[name]:GetScript("OnEnter")(_G[name], true)
							ReanchorTooltip(GameTooltip, myButton)
						end)
						myButton:HookScript("OnLeave", function()
							GameTooltip:Hide()
						end)
						if ZGV_Notification_Entry_Template_Mixin then
							-- Fix notification system entry height
							hooksecurefunc(ZGV_Notification_Entry_Template_Mixin, "UpdateHeight", function(self)
								self:Show()
								local height = 46
								if ZGV and ZGV.db and ZGV.db.profile and ZGV.db.profile.nc_size and ZGV.db.profile.nc_size == 1 then height = 36 end
								height = height + (self.time:IsVisible() and self.time:GetStringHeight()+0 or 0)
								height = height + (self.title:IsVisible() and self.title:GetStringHeight()+3 or 0)
								height = height + (self.text:IsVisible() and self.text:GetStringHeight()+3 or 0)
								height = height + (self.SpecialButton and self.SpecialButton:IsVisible() and self.SpecialButton:GetHeight()+8 or 0)
								if (self.single or self.special) then height = max(height,25) end
								self:SetHeight(height)
								self:Hide()
							end)
						end
					elseif name == "BtWQuestsMinimapButton"				-- BtWQuests
						or name == "TomCats-MinimapButton"				-- TomCat's Tours
						or name == "TomCats-LoveIsInTheAirMinimapButton2023"
						or name == "TomCats-LunarFestivalMinimapButton2023"
						or name == "LibDBIcon10_MethodRaidTools"		-- Method Raid Tools
						or name == "wlMinimapButton"					-- Wowhead Looter (part of Wowhead client)
						or name == "CLN_MinimapButton"					-- Chatty Little NPC
						then
						local myButton = LibStub("LibDBIcon-1.0"):GetMinimapButton("LeaPlusCustomIcon_" .. name)
						myButton:HookScript("OnEnter", function()
							_G[name]:GetScript("OnEnter")(_G[name], true)
							ReanchorTooltip(GameTooltip, myButton)
						end)
						myButton:HookScript("OnLeave", function()
							GameTooltip:Hide()
						end)
					else
						-- Unknown custom buttons
						local myButton = LibStub("LibDBIcon-1.0"):GetMinimapButton("LeaPlusCustomIcon_" .. name)
						myButton:HookScript("OnEnter", function()
							GameTooltip:SetOwner(myButton, "ANCHOR_TOP")
							GameTooltip:AddLine(name)
							GameTooltip:AddLine(L["This is a custom button.  Please ask the addon author to use the standard LibDBIcon library instead."], 1, 1, 1, true)
							GameTooltip:Show()
							ReanchorTooltip(GameTooltip, myButton)
						end)
						myButton:HookScript("OnLeave", function()
							GameTooltip:Hide()
						end)
					end
				end

				-- Create LibDBIcon buttons for these addons that have LibDBIcon prefixes
				local customButtonTable = {
					"LibDBIcon10_MethodRaidTools", -- Method Raid Tools
					"LibDBIcon10_WoWtility", -- Wowtility
				}

				-- Do not create LibDBIcon buttons for these special case buttons
				local BypassButtonTable = {
					"SexyMapZoneTextButton", -- SexyMap
					"Narci_MinimapButton", -- Narcissus
				}

				-- Some buttons have less than 3 regions.  These need to be manually defined below.
				local LowRegionCountButtons = {
					"AllTheThings-Minimap", -- AllTheThings
					"OOMinimapButton", -- OmniumObservator
				}

				-- Function to loop through minimap children to find non-standard addon buttons
				local function MakeButtons()
					local temp = {Minimap:GetChildren()}
					for i = 1, #temp do
						if temp[i] then
							local btn = temp[i]
							local name = btn:GetName()
							local btype = btn:GetObjectType()
							if name and btype == "Button" and not CustomAddonTable[name] and (btn:GetNumRegions() >= 3 or table.contains(LowRegionCountButtons, name)) and not issecurevariable(name) and btn:IsShown() then
								if not strfind(strlower(LeaPlusDB["MiniExcludeList"]), strlower("##" .. name)) then
									if not string.find(name, "LibDBIcon") and not table.contains(BypassButtonTable, name) or table.contains(customButtonTable, name) then
										if not strfind(name, "^QuestieFrame") then -- Don't make buttons for Questie icons
											CreateBadButton(name)
											btn:Hide()
											btn:SetScript("OnShow", function() btn:Hide() end)
										end
									end
								end
							end
						end
					end
				end

				-- Run the function a few times on startup
				C_Timer.NewTicker(2, MakeButtons, 8)
				C_Timer.After(0.1, MakeButtons)

			end

			----------------------------------------------------------------------
			-- Hide addon buttons
			----------------------------------------------------------------------

			if LeaPlusLC["MinimapButtonBag"] == "Off" then

				-- Function to set button state
				local function SetHideButtons()
					if LeaPlusLC["HideMiniAddonButtons"] == "On" then
						-- Hide existing buttons
						local buttons = LibDBIconStub:GetButtonList()
						for i = 1, #buttons do
							local buttonName = strlower(buttons[i])
							if not strfind(strlower(LeaPlusDB["MiniExcludeList"]), buttonName) then
								LibDBIconStub:ShowOnEnter(buttons[i], true)
							end
						end
						-- Hide new buttons
						-- LibDBIcon_IconCreated: Done in LibDBIcon callback function
					else
						-- Show existing buttons
						local buttons = LibDBIconStub:GetButtonList()
						for i = 1, #buttons do
							local buttonName = strlower(buttons[i])
							if not strfind(strlower(LeaPlusDB["MiniExcludeList"]), buttonName) then
								LibDBIconStub:ShowOnEnter(buttons[i], false)
							end
						end
						-- Show new buttons
						-- LibDBIcon_IconCreated: Done in LibDBIcon callback function
					end
				end

				-- Assign file level scope (it's used in reset and preset)
				LeaPlusLC.SetHideButtons = SetHideButtons

				-- Set buttons when option is clicked and on startup
				LeaPlusCB["HideMiniAddonButtons"]:HookScript("OnClick", SetHideButtons)
				SetHideButtons()

			end

			----------------------------------------------------------------------
			-- Buttons
			----------------------------------------------------------------------

			-- Hide help button
			SideMinimap.h:Hide()

			-- Back button handler
			SideMinimap.b:SetScript("OnClick", function()
				SideMinimap:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page5"]:Show()
				return
			end)

			-- Reset button handler
			SideMinimap.r.tiptext = SideMinimap.r.tiptext .. "|n|n" .. L["Note that this will not reset settings that require a UI reload."]
			SideMinimap.r:HookScript("OnClick", function()
				LeaPlusLC["MinimapEffect"] = 1; LeaPlusLC.SetMinimapEffect()
				LeaPlusLC["HideMiniAddonButtons"] = "On"; if LeaPlusLC.SetHideButtons then LeaPlusLC:SetHideButtons() end
				LeaPlusLC["MiniClusterScale"] = 1; SetClusterScale()
				LeaPlusLC["MinimapBorderWidth"] = 3
				-- Refresh panel
				SideMinimap:Hide(); SideMinimap:Show()
			end)

			-- Configuration button handler
			LeaPlusCB["ModMinimapBtn"]:HookScript("OnClick", function()
				if LeaPlusLC:PlayerInCombat() then
					return
				else
					if IsShiftKeyDown() and IsControlKeyDown() then
						-- Preset profile
						LeaPlusLC["MinimapEffect"] = 3; LeaPlusLC.SetMinimapEffect()
						LeaPlusLC["HideMiniAddonButtons"] = "On"; if LeaPlusLC.SetHideButtons then LeaPlusLC:SetHideButtons() end
						LeaPlusLC["HideMiniAddonMenu"] = "On"
						LeaPlusLC["MiniClusterScale"] = 1; SetClusterScale()
						LeaPlusLC["UnclampMinimap"] = "On"
						LeaPlusLC["MinimapBorderWidth"] = 3
						LeaPlusLC:ReloadCheck() -- Special reload check
					else
						-- Show configuration panel
						SideMinimap:Show()
						LeaPlusLC:HideFrames()
					end
				end
			end)

			-- LibDBIcon callback (search LibDBIcon_IconCreated to find calls to this)
			LibDBIconStub.RegisterCallback(miniFrame, "LibDBIcon_IconCreated", function(self, button, name)

				-- Minimap button bag: Hide new LibDBIcon icons
				if LeaPlusLC["MinimapButtonBag"] == "On" then
					--C_Timer.After(0.1, function() -- Removed for now
						local buttonName = strlower(name)

						-- Special case for MoveAny because it doesn't have button.db
						if buttonName == "moveany" then
							button.db = button.db or {}
							if not button.db.hide then button.db.hide = false end
						end

						if not strfind(strlower(LeaPlusDB["MiniExcludeList"]), buttonName) then
							if button.db and not button.db.hide then
								button:Hide()
								button:SetScript("OnShow", function() if not LeaPlusLC.bFrame:IsShown() then button:Hide() end end)
							end
							-- Create background texture
							local bFrameBg = button:CreateTexture(nil, "BACKGROUND")
							bFrameBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
							bFrameBg:SetPoint("CENTER")
							bFrameBg:SetSize(30, 30)
							bFrameBg:SetVertexColor(0, 0, 0, 0.5)
						end
						-- Move GameTooltip to below the minimap in case the button uses it
						button:HookScript("OnEnter", LeaPlusLC.SetButtonTooltip)
					--end)
				end

				-- Hide addon buttons: Hide new LibDBIcon icons
				if LeaPlusLC["MinimapButtonBag"] == "Off" then
					local buttonName = strlower(name)
					if LeaPlusLC["HideMiniAddonButtons"] == "On" then
						-- Hide addon buttons is enabled
						if not strfind(strlower(LeaPlusDB["MiniExcludeList"]), buttonName) then
							LibDBIconStub:ShowOnEnter(name, true)
						end
					else
						-- Hide addon buttons is disabled
						if not strfind(strlower(LeaPlusDB["MiniExcludeList"]), buttonName) then
							LibDBIconStub:ShowOnEnter(name, false)
						end
					end
				end

			end)

		end

		----------------------------------------------------------------------
		-- Show ready timer
		----------------------------------------------------------------------

		if LeaPlusLC["ShowReadyTimer"] == "On" then


			-- Dungeons and Raids
			do

				-- Declare variables
				local duration, barTime = 40, -1
				local t = duration

				-- Create status bar below dungeon ready popup
				local bar = CreateFrame("StatusBar", nil, LFGDungeonReadyPopup)
				bar:SetPoint("TOPLEFT", LFGDungeonReadyPopup, "BOTTOMLEFT", 0, -5)
				bar:SetPoint("TOPRIGHT", LFGDungeonReadyPopup, "BOTTOMRIGHT", 0, -5)
				bar:SetHeight(5)
				bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
				bar:SetStatusBarColor(1.0, 0.85, 0.0)
				bar:SetMinMaxValues(0, duration)

				-- Create status bar text
				local text = bar:CreateFontString(nil, "ARTWORK")
				text:SetFontObject("GameFontNormalLarge")
				text:SetTextColor(1.0, 0.85, 0.0)
				text:SetPoint("TOP", 0, -10)

				-- Update bar as timer counts down
				bar:SetScript("OnUpdate", function(self, elapsed)
					t = t - elapsed
					if barTime >= 1 or barTime == -1 then
						self:SetValue(t)
						text:SetText(SecondsToTime(floor(t + 0.5)))
						barTime = 0
					end
					barTime = barTime + elapsed
				end)

				-- Show frame when dungeon ready frame shows
				local frame = CreateFrame("FRAME")
				frame:RegisterEvent("LFG_PROPOSAL_SHOW")
				frame:RegisterEvent("LFG_PROPOSAL_FAILED")
				frame:RegisterEvent("LFG_PROPOSAL_SUCCEEDED")
				frame:SetScript("OnEvent", function(self, event)
					if event == "LFG_PROPOSAL_SHOW" then
						t = duration
						barTime = -1
						bar:Show()
						-- Hide existing timer bars (such as BigWigs)
						local children = {LFGDungeonReadyPopup:GetChildren()}
						if children then
							for i, child in ipairs(children) do
								if child ~= bar then
									local objType = child:GetObjectType()
									if objType and objType == "StatusBar" then
										child:Hide()
									end
								end
							end
						end
					else
						bar:Hide()
					end
				end)

			end

			-- Player vs Player
			do

				-- Declare variables
				local t, barTime = -1, -1

				-- Create status bar below dungeon ready popup
				local bar = CreateFrame("StatusBar", nil, PVPReadyDialog)
				bar:SetPoint("TOPLEFT", PVPReadyDialog, "BOTTOMLEFT", 0, -5)
				bar:SetPoint("TOPRIGHT", PVPReadyDialog, "BOTTOMRIGHT", 0, -5)
				bar:SetHeight(5)
				bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
				bar:SetStatusBarColor(1.0, 0.85, 0.0)

				-- Create status bar text
				local text = bar:CreateFontString(nil, "ARTWORK")
				text:SetFontObject("GameFontNormalLarge")
				text:SetTextColor(1.0, 0.85, 0.0)
				text:SetPoint("TOP", 0, -10)

				-- Update bar as timer counts down
				bar:SetScript("OnUpdate", function(self, elapsed)
					t = t - elapsed
					if barTime >= 1 or barTime == -1 then
						self:SetValue(t)
						text:SetText(SecondsToTime(floor(t + 0.5)))
						barTime = 0
					end
					barTime = barTime + elapsed
				end)

				-- Show frame when PvP ready frame shows
				hooksecurefunc("PVPReadyDialog_Display", function(self, id)
					t = GetBattlefieldPortExpiration(id) + 1
					-- t = 89; -- debug
					if t and t > 1 then
						bar:SetMinMaxValues(0, t)
						barTime = -1
						bar:Show()
					else
						bar:Hide()
					end
				end)

				PVPReadyDialog:HookScript("OnHide", function()
					bar:Hide()
				end)

				-- Debug
				-- C_Timer.After(2, function() PVPReadyDialog_Display(PVPReadyDialog, 1, "Warsong Gulch", 0, "BATTLEGROUND", "", "DAMAGER"); bar:Show() end)

			end

		end

		----------------------------------------------------------------------
		-- Show flight times
		----------------------------------------------------------------------

		if LeaPlusLC["ShowFlightTimes"] == "On" then

			-- Function to check for Frequent Flier perk in legacy system
			local function HasFrequentFlier()
				return IsPlayerSpell(1225490)
			end

			-- Frequent Flier makes flights 20% faster (flight time is divided by this)
			local frequentFlierSpeed = 1.2

			-- Load flight data
			Leatrix_Plus["FlightData"] = {}
			local faction = UnitFactionGroup("player")
			if faction == "Alliance" then
				Leatrix_Plus:LoadFlightDataAlliance()
			elseif faction == "Horde" then
				Leatrix_Plus:LoadFlightDataHorde()
			end

			-- Minimum time difference (in seconds) to flight data entry before flight report window is shown
			local timeBuffer = 15

			----------------------------------------------------------------------
			-- Route lookup
			----------------------------------------------------------------------

			-- Variables
			local data = Leatrix_Plus["FlightData"]
			local flightFrame = CreateFrame("FRAME")
			LeaPlusLC.flightFrame = flightFrame

			-- Cache functions used while flying
			local GetTime, UnitOnTaxi, format, floor, ceil, max = GetTime, UnitOnTaxi, string.format, math.floor, math.ceil, math.max

			-- Set game title as shown in incorrect flight details window
			local gameTitle = L["Forever"]

			-- Function to get continent
			local function getContinent()
				local mapID = C_Map.GetBestMapForUnit("player")
				if(mapID) then
					local info = C_Map.GetMapInfo(mapID)
					if(info) then
						while(info['mapType'] and info['mapType'] > 2) do
							info = C_Map.GetMapInfo(info['parentMapID'])
						end
						if(info['mapType'] == 2) then
							return info['mapID']
						end
					end
				end
			end

			-- Function to get the flight data for the current continent
			local function GetContinentData()
				local continent = getContinent()
				return continent and data[faction] and data[faction][continent]
			end

			-- Function to get node name
			local function GetNodeName(i)
				return strmatch(TaxiNodeName(i), "[^,]+")
			end

			-- Function to get the node the player is standing at
			local function GetCurrentNode()
				for i = 1, NumTaxiNodes() do
					if TaxiNodeGetType(i) == "CURRENT" then return i end
				end
			end

			-- Function to get the flight data key for a node (its map position)
			local function GetNodeKey(i)
				local x, y = TaxiNodePosition(i)
				return format("%0.2f", x) .. ":" .. format("%0.2f", y), x, y
			end

			-- Every node on the route to a destination (start first) with its key, position and name
			local routeKeys, routeX, routeY, routeNames = {}, {}, {}, {}

			local function AddRouteNode(i)
				local n = #routeKeys + 1
				routeKeys[n], routeX[n], routeY[n] = GetNodeKey(i)
				routeNames[n] = GetNodeName(i)
			end

			-- Function to build the route to a destination (returns the flight data key of the route and destination)
			local function BuildRoute(current, node)
				wipe(routeKeys); wipe(routeX); wipe(routeY); wipe(routeNames)
				AddRouteNode(current)
				for i = 2, GetNumRoutes(node) + 1 do
					AddRouteNode(TaxiGetNodeSlot(node, i, true))
				end
				local destination = GetNodeKey(node)
				local routeString = table.concat(routeKeys, ":")
				-- If route string does not contain destination, add it to the end (such as Altar of Sha'tar)
				if not strfind(routeString, destination, 1, true) then
					AddRouteNode(node)
					routeString = routeString .. ":" .. destination
				end
				return routeString, destination
			end

			-- Function to get a saved flight time between two nodes on the route (nil if not saved)
			local function GetSavedTime(continentData, first, last)
				local routeString = routeKeys[first]
				for i = first + 1, last do
					routeString = routeString .. ":" .. routeKeys[i]
				end
				local duration = continentData[routeString]
				if type(duration) == "number" and duration > 0 then return duration end
			end

			-- Function to work out when each stop on the route is reached (in seconds after takeoff)
			-- Uses the saved time from the start to the stop, else the saved time from the stop to the end, else the share of the distance
			local function GetStopTimes(continentData, total, names, times)
				wipe(names); wipe(times)
				local last = #routeKeys
				local previous = 0
				for i = 2, last - 1 do
					local stopTime = GetSavedTime(continentData, 1, i)
					if not stopTime then
						local rest = GetSavedTime(continentData, i, last)
						stopTime = rest and total - rest
					end
					if not stopTime or stopTime <= previous or stopTime >= total then
						-- Saved times are missing or do not agree so use the share of the distance for every stop
						wipe(times)
						break
					end
					times[i - 1] = stopTime
					previous = stopTime
				end
				if last > 2 and #times ~= last - 2 then
					local distance = 0
					for i = 2, last do
						local dx, dy = routeX[i] - routeX[i - 1], routeY[i] - routeY[i - 1]
						distance = distance + math.sqrt(dx * dx + dy * dy)
						if i < last then times[i - 1] = distance end
					end
					for i = 1, last - 2 do
						times[i] = distance > 0 and total * times[i] / distance or total * i / (last - 1)
					end
				end
				for i = 2, last - 1 do
					names[i - 1] = routeNames[i]
				end
			end

			----------------------------------------------------------------------
			-- Flight progress bar
			----------------------------------------------------------------------

			local WHITE = "Interface\\Buttons\\WHITE8X8"
			local fillR, fillG, fillB = 0.95, 0.27, 0.27
			if faction == "Alliance" then fillR, fillG, fillB = 0.30, 0.62, 1.00 end

			local bar -- The bar frame (created when first needed)
			local flying -- True while the bar is showing a flight
			local fl = { names = {}, times = {} } -- The flight shown on the bar (stop names and times exclude start and destination)
			local ticks = {} -- Stop markers on the bar
			local barFill, barNext -- Fill mode and next stop settings
			local lastSecond, sinceUpdate = -1, 0
			local StopBar, FlightPanel

			-- Speech
			local speechTimes = {600, 540, 480, 420, 360, 300, 240, 180, 120, 60, 30, 20, 10}
			local speechText = {L["Ten minutes"], L["Nine minutes"], L["Eight minutes"], L["Seven minutes"], L["Six minutes"], L["Five minutes"], L["Four minutes"], L["Three minutes"], L["Two minutes"], L["One minute"], L["Thirty seconds"], L["Twenty seconds"], L["Ten seconds"]}
			local speechIndex = 1

			-- Function to get the voice chosen in the game's text to speech options
			local function GetVoice()
				if C_TTSSettings and C_TTSSettings.GetVoiceOptionID and Enum.TtsVoiceType then
					return C_TTSSettings.GetVoiceOptionID(Enum.TtsVoiceType.Standard) or 0
				end
				return 0
			end

			-- Function to speak text (uses the speech rate and volume from the game's text to speech options)
			local function Speak(text)
				local rate, volume = -2, GetCVar("Sound_MasterVolume") * 100
				if C_TTSSettings then
					if C_TTSSettings.GetSpeechRate then rate = C_TTSSettings.GetSpeechRate() or rate end
					if C_TTSSettings.GetSpeechVolume then volume = C_TTSSettings.GetSpeechVolume() or volume end
				end
				C_VoiceChat.SpeakText(GetVoice(), text, rate, volume)
			end

			-- Function to skip spoken times that are already behind
			local function SpeechReset(remaining)
				speechIndex = 1
				while speechTimes[speechIndex] and speechTimes[speechIndex] >= remaining do
					speechIndex = speechIndex + 1
				end
			end

			-- Function to speak the remaining time when it passes a spoken time
			local function SpeechCheck(remaining)
				local spoken = speechTimes[speechIndex]
				if spoken and remaining <= spoken then
					speechIndex = speechIndex + 1
					if remaining > spoken - 2 then Speak(speechText[speechIndex - 1]) end
				end
			end

			-- Function to format time as minutes and seconds
			local function FormatTime(seconds)
				seconds = ceil(seconds)
				return format("%d:%02d", floor(seconds / 60), seconds % 60)
			end

			-- Function to create a font string
			local function MakeText(justify)
				local fs = bar:CreateFontString(nil, "OVERLAY")
				fs:SetJustifyH(justify)
				fs:SetWordWrap(false)
				return fs
			end

			-- Function to create the bar
			local function BuildBar()

				bar = CreateFrame("Frame", nil, UIParent)
				bar:SetFrameStrata("MEDIUM")
				bar:SetPoint(LeaPlusLC["FlightBarA"], UIParent, LeaPlusLC["FlightBarR"], LeaPlusLC["FlightBarX"], LeaPlusLC["FlightBarY"])
				bar:Hide()

				-- Background
				bar.bg = bar:CreateTexture(nil, "BACKGROUND")
				bar.bg:SetAllPoints()
				bar.bg:SetColorTexture(0.04, 0.04, 0.06, 0.75)

				-- Hairline border (top, bottom, left, right)
				bar.edges = {}
				for i = 1, 4 do
					bar.edges[i] = bar:CreateTexture(nil, "BORDER")
					bar.edges[i]:SetColorTexture(1, 1, 1, 0.1)
				end
				bar.edges[1]:SetPoint("TOPLEFT"); bar.edges[1]:SetPoint("TOPRIGHT")
				bar.edges[2]:SetPoint("BOTTOMLEFT"); bar.edges[2]:SetPoint("BOTTOMRIGHT")
				bar.edges[3]:SetPoint("TOPLEFT"); bar.edges[3]:SetPoint("BOTTOMLEFT")
				bar.edges[4]:SetPoint("TOPRIGHT"); bar.edges[4]:SetPoint("BOTTOMRIGHT")

				-- Destination and time remaining
				bar.dest = MakeText("LEFT")
				bar.time = MakeText("RIGHT")
				bar.time:SetTextColor(0.9, 0.9, 0.9)

				-- Progress track
				bar.track = CreateFrame("StatusBar", nil, bar)
				bar.track:SetStatusBarTexture(WHITE)
				bar.track:SetStatusBarColor(fillR, fillG, fillB, 1)
				bar.track:SetMinMaxValues(0, 1)
				bar.track.bg = bar.track:CreateTexture(nil, "BACKGROUND")
				bar.track.bg:SetAllPoints()
				bar.track.bg:SetColorTexture(1, 1, 1, 0.12)

				-- Spark at the edge of the fill
				bar.spark = bar.track:CreateTexture(nil, "OVERLAY", nil, 1)
				bar.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
				bar.spark:SetBlendMode("ADD")
				bar.spark:SetPoint("CENTER", bar.track:GetStatusBarTexture(), "RIGHT")

				-- Next stop
				bar.nextIcon = bar:CreateTexture(nil, "OVERLAY")
				bar.nextIcon:SetTexture("Interface\\TaxiFrame\\UI-Taxi-Icon-White")
				bar.nextIcon:SetVertexColor(0.7, 0.7, 0.7)
				bar.nextName = MakeText("LEFT")
				bar.nextName:SetTextColor(0.7, 0.7, 0.7)
				bar.nextTime = MakeText("RIGHT")
				bar.nextTime:SetTextColor(0.7, 0.7, 0.7)

				-- Drag to move (mouse is only enabled while the configuration panel is showing)
				bar:SetMovable(true)
				bar:EnableMouse(false)
				bar:SetScript("OnMouseDown", function(self, btn)
					if btn == "LeftButton" then self:StartMoving() end
				end)
				bar:SetScript("OnMouseUp", function(self)
					self:StopMovingOrSizing()
					LeaPlusLC["FlightBarA"], void, LeaPlusLC["FlightBarR"], LeaPlusLC["FlightBarX"], LeaPlusLC["FlightBarY"] = self:GetPoint()
				end)

			end

			-- Function to place stop markers on the track
			local function PlaceTicks(width, thick, px)
				local count = #fl.times
				for i = 1, max(count, #ticks) do
					local tick = ticks[i]
					if i <= count then
						if not tick then
							tick = bar.track:CreateTexture(nil, "OVERLAY")
							tick:SetColorTexture(0.04, 0.04, 0.06, 0.9)
							ticks[i] = tick
						end
						local frac = fl.times[i] / fl.total
						if not barFill then frac = 1 - frac end
						tick:SetSize(px * 2, thick)
						tick:ClearAllPoints()
						tick:SetPoint("CENTER", bar.track, "LEFT", width * frac, 0)
						tick:Show()
					elseif tick then
						tick:Hide()
					end
				end
			end

			-- Function to lay out the bar from the current settings
			local function Layout()

				local size = LeaPlusLC["FlightBarFontSize"]
				local small = max(6, size - 2)
				local showBg = LeaPlusLC["FlightBarBackground"] == "On"
				barFill = LeaPlusLC["FlightBarFillBar"] == "On"
				barNext = LeaPlusLC["FlightBarNextHop"] == "On"
				local showNext = barNext and fl.nextStop ~= nil
				local pad = showBg and max(3, floor(size * 0.4 + 0.5)) or 0
				local thick = max(2, floor(size / 4 + 0.5))
				local gap = max(2, floor(size / 4 + 0.5))
				local width = LeaPlusLC["FlightBarWidth"]

				-- Size
				bar:SetScale(LeaPlusLC["FlightBarScale"])
				bar:SetWidth(width)
				bar:SetHeight(pad + size + gap + thick + (showNext and gap + small or 0) + pad)

				-- Background and border (border is one screen pixel thick)
				local px = PixelUtil and PixelUtil.GetPixelToUIUnitFactor() / bar:GetEffectiveScale() or 1
				bar.bg:SetShown(showBg)
				for i = 1, 4 do bar.edges[i]:SetShown(showBg) end
				bar.edges[1]:SetHeight(px); bar.edges[2]:SetHeight(px)
				bar.edges[3]:SetWidth(px); bar.edges[4]:SetWidth(px)

				-- Fonts (outlined without the background so text stays readable)
				local font = GameFontNormal:GetFont()
				local flags = showBg and "" or "OUTLINE"
				local shadow = showBg and 1 or 0
				bar.dest:SetFont(font, size, flags)
				bar.time:SetFont(font, size, flags)
				bar.nextName:SetFont(font, small, flags)
				bar.nextTime:SetFont(font, small, flags)
				bar.dest:SetShadowOffset(shadow, -shadow)
				bar.time:SetShadowOffset(shadow, -shadow)
				bar.nextName:SetShadowOffset(shadow, -shadow)
				bar.nextTime:SetShadowOffset(shadow, -shadow)

				-- Destination and time remaining
				bar.time:ClearAllPoints()
				bar.time:SetPoint("TOPRIGHT", -pad, -pad)
				bar.dest:ClearAllPoints()
				bar.dest:SetPoint("TOPLEFT", pad, -pad)
				bar.dest:SetPoint("RIGHT", bar.time, "LEFT", -size / 2, 0)
				bar.dest:SetText(LeaPlusLC["FlightBarDestination"] == "On" and fl.dest or "")

				-- Progress track
				local y = pad + size + gap
				bar.track:ClearAllPoints()
				bar.track:SetPoint("TOPLEFT", pad, -y)
				bar.track:SetPoint("TOPRIGHT", -pad, -y)
				bar.track:SetHeight(thick)
				bar.spark:SetSize(max(8, thick * 4), thick * 4)
				PlaceTicks(width - pad * 2, thick, px)

				-- Next stop
				bar.nextIcon:SetShown(showNext)
				bar.nextName:SetShown(showNext)
				bar.nextTime:SetShown(showNext)
				if showNext then
					y = y + thick + gap
					bar.nextIcon:SetSize(small, small)
					bar.nextIcon:ClearAllPoints()
					bar.nextIcon:SetPoint("TOPLEFT", pad, -y)
					bar.nextTime:ClearAllPoints()
					bar.nextTime:SetPoint("TOPRIGHT", -pad, -y)
					bar.nextName:ClearAllPoints()
					bar.nextName:SetPoint("TOPLEFT", bar.nextIcon, "TOPRIGHT", 3, 0)
					bar.nextName:SetPoint("RIGHT", bar.nextTime, "LEFT", -small / 2, 0)
					bar.nextName:SetText(fl.names[fl.nextStop])
				end

			end

			-- Function to show progress (returns the time remaining)
			local function SetProgress(elapsed)
				local remaining = fl.total - elapsed
				if remaining < 0 then remaining = 0 end
				local value = remaining / fl.total
				if barFill then value = 1 - value end
				bar.track:SetValue(value)
				bar.spark:SetShown(value > 0 and value < 1)
				return remaining
			end

			-- Function to show the time remaining and the next stop
			local function UpdateText(elapsed, remaining)
				bar.time:SetText(FormatTime(remaining))
				local nextStop = fl.nextStop
				if nextStop then
					-- Move past stops already reached
					while nextStop and elapsed >= fl.times[nextStop] do
						nextStop = fl.times[nextStop + 1] and nextStop + 1 or nil
					end
					if nextStop ~= fl.nextStop then
						fl.nextStop = nextStop
						if nextStop then
							bar.nextName:SetText(fl.names[nextStop])
						elseif barNext then
							-- No more stops so remove the next stop line
							Layout()
						end
					end
					if nextStop and barNext then
						bar.nextTime:SetText(FormatTime(fl.times[nextStop] - elapsed))
					end
				end
			end

			-- Update the bar while flying (text changes once per second)
			local function OnUpdate(self, elapsed)
				sinceUpdate = sinceUpdate + elapsed
				if sinceUpdate < 0.1 then return end
				sinceUpdate = 0
				local flown = GetTime() - fl.start
				local remaining = SetProgress(flown)
				local second = ceil(remaining)
				if second ~= lastSecond then
					lastSecond = second
					-- Remove the bar when time is up or the player is no longer on a taxi (such as after an early landing)
					if remaining <= 0 or (flown > 2 and not UnitOnTaxi("player")) then
						StopBar()
						return
					end
					UpdateText(flown, remaining)
					if fl.speech then SpeechCheck(remaining) end
				end
			end

			-- Function to show a preview on the bar while the configuration panel is showing
			local function ShowPreview()
				if not bar then BuildBar() end
				bar:EnableMouse(true)
				if flying then return end
				-- Sample flight with one stop (zone names come from the game so they are localised)
				local destMap, stopMap = 1454, 1413 -- Orgrimmar, The Barrens
				if faction == "Alliance" then destMap, stopMap = 1455, 1432 end -- Ironforge, Loch Modan
				local destInfo, stopInfo = C_Map.GetMapInfo(destMap), C_Map.GetMapInfo(stopMap)
				wipe(fl.names); wipe(fl.times)
				fl.dest = destInfo and destInfo.name or ""
				fl.names[1] = stopInfo and stopInfo.name or ""
				fl.times[1] = 165
				fl.total, fl.start, fl.nextStop = 300, GetTime() - 120, 1
				Layout()
				SetProgress(120)
				UpdateText(120, 180)
				bar:Show()
			end

			-- Function to remove the preview
			local function HidePreview()
				if not bar then return end
				bar:EnableMouse(false)
				if not flying then bar:Hide() end
			end

			-- Function to start the bar (stop names and times must already be in fl)
			local function StartBar(total, destination)
				if not bar then BuildBar() end
				flying = true
				fl.total, fl.dest, fl.start = total, destination, GetTime()
				fl.nextStop = fl.times[1] and 1 or nil
				fl.speech = LeaPlusLC["FlightBarSpeech"] == "On"
				SpeechReset(total)
				if fl.speech then
					C_Timer.After(1, function()
						if flying then Speak(L["Flight commenced."]) end
					end)
				end
				Layout()
				SetProgress(0)
				UpdateText(0, total)
				lastSecond, sinceUpdate = -1, 0
				bar:SetScript("OnUpdate", OnUpdate)
				bar:Show()
				if LeaPlusCB["CloseFlightBarButton"] then LeaPlusLC:LockItem(LeaPlusCB["CloseFlightBarButton"], false) end
			end

			-- Function to stop the bar
			StopBar = function()
				if not bar then return end
				flying = nil
				bar:SetScript("OnUpdate", nil)
				if LeaPlusCB["CloseFlightBarButton"] then LeaPlusLC:LockItem(LeaPlusCB["CloseFlightBarButton"], true) end
				if FlightPanel and FlightPanel:IsShown() then
					ShowPreview()
				else
					bar:Hide()
				end
			end

			-- Function to apply changed settings to the bar
			local function RefreshBar()
				if not bar or not bar:IsShown() then return end
				if flying then
					Layout()
					SetProgress(GetTime() - fl.start)
					lastSecond = -1 -- Update text on the next tick
				else
					ShowPreview()
				end
			end

			----------------------------------------------------------------------
			-- Flight report window
			----------------------------------------------------------------------

			local reportFrame -- Created when first needed
			local reportLink = "https://www.curseforge.com/members/leatrix/projects"

			-- Function to create a read-only copy box (click it to highlight the text for copying)
			local function MakeCopyBox(parent, px)
				local box = CreateFrame("EditBox", nil, parent)
				box:SetHeight(24)
				box:SetAutoFocus(false)
				box:SetFontObject("ChatFontNormal")
				box:SetTextInsets(8, 8, 0, 0)
				box:SetAltArrowKeyMode(false)
				box.bg = box:CreateTexture(nil, "BACKGROUND")
				box.bg:SetAllPoints()
				box.bg:SetColorTexture(0, 0, 0, 0.5)
				box.edges = {}
				for i = 1, 4 do
					box.edges[i] = box:CreateTexture(nil, "BORDER")
					box.edges[i]:SetColorTexture(1, 1, 1, 0.15)
				end
				box.edges[1]:SetPoint("TOPLEFT"); box.edges[1]:SetPoint("TOPRIGHT"); box.edges[1]:SetHeight(px)
				box.edges[2]:SetPoint("BOTTOMLEFT"); box.edges[2]:SetPoint("BOTTOMRIGHT"); box.edges[2]:SetHeight(px)
				box.edges[3]:SetPoint("TOPLEFT"); box.edges[3]:SetPoint("BOTTOMLEFT"); box.edges[3]:SetWidth(px)
				box.edges[4]:SetPoint("TOPRIGHT"); box.edges[4]:SetPoint("BOTTOMRIGHT"); box.edges[4]:SetWidth(px)
				-- Highlight on click and put the text back if it gets changed
				box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
				box:SetScript("OnEditFocusLost", function(self) self:HighlightText(0, 0) end)
				box:SetScript("OnMouseUp", function(self) self:HighlightText() end)
				box:SetScript("OnTextChanged", function(self, userInput)
					if userInput then self:SetText(self.copyText or ""); self:HighlightText() end
				end)
				box:SetScript("OnEnterPressed", function(self) self:HighlightText() end)
				box:SetScript("OnEscapePressed", function(self) self:ClearFocus(); parent:Hide() end)
				return box
			end

			-- Function to set the text of a copy box
			local function SetCopyText(box, text)
				box.copyText = text
				box:SetText(text)
				box:SetCursorPosition(0)
			end

			-- Function to create the report window
			local function BuildReportFrame()

				local frame = CreateFrame("Frame", LeaPlusLC:CreateRandomName(), UIParent)
				reportFrame = frame
				frame:SetSize(460, 300)
				frame:SetPoint("CENTER", 0, 80)
				frame:SetFrameStrata("DIALOG")
				frame:SetToplevel(true)
				frame:SetClampedToScreen(true)
				frame:EnableMouse(true)
				frame:SetMovable(true)
				frame:RegisterForDrag("LeftButton")
				frame:SetScript("OnDragStart", frame.StartMoving)
				frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
				frame:Hide()

				-- Close with escape
				table.insert(UISpecialFrames, frame:GetName())

				-- Background and hairline border
				local px = PixelUtil and PixelUtil.GetPixelToUIUnitFactor() / frame:GetEffectiveScale() or 1
				frame.bg = frame:CreateTexture(nil, "BACKGROUND")
				frame.bg:SetAllPoints()
				frame.bg:SetColorTexture(0.06, 0.06, 0.08, 0.94)
				local edges = {}
				for i = 1, 4 do
					edges[i] = frame:CreateTexture(nil, "BORDER")
					edges[i]:SetColorTexture(1, 1, 1, 0.12)
				end
				edges[1]:SetPoint("TOPLEFT"); edges[1]:SetPoint("TOPRIGHT"); edges[1]:SetHeight(px)
				edges[2]:SetPoint("BOTTOMLEFT"); edges[2]:SetPoint("BOTTOMRIGHT"); edges[2]:SetHeight(px)
				edges[3]:SetPoint("TOPLEFT"); edges[3]:SetPoint("BOTTOMLEFT"); edges[3]:SetWidth(px)
				edges[4]:SetPoint("TOPRIGHT"); edges[4]:SetPoint("BOTTOMRIGHT"); edges[4]:SetWidth(px)

				-- Accent line along the top in the faction colour
				frame.accent = frame:CreateTexture(nil, "ARTWORK")
				frame.accent:SetPoint("TOPLEFT"); frame.accent:SetPoint("TOPRIGHT")
				frame.accent:SetHeight(2)
				frame.accent:SetColorTexture(fillR, fillG, fillB, 0.9)

				-- Header icon
				frame.icon = frame:CreateTexture(nil, "ARTWORK")
				frame.icon:SetSize(40, 40)
				frame.icon:SetPoint("TOPLEFT", 16, -18)
				frame.icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
				frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

				-- Title and thank you message
				frame.title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
				frame.title:SetPoint("TOPLEFT", frame.icon, "TOPRIGHT", 12, -3)
				frame.title:SetText(L["Flight time report"])
				frame.thanks = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
				frame.thanks:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -5)
				frame.thanks:SetPoint("RIGHT", -40, 0)
				frame.thanks:SetJustifyH("LEFT")
				frame.thanks:SetText(L["Thank you for helping to improve Leatrix Plus!"])

				-- Close button
				frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
				frame.close:SetSize(28, 28)
				frame.close:SetPoint("TOPRIGHT", -2, -4)
				frame.close:SetScript("OnClick", function() frame:Hide() end)

				-- Divider
				frame.divider = frame:CreateTexture(nil, "ARTWORK")
				frame.divider:SetPoint("TOPLEFT", 16, -72)
				frame.divider:SetPoint("TOPRIGHT", -16, -72)
				frame.divider:SetHeight(px)
				frame.divider:SetColorTexture(1, 1, 1, 0.1)

				-- Flight summary
				frame.flightIcon = frame:CreateTexture(nil, "ARTWORK")
				frame.flightIcon:SetSize(16, 16)
				frame.flightIcon:SetPoint("TOPLEFT", 16, -84)
				frame.flightIcon:SetTexture("Interface\\GossipFrame\\TaxiGossipIcon")
				frame.summary = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
				frame.summary:SetPoint("TOPLEFT", frame.flightIcon, "TOPRIGHT", 8, -2)
				frame.summary:SetWidth(404)
				frame.summary:SetJustifyH("LEFT")

				-- How to send the report
				frame.sendIcon = frame:CreateTexture(nil, "ARTWORK")
				frame.sendIcon:SetSize(16, 16)
				frame.sendIcon:SetPoint("TOPLEFT", frame.summary, "BOTTOMLEFT", -24, -14)
				frame.sendIcon:SetTexture("Interface\\Icons\\INV_Letter_15")
				frame.sendIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
				frame.steps = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
				frame.steps:SetPoint("TOPLEFT", frame.sendIcon, "TOPRIGHT", 8, -2)
				frame.steps:SetWidth(404)
				frame.steps:SetJustifyH("LEFT")
				frame.steps:SetSpacing(2)
				frame.steps:SetTextColor(0.8, 0.8, 0.8)
				frame.steps:SetText(L["Please send this report to Leatrix on CurseForge. Open the link below, click Message and paste the report into your message."] .. " " .. L["Consider following Leatrix to show your support for the addons."])

				-- Link box
				frame.linkLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
				frame.linkLabel:SetPoint("TOPLEFT", frame.steps, "BOTTOMLEFT", 0, -14)
				frame.linkLabel:SetText("1. " .. L["Link"])
				frame.link = MakeCopyBox(frame, px)
				frame.link:SetPoint("TOPLEFT", frame.linkLabel, "BOTTOMLEFT", 0, -4)
				frame.link:SetPoint("RIGHT", -16, 0)
				SetCopyText(frame.link, reportLink)

				-- Report box
				frame.reportLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
				frame.reportLabel:SetPoint("TOPLEFT", frame.link, "BOTTOMLEFT", 0, -10)
				frame.reportLabel:SetText("2. " .. L["Report"])
				frame.report = MakeCopyBox(frame, px)
				frame.report:SetPoint("TOPLEFT", frame.reportLabel, "BOTTOMLEFT", 0, -4)
				frame.report:SetPoint("RIGHT", -16, 0)

				-- Copy hint
				frame.hint = frame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
				frame.hint:SetPoint("TOP", frame.report, "BOTTOM", 0, -10)
				frame.hint:SetText(L["Click a box then press CTRL/C to copy it."])

				-- Remove keyboard focus when closed
				frame:SetScript("OnHide", function(self)
					self.link:ClearFocus()
					self.report:ClearFocus()
				end)

			end

			-- Function to show the report window
			-- info: from, to, taken and saved (seconds at normal speed, saved is nil for new flights), route, names and frequentFlier
			local function ShowReport(info)
				if not reportFrame then BuildReportFrame() end
				local summary = info.from .. " " .. L["to"] .. " " .. info.to .. " " .. L["took"] .. " " .. FormatTime(info.taken) .. "."
				local savedText
				if info.saved then
					summary = summary .. " " .. L["The saved flight time is"] .. " " .. FormatTime(info.saved) .. "."
					savedText = "saved " .. info.saved
				else
					summary = summary .. " " .. L["This flight is not in the database yet."]
					savedText = "new"
				end
				if info.frequentFlier then
					summary = summary .. " " .. L["Frequent Flier was active, so this time has been converted to normal flight speed."]
					savedText = savedText .. ", Frequent Flier"
				end
				reportFrame.summary:SetText(summary)
				-- Fit the height to the text (summary and steps can wrap)
				reportFrame:SetHeight(86 + reportFrame.summary:GetStringHeight() + reportFrame.steps:GetStringHeight() + 156)
				SetCopyText(reportFrame.report, faction .. " (" .. gameTitle .. "): " .. '["' .. info.route .. '"] = ' .. info.taken .. ", -- " .. info.names .. " (" .. savedText .. ")")
				reportFrame:Show()
			end

			-- Function to hide the report window
			local function HideReport()
				if reportFrame then reportFrame:Hide() end
			end

			-- Show a sample report window (/ltp flightpopup)
			LeaPlusLC.ShowFlightReportTest = function()
				local fromMap, toMap = 1454, 1413 -- Orgrimmar, The Barrens
				if faction == "Alliance" then fromMap, toMap = 1455, 1432 end -- Ironforge, Loch Modan
				local fromInfo, toInfo = C_Map.GetMapInfo(fromMap), C_Map.GetMapInfo(toMap)
				local from, to = fromInfo and fromInfo.name or "", toInfo and toInfo.name or ""
				ShowReport({from = from, to = to, taken = 134, saved = 112, route = "0.50:0.50:0.60:0.60", names = from .. ", " .. to})
			end

			----------------------------------------------------------------------
			-- Flight events
			----------------------------------------------------------------------

			-- Details of the flight in progress for the flight report window
			local report = {}

			-- Show flight report window after landing if the flight time is missing or wrong
			flightFrame:SetScript("OnEvent", function()
				flightFrame:UnregisterEvent("PLAYER_CONTROL_GAINED")
				-- Convert to normal speed so it matches the flight data
				report.taken = floor((GetTime() - report.start) * (report.frequentFlier and frequentFlierSpeed or 1) + 0.5)
				if not report.saved or report.taken > (report.saved + timeBuffer) or report.taken < (report.saved - timeBuffer) then
					if LeaPlusLC["FlightBarContribute"] == "On" then ShowReport(report) end
				end
				-- Remove the bar since we have landed
				if flying then StopBar() end
			end)

			-- Show progress bar when flight is taken
			hooksecurefunc("TakeTaxiNode", function(node)
				if UnitAffectingCombat("player") then return end
				HideReport()
				local current = GetCurrentNode()
				if not current then return end

				-- Get route and saved flight time
				local continentData = GetContinentData()
				local routeString, destination = BuildRoute(current, node)
				local duration = continentData and continentData[routeString]
				if type(duration) ~= "number" then duration = nil end

				-- Flights with variable durations (flagged as 0) have no bar and no report popup
				if duration == 0 then
					flightFrame:UnregisterEvent("PLAYER_CONTROL_GAINED")
					StopBar()
					return
				end

				-- Store flight details for the flight report window
				local destName = GetNodeName(node)
				local names = table.concat(routeNames, ", ")
				if not strfind(names, destName, 1, true) then names = names .. ", " .. destName end
				report.start, report.route, report.names, report.saved = GetTime(), routeString, names, duration
				report.from, report.to = routeNames[1], destName
				report.frequentFlier = HasFrequentFlier()

				-- Register landing if the player is on a taxi or remove the bar if not
				C_Timer.After(1, function()
					if UnitOnTaxi("player") then
						flightFrame:RegisterEvent("PLAYER_CONTROL_GAINED")
					else
						flightFrame:UnregisterEvent("PLAYER_CONTROL_GAINED")
						StopBar()
					end
				end)

				-- Show progress bar if flight exists in database
				if duration then
					GetStopTimes(continentData, duration, fl.names, fl.times)
					-- Frequent Flier flights are faster
					local barTime = duration
					if report.frequentFlier then
						barTime = duration / frequentFlierSpeed
						for i = 1, #fl.times do
							fl.times[i] = fl.times[i] / frequentFlierSpeed
						end
					end
					StartBar(barTime, destName)
				else
					StopBar()
				end
			end)

			-- Early landing stops at the next stop so the bar counts down to that instead
			hooksecurefunc("TaxiRequestEarlyLanding", function()
				if not flying then return end
				local nextStop = fl.nextStop
				if nextStop then
					fl.total, fl.dest = fl.times[nextStop], fl.names[nextStop]
					for i = #fl.times, nextStop, -1 do
						fl.times[i], fl.names[i] = nil, nil
					end
					fl.nextStop = nil
					SpeechReset(fl.total - (GetTime() - fl.start))
					RefreshBar()
				end
			end)

			-- Show flight time in node tooltips
			hooksecurefunc("TaxiNodeOnButtonEnter", function(button)
				local current = GetCurrentNode()
				if not current then return end
				local continentData = GetContinentData()
				local routeString, destination = BuildRoute(current, button:GetID())
				local duration = continentData and continentData[routeString]
				if type(duration) == "number" then
					if duration == 0 then
						GameTooltip:AddLine(L["Flight times are not available for this route."], 0.9, 0.9, 0.9, true)
					else
						if HasFrequentFlier() then duration = duration / frequentFlierSpeed end
						GameTooltip:AddLine(L["Duration"] .. ": " .. FormatTime(duration), 0.9, 0.9, 0.9, true)
					end
					GameTooltip:Show()
				elseif routeKeys[1] ~= destination then
					GameTooltip:AddLine(L["Duration"] .. ": -:--", 0.9, 0.9, 0.9, true)
					GameTooltip:Show()
				end
			end)

			-- Unregister landing event for various reasons that stop taxi early
			local function StopLandingEvent()
				LeaPlusLC.flightFrame:UnregisterEvent("PLAYER_CONTROL_GAINED")
			end

			hooksecurefunc("TaxiNodeOnButtonEnter", StopLandingEvent)
			hooksecurefunc("TaxiRequestEarlyLanding", StopLandingEvent)
			hooksecurefunc("AcceptBattlefieldPort", StopLandingEvent)
			hooksecurefunc(C_SummonInfo, "ConfirmSummon", StopLandingEvent)

			----------------------------------------------------------------------
			-- Configuration panel
			----------------------------------------------------------------------

			-- Create configuration panel
			FlightPanel = LeaPlusLC:CreatePanel("Show flight times", "FlightPanel")

			LeaPlusLC:MakeTx(FlightPanel, "Settings", 16, -72)
			LeaPlusLC:MakeCB(FlightPanel, "FlightBarBackground", "Show background", 16, -92, false, "If checked, the flight progress bar background texture will be shown.")
			LeaPlusLC:MakeCB(FlightPanel, "FlightBarDestination", "Show destination", 16, -112, false, "If checked, the flight progress bar destination will be shown.")
			LeaPlusLC:MakeCB(FlightPanel, "FlightBarNextHop", "Show next stop", 16, -132, false, "If checked, the next stop on the route and the time to reach it will be shown under the flight progress bar.")
			LeaPlusLC:MakeCB(FlightPanel, "FlightBarFillBar", "Fill instead of drain", 16, -152, false, "If checked, the flight progress bar background will fill instead of drain.")
			LeaPlusLC:MakeCB(FlightPanel, "FlightBarSpeech", "Speak the remaining time", 16, -172, false, "If checked, the remaining flight time will be spoken using text to speech.|n|nChanges to this setting will take effect on the next flight you take.")

			LeaPlusLC:MakeTx(FlightPanel, "Contribute", 16, -212)
			LeaPlusLC:MakeCB(FlightPanel, "FlightBarContribute", "Help contribute flight times", 16, -232, false, "If checked, you will be prompted to submit missing flight times.")

			LeaPlusLC:MakeTx(FlightPanel, "Scale", 356, -72)
			LeaPlusLC:MakeSL(FlightPanel, "FlightBarScale", "Drag to set the flight progress bar scale.", 1, 5, 0.1, 356, -92, "%.2f")

			LeaPlusLC:MakeTx(FlightPanel, "Width", 356, -132)
			LeaPlusLC:MakeSL(FlightPanel, "FlightBarWidth", "Drag to set the flight progress bar width.", 40, 460, 10, 356, -152, "%.0f")

			LeaPlusLC:MakeTx(FlightPanel, "Text size", 356, -192)
			LeaPlusLC:MakeSL(FlightPanel, "FlightBarFontSize", "Drag to set the flight progress bar text size.", 6, 20, 1, 356, -212, "%.0f")

			-- Add close bar button
			local CloseFlightBarButton = LeaPlusLC:CreateButton("CloseFlightBarButton", FlightPanel, "Close Bar", "TOPLEFT", 16, -72, 0, 25, true, "Click to close the currently active flight progress bar.")
			LeaPlusCB["CloseFlightBarButton"]:ClearAllPoints()
			LeaPlusCB["CloseFlightBarButton"]:SetPoint("LEFT", FlightPanel.h, "RIGHT", 10, 0)
			LeaPlusCB["CloseFlightBarButton"]:SetScript("OnClick", function()
				if flying then StopBar() end
			end)
			LeaPlusLC:LockItem(LeaPlusCB["CloseFlightBarButton"], true)

			-- Apply checkbox changes to the bar
			LeaPlusCB["FlightBarBackground"]:HookScript("OnClick", RefreshBar)
			LeaPlusCB["FlightBarDestination"]:HookScript("OnClick", RefreshBar)
			LeaPlusCB["FlightBarNextHop"]:HookScript("OnClick", RefreshBar)
			LeaPlusCB["FlightBarFillBar"]:HookScript("OnClick", RefreshBar)

			-- Flight progress bar scale
			local function SetFlightBarScale()
				LeaPlusCB["FlightBarScale"].f:SetFormattedText("%.0f%%", (LeaPlusLC["FlightBarScale"] / 2) * 100)
				RefreshBar()
			end
			LeaPlusCB["FlightBarScale"]:HookScript("OnValueChanged", SetFlightBarScale)
			SetFlightBarScale()

			-- Flight progress bar width
			local function SetFlightBarWidth()
				LeaPlusCB["FlightBarWidth"].f:SetFormattedText("%.0f%%", (LeaPlusLC["FlightBarWidth"] / 230) * 100)
				RefreshBar()
			end
			LeaPlusCB["FlightBarWidth"]:HookScript("OnValueChanged", SetFlightBarWidth)
			SetFlightBarWidth()

			-- Flight progress bar text size
			LeaPlusCB["FlightBarFontSize"]:HookScript("OnValueChanged", RefreshBar)

			-- Help button tooltip
			FlightPanel.h.tiptext = L["Drag the frame overlay to position the frame."]

			-- Back button handler
			FlightPanel.b:SetScript("OnClick", function()
				FlightPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page7"]:Show()
				return
			end)

			-- Reset button handler
			FlightPanel.r:SetScript("OnClick", function()

				-- Reset position, scale, width and text size
				LeaPlusLC["FlightBarA"], LeaPlusLC["FlightBarR"], LeaPlusLC["FlightBarX"], LeaPlusLC["FlightBarY"] = "TOP", "TOP", 0, -66
				LeaPlusLC["FlightBarScale"] = 2
				LeaPlusLC["FlightBarWidth"] = 230
				LeaPlusLC["FlightBarFontSize"] = 10
				if bar then
					bar:ClearAllPoints()
					bar:SetPoint(LeaPlusLC["FlightBarA"], UIParent, LeaPlusLC["FlightBarR"], LeaPlusLC["FlightBarX"], LeaPlusLC["FlightBarY"])
				end

				-- Reset checkboxes
				LeaPlusLC["FlightBarBackground"] = "On"
				LeaPlusLC["FlightBarDestination"] = "On"
				LeaPlusLC["FlightBarNextHop"] = "On"
				LeaPlusLC["FlightBarFillBar"] = "Off"
				LeaPlusLC["FlightBarSpeech"] = "Off"
				LeaPlusLC["FlightBarContribute"] = "On"

				-- Refresh configuration panel and bar
				FlightPanel:Hide(); FlightPanel:Show()
				RefreshBar()

			end)

			-- Show configuration panal when options panel button is clicked
			LeaPlusCB["ShowFlightTimesBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["FlightBarContribute"] = "On"
				else
					FlightPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

			-- Show the bar with a preview while the configuration panel is showing so it can be positioned
			FlightPanel:HookScript("OnShow", ShowPreview)
			FlightPanel:HookScript("OnHide", HidePreview)

		end

		----------------------------------------------------------------------
		-- Remove transforms (no reload required)
		----------------------------------------------------------------------

		do

			local transTable = {

				-- Single spell IDs
				["TransLantern"] = {44212}, -- Weighted Jack-o'-Lantern
				["TransTurkey"] = {61781}, -- Turkey (Pilgrim's Bounty)

				-- Noblegarden: Noblegarden Bunny
				["TransNobleBunny"] = {
					--[[Noblegarden Bunny]] 61734,
					--[[Rabbit Costume]] 61716,
				},

				-- Hallowed Wand costumes
				["TransHallowed"] = {
					--[[Abomination]] 172010,
					--[[CancelBanshee]] 218132,
					--[[Bat]] 191703, 24732,
					--[[Gargoyle]] 191210,
					--[[Geist]] 172015,
					--[[Ghost]] 24735, 24736, 191698, 191700,
					--[[Ghoul]] 172008,
					--[[Leper Gnome]] 24712, 24713, 191701,
					--[[Nerubian]] 191211,
					--[[Ninja]] 24710, 24711, 191686, 191688,
					--[[Pirate]] 24708, 24709, 173958, 173959, 191682, 191683,
					--[[Skeleton]] 24723, 191702,
					--[[Slime]] 172003,
					--[[Spider]] 172020,
					--[[Wight]] 191208,
					--[[Wisp]] 24740,
				},

				-- Noggenfogger Elixir
				["TransNoggenfogger"] = {
					--[[You feel light]] 16593, 1223630,
					--[[You feel smaller]] 16595, 1223629,
				},

			}

			-- Give table file level scope (its used during logout and for admin command)
			LeaPlusLC["transTable"] = transTable

			-- Create local table for storing spell IDs that need to be removed
			local cTable = {}

			-- Load saved settings or set default values
			for k, v in pairs(transTable) do
				if LeaPlusDB[k] and type(LeaPlusDB[k]) == "string" and LeaPlusDB[k] == "On" or LeaPlusDB[k] == "Off" then
					LeaPlusLC[k] = LeaPlusDB[k]
				else
					LeaPlusLC[k] = "Off"
					LeaPlusDB[k] = "Off"
				end
			end

			-- Create scrolling configuration panel
			local transPanel = LeaPlusLC:CreatePanel("Remove transforms", "transPanel", true)

			-- Initialise row count
			local row = -1

			-- Add checkboxes
			row = row + 2; LeaPlusLC:MakeTx(transPanel.scrollChild, "Events", 16,  -(row - 1) * 20 - 2)
			row = row + 1; LeaPlusLC:MakeCB(transPanel.scrollChild, "TransHallowed", "Hallow's End: Hallowed Wand", 16,  -((row - 1) * 20) - 2, false, "If checked, the Hallowed Wand transforms will be removed when applied.")
			row = row + 1; LeaPlusLC:MakeCB(transPanel.scrollChild, "TransLantern", "Hallow's End: Weighted Jack-o'-Lantern", 16,  -((row - 1) * 20) - 2, false, "If checked, the Weighted Jack-o'-Lantern transform will be removed when applied.")
			row = row + 1; LeaPlusLC:MakeCB(transPanel.scrollChild, "TransNobleBunny", "Noblegarden: Noblegarden Bunny", 16,  -((row - 1) * 20) - 2, false, "If checked, the Noblegarden bunny transforms will be removed when applied.")
			row = row + 1; LeaPlusLC:MakeCB(transPanel.scrollChild, "TransTurkey", "Pilgrim's Bounty: Turkey Shooter", 16,  -((row - 1) * 20) - 2, false, "If checked, the Turkey Shooter transform will be removed when applied.")

			row = row + 2; LeaPlusLC:MakeTx(transPanel.scrollChild, "Items", 16,  -(row - 1) * 20 - 2)
			row = row + 1; LeaPlusLC:MakeCB(transPanel.scrollChild, "TransNoggenfogger", "Noggenfogger Elixir", 16,  -((row - 1) * 20) - 2, false, "If checked, the slow fall and shrink effects of Noggenfogger Elixir will be removed when applied while keeping the skeleton transform intact.")

			-- Debug
			-- RemoveCommentToEnableDebug = true
			if RemoveCommentToEnableDebug then
				row = row + 2; LeaPlusLC:MakeTx(transPanel.scrollChild, "Debug", 16,  -(row - 1) * 20 - 2)
				row = row + 1; LeaPlusLC:MakeCB(transPanel.scrollChild, "CancelDevotion", "Devotion Aura", 16, -((row - 1) * 20) - 2, false, "")
				transTable["CancelDevotion"] = {465}
				LeaPlusLC["CancelDevotion"] = "On"

				row = row + 1; LeaPlusLC:MakeCB(transPanel.scrollChild, "CancelStealth", "Stealth", 16, -((row - 1) * 20) - 2, false, "")
				transTable["CancelStealth"] = {115191} -- Old: 1784
				LeaPlusLC["CancelStealth"] = "On"

				row = row + 1; LeaPlusLC:MakeCB(transPanel.scrollChild, "CancelIntel", "Intellect", 16, -((row - 1) * 20) - 2, false, "")
				transTable["CancelIntel"] = {1459}
				LeaPlusLC["CancelIntel"] = "On"

				row = row + 1; LeaPlusLC:MakeCB(transPanel.scrollChild, "CancelMonkey", "Aspect of the Monkey", 16, -((row - 1) * 20) - 2, false, "")
				transTable["CancelMonkey"] = {13163}
				LeaPlusLC["CancelMonkey"] = "On"

			end

			-- Function to populate cTable with spell IDs for settings that are enabled
			local function UpdateList()
				for k, v in pairs(transTable) do
					for j, spellID in pairs(v) do
						if LeaPlusLC[k] == "On" then
							cTable[spellID] = true
						else
							cTable[spellID] = nil
						end
					end
				end
			end

			-- Populate cTable on startup
			UpdateList()

			-- Create frame for events
			local spellFrame = CreateFrame("FRAME")
			spellFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

			-- Function to cancel buffs
			local function eventFunc()
				if not C_Secrets.ShouldAurasBeSecret() then
					for i = 1, 40 do
						local BuffData = C_UnitAuras.GetBuffDataByIndex("player", i)
						if BuffData then
							local spellID = BuffData.spellId
							if spellID and canaccessvalue(spellID) and cTable[spellID] then
								if not UnitAffectingCombat("player") then
									CancelUnitBuff("player", i)
								end
							end
						end
					end
				end
			end

			-- Check for buffs
			spellFrame:SetScript("OnEvent", function(self, event, unit, updatedAuras)
				if event == "UNIT_AURA" then
					if updatedAuras then
						if canaccessvalue(updatedAuras.isFullUpdate) and updatedAuras.isFullUpdate then
							eventFunc()
						elseif canaccessvalue(updatedAuras.addedAuras) and updatedAuras.addedAuras then
							for void, aura in ipairs(updatedAuras.addedAuras) do
								if aura.spellId and canaccessvalue(aura.spellId) and cTable[aura.spellId] then
									eventFunc()
								end
							end
						end
					end
				elseif event == "PLAYER_REGEN_ENABLED" then

					-- Traverse buffs (will only run spell was found in cTable previously)
					if not C_Secrets.ShouldAurasBeSecret() then
						for i = 1, 40 do
							local BuffData = C_UnitAuras.GetBuffDataByIndex("player", i)
							if BuffData then
								local spellID = BuffData.spellId
								if spellID and canaccessvalue(spellID) and cTable[spellID] then
									CancelUnitBuff("player", i)
								end
							end
						end
					end
				end
			end)

			-- Function to set event
			local function SetTransformFunc()
				if LeaPlusLC["NoTransforms"] == "On" then
					eventFunc()
					spellFrame:RegisterUnitEvent("UNIT_AURA", "player")
					spellFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
				else
					spellFrame:UnregisterEvent("UNIT_AURA")
					spellFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
				end
			end

			-- Run set event function when option is clicked and on startup
			LeaPlusCB["NoTransforms"]:HookScript("OnClick", SetTransformFunc)
			if LeaPlusLC["NoTransforms"] == "On" then SetTransformFunc() end

			-- Set click width for checkboxes and run update when checkboxes are clicked
			for k, v in pairs(transTable) do
				--[[LeaPlusCB[k].f:SetWidth(80)
				if LeaPlusCB[k].f:GetStringWidth() > 80 then
					LeaPlusCB[k]:SetHitRectInsets(0, -70, 0, 0)
				else
					LeaPlusCB[k]:SetHitRectInsets(0, -LeaPlusCB[k].f:GetStringWidth() + 4, 0, 0)
				end]]
				LeaPlusCB[k]:HookScript("OnClick", function()
					UpdateList()
					eventFunc()
				end)
			end

			-- Help button hidden
			transPanel.h:Hide()

			-- Back button handler
			transPanel.b:SetScript("OnClick", function()
				transPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page7"]:Show()
				return
			end)

			-- Reset button handler
			transPanel.r:SetScript("OnClick", function()

				-- Reset checkboxes
				for k, v in pairs(transTable) do
					LeaPlusLC[k] = "Off"
				end
				UpdateList()
				eventFunc()

				-- Refresh panel
				transPanel:Hide(); transPanel:Show()

			end)

			-- Show panal when options panel button is clicked
			LeaPlusCB["NoTransformsBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					for k, v in pairs(transTable) do
						LeaPlusLC[k] = "On"
					end
					UpdateList()
					eventFunc()
				else
					transPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		-- Show train all button
		----------------------------------------------------------------------

		if LeaPlusLC["ShowTrainAllButton"] == "On" then

			-- Function to create train all button
			EventUtil.ContinueOnAddOnLoaded("Blizzard_TrainerUI",function()

				----------------------------------------------------------------------
				--	Train All button
				----------------------------------------------------------------------

				-- Create train all button
				LeaPlusLC:CreateButton("TrainAllButton", ClassTrainerFrame, "Train All", "BOTTOMLEFT", 344, 54, 0, 22, false, "")
				LeaPlusCB["TrainAllButton"]:ClearAllPoints()
				LeaPlusCB["TrainAllButton"]:SetPoint("RIGHT", ClassTrainerTrainButton, "LEFT", -1, 0)

				local gap = ClassTrainerFrame:GetWidth() - ClassTrainerFrameMoneyBg:GetWidth() - ClassTrainerTrainButton:GetWidth() - 13
				if LeaPlusCB["TrainAllButton"]:GetWidth() > gap then
					LeaPlusCB["TrainAllButton"]:GetFontString():SetWordWrap(false)
					LeaPlusCB["TrainAllButton"]:SetWidth(gap)
					LeaPlusCB["TrainAllButton"]:GetFontString():SetWidth(gap - 8)
				end

				-- Give button global scope (useful for compatibility with other addons and essential for ElvUI)
				_G.LeaPlusGlobalTrainAllButton = LeaPlusCB["TrainAllButton"]

				-- Button tooltip
				LeaPlusCB["TrainAllButton"]:SetScript("OnEnter", function(self)
					-- Get number of available skills and total cost
					local count, cost = 0, 0
					for i = 1, GetNumTrainerServices() do
						local void, isAvail = GetTrainerServiceInfo(i)
						if isAvail and isAvail == "available" then
							count = count + 1
							cost = cost + GetTrainerServiceCost(i)
						end
					end
					-- Show tooltip
					if count > 0 then
						GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, 4)
						GameTooltip:ClearLines()
						if count > 1 then
							GameTooltip:AddLine(L["Train"] .. " " .. count .. " " .. L["skills for"] .. " " .. C_CurrencyInfo.GetCoinTextureString(cost))
						else
							GameTooltip:AddLine(L["Train"] .. " " .. count .. " " .. L["skill for"] .. " " .. C_CurrencyInfo.GetCoinTextureString(cost))
						end
						GameTooltip:Show()
					end
				end)

				-- Button click handler
				LeaPlusCB["TrainAllButton"]:SetScript("OnClick",function(self)
					for i = 1, GetNumTrainerServices() do
						local void, isAvail = GetTrainerServiceInfo(i)
						if isAvail and isAvail == "available" then
							BuyTrainerService(i)
						end
					end
				end)

				-- Enable button only when skills are available
				local skillsAvailable
				hooksecurefunc("ClassTrainerFrame_Update", function()
					skillsAvailable = false
					for i = 1, GetNumTrainerServices() do
						local void, isAvail = GetTrainerServiceInfo(i)
						if isAvail and isAvail == "available" then
							skillsAvailable = true
						end
					end
					LeaPlusCB["TrainAllButton"]:SetEnabled(skillsAvailable)
					-- Refresh tooltip
					if LeaPlusCB["TrainAllButton"]:IsMouseOver() and skillsAvailable then
						LeaPlusCB["TrainAllButton"]:GetScript("OnEnter")(LeaPlusCB["TrainAllButton"])
					end
				end)

				-- Hide button for trainer frames with points (such as hunter beast training)
				ClassTrainerFrame:HookScript("OnShow", function()
					if ClassTrainerFrame.trainingPoints:IsShown() then
						LeaPlusCB["TrainAllButton"]:Hide()
					else
						LeaPlusCB["TrainAllButton"]:Show()
					end
				end)

				----------------------------------------------------------------------
				--	ElvUI fixes
				----------------------------------------------------------------------

				-- ElvUI fixes
				if LeaPlusLC.ElvUI then
					local E = LeaPlusLC.ElvUI
					if E.private.skins.blizzard.enable and E.private.skins.blizzard.trainer then
						LeaPlusCB["TrainAllButton"]:ClearAllPoints()
						LeaPlusCB["TrainAllButton"]:SetPoint("RIGHT", ClassTrainerTrainButton, "LEFT", -6, 0)
						E:GetModule("Skins"):HandleButton(_G.LeaPlusGlobalTrainAllButton)
						if LeaPlusCB["TrainAllButton"]:GetWidth() > gap then
							LeaPlusCB["TrainAllButton"]:GetFontString():SetWordWrap(false)
							LeaPlusCB["TrainAllButton"]:SetWidth(gap - 5)
							LeaPlusCB["TrainAllButton"]:GetFontString():SetWidth(gap - 8)
						end
					end
				end

			end)

		end

		----------------------------------------------------------------------
		-- Filter chat messages
		----------------------------------------------------------------------

		if LeaPlusLC["FilterChatMessages"] == "On" and not LeaLockList["FilterChatMessages"] then

			-- Load LibChatAnims
			Leatrix_Plus:LeaPlusLCA()

			-- Create configuration panel
			local ChatFilterPanel = LeaPlusLC:CreatePanel("Filter chat messages", "ChatFilterPanel")

			LeaPlusLC:MakeTx(ChatFilterPanel, "Settings", 16, -72)
			LeaPlusLC:MakeCB(ChatFilterPanel, "BlockSpellLinks", "Block spell links during combat", 16, -92, false, "If checked, messages containing spell links will be blocked while you are in combat.|n|nThis is useful for blocking spell interrupt spam.|n|nThis applies to the say, party, raid, instance, emote and yell channels.")
			LeaPlusLC:MakeCB(ChatFilterPanel, "BlockDrunkenSpam", "Block drunken spam", 16, -112, false, "If checked, drunken messages will be blocked unless they apply to your character.|n|nThis applies to the system channel.")
			LeaPlusLC:MakeCB(ChatFilterPanel, "BlockDuelSpam", "Block duel spam", 16, -132, false, "If checked, duel victory and retreat messages will be blocked unless your character took part in the duel.|n|nThis applies to the system channel.")

			-- Lock block drunken spam option for zhTW
			if GameLocale == "zhTW" then
				LeaPlusLC:LockItem(LeaPlusCB["BlockDrunkenSpam"], true)
				LeaPlusLC["BlockDrunkenSpam"] = "Off"
				LeaPlusDB["BlockDrunkenSpam"] = "Off"
				LeaPlusCB["BlockDrunkenSpam"].tiptext = LeaPlusCB["BlockDrunkenSpam"].tiptext .. "|n|n|cff00AAFF" .. L["Cannot use this with your locale."]
			end

			-- Help button hidden
			ChatFilterPanel.h:Hide()

			-- Back button handler
			ChatFilterPanel.b:SetScript("OnClick", function()
				ChatFilterPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page3"]:Show()
				return
			end)

			local charName = GetUnitName("player")
			local charRealm = GetNormalizedRealmName()
			local nameRealm = charName .. "%%-" .. charRealm

			-- Localise Angelis and Sinny spam
				if GameLocale == "frFR" then L["Sinny"] = "Stèlon"		; L["Angelis"] = "Angélis"
			elseif GameLocale == "ptBR" then L["Sinny"] = "Pecadito"	; L["Angelis"] = "Ângelis"
			elseif GameLocale == "ruRU" then L["Sinny"] = "Грешок"		; L["Angelis"] = "Ангелис"
			elseif GameLocale == "koKR" then L["Sinny"] = "죄악이"			; L["Angelis"] = "안젤리스"
			elseif GameLocale == "zhTW" then L["Sinny"] = "罪罪"			; L["Angelis"] = "安吉莉丝"
			elseif GameLocale == "zhCN" then L["Sinny"] = "罪罪"			; L["Angelis"] = "安吉莉丝"
			elseif GameLocale == "deDE" then L["Sinny"] = "Sündi"
			elseif GameLocale == "esES" then L["Sinny"] = "Pecadín"
			elseif GameLocale == "esMX" then L["Sinny"] = "Pecadín"
			elseif GameLocale == "itIT" then L["Sinny"] = "Peccatello"
			end

			-- Chat filter
			local function ChatFilterFunc(self, event, msg, sender)
				-- Block duel spam
				if LeaPlusLC["BlockDuelSpam"] == "On" then
					-- Block duel messages unless you are part of the duel
					if msg:match(DUEL_WINNER_KNOCKOUT:gsub("%%1$s", "%.+"):gsub("%%2$s", "%.+")) or msg:match(DUEL_WINNER_RETREAT:gsub("%%1$s", "%.+"):gsub("%%2$s", "%.+")) then
						-- Player has defeated player in a duel.
						if msg:match(DUEL_WINNER_KNOCKOUT:gsub("%%1$s", charName):gsub("%%2$s", "%.+")) then return false end
						if msg:match(DUEL_WINNER_KNOCKOUT:gsub("%%1$s", nameRealm):gsub("%%2$s", "%.+")) then return false end
						if msg:match(DUEL_WINNER_KNOCKOUT:gsub("%%1$s", "%.+"):gsub("%%2$s", charName)) then return false end
						if msg:match(DUEL_WINNER_KNOCKOUT:gsub("%%1$s", "%.+"):gsub("%%2$s", nameRealm)) then return false end
						-- Player has fled from player in a duel.
						if msg:match(DUEL_WINNER_RETREAT:gsub("%%1$s", charName):gsub("%%2$s", "%.+")) then return false end
						if msg:match(DUEL_WINNER_RETREAT:gsub("%%1$s", nameRealm):gsub("%%2$s", "%.+")) then return false end
						if msg:match(DUEL_WINNER_RETREAT:gsub("%%1$s", "%.+"):gsub("%%2$s", charName)) then return false end
						if msg:match(DUEL_WINNER_RETREAT:gsub("%%1$s", "%.+"):gsub("%%2$s", nameRealm)) then return false end
						-- Block all duel messages not involving player
						return true
					end
				end
				-- Block spell links
				if LeaPlusLC["BlockSpellLinks"] == "On" and UnitAffectingCombat("player") then
					if msg:find("|Hspell") then return true end
				end
				-- Block drunken spam
				if LeaPlusLC["BlockDrunkenSpam"] == "On" then
					for i = 1, 4 do
						local drunk1 = _G["DRUNK_MESSAGE_ITEM_OTHER"..i]:gsub("%%s", "%s-")
						local drunk2 = _G["DRUNK_MESSAGE_OTHER"..i]:gsub("%%s", "%s-")
						if msg:match(drunk1) or msg:match(drunk2) then
							return true
						end
					end
				end
			end

			-- Enable or disable chat filter settings
			local function SetChatFilter()
				if LeaPlusLC["BlockSpellLinks"] == "On" then
					ChatFrameUtil.AddMessageEventFilter("CHAT_MSG_SAY", ChatFilterFunc)
					ChatFrameUtil.AddMessageEventFilter("CHAT_MSG_PARTY", ChatFilterFunc)
					ChatFrameUtil.AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", ChatFilterFunc)
					ChatFrameUtil.AddMessageEventFilter("CHAT_MSG_RAID", ChatFilterFunc)
					ChatFrameUtil.AddMessageEventFilter("CHAT_MSG_RAID_LEADER", ChatFilterFunc)
					ChatFrameUtil.AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", ChatFilterFunc)
					ChatFrameUtil.AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", ChatFilterFunc)
					ChatFrameUtil.AddMessageEventFilter("CHAT_MSG_EMOTE", ChatFilterFunc)
					ChatFrameUtil.AddMessageEventFilter("CHAT_MSG_YELL", ChatFilterFunc)
				else
					ChatFrameUtil.RemoveMessageEventFilter("CHAT_MSG_SAY", ChatFilterFunc)
					ChatFrameUtil.RemoveMessageEventFilter("CHAT_MSG_PARTY", ChatFilterFunc)
					ChatFrameUtil.RemoveMessageEventFilter("CHAT_MSG_PARTY_LEADER", ChatFilterFunc)
					ChatFrameUtil.RemoveMessageEventFilter("CHAT_MSG_RAID", ChatFilterFunc)
					ChatFrameUtil.RemoveMessageEventFilter("CHAT_MSG_RAID_LEADER", ChatFilterFunc)
					ChatFrameUtil.RemoveMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", ChatFilterFunc)
					ChatFrameUtil.RemoveMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", ChatFilterFunc)
					ChatFrameUtil.RemoveMessageEventFilter("CHAT_MSG_EMOTE", ChatFilterFunc)
					ChatFrameUtil.RemoveMessageEventFilter("CHAT_MSG_YELL", ChatFilterFunc)
				end
				if LeaPlusLC["BlockDrunkenSpam"] == "On" or LeaPlusLC["BlockDuelSpam"] == "On" then
					ChatFrameUtil.AddMessageEventFilter("CHAT_MSG_SYSTEM", ChatFilterFunc)
				else
					ChatFrameUtil.RemoveMessageEventFilter("CHAT_MSG_SYSTEM", ChatFilterFunc)
				end
			end

			-- Set chat filter when settings are clicked and on startup
			LeaPlusCB["BlockSpellLinks"]:HookScript("OnClick", SetChatFilter)
			LeaPlusCB["BlockDrunkenSpam"]:HookScript("OnClick", SetChatFilter)
			LeaPlusCB["BlockDuelSpam"]:HookScript("OnClick", SetChatFilter)
			SetChatFilter()

			-- Reset button handler
			ChatFilterPanel.r:SetScript("OnClick", function()

				-- Reset controls
				LeaPlusLC["BlockSpellLinks"] = "Off"
				LeaPlusLC["BlockDrunkenSpam"] = "Off"
				LeaPlusLC["BlockDuelSpam"] = "Off"
				SetChatFilter()

				-- Refresh configuration panel
				ChatFilterPanel:Hide(); ChatFilterPanel:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			LeaPlusCB["FilterChatMessagesBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["BlockSpellLinks"] = "On"
					LeaPlusLC["BlockDrunkenSpam"] = "On"
					LeaPlusLC["BlockDuelSpam"] = "On"
					SetChatFilter()
				else
					ChatFilterPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		-- Automatically accept resurrection requests (no reload required)
		----------------------------------------------------------------------

		do

			-- Create configuration panel
			local AcceptResPanel = LeaPlusLC:CreatePanel("Accept resurrection", "AcceptResPanel")

			LeaPlusLC:MakeTx(AcceptResPanel, "Settings", 16, -72)
			LeaPlusLC:MakeCB(AcceptResPanel, "AutoResNoCombat", "Exclude combat resurrection", 16, -92, false, "If checked, resurrection requests will not be automatically accepted if the player resurrecting you is in combat.")
			LeaPlusLC:MakeCB(AcceptResPanel, "AutoResNoAfterlife", "Exclude afterlife resurrection", 16, -112, false, "If checked, resurrection requests will not be automatically accepted if the player resurrecting you is dead and in the afterlife.")

			-- Help button hidden
			AcceptResPanel.h:Hide()

			-- Back button handler
			AcceptResPanel.b:SetScript("OnClick", function()
				AcceptResPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page1"]:Show();
				return
			end)

			-- Reset button handler
			AcceptResPanel.r:SetScript("OnClick", function()

				-- Reset checkboxes
				LeaPlusLC["AutoResNoCombat"] = "On"
				LeaPlusLC["AutoResNoAfterlife"] = "Off"

				-- Refresh panel
				AcceptResPanel:Hide(); AcceptResPanel:Show()

			end)

			-- Show panal when options panel button is clicked
			LeaPlusCB["AutoAcceptResBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["AutoResNoCombat"] = "On"
					LeaPlusLC["AutoResNoAfterlife"] = "Off"
				else
					AcceptResPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

			-- Function to set resurrect event
			local function SetResEvent()
				if LeaPlusLC["AutoAcceptRes"] == "On" then
					AcceptResPanel:RegisterEvent("RESURRECT_REQUEST")
				else
					AcceptResPanel:UnregisterEvent("RESURRECT_REQUEST")
				end
			end

			-- Run function when option is clicked and on startup if option is enabled
			LeaPlusCB["AutoAcceptRes"]:HookScript("OnClick", SetResEvent)
			if LeaPlusLC["AutoAcceptRes"] == "On" then SetResEvent() end

			-- Handle event
			AcceptResPanel:SetScript("OnEvent", function(self, event, arg1)
				if event == "RESURRECT_REQUEST" then

					-- Exclude afterlife resurrection (such as a holy priest with the Afterlife talent)
					if LeaPlusLC["AutoResNoAfterlife"] == "On" and UnitIsDead(arg1) then return end

					-- Manage other resurrection requests
					if not UnitAffectingCombat(arg1) or LeaPlusLC["AutoResNoCombat"] == "Off" then
						AcceptResurrect()
						StaticPopup_Hide("RESURRECT_NO_TIMER")
					end
					return

				end
			end)

		end

		----------------------------------------------------------------------
		-- Hide keybind text
		----------------------------------------------------------------------

		if LeaPlusLC["HideKeybindText"] == "On" and not LeaLockList["HideKeybindText"] then

			-- Hide bind text
			for i = 1, 12 do
				_G["ActionButton"..i.."HotKey"]:SetAlpha(0) -- Main bar
				_G["MultiBarBottomRightButton"..i.."HotKey"]:SetAlpha(0) -- Bottom right bar
				_G["MultiBarBottomLeftButton"..i.."HotKey"]:SetAlpha(0) -- Bottom left bar
				_G["MultiBarRightButton"..i.."HotKey"]:SetAlpha(0) -- Right bar
				_G["MultiBarLeftButton"..i.."HotKey"]:SetAlpha(0) -- Left bar
				_G["MultiBar5Button" .. i .. "HotKey"]:SetAlpha(0) -- Dragonflight new bars
				_G["MultiBar6Button" .. i .. "HotKey"]:SetAlpha(0) -- Dragonflight new bars
				_G["MultiBar7Button" .. i .. "HotKey"]:SetAlpha(0) -- Dragonflight new bars
			end

		end

		----------------------------------------------------------------------
		-- Hide macro text
		----------------------------------------------------------------------

		if LeaPlusLC["HideMacroText"] == "On" and not LeaLockList["HideMacroText"] then

			-- Hide marco text
			for i = 1, 12 do
				_G["ActionButton"..i.."Name"]:SetAlpha(0) -- Main bar
				_G["MultiBarBottomRightButton"..i.."Name"]:SetAlpha(0) -- Bottom right bar
				_G["MultiBarBottomLeftButton"..i.."Name"]:SetAlpha(0) -- Bottom left bar
				_G["MultiBarRightButton"..i.."Name"]:SetAlpha(0) -- Right bar
				_G["MultiBarLeftButton"..i.."Name"]:SetAlpha(0) -- Left bar
				_G["MultiBar5Button" .. i .. "Name"]:SetAlpha(0) -- Dragonflight new bars
				_G["MultiBar6Button" .. i .. "Name"]:SetAlpha(0) -- Dragonflight new bars
				_G["MultiBar7Button" .. i .. "Name"]:SetAlpha(0) -- Dragonflight new bars
			end

		end

		----------------------------------------------------------------------
		--	Show druid power bar
		----------------------------------------------------------------------

		if LeaPlusLC["ShowDruidPowerBar"] == "On" and not LeaLockList["ShowDruidPowerBar"] then

			local void, class = UnitClass("player")
			local manaBar = PlayerFrame_GetManaBar and PlayerFrame_GetManaBar()
			local container = PlayerFrame.PlayerFrameContainer
			if class == "DRUID" and manaBar and container and container.AlternatePowerFrameTexture then

				-- Bar position and size
				local barX, barY = 0, -1
				local barWidth = manaBar:GetWidth()
				local barHeight = manaBar:GetHeight()

				-- Create druid power bar underneath the player frame power bar
				local bar = CreateFrame("StatusBar", nil, PlayerFrame)
				bar:SetPoint("TOPLEFT", manaBar, "BOTTOMLEFT", barX, barY)
				bar:SetSize(barWidth, barHeight)
				bar:SetFrameLevel(manaBar:GetFrameLevel() + 1)
				bar:SetStatusBarTexture("UI-HUD-UnitFrame-Player-PortraitOn-Bar-Mana")
				bar:Hide()

				-- Mask the bar so it fits the frame art (same mask as the Blizzard power bar)
				local barTexture = bar:GetStatusBarTexture()
				barTexture:SetTexelSnappingBias(0)
				barTexture:SetSnapToPixelGrid(false)
				bar.Mask = bar:CreateMaskTexture()
				bar.Mask:SetAtlas("UI-HUD-UnitFrame-Player-PortraitOn-Bar-Mana-Mask", TextureKitConstants.UseAtlasSize)
				bar.Mask:SetPoint("TOPLEFT", -2, 2)
				barTexture:AddMaskTexture(bar.Mask)

				-- Create status text (same layout as Blizzard status bars)
				bar.TextString = bar:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
				bar.TextString:SetPoint("CENTER")

				bar.LeftText = bar:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
				bar.LeftText:SetPoint("LEFT", 2, 0)

				bar.RightText = bar:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
				bar.RightText:SetPoint("RIGHT", -2, 0)

				-- Function to swap player frame art (texture display only, nothing is written to Blizzard code)
				local function SetFrameArt(showBar)
					if PlayerFrame.state == "vehicle" or PlayerFrame.activeAlternatePowerBar or UNIT_FRAME_SHOW_HEALTH_ONLY then return end
					if showBar then
						-- Use the Blizzard frame art that has room for a third bar
						container.FrameTexture:Hide()
						container.AlternatePowerFrameTexture:Show()
						container.FrameFlash:SetAtlas("UI-HUD-UnitFrame-Player-PortraitOn-ClassResource-InCombat", TextureKitConstants.UseAtlasSize)
						container.FrameFlash:SetPoint("CENTER", container, "CENTER", -2, 0.5)
						manaBar.ManaBarMask:SetAtlas("Unit_BarMask", TextureKitConstants.UseAtlasSize)
					else
						-- Restore the standard Blizzard frame art
						container.AlternatePowerFrameTexture:Hide()
						container.FrameTexture:Show()
						container.FrameFlash:SetAtlas("UI-HUD-UnitFrame-Player-PortraitOn-InCombat", TextureKitConstants.UseAtlasSize)
						container.FrameFlash:SetPoint("CENTER", container, "CENTER", -1.5, 1)
						manaBar.ManaBarMask:SetAtlas("UI-HUD-UnitFrame-Player-PortraitOn-Bar-Mana-Mask", TextureKitConstants.UseAtlasSize)
					end
				end

				-- Function to get mana percentage (uses secret-safe API if it exists)
				local function GetManaPercent()
					if UnitPowerPercent and CurveConstants and CurveConstants.ScaleTo100 then
						return UnitPowerPercent("player", Enum.PowerType.Mana, false, CurveConstants.ScaleTo100)
					end
					local cur, max = UnitPower("player", Enum.PowerType.Mana), UnitPowerMax("player", Enum.PowerType.Mana)
					if issecretvalue and (issecretvalue(cur) or issecretvalue(max)) then return end
					if max > 0 then return cur / max * 100 end
					return 0
				end

				-- Function to update status text using the game status text setting (read only)
				local isMouseOver = false
				local function UpdateText()
					local mode = C_CVar.GetCVar("statusTextDisplay")
					if not mode then
						mode = C_CVar.GetCVar("statusText") == "1" and "NUMERIC" or "NONE"
					end
					if mode == "NONE" and isMouseOver then mode = "NUMERIC" end

					bar.TextString:Hide(); bar.LeftText:Hide(); bar.RightText:Hide()

					if mode == "NUMERIC" then
						bar.TextString:SetFormattedText("%s / %s", UnitPower("player", Enum.PowerType.Mana), UnitPowerMax("player", Enum.PowerType.Mana))
						bar.TextString:Show()
					elseif mode == "PERCENT" then
						local percent = GetManaPercent()
						if percent then
							bar.TextString:SetFormattedText("%.0f%%", percent)
							bar.TextString:Show()
						end
					elseif mode == "BOTH" then
						local percent = GetManaPercent()
						if percent then
							bar.LeftText:SetFormattedText("%.0f%%", percent)
							bar.LeftText:Show()
						end
						bar.RightText:SetFormattedText("%s", UnitPower("player", Enum.PowerType.Mana))
						bar.RightText:Show()
					end
				end

				-- Function to update mana values (no arithmetic or comparisons so secret values are safe)
				local function UpdateValue()
					bar:SetMinMaxValues(0, UnitPowerMax("player", Enum.PowerType.Mana))
					bar:SetValue(UnitPower("player", Enum.PowerType.Mana))
					UpdateText()
				end

				-- Function to show bar when primary power is rage or energy
				local function UpdatePowerType()
					local powerType = UnitPowerType("player")
					local show = (powerType == Enum.PowerType.Rage or powerType == Enum.PowerType.Energy) and PlayerFrame.state ~= "vehicle"
					if show then UpdateValue() end
					bar:SetShown(show)
					SetFrameArt(show)
				end

				-- Reapply frame art after Blizzard resets it
				if PlayerFrame_ToPlayerArt then
					hooksecurefunc("PlayerFrame_ToPlayerArt", UpdatePowerType)
				end

				-- Show status text on mouseover when status text is set to none (clicks pass through to player frame)
				bar:SetMouseMotionEnabled(true)
				bar:SetMouseClickEnabled(false)
				bar:SetScript("OnEnter", function() isMouseOver = true; UpdateText() end)
				bar:SetScript("OnLeave", function() isMouseOver = false; UpdateText() end)

				-- Register events (hidden frames still receive events)
				bar:RegisterEvent("PLAYER_ENTERING_WORLD")
				bar:RegisterEvent("CVAR_UPDATE")
				bar:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
				bar:RegisterUnitEvent("UNIT_MAXPOWER", "player")
				bar:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
				bar:SetScript("OnEvent", function(self, event)
					if event == "PLAYER_ENTERING_WORLD" or event == "UNIT_DISPLAYPOWER" then
						UpdatePowerType()
					elseif bar:IsShown() then
						UpdateValue()
					end
				end)

				-- Run on startup
				UpdatePowerType()

			end

		end

		----------------------------------------------------------------------
		-- Automatically release in battlegrounds
		----------------------------------------------------------------------

		do

			-- Create configuration panel
			local ReleasePanel = LeaPlusLC:CreatePanel("Release in PvP", "ReleasePanel")

			LeaPlusLC:MakeTx(ReleasePanel, "Settings", 16, -72)
			LeaPlusLC:MakeCB(ReleasePanel, "AutoReleaseNoAlterac", "Exclude Alterac Valley", 16, -92, false, "If checked, you will not release automatically in Alterac Valley.")
			-- Debug -- LeaPlusLC:MakeCB(ReleasePanel, "AutoReleaseNoStormwind", "Exclude Stormwind (debug)", 16, -172, false, "If checked, you will not release automatically in Stormwind.")

			LeaPlusLC:MakeTx(ReleasePanel, "Delay", 356, -72)
			LeaPlusLC:MakeSL(ReleasePanel, "AutoReleaseDelay", "Drag to set the number of milliseconds before you are automatically released.|n|nYou can hold down shift as the timer is ending to cancel the automatic release.", 0, 3000, 100, 356, -92, "%.0f")

			-- Help button hidden
			ReleasePanel.h:Hide()

			-- Back button handler
			ReleasePanel.b:SetScript("OnClick", function()
				ReleasePanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page1"]:Show();
				return
			end)

			-- Reset button handler
			ReleasePanel.r:SetScript("OnClick", function()

				-- Reset checkboxes
				LeaPlusLC["AutoReleaseNoAlterac"] = "Off"
				LeaPlusLC["AutoReleaseDelay"] = 0

				-- Refresh panel
				ReleasePanel:Hide(); ReleasePanel:Show()

			end)

			-- Show panal when options panel button is clicked
			LeaPlusCB["AutoReleasePvPBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["AutoReleaseNoAlterac"] = "Off"
					LeaPlusLC["AutoReleaseDelay"] = 0
				else
					ReleasePanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

			-- Release in battlegrounds
			hooksecurefunc("StaticPopup_Show", function(sType)
				if sType and sType == "DEATH" and LeaPlusLC["AutoReleasePvP"] == "On" then
					if C_DeathInfo.GetSelfResurrectOptions() and #C_DeathInfo.GetSelfResurrectOptions() > 0 then return end
					local InstStat, InstType = IsInInstance()
					-- if not CommentOutToRemoveDebugOnlyMode then InstStat = true; InstType = "pvp" end -- (DEBUG ONLY)
					if InstStat and InstType == "pvp" then
						-- Exclude specific maps
						local mapID = C_Map.GetBestMapForUnit("player") or nil
						if mapID then
							if mapID == 91 and LeaPlusLC["AutoReleaseNoAlterac"] == "On" then return end -- Alterac Valley
							if mapID == 1537 and LeaPlusLC["AutoReleaseNoAlterac"] == "On" then return end -- Alterac Valley
							-- if mapID == 84 then return end -- Exclude Stormwind (DEBUG ONLY)
						end
						-- Release automatically in PvP
						local delay = LeaPlusLC["AutoReleaseDelay"] / 1000
						C_Timer.After(delay, function()
							local dialog = StaticPopup_Visible("DEATH")
							if dialog then
								if IsShiftKeyDown() then
									LeaPlusLC:DisplayMessage(L["Automatic Release Cancelled"], true)
								else
									StaticPopup_OnClick(_G[dialog], 1)
								end
							end
						end)
					end
					-- LeaPlusLC.NewPatch - This block was used for releasing in world zones like Wintergrasp, Tol Barad and Ashran
					-- Uncomment the entire block to add world zones if needed in future
					--[[local areaID = C_Map.GetBestMapForUnit("player") or 0
					if areaID == 84 and LeaPlusLC["AutoReleaseNoStormwind"] == "Off" -- Stormwind
					then
						-- Release automatically in world zones
						local delay = LeaPlusLC["AutoReleaseDelay"] / 1000
						C_Timer.After(delay, function()
							local dialog = StaticPopup_Visible("DEATH")
							if dialog then
								if IsShiftKeyDown() then
									LeaPlusLC:DisplayMessage(L["Automatic Release Cancelled"], true)
								else
									StaticPopup_OnClick(_G[dialog], 1)
								end
							end
						end)
					end]]
				end
			end)

		end

		----------------------------------------------------------------------
		--	Set weather density (no reload required)
		----------------------------------------------------------------------

		do

			-- Create configuration panel
			local weatherPanel = LeaPlusLC:CreatePanel("Set weather density", "weatherPanel")
			LeaPlusLC:MakeTx(weatherPanel, "Settings", 16, -72)
			LeaPlusLC:MakeSL(weatherPanel, "WeatherLevel", "Drag to set the density of weather effects.", 0, 3, 1, 16, -92, "%.0f")

			local weatherSliderTable = {L["Very Low"], L["Low"], L["Medium"], L["High"]}

			-- Function to set the weather density
			local function SetWeatherFunc()
				LeaPlusCB["WeatherLevel"].f:SetText(LeaPlusLC["WeatherLevel"] .. "  (" .. weatherSliderTable[LeaPlusLC["WeatherLevel"] + 1] .. ")")
				if LeaPlusLC["SetWeatherDensity"] == "On" then
					SetCVar("WeatherDensity", LeaPlusLC["WeatherLevel"])
					SetCVar("RAIDweatherDensity", LeaPlusLC["WeatherLevel"])
				else
					SetCVar("WeatherDensity", "3")
					SetCVar("RAIDweatherDensity", "3")
				end
			end

			-- Set weather density when options are clicked and on startup if option is enabled
			LeaPlusCB["SetWeatherDensity"]:HookScript("OnClick", SetWeatherFunc)
			LeaPlusCB["WeatherLevel"]:HookScript("OnValueChanged", SetWeatherFunc)
			if LeaPlusLC["SetWeatherDensity"] == "On" then SetWeatherFunc() end

			-- Prevent weather density from being changed when particle density is changed
			hooksecurefunc("SetCVar", function(setting, value)
				if setting and LeaPlusLC["SetWeatherDensity"] == "On" then
					if setting == "graphicsParticleDensity" then
						if GetCVar("WeatherDensity") ~= LeaPlusLC["WeatherLevel"] then
							C_Timer.After(0.1, function()
								SetCVar("WeatherDensity", LeaPlusLC["WeatherLevel"])
							end)
						end
					elseif setting == "raidGraphicsParticleDensity" then
						if GetCVar("RAIDweatherDensity") ~= LeaPlusLC["WeatherLevel"] then
							C_Timer.After(0.1, function()
								SetCVar("RAIDweatherDensity", LeaPlusLC["WeatherLevel"])
							end)
						end
					end
				end
			end)

			-- Help button hidden
			weatherPanel.h:Hide()

			-- Back button handler
			weatherPanel.b:SetScript("OnClick", function()
				weatherPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page7"]:Show()
				return
			end)

			-- Reset button handler
			weatherPanel.r:SetScript("OnClick", function()

				-- Reset slider
				LeaPlusLC["WeatherLevel"] = 3

				-- Refresh side panel
				weatherPanel:Hide(); weatherPanel:Show()

			end)

			-- Show configuration panal when options panel button is clicked
			LeaPlusCB["SetWeatherDensityBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["WeatherLevel"] = 0
					SetWeatherFunc()
				else
					weatherPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

		end

		----------------------------------------------------------------------
		--	Remove raid restrictions (no reload required)
		----------------------------------------------------------------------

		do

			-- Function to set raid restrictions
			local function SetRaidFunc()
				if LeaPlusLC["NoRaidRestrictions"] == "On" then
					SetAllowLowLevelRaid(true)
				else
					SetAllowLowLevelRaid(false)
				end
			end

			-- Run function when option is clicked and on startup (if enabled)
			LeaPlusCB["NoRaidRestrictions"]:HookScript("OnClick", SetRaidFunc)
			if LeaPlusLC["NoRaidRestrictions"] == "On" then SetRaidFunc() end

		end

		----------------------------------------------------------------------
		-- Disable drunken haze (no reload required)
		----------------------------------------------------------------------

		do

			-- Function to set drunken haze
			local function SetDrunkenHaze()
				if LeaPlusLC["NoDrunkenHaze"] == "On" then
					SetCVar("ffxGlow", "0")
				else
					SetCVar("ffxGlow", "1")
				end
			end

			-- Set drunken haze on startup and when option is clicked (if enabled)
			LeaPlusCB["NoDrunkenHaze"]:HookScript("OnClick", SetDrunkenHaze)
			if LeaPlusLC["NoDrunkenHaze"] == "On" then SetDrunkenHaze() end

		end

		----------------------------------------------------------------------
		-- Disable screen effects (no reload required)
		----------------------------------------------------------------------

		do

			-- Function to set screen effects
			local function SetEffects()
				if LeaPlusLC["NoScreenEffects"] == "On" then
					SetCVar("ffxDeath", "0")
					SetCVar("ffxNether", "0")
				else
					SetCVar("ffxDeath", "1")
					SetCVar("ffxNether", "1")
				end
			end

			-- Set screen effects when option is clicked and on startup (if enabled)
			LeaPlusCB["NoScreenEffects"]:HookScript("OnClick", SetEffects)
			if LeaPlusLC["NoScreenEffects"] == "On" then SetEffects() end

		end

		----------------------------------------------------------------------
		--	Max camera zoom (no reload required)
		----------------------------------------------------------------------

		do

			-- Function to set camera zoom
			local function SetZoom()
				if LeaPlusLC["MaxCameraZoom"] == "On" then
					SetCVar("cameraDistanceMaxZoomFactor", 2.6)
				else
					SetCVar("cameraDistanceMaxZoomFactor", 1.9)
				end
			end

			-- Set camera zoom when option is clicked and on startup (if enabled)
			LeaPlusCB["MaxCameraZoom"]:HookScript("OnClick", SetZoom)
			if LeaPlusLC["MaxCameraZoom"] == "On" then SetZoom() end

		end

		----------------------------------------------------------------------
		-- Universal group chat color (no reload required)
		----------------------------------------------------------------------

		do

			-- Function to set chat colors
			local function SetCol()
				if LeaPlusLC["UnivGroupColor"] == "On" then
					ChangeChatColor("RAID", 0.67, 0.67, 1)
					ChangeChatColor("RAID_LEADER", 0.46, 0.78, 1)
					ChangeChatColor("INSTANCE_CHAT", 0.67, 0.67, 1)
					ChangeChatColor("INSTANCE_CHAT_LEADER", 0.46, 0.78, 1)
				else
					ChangeChatColor("RAID", 1, 0.50, 0)
					ChangeChatColor("RAID_LEADER", 1, 0.28, 0.04)
					ChangeChatColor("INSTANCE_CHAT", 1, 0.50, 0)
					ChangeChatColor("INSTANCE_CHAT_LEADER", 1, 0.28, 0.04)
				end
			end

			-- Set chat colors when option is clicked and on startup (if enabled)
			LeaPlusCB["UnivGroupColor"]:HookScript("OnClick", SetCol)
			if LeaPlusLC["UnivGroupColor"] == "On" then	SetCol() end

		end

		----------------------------------------------------------------------
		-- Minimap button (no reload required)
		----------------------------------------------------------------------

		do

			-- Minimap button click function
			local function MiniBtnClickFunc(arg1, arg2)

				if arg1 == "Leatrix_Plus" then arg1 = "LeftButton" end -- Needed for compartment menu clicks

				-- Prevent options panel from showing if Blizzard Store is showing
				if StoreFrame and StoreFrame:GetAttribute("isshown") then return end
				-- Left button down
				if arg1 == "LeftButton" or arg2 and arg2 == "LeftButton" then

					-- Control key toggles target tracking
					if IsControlKeyDown() and not IsShiftKeyDown() and not IsAltKeyDown() then
						for i = 1, C_Minimap.GetNumTrackingTypes() do
							local trackingInfo = C_Minimap.GetTrackingInfo(i)
							if trackingInfo.name and trackingInfo.name == MINIMAP_TRACKING_TARGET then
								if trackingInfo.active then
									C_Minimap.SetTracking(i, false)
									LeaPlusLC:DisplayMessage(L["Target Tracking Disabled"], true)
								else
									C_Minimap.SetTracking(i, true)
									LeaPlusLC:DisplayMessage(L["Target Tracking Enabled"], true)
								end
							end
						end
						return
					end

					-- Shift key toggles music
					if IsShiftKeyDown() and not IsControlKeyDown() and not IsAltKeyDown() then
						Sound_ToggleMusic()
						return
					end

					-- Control key and alt key toggles Zygor addon
					if IsControlKeyDown() and IsAltKeyDown() and not IsShiftKeyDown() then
						LeaPlusLC:ZygorToggle()
						return
					end

					-- Alt key toggles error messages
					if IsAltKeyDown() and not IsControlKeyDown() and not IsShiftKeyDown() then
						if LeaPlusDB["HideErrorMessages"] == "On" then -- Checks global
							if LeaPlusLC["ShowErrorsFlag"] == 1 then
								LeaPlusLC["ShowErrorsFlag"] = 0
								LeaPlusLC:DisplayMessage(L["Error messages will be shown"], true)
							else
								LeaPlusLC["ShowErrorsFlag"] = 1
								LeaPlusLC:DisplayMessage(L["Error messages will be hidden"], true)
							end
							return
						end
						return
					end

					-- Control key and shift key toggles maximised window mode
					if IsControlKeyDown() and IsShiftKeyDown() and not IsAltKeyDown() then
						if LeaPlusLC:PlayerInCombat() then
							return
						else
							SetCVar("gxMaximize", tostring(1 - GetCVar("gxMaximize")))
							UpdateWindow()
						end
						return
					end

					-- No modifier key toggles the options panel
					if LeaPlusLC:IsPlusShowing() then
						LeaPlusLC:HideFrames()
						LeaPlusLC:HideConfigPanels()
					else
						LeaPlusLC:HideFrames()
						LeaPlusLC["PageF"]:Show()
					end
					LeaPlusLC["Page"..LeaPlusLC["LeaStartPage"]]:Show()
				end

				-- Right button down
				if arg1 == "RightButton" or arg2 and arg2 == "RightButton" then

					-- No modifier key toggles the options panel
					if LeaPlusLC:IsPlusShowing() then
						LeaPlusLC:HideFrames()
						LeaPlusLC:HideConfigPanels()
					else
						LeaPlusLC:HideFrames()
						LeaPlusLC["PageF"]:Show()
					end
					LeaPlusLC["Page" .. LeaPlusLC["LeaStartPage"]]:Show()

				end

			end

			-- Assign global scope for function (it's used in TOC)
			_G.LeaPlusGlobalMiniBtnClickFunc = MiniBtnClickFunc

			-- Create minimap button using LibDBIcon
			local miniButton = LibStub("LibDataBroker-1.1"):NewDataObject("Leatrix_Plus", {
				type = "data source",
				text = "Leatrix Plus",
				icon = "Interface\\HELPFRAME\\ReportLagIcon-Movement",
				OnClick = function(self, btn)
					MiniBtnClickFunc(btn)
				end,
				OnTooltipShow = function(tooltip)
					if not tooltip or not tooltip.AddLine then return end
					tooltip:AddLine("Leatrix Plus")
				end,
			})

			local icon = LibStub("LibDBIcon-1.0", true)
			icon:Register("Leatrix_Plus", miniButton, LeaPlusDB)

			-- Function to toggle LibDBIcon
			local function SetLibDBIconFunc()
				if LeaPlusLC["ShowMinimapIcon"] == "On" then
					LeaPlusDB["hide"] = false
					icon:Show("Leatrix_Plus")
				else
					LeaPlusDB["hide"] = true
					icon:Hide("Leatrix_Plus")
				end
			end

			-- Set LibDBIcon when option is clicked and on startup
			LeaPlusCB["ShowMinimapIcon"]:HookScript("OnClick", SetLibDBIconFunc)
			SetLibDBIconFunc()

		end

		----------------------------------------------------------------------
		-- Show volume control on character frame
		----------------------------------------------------------------------

		if LeaPlusLC["ShowVolume"] == "On" then

			-- Function to update master volume
			local function MasterVolUpdate()
				if LeaPlusLC["ShowVolume"] == "On" then
					-- Set the volume
					SetCVar("Sound_MasterVolume", LeaPlusLC["LeaPlusMaxVol"]);
					-- Format the slider text
					LeaPlusCB["LeaPlusMaxVol"].f:SetFormattedText("%.0f", LeaPlusLC["LeaPlusMaxVol"] * 20)
				end
			end

			-- Create slider control
			LeaPlusLC["LeaPlusMaxVol"] = tonumber(GetCVar("Sound_MasterVolume"))
			LeaPlusLC:MakeSL(CharacterModelScene, "LeaPlusMaxVol", "",	0, 1, 0.05, -34, -328, "%.2f")
			LeaPlusCB["LeaPlusMaxVol"]:SetWidth(64)

			-- Set slider control value when shown
			LeaPlusCB["LeaPlusMaxVol"]:SetScript("OnShow", function()
				LeaPlusCB["LeaPlusMaxVol"]:SetValue(GetCVar("Sound_MasterVolume"))
			end)

			-- Update volume when slider control is changed
			LeaPlusCB["LeaPlusMaxVol"]:HookScript("OnValueChanged", function()
				if IsMouseButtonDown("RightButton") and IsShiftKeyDown() then
					-- Dual layout is active so don't adjust slider
					LeaPlusCB["LeaPlusMaxVol"].f:SetFormattedText("%.0f", LeaPlusLC["LeaPlusMaxVol"] * 20)
					LeaPlusCB["LeaPlusMaxVol"]:Hide()
					LeaPlusCB["LeaPlusMaxVol"]:Show()
					return
				else
					-- Set sound level and refresh slider
					MasterVolUpdate()
				end
			end)

			-- Dual layout
			local function SetVolumePlacement()
				LeaPlusCB["LeaPlusMaxVol"]:ClearAllPoints()
				if LeaPlusLC["ShowVolumeInFrame"] == "On" then
					-- Just left of the main hand slot, above the weapon row
					LeaPlusCB["LeaPlusMaxVol"]:SetPoint("BOTTOM", CharacterSecondaryHandSlot, "TOP", 0, 8)
				else
					-- Bottom left corner of the character pane, level with the weapon row
					LeaPlusCB["LeaPlusMaxVol"]:SetPoint("TOPLEFT", CharacterFrame.LeftPaneHost, "BOTTOMLEFT", 14, 34)
				end
			end

			LeaPlusCB["LeaPlusMaxVol"]:SetScript('OnMouseDown', function(self, btn)
				if btn == "RightButton" and IsShiftKeyDown() then
					if LeaPlusLC["ShowVolumeInFrame"] == "On" then LeaPlusLC["ShowVolumeInFrame"] = "Off" else LeaPlusLC["ShowVolumeInFrame"] = "On" end
					SetVolumePlacement();
				end
			end)

			CharacterModelScene:HookScript("OnShow",function()
				SetVolumePlacement()
			end)

			-- ElvUI skin for slider control
			if LeaPlusLC.ElvUI then
				_G.LeaPlusGlobalVolumeButton = LeaPlusCB["LeaPlusMaxVol"]
				LeaPlusLC.ElvUI:GetModule("Skins"):HandleSliderFrame(_G.LeaPlusGlobalVolumeButton, false)
			end

		end

		----------------------------------------------------------------------
		--	Use arrow keys in chat
		----------------------------------------------------------------------

		if LeaPlusLC["UseArrowKeysInChat"] == "On" and not LeaLockList["UseArrowKeysInChat"] then
			-- Enable arrow keys for normal and existing chat frames
			for i = 1, 50 do
				if _G["ChatFrame" .. i] then
					_G["ChatFrame" .. i .. "EditBox"]:SetAltArrowKeyMode(false)
				end
			end
			-- Enable arrow keys for temporary chat frames
			hooksecurefunc("FCF_OpenTemporaryWindow", function()
				local cf = FCF_GetCurrentChatFrame():GetName() or nil
				if cf then
					_G[cf .. "EditBox"]:SetAltArrowKeyMode(false)
				end
			end)
		end

		----------------------------------------------------------------------
		-- Hide social button
		----------------------------------------------------------------------

		if LeaPlusLC["NoSocialButton"] == "On" and not LeaLockList["NoSocialButton"] then
			-- Create hidden frame to store social button
			local tframe = CreateFrame("FRAME")
			tframe:Hide()
			QuickJoinToastButton:SetParent(tframe)
		end

		----------------------------------------------------------------------
		-- L43: Manage widget top
		----------------------------------------------------------------------

		if LeaPlusLC["ManageWidgetTop"] == "On" and not LeaLockList["ManageWidgetTop"] then

			-- Create and manage container for UIWidgetTopCenterContainerFrame
			local topCenterHolder = CreateFrame("Frame", nil, UIParent)
			topCenterHolder:SetPoint("TOP", UIParent, "TOP", 0, -15)
			topCenterHolder:SetSize(10, 58)

			local topCenterContainer = _G.UIWidgetTopCenterContainerFrame
			topCenterContainer:ClearAllPoints()
			topCenterContainer:SetPoint('CENTER', topCenterHolder)

			hooksecurefunc(topCenterContainer, 'SetPoint', function(self, void, b)
				if b and (b ~= topCenterHolder) then
					-- Reset parent if it changes from topCenterHolder
					self:ClearAllPoints()
					self:SetPoint('CENTER', topCenterHolder)
					self:SetParent(topCenterHolder)
				end
			end)

			-- Allow widget frame to be moved
			topCenterHolder:SetMovable(true)
			topCenterHolder:SetUserPlaced(true)
			topCenterHolder:SetDontSavePosition(true)
			topCenterHolder:SetClampedToScreen(false)

			-- Set widget frame position at startup
			topCenterHolder:ClearAllPoints()
			topCenterHolder:SetPoint(LeaPlusLC["WidgetTopA"], UIParent, LeaPlusLC["WidgetTopR"], LeaPlusLC["WidgetTopX"], LeaPlusLC["WidgetTopY"])
			topCenterHolder:SetScale(LeaPlusLC["WidgetTopScale"])
			UIWidgetTopCenterContainerFrame:SetScale(LeaPlusLC["WidgetTopScale"])

			-- Create drag frame
			local dragframe = CreateFrame("FRAME", nil, nil, "BackdropTemplate")
			dragframe:SetPoint("CENTER", topCenterHolder, "CENTER", 0, 1)
			dragframe:SetBackdropColor(0.0, 0.5, 1.0)
			dragframe:SetBackdrop({edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = false, tileSize = 0, edgeSize = 16, insets = { left = 0, right = 0, top = 0, bottom = 0}})
			dragframe:SetToplevel(true)
			dragframe:Hide()
			dragframe:SetScale(LeaPlusLC["WidgetTopScale"])

			dragframe.t = dragframe:CreateTexture()
			dragframe.t:SetAllPoints()
			dragframe.t:SetColorTexture(0.0, 1.0, 0.0, 0.5)
			dragframe.t:SetAlpha(0.5)

			dragframe.f = dragframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
			dragframe.f:SetPoint('CENTER', 0, 0)
			dragframe.f:SetText(L["Widget Top"])

			-- Click handler
			dragframe:SetScript("OnMouseDown", function(self, btn)
				-- Start dragging if left clicked
				if btn == "LeftButton" then
					topCenterHolder:StartMoving()
				end
			end)

			dragframe:SetScript("OnMouseUp", function()
				-- Save frame position
				topCenterHolder:StopMovingOrSizing()
				LeaPlusLC["WidgetTopA"], void, LeaPlusLC["WidgetTopR"], LeaPlusLC["WidgetTopX"], LeaPlusLC["WidgetTopY"] = topCenterHolder:GetPoint()
				topCenterHolder:SetMovable(true)
				topCenterHolder:ClearAllPoints()
				topCenterHolder:SetPoint(LeaPlusLC["WidgetTopA"], UIParent, LeaPlusLC["WidgetTopR"], LeaPlusLC["WidgetTopX"], LeaPlusLC["WidgetTopY"])
			end)

			-- Snap-to-grid
			do
				local frame, grid = dragframe, 10
				local w, h = 0, 60
				local xpos, ypos, scale, uiscale
				frame:RegisterForDrag("RightButton")
				frame:HookScript("OnDragStart", function()
					frame:SetScript("OnUpdate", function()
						scale, uiscale = frame:GetScale(), UIParent:GetScale()
						xpos, ypos = GetCursorPosition()
						xpos = floor((xpos / scale / uiscale) / grid) * grid - w / 2
						ypos = ceil((ypos / scale / uiscale) / grid) * grid + h / 2
						topCenterHolder:ClearAllPoints()
						topCenterHolder:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", xpos, ypos)
					end)
				end)
				frame:HookScript("OnDragStop", function()
					frame:SetScript("OnUpdate", nil)
					frame:GetScript("OnMouseUp")()
				end)
			end

			-- Create configuration panel
			local WidgetTopPanel = LeaPlusLC:CreatePanel("Manage widget top", "WidgetTopPanel")

			-- Create Titan Panel screen adjust warning
			local titanFrame = CreateFrame("FRAME", nil, WidgetTopPanel)
			titanFrame:SetAllPoints()
			titanFrame:Hide()
			LeaPlusLC:MakeTx(titanFrame, "Warning", 16, -172)
			titanFrame.txt = LeaPlusLC:MakeWD(titanFrame, "Titan Panel frame adjustment needs to be disabled.", 16, -192, 500)
			titanFrame.txt:SetWordWrap(false)
			titanFrame.txt:SetWidth(520)
			titanFrame.btn = LeaPlusLC:CreateButton("fixTitanBtn", titanFrame, "Okay, disable frame adjustment for me", "TOPLEFT", 16, -212, 0, 25, true, "Click to disable Titan Panel frame adjustment.  Your UI will be reloaded.")
			titanFrame.btn:SetScript("OnClick", function()
				if C_AddOns.IsAddOnLoaded("Titan") and TitanPlayerSettings and TitanPlayerSettings.Adjust and TitanPlayerSettings.Adjust.UIWidgetTopCenterContainerFrame and TitanPlayerSettings.Adjust.UIWidgetTopCenterContainerFrame.adjust then
					TitanPlayerSettings.Adjust.UIWidgetTopCenterContainerFrame.adjust = false
					ReloadUI()
				end
			end)

			LeaPlusLC:MakeTx(WidgetTopPanel, "Scale", 16, -72)
			LeaPlusLC:MakeSL(WidgetTopPanel, "WidgetTopScale", "Drag to set the widget top scale.", 0.5, 2, 0.05, 16, -92, "%.2f")

			-- Set scale when slider is changed
			LeaPlusCB["WidgetTopScale"]:HookScript("OnValueChanged", function()
				topCenterHolder:SetScale(LeaPlusLC["WidgetTopScale"])
				UIWidgetTopCenterContainerFrame:SetScale(LeaPlusLC["WidgetTopScale"])
				dragframe:SetScale(LeaPlusLC["WidgetTopScale"])
				-- Show formatted slider value
				LeaPlusCB["WidgetTopScale"].f:SetFormattedText("%.0f%%", LeaPlusLC["WidgetTopScale"] * 100)
			end)

			-- Hide frame alignment grid with panel
			WidgetTopPanel:HookScript("OnHide", function()
				LeaPlusLC.grid:Hide()
			end)

			-- Toggle grid button
			local WidgetTopToggleGridButton = LeaPlusLC:CreateButton("WidgetTopToggleGridButton", WidgetTopPanel, "Toggle Grid", "TOPLEFT", 16, -72, 0, 25, true, "Click to toggle the frame alignment grid.")
			LeaPlusCB["WidgetTopToggleGridButton"]:ClearAllPoints()
			LeaPlusCB["WidgetTopToggleGridButton"]:SetPoint("LEFT", WidgetTopPanel.h, "RIGHT", 10, 0)
			LeaPlusCB["WidgetTopToggleGridButton"]:SetScript("OnClick", function()
				if LeaPlusLC.grid:IsShown() then LeaPlusLC.grid:Hide() else LeaPlusLC.grid:Show() end
			end)
			WidgetTopPanel:HookScript("OnHide", function()
				if LeaPlusLC.grid then LeaPlusLC.grid:Hide() end
			end)

			-- Help button tooltip
			WidgetTopPanel.h.tiptext = L["Drag the frame overlay with the left button to position it freely or with the right button to position it using snap-to-grid."]

			-- Back button handler
			WidgetTopPanel.b:SetScript("OnClick", function()
				WidgetTopPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page6"]:Show()
				return
			end)

			-- Reset button handler
			WidgetTopPanel.r:SetScript("OnClick", function()

				-- Reset position and scale
				LeaPlusLC["WidgetTopA"] = "TOP"
				LeaPlusLC["WidgetTopR"] = "TOP"
				LeaPlusLC["WidgetTopX"] = 0
				LeaPlusLC["WidgetTopY"] = -15
				LeaPlusLC["WidgetTopScale"] = 1
				topCenterHolder:ClearAllPoints()
				topCenterHolder:SetPoint(LeaPlusLC["WidgetTopA"], UIParent, LeaPlusLC["WidgetTopR"], LeaPlusLC["WidgetTopX"], LeaPlusLC["WidgetTopY"])

				-- Refresh configuration panel
				WidgetTopPanel:Hide(); WidgetTopPanel:Show()
				dragframe:Show()

				-- Show frame alignment grid
				LeaPlusLC.grid:Show()

			end)

			-- Show configuration panel when options panel button is clicked
			LeaPlusCB["ManageWidgetTopButton"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["WidgetTopA"] = "CENTER"
					LeaPlusLC["WidgetTopR"] = "CENTER"
					LeaPlusLC["WidgetTopX"] = 0
					LeaPlusLC["WidgetTopY"] = -160
					LeaPlusLC["WidgetTopScale"] = 1.25
					topCenterHolder:ClearAllPoints()
					topCenterHolder:SetPoint(LeaPlusLC["WidgetTopA"], UIParent, LeaPlusLC["WidgetTopR"], LeaPlusLC["WidgetTopX"], LeaPlusLC["WidgetTopY"])
					topCenterHolder:SetScale(LeaPlusLC["WidgetTopScale"])
					UIWidgetTopCenterContainerFrame:SetScale(LeaPlusLC["WidgetTopScale"])
				else
					-- Show Titan Panel frame adjustment warning if Titan Panel is installed with frame adjustment widget enabled
					if C_AddOns.IsAddOnLoaded("Titan") and TitanPlayerSettings and TitanPlayerSettings.Adjust and TitanPlayerSettings.Adjust.UIWidgetTopCenterContainerFrame and TitanPlayerSettings.Adjust.UIWidgetTopCenterContainerFrame.adjust then
						titanFrame:Show()
					end

					-- Find out if the UI has a non-standard scale
					if GetCVar("useuiscale") == "1" then
						LeaPlusLC["gscale"] = GetCVar("uiscale")
					else
						LeaPlusLC["gscale"] = 1
					end

					-- Set drag frame size according to UI scale
					dragframe:SetWidth(160 * LeaPlusLC["gscale"])
					dragframe:SetHeight(79 * LeaPlusLC["gscale"])

					-- Show configuration panel
					WidgetTopPanel:Show()
					LeaPlusLC:HideFrames()
					dragframe:Show()

					-- Show frame alignment grid
					LeaPlusLC.grid:Show()
				end
			end)

			-- Hide drag frame when configuration panel is closed
			WidgetTopPanel:HookScript("OnHide", function() dragframe:Hide() end)

		end

		----------------------------------------------------------------------
		-- Hide chat buttons
		----------------------------------------------------------------------

		if LeaPlusLC["NoChatButtons"] == "On" and not LeaLockList["NoChatButtons"] then

			-- Create hidden frame to store unwanted frames (more efficient than creating functions)
			local tframe = CreateFrame("FRAME")
			tframe:Hide()

			-- Function to enable mouse scrolling with CTRL and SHIFT key modifiers
			local function AddMouseScroll(chtfrm)
				if _G[chtfrm] then
					_G[chtfrm]:SetScript("OnMouseWheel", function(self, direction)
						if direction == 1 then
							if IsControlKeyDown() then
								self:ScrollToTop()
							elseif IsShiftKeyDown() then
								self:PageUp()
							else
								self:ScrollUp()
							end
						else
							if IsControlKeyDown() then
								self:ScrollToBottom()
							elseif IsShiftKeyDown() then
								self:PageDown()
							else
								self:ScrollDown()
							end
						end
					end)
					_G[chtfrm]:EnableMouseWheel(true)
				end
			end

			-- Function to hide chat buttons
			local function HideButtons(chtfrm)
				_G[chtfrm .. "ButtonFrameMinimizeButton"]:SetParent(tframe)
				_G[chtfrm .. "ButtonFrameMinimizeButton"]:Hide();
				_G[chtfrm .. "ButtonFrame"]:SetSize(0.1,0.1)
				_G[chtfrm].ScrollBar:SetParent(tframe)
				_G[chtfrm].ScrollBar:Hide()
			end

			-- Function to highlight chat tabs and click to scroll to bottom
			local function HighlightTabs(chtfrm)

				-- Hide bottom button
				_G[chtfrm].ScrollToBottomButton:SetSize(0.1, 0.1) -- Positions it away

				-- Remove click from the bottom button
				_G[chtfrm].ScrollToBottomButton:SetScript("OnClick", nil)

				-- Remove textures
				_G[chtfrm].ScrollToBottomButton:SetNormalTexture("")
				_G[chtfrm].ScrollToBottomButton:SetHighlightTexture("")
				_G[chtfrm].ScrollToBottomButton:SetPushedTexture("")
				_G[chtfrm].ScrollToBottomButton:SetDisabledTexture("")

				-- Always scroll to bottom when clicking a tab
				_G[chtfrm .. "Tab"]:HookScript("OnClick", function(self,arg1)
					if arg1 == "LeftButton" then
						_G[chtfrm]:ScrollToBottom()
					end
				end)

				-- Create new bottom button under tab
				_G[chtfrm .. "Tab"].newglow = _G[chtfrm .. "Tab"]:CreateTexture(nil, "BACKGROUND")
				_G[chtfrm .. "Tab"].newglow:ClearAllPoints()
				_G[chtfrm .. "Tab"].newglow:SetAllPoints()
				_G[chtfrm .. "Tab"].newglow:SetTexture("Interface\\ChatFrame\\ChatFrameTab-NewMessage")
				_G[chtfrm .. "Tab"].newglow:SetVertexColor(0.6, 0.6, 1, 0.7)
				_G[chtfrm .. "Tab"].newglow:SetBlendMode("ADD")
				_G[chtfrm .. "Tab"].newglow:Hide()

				-- Show new bottom button when old one glows
				_G[chtfrm].ScrollToBottomButton.Flash:HookScript("OnShow", function(self,arg1)
					_G[chtfrm .. "Tab"].newglow:Show()
				end)

				_G[chtfrm].ScrollToBottomButton.Flash:HookScript("OnHide", function(self,arg1)
					_G[chtfrm .. "Tab"].newglow:Hide()
				end)

			end

			-- Set options for normal and existing chat frames
			for i = 1, 50 do
				if _G["ChatFrame" .. i] then
					AddMouseScroll("ChatFrame" .. i)
					HideButtons("ChatFrame" .. i)
					HighlightTabs("ChatFrame" .. i)
				end
			end

			-- Do the functions above for temporary chat frames
			hooksecurefunc("FCF_OpenTemporaryWindow", function(chatType)
				local cf = FCF_GetCurrentChatFrame():GetName() or nil
				if cf then

					-- Set options for temporary frame
					AddMouseScroll(cf)
					HideButtons(cf)
					HighlightTabs(cf)

					-- Create new bottom button under tab
					_G[cf .. "Tab"].newglow = _G[cf .. "Tab"]:CreateTexture(nil, "BACKGROUND")
					_G[cf .. "Tab"].newglow:ClearAllPoints()
					_G[cf .. "Tab"].newglow:SetAllPoints()
					_G[cf .. "Tab"].newglow:SetTexture("Interface\\ChatFrame\\ChatFrameTab-NewMessage")
					_G[cf .. "Tab"].newglow:SetVertexColor(0.6, 0.6, 1, 1)
					_G[cf .. "Tab"].newglow:SetBlendMode("ADD")
					_G[cf .. "Tab"].newglow:Hide()

					-- Show new bottom button when old one glows
					_G[cf].ScrollToBottomButton.Flash:HookScript("OnShow", function(self,arg1)
						_G[cf .. "Tab"].newglow:Show()
					end)

					_G[cf].ScrollToBottomButton.Flash:HookScript("OnHide", function(self,arg1)
						_G[cf .. "Tab"].newglow:Hide()
					end)

				end
			end)

			-- Hide text to speech button
			TextToSpeechButton:SetParent(tframe)

			-- Move voice chat and chat menu buttons inside the chat frame
			ChatFrameChannelButton:ClearAllPoints()
			ChatFrameChannelButton:SetPoint("TOPRIGHT", ChatFrame1Background, "TOPRIGHT", 1, -3)
			ChatFrameChannelButton:SetSize(26,25)

			ChatFrameToggleVoiceDeafenButton:ClearAllPoints()
			ChatFrameToggleVoiceDeafenButton:SetPoint("TOP", ChatFrameChannelButton, "BOTTOM", 0, -2)
			ChatFrameToggleVoiceDeafenButton:SetSize(26,25)

			ChatFrameToggleVoiceMuteButton:ClearAllPoints()
			ChatFrameToggleVoiceMuteButton:SetPoint("TOP", ChatFrameToggleVoiceDeafenButton, "BOTTOM", 0, -2)
			ChatFrameToggleVoiceMuteButton:SetSize(26,25)

			ChatFrameMenuButton:ClearAllPoints()
			ChatFrameMenuButton:SetPoint("BOTTOMRIGHT", ChatFrame1Background, "BOTTOMRIGHT", 3, 18)
			ChatFrameMenuButton:SetSize(29,29)

			-- Function to set voice chat and chat menu buttons
			local function SetChatButtonFrameButtons()
				if LeaPlusLC["ShowVoiceButtons"] == "On" then
					-- Show voice chat buttons
					ChatFrameChannelButton:SetParent(UIParent)
					ChatFrameToggleVoiceDeafenButton:SetParent(UIParent)
					ChatFrameToggleVoiceMuteButton:SetParent(UIParent)
				else
					-- Hide voice chat buttons
					ChatFrameChannelButton:SetParent(tframe)
					ChatFrameToggleVoiceDeafenButton:SetParent(tframe)
					ChatFrameToggleVoiceMuteButton:SetParent(tframe)
				end
				if LeaPlusLC["ShowChatMenuButton"] == "On" then
					-- Show chat menu button
					ChatFrameMenuButton:SetParent(UIParent)
				else
					-- Hide chat menu button
					ChatFrameMenuButton:SetParent(tframe)
				end
			end

			-- Create configuration panel
			local HideChatButtonsPanel = LeaPlusLC:CreatePanel("Hide chat buttons", "HideChatButtonsPanel")

			-- Add checkboxes
			LeaPlusLC:MakeTx(HideChatButtonsPanel, "General", 16, -72)
			LeaPlusLC:MakeCB(HideChatButtonsPanel, "ShowVoiceButtons", "Show voice chat buttons", 16, -92, false, "If checked, voice chat buttons will be shown.")
			LeaPlusLC:MakeCB(HideChatButtonsPanel, "ShowChatMenuButton", "Show chat menu button", 16, -112, false, "If checked, the chat menu button will be shown.")

			-- Help button hidden
			HideChatButtonsPanel.h:Hide()

			-- Back button handler
			HideChatButtonsPanel.b:SetScript("OnClick", function()
				HideChatButtonsPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page3"]:Show()
				return
			end)

			-- Reset button handler
			HideChatButtonsPanel.r:SetScript("OnClick", function()

				-- Reset checkboxes
				LeaPlusLC["ShowVoiceButtons"] = "Off"
				LeaPlusLC["ShowChatMenuButton"] = "Off"

				-- Refresh panel
				SetChatButtonFrameButtons()
				HideChatButtonsPanel:Hide(); HideChatButtonsPanel:Show()

			end)

			-- Show panal when options panel button is clicked
			LeaPlusCB["NoChatButtonsBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["ShowVoiceButtons"] = "On"
					LeaPlusLC["ShowChatMenuButton"] = "Off"
					SetChatButtonFrameButtons()
				else
					HideChatButtonsPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

			-- Run function when options are clicked and on startup
			LeaPlusCB["ShowVoiceButtons"]:HookScript("OnClick", SetChatButtonFrameButtons)
			LeaPlusCB["ShowChatMenuButton"]:HookScript("OnClick", SetChatButtonFrameButtons)
			SetChatButtonFrameButtons()

		end

		----------------------------------------------------------------------
		-- Recent chat window
		----------------------------------------------------------------------

		if LeaPlusLC["RecentChatWindow"] == "On" and not LeaLockList["RecentChatWindow"] then

			-- Create recent chat frame
			local editFrame = CreateFrame("ScrollFrame", nil, UIParent, "LeaPlusRecentChatScrollFrameTemplate")

			-- Set frame parameters
			editFrame:ClearAllPoints()
			editFrame:SetPoint("BOTTOM", 0, 130)
			editFrame:SetSize(600, LeaPlusLC["RecentChatSize"])
			editFrame:SetFrameStrata("MEDIUM")
			editFrame:SetToplevel(true)
			editFrame:Hide()

			-- Add background color
			editFrame.t = editFrame:CreateTexture(nil, "BACKGROUND")
			editFrame.t:SetAllPoints()
			editFrame.t:SetColorTexture(0.00, 0.00, 0.0, 0.6)

			-- Create title bar
			local titleFrame = CreateFrame("Frame", nil, editFrame)
			titleFrame:ClearAllPoints()
			titleFrame:SetPoint("TOP", 0, 24)
			titleFrame:SetSize(600, 24)
			titleFrame:SetFrameStrata("MEDIUM")
			titleFrame:SetToplevel(true)
			titleFrame:SetHitRectInsets(-6, -6, -6, -6)
			titleFrame.t = titleFrame:CreateTexture(nil, "BACKGROUND")
			titleFrame.t:SetAllPoints()
			titleFrame.t:SetColorTexture(0.00, 0.00, 0.0, 0.8)

			-- Add message count
			titleFrame.m = titleFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
			titleFrame.m:SetPoint("LEFT", 4, 0)
			titleFrame.m:SetText(L["Messages"] .. ": 0")
			titleFrame.m:SetFont(titleFrame.m:GetFont(), 16, nil)

			-- Add right-click to close message
			titleFrame.x = titleFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
			titleFrame.x:SetPoint("RIGHT", -4, 0)
			titleFrame.x:SetText(L["Drag to size"] .. " | " .. L["Right-click to close"])
			titleFrame.x:SetFont(titleFrame.x:GetFont(), 16, nil)
			titleFrame.x:SetWidth(600 - titleFrame.m:GetStringWidth() - 30)
			titleFrame.x:SetWordWrap(false)
			titleFrame.x:SetJustifyH("RIGHT")

			-- Drag to resize
			editFrame:SetResizable(true)
			editFrame:SetResizeBounds(600, 170, 600, 560)

			titleFrame:HookScript("OnMouseDown", function(self, btn)
				if btn == "LeftButton" then
					editFrame:StartSizing("TOP")
				end
			end)
			titleFrame:HookScript("OnMouseUp", function(self, btn)
				if btn == "LeftButton" then
					editFrame:StopMovingOrSizing()
					LeaPlusLC["RecentChatSize"] = editFrame:GetHeight()
				elseif btn == "MiddleButton" then
					-- Reset frame size
					LeaPlusLC["RecentChatSize"] = 170
					editFrame:SetSize(600, LeaPlusLC["RecentChatSize"])
					editFrame:ClearAllPoints()
					editFrame:SetPoint("BOTTOM", 0, 130)
				end
			end)

			-- Create character count
			editFrame.CharCount = editFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
			editFrame.CharCount:Hide()

			-- Create editbox
			local editBox = editFrame.EditBox
			editBox:SetAltArrowKeyMode(false)
			editBox:SetTextInsets(4, 4, 4, 4)
			editBox:SetWidth(editFrame:GetWidth() - 30)
			editBox:SetSecurityDisablePaste()
			editBox:SetMaxLetters(0)

			editFrame:SetScrollChild(editBox)

			-- Manage focus
			editBox:HookScript("OnEditFocusLost", function()
				if titleFrame:IsMouseOver() and IsMouseButtonDown("LeftButton") then
					editBox:SetFocus()
				end
			end)

			-- Close frame with right-click of editframe or editbox
			local function CloseRecentChatWindow()
				editBox:SetText("")
				editBox:ClearFocus()
				editFrame:Hide()
			end

			editFrame:SetScript("OnMouseDown", function(self, btn)
				if btn == "RightButton" then CloseRecentChatWindow() end
			end)

			editBox:SetScript("OnMouseDown", function(self, btn)
				if btn == "RightButton" then CloseRecentChatWindow() end
			end)

			titleFrame:HookScript("OnMouseDown", function(self, btn)
				if btn == "RightButton" then CloseRecentChatWindow() end
			end)

			-- Disable text changes while still allowing editing controls to work
			editBox:EnableKeyboard(false)
			editBox:SetScript("OnKeyDown", function() end)

			-- Populate recent chat frame with chat messages
			local function ShowChatbox(chtfrm)
				editBox:SetText("")
				local NumMsg = chtfrm:GetNumMessages()
				local StartMsg = 1
				if NumMsg > 256 then StartMsg = NumMsg - 255 end
				local totalMsgCount = 0
				for iMsg = StartMsg, NumMsg do
					local chatMessage, r, g, b, chatTypeID = chtfrm:GetMessageInfo(iMsg)
					if chatMessage and canaccessvalue(chatMessage) then

						-- Handle Battle.net messages
						if string.match(chatMessage, "k:(%d+):(%d+):BN_WHISPER:")
						or string.match(chatMessage, "k:(%d+):(%d+):BN_INLINE_TOAST_ALERT:")
						or string.match(chatMessage, "k:(%d+):(%d+):BN_INLINE_TOAST_BROADCAST:")
						then
							local ctype
							if string.match(chatMessage, "k:(%d+):(%d+):BN_WHISPER:") then
								ctype = "BN_WHISPER"
							elseif string.match(chatMessage, "k:(%d+):(%d+):BN_INLINE_TOAST_ALERT:") then
								ctype = "BN_INLINE_TOAST_ALERT"
							elseif string.match(chatMessage, "k:(%d+):(%d+):BN_INLINE_TOAST_BROADCAST:") then
								ctype = "BN_INLINE_TOAST_BROADCAST"
							end
							local id = tonumber(string.match(chatMessage, "k:(%d+):%d+:" .. ctype .. ":"))
							local totalBNFriends = BNGetNumFriends()
							for friendIndex = 1, totalBNFriends do
								local accountInfo = C_BattleNet.GetFriendAccountInfo(friendIndex)
								local bnetAccountID = accountInfo.bnetAccountID
								local battleTag = accountInfo.battleTag
								if id == bnetAccountID then
									battleTag = strsplit("#", battleTag)
									chatMessage = chatMessage:gsub("(|HBNplayer%S-|k)(%d-)(:%S-" .. ctype .. "%S-|h)%[(%S-)%](|?h?)(:?)", "[" .. battleTag .. "]:")
								end
							end
						end

						-- Handle colors
						if r and g and b then
							local colorCode = RGBToColorCode(r, g, b)
							chatMessage = colorCode .. chatMessage
						end

						chatMessage = gsub(chatMessage, "|T.-|t", "") -- Remove textures
						chatMessage = gsub(chatMessage, "|A.-|a", "") -- Remove atlases
						editBox:Insert(chatMessage .. "|r|n")

					end
					totalMsgCount = totalMsgCount + 1
				end
				titleFrame.m:SetText(L["Messages"] .. ": " .. totalMsgCount)
				editFrame:SetVerticalScroll(0)
				editFrame.ScrollBar:ScrollToEnd()
				editFrame:Show()
				editBox:ClearFocus()
			end

			-- Hook normal chat frame tab clicks
			for i = 1, 50 do
				if _G["ChatFrame" .. i] then
					_G["ChatFrame" .. i .. "Tab"]:HookScript("OnClick", function()
						if IsControlKeyDown() then
							editBox:SetFont(_G["ChatFrame" .. i]:GetFont())
							editFrame:SetPanExtent(select(2, _G["ChatFrame" .. i]:GetFont()))
							ShowChatbox(_G["ChatFrame" .. i])
						end
					end)
				end
			end

			-- Hook temporary chat frame tab clicks
			hooksecurefunc("FCF_OpenTemporaryWindow", function()
				local cf = FCF_GetCurrentChatFrame():GetName() or nil
				if cf then
					_G[cf .. "Tab"]:HookScript("OnClick", function()
						if IsControlKeyDown() then
							editBox:SetFont(_G[cf]:GetFont())
							editFrame:SetPanExtent(select(2, _G[cf]:GetFont()))
							ShowChatbox(_G[cf])
						end
					end)
				end
			end)

			-- Add entry to chat menu to show recent chat window
			Menu.ModifyMenu("MENU_FCF_TAB", function(self, rootDescription, contextData)
				rootDescription:CreateDivider()
				rootDescription:CreateTitle(L["Leatrix Plus"])
				local recentChatButton = rootDescription:CreateButton(L["Recent chat window"], function()
					local currentChatFrame = FCF_GetCurrentChatFrame()
					editBox:SetFont(currentChatFrame:GetFont())
					editFrame:SetPanExtent(select(2, currentChatFrame:GetFont()))
					ShowChatbox(currentChatFrame)
				end)
			end)

		end

		----------------------------------------------------------------------
		--	Hide alerts
		----------------------------------------------------------------------

		if LeaPlusLC["NoAlerts"] == "On" then
			hooksecurefunc(AlertFrame, "RegisterEvent", function(self, event)
				AlertFrame:UnregisterEvent(event)
			end)
			AlertFrame:UnregisterAllEvents()
			EventRegistry:UnregisterFrameEvent("NEW_HOUSING_ITEM_ACQUIRED")
		end

		----------------------------------------------------------------------
		-- Combat plates
		----------------------------------------------------------------------

		if LeaPlusLC["CombatPlates"] == "On" then

			-- Toggle nameplates with combat
			local f = CreateFrame("Frame")
			f:RegisterEvent("PLAYER_REGEN_DISABLED")
			f:RegisterEvent("PLAYER_REGEN_ENABLED")
			f:SetScript("OnEvent", function(self, event)
				SetCVar("nameplateShowEnemies", event == "PLAYER_REGEN_DISABLED" and 1 or 0)
			end)

			-- Run combat check on startup
			SetCVar("nameplateShowEnemies", UnitAffectingCombat("player") and 1 or 0)

		end

		----------------------------------------------------------------------
		-- Enhance tooltip
		----------------------------------------------------------------------

		if LeaPlusLC["TipModEnable"] == "On" and not LeaLockList["TipModEnable"] then

			-- Enable mouse hover events for world frame (required for hide tooltips, cursor anchor and maybe other addons)
			WorldFrame:EnableMouseMotion(true)

			----------------------------------------------------------------------
			--	Position the tooltip
			----------------------------------------------------------------------

			-- Position general tooltip
			hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
				if LeaPlusLC["TooltipAnchorMenu"] ~= 1 then
					if (not tooltip or not parent) then
						return
					end
					if WorldFrame:IsMouseMotionFocus() then
						if LeaPlusLC["TooltipAnchorMenu"] == 2 then
							tooltip:SetOwner(parent, "ANCHOR_CURSOR")
							return
						elseif LeaPlusLC["TooltipAnchorMenu"] == 3 then
							tooltip:SetOwner(parent, "ANCHOR_CURSOR_LEFT", LeaPlusLC["TipCursorX"], LeaPlusLC["TipCursorY"])
							return
						elseif LeaPlusLC["TooltipAnchorMenu"] == 4 then
							tooltip:SetOwner(parent, "ANCHOR_CURSOR_RIGHT", LeaPlusLC["TipCursorX"], LeaPlusLC["TipCursorY"])
							return
						end
					end
				end
			end)

			----------------------------------------------------------------------
			--	Tooltip Configuration
			----------------------------------------------------------------------

			local LT = {}

			-- Create locale specific level string
			LT["LevelLocale"] = strtrim(strtrim(string.gsub(TOOLTIP_UNIT_LEVEL, "%%s", "")))
			if GameLocale == "ruRU" then
				LT["LevelLocale"] = "-ro уровня"
			end

			-- Tooltip
			LT["ColorBlind"] = GetCVar("colorblindMode")

			---------------------------------------------------------------------------------------------------------
			-- Tooltip movement settings
			---------------------------------------------------------------------------------------------------------

			-- Create tooltip customisation side panel
			local SideTip = LeaPlusLC:CreatePanel("Enhance tooltip", "SideTip")

			-- Add controls
			LeaPlusLC:MakeTx(SideTip, "Settings", 16, -72)
			LeaPlusLC:MakeCB(SideTip, "TipShowRank", "Show guild ranks for your guild", 16, -92, false, "If checked, guild ranks will be shown for players in your guild.")
			LeaPlusLC:MakeCB(SideTip, "TipShowOtherRank", "Show guild ranks for other guilds", 16, -112, false, "If checked, guild ranks will be shown for players who are not in your guild.")
			LeaPlusLC:MakeCB(SideTip, "TipShowTarget", "Show the unit's target", 16, -132, false, "If checked, unit targets will be shown.")
			LeaPlusLC:MakeCB(SideTip, "TipBackSimple", "Color the backdrops based on faction", 16, -152, false, "If checked, backdrops will be tinted blue (friendly) or red (hostile).")
			LeaPlusLC:MakeCB(SideTip, "TipNoHealthBar", "Hide the health bar", 16, -172, true, "If checked, the health bar will not be shown.")

			-- Show restrictions to tooltips in Forever
			LeaPlusCB["TipShowRank"].tiptext = LeaPlusCB["TipShowRank"].tiptext .. "|n|n" .. L["This setting does not apply during instanced combat encounters."]
			LeaPlusCB["TipShowOtherRank"].tiptext = LeaPlusCB["TipShowOtherRank"].tiptext .. "|n|n" .. L["This setting does not apply during instanced combat encounters."]
			LeaPlusCB["TipShowTarget"].tiptext = LeaPlusCB["TipShowTarget"].tiptext .. "|n|n" .. L["This setting does not apply during instanced combat encounters."]
			LeaPlusCB["TipBackSimple"].tiptext = LeaPlusCB["TipBackSimple"].tiptext .. "|n|n" .. L["This setting does not apply during instanced combat encounters."]

			LeaPlusLC:MakeTx(SideTip, "Hide tooltips", 16, -212)
			LeaPlusLC:MakeCB(SideTip, "TipHideInCombat", "Hide tooltips for world units during combat", 16, -232, false, "If checked, tooltips for world units will be hidden during combat.")
			LeaPlusLC:MakeCB(SideTip, "TipHideShiftOverride", "Show tooltips with shift key", 16, -252, false, "If checked, you can hold shift while tooltips are hidden to show them temporarily.")

			-- Handle show tooltips with shift key lock
			local function SetTipHideShiftOverrideFunc()
				if LeaPlusLC["TipHideInCombat"] == "On" then
					LeaPlusLC:LockItem(LeaPlusCB["TipHideShiftOverride"], false)
				else
					LeaPlusLC:LockItem(LeaPlusCB["TipHideShiftOverride"], true)
				end
			end

			LeaPlusCB["TipHideInCombat"]:HookScript("OnClick", SetTipHideShiftOverrideFunc)
			SetTipHideShiftOverrideFunc()

			LeaPlusLC:CreateDropdown("TooltipAnchorMenu", "Anchor", 146, "TOPLEFT", SideTip, "TOPLEFT", 356, -92, false, {{L["None"], 1}, {L["Cursor"], 2}, {L["Cursor Left"], 3}, {L["Cursor Right"], 4}})

			local XOffsetHeading = LeaPlusLC:MakeTx(SideTip, "X Offset", 356, -132)
			LeaPlusLC:MakeSL(SideTip, "TipCursorX", "Drag to set the cursor X offset.", -128, 128, 1, 356, -152, "%.0f")

			local YOffsetHeading = LeaPlusLC:MakeTx(SideTip, "Y Offset", 356, -182)
			LeaPlusLC:MakeSL(SideTip, "TipCursorY", "Drag to set the cursor Y offset.", -128, 128, 1, 356, -202, "%.0f")

			LeaPlusLC:MakeTx(SideTip, "Scale", 356, -232)
			LeaPlusLC:MakeSL(SideTip, "LeaPlusTipSize", "Drag to set the tooltip scale.", 0.50, 2.00, 0.05, 356, -252, "%.2f")

			-- Function to enable or disable anchor controls
			local function SetAnchorControls()
				-- Set the X and Y sliders
				if LeaPlusLC["TooltipAnchorMenu"] == 1 or LeaPlusLC["TooltipAnchorMenu"] == 2 then
					-- Dropdown is set to none or cursor so disable X and Y offset sliders
					LeaPlusLC:LockItem(LeaPlusCB["TipCursorX"], true)
					LeaPlusLC:LockItem(LeaPlusCB["TipCursorY"], true)
					XOffsetHeading:SetAlpha(0.3)
					YOffsetHeading:SetAlpha(0.3)
					LeaPlusCB["TipCursorX"]:SetScript("OnEnter", nil)
					LeaPlusCB["TipCursorY"]:SetScript("OnEnter", nil)
				else
					-- Dropdown is set to cursor left or cursor right so enable X and Y offset sliders
					LeaPlusLC:LockItem(LeaPlusCB["TipCursorX"], false)
					LeaPlusLC:LockItem(LeaPlusCB["TipCursorY"], false)
					XOffsetHeading:SetAlpha(1.0)
					YOffsetHeading:SetAlpha(1.0)
					LeaPlusCB["TipCursorX"]:SetScript("OnEnter", LeaPlusLC.TipSee)
					LeaPlusCB["TipCursorY"]:SetScript("OnEnter", LeaPlusLC.TipSee)
				end
			end

			-- Set controls when dropdown menu is changed and on startup
			LeaPlusCB["TooltipAnchorMenu"]:RegisterCallback("OnMenuClose", function()
				if not UnitAffectingCombat("player") then
					SetAnchorControls()
				end
			end)
			SetAnchorControls()

			-- Help button hidden
			SideTip.h:Hide()

			-- Back button handler
			SideTip.b:SetScript("OnClick", function()
				SideTip:Hide()
				LeaPlusLC["PageF"]:Show()
				LeaPlusLC["Page5"]:Show()
				return
			end)

			-- Reset button handler
			SideTip.r.tiptext = SideTip.r.tiptext .. "|n|n" .. L["Note that this will not reset settings that require a UI reload."]
			SideTip.r:SetScript("OnClick", function()
				LeaPlusLC["TipShowRank"] = "On"
				LeaPlusLC["TipShowOtherRank"] = "Off"
				LeaPlusLC["TipShowTarget"] = "On"
				LeaPlusLC["TipBackSimple"] = "Off"
				LeaPlusLC["TipHideInCombat"] = "Off"; SetTipHideShiftOverrideFunc()
				LeaPlusLC["TipHideShiftOverride"] = "On"
				LeaPlusLC["LeaPlusTipSize"] = 1.00
				LeaPlusLC["TooltipAnchorMenu"] = 1
				LeaPlusLC["TipCursorX"] = 0
				LeaPlusLC["TipCursorY"] = 0
				SetAnchorControls()
				LeaPlusLC:SetTipScale()
				SideTip:Hide(); SideTip:Show()
			end)

			--	Move the tooltip
			LeaPlusCB["MoveTooltipButton"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["TipShowRank"] = "On"
					LeaPlusLC["TipShowOtherRank"] = "Off"
					LeaPlusLC["TipShowTarget"] = "On"
					LeaPlusLC["TipBackSimple"] = "On"
					LeaPlusLC["TipHideInCombat"] = "Off"; SetTipHideShiftOverrideFunc()
					LeaPlusLC["TipHideShiftOverride"] = "On"
					LeaPlusLC["LeaPlusTipSize"] = 1.25
					LeaPlusLC["TooltipAnchorMenu"] = 1
					LeaPlusLC["TipCursorX"] = 0
					LeaPlusLC["TipCursorY"] = 0
					SetAnchorControls()
					LeaPlusLC:SetTipScale()
					LeaPlusLC:SetDim()
					LeaPlusLC:ReloadCheck()
					SideTip:Show(); SideTip:Hide() -- Needed to update tooltip scale
					LeaPlusLC["PageF"]:Hide(); LeaPlusLC["PageF"]:Show()
				else
					-- Show tooltip configuration panel
					LeaPlusLC:HideFrames()
					SideTip:Show()
				end
			end)

			-- Hide health bar
			if LeaPlusLC["TipNoHealthBar"] == "On" then
				GameTooltipStatusBarTexture:SetTexture("")
			end

			---------------------------------------------------------------------------------------------------------
			-- Tooltip scale settings
			---------------------------------------------------------------------------------------------------------

			-- Function to set the tooltip scale
			local function SetTipScale()

				-- General tooltip
				if GameTooltip then GameTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"]) end

				-- Friends
				if FriendsTooltip then FriendsTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"]) end

				-- AutoCompleteBox
				if AutoCompleteBox then AutoCompleteBox:SetScale(LeaPlusLC["LeaPlusTipSize"]) end

				-- Reputation
				if ReputationParagonTooltip then ReputationParagonTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"]) end

				-- Pet battles and battle pets
				if PetBattlePrimaryAbilityTooltip then PetBattlePrimaryAbilityTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"]) end
				if PetBattlePrimaryUnitTooltip then PetBattlePrimaryUnitTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"]) end
				if BattlePetTooltip then BattlePetTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"]) end
				if FloatingBattlePetTooltip then FloatingBattlePetTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"]) end
				if FloatingPetBattleAbilityTooltip then FloatingPetBattleAbilityTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"]) end

				-- Garrison
				if FloatingGarrisonFollowerTooltip then FloatingGarrisonFollowerTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"]) end
				if FloatingGarrisonFollowerAbilityTooltip then FloatingGarrisonFollowerAbilityTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"]) end
				if FloatingGarrisonMissionTooltip then FloatingGarrisonMissionTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"]) end
				if FloatingGarrisonShipyardFollowerTooltip then FloatingGarrisonShipyardFollowerTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"]) end

				-- Order Hall
				if GarrisonFollowerMissionAbilityWithoutCountersTooltip then GarrisonFollowerMissionAbilityWithoutCountersTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"]) end
				if GarrisonFollowerAbilityWithoutCountersTooltip then GarrisonFollowerAbilityWithoutCountersTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"]) end

				-- Items (links, comparisons)
				if ItemRefTooltip then ItemRefTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"]) end
				if ItemRefShoppingTooltip1 then ItemRefShoppingTooltip1:SetScale(LeaPlusLC["LeaPlusTipSize"]) end
				if ItemRefShoppingTooltip2 then ItemRefShoppingTooltip2:SetScale(LeaPlusLC["LeaPlusTipSize"]) end
				if ShoppingTooltip1 then ShoppingTooltip1:SetScale(LeaPlusLC["LeaPlusTipSize"]) end
				if ShoppingTooltip2 then ShoppingTooltip2:SetScale(LeaPlusLC["LeaPlusTipSize"]) end

				-- World map (story)
				if QuestScrollFrame.WarCampaignTooltip then	QuestScrollFrame.WarCampaignTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"]) end
				if QuestScrollFrame.StoryTooltip then
					QuestScrollFrame.StoryTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"])
					QuestScrollFrame.StoryTooltip:SetFrameStrata("TOOLTIP")
				end

				-- Minimap (PVP queue status)
				if QueueStatusFrame then QueueStatusFrame:SetScale(LeaPlusLC["LeaPlusTipSize"]) end

				-- Embedded item tooltip (as used in PVP UI)
				if EmbeddedItemTooltip then EmbeddedItemTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"]) end

				-- Nameplate tooltip
				if NamePlateTooltip then NamePlateTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"]) end

				-- LibDBIcon
				if LibDBIconTooltip then LibDBIconTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"]) end

				-- Total RP 3
				if C_AddOns.IsAddOnLoaded("totalRP3") and TRP3_MainTooltip and TRP3_CharacterTooltip then
					TRP3_MainTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"])
					TRP3_CharacterTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"])
				end

				-- Altoholic
				if AddonFactory_Tooltip then
					AddonFactory_Tooltip:SetScale(LeaPlusLC["LeaPlusTipSize"])
				end

				-- Set slider formatted text
				LeaPlusCB["LeaPlusTipSize"].f:SetFormattedText("%.0f%%", LeaPlusLC["LeaPlusTipSize"] * 100)

			end

			-- Give function a file level scope
			LeaPlusLC.SetTipScale = SetTipScale

			-- Set tooltip scale when slider or checkbox changes and on startup
			LeaPlusCB["LeaPlusTipSize"]:HookScript("OnValueChanged", SetTipScale)
			SetTipScale()

			----------------------------------------------------------------------
			-- Character customisation (dragonriding customisation, barbershop)
			----------------------------------------------------------------------

			EventUtil.ContinueOnAddOnLoaded("Blizzard_CharacterCustomize",function()

				-- Function to set tooltip scale
				local function SetCharCustomiseScale()
					if CharCustomizeNoHeaderTooltip then
						CharCustomizeNoHeaderTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"])
					end
				end

				-- Set tooltip scale when slider changes and on startup
				LeaPlusCB["LeaPlusTipSize"]:HookScript("OnValueChanged", SetCharCustomiseScale)
				SetCharCustomiseScale()

			end)

			----------------------------------------------------------------------
			-- Contribution frame
			----------------------------------------------------------------------

			EventUtil.ContinueOnAddOnLoaded("Blizzard_Contribution",function()

				-- Function to set tooltip scale
				local function SetContributionTipScale()
					ContributionBuffTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"])
				end

				-- Set tooltip scale when slider changes and on startup
				LeaPlusCB["LeaPlusTipSize"]:HookScript("OnValueChanged", SetContributionTipScale)
				SetContributionTipScale()

			end)

			----------------------------------------------------------------------
			-- Encounter Journal tooltips
			----------------------------------------------------------------------

			EventUtil.ContinueOnAddOnLoaded("Blizzard_EncounterJournal",function()

				-- Function to set tooltip scale
				local function SetEncounterJournalTipScale()
					EncounterJournalTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"])
				end

				-- Set tooltip scale when slider changes and on startup
				LeaPlusCB["LeaPlusTipSize"]:HookScript("OnValueChanged", SetEncounterJournalTipScale)
				SetEncounterJournalTipScale()

			end)

			----------------------------------------------------------------------
			-- Blizzard Settings tooltip
			----------------------------------------------------------------------

			EventUtil.ContinueOnAddOnLoaded("Blizzard_Settings",function()

				-- Set tooltip scale when tooltip is shown
				SettingsTooltip:HookScript("OnShow", function()
					SettingsTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"] * UIParent:GetScale())
				end)

			end)

			----------------------------------------------------------------------
			-- Perks program tooltip (trading post)
			----------------------------------------------------------------------

			EventUtil.ContinueOnAddOnLoaded("Blizzard_PerksProgram",function()

				-- Set tooltip scale
				PerksProgramTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"])

			end)

			----------------------------------------------------------------------
			-- Death Recap frame tooltips
			----------------------------------------------------------------------

			EventUtil.ContinueOnAddOnLoaded("Blizzard_DeathRecap",function()

				-- Simple fix to prevent mousing over units behind the frame
				DeathRecapFrame:EnableMouse(true)

			end)

			----------------------------------------------------------------------
			-- Garrison tooltips
			----------------------------------------------------------------------

			EventUtil.ContinueOnAddOnLoaded("Blizzard_GarrisonUI",function()

				-- Function to set tooltip scale
				local function SetGarrisonTipScale()
					GarrisonFollowerTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"])
					GarrisonFollowerAbilityTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"])
					GarrisonMissionMechanicTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"])
					GarrisonMissionMechanicFollowerCounterTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"])
					GarrisonBuildingFrame.BuildingLevelTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"])
					GarrisonBonusAreaTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"])
					GarrisonShipyardMapMissionTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"])
					GarrisonShipyardFollowerTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"])
				end

				-- Set tooltip scale when slider changes and on startup
				LeaPlusCB["LeaPlusTipSize"]:HookScript("OnValueChanged", SetGarrisonTipScale)
				SetGarrisonTipScale()

			end)

			---------------------------------------------------------------------------------------------------------
			-- Other tooltip code
			---------------------------------------------------------------------------------------------------------

			-- Remove the right-click for frame settings instruction (UNIT_POPUP_RIGHT_CLICK)
			hooksecurefunc("UnitFrame_UpdateTooltip", function(self)
				GameTooltip_SetDefaultAnchor(GameTooltip, self)
				GameTooltip:SetUnit(self.unit, true)
				GameTooltip:Show()
			end)

			-- Function to return a value only if it can be accessed (secret values return nil)
			local function Safe(value)
				if canaccessvalue(value) then return value end
			end

			-- Function to convert a color table to a color code
			local function ColorCode(col)
				return string.format("|cff%02x%02x%02x", col.r * 255, col.g * 255, col.b * 255)
			end

			-- Level string
			local LevelString, LevelString2
			if GameLocale == "ruRU" then
				-- Level string for ruRU
				LevelString = "уровня"
				LevelString2 = "уровень"
			else
				-- Level string for all other locales
				LevelString = string.lower(TOOLTIP_UNIT_LEVEL:gsub("%%s",".+"))
			end

			-- Tag locale (code construction from tiplang)
			local ttYou, ttLevel, ttBoss, ttElite, ttRare, ttRareElite, ttRareBoss, ttTarget
			if 		GameLocale == "zhCN" then 	ttYou = "您"		; ttLevel = "等级"		; ttBoss = "首领"	; ttElite = "精英"	; ttRare = "精良"	; ttRareElite = "精良 精英"		; ttRareBoss = "精良 首领"		; ttTarget = "目标"
			elseif 	GameLocale == "zhTW" then 	ttYou = "您"		; ttLevel = "等級"		; ttBoss = "首領"	; ttElite = "精英"	; ttRare = "精良"	; ttRareElite = "精良 精英"		; ttRareBoss = "精良 首領"		; ttTarget = "目標"
			elseif 	GameLocale == "ruRU" then 	ttYou = "ВЫ"	; ttLevel = "Уровень"	; ttBoss = "босс"	; ttElite = "элита"	; ttRare = "Редкое"	; ttRareElite = "Редкое элита"	; ttRareBoss = "Редкое босс"	; ttTarget = "Цель"
			elseif 	GameLocale == "koKR" then 	ttYou = "당신"	; ttLevel = "레벨"		; ttBoss = "우두머리"	; ttElite = "정예"	; ttRare = "희귀"	; ttRareElite = "희귀 정예"		; ttRareBoss = "희귀 우두머리"		; ttTarget = "대상"
			elseif 	GameLocale == "esMX" then 	ttYou = "TÚ"	; ttLevel = "Nivel"		; ttBoss = "Jefe"	; ttElite = "Élite"	; ttRare = "Raro"	; ttRareElite = "Raro Élite"	; ttRareBoss = "Raro Jefe"		; ttTarget = "Objetivo"
			elseif 	GameLocale == "ptBR" then 	ttYou = "VOCÊ"	; ttLevel = "Nível"		; ttBoss = "Chefe"	; ttElite = "Elite"	; ttRare = "Raro"	; ttRareElite = "Raro Elite"	; ttRareBoss = "Raro Chefe"		; ttTarget = "Alvo"
			elseif 	GameLocale == "deDE" then 	ttYou = "SIE"	; ttLevel = "Stufe"		; ttBoss = "Boss"	; ttElite = "Elite"	; ttRare = "Selten"	; ttRareElite = "Selten Elite"	; ttRareBoss = "Selten Boss"	; ttTarget = "Ziel"
			elseif 	GameLocale == "esES" then	ttYou = "TÚ"	; ttLevel = "Nivel"		; ttBoss = "Jefe"	; ttElite = "Élite"	; ttRare = "Raro"	; ttRareElite = "Raro Élite"	; ttRareBoss = "Raro Jefe"		; ttTarget = "Objetivo"
			elseif 	GameLocale == "frFR" then 	ttYou = "TOI"	; ttLevel = "Niveau"	; ttBoss = "Boss"	; ttElite = "Élite"	; ttRare = "Rare"	; ttRareElite = "Rare Élite"	; ttRareBoss = "Rare Boss"		; ttTarget = "Cible"
			elseif 	GameLocale == "itIT" then 	ttYou = "TU"	; ttLevel = "Livello"	; ttBoss = "Boss"	; ttElite = "Élite"	; ttRare = "Raro"	; ttRareElite = "Raro Élite"	; ttRareBoss = "Raro Boss"		; ttTarget = "Bersaglio"
			else 								ttYou = "YOU"	; ttLevel = "Level"		; ttBoss = "Boss"	; ttElite = "Elite"	; ttRare = "Rare"	; ttRareElite = "Rare Elite"	; ttRareBoss = "Rare Boss"		; ttTarget = "Target"
			end

			-- Function to find the level line (lines with secret text are skipped)
			local function FindLevelLine(first)
				for i = first, math.min(GameTooltip:NumLines(), first + 3) do
					local text = Safe(_G["GameTooltipTextLeft" .. i]:GetText())
					if text then
						local lower = string.lower(text)
						if lower:find(LevelString) or (LevelString2 and lower:find(LevelString2)) then
							return i, text
						end
					end
				end
			end

			-- Function to get level text (colored by difficulty if required)
			local function GetLevelText(unit, level, realLevel, useColor)

				-- Level ?? units
				if level == -1 then
					if GameLocale == "ruRU" then
						return "|cffff3333??-ro " .. ttLevel .. "|r"
					else
						return "|cffff3333" .. ttLevel .. " ??|r"
					end
				end

				-- Show real level if different (such as level scaling)
				local realText = ""
				if not useColor and realLevel and realLevel ~= level then
					realText = " (" .. realLevel .. ")"
				end

				-- Construct level text
				local levelText
				if GameLocale == "ruRU" then
					levelText = level .. realText .. LT["LevelLocale"]
				else
					levelText = LT["LevelLocale"] .. " " .. level .. realText
				end

				-- Color level by difficulty
				if useColor then
					levelText = ColorCode(GetDifficultyColor(C_PlayerInfo.GetContentDifficultyCreatureForPlayer(unit))) .. levelText .. "|r"
				end

				return levelText

			end

			-- Show tooltip
			local function ShowTip(self)

				-- Required for Dragonflight (or not self:IsTooltipType(Enum.TooltipDataType.Unit))
				if self ~= GameTooltip then return end

				-- Do nothing if CTRL, SHIFT and ALT are being held
				if IsControlKeyDown() and IsAltKeyDown() and IsShiftKeyDown() then
					return
				end

				-- Hide tooltips for world units during combat
				if WorldFrame:IsMouseMotionFocus() then
					if LeaPlusLC["TipHideInCombat"] == "On" and UnitAffectingCombat("player") then
						if not IsShiftKeyDown() or LeaPlusLC["TipHideShiftOverride"] == "Off" then
							GameTooltip:Hide()
							return
						end
					end
				end

				-- Get unit (secret unit tokens cannot be used so try the unit frame token instead)
				local unit
				if WorldFrame:IsMouseMotionFocus() then
					unit = "mouseover"
				else
					unit = select(2, GameTooltip:GetUnit())
					if not canaccessvalue(unit) then
						local owner = GameTooltip:GetOwner()
						unit = owner and not owner:IsForbidden() and Safe(owner.unit)
					end
				end
				if type(unit) ~= "string" or not UnitExists(unit) then return end

				-- Quit if unit is a wild pet
				if UnitIsWildBattlePet(unit) then return end

				-- Get unit information (reaction is nil if the unit is out of range so treat it as friendly)
				local name, realm = UnitName(unit)
				local isPlayer = UnitIsPlayer(unit)
				local playerControl = UnitPlayerControlled(unit)
				local reaction = UnitReaction(unit, "player") or 5
				local level = UnitEffectiveLevel(unit)
				local realLevel = UnitLevel(unit)
				local isDead = UnitIsDeadOrGhost(unit)
				local className, class = UnitClass(unit)
				className, class = Safe(className), Safe(class)
				local classCol = class and LeaPlusLC["RaidColors"][class]

				----------------------------------------------------------------------
				-- Name line
				----------------------------------------------------------------------

				local r, g, b
				if isPlayer then

					-- Show player name with title and realm
					local nameText = UnitPVPName(unit)
					if not nameText or (canaccessvalue(nameText) and nameText == "") then nameText = name end -- Some units (Demolition Fan, 237523) return empty strings for UnitPVPName
					realm = Safe(realm)
					-- if nameText and realm and realm ~= "" then nameText = nameText .. " - " .. realm end -- Not used on Forever as realm returns surname
					if nameText then GameTooltipTextLeft1:SetText(nameText) end

					-- Show player name in class color
					if classCol then r, g, b = classCol.r, classCol.g, classCol.b end

				elseif playerControl or reaction > 4 then

					-- Show friendly and player controlled units in green or blue depending on PvP status
					if Safe(UnitIsPVP(unit)) then
						r, g, b = 0, 1, 0
					else
						r, g, b = 0, 0.67, 1
					end

				elseif reaction < 4 then

					-- Show hostile mobs in brighter red (alive) and steel blue (tap denied)
					if UnitIsTapDenied(unit) then
						r, g, b = 0.53, 0.73, 0.73
					else
						r, g, b = 1, 0.2, 0.2
					end

				end

				-- Show dead units in grey
				if isDead then r, g, b = 0.53, 0.53, 0.53 end

				-- Set name color (the name text is not touched so secret names are fine)
				if r then GameTooltipTextLeft1:SetTextColor(r, g, b) end

				----------------------------------------------------------------------
				-- Player guild and information lines
				----------------------------------------------------------------------

				if isPlayer then

					-- Show guild line
					local guildName, guildRank = GetGuildInfo(unit)
					if guildName then
						local showRank
						if UnitIsInMyGuild(unit) then
							showRank = LeaPlusLC["TipShowRank"] == "On"
						else
							showRank = LeaPlusLC["TipShowOtherRank"] == "On"
						end
						if showRank and guildRank then
							GameTooltipTextLeft2:SetText(guildName .. " - " .. guildRank)
						else
							GameTooltipTextLeft2:SetText(guildName)
						end
						GameTooltipTextLeft2:SetTextColor(0.67, 0.67, 1)
					end

					-- Show information line (level, race and class)
					local infoLine, infoOld
					if className and level then infoLine, infoOld = FindLevelLine(guildName and 3 or 2) end
					if infoLine then

						-- Keep Blizzard information line if it shows a different race (such as disguised players)
						local race = Safe(UnitRace(unit))
						local keepLine = race and not infoOld:find(race, 1, true)

						-- Level and race
						local infoText = GetLevelText(unit, level, realLevel, reaction < 5)
						if race then
							if GameLocale == "ruRU" then
								infoText = race .. ", " .. infoText
							else
								infoText = infoText .. " " .. race
							end
						end

						-- Show specialisation line in class color or show class on information line if there is no specialisation line (such as Akunda the Nimble in Vol'dun)
						local specLine = infoLine < GameTooltip:NumLines() and _G["GameTooltipTextLeft" .. (infoLine + 1)]
						local specText = specLine and Safe(specLine:GetText())
						if specText and specText:find(className, 1, true) then
							if classCol then specLine:SetTextColor(classCol.r, classCol.g, classCol.b) end
						elseif classCol then
							infoText = infoText .. " " .. ColorCode(classCol) .. className .. "|r"
						else
							infoText = infoText .. " " .. className
						end

						-- Show information line
						if not keepLine then _G["GameTooltipTextLeft" .. infoLine]:SetText(infoText) end

					end

				end

				----------------------------------------------------------------------
				-- Mob level in color (neutral or lower)
				----------------------------------------------------------------------

				if not isPlayer and not playerControl and reaction < 5 and level and UnitCanAttack(unit, "player") then

					local mobLine, mobText = FindLevelLine(2)
					if mobLine then

						-- Rare, elite and boss mobs
						local isBoss = mobText:find(ttBoss, 1, true)
						local special = UnitClassification(unit)
						if special == "elite" then
							special = isBoss and "(" .. ttBoss .. ")" or "(" .. ttElite .. ")"
						elseif special == "rare" then
							special = "|c00e066ff(" .. ttRare .. ")"
						elseif special == "rareelite" then
							special = isBoss and "|c00e066ff(" .. ttRareBoss .. ")" or "|c00e066ff(" .. ttRareElite .. ")"
						elseif special == "worldboss" or (special == "normal" and level == -1 and isBoss) then
							special = "(" .. ttBoss .. ")"
						else
							special = ""
						end

						-- Show mob info line
						_G["GameTooltipTextLeft" .. mobLine]:SetText(GetLevelText(unit, level, nil, true) .. " " .. special)

					end

				end

				----------------------------------------------------------------------
				-- Backdrop color
				----------------------------------------------------------------------

				if LeaPlusLC["TipBackSimple"] == "On" then
					local faction = UnitFactionGroup(unit)
					if faction and faction ~= UnitFactionGroup("player") and UnitCanAttack("player", unit) and not isDead then
						-- Hostile faction
						GameTooltip.NineSlice:SetCenterColor(0.5, 0.0, 0.0)
					else
						-- Friendly faction
						GameTooltip.NineSlice:SetCenterColor(0.0, 0.0, 0.5)
					end
				end

				----------------------------------------------------------------------
				--	Show target
				----------------------------------------------------------------------

				if LeaPlusLC["TipShowTarget"] == "On" then

					local targetUnit = unit .. "target"
					if UnitExists(targetUnit) then

						-- Get target name (this can be secret)
						local target = UnitName(targetUnit)

						if C_Secrets.CanCompareUnitTokens(targetUnit, "player") and Safe(UnitIsUnit(targetUnit, "player")) then
							-- If target is you, set target to YOU
							target = "|c12ff4400" .. ttYou
						elseif UnitIsPlayer(targetUnit) then
							-- If it's not you, but it's a player, show target in class color
							local targetClass = Safe(UnitClassBase(targetUnit))
							local targetCol = targetClass and LeaPlusLC["RaidColors"][targetClass]
							if targetCol and target then target = ColorCode(targetCol) .. target end
						end

						-- Add target line (text is set separately as it can be secret)
						if target then
							GameTooltip:AddLine(" ")
							_G["GameTooltipTextLeft" .. GameTooltip:NumLines()]:SetText(ttTarget .. ": " .. target)
						end

					end

				end

			end

			TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, ShowTip)

		end

		----------------------------------------------------------------------
		--	Move chat editbox to top
		----------------------------------------------------------------------

		if LeaPlusLC["MoveChatEditBoxToTop"] == "On" and not LeaLockList["MoveChatEditBoxToTop"] then

			-- Set options for normal chat frames
			for i = 1, 50 do
				if _G["ChatFrame" .. i] then
					-- Position the editbox
					_G["ChatFrame" .. i .. "EditBox"]:ClearAllPoints()
					_G["ChatFrame" .. i .. "EditBox"]:SetPoint("TOP", _G["ChatFrame" .. i], "TOP", 0, 0)
					_G["ChatFrame" .. i .. "EditBox"]:SetPoint("LEFT", _G["ChatFrame" .. i], "LEFT", 0, 0)
					_G["ChatFrame" .. i .. "EditBox"]:SetPoint("RIGHT", _G["ChatFrame" .. i], "RIGHT", 0, 0)
				end
			end

			-- Do the functions above for other chat frames (pet battles, whispers, etc)
			hooksecurefunc("FCF_OpenTemporaryWindow", function()
				local cf = FCF_GetCurrentChatFrame():GetName() or nil
				if cf then
					-- Position the editbox
					_G[cf .. "EditBox"]:ClearAllPoints()
					_G[cf .. "EditBox"]:SetPoint("TOP", cf, "TOP", 0, 0)
					_G[cf .. "EditBox"]:SetPoint("LEFT", cf, "LEFT", 0, 0)
					_G[cf .. "EditBox"]:SetPoint("RIGHT", cf, "RIGHT", 0, 0)
				end
			end)

		end

		----------------------------------------------------------------------
		-- Show borders
		----------------------------------------------------------------------

		if LeaPlusLC["ShowBorders"] == "On" then

			-- Create border textures
			local BordTop = WorldFrame:CreateTexture(nil, "ARTWORK"); BordTop:SetColorTexture(0, 0, 0, 1); BordTop:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0); BordTop:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
			local BordBot = WorldFrame:CreateTexture(nil, "ARTWORK"); BordBot:SetColorTexture(0, 0, 0, 1); BordBot:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0); BordBot:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
			local BordLeft = WorldFrame:CreateTexture(nil, "ARTWORK"); BordLeft:SetColorTexture(0, 0, 0, 1); BordLeft:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0); BordLeft:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
			local BordRight = WorldFrame:CreateTexture(nil, "ARTWORK"); BordRight:SetColorTexture(0, 0, 0, 1); BordRight:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0); BordRight:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)

			-- Create border configuration panel
			local bordersPanel = LeaPlusLC:CreatePanel("Show borders", "bordersPanel")

			-- Function to set border parameters
			local function RefreshBorders()

				-- Set border size and transparency
				BordTop:SetHeight(LeaPlusLC["BordersTop"]); BordTop:SetAlpha(1 - LeaPlusLC["BordersAlpha"])
				BordBot:SetHeight(LeaPlusLC["BordersBottom"]); BordBot:SetAlpha(1 - LeaPlusLC["BordersAlpha"])
				BordLeft:SetWidth(LeaPlusLC["BordersLeft"]); BordLeft:SetAlpha(1 - LeaPlusLC["BordersAlpha"])
				BordRight:SetWidth(LeaPlusLC["BordersRight"]); BordRight:SetAlpha(1 - LeaPlusLC["BordersAlpha"])

				-- Show formatted slider value
				LeaPlusCB["BordersAlpha"].f:SetFormattedText("%.0f%%", LeaPlusLC["BordersAlpha"] * 100)

			end

			-- Create slider controls
			LeaPlusLC:MakeTx(bordersPanel, "Top", 16, -72)
			LeaPlusLC:MakeSL(bordersPanel, "BordersTop", "Drag to set the size of the top border.", 0, 300, 5, 16, -92, "%.0f")
			LeaPlusCB["BordersTop"]:HookScript("OnValueChanged", RefreshBorders)

			LeaPlusLC:MakeTx(bordersPanel, "Bottom", 16, -132)
			LeaPlusLC:MakeSL(bordersPanel, "BordersBottom", "Drag to set the size of the bottom border.", 0, 300, 5, 16, -152, "%.0f")
			LeaPlusCB["BordersBottom"]:HookScript("OnValueChanged", RefreshBorders)

			LeaPlusLC:MakeTx(bordersPanel, "Left", 186, -72)
			LeaPlusLC:MakeSL(bordersPanel, "BordersLeft", "Drag to set the size of the left border.", 0, 300, 5, 186, -92, "%.0f")
			LeaPlusCB["BordersLeft"]:HookScript("OnValueChanged", RefreshBorders)

			LeaPlusLC:MakeTx(bordersPanel, "Right", 186, -132)
			LeaPlusLC:MakeSL(bordersPanel, "BordersRight", "Drag to set the size of the right border.", 0, 300, 5, 186, -152, "%.0f")
			LeaPlusCB["BordersRight"]:HookScript("OnValueChanged", RefreshBorders)

			LeaPlusLC:MakeTx(bordersPanel, "Transparency", 356, -132)
			LeaPlusLC:MakeSL(bordersPanel, "BordersAlpha", "Drag to set the transparency of the borders.", 0, 0.9, 0.1, 356, -152, "%.1f")
			LeaPlusCB["BordersAlpha"]:HookScript("OnValueChanged", RefreshBorders)

			-- Help button hidden
			bordersPanel.h:Hide()

			-- Back button handler
			bordersPanel.b:SetScript("OnClick", function()
				bordersPanel:Hide()
				LeaPlusLC["PageF"]:Show()
				LeaPlusLC["Page5"]:Show()
				return
			end)

			-- Reset button handler
			bordersPanel.r:SetScript("OnClick", function()
				LeaPlusLC["BordersTop"] = 0
				LeaPlusLC["BordersBottom"] = 0
				LeaPlusLC["BordersLeft"] = 0
				LeaPlusLC["BordersRight"] = 0
				LeaPlusLC["BordersAlpha"] = 0
				bordersPanel:Hide(); bordersPanel:Show()
				RefreshBorders()
			end)

			-- Configuration button handler
			LeaPlusCB["ModBordersBtn"]:SetScript("OnClick", function()
				if IsShiftKeyDown() and IsControlKeyDown() then
					-- Preset profile
					LeaPlusLC["BordersTop"] = 0
					LeaPlusLC["BordersBottom"] = 0
					LeaPlusLC["BordersLeft"] = 0
					LeaPlusLC["BordersRight"] = 0
					LeaPlusLC["BordersAlpha"] = 0.7
					RefreshBorders()
				else
					bordersPanel:Show()
					LeaPlusLC:HideFrames()
				end
			end)

			-- Set borders on startup
			RefreshBorders()

			-- Hide borders when cinematic is shown
			hooksecurefunc(CinematicFrame, "Hide", function()
				BordTop:Show(); BordBot:Show(); BordLeft:Show(); BordRight:Show()
			end)
			hooksecurefunc(CinematicFrame, "Show", function()
				BordTop:Hide(); BordBot:Hide(); BordLeft:Hide(); BordRight:Hide()
			end)

		end

		----------------------------------------------------------------------
		-- Silence rested emotes
		----------------------------------------------------------------------

		-- Manage emotes
		if LeaPlusLC["NoRestedEmotes"] == "On" then

			-- Zone table 		English					, French					, German					, Italian						, Russian					, S Chinese	, Spanish					, T Chinese	,
			local zonetable = {	"The Grim Guzzler"		, "Le Sinistre écluseur"	, "Zum Grimmigen Säufer"	, "Torvo Beone"					, "Трактир Угрюмый обжора"	, "黑铁酒吧"	, "Tragapenas"				, "黑鐵酒吧"	,
			}

			-- Function to set rested state
			local function UpdateEmoteSound()

				-- Find character's current zone
				local szone = GetSubZoneText() or "None"

				-- Find out if emote sounds are disabled or enabled
				local emoset = GetCVar("Sound_EnableEmoteSounds")

				if IsResting() then
					-- Character is resting so silence emotes
					if emoset ~= "0" then
						SetCVar("Sound_EnableEmoteSounds", "0")
					end
					return
				end

				-- Traverse zone table and silence emotes if character is in a designated zone
				for k, v in next, zonetable do
					if szone == zonetable[k] then
						if emoset ~= "0" then
							SetCVar("Sound_EnableEmoteSounds", "0")
						end
						return
					end
				end

				-- If the above didn't return, emote sounds should be enabled
				if emoset ~= "1" then
					SetCVar("Sound_EnableEmoteSounds", "1")
				end
				return

			end

			-- Set emote sound when rest state or zone changes
			local RestEvent = CreateFrame("FRAME")
			RestEvent:RegisterEvent("PLAYER_UPDATE_RESTING")
            RestEvent:RegisterEvent("ZONE_CHANGED_NEW_AREA")
			RestEvent:RegisterEvent("ZONE_CHANGED")
			RestEvent:RegisterEvent("ZONE_CHANGED_INDOORS")
			RestEvent:SetScript("OnEvent", UpdateEmoteSound)

			-- Set sound setting at startup
			UpdateEmoteSound()

		end

		----------------------------------------------------------------------
		-- Flares (world markers)
		----------------------------------------------------------------------

		do
			local raidTable = {L["Flare: Square"], L["Flare: Triangle"], L["Flare: Diamond"], L["Flare: Cross"], L["Flare: Star"], L["Flare: Circle"], L["Flare: Moon"], L["Flare: Skull"], L["Flare: Clear all"]}
			for i = 1, 9 do
				_G["BINDING_NAME_CLICK " .. "LeaPlusGlobalFlare" .. i ..":LeftButton"] = raidTable[i]
				local btn = CreateFrame("Button", "LeaPlusGlobalFlare" .. i, nil, "SecureActionButtonTemplate")
				btn:SetAttribute("type", "macro")
				if i == 9 then
					btn:SetAttribute("macrotext", "/clearworldmarker 1\n/clearworldmarker 2\n/clearworldmarker 3\n/clearworldmarker 4\n/clearworldmarker 5\n/clearworldmarker 6\n/clearworldmarker 7\n/clearworldmarker 8")
				else
					btn:SetAttribute("macrotext", "/clearworldmarker " .. i .. "\n/worldmarker " .. i)
				end
				btn:RegisterForClicks("AnyUp", "AnyDown")
			end
		end

		----------------------------------------------------------------------
		-- Frame alignment grid
		----------------------------------------------------------------------

		do

			-- Create frame alignment grid
			local grid = CreateFrame('FRAME')
			LeaPlusLC.grid = grid
			grid:Hide()
			grid:SetAllPoints(UIParent)
			local w, h = GetScreenWidth() * UIParent:GetEffectiveScale(), GetScreenHeight() * UIParent:GetEffectiveScale()
			local ratio = w / h
			local sqsize = w / 20
			local wline = floor(sqsize - (sqsize % 2))
			local hline = floor(sqsize / ratio - ((sqsize / ratio) % 2))
			-- Plot vertical lines
			for i = 0, wline do
				local t = LeaPlusLC.grid:CreateTexture(nil, 'BACKGROUND')
				if i == wline / 2 then t:SetColorTexture(1, 0, 0, 0.5) else t:SetColorTexture(0, 0, 0, 0.5) end
				t:SetPoint('TOPLEFT', grid, 'TOPLEFT', i * w / wline - 1, 0)
				t:SetPoint('BOTTOMRIGHT', grid, 'BOTTOMLEFT', i * w / wline + 1, 0)
			end
			-- Plot horizontal lines
			for i = 0, hline do
				local t = LeaPlusLC.grid:CreateTexture(nil, 'BACKGROUND')
				if i == hline / 2 then	t:SetColorTexture(1, 0, 0, 0.5) else t:SetColorTexture(0, 0, 0, 0.5) end
				t:SetPoint('TOPLEFT', grid, 'TOPLEFT', 0, -i * h / hline + 1)
				t:SetPoint('BOTTOMRIGHT', grid, 'TOPRIGHT', 0, -i * h / hline - 1)
			end

		end

		----------------------------------------------------------------------
		-- Media player
		----------------------------------------------------------------------

		function LeaPlusLC:MediaFunc()

			-- Create tables for list data
			local ListData, playlist = {}, {}
			local scrollFrame, willPlay, musicHandle, ZonePage, LastPlayed, LastFolder, TempFolder, HeadingOfClickedTrack, LastMusicHandle
			local numButtons = math.floor((LeaPlusLC.MainPanelHeight - 110) / 16) - 1
			local uframe = CreateFrame("FRAME")

			-- These categories will not appear in random track selections
			local randomBannedList = {L["Narration"], L["Cinematics"]}

			-- Remove the duplicate number some tracks have after the file ID (path#fileid#2 becomes path#fileid)
			local function StripDup(track)
				return (track:gsub("^(.-#%d+)#%d+$", "%1"))
			end

			-- Get media table
			local ZoneList = Leatrix_Plus["ZoneList"]

			-- Show relevant list items
			local function UpdateList()
				local offset = max(0, floor(scrollFrame:GetVerticalScroll() + 0.5))
				for i, button in ipairs(scrollFrame.buttons) do
					local index = offset + i
					if index <= #ListData then
						-- Show zone listing or track listing (store the full list entry on the button)
						button.item = ListData[index]
						local label = ListData[index].zone or ListData[index]
						-- Hide the duplicate number some tracks have after the file ID (path#fileid#2 shows as path#fileid)
						if type(ListData[index]) == "string" then label = StripDup(label) end
						button:SetText(label)
						-- Set width of highlight texture
						if button:GetTextWidth() > 290 then
							button.t:SetSize(290, 16)
						else
							button.t:SetSize(button:GetTextWidth(), 16)
						end
						-- Show the button
						button:Show()
						-- Hide highlight bar texture by default
						button.s:Hide()
						-- Hide highlight bar if the button is a heading
						if strfind(button:GetText(), "|c") then button.t:Hide() end
						-- Show last played track highlight bar texture
						if LastPlayed == button.item then
							local HeadingOfCurrentFolder = ListData[1]
							if HeadingOfCurrentFolder == HeadingOfClickedTrack then
								button.s:Show()
							end
						end
						-- Show last played folder highlight bar texture
						if LastFolder == button:GetText() then
							button.s:Show()
						end
						-- Set width of highlight bar
						if button:GetTextWidth() > 290 then
							button.s:SetSize(290, 16)
						else
							button.s:SetSize(button:GetTextWidth(), 16)
						end
						-- Limit click to label width
						local bWidth = button:GetFontString():GetStringWidth() or 0
						if bWidth > 290 then bWidth = 290 end
						button:SetHitRectInsets(0, 454 - bWidth, 0, 0)
						-- Disable label click movement
						button:SetPushedTextOffset(0, 0)
						-- Disable word wrap and set width
						button:GetFontString():SetWidth(290)
						button:GetFontString():SetWordWrap(false)
					else
						button:Hide()
					end
				end

				local bRoll = ((36 + (LeaPlusLC.MainPanelHeight - 370)) / 16) + 16
				scrollFrame.child:SetSize(200, #ListData + (math.floor(bRoll * 15)))

			end

			-- Give function file level scope (it's used in SetPlusScale to set the highlight bar scale)
			LeaPlusLC.UpdateList = UpdateList

			-- Right-button click to go back
			local function BackClick()
				-- Return to the current zone list (back button)
				if type(ListData[1]) == "string" then
					-- Strip the color code from the list data
					local nocol = string.gsub(ListData[1], "|cffffd800", "")
					-- Strip the zone
					local backzone = strsplit(":", nocol, 2)
					-- Don't go back if random or search category is being shown
					if backzone == L["Random"] or backzone == L["Search"] then return end
					-- Show the tracklist continent
					if ZoneList[backzone] then ListData = ZoneList[backzone] end
					UpdateList()
					scrollFrame:SetVerticalScroll(ZonePage or 0)
				end
			end

			-- Function to make navigation menu buttons
			local function MakeButton(where, y)
				local mbtn = CreateFrame("Button", nil, LeaPlusLC["Page9"])
				mbtn:Show()
				mbtn:SetAlpha(1.0)
				mbtn:SetPoint("TOPLEFT", 146, y)

				-- Create hover texture
				mbtn.t = mbtn:CreateTexture(nil, "BACKGROUND")
				mbtn.t:SetColorTexture(0.3, 0.3, 0.00, 0.8)
				mbtn.t:SetAlpha(0.7)
				mbtn.t:SetAllPoints()
				mbtn.t:Hide()

				-- Create highlight texture
				mbtn.s = mbtn:CreateTexture(nil, "BACKGROUND")
				mbtn.s:SetColorTexture(0.3, 0.3, 0.00, 0.8)
				mbtn.s:SetAlpha(1.0)
				mbtn.s:SetAllPoints()
				mbtn.s:Hide()

				-- Create fontstring
				mbtn.f = mbtn:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
				mbtn.f:SetPoint('LEFT', 1, 0)
				mbtn.f:SetText(L[where])

				mbtn:SetScript("OnEnter", function()
					mbtn.t:Show()
				end)

				mbtn:SetScript("OnLeave", function()
					mbtn.t:Hide()
				end)

				-- Set button size when shown
				mbtn:SetScript("OnShow", function()
					mbtn:SetSize(mbtn.f:GetStringWidth() + 1, 16)
				end)

				mbtn:SetScript("OnClick", function()
					-- Show zone listing for clicked item
					ListData = ZoneList[where]
					UpdateList()
				end)

				return mbtn, mbtn.s

			end

			-- Create a table for each button
			local conbtn = {}
			for q, w in pairs(ZoneList) do
				conbtn[q] = {}
			end

			-- Create buttons
			local function MakeButtonNow(title, anchor)
				conbtn[title], conbtn[title].s = MakeButton(title, height)
				conbtn[title]:ClearAllPoints()
				if title == L["Zones"] then
					-- Set first button position
					conbtn[title]:SetPoint("TOPLEFT", LeaPlusLC["Page9"], "TOPLEFT", 145, -70)
				elseif anchor then
					-- Set subsequent button positions
					conbtn[title]:SetPoint("TOPLEFT", conbtn[anchor], "BOTTOMLEFT", 0, 0)
					conbtn[title].f:SetText(L[title])
				end
			end

			MakeButtonNow(L["Zones"])
			MakeButtonNow(L["Dungeons"], L["Zones"])
			MakeButtonNow(L["Various"], L["Dungeons"])
			MakeButtonNow(L["Movies"], L["Various"])
			MakeButtonNow(L["Random"], L["Movies"])
			MakeButtonNow(L["Search"]) -- Positioned when search editbox is created

			-- Show button highlight for clicked button
			for q, w in pairs(ZoneList) do
				if type(w) == "string" and conbtn[w] then
					conbtn[w]:HookScript("OnClick", function()
						-- Hide all button highlights
						for k, v in pairs(ZoneList) do
							if type(v) == "string" and conbtn[v] then
								conbtn[v].s:Hide()
							end
						end
						-- Show clicked button highlight
						conbtn[w].s:Show()
						LeaPlusDB["MusicContinent"] = w
						scrollFrame:SetVerticalScroll(0)
						-- Set TempFolder for listings without folders
						if w == L["Random"] then TempFolder = L["Random"] end
						if w == L["Search"] then TempFolder = L["Search"] end
					end)
				end
			end

			-- Create scroll bar
			scrollFrame = CreateFrame("ScrollFrame", nil, LeaPlusLC["Page9"], "ScrollFrameTemplate")
			scrollFrame:SetPoint("TOPLEFT", 0, -32)
			scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)
			scrollFrame:SetPanExtent(1)
			scrollFrame:SetScript("OnVerticalScroll", UpdateList)

			-- Create the scroll child
			scrollFrame.child = CreateFrame("Frame", nil, scrollFrame)
			scrollFrame:SetScrollChild(scrollFrame.child)

			-- Add stop button
			local stopBtn = LeaPlusLC:CreateButton("StopMusicBtn", LeaPlusLC["Page9"], "Stop", "BOTTOMLEFT", 146, 53, 0, 25, true, "")
			stopBtn:Hide(); stopBtn:Show()
			LeaPlusLC:LockItem(stopBtn, true)
			stopBtn:SetScript("OnClick", function()
				-- Unregister loading screen event and cancel the track monitor first so stopping doesn't start the next track
				uframe:UnregisterEvent("LOADING_SCREEN_DISABLED")
				if LeaPlusLC.TrackTimer then LeaPlusLC.TrackTimer:Cancel() end
				LastMusicHandle = nil
				if musicHandle then
					StopSound(musicHandle)
					musicHandle = nil
					-- Hide highlight bars
					LastPlayed = ""
					LastFolder = ""
					UpdateList()
				end
				-- Lock button
				LeaPlusLC:LockItem(stopBtn, true)
			end)

			-- Store currently playing track number
			local tracknumber = 1

			-- Count tracks in a row that failed to start (stops the player looping forever if nothing can play)
			local failedTracks = 0

			-- Forward declaration so the track monitor can move on to the next track
			local PlayTrack

			-- Function to play the next track in the playlist
			local function PlayNextTrack()
				-- Playlist is at the end (last entry repeats the first track), restart from first track
				if tracknumber >= #playlist then tracknumber = 1 end
				PlayTrack()
			end

			-- Function to play a track and show the static highlight bar
			function PlayTrack()
				if not playlist[tracknumber] then return end
				-- Stop the previous track and its monitor (clear the handle first so stopping it doesn't trigger the next track)
				if LeaPlusLC.TrackTimer then LeaPlusLC.TrackTimer:Cancel() end
				local oldHandle = musicHandle
				musicHandle, LastMusicHandle = nil, nil
				if oldHandle then StopSound(oldHandle) end
				-- Play music file (entries are path#filedataid)
				local file, soundID = playlist[tracknumber]:match("^(.-)#(%d+)")
				willPlay, musicHandle = PlaySoundFile(tonumber(soundID) or soundID, "Master")
				if willPlay and musicHandle then
					-- Watch the track and play the next one when it stops playing
					failedTracks = 0
					local thisHandle, ticker = musicHandle
					ticker = C_Timer.NewTicker(1, function()
						-- Another track has started since this one so stop watching
						if musicHandle ~= thisHandle then ticker:Cancel() return end
						if not C_Sound.IsPlaying(thisHandle) then
							-- Track has finished
							ticker:Cancel()
							PlayNextTrack()
						end
					end)
					LeaPlusLC.TrackTimer = ticker
				else
					-- Track could not be played so try the next one (give up after a full pass of the playlist)
					failedTracks = failedTracks + 1
					if failedTracks < #playlist then
						LeaPlusLC.TrackTimer = C_Timer.NewTimer(1, PlayNextTrack)
					end
				end
				-- Store its handle for later use
				LastMusicHandle = musicHandle
				LastPlayed = playlist[tracknumber]
				tracknumber = tracknumber + 1
				-- Show static highlight bar
				for index = 1, numButtons do
					local button = scrollFrame.buttons[index]
					local item = button:IsShown() and button.item
					if type(item) == "string" and item:match("^(.-)#(%d+)") then
						if item == LastPlayed and LastFolder == TempFolder then
							button.s:Show()
						else
							button.s:Hide()
						end
					end
				end
			end

			-- Create editbox for search
			local sBox = LeaPlusLC:CreateEditBox("MusicSearchBox", LeaPlusLC["Page9"], 78, 10, "TOPLEFT", 150, -(LeaPlusLC.MainPanelHeight - 110), "MusicSearchBox", "MusicSearchBox")
			sBox:SetMaxLetters(50)

			-- Position search button above editbox
			conbtn[L["Search"]]:ClearAllPoints()
			conbtn[L["Search"]]:SetPoint("BOTTOMLEFT", sBox, "TOPLEFT", -4, 0)

			-- Set initial search data
			for q, w in pairs(ZoneList) do
				if conbtn[w] then
					conbtn[w]:HookScript("OnClick", function()
						if w == L["Search"] then
							ListData[1] = "|cffffd800" .. L["Search"]
							if #ListData == 1 then
								ListData[2] = "|cffffffaa{" .. L["enter zone or track name"] .. "}"
							end
							UpdateList()
						else
							sBox:ClearFocus()
						end
					end)
				end
			end

			-- Function to show search results
			local function ShowSearchResults()
				-- Get unescaped editbox text
				local searchText = gsub(strlower(sBox:GetText()), '(['..("%^$().[]*+-?"):gsub("(.)", "%%%1")..'])', "%%%1")
				-- Wipe the track listing
				wipe(ListData)
				-- Set the track list heading
				ListData[1] = "|cffffd800" .. L["Search"]
				-- Show the subheading only if no search results are being shown
				if searchText == "" then
					ListData[2] = "|cffffffaa{" .. L["enter zone or track name"] .. "}"
				else
					ListData[2] = ""
				end
				-- Traverse music listing and populate ListData
				if searchText ~= "" then
					local word1, word2, word3, word4, word5 = strsplit(" ", (strtrim(searchText):gsub("%s+", " ")))
					local hash = {}
					local trackCount = 0
					for i, e in pairs(ZoneList) do
						if ZoneList[e] then
							for a, b in pairs(ZoneList[e]) do
								if b.tracks then
									for k, v in pairs(b.tracks) do
										if (strfind(v, "#") or strfind(v, "|r")) and (strfind(strlower(v), word1) or strfind(strlower(b.zone), word1) or strfind(strlower(b.category), word1)) then
											if not word2 or word2 ~= "" and (strfind(strlower(v), word2) or strfind(strlower(b.zone), word2) or strfind(strlower(b.category), word2)) then
												if not word3 or word3 ~= "" and (strfind(strlower(v), word3) or strfind(strlower(b.zone), word3) or strfind(strlower(b.category), word3)) then
													if not word4 or word4 ~= "" and (strfind(strlower(v), word4) or strfind(strlower(b.zone), word4) or strfind(strlower(b.category), word4)) then
														if not word5 or word5 ~= "" and (strfind(strlower(v), word5) or strfind(strlower(b.zone), word5) or strfind(strlower(b.category), word5)) then
															-- Show category
															if not hash[b.category] then
																tinsert(ListData, "|cffffffff")
																if b.category == e then
																	-- No category so just show ZoneList entry (such as Various)
																	tinsert(ListData, "|cffffd800" .. e)
																else
																	-- Category exists so show that
																	tinsert(ListData, "|cffffd800" .. e .. ": " .. b.category)
																end
																hash[b.category] = true
															end
															-- Show track (only once if it appears more than once in the same entry)
															local dupKey = "|Cffffffaa" .. b.zone .. " |r" .. StripDup(v)
															if not hash[dupKey] then
																tinsert(ListData, "|Cffffffaa" .. b.zone .. " |r" .. v)
																trackCount = trackCount + 1
																hash[dupKey] = true
															end
															hash[v] = true
														end
													end
												end
											end
										end
									end
								end
							end
						end
					end

					-- Set results tag
					if trackCount == 1 then
						ListData[2] = "|cffffffaa{" .. trackCount .. " " .. L["result"] .. "}"
					else
						ListData[2] = "|cffffffaa{" .. trackCount .. " " .. L["results"] .. "}"
					end
				end
				-- Refresh the track listing
				UpdateList()
				-- Set track listing to top
				scrollFrame:SetVerticalScroll(0)
			end

			-- Populate ListData when editbox is changed by user
			sBox:HookScript("OnTextChanged", function(self, userInput)
				if userInput then
					-- Show search page
					conbtn[L["Search"]]:Click()
					-- If search results are currently playing, stop playback since search results will be changed
					if LastFolder == L["Search"] then stopBtn:Click() end
					-- Show search results
					ShowSearchResults()
				end
			end)

			-- Populate ListData when editbox enter key is pressed
			sBox:HookScript("OnEnterPressed", function()
				-- Show search page
				conbtn[L["Search"]]:Click()
				-- If search results are currently playing, stop playback since search results will be changed
				if LastFolder == L["Search"] then stopBtn:Click() end
				-- Show search results
				ShowSearchResults()
			end)

			-- Function to get random argument for random track listing
			local function GetRandomArgument(...)
				return (select(random(select("#", ...)), ...))
			end

			-- Function to show random track listing
			local function ShowRandomList()
				-- If random track is currently playing, stop playback since random track list will be changed
				if LastFolder == L["Random"] then
					stopBtn:Click()
				end
				-- Wipe the track listing for random
				wipe(ListData)
				-- Set the track list heading
				ListData[1] = "|cffffd800" .. L["Random"]
				ListData[2] = "|Cffffffaa{" .. L["click here for new selection"] .. "}" -- Must be capital |C
				ListData[3] = "|cffffd800"
				ListData[4] = "|cffffd800" .. L["Selection of music tracks"] -- Must be lower case |c
				-- Populate list data until it contains desired number of tracks
				while #ListData < 50 do
					-- Get random category
					local rCategory = GetRandomArgument(L["Zones"], L["Dungeons"], L["Various"])
					-- Get random zone within category
					local rZone = random(1, #ZoneList[rCategory])
					-- Get random track within zone
					local rTrack = ZoneList[rCategory][rZone].tracks[random(1, #ZoneList[rCategory][rZone].tracks)]
					-- Insert track into ListData if it's not a duplicate or on the banned list
					-- Check the track isn't already listed (ignoring any duplicate number)
					local alreadyListed = false
					if rTrack and rTrack ~= "" and strfind(rTrack, "#") then
						local rKey = "|Cffffffaa" .. ZoneList[rCategory][rZone].zone .. " |r" .. StripDup(rTrack)
						for n = 5, #ListData do
							if StripDup(ListData[n]) == rKey then alreadyListed = true break end
						end
					end
					if rTrack and rTrack ~= "" and strfind(rTrack, "#") and not alreadyListed then
						if not table.contains(randomBannedList, L[ZoneList[rCategory][rZone].zone]) and not table.contains(randomBannedList, rTrack) then
							tinsert(ListData, "|Cffffffaa" .. ZoneList[rCategory][rZone].zone .. " |r" .. rTrack)
						end
					end
				end
				-- Refresh the track listing
				UpdateList()
				-- Set track listing to top
				scrollFrame:SetVerticalScroll(0)
			end

			-- Show random track listing on startup when random button is clicked
			for q, w in pairs(ZoneList) do
				if conbtn[w] then
					conbtn[w]:HookScript("OnClick", function()
						if w == L["Random"] then
							-- Generate initial playlist for first run
							if #ListData == 0 then
								ShowRandomList()
							end
						end
					end)
				end
			end

			-- Create list items
			scrollFrame.buttons = {}
			for i = 1, numButtons do
				scrollFrame.buttons[i] = CreateFrame("Button", nil, LeaPlusLC["Page9"])
				local button = scrollFrame.buttons[i]

				button:SetSize(470 - 14, 16)
				button:SetNormalFontObject("GameFontHighlightLeft")
				button:SetPoint("TOPLEFT", 246, -62+ -(i - 1) * 16 - 8)

				-- Create highlight bar texture
				button.t = button:CreateTexture(nil, "BACKGROUND")
				button.t:SetPoint("TOPLEFT", button, 0, 0)
				button.t:SetSize(516, 16)

				button.t:SetColorTexture(0.3, 0.3, 0.0, 0.8)
				button.t:SetAlpha(0.7)
				button.t:Hide()

				-- Create last playing highlight bar texture
				button.s = button:CreateTexture(nil, "BACKGROUND")
				button.s:SetPoint("TOPLEFT", button, 0, 0)
				button.s:SetSize(516, 16)

				button.s:SetColorTexture(0.3, 0.4, 0.00, 0.6)
				button.s:Hide()

				button:SetScript("OnEnter", function()
					-- Highlight links only
					if not string.match(button:GetText() or "", "|c") then
						button.t:Show()
					end
				end)

				button:SetScript("OnLeave", function()
					button.t:Hide()
				end)

				button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

				-- Handler for restarting the player after a loading screen (track endings are watched in PlayTrack)
				uframe:SetScript("OnEvent", function(self, event)
					if event == "LOADING_SCREEN_DISABLED" then
						-- Restart player if it stopped between tracks during loading screen
						if playlist and tracknumber and playlist[tracknumber] and not willPlay and not musicHandle then
							tracknumber = tracknumber - 1
							C_Timer.After(0.1, PlayTrack)
						end
					end
				end)

				-- Click handler for track, zone and back button
				button:SetScript("OnClick", function(self, btn)
					if btn == "LeftButton" then
						-- Remove focus from search box
						sBox:ClearFocus()
						-- Get clicked list entry (full entry, including any hidden duplicate number)
						local item = type(self.item) == "string" and self.item or self:GetText()
						-- Do nothing if its a blank line or informational heading
						if not item or strfind(item, "|c") then return end
						if item == "|Cffffffaa{" .. L["click here for new selection"] .. "}" then -- must be capital |C
							-- Create new random track listing
							ShowRandomList()
							return
						elseif strfind(item, "#") then
							-- Enable sound if required
							if GetCVar("Sound_EnableAllSound") == "0" then SetCVar("Sound_EnableAllSound", "1") end
							-- Disable music if it's currently enabled
							if GetCVar("Sound_EnableMusic") == "1" then	SetCVar("Sound_EnableMusic", "0") end
							-- Add all tracks to playlist
							wipe(playlist)
							local StartItem = 0
							-- Get item clicked row number
							for index = 1, #ListData do
								if ListData[index] == item then StartItem = index end
							end
							-- Add all items from clicked item onwards to playlist
							for index = StartItem, #ListData do
								local item = ListData[index]
								if item then
									if strfind(item, "#") then
										tinsert(playlist, item)
									end
								end
							end
							-- Add all items up to clicked item to playlist
							for index = 1, StartItem do
								local item = ListData[index]
								if item then
									if strfind(item, "#") then
										tinsert(playlist, item)
									end
								end
							end
							-- Enable the stop button
							LeaPlusLC:LockItem(stopBtn, false)
							-- Set Temp Folder to Random if track is in Random
							if ListData[1] == "|cffffd800" .. L["Random"] then TempFolder = L["Random"] end
							-- Set Temp Folder to Search if track is in Search
							if ListData[1] == "|cffffd800" .. L["Search"] then TempFolder = L["Search"] end
							-- Store information about the track we are about to play
							tracknumber = 1
							LastPlayed = item
							LastFolder = TempFolder
							HeadingOfClickedTrack = ListData[1]
							-- Play first track
							PlayTrack()
							-- Restart the player if a loading screen stops it between tracks
							uframe:RegisterEvent("LOADING_SCREEN_DISABLED")
							return
						elseif strfind(item, "|r") then
							-- A movie was clicked
							if not LeaPlusLC.MovieFinishedIsHooked then
								-- Workaround for movie frame hiding media player
								MovieFrame:HookScript("OnMovieFinished", function(self)
									if LeaPlusLC.MoviePlaying then
										LeaPlusLC.MoviePlaying = false
										if not LeaPlusLC["PageF"]:IsShown() then
											LeaPlusLC:HideFrames()
											LeaPlusLC["PageF"]:Show()
											LeaPlusLC["Page"..LeaPlusLC["LeaStartPage"]]:Show()
										end
									end
								end)
								LeaPlusLC.MovieFinishedIsHooked = true
							end
							local movieName, movieID = item:match("([^,]+)%|r([^,]+)")
							movieID = strtrim(movieID, "()")
							if IsMoviePlayable(movieID) then
								stopBtn:Click()
								LeaPlusLC.MoviePlaying = true
								MovieFrame_PlayMovie(MovieFrame, movieID)
							else
								LeaPlusLC:Print("Movie not playable.")
							end
							return
						else
							-- A zone was clicked so show track listing
							ZonePage = scrollFrame:GetVerticalScroll()
							-- Find the track listing for the clicked zone
							for q, w in pairs(ZoneList) do
								for k, v in pairs(ZoneList[w]) do
									if item == v.zone then
										-- Show track listing
										TempFolder = item
										LeaPlusDB["MusicZone"] = item
										ListData = v.tracks
										UpdateList()
										-- Hide hover highlight if track under pointer is a heading
										if strfind(scrollFrame.buttons[i]:GetText(), "|c") then
											scrollFrame.buttons[i].t:Hide()
										end
										-- Show top of track list
										scrollFrame:SetVerticalScroll(0)
										return
									end
								end
							end
						end
					elseif btn == "RightButton" then
						-- Back button was clicked
						BackClick()
					end
				end)

			end

			-- Right-click to go back (from anywhere on the main content area of the panel)
			LeaPlusLC["PageF"]:HookScript("OnMouseUp", function(self, btn)
				if LeaPlusLC["Page9"]:IsShown() and LeaPlusLC["Page9"]:IsMouseOver(0, 0, 0, -440) == false and LeaPlusLC["Page9"]:IsMouseOver(-(LeaPlusLC.MainPanelHeight - 47), 0, 0, 0) == false then
					if btn == "RightButton" then
						BackClick()
					end
				end
			end)

			-- Set zone listing on startup
			if LeaPlusDB["MusicContinent"] and LeaPlusDB["MusicContinent"] ~= "" then
				-- Saved music continent exists
				if conbtn[LeaPlusDB["MusicContinent"]] then
					-- Saved continent is valid button so click it
					conbtn[LeaPlusDB["MusicContinent"]]:Click()
				else
					-- Saved continent is not valid button so click default button
					conbtn[L["Zones"]]:Click()
				end
			else
				-- Saved music continent does not exist so click default button
				conbtn[L["Zones"]]:Click()
			end
			UpdateList()

			-- Manage events
			LeaPlusLC["Page9"]:RegisterEvent("PLAYER_LOGOUT")
			LeaPlusLC["Page9"]:RegisterEvent("UI_SCALE_CHANGED")
			LeaPlusLC["Page9"]:SetScript("OnEvent", function(self, event)
				if event == "PLAYER_LOGOUT" then
					-- Stop playing at reload or logout
					if musicHandle then
						StopSound(musicHandle)
					end
				elseif event == "UI_SCALE_CHANGED" then
					-- Refresh list
					UpdateList()
				end
			end)

		end

		-- Run on startup
		LeaPlusLC:MediaFunc()

		-- Release memory
		LeaPlusLC.MediaFunc = nil

		----------------------------------------------------------------------
		-- Panel alpha
		----------------------------------------------------------------------

		do

			-- Function to set panel alpha
			local function SetPlusAlpha()
				-- Set panel alpha
				LeaPlusLC["PageF"].t:SetAlpha(1 - LeaPlusLC["PlusPanelAlpha"])
				-- Show formatted value
				LeaPlusCB["PlusPanelAlpha"].f:SetFormattedText("%.0f%%", LeaPlusLC["PlusPanelAlpha"] * 100)
			end

			-- Set alpha on startup
			SetPlusAlpha()

			-- Set alpha after changing slider
			LeaPlusCB["PlusPanelAlpha"]:HookScript("OnValueChanged", SetPlusAlpha)

		end

		----------------------------------------------------------------------
		-- Panel scale
		----------------------------------------------------------------------

		do

			-- Function to set panel scale
			local function SetPlusScale()
				-- Reset panel position
				LeaPlusLC["MainPanelA"], LeaPlusLC["MainPanelR"], LeaPlusLC["MainPanelX"], LeaPlusLC["MainPanelY"] = "CENTER", "CENTER", 0, 0
				if LeaPlusLC["PageF"]:IsShown() then
					LeaPlusLC["PageF"]:Hide()
					LeaPlusLC["PageF"]:Show()
				end
				-- Set panel scale
				LeaPlusLC["PageF"]:SetScale(LeaPlusLC["PlusPanelScale"])
				-- Update music player highlight bar scale
				LeaPlusLC:UpdateList()
			end

			-- Set scale on startup
			LeaPlusLC["PageF"]:SetScale(LeaPlusLC["PlusPanelScale"])

			-- Set scale and reset panel position after changing slider
			LeaPlusCB["PlusPanelScale"]:HookScript("OnMouseUp", SetPlusScale)
			LeaPlusCB["PlusPanelScale"]:HookScript("OnMouseWheel", SetPlusScale)

			-- Show formatted slider value
			LeaPlusCB["PlusPanelScale"]:HookScript("OnValueChanged", function()
				LeaPlusCB["PlusPanelScale"].f:SetFormattedText("%.0f%%", LeaPlusLC["PlusPanelScale"] * 100)
			end)

		end

		----------------------------------------------------------------------
		-- Create panel in game options panel
		----------------------------------------------------------------------

		do

			local interPanel = CreateFrame("FRAME")
			interPanel.name = "Leatrix Plus"

			local maintitle = LeaPlusLC:MakeTx(interPanel, "Leatrix Plus", 0, 0)
			maintitle:SetFont(maintitle:GetFont(), 72)
			maintitle:ClearAllPoints()
			maintitle:SetPoint("TOP", 0, -72)

			local expTitle = LeaPlusLC:MakeTx(interPanel, "Shadowlands", 0, 0)
			expTitle:SetFont(expTitle:GetFont(), 32)
			expTitle:ClearAllPoints()
			expTitle:SetPoint("TOP", 0, -152)

			local subTitle = LeaPlusLC:MakeTx(interPanel, "curseforge.com/wow/addons/leatrix-plus", 0, 0)
			subTitle:SetFont(subTitle:GetFont(), 20)
			subTitle:ClearAllPoints()
			subTitle:SetPoint("BOTTOM", 0, 72)

			local slashTitle = LeaPlusLC:MakeTx(interPanel, "/ltp", 0, 0)
			slashTitle:SetFont(slashTitle:GetFont(), 72)
			slashTitle:ClearAllPoints()
			slashTitle:SetPoint("BOTTOM", subTitle, "TOP", 0, 40)
			slashTitle:SetScript("OnMouseUp", function(self, button)
				if button == "LeftButton" then
					SlashCmdList["Leatrix_Plus"]("")
				end
			end)
			slashTitle:SetScript("OnEnter", function()
				slashTitle.r,  slashTitle.g, slashTitle.b = slashTitle:GetTextColor()
				slashTitle:SetTextColor(1, 1, 0)
			end)
			slashTitle:SetScript("OnLeave", function()
				slashTitle:SetTextColor(slashTitle.r, slashTitle.g, slashTitle.b)
			end)

			local pTex = interPanel:CreateTexture(nil, "BACKGROUND")
			pTex:SetAllPoints()
			pTex:SetTexture("Interface\\GLUES\\Models\\UI_MainMenu\\swordgradient2")
			pTex:SetAlpha(0.2)
			pTex:SetTexCoord(0, 1, 1, 0)

			expTitle:SetText(L["Forever"])
			local category = Settings.RegisterCanvasLayoutCategory(interPanel, L["Leatrix Plus"])
			Settings.RegisterAddOnCategory(category)

		end

		----------------------------------------------------------------------
		-- Final code for Player
		----------------------------------------------------------------------

		-- Show first run message
		if not LeaPlusDB["FirstRunMessageSeen"] then
			C_Timer.After(1, function()
				LeaPlusLC:Print(L["Enter"] .. " |cff00ff00" .. "/ltp" .. "|r " .. L["or click the minimap button to open Leatrix Plus."])
				LeaPlusDB["FirstRunMessageSeen"] = true
			end)
		end

		-- Register logout event to save settings
		LpEvt:RegisterEvent("PLAYER_LOGOUT")

		-- Update addon memory usage (speeds up initial value)
		UpdateAddOnMemoryUsage()

		-- Release memory
		LeaPlusLC.Player = nil

	end

----------------------------------------------------------------------
-- 	L60: Default events
----------------------------------------------------------------------

	local function eventHandler(self, event, arg1, arg2, ...)

		----------------------------------------------------------------------
		-- L62: Profile events
		----------------------------------------------------------------------

		if event == "ADDON_LOADED" then
			if arg1 == "Leatrix_Plus" then

				-- Replace old var names with new ones
				local function UpdateVars(oldvar, newvar)
					if LeaPlusDB[oldvar] and not LeaPlusDB[newvar] then LeaPlusDB[newvar] = LeaPlusDB[oldvar]; LeaPlusDB[oldvar] = nil end
				end

				UpdateVars("CombineAddonButtons", "MinimapButtonBag")		-- 12.0.00 (24th January 2026)
				UpdateVars("MinimapMod", "MinimapModder")					-- 9.2.26 (24th August 2022)
				UpdateVars("RestorechatMessages", "RestoreChatMessages")	-- 9.2.36 (20th September 2022)

				-- Minimum faster auto loot delay changed from 0.0 to 0.1 in 10.0.20
				if LeaPlusDB["LeaPlusFasterLootDelay"] and LeaPlusDB["LeaPlusFasterLootDelay"] == 0 then
					LeaPlusDB["LeaPlusFasterLootDelay"] = 0.1
				end

				if LeaPlusDB["AutoQuestNoDaily"] and not LeaPlusDB["AutoQuestDaily"] then
					if LeaPlusDB["AutoQuestNoDaily"] == "On" then
						LeaPlusDB["AutoQuestDaily"] = "Off"
					else
						LeaPlusDB["AutoQuestDaily"] = "On"
					end
					LeaPlusDB["AutoQuestNoDaily"] = nil
				end

				-- Mute game sounds split with Mute mount sounds
				if LeaPlusDB["MuteGameSounds"] == "On" and not LeaPlusDB["MuteMountSounds"] then
					if LeaPlusDB["MuteAerials"] == "On"
					or LeaPlusDB["MuteAirships"] == "On"
					or LeaPlusDB["MuteBanLu"] == "On"
					or LeaPlusDB["MuteBikes"] == "On"
					or LeaPlusDB["MuteBrooms"] == "On"
					or LeaPlusDB["MuteDragonriding"] == "On"
					or LeaPlusDB["MuteFurlines"] == "On"
					or LeaPlusDB["MuteGyrocopters"] == "On"
					or LeaPlusDB["MuteHovercraft"] == "On"
					or LeaPlusDB["MuteMechSteps"] == "On"
					or LeaPlusDB["MuteMechsuits"] == "On"
					or LeaPlusDB["MuteOttuks"] == "On"
					or LeaPlusDB["MuteRazorwings"] == "On"
					or LeaPlusDB["MuteRockets"] == "On"
					or LeaPlusDB["MuteSoulEaters"] == "On"
					or LeaPlusDB["MuteSoulseekers"] == "On"
					or LeaPlusDB["MuteStriders"] == "On"
					or LeaPlusDB["MuteTravelers"] == "On"
					or LeaPlusDB["MuteUnicorns"] == "On"
					or LeaPlusDB["MuteZeppelins"] == "On"
					then
						LeaPlusLC["MuteMountSounds"] = "On"
						LeaPlusDB["MuteMountSounds"] = "On"
					end
				end

				-- Automation
				LeaPlusLC:LoadVarChk("AutomateQuests", "Off")				-- Automate quests
				LeaPlusLC:LoadVarChk("AutoQuestShift", "Off")				-- Automate quests requires shift
				LeaPlusLC:LoadVarChk("AutoQuestRegular", "On")				-- Accept regular quests
				LeaPlusLC:LoadVarChk("AutoQuestDaily", "On")				-- Accept daily quests
				LeaPlusLC:LoadVarChk("AutoQuestWeekly", "On")				-- Accept weekly quests
				LeaPlusLC:LoadVarChk("AutoQuestCompleted", "On")			-- Turn-in completed quests
				LeaPlusLC:LoadVarNum("AutoQuestKeyMenu", 1, 1, 4)			-- Automate quests override key
				LeaPlusLC:LoadVarChk("AutomateGossip", "Off")				-- Automate gossip
				LeaPlusLC:LoadVarChk("AutoAcceptSummon", "Off")				-- Accept summon
				LeaPlusLC:LoadVarChk("AutoAcceptRes", "Off")				-- Accept resurrection
				LeaPlusLC:LoadVarChk("AutoResNoCombat", "On")				-- Accept resurrection exclude combat
				LeaPlusLC:LoadVarChk("AutoResNoAfterlife", "Off")			-- Accept resurrection exclude afterlife
				LeaPlusLC:LoadVarChk("AutoReleasePvP", "Off")				-- Release in PvP
				LeaPlusLC:LoadVarChk("AutoReleaseNoAlterac", "Off")			-- Release in PvP Exclude Alterac Valley
				LeaPlusLC:LoadVarNum("AutoReleaseDelay", 0, 0, 3000)		-- Release in PvP Delay

				LeaPlusLC:LoadVarChk("AutoSellJunk", "Off")					-- Sell junk automatically
				LeaPlusLC:LoadVarChk("AutoSellShowSummary", "On")			-- Sell junk summary in chat
				LeaPlusLC:LoadVarChk("AutoSellNoGreyGear", "Off")			-- Sell junk exclude all grey gear
				LeaPlusLC:LoadVarStr("AutoSellExcludeList", "")				-- Sell junk exclude list
				LeaPlusLC:LoadVarChk("AutoRepairGear", "Off")				-- Repair automatically
				LeaPlusLC:LoadVarChk("AutoRepairGuildFunds", "On")			-- Repair using guild funds
				LeaPlusLC:LoadVarChk("AutoRepairShowSummary", "On")			-- Repair show summary in chat

				-- Social
				LeaPlusLC:LoadVarChk("NoDuelRequests", "Off")				-- Block duels
				LeaPlusLC:LoadVarChk("NoPartyInvites", "Off")				-- Block party invites
				LeaPlusLC:LoadVarChk("NoRequestedInvites", "Off")			-- Block requested invites
				LeaPlusLC:LoadVarChk("NoFriendRequests", "Off")				-- Block friend requests
				LeaPlusLC:LoadVarChk("NoSharedQuests", "Off")				-- Block shared quests

				LeaPlusLC:LoadVarChk("AcceptPartyFriends", "Off")			-- Party from friends
				LeaPlusLC:LoadVarChk("InviteFromWhisper", "Off")			-- Invite from whispers
				LeaPlusLC:LoadVarChk("InviteFriendsOnly", "Off")			-- Restrict invites to friends
				LeaPlusLC["InvKey"]	= LeaPlusDB["InvKey"] or "inv"			-- Invite from whisper keyword
				LeaPlusLC:LoadVarChk("FriendlyCommunities", "Off")			-- Friendly communities
				LeaPlusLC:LoadVarChk("FriendlyGuild", "On")					-- Friendly guild

				-- Chat
				LeaPlusLC:LoadVarChk("UseEasyChatResizing", "Off")			-- Use easy resizing
				LeaPlusLC:LoadVarChk("NoCombatLogTab", "Off")				-- Hide the combat log
				LeaPlusLC:LoadVarChk("NoChatButtons", "Off")				-- Hide chat buttons
				LeaPlusLC:LoadVarChk("ShowVoiceButtons", "Off")				-- Show voice buttons
				LeaPlusLC:LoadVarChk("ShowChatMenuButton", "Off")			-- Show chat menu button
				LeaPlusLC:LoadVarChk("NoSocialButton", "Off")				-- Hide social button
				LeaPlusLC:LoadVarChk("UnclampChat", "Off")					-- Unclamp chat frame
				LeaPlusLC:LoadVarChk("MoveChatEditBoxToTop", "Off")			-- Move editbox to top
				LeaPlusLC:LoadVarChk("MoreChatFontSizes", "Off")			-- More chat font sizes

				LeaPlusLC:LoadVarChk("NoStickyChat", "Off")					-- Disable sticky chat
				LeaPlusLC:LoadVarChk("UseArrowKeysInChat", "Off")			-- Use arrow keys in chat
				LeaPlusLC:LoadVarChk("NoChatFade", "Off")					-- Disable chat fade
				LeaPlusLC:LoadVarChk("UnivGroupColor", "Off")				-- Universal group color
				LeaPlusLC:LoadVarChk("RecentChatWindow", "Off")				-- Recent chat window
				LeaPlusLC:LoadVarNum("RecentChatSize", 170, 170, 600)		-- Recent chat size
				LeaPlusLC:LoadVarChk("FilterChatMessages", "Off")			-- Filter chat messages
				LeaPlusLC:LoadVarChk("BlockSpellLinks", "Off")				-- Block spell links
				LeaPlusLC:LoadVarChk("BlockDrunkenSpam", "Off")				-- Block drunken spam
				LeaPlusLC:LoadVarChk("BlockDuelSpam", "Off")				-- Block duel spam
				LeaPlusLC:LoadVarChk("RestoreChatMessages", "Off")			-- Restore chat messages

				-- Text
				LeaPlusLC:LoadVarChk("HideErrorMessages", "Off")			-- Hide error messages
				LeaPlusLC:LoadVarChk("NoHitIndicators", "Off")				-- Hide portrait numbers
				LeaPlusLC:LoadVarChk("HideZoneText", "Off")					-- Hide zone text
				LeaPlusLC:LoadVarChk("HideKeybindText", "Off")				-- Hide keybind text
				LeaPlusLC:LoadVarChk("HideMacroText", "Off")				-- Hide macro text

				LeaPlusLC:LoadVarChk("QuestFontChange", "Off")				-- Resize quest text
				LeaPlusLC:LoadVarNum("LeaPlusQuestFontSize", 12, 10, 30)	-- Quest text slider

				-- Interface
				LeaPlusLC:LoadVarChk("MinimapModder", "Off")				-- Enhance minimap
				LeaPlusLC:LoadVarChk("SquareMinimap", "On")					-- Square minimap
				LeaPlusLC:LoadVarChk("HideMiniAddonMenu", "On")				-- Hide addon menu
				LeaPlusLC:LoadVarChk("UnclampMinimap", "Off")				-- Unclamp minimap cluster
				LeaPlusLC:LoadVarChk("MinimapButtonBag", "Off")				-- Minimap button bag
				LeaPlusLC:LoadVarStr("MiniExcludeList", "")					-- Minimap exclude list
				LeaPlusLC:LoadVarChk("HideMiniAddonButtons", "On")			-- Hide addon buttons
				LeaPlusLC:LoadVarNum("MinimapBorderWidth", 3, 1, 10)		-- Minimap border width
				LeaPlusLC:LoadVarNum("MiniClusterScale", 1, 0.5, 2)			-- Minimap cluster scale
				LeaPlusLC:LoadVarNum("MinimapEffect", 1, 1, 33)				-- Minimap effect

				LeaPlusLC:LoadVarChk("TipModEnable", "Off")					-- Enhance tooltip
				LeaPlusLC:LoadVarChk("TipShowRank", "On")					-- Show rank for your guild
				LeaPlusLC:LoadVarChk("TipShowOtherRank", "Off")				-- Show rank for other guilds
				LeaPlusLC:LoadVarChk("TipShowTarget", "On")					-- Show target
				LeaPlusLC:LoadVarChk("TipBackSimple", "Off")				-- Color backdrops
				LeaPlusLC:LoadVarChk("TipHideInCombat", "Off")				-- Hide tooltips during combat
				LeaPlusLC:LoadVarChk("TipHideShiftOverride", "On")			-- Hide tooltips shift override
				LeaPlusLC:LoadVarChk("TipNoHealthBar", "Off")				-- Hide health bar
				LeaPlusLC:LoadVarNum("LeaPlusTipSize", 1.00, 0.50, 2.00)	-- Tooltip scale slider
				LeaPlusLC:LoadVarNum("TooltipAnchorMenu", 1, 1, 4)			-- Tooltip anchor menu
				LeaPlusLC:LoadVarNum("TipCursorX", 0, -128, 128)			-- Tooltip cursor X offset
				LeaPlusLC:LoadVarNum("TipCursorY", 0, -128, 128)			-- Tooltip cursor Y offset

				LeaPlusLC:LoadVarChk("EnhanceDressup", "Off")				-- Enhance dressup
				LeaPlusLC:LoadVarChk("DressupItemButtons", "On")			-- Dressup item buttons
				LeaPlusLC:LoadVarChk("DressupAnimControl", "On")			-- Dressup animation control
				LeaPlusLC:LoadVarChk("DressupMoreZoomOut", "Off")			-- Dressup increase zoom out distance
				LeaPlusLC:LoadVarChk("DressupTransmogAnim", "Off")			-- Dressup show transmogrify animation control
				LeaPlusLC:LoadVarNum("DressupFasterZoom", 3, 1, 10)			-- Dressup zoom speed

				LeaPlusLC:LoadVarChk("EnhanceFlightMap", "Off")				-- Enhance flight map
				LeaPlusLC:LoadVarNum("LeaPlusTaxiMapScale", 1, 1, 3)		-- Enhance flight map scale
				LeaPlusLC:LoadVarNum("LeaPlusTaxiIconSize", 16, 16, 32)		-- Enhance flight icon size
				LeaPlusLC:LoadVarAnc("FlightMapA", "TOPLEFT")				-- Enhance flight map anchor
				LeaPlusLC:LoadVarAnc("FlightMapR", "TOPLEFT")				-- Enhance flight map relative
				LeaPlusLC:LoadVarNum("FlightMapX", 16, -5000, 5000)			-- Enhance flight map X
				LeaPlusLC:LoadVarNum("FlightMapY", -48, -5000, 5000)			-- Enhance flight map Y

				LeaPlusLC:LoadVarChk("ShowVolume", "Off")					-- Show volume slider
				LeaPlusLC:LoadVarChk("ShowVolumeInFrame", "Off")			-- Volume slider dual layout

				LeaPlusLC:LoadVarChk("DurabilityStatus", "Off")				-- Show durability status
				LeaPlusLC:LoadVarChk("ShowRaidToggle", "Off")				-- Show raid button
				LeaPlusLC:LoadVarChk("ShowTrainAllButton", "Off")			-- Show train all button
				LeaPlusLC:LoadVarChk("ShowBorders", "Off")					-- Show borders
				LeaPlusLC:LoadVarNum("BordersTop", 0, 0, 300)				-- Top border
				LeaPlusLC:LoadVarNum("BordersBottom", 0, 0, 300)			-- Bottom border
				LeaPlusLC:LoadVarNum("BordersLeft", 0, 0, 300)				-- Left border
				LeaPlusLC:LoadVarNum("BordersRight", 0, 0, 300)				-- Right border
				LeaPlusLC:LoadVarNum("BordersAlpha", 0, 0, 0.9)				-- Border alpha
				LeaPlusLC:LoadVarChk("ShowPlayerChain", "Off")				-- Show player chain
				LeaPlusLC:LoadVarNum("PlayerChainMenu", 1, 1, 6)			-- Player chain dropdown value
				LeaPlusLC:LoadVarChk("ShowDruidPowerBar", "Off")			-- Show druid power bar
				LeaPlusLC:LoadVarChk("ShowReadyTimer", "Off")				-- Show ready timer
				LeaPlusLC:LoadVarChk("ShowRangeColoring", "Off")			-- Show range coloring
				LeaPlusLC:LoadVarChk("ShowInfoCards", "Off")				-- Show info cards
				LeaPlusLC:LoadVarStr("InfoCardKey", "")						-- Info card key
				LeaPlusLC:LoadVarChk("ShowWowheadLinks", "Off")				-- Show Wowhead links
				LeaPlusLC:LoadVarChk("WowheadLinkComments", "Off")			-- Show Wowhead links to comments

				-- Frames
				LeaPlusLC:LoadVarChk("ManageWidgetTop", "Off")				-- Manage widget top
				LeaPlusLC:LoadVarAnc("WidgetTopA", "TOP")					-- Manage widget top anchor
				LeaPlusLC:LoadVarAnc("WidgetTopR", "TOP")					-- Manage widget top relative
				LeaPlusLC:LoadVarNum("WidgetTopX", 0, -5000, 5000)			-- Manage widget top position X
				LeaPlusLC:LoadVarNum("WidgetTopY", -15, -5000, 5000)		-- Manage widget top position Y
				LeaPlusLC:LoadVarNum("WidgetTopScale", 1, 0.5, 2)			-- Manage widget top scale

				LeaPlusLC:LoadVarChk("ClassColFrames", "Off")				-- Class colored frames
				LeaPlusLC:LoadVarChk("ClassColPlayer", "On")				-- Class colored player frame
				LeaPlusLC:LoadVarChk("ClassColTarget", "On")				-- Class colored target frame
				LeaPlusLC:LoadVarChk("ClassColPlayerBorder", "Off")			-- Class colored player frame border
				LeaPlusLC:LoadVarChk("ClassColTargetBorder", "Off")			-- Class colored target frame border
				LeaPlusLC:LoadVarChk("ClassColChain", "Off")				-- Class colored player chain

				LeaPlusLC:LoadVarChk("NoAlerts", "Off")						-- Hide alerts
				LeaPlusLC:LoadVarChk("HideCleanupBtns", "Off")				-- Hide clean-up buttons
				LeaPlusLC:LoadVarChk("HideBossBanner", "Off")				-- Hide boss banner
				LeaPlusLC:LoadVarChk("HideEventToasts", "Off")				-- Hide event toasts
				LeaPlusLC:LoadVarChk("NoClassBar", "Off")					-- Hide stance bar
				LeaPlusLC:LoadVarChk("NoRestedSleep", "Off")				-- Hide rested sleep

				-- System
				LeaPlusLC:LoadVarChk("NoDrunkenHaze", "Off")				-- Disable drunken haze
				LeaPlusLC:LoadVarChk("NoScreenEffects", "Off")				-- Disable screen effects
				LeaPlusLC:LoadVarChk("SetWeatherDensity", "Off")			-- Set weather density
				LeaPlusLC:LoadVarNum("WeatherLevel", 3, 0, 3)				-- Weather density level
				LeaPlusLC:LoadVarChk("MaxCameraZoom", "Off")				-- Max camera zoom

				LeaPlusLC:LoadVarChk("NoRestedEmotes", "Off")				-- Silence rested emotes
				LeaPlusLC:LoadVarChk("KeepAudioSynced", "Off")				-- Keep audio synced
				LeaPlusLC:LoadVarChk("MuteGameSounds", "Off")				-- Mute game sounds
				LeaPlusLC:LoadVarChk("MuteMountSounds", "Off")				-- Mute mount sounds
				LeaPlusLC:LoadVarChk("MuteCustomSounds", "Off")				-- Mute custom sounds
				LeaPlusLC:LoadVarStr("MuteCustomList", "")					-- Mute custom sounds list

				LeaPlusLC:LoadVarChk("NoRaidRestrictions", "Off")			-- Remove raid restrictions
				LeaPlusLC:LoadVarChk("NoConfirmLoot", "Off")				-- Disable loot warnings
				LeaPlusLC:LoadVarChk("FasterLooting", "Off")				-- Faster auto loot
				LeaPlusLC:LoadVarNum("LeaPlusFasterLootDelay", 0.3, 0.1, 0.3)	-- Faster auto loot delay

				LeaPlusLC:LoadVarChk("FasterMovieSkip", "Off")				-- Faster movie skip
				LeaPlusLC:LoadVarChk("CombatPlates", "Off")					-- Combat plates
				LeaPlusLC:LoadVarChk("EasyItemDestroy", "Off")				-- Easy item destroy
				LeaPlusLC:LoadVarChk("NoTransforms", "Off")					-- Remove transforms

				LeaPlusLC:LoadVarChk("ShowFlightTimes", "Off")				-- Show flight times
				LeaPlusLC:LoadVarChk("FlightBarBackground", "On")			-- Show flight times bar background
				LeaPlusLC:LoadVarChk("FlightBarDestination", "On")			-- Show flight times bar destination
				LeaPlusLC:LoadVarChk("FlightBarNextHop", "On")				-- Show flight times bar next stop
				LeaPlusLC:LoadVarChk("FlightBarFillBar", "Off")				-- Show flight times bar fill mode
				LeaPlusLC:LoadVarChk("FlightBarSpeech", "Off")				-- Show flight times bar speech
				LeaPlusLC:LoadVarChk("FlightBarContribute", "On")			-- Show flight times contribute
				LeaPlusLC:LoadVarAnc("FlightBarA", "TOP")					-- Show flight times anchor
				LeaPlusLC:LoadVarAnc("FlightBarR", "TOP")					-- Show flight times relative
				LeaPlusLC:LoadVarNum("FlightBarX", 0, -5000, 5000)			-- Show flight position X
				LeaPlusLC:LoadVarNum("FlightBarY", -66, -5000, 5000)		-- Show flight position Y
				LeaPlusLC:LoadVarNum("FlightBarScale", 2, 1, 5)				-- Show flight times bar scale
				LeaPlusLC:LoadVarNum("FlightBarWidth", 230, 40, 460)		-- Show flight times bar width
				LeaPlusLC:LoadVarNum("FlightBarFontSize", 10, 6, 20)		-- Show flight times bar text size

				-- Settings
				LeaPlusLC:LoadVarNum("AddonLanguage", 1, 1, 12)				-- Addon language
				LeaPlusLC:LoadVarChk("ShowMinimapIcon", "On")				-- Show minimap button
				LeaPlusLC:LoadVarChk("SetEditModeLayout", "Off")			-- Set edit mode layout
				LeaPlusLC["EditModeLayoutName"]	= LeaPlusDB["EditModeLayoutName"] or ""			-- Edit mode layout name
				LeaPlusLC:LoadVarChk("SimpleAddonListing", "Off")			-- Simple addon listing

				LeaPlusLC:LoadVarNum("PlusPanelScale", 1, 1, 2)				-- Panel scale
				LeaPlusLC:LoadVarNum("PlusPanelAlpha", 0, 0, 1)				-- Panel alpha

				-- Panel position
				LeaPlusLC:LoadVarAnc("MainPanelA", "CENTER")				-- Panel anchor
				LeaPlusLC:LoadVarAnc("MainPanelR", "CENTER")				-- Panel relative
				LeaPlusLC:LoadVarNum("MainPanelX", 0, -5000, 5000)			-- Panel X axis
				LeaPlusLC:LoadVarNum("MainPanelY", 0, -5000, 5000)			-- Panel Y axis

				-- Start page
				LeaPlusLC:LoadVarNum("LeaStartPage", 0, 0, LeaPlusLC["NumberOfPages"])

				-- Lock conflicting options
				do

					-- Function to disable and lock an option and add a note to the tooltip
					local function Lock(option, reason, optmodule)
						LeaLockList[option] = LeaPlusLC[option]
						LeaPlusLC:LockItem(LeaPlusCB[option], true)
						LeaPlusCB[option].tiptext = LeaPlusCB[option].tiptext .. "|n|n|cff00AAFF" .. L[reason]
						if optmodule then
							LeaPlusCB[option].tiptext = LeaPlusCB[option].tiptext .. " " .. L[optmodule] .. " " .. L["module"]
						end
						LeaPlusCB[option].tiptext = LeaPlusCB[option].tiptext .. "."
						-- Remove hover from configuration button if there is one
						local temp = {LeaPlusCB[option]:GetChildren()}
						if temp and temp[1] and temp[1].t and temp[1].t:GetTexture() == 311225 then
							temp[1]:SetHighlightTexture(0)
							temp[1]:SetScript("OnEnter", nil)
						end
					end

					-- Disable items that conflict with Easy Frames
					if C_AddOns.IsAddOnLoaded("EasyFrames") then
						Lock("ClassColFrames", L["Cannot be used with Easy Frames"]) -- Class colored frames
					end

					-- Disable items that conflict with Glass
					if C_AddOns.IsAddOnLoaded("Glass") then
						local reason = L["Cannot be used with Glass"]
						Lock("UseEasyChatResizing", reason) -- Use easy resizing
						Lock("NoCombatLogTab", reason) -- Hide the combat log
						Lock("NoChatButtons", reason) -- Hide chat buttons
						Lock("NoSocialButton", reason) -- Hide social button
						Lock("UnclampChat", reason) -- Unclamp chat frame
						Lock("MoveChatEditBoxToTop", reason) -- Move editbox to top
						Lock("MoreChatFontSizes", reason) -- More chat font sizes
						Lock("NoChatFade", reason) --  Disable chat fade
						Lock("RecentChatWindow", reason) -- Recent chat window
					end

					-- Disable items that conflict with ElvUI
					if LeaPlusLC.ElvUI then
						local E = LeaPlusLC.ElvUI
						if E and E.private then

							local reason = L["Cannot be used with ElvUI"]

							-- Chat
							if E.private.chat.enable then
								Lock("UseEasyChatResizing", reason, "Chat") -- Use easy resizing
								Lock("NoCombatLogTab", reason, "Chat") -- Hide the combat log
								Lock("NoChatButtons", reason, "Chat") -- Hide chat buttons
								Lock("NoSocialButton", reason, "Chat") -- Hide social button
								Lock("UnclampChat", reason, "Chat") -- Unclamp chat frame
								Lock("MoreChatFontSizes", reason, "Chat") --  More chat font sizes
								Lock("NoStickyChat", reason, "Chat") -- Disable sticky chat
								Lock("UseArrowKeysInChat", reason, "Chat") -- Use arrow keys in chat
								Lock("NoChatFade", reason, "Chat") -- Disable chat fade
								Lock("RestoreChatMessages", reason, "Chat") -- Restore chat messages (E.db.chat.chatHistory)
							end

							-- Minimap
							if E.private.general.minimap.enable then
								Lock("MinimapModder", reason, "Minimap") -- Enhance minimap
							end

							-- UnitFrames
							if E.private.unitframe.enable then
								Lock("ShowRaidToggle", reason, "UnitFrames") -- Show raid button
								Lock("ShowDruidPowerBar", reason, "UnitFrames") -- Show druid power bar
							end

							-- ActionBars
							if E.private.actionbar.enable then
								Lock("NoClassBar", reason, "ActionBars") -- Hide stance bar
								Lock("HideKeybindText", reason, "ActionBars") -- Hide keybind text
								Lock("HideMacroText", reason, "ActionBars") -- Hide macro text
							end

							-- Bags
							if E.private.bags.enable then
								Lock("HideCleanupBtns", reason, "Bags") -- Hide clean-up buttons
							end

							-- Tooltip
							if E.private.tooltip.enable then
								Lock("TipModEnable", reason, "Tooltip") -- Enhance tooltip
							end

							-- UnitFrames: Disabled Blizzard: Player
							if E.private.unitframe.disabledBlizzardFrames.player then
								Lock("ShowPlayerChain", reason, "UnitFrames (Disabled Blizzard Frames Player)") -- Show player chain
								Lock("NoHitIndicators", reason, "UnitFrames (Disabled Blizzard Frames Player)") -- Hide portrait numbers
								Lock("NoRestedSleep", reason, "UnitFrames (Disabled Blizzard Frames Player)") -- Hide rested sleep
							end

							-- UnitFrames: Disabled Blizzard: Player, Target or Focus
							if E.private.unitframe.disabledBlizzardFrames.player or E.private.unitframe.disabledBlizzardFrames.target or E.private.unitframe.disabledBlizzardFrames.focus then
								Lock("ClassColFrames", reason, "UnitFrames (Disabled Blizzard Frames Player, Target and Focus)") -- Class-colored frames
							end

							-- Base
							do
								Lock("ManageWidgetTop", reason) -- Manage widget top
							end

						end

						C_AddOns.EnableAddOn("Leatrix_Plus")
					end

				end

				-- Lock options currently not compatible with the next expansion (LeaPlusLC.DF)
				local function LockDF(option, reason)
					LeaPlusLC[option] = "Off"
					LeaPlusDB[option] = "Off"
					LeaPlusLC:LockItem(LeaPlusCB[option], true)
					if reason then
						LeaPlusCB[option].tiptext = LeaPlusCB[option].tiptext .. "|n|n|cff00AAFF" .. L[reason]
					end
				end

				--if LeaPlusLC.NewPatch then
					-- Lock Filter chat messages in Forever because it breaks chat at the moment due to game bug
					LockDF("FilterChatMessages", "Not available yet.") -- Combat, edit mode, drag minimap
				--end

				-- Run other startup items
				LeaPlusLC:SetDim()

			end
			return
		end

		if event == "PLAYER_LOGIN" then
			LeaPlusLC:Player()
			collectgarbage()
			return
		end

		-- Save locals back to globals on logout
		if event == "PLAYER_LOGOUT" then

			-- Run the logout function without wipe flag
			LeaPlusLC:PlayerLogout(false)

			-- Automation
			LeaPlusDB["AutomateQuests"]			= LeaPlusLC["AutomateQuests"]
			LeaPlusDB["AutoQuestShift"]			= LeaPlusLC["AutoQuestShift"]
			LeaPlusDB["AutoQuestRegular"]		= LeaPlusLC["AutoQuestRegular"]
			LeaPlusDB["AutoQuestDaily"]			= LeaPlusLC["AutoQuestDaily"]
			LeaPlusDB["AutoQuestWeekly"]		= LeaPlusLC["AutoQuestWeekly"]
			LeaPlusDB["AutoQuestCompleted"]		= LeaPlusLC["AutoQuestCompleted"]
			LeaPlusDB["AutoQuestKeyMenu"]		= LeaPlusLC["AutoQuestKeyMenu"]
			LeaPlusDB["AutomateGossip"]			= LeaPlusLC["AutomateGossip"]
			LeaPlusDB["AutoAcceptSummon"] 		= LeaPlusLC["AutoAcceptSummon"]
			LeaPlusDB["AutoAcceptRes"] 			= LeaPlusLC["AutoAcceptRes"]
			LeaPlusDB["AutoResNoCombat"] 		= LeaPlusLC["AutoResNoCombat"]
			LeaPlusDB["AutoResNoAfterlife"] 	= LeaPlusLC["AutoResNoAfterlife"]
			LeaPlusDB["AutoReleasePvP"] 		= LeaPlusLC["AutoReleasePvP"]
			LeaPlusDB["AutoReleaseNoAlterac"] 	= LeaPlusLC["AutoReleaseNoAlterac"]
			LeaPlusDB["AutoReleaseDelay"] 		= LeaPlusLC["AutoReleaseDelay"]

			LeaPlusDB["AutoSellJunk"] 			= LeaPlusLC["AutoSellJunk"]
			LeaPlusDB["AutoSellShowSummary"] 	= LeaPlusLC["AutoSellShowSummary"]
			LeaPlusDB["AutoSellNoGreyGear"] 	= LeaPlusLC["AutoSellNoGreyGear"]
			LeaPlusDB["AutoSellExcludeList"] 	= LeaPlusLC["AutoSellExcludeList"]
			LeaPlusDB["AutoRepairGear"] 		= LeaPlusLC["AutoRepairGear"]
			LeaPlusDB["AutoRepairGuildFunds"] 	= LeaPlusLC["AutoRepairGuildFunds"]
			LeaPlusDB["AutoRepairShowSummary"] 	= LeaPlusLC["AutoRepairShowSummary"]

			-- Social
			LeaPlusDB["NoDuelRequests"] 		= LeaPlusLC["NoDuelRequests"]
			LeaPlusDB["NoPartyInvites"]			= LeaPlusLC["NoPartyInvites"]
			LeaPlusDB["NoRequestedInvites"]		= LeaPlusLC["NoRequestedInvites"]
			LeaPlusDB["NoFriendRequests"]		= LeaPlusLC["NoFriendRequests"]
			LeaPlusDB["NoSharedQuests"]			= LeaPlusLC["NoSharedQuests"]

			LeaPlusDB["AcceptPartyFriends"]		= LeaPlusLC["AcceptPartyFriends"]
			LeaPlusDB["InviteFromWhisper"]		= LeaPlusLC["InviteFromWhisper"]
			LeaPlusDB["InviteFriendsOnly"]		= LeaPlusLC["InviteFriendsOnly"]
			LeaPlusDB["InvKey"]					= LeaPlusLC["InvKey"]
			LeaPlusDB["FriendlyCommunities"]	= LeaPlusLC["FriendlyCommunities"]
			LeaPlusDB["FriendlyGuild"]			= LeaPlusLC["FriendlyGuild"]

			-- Chat
			LeaPlusDB["UseEasyChatResizing"]	= LeaPlusLC["UseEasyChatResizing"]
			LeaPlusDB["NoCombatLogTab"]			= LeaPlusLC["NoCombatLogTab"]
			LeaPlusDB["NoChatButtons"]			= LeaPlusLC["NoChatButtons"]
			LeaPlusDB["ShowVoiceButtons"]		= LeaPlusLC["ShowVoiceButtons"]
			LeaPlusDB["ShowChatMenuButton"]		= LeaPlusLC["ShowChatMenuButton"]
			LeaPlusDB["NoSocialButton"]			= LeaPlusLC["NoSocialButton"]
			LeaPlusDB["UnclampChat"]			= LeaPlusLC["UnclampChat"]
			LeaPlusDB["MoveChatEditBoxToTop"]	= LeaPlusLC["MoveChatEditBoxToTop"]
			LeaPlusDB["MoreChatFontSizes"]		= LeaPlusLC["MoreChatFontSizes"]

			LeaPlusDB["NoStickyChat"] 			= LeaPlusLC["NoStickyChat"]
			LeaPlusDB["UseArrowKeysInChat"]		= LeaPlusLC["UseArrowKeysInChat"]
			LeaPlusDB["NoChatFade"]				= LeaPlusLC["NoChatFade"]
			LeaPlusDB["UnivGroupColor"]			= LeaPlusLC["UnivGroupColor"]
			LeaPlusDB["RecentChatWindow"]		= LeaPlusLC["RecentChatWindow"]
			LeaPlusDB["RecentChatSize"]			= LeaPlusLC["RecentChatSize"]
			LeaPlusDB["FilterChatMessages"]		= LeaPlusLC["FilterChatMessages"]
			LeaPlusDB["BlockSpellLinks"]		= LeaPlusLC["BlockSpellLinks"]
			LeaPlusDB["BlockDrunkenSpam"]		= LeaPlusLC["BlockDrunkenSpam"]
			LeaPlusDB["BlockDuelSpam"]			= LeaPlusLC["BlockDuelSpam"]
			LeaPlusDB["RestoreChatMessages"]	= LeaPlusLC["RestoreChatMessages"]

			-- Text
			LeaPlusDB["HideErrorMessages"]		= LeaPlusLC["HideErrorMessages"]
			LeaPlusDB["NoHitIndicators"]		= LeaPlusLC["NoHitIndicators"]
			LeaPlusDB["HideZoneText"] 			= LeaPlusLC["HideZoneText"]
			LeaPlusDB["HideKeybindText"] 		= LeaPlusLC["HideKeybindText"]
			LeaPlusDB["HideMacroText"] 			= LeaPlusLC["HideMacroText"]

			LeaPlusDB["QuestFontChange"] 		= LeaPlusLC["QuestFontChange"]
			LeaPlusDB["LeaPlusQuestFontSize"]	= LeaPlusLC["LeaPlusQuestFontSize"]

			-- Interface
			LeaPlusDB["MinimapModder"]			= LeaPlusLC["MinimapModder"]
			LeaPlusDB["SquareMinimap"]			= LeaPlusLC["SquareMinimap"]
			LeaPlusDB["HideMiniAddonMenu"]		= LeaPlusLC["HideMiniAddonMenu"]
			LeaPlusDB["UnclampMinimap"]			= LeaPlusLC["UnclampMinimap"]
			LeaPlusDB["MinimapButtonBag"]		= LeaPlusLC["MinimapButtonBag"]
			LeaPlusDB["MiniExcludeList"] 		= LeaPlusLC["MiniExcludeList"]
			LeaPlusDB["HideMiniAddonButtons"]	= LeaPlusLC["HideMiniAddonButtons"]
			LeaPlusDB["MinimapBorderWidth"]		= LeaPlusLC["MinimapBorderWidth"]
			LeaPlusDB["MiniClusterScale"]		= LeaPlusLC["MiniClusterScale"]
			LeaPlusDB["MinimapEffect"]			= LeaPlusLC["MinimapEffect"]

			LeaPlusDB["TipModEnable"]			= LeaPlusLC["TipModEnable"]
			LeaPlusDB["TipShowRank"]			= LeaPlusLC["TipShowRank"]
			LeaPlusDB["TipShowOtherRank"]		= LeaPlusLC["TipShowOtherRank"]
			LeaPlusDB["TipShowTarget"]			= LeaPlusLC["TipShowTarget"]
			LeaPlusDB["TipBackSimple"]			= LeaPlusLC["TipBackSimple"]
			LeaPlusDB["TipHideInCombat"]		= LeaPlusLC["TipHideInCombat"]
			LeaPlusDB["TipHideShiftOverride"]	= LeaPlusLC["TipHideShiftOverride"]
			LeaPlusDB["TipNoHealthBar"]			= LeaPlusLC["TipNoHealthBar"]
			LeaPlusDB["LeaPlusTipSize"]			= LeaPlusLC["LeaPlusTipSize"]
			LeaPlusDB["TooltipAnchorMenu"]		= LeaPlusLC["TooltipAnchorMenu"]
			LeaPlusDB["TipCursorX"]				= LeaPlusLC["TipCursorX"]
			LeaPlusDB["TipCursorY"]				= LeaPlusLC["TipCursorY"]

			LeaPlusDB["EnhanceDressup"]			= LeaPlusLC["EnhanceDressup"]
			LeaPlusDB["DressupItemButtons"]		= LeaPlusLC["DressupItemButtons"]
			LeaPlusDB["DressupAnimControl"]		= LeaPlusLC["DressupAnimControl"]
			LeaPlusDB["DressupMoreZoomOut"]		= LeaPlusLC["DressupMoreZoomOut"]
			LeaPlusDB["DressupTransmogAnim"]	= LeaPlusLC["DressupTransmogAnim"]
			LeaPlusDB["DressupFasterZoom"]		= LeaPlusLC["DressupFasterZoom"]

			LeaPlusDB["EnhanceFlightMap"]		= LeaPlusLC["EnhanceFlightMap"]
			LeaPlusDB["LeaPlusTaxiMapScale"]	= LeaPlusLC["LeaPlusTaxiMapScale"]
			LeaPlusDB["LeaPlusTaxiIconSize"]	= LeaPlusLC["LeaPlusTaxiIconSize"]
			LeaPlusDB["FlightMapA"]				= LeaPlusLC["FlightMapA"]
			LeaPlusDB["FlightMapR"]				= LeaPlusLC["FlightMapR"]
			LeaPlusDB["FlightMapX"]				= LeaPlusLC["FlightMapX"]
			LeaPlusDB["FlightMapY"]				= LeaPlusLC["FlightMapY"]

			LeaPlusDB["ShowVolume"] 			= LeaPlusLC["ShowVolume"]
			LeaPlusDB["ShowVolumeInFrame"] 		= LeaPlusLC["ShowVolumeInFrame"]

			LeaPlusDB["DurabilityStatus"]		= LeaPlusLC["DurabilityStatus"]
			LeaPlusDB["ShowRaidToggle"]			= LeaPlusLC["ShowRaidToggle"]
			LeaPlusDB["ShowTrainAllButton"]		= LeaPlusLC["ShowTrainAllButton"]
			LeaPlusDB["ShowBorders"]			= LeaPlusLC["ShowBorders"]
			LeaPlusDB["BordersTop"]				= LeaPlusLC["BordersTop"]
			LeaPlusDB["BordersBottom"]			= LeaPlusLC["BordersBottom"]
			LeaPlusDB["BordersLeft"]			= LeaPlusLC["BordersLeft"]
			LeaPlusDB["BordersRight"]			= LeaPlusLC["BordersRight"]
			LeaPlusDB["BordersAlpha"]			= LeaPlusLC["BordersAlpha"]
			LeaPlusDB["ShowPlayerChain"]		= LeaPlusLC["ShowPlayerChain"]
			LeaPlusDB["PlayerChainMenu"]		= LeaPlusLC["PlayerChainMenu"]
			LeaPlusDB["ShowDruidPowerBar"]		= LeaPlusLC["ShowDruidPowerBar"]
			LeaPlusDB["ShowReadyTimer"]			= LeaPlusLC["ShowReadyTimer"]
			LeaPlusDB["ShowRangeColoring"]		= LeaPlusLC["ShowRangeColoring"]
			LeaPlusDB["ShowInfoCards"]			= LeaPlusLC["ShowInfoCards"]
			LeaPlusDB["InfoCardKey"]			= LeaPlusLC["InfoCardKey"]
			LeaPlusDB["ShowWowheadLinks"]		= LeaPlusLC["ShowWowheadLinks"]
			LeaPlusDB["WowheadLinkComments"]	= LeaPlusLC["WowheadLinkComments"]

			-- Frames
			LeaPlusDB["ManageWidgetTop"]		= LeaPlusLC["ManageWidgetTop"]
			LeaPlusDB["WidgetTopA"]				= LeaPlusLC["WidgetTopA"]
			LeaPlusDB["WidgetTopR"]				= LeaPlusLC["WidgetTopR"]
			LeaPlusDB["WidgetTopX"]				= LeaPlusLC["WidgetTopX"]
			LeaPlusDB["WidgetTopY"]				= LeaPlusLC["WidgetTopY"]
			LeaPlusDB["WidgetTopScale"]			= LeaPlusLC["WidgetTopScale"]

			LeaPlusDB["ClassColFrames"]			= LeaPlusLC["ClassColFrames"]
			LeaPlusDB["ClassColPlayer"]			= LeaPlusLC["ClassColPlayer"]
			LeaPlusDB["ClassColTarget"]			= LeaPlusLC["ClassColTarget"]
			LeaPlusDB["ClassColPlayerBorder"]	= LeaPlusLC["ClassColPlayerBorder"]
			LeaPlusDB["ClassColTargetBorder"]	= LeaPlusLC["ClassColTargetBorder"]
			LeaPlusDB["ClassColChain"]			= LeaPlusLC["ClassColChain"]

			LeaPlusDB["NoAlerts"]				= LeaPlusLC["NoAlerts"]
			LeaPlusDB["HideCleanupBtns"]		= LeaPlusLC["HideCleanupBtns"]
			LeaPlusDB["HideBossBanner"]			= LeaPlusLC["HideBossBanner"]
			LeaPlusDB["HideEventToasts"]		= LeaPlusLC["HideEventToasts"]
			LeaPlusDB["NoClassBar"]				= LeaPlusLC["NoClassBar"]
			LeaPlusDB["NoRestedSleep"]			= LeaPlusLC["NoRestedSleep"]

			-- System
			LeaPlusDB["NoDrunkenHaze"] 			= LeaPlusLC["NoDrunkenHaze"]
			LeaPlusDB["NoScreenEffects"] 		= LeaPlusLC["NoScreenEffects"]
			LeaPlusDB["SetWeatherDensity"] 		= LeaPlusLC["SetWeatherDensity"]
			LeaPlusDB["WeatherLevel"] 			= LeaPlusLC["WeatherLevel"]
			LeaPlusDB["MaxCameraZoom"] 			= LeaPlusLC["MaxCameraZoom"]

			LeaPlusDB["NoRestedEmotes"]			= LeaPlusLC["NoRestedEmotes"]
			LeaPlusDB["KeepAudioSynced"]		= LeaPlusLC["KeepAudioSynced"]
			LeaPlusDB["MuteGameSounds"]			= LeaPlusLC["MuteGameSounds"]
			LeaPlusDB["MuteMountSounds"]		= LeaPlusLC["MuteMountSounds"]
			LeaPlusDB["MuteCustomSounds"]		= LeaPlusLC["MuteCustomSounds"]
			LeaPlusDB["MuteCustomList"]			= LeaPlusLC["MuteCustomList"]

			LeaPlusDB["NoRaidRestrictions"]		= LeaPlusLC["NoRaidRestrictions"]
			LeaPlusDB["NoConfirmLoot"] 			= LeaPlusLC["NoConfirmLoot"]
			LeaPlusDB["FasterLooting"] 			= LeaPlusLC["FasterLooting"]
			LeaPlusDB["LeaPlusFasterLootDelay"] = LeaPlusLC["LeaPlusFasterLootDelay"]

			LeaPlusDB["FasterMovieSkip"] 		= LeaPlusLC["FasterMovieSkip"]
			LeaPlusDB["CombatPlates"]			= LeaPlusLC["CombatPlates"]
			LeaPlusDB["EasyItemDestroy"]		= LeaPlusLC["EasyItemDestroy"]
			LeaPlusDB["NoTransforms"] 			= LeaPlusLC["NoTransforms"]

			LeaPlusDB["ShowFlightTimes"]		= LeaPlusLC["ShowFlightTimes"]
			LeaPlusDB["FlightBarBackground"]	= LeaPlusLC["FlightBarBackground"]
			LeaPlusDB["FlightBarDestination"]	= LeaPlusLC["FlightBarDestination"]
			LeaPlusDB["FlightBarNextHop"]		= LeaPlusLC["FlightBarNextHop"]
			LeaPlusDB["FlightBarFillBar"]		= LeaPlusLC["FlightBarFillBar"]
			LeaPlusDB["FlightBarSpeech"]		= LeaPlusLC["FlightBarSpeech"]
			LeaPlusDB["FlightBarContribute"]	= LeaPlusLC["FlightBarContribute"]
			LeaPlusDB["FlightBarA"]				= LeaPlusLC["FlightBarA"]
			LeaPlusDB["FlightBarR"]				= LeaPlusLC["FlightBarR"]
			LeaPlusDB["FlightBarX"]				= LeaPlusLC["FlightBarX"]
			LeaPlusDB["FlightBarY"]				= LeaPlusLC["FlightBarY"]
			LeaPlusDB["FlightBarScale"]			= LeaPlusLC["FlightBarScale"]
			LeaPlusDB["FlightBarWidth"]			= LeaPlusLC["FlightBarWidth"]
			LeaPlusDB["FlightBarFontSize"]		= LeaPlusLC["FlightBarFontSize"]

			-- Settings
			LeaPlusDB["AddonLanguage"] 			= LeaPlusLC["AddonLanguage"]
			LeaPlusDB["ShowMinimapIcon"] 		= LeaPlusLC["ShowMinimapIcon"]
			LeaPlusDB["SetEditModeLayout"] 		= LeaPlusLC["SetEditModeLayout"]
			LeaPlusDB["EditModeLayoutName"] 	= LeaPlusLC["EditModeLayoutName"]
			LeaPlusDB["SimpleAddonListing"] 	= LeaPlusLC["SimpleAddonListing"]

			LeaPlusDB["PlusPanelScale"] 		= LeaPlusLC["PlusPanelScale"]
			LeaPlusDB["PlusPanelAlpha"] 		= LeaPlusLC["PlusPanelAlpha"]

			-- Panel position
			LeaPlusDB["MainPanelA"]				= LeaPlusLC["MainPanelA"]
			LeaPlusDB["MainPanelR"]				= LeaPlusLC["MainPanelR"]
			LeaPlusDB["MainPanelX"]				= LeaPlusLC["MainPanelX"]
			LeaPlusDB["MainPanelY"]				= LeaPlusLC["MainPanelY"]

			-- Start page
			LeaPlusDB["LeaStartPage"]			= LeaPlusLC["LeaStartPage"]

			-- Mute game sounds (LeaPlusLC["MuteGameSounds"])
			for k, v in pairs(LeaPlusLC["muteTable"]) do
				LeaPlusDB[k] = LeaPlusLC[k]
			end

			-- Mute mount sounds (LeaPlusLC["MuteMountSounds"])
			for k, v in pairs(LeaPlusLC["mountTable"]) do
				LeaPlusDB[k] = LeaPlusLC[k]
			end

			-- Remove transforms (LeaPlusLC["NoTransforms"])
			for k, v in pairs(LeaPlusLC["transTable"]) do
				LeaPlusDB[k] = LeaPlusLC[k]
			end

		end

	end

--	Register event handler
	LpEvt:SetScript("OnEvent", eventHandler)

----------------------------------------------------------------------
--	L70: Player logout
----------------------------------------------------------------------

	-- Player Logout
	function LeaPlusLC:PlayerLogout(wipe)

		----------------------------------------------------------------------
		-- Restore default values for options that do not require reloads
		----------------------------------------------------------------------

		if wipe then

			-- Disable drunken haze (LeaPlusLC["NoDrunkenHaze"])
			SetCVar("ffxGlow", "1")

			-- Disable screen effects (LeaPlusLC["NoScreenEffects"])
			SetCVar("ffxDeath", "1")
			SetCVar("ffxNether", "1")
			SetCVar("ffxVenari", "1")
			SetCVar("ffxLingeringVenari", "1")

			-- Set weather density (LeaPlusLC["SetWeatherDensity"])
			SetCVar("WeatherDensity", "3")
			SetCVar("RAIDweatherDensity", "3")

			-- Remove raid restrictions (LeaPlusLC["NoRaidRestrictions"])
			SetAllowLowLevelRaid(false)

			-- Max camera zoom (LeaPlusLC["MaxCameraZoom"])
			SetCVar("cameraDistanceMaxZoomFactor", 1.9)

			-- Universal group color (LeaPlusLC["UnivGroupColor"])
			ChangeChatColor("RAID", 1, 0.50, 0)
			ChangeChatColor("RAID_LEADER", 1, 0.28, 0.04)
			ChangeChatColor("INSTANCE_CHAT", 1, 0.50, 0)
			ChangeChatColor("INSTANCE_CHAT_LEADER", 1, 0.28, 0.04)

			-- Mute game sounds (LeaPlusLC["MuteGameSounds"])
			for k, v in pairs(LeaPlusLC["muteTable"]) do
				for i, e in pairs(v) do
					local file, soundID = e:match("([^,]+)%#([^,]+)")
					UnmuteSoundFile(soundID)
				end
			end

			-- Mute mount sounds (LeaPlusLC["MuteMountSounds"])
			for k, v in pairs(LeaPlusLC["mountTable"]) do
				for i, e in pairs(v) do
					local file, soundID = e:match("([^,]+)%#([^,]+)")
					UnmuteSoundFile(soundID)
				end
			end

		end

		----------------------------------------------------------------------
		-- Restore default values for options that require reloads
		----------------------------------------------------------------------

		-- Silence rested emotes
		if LeaPlusDB["NoRestedEmotes"] == "On" then
			if wipe or (not wipe and LeaPlusLC["NoRestedEmotes"] == "Off") then
				SetCVar("Sound_EnableEmoteSounds", "1")
			end
		end

	end

----------------------------------------------------------------------
-- 	Options panel functions
----------------------------------------------------------------------

	-- Function to add textures to panels
	function LeaPlusLC:CreateBar(name, parent, width, height, anchor, r, g, b, alp, tex)
		local ft = parent:CreateTexture(nil, "BORDER")
		ft:SetTexture(tex)
		ft:SetSize(width, height)
		ft:SetPoint(anchor)
		ft:SetVertexColor(r ,g, b, alp)
		if name == "MainTexture" then
			ft:SetTexCoord(0.09, 1, 0, 1);
		end
	end

	-- Create a configuration panel
	function LeaPlusLC:CreatePanel(title, globref, scrolling)

		-- Create the panel
		local Side = CreateFrame("Frame", LeaPlusLC:CreateRandomName(), UIParent)

		-- Make it a system frame
		table.insert(UISpecialFrames, Side:GetName())

		-- Store it in the configuration panel table
		tinsert(LeaConfigList, Side)

		-- Set frame parameters
		Side:Hide();
		Side:SetSize(570, LeaPlusLC.MainPanelHeight)
		Side:SetClampedToScreen(true)
		Side:SetClampRectInsets(500, -500, -300, 300)
		Side:SetFrameStrata("FULLSCREEN_DIALOG")

		-- Set the background color
		Side.t = Side:CreateTexture(nil, "BACKGROUND")
		Side.t:SetAllPoints()
		Side.t:SetColorTexture(0.05, 0.05, 0.05, 0.9)

		-- Add a close Button
		Side.c = LeaPlusLC:CreateCloseButton(Side, 30, 30, "TOPRIGHT", 0, 0)
		Side.c:SetScript("OnClick", function() Side:Hide() end)

		-- Add reset, help and back buttons
		Side.r = LeaPlusLC:CreateButton("ResetButton", Side, "Reset", "BOTTOMLEFT", 16, 53, 0, 25, true, "Click to reset the settings on this page.")
		Side.h = LeaPlusLC:CreateButton("HelpButton", Side, "Help", "BOTTOMLEFT", 76, 53, 0, 25, true, "No help is available for this page.")
		Side.b = LeaPlusLC:CreateButton("BackButton", Side, "Back to Main Menu", "BOTTOMRIGHT", -16, 53, 0, 25, true, "Click to return to the main menu.")

		-- Reposition help button so it doesn't overlap reset button
		Side.h:ClearAllPoints()
		Side.h:SetPoint("LEFT", Side.r, "RIGHT", 10, 0)

		-- Remove the click texture from the help button
		Side.h:SetPushedTextOffset(0, 0)

		-- Add a reload button and syncronise it with the main panel reload button
		local reloadb = LeaPlusLC:CreateButton("ConfigReload", Side, "Reload", "BOTTOMRIGHT", -16, 10, 0, 25, true, LeaPlusCB["ReloadUIButton"].tiptext)
		LeaPlusLC:LockItem(reloadb,true)
		reloadb:SetScript("OnClick", ReloadUI)

		reloadb.f = reloadb:CreateFontString(nil, 'ARTWORK', 'GameFontNormalSmall')
		reloadb.f:SetHeight(32);
		reloadb.f:SetPoint('RIGHT', reloadb, 'LEFT', -10, 0)
		reloadb.f:SetText(LeaPlusCB["ReloadUIButton"].f:GetText())
		reloadb.f:Hide()

		LeaPlusCB["ReloadUIButton"]:HookScript("OnEnable", function()
			LeaPlusLC:LockItem(reloadb, false)
			reloadb.f:Show()
		end)

		LeaPlusCB["ReloadUIButton"]:HookScript("OnDisable", function()
			LeaPlusLC:LockItem(reloadb, true)
			reloadb.f:Hide()
		end)

		-- Set textures
		LeaPlusLC:CreateBar("FootTexture", Side, 570, 48, "BOTTOM", 0.5, 0.5, 0.5, 1.0, "Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated.png")
		LeaPlusLC:CreateBar("MainTexture", Side, 570, LeaPlusLC.MainPanelHeight - 47, "TOPRIGHT", 0.7, 0.7, 0.7, 0.7,  "Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated.png")

		-- Allow movement
		Side:EnableMouse(true)
		Side:SetMovable(true)
		Side:RegisterForDrag("LeftButton")
		Side:SetScript("OnDragStart", Side.StartMoving)
		Side:SetScript("OnDragStop", function ()
			Side:StopMovingOrSizing();
			Side:SetUserPlaced(false);
			-- Save panel position
			LeaPlusLC["MainPanelA"], void, LeaPlusLC["MainPanelR"], LeaPlusLC["MainPanelX"], LeaPlusLC["MainPanelY"] = Side:GetPoint()
		end)

		-- Set panel attributes when shown
		Side:SetScript("OnShow", function()
			Side:ClearAllPoints()
			Side:SetPoint(LeaPlusLC["MainPanelA"], UIParent, LeaPlusLC["MainPanelR"], LeaPlusLC["MainPanelX"], LeaPlusLC["MainPanelY"])
			Side:SetScale(LeaPlusLC["PlusPanelScale"])
			Side.t:SetAlpha(1 - LeaPlusLC["PlusPanelAlpha"])
		end)

		-- Add title
		Side.f = Side:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
		Side.f:SetPoint('TOPLEFT', 16, -16);
		Side.f:SetText(L[title])

		-- Add description
		Side.v = Side:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
		Side.v:SetHeight(32);
		Side.v:SetPoint('TOPLEFT', Side.f, 'BOTTOMLEFT', 0, -8);
		Side.v:SetPoint('RIGHT', Side, -32, 0)
		Side.v:SetJustifyH('LEFT'); Side.v:SetJustifyV('TOP');
		Side.v:SetText(L["Configuration Panel"])

		-- Prevent options panel from showing while side panel is showing
		LeaPlusLC["PageF"]:HookScript("OnShow", function()
			if Side:IsShown() then LeaPlusLC["PageF"]:Hide(); end
		end)

		-- Create scroll frame if needed
		if scrolling then

			-- Create backdrop
			Side.backFrame = CreateFrame("FRAME", nil, Side, "BackdropTemplate")
			Side.backFrame:SetSize(Side:GetSize())
			Side.backFrame:SetPoint("TOPLEFT", 16, -68)
			Side.backFrame:SetPoint("BOTTOMRIGHT", -16, 98)
			Side.backFrame:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"})
			Side.backFrame:SetBackdropColor(0, 0, 1, 0.5)

			-- Create scroll frame
			Side.scrollFrame = CreateFrame("ScrollFrame", nil, Side.backFrame, "LeaPlusConfigurationPanelScrollFrameTemplate")
			Side.scrollChild = CreateFrame("Frame", nil, Side.scrollFrame)

			Side.scrollChild:SetSize(1, 1)
			Side.scrollFrame:SetScrollChild(Side.scrollChild)
			Side.scrollFrame:SetPoint("TOPLEFT", -8, -6)
			Side.scrollFrame:SetPoint("BOTTOMRIGHT", -29, 6)
			Side.scrollFrame:SetPanExtent(20)

			-- Set scroll list to top when shown
			Side.scrollFrame:HookScript("OnShow", function()
				Side.scrollFrame:SetVerticalScroll(0)
			end)

			-- Add scroll for more message
			local footMessage = LeaPlusLC:MakeTx(Side, "(scroll the list for more)", 16, 0)
			footMessage:ClearAllPoints()
			footMessage:SetPoint("TOPRIGHT", Side.scrollFrame, "TOPRIGHT", 28, 24)

			-- Give child a file level scope (it's used in LeaPlusLC.TipSee)
			LeaPlusLC[globref .. "ScrollChild"] = Side.scrollChild

		end

		-- Return the frame
		return Side

	end

	-- Define subheadings
	function LeaPlusLC:MakeTx(frame, title, x, y)
		local text = frame:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		text:SetPoint("TOPLEFT", x, y)
		text:SetText(L[title])
		return text
	end

	-- Define text
	function LeaPlusLC:MakeWD(frame, title, x, y)
		local text = frame:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
		text:SetPoint("TOPLEFT", x, y)
		text:SetText(L[title])
		text:SetJustifyH"LEFT";
		return text
	end

	-- Create a slider control (uses standard template)
	function LeaPlusLC:MakeSL(frame, field, caption, low, high, step, x, y, form)

		-- Create slider control
		local Slider = CreateFrame("Slider", nil, frame, "LeaPlusConfigurationPanelSliderTemplate") -- Old is UISliderTemplate
		LeaPlusCB[field] = Slider
		Slider:SetMinMaxValues(low, high)
		Slider:SetValueStep(step)
		Slider:EnableMouseWheel(true)
		Slider:SetPoint('TOPLEFT', x,y)
		Slider:SetWidth(100)
		Slider:SetHeight(20)
		Slider:SetHitRectInsets(0, 0, 0, 0)
		Slider.tiptext = L[caption]
		Slider:SetScript("OnEnter", LeaPlusLC.TipSee)
		Slider:SetScript("OnLeave", GameTooltip_Hide)

		-- Create slider label
		Slider.f = Slider:CreateFontString(nil, 'BACKGROUND')
		Slider.f:SetFontObject('GameFontHighlight')
		Slider.f:SetPoint('LEFT', Slider, 'RIGHT', 12, 0)
		Slider.f:SetFormattedText("%.2f", Slider:GetValue())

		-- Process mousewheel scrolling
		Slider:SetScript("OnMouseWheel", function(self, arg1)
			if Slider:IsEnabled() then
				local step = step * arg1
				local value = self:GetValue()
				if step > 0 then
					self:SetValue(min(value + step, high))
				else
					self:SetValue(max(value + step, low))
				end
			end
		end)

		-- Process value changed
		Slider:SetScript("OnValueChanged", function(self, value)
			local value = floor((value - low) / step + 0.5) * step + low
			Slider.f:SetFormattedText(form, value)
			LeaPlusLC[field] = value
		end)

		-- Set slider value when shown
		Slider:SetScript("OnShow", function(self)
			self:SetValue(LeaPlusLC[field])
		end)

	end

	-- Create a checkbox control (uses standard template)
	function LeaPlusLC:MakeCB(parent, field, caption, x, y, reload, tip, tipstyle)

		-- Create the checkbox
		local Cbox = CreateFrame('CheckButton', nil, parent, "ChatConfigCheckButtonTemplate")
		LeaPlusCB[field] = Cbox
		Cbox:SetPoint("TOPLEFT",x, y)
		Cbox:SetScript("OnEnter", LeaPlusLC.TipSee)
		Cbox:SetScript("OnLeave", GameTooltip_Hide)

		-- Add label and tooltip
		Cbox.f = Cbox:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
		Cbox.f:SetPoint('LEFT', 20, 0)
		if reload then
			-- Checkbox requires UI reload
			Cbox.f:SetText(L[caption] .. "*")
			Cbox.tiptext = L[tip] .. "|n|n* " .. L["Requires UI reload."]
		else
			-- Checkbox does not require UI reload
			Cbox.f:SetText(L[caption])
			Cbox.tiptext = L[tip]
		end

		-- Set label parameters
		Cbox.f:SetJustifyH("LEFT")
		Cbox.f:SetWordWrap(false)

		-- Set maximum label width
		if parent:GetParent() == LeaPlusLC["PageF"] then
			-- Main panel checkbox labels
			if Cbox.f:GetWidth() > 152 then
				Cbox.f:SetWidth(152)
				LeaPlusLC["TruncatedLabelsList"] = LeaPlusLC["TruncatedLabelsList"] or {}
				LeaPlusLC["TruncatedLabelsList"][Cbox.f] = L[caption]
			end
			-- Set checkbox click width
			if Cbox.f:GetStringWidth() > 152 then
				Cbox:SetHitRectInsets(0, -142, 0, 0)
			else
				Cbox:SetHitRectInsets(0, -Cbox.f:GetStringWidth() + 4, 0, 0)
			end
		else
			-- Configuration panel checkbox labels (other checkboxes either have custom functions or blank labels)
			if Cbox.f:GetWidth() > 302 then
				Cbox.f:SetWidth(302)
				LeaPlusLC["TruncatedLabelsList"] = LeaPlusLC["TruncatedLabelsList"] or {}
				LeaPlusLC["TruncatedLabelsList"][Cbox.f] = L[caption]
			end
			-- Set checkbox click width
			if Cbox.f:GetStringWidth() > 302 then
				Cbox:SetHitRectInsets(0, -292, 0, 0)
			else
				Cbox:SetHitRectInsets(0, -Cbox.f:GetStringWidth() + 4, 0, 0)
			end
		end

		-- Set default checkbox state and click area
		Cbox:SetScript('OnShow', function(self)
			if LeaPlusLC[field] == "On" then
				self:SetChecked(true)
			else
				self:SetChecked(false)
			end
		end)

		-- Process clicks
		Cbox:SetScript('OnClick', function()
			if Cbox:GetChecked() then
				LeaPlusLC[field] = "On"
			else
				LeaPlusLC[field] = "Off"
			end
			LeaPlusLC:SetDim(); -- Lock invalid options
			LeaPlusLC:ReloadCheck(); -- Show reload button if needed
		end)
	end

	-- Create an editbox (uses standard template)
	function LeaPlusLC:CreateEditBox(frame, parent, width, maxchars, anchor, x, y, tab, shifttab)

		-- Create editbox
        local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
		LeaPlusCB[frame] = eb
		eb:SetPoint(anchor, x, y)
		eb:SetWidth(width)
		eb:SetHeight(24)
		eb:SetFontObject("GameFontNormal")
		eb:SetTextColor(1.0, 1.0, 1.0)
		eb:SetAutoFocus(false)
		eb:SetMaxLetters(maxchars)
		eb:SetScript("OnEscapePressed", eb.ClearFocus)
		eb:SetScript("OnEnterPressed", eb.ClearFocus)

		-- Add editbox border and backdrop
		eb.f = CreateFrame("FRAME", nil, eb, "BackdropTemplate")
		eb.f:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 }})
		eb.f:SetPoint("LEFT", -6, 0)
		eb.f:SetWidth(eb:GetWidth()+6)
		eb.f:SetHeight(eb:GetHeight())
		eb.f:SetBackdropColor(1.0, 1.0, 1.0, 0.3)

		-- Move onto next editbox when tab key is pressed
		eb:SetScript("OnTabPressed", function(self)
			self:ClearFocus()
			if IsShiftKeyDown() then
				LeaPlusCB[shifttab]:SetFocus()
			else
				LeaPlusCB[tab]:SetFocus()
			end
		end)

		return eb

	end

	-- Create a standard button (using standard button template)
	function LeaPlusLC:CreateButton(name, frame, label, anchor, x, y, width, height, reskin, tip, naked)
		local mbtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		LeaPlusCB[name] = mbtn
		mbtn:SetSize(width, height)
		mbtn:SetPoint(anchor, x, y)
		mbtn:SetHitRectInsets(0, 0, 0, 0)
		mbtn:SetText(L[label])

		-- Create fontstring so the button can be sized correctly
		mbtn.f = mbtn:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		mbtn.f:SetText(L[label])
		if width > 0 then
			-- Button should have static width
			mbtn:SetWidth(width)
		else
			-- Button should have variable width
			mbtn:SetWidth(mbtn.f:GetStringWidth() + 20)
		end

		-- Tooltip handler
		mbtn.tiptext = L[tip]
		mbtn:SetScript("OnEnter", LeaPlusLC.TipSee)
		mbtn:SetScript("OnLeave", GameTooltip_Hide)

		-- Texture the button
		if reskin then

			-- Set skinned button textures
			if not naked then
				mbtn:SetNormalTexture("Interface\\AddOns\\Leatrix_Plus\\Leatrix_Plus.blp")
				mbtn:GetNormalTexture():SetTexCoord(0.5, 1, 0, 0.125)
			end
			mbtn:SetHighlightTexture("Interface\\AddOns\\Leatrix_Plus\\Leatrix_Plus.blp")
			mbtn:GetHighlightTexture():SetTexCoord(0, 0.5, 0, 0.125)

			-- Hide the default textures
			mbtn:HookScript("OnShow", function() mbtn.Left:Hide(); mbtn.Middle:Hide(); mbtn.Right:Hide() end)
			mbtn:HookScript("OnEnable", function() mbtn.Left:Hide(); mbtn.Middle:Hide(); mbtn.Right:Hide() end)
			mbtn:HookScript("OnDisable", function() mbtn.Left:Hide(); mbtn.Middle:Hide(); mbtn.Right:Hide() end)
			mbtn:HookScript("OnMouseDown", function() mbtn.Left:Hide(); mbtn.Middle:Hide(); mbtn.Right:Hide() end)
			mbtn:HookScript("OnMouseUp", function() mbtn.Left:Hide(); mbtn.Middle:Hide(); mbtn.Right:Hide() end)

		end

		return mbtn
	end

	----------------------------------------------------------------------
	-- Pop-up lists
	----------------------------------------------------------------------

	-- The game's menus keep their state on the menu frame and the world map reads the frame under the pointer every
	-- frame, so menu entries made by an addon spread taint into the map's own code while the map is open. Dropdown
	-- menus use these pop-up lists instead. They are frames of our own, so the map never reads anything the addon wrote.

	function LeaPlusLC:CreatePopupList(parent)

		local rowHeight, rowsPerColumn, columnWidth = 20, 25, 180
		local rows = {}
		local owner, entries, isChecked, onClick, onWheel

		local list = CreateFrame("Frame", nil, parent, "BackdropTemplate")
		list:SetFrameStrata("FULLSCREEN_DIALOG")
		list:SetClampedToScreen(true)
		list:EnableMouse(true)
		list:EnableMouseWheel(true)
		list:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
		list:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
		list:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
		list:Hide()

		-- Mousewheel runs the wheel function if there is one (and stops anything under the list from scrolling)
		list:SetScript("OnMouseWheel", function(self, delta)
			if onWheel then onWheel(delta) end
		end)

		-- Close the list when clicking anywhere else (only watched while the list is showing)
		list:SetScript("OnShow", function(self) self:RegisterEvent("GLOBAL_MOUSE_DOWN") end)
		list:SetScript("OnHide", function(self) self:UnregisterEvent("GLOBAL_MOUSE_DOWN") end)
		list:SetScript("OnEvent", function(self)
			if not self:IsMouseOver() and not (owner and owner:IsMouseOver()) then
				self:Hide()
			end
		end)

		-- Function to show a row as checked or not
		local function SetRowCheck(row)
			if isChecked(row.entry) then
				row.Check:Show()
				row.Text:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
			else
				row.Check:Hide()
				row.Text:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
			end
		end

		-- Function to get a row (rows are created when first needed and reused)
		local function GetRow(index)
			local row = rows[index]
			if not row then
				row = CreateFrame("Button", nil, list)
				row:SetSize(columnWidth, rowHeight)
				row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
				row.Check = row:CreateTexture(nil, "ARTWORK")
				row.Check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
				row.Check:SetSize(16, 16)
				row.Check:SetPoint("LEFT", 4, 0)
				row.Text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
				row.Text:SetPoint("LEFT", 22, 0)
				row.Text:SetPoint("RIGHT", -4, 0)
				row.Text:SetJustifyH("LEFT")
				row.Text:SetWordWrap(false)
				row:SetScript("OnClick", function(self)
					-- The click function returns true to keep the list open (such as for checkboxes)
					if onClick(self.entry) then
						for i = 1, #entries do SetRowCheck(rows[i]) end
					else
						list:Hide()
					end
				end)
				rows[index] = row
			end
			return row
		end

		local popup = {}

		-- Close the list
		function popup:Close()
			list:Hide()
		end

		-- Update the checks in the open list
		function popup:Refresh()
			if not list:IsShown() then return end
			for i = 1, #entries do SetRowCheck(rows[i]) end
		end

		-- Show the list next to a button (long lists are split into columns)
		function popup:Open(button, items, checkedFunc, clickFunc, point, relativePoint, x, y, wheelFunc)
			local count = #items
			if count == 0 then return end
			owner, entries, isChecked, onClick, onWheel = button, items, checkedFunc, clickFunc, wheelFunc
			local columns = math.ceil(count / rowsPerColumn)
			local perColumn = math.ceil(count / columns)
			for i = 1, count do
				local row = GetRow(i)
				row.entry = items[i]
				row.Text:SetText(items[i].name)
				SetRowCheck(row)
				row:ClearAllPoints()
				row:SetPoint("TOPLEFT", list, "TOPLEFT", 8 + math.floor((i - 1) / perColumn) * columnWidth, -8 - ((i - 1) % perColumn) * rowHeight)
				row:Show()
			end
			for i = count + 1, #rows do
				rows[i]:Hide()
				rows[i].entry = nil
			end
			list:SetSize(columns * columnWidth + 16, perColumn * rowHeight + 16)
			list:ClearAllPoints()
			list:SetPoint(point, button, relativePoint, x, y)
			list:SetFrameLevel(button:GetFrameLevel() + 20)
			list:Show()
		end

		-- Open the list for a button or close it if it's already open for that button
		function popup:Toggle(button, ...)
			if list:IsShown() and owner == button then
				list:Hide()
			else
				self:Open(button, ...)
			end
		end

		return popup

	end

	-- Create a dropdown menu (the standard dropdown button but it opens a pop-up list instead of the game's menu, see
	-- LeaPlusLC:CreatePopupList for why)
	function LeaPlusLC:CreateDropdown(frame, label, width, anchor, parent, relative, x, y, reload, items)

		local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
		LeaPlusCB[frame] = dropdown
		dropdown:SetPoint(anchor, parent, relative, x, y)
		dropdown:SetWidth(width)

		local lf = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal"); lf:SetPoint("TOPLEFT", dropdown, 0, 20); lf:SetPoint("TOPRIGHT", dropdown, -5, 20); lf:SetJustifyH("LEFT"); lf:SetText(L[label])

		-- List entries
		local entries = {}
		for i = 1, #items do
			entries[i] = {name = items[i][1], value = items[i][2]}
		end

		-- Function to show the current option on the button
		local function UpdateText()
			for i = 1, #entries do
				if entries[i].value == LeaPlusLC[frame] then
					dropdown:OverrideText(entries[i].name)
					return
				end
			end
			dropdown:OverrideText("")
		end

		-- Function to apply an option (runs anything hooked to the menu closing, so options apply in the same way as before)
		local function SetValue(value)
			LeaPlusLC[frame] = value
			UpdateText()
			dropdown:TriggerEvent(DropdownButtonMixin.Event.OnMenuClose, dropdown)
			if reload then
				LeaPlusLC:ReloadCheck()
			end
		end

		local popup = LeaPlusLC:CreatePopupList(parent)

		local function IsCurrent(entry)
			return entry.value == LeaPlusLC[frame]
		end

		local function Choose(entry)
			SetValue(entry.value)
		end

		-- Function to step to the next or previous option (scroll down for the next option, up for the previous one, stops at either end)
		local function Step(delta)
			local index = 1
			for i = 1, #entries do
				if entries[i].value == LeaPlusLC[frame] then index = i; break end
			end
			index = index + (delta < 0 and 1 or -1)
			if index < 1 or index > #entries then return end
			SetValue(entries[index].value)
			popup:Refresh()
		end

		-- Open or close the list when the button is clicked
		dropdown:HookScript("OnMouseDown", function(self, button)
			if button ~= "LeftButton" or not self:IsEnabled() then return end
			popup:Toggle(self, entries, IsCurrent, Choose, "TOPLEFT", "BOTTOMLEFT", 0, -2, Step)
		end)

		-- Cycle through the options with the mousewheel over the button (the open list does the same)
		dropdown:EnableMouseWheel(true)
		dropdown:HookScript("OnMouseWheel", function(self, delta)
			if self:IsEnabled() then Step(delta) end
		end)

		-- Close the list if the button is disabled
		dropdown:HookScript("OnDisable", function() popup:Close() end)

		-- Show the current option when the button is shown
		dropdown:HookScript("OnShow", UpdateText)
		UpdateText()

	end

----------------------------------------------------------------------
-- 	Create main options panel frame
----------------------------------------------------------------------

	function LeaPlusLC:CreateMainPanel()

		-- Create the panel
		local PageF = CreateFrame("Frame", LeaPlusLC:CreateRandomName(), UIParent);

		-- Make it a system frame
		table.insert(UISpecialFrames, PageF:GetName())

		-- Set frame parameters
		LeaPlusLC["PageF"] = PageF
		PageF:SetSize(570, LeaPlusLC.MainPanelHeight)
		PageF:Hide();
		PageF:SetFrameStrata("FULLSCREEN_DIALOG")
		PageF:SetClampedToScreen(true)
		PageF:SetClampRectInsets(500, -500, -300, 300)
		PageF:EnableMouse(true)
		PageF:SetMovable(true)
		PageF:RegisterForDrag("LeftButton")
		PageF:SetScript("OnDragStart", PageF.StartMoving)
		PageF:SetScript("OnDragStop", function ()
			PageF:StopMovingOrSizing();
			PageF:SetUserPlaced(false);
			-- Save panel position
			LeaPlusLC["MainPanelA"], void, LeaPlusLC["MainPanelR"], LeaPlusLC["MainPanelX"], LeaPlusLC["MainPanelY"] = PageF:GetPoint()
		end)

		-- Add background color
		PageF.t = PageF:CreateTexture(nil, "BACKGROUND")
		PageF.t:SetAllPoints()
		PageF.t:SetColorTexture(0.05, 0.05, 0.05, 0.9)

		-- Add textures
		LeaPlusLC:CreateBar("FootTexture", PageF, 570, 48, "BOTTOM", 0.5, 0.5, 0.5, 1.0, "Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated.png")
		LeaPlusLC:CreateBar("MainTexture", PageF, 440, LeaPlusLC.MainPanelHeight - 47, "TOPRIGHT", 0.7, 0.7, 0.7, 0.7,  "Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated.png")
		LeaPlusLC:CreateBar("MenuTexture", PageF, 130, LeaPlusLC.MainPanelHeight - 47, "TOPLEFT", 0.7, 0.7, 0.7, 0.7, "Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated.png")

		-- Set panel position when shown
		PageF:SetScript("OnShow", function()
			PageF:ClearAllPoints()
			PageF:SetPoint(LeaPlusLC["MainPanelA"], UIParent, LeaPlusLC["MainPanelR"], LeaPlusLC["MainPanelX"], LeaPlusLC["MainPanelY"])
		end)

		-- Add main title (shown above menu in the corner)
		PageF.mt = PageF:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
		PageF.mt:SetPoint('TOPLEFT', 16, -16)
		PageF.mt:SetText("Leatrix Plus")

		-- Add version text (shown underneath main title)
		PageF.v = PageF:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
		PageF.v:SetHeight(32);
		PageF.v:SetPoint('TOPLEFT', PageF.mt, 'BOTTOMLEFT', 0, -8);
		PageF.v:SetPoint('RIGHT', PageF, -32, 0)
		PageF.v:SetJustifyH('LEFT'); PageF.v:SetJustifyV('TOP');
		PageF.v:SetNonSpaceWrap(true); PageF.v:SetText(L["FE"] .. " " .. LeaPlusLC["AddonVer"])

		-- Add reload UI Button
		local reloadb = LeaPlusLC:CreateButton("ReloadUIButton", PageF, "Reload", "BOTTOMRIGHT", -16, 10, 0, 25, true, "Your UI needs to be reloaded for some of the changes to take effect.|n|nYou don't have to click the reload button immediately but you do need to click it when you are done making changes and you want the changes to take effect.")
		LeaPlusLC:LockItem(reloadb,true)
		reloadb:SetScript("OnClick", ReloadUI)

		reloadb.f = reloadb:CreateFontString(nil, 'ARTWORK', 'GameFontNormalSmall')
		reloadb.f:SetHeight(32);
		reloadb.f:SetPoint('RIGHT', reloadb, 'LEFT', -10, 0)
		reloadb.f:SetText(L["Your UI needs to be reloaded."])
		reloadb.f:Hide()

		-- Add close Button (LeaPlusLC.DF: Using custom template)
		local CloseB = LeaPlusLC:CreateCloseButton(PageF, 30, 30, "TOPRIGHT", 0, 0)
		CloseB:SetScript("OnClick", LeaPlusLC.HideFrames)

		-- Release memory
		LeaPlusLC.CreateMainPanel = nil

	end

	LeaPlusLC:CreateMainPanel();

----------------------------------------------------------------------
-- 	L80: Commands
----------------------------------------------------------------------

	-- Slash command function
	function LeaPlusLC:SlashFunc(str)
		if str and str ~= "" then
			-- Get parameters in lower case with duplicate spaces removed
			local str, arg1, arg2, arg3 = strsplit(" ", string.lower(str:gsub("%s+", " ")))
			-- Traverse parameters
			if str == "wipe" then
				-- Wipe settings
				LeaPlusLC:PlayerLogout(true) -- Run logout function with wipe parameter
				wipe(LeaPlusDB)
				LpEvt:UnregisterAllEvents(); -- Don't save any settings
				ReloadUI();
			elseif str == "nosave" then
				-- Prevent Leatrix Plus from overwriting LeaPlusDB at next logout
				LpEvt:UnregisterEvent("PLAYER_LOGOUT")
				LeaPlusLC:Print("Leatrix Plus will not overwrite LeaPlusDB at next logout.")
				return
			elseif str == "reset" then
				-- Reset panel positions
				LeaPlusLC["MainPanelA"], LeaPlusLC["MainPanelR"], LeaPlusLC["MainPanelX"], LeaPlusLC["MainPanelY"] = "CENTER", "CENTER", 0, 0
				LeaPlusLC["PlusPanelScale"] = 1
				LeaPlusLC["PlusPanelAlpha"] = 0
				LeaPlusLC["PageF"]:SetScale(1)
				LeaPlusLC["PageF"].t:SetAlpha(1 - LeaPlusLC["PlusPanelAlpha"])
				-- Refresh panels
				LeaPlusLC["PageF"]:ClearAllPoints()
				LeaPlusLC["PageF"]:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
				-- Reset currently showing configuration panel
				for k, v in pairs(LeaConfigList) do
					if v:IsShown() then
						v:ClearAllPoints()
						v:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
						v:SetScale(1)
						v.t:SetAlpha(1 - LeaPlusLC["PlusPanelAlpha"])
					end
				end
				-- Refresh Leatrix Plus settings menu only
				if LeaPlusLC["Page8"]:IsShown() then
					LeaPlusLC["Page8"]:Hide()
					LeaPlusLC["Page8"]:Show()
				end
			elseif str == "hk" then
				-- Print lifetime honorable kills
				local chagmsg = L["Lifetime honorable kills"]
				local ltphk = GetStatistic(588)
				if ltphk == "--" then ltphk = "0" end
				chagmsg = chagmsg .. ": |cffffffff" .. ltphk
				LeaPlusLC:Print(chagmsg)
				return
			elseif str == "taint" then
				-- Set taint log level
				if arg1 and arg1 ~= "" then
					arg1 = tonumber(arg1)
					if arg1 and arg1 >= 0 and arg1 <= 2 then
						if arg1 == 0 then
							-- Disable taint log
							ConsoleExec("taintLog 0")
							LeaPlusLC:Print("Taint level: Disabled (0).")
						elseif arg1 == 1 then
							-- Basic taint log
							ConsoleExec("taintLog 1")
							LeaPlusLC:Print("Taint level: Basic (1).")
						elseif arg1 == 2 then
							-- Full taint log
							ConsoleExec("taintLog 2")
							LeaPlusLC:Print("Taint level: Full (2).")
						end
					else
						LeaPlusLC:Print("Invalid taint level.")
					end
				else
					-- Show current taint level
					local taintCurrent = GetCVar("taintLog")
					if taintCurrent == "0" then
						LeaPlusLC:Print("Taint level: Disabled (0).")
					elseif taintCurrent == "1" then
						LeaPlusLC:Print("Taint level: Basic (1).")
					elseif taintCurrent == "2" then
						LeaPlusLC:Print("Taint level: Full (2).")
					end
				end
				return
			elseif str == "quest" then
				-- Show quest completed status
				if arg1 and arg1 ~= "" then
					if arg1 == "wipe" then
						-- Wipe quest log
						for i = 1, C_QuestLog.GetNumQuestLogEntries() do
							C_QuestLog.SetSelectedQuest(C_QuestLog.GetInfo(i).questID)
							C_QuestLog.SetAbandonQuest()
							C_QuestLog.AbandonQuest()
						end
						LeaPlusLC:Print(L["Quest log wiped."])
						return
					elseif arg1 == "clone" and GetNumSubgroupMembers(1) > 0 then
						-- Share all quests
						local i = 0
						C_Timer.NewTicker(0.3, function()
							i = i + 1
							local selectedQuest = C_QuestLog.GetInfo(i)
							if selectedQuest then
								C_QuestLog.SetSelectedQuest(selectedQuest.questID)
								local title = C_QuestLog.GetTitleForQuestID(selectedQuest.questID)
								if title then
									print(title)
									if C_QuestLog.IsPushableQuest(selectedQuest.questID) then
										QuestLogPushQuest(i)
									else
										LeaPlusLC:Print(L["Not applicable."])
									end
								end
							end
						end, C_QuestLog.GetNumQuestLogEntries())
						return
					elseif tonumber(arg1) and tonumber(arg1) < 999999999 then
						-- Show quest information
						LeaPlusLC.LoadQuestEventFrame = LeaPlusLC.LoadQuestEventFrame or CreateFrame("FRAME")
						LeaPlusLC.LoadQuestEventFrame:SetScript("OnEvent", function(self, event, questID, success)
							if tonumber(questID) == tonumber(arg1) then
								LeaPlusLC.LoadQuestEventFrame:UnregisterEvent("QUEST_DATA_LOAD_RESULT")
								local tempGetQuestInfo = C_QuestLog.GetTitleForQuestID
								local questCompleted = C_QuestLog.IsQuestFlaggedCompleted(arg1)
								local questTitle = C_TaskQuest.GetQuestInfoByQuestID(arg1) or tempGetQuestInfo(arg1)
								if questTitle then
									if success then
										if questCompleted then
											LeaPlusLC:Print(questTitle .. " (" .. arg1 .. "):" .. "|cffffffff " .. L["Completed."])
										else
											LeaPlusLC:Print(questTitle .. " (" .. arg1 .. "):" .. "|cffffffff " .. L["Not completed."])
										end
									else
										LeaPlusLC:Print(questTitle .. " (" .. arg1 .. "):" .. "|cffffffff " .. L["Error retrieving quest."])
									end
								else
									LeaPlusLC:Print("Invalid quest ID.")
									return
								end
							end
						end)
						LeaPlusLC.LoadQuestEventFrame:RegisterEvent("QUEST_DATA_LOAD_RESULT")
						C_QuestLog.RequestLoadQuestByID(arg1)
					else
						LeaPlusLC:Print("Invalid quest ID.")
					end
				else
					LeaPlusLC:Print("Missing quest ID.")
				end
				return
			elseif str == "gstaff" then
				-- Buy 10 x Rough Wooden Staff from Larana Drome in Scribes' Sacellum, Dalaran, Northrend (used for testing)
				local npcName = UnitName("target")
				local npcGuid = UnitGUID("target") or nil
				local errmsg = "Requires you to be interacting with Larana Drome.  She can be found at Scribes' Sacellum, Dalaran, Northrend."
				if npcName and npcGuid then
					local void, void, void, void, void, npcID = strsplit("-", npcGuid)
					if npcID and npcID == "28723" then
						local id, ida, idb = 0, GetMerchantItemID(5), GetMerchantItemID(6)
						if ida == 1515 then id = 5 elseif idb == 1515 then id = 6 end
						if id > 0 then
							for k = 1, 10 do
								BuyMerchantItem(id)
							end
						end
					else
						LeaPlusLC:Print(errmsg)
					end
				else
					LeaPlusLC:Print(errmsg)
				end
				return
			elseif str == "rest" then
				-- Show rested bubbles
				LeaPlusLC:Print(L["Rested bubbles"] .. ": |cffffffff" .. (math.floor(20 * (GetXPExhaustion() or 0) / UnitXPMax("player") + 0.5)))
				return
			elseif str == "zygor" then
				-- Toggle Zygor addon
				LeaPlusLC:ZygorToggle()
				return
			elseif str == "mountid" then
				-- Get mount ID by mount name
				if not arg1 or arg1 == "" then LeaPlusLC:Print("Missing mount name.") return end
				local mounts = C_MountJournal.GetMountIDs()
				local mountSuccess = false
				for i = 1, #mounts do
					local creatureName, spellID, icon, active, isUsable, sourceType = C_MountJournal.GetMountInfoByID(mounts[i])
					if strfind(strlower(creatureName), strlower(arg1)) then
						LeaPlusLC:Print(creatureName .. ": |cffffffff" .. mounts[i] .. "|r")
						mountSuccess = true
					end
				end
				if not mountSuccess then LeaPlusLC:Print("Mount not found.") end
				return
			elseif str == "tooltip" then
				-- Print tooltip frame name
				pcall(function()
					local enumf = EnumerateFrames()
					while enumf do
						if (enumf:GetObjectType() == "GameTooltip" or strfind((enumf:GetName() or ""):lower(),"tip")) and enumf:IsVisible() and enumf:GetPoint() then
							print(enumf:GetName())
						end
						enumf = EnumerateFrames(enumf)
					end
					collectgarbage()
					return
				end)
			elseif str == "soil" then
				-- Enable dark soil and jelly deposit scanning
				if not LeaPlusLC["DarkScriptlEnabled"] then
					GameTooltip:HookScript("OnUpdate", function()
						local a = _G["GameTooltipTextLeft1"]:GetText() or ""
						if a == "Dark Soil" or a == "Jelly Deposit" or a == "Gersahl Shrub" then
							C_Sound.PlaySound(8959, "Master")
						end
					end)
					-- Add Friendly Alpaca spawn locations to Uldum map
					if TomTom then
						for void, v in next, ({{15,62},{24,9},{28,49},{30,29},{39,10},{42,70},{46,48},{53,19},{55,69},{63,53},{63,14},{70,39},{76,68}}) do
							TomTom:AddWaypoint(1527, v[1]/100, v[2]/100, {title = "Friendly Alpaca"})
						end
					end
					LeaPlusLC["DarkScriptlEnabled"] = true
					LeaPlusLC:Print("Dark Soil scanning activated.  Reload UI to exit.")
				else
					LeaPlusLC:Print("Dark Soil scanning is already activated.  You only need to run this once.  Reload UI to exit.")
				end
				return
			elseif str == "rsnd" then
				-- Restart sound system
				if LeaPlusCB["StopMusicBtn"] then LeaPlusCB["StopMusicBtn"]:Click() end
				Sound_GameSystem_RestartSoundSystem()
				LeaPlusLC:Print("Sound system restarted.")
				return
			elseif str == "event" then
				-- List events (used for debug)
				LeaPlusLC["DbF"] = LeaPlusLC["DbF"] or CreateFrame("FRAME")
				if not LeaPlusLC["DbF"]:GetScript("OnEvent") then
					LeaPlusLC:Print("Tracing started.")
					LeaPlusLC["DbF"]:RegisterAllEvents()
					LeaPlusLC["DbF"]:SetScript("OnEvent", function(self, event)
						if event == "ACTIONBAR_UPDATE_COOLDOWN"
						or event == "BAG_UPDATE_COOLDOWN"
						or event == "CHAT_MSG_TRADESKILLS"
						or event == "COMBAT_LOG_EVENT_UNFILTERED"
						or event == "CURSOR_CHANGED"
						or event == "ITEM_DATA_LOAD_RESULT"
						or event == "SPELL_UPDATE_COOLDOWN"
						or event == "SPELL_UPDATE_USABLE"
						or event == "UNIT_POWER_FREQUENT"
						or event == "UPDATE_INVENTORY_DURABILITY"
						or event == "UPDATE_SHAPESHIFT_COOLDOWN"
						or event == "UPDATE_UI_WIDGET"
						or event == "WORLD_CURSOR_TOOLTIP_UPDATE"
						then return
						else
							print(event)
						end
					end)
				else
					LeaPlusLC["DbF"]:UnregisterAllEvents()
					LeaPlusLC["DbF"]:SetScript("OnEvent", nil)
					LeaPlusLC:Print("Tracing stopped.")
				end
				return
			elseif str == "game" then
				-- Show game build
				local version, build, gdate, tocversion = GetBuildInfo()
				LeaPlusLC:Print(L["World of Warcraft"] .. ": |cffffffff" .. version .. "." .. build .. " (" .. gdate .. ") (" .. tocversion .. ")")
				return
			elseif str == "config" then
				-- Show maximum camera distance
				LeaPlusLC:Print(L["Camera distance"] .. ": |cffffffff" .. GetCVar("cameraDistanceMaxZoomFactor"))
				-- Show screen effects
				LeaPlusLC:Print(L["Shaders"] .. ": |cffffffff" .. GetCVar("ffxGlow") .. ", " .. GetCVar("ffxDeath") .. ", " .. GetCVar("ffxNether"))
				-- Show particle density
				LeaPlusLC:Print(L["Particle density"] .. ": |cffffffff" .. GetCVar("particleDensity"))
				LeaPlusLC:Print(L["Weather density"] .. ": |cffffffff" .. GetCVar("weatherDensity"))
				LeaPlusLC:Print(L["Field of view"] .. ": |cffffffff" .. GetCVar("camerafov"))
				-- Show config
				LeaPlusLC:Print("SynchroniseConfig: |cffffffff" .. GetCVar("synchronizeConfig"))
				-- Show raid restrictions
				local unRaid = GetAllowLowLevelRaid()
				if unRaid and unRaid == true then
					LeaPlusLC:Print("GetAllowLowLevelRaid: |cffffffff" .. "True")
				else
					LeaPlusLC:Print("GetAllowLowLevelRaid: |cffffffff" .. "False")
				end
				return
			elseif str == "tipcol" then
				-- Show default tooltip title color
				if GameTooltipTextLeft1:IsShown() then
					local r, g, b, a = GameTooltipTextLeft1:GetTextColor()
					r = r <= 1 and r >= 0 and r or 0
					g = g <= 1 and g >= 0 and g or 0
					b = b <= 1 and b >= 0 and b or 0
					LeaPlusLC:Print(L["Tooltip title color"] .. ": " .. strupper(string.format("%02x%02x%02x", r * 255, g * 255, b * 255) .. "."))
				else
					LeaPlusLC:Print("No tooltip showing.")
				end
				return
			elseif str == "list" then
				-- Enumerate frames
				local frame = EnumerateFrames()
				while frame do
					if not frame:IsAnchoringSecret() then
						if (frame:IsVisible() and frame:IsMouseOver()) then
							LeaPlusLC:Print(frame:GetName() or string.format("[Unnamed Frame: %s]", tostring(frame)))
						end
					else
						LeaPlusLC:Print(L["[Secret frame: SECRET FRAME]"])
					end
					frame = EnumerateFrames(frame)
				end
				return
			elseif str == "nohelp" then
				-- Set most help plates to seen
				for i = 1, 100 do
					SetCVarBitfield("closedInfoFrames", i, true)
				end
				return
			elseif str == "grid" then
				-- Toggle frame alignment grid
				if LeaPlusLC.grid:IsShown() then LeaPlusLC.grid:Hide() else LeaPlusLC.grid:Show() end
				return
			elseif str == "chk" then
				-- List truncated checkbox labels
				if LeaPlusLC["TruncatedLabelsList"] then
					for i, v in pairs(LeaPlusLC["TruncatedLabelsList"]) do
						LeaPlusLC:Print(LeaPlusLC["TruncatedLabelsList"][i])
					end
				else
					LeaPlusLC:Print("Checkbox labels are Ok.")
				end
				return
			elseif str == "cv" then
				-- Print and set console variable setting
				if arg1 and arg1 ~= "" then
					if GetCVar(arg1) then
						if arg2 and arg2 ~= ""  then
							if tonumber(arg2) then
								SetCVar(arg1, arg2)
							else
								LeaPlusLC:Print("Value must be a number.")
								return
							end
						end
						LeaPlusLC:Print(arg1 .. ": |cffffffff" .. GetCVar(arg1))
					else
						LeaPlusLC:Print("Invalid console variable.")
					end
				else
					LeaPlusLC:Print("Missing console variable.")
				end
				return
			elseif str == "torch" or str == "t" then
				-- Torch toggle
				if tonumber(GetCVar("gamma")) ~= 1.0 then
					SetCVar("gamma", 1.0)
					LeaPlusLC:DisplayMessage(L["Torch Off"], true)
				else
					SetCVar("gamma", 1.3)
					LeaPlusLC:DisplayMessage(L["Torch On"], true)
				end
				return
			elseif str == "play" then
				-- Play sound ID
				if arg1 and arg1 ~= "" then
					if tonumber(arg1) then
						-- Stop last played sound ID
						if LeaPlusLC.SNDcanitHandle then
							StopSound(LeaPlusLC.SNDcanitHandle)
						end
						-- Play sound ID
						LeaPlusLC.SNDcanitPlay, LeaPlusLC.SNDcanitHandle = C_Sound.PlaySound(arg1, "Master", false, false)
						if not LeaPlusLC.SNDcanitPlay then LeaPlusLC:Print(L["Invalid sound ID"] .. ": |cffffffff" .. arg1) end
					else
						LeaPlusLC:Print(L["Invalid sound ID"] .. ": |cffffffff" .. arg1)
					end
				else
					LeaPlusLC:Print("Missing sound ID.")
				end
				return
			elseif str == "stop" then
				-- Stop last played sound ID
				if LeaPlusLC.SNDcanitHandle then
					StopSound(LeaPlusLC.SNDcanitHandle)
				end
				return
			elseif str == "wipecds" then
				-- Wipe cooldowns
				LeaPlusDB["Cooldowns"] = nil
				ReloadUI()
				return
			elseif str == "tipchat" then
				-- Print tooltip contents in chat
				local numLines = GameTooltip:NumLines()
				if numLines then
					for i = 1, numLines do
						print(_G["GameTooltipTextLeft" .. i]:GetText() or "")
					end
				end
				return
			elseif str == "tiplang" then
				-- Tooltip tag locale code constructor
				local msg = ""
				msg = msg .. 'if GameLocale == "' .. GameLocale .. '" then '
				msg = msg .. 'ttLevel = "' .. LEVEL .. '"; '
				msg = msg .. 'ttBoss = "' .. BOSS .. '"; '
				msg = msg .. 'ttElite = "' .. ELITE .. '"; '
				msg = msg .. 'ttRare = "' .. ITEM_QUALITY3_DESC .. '"; '
				msg = msg .. 'ttRareElite = "' .. ITEM_QUALITY3_DESC .. " " .. ELITE .. '"; '
				msg = msg .. 'ttRareBoss = "' .. ITEM_QUALITY3_DESC .. " " .. BOSS .. '"; '
				msg = msg .. 'ttTarget = "' .. TARGET .. '"; '
				msg = msg .. "end"
				print(msg)
				return
			elseif str == "con" then
				-- Show the developer console
				ConsoleSetFontHeight(28)
				DeveloperConsole:Toggle(true)
				return
			elseif str == "movietime" then
				-- Show movie length
				if not LeaPlusLC.movieTimeLoaded then
					hooksecurefunc(MovieFrame, "Show", function()
						LeaPlusLC.startMovieTime = GetTime()
					end)
					hooksecurefunc(MovieFrame, "Hide", function()
						LeaPlusLC.endMovieTime = GetTime()
						local ttime = LeaPlusLC.endMovieTime - LeaPlusLC.startMovieTime
						print(string.format("%0.0f", ttime))
					end)
					LeaPlusLC.movieTimeLoaded = true
					LeaPlusLC:Print("MovieTime loaded.")
				else
					LeaPlusLC:Print("MovieTime is already loaded.")
				end
				return
			elseif str == "movie" then
				-- Playback movie by ID
				arg1 = tonumber(arg1)
				if arg1 and arg1 ~= "" then
					-- Play movie by ID
					if IsMoviePlayable(arg1) then
						MovieFrame_PlayMovie(MovieFrame, arg1)
					else
						LeaPlusLC:Print("Movie not playable.")
					end
				else
					-- List playable movie IDs
					local count = 0
					for i = 1, 5000 do
						if IsMoviePlayable(i) then
							print(i)
							count = count + 1
						end
					end
					LeaPlusLC:Print("Total movies: |cffffffff" .. count)
				end
				return
			elseif str == "cin" then
				-- Play opening cinematic (only works if character has never gained XP) (used for testing)
				OpeningCinematic()
				return
			elseif str == "skit" then
				-- Play a test sound kit
				C_Sound.PlaySound("1020", "Master", false, true)
				return
			elseif str == "dup" then
				-- Print music track duplicates
				local mask, found, badidfound = false, false, false
				for i, e in pairs(Leatrix_Plus["ZoneList"]) do
					if Leatrix_Plus["ZoneList"][e] then
						for a, b in pairs(Leatrix_Plus["ZoneList"][e]) do
							local same = {}
							if b.tracks then
								for k, v in pairs(b.tracks) do
									-- Check for bad sound IDs
									if not strfind(v, "|c") then
										if not v:match("([^,]+)%#([^,]+)%#([^,]+)") then
											local temFile, temSoundID = v:match("([^,]+)%#([^,]+)")
											if temSoundID then
												local temPlay, temHandle = C_Sound.PlaySound(temSoundID, "Master", false, true)
												if temHandle then StopSound(temHandle) end
												temPlay, temHandle = C_Sound.PlaySound(temSoundID, "Master", false, true)
												if not temPlay and not temHandle then
													print("|cffff5400" .. L["Bad ID"] .. ": |r" .. e, v)
													badidfound = true
												else
													if temHandle then StopSound(temHandle) end
												end
											end
										end
										-- Check for duplicate IDs
										if table.contains(same, v) and mask == false then
											mask = true
											found = true
											print("|cffec51ff" .. L["Dup ID"] .. ": |r" .. e, v)
										end
										tinsert(same, v)
										mask = false
									end
								end
							end
						end
					end
				end
				if badidfound == false then
					LeaPlusLC:Print("No bad sound IDs found.")
				end
				if found == false then
					LeaPlusLC:Print("No media duplicates found.")
				end
				Sound_GameSystem_RestartSoundSystem()
				collectgarbage()
				return
			elseif str == "enigma" then
				-- Enigma
				if not LeaPlusLC.enimgaFrame then
					local selectedBtn
					local bt = {}
					local eData = {
						{[9]=1, [10]=1, [11]=1, [12]=1, [13]=1, [20]=1, [23]=1, [24]=1, [25]=1, [26]=1, [27]=1, [30]=1, [37]=1, [38]=1, [39]=1, [40]=1, [41]=2, "L4, U2, R4, U2, L4",},
						{[9]=1, [11]=1, [12]=1, [13]=1, [16]=1, [18]=1, [20]=1, [23]=1, [24]=1, [25]=1, [27]=1, [34]=1, [41]=2, "U4, L2, D2, L2, U2",},
						{[9]=1, [10]=1, [11]=1, [12]=1, [19]=1, [25]=1, [26]=1, [32]=1, [39]=1, [40]=1, [41]=2, "L2, U2, R1, U2, L3",},
						{[9]=1, [10]=1, [11]=1, [18]=1, [23]=1, [24]=1, [25]=1, [30]=1, [37]=1, [38]=1, [39]=1, [40]=1, [41]=2, "L4, U2, R2, U2, L2",},
						{[9]=1, [10]=1, [11]=1, [12]=1, [13]=1, [16]=1, [23]=1, [25]=1, [26]=1, [27]=1, [30]=1, [32]=1, [34]=1, [37]=1, [38]=1, [39]=1, [41]=2, "U2, L2, D2, L2, U4, R4",},
						{[12]=1,[13]=1, [18]=1, [19]=1, [25]=1, [32]=1, [33]=1, [40]=1, [41]=2, "L1, U1, L1, U2, R1, U1, R1",},
						{[9]=1, [11]=1, [12]=1, [13]=1, [16]=1, [18]=1, [20]=1, [23]=1, [25]=1, [27]=1, [30]=1, [31]=1, [32]=1, [34]=1, [41]=2, "U4, L2, D3, L2, U3",},
						{[9]=1, [10]=1, [17]=1, [24]=1, [25]=1, [32]=1, [33]=1, [40]=1, [41]=2, "L1, U1, L1, U1, L1, U2, L1",},
						{[9]=1, [16]=1, [17]=1, [18]=1, [19]=1, [20]=1, [27]=1, [34]=1, [41]=2, "U3, L4, U1",},
						{[9]=1, [10]=1, [11]=1, [12]=1, [13]=1, [16]=1, [23]=1, [24]=1, [25]=1, [26]=1, [33]=1, [40]=1, [41]=2, "L1, U2, L3, U2, R4",},
						{[9]=1, [10]=1, [11]=1, [12]=1, [13]=1, [16]=1, [23]=1, [30]=1, [37]=1, [38]=1, [39]=1, [40]=1, [41]=2, "L4, U4, R4",},
						{[11]=1,[12]=1, [13]=1, [18]=1, [23]=1, [24]=1, [25]=1, [30]=1, [37]=1, [38]=1, [39]=1, [40]=1, [41]=2, "L4, U2, R2, U2, R2",},
						{[13]=1,[20]=1, [23]=1, [24]=1, [25]=1, [26]=1, [27]=1, [30]=1, [37]=1, [38]=1, [39]=1, [40]=1, [41]=2, "L4, U2, R4, U2",},
					}
					-- Create frame
					local eFrame = CreateFrame("Frame", nil, UIParent)
					eFrame:SetPoint("TOP", 0, 0)
					eFrame:SetSize(1222, 134)
					eFrame.b = eFrame:CreateTexture(nil, "BACKGROUND")
					eFrame.b:SetAllPoints()
					eFrame.b:SetColorTexture(0, 0, 0, 1)
					eFrame:SetFrameStrata("FULLSCREEN_DIALOG")
					eFrame:SetScale(0.9)
					eFrame:SetToplevel(true)
					eFrame:EnableMouse(true)
					LeaPlusLC.enimgaFrame = eFrame

					-- Right-click to exit
					eFrame:SetScript("OnMouseDown", function(self, btn)
						if btn == "RightButton" then
							eFrame:Hide()
						end
					end)

					-- Create title fontstring
					eFrame.f = eFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
					eFrame.f:SetPoint("BOTTOMLEFT", 10, 10)
					eFrame.f:SetText(L["Choose an Enigma pattern"])
					eFrame.f:SetFont(eFrame.f:GetFont(), 24, nil)

					-- Create close fontstring
					eFrame.x = eFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
					eFrame.x:SetPoint("BOTTOMRIGHT", -10, 10)
					eFrame.x:SetText(L["Right-click to close"])
					eFrame.x:SetFont(eFrame.f:GetFont(), 24, nil)

					-- Create buttons
					for eBtn = 1, #eData do
						local b = CreateFrame("Button", nil, eFrame)
						tinsert(bt, b)
						b:SetSize(94, 94)
						b:SetPoint("TOPLEFT", ((eBtn - 1) % 13) * 94, -2)

						-- Button highlight bar
						b.line = b:CreateTexture(nil, "ARTWORK")
						b.line:SetTexture("Interface\\PLAYERFRAME\\DruidLunarBarHorizontal")
						b.line:SetSize(84, 6)
						b.line:SetPoint("BOTTOM", 0, -4)
						b.line:Hide()

						-- Button textures
						for row = 0, 7 - 1 do
							for col = 0, 7 - 1 do
								local t = b:CreateTexture(nil, "ARTWORK")
								t:SetSize(12, 12)
								t:SetPoint("TOPLEFT", 5 + col * 12, - 5 - row * 12)
								local c = eData[eBtn][row * 7 + col + 1]
								-- Do nothing if element is the solution
								if c and strfind(c, ",") then c = nil end
								-- Color textures
								if c == 2 then
									-- Starting block
									t:SetColorTexture(0, 1, 0)
								elseif c then
									-- Path
									t:SetColorTexture(1, 1, 1)
								else
									-- Background
									t:SetColorTexture(.4, .4, .9)
								end
							end
						end

						-- Button scripts
						b:SetScript("OnEnter", function()
							bt[eBtn].line:Show()
						end)

						b:SetScript("OnLeave", function()
							if b ~= selectedBtn then bt[eBtn].line:Hide() end
						end)

						b:SetScript("OnMouseDown", function(self, btn)
							if btn == "RightButton" then
								-- Right-click to exit
								eFrame:Hide()
								return
							else
								-- Deselect all buttons
								for test = 1, #bt do
									bt[test].line:Hide()
								end
								-- Select current button
								bt[eBtn].line:Show()
								selectedBtn = b
								C_Sound.PlaySound(115, "Master", false, true)
								-- Print button data
								eFrame.f:SetText(L["Enigma"] .. " " .. eBtn .. ": |cffffffff" .. eData[eBtn][#eData[eBtn]])
							end
						end)

					end
				else
					-- Toggle frame
					if LeaPlusLC.enimgaFrame:IsShown() then
						LeaPlusLC.enimgaFrame:Hide()
					else
						LeaPlusLC.enimgaFrame:Show()
					end
				end
				return
			elseif str == "showinst" then
				-- List instance IDs for currently selected Encounter Journal expansion filter dropdown
				for i = 1, 5000 do
					local instanceID, name, description, bgImage, buttonImage, loreImage, dungeonAreaMapID, link = EJ_GetInstanceByIndex(i, false)
					if instanceID then print(instanceID, name) end
				end
				for i = 1, 5000 do
					local instanceID, name, description, bgImage, buttonImage, loreImage, dungeonAreaMapID, link = EJ_GetInstanceByIndex(i, true)
					if instanceID then print(instanceID, name) end
				end
				return
			elseif str == "exit" then
				-- Exit a vehicle
				VehicleExit()
				return
			elseif str == "pos" then
				-- Map POI code builder
				local mapID = C_Map.GetBestMapForUnit("player") or nil
				local mapName = C_Map.GetMapInfo(mapID).name or nil
				local mapRects = {}
				local tempVec2D = CreateVector2D(0, 0)
				local void
				-- Get player map position
				tempVec2D.x, tempVec2D.y = UnitPosition("player")
				if not tempVec2D.x then return end
				local mapRect = mapRects[mapID]
				if not mapRect then
					mapRect = {}
					void, mapRect[1] = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(0, 0))
					void, mapRect[2] = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(1, 1))
					mapRect[2]:Subtract(mapRect[1])
					mapRects[mapID] = mapRect
				end
				tempVec2D:Subtract(mapRects[mapID][1])
				local pX, pY = tempVec2D.y/mapRects[mapID][2].y, tempVec2D.x/mapRects[mapID][2].x
				pX = string.format("%0.1f", 100 * pX)
				pY = string.format("%0.1f", 100 * pY)
				if mapID and mapName and pX and pY then
					ChatFrame1:Clear()
					local dnType, dnTex = "Dungeon", "dnTex"
					if arg1 == "raid" then dnType, dnTex = "Raid", "rdTex" end
					if arg1 == "portal" then dnType = "Portal" end
					print('[' .. mapID .. '] =  --[[' .. mapName .. ']] {{"Dungeon", ' .. pX .. ', ' .. pY .. ', L[' .. '"Name"' .. '], L[' .. '"' .. dnType .. '"' .. ']},},')
				end
				return
			elseif str == "mapref" then
				-- Print map reveal structure code
				if not WorldMapFrame:IsShown() then
					LeaPlusLC:Print("Open the map first!")
					return
				end
				ChatFrame1:Clear()
				local msg = ""
				local mapID = WorldMapFrame.mapID
				local mapName = C_Map.GetMapInfo(mapID).name
				local mapArt = C_Map.GetMapArtID(mapID)
				msg = msg .. "--[[" .. mapName .. "]] [" .. mapArt .. "] = {"
				local exploredMapTextures = C_MapExplorationInfo.GetExploredMapTextures(mapID);
				if exploredMapTextures then
					for i, exploredTextureInfo in ipairs(exploredMapTextures) do
						local twidth = exploredTextureInfo.textureWidth or 0
						if twidth > 0 then
							local theight = exploredTextureInfo.textureHeight or 0
							local offsetx = exploredTextureInfo.offsetX
							local offsety = exploredTextureInfo.offsetY
							local filedataIDS = exploredTextureInfo.fileDataIDs
							msg = msg .. "[" .. '"' .. twidth .. ":" .. theight .. ":" .. offsetx .. ":" .. offsety .. '"' .. "] = " .. '"'
							for fileData = 1, #filedataIDS do
								msg = msg .. filedataIDS[fileData]
								if fileData < #filedataIDS then
									msg = msg .. ", "
								else
									msg = msg .. '",'
									if i < #exploredMapTextures then
										msg = msg .. " "
									end
								end
							end
						end
					end
					msg = msg .. "},"
					print(msg)
				end
				return
			elseif str == "map" then
				-- Set map by ID, print currently showing map ID or print character map ID
				if not arg1 then
					-- Print map ID
					if WorldMapFrame:IsShown() then
						-- Show world map ID
						local mapID = WorldMapFrame.mapID or nil
						local artID = C_Map.GetMapArtID(mapID) or nil
						local mapName = C_Map.GetMapInfo(mapID).name or nil
						if mapID and artID and mapName then
							LeaPlusLC:Print(mapID .. " (" .. artID .. "): " .. mapName .. " (map)")
						end
					else
						-- Show character map ID
						local mapID = C_Map.GetBestMapForUnit("player") or nil
						local artID = C_Map.GetMapArtID(mapID) or nil
						local mapName = C_Map.GetMapInfo(mapID).name or nil
						if mapID and artID and mapName then
							LeaPlusLC:Print(mapID .. " (" .. artID .. "): " .. mapName .. " (player)")
						end
					end
					return
				elseif not tonumber(arg1) or not C_Map.GetMapInfo(arg1) then
					-- Invalid map ID
					LeaPlusLC:Print("Invalid map ID.")
				else
					-- Set map by ID
					WorldMapFrame:SetMapID(tonumber(arg1))
				end
				return
			elseif str == "cls" then
				-- Clear chat frame
				ChatFrame1:Clear()
				return
			elseif str == "al" then
				-- Enable auto loot
				SetCVar("autoLootDefault", "1")
				LeaPlusLC:Print("Auto loot is now enabled.")
				return
			elseif str == "realm" then
				-- Show list of connected realms
				local titleRealm = GetRealmName()
				local userRealm = GetNormalizedRealmName()
				local connectedServers = C_AutoComplete.GetAutoCompleteRealms()
				if titleRealm and userRealm and connectedServers then
					LeaPlusLC:Print(L["Connections for"] .. "|cffffffff " .. titleRealm)
					if #connectedServers > 0 then
						local count = 1
						for i = 1, #connectedServers do
							if userRealm ~= connectedServers[i] then
								LeaPlusLC:Print(count .. ".  " .. connectedServers[i])
								count = count + 1
							end
						end
					else
						LeaPlusLC:Print("None")
					end
				end
				return
			elseif str == "deletelooms" then
				-- Delete heirlooms from bags
				for bag = 0, 4 do
					for slot = 1, C_Container.GetContainerNumSlots(bag) do
						local name = C_Container.GetContainerItemLink(bag, slot)
						if name and string.find(name, "00ccff") then
							print(name)
							PickupContainerItem(bag, slot)
							DeleteCursorItem()
						end
					end
				end
				return
			elseif str == "help" then
				-- Help panel
				if not LeaPlusLC.HelpFrame then
					local frame = CreateFrame("FRAME", nil, UIParent)
					frame:SetSize(570, 360); frame:SetFrameStrata("FULLSCREEN_DIALOG"); frame:SetFrameLevel(100)
					frame.tex = frame:CreateTexture(nil, "BACKGROUND"); frame.tex:SetAllPoints(); frame.tex:SetColorTexture(0.05, 0.05, 0.05, 0.9)
					frame.close = LeaPlusLC:CreateCloseButton(frame, 30, 30, "TOPRIGHT", 0, 0)
					frame.close:SetScript("OnClick", function() frame:Hide() end)
					frame:ClearAllPoints(); frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
					frame:SetClampedToScreen(true)
					frame:SetClampRectInsets(450, -450, -300, 300)
					frame:EnableMouse(true)
					frame:SetMovable(true)
					frame:RegisterForDrag("LeftButton")
					frame:SetScript("OnDragStart", frame.StartMoving)
					frame:SetScript("OnDragStop", function() frame:StopMovingOrSizing() frame:SetUserPlaced(false) end)
					frame:Hide()
					LeaPlusLC:CreateBar("HelpPanelMainTexture", frame, 570, 360, "TOPRIGHT", 0.7, 0.7, 0.7, 0.7,  "Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated.png")
					-- Panel contents
					local col1, col2, color1 = 10, 120, "|cffffffaa"
					LeaPlusLC:MakeTx(frame, "Leatrix Plus Help", col1, -10)
					LeaPlusLC:MakeWD(frame, color1 .. "/ltp|r", col1, -30)
					LeaPlusLC:MakeWD(frame, "Toggle options panel.", col2, -30)
					LeaPlusLC:MakeWD(frame, color1 .. "/ltp reset", col1, -50)
					LeaPlusLC:MakeWD(frame, "Reset addon panel position and scale.", col2, -50)
					LeaPlusLC:MakeWD(frame, color1 .. "/ltp wipe", col1, -70)
					LeaPlusLC:MakeWD(frame, "Wipe all addon settings (reloads UI).", col2, -70)
					LeaPlusLC:MakeWD(frame, color1 .. "/ltp realm", col1, -90)
					LeaPlusLC:MakeWD(frame, "Show realms connected to yours.", col2, -90)
					LeaPlusLC:MakeWD(frame, color1 .. "/ltp rest", col1, -110)
					LeaPlusLC:MakeWD(frame, "Show number of rested XP bubbles remaining.", col2, -110)
					LeaPlusLC:MakeWD(frame, color1 .. "/ltp quest <id>", col1, -130)
					LeaPlusLC:MakeWD(frame, "Show quest completion status for <quest id>.", col2, -130)
					LeaPlusLC:MakeWD(frame, color1 .. "/ltp quest wipe", col1, -150)
					LeaPlusLC:MakeWD(frame, "Wipe your quest log.", col2, -150)
					LeaPlusLC:MakeWD(frame, color1 .. "/ltp hk", col1, -170)
					LeaPlusLC:MakeWD(frame, "Show your lifetime honorable kills.", col2, -170)
					LeaPlusLC:MakeWD(frame, color1 .. "/ltp grid", col1, -190)
					LeaPlusLC:MakeWD(frame, "Toggle a frame alignment grid.", col2, -190)
					LeaPlusLC:MakeWD(frame, color1 .. "/ltp zygor", col1, -210)
					LeaPlusLC:MakeWD(frame, "Toggle the Zygor addon (reloads UI).", col2, -210)
					LeaPlusLC:MakeWD(frame, color1 .. "/ltp movie <id>", col1, -230)
					LeaPlusLC:MakeWD(frame, "Play a movie by its ID.", col2, -230)
					LeaPlusLC:MakeWD(frame, color1 .. "/ltp enigma", col1, -250)
					LeaPlusLC:MakeWD(frame, "Toggle the Enigmatic quest solver.", col2, -250)
					LeaPlusLC:MakeWD(frame, color1 .. "/ltp rsnd", col1, -270)
					LeaPlusLC:MakeWD(frame, "Restart the sound system.", col2, -270)
					LeaPlusLC:MakeWD(frame, color1 .. "/ltp ra", col1, -290)
					LeaPlusLC:MakeWD(frame, "Announce target in General chat channel (useful for rares).", col2, -290)
					LeaPlusLC:MakeWD(frame, color1 .. "/ltp con", col1, -310)
					LeaPlusLC:MakeWD(frame, "Launch the developer console with a large font.", col2, -310)
					LeaPlusLC:MakeWD(frame, color1 .. "/rl", col1, -330)
					LeaPlusLC:MakeWD(frame, "Reload the UI.", col2, -330)
					LeaPlusLC.HelpFrame = frame
					_G["LeaPlusGlobalHelpPanel"] = frame
					table.insert(UISpecialFrames, "LeaPlusGlobalHelpPanel")
				end
				if LeaPlusLC.HelpFrame:IsShown() then LeaPlusLC.HelpFrame:Hide() else LeaPlusLC.HelpFrame:Show() end
				return
			elseif str == "who" then
				-- Print out who list URLs
				ChatFrame1:Clear()
				local realmName = gsub(GetRealmName(), " ", "-")
				for i = 1,C_FriendList.GetNumWhoResults() do
					local p = C_FriendList.GetWhoInfo(i)
					if not string.find(p.fullName, "-") then
						print("https://worldofwarcraft.com/en-gb/character/eu/" .. realmName .. "/" .. p.fullName .. "/collections/pets")
					end
				end
				return
			elseif str == "ra" then
				-- Announce target name and map pin link in General chat channel
				if C_ChatInfo.InChatMessagingLockdown() then
					LeaPlusLC:Print("Chat messages are restricted right now.")
					return
				end
				local genChannel
				if GameLocale == "deDE" 	then genChannel = "Allgemein"
				elseif GameLocale == "esMX" then genChannel = "General"
				elseif GameLocale == "esES" then genChannel = "General"
				elseif GameLocale == "frFR" then genChannel = "Général"
				elseif GameLocale == "itIT" then genChannel = "Generale"
				elseif GameLocale == "ptBR" then genChannel = "Geral"
				elseif GameLocale == "ruRU" then genChannel = "Общий"
				elseif GameLocale == "koKR" then genChannel = "공개"
				elseif GameLocale == "zhCN" then genChannel = "综合"
				elseif GameLocale == "zhTW" then genChannel = "綜合"
				else							 genChannel = "General"
				end
				-- genChannel = "Crazy" -- Uncomment for debug
				if genChannel then
					local index = GetChannelName(genChannel)
					if index and index > 0 then
						local mapID = C_Map.GetBestMapForUnit("player")
						if C_Map.CanSetUserWaypointOnMap(mapID) then
							local pos = C_Map.GetPlayerMapPosition(mapID, "player")
							if pos.x and pos.x ~= "0" and pos.y and pos.y ~= "0" then
								local mapPoint = UiMapPoint.CreateFromVector2D(mapID, pos)
								if mapPoint then
									-- Store original pin if there is one
									local currentPin = C_Map.GetUserWaypointHyperlink()
									-- Set map pin and get the link
									C_Map.SetUserWaypoint(mapPoint)
									local myPin = C_Map.GetUserWaypointHyperlink()
									-- Put original pin back if there was one
									if currentPin then
										C_Timer.After(0.1, function()
											local oldPin = C_Map.GetUserWaypointFromHyperlink(currentPin)
											C_Map.SetUserWaypoint(oldPin)
										end)
									end
									-- Announce in chat
									if myPin then
										-- Get unit classification (elite, rare, rare elite or boss)
										local unitType, unitTag = UnitClassification("target"), ""
										if unitType then
											if unitType == "rare" or unitType == "rareelite" then unitTag = "(" .. L["Rare"] .. ") " elseif unitType == "worldboss" then unitTag = "(" .. L["Boss"] .. ") " end
										end
										C_ChatInfo.SendChatMessage(format("%%t " .. unitTag, " ") .. " " .. myPin, "CHANNEL", nil, index)
--										C_ChatInfo.SendChatMessage(format("%%t " .. unitTag, " ") .. " " .. myPin, "WHISPER", nil, GetUnitName("player")) -- Debug
										C_Map.ClearUserWaypoint()
									else
										LeaPlusLC:Print("Invalid target.")
									end
								else
									LeaPlusLC:Print("Cannot announce in this zone.")
								end
							else
								LeaPlusLC:Print("Cannot announce in this zone.")
							end
						else
							LeaPlusLC:Print("Cannot announce in this zone.")
						end
					else
						LeaPlusLC:Print("Cannot find General chat channel.")
					end
				end
				return
			elseif str == "ach" then
				-- Set Instance Achievement Tracker window properties
				if AchievementTracker then
					AchievementTracker:SetScale(1.4)
					AchievementTracker:SetClampRectInsets(500, -500, -10, 300)
					table.insert(UISpecialFrames, "AchievementTracker")
					LeaPlusLC:Print("IAT scale set and window can now be closed with escape.")
				end
				return
			elseif str == "blanchy" then
				-- Sound alert when Dead Blanchy emotes nearby
				LeaPlusLC.BlanchyFrame = LeaPlusLC.BlanchyFrame or CreateFrame("FRAME")
				if LeaPlusLC.BlanchyFrame:IsEventRegistered("CHAT_MSG_MONSTER_EMOTE") then
					C_Map.ClearUserWaypoint()
					LeaPlusLC.BlanchyFrame:UnregisterEvent("CHAT_MSG_MONSTER_EMOTE")
					LeaPlusLC:Print("Dead Blanchy alert disabled.")
				else
					C_Map.SetUserWaypoint(UiMapPoint.CreateFromVector2D(1525, CreateVector2D(63.1/100, 43.0/100)))
					LeaPlusLC.BlanchyFrame:RegisterEvent("CHAT_MSG_MONSTER_EMOTE")
					LeaPlusLC:Print("Dead Blanchy alert active.  Spawn point has been pinned to the Revendreth map.  An alert will sound 20 times when Blanchy emotes nearby.")
				end
				LeaPlusLC.BlanchyFrame:SetScript("OnEvent", function(self, event, void, pname)
					if pname == L["Dead Blanchy"] then
						C_Timer.NewTicker(1, function()	C_Sound.PlaySound(8959, "Master") end, 20)
					end
				end)
				return
			elseif str == "perf" then
				-- Average FPS during combat
				local fTab = {}
				if not LeaPlusLC.perf then
					LeaPlusLC.perf = CreateFrame("FRAME")
				end
				local fFrm = LeaPlusLC.perf
				local k, startTime = 0, 0
				if fFrm:IsEventRegistered("PLAYER_REGEN_DISABLED") then
					fFrm:UnregisterAllEvents()
					fFrm:SetScript("OnUpdate", nil)
					LeaPlusLC:Print("PERF unloaded.")
				else
					fFrm:RegisterEvent("PLAYER_REGEN_DISABLED")
					fFrm:RegisterEvent("PLAYER_REGEN_ENABLED")
					LeaPlusLC:Print("Waiting for combat to start...")
				end
				fFrm:SetScript("OnEvent", function(self, event)
					if event == "PLAYER_REGEN_DISABLED" then
						LeaPlusLC:Print("Monitoring FPS during combat...")
						fFrm:SetScript("OnUpdate", function()
							k = k + 1
							fTab[k] = GetFramerate()
						end)
						startTime = GetTime()
					else
						fFrm:SetScript("OnUpdate", nil)
						local tSum = 0
						for i = 1, #fTab do
							tSum = tSum + fTab[i]
						end
						local timeTaken = string.format("%.0f", GetTime() - startTime)
						if tSum > 0 then
							LeaPlusLC:Print("Average FPS for " .. timeTaken .. " seconds of combat: " .. string.format("%.0f", tSum / #fTab))
						end
					end
				end)
				return
			elseif str == "col" then
				-- Convert color values
				LeaPlusLC:Print("|n")
				local r, g, b = tonumber(arg1), tonumber(arg2), tonumber(arg3)
				if r and g and b then
					-- RGB source
					LeaPlusLC:Print("Source: |cffffffff" .. r .. " " .. g .. " " .. b .. " ")
					-- RGB to Hex
					if r > 1 and g > 1 and b > 1 then
						-- RGB to Hex
						LeaPlusLC:Print("Hex: |cffffffff" .. strupper(string.format("%02x%02x%02x", r, g, b)) .. " (from RGB)")
					else
						-- Wow to Hex
						LeaPlusLC:Print("Hex: |cffffffff" .. strupper(string.format("%02x%02x%02x", r * 255, g * 255, b * 255)) .. " (from Wow)")
						-- Wow to RGB
						local rwow = string.format("%.0f", r * 255)
						local gwow = string.format("%.0f", g * 255)
						local bwow = string.format("%.0f", b * 255)
						if rwow ~= "0.0" and gwow ~= "0.0" and bwow ~= "0.0" then
							LeaPlusLC:Print("RGB: |cffffffff" .. rwow .. " " .. gwow .. " " .. bwow .. " (from Wow)")
						end
					end
					-- RGB to Wow
					local rwow = string.format("%.1f", r / 255)
					local gwow = string.format("%.1f", g / 255)
					local bwow = string.format("%.1f", b / 255)
					if rwow ~= "0.0" and gwow ~= "0.0" and bwow ~= "0.0" then
						LeaPlusLC:Print("Wow: |cffffffff" .. rwow .. " " .. gwow .. " " .. bwow)
					end
					LeaPlusLC:Print("|n")
				elseif arg1 and strlen(arg1) == 6 and strmatch(arg1,"%x") and arg2 == nil and arg3 == nil then
					-- Hex source
					local rhex, ghex, bhex = string.sub(arg1, 1, 2), string.sub(arg1, 3, 4), string.sub(arg1, 5, 6)
					if strmatch(rhex,"%x") and strmatch(ghex,"%x") and strmatch(bhex,"%x") then
						LeaPlusLC:Print("Source: |cffffffff" .. strupper(arg1))
						LeaPlusLC:Print("Wow: |cffffffff" .. string.format("%.1f", tonumber(rhex, 16) / 255) ..  "  " .. string.format("%.1f", tonumber(ghex, 16) / 255) .. "  " .. string.format("%.1f", tonumber(bhex, 16) / 255))
						LeaPlusLC:Print("RGB: |cffffffff" .. tonumber(rhex, 16) .. "  " .. tonumber(ghex, 16) .. "  " .. tonumber(bhex, 16))
					else
						LeaPlusLC:Print("Invalid arguments.")
					end
					LeaPlusLC:Print("|n")
				else
					LeaPlusLC:Print("Invalid arguments.")
				end
				return
			elseif str == "click" then
				-- Click a button so a user can test if it is allowed (optional number of times to click)
				local mouseFoci = GetMouseFoci()
				if mouseFoci then
					local frame = mouseFoci[#mouseFoci]
					local ftype = frame:GetObjectType()
					if frame and ftype and ftype == "Button" then
						if arg1 and tonumber(arg1) > 1 and tonumber(arg1) < 1000 then
							for i =1, tonumber(arg1) do C_Timer.After(0.1 * i, function() frame:Click() end) end
						else
							frame:Click()
						end
					else
						LeaPlusLC:Print("Hover the pointer over a button.")
					end
					return
				end
			elseif str == "frame" then
				-- Print frame name under mouse
				local mouseFoci = GetMouseFoci()
				if mouseFoci then
					local frame = mouseFoci[#mouseFoci]
					local ftype = frame:GetObjectType()
					if frame and ftype then
						local fname = frame:GetName()
						local issecure, tainted = issecurevariable(fname)
						if issecure then issecure = "Yes" else issecure = "No" end
						if tainted then tainted = "Yes" else tainted = "No" end
						if fname then
							LeaPlusLC:Print("Name: |cffffffff" .. fname)
							LeaPlusLC:Print("Type: |cffffffff" .. ftype)
							LeaPlusLC:Print("Secure: |cffffffff" .. issecure)
							LeaPlusLC:Print("Tainted: |cffffffff" .. tainted)
						end
					end
				end
				return
			elseif str == "arrow" then
				-- Arrow (left: drag, shift/ctrl: rotate, mouseup: loc, pointer must be on arrow stem)
				local f = CreateFrame("Frame", nil, WorldMapFrame.ScrollContainer)
				f:SetSize(64, 64)
				f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
				f:SetFrameLevel(500)
				f:SetParent(WorldMapFrame.ScrollContainer)
				f:SetScale(0.6)

				f.t = f:CreateTexture(nil, "ARTWORK")
				f.t:SetAtlas("Garr_LevelUpgradeArrow")
				f.t:SetAllPoints()

				f.f = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
				f.f:SetText("0.0")

				local x = 0
				f:SetScript("OnUpdate", function()
					if IsShiftKeyDown() then
						x = x + 0.01
						if x > 6.3 then x = 0 end
						f.t:SetRotation(x)
						f.f:SetFormattedText("%.1f", x)
					elseif IsControlKeyDown() then
						x = x - 0.01
						if x < 0 then x = 6.3 end
						f.t:SetRotation(x)
						f.f:SetFormattedText("%.1f", x)
					end
					-- Print coordinates when mouse is in right place
					local x, y = WorldMapFrame.ScrollContainer:GetNormalizedCursorPosition()
					if x and y and x > 0 and y > 0 then
						if f:IsMouseOver(-31, 31, 31, -31) then
							ChatFrame1:Clear()
							print(('{"Arrow", ' .. floor(x * 1000 + 0.5) / 10) .. ',', (floor(y * 1000 + 0.5) / 10) .. ', L["Step 1"], L["Start here."], arTex, nil, nil, nil, nil, nil, ' .. f.f:GetText() .. "},")
							PlaySoundFile(567412, "Master", false, true)
						end
					end
				end)

				f:SetMovable(true)
				f:SetScript("OnMouseDown", function(self, btn)
					if btn == "LeftButton" then
						f:StartMoving()
					end
				end)

				f:SetScript("OnMouseUp", function()
					f:StopMovingOrSizing()
					--ChatFrame1:Clear()
					--local x, y = WorldMapFrame.ScrollContainer:GetNormalizedCursorPosition()
					--if x and y and x > 0 and y > 0 and f:IsMouseOver() then
					--	print(('{"Arrow", ' .. floor(x * 1000 + 0.5) / 10) .. ',', (floor(y * 1000 + 0.5) / 10) .. ', L["Step 1"], L["Start here."], ' .. f.f:GetText() .. "},")
					--end
				end)
				return
			elseif str == "dis" then
				-- Disband group
				if not LeaPlusLC:IsInLFGQueue() and not IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
					local x = GetNumGroupMembers() or 0
					for i = x, 1, -1 do
						if GetNumGroupMembers() > 0 then
							local name = GetRaidRosterInfo(i)
							if name and name ~= UnitName("player") then
								C_PartyInfo.UninviteUnit(name)
							end
						end
					end
				else
					LeaPlusLC:Print("You cannot do that while in group finder.")
				end
				return
			elseif str == "reinv" then
				-- Disband and reinvite raid
				if not LeaPlusLC:IsInLFGQueue() and not IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
					if UnitIsGroupLeader("player") then
						-- Disband
						local groupNames = {}
						local x = GetNumGroupMembers() or 0
						for i = x, 1, -1 do
							if GetNumGroupMembers() > 0 then
								local name = GetRaidRosterInfo(i)
								if name and name ~= UnitName("player") then
									C_PartyInfo.UninviteUnit(name)
									tinsert(groupNames, name)
								end
							end
						end
						-- Reinvite
						C_Timer.After(0.1, function()
							for k, v in pairs(groupNames) do
								C_PartyInfo.InviteUnit(v)
							end
						end)
					else
						LeaPlusLC:Print("You need to be group leader.")
					end
				else
					LeaPlusLC:Print("You cannot do that while in group finder.")
				end
				return
			elseif str == "limit" then
				-- Sound Limit
				if not LeaPlusLC.MuteFrame then
					-- Panel frame
					local frame = CreateFrame("FRAME", nil, UIParent)
					frame:SetSize(294, 86); frame:SetFrameStrata("FULLSCREEN_DIALOG"); frame:SetFrameLevel(100); frame:SetScale(2)
					frame.tex = frame:CreateTexture(nil, "BACKGROUND"); frame.tex:SetAllPoints(); frame.tex:SetColorTexture(0.05, 0.05, 0.05, 0.9)
					frame.close = LeaPlusLC:CreateCloseButton(frame, 30, 30, "TOPRIGHT", 0, 0)
					frame.close:SetScript("OnClick", function() frame:Hide() end)
					frame:ClearAllPoints(); frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
					frame:SetClampedToScreen(true)
					frame:EnableMouse(true)
					frame:SetMovable(true)
					frame:RegisterForDrag("LeftButton")
					frame:SetScript("OnDragStart", frame.StartMoving)
					frame:SetScript("OnDragStop", function() frame:StopMovingOrSizing() frame:SetUserPlaced(false) end)
					frame:Hide()
					LeaPlusLC:CreateBar("MutePanelMainTexture", frame, 294, 86, "TOPRIGHT", 0.7, 0.7, 0.7, 0.7,  "Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated.png")
					-- Panel contents
					LeaPlusLC:MakeTx(frame, "Sound Limit", 16, -12)
					local endBox = LeaPlusLC:CreateEditBox("SoundEndBox", frame, 116, 10, "TOPLEFT", 16, -32, "SoundEndBox", "SoundEndBox")
					endBox:SetText(9000000)
					endBox:SetScript("OnMouseWheel", function(self, delta)
						local endSound = tonumber(endBox:GetText())
						if endSound then
							if delta == 1 then endSound = endSound + LeaPlusLC.SoundByte else endSound = endSound - LeaPlusLC.SoundByte end
							if endSound < 1 then endSound = 1 elseif endSound >= 9000000 then endSound = 9000000 end
							endBox:SetText(endSound)
						else
							endSound = 100000
							endBox:SetText(endSound)
						end
					end)
					-- Set limit button
					frame.btn = LeaPlusLC:CreateButton("muteRangeButton", frame, "SET LIMIT", "TOPLEFT", 16, -72, 0, 25, true, "Click to set the sound file limit.  Use the mousewheel on the editbox along with the step buttons below to adjust the sound limit.  Acceptable range is from 1 to 9000000.  Sound files higher than this limit will be muted.")
					frame.btn:ClearAllPoints()
					frame.btn:SetPoint("LEFT", endBox, "RIGHT", 10, 0)
					frame.btn:SetScript("OnClick", function()
						local endSound = tonumber(endBox:GetText())
						if endSound then
							if endSound > 9000000 then endSound = 9000000 endBox:SetText(endSound) end
							frame.btn:SetText("WAIT")
							C_Timer.After(0.1, function()
								for i = 1, 9000000 do
									MuteSoundFile(i)
								end
								for i = 1, endSound do
									UnmuteSoundFile(i)
								end
								Sound_GameSystem_RestartSoundSystem()
								frame.btn:SetText("SET LIMIT")
							end)
						else
							frame.btn:SetText("INVALID")
							frame.btn:EnableMouse(false)
							C_Timer.After(2, function()
								frame.btn:SetText("SET LIMIT")
								frame.btn:EnableMouse(true)
							end)
						end
					end)
					-- Mute all button
					frame.MuteAllBtn = LeaPlusLC:CreateButton("muteMuteAllButton", frame, "MUTE ALL", "TOPLEFT", 16, -92, 0, 25, true, "Click to mute every sound in the game.")
					frame.MuteAllBtn:SetScale(0.5)
					frame.MuteAllBtn:ClearAllPoints()
					frame.MuteAllBtn:SetPoint("TOPLEFT", frame.btn, "TOPRIGHT", 20, 0)
					frame.MuteAllBtn:SetScript("OnClick", function()
						frame.MuteAllBtn:SetText("WAIT")
						C_Timer.After(0.1, function()
							for i = 1, 9000000 do
								MuteSoundFile(i)
							end
							Sound_GameSystem_RestartSoundSystem()
							frame.MuteAllBtn:SetText("MUTE ALL")
						end)
						return
					end)
					-- Unmute all button
					frame.UnmuteAllBtn = LeaPlusLC:CreateButton("muteUnmuteAllButton", frame, "UNMUTE ALL", "TOPLEFT", 16, -92, 0, 25, true, "Click to unmute every sound in the game.")
					frame.UnmuteAllBtn:SetScale(0.5)
					frame.UnmuteAllBtn:ClearAllPoints()
					frame.UnmuteAllBtn:SetPoint("TOPLEFT", frame.MuteAllBtn, "BOTTOMLEFT", 0, -10)
					frame.UnmuteAllBtn:SetScript("OnClick", function()
						frame.UnmuteAllBtn:SetText("WAIT")
						C_Timer.After(0.1, function()
							for i = 1, 9000000 do
								UnmuteSoundFile(i)
							end
							Sound_GameSystem_RestartSoundSystem()
							frame.UnmuteAllBtn:SetText("UNMUTE ALL")
						end)
						return
					end)
					-- Step buttons
					frame.millionBtn = LeaPlusLC:CreateButton("SoundMillionButton", frame, "1000000", "TOPLEFT", 26, -122, 0, 25, true, "Set the editbox step value to 1000000.")
					frame.millionBtn:SetScale(0.5)

					frame.hundredThousandBtn = LeaPlusLC:CreateButton("SoundHundredThousandButton", frame, "100000", "TOPLEFT", 16, -112, 0, 25, true, "Set the editbox step value to 100000.")
					frame.hundredThousandBtn:ClearAllPoints()
					frame.hundredThousandBtn:SetPoint("LEFT", frame.millionBtn, "RIGHT", 10, 0)
					frame.hundredThousandBtn:SetScale(0.5)

					frame.tenThousandBtn = LeaPlusLC:CreateButton("SoundTenThousandButton", frame, "10000", "TOPLEFT", 16, -112, 0, 25, true, "Set the editbox step value to 10000.")
					frame.tenThousandBtn:ClearAllPoints()
					frame.tenThousandBtn:SetPoint("LEFT", frame.hundredThousandBtn, "RIGHT", 10, 0)
					frame.tenThousandBtn:SetScale(0.5)

					frame.thousandBtn = LeaPlusLC:CreateButton("SoundThousandButton", frame, "1000", "TOPLEFT", 16, -112, 0, 25, true, "Set the editbox step value to 1000.")
					frame.thousandBtn:ClearAllPoints()
					frame.thousandBtn:SetPoint("LEFT", frame.tenThousandBtn, "RIGHT", 10, 0)
					frame.thousandBtn:SetScale(0.5)

					frame.hundredBtn = LeaPlusLC:CreateButton("SoundHundredButton", frame, "100", "TOPLEFT", 16, -112, 0, 25, true, "Set the editbox step value to 100.")
					frame.hundredBtn:ClearAllPoints()
					frame.hundredBtn:SetPoint("LEFT", frame.thousandBtn, "RIGHT", 10, 0)
					frame.hundredBtn:SetScale(0.5)

					frame.tenBtn = LeaPlusLC:CreateButton("SoundTenButton", frame, "10", "TOPLEFT", 16, -112, 0, 25, true, "Set the editbox step value to 10.")
					frame.tenBtn:ClearAllPoints()
					frame.tenBtn:SetPoint("LEFT", frame.hundredBtn, "RIGHT", 10, 0)
					frame.tenBtn:SetScale(0.5)

					frame.oneBtn = LeaPlusLC:CreateButton("SoundTenButton", frame, "1", "TOPLEFT", 16, -112, 0, 25, true, "Set the editbox step value to 1.")
					frame.oneBtn:ClearAllPoints()
					frame.oneBtn:SetPoint("LEFT", frame.tenBtn, "RIGHT", 10, 0)
					frame.oneBtn:SetScale(0.5)

					local function DimAllBoxes()
						frame.millionBtn:SetAlpha(0.3)
						frame.hundredThousandBtn:SetAlpha(0.3)
						frame.tenThousandBtn:SetAlpha(0.3)
						frame.thousandBtn:SetAlpha(0.3)
						frame.hundredBtn:SetAlpha(0.3)
						frame.tenBtn:SetAlpha(0.3)
						frame.oneBtn:SetAlpha(0.3)
					end

					LeaPlusLC.SoundByte = 1000000
					DimAllBoxes()
					frame.millionBtn:SetAlpha(1)

					-- Step button handlers
					frame.millionBtn:SetScript("OnClick", function()
						LeaPlusLC.SoundByte = 1000000
						DimAllBoxes()
						frame.millionBtn:SetAlpha(1)
					end)

					frame.hundredThousandBtn:SetScript("OnClick", function()
						LeaPlusLC.SoundByte = 100000
						DimAllBoxes()
						frame.hundredThousandBtn:SetAlpha(1)
					end)

					frame.tenThousandBtn:SetScript("OnClick", function()
						LeaPlusLC.SoundByte = 10000
						DimAllBoxes()
						frame.tenThousandBtn:SetAlpha(1)
					end)

					frame.thousandBtn:SetScript("OnClick", function()
						LeaPlusLC.SoundByte = 1000
						DimAllBoxes()
						frame.thousandBtn:SetAlpha(1)
					end)

					frame.hundredBtn:SetScript("OnClick", function()
						LeaPlusLC.SoundByte = 100
						DimAllBoxes()
						frame.hundredBtn:SetAlpha(1)
					end)

					frame.tenBtn:SetScript("OnClick", function()
						LeaPlusLC.SoundByte = 10
						DimAllBoxes()
						frame.tenBtn:SetAlpha(1)
					end)

					frame.oneBtn:SetScript("OnClick", function()
						LeaPlusLC.SoundByte = 1
						DimAllBoxes()
						frame.oneBtn:SetAlpha(1)
					end)

					-- Final code
					LeaPlusLC.MuteFrame = frame
					_G["LeaPlusGlobalMutePanel"] = frame
					table.insert(UISpecialFrames, "LeaPlusGlobalMutePanel")
				end
				if LeaPlusLC.MuteFrame:IsShown() then LeaPlusLC.MuteFrame:Hide() else LeaPlusLC.MuteFrame:Show() end
				return
			elseif str == "tz" then
				-- Tazavesh Helper
				if arg1 and arg ~= "" then
					-- Aggramar's Vault
					if not string.find(arg1, "o") or not string.find(arg1, "y") or not string.find(arg1, "p") or not string.find(arg1, "b") then
						LeaPlusLC:Print("Valid letters are O (Orange), Y (Yellow), P (Purple), B (Blue).")
						return
					end
					arg1 = arg1:gsub("%w", {["o"] = "ORANGE,", ["y"] = "YELLOW,", ["p"] = "PURPLE,", ["b"] = "BLUE,"})
					local a, b, c, d = arg1:match("([^,]+),([^,]+),([^,]+),([^,]+)")
					if a and b and c and d then
						local chatDestination
						if IsInRaid() then
							return
						elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
							chatDestination = "INSTANCE_CHAT"
						elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
							chatDestination = "PARTY"
						end
						LeaPlusLC:Print("Letters need to be in clockwise order as they appear.")
						C_ChatInfo.SendChatMessage("Quickly take orbs to these positions and click.", chatDestination)
						C_ChatInfo.SendChatMessage(a .. ": Front left of boss (north)", chatDestination)
						C_ChatInfo.SendChatMessage(b .. ": Front right of boss (east)", chatDestination)
						C_ChatInfo.SendChatMessage(d .. ": Back left of boss (west)", chatDestination)
						C_ChatInfo.SendChatMessage(c .. ": Back right of boss (south)", chatDestination)
					end
					return
				end
				-- Myza's Oasis
				local target
				if not C_Secrets.ShouldAurasBeSecret() then
					for i = 1, 40 do
						local DebuffData = C_UnitAuras.GetDebuffDataByIndex("player", i)
						if DebuffData then
							local spellID = DebuffData.spellId
							if spellID then
								if spellID == 352125 or spellID == 358911 or spellID == 358912 then
									target = "Xy'ghana"
								elseif spellID == 352127 or spellID == 358905 or spellID == 358906 then
									target = "Xy'aqida"
								elseif spellID == 352128 or spellID == 358907 or spellID == 358908 then
									target = "Xy'tadir"
								elseif spellID == 352129 or spellID == 358915 or spellID == 358916 then
									target = "Xy'nara"
								elseif spellID == 352130 or spellID == 358900 or spellID == 358901 then
									target = "Xy'mal"
								elseif spellID == 352131 or spellID == 358917 or spellID == 358918 then
									target = "Xy'jahid"
								elseif spellID == 352132 or spellID == 358903 or spellID == 358904 then
									target = "Xy'kitaab"
								elseif spellID == 352133 or spellID == 358913 or spellID == 358914 then
									target = "Xy'har"
								elseif spellID == 352134 or spellID == 358909 or spellID == 358910 then
									target = "Xy'zaro"
								-- elseif spellID == 15007 then target = "Ghost" -- Resurrection sickness (debug)
								end
							end
						end
					end
					if target and target ~= "" then
						LeaPlusLC:ShowSystemEditBox("/tar" .. " " .. target, true)
						LeaPlusLC.FactoryEditBox.f:SetText(L["Myza's Oasis"] .. ": " .. target)
					end
				end
				return
			elseif str == "mem" or str == "m" then
				-- Show addon panel with memory usage
				if LeaPlusLC.ShowMemoryUsage then
					LeaPlusLC:ShowMemoryUsage(LeaPlusLC["Page8"], "TOPLEFT", 146, -262)
				end
				-- Prevent options panel from showing if Blizzard Store is showing
				if StoreFrame and StoreFrame:GetAttribute("isshown") then return end
				-- Toggle the options panel if game options panel is not showing
				if LeaPlusLC:IsPlusShowing() then
					LeaPlusLC:HideFrames()
					LeaPlusLC:HideConfigPanels()
				else
					LeaPlusLC:HideFrames()
					LeaPlusLC["PageF"]:Show()
				end
				LeaPlusLC["Page"..LeaPlusLC["LeaStartPage"]]:Show()
				return
			elseif str == "gossinfo" then
				-- Print gossip frame information
				if GossipFrame:IsShown() then
					local npcName = UnitName("npc")
					local npcGuid = UnitGUID("npc") or nil
					if npcName and npcGuid then
						local void, void, void, void, void, npcID = strsplit("-", npcGuid)
						if npcID then
							LeaPlusLC:Print(npcName .. ": |cffffffff" .. npcID)
						end
					end
					LeaPlusLC:Print("Available quests: |cffffffff" .. C_GossipInfo.GetNumAvailableQuests())
					LeaPlusLC:Print("Active quests: |cffffffff" .. C_GossipInfo.GetNumActiveQuests())
					local gossipInfoTable = C_GossipInfo.GetOptions()
					if gossipInfoTable and gossipInfoTable[1] and gossipInfoTable[1].name then
						LeaPlusLC:Print("Gossip count: |cffffffff" .. #gossipInfoTable)
						LeaPlusLC:Print("Gossip name: |cffffffff" .. gossipInfoTable[1].name)
					else
						LeaPlusLC:Print("Gossip info: |cffffffff" .. "Nil")
					end
					if GossipTitleButton1 and GossipTitleButton1:GetText() then
						LeaPlusLC:Print("First option: |cffffffff" .. GossipTitleButton1:GetText())
					end
					-- LeaPlusLC:Print("Gossip text: |cffffffff" .. GetGossipText())
					if not IsShiftKeyDown() then
						SelectGossipOption(1)
					end
				else
					LeaPlusLC:Print("Gossip frame not open.")
				end
				return
			elseif str == "traits" then
				-- Set dragonriding traits
				if C_AddOns.IsAddOnLoaded("Blizzard_GenericTraitUI") and GenericTraitFrame:IsShown() then
					local c = C_Traits.GetConfigIDBySystemID(1)
					for count = 1, 10 do
						for i, n in ipairs(C_Traits.GetTreeNodes(672)) do
							local f = C_Traits.GetNodeInfo(c, n)
							if #f.entryIDs < 2 then
								-- One trait only
								C_Traits.PurchaseRank(c, n)
							else
								-- Two trait choices
								C_Traits.SetSelection(c, n, f.entryIDs[2]) -- 1 for left-side trait, 2 for right-side trait
							end
						end
					end
					-- Save changes
					C_Traits.CommitConfig(c)
					-- Reload to clear everything
					ReloadUI()
				else
					LeaPlusLC:Print("Open the dragonriding trait frame first!")
				end
				return
			elseif str == "talents" or str == "tal" then
				-- Ensure the talents window is loaded
				if not PlayerSpellsFrame then
					LeaPlusLC:Print("Open the talents window first.")
					return
				end
				-- Get player class
				local void, class = UnitClass("player")
				local importStream
				if class == "PALADIN" then
					importStream = ExportUtil.MakeImportDataStream("BIEAomTTpSA9oX6huYLb5nP3r3iWSi2BSIlkIlWLRCJkIBAAIAAAAAAAgikkkQiQCRgWiAAAAABBA")
				elseif class == "WARLOCK" then
					importStream = ExportUtil.MakeImportDataStream("BsQAj5LiEN4VXhSin5RcWeAUgoIhIJSCBBkSSSCFQS0SSItkEEAAAAAAAAAAAAIEaJJJA")
				elseif class == "PRIEST" then
					importStream = ExportUtil.MakeImportDataStream("BEQA/KVNHBYFUG61hTBXiMbcYCAAAAAAAokCCkQEJhkkkSUSoEAAAAAl0IkEJgSSSSQISCBlAA")
				else
					return
				end
				-- Delete the loadout called Mine
				local activeSpecID = C_SpecializationInfo.GetSpecialization()
				local specID = C_SpecializationInfo.GetSpecializationInfo(activeSpecID)
				local configs = C_ClassTalents.GetConfigIDsBySpecID(specID)
				for void, configID in ipairs(configs) do
					local configInfo = C_Traits.GetConfigInfo(configID)
					if configInfo.name == "Mine" then
						C_ClassTalents.DeleteConfig(configID)
					end
				end
				-- Create a new loadout called Mine
				local headerValid, serializationVersion, specID, treeHash = PlayerSpellsFrame.TalentsFrame:ReadLoadoutHeader(importStream)

				local treeInfo = PlayerSpellsFrame.TalentsFrame:GetTreeInfo()
				local configID = PlayerSpellsFrame.TalentsFrame:GetConfigID()

				local loadoutContent = PlayerSpellsFrame.TalentsFrame:ReadLoadoutContent(importStream, treeInfo.ID)
				local loadoutEntryInfo = PlayerSpellsFrame.TalentsFrame:ConvertToImportLoadoutEntryInfo(configID, treeInfo.ID, loadoutContent)

				local newConfigHasPurchasedRanks = #loadoutEntryInfo > 0
				local configInfo = C_Traits.GetConfigInfo(configID)
				local success, errorString = C_ClassTalents.ImportLoadout(configID, loadoutEntryInfo, "Mine")
				PlayerSpellsFrame.TalentsFrame:OnTraitConfigCreateStarted(newConfigHasPurchasedRanks)
				-- Add reload button
				if not LeaPlusLC.TalentsReloadButton then
					local reloadButton = LeaPlusLC:CreateButton("TalentsReloadButton", PlayerSpellsFrame.TalentsFrame, ">>> RELOAD <<<", "BOTTOM", 0, 10, 200, 45, true, "")
					reloadButton:ClearAllPoints()
					reloadButton:SetPoint("LEFT", PlayerSpellsFrame.TalentsFrame.ResetButton, "RIGHT", 60, -4)
					reloadButton:SetScript("OnClick", ReloadUI)
					reloadButton:Hide(); reloadButton:Show()
					LeaPlusLC.TalentsReloadButton = reloadButton
				end
				return
			elseif str == "svars" then
				-- Print saved variables
				LeaPlusLC:Print(L["Saved Variables"] .. "|n")
				LeaPlusLC:Print(L["The following list shows option label, setting name and currently saved value.  Enable |cffffffffIncrease chat history|r (chat) and |cffffffffRecent chat window|r (chat) to make it easier."] .. "|n")
				LeaPlusLC:Print(L["Modifying saved variables must start with |cffffffff/ltp nosave|r to prevent your changes from being reverted during reload or logout."] .. "|n")
				LeaPlusLC:Print(L['Syntax is |cffffffff/run LeaPlusDB[' .. '"' .. 'setting name' .. '"' .. '] = ' .. '"' .. 'value' .. '" |r(case sensitive).'])
				LeaPlusLC:Print(L["When done, |cffffffff/reload|r to save your changes."] .. "|n")
				-- Checkboxes
				LeaPlusLC:Print(L["Checkboxes"] .. "|n")
				LeaPlusLC:Print(L["Checkboxes can be set to On or Off."] .. "|n")
				for key, value in pairs(LeaPlusDB) do
					if LeaPlusCB[key] and LeaPlusCB[key].f then
						if LeaPlusCB[key]:GetObjectType() ~= "Slider" and LeaPlusCB[key]:GetObjectType() ~= "Button" then
							LeaPlusLC:Print(string.gsub(LeaPlusCB[key].f:GetText(), "%*$", "") .. ": |cffffffff" .. key .. "|r |cff1eff0c(" .. value .. ")|r")
						end
					end
				end
				-- Sliders
				LeaPlusLC:Print("|n" .. L["Sliders"] .. "|n")
				LeaPlusLC:Print(L["Sliders can be set to a numeric value which must be in the range supported by the slider."] .. "|n")
				for key, value in pairs(LeaPlusDB) do
					if LeaPlusCB[key] and LeaPlusCB[key].f then
						if LeaPlusCB[key]:GetObjectType() == "Slider" then
							LeaPlusLC:Print("Slider: " .. "|cffffffff" .. key .. "|r |cff1eff0c(" .. value .. ")|r" .. " (" .. string.gsub(LeaPlusCB[key].f:GetText(), "%*$", "") .. ")" )
						end
					end
				end
				-- Dropdowns
				LeaPlusLC:Print("|n" .. L["Dropdowns"] .. "|n")
				LeaPlusLC:Print(L["Dropdowns can be set to a numeric value which must be in the range supported by the dropdown."] .. "|n")
				for key, value in pairs(LeaPlusDB) do
					if LeaPlusCB[key] and LeaPlusCB[key]:GetObjectType() == "Button" and LeaPlusLC[key] then
						LeaPlusLC:Print("Dropdown: " .. "|cffffffff" .. key .. "|r |cff1eff0c(" .. value .. ")|r")
					end
				end
				return
			elseif str == "tags" then
				-- Print open menu tags (such as dropdown menus)
				Menu.PrintOpenMenuTags()
				return
			elseif str == "editmode" then
				-- Open Edit Mode (useful for new player experience)
				if not LeaPlusLC:PlayerInCombat() then
					RunScript('ShowUIPanel(EditModeManagerFrame)')
				end
				return
			elseif str == "taintmap" then
				-- TaintMap
				if LeaPlusLC.TaintMap then
					LeaPlusLC.TaintMap:Cancel()
					LeaPlusLC.TaintMap = nil
					LeaPlusLC:Print("TaintMap stopped.")
					return
				end
				LeaPlusLC.TaintMap = C_Timer.NewTicker(1, function()
					for k,v in pairs(WorldMapFrame) do
						local ok, who = issecurevariable(WorldMapFrame, k)
						if not ok then
							print("Tainted:", k, "by", who or "unknown")
						end
					end
				end)
				LeaPlusLC:Print("TaintMap started.")
				return
			elseif str == "forced" then
				-- Enable all addon restrictions
				-- Example: /run ChatFrame1:SetMaxLines(4096) and whisper yourself
				SetCVar("addonMapRestrictionsForced", "1")
				SetCVar("addonChatRestrictionsForced", "1")
				SetCVar("addonCombatRestrictionsForced", "1")
				SetCVar("addonPvPMatchRestrictionsForced", "1")
				SetCVar("addonEncounterRestrictionsForced", "1")
				SetCVar("addonChallengeModeRestrictionsForced", "1")
				LeaPlusLC:Print("Addon restrictions are now enforced.")
				return
			elseif str == "unforced" then
				-- Remove all addon restrictions
				SetCVar("addonMapRestrictionsForced", "0")
				SetCVar("addonChatRestrictionsForced", "0")
				SetCVar("addonCombatRestrictionsForced", "0")
				SetCVar("addonPvPMatchRestrictionsForced", "0")
				SetCVar("addonEncounterRestrictionsForced", "0")
				SetCVar("addonChallengeModeRestrictionsForced", "0")
				LeaPlusLC:Print("Addon restrictions are no longer enforced.")
				return
			elseif str == "flightpopup" then
				-- Show a sample flight time report window
				if LeaPlusLC.ShowFlightReportTest then
					LeaPlusLC.ShowFlightReportTest()
				else
					LeaPlusLC:Print("Show flight times is not enabled.")
				end
				return
			elseif str == "checkglobal" then
				-- Print global frame names created by the addon
				local c = 0
				for k, v in pairs(_G) do
					if type(k) == "string" and type(v) == "table" then
						local void, a = issecurevariable(k)
						if a == "Leatrix_Plus" then
							c = c + 1
							print(k)
						end
					end
				end
				print(c,"global tables/frames")
				return
			elseif str == "admin" then
				-- Preset profile (used for testing)
				LpEvt:UnregisterAllEvents()						-- Prevent changes
				wipe(LeaPlusDB)									-- Wipe settings
				LeaPlusLC:PlayerLogout(true)					-- Reset permanent settings
				-- Automation
				LeaPlusDB["AutomateQuests"] = "On"				-- Automate quests
				LeaPlusDB["AutoQuestShift"] = "Off"				-- Automate quests requires shift
				LeaPlusDB["AutoQuestRegular"] = "On"			-- Accept regular quests
				LeaPlusDB["AutoQuestDaily"] = "On"				-- Accept daily quests
				LeaPlusDB["AutoQuestWeekly"] = "On"				-- Accept weekly quests
				LeaPlusDB["AutoQuestCompleted"] = "On"			-- Turn-in completed quests
				LeaPlusDB["AutoQuestKeyMenu"] = 1				-- Automate quests override key
				LeaPlusDB["AutomateGossip"] = "On"				-- Automate gossip
				LeaPlusDB["AutoAcceptSummon"] = "On"			-- Accept summon
				LeaPlusDB["AutoAcceptRes"] = "On"				-- Accept resurrection
				LeaPlusDB["AutoReleasePvP"] = "On"				-- Release in PvP
				LeaPlusDB["AutoSellJunk"] = "On"				-- Sell junk automatically
				LeaPlusDB["AutoSellExcludeList"] = ""			-- Sell junk exclusions list
				LeaPlusDB["AutoRepairGear"] = "On"				-- Repair automatically

				-- Social
				LeaPlusDB["NoDuelRequests"] = "On"				-- Block duels
				LeaPlusDB["NoPartyInvites"] = "Off"				-- Block party invites
				LeaPlusDB["NoRequestedInvites"] = "Off"			-- Block requested invites
				LeaPlusDB["NoFriendRequests"] = "Off"			-- Block friend requests
				LeaPlusDB["NoSharedQuests"] = "Off"				-- Block shared quests

				LeaPlusDB["AcceptPartyFriends"] = "On"			-- Party from friends
				LeaPlusDB["InviteFromWhisper"] = "On"			-- Invite from whispers
				LeaPlusDB["InviteFriendsOnly"] = "On"			-- Restrict invites to friends
				LeaPlusDB["FriendlyCommunities"] = "On"			-- Friendly communities
				LeaPlusDB["FriendlyGuild"] = "On"				-- Friendly guild

				-- Chat
				LeaPlusDB["UseEasyChatResizing"] = "On"			-- Use easy resizing
				LeaPlusDB["NoCombatLogTab"] = "On"				-- Hide the combat log
				LeaPlusDB["NoChatButtons"] = "On"				-- Hide chat buttons
				LeaPlusDB["ShowVoiceButtons"] = "On"			-- Show voice buttons
				LeaPlusDB["ShowChatMenuButton"] = "Off"			-- Show chat menu button
				LeaPlusDB["NoSocialButton"] = "On"				-- Hide social button
				LeaPlusDB["UnclampChat"] = "On"					-- Unclamp chat frame
				LeaPlusDB["MoveChatEditBoxToTop"] = "On"		-- Move editbox to top
				LeaPlusDB["MoreChatFontSizes"] = "On"			-- More chat font sizes

				LeaPlusDB["NoStickyChat"] = "On"				-- Disable sticky chat
				LeaPlusDB["UseArrowKeysInChat"] = "On"			-- Use arrow keys in chat
				LeaPlusDB["NoChatFade"] = "On"					-- Disable chat fade
				LeaPlusDB["UnivGroupColor"] = "On"				-- Universal group color
				LeaPlusDB["RecentChatWindow"] = "On"			-- Recent chat window
				LeaPlusDB["RecentChatSize"] = 170				-- Recent chat size
				LeaPlusDB["FilterChatMessages"] = "On"			-- Filter chat messages
				LeaPlusDB["BlockSpellLinks"] = "On"				-- Block spell links
				LeaPlusDB["BlockDrunkenSpam"] = "On"			-- Block drunken spam
				LeaPlusDB["BlockDuelSpam"] = "On"				-- Block duel spam
				LeaPlusDB["RestoreChatMessages"] = "On"			-- Restore chat messages

				-- Text
				LeaPlusDB["HideErrorMessages"] = "On"			-- Hide error messages
				LeaPlusDB["NoHitIndicators"] = "On"				-- Hide portrait numbers
				LeaPlusDB["HideKeybindText"] = "On"				-- Hide keybind text
				LeaPlusDB["HideMacroText"] = "On"				-- Hide macro text

				LeaPlusDB["QuestFontChange"] = "On"				-- Resize quest text
				LeaPlusDB["LeaPlusQuestFontSize"] = 18			-- Quest font size

				-- Interface
				LeaPlusDB["MinimapModder"] = "On"				-- Enhance minimap
				LeaPlusDB["SquareMinimap"] = "On"				-- Square minimap
				LeaPlusDB["HideMiniAddonMenu"] = "On"			-- Hide addon menu
				LeaPlusDB["UnclampMinimap"] = "On"				-- Unclamp minimap cluster
				LeaPlusDB["MinimapButtonBag"] = "On"			-- Minimap button bag
				LeaPlusDB["MiniExcludeList"] = "BugSack, Leatrix_Plus" -- Excluded addon list
				LeaPlusDB["MinimapBorderWidth"] = 3				-- Minimap border width
				LeaPlusDB["MiniClusterScale"] = 1				-- Minimap cluster scale
				LeaPlusDB["MinimapEffect"] = 1					-- Minimap effect

				LeaPlusDB["TipModEnable"] = "On"				-- Enhance tooltip
				LeaPlusDB["TipBackSimple"] = "On"				-- Color backdrops
				LeaPlusDB["LeaPlusTipSize"] = 1.25				-- Tooltip scale slider
				LeaPlusDB["TooltipAnchorMenu"] = 1				-- Tooltip anchor
				LeaPlusDB["TipCursorX"] = 0						-- X offset
				LeaPlusDB["TipCursorY"] = 0						-- Y offset
				LeaPlusDB["EnhanceDressup"] = "On"				-- Enhance dressup
				LeaPlusDB["DressupMoreZoomOut"] = "Off"			-- Enhance dressup increase zoom out distance
				LeaPlusDB["DressupTransmogAnim"] = "Off"		-- Enhance dressup transmogrify animation control
				LeaPlusDB["DressupFasterZoom"] = 3				-- Dressup zoom speed

				LeaPlusDB["EnhanceFlightMap"] = "On"			-- Enhance flight map
				LeaPlusDB["LeaPlusTaxiMapScale"] = 1			-- Enhance flight map scale
				LeaPlusDB["LeaPlusTaxiIconSize"] = 16			-- Enhance flight icon size
				LeaPlusDB["FlightMapA"] = "TOPLEFT"				-- Enhance flight map anchor
				LeaPlusDB["FlightMapR"] = "TOPLEFT"				-- Enhance flight map relative
				LeaPlusDB["FlightMapX"] = 16					-- Enhance flight map X
				LeaPlusDB["FlightMapX"] = -48					-- Enhance flight map Y

				LeaPlusDB["ShowVolume"] = "On"					-- Show volume slider
				LeaPlusDB["DurabilityStatus"] = "On"			-- Show durability status
				LeaPlusDB["ShowRaidToggle"] = "On"				-- Show raid toggle button
				LeaPlusDB["ShowTrainAllButton"] = "On"			-- Show train all button
				LeaPlusDB["ShowBorders"] = "On"					-- Show borders
				LeaPlusDB["ShowPlayerChain"] = "On"				-- Show player chain
				LeaPlusDB["PlayerChainMenu"] = 1				-- Player chain style
				LeaPlusDB["ShowDruidPowerBar"] = "On"			-- Show druid power bar
				LeaPlusDB["ShowReadyTimer"] = "On"				-- Show ready timer
				LeaPlusDB["ShowRangeColoring"] = "On"			-- Show range coloring
				LeaPlusDB["ShowInfoCards"] = "On"				-- Show info cards
				LeaPlusDB["InfoCardKey"] = "CTRL-A"				-- Info card key
				LeaPlusDB["ShowWowheadLinks"] = "On"			-- Show Wowhead links
				LeaPlusDB["WowheadLinkComments"] = "On"			-- Show Wowhead links to comments

				-- Interface: Manage frames
				LeaPlusDB["ManageWidgetTop"] = "On"				-- Manage widget top
				LeaPlusDB["WidgetTopA"] = "TOP"					-- Manage widget top anchor
				LeaPlusDB["WidgetTopR"] = "TOP"					-- Manage widget top relative
				LeaPlusDB["WidgetTopX"] = 0						-- Manage widget top position X
				LeaPlusDB["WidgetTopY"] = -432					-- Manage widget top position Y
				LeaPlusDB["WidgetTopScale"] = 1.25				-- Manage widget top scale

				LeaPlusDB["ClassColFrames"] = "On"				-- Class colored frames
				LeaPlusDB["ClassColPlayerBorder"] = "On"			-- Player border in class color
				LeaPlusDB["ClassColTargetBorder"] = "On"			-- Target border in class color
				LeaPlusDB["ClassColChain"] = "On"				-- Chain in class color

				LeaPlusDB["NoAlerts"] = "On"					-- Hide alerts
				LeaPlusDB["HideCleanupBtns"] = "On"				-- Hide cleanup buttons
				LeaPlusDB["HideBossBanner"] = "On"				-- Hide boss banner
				LeaPlusDB["HideEventToasts"] = "On"				-- Hide event toasts
				LeaPlusDB["NoClassBar"] = "On"					-- Hide stance bar
				LeaPlusDB["NoRestedSleep"] = "On"				-- Hide rested sleep

				-- System
				LeaPlusDB["NoDrunkenHaze"] = "On"				-- Disable drunken haze
				LeaPlusDB["NoScreenEffects"] = "On"				-- Disable screen effects
				LeaPlusDB["SetWeatherDensity"] = "On"			-- Set weather density
				LeaPlusDB["WeatherLevel"] = 0					-- Weather density level
				LeaPlusDB["MaxCameraZoom"] = "On"				-- Max camera zoom
				LeaPlusDB["NoRestedEmotes"] = "On"				-- Silence rested emotes
				LeaPlusDB["KeepAudioSynced"] = "On"				-- Keep audio synced
				LeaPlusDB["MuteGameSounds"] = "On"				-- Mute game sounds
				LeaPlusDB["MuteMountSounds"] = "On"				-- Mute mount sounds
				LeaPlusDB["MuteCustomSounds"] = "On"			-- Mute custom sounds
				LeaPlusDB["MuteCustomList"] = ""				-- Mute custom sounds list

				LeaPlusDB["NoRaidRestrictions"] = "On"			-- Remove raid restrictions
				LeaPlusDB["NoConfirmLoot"] = "On"				-- Disable loot warnings
				LeaPlusDB["FasterLooting"] = "On"				-- Faster auto loot
				LeaPlusDB["LeaPlusFasterLootDelay"] = 0.3		-- Faster loot delay

				LeaPlusDB["FasterMovieSkip"] = "On"				-- Faster movie skip
				LeaPlusDB["CombatPlates"] = "On"				-- Combat plates
				LeaPlusDB["EasyItemDestroy"] = "On"				-- Easy item destroy
				LeaPlusDB["NoTransforms"] = "On"				-- Remove transforms

				LeaPlusDB["ShowFlightTimes"] = "On"				-- Show flight times
				LeaPlusDB["FlightBarBackground"] = "Off"		-- Show flight times bar background
				LeaPlusDB["FlightBarDestination"] = "On"		-- Show flight times bar destination
				LeaPlusDB["FlightBarFillBar"] = "Off"			-- Show flight times bar fill mode
				LeaPlusDB["FlightBarSpeech"] = "On"				-- Show flight times bar speech
				LeaPlusDB["FlightBarContribute"] = "On"			-- Show flight times contribute

				-- Settings
				LeaPlusDB["SetEditModeLayout"] = "On"			-- Set edit mode layout
				LeaPlusDB["EditModeLayoutName"] = "Main"		-- Edit mode layout name
				LeaPlusDB["SimpleAddonListing"] = "On"			-- Simple addon listing

				-- Mute game sounds (LeaPlusLC["MuteGameSounds"])
				for k, v in pairs(LeaPlusLC["muteTable"]) do
					LeaPlusDB[k] = "On"
				end
				LeaPlusDB["MuteReady"] = "Off"	-- Mute ready check
				LeaPlusDB["MuteVigor"] = "Off"	-- Mute vigor

				-- Mute mount sounds (LeaPlusLC["MuteMountSounds"])
				for k, v in pairs(LeaPlusLC["mountTable"]) do
					LeaPlusDB[k] = "On"
				end

				-- Remove transforms (LeaPlusLC["NoTransforms"])
				for k, v in pairs(LeaPlusLC["transTable"]) do
					LeaPlusDB[k] = "On"
				end

				-- Set chat font sizes
				for i = 1, 50 do if _G["ChatFrame" .. i] then FCF_SetChatWindowFontSize(self, _G["ChatFrame" .. i], 18) end end

				-- Reload
				ReloadUI()
			else
				LeaPlusLC:Print("Invalid parameter.")
			end
			return
		else
			-- Prevent options panel from showing if Blizzard Store is showing
			if StoreFrame and StoreFrame:GetAttribute("isshown") then return end
			-- Toggle the options panel if game options panel is not showing
			if LeaPlusLC:IsPlusShowing() then
				LeaPlusLC:HideFrames()
				LeaPlusLC:HideConfigPanels()
			else
				LeaPlusLC:HideFrames()
				LeaPlusLC["PageF"]:Show()
			end
			LeaPlusLC["Page"..LeaPlusLC["LeaStartPage"]]:Show()
		end
	end

	-- Slash command for global function
	_G.SLASH_Leatrix_Plus1 = "/ltp"
	_G.SLASH_Leatrix_Plus2 = "/leaplus"

	SlashCmdList["Leatrix_Plus"] = function(self)
		-- Run slash command function
		LeaPlusLC:SlashFunc(self)
	end

	-- Slash command for UI reload
	_G.SLASH_LEATRIX_PLUS_RL1 = "/rl"
	SlashCmdList["LEATRIX_PLUS_RL"] = function()
		ReloadUI()
	end

----------------------------------------------------------------------
-- 	L90: Create options panel pages (no content yet)
----------------------------------------------------------------------

	-- Function to add menu button
	function LeaPlusLC:MakeMN(name, text, parent, anchor, x, y, width, height)

		local mbtn = CreateFrame("Button", nil, parent)
		LeaPlusLC[name] = mbtn
		mbtn:Show();
		mbtn:SetSize(width, height)
		mbtn:SetAlpha(1.0)
		mbtn:SetPoint(anchor, x, y)

		mbtn.t = mbtn:CreateTexture(nil, "BACKGROUND")
		mbtn.t:SetAllPoints()
		mbtn.t:SetColorTexture(0.3, 0.3, 0.00, 0.8)
		mbtn.t:SetAlpha(0.7)
		mbtn.t:Hide()

		mbtn.s = mbtn:CreateTexture(nil, "BACKGROUND")
		mbtn.s:SetAllPoints()
		mbtn.s:SetColorTexture(0.3, 0.3, 0.00, 0.8)
		mbtn.s:Hide()

		mbtn.f = mbtn:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		mbtn.f:SetPoint('LEFT', 16, 0)
		mbtn.f:SetText(L[text])

		mbtn:SetScript("OnEnter", function()
			mbtn.t:Show()
		end)

		mbtn:SetScript("OnLeave", function()
			mbtn.t:Hide()
		end)

		return mbtn, mbtn.s

	end

	-- Function to create individual options panel pages
	function LeaPlusLC:MakePage(name, title, menu, menuname, menuparent, menuanchor, menux, menuy, menuwidth, menuheight)

		-- Create frame
		local oPage = CreateFrame("Frame", nil, LeaPlusLC["PageF"])
		LeaPlusLC[name] = oPage
		oPage:SetAllPoints(LeaPlusLC["PageF"])
		oPage:Hide()

		-- Add page title
		oPage.s = oPage:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
		oPage.s:SetPoint('TOPLEFT', 146, -16)
		oPage.s:SetText(L[title])

		-- Add menu item if needed
		if menu then
			LeaPlusLC[menu], LeaPlusLC[menu .. ".s"] = LeaPlusLC:MakeMN(menu, menuname, menuparent, menuanchor, menux, menuy, menuwidth, menuheight)
			LeaPlusLC[name]:SetScript("OnShow", function() LeaPlusLC[menu .. ".s"]:Show(); end)
			LeaPlusLC[name]:SetScript("OnHide", function() LeaPlusLC[menu .. ".s"]:Hide(); end)
		end

		return oPage

	end

	-- Create options pages
	LeaPlusLC["Page0"] = LeaPlusLC:MakePage("Page0", "Home"			, "LeaPlusNav0", "Home"			, LeaPlusLC["PageF"], "TOPLEFT", 16, -72, 112, 20)
	LeaPlusLC["Page1"] = LeaPlusLC:MakePage("Page1", "Automation"	, "LeaPlusNav1", "Automation"	, LeaPlusLC["PageF"], "TOPLEFT", 16, -112, 112, 20)
	LeaPlusLC["Page2"] = LeaPlusLC:MakePage("Page2", "Social"		, "LeaPlusNav2", "Social"		, LeaPlusLC["PageF"], "TOPLEFT", 16, -132, 112, 20)
	LeaPlusLC["Page3"] = LeaPlusLC:MakePage("Page3", "Chat"			, "LeaPlusNav3", "Chat"			, LeaPlusLC["PageF"], "TOPLEFT", 16, -152, 112, 20)
	LeaPlusLC["Page4"] = LeaPlusLC:MakePage("Page4", "Text"			, "LeaPlusNav4", "Text"			, LeaPlusLC["PageF"], "TOPLEFT", 16, -172, 112, 20)
	LeaPlusLC["Page5"] = LeaPlusLC:MakePage("Page5", "Interface"	, "LeaPlusNav5", "Interface"	, LeaPlusLC["PageF"], "TOPLEFT", 16, -192, 112, 20)
	LeaPlusLC["Page6"] = LeaPlusLC:MakePage("Page6", "Frames"		, "LeaPlusNav6", "Frames"		, LeaPlusLC["PageF"], "TOPLEFT", 16, -212, 112, 20)
	LeaPlusLC["Page7"] = LeaPlusLC:MakePage("Page7", "System"		, "LeaPlusNav7", "System"		, LeaPlusLC["PageF"], "TOPLEFT", 16, -232, 112, 20)
	LeaPlusLC["Page8"] = LeaPlusLC:MakePage("Page8", "Settings"		, "LeaPlusNav8", "Settings"		, LeaPlusLC["PageF"], "TOPLEFT", 16, -272, 112, 20)
	LeaPlusLC["Page9"] = LeaPlusLC:MakePage("Page9", "Media"		, "LeaPlusNav9", "Media"		, LeaPlusLC["PageF"], "TOPLEFT", 16, -292, 112, 20)

	-- Page navigation mechanism
	for i = 0, LeaPlusLC["NumberOfPages"] do
		LeaPlusLC["LeaPlusNav"..i]:SetScript("OnClick", function()
			LeaPlusLC:HideFrames()
			LeaPlusLC["PageF"]:Show()
			LeaPlusLC["Page"..i]:Show()
			LeaPlusLC["LeaStartPage"] = i
		end)
	end

	----------------------------------------------------------------------
	-- 	Options search
	----------------------------------------------------------------------

	do

		local PageF = LeaPlusLC["PageF"]
		local numPages = LeaPlusLC["NumberOfPages"]
		local rowHeight = 20
		local cogTip = L["Click to configure the settings for this option."]

		----------------------------------------------------------------------
		-- Results page
		----------------------------------------------------------------------

		local results = CreateFrame("Frame", nil, PageF)
		results:SetAllPoints(PageF)
		results:Hide()

		-- Page title and result count
		results.s = results:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		results.s:SetPoint("TOPLEFT", 146, -16)
		results.s:SetText(L["Search results"])

		results.c = results:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		results.c:SetPoint("TOPLEFT", PageF.v, "TOPLEFT", 130, 0)
		results.c:SetJustifyH("LEFT")

		-- Hide results when any options page is shown
		for i = 0, numPages do
			if LeaPlusLC["Page" .. i] then
				LeaPlusLC["Page" .. i]:HookScript("OnShow", function() results:Hide() end)
			end
		end

		-- Scrolling list (same style as the scrolling configuration panels)
		local backFrame = CreateFrame("Frame", nil, results, "BackdropTemplate")
		backFrame:SetPoint("TOPLEFT", 146, -68)
		backFrame:SetPoint("BOTTOMRIGHT", -16, 58)
		backFrame:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"})
		backFrame:SetBackdropColor(0, 0, 1, 0.5)

		-- Scroll frame is inset so the links and their highlight stay inside the darker box
		local scrollFrame = CreateFrame("ScrollFrame", nil, backFrame, "LeaPlusConfigurationPanelScrollFrameTemplate")
		local scrollChild = CreateFrame("Frame", nil, scrollFrame)
		scrollChild:SetSize(1, 1)
		scrollFrame:SetScrollChild(scrollChild)
		scrollFrame:SetPoint("TOPLEFT", 6, -6)
		scrollFrame:SetPoint("BOTTOMRIGHT", -29, 6)
		scrollFrame:SetPanExtent(rowHeight)

		-- Scroll for more message (only shown when the list is longer than the panel)
		local moreMessage = LeaPlusLC:MakeTx(results, "(scroll the list for more)", 16, 0)
		moreMessage:ClearAllPoints()
		moreMessage:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 28, 24)
		moreMessage:Hide()

		----------------------------------------------------------------------
		-- Search index (options on the main pages and settings in the configuration panels)
		----------------------------------------------------------------------

		local index, otherPanels

		-- Remove color codes, line breaks and reload asterisks, and make lower case
		local function Clean(text)
			text = (text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|n", " "):gsub("%*", "")
			return strtrim(string.lower(text))
		end

		-- Find the configuration button (cogwheel) for an option (created by CfgBtn as a child of the checkbox)
		local function FindCog(cb)
			for i, child in ipairs({cb:GetChildren()}) do
				if child:GetObjectType() == "Button" and child.t and child.tiptext == cogTip then
					return child
				end
			end
		end

		-- Find the label above a dropdown (created by CreateDropdown 20 pixels above it)
		local function DropdownLabel(dd)
			for i, region in ipairs({dd:GetRegions()}) do
				if region:GetObjectType() == "FontString" then
					local point, relativeTo, relativePoint, x, y = region:GetPoint(1)
					if relativeTo == dd and y == 20 then return region:GetText() end
				end
			end
		end

		-- Find the heading just above a slider (slider captions are used for their tooltips)
		local function SliderLabel(slider)
			local _, _, _, sx, sy = slider:GetPoint()
			if not sx or not sy then return end
			local best, bestGap
			for i, region in ipairs({slider:GetParent():GetRegions()}) do
				if region:GetObjectType() == "FontString" then
					local _, _, _, x, y = region:GetPoint(1)
					if x == sx and y and y > sy and y - sy <= 30 and (not bestGap or y - sy < bestGap) then
						best, bestGap = region:GetText(), y - sy
					end
				end
			end
			return best
		end

		local function BuildIndex()
			index, otherPanels = {}, {}

			local pageOf, isPanel = {}, {}
			for i = 1, numPages do
				if LeaPlusLC["Page" .. i] then pageOf[LeaPlusLC["Page" .. i]] = i end
			end
			for i, panel in ipairs(LeaConfigList) do isPanel[panel] = true end

			-- Find the configuration panel a control is in (controls can be inside a scroll frame)
			local function PanelOf(frame)
				local p = frame:GetParent()
				while p do
					if isPanel[p] then return p end
					p = p:GetParent()
				end
			end

			local byTitle, subsByPanel = {}, {}

			for field, w in pairs(LeaPlusCB) do
				if type(w) == "table" and w.GetObjectType then
					local objType = w:GetObjectType()
					local page = pageOf[w:GetParent()]
					if page then
						-- Option on a main page
						if objType == "CheckButton" and w.f then
							local _, _, _, x, y = w:GetPoint()
							local label = w.f:GetText() or ""
							local entry = {cb = w, cog = FindCog(w), field = field, page = page, x = x or 0, y = y or 0, label = label, pageName = LeaPlusLC["Page" .. page].s:GetText(), text = Clean(label .. " " .. (w.tiptext or "")), subs = {}}
							index[#index + 1] = entry
							byTitle[Clean(label)] = entry
						end
					else
						-- Setting in a configuration panel
						local panel = PanelOf(w)
						if panel then
							local label, isCheck
							if objType == "CheckButton" and w.f then
								label, isCheck = w.f:GetText(), true
							elseif objType == "Slider" then
								label = SliderLabel(w) or w.tiptext
							elseif objType == "DropdownButton" then
								label = DropdownLabel(w)
							end
							if label and strtrim(label) ~= "" then
								local _, _, _, x, y = w:GetPoint()
								subsByPanel[panel] = subsByPanel[panel] or {}
								tinsert(subsByPanel[panel], {target = w, panel = panel, field = isCheck and field or nil, label = label, tiptext = w.tiptext, x = x or 0, y = y or 0, text = Clean(label .. " " .. (w.tiptext or ""))})
							end
						end
					end
				end
			end

			-- Sort options in the same order as the pages (page, then column, then top to bottom)
			table.sort(index, function(a, b)
				if a.page ~= b.page then return a.page < b.page end
				if a.x ~= b.x then return a.x < b.x end
				return a.y > b.y
			end)

			-- Link each configuration panel to the option with the same name (others go under Other settings)
			for panel, subs in pairs(subsByPanel) do
				table.sort(subs, function(a, b)
					if a.y ~= b.y then return a.y > b.y end
					return a.x < b.x
				end)
				local title = panel.f and panel.f:GetText() or ""
				local parent = byTitle[Clean(title)]
				for i, sub in ipairs(subs) do sub.parent = parent end
				if parent then
					parent.subs = subs
				else
					otherPanels[#otherPanels + 1] = {panel = panel, label = title, subs = subs}
				end
			end
			table.sort(otherPanels, function(a, b) return a.label < b.label end)
		end

		----------------------------------------------------------------------
		-- Highlight an option or setting after jumping to it
		----------------------------------------------------------------------

		local flash = CreateFrame("Frame", nil, PageF)
		flash:Hide()
		flash.t = flash:CreateTexture(nil, "OVERLAY")
		flash.t:SetAllPoints()
		flash.t:SetColorTexture(1, 0.82, 0, 0.35)
		flash.t:SetBlendMode("ADD")

		local flashAnim = flash:CreateAnimationGroup()
		for i, v in ipairs({{0, 1, 0.2}, {1, 0, 0.4}, {0, 1, 0.2}, {1, 0, 0.8}}) do
			local a = flashAnim:CreateAnimation("Alpha")
			a:SetFromAlpha(v[1])
			a:SetToAlpha(v[2])
			a:SetDuration(v[3])
			a:SetOrder(i)
		end
		flashAnim:SetScript("OnFinished", function() flash:Hide() end)

		-- Flash a control (holder is the panel it's shown on)
		local function Flash(target, holder)
			flash:SetParent(holder)
			flash:SetFrameStrata(holder:GetFrameStrata())
			flash:ClearAllPoints()
			local objType = target:GetObjectType()
			if objType == "CheckButton" and target.f then
				-- Checkbox and its label
				flash:SetPoint("TOPLEFT", target, "TOPLEFT", -2, 0)
				flash:SetPoint("BOTTOMLEFT", target, "BOTTOMLEFT", -2, 0)
				flash:SetWidth(28 + math.min(target.f:GetStringWidth(), target.f:GetWidth()))
			elseif objType == "Slider" then
				-- Slider and its value
				flash:SetPoint("TOPLEFT", target, "TOPLEFT", -4, 4)
				flash:SetPoint("BOTTOMLEFT", target, "BOTTOMLEFT", -4, -4)
				flash:SetWidth(target:GetWidth() + 8 + (target.f and target.f:GetStringWidth() + 12 or 0))
			else
				-- Dropdown and its label above
				flash:SetPoint("TOPLEFT", target, "TOPLEFT", -4, 22)
				flash:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", 4, -4)
			end
			flash:SetFrameLevel(target:GetFrameLevel() + 5)
			flash:Show()
			flashAnim:Stop()
			flashAnim:Play()
		end

		-- Open an options page (used by the headings)
		local function ShowPage(page)
			LeaPlusLC:HideFrames()
			PageF:Show()
			LeaPlusLC["Page" .. page]:Show()
			LeaPlusLC["LeaStartPage"] = page
		end

		-- Open the page an option is on and highlight it
		local function ShowOption(entry)
			ShowPage(entry.page)
			Flash(entry.cb, PageF)
		end

		-- Open a configuration panel directly (used when a panel has no matching option)
		local function ShowPanel(panel)
			LeaPlusLC:HideFrames()
			LeaPlusLC:HideConfigPanels()
			panel:Show()
		end

		-- Open the configuration panel a setting is in and highlight it
		local function ShowSub(sub)
			local parent = sub.parent
			local cog = parent and parent.cog
			if cog then
				if cog:IsEnabled() and parent.cb:IsEnabled() then
					-- Use the real cogwheel so the panel is set up as normal
					GameTooltip:Hide()
					cog:Click()
				else
					-- Cogwheel is locked (option is off or needs a reload) so show the option instead
					ShowOption(parent)
					return
				end
			else
				ShowPanel(sub.panel)
			end
			if sub.panel:IsShown() then Flash(sub.target, sub.panel) end
		end

		----------------------------------------------------------------------
		-- Result list (page headings, options, and configuration panel settings underneath)
		----------------------------------------------------------------------

		local rows = {}

		local function GetRow(n)
			if rows[n] then return rows[n] end

			local row = CreateFrame("Button", nil, scrollChild)
			row:SetHeight(rowHeight)
			row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(n - 1) * rowHeight)
			row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -(n - 1) * rowHeight)

			row.hl = row:CreateTexture(nil, "BACKGROUND")
			row.hl:SetAllPoints()
			row.hl:SetColorTexture(0.3, 0.3, 0.00, 0.5)
			row.hl:Hide()

			-- Page heading
			row.h = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
			row.h:SetPoint("LEFT", 8, 0)
			row.h:SetJustifyH("LEFT")

			-- Enabled status (fixed width column on the right)
			row.e = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
			row.e:SetPoint("RIGHT", -8, 0)
			row.e:SetWidth(28)
			row.e:SetJustifyH("CENTER")

			-- Option or setting name (indent is set when the row is used)
			row.f = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
			row.f:SetJustifyH("LEFT")
			row.f:SetWordWrap(false)

			row:SetScript("OnEnter", function(self)
				self.hl:Show()
				if self.tiptext then LeaPlusLC.TipSee(self) end
			end)
			row:SetScript("OnLeave", function(self)
				self.hl:Hide()
				GameTooltip:Hide()
			end)
			row:SetScript("OnClick", function(self)
				if self.kind == "option" then
					ShowOption(self.data)
				elseif self.kind == "sub" then
					ShowSub(self.data)
				elseif self.kind == "panel" then
					ShowPanel(self.data.panel)
				elseif self.kind == "heading" and self.page then
					ShowPage(self.page)
				end
			end)

			rows[n] = row
			return row
		end

		-- Set the indent of a row's name
		local function SetIndent(row, indent)
			row.f:ClearAllPoints()
			row.f:SetPoint("LEFT", indent, 0)
			row.f:SetPoint("RIGHT", row.e, "LEFT", -8, 0)
		end

		-- Show the On or Off status for a setting
		local function SetStatus(row, field)
			if not field then row.e:Hide() return end
			if LeaPlusLC[field] == "On" then
				row.e:SetText(L["On"])
				row.e:SetTextColor(0.2, 1, 0.2)
			else
				row.e:SetText(L["Off"])
				row.e:SetTextColor(0.5, 0.5, 0.5)
			end
			row.e:Show()
		end

		----------------------------------------------------------------------
		-- Show search results
		----------------------------------------------------------------------

		local function ShowResults(query)

			if not index then BuildIndex() end

			-- Every word typed must appear in the name or tooltip
			local words = {}
			for word in string.lower(query):gmatch("%S+") do words[#words + 1] = word end

			local function Matches(text)
				for i, word in ipairs(words) do
					if not text:find(word, 1, true) then return false end
				end
				return true
			end

			-- Build the list
			local items, count, lastHeading = {}, 0, nil
			local function AddHeading(key, name, page)
				if key ~= lastHeading then
					items[#items + 1] = {kind = "heading", name = name, page = page}
					lastHeading = key
				end
			end

			-- Options and their configuration panel settings
			for i, entry in ipairs(index) do
				local optionMatch = Matches(entry.text)
				local subs = {}
				for j, sub in ipairs(entry.subs) do
					if Matches(sub.text) then subs[#subs + 1] = sub end
				end
				if optionMatch or #subs > 0 then
					AddHeading(entry.page, entry.pageName, entry.page)
					items[#items + 1] = {kind = "option", data = entry}
					if optionMatch then count = count + 1 end
					for j, sub in ipairs(subs) do
						items[#items + 1] = {kind = "sub", data = sub}
						count = count + 1
					end
				end
			end

			-- Configuration panels without a matching option
			for i, group in ipairs(otherPanels) do
				local subs = {}
				for j, sub in ipairs(group.subs) do
					if Matches(sub.text) then subs[#subs + 1] = sub end
				end
				if #subs > 0 then
					AddHeading("other", L["Other settings"])
					items[#items + 1] = {kind = "panel", data = group}
					for j, sub in ipairs(subs) do
						items[#items + 1] = {kind = "sub", data = sub}
						count = count + 1
					end
				end
			end

			-- Show the list
			for i, item in ipairs(items) do
				local row = GetRow(i)
				row.kind, row.data, row.page, row.tiptext = item.kind, item.data, nil, nil
				row.h:Hide()
				row.f:Hide()
				row.e:Hide()
				if item.kind == "heading" then
					row.page = item.page
					row.h:SetText(item.name)
					row.h:Show()
				elseif item.kind == "option" then
					SetIndent(row, 20)
					row.f:SetText(item.data.label)
					row.f:SetTextColor(1, 1, 1)
					row.f:Show()
					row.tiptext = item.data.cb.tiptext
					SetStatus(row, item.data.field)
				elseif item.kind == "panel" then
					SetIndent(row, 20)
					row.f:SetText(item.data.label)
					row.f:SetTextColor(1, 1, 1)
					row.f:Show()
				elseif item.kind == "sub" then
					SetIndent(row, 36)
					row.f:SetText(item.data.label)
					row.f:SetTextColor(0.6, 0.6, 0.6)
					row.f:Show()
					row.tiptext = item.data.tiptext
					SetStatus(row, item.data.field)
				end
				row:Show()
			end
			for i = #items + 1, #rows do
				rows[i]:Hide()
				rows[i].kind, rows[i].data, rows[i].page = nil, nil, nil
			end

			-- Size the list and scroll to the top
			scrollChild:SetWidth(scrollFrame:GetWidth())
			scrollChild:SetHeight(math.max(#items * rowHeight, 1))
			scrollFrame:SetVerticalScroll(0)
			moreMessage:SetShown(#items * rowHeight > scrollFrame:GetHeight())

			-- Result count (options and settings that matched, not context rows)
			if count == 0 then
				results.c:SetText(L["No options found."])
			elseif count == 1 then
				results.c:SetText(L["1 option found."])
			else
				results.c:SetFormattedText(L["%d options found."], count)
			end

		end

		----------------------------------------------------------------------
		-- Search box (top right of the panel)
		----------------------------------------------------------------------

		local eb = LeaPlusLC:CreateEditBox("OptionsSearchBox", PageF, 180, 40, "TOPRIGHT", -36, -12, "OptionsSearchBox", "OptionsSearchBox")
		eb:SetHeight(25)
		eb:SetFontObject("GameFontHighlight")
		eb:SetTextInsets(8, 22, 0, 0)

		-- Remove the default editbox art
		eb.f:Hide()
		for i, key in pairs({"Left", "Middle", "Mid", "Right"}) do
			if eb[key] then eb[key]:SetAlpha(0) end
		end

		-- Translucent inset that blends with the panel (dark fill and a faint outline)
		eb.bg = eb:CreateTexture(nil, "BACKGROUND")
		eb.bg:SetAllPoints()
		eb.bg:SetColorTexture(0, 0, 0, 0.35)

		-- Outline (1 pixel lines around the box)
		eb.edges = {}
		local function MakeEdge(p1, p2, horizontal)
			local edge = eb:CreateTexture(nil, "BORDER")
			edge:SetPoint(p1, eb, p1)
			edge:SetPoint(p2, eb, p2)
			if PixelUtil then
				if horizontal then PixelUtil.SetHeight(edge, 1) else PixelUtil.SetWidth(edge, 1) end
			else
				if horizontal then edge:SetHeight(1) else edge:SetWidth(1) end
			end
			eb.edges[#eb.edges + 1] = edge
		end
		MakeEdge("TOPLEFT", "TOPRIGHT", true)
		MakeEdge("BOTTOMLEFT", "BOTTOMRIGHT", true)
		MakeEdge("TOPLEFT", "BOTTOMLEFT", false)
		MakeEdge("TOPRIGHT", "BOTTOMRIGHT", false)

		-- Set outline color
		local function SetEdgeColor(r, g, b, a)
			for i, edge in pairs(eb.edges) do edge:SetColorTexture(r, g, b, a) end
		end

		-- Placeholder text
		eb.ph = eb:CreateFontString(nil, "ARTWORK", "GameFontDisable")
		eb.ph:SetPoint("LEFT", 8, 0)
		eb.ph:SetText(L["Search options"])

		-- Clear button (cross on the right, shown when there is text)
		eb.clear = CreateFrame("Button", nil, eb)
		eb.clear:SetSize(14, 14)
		eb.clear:SetPoint("RIGHT", -6, 0)
		eb.clear.t = eb.clear:CreateTexture(nil, "ARTWORK")
		eb.clear.t:SetAllPoints()
		eb.clear.t:SetTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
		eb.clear.t:SetAlpha(0.5)
		eb.clear:SetScript("OnEnter", function(self) self.t:SetAlpha(1) end)
		eb.clear:SetScript("OnLeave", function(self) self.t:SetAlpha(0.5) end)
		eb.clear:Hide()

		-- Update placeholder, clear button and outline (gold while typing, lighter on hover)
		local function UpdateBox()
			local empty = eb:GetText() == ""
			eb.ph:SetShown(empty and not eb:HasFocus())
			eb.clear:SetShown(not empty)
			if eb:HasFocus() then
				SetEdgeColor(1, 0.82, 0, 0.5)
			elseif eb:IsMouseOver() then
				SetEdgeColor(1, 1, 1, 0.3)
			else
				SetEdgeColor(1, 1, 1, 0.15)
			end
		end
		eb:HookScript("OnEditFocusGained", UpdateBox)
		eb:HookScript("OnEditFocusLost", UpdateBox)
		eb:HookScript("OnEnter", UpdateBox)
		eb:HookScript("OnLeave", UpdateBox)

		-- Return to the last options page
		local function ShowLastPage()
			results:Hide()
			local page = LeaPlusLC["Page" .. (LeaPlusLC["LeaStartPage"] or 0)]
			if page then page:Show() end
		end

		-- Clear the search and return to the last page
		local function ClearSearch()
			eb:SetText("")
			eb:ClearFocus()
			ShowLastPage()
			UpdateBox()
		end
		eb.clear:SetScript("OnClick", ClearSearch)

		-- Search as you type
		eb:SetScript("OnTextChanged", function(self, userInput)
			UpdateBox()
			if not userInput then return end
			local query = strtrim(self:GetText())
			if query == "" then
				ShowLastPage()
			else
				for i = 0, numPages do
					if LeaPlusLC["Page" .. i] then LeaPlusLC["Page" .. i]:Hide() end
				end
				results:Show()
				ShowResults(query)
			end
		end)

		-- Escape clears the search, enter takes focus off the editbox
		eb:SetScript("OnEscapePressed", ClearSearch)
		eb:SetScript("OnEnterPressed", eb.ClearFocus)

		-- Clear the search when the panel is closed or another page is chosen (index is rebuilt next time)
		PageF:HookScript("OnHide", function()
			results:Hide()
			eb:SetText("")
			eb:ClearFocus()
			UpdateBox()
			index = nil
		end)

		UpdateBox()

	end

	-- Use a variable to contain the page number (makes it easier to move options around)
	local pg;

----------------------------------------------------------------------
-- 	LC0: Welcome
----------------------------------------------------------------------

	pg = "Page0"

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Welcome to Leatrix Plus.", 146, -72)
	LeaPlusLC:MakeWD(LeaPlusLC[pg], "To begin, choose an options page.", 146, -92)

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Support", 146, -132);
	LeaPlusLC:MakeWD(LeaPlusLC[pg], "curseforge.com/wow/addons/leatrix-plus", 146, -152)

----------------------------------------------------------------------
-- 	LC1: Automation
----------------------------------------------------------------------

	pg = "Page1"

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Character"					, 	146, -72)
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutomateQuests"			,	"Automate quests"				,	146, -92, 	false,	"If checked, quests will be selected, accepted and turned-in automatically.|n|nQuests which require gold, currency, a crafting reagent or an account-bound item will not be turned-in automatically.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutomateGossip"			,	"Automate gossip"				,	146, -112, 	false,	"If checked, you can hold down the alt key while opening a gossip window to automatically select a single gossip option.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutoAcceptSummon"			,	"Accept summon"					, 	146, -132, 	false,	"If checked, summon requests will be accepted automatically unless you are in combat.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutoAcceptRes"				,	"Accept resurrection"			, 	146, -152, 	false,	"If checked, resurrection requests will be accepted automatically.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutoReleasePvP"			,	"Release in PvP"				, 	146, -172, 	false,	"If checked, you will release automatically after you die in a battleground.|n|nYou will not release automatically if you have the ability to self-resurrect.")

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Vendors"					, 	340, -72)
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutoSellJunk"				,	"Sell junk automatically"		,	340, -92, 	true,	"If checked, all grey items in your bags will be sold automatically when you visit a merchant.|n|nYou can hold the shift key down when you talk to a merchant to override this setting.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutoRepairGear"			, 	"Repair automatically"			,	340, -112, 	false,	"If checked, your gear will be repaired automatically when you visit a suitable merchant.|n|nYou can hold the shift key down when you talk to a merchant to override this setting.")

	LeaPlusLC:CfgBtn("AutomateQuestsBtn", LeaPlusCB["AutomateQuests"])
	LeaPlusLC:CfgBtn("AutoAcceptResBtn", LeaPlusCB["AutoAcceptRes"])
	LeaPlusLC:CfgBtn("AutoReleasePvPBtn", LeaPlusCB["AutoReleasePvP"])
	LeaPlusLC:CfgBtn("AutoSellJunkBtn", LeaPlusCB["AutoSellJunk"])
	LeaPlusLC:CfgBtn("AutoRepairBtn", LeaPlusCB["AutoRepairGear"])

----------------------------------------------------------------------
-- 	LC2: Social
----------------------------------------------------------------------

	pg = "Page2"

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Blocks"					, 	146, -72)
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoDuelRequests"			, 	"Block duels"					,	146, -92, 	false,	"If checked, duel requests will be blocked unless the player requesting the duel is a friend.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoPartyInvites"			, 	"Block party invites"			, 	146, -112, 	false,	"If checked, party invitations will be blocked unless the player inviting you is a friend.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoRequestedInvites"		, 	"Block requested invites"		, 	146, -132, 	false,	"If checked, requests to invite a player to your group will be declined unless the player requesting to join is a friend.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoFriendRequests"			, 	"Block friend requests"			, 	146, -152, 	false,	"If checked, BattleTag and Real ID friend requests will be automatically declined.|n|nEnabling this option will automatically decline any pending requests.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoSharedQuests"			, 	"Block shared quests"			, 	146, -172, 	false,	"If checked, shared quests will be declined unless the player sharing the quest is a friend.")

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Groups"					, 	340, -72)
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "AcceptPartyFriends"		, 	"Party from friends"			, 	340, -92, 	false,	"If checked, party invitations from friends will be automatically accepted unless you are queued in Dungeon Finder.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "InviteFromWhisper"			,   "Invite from whispers"			,	340, -112,	false,	L["If checked, a group invite will be sent to anyone who whispers you with a set keyword as long as you are ungrouped, group leader or raid assistant and not queued for a dungeon or raid.|n|nFriends who message the keyword using Battle.net will not be sent a group invite if they are appearing offline.  They need to either change their online status or use character whispers."] .. "|n|n" .. L["Keyword"] .. ": |cffffffff" .. "dummy" .. "|r")

	-- Show footer
	local FriendlyGuildFooter = LeaPlusLC:MakeFT(LeaPlusLC[pg], "For all of the social options above, you can treat guild members and members of your communities as friends too.", 146, 380, 96)
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "FriendlyGuild"				, 	"Guild"							, 	146, -282, 	false,	"If checked, members of your guild will be treated as friends for all of the options on this page.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "FriendlyCommunities"		, 	"Communities"					, 	340, -282, 	false,	"If checked, members of your communities will be treated as friends for all of the options on this page.")

	if LeaPlusCB["FriendlyGuild"].f:GetStringWidth() > 90 then
		LeaPlusCB["FriendlyGuild"].f:SetWidth(90)
	end
	if LeaPlusCB["FriendlyCommunities"].f:GetStringWidth() > 90 then
		LeaPlusCB["FriendlyCommunities"].f:SetWidth(90)
	end

	LeaPlusCB["FriendlyGuild"]:ClearAllPoints()
	LeaPlusCB["FriendlyGuild"]:SetPoint("TOPLEFT", FriendlyGuildFooter, "BOTTOMLEFT", 0, -10)
	LeaPlusCB["FriendlyCommunities"]:ClearAllPoints()
	LeaPlusCB["FriendlyCommunities"]:SetPoint("LEFT", LeaPlusCB["FriendlyGuild"], "RIGHT", LeaPlusCB["FriendlyGuild"].f:GetWidth() + 6, 0)

	LeaPlusLC:CfgBtn("InvWhisperBtn", LeaPlusCB["InviteFromWhisper"])

----------------------------------------------------------------------
-- 	LC3: Chat
----------------------------------------------------------------------

	pg = "Page3"

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Chat Frame"				, 	146, -72)
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "UseEasyChatResizing"		,	"Use easy resizing"				,	146, -92,	true,	"If checked, dragging the General chat tab will expand the chat frame upwards.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoCombatLogTab" 			, 	"Hide the combat log"			, 	146, -112, 	true,	"If checked, the combat log will be hidden.|n|nThe combat log must be docked in order for this option to work.|n|nIf the combat log is undocked, you can dock it by dragging the tab (and reloading your UI) or by resetting the chat windows (from the chat menu).")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoChatButtons"				,	"Hide chat buttons"				,	146, -132,	true,	"If checked, chat frame buttons will be hidden.|n|nClicking chat tabs will automatically show the latest messages.|n|nUse the mouse wheel to scroll through the chat history.  Hold down SHIFT for page jump or CTRL to jump to the top or bottom of the chat history.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoSocialButton"			,	"Hide social button"			,	146, -152,	true,	"If checked, the social button and quick-join notification will be hidden.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "UnclampChat"				,	"Unclamp chat frame"			,	146, -172,	true,	"If checked, you will be able to drag the chat frame to the edge of the screen.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "MoveChatEditBoxToTop" 		, 	"Move editbox to top"			,	146, -192, 	true,	"If checked, the editbox will be moved to the top of the chat frame.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "MoreChatFontSizes"		 	, 	"More chat font sizes"			,	146, -212, 	true,	"If checked, additional chat font sizes will be available in the chat font size menu.")

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Mechanics"					, 	340, -72)
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoStickyChat"				, 	"Disable sticky chat"			,	340, -92,	true,	"If checked, sticky chat will be disabled.|n|nNote that this does not apply to temporary chat windows.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "UseArrowKeysInChat"		, 	"Use arrow keys in chat"		, 	340, -112, 	true,	"If checked, you can press the arrow keys to move the insertion point left and right in the chat frame.|n|nIf unchecked, the arrow keys will use the default keybind setting.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoChatFade"				, 	"Disable chat fade"				, 	340, -132, 	true,	"If checked, chat text will not fade out after a time period.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "UnivGroupColor"			,	"Universal group color"			,	340, -152,	false,	"If checked, raid chat and instance chat will both be colored blue (to match the default party chat color).")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "RecentChatWindow"			,	"Recent chat window"			, 	340, -172, 	true,	"If checked, you can hold down the control key and click a chat tab to view recent chat in a copy-friendly window.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "FilterChatMessages"		, 	"Filter chat messages"			,	340, -192, 	true,	"If checked, you can block spell links, drunken spam and duel spam.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "RestoreChatMessages"		, 	"Restore chat messages"			,	340, -212, 	true,	"If checked, recent chat will be restored when you reload your interface.")

	LeaPlusLC:CfgBtn("NoChatButtonsBtn", LeaPlusCB["NoChatButtons"])
	LeaPlusLC:CfgBtn("FilterChatMessagesBtn", LeaPlusCB["FilterChatMessages"])

----------------------------------------------------------------------
-- 	LC4: Text
----------------------------------------------------------------------

	pg = "Page4"

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Visibility"				, 	146, -72)
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "HideErrorMessages"			, 	"Hide error messages"			,	146, -92, 	true,	"If checked, most error messages (such as 'Not enough rage') will not be shown.  Some important errors are excluded.|n|nIf you have the minimap button enabled, you can hold down the alt key and click it to toggle error messages without affecting this setting.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoHitIndicators"			, 	"Hide portrait numbers"			,	146, -112, 	true,	"If checked, damage and healing numbers in the player and pet portrait frames will be hidden.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "HideZoneText"				,	"Hide zone text"				,	146, -132, 	true,	"If checked, zone text will not be shown (eg. 'Ironforge').")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "HideKeybindText"			,	"Hide keybind text"				,	146, -152, 	true,	"If checked, keybind text will not be shown on action buttons.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "HideMacroText"				,	"Hide macro text"				,	146, -172, 	true,	"If checked, macro text will not be shown on action buttons.")

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Text Size"					, 	340, -72)
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "QuestFontChange"			,	"Resize quest text"				, 	340, -92, 	true,	"If checked, you will be able to change the font size of quest text.|n|nEnabling this option will also change the text size of other frames which inherit the same font (such as the Dungeon Finder frame).")

	LeaPlusLC:CfgBtn("QuestTextBtn", LeaPlusCB["QuestFontChange"])

----------------------------------------------------------------------
-- 	LC5: Interface
----------------------------------------------------------------------

	pg = "Page5"

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Enhancements"				, 	146, -72)
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "MinimapModder"				,	"Enhance minimap"				, 	146, -92, 	true,	"If checked, you will be able to customise the minimap.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "TipModEnable"				,	"Enhance tooltip"				,	146, -112, 	true,	"If checked, the tooltip will be color coded and you will be able to modify the tooltip layout and scale.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "EnhanceDressup"			, 	"Enhance dressup"				,	146, -132, 	true,	"If checked, gear toggle buttons will be added to the dressup frame and model positioning controls will be removed.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "EnhanceFlightMap"			, 	"Enhance flight map"			,	146, -152, 	true,	"If checked, you will be able to customise the flight map.")

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Extras"					, 	340, -72)
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowVolume"				, 	"Show volume slider"			, 	340, -92, 	true,	"If checked, a master volume slider will be shown in the character frame.|n|nThe volume slider can be placed in either of two locations in the character frame.  To toggle between them, hold the shift key down and right-click the slider.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "DurabilityStatus"			, 	"Show durability status"		, 	340, -112, 	true,	"If checked, a button will be added to the character frame which will show your equipped item durability when you hover the pointer over it.|n|nIn addition, an overall percentage will be shown in the chat frame when you die.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowRaidToggle"			, 	"Show raid button"				,	340, -132, 	true,	"If checked, the button to toggle the raid container frame will be shown just above the raid management frame (left side of the screen) instead of in the raid management frame itself.|n|nThis allows you to toggle the raid container frame without needing to open the raid management frame.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowTrainAllButton"		, 	"Show train all button"			,	340, -152, 	true,	"If checked, a button will be added to the skill trainer frame which will allow you to train all available skills instantly.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowBorders"				,	"Show borders"					,	340, -172, 	true,	"If checked, you will be able to show customisable borders around the edges of the screen.|n|nThe borders are placed on top of the game world but under the UI so you can place UI elements over them.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowPlayerChain"			, 	"Show player chain"				,	340, -192, 	true,	"If checked, you will be able to show a rare, elite or rare elite chain around the player frame.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowDruidPowerBar"			, 	"Show druid power bar"			,	340, -212, 	true,	"If checked, a power bar will be shown in the player frame when you are playing a shapeshifted druid.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowReadyTimer"			, 	"Show ready timer"				,	340, -232, 	true,	"If checked, a timer will be shown under the dungeon ready frame and the PvP encounter ready frame so that you know how long you have left to click the enter button.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowRangeColoring"			, 	"Show range coloring"			, 	340, -252, 	true,	"If checked, action button icons will be colored red for out of range and blue for not enough mana.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowInfoCards"				, 	"Show info cards"				, 	340, -272, 	true,	"If checked, you can point at almost anything and press a key to show an information card, model preview and a link to Wowhead.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowWowheadLinks"			, 	"Show Wowhead links"			, 	340, -292, 	true,	"If checked, Wowhead links will be shown in the world map frame and the legacy challenges frame.")

	LeaPlusLC:CfgBtn("ModMinimapBtn", LeaPlusCB["MinimapModder"])
	LeaPlusLC:CfgBtn("MoveTooltipButton", LeaPlusCB["TipModEnable"])
	LeaPlusLC:CfgBtn("EnhanceDressupBtn", LeaPlusCB["EnhanceDressup"])
	LeaPlusLC:CfgBtn("EnhanceFlightMapBtn", LeaPlusCB["EnhanceFlightMap"])
	LeaPlusLC:CfgBtn("ModBordersBtn", LeaPlusCB["ShowBorders"])
	LeaPlusLC:CfgBtn("ModPlayerChain", LeaPlusCB["ShowPlayerChain"])
	LeaPlusLC:CfgBtn("ShowInfoCardsBtn", LeaPlusCB["ShowInfoCards"])
	LeaPlusLC:CfgBtn("ShowWowheadLinksBtn", LeaPlusCB["ShowWowheadLinks"])

----------------------------------------------------------------------
-- 	LC6: Frames
----------------------------------------------------------------------

	pg = "Page6"

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Features"					, 	146, -72)
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ManageWidgetTop"			,	"Manage widget top"				, 	146, -92, 	true,	"If checked, you will be able to change the position and scale of the widget top frame.|n|nThe widget top frame is commonly used for showing PvP scores and tracking objectives.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ClassColFrames"			, 	"Class colored frames"			,	146, -112, 	true,	"If checked, class coloring will be used in the player frame, target frame and focus frame.")

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Visibility"				, 	340, -72)
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoAlerts"					,	"Hide alerts"					, 	340, -92, 	true,	"If checked, alert frames will not be shown.|n|nAlert frames are toast frames used for things like achievement earned, loot won, new recipe learned, new mount collected, etc.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "HideCleanupBtns"			, 	"Hide clean-up buttons"			, 	340, -112, 	true,	"If checked, the backpack clean-up button and the bank frame clean-up button will not be shown.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "HideBossBanner"			, 	"Hide boss banner"				, 	340, -132, 	true,	"If checked, the boss banner will not be shown.|n|nThe boss banner appears when a boss is defeated.  It shows the name of the boss and the loot that was distributed.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "HideEventToasts"			, 	"Hide event toasts"				, 	340, -152, 	true,	"If checked, event toasts will not be shown.|n|nEvent toasts are used for encounter objectives, level-ups, pet battle rewards, etc.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoClassBar"				,	"Hide stance bar"				, 	340, -172, 	true,	"If checked, the stance bar will not be shown.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoRestedSleep"				,	"Hide rested sleep"				, 	340, -192, 	true,	"If checked, the player frame rested sleep animation will not be shown.")

	LeaPlusLC:CfgBtn("ManageWidgetTopButton", LeaPlusCB["ManageWidgetTop"])
	LeaPlusLC:CfgBtn("ClassColFramesBtn", LeaPlusCB["ClassColFrames"])

----------------------------------------------------------------------
-- 	LC7: System
----------------------------------------------------------------------

	pg = "Page7"

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Graphics and Sound"		, 	146, -72)
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoDrunkenHaze"				, 	"Disable drunken haze"			, 	146, -92, 	false,	"If checked, the drunken haze effect will be disabled.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoScreenEffects"			, 	"Disable screen effects"		, 	146, -112, 	false,	"If checked, the grey screen of death and the netherworld effect will be disabled.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "SetWeatherDensity"			, 	"Set weather density"			, 	146, -132, 	false,	"If checked, you will be able to set the density of weather effects.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "MaxCameraZoom"				, 	"Max camera zoom"				, 	146, -152, 	false,	"If checked, you will be able to zoom out to a greater distance.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoRestedEmotes"			, 	"Silence rested emotes"			,	146, -172, 	true,	"If checked, emote sounds will be disabled while your character is resting and enabled while your character is not resting.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "KeepAudioSynced"			, 	"Keep audio synced"				,	146, -192, 	true,	"If checked, when you change the audio output device in your operating system, the game audio output device will change automatically as long as a cinematic is not playing at the time.|n|nFor this to work, the game audio output device will be set to system default.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "MuteGameSounds"			, 	"Mute game sounds"				,	146, -212, 	false,	"If checked, you will be able to mute a selection of game sounds.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "MuteMountSounds"			, 	"Mute mount sounds"				,	146, -232, 	false,	"If checked, you will be able to mute a selection of mount sounds.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "MuteCustomSounds"			, 	"Mute custom sounds"			,	146, -252, 	false,	"If checked, you will be able to mute your own choice of sounds.")

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Game Options"				, 	340, -72)
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoRaidRestrictions"		, 	"Remove raid restrictions"		,	340, -92, 	false,	"If checked, converting a party group to a raid group will succeed even if there are low level characters in the group.|n|nEveryone in the group needs to have Leatrix Plus installed with this option enabled.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoConfirmLoot"				, 	"Disable loot warnings"			,	340, -112, 	false,	"If checked, confirmations will no longer appear when you choose a loot roll option or attempt to sell or mail a tradable item.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "FasterLooting"				, 	"Faster auto loot"				,	340, -132, 	true,	"If checked, the amount of time it takes to auto loot creatures will be significantly reduced.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "FasterMovieSkip"			, 	"Faster movie skip"				,	340, -152, 	true,	"If checked, you will be able to cancel movies without being prompted for confirmation.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "CombatPlates"				, 	"Combat plates"					,	340, -172, 	true,	"If checked, enemy nameplates will be shown during combat and hidden when combat ends.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "EasyItemDestroy"			, 	"Easy item destroy"				,	340, -192, 	true,	"If checked, you will no longer need to type delete when destroying a superior quality item.|n|nIn addition, item links will be shown in all item destroy confirmation windows.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoTransforms"				, 	"Remove transforms"				, 	340, -212, 	false, 	"If checked, you will be able to have certain transforms removed automatically when they are applied to your character.|n|nYou can choose the transforms in the configuration panel.|n|nExamples include Weighted Jack-o'-Lantern and Hallowed Wand.|n|nTransforms applied during combat will be removed when combat ends.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowFlightTimes"			, 	"Show flight times"				, 	340, -232, 	true,	"If checked, flight times will be shown in the flight map and when you take a flight.")

	LeaPlusLC:CfgBtn("SetWeatherDensityBtn", LeaPlusCB["SetWeatherDensity"])
	LeaPlusLC:CfgBtn("MuteGameSoundsBtn", LeaPlusCB["MuteGameSounds"])
	LeaPlusLC:CfgBtn("MuteMountSoundsBtn", LeaPlusCB["MuteMountSounds"])
	LeaPlusLC:CfgBtn("MuteCustomSoundsBtn", LeaPlusCB["MuteCustomSounds"])
	LeaPlusLC:CfgBtn("FasterLootingBtn", LeaPlusCB["FasterLooting"])
	LeaPlusLC:CfgBtn("NoTransformsBtn", LeaPlusCB["NoTransforms"])
	LeaPlusLC:CfgBtn("ShowFlightTimesBtn", LeaPlusCB["ShowFlightTimes"])

----------------------------------------------------------------------
-- 	LC8: Settings
----------------------------------------------------------------------

	pg = "Page8"

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Addon"						, 146, -72)
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowMinimapIcon"			, "Show minimap button"				, 146, -92,		false,	"If checked, a minimap button will be available.|n|nClick - Toggle options panel.|n|nSHIFT-click - Toggle music.|n|nCTRL-click - Toggle minimap target tracking.|n|nALT-click - Toggle errors (if enabled).|n|nCTRL/SHIFT-click - Toggle windowed mode.|n|nCTRL/ALT-click - Toggle Zygor (if installed).")

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Miscellaneous"				, 146, -132)
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "SetEditModeLayout"			, "Set edit mode layout"			, 146, -152,	false,	"If checked, you can specify an edit mode layout that will always be applied when you login to any character.")
	LeaPlusLC:MakeCB(LeaPlusLC[pg], "SimpleAddonListing"		, "Simple addon listing"			, 146, -172,	true,	"If checked, the addon listing will be shown in alphabetical order without categories.")

	LeaPlusLC:CreateDropdown("AddonLanguage", "Language", 146, "TOPLEFT", LeaPlusLC[pg], "TOPLEFT", 340, -92, true, {{L["Automatic"], 1}, {L["English"], 2}, {L["Deutsch"], 3}, {L["Español (EU)"], 4}, {L["Español (AL)"], 5}, {L["Français"], 6}, {L["Italiano"], 7}, {L["Português"], 8}, {L["Русский"], 9}, {L["한국어"], 10}, {L["简体中文"], 11}, {L["繁體中文"], 12}})

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Scale", 340, -142)
	LeaPlusLC:MakeSL(LeaPlusLC[pg], "PlusPanelScale", "Drag to set the scale of the Leatrix Plus panel.", 1, 2, 0.1, 340, -162, "%.1f")

	LeaPlusLC:MakeTx(LeaPlusLC[pg], "Transparency", 340, -202)
	LeaPlusLC:MakeSL(LeaPlusLC[pg], "PlusPanelAlpha", "Drag to set the transparency of the Leatrix Plus panel.", 0, 1, 0.1, 340, -222, "%.1f")

	LeaPlusLC:CfgBtn("SetEditModeLayoutBtn", LeaPlusCB["SetEditModeLayout"])
