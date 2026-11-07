local ADDON_NAME, ns = ...

-- ==========================================
-- RECOLECCION
-- ==========================================
-- Al saquear un objeto del mundo (GameObject) se apunta el nodo en tu posicion,
-- que es la buena: corrige la que diera el minimapa. Que nodo era sale del
-- botin (la hierba o la mena que da) y de su nombre, que llega con
-- UNIT_SPELLCAST_SENT (el objetivo del hechizo de recoger o abrir). Ese
-- nombre, en el idioma del cliente, se aprende para reconocerlo luego en el
-- minimapa.
--
-- Los bancos de peces no: el botin sale del corcho, no del banco. Se guardan
-- desde el minimapa (Buscar peces).

local TRADE_GOODS, HERB, METAL_AND_STONE = 7, 9, 7 -- clase y subclases de objeto
local CAST_VALID = 10 -- segundos que vale el nombre del ultimo objetivo

local castTarget, castTime = nil, 0
local lastSource

-- Objetos del botin: { item, icon, count, kind }
local function ReadLoot()
    local loot = {}
    for slot = 1, GetNumLootItems() do
        local link = GetLootSlotLink(slot)
        if link and not issecretvalue(link) then
            local item, _, _, _, icon, class, subclass = C_Item.GetItemInfoInstant(link)
            local _, _, count = GetLootSlotInfo(slot)
            if issecretvalue(count) then count = 1 end
            local kind = class == TRADE_GOODS and (subclass == HERB and "herb" or subclass == METAL_AND_STONE and "ore") or nil
            table.insert(loot, { item = item, icon = icon, count = count or 1, kind = kind })
        end
    end
    return loot
end

-- Que nodo dio este botin: id y tipo
local function Identify(name, loot)
    local known = ns.IdByName(name)
    -- Primero lo del catalogo: un nodo puede dar ademas otra hierba (Brezospina
    -- da Cardo veloz) y esa no dice que nodo era
    for _, entry in ipairs(loot) do
        local ids = entry.kind and ns.IdsByItem(entry.item)
        if ids then
            -- El nombre decide entre los que dan lo mismo (con limo, rico...)
            for _, id in ipairs(ids) do
                if id == known then return id, entry.kind, entry.icon end
            end
            return ids[1], entry.kind, entry.icon
        end
    end
    for _, entry in ipairs(loot) do
        if entry.kind then
            if known and ns.KindOf(known) == entry.kind then return known, entry.kind, entry.icon end
            -- Hierba o mena nueva de Forever
            if name then return ns.NewLearnedId(entry.kind, name, entry.icon), entry.kind, entry.icon end
            return nil
        end
    end
    -- Sin hierba ni mena: un tesoro, si el minimapa o el catalogo lo conocen
    if known and ns.KindOf(known) == "treasure" then return known, "treasure" end
    return nil
end

local function OnLootReady()
    local guid = GetLootSourceInfo(1)
    if not guid or issecretvalue(guid) or guid == lastSource or guid:sub(1, 11) ~= "GameObject-" then return end
    lastSource = guid
    local name = GetTime() - castTime < CAST_VALID and castTarget or nil
    castTarget = nil
    local loot = ReadLoot()
    local id, kind, icon = Identify(name, loot)
    if not id then return end
    -- Su nombre en tu idioma, para el minimapa (y el icono si el catalogo no lo trae)
    if name then ns.LearnName(id, name, icon) end
    if ns.SessionAdd then ns.SessionAdd(kind, loot) end
    local map, x, y = ns.PlayerPosition()
    if not map then return end
    local coord = ns.AddNode(kind, map, x, y, id, "gathered")
    if not coord then return end
    ns.ClearLive(kind, map, coord) -- recogido: ya no esta
    if ns.ShareNode then ns.ShareNode(kind, map, coord, id) end
end

function ns.SetupCollector()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("UNIT_SPELLCAST_SENT")
    frame:RegisterEvent("LOOT_READY")
    frame:SetScript("OnEvent", function(_, event, unit, target)
        if event == "LOOT_READY" then
            OnLootReady()
        elseif unit == "player" and target and not issecretvalue(target) and target ~= "" then
            castTarget, castTime = target, GetTime()
        end
    end)
end
