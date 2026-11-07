-- GatherRadar: hierbas, menas, tesoros y bancos de peces de WoW Forever en el
-- minimapa (con el icono de lo que dan) y en el mapa del mundo. Recuerda donde
-- estaba cada nodo (lo que recoges y lo que ve en el minimapa), comparte con el
-- grupo, guia con una flecha al mas cercano y lleva la cuenta de la sesion.
-- Importa GatherMate2_Data si el jugador lo tiene, sin duplicar.
--
-- Valores secretos: posicion, orientacion y rastreo se comprueban con
-- issecretvalue antes de usarlos (dentro de instancias pueden serlo).

local ADDON_NAME, ns = ...
local L = ns.L

ns.PREFIX = "|cffd597ffGatherRadar|r: "

local DEFAULTS = {
    kinds = { herb = true, ore = true, treasure = true, fish = true },
    mapKinds = { herb = true, ore = true, treasure = true, fish = true }, -- menu del boton del mapa
    importKinds = { herb = true, ore = true, treasure = true, fish = true }, -- que importa "Importar"
    minimap = true,
    worldMap = true,
    arrow = false,
    session = false,
    scan = true,
    saveSeen = true,
    share = true,
    hard = true, -- aro rojo y la flecha se salta lo que no puedes recoger
    minimapSize = 14,
    worldMapSize = 14,
    dedupe = 15,
}
ns.DEFAULTS = DEFAULTS

local function CopyDefaults(src, dst)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            CopyDefaults(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

-- Vuelve a los valores por defecto sin tocar nodos, nombres ni posiciones
function ns.ResetSettings()
    for k, v in pairs(DEFAULTS) do
        if type(v) == "table" then
            ns.db[k] = {}
            CopyDefaults(v, ns.db[k])
        else
            ns.db[k] = v
        end
    end
    ns.ApplySettings()
end

-- ==========================================
-- POSICION
-- ==========================================
-- Mapa y posicion (0-1) del jugador, o nil (instancias, valores secretos)
function ns.PlayerPosition()
    local map = C_Map.GetBestMapForUnit("player")
    if not map or issecretvalue(map) then return nil end
    local pos = C_Map.GetPlayerMapPosition(map, "player")
    if not pos or issecretvalue(pos) then return nil end
    local x, y = pos:GetXY()
    if not x or issecretvalue(x) or issecretvalue(y) or (x == 0 and y == 0) then return nil end
    return map, x, y
end

-- Radianes, antihorario desde el norte; nil si es secreto
function ns.Facing()
    local f = GetPlayerFacing()
    if not f or issecretvalue(f) then return nil end
    return f
end

-- Yardas del centro al borde del minimapa
function ns.ViewRadius()
    local r = C_Minimap and C_Minimap.GetViewRadius and C_Minimap.GetViewRadius()
    if not r or issecretvalue(r) or r <= 0 then return nil end
    return r
end

-- ==========================================
-- ARRANQUE
-- ==========================================
function ns.ApplySettings()
    if ns.RescanNow then ns.RescanNow() end
    if ns.RefreshPins then ns.RefreshPins() end
    if ns.UpdateArrow then ns.UpdateArrow() end
    if ns.UpdateSession then ns.UpdateSession() end
end

local function OnAddonLoaded()
    GatherRadarDB = GatherRadarDB or {}
    local db = GatherRadarDB
    CopyDefaults(DEFAULTS, db)
    db.nodes = db.nodes or {} -- [tipo][mapa][coord] = id
    db.names = db.names or {} -- nombre local (minusculas) -> id
    db.learned = db.learned or {} -- [id] = { kind, name, icon }
    db.nextLearned = db.nextLearned or 100000
    db.arrowPos = db.arrowPos or {}
    db.sessionPos = db.sessionPos or {}
    if db.dedupe < 5 then db.dedupe = 5 end
    ns.db = db

    ns.LoadItemNames()
    ns.SetupCollector()
    ns.SetupComm()
    ns.SetupWorldMapPins()
    ns.CreateOptions()
    ns.ApplySettings()
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("ADDON_LOADED")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:RegisterEvent("MINIMAP_UPDATE_TRACKING")
driver:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" then
        if name ~= ADDON_NAME then return end
        self:UnregisterEvent("ADDON_LOADED")
        OnAddonLoaded()
        -- Escaner y pines del minimapa, cada frame
        self:SetScript("OnUpdate", function(_, elapsed)
            ns.ScannerUpdate(elapsed)
            ns.MinimapPinsUpdate(elapsed)
        end)
    elseif ns.db then
        ns.RescanNow()
        ns.RefreshPins()
    end
end)

SLASH_GATHERRADAR1 = "/gr"
SLASH_GATHERRADAR2 = "/gatherradar"
SlashCmdList.GATHERRADAR = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "session" or msg == "sesion" then
        ns.db.session = not ns.db.session
        ns.UpdateSession()
    elseif msg == "arrow" or msg == "flecha" then
        ns.db.arrow = not ns.db.arrow
        ns.UpdateArrow()
    elseif msg == "import" then
        ns.ImportGatherMate()
    else
        ns.OpenOptions()
    end
end
