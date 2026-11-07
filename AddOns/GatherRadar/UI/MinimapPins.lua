local ADDON_NAME, ns = ...
local L = ns.L

-- ==========================================
-- PINES DEL MINIMAPA
-- ==========================================
-- Lo que el escaner detecta ahora (o un companero de grupo), de las profesiones
-- que tienes, sale en el minimapa con el icono de lo que da y un aro del color
-- de la probabilidad de subir habilidad (rojo: aun no puedes). Lo recordado no
-- sale aqui: para eso esta el mapa del mundo. Un nodo nuevo late unos segundos.
--
-- Se recolocan solo si te mueves, giras o cambia el zoom, o cada LIVE_EVERY
-- segundos (lo detectado deja de estarlo).
-- ponytail: solo los nodos del mapa en el que estas; en el borde entre dos
-- zonas no salen los de la vecina.

local INTERVAL = 0.05
local LIVE_EVERY = 0.5
local MAX_PINS = 150
local FLASH = 3 -- segundos que late un nodo nuevo
local MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"

local pins, used = {}, 0
local elapsedSum, liveSum = 0, 0
local dirty = true
local last = {}
local flash = {} -- [clave] = hasta cuando late

local function Key(kind, map, coord) return kind .. map .. ":" .. coord end

function ns.OnNewNode(kind, map, coord)
    flash[Key(kind, map, coord)] = GetTime() + FLASH
    dirty = true
end

-- Nombre, habilidad que pide (en su color) y una linea gris opcional
function ns.NodeTooltip(owner, id, note)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:AddLine(ns.NodeName(id))
    local need, _, color = ns.Difficulty(id)
    if need then
        local kind = ns.KindOf(id)
        local info = C_SkillInfo and C_SkillInfo.GetSkillLineInfoByID(ns.KINDS[kind].skill)
        local prof = info and not issecretvalue(info) and info.name or L["KIND_" .. kind:upper()]
        GameTooltip:AddLine(ITEM_MIN_SKILL:format(prof, need), color:GetRGB())
    end
    if note then GameTooltip:AddLine(note, 0.8, 0.8, 0.8, true) end
    GameTooltip:Show()
end

local function ShowTooltip(pin)
    ns.NodeTooltip(pin, pin.id, L.SEEN_NOW)
end

local function NewPin()
    local pin = CreateFrame("Frame", nil, Minimap)
    pin:SetFrameLevel(Minimap:GetFrameLevel() + 5)
    pin:EnableMouse(true)
    pin:SetScript("OnEnter", ShowTooltip)
    pin:SetScript("OnLeave", function() GameTooltip:Hide() end)

    pin.glow = pin:CreateTexture(nil, "BACKGROUND")
    pin.glow:SetTexture("Interface\\Cooldown\\star4")
    pin.glow:SetBlendMode("ADD")
    pin.glow:SetPoint("CENTER")
    pin.pulse = pin.glow:CreateAnimationGroup()
    pin.pulse:SetLooping("BOUNCE")
    local fade = pin.pulse:CreateAnimation("Alpha")
    fade:SetFromAlpha(0.2)
    fade:SetToAlpha(1)
    fade:SetDuration(0.4)

    ns.AddPinArt(pin)
    return pin
end

local function Round(frame, texture)
    local mask = frame:CreateMaskTexture()
    mask:SetTexture(MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(texture)
    texture:AddMaskTexture(mask)
end

-- Icono redondo y, detras, un disco de color algo mayor que hace de aro.
-- Tambien para los pines del mapa del mundo.
function ns.AddPinArt(frame)
    frame.ring = frame:CreateTexture(nil, "BORDER")
    frame.ring:SetPoint("CENTER")
    frame.ring:SetColorTexture(1, 1, 1)
    Round(frame, frame.ring)
    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetPoint("CENTER")
    Round(frame, frame.icon)
end

function ns.SetPinArt(frame, id, size)
    frame:SetSize(size, size)
    frame.icon:SetSize(size, size)
    frame.ring:SetSize(size + 3, size + 3)
    frame.ring:SetVertexColor(ns.RingColor(id))
    ns.SetNodeIcon(frame.icon, id)
end

-- El icono del nodo, o el del tipo si no hay
function ns.SetNodeIcon(texture, id)
    local icon = ns.NodeIcon(id)
    local kind = ns.KindOf(id)
    if icon then
        texture:SetTexture(icon)
        texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    elseif kind and ns.KINDS[kind].atlas then
        texture:SetAtlas(ns.KINDS[kind].atlas)
    else
        texture:SetTexture(kind and ns.KINDS[kind].icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
end

-- Color del aro: dificultad en hierbas y menas, el del tipo en el resto
function ns.RingColor(id)
    local _, _, color = ns.Difficulty(id)
    if color then
        if color == RED_FONT_COLOR and not ns.db.hard then return 1, 1, 1 end
        return color:GetRGB()
    end
    local kind = ns.KindOf(id)
    local c = kind and ns.KINDS[kind].color
    if c then return c[1], c[2], c[3] end
    return 1, 1, 1
end

local function Place(kind, map, coord, id, px, py)
    if used >= MAX_PINS then return end
    used = used + 1
    local pin = pins[used] or NewPin()
    pins[used] = pin
    local size = ns.db.minimapSize
    pin.id = id
    pin.glow:SetSize(size * 2.2, size * 2.2)
    ns.SetPinArt(pin, id, size) -- el aro cambia de color al subir habilidad
    pin.kind, pin.map, pin.coord = kind, map, coord
    local until_ = flash[Key(kind, map, coord)]
    local flashing = until_ and until_ > GetTime()
    pin.glow:SetShown(flashing or false)
    if flashing and not pin.pulse:IsPlaying() then pin.pulse:Play() end
    if not flashing and pin.pulse:IsPlaying() then pin.pulse:Stop() end
    pin:ClearAllPoints()
    pin:SetPoint("CENTER", Minimap, "CENTER", px, py)
    pin:Show()
end

local function Update()
    used = 0
    local map, x, y = ns.PlayerPosition()
    local radius = ns.ViewRadius()
    if ns.db.minimap and map and radius and Minimap:IsVisible() then
        local half = Minimap:GetWidth() / 2
        local limit = (half - 2) ^ 2
        local w, h = ns.MapSize(map)
        local rotate = GetCVar("rotateMinimap") == "1"
        local f = rotate and ns.Facing() or 0
        local cos, sin = math.cos(-f), math.sin(-f)
        local scale = half / radius
        for _, kind in ipairs(ns.KIND_ORDER) do
            if ns.KindShown(kind) and ns.HasProfession(kind) then
                ns.EachNode(kind, map, function(coord, id)
                    local nx, ny = ns.Decode(coord)
                    local east, north = (nx - x) * w, (y - ny) * h
                    if rotate then east, north = east * cos - north * sin, east * sin + north * cos end
                    local mx, my = east * scale, north * scale
                    if mx * mx + my * my <= limit and ns.IsLive(kind, map, coord) then
                        Place(kind, map, coord, id, mx, my)
                    end
                end)
            end
        end
    end
    for i = used + 1, #pins do pins[i]:Hide() end
end

-- Cada frame desde Core/GatherRadar.lua
function ns.MinimapPinsUpdate(elapsed)
    elapsedSum = elapsedSum + elapsed
    liveSum = liveSum + elapsed
    if elapsedSum < INTERVAL then return end
    elapsedSum = 0
    local map, x, y = ns.PlayerPosition()
    local f, r = ns.Facing(), ns.ViewRadius()
    local moved = map ~= last.map or x ~= last.x or y ~= last.y or r ~= last.r
        or (f ~= last.f and GetCVar("rotateMinimap") == "1")
    if not (dirty or moved or liveSum >= LIVE_EVERY) then return end
    last.map, last.x, last.y, last.f, last.r = map, x, y, f, r
    dirty, liveSum = false, 0
    Update()
end

-- Tras cambiar nodos u opciones: minimapa y mapa del mundo
function ns.RefreshPins()
    dirty = true
    if ns.RefreshWorldMap then ns.RefreshWorldMap() end
end
