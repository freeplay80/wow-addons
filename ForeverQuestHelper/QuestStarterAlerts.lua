local _, helper = ...
local isSecret = issecretvalue or function() return false end
local previous

local function Announce(itemText)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd785퀘스트 도우미|r · 퀘스트 시작 아이템 획득 " .. itemText)
end

local function AnnounceStarter(questID, entry)
    if entry.link then
        Announce(entry.link)
        return
    end

    local item = Item:CreateFromItemID(entry.itemID)
    item:ContinueOnItemLoad(function()
        if previous and previous[questID] == entry and helper.IsEnabled("starterAlerts") then
            local itemText = item:GetItemLink() or item:GetItemName()
            if itemText and not isSecret(itemText) then Announce(itemText) end
        end
    end)
end

local function ScanBags()
    local present = {}
    for bag = Enum.BagIndex.Backpack, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        local slots = C_Container.GetContainerNumSlots(bag)
        if isSecret(slots) or type(slots) ~= "number" then return end
        for slot = 1, slots do
            local quest = C_Container.GetContainerItemQuestInfo(bag, slot)
            if not isSecret(quest) and quest and not isSecret(quest.questID) and not isSecret(quest.isActive)
                and type(quest.questID) == "number" and quest.questID > 0 and not quest.isActive
                and not present[quest.questID] then
                local questID = quest.questID
                local entry = previous and previous[questID]
                if not entry then
                    local itemID = C_Container.GetContainerItemID(bag, slot)
                    local link = C_Container.GetContainerItemLink(bag, slot)
                    if not isSecret(itemID) and type(itemID) == "number" then
                        entry = { itemID = itemID, link = not isSecret(link) and link or nil }
                    end
                end
                present[questID] = entry
            end
        end
    end

    local old = previous
    previous = present
    if old and helper.IsEnabled("starterAlerts") then
        for questID, entry in pairs(present) do
            if not old[questID] then AnnounceStarter(questID, entry) end
        end
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_ENTERING_WORLD" then previous = nil end
    ScanBags()
end)
