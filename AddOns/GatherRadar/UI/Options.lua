local ADDON_NAME, ns = ...
local L = ns.L

-- ==========================================
-- OPCIONES
-- ==========================================
-- Raiz "Acerca de" (UI/About.lua) y, colgando de ella, "General" (que se ve y
-- como) y "Datos" (base de datos, duplicados, GatherMate2_Data y borrar).

local HEADER = "|cffC47FF3"
local LOGO = "Interface\\AddOns\\" .. ADDON_NAME .. "\\img\\logo_gr"
local X = 16
local COL2 = 300

local function AddTooltip(widget, text)
    widget:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(text, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    widget:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- Las plantillas de casilla y deslizador buscan sus textos por nombre global
local named = 0
local function NextName()
    named = named + 1
    return "GatherRadarOption" .. named
end

-- Panel con titulo, logo y los ayudantes para sus controles
local function NewPanel(titleText)
    local panel = CreateFrame("Frame")
    panel:Hide()
    local ui = { panel = panel, widgets = {} }

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", X, -16)
    title:SetText(titleText)

    local logo = panel:CreateTexture(nil, "ARTWORK")
    logo:SetSize(110, 110)
    logo:SetPoint("TOPRIGHT", -38, -5)
    logo:SetTexture(LOGO)

    local version = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    version:SetPoint("TOP", logo, "BOTTOM", 0, -2)
    version:SetText("v" .. (C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "?"))

    function ui.Header(text, y)
        local fs = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        fs:SetPoint("TOPLEFT", X, y)
        fs:SetText(HEADER .. text .. "|r")
        return fs
    end

    function ui.Line(y)
        local line = panel:CreateTexture(nil, "ARTWORK")
        line:SetColorTexture(1, 1, 1, 0.1)
        line:SetSize(580, 1)
        line:SetPoint("TOPLEFT", X, y)
    end

    -- get/set: la opcion puede estar dentro de una tabla (kinds.herb)
    function ui.Check(label, tooltip, x, y, get, set)
        local cb = CreateFrame("CheckButton", NextName(), panel, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", x, y)
        _G[cb:GetName() .. "Text"]:SetText(label)
        cb:SetScript("OnClick", function(self)
            set(self:GetChecked() and true or false)
            ns.ApplySettings()
        end)
        AddTooltip(cb, tooltip)
        cb.Refresh = function(self) self:SetChecked(get()) end
        table.insert(ui.widgets, cb)
        return cb
    end

    function ui.Option(key, label, tooltip, x, y)
        return ui.Check(label, tooltip, x, y, function() return ns.db[key] end, function(v) ns.db[key] = v end)
    end

    function ui.Slider(key, label, tooltip, x, y, min, max, step, format)
        local slider = CreateFrame("Slider", NextName(), panel, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", x + 10, y)
        slider:SetWidth(240)
        slider:SetMinMaxValues(min, max)
        slider:SetValueStep(step)
        slider:SetObeyStepOnDrag(true)
        local name = slider:GetName()
        _G[name .. "Low"]:SetText(format and format(min) or min)
        _G[name .. "High"]:SetText(format and format(max) or max)
        local function Label()
            local v = ns.db[key]
            _G[name .. "Text"]:SetText(label .. ": " .. (format and format(v) or v))
        end
        slider:SetScript("OnValueChanged", function(_, value)
            value = math.floor(value / step + 0.5) * step
            if value == ns.db[key] then return end
            ns.db[key] = value
            Label()
            ns.ApplySettings()
        end)
        AddTooltip(slider, tooltip)
        slider.Refresh = function(self)
            self:SetValue(ns.db[key])
            Label()
        end
        table.insert(ui.widgets, slider)
        return slider
    end

    function ui.Button(text, tooltip, x, y, width, onClick)
        local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        b:SetSize(width or 200, width == 180 and 26 or 24)
        b:SetPoint("TOPLEFT", x, y)
        b:SetText(text)
        b:SetScript("OnClick", onClick)
        if tooltip then AddTooltip(b, tooltip) end
        return b
    end

    function ui.Refresh()
        for _, w in ipairs(ui.widgets) do w:Refresh() end
        if ui.OnRefresh then ui.OnRefresh() end
    end
    panel:SetScript("OnShow", ui.Refresh)
    return ui
end

local function CreateGeneral()
    local ui = NewPanel(L.OPTIONS_TITLE)

    ui.Header(L.HEADER_SHOW, -56)
    for i, kind in ipairs(ns.KIND_ORDER) do
        local x = (i % 2 == 1) and X or X + COL2 - X
        local y = -81 - math.floor((i - 1) / 2) * 26
        local key = "KIND_" .. kind:upper()
        ui.Check(L[key], L[key .. "_TOOLTIP"], x, y,
            function() return ns.db.kinds[kind] end, function(v) ns.db.kinds[kind] = v end)
    end
    ui.Option("minimap", L.SHOW_MINIMAP, L.SHOW_MINIMAP_TOOLTIP, X, -139)
    ui.Option("worldMap", L.SHOW_WORLDMAP, L.SHOW_WORLDMAP_TOOLTIP, COL2, -139)
    ui.Option("arrow", L.SHOW_ARROW, L.SHOW_ARROW_TOOLTIP, X, -165)
    ui.Option("session", L.SHOW_SESSION, L.SHOW_SESSION_TOOLTIP, COL2, -165)
    ui.Line(-198)

    ui.Header(L.HEADER_RADAR, -214)
    ui.Option("scan", L.SCAN, L.SCAN_TOOLTIP, X, -239)
    ui.Option("saveSeen", L.SAVE_SEEN, L.SAVE_SEEN_TOOLTIP, X, -265)
    ui.Option("share", L.SHARE, L.SHARE_TOOLTIP, X, -291)
    ui.Option("hard", L.HARD, L.HARD_TOOLTIP, X, -317)
    ui.Line(-350)

    ui.Header(L.HEADER_LOOK, -366)
    ui.Slider("minimapSize", L.MINIMAP_SIZE, L.MINIMAP_SIZE_TOOLTIP, X, -400, 8, 28, 1)
    ui.Slider("worldMapSize", L.WORLDMAP_SIZE, L.WORLDMAP_SIZE_TOOLTIP, COL2, -400, 8, 32, 1)

    ui.Button(L.DEFAULTS, nil, X, -450, 180, function()
        ns.ResetSettings()
        ui.Refresh()
    end)
    return ui.panel
end

StaticPopupDialogs["GATHERRADAR_CLEAR_ALL"] = {
    text = "", -- se pone al mostrarlo (ver CreateData)
    button1 = ACCEPT,
    button2 = CANCEL,
    OnAccept = function() ns.ClearAll() end,
    timeout = 0, -- una accion destructiva no se cierra sola
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["GATHERRADAR_FORGET_ALL"] = {
    text = "", -- texto y OnAccept se ponen al mostrarlo (ver CreateData)
    button1 = ACCEPT,
    button2 = CANCEL,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function CreateData()
    local ui = NewPanel(L.DATA_TITLE)

    ui.Header(L.HEADER_DATABASE, -56)
    local stats = ui.panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    stats:SetPoint("TOPLEFT", X, -80)
    stats:SetJustifyH("LEFT")
    local function ShowStats()
        local parts = {}
        for _, kind in ipairs(ns.KIND_ORDER) do
            table.insert(parts, L["KIND_" .. kind:upper()] .. ": |cffffffff" .. ns.Count(kind) .. "|r")
        end
        stats:SetText(table.concat(parts, "    "))
    end
    ui.OnRefresh = ShowStats
    ui.Line(-110)

    ui.Header(L.HEADER_DEDUPE, -126)
    ui.Slider("dedupe", L.DEDUPE, L.DEDUPE_TOOLTIP, X, -160, 5, 50, 1, function(v) return L.YARDS:format(v) end)
    ui.Button(L.CLEANUP, L.CLEANUP_TOOLTIP, COL2, -156, 200, function()
        print(ns.PREFIX .. L.CLEANUP_DONE:format(ns.Cleanup()))
        ShowStats()
    end)
    ui.Line(-200)

    ui.Header(L.HEADER_IMPORT, -216)
    local desc = ui.panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", X, -238)
    desc:SetWidth(570)
    desc:SetJustifyH("LEFT")
    desc:SetText(L.IMPORT_DESC)
    -- Que tipos importa: hierbas y menas en una fila, tesoros y peces en otra
    for i, kind in ipairs(ns.KIND_ORDER) do
        local x = (i % 2 == 1) and X or COL2
        local y = -286 - math.floor((i - 1) / 2) * 26
        ui.Check(L["KIND_" .. kind:upper()], L.IMPORT_KIND_TOOLTIP, x, y,
            function() return ns.db.importKinds[kind] end, function(v) ns.db.importKinds[kind] = v end)
    end
    ui.Button(L.IMPORT, L.IMPORT_TOOLTIP, X, -344, 240, function()
        ns.ImportGatherMate()
        ShowStats()
    end)
    ui.Line(-382)

    ui.Header(L.HEADER_CLEAR, -398)
    ui.Button(L.CLEAR_ZONE, L.CLEAR_ZONE_TOOLTIP, X, -422, 200, function()
        local map = ns.PlayerPosition()
        if map then ns.ClearZone(map) end
        ShowStats()
    end)
    ui.Button(L.CLEAR_ALL, L.CLEAR_ALL_TOOLTIP, COL2, -422, 200, function()
        StaticPopupDialogs.GATHERRADAR_CLEAR_ALL.text = L.CLEAR_ALL_CONFIRM
        StaticPopup_Show("GATHERRADAR_CLEAR_ALL")
    end)
    ui.Line(-460)

    ui.Header(L.HEADER_FORGET, -476)
    local forget = ui.panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    forget:SetPoint("TOPLEFT", X, -498)
    forget:SetWidth(570)
    forget:SetJustifyH("LEFT")
    forget:SetText(L.FORGET_DESC)
    ui.Button(L.FORGET_ALL, L.FORGET_ALL_TOOLTIP, X, -530, 200, function()
        StaticPopupDialogs.GATHERRADAR_FORGET_ALL.text = L.FORGET_ALL_CONFIRM
        StaticPopupDialogs.GATHERRADAR_FORGET_ALL.OnAccept = function()
            ns.ForgetAll()
            print(ns.PREFIX .. L.FORGET_DONE)
            ShowStats()
        end
        StaticPopup_Show("GATHERRADAR_FORGET_ALL")
    end)
    return ui.panel
end

local general
function ns.OpenOptions()
    Settings.OpenToCategory(general:GetID())
end

function ns.CreateOptions()
    local root = ns.CreateAbout({
        name = "GatherRadar",
        logo = LOGO,
        github = "https://github.com/Pirson-s-Addons/GatherRadar",
        curseforge = "https://www.curseforge.com/wow/addons/gather-radar",
        commands = {
            { "/gr", L.CMD_OPEN },
            { "/gr session", L.CMD_SESSION },
            { "/gr arrow", L.CMD_ARROW },
            { "/gr import", L.CMD_IMPORT },
        },
    })
    general = Settings.RegisterCanvasLayoutSubcategory(root, CreateGeneral(), L.GENERAL)
    Settings.RegisterCanvasLayoutSubcategory(root, CreateData(), L.DATA)
end
