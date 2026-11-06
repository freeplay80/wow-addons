local _, helper = ...
local metersPerYard = 0.9144
local guideHeight = 48
local isSecret = issecretvalue or function() return false end
local waypoint
local routeStep, routeTracking, pendingTurnIns, routeNotice
local moving, dragging = false, false

local guide = CreateFrame("Frame", nil, UIParent)
guide:SetSize(280, guideHeight)
guide:SetPoint("TOP", UIParent, "TOP", 0, -126)
guide:SetMovable(true)
guide:SetClampedToScreen(true)
guide:EnableMouse(false)
guide:RegisterForDrag("LeftButton")
guide:Hide()

local heading = guide:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
heading:SetPoint("TOP", guide, "TOP", 13, -4)

local arrow = guide:CreateTexture(nil, "ARTWORK")
arrow:SetTexture(helper.directionArrowTexture)
arrow:SetSize(22, 22)
arrow:SetPoint("RIGHT", heading, "LEFT", -5, 0)

local caption = guide:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
caption:SetPoint("TOPLEFT", guide, "TOPLEFT", 0, -28)
caption:SetPoint("TOPRIGHT", guide, "TOPRIGHT", 0, -28)
caption:SetWordWrap(false)
caption:SetMaxLines(1)

local routeReason = guide:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
routeReason:SetPoint("TOPLEFT", guide, "TOPLEFT", 5, -44)
routeReason:SetPoint("TOPRIGHT", guide, "TOPRIGHT", -5, -44)
routeReason:SetJustifyH("CENTER")
routeReason:SetWordWrap(true)
routeReason:SetMaxLines(2)
routeReason:Hide()

local turnInDetails = guide:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
turnInDetails:SetJustifyH("CENTER")
turnInDetails:SetWordWrap(true)
turnInDetails:Hide()
local events = CreateFrame("Frame")

local function IsReadableNumber(value)
    return not isSecret(value) and type(value) == "number"
end

local function Read(func, ...)
    local ok, a, b = pcall(func, ...)
    if ok and not isSecret(a) and not isSecret(b) then return a, b end
end

local function RestoreGuidePosition()
    local saved = helper.GetSettings().guidePosition
    guide:ClearAllPoints()
    if type(saved) == "table" and IsReadableNumber(saved.x) and IsReadableNumber(saved.y) then
        guide:SetPoint("CENTER", UIParent, "CENTER", saved.x, saved.y)
    else
        guide:SetPoint("TOP", UIParent, "TOP", 0, -126)
    end
end

local function FinishDrag()
    if not dragging then return end
    dragging = false
    guide:StopMovingOrSizing()
    guide:SetUserPlaced(false)
    local x, y = guide:GetCenter()
    local originX, originY = UIParent:GetCenter()
    if x and y and originX and originY then
        helper.GetSettings().guidePosition = { x = x - originX, y = y - originY }
        RestoreGuidePosition()
    end
end

guide:SetScript("OnDragStart", function()
    if moving then
        dragging = true
        guide:StartMoving()
    end
end)
guide:SetScript("OnDragStop", FinishDrag)

local function IsMapPoint(x, y)
    return IsReadableNumber(x) and IsReadableNumber(y)
        and x >= 0 and x <= 1 and y >= 0 and y <= 1 and (x > 0 or y > 0)
end

local function FindQuestPoint(questID, mapID)
    while IsReadableNumber(mapID) and mapID > 0 do
        local x, y = Read(C_QuestLog.GetNextWaypointForMap, questID, mapID)
        if IsMapPoint(x, y) then
            return mapID, x, y
        end

        for _, poi in ipairs(Read(C_QuestLog.GetQuestsOnMap, mapID) or {}) do
            if not isSecret(poi) and IsReadableNumber(poi.questID) and poi.questID == questID
                and not isSecret(poi.isMapIndicatorQuest) and not poi.isMapIndicatorQuest
                and not isSecret(poi.isQuestStart) and not poi.isQuestStart and IsMapPoint(poi.x, poi.y) then
                return mapID, poi.x, poi.y
            end
        end

        local map = Read(C_Map.GetMapInfo, mapID)
        if not map or not IsReadableNumber(map.mapType) or map.mapType <= Enum.UIMapType.Continent
            or not IsReadableNumber(map.parentMapID) or map.parentMapID == mapID then
            break
        end
        mapID = map.parentMapID
    end
end

local function ShowFloorGuide(direction, floorName, up, title)
    waypoint = nil
    events:SetScript("OnUpdate", nil)
    heading:SetText(direction)
    caption:SetText(floorName and (floorName .. " · " .. title) or title)
    arrow:Show()
    arrow:SetRotation(up and 0 or math.pi)
    guide:Show()
end

local function GetWorldPosition(mapID, position)
    if not C_Map.GetWorldPosFromMapPos or not IsReadableNumber(mapID) or isSecret(position)
        or not position or not IsMapPoint(position.x, position.y) then return end
    local world, vector = Read(C_Map.GetWorldPosFromMapPos, mapID, position)
    if IsReadableNumber(world) and not isSecret(vector) and vector
        and IsReadableNumber(vector.x) and IsReadableNumber(vector.y) then
        return world, vector.x, vector.y
    end
end

local function GetOffset()
    if waypoint.world then
        local playerMapID = Read(C_Map.GetBestMapForUnit, "player")
        if IsReadableNumber(playerMapID) and playerMapID ~= waypoint.mapID then
            local playerPosition = Read(C_Map.GetPlayerMapPosition, playerMapID, "player")
            local world, x, y = GetWorldPosition(playerMapID, playerPosition)
            if world == waypoint.world then
                -- World X increases northward and world Y increases westward.
                return y - waypoint.wy, waypoint.wx - x
            elseif world then
                return nil, nil, "다른 대륙·인스턴스"
            end
        end
    end

    local position = Read(C_Map.GetPlayerMapPosition, waypoint.mapID, "player")
    if waypoint.width and not isSecret(position) and position and IsMapPoint(position.x, position.y) then
        return (waypoint.x - position.x) * waypoint.width, (position.y - waypoint.y) * waypoint.height
    end
end

local function UpdateGuide()
    local east, north, unavailable = GetOffset()
    local action = waypoint.action
    if not east then
        if action then
            heading:SetText(action .. " · " .. (unavailable or "거리 확인 불가"))
            arrow:Hide()
            guide:Show()
        else
            guide:Hide()
        end
        return
    end

    local distanceYards = math.sqrt(east * east + north * north)
    if distanceYards < 1 and not action then
        guide:Hide()
        return
    end

    -- Map Y increases southward. Player facing increases counterclockwise from north.
    local facing = Read(GetPlayerFacing)
    local showArrow = distanceYards >= 1 and IsReadableNumber(facing)
    if showArrow then arrow:SetRotation(-(math.atan2(east, north) + facing)) end
    arrow:SetShown(showArrow)
    local distance = ("%d m"):format(math.floor(distanceYards * metersPerYard + 0.5))
    if action then distance = action .. " · " .. (distanceYards < 1 and "도착" or distance) end
    heading:SetText(distance)
    guide:Show()
end

local elapsed = 0
local function OnUpdate(_, delta)
    elapsed = elapsed + delta
    if elapsed >= 0.2 then
        elapsed = 0
        UpdateGuide()
    end
end

local function FollowPoint(point, title, action)
    local width, height = Read(C_Map.GetMapWorldSize, point.mapID)
    if not (IsReadableNumber(width) and IsReadableNumber(height) and width > 0 and height > 0) then
        width, height = nil, nil
    end
    if not (width or point.world or action) then return end

    waypoint = {
        mapID = point.mapID, x = point.x, y = point.y, width = width, height = height,
        world = point.world, wx = point.wx, wy = point.wy, action = action,
    }
    caption:SetText(title)
    elapsed = 0
    events:SetScript("OnUpdate", OnUpdate)
    UpdateGuide()
    return true
end

local function TurnInName(entry)
    if entry.giver then return entry.giver end
    if entry.giverID then return ("%s #%d"):format(entry.giverKind == 1 and "NPC" or "물체", entry.giverID) end
    return "반납 대상 미확인"
end

local function FormatTurnIns(turnIns)
    local first = turnIns[1]
    local shared = first.giverID ~= nil
    local titles, lines = {}, {}
    for _, entry in ipairs(turnIns) do
        titles[entry.title] = (titles[entry.title] or 0) + 1
        shared = shared and first.giverID == entry.giverID and first.giverKind == entry.giverKind
    end
    if shared then
        local label = first.giverKind == 1 and "반납 NPC" or "반납 대상"
        lines[1] = label .. " · " .. TurnInName(first)
    end
    for _, entry in ipairs(turnIns) do
        local title = titles[entry.title] > 1 and ("%s (#%d)"):format(entry.title, entry.id) or entry.title
        lines[#lines + 1] = shared and title or (title .. " → " .. TurnInName(entry))
    end
    return table.concat(lines, "\n")
end

local function RefreshGuide(_, event)
    if event == "PLAYER_ENTERING_WORLD" then RestoreGuidePosition() end
    local showGuide = event ~= "PLAYER_LEAVING_WORLD" and helper.IsEnabled("screenGuide")
    local showRoute = showGuide and not moving and routeTracking
    local reason = showRoute and (routeStep and routeStep.reason or routeNotice) or nil
    routeReason:SetText(reason)
    routeReason:SetShown(reason ~= nil)
    local turnIns = showRoute and (pendingTurnIns or (routeStep and routeStep.turnIns))
    local hasTurnIns = turnIns and #turnIns > 0
    local anchor = reason and routeReason or caption
    turnInDetails:ClearAllPoints()
    turnInDetails:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
    turnInDetails:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -4)
    local details = hasTurnIns and FormatTurnIns(turnIns) or nil
    if details and not (routeStep and routeStep.turnIns) then
        details = ("공동 반납 · 남은 %d개\n"):format(#turnIns) .. details
    end
    turnInDetails:SetText(details)
    turnInDetails:SetShown(hasTurnIns == true)
    local height = reason and 72 or guideHeight
    if hasTurnIns then
        local start = reason and (54 + routeReason:GetStringHeight()) or 54
        height = math.max(height, start + turnInDetails:GetStringHeight())
    end
    guide:SetHeight(height)

    if moving and event ~= "PLAYER_LEAVING_WORLD" then
        heading:SetText("길 안내 위치")
        caption:SetText("드래그해서 옮긴 뒤 ‘이동 완료’를 누르세요.")
        arrow:Show()
        arrow:SetRotation(0)
        guide:Show()
        return
    end

    if showGuide then
        local playerMapID = Read(C_Map.GetBestMapForUnit, "player")
        if routeTracking then
            if routeStep then
                local point = routeStep.point
                local action = helper.HordeQuestPlan.GetStepLabel(routeStep)
                local title = routeStep.quest.title
                if point.entrance then title = point.entrance .. " 입구 · " .. title end
                local direction, floorName, up = helper.GetQuestFloorHint(playerMapID, point.mapID)
                if direction then
                    ShowFloorGuide(action .. " · " .. direction, floorName, up, title)
                else
                    FollowPoint(point, title, action)
                end
            else
                waypoint = nil
                events:SetScript("OnUpdate", nil)
                heading:SetText("추천 지점 대기")
                caption:SetText("캐릭터의 퀘스트 진행 상태를 확인하세요.")
                arrow:Hide()
                guide:Show()
            end
            return
        end

        local trackingPin = Read(C_SuperTrack.IsSuperTrackingUserWaypoint)
        if not isSecret(trackingPin) and trackingPin then
            local point = Read(C_Map.GetUserWaypoint)
            if not isSecret(point) and point then
                local direction, floorName, up = helper.GetQuestFloorHint(playerMapID, point.uiMapID)
                if direction then
                    ShowFloorGuide(direction, floorName, up, "선택한 지도 핀")
                    return
                end
                local position = point.position
                if IsReadableNumber(point.uiMapID) and not isSecret(position) and position
                    and IsMapPoint(position.x, position.y) then
                    local world, x, y = GetWorldPosition(point.uiMapID, position)
                    if FollowPoint({ mapID = point.uiMapID, x = position.x, y = position.y,
                        world = world, wx = x, wy = y }, "선택한 지도 핀") then return end
                end
            end
        elseif not isSecret(trackingPin) then
            local questID = Read(C_SuperTrack.GetSuperTrackedQuestID)
            if IsReadableNumber(questID) and questID > 0 and Read(C_QuestLog.IsOnQuest, questID) then
                local title = Read(C_QuestLog.GetTitleForQuestID, questID)
                if isSecret(title) or type(title) ~= "string" then title = "" end
                local direction, floorName, up = helper.GetQuestFloorHint(playerMapID, helper.GetQuestWaypointMap(questID))
                if direction then
                    ShowFloorGuide(direction, floorName, up, title)
                    return
                end
                if Read(C_QuestLog.IsComplete, questID) ~= true then
                    local mapID, x, y = FindQuestPoint(questID, playerMapID)
                    if mapID and FollowPoint({ mapID = mapID, x = x, y = y }, "퀘스트 안내 · " .. title) then return end
                end
            end
        end
    end

    waypoint = nil
    events:SetScript("OnUpdate", nil)
    guide:Hide()
end

function helper.SetRouteGuide(step, tracking, turnIns, notice)
    routeStep, routeTracking = step, tracking
    pendingTurnIns, routeNotice = turnIns, notice
    RefreshGuide()
end

function helper.FinishGuideMove()
    if not moving then return end
    FinishDrag()
    moving = false
    guide:EnableMouse(false)
    RefreshGuide()
end

function helper.ToggleGuideMove()
    if moving then
        helper.FinishGuideMove()
    else
        moving = true
        events:SetScript("OnUpdate", nil)
        guide:EnableMouse(true)
        RefreshGuide()
    end
    return moving
end

function helper.ResetGuidePosition()
    FinishDrag()
    helper.GetSettings().guidePosition = nil
    RestoreGuidePosition()
end

helper.OnFeatureChanged("screenGuide", RefreshGuide)
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_LEAVING_WORLD")
events:RegisterEvent("SUPER_TRACKING_CHANGED")
events:RegisterEvent("SUPER_TRACKING_PATH_UPDATED")
events:RegisterEvent("QUEST_LOG_UPDATE")
events:RegisterEvent("QUEST_POI_UPDATE")
events:RegisterEvent("PLAYER_MAP_CHANGED")
events:RegisterEvent("USER_WAYPOINT_UPDATED")
events:RegisterEvent("ZONE_CHANGED")
events:RegisterEvent("ZONE_CHANGED_INDOORS")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
events:SetScript("OnEvent", RefreshGuide)
