local _, helper = ...
local isSecret = issecretvalue or function() return false end
local pinTemplate = "ForeverQuestRoutePinTemplate"
local rowHeight, rowWidth = 42, 330
local route, omitted, rows = {}, {}, {}
local turnInOnly = false
local mapID, mapProvider, refreshQueued
local trackerMapID, trackerDestinations, trackerPoints

local function Read(func, ...)
    local ok, first, second, third = pcall(func, ...)
    if ok and not (isSecret(first) or isSecret(second) or isSecret(third)) then
        return first, second, third
    end
end

local function IsPublic(value, valueType)
    return not isSecret(value) and type(value) == valueType
end

local function HasCoordinates(x, y)
    return IsPublic(x, "number") and IsPublic(y, "number")
        and x >= 0 and x <= 1 and y >= 0 and y <= 1 and (x ~= 0 or y ~= 0)
end

local function GetPlayerCoordinates(currentMapID)
    local position = currentMapID and Read(C_Map.GetPlayerMapPosition, currentMapID, "player")
    if position then return Read(position.GetXY, position) end
end

local function GetQuestPoints(currentMapID)
    -- Let the visible world map keep control of its own POI query.
    if (not WorldMapFrame or not WorldMapFrame:IsShown())
        and Read(C_QuestLog.GetMapForQuestPOIs) ~= currentMapID then
        Read(C_QuestLog.SetMapForQuestPOIs, currentMapID)
    end
    local points = {}
    for _, point in ipairs(Read(C_QuestLog.GetQuestsOnMap, currentMapID) or {}) do
        if not isSecret(point) and IsPublic(point.questID, "number")
            and not isSecret(point.isMapIndicatorQuest) and not point.isMapIndicatorQuest
            and not isSecret(point.isQuestStart) and not point.isQuestStart
            and HasCoordinates(point.x, point.y) then
            points[point.questID] = points[point.questID] or point
        end
    end
    return points
end

local function GetQuestDestination(questID, currentMapID, point, turnIn)
    if point and turnIn then return point.x, point.y end
    local targetMapID, x, y = Read(C_QuestLog.GetNextWaypoint, questID)
    if targetMapID == currentMapID and HasCoordinates(x, y) then return x, y end
    if point then return point.x, point.y end
    local validMap = IsPublic(targetMapID, "number") and targetMapID > 0
    return nil, nil, validMap and targetMapID ~= currentMapID,
        validMap and HasCoordinates(x, y) and targetMapID or nil
end

local function GetMeters(distanceSq)
    -- Blizzard reports map dimensions and quest distances in yards.
    return math.floor(math.sqrt(distanceSq) * 0.9144 + 0.5)
end

local function CollectQuests(currentMapID, points)
    local quests, seen = {}, {}
    local function AddQuest(questID, title)
        if IsPublic(questID, "number") and questID > 0 and not seen[questID]
            and not Read(C_QuestLog.IsFailed, questID) then
            seen[questID] = true
            quests[#quests + 1] = {
                id = questID,
                title = IsPublic(title, "string") and title or ("퀘스트 %d"):format(questID),
            }
        end
    end

    local count = Read(C_QuestLog.GetNumQuestLogEntries) or 0
    for index = 1, count do
        local info = Read(C_QuestLog.GetInfo, index)
        if info and not isSecret(info.isHeader) and not info.isHeader
            and not isSecret(info.isHidden) and not info.isHidden then
            AddQuest(info.questID, info.title)
        end
    end

    for questID in pairs(points) do
        if not seen[questID] and Read(C_QuestLog.IsOnQuest, questID) then
            -- Map POIs can still identify accepted quests under collapsed log headers.
            AddQuest(questID, Read(C_QuestLog.GetTitleForQuestID, questID))
        end
    end

    local destinations, unavailable = {}, {}
    for _, quest in ipairs(quests) do
        quest.turnIn = Read(C_QuestLog.ReadyForTurnIn, quest.id) == true
        quest.turnInPoint = quest.turnIn and points[quest.id] ~= nil
        quest.x, quest.y, quest.otherMap, quest.targetMapID = GetQuestDestination(quest.id, currentMapID,
            points[quest.id], quest.turnIn)

        if quest.x then
            destinations[#destinations + 1] = quest
        else
            unavailable[#unavailable + 1] = quest
        end
    end
    return destinations, unavailable
end

local function OrderRoute(destinations, x, y, width, height)
    local hasMapSize = width and height and width > 0 and height > 0
    if not hasMapSize then width, height = 1, 1 end
    local remaining = {}
    for index, quest in ipairs(destinations) do remaining[index] = quest end
    local ordered = {}
    while #remaining > 0 do
        local bestIndex, bestDistance
        for index, quest in ipairs(remaining) do
            local dx, dy = (quest.x - x) * width, (quest.y - y) * height
            local distance = dx * dx + dy * dy
            if not bestDistance or distance < bestDistance
                or (distance == bestDistance and quest.id < remaining[bestIndex].id) then
                bestIndex, bestDistance = index, distance
            end
        end
        local quest = table.remove(remaining, bestIndex)
        if hasMapSize then
            quest.distanceMeters = GetMeters(bestDistance)
        end
        ordered[#ordered + 1] = quest
        x, y = quest.x, quest.y
    end
    return ordered
end

ForeverQuestRoutePinMixin = {}

function ForeverQuestRoutePinMixin:OnLoad()
    self:SetDefaultMapPinScale()
    self:UseFrameLevelType("PIN_FRAME_LEVEL_QUEST_PING")
end

function ForeverQuestRoutePinMixin:OnAcquired(x, y, label)
    self.Number:SetText(label)
    self:SetWidth(math.max(24, self.Number:GetStringWidth() + 8))
    self:SetPosition(x, y)
end

local panel = CreateFrame("Frame", "ForeverQuestRouteFrame", UIParent, "ButtonFrameTemplate")
panel:SetSize(666, 492)
panel:SetPoint("CENTER", UIParent, "CENTER")
panel:SetFrameStrata("DIALOG")
panel:SetClampedToScreen(true)
panel:SetMovable(true)
panel.TitleContainer.TitleText:SetText("퀘스트 도우미")
panel:SetPortraitToAsset("Interface\\QuestFrame\\UI-QuestLog-BookIcon")
panel:Hide()
tinsert(UISpecialFrames, panel:GetName())

local header = CreateFrame("Frame", nil, panel)
header:SetPoint("TOPLEFT", 62, -1)
header:SetPoint("TOPRIGHT", -34, -4)
header:SetHeight(52)
header:EnableMouse(true)
header:RegisterForDrag("LeftButton")
header:SetScript("OnDragStart", function() panel:StartMoving() end)
header:SetScript("OnDragStop", function() panel:StopMovingOrSizing() end)

local settingsTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
settingsTitle:SetPoint("TOPLEFT", 24, -77)
settingsTitle:SetText("기능 설정")

local routeTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
routeTitle:SetPoint("TOPLEFT", 304, -77)
routeTitle:SetText("현재 지역 동선")

local hordeButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
hordeButton:SetSize(120, 22)
hordeButton:SetPoint("TOPRIGHT", -23, -43)
hordeButton:SetText("호드 추천 동선")
hordeButton:SetScript("OnClick", function()
    panel:Hide()
    helper.ToggleHordeQuestPlan()
end)

local turnInButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
turnInButton:SetSize(120, 22)
turnInButton:SetPoint("TOPRIGHT", -23, -74)

local divider = panel:CreateTexture(nil, "ARTWORK")
divider:SetColorTexture(0.65, 0.53, 0.31, 0.4)
divider:SetPoint("TOPLEFT", 288, -71)
divider:SetPoint("BOTTOMLEFT", 288, 35)
divider:SetWidth(1)

local summary = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
summary:SetPoint("TOPLEFT", 304, -101)
summary:SetPoint("RIGHT", panel, "RIGHT", -15, 0)
summary:SetJustifyH("LEFT")

local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 304, -125)
scroll:SetPoint("BOTTOMRIGHT", -30, 79)
local content = CreateFrame("Frame", nil, scroll)
content:SetSize(rowWidth, 1)
scroll:SetScrollChild(content)

local message = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
message:SetPoint("BOTTOMLEFT", 304, 52)
message:SetPoint("RIGHT", panel, "RIGHT", -15, 0)
message:SetJustifyH("LEFT")
local clickHint = "항목을 클릭하면 기본 길 안내 핀이 바뀝니다."

local function SetWaypoint(quest)
    if not quest or not mapID then return end
    if Read(C_Map.GetBestMapForUnit, "player") ~= mapID then
        message:SetText("지역이 바뀌었습니다. 동선을 갱신한 뒤 다시 선택하세요.")
        return
    end
    if not Read(C_Map.CanSetUserWaypointOnMap, mapID)
        or not Read(C_Map.SetUserWaypoint, UiMapPoint.CreateFromCoordinates(mapID, quest.x, quest.y)) then
        message:SetText("이 위치에는 기본 길 안내 핀을 설정할 수 없습니다.")
        return
    end
    Read(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
    message:SetText(("길 안내 위치 · %.1f, %.1f"):format(quest.x * 100, quest.y * 100))
end

local function CreateRow(index)
    local row = CreateFrame("Button", nil, content)
    row:SetSize(rowWidth, rowHeight - 2)
    row:SetPoint("TOPLEFT", 0, -(index - 1) * rowHeight)
    local background = row:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.14, 0.18, 0.22, 0.68)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")

    row.title = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    row.title:SetPoint("TOPLEFT", 8, -5)
    row.title:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    row.title:SetJustifyH("LEFT")
    row.title:SetWordWrap(false)
    row.detail = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.detail:SetPoint("BOTTOMLEFT", 8, 5)
    row:SetScript("OnClick", function(self)
        if self.quest.x then SetWaypoint(self.quest) end
    end)
    row:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.quest.title, 1, 1, 1, 1, true)
        GameTooltip:AddLine(self.detail:GetText(), 0.82, 0.86, 0.90, true)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return row
end

local function LastAtDestination(index)
    local quest, last = route[index], index
    while route[last + 1] and route[last + 1].x == quest.x and route[last + 1].y == quest.y do
        last = last + 1
    end
    return last
end

local function RenderRows()
    local count = #route + #omitted
    local groupEnd = 0
    content:SetHeight(math.max(1, count * rowHeight))
    for index = 1, count do
        local quest = route[index] or omitted[index - #route]
        local row = rows[index] or CreateRow(index)
        rows[index] = row
        row.quest = quest
        local kind = quest.turnIn and "반납" or "목표"
        if quest.x then
            if index <= groupEnd then
                row.title:SetText("    " .. quest.title)
                row.detail:SetText("같은 반납 지점")
            else
                groupEnd = turnInOnly and LastAtDestination(index) or index
                local label = groupEnd > index and ("%d–%d"):format(index, groupEnd) or tostring(index)
                row.title:SetText(label .. ". " .. quest.title)
                local distance = quest.distanceMeters and ("이동 %d m   ·   "):format(quest.distanceMeters) or ""
                if groupEnd > index then kind = ("같은 지점 반납 %d개"):format(groupEnd - index + 1) end
                row.detail:SetText(("%s   ·   %s%.1f, %.1f"):format(kind, distance, quest.x * 100, quest.y * 100))
            end
            row.title:SetTextColor(1, 0.91, 0.66)
        else
            row.title:SetText(quest.title)
            local floorHint = helper.GetQuestFloorHint(mapID, quest.targetMapID)
            row.detail:SetText(kind .. "   ·   " .. (floorHint or (quest.otherMap and "다른 지역" or "좌표 없음")))
            row.title:SetTextColor(0.73, 0.77, 0.81)
        end
        row:Show()
    end
    for index = count + 1, #rows do rows[index]:Hide() end
    scroll:UpdateScrollChildRect()
    scroll:SetVerticalScroll(math.min(scroll:GetVerticalScroll(), scroll:GetVerticalScrollRange()))
end

local function AttachMapProvider()
    if mapProvider or not WorldMapFrame then return end
    mapProvider = CreateFromMixins(MapCanvasDataProviderMixin)
    function mapProvider:RemoveAllData()
        self:GetMap():RemoveAllPinsByTemplate(pinTemplate)
    end
    function mapProvider:RefreshAllData()
        self:RemoveAllData()
        local map = self:GetMap()
        if not helper.IsEnabled("mapPins") or not panel:IsShown() or map:GetMapID() ~= mapID then return end
        local index = 1
        while index <= #route do
            local quest = route[index]
            local last = LastAtDestination(index)
            local label = last > index and ("%d–%d"):format(index, last) or tostring(index)
            map:AcquirePin(pinTemplate, quest.x, quest.y, label)
            index = last + 1
        end
    end
    WorldMapFrame:AddDataProvider(mapProvider)
end

local function MakeButton(text, x)
    local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    button:SetSize(108, 24)
    button:SetPoint("BOTTOMLEFT", x, 13)
    button:SetText(text)
    return button
end

local nextButton = MakeButton("첫 목적지 안내", 304)
local mapButton = MakeButton("지도 보기", 420)
local refreshButton = MakeButton("다시 계산", 536)

local function GetTurnIns(quests)
    local ready = {}
    for _, quest in ipairs(quests) do
        if quest.turnIn then ready[#ready + 1] = quest end
    end
    return ready
end

local function Refresh()
    local currentMapID = Read(C_Map.GetBestMapForUnit, "player")
    local x, y = GetPlayerCoordinates(currentMapID)
    if mapID ~= currentMapID then
        scroll:SetVerticalScroll(0)
        message:SetText(clickHint)
    end
    mapID, route, omitted = currentMapID, {}, {}
    local readyCount = 0
    if HasCoordinates(x, y) then
        local destinations
        destinations, omitted = CollectQuests(mapID, GetQuestPoints(mapID))
        local ready, readyWithoutCoordinates = GetTurnIns(destinations), GetTurnIns(omitted)
        readyCount = #ready + #readyWithoutCoordinates
        if turnInOnly then
            destinations, omitted = {}, readyWithoutCoordinates
            for _, quest in ipairs(ready) do
                if quest.turnInPoint then
                    destinations[#destinations + 1] = quest
                else
                    -- An intermediate waypoint is insufficient to group a turn-in.
                    quest.x, quest.y = nil, nil
                    omitted[#omitted + 1] = quest
                end
            end
        end
        local width, height = Read(C_Map.GetMapWorldSize, mapID)
        route = OrderRoute(destinations, x, y, width, height)
        local info = Read(C_Map.GetMapInfo, mapID)
        local name = info and IsPublic(info.name, "string") and info.name or "현재 지역"
        local mode = turnInOnly and "반납" or "동선"
        summary:SetText(("%s  ·  %s %d개  /  좌표 없음 %d개"):format(name, mode, #route, #omitted))
    else
        summary:SetText("현재 위치를 확인할 수 없습니다.")
    end
    nextButton:SetEnabled(#route > 0)
    mapButton:SetEnabled(mapID ~= nil)
    turnInButton:SetShown(helper.IsEnabled("turnInList"))
    turnInButton:SetEnabled(turnInOnly or readyCount > 0)
    turnInButton:SetText(turnInOnly and "전체 동선" or ("반납 가능 %d개"):format(readyCount))
    RenderRows()
    AttachMapProvider()
    if mapProvider and WorldMapFrame:IsShown() then mapProvider:RefreshAllData() end
end

turnInButton:SetScript("OnClick", function()
    turnInOnly = not turnInOnly
    scroll:SetVerticalScroll(0)
    Refresh()
end)

local function QueueRefresh()
    if refreshQueued or not panel:IsShown() then return end
    refreshQueued = true
    C_Timer.After(0.1, function()
        refreshQueued = nil
        if panel:IsShown() then Refresh() end
    end)
end

nextButton:SetScript("OnClick", function() SetWaypoint(route[1]) end)
mapButton:SetScript("OnClick", function()
    if mapID then Read(C_Map.OpenWorldMap, mapID) end
    QueueRefresh()
end)
refreshButton:SetScript("OnClick", function()
    message:SetText(clickHint)
    Refresh()
end)
panel:SetScript("OnShow", function()
    message:SetText(clickHint)
    Refresh()
end)
panel:SetScript("OnHide", function()
    if mapProvider then mapProvider:RemoveAllData() end
end)
helper.CreateSettingsControls(panel)
helper.OnFeatureChanged("mapPins", function()
    if mapProvider then mapProvider:RefreshAllData() end
end)
helper.OnFeatureChanged("turnInList", function()
    if not helper.IsEnabled("turnInList") then turnInOnly = false end
    if panel:IsShown() then Refresh() end
end)
panel:SetScript("OnEvent", function()
    trackerDestinations = nil
    QueueRefresh()
end)
for _, event in ipairs({
    "PLAYER_ENTERING_WORLD", "PLAYER_MAP_CHANGED", "QUEST_LOG_UPDATE", "QUEST_POI_UPDATE", "SUPER_TRACKING_PATH_UPDATED",
}) do
    panel:RegisterEvent(event)
end

local function ToggleRoutePanel()
    panel:SetShown(not panel:IsShown())
end

SLASH_FOREVERQUESTROUTE1 = "/fqh"
SlashCmdList.FOREVERQUESTROUTE = function(message)
    if type(message) == "string" and message:match("^%s*horde%s*$") then
        panel:Hide()
        helper.ToggleHordeQuestPlan()
    else
        ToggleRoutePanel()
    end
end

local trackerRouteButton
local function AttachTrackerRouteButton()
    if trackerRouteButton then
        trackerRouteButton:SetShown(helper.IsEnabled("trackerButton"))
        return
    end
    if not helper.IsEnabled("trackerButton") then return end
    local header = ObjectiveTrackerFrame and ObjectiveTrackerFrame.Header
    if not header or not header.MinimizeButton then return end

    trackerRouteButton = CreateFrame("Button", nil, header, "UIPanelButtonTemplate")
    trackerRouteButton:SetSize(54, 20)
    trackerRouteButton:SetPoint("RIGHT", header.FilterButton or header.MinimizeButton, "LEFT", -4, 0)
    trackerRouteButton:SetText("도우미")
    trackerRouteButton:SetScript("OnClick", ToggleRoutePanel)
end

local trackerLabels = setmetatable({}, { __mode = "k" })
local activeArrows = {}
local arrowSize, arrowGap = 16, 4
local fullTurn = 2 * math.pi
local arrowDriver = CreateFrame("Frame")
arrowDriver:Hide()

local function RotateTrackerArrow(display, facing, blend)
    local angle = (display.bearing - facing) % fullTurn
    if display.angle then
        -- Interpolate across the shortest arc, including at the 0/360 seam.
        local delta = (angle - display.angle + math.pi) % fullTurn - math.pi
        if math.abs(delta) > 0.005 then
            angle = (display.angle + delta * blend) % fullTurn
        end
    end
    if angle ~= display.angle then
        display.angle = angle
        display.arrow:SetRotation(angle)
    end
    display.arrow:Show()
end

arrowDriver:SetScript("OnUpdate", function(_, elapsed)
    local facing = Read(GetPlayerFacing)
    local blend = 1 - math.exp(-18 * elapsed)
    for display in pairs(activeArrows) do
        if facing then
            RotateTrackerArrow(display, facing, blend)
        else
            display.angle = nil
            display.arrow:Hide()
        end
    end
end)

local function HideTrackerArrow(display)
    display.arrow:Hide()
    display.angle = nil
    activeArrows[display] = nil
    if not next(activeArrows) then arrowDriver:Hide() end
end

local function SetTrackerLabel(block, text, distanceText, bearing, facing)
    local display = trackerLabels[block]
    if not text and not (bearing and facing) then
        if display then
            display.label:Hide()
            HideTrackerArrow(display)
        end
        return
    end

    local header = block.HeaderText
    if not display then
        local label = block:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetTextColor(0.72, 0.86, 1)
        local arrow = block:CreateTexture(nil, "OVERLAY")
        arrow:SetTexture(helper.directionArrowTexture)
        arrow:SetSize(arrowSize, arrowSize)
        arrow:Hide()
        display = { label = label, arrow = arrow }
        trackerLabels[block] = display
        block:HookScript("OnHide", function()
            label:Hide()
            HideTrackerArrow(display)
        end)
    end

    local label = display.label
    if label:GetText() ~= (text or "") then label:SetText(text or "") end

    -- The header already reserves space for native quest item and group buttons.
    local titleWidth = Read(header.GetUnboundedStringWidth, header)
    local availableWidth = Read(header.GetWidth, header)
    local offset = titleWidth and titleWidth > 0 and titleWidth + 7
    if not offset or not availableWidth then
        label:Hide()
        HideTrackerArrow(display)
        return
    end

    local textWidth = text and label:GetStringWidth() or 0
    if offset + textWidth > availableWidth and distanceText and distanceText ~= text then
        label:SetText(distanceText)
        textWidth = label:GetStringWidth()
    end
    if offset + textWidth > availableWidth then
        label:Hide()
        HideTrackerArrow(display)
        return
    end

    local arrowSpace = arrowSize + (text and arrowGap or 0)
    local showArrow = bearing and facing and offset + arrowSpace + textWidth <= availableWidth
    label:SetPoint("LEFT", header, "LEFT", offset + (showArrow and arrowSpace or 0), 0)
    label:SetShown(text ~= nil)
    if showArrow then
        display.arrow:SetPoint("LEFT", header, "LEFT", offset, 0)
        display.bearing = bearing
        if not activeArrows[display] then
            activeArrows[display] = true
            RotateTrackerArrow(display, facing, 1)
            arrowDriver:Show()
        end
    else
        HideTrackerArrow(display)
    end
end

local function ReadTrackerMap()
    local currentMapID = Read(C_Map.GetBestMapForUnit, "player")
    local x, y = GetPlayerCoordinates(currentMapID)
    if not HasCoordinates(x, y) then return false end

    local width, height = Read(C_Map.GetMapWorldSize, currentMapID)
    if not width or not height or width <= 0 or height <= 0 then width, height = nil, nil end
    if not trackerDestinations or trackerMapID ~= currentMapID then
        trackerMapID = currentMapID
        trackerPoints = GetQuestPoints(currentMapID)
        trackerDestinations = CollectQuests(currentMapID, trackerPoints)
    end

    local byQuest = {}
    for priority, quest in ipairs(OrderRoute(trackerDestinations, x, y, width, height)) do
        quest.priority = priority
        byQuest[quest.id] = quest
    end
    return { id = currentMapID, x = x, y = y, width = width, height = height, byQuest = byQuest }
end

local atan2 = math.atan2 or math.atan
local function GetTrackerGuidance(questID, trackerMap)
    local quest = trackerMap and trackerMap.byQuest[questID]
    local meters, bearing
    if trackerMap and trackerMap.width then
        local x, y
        if quest then
            x, y = quest.x, quest.y
        else
            local turnIn = Read(C_QuestLog.ReadyForTurnIn, questID) == true
            x, y = GetQuestDestination(questID, trackerMap.id, trackerPoints[questID], turnIn)
        end
        if x then
            local dx = (x - trackerMap.x) * trackerMap.width
            local dy = (y - trackerMap.y) * trackerMap.height
            meters = GetMeters(dx * dx + dy * dy)
            -- Match GetPlayerFacing: radians counterclockwise from map north.
            if meters > 0 then bearing = atan2(-dx, -dy) end
        end
    end
    if meters == nil then
        local distanceSq, onContinent = Read(C_QuestLog.GetDistanceSqToQuest, questID)
        if onContinent == true and distanceSq and distanceSq >= 0 and distanceSq < math.huge then
            meters = GetMeters(distanceSq)
        end
    end
    return meters, bearing, quest and quest.priority
end

local function UpdateTrackerGuidance()
    if not trackerRouteButton then AttachTrackerRouteButton() end
    local showOrder = helper.IsEnabled("trackerOrder")
    local showDistance = helper.IsEnabled("trackerDistance")
    local showDirection = helper.IsEnabled("trackerDirection")
    if not (showOrder or showDistance or showDirection) then
        for block in pairs(trackerLabels) do SetTrackerLabel(block) end
        return
    end
    local tracker = QuestObjectiveTracker
    if not tracker or not tracker.usedBlocks or not tracker:IsVisible() then return end

    local facing = Read(GetPlayerFacing)
    local trackerMap
    tracker:EnumerateActiveBlocks(function(block)
        if not block:IsVisible() or not block.HeaderText or not IsPublic(block.id, "number")
            or Read(C_QuestLog.IsFailed, block.id) then
            SetTrackerLabel(block)
            return
        end
        if trackerMap == nil then trackerMap = ReadTrackerMap() end
        local meters, bearing, priority = GetTrackerGuidance(block.id, trackerMap)
        local distanceText = showDistance and meters and ("%d m"):format(meters)
        local parts = {}
        if showOrder and priority then parts[#parts + 1] = ("#%d"):format(priority) end
        if distanceText then parts[#parts + 1] = distanceText end
        local text = #parts > 0 and table.concat(parts, "  ") or nil
        SetTrackerLabel(block, text, distanceText, showDirection and bearing, facing)
    end)
end

helper.OnFeatureChanged("trackerButton", AttachTrackerRouteButton)
helper.OnFeatureChanged("trackerOrder", UpdateTrackerGuidance)
helper.OnFeatureChanged("trackerDistance", UpdateTrackerGuidance)
helper.OnFeatureChanged("trackerDirection", UpdateTrackerGuidance)
-- SavedVariables are restored before PLAYER_ENTERING_WORLD, after this file loads.
panel:HookScript("OnEvent", function(_, event)
    if event == "PLAYER_ENTERING_WORLD" then AttachTrackerRouteButton() end
end)
C_Timer.NewTicker(0.5, UpdateTrackerGuidance)
