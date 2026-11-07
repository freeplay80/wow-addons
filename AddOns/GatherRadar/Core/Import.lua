local ADDON_NAME, ns = ...
local L = ns.L

-- ==========================================
-- IMPORTAR NODOS DE WOWHEAD
-- ==========================================
-- Solo si el jugador lo pide (boton en Opciones o /gr import), y solo los tipos
-- marcados en Datos (importKinds). Los nodos de WoW Forever van incluidos en
-- Data/Import*.lua (ns.IMPORT_DATA), con el mismo formato que nuestra base de
-- datos: hierbas, menas y tesoros de GatherMate2_Data (Wowhead) y bancos de peces
-- de AzerothCore (GatherMate2_Data no trae peces). No hace falta GatherMate2,
-- que GatherMate2_Data exige para cargar. Si GatherMate2
-- esta instalado, tambien se traen los nodos que el jugador guardo con el
-- (GatherMate2HerbDB...). Solo se anaden los que faltan: lo que ya tienes no
-- se toca y lo que cae cerca de un nodo tuyo se descarta.
-- ponytail: los datos ocupan ~600 KB siempre cargados; addon LoadOnDemand
-- aparte si la memoria importa.

local GM2_DBS = { herb = "GatherMate2HerbDB", ore = "GatherMate2MineDB", treasure = "GatherMate2TreasureDB", fish = "GatherMate2FishDB" }

local function Known(kind)
    return function(id) return ns.NODES[id] ~= nil and ns.NODES[id].kind == kind end
end

function ns.ImportGatherMate()
    local data = ns.IMPORT_DATA or {}
    local lines = {}
    for _, kind in ipairs(ns.KIND_ORDER) do
        if ns.db.importKinds[kind] then
            local added = 0
            for _, source in ipairs({ data[kind], _G[GM2_DBS[kind]] }) do
                if type(source) == "table" then added = added + ns.ImportKind(kind, source, Known(kind)) end
            end
            table.insert(lines, L["KIND_" .. kind:upper()] .. ": " .. added)
        end
    end
    if #lines == 0 then return print(ns.PREFIX .. L.IMPORT_NONE) end
    print(ns.PREFIX .. L.IMPORT_DONE .. " " .. table.concat(lines, ", "))
end
