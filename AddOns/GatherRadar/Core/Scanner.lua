local ADDON_NAME, ns = ...

-- ==========================================
-- ESCANER DEL MINIMAPA
-- ==========================================
-- Un addon no puede preguntar donde estan las hierbas, pero el minimapa si
-- dice como se llama el punto que hay bajo el raton. Un raton falso
-- (Minimap:UpdateMouseoverAtPoint) recorre una rejilla sobre el minimapa y lee
-- su tooltip (C_TooltipInfo.GetMinimapMouseover).
--
-- 1. Rejilla cada STEP unidades: que nodo hay en cada punto.
-- 2. Los puntos seguidos del mismo nodo son un punto del minimapa; su centro se
--    afina buscando sus 4 bordes por biseccion (~1 yarda).
-- 3. Centro del minimapa -> yardas -> coordenadas del mapa, y a la base de datos.
--
-- Va en una corrutina con PER_FRAME sondeos por frame para no notarse.
-- ponytail: dos puntos iguales que se tocan cuentan como uno (centro entre
-- ambos); al recoger uno, la posicion buena lo corrige.

local STEP = 6 -- unidades del minimapa entre puntos de la rejilla
local PER_FRAME = 80
local WAIT_MOVING, WAIT_STILL = 1, 3 -- segundos entre escaneos
local REACH = 24 -- maximo radio de un punto del minimapa (unidades)
local LIVE = 8 -- segundos que un nodo visto cuenta como "esta ahi ahora"

local scanner -- corrutina en marcha
local wait = 0
local probes = 0
local lastX, lastY, lastFacing, lastRadius
ns.live = {}
ns.tracking = {}

local function LiveKey(kind, map, coord) return kind .. map .. ":" .. coord end

function ns.IsLive(kind, map, coord)
    local t = ns.live[LiveKey(kind, map, coord)]
    return t and GetTime() - t < LIVE
end

function ns.MarkLive(kind, map, coord) ns.live[LiveKey(kind, map, coord)] = GetTime() end
function ns.ClearLive(kind, map, coord) ns.live[LiveKey(kind, map, coord)] = nil end

-- Que buscadores (Buscar hierbas, minerales, tesoros, peces) estan activos
local function ReadTracking()
    wipe(ns.tracking)
    if not (C_Minimap.GetNumTrackingTypes and C_Minimap.GetTrackingInfo) then
        for kind in pairs(ns.KINDS) do ns.tracking[kind] = true end -- sin API: se escanea igual
        return
    end
    for i = 1, C_Minimap.GetNumTrackingTypes() do
        local info = C_Minimap.GetTrackingInfo(i)
        if info and not issecretvalue(info) and not issecretvalue(info.spellID) and not issecretvalue(info.active) then
            for kind, k in pairs(ns.KINDS) do
                if info.spellID == k.finder and info.active then ns.tracking[kind] = true end
            end
        end
    end
end

-- Quita colores y texturas de una linea del tooltip
local function Clean(text)
    text = text:gsub("|A.-|a", ""):gsub("|T.-|t", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    return text:match("^%s*(.-)%s*$")
end

-- IDs de los nodos bajo el punto x, y (unidades desde la esquina inferior izquierda)
local seen = {}
local function Probe(left, bottom, scale, x, y)
    wipe(seen)
    probes = probes + 1
    if probes >= PER_FRAME then
        probes = 0
        coroutine.yield()
    end
    Minimap:UpdateMouseoverAtPoint((left + x) * scale, (bottom + y) * scale)
    local data = C_TooltipInfo.GetMinimapMouseover()
    local lines = data and not issecretvalue(data) and data.lines
    if not lines or issecretvalue(lines) then return seen end
    for _, line in ipairs(lines) do
        local text = line.leftText
        if text and not issecretvalue(text) then
            for name in text:gmatch("[^\n]+") do
                local id = ns.IdByName(Clean(name))
                local kind = id and ns.KindOf(id)
                if kind and ns.db.kinds[kind] then seen[id] = true end
            end
        end
    end
    return seen
end

-- Distancia del centro cx, cy al borde del punto `id` en la direccion dx, dy
local function Edge(left, bottom, scale, id, cx, cy, dx, dy)
    local hit, miss = 0, nil
    for d = 2, REACH, 2 do
        if not Probe(left, bottom, scale, cx + dx * d, cy + dy * d)[id] then
            miss = d
            break
        end
        hit = d
    end
    if not miss then return hit end
    for _ = 1, 4 do
        local mid = (hit + miss) / 2
        if Probe(left, bottom, scale, cx + dx * mid, cy + dy * mid)[id] then hit = mid else miss = mid end
    end
    return (hit + miss) / 2
end

-- Grupos de puntos seguidos (8 vecinos) de la rejilla
local AROUND = { -1001, -1000, -999, -1, 1, 999, 1000, 1001 }
local function Groups(points)
    local groups, done = {}, {}
    for start in pairs(points) do
        if not done[start] then
            local group, queue = {}, { start }
            done[start] = true
            while #queue > 0 do
                local p = table.remove(queue)
                table.insert(group, p)
                for _, off in ipairs(AROUND) do
                    local q = p + off
                    if points[q] and not done[q] then
                        done[q] = true
                        table.insert(queue, q)
                    end
                end
            end
            table.insert(groups, group)
        end
    end
    return groups
end

-- Del centro del minimapa (unidades) a coordenadas del mapa del jugador
local function ToMap(ox, oy)
    local map, px, py = ns.PlayerPosition()
    local radius = ns.ViewRadius()
    if not (map and radius) then return nil end
    local yards = radius / (Minimap:GetWidth() / 2)
    local east, north = ox * yards, oy * yards
    if GetCVar("rotateMinimap") == "1" then
        local f = ns.Facing()
        if not f then return nil end
        east, north = east * math.cos(f) - north * math.sin(f), east * math.sin(f) + north * math.cos(f)
    end
    local w, h = ns.MapSize(map)
    return map, px + east / w, py - north / h
end

local function Scan()
    local left, bottom = Minimap:GetLeft(), Minimap:GetBottom()
    local scale = Minimap:GetEffectiveScale()
    local size = Minimap:GetWidth()
    local half = size / 2
    -- 1. Rejilla
    local hits = {} -- [id][gx * 1000 + gy] = true
    local limit = (half - 1) ^ 2
    for gx = 0, math.floor(size / STEP) do
        for gy = 0, math.floor(size / STEP) do
            local x, y = gx * STEP, gy * STEP
            if (x - half) ^ 2 + (y - half) ^ 2 <= limit then
                for id in pairs(Probe(left, bottom, scale, x, y)) do
                    hits[id] = hits[id] or {}
                    hits[id][gx * 1000 + gy] = true
                end
            end
        end
    end
    -- 2. Cada grupo, un punto; su centro afinado por los bordes
    for id, points in pairs(hits) do
        for _, group in ipairs(Groups(points)) do
            local sx, sy = 0, 0
            for _, p in ipairs(group) do
                sx, sy = sx + math.floor(p / 1000) * STEP, sy + p % 1000 * STEP
            end
            local cx, cy = sx / #group, sy / #group
            if Probe(left, bottom, scale, cx, cy)[id] then
                local r = Edge(left, bottom, scale, id, cx, cy, 1, 0)
                local l = Edge(left, bottom, scale, id, cx, cy, -1, 0)
                local u = Edge(left, bottom, scale, id, cx, cy, 0, 1)
                local d = Edge(left, bottom, scale, id, cx, cy, 0, -1)
                cx, cy = cx + (r - l) / 2, cy + (u - d) / 2
            end
            -- 3. A la base de datos
            local map, x, y = ToMap(cx - half, cy - half)
            local kind = ns.KindOf(id)
            if map and x >= 0 and x < 1 and y >= 0 and y < 1 then
                local coord, isNew, temp = ns.AddNode(kind, map, x, y, id, "seen")
                if coord then
                    ns.MarkLive(kind, map, coord)
                    if isNew then
                        if ns.OnNewNode then ns.OnNewNode(kind, map, coord, id) end
                        if not temp and ns.ShareNode then ns.ShareNode(kind, map, coord, id) end
                    end
                end
            end
        end
    end
end

-- Algo que ver: escaneo activado, minimapa visible y un buscador encendido
local function CanScan()
    if not (ns.db.scan and Minimap:IsVisible() and Minimap:GetLeft()) then return false end
    if not (Minimap.UpdateMouseoverAtPoint and C_TooltipInfo and C_TooltipInfo.GetMinimapMouseover) then return false end
    ReadTracking()
    for kind in pairs(ns.tracking) do
        if ns.db.kinds[kind] then return true end
    end
    return false
end

-- Quieto (misma posicion, giro y zoom) se escanea menos
local function Still()
    local _, x, y = ns.PlayerPosition()
    local f, r = ns.Facing(), ns.ViewRadius()
    local still = x == lastX and y == lastY and f == lastFacing and r == lastRadius
    lastX, lastY, lastFacing, lastRadius = x, y, f, r
    return still
end

local function Resume()
    if Minimap.SetUsingSoftCursor then Minimap:SetUsingSoftCursor(true) end
    local ok, err = coroutine.resume(scanner)
    if Minimap.SetUsingSoftCursor then Minimap:SetUsingSoftCursor(false) end
    if not ok then
        scanner = nil
        if ns.db.debug then print(ns.PREFIX .. tostring(err)) end
    elseif coroutine.status(scanner) == "dead" then
        scanner = nil
    end
end

function ns.ScannerUpdate(elapsed)
    if scanner then return Resume() end
    wait = wait - elapsed
    if wait > 0 then return end
    wait = Still() and WAIT_STILL or WAIT_MOVING
    if not CanScan() then return end
    probes = 0
    scanner = coroutine.create(Scan)
    Resume()
end

-- Tras una pantalla de carga o un cambio de opciones: escanear ya
function ns.RescanNow()
    scanner = nil
    wait = 0
end
