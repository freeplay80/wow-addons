-- ForeverBankDeposit: 은행이 열려 있을 때 버튼(또는 /fbd)으로 가방의 "제작 재료"를 은행에 넣는다.
-- 분류는 이름이 아닌 숫자(classID 7 = 제작 재료)로 판단하므로 클라이언트 언어와 무관하다.
-- 아이템을 삭제하거나 판매하지 않고, 가방에서 은행으로 옮기기만 한다.
-- 포에버에서 동작하는지는 NOT_TESTED (실제 게임에서 확인 필요).

local PREFIX = "|cff66ccff[은행 재료 입금]|r "
local TRADE_GOODS = 7
local STEP = 0.15 -- 아이템 하나를 옮긴 뒤 다음 것을 옮기기까지의 간격(초). 서버 응답을 기다리기 위함

local GetNumSlots = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
local UseItem = (C_Container and C_Container.UseContainerItem) or UseContainerItem
local GetItemInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant

local bankOpen = false
local queue, running, total = {}, false, 0

local function SlotInfo(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if not info then return nil end
        return info.hyperlink, info.isLocked
    end
    local _, _, locked, _, _, _, link = GetContainerItemInfo(bag, slot)
    return link, locked
end

-- 가방(0~4)에서 제작 재료가 든 칸 목록
local function Collect()
    local list = {}
    if not (GetNumSlots and GetItemInstant) then return list end
    for bag = 0, 4 do
        for slot = 1, (GetNumSlots(bag) or 0) do
            local link = SlotInfo(bag, slot)
            if link then
                local classID = select(6, GetItemInstant(link))
                if classID == TRADE_GOODS then
                    list[#list + 1] = { bag = bag, slot = slot, link = link, tries = 0 }
                end
            end
        end
    end
    return list
end

local driver = CreateFrame("Frame")

local function Finish(aborted)
    running = false
    driver:SetScript("OnUpdate", nil)
    if aborted then
        print(PREFIX .. "은행이 닫혀서 중단했습니다.")
        return
    end
    local function report()
        local left = #Collect()
        print(PREFIX .. string.format("입금 요청 %d칸 완료. 가방에 남은 재료 %d칸%s", total, left,
            left > 0 and " (은행이 가득 찼거나 옮길 수 없는 아이템일 수 있음)" or ""))
    end
    if C_Timer and C_Timer.After then C_Timer.After(0.8, report) else report() end
end

local function Start()
    if not bankOpen then
        print(PREFIX .. "은행 창을 연 상태에서 사용하세요.")
        return
    end
    if InCombatLockdown() then
        print(PREFIX .. "전투 중에는 사용할 수 없습니다.")
        return
    end
    if running then return end
    queue = Collect()
    total = #queue
    if total == 0 then
        print(PREFIX .. "가방에 넣을 제작 재료가 없습니다.")
        return
    end
    running = true
    local acc = 0
    driver:SetScript("OnUpdate", function(_, elapsed)
        acc = acc + elapsed
        if acc < STEP then return end
        acc = 0
        if not bankOpen then return Finish(true) end
        local item = table.remove(queue, 1)
        if not item then return Finish(false) end
        local link, locked = SlotInfo(item.bag, item.slot)
        if link and link == item.link then
            if locked then
                -- 아직 이전 이동이 끝나지 않은 칸은 나중에 다시 시도(최대 3번)
                item.tries = item.tries + 1
                if item.tries <= 3 then queue[#queue + 1] = item end
            else
                UseItem(item.bag, item.slot)
            end
        end
    end)
end

-- ---------- 버튼 ----------
local button = CreateFrame("Button", "ForeverBankDepositButton", UIParent, "UIPanelButtonTemplate")
button:SetSize(90, 22)
button:SetText("재료 입금")
button:SetFrameStrata("HIGH")
button:Hide()
button:SetScript("OnClick", Start)
button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("가방의 제작 재료를 은행에 넣습니다")
    GameTooltip:AddLine(string.format("현재 %d칸", #Collect()), 1, 1, 1)
    GameTooltip:AddLine("삭제·판매는 하지 않습니다.", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end)
button:SetScript("OnLeave", function() GameTooltip:Hide() end)

local function Place()
    button:ClearAllPoints()
    if BankFrame and BankFrame:IsShown() then
        button:SetPoint("TOPRIGHT", BankFrame, "TOPRIGHT", -44, -30)
    else
        button:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

-- ---------- 이벤트·명령 ----------
local ev = CreateFrame("Frame")
ev:RegisterEvent("BANKFRAME_OPENED")
ev:RegisterEvent("BANKFRAME_CLOSED")
ev:SetScript("OnEvent", function(_, event)
    if event == "BANKFRAME_OPENED" then
        bankOpen = true
        Place()
        button:Show()
    else
        bankOpen = false
        button:Hide()
    end
end)

SLASH_FOREVERBANKDEPOSIT1 = "/fbd"
SlashCmdList["FOREVERBANKDEPOSIT"] = function() Start() end

print(PREFIX .. "불러옴 (0.1.0). 은행 창의 [재료 입금] 버튼 또는 /fbd")
