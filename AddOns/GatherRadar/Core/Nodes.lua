local ADDON_NAME, ns = ...

-- ==========================================
-- CATALOGO DE NODOS
-- ==========================================
-- Cada nodo tiene el mismo ID que en GatherMate2 (401 = Flor de paz, 201 = Filon
-- de cobre...), asi los datos de GatherMate2_Data entran tal cual. Los nodos
-- propios de Forever que GatherMate2 no tiene llevan IDs 90000+.
--
-- El minimapa solo da el nombre del nodo. Se reconoce por:
--   * su nombre en ingles (este catalogo),
--   * el nombre del objeto que da, en el idioma del cliente (hierbas: el nodo se
--     llama como la hierba),
--   * lo aprendido al recolectar (GatherRadarDB.names): el nombre que tenia el
--     nodo y el objeto que dio. Asi se aprenden las menas en otros idiomas.

-- kind: finder = hechizo de rastreo, skill = linea de habilidad, gm2 = global
-- de GatherMate2_Data, atlas/color = icono y aro por defecto
local KINDS = {
    herb = { finder = 2383, skill = 182, gm2 = "GatherMateData2HerbDB", atlas = "Professions_Tracking_Herb" },
    ore = { finder = 2580, skill = 186, gm2 = "GatherMateData2MineDB", atlas = "Professions_Tracking_Ore" },
    treasure = { finder = 2481, gm2 = "GatherMateData2TreasureDB", icon = "Interface\\Icons\\INV_Box_02", color = { 1, 0.82, 0 } },
    fish = { finder = 43308, skill = 356, gm2 = "GatherMateData2FishDB", icon = "Interface\\Icons\\INV_Misc_Fish_02", color = { 0.3, 0.7, 1 } },
}
ns.KINDS = KINDS
ns.KIND_ORDER = { "herb", "ore", "treasure", "fish" }

-- [id] = { kind, nombre en ingles, objeto (icono y nombre local), habilidad }
local NODES = {}
ns.NODES = NODES

local function Add(kind, list)
    for _, n in ipairs(list) do
        NODES[n[1]] = { id = n[1], kind = kind, name = n[2], item = n[3], skill = n[4] }
    end
end

Add("herb", {
    { 401, "Peacebloom", 2447, 1 }, { 402, "Silverleaf", 765, 1 }, { 403, "Earthroot", 2449, 15 },
    { 404, "Mageroyal", 785, 50 }, { 405, "Briarthorn", 2450, 70 }, { 407, "Stranglekelp", 3820, 85 },
    { 408, "Bruiseweed", 2453, 100 }, { 409, "Wild Steelbloom", 3355, 115 }, { 410, "Grave Moss", 3369, 120 },
    { 411, "Kingsblood", 3356, 125 }, { 412, "Liferoot", 3357, 150 }, { 413, "Fadeleaf", 3818, 160 },
    { 414, "Goldthorn", 3821, 170 }, { 415, "Khadgar's Whisker", 3358, 185 }, { 416, "Wintersbite", 3819, 195 },
    { 417, "Firebloom", 4625, 205 }, { 418, "Purple Lotus", 8831, 210 }, { 420, "Arthas' Tears", 8836, 220 },
    { 421, "Sungrass", 8838, 230 }, { 422, "Blindweed", 8839, 235 }, { 423, "Ghost Mushroom", 8845, 245 },
    { 424, "Gromsblood", 8846, 250 }, { 425, "Golden Sansam", 13464, 260 }, { 426, "Dreamfoil", 13463, 270 },
    { 427, "Mountain Silversage", 13465, 280 }, { 428, "Plaguebloom", 13466, 285 }, { 429, "Icecap", 13467, 290 },
    { 431, "Black Lotus", 13468, 300 },
    -- Nuevas de Forever (sin objeto conocido: el icono se aprende al recogerlas)
    { 90401, "Nightmare Moss", nil, 125 }, { 90402, "Dreamroot", nil, 205 }, { 90403, "Moonroot", nil, 250 },
    { 90404, "Star Lotus", nil, 250 }, { 90405, "Doom Weed", nil, 1 }, { 90406, "Gloom Weed", nil, 1 },
})

Add("ore", {
    { 201, "Copper Vein", 2770, 1 }, { 202, "Tin Vein", 2771, 65 }, { 203, "Iron Deposit", 2772, 125 },
    { 204, "Silver Vein", 2775, 75 }, { 205, "Gold Vein", 2776, 155 }, { 206, "Mithril Deposit", 3858, 175 },
    { 207, "Ooze Covered Mithril Deposit", 3858, 175 }, { 208, "Truesilver Deposit", 7911, 230 },
    { 209, "Ooze Covered Silver Vein", 2775, 75 }, { 210, "Ooze Covered Gold Vein", 2776, 155 },
    { 211, "Ooze Covered Truesilver Deposit", 7911, 230 }, { 212, "Ooze Covered Rich Thorium Vein", 10620, 275 },
    { 213, "Ooze Covered Thorium Vein", 10620, 245 }, { 214, "Small Thorium Vein", 10620, 245 },
    { 215, "Rich Thorium Vein", 10620, 275 }, { 217, "Dark Iron Deposit", 11370, 230 },
    { 218, "Lesser Bloodstone Deposit", 4278, 75 }, { 219, "Incendicite Mineral Vein", 3340, 65 },
    { 220, "Indurium Mineral Vein", 5833, 150 },
    -- Nuevas de Forever
    { 90201, "Cold Iron Deposit", nil, 125 }, { 90202, "Fool's Gold Vein", nil, 175 },
    { 90203, "Starsilver Vein", nil, 245 }, { 90204, "Greater Moonstone Formation", nil, 245 },
    { 90205, "Heavy Thorium Vein", nil, 300 }, { 90206, "Moonstone Formation", nil, 1 },
    { 90207, "Chunk of Amber", nil, 1 },
})

Add("treasure", {
    { 501, "Giant Clam" }, { 502, "Battered Chest" }, { 503, "Tattered Chest" }, { 504, "Solid Chest" },
    { 505, "Large Iron Bound Chest" }, { 506, "Large Solid Chest" }, { 507, "Large Battered Chest" },
    { 508, "Buccaneer's Strongbox" }, { 509, "Large Mithril Bound Chest" }, { 510, "Large Darkwood Chest" },
    { 511, "Un'Goro Dirt Pile" }, { 512, "Bloodpetal Sprout" }, { 513, "Blood of Heroes" },
    { 514, "Practice Lockbox" }, { 515, "Battered Footlocker" }, { 516, "Waterlogged Footlocker" },
    { 517, "Dented Footlocker" }, { 518, "Mossy Footlocker" }, { 519, "Scarlet Footlocker" },
})

-- Bancos: los peces que dan ponen el icono
Add("fish", {
    { 101, "Floating Wreckage" }, { 103, "Floating Debris" }, { 105, "Firefin Snapper School", 6359 },
    { 106, "Greater Sagefish School", 21153 }, { 107, "Oily Blackmouth School", 6358 },
    { 108, "Sagefish School", 21071 }, { 109, "School of Deviate Fish", 6522 },
    { 110, "Stonescale Eel Swarm", 13422 }, { 113, "Pure Water", 7070 },
})

-- ==========================================
-- NOMBRES -> ID
-- ==========================================
local byName = {} -- nombre (en minusculas) -> id
local byItem = {} -- objeto -> { ids }

local function Key(name) return name and name:lower() end

-- Hierbas con algo mas en el nombre ("Wilted Peacebloom", "Flor de paz marchita",
-- nuevas de Forever): la hierba cuyo nombre (ingles o del cliente) va dentro, la
-- mas larga. Con cifras, ":" o "/" es el progreso de una mision ("Flor de paz 3/8").
local herbNames = {} -- nombre en minusculas -> id
local partial = {} -- cache: nombre -> id o false

local function PartialHerb(key)
    if partial[key] == nil then
        local best, bestLen = false, 0
        if not key:find("[%d:/]") then
            for herb, id in pairs(herbNames) do
                if #herb > bestLen and key:find(herb, 1, true) then best, bestLen = id, #herb end
            end
        end
        partial[key] = best
    end
    return partial[key]
end

for id, node in pairs(NODES) do
    byName[Key(node.name)] = id
    if node.kind == "herb" then herbNames[Key(node.name)] = id end
    if node.item then
        byItem[node.item] = byItem[node.item] or {}
        table.insert(byItem[node.item], id)
    end
end
-- El primero de cada objeto es el nodo normal, no su version con limo
for _, ids in pairs(byItem) do table.sort(ids) end

-- Nombres del juego en el idioma del cliente (Data/NodeNames.lua): menas,
-- tesoros y peces se reconocen sin recogerlos antes
local localNames = ns.NODE_NAMES or {}
for id, name in pairs(localNames) do
    if NODES[id] then
        byName[Key(name)] = id
        if NODES[id].kind == "herb" then herbNames[Key(name)] = id end
    end
end

-- Nombres de los objetos en el idioma del cliente: llegan sin orden tras pedirlos
local itemNames = {}

function ns.LoadItemNames()
    for id, node in pairs(NODES) do
        if node.item and Item and Item.CreateFromItemID then
            local item = Item:CreateFromItemID(node.item)
            item:ContinueOnItemLoad(function()
                local name = item:GetItemName()
                if not name then return end
                itemNames[id] = name
                -- Hierbas: el nodo se llama como la hierba en todos los idiomas
                if node.kind == "herb" and not byName[Key(name)] then
                    byName[Key(name)] = id
                    herbNames[Key(name)] = id
                    wipe(partial)
                end
            end)
        end
    end
end

-- ID del nodo con este nombre, o nil
function ns.IdByName(name)
    local key = Key(name)
    if not key then return nil end
    local learned = ns.db and ns.db.names[key]
    return learned or byName[key] or PartialHerb(key) or nil
end

-- IDs del catalogo que dan este objeto
function ns.IdsByItem(item) return byItem[item] end

-- Nombre a mostrar: lo aprendido al recogerlo, la hierba en tu idioma o el ingles
function ns.NodeName(id)
    local node = NODES[id]
    local learned = ns.db and ns.db.learned[id]
    if learned and learned.name then return learned.name end
    if not node then return "?" end
    if localNames[id] then return localNames[id] end
    if node.kind == "herb" and itemNames[id] then return itemNames[id] end
    return node.name
end

-- Apunta el nombre local de un nodo (y su icono si el catalogo no lo trae)
function ns.LearnName(id, name, icon)
    if not (id and name) then return end
    ns.db.names[Key(name)] = id
    local learned = ns.db.learned[id] or {}
    learned.name = name
    if icon and not (NODES[id] and NODES[id].item) then learned.icon = icon end
    ns.db.learned[id] = learned
end

-- Icono del nodo: el del objeto, el aprendido o el generico de su tipo
function ns.NodeIcon(id)
    local node = NODES[id]
    if node and node.item and C_Item and C_Item.GetItemIconByID then
        local icon = C_Item.GetItemIconByID(node.item)
        if icon then return icon end
    end
    local learned = ns.db and ns.db.learned[id]
    if learned and learned.icon then return learned.icon end
    return nil -- el llamador pone el del tipo (atlas)
end

function ns.KindOf(id)
    local node = NODES[id]
    if node then return node.kind end
    local learned = ns.db and ns.db.learned[id]
    return learned and learned.kind
end

-- Nodo nuevo de Forever que no esta en el catalogo: ID propio 100000+
function ns.NewLearnedId(kind, name, icon)
    local id = ns.db.nextLearned
    ns.db.nextLearned = id + 1
    ns.db.learned[id] = { kind = kind, name = name, icon = icon }
    ns.db.names[Key(name)] = id
    return id
end

-- ==========================================
-- HABILIDAD
-- ==========================================
local skills, skillsRead = {}, 0

local function Skill(kind)
    if GetTime() - skillsRead > 2 then
        wipe(skills)
        skillsRead = GetTime()
    end
    if skills[kind] == nil then
        local line = KINDS[kind].skill
        local info = line and C_SkillInfo and C_SkillInfo.GetSkillLineInfoByID and C_SkillInfo.GetSkillLineInfoByID(line)
        local rank = info and not issecretvalue(info) and info.rank
        if rank and not issecretvalue(rank) and rank > 0 then
            local bonus = info.modifier
            if issecretvalue(bonus) then bonus = 0 end
            skills[kind] = rank + (bonus or 0)
        else
            skills[kind] = false
        end
    end
    return skills[kind]
end

-- Habilidad que pide, la tuya (false si no la tienes) y el color de la
-- probabilidad de subir: rojo no puedes, naranja/amarillo/verde/gris como en
-- la ventana de profesion (25, 50 y 100 puntos por encima)
function ns.Difficulty(id)
    local node = NODES[id]
    local kind = ns.KindOf(id)
    local need = node and node.skill
    if not (kind and need and KINDS[kind].skill) then return nil end
    local skill = Skill(kind)
    if not skill then return need, false, RED_FONT_COLOR end
    local over = skill - need
    local color = over < 0 and RED_FONT_COLOR or over < 25 and DIFFICULT_DIFFICULTY_COLOR
        or over < 50 and FAIR_DIFFICULTY_COLOR or over < 100 and EASY_DIFFICULTY_COLOR or TRIVIAL_DIFFICULTY_COLOR
    return need, skill, color
end

-- Tienes la profesion de ese tipo (los tesoros no piden ninguna)
function ns.HasProfession(kind)
    return not KINDS[kind].skill or Skill(kind) ~= false
end

function ns.TooHard(id)
    local need, skill = ns.Difficulty(id)
    return need ~= nil and (skill == false or skill < need)
end
