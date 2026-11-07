local ADDON_NAME, ns = ...

-- ==========================================
-- COMPARTIR CON EL GRUPO
-- ==========================================
-- Cada nodo nuevo que ves o recoges se manda al grupo o banda por mensajes de
-- addon; los de los demas entran en tu base de datos (sin duplicar) y brillan
-- en tu minimapa como vistos ahora. Se juntan en un mensaje cada FLUSH segundos.
--
-- Formato: "1|h,1411,3570284000,401;o,..." (version|tipo,mapa,coord,id;...)
-- Lo recibido se valida entero: viene de otro jugador.

local PREFIX = "GatherRadar"
local VERSION = "1"
local FLUSH = 1.5
local MAX_LEN = 240
local LETTER = { herb = "h", ore = "o", treasure = "t", fish = "f" }
local KIND_OF = { h = "herb", o = "ore", t = "treasure", f = "fish" }

local queue = {}
local flushing = false

local function Channel()
    if IsInRaid() then return "RAID" end
    if IsInGroup() then return "PARTY" end
    return nil
end

local function Flush()
    flushing = false
    local channel = Channel()
    if not (channel and ns.db.share) then
        wipe(queue)
        return
    end
    local msg = VERSION .. "|"
    while #queue > 0 and #msg + #queue[1] + 1 <= MAX_LEN do
        msg = msg .. (msg:sub(-1) == "|" and "" or ";") .. table.remove(queue, 1)
    end
    C_ChatInfo.SendAddonMessage(PREFIX, msg, channel)
    if #queue > 0 then
        flushing = true
        C_Timer.After(FLUSH, Flush)
    end
end

-- Solo nodos del catalogo: los aprendidos (100000+) no existen en otros clientes
function ns.ShareNode(kind, map, coord, id)
    if not (ns.db.share and Channel() and ns.NODES[id]) then return end
    -- %.0f y no %d: coord pasa de 2^31 y el %d de WoW da error (integer overflow)
    table.insert(queue, ("%s,%d,%.0f,%d"):format(LETTER[kind], map, coord, id))
    if not flushing then
        flushing = true
        C_Timer.After(FLUSH, Flush)
    end
end

local function IsMe(sender)
    local me = UnitName("player")
    return sender == me or (Ambiguate and Ambiguate(sender, "none") == me)
end

-- "h,1411,3570284000,401" -> tipo, mapa, x, y, id; nil si no es valido
local function Parse(entry)
    local letter, map, coord, id = entry:match("^(%a),(%d+),(%d+),(%d+)$")
    local kind = KIND_OF[letter]
    map, coord, id = tonumber(map), tonumber(coord), tonumber(id)
    if not (kind and map and coord and id) or map > 100000 then return nil end
    local node = ns.NODES[id]
    if not node or node.kind ~= kind then return nil end
    local x, y = ns.Decode(coord)
    if x < 0 or x >= 1 or y < 0 or y >= 1 or ns.Encode(x, y) ~= coord then return nil end
    return kind, map, x, y, id
end
ns.ParseShared = Parse

local function OnMessage(text, sender)
    if not ns.db.share or IsMe(sender) then return end
    local version, body = text:match("^(%d+)|(.*)$")
    if version ~= VERSION then return end
    for entry in body:gmatch("[^;]+") do
        local kind, map, x, y, id = Parse(entry)
        if kind and ns.db.kinds[kind] then
            local coord = ns.AddNode(kind, map, x, y, id, "shared")
            if coord then ns.MarkLive(kind, map, coord) end
        end
    end
end

function ns.SetupComm()
    if not (C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix) then return end
    C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:SetScript("OnEvent", function(_, _, prefix, text, _, sender)
        if prefix ~= PREFIX or issecretvalue(text) or issecretvalue(sender) then return end
        if type(text) ~= "string" or type(sender) ~= "string" then return end
        OnMessage(text, sender)
    end)
end
