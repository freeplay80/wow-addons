local _, ns = ...
local Read, empty = ns.Read, {}
local pinTemplate = "ForeverClassTrainerPinTemplate"
local trainerFlag = 16
local provider, indexed, indexedClass, worker, refreshQueued, indexIssue

local function GetProvider()
    local db = LibQuestieDB
    if type(db) ~= "table" then return nil, nil, "QuestieDB가 없어 방문한 훈련사만 표시합니다." end
    if db.flavor and (type(db.flavor) ~= "table" or db.flavor.name ~= "Forever") then
        return nil, nil, "QuestieDB가 포에버용이 아니어서 방문한 훈련사만 표시합니다."
    end
    local zones = Read(type(db.Support) == "table" and db.Support.Get, "ZoneDB")
    if type(zones) ~= "table" or type(zones.private) ~= "table"
        or type(zones.private.areaIdToUiMapId) ~= "string" then
        return nil, nil, "QuestieDB 지도 데이터를 읽을 수 없어 방문한 훈련사만 표시합니다."
    end
    if type(db.Npc) ~= "table" or type(db.Npc.GetAllIds) ~= "function" then
        return nil, nil, "QuestieDB API가 달라 방문한 훈련사만 표시합니다."
    end
    return db, zones.private
end

local function AddPoint(maps, mapID, npcID, name, subName, x, y)
    if type(mapID) ~= "number" or type(x) ~= "number" or type(y) ~= "number" then return end
    local list = maps[mapID] or {}
    maps[mapID] = list
    for _, point in ipairs(list) do
        if point.npcID == npcID and math.abs(point.x - x) < 0.01 and math.abs(point.y - y) < 0.01 then return end
    end
    list[#list + 1] = { npcID = npcID, name = name, subName = subName, x = x, y = y }
end

-- Class trainers are NPCs with the trainer flag whose subname names the player's class.
local function IndexTrainers(class, names, faction)
    local maps = {}
    local db, zones = GetProvider()
    if db then
        local areaMaps = assert(loadstring(zones.areaIdToUiMapId))()
        local npc = db.Npc
        local hostile = faction == "Horde" and "A" or faction == "Alliance" and "H" or nil
        local count = 0
        for _, id in ipairs(npc.GetAllIds()) do
            count = count + 1
            if count % 1500 == 0 then coroutine.yield() end
            local flags = npc.npcFlags(id)
            if type(flags) == "number" and bit.band(flags, trainerFlag) ~= 0 then
                local sub = npc.subName(id)
                if ns.TextNamesClass(sub, names) and npc.friendlyToFaction(id) ~= hostile then
                    for area, coordinates in pairs(npc.spawns(id) or empty) do
                        for _, coordinate in ipairs(coordinates) do
                            local x, y, phase = unpack(coordinate)
                            if (not phase or phase == 0) and x ~= -1 and y ~= -1 then
                                AddPoint(maps, areaMaps[area], id, npc.name(id), sub, x / 100, y / 100)
                            end
                        end
                    end
                end
            end
        end
    end
    for npcID, record in pairs(ns.GetDB().trainers[class] or empty) do
        if type(record) == "table" then
            AddPoint(maps, record.mapID, npcID, record.name, nil, record.x, record.y)
        end
    end
    return maps
end

ForeverClassTrainerPinMixin = {}

function ForeverClassTrainerPinMixin:OnAcquired(point)
    self.point = point
    self:SetAlpha(1)
    self:SetPosition(point.x, point.y)
end

function ForeverClassTrainerPinMixin:OnMouseEnter()
    local point = self.point
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(point.name or "직업 훈련사", 1, 0.82, 0.42)
    GameTooltip:AddLine(point.subName or "직업 훈련사", 0.76, 0.84, 0.88)
    local list = ns.GetLearnable()
    if #list > 0 then
        GameTooltip:AddLine(("지금 배울 수 있는 스킬 %d개"):format(#list), 0.52, 1, 0.6)
        for index, entry in ipairs(list) do
            if index > 8 then
                GameTooltip:AddLine(("외 %d개"):format(#list - 8), 0.7, 0.7, 0.7)
                break
            end
            local label = entry.rank ~= "" and (entry.name .. " (" .. entry.rank .. ")") or entry.name
            GameTooltip:AddLine("레벨 " .. (entry.level or 0) .. " · " .. label, 0.9, 0.9, 0.9)
        end
    end
    GameTooltip:Show()
end

function ForeverClassTrainerPinMixin:OnMouseLeave()
    if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
end

function ForeverClassTrainerPinMixin:OnReleased()
    self:OnMouseLeave()
    self.point = nil
    MapCanvasPinMixin.OnReleased(self)
end

local function StartIndex(class, names)
    local faction = Read(UnitFactionGroup, "player")
    local task = coroutine.create(IndexTrainers)
    worker = task
    local first = true
    local function Resume()
        if worker ~= task then return end
        local started = debugprofilestop()
        repeat
            local ok, result
            if first then
                first = false
                ok, result = coroutine.resume(task, class, names, faction)
            else
                ok, result = coroutine.resume(task)
            end
            if not ok or coroutine.status(task) == "dead" then
                worker = nil
                indexed = ok and result or {}
                indexedClass = class
                indexIssue = nil
                if not ok then
                    indexIssue = "훈련사 위치를 읽지 못했습니다. QuestieDB 설치 상태를 확인하세요."
                    geterrorhandler()(result)
                end
                if provider then provider:RefreshAllData() end
                if ns.OnIndexReady then ns.OnIndexReady() end
                return
            end
        until debugprofilestop() - started >= 4
        C_Timer.After(0, Resume)
    end
    C_Timer.After(0, Resume)
end

-- Builds the trainer index on demand; the map and the HUD both use it.
function ns.EnsureIndex()
    local class, names = ns.GetClass()
    if not class then return end
    if indexedClass and indexedClass ~= class then indexed, indexedClass = nil, nil end
    if not indexed and not worker then StartIndex(class, names) end
end

-- Flat list of this class's trainer points ({ mapID, x, y, name, npcID }); the second value says if indexing finished.
function ns.GetTrainerPoints()
    local list = {}
    for mapID, points in pairs(indexed or empty) do
        for _, point in ipairs(points) do
            point.mapID = mapID
            list[#list + 1] = point
        end
    end
    return list, indexed ~= nil
end

local function Draw(map, mapID)
    provider:RemoveAllData()
    for _, point in ipairs(indexed and indexed[mapID] or empty) do
        map:AcquirePin(pinTemplate, point)
    end
end

local function AttachProvider()
    if provider or not WorldMapFrame then return end
    provider = CreateFromMixins(MapCanvasDataProviderMixin)

    function provider:RemoveAllData()
        self:GetMap():RemoveAllPinsByTemplate(pinTemplate)
    end

    function provider:RefreshAllData()
        if refreshQueued then return end
        refreshQueued = true
        C_Timer.After(0, function()
            refreshQueued = nil
            local map = self:GetMap()
            if not map:IsShown() or not ns.IsEnabled("pins") then
                self:RemoveAllData()
                return
            end
            ns.EnsureIndex()
            if indexed then Draw(map, map:GetMapID()) end
        end)
    end

    function provider:OnMapChanged()
        self:RemoveAllData()
        self:RefreshAllData()
    end

    function provider:OnHide()
        self:RemoveAllData()
    end

    WorldMapFrame:AddDataProvider(provider)
    provider:RefreshAllData()
end

function ns.RefreshPins()
    if provider then provider:RefreshAllData() end
end

-- A newly visited trainer must show up without a reload.
function ns.OnTrainerRecorded()
    indexed, indexedClass, worker = nil, nil, nil
    ns.EnsureIndex()
    ns.RefreshPins()
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" then
        if addonName == "Blizzard_WorldMap" then AttachProvider() end
    else
        AttachProvider()
    end
end)
if WorldMapFrame then AttachProvider() end
