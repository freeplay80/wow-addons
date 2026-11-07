local _, helper = ...
local events = CreateFrame("Frame")
local lineType = Enum.TooltipDataLineType
local markerTexture = "Interface\\AddOns\\ForeverQuestHelper\\QuestCompass.tga"
local isSecret = issecretvalue or function() return false end
local activeUnits = {}
local markers = {}
local questObjectives = {}
local objectNames = {}
local questsDirty = true
local refreshQueued = false
local inWorld = false

-- The client can refuse access to restricted data or return a secret value.
local function ReadUnitAPI(func, ...)
    local ok, value = pcall(func, ...)
    if ok and not isSecret(value) then
        return value
    end
end

local function TextKey(text)
    if isSecret(text) or type(text) ~= "string" then
        return nil
    end

    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    text = text:gsub("\194\160", " "):gsub("%s+", " "):match("^%s*(.-)%s*$")
    if text ~= "" then
        return text:lower()
    end
end

local function ObjectiveKey(text)
    text = TextKey(text)
    if text then
        -- The log and the tooltip can put the progress counter on opposite sides.
        text = text:gsub("^%d+%s*/%s*%d+[%s:%-]+", "")
        text = text:gsub("[%s:%-]+%d+%s*/%s*%d+$", "")
        return TextKey(text)
    end
end

local function RefreshQuestObjectives()
    wipe(questObjectives)
    wipe(objectNames)

    local count = ReadUnitAPI(C_QuestLog.GetNumQuestLogEntries)
    if type(count) ~= "number" then return end
    for index = 1, count do
        local quest = ReadUnitAPI(C_QuestLog.GetInfo, index)
        if quest and not isSecret(quest.isHeader) and not quest.isHeader
            and not isSecret(quest.isHidden) and not quest.isHidden
            and not isSecret(quest.questID) and type(quest.questID) == "number" and quest.questID > 0
            and ReadUnitAPI(C_QuestLog.IsFailed, quest.questID) ~= true then
            local title = TextKey(quest.title)
            local objectives = ReadUnitAPI(C_QuestLog.GetQuestObjectives, quest.questID)
            if title and objectives then
                for _, objective in ipairs(objectives) do
                    local key = not isSecret(objective) and not isSecret(objective.finished)
                        and not objective.finished and ObjectiveKey(objective.text)
                    if key then
                        questObjectives[title] = questObjectives[title] or {}
                        questObjectives[title][key] = { title = quest.title, objective = objective }
                        objectNames[key] = true
                    end
                end
            end
        end
    end

    questsDirty = false
end

local function VisitTooltipObjectives(data, visit)
    if questsDirty then RefreshQuestObjectives() end
    if isSecret(data) or type(data) ~= "table" then return false end
    local lines = data.lines
    if isSecret(lines) or type(lines) ~= "table" then
        return false
    end

    local objectives
    for _, line in ipairs(lines) do
        if isSecret(line) or isSecret(line.type) then
            objectives = nil
        elseif line.type == lineType.QuestTitle then
            objectives = questObjectives[TextKey(line.leftText)]
        elseif line.type == lineType.QuestObjective and objectives then
            local match = objectives[ObjectiveKey(line.leftText)]
            if match and (not visit or visit(match)) then
                return true
            end
        end
    end

    return false
end

local function IsQuestTarget(unit)
    if VisitTooltipObjectives(ReadUnitAPI(C_TooltipInfo.GetUnit, unit)) then
        return true
    end

    -- Some interactive objects provide a name but no unit tooltip.
    return ReadUnitAPI(UnitIsGameObject, unit) == true
        and objectNames[TextKey(ReadUnitAPI(UnitName, unit))] == true
end

local function GetRemainingText(objective)
    local required, fulfilled = objective.numRequired, objective.numFulfilled
    if not isSecret(required) and not isSecret(fulfilled)
        and type(required) == "number" and type(fulfilled) == "number" and required > fulfilled then
        local kind = not isSecret(objective.type) and objective.type
        local unit = kind == "monster" and "마리" or kind == "item" and "개" or ""
        return ("%d%s 남음"):format(required - fulfilled, unit)
    end
    return "미완료"
end

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
    if tooltip ~= GameTooltip or not helper.IsEnabled("targetTooltip") then return end

    local shown = {}
    VisitTooltipObjectives(data, function(match)
        if not shown[match] then
            if not next(shown) then
                tooltip:AddLine("|T" .. markerTexture .. ":12:12|t 퀘스트 대상", 1, 0.82, 0.45)
            end
            shown[match] = true
            tooltip:AddLine(match.title .. " · " .. GetRemainingText(match.objective), 1, 0.94, 0.80, true)
        end
    end)
end)

local function PositionMarker(marker, plate)
    local name = plate.UnitFrame and plate.UnitFrame.name
    local anchor, point, xOffset = plate, "RIGHT", 4

    if name and ReadUnitAPI(name.IsVisible, name) then
        local textWidth = ReadUnitAPI(name.GetWrappedWidth, name)
        local fieldWidth = ReadUnitAPI(name.GetWidth, name)
        if textWidth and textWidth > 0 and fieldWidth and fieldWidth > 0 then
            -- The name field can be wider than the text it displays.
            local width = math.min(textWidth, fieldWidth)
            local justify = ReadUnitAPI(name.GetJustifyH, name)
            anchor = name
            if justify == "LEFT" then
                point, xOffset = "LEFT", xOffset + width
            elseif justify == "CENTER" then
                point, xOffset = "CENTER", xOffset + width / 2
            end
        end
    end

    marker:ClearAllPoints()
    marker:SetPoint("LEFT", anchor, point, xOffset, 0)
end

local function ShowMarker(plate)
    local marker = markers[plate]
    if not marker then
        marker = CreateFrame("Frame", nil, plate)
        marker:SetSize(16, 16)
        marker:EnableMouse(false)

        local icon = marker:CreateTexture(nil, "OVERLAY")
        icon:SetAllPoints()
        icon:SetTexture(markerTexture)
        icon:SetBlendMode("BLEND")
        markers[plate] = marker
    end

    PositionMarker(marker, plate)
    marker:Show()
end

local function GetNamePlate(unit)
    local plate = ReadUnitAPI(C_NamePlate.GetNamePlateForUnit, unit)
    if plate and not plate:IsForbidden() then
        return plate
    end
end

local function RefreshMarkers()
    refreshQueued = false
    if not inWorld then
        return
    end

    if not helper.IsEnabled("nameplateMarks") then
        for _, marker in pairs(markers) do marker:Hide() end
        return
    end

    if questsDirty then
        RefreshQuestObjectives()
    end

    local visible = {}
    if next(questObjectives) then
        -- With interaction nameplates enabled, the client can expose one nearby object.
        local softObject = ReadUnitAPI(UnitIsGameObject, "softinteract") == true
            and IsQuestTarget("softinteract")
        local softPlate = softObject and GetNamePlate("softinteract")
        if softPlate then
            visible[softPlate] = true
        end

        for unit in pairs(activeUnits) do
            local plate = GetNamePlate(unit)
            activeUnits[unit] = plate or true
            if plate and not visible[plate] then
                local isSoftPlate = softObject and not softPlate
                    and ReadUnitAPI(UnitIsUnit, unit, "softinteract") == true
                if isSoftPlate or IsQuestTarget(unit) then
                    visible[plate] = true
                end
            end
        end
    end

    for plate in pairs(visible) do
        ShowMarker(plate)
    end
    for plate, marker in pairs(markers) do
        if not visible[plate] then
            marker:Hide()
        end
    end
end

local function QueueRefresh()
    if not refreshQueued then
        refreshQueued = true
        C_Timer.After(0, RefreshMarkers)
    end
end

helper.OnFeatureChanged("nameplateMarks", QueueRefresh)
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_LEAVING_WORLD")
events:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
events:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
events:RegisterEvent("QUEST_LOG_UPDATE")
events:RegisterEvent("QUEST_WATCH_UPDATE")
events:RegisterEvent("UNIT_NAME_UPDATE")
events:RegisterEvent("CVAR_UPDATE")

events:SetScript("OnEvent", function(_, event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
        activeUnits[unit] = true
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        local plate = activeUnits[unit]
        activeUnits[unit] = nil
        local marker = markers[plate]
        if marker then
            marker:Hide()
        end
    elseif event == "PLAYER_LEAVING_WORLD" then
        inWorld = false
        wipe(activeUnits)
        for _, marker in pairs(markers) do
            marker:Hide()
        end
        return
    elseif event == "PLAYER_ENTERING_WORLD" then
        inWorld = true
        questsDirty = true
    elseif event == "QUEST_LOG_UPDATE" or event == "QUEST_WATCH_UPDATE" then
        questsDirty = true
    elseif event == "UNIT_NAME_UPDATE" and not activeUnits[unit] then
        return
    elseif event == "CVAR_UPDATE" and (isSecret(unit) or type(unit) ~= "string" or not unit:lower():match("^nameplate")) then
        return
    end

    QueueRefresh()
end)
