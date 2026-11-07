local ADDON_NAME, ns = ...
local L = ns.L

-- ==========================================
-- PANEL DE SESION
-- ==========================================
-- Desde que entras (o desde Reiniciar): tiempo, nodos recogidos y por hora, y
-- lo conseguido con su icono, ordenado por cantidad. Se mueve arrastrando.

local MAX_ITEMS = 8
local WIDTH = 230

local session = { start = GetTime(), nodes = {}, items = {}, order = {} }
local panel, elapsedSum = nil, 0

function ns.SessionAdd(kind, loot)
    session.nodes[kind] = (session.nodes[kind] or 0) + 1
    for _, entry in ipairs(loot) do
        if entry.item then
            local item = session.items[entry.item]
            if not item then
                item = { id = entry.item, icon = entry.icon, count = 0 }
                session.items[entry.item] = item
                table.insert(session.order, item)
            end
            item.count = item.count + entry.count
        end
    end
    elapsedSum = 1 -- repintar ya
end

local function Reset()
    session = { start = GetTime(), nodes = {}, items = {}, order = {} }
    elapsedSum = 1
end
ns.ResetSession = Reset

local function PerHour(count, hours)
    return hours > 0.01 and math.floor(count / hours + 0.5) or 0
end

local function Refresh()
    local seconds = GetTime() - session.start
    local hours = seconds / 3600
    panel.time:SetText(L.SESSION_TIME:format(SecondsToClock and SecondsToClock(seconds) or math.floor(seconds)))
    local total, parts = 0, {}
    for _, kind in ipairs(ns.KIND_ORDER) do
        local n = session.nodes[kind]
        if n then
            total = total + n
            table.insert(parts, L["KIND_" .. kind:upper()] .. " " .. n)
        end
    end
    panel.nodes:SetText(L.SESSION_NODES:format(total, PerHour(total, hours)))
    panel.kinds:SetText(table.concat(parts, " · "))
    table.sort(session.order, function(a, b) return a.count > b.count end)
    for i, row in ipairs(panel.rows) do
        local item = session.order[i]
        row:SetShown(item ~= nil)
        if item then
            row.icon:SetTexture(item.icon)
            local name = C_Item.GetItemNameByID(item.id) or ""
            row.text:SetText(("%d × %s"):format(item.count, name))
            row.rate:SetText(L.PER_HOUR:format(PerHour(item.count, hours)))
        end
    end
    local shown = math.min(#session.order, MAX_ITEMS)
    panel:SetHeight(86 + shown * 18 + (shown == 0 and 18 or 0))
    panel.empty:SetShown(shown == 0)
end

local function CreatePanel()
    panel = CreateFrame("Frame", "GatherRadarSession", UIParent, "BackdropTemplate")
    panel:SetWidth(WIDTH)
    panel:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    panel:SetBackdropColor(0.05, 0.02, 0.1, 0.85)
    panel:SetBackdropBorderColor(0.77, 0.5, 0.95)
    local pos = ns.db.sessionPos
    panel:SetPoint(pos.point or "RIGHT", UIParent, pos.relPoint or "RIGHT", pos.x or -60, pos.y or 120)
    panel:SetClampedToScreen(true)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", function()
        panel:StopMovingOrSizing()
        local point, _, relPoint, x, y = panel:GetPoint()
        pos.point, pos.relPoint, pos.x, pos.y = point, relPoint, x, y
    end)

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 10, -9)
    title:SetText("|cffd597ffGatherRadar|r · " .. L.SESSION)

    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetSize(22, 22)
    close:SetPoint("TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function()
        ns.db.session = false
        ns.UpdateSession()
    end)

    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(70, 18)
    reset:SetPoint("RIGHT", close, "LEFT", -2, 0)
    reset:SetText(L.RESET)
    reset:SetScript("OnClick", Reset)

    panel.time = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panel.time:SetPoint("TOPLEFT", 10, -30)
    panel.nodes = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    panel.nodes:SetPoint("TOPLEFT", 10, -46)
    panel.kinds = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    panel.kinds:SetPoint("TOPLEFT", 10, -63)
    panel.empty = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    panel.empty:SetPoint("TOPLEFT", 10, -82)
    panel.empty:SetText(L.SESSION_EMPTY)

    panel.rows = {}
    for i = 1, MAX_ITEMS do
        local row = CreateFrame("Frame", nil, panel)
        row:SetSize(WIDTH - 20, 16)
        row:SetPoint("TOPLEFT", 10, -80 - (i - 1) * 18)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(16, 16)
        row.icon:SetPoint("LEFT")
        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
        row.text:SetWidth(WIDTH - 90)
        row.text:SetJustifyH("LEFT")
        row.text:SetWordWrap(false)
        row.rate = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.rate:SetPoint("RIGHT")
        panel.rows[i] = row
    end

    panel:SetScript("OnUpdate", function(_, elapsed)
        elapsedSum = elapsedSum + elapsed
        if elapsedSum < 1 then return end
        elapsedSum = 0
        Refresh()
    end)
end

function ns.UpdateSession()
    if not ns.db.session then
        if panel then panel:Hide() end
        return
    end
    if not panel then CreatePanel() end
    Refresh()
    panel:Show()
end
