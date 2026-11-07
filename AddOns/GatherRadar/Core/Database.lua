local ADDON_NAME, ns = ...

-- ==========================================
-- BASE DE DATOS DE NODOS
-- ==========================================
-- GatherRadarDB.nodes[tipo][mapa][coord] = id, con la coordenada codificada
-- como en GatherMate2 (xxxx yyyy 00 sobre 10.000): los datos de
-- GatherMate2_Data se copian sin convertir.
--
-- Sin duplicados: dos nodos del mismo tipo a menos de db.dedupe yardas son el
-- mismo sitio y se queda uno.
--   gathered (recogido): la posicion buena; mueve el que hubiera ahi
--   seen (visto en el minimapa): actualiza que hay, sin mover el sitio
--   shared / import (grupo, GatherMate2_Data): solo entra si falta
--
-- Con "Guardar nodos vistos" apagado lo visto va a ns.temp, que se borra al
-- salir del juego.

ns.temp = {}

function ns.Encode(x, y)
    x = math.min(math.max(x, 0), 0.9999)
    y = math.min(math.max(y, 0), 0.9999)
    return math.floor(x * 10000 + 0.5) * 1000000 + math.floor(y * 10000 + 0.5) * 100
end

function ns.Decode(coord)
    return math.floor(coord / 1000000) / 10000, math.floor(coord % 1000000 / 100) / 10000
end

-- Tamano del mapa en yardas. Sin el (algunos mapas de ciudad) se toma 1000:
-- ponytail: dedupe aproximado en mapas sin tamano, mirar C_Map si hiciera falta
local sizes = {}
function ns.MapSize(map)
    local size = sizes[map]
    if not size then
        local w, h = C_Map.GetMapWorldSize(map)
        if not (w and h) or w <= 0 or h <= 0 then w, h = 1000, 1000 end
        size = { w, h }
        sizes[map] = size
    end
    return size[1], size[2]
end

local function Zone(store, kind, map, create)
    local byKind = store[kind]
    if not byKind then
        if not create then return nil end
        byKind = {}
        store[kind] = byKind
    end
    local zone = byKind[map]
    if not zone and create then
        zone = {}
        byKind[map] = zone
    end
    return zone
end

-- El nodo mas cercano a x, y dentro del radio de duplicados: coord, id
local function Nearest(zone, x, y, w, h, radius)
    if not zone then return nil end
    local best, bestId, bestGap = nil, nil, radius * radius
    for coord, id in pairs(zone) do
        local nx, ny = ns.Decode(coord)
        local dx, dy = (nx - x) * w, (ny - y) * h
        local gap = dx * dx + dy * dy
        if gap <= bestGap then best, bestId, bestGap = coord, id, gap end
    end
    return best, bestId
end

-- Devuelve la coordenada guardada, si es nuevo y si estaba en ns.temp
function ns.AddNode(kind, map, x, y, id, source)
    if not (kind and map and x and y and id) then return nil end
    local w, h = ns.MapSize(map)
    local radius = ns.db.dedupe
    local zone = Zone(ns.db.nodes, kind, map, false)
    local temp = Zone(ns.temp, kind, map, false)
    local coord, old = Nearest(zone, x, y, w, h, radius)
    local inTemp = false
    if not coord then
        coord, old = Nearest(temp, x, y, w, h, radius)
        inTemp = coord ~= nil
    end

    if coord then
        local here = inTemp and temp or zone
        if source == "gathered" then
            -- La posicion buena es la de quien lo recoge: lo de ahi se mueve aqui
            here[coord] = nil
            coord = ns.Encode(x, y)
            Zone(ns.db.nodes, kind, map, true)[coord] = id
            inTemp = false
            ns.NodesChanged(map)
        elseif source == "seen" and old ~= id then
            here[coord] = id -- otro nodo del mismo punto de aparicion
            ns.NodesChanged(map)
        end
        return coord, false, inTemp
    end

    local persist = source ~= "seen" or ns.db.saveSeen
    local store = persist and ns.db.nodes or ns.temp
    coord = ns.Encode(x, y)
    Zone(store, kind, map, true)[coord] = id
    ns.NodesChanged(map)
    return coord, true, not persist
end

function ns.RemoveNode(kind, map, coord)
    for _, store in ipairs({ ns.db.nodes, ns.temp }) do
        local zone = Zone(store, kind, map, false)
        if zone then zone[coord] = nil end
    end
    ns.NodesChanged(map)
end

-- fn(coord, id) por cada nodo guardado o visto de ese tipo en ese mapa
function ns.EachNode(kind, map, fn)
    local zone = Zone(ns.db.nodes, kind, map, false)
    if zone then for coord, id in pairs(zone) do fn(coord, id) end end
    zone = Zone(ns.temp, kind, map, false)
    if zone then for coord, id in pairs(zone) do fn(coord, id) end end
end

-- Lo que se pinta (minimapa, mapa del mundo y flecha): lo activo en General,
-- que es lo que se detecta y se guarda, y marcado en el menu del boton del mapa
function ns.KindShown(kind)
    return ns.db.kinds[kind] and ns.db.mapKinds[kind]
end

-- ==========================================
-- IMPORTAR Y LIMPIAR (muchos nodos de golpe)
-- ==========================================
-- Rejilla con celdas del tamano del radio: cada nodo solo se compara con los
-- de su celda y las 8 de alrededor.

local function Grid(w, h, radius)
    local cellX, cellY = radius / w, radius / h
    local cells = {}
    local grid = {}

    local function CellOf(x, y) return math.floor(x / cellX), math.floor(y / cellY) end

    function grid.Near(x, y)
        local cx, cy = CellOf(x, y)
        local r2 = radius * radius
        for i = cx - 1, cx + 1 do
            for j = cy - 1, cy + 1 do
                local cell = cells[i * 100000 + j]
                if cell then
                    for _, p in ipairs(cell) do
                        local dx, dy = (p[1] - x) * w, (p[2] - y) * h
                        if dx * dx + dy * dy <= r2 then return true end
                    end
                end
            end
        end
        return false
    end

    function grid.Put(x, y)
        local cx, cy = CellOf(x, y)
        local key = cx * 100000 + cy
        cells[key] = cells[key] or {}
        table.insert(cells[key], { x, y })
    end

    return grid
end

-- Junta en zone los nodos de incoming que no tengan uno cerca; devuelve cuantos
-- entraron. accept(id) filtra los IDs que no conocemos.
local function Merge(zone, incoming, w, h, radius, accept)
    local grid = Grid(w, h, radius)
    for coord in pairs(zone) do grid.Put(ns.Decode(coord)) end
    local added = 0
    for coord, id in pairs(incoming) do
        if type(coord) == "number" and type(id) == "number" and (not accept or accept(id)) then
            local x, y = ns.Decode(coord)
            if x >= 0 and x < 1 and y >= 0 and y < 1 and not grid.Near(x, y) then
                zone[coord] = id
                grid.Put(x, y)
                added = added + 1
            end
        end
    end
    return added
end
ns.Merge = Merge

-- source[mapa][coord] = id (formato GatherMate2). Devuelve los nodos nuevos.
function ns.ImportKind(kind, source, accept)
    local added = 0
    for map, nodes in pairs(source) do
        if type(map) == "number" and type(nodes) == "table" then
            local w, h = ns.MapSize(map)
            added = added + Merge(Zone(ns.db.nodes, kind, map, true), nodes, w, h, ns.db.dedupe, accept)
        end
    end
    ns.NodesChanged()
    return added
end

-- Quita los duplicados que ya hubiera (p. ej. tras subir el radio). Devuelve
-- cuantos se borraron.
function ns.Cleanup()
    local removed = 0
    for kind, maps in pairs(ns.db.nodes) do
        for map, zone in pairs(maps) do
            local w, h = ns.MapSize(map)
            local before = 0
            for _ in pairs(zone) do before = before + 1 end
            local kept = {}
            maps[map] = kept
            removed = removed + before - Merge(kept, zone, w, h, ns.db.dedupe)
        end
    end
    ns.NodesChanged()
    return removed
end

function ns.Count(kind)
    local total = 0
    for _, zone in pairs(ns.db.nodes[kind] or {}) do
        for _ in pairs(zone) do total = total + 1 end
    end
    return total
end

function ns.ClearZone(map)
    for _, store in ipairs({ ns.db.nodes, ns.temp }) do
        for _, maps in pairs(store) do maps[map] = nil end
    end
    ns.NodesChanged(map)
end

function ns.ClearAll()
    wipe(ns.db.nodes)
    wipe(ns.temp)
    ns.NodesChanged()
end

-- Olvidar todo: nodos, nombres e iconos aprendidos y la sesion. Los ajustes se
-- quedan (para eso esta "Valores por defecto").
function ns.ForgetAll()
    ns.ClearAll()
    wipe(ns.db.names)
    wipe(ns.db.learned)
    ns.db.nextLearned = 100000
    if ns.live then wipe(ns.live) end
    if ns.ResetSession then ns.ResetSession() end
end

-- Avisos a los pines: se juntan y se repintan una vez por frame
local pending = false
function ns.NodesChanged()
    if pending or not C_Timer then return end
    pending = true
    C_Timer.After(0, function()
        pending = false
        if ns.RefreshPins then ns.RefreshPins() end
    end)
end
