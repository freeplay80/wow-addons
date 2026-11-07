local _, helper = ...
local plan = helper.HordeQuestPlan
local pageSize = 11
local isSecret = issecretvalue or function() return false end
local progressLabels = {
    completed = "|cff80e79b[완료]|r",
    active = "|cff8fd5ff[진행 중]|r",
    unstarted = "|ffc3c7ce[미시작]|r",
    unknown = "|cffffca78[상태 미확인]|r",
}
local panel = CreateFrame("Frame", "ForeverHordeQuestFrame", UIParent, "ButtonFrameTemplate")
panel:SetSize(690, 530)
panel:SetPoint("CENTER")
panel:SetFrameStrata("DIALOG")
panel:SetClampedToScreen(true)
panel.TitleContainer.TitleText:SetText("호드 퀘스트 동선")
panel:SetPortraitToAsset("Interface\\QuestFrame\\UI-QuestLog-BookIcon")
panel:Hide()
tinsert(UISpecialFrames, panel:GetName())

local function Text(parent, font, x, y, width)
    local label = parent:CreateFontString(nil, "ARTWORK", font)
    label:SetPoint("TOPLEFT", x, y)
    label:SetWidth(width)
    label:SetJustifyH("LEFT")
    return label
end

local function Button(title, x, y, width)
    local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", x, y)
    button:SetSize(width, 22)
    button:SetText(title)
    return button
end

local routeButton = Button("추천 동선", 66, -28, 104)
local catalogButton = Button("퀘스트 목록", 176, -28, 104)
local trackButton = Button("동선 추적", 293, -28, 116)
local skipButton = Button("건너뛰기", 415, -28, 136)
local refreshButton = Button("다시 계산", 557, -28, 106)
local prevButton = Button("이전", 24, -493, 70)
local nextButton = Button("다음", 100, -493, 70)
local summary = Text(panel, "GameFontHighlightSmall", 23, -60, 642)
local footer = Text(panel, "GameFontHighlightSmall", 180, -491, 216)
local resetButton = Button("제외 해제", 402, -493, 108)
local scopeButton = Button("현재 지역 우선", 515, -493, 148)
local search = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
search:SetPoint("TOPLEFT", 293, -28)
search:SetSize(248, 22)
search:SetMaxLetters(100)
search:SetAutoFocus(false)

local mode, page, selection = "route", 1, nil
local result, job, queued, fault
local tracking = false
local preferredQuest, trackedStep
local skipped, pendingTurnIns = {}, {}
local Refresh
local rows = {}

local function Place(point, playerMapID)
    local info = C_Map.GetMapInfo(point.mapID)
    local zone = info and not isSecret(info) and not isSecret(info.name) and info.name
        or ("지도 #%d"):format(point.mapID)
    local floorHint = helper.GetQuestFloorHint(playerMapID, point.mapID)
    return ("%s%s %.1f, %.1f%s"):format(floorHint and (floorHint .. " · ") or "", zone, point.x * 100, point.y * 100,
        point.entrance and (" · " .. point.entrance .. " 입구") or "")
end

local function Waypoint(point)
    local ok, allowed = pcall(C_Map.CanSetUserWaypointOnMap, point.mapID)
    if not ok or isSecret(allowed) or allowed ~= true then
        footer:SetText("이 지도에는 기본 길 안내 핀을 놓을 수 없습니다.")
        return
    end
    local success, set = pcall(C_Map.SetUserWaypoint, UiMapPoint.CreateFromCoordinates(point.mapID, point.x, point.y))
    if success and not isSecret(set) and set then
        pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
        footer:SetText("길 안내 · " .. Place(point, C_Map.GetBestMapForUnit("player")))
    else
        footer:SetText("기본 길 안내 핀을 놓을 수 없습니다.")
    end
end

local function QuestLinks(quests, single)
    local labels = {}
    for _, id in ipairs(quests or {}) do
        local q = result.byID[math.abs(id)]
        labels[#labels + 1] = q and ("%s #%d"):format(q.title, math.abs(id)) or ("#%d"):format(math.abs(id))
    end
    if single and single > 0 then
        local q = result.byID[single]
        labels[#labels + 1] = q and ("%s #%d"):format(q.title, single) or ("#%d"):format(single)
    end
    return table.concat(labels, ", ")
end

local function CatalogTitle(q)
    return ("%s  %s  #%d"):format(progressLabels[q.progress], q.title, q.id)
end

local function QuestDetail(q)
    local loc = result.locations(q)
    local playerMapID = C_Map.GetBestMapForUnit("player")
    local lines = {}
    local function Add(title, detail, point)
        lines[#lines + 1] = { title = title, detail = detail, point = point }
    end
    local level = q.minLevel and q.minLevel > 0 and ("최소 레벨 %d"):format(q.minLevel) or nil
    local detail = q.status and level and (q.status .. "  ·  " .. level) or q.status or level
    Add(CatalogTitle(q), detail)
    for _, link in ipairs({
        { q.any and "대체 선행 · 하나 완료" or "필수 선행 · 모두 완료", QuestLinks(q.any or q.all) },
        { "진행 중이어야 하는 퀘스트", QuestLinks(nil, q.parent) },
        { "진행 또는 완료 조건", QuestLinks(nil, q.startWith) },
        { "후속 퀘스트", QuestLinks(q.children, q.next) },
        { "이어지는 안내 퀘스트", QuestLinks(q.breadcrumbs, q.breadcrumbFor) },
        { "배타 퀘스트", QuestLinks(q.exclusive) },
        { "완료 시 수락 불가", QuestLinks(nil, q.untilDone) },
        { "진행 중 수락 불가", QuestLinks(nil, q.disabledBy) },
    }) do
        if link[2] ~= "" then Add(link[1], link[2]) end
    end
    local conditions = {}
    if q.races and q.races > 0 then conditions[#conditions + 1] = "종족 제한" end
    if q.classes and q.classes > 0 then conditions[#conditions + 1] = "직업 제한" end
    if q.maxLevel and q.maxLevel > 0 then conditions[#conditions + 1] = ("최대 레벨 %d"):format(q.maxLevel) end
    if q.minRep then conditions[#conditions + 1] = ("평판 #%d %g 이상"):format(unpack(q.minRep)) end
    if q.maxRep then conditions[#conditions + 1] = ("평판 #%d %g 미만"):format(unpack(q.maxRep)) end
    if q.skill then conditions[#conditions + 1] = ("전문기술 #%d 숙련 %d"):format(unpack(q.skill)) end
    if q.ranks then conditions[#conditions + 1] = "전문기술 등급 제한" end
    if q.spec and q.spec > 0 then conditions[#conditions + 1] = ("전문화 #%d"):format(q.spec) end
    if q.spell and q.spell ~= 0 then conditions[#conditions + 1] = ("주문 #%d %s"):format(math.abs(q.spell),
        q.spell > 0 and "습득 필요" or "습득 시 제한") end
    for _, id in ipairs(q.items or {}) do conditions[#conditions + 1] = ("필요 아이템 #%d"):format(id) end
    if #conditions > 0 then Add("수락 조건", table.concat(conditions, ", ")) end

    local function AddPoints(title, points, missing)
        if #points == 0 then Add(title, missing or "좌표 미확인") end
        local shown = {}
        for _, point in ipairs(points) do
            local place = Place(point, playerMapID)
            if not shown[place] then
                Add(title, point.label and (point.label .. " · " .. place) or place, point)
                shown[place] = true
            end
        end
    end
    AddPoints("수락 장소", loc[1], loc.pickupNote)
    if loc.itemStarts and #loc.itemStarts > 0 then AddPoints("시작 아이템 획득 후보", loc.itemStarts) end
    if q.livePoint then AddPoints("게임이 표시한 수행 지점", { q.livePoint }) end
    if #loc[2] == 0 then
        Add("수행 장소", q.verifiedDelivery and "대화·전달과 반납이 같은 장소 · Wowhead 포에버 확인"
            or "DB 목표 좌표 미확인")
    end
    for _, objective in ipairs(loc[2]) do AddPoints("수행 · " .. objective.label, objective.points) end
    AddPoints("반납 장소", q.turnInPoints or loc[3])
    return lines
end

local function Entries()
    if not result then return {} end
    if mode == "detail" then return selection.lines end
    local entries = {}
    if mode == "route" then
        local playerMapID = C_Map.GetBestMapForUnit("player")
        for index, step in ipairs(result.route) do
            local distance = step.yards and ("%d m · "):format(math.floor(step.yards * 0.9144 + 0.5)) or ""
            entries[index] = {
                title = ("%d. %s · %s%s%s"):format(index, plan.GetStepLabel(step),
                    step.remote and "[다른 대륙·인스턴스] " or "", step.quest.title,
                    step.branch and "  [선택 분기]" or ""),
                detail = (step.reason and (step.reason .. " · ") or "") .. distance .. Place(step.point, playerMapID)
                    .. (step.objective and (" · " .. step.objective)
                    or step.point.label and (" · " .. step.point.label) or ""),
                point = step.point, quest = step.quest, step = step,
            }
        end
    else
        local query = search:GetText():match("^%s*(.-)%s*$"):lower()
        local id = tonumber(query:match("^#?(%d+)$"))
        for _, q in ipairs(result.catalog) do
            if (id and q.id == id) or (not id and q.title:lower():find(query, 1, true)) then
                entries[#entries + 1] = { title = CatalogTitle(q), detail = q.status, quest = q }
            end
        end
    end
    return entries
end

local function Render()
    local entries = Entries()
    local pages = math.max(1, math.ceil(#entries / pageSize))
    page = math.min(page, pages)
    if result then
        summary:SetText(("%s  ·  %d단계 추천 / %d개 퀘스트 / 조건 대기 %d개 / 추가 확인 %d개"):format(
            result.notice or (result.preferredUnavailable and "선택한 퀘스트를 진행할 수 없어 자동 추천으로 전환"
                or mode == "detail" and "퀘스트 상세" or mode == "catalog" and "호드·공용 퀘스트"
                or tracking and "동선 추적 중" or "현재 위치 기준"),
            #result.route, #result.catalog, result.pending, result.missing))
        local hint = mode == "route" and "클릭 HUD · Shift+클릭 지도 핀" or "퀘스트 이름이나 ID로 검색"
        if mode == "route" and tracking and not helper.IsEnabled("screenGuide") then
            hint = "HUD를 표시하려면 /fqh에서 화면 길 안내를 켜세요."
        end
        if mode == "detail" then hint = "좌표 항목 클릭 시 길 안내" end
        footer:SetText(("%d/%d 페이지  ·  %s"):format(page, pages, #entries == 0 and "표시할 항목이 없습니다." or hint))
    else
        summary:SetText(fault or "캐릭터 진행 상태와 포에버 퀘스트를 확인하는 중입니다.")
        footer:SetText("")
    end
    search:SetShown(mode == "catalog")
    trackButton:SetShown(mode == "route")
    trackButton:SetText(tracking and "추적 중지" or "동선 추적")
    trackButton:SetEnabled(tracking or (result ~= nil and #result.route > 0))
    skipButton:SetShown(mode == "route")
    skipButton:SetEnabled(result ~= nil and #result.route > 0)
    resetButton:SetShown(mode == "route" and next(skipped) ~= nil)
    scopeButton:SetShown(mode == "route")
    scopeButton:SetText(helper.IsEnabled("hordeLocalFirst") and "현재 지역 우선" or "전체 지역")
    prevButton:SetEnabled(page > 1)
    nextButton:SetEnabled(page < pages)
    for index, row in ipairs(rows) do
        local entry = entries[(page - 1) * pageSize + index]
        row.entry = entry
        row:SetShown(entry ~= nil)
        if entry then
            row.title:SetPoint("TOPLEFT", 7, entry.detail and -3 or -10)
            row.title:SetText(entry.title)
            row.detail:SetText(entry.detail)
        end
    end
end

for index = 1, pageSize do
    local row = CreateFrame("Button", nil, panel)
    row:SetPoint("TOPLEFT", 23, -78 - (index - 1) * 37)
    row:SetSize(641, 35)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.14, 0.18, 0.22, 0.68)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    row.title = Text(row, "GameFontNormal", 7, -3, 627)
    row.detail = Text(row, "GameFontHighlightSmall", 7, -19, 627)
    row.title:SetWordWrap(false)
    row.detail:SetWordWrap(false)
    row:SetScript("OnClick", function(self, button)
        local entry = self.entry
        if not entry then return end
        if entry.step and button ~= "RightButton" and not (IsShiftKeyDown and IsShiftKeyDown()) then
            preferredQuest = entry.quest.id
            tracking = true
            Refresh()
        elseif entry.point and button ~= "RightButton" then
            Waypoint(entry.point)
        elseif entry.quest then
            mode, page, selection = "detail", 1, { quest = entry.quest, lines = QuestDetail(entry.quest) }
            Render()
        end
    end)
    row:SetScript("OnEnter", function(self)
        if not self.entry then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.entry.title, 1, 1, 1, 1, true)
        if self.entry.detail then
            GameTooltip:AddLine(self.entry.detail, 0.82, 0.86, 0.90, true)
        end
        if self.entry.step then
            GameTooltip:AddLine("클릭 HUD 지정 · Shift+클릭 지도 핀 · 우클릭 상세", 0.7, 0.75, 0.8, true)
        end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    rows[index] = row
end

local function PublishGuide()
    trackedStep = result and result.route[1]
    if result then
        local nextTurnIns, seen = {}, {}
        local function Keep(entries)
            for _, entry in ipairs(entries or {}) do
                local quest = result.byID[entry.id]
                if quest and (quest.progress == "active" or quest.progress == "unknown")
                    and not quest.failed and not seen[entry.id] then
                    seen[entry.id] = true
                    nextTurnIns[#nextTurnIns + 1] = entry
                end
            end
        end
        Keep(trackedStep and trackedStep.turnIns)
        Keep(pendingTurnIns)
        pendingTurnIns = nextTurnIns
        if result.preferredUnavailable then preferredQuest = nil end
    end
    helper.SetRouteGuide(trackedStep, true, pendingTurnIns, fault or (result and result.notice))
end

Refresh = function()
    result, fault = nil, nil
    if panel:IsShown() then Render() end
    local limit = panel:IsShown() and 30 or 1
    local options = { skipped = skipped, questID = preferredQuest, localFirst = helper.IsEnabled("hordeLocalFirst") }
    local worker = coroutine.create(function() return plan.Build(limit, coroutine.yield, options) end)
    job = worker
    local function Resume()
        if job ~= worker or (not panel:IsShown() and not tracking) then return end
        local start = debugprofilestop()
        repeat
            local ok, data, message = coroutine.resume(worker)
            if not ok or coroutine.status(worker) == "dead" then
                job = nil
                result = ok and data or nil
                fault = not ok and "퀘스트 데이터를 읽는 중 오류가 발생했습니다. 다시 계산을 눌러 주세요." or message
                if not ok then geterrorhandler()(data) end
                if tracking then PublishGuide() end
                if selection then
                    local q = result and result.byID[selection.quest.id]
                    if q then selection = { quest = q, lines = QuestDetail(q) }
                    else mode, selection = "route", nil end
                end
                if panel:IsShown() then Render() end
                return
            end
        until debugprofilestop() - start >= 4
        C_Timer.After(0, Resume)
    end
    C_Timer.After(0, Resume)
end

local function SetMode(newMode)
    mode, page, selection = newMode, 1, nil
    Render()
end

routeButton:SetScript("OnClick", function() SetMode("route") end)
catalogButton:SetScript("OnClick", function() SetMode("catalog") end)
trackButton:SetScript("OnClick", function()
    tracking = not tracking
    preferredQuest = nil
    if tracking then
        PublishGuide()
        Refresh()
    else
        trackedStep = nil
        helper.SetRouteGuide(nil, false)
        Render()
    end
end)
skipButton:SetScript("OnClick", function()
    local step = trackedStep or (result and result.route[1])
    if not step then return end
    skipped[step.quest.id] = true
    if preferredQuest == step.quest.id then preferredQuest = nil end
    if tracking then helper.SetRouteGuide(nil, true, pendingTurnIns) end
    Refresh()
end)
resetButton:SetScript("OnClick", function()
    skipped = {}
    Refresh()
end)
scopeButton:SetScript("OnClick", function()
    helper.SetEnabled("hordeLocalFirst", not helper.IsEnabled("hordeLocalFirst"))
    Refresh()
end)
refreshButton:SetScript("OnClick", Refresh)
prevButton:SetScript("OnClick", function() page = page - 1 Render() end)
nextButton:SetScript("OnClick", function() page = page + 1 Render() end)
search:SetScript("OnTextChanged", function() page = 1 Render() end)
search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
panel:SetScript("OnShow", Refresh)
panel:SetScript("OnHide", function()
    if not tracking then job = nil end
end)
panel:SetScript("OnEvent", function()
    if not panel:IsShown() and not tracking then return end
    job = nil
    if queued then return end
    queued = true
    C_Timer.After(0.3, function()
        queued = nil
        if panel:IsShown() or tracking then Refresh() end
    end)
end)
for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "QUEST_LOG_UPDATE", "QUEST_ACCEPTED", "QUEST_TURNED_IN",
    "PLAYER_LEVEL_UP", "PLAYER_MAP_CHANGED", "BAG_UPDATE_DELAYED",
    "UPDATE_FACTION", "SKILL_LINES_CHANGED", "SPELLS_CHANGED" }) do
    pcall(panel.RegisterEvent, panel, event)
end

function helper.ToggleHordeQuestPlan()
    panel:SetShown(not panel:IsShown())
end
