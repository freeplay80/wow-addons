local _, ns = ...
local Read = ns.Read
local isSecret = issecretvalue or function() return false end
local metersPerYard = 0.9144
local arrivedYards = 15
local learnable, trainerWindowOpen = {}, false

local function IsNumber(value)
    return not isSecret(value) and type(value) == "number"
end

local width, padding, rowHeight, maxRows = 290, 10, 19, 6
local headerHeight = 44
local gold = { 0.78, 0.55, 0.10 }

local hud = CreateFrame("Frame", "ForeverTrainerHud", UIParent)
hud:SetSize(width, 100)
hud:SetPoint("TOP", UIParent, "TOP", 0, -190)
hud:SetMovable(true)
hud:SetClampedToScreen(true)
hud:EnableMouse(true)
hud:RegisterForDrag("LeftButton")
hud:Hide()

local background = hud:CreateTexture(nil, "BACKGROUND")
background:SetAllPoints()
background:SetColorTexture(0.04, 0.035, 0.025, 0.72)

-- Thin gold frame made of four edge textures.
local function Edge(point1, point2, horizontal)
    local edge = hud:CreateTexture(nil, "BORDER")
    edge:SetColorTexture(gold[1], gold[2], gold[3], 0.9)
    edge:SetPoint(point1)
    edge:SetPoint(point2)
    if horizontal then edge:SetHeight(1) else edge:SetWidth(1) end
end
Edge("TOPLEFT", "TOPRIGHT", true)
Edge("BOTTOMLEFT", "BOTTOMRIGHT", true)
Edge("TOPLEFT", "BOTTOMLEFT", false)
Edge("TOPRIGHT", "BOTTOMRIGHT", false)

local arrow = hud:CreateTexture(nil, "ARTWORK")
arrow:SetTexture("Interface/AddOns/ForeverTrainerHelper/TrainerArrow.tga")
arrow:SetSize(36, 36)
arrow:SetPoint("TOPLEFT", hud, "TOPLEFT", padding - 2, -padding + 2)

local heading = hud:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
heading:SetPoint("TOPLEFT", arrow, "TOPRIGHT", 6, -2)
heading:SetPoint("RIGHT", hud, "RIGHT", -padding, 0)
heading:SetJustifyH("LEFT")
heading:SetWordWrap(false)

local place = hud:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
place:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -2)
place:SetPoint("RIGHT", hud, "RIGHT", -padding, 0)
place:SetJustifyH("LEFT")
place:SetWordWrap(false)

local divider = hud:CreateTexture(nil, "ARTWORK")
divider:SetColorTexture(gold[1], gold[2], gold[3], 0.35)
divider:SetHeight(1)
divider:SetPoint("TOPLEFT", hud, "TOPLEFT", padding, -(headerHeight + padding))
divider:SetPoint("TOPRIGHT", hud, "TOPRIGHT", -padding, -(headerHeight + padding))

local skillTitle = hud:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
skillTitle:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -6)
skillTitle:SetTextColor(0.52, 1, 0.6)

local rows = {}
local function GetRow(index)
    local row = rows[index]
    if row then return row end
    row = {}
    local top = headerHeight + padding + 28 + (index - 1) * rowHeight
    row.icon = hud:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(16, 16)
    row.icon:SetPoint("TOPLEFT", hud, "TOPLEFT", padding, -top)
    row.info = hud:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.info:SetPoint("TOPRIGHT", hud, "TOPRIGHT", -padding, -top - 2)
    row.info:SetJustifyH("RIGHT")
    row.name = hud:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 6, -2)
    row.name:SetPoint("RIGHT", row.info, "LEFT", -6, 0)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    rows[index] = row
    return row
end

local function RestorePosition()
    local saved = ns.GetDB().hudPosition
    hud:ClearAllPoints()
    if type(saved) == "table" and IsNumber(saved.x) and IsNumber(saved.y) then
        hud:SetPoint("CENTER", UIParent, "CENTER", saved.x, saved.y)
    else
        hud:SetPoint("TOP", UIParent, "TOP", 0, -190)
    end
end

hud:SetScript("OnDragStart", function(self) self:StartMoving() end)
hud:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local centerX, centerY = self:GetCenter()
    local parentX, parentY = UIParent:GetCenter()
    if IsNumber(centerX) and IsNumber(centerY) and IsNumber(parentX) and IsNumber(parentY) then
        ns.GetDB().hudPosition = { x = centerX - parentX, y = centerY - parentY }
    end
end)

local function WorldPosition(mapID, x, y)
    if not CreateVector2D or not C_Map.GetWorldPosFromMapPos then return end
    local world, vector = Read(C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(x, y))
    if IsNumber(world) and vector then
        local wx, wy = Read(vector.GetXY, vector)
        if IsNumber(wx) and IsNumber(wy) then return world, wx, wy end
    end
end

-- Returns the nearest trainer in the player's world: point, east and north offsets in yards.
local function FindNearest()
    local points, ready = ns.GetTrainerPoints()
    if not ready then return nil, nil, nil, "loading" end
    if #points == 0 then return nil, nil, nil, "none" end

    local playerMapID = Read(C_Map.GetBestMapForUnit, "player")
    local position = IsNumber(playerMapID) and Read(C_Map.GetPlayerMapPosition, playerMapID, "player")
    if not position then return nil, nil, nil, "unknown" end
    local playerWorld, px, py = WorldPosition(playerMapID, Read(position.GetXY, position))
    if not playerWorld then return nil, nil, nil, "unknown" end

    local best, bestEast, bestNorth, bestDistance
    for _, point in ipairs(points) do
        if point.world == nil then
            point.world, point.wx, point.wy = WorldPosition(point.mapID, point.x, point.y)
            point.world = point.world or false
        end
        if point.world == playerWorld then
            -- World X increases northward and world Y increases westward.
            local east, north = py - point.wy, point.wx - px
            local distance = math.sqrt(east * east + north * north)
            if not bestDistance or distance < bestDistance then
                best, bestEast, bestNorth, bestDistance = point, east, north, distance
            end
        end
    end
    if not best then return nil, nil, nil, "elsewhere" end
    return best, bestEast, bestNorth
end

local questionMark = "Interface/Icons/INV_Misc_QuestionMark"

local function ShowSkills()
    skillTitle:SetText(("지금 배울 수 있는 스킬 %d개"):format(#learnable))
    local shown = math.min(#learnable, maxRows)
    for index = 1, shown do
        local entry, row = learnable[index], GetRow(index)
        local texture = type(entry.id) == "number"
            and Read(C_Spell and C_Spell.GetSpellTexture or GetSpellTexture, entry.id)
        row.icon:SetTexture(texture or questionMark)
        local rankText = type(entry.id) == "number" and Read(C_Spell and C_Spell.GetSpellSubtext, entry.id)
        if type(rankText) ~= "string" or rankText == "" then rankText = entry.rank end
        row.name:SetText(entry.name .. ((type(rankText) == "string" and rankText ~= "") and (" |cff9d9d9d(" .. rankText .. ")|r") or ""))
        row.info:SetText(("Lv%d · %s"):format(entry.level or 0, ns.Money(entry.cost)))
        row.icon:Show()
        row.name:Show()
        row.info:Show()
    end
    for index = shown + 1, #rows do
        rows[index].icon:Hide()
        rows[index].name:Hide()
        rows[index].info:Hide()
    end
    local extra = #learnable - shown
    local footer = 0
    if extra > 0 then
        local row = GetRow(shown + 1)
        row.icon:Hide()
        row.info:Hide()
        row.name:SetText(("|cff9d9d9d…외 %d개 (/fth 로 전체 보기)|r"):format(extra))
        row.name:Show()
        footer = 1
    end
    hud:SetHeight(headerHeight + padding * 2 + 28 + (shown + footer) * rowHeight)
end

local function Update()
    if not ns.IsEnabled("hud") or trainerWindowOpen or #learnable == 0 then
        hud:Hide()
        return
    end
    ns.EnsureIndex()
    local point, east, north, reason = FindNearest()
    ShowSkills()
    if point then
        local yards = math.sqrt(east * east + north * north)
        local facing = Read(GetPlayerFacing)
        if yards < arrivedYards then
            heading:SetText("훈련사 도착")
            arrow:Hide()
        else
            heading:SetText(("훈련사 %d m"):format(math.floor(yards * metersPerYard + 0.5)))
            arrow:SetShown(IsNumber(facing))
            -- Player facing increases counterclockwise from north.
            if IsNumber(facing) then arrow:SetRotation(-(math.atan2(east, north) + facing)) end
        end
        place:SetText(point.name or "직업 훈련사")
    else
        arrow:Hide()
        heading:SetText("훈련사 위치 미확인")
        place:SetText(({
            loading = "훈련사 위치를 불러오는 중입니다.",
            none = "알려진 훈련사 위치가 없습니다. QuestieDB를 설치하거나 훈련사를 방문하세요.",
            elsewhere = "다른 대륙·인스턴스에 있거나 이 지역에 훈련사가 없습니다.",
            unknown = "현재 위치를 확인할 수 없습니다.",
        })[reason] or "")
    end
    hud:Show()
end

local function RefreshLearnable()
    learnable = ns.GetLearnable()
    Update()
end

function ns.RefreshHud()
    RefreshLearnable()
end

ns.OnIndexReady = Update

local events = CreateFrame("Frame")
-- A hidden frame stops receiving OnUpdate, so the ticker lives on this always-shown frame.
local elapsed = 0
events:SetScript("OnUpdate", function(_, delta)
    elapsed = elapsed + delta
    if elapsed >= 0.25 then
        elapsed = 0
        Update()
    end
end)
events:SetScript("OnEvent", function(_, event)
    if event == "TRAINER_SHOW" then
        trainerWindowOpen = true
    elseif event == "TRAINER_CLOSED" then
        trainerWindowOpen = false
    end
    -- Spell data settles shortly after login, level-ups and purchases.
    C_Timer.After(event == "PLAYER_ENTERING_WORLD" and 4 or 1, RefreshLearnable)
end)
for _, event in ipairs({
    "PLAYER_ENTERING_WORLD", "PLAYER_LEVEL_UP", "SPELLS_CHANGED", "TRAINER_SHOW", "TRAINER_UPDATE", "TRAINER_CLOSED",
}) do
    pcall(events.RegisterEvent, events, event)
end

RestorePosition()
