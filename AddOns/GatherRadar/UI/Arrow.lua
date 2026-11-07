local ADDON_NAME, ns = ...
local L = ns.L

-- ==========================================
-- FLECHA AL NODO MAS CERCANO
-- ==========================================
-- Apunta al nodo mas cercano del mapa en el que estas: primero lo que se ve
-- ahora en el minimapa, si no lo recordado. Se salta el que tienes encima y,
-- con "Marcar lo que no puedes recoger", los que piden mas habilidad.
-- Arrastrar para moverla, clic derecho para apagarla. Arte de DungeonQuestAtlas.

local INTERVAL = 0.1
local SKIP = 6 -- yardas: el nodo que estas recogiendo no cuenta

local arrow, elapsedSum = nil, 0

-- dx este, dy sur (yardas) y el nodo, o nil
local function Target()
    local map, x, y = ns.PlayerPosition()
    if not map then return nil end
    local w, h = ns.MapSize(map)
    local best, bestLive
    for _, kind in ipairs(ns.KIND_ORDER) do
        if ns.KindShown(kind) then
            ns.EachNode(kind, map, function(coord, id)
                if ns.db.hard and ns.TooHard(id) then return end
                local nx, ny = ns.Decode(coord)
                local dx, dy = (nx - x) * w, (ny - y) * h
                local d = dx * dx + dy * dy
                if d < SKIP * SKIP then return end
                local live = ns.IsLive(kind, map, coord)
                -- Lo visto ahora gana a lo recordado; entre iguales, el mas cerca
                if not best or (live and not bestLive) or (live == bestLive and d < best.d) then
                    best, bestLive = { d = d, dx = dx, dy = dy, id = id }, live
                end
            end)
        end
    end
    return best
end

local function Update(self, elapsed)
    elapsedSum = elapsedSum + elapsed
    if elapsedSum < INTERVAL then return end
    elapsedSum = 0
    local target = Target()
    if not target then
        self.title:SetText(L.ARROW_NONE)
        self.distance:SetText("")
        self.icon:Hide()
        self.image:SetAlpha(0.3)
        return
    end
    self.title:SetText(ns.NodeName(target.id))
    self.distance:SetText(L.YARDS:format(math.floor(math.sqrt(target.d) + 0.5)))
    ns.SetNodeIcon(self.icon, target.id)
    self.icon:Show()
    local facing = ns.Facing()
    self.image:SetAlpha(facing and 1 or 0.3)
    if facing then self.image:SetRotation(math.atan2(-target.dx, -target.dy) - facing) end
end

local function CreateArrow()
    arrow = CreateFrame("Frame", "GatherRadarArrow", UIParent)
    arrow:SetSize(56, 56)
    local pos = ns.db.arrowPos
    arrow:SetPoint(pos.point or "TOP", UIParent, pos.relPoint or "TOP", pos.x or 0, pos.y or -170)
    arrow:SetClampedToScreen(true)
    arrow:SetMovable(true)
    arrow:EnableMouse(true)
    arrow:RegisterForDrag("LeftButton")
    arrow:SetScript("OnDragStart", arrow.StartMoving)
    arrow:SetScript("OnDragStop", function()
        arrow:StopMovingOrSizing()
        local point, _, relPoint, x, y = arrow:GetPoint()
        pos.point, pos.relPoint, pos.x, pos.y = point, relPoint, x, y
    end)
    arrow:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" then
            ns.db.arrow = false
            ns.UpdateArrow()
        end
    end)
    arrow:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.ARROW_TOOLTIP, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    arrow:SetScript("OnLeave", function() GameTooltip:Hide() end)

    arrow.image = arrow:CreateTexture(nil, "ARTWORK")
    arrow.image:SetSize(44, 44)
    arrow.image:SetPoint("CENTER")
    arrow.image:SetTexture("Interface\\AddOns\\" .. ADDON_NAME .. "\\img\\arrow_gr")

    arrow.title = arrow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    arrow.title:SetPoint("TOP", arrow, "BOTTOM", 8, -2)
    arrow.icon = arrow:CreateTexture(nil, "OVERLAY")
    arrow.icon:SetSize(14, 14)
    arrow.icon:SetPoint("RIGHT", arrow.title, "LEFT", -3, 0)
    arrow.distance = arrow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    arrow.distance:SetPoint("TOP", arrow.title, "BOTTOM", -8, -2)
    arrow:SetScript("OnUpdate", Update)
end

function ns.UpdateArrow()
    if not ns.db.arrow then
        if arrow then arrow:Hide() end
        return
    end
    if not arrow then CreateArrow() end
    arrow:Show()
end
