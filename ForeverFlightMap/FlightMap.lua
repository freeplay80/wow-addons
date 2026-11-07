local _, ns = ...
local isSecret = issecretvalue or function() return false end
local empty = {}

local function Public(value)
    if not isSecret(value) then return value end
end

local function Read(func, ...)
    if type(func) ~= "function" then return end
    local ok, a, b = pcall(func, ...)
    if ok then return Public(a), Public(b) end
end
ns.Read = Read

function ns.GetDB()
    if type(ForeverFlightMapDB) ~= "table" then ForeverFlightMapDB = {} end
    local db = ForeverFlightMapDB
    db.nodes = type(db.nodes) == "table" and db.nodes or {}
    return db
end

function ns.IsEnabled()
    return type(ForeverFlightMapDB) ~= "table" or ForeverFlightMapDB.pins ~= false
end

-- Official source first: C_TaxiMap. The two calls differ in which nodes they list, so both are merged.
-- The fields below follow the retail structure names; the Forever API text lists no field names, so every
-- field is read defensively and `/ffm dump` shows what the client really returns (NOT_TESTED in game).
local function Position(node)
    local pos = type(node.position) == "table" and node.position or nil
    local x = pos and (pos.x or pos[1]) or node.x
    local y = pos and (pos.y or pos[2]) or node.y
    -- The client lists nodes of the whole continent for any zone map; coordinates outside 0..1 are off this map.
    if type(x) == "number" and type(y) == "number" and x >= 0 and x <= 1 and y >= 0 and y <= 1 and not (x == 0 and y == 0) then
        return x, y
    end
end

-- Observed with /ffm dump: faction 1 = Horde nodes, 2 = Alliance nodes (inferred from node names; no official enum text).
local function IsOtherFaction(faction)
    local group = Read(UnitFactionGroup, "player")
    if group == "Horde" then return faction == 2 end
    if group == "Alliance" then return faction == 1 end
    return false
end

function ns.CollectNodes(mapID)
    local found = {}
    for _, getter in ipairs({ C_TaxiMap and C_TaxiMap.GetTaxiNodesForMap, C_TaxiMap and C_TaxiMap.GetAllTaxiNodes }) do
        local list = Read(getter, mapID)
        if type(list) == "table" then
            for _, node in ipairs(list) do
                if type(node) == "table" then
                    local x, y = Position(node)
                    if x and not IsOtherFaction(node.faction) then
                        local key = node.nodeID or (tostring(node.name) .. ":" .. x .. ":" .. y)
                        if not found[key] then
                            found[key] = { nodeID = node.nodeID, name = node.name, x = x, y = y, state = node.state, faction = node.faction }
                        end
                    end
                end
            end
        end
    end
    return found
end

-- Nodes seen once are remembered so they still show when the client stops listing them.
function ns.Remember(mapID, nodes)
    local store = ns.GetDB().nodes
    for key, node in pairs(nodes) do
        if node.nodeID then
            store[node.nodeID] = { mapID = mapID, name = node.name, x = node.x, y = node.y, faction = node.faction }
        end
    end
end

local function StateText(state)
    local enum = Enum and Enum.FlightPathState
    if enum and state == enum.Current then return "현재 위치", 0.4, 1, 0.5 end
    if enum and state == enum.Reachable then return "이용 가능", 0.5, 0.9, 1 end
    if enum and state == enum.Unreachable then return "아직 발견하지 못함", 0.6, 0.6, 0.6 end
end
ns.StateText = StateText

SLASH_FOREVERFLIGHTMAP1 = "/ffm"
SlashCmdList.FOREVERFLIGHTMAP = function(message)
    local cmd = strlower(strtrim(message or ""))
    local db = ns.GetDB()
    if cmd == "dump" then
        local mapID = WorldMapFrame and WorldMapFrame:IsShown() and WorldMapFrame:GetMapID() or Read(C_Map.GetBestMapForUnit, "player")
        local nodes = mapID and ns.CollectNodes(mapID) or {}
        local count = 0
        for _, node in pairs(nodes) do
            count = count + 1
            if count <= 10 then
                print(("|cff66ccffFlightMap|r %s (%.3f, %.3f) state=%s faction=%s"):format(
                    tostring(node.name), node.x, node.y, tostring(node.state), tostring(node.faction)))
            end
        end
        print(("|cff66ccffFlightMap|r 지도 %s에서 비행지점 %d개를 읽었습니다."):format(tostring(mapID), count))
    elseif cmd == "pins" then
        db.pins = db.pins == false
        print("|cff66ccffFlightMap|r 지도 표시: " .. (db.pins == false and "꺼짐" or "켜짐"))
        if ns.RefreshPins then ns.RefreshPins() end
    else
        local saved = 0
        for _ in pairs(db.nodes) do saved = saved + 1 end
        print(("|cff66ccffFlightMap|r 지도 표시 %s · 기록한 비행지점 %d개"):format(db.pins == false and "꺼짐" or "켜짐", saved))
        print("/ffm pins  지도 표시 켜기/끄기   /ffm dump  현재 지도에서 읽은 값 확인")
    end
end
