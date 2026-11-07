local ADDON_NAME, ns = ...
local L = ns.L

-- ==========================================
-- PINES DEL MAPA DEL MUNDO
-- ==========================================
-- Un proveedor de datos del mapa (MapCanvasDataProviderMixin), como en
-- DungeonQuestAtlas: todos los nodos guardados del mapa que estas viendo.
-- Mayus + clic derecho en un pin lo borra (un nodo mal puesto).
-- ponytail: en el mapa del continente no salen los nodos de sus zonas.

local TEMPLATE = "GatherRadarWorldMapPinTemplate"
local provider

local function CreatePinMixin()
    GatherRadarWorldMapPinMixin = CreateFromMixins(MapCanvasPinMixin)
    local mixin = GatherRadarWorldMapPinMixin

    function mixin:OnLoad()
        self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI")
        self:SetScalingLimits(1, 1.0, 1.2)
        ns.AddPinArt(self)
    end

    function mixin:OnAcquired(kind, map, coord, id)
        self.kind, self.map, self.coord, self.id = kind, map, coord, id
        ns.SetPinArt(self, id, ns.db.worldMapSize)
        self:SetPosition(ns.Decode(coord))
    end

    function mixin:OnMouseEnter()
        local x, y = ns.Decode(self.coord)
        ns.NodeTooltip(self, self.id, ("%.1f, %.1f"):format(x * 100, y * 100) .. "\n" .. L.PIN_DELETE)
    end

    function mixin:OnMouseLeave() GameTooltip:Hide() end

    function mixin:ShouldMouseButtonBePassthrough() return false end
    -- AcquirePin la llama siempre y en combate es protegida (ver DungeonQuestAtlas)
    mixin.SetPassThroughButtons = function() end

    function mixin:OnMouseClickAction(button)
        if button == "RightButton" and IsShiftKeyDown() then
            ns.RemoveNode(self.kind, self.map, self.coord)
        end
    end
end

local function CreateProvider()
    provider = CreateFromMixins(MapCanvasDataProviderMixin)

    function provider:RemoveAllData()
        self:GetMap():RemoveAllPinsByTemplate(TEMPLATE)
    end

    function provider:RefreshAllData()
        self:RemoveAllData()
        local map = self:GetMap():GetMapID()
        if not (map and ns.db.worldMap) then return end
        for _, kind in ipairs(ns.KIND_ORDER) do
            if ns.KindShown(kind) then
                ns.EachNode(kind, map, function(coord, id)
                    self:GetMap():AcquirePin(TEMPLATE, kind, map, coord, id)
                end)
            end
        end
    end

    WorldMapFrame:AddDataProvider(provider)
end

-- Boton redondo del mapa del mundo con un desplegable (DropdownButton +
-- SetupMenu), como el de DungeonQuestAtlas: que tipos salen en el mapa. Va en
-- la columna de botones de arriba a la izquierda, debajo de los del juego y del
-- de DungeonQuestAtlas; con la libreria de botones de otro addon, en su columna.
local mapButton

local function UpdateMapButton()
    if not mapButton then return end
    local any = false
    for _, kind in ipairs(ns.KIND_ORDER) do
        if ns.KindShown(kind) then any = true end
    end
    any = any and ns.db.worldMap
    mapButton.Icon:SetDesaturated(not any)
    mapButton.Icon:SetAlpha(any and 1 or 0.6)
end

function ns.RefreshWorldMap()
    UpdateMapButton()
    if provider and provider:GetMap() and provider:GetMap():IsShown() then provider:RefreshAllData() end
end

local function Toggle(get, set)
    return function()
        set(not get())
        ns.RefreshPins()
    end
end

local function SetupMenu(button)
    button:SetupMenu(function(_, root)
        root:CreateTitle(L.MAP_MENU_SHOW)
        for _, kind in ipairs(ns.KIND_ORDER) do
            local get = function() return ns.db.mapKinds[kind] end
            root:CreateCheckbox(L["KIND_" .. kind:upper()], get, Toggle(get, function(v) ns.db.mapKinds[kind] = v end))
        end
        root:CreateDivider()
        local shown = function() return ns.db.worldMap end
        root:CreateCheckbox(L.SHOW_WORLDMAP, shown, Toggle(shown, function(v) ns.db.worldMap = v end))
        root:CreateButton(L.MAP_MENU_OPTIONS, function()
            if not InCombatLockdown() then HideUIPanel(WorldMapFrame) end
            ns.OpenOptions()
        end)
    end)
end

local function PlaceAlone(button)
    local below = 0
    local pinButton = WorldMapTrackingPinButtonMixin and WorldMapTrackingPinButtonMixin.OnLoad
    for _, f in ipairs(WorldMapFrame.overlayFrames or {}) do
        if pinButton and f.OnLoad == pinButton then below = below + 1 end
    end
    if _G.DungeonQuestAtlasMapButton then below = below + 1 end
    button:SetPoint("TOPLEFT", WorldMapFrame:GetCanvasContainer(), "TOPLEFT", 3, -32 * below)
end

local function CreateMapButton()
    GatherRadarMapButtonMixin = {}
    function GatherRadarMapButtonMixin:OnLoad()
        self.Icon:SetAtlas(ns.KINDS.herb.atlas)
        SetupMenu(self)
    end
    function GatherRadarMapButtonMixin:OnEnter()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("|cffd597ffGatherRadar|r")
        GameTooltip:AddLine(L.MAP_BUTTON_TOOLTIP, 1, 1, 1)
        GameTooltip:Show()
    end
    function GatherRadarMapButtonMixin:OnLeave() GameTooltip:Hide() end
    function GatherRadarMapButtonMixin:Refresh() end -- la llama la libreria de botones al cambiar de mapa

    local krowi = LibStub and LibStub("Krowi_WorldMapButtons-1.4", true)
    if krowi then
        mapButton = krowi:Add("GatherRadarMapButtonTemplate", "DropdownButton")
    else
        mapButton = CreateFrame("DropdownButton", "GatherRadarMapButton", WorldMapFrame, "GatherRadarMapButtonTemplate")
        PlaceAlone(mapButton)
    end
    UpdateMapButton()
end

-- Al abrir el mapa la primera vez: ya han cargado los demas addons (DungeonQuestAtlas
-- crea su boton en ese mismo momento, antes por orden alfabetico)
local function MapButtonOnFirstShow()
    if mapButton or not WorldMapFrame.GetCanvasContainer then return end
    local ok, err = pcall(CreateMapButton)
    if not ok and ns.db.debug then print(ns.PREFIX .. tostring(err)) end
end

-- El mapa del mundo puede cargarse despues que el addon
function ns.SetupWorldMapPins()
    local function Setup()
        CreatePinMixin()
        CreateProvider()
        WorldMapFrame:HookScript("OnShow", MapButtonOnFirstShow)
    end
    if WorldMapFrame and MapCanvasDataProviderMixin then
        Setup()
    elseif EventUtil and EventUtil.ContinueOnAddOnLoaded then
        EventUtil.ContinueOnAddOnLoaded("Blizzard_WorldMap", Setup)
    end
end
