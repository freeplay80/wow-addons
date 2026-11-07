local _, helper = ...
local plan = helper.HordeQuestPlan
local pinTemplate = "ForeverHordeQuestStartPinTemplate"
local isSecret = issecretvalue or function() return false end
local provider, indexed, worker, refreshQueued, indexIssue

local function IndexStarts()
    local maps = {}
    local result = plan.Build(0, coroutine.yield)
    if not result then return maps end
    for index, quest in ipairs(result.catalog) do
        if quest.canStart then
            for _, point in ipairs(result.startPoints(quest)) do
                -- A dungeon entrance does not identify the giver's position.
                if not point.entrance then
                    local groups = maps[point.mapID] or {}
                    maps[point.mapID] = groups
                    local key = ("%.4f:%.4f"):format(point.x, point.y)
                    local group = groups[key] or { x = point.x, y = point.y, quests = {} }
                    groups[key] = group
                    group.quests[quest.id] = {
                        id = quest.id, title = quest.title, level = quest.minLevel, giver = point.label,
                    }
                end
            end
        end
        if index % 100 == 0 then coroutine.yield() end
    end
    return maps
end

ForeverHordeQuestStartPinMixin = {}

function ForeverHordeQuestStartPinMixin:OnLoad()
    self:SetScalingLimits(1, 1, 1.2)
    self:UseFrameLevelType("PIN_FRAME_LEVEL_QUEST_PING")
    local atlas = "QuestNormal"
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) then
        self.Icon:SetAtlas(atlas)
        self.Icon:SetDesaturated(true)
        self.Icon:SetVertexColor(0.42, 1, 0.96)
        self.Icon:Show()
    else
        self.Mark:SetText("!")
        self.Mark:SetTextColor(0.52, 1, 0.96)
        self.Mark:Show()
    end
end

function ForeverHordeQuestStartPinMixin:OnAcquired(x, y, quests)
    self.quests = quests
    self:SetAlpha(1)
    self:SetPosition(x, y)
end

function ForeverHordeQuestStartPinMixin:OnMouseEnter()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local multiple = #self.quests > 1
    if multiple then
        GameTooltip:SetText(("수락 가능 퀘스트 %d개"):format(#self.quests))
    end
    for _, quest in ipairs(self.quests) do
        if multiple then
            GameTooltip:AddLine(quest.title, 1, 0.82, 0.42, true)
        else
            GameTooltip:SetText(quest.title, 1, 0.82, 0.42, 1, true)
        end
        GameTooltip:AddDoubleLine(quest.giver or "수락 장소", ("레벨 %d+"):format(quest.level),
            0.76, 0.84, 0.88, 0.55, 0.9, 0.94)
    end
    GameTooltip:Show()
end

function ForeverHordeQuestStartPinMixin:OnMouseLeave()
    if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
end

function ForeverHordeQuestStartPinMixin:OnReleased()
    self:OnMouseLeave()
    self.quests = nil
    MapCanvasPinMixin.OnReleased(self)
end

local function Draw(map, mapID)
    provider:RemoveAllData()
    local groups = indexed[mapID]
    if not groups then return end

    local native = {}
    for pin in map:EnumeratePinsByTemplate("QuestOfferPinTemplate") do
        local id = pin.questID
        if pin:IsShown() and not isSecret(id) and type(id) == "number" then native[id] = true end
    end
    for _, group in pairs(groups) do
        local quests = {}
        for id, quest in pairs(group.quests) do
            if not native[id] then quests[#quests + 1] = quest end
        end
        if #quests > 0 then
            table.sort(quests, function(a, b) return a.id < b.id end)
            map:AcquirePin(pinTemplate, group.x, group.y, quests)
        end
    end
end

local function StartIndex()
    local task = coroutine.create(IndexStarts)
    worker = task
    local function Resume()
        if worker ~= task then return end
        local started = debugprofilestop()
        repeat
            local ok, maps = coroutine.resume(task)
            if not ok or coroutine.status(task) == "dead" then
                worker = nil
                indexed = ok and maps or {}
                if not ok then
                    indexIssue = "퀘스트 시작 위치를 읽지 못했습니다. QuestieDB 설치 상태를 확인하세요."
                    geterrorhandler()(maps)
                end
                provider:RefreshAllData()
                return
            end
        until debugprofilestop() - started >= 4
        C_Timer.After(0, Resume)
    end
    C_Timer.After(0, Resume)
end

local function AttachProvider()
    if provider or not WorldMapFrame then return end
    provider = CreateFromMixins(MapCanvasDataProviderMixin)
    local notice = CreateFrame("Frame", nil, WorldMapFrame)
    notice:SetSize(406, 40)
    notice:SetPoint("TOP", WorldMapFrame, "TOP", 0, -48)
    notice:SetFrameLevel(WorldMapFrame:GetFrameLevel() + 20)
    notice:EnableMouse(false)
    local background = notice:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.07, 0.08, 0.10, 0.94)
    local noticeText = notice:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    noticeText:SetPoint("LEFT", 8, 0)
    noticeText:SetPoint("RIGHT", -8, 0)
    noticeText:SetWordWrap(true)
    notice:Hide()

    function provider:RemoveAllData()
        self:GetMap():RemoveAllPinsByTemplate(pinTemplate)
    end

    function provider:RefreshAllData()
        if refreshQueued then return end
        refreshQueued = true
        -- Let the game's other map providers finish creating their pins first.
        C_Timer.After(0, function()
            refreshQueued = nil
            local map = self:GetMap()
            notice:Hide()
            if not map:IsShown() or not helper.IsEnabled("hordeStartPins") or not plan.IsHorde() then return end
            local issue = plan.GetDataIssue() or indexIssue
            if issue then
                self:RemoveAllData()
                noticeText:SetText(issue)
                notice:Show()
                return
            end
            local mapID = map:GetMapID()
            local info = mapID and C_Map.GetMapInfo(mapID)
            if not info or info.mapType < Enum.UIMapType.Zone then
                self:RemoveAllData()
            elseif indexed then
                Draw(map, mapID)
            elseif not worker then
                StartIndex()
            end
        end)
    end

    function provider:OnMapChanged()
        self:RemoveAllData()
        self:RefreshAllData()
    end

    function provider:OnHide()
        worker = nil
        self:RemoveAllData()
        notice:Hide()
    end

    WorldMapFrame:AddDataProvider(provider)
    provider:RefreshAllData()
end

local function Invalidate()
    indexed, worker, indexIssue = nil, nil, nil
    if provider then
        provider:RemoveAllData()
        provider:RefreshAllData()
    end
end

local events = CreateFrame("Frame")
events:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" then
        if addonName == "Blizzard_WorldMap" then AttachProvider() end
    elseif event == "QUESTLINE_UPDATE" or event == "MINIMAP_UPDATE_TRACKING" then
        if provider then provider:RefreshAllData() end
    else
        if event == "PLAYER_ENTERING_WORLD" then AttachProvider() end
        Invalidate()
    end
end)
for _, event in ipairs({
    "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "QUEST_LOG_UPDATE", "QUEST_ACCEPTED", "QUEST_TURNED_IN",
    "PLAYER_LEVEL_UP", "BAG_UPDATE_DELAYED", "UPDATE_FACTION", "SKILL_LINES_CHANGED", "SPELLS_CHANGED",
    "QUESTLINE_UPDATE", "MINIMAP_UPDATE_TRACKING",
}) do
    pcall(events.RegisterEvent, events, event)
end
helper.OnFeatureChanged("hordeStartPins", Invalidate)
AttachProvider()
