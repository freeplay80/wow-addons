local _, helper = ...
local isSecret = issecretvalue or function() return false end

local function IsNumber(value)
    return not isSecret(value) and type(value) == "number" and value == value
end

local function Read(func, ...)
    if not func then return end
    local ok, first, second, third = pcall(func, ...)
    if ok and not (isSecret(first) or isSecret(second) or isSecret(third)) then
        return first, second, third
    end
end

function helper.GetQuestFloorHint(playerMapID, destinationMapID)
    if not IsNumber(playerMapID) or not IsNumber(destinationMapID)
        or playerMapID <= 0 or destinationMapID <= 0 or playerMapID == destinationMapID then return end

    local groupID = Read(C_Map.GetMapGroupID, playerMapID)
    if not IsNumber(groupID) or groupID <= 0 then return end
    local members = Read(C_Map.GetMapGroupMembersInfo, groupID)
    if type(members) ~= "table" then return end

    local playerFloor, destinationFloor, destinationName
    for _, member in ipairs(members) do
        if not isSecret(member) and IsNumber(member.mapID) and IsNumber(member.relativeHeightIndex) then
            if member.mapID == playerMapID then
                playerFloor = member.relativeHeightIndex
            elseif member.mapID == destinationMapID then
                destinationFloor = member.relativeHeightIndex
                if not isSecret(member.name) and type(member.name) == "string" and member.name ~= "" then
                    destinationName = member.name
                end
            end
        end
    end

    -- A floor index is only comparable inside one map group.
    if playerFloor and destinationFloor and playerFloor ~= destinationFloor then
        local up = destinationFloor > playerFloor
        return up and "위층으로" or "아래층으로", destinationName, up
    end
end

function helper.GetQuestWaypointMap(questID)
    local mapID, x, y = Read(C_QuestLog.GetNextWaypoint, questID)
    if IsNumber(mapID) and mapID > 0 and IsNumber(x) and IsNumber(y)
        and x >= 0 and x <= 1 and y >= 0 and y <= 1 and (x > 0 or y > 0) then
        return mapID
    end
end
