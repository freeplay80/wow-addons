local _, helper = ...
local isSecret = issecretvalue or function() return false end
local featureHandlers = {}
local circleCVar = "ShowQuestUnitCircles"
helper.directionArrowTexture = "Interface\\AddOns\\ForeverQuestHelper\\QuestArrow.tga"

function helper.GetSettings()
    if type(ForeverQuestHelperDB) ~= "table" then
        ForeverQuestHelperDB = {}
    end
    return ForeverQuestHelperDB
end

function helper.IsEnabled(feature)
    if feature == "questCircles" then
        local ok, value = pcall(C_CVar.GetCVar, circleCVar)
        if ok and not isSecret(value) and value ~= nil then return value == "1" end
        return nil
    end
    return type(ForeverQuestHelperDB) ~= "table" or ForeverQuestHelperDB[feature] ~= false
end

function helper.SetEnabled(feature, enabled)
    if feature == "questCircles" then
        pcall(C_CVar.SetCVar, circleCVar, enabled and "1" or "0")
    else
        local settings = helper.GetSettings()
        settings[feature] = enabled
    end
    if featureHandlers[feature] then featureHandlers[feature]() end
end

function helper.OnFeatureChanged(feature, callback)
    featureHandlers[feature] = callback
end

local features = {
    { "mapPins", "지도 순번 핀", "동선 창이 열리면 지도에 방문 순서를 표시합니다." },
    { "hordeStartPins", "호드 미수락 퀘스트 지도 핀", "수락 조건을 충족한 퀘스트의 시작 장소를 표시합니다." },
    { "trackerButton", "추적기 도우미 버튼", "기본 퀘스트 추적기에서 이 창을 엽니다." },
    { "trackerOrder", "추적기 방문 순번", "추천 방문 순서를 퀘스트 제목 옆에 표시합니다." },
    { "trackerDistance", "추적기 거리", "현재 위치에서 목표까지의 직선거리를 표시합니다." },
    { "trackerDirection", "추적기 방향", "캐릭터가 보는 방향을 기준으로 화살표를 돌립니다." },
    { "nameplateMarks", "이름표 나침반", "미완료 퀘스트 대상의 이름표 옆에 표시합니다." },
    { "screenGuide", "화면 길 안내", "선택한 퀘스트의 방향과 거리, 확인 가능한 층 이동을 표시합니다." },
    { "questCircles", "게임 기본 퀘스트 원", "게임이 지원하는 대상의 발밑 표시를 켭니다." },
    { "targetTooltip", "대상 툴팁", "마우스를 올리면 관련 퀘스트의 남은 목표를 표시합니다." },
    { "turnInList", "반납 목록", "완료한 퀘스트를 같은 반납 지점끼리 모아 봅니다." },
    { "starterAlerts", "퀘스트 시작 아이템 알림", "가방에 들어온 퀘스트 시작 아이템을 채팅에 알립니다." },
}

function helper.CreateSettingsControls(panel)
    local checks = {}
    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 19, -101)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMLEFT", 266, 72)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(245, #features * 40)
    scroll:SetScrollChild(content)

    for index, feature in ipairs(features) do
        local key, name, description = unpack(feature)
        local check = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
        check:SetSize(24, 24)
        check:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(index - 1) * 40)
        checks[key] = check

        local label = check:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("LEFT", check, "RIGHT", 3, 0)
        label:SetText(name)

        local detail = check:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        detail:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)
        detail:SetWidth(211)
        detail:SetJustifyH("LEFT")
        detail:SetTextColor(0.76, 0.72, 0.64)
        detail:SetText(description)

        check:SetScript("OnClick", function(self)
            helper.SetEnabled(key, self:GetChecked() == true)
            self:SetChecked(helper.IsEnabled(key) == true)
        end)
    end

    local move = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    move:SetSize(117, 24)
    move:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, -433)
    move:SetText("안내 위치 이동")
    move:SetScript("OnClick", function(self)
        self:SetText(helper.ToggleGuideMove() and "이동 완료" or "안내 위치 이동")
    end)

    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(108, 24)
    reset:SetPoint("LEFT", move, "RIGHT", 6, 0)
    reset:SetText("위치 초기화")
    reset:SetScript("OnClick", function() helper.ResetGuidePosition() end)

    panel:HookScript("OnShow", function()
        for key, check in pairs(checks) do
            local value = helper.IsEnabled(key)
            check:SetChecked(value == true)
            check:SetEnabled(value ~= nil)
        end
    end)
    panel:HookScript("OnHide", function()
        helper.FinishGuideMove()
        move:SetText("안내 위치 이동")
    end)

    local events = CreateFrame("Frame")
    events:RegisterEvent("CVAR_UPDATE")
    events:SetScript("OnEvent", function(_, _, name)
        if not isSecret(name) and type(name) == "string" and name:lower() == circleCVar:lower() then
            local value = helper.IsEnabled("questCircles")
            checks.questCircles:SetChecked(value == true)
            checks.questCircles:SetEnabled(value ~= nil)
        end
    end)
end
