local _, ns = ...
local Read, empty = ns.Read, {}
local pinTemplate = "ForeverFlightPointPinTemplate"
local provider, refreshQueued

ForeverFlightPointPinMixin = {}

function ForeverFlightPointPinMixin:OnAcquired(point)
    self.point = point
    self:SetAlpha(point.dim and 0.55 or 1)
    self:SetPosition(point.x, point.y)
end

function ForeverFlightPointPinMixin:OnMouseEnter()
    local point = self.point
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(point.name or "비행지점", 0.4, 0.8, 1)
    local text, r, g, b = ns.StateText(point.state)
    if text then GameTooltip:AddLine(text, r, g, b) end
    if point.remembered then GameTooltip:AddLine("이전에 기록한 위치", 0.7, 0.7, 0.7) end
    GameTooltip:Show()
end

function ForeverFlightPointPinMixin:OnMouseLeave()
    if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
end

function ForeverFlightPointPinMixin:OnReleased()
    self:OnMouseLeave()
    self.point = nil
    MapCanvasPinMixin.OnReleased(self)
end

-- Remembered nodes belong to the map they were seen on; other maps get them through world coordinates.
local function ConvertToMap(node, mapID)
    if node.mapID == mapID then return node.x, node.y end
    if not (C_Map and C_Map.GetWorldPosFromMapPos and C_Map.GetMapPosFromWorldPos and CreateVector2D) then return end
    local instance, world = Read(C_Map.GetWorldPosFromMapPos, node.mapID, CreateVector2D(node.x, node.y))
    if not world then return end
    local _, pos = Read(C_Map.GetMapPosFromWorldPos, instance, world, mapID)
    if type(pos) == "table" and pos.x and pos.y and pos.x > 0 and pos.x < 1 and pos.y > 0 and pos.y < 1 then
        return pos.x, pos.y
    end
end

local function Draw(map, mapID)
    provider:RemoveAllData()
    local live = ns.CollectNodes(mapID)
    ns.Remember(mapID, live)
    local shown = {}
    for _, node in pairs(live) do
        if node.nodeID then shown[node.nodeID] = true end
        local enum = Enum and Enum.FlightPathState
        node.dim = enum and node.state == enum.Unreachable or false
        map:AcquirePin(pinTemplate, node)
    end
    for nodeID, node in pairs(ns.GetDB().nodes) do
        if not shown[nodeID] and type(node) == "table" and node.mapID then
            local x, y = ConvertToMap(node, mapID)
            if x then
                map:AcquirePin(pinTemplate, { nodeID = nodeID, name = node.name, x = x, y = y, remembered = true })
            end
        end
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
            if not map:IsShown() or not ns.IsEnabled() then
                self:RemoveAllData()
                return
            end
            local mapID = map:GetMapID()
            if mapID then Draw(map, mapID) end
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

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("TAXI_NODE_STATUS_CHANGED")
events:RegisterEvent("TAXIMAP_OPENED")
events:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" then
        if addonName == "Blizzard_WorldMap" then AttachProvider() end
    elseif event == "TAXIMAP_OPENED" or event == "TAXI_NODE_STATUS_CHANGED" then
        local mapID = Read(GetTaxiMapID)
        if mapID then ns.Remember(mapID, ns.CollectNodes(mapID)) end
        ns.RefreshPins()
    else
        AttachProvider()
    end
end)
if WorldMapFrame then AttachProvider() end
