-- ForeverBuffGreeter (진단 버전 0.1.2)
-- 확인된 사실: 전투 로그 이벤트(COMBAT_LOG_EVENT_UNFILTERED) 등록은 이 클라이언트에서 차단된다(사용자 확인).
-- 공식 API 문서상 대안 경로(실제 동작은 NOT_TESTED, 아래 명령으로 하나씩 시험):
--   UNIT_AURA + C_UnitAuras.GetUnitAuraInstanceIDs/GetAuraCasterGUID  : 버프 시전자 확인
--   C_ChatInfo.PerformEmote(emoteName, targetName, suppressMoveError) : 이름으로 이모트
-- 자동 동작은 없다. 시험 결과는 채팅창에 나온다.
--   /fbg 오라          : UNIT_AURA 감지 켜기/끄기. 버프를 받으면 시전자 정보를 채팅창에 출력
--   /fbg 인사          : PerformEmote("HELLO") (대상 없이)
--   /fbg 인사 <이름>   : PerformEmote("HELLO", 이름)

local frame = CreateFrame("Frame")
local watching = false
local known = {}

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccff[버프인사]|r " .. msg)
end

local function IsSecret(v)
    return issecretvalue and issecretvalue(v) or false
end

local function Describe(v)
    if v == nil then return "nil" end
    if IsSecret(v) then return "(비밀 값)" end
    return tostring(v)
end

local function CheckNewBuffs()
    local ids = C_UnitAuras.GetUnitAuraInstanceIDs("player", "HELPFUL")
    if not ids then Print("GetUnitAuraInstanceIDs 결과 없음"); return end
    local seen = {}
    for _, id in ipairs(ids) do
        seen[id] = true
        if not known[id] then
            local guid = C_UnitAuras.GetAuraCasterGUID("player", id)
            local name
            if guid and not IsSecret(guid) then
                local _, _, _, _, _, n = GetPlayerInfoByGUID(guid)
                name = n
            end
            Print("새 버프 id=" .. id .. " 시전자GUID=" .. Describe(guid) .. " 이름=" .. Describe(name))
        end
    end
    known = seen
end

frame:SetScript("OnEvent", function(_, event)
    if event == "UNIT_AURA" then CheckNewBuffs() end
end)

SLASH_FOREVERBUFFGREETER1 = "/fbg"
SLASH_FOREVERBUFFGREETER2 = "/버프인사"
SlashCmdList["FOREVERBUFFGREETER"] = function(msg)
    local cmd, arg = (msg or ""):match("^(%S*)%s*(.-)$")
    if cmd == "오라" then
        watching = not watching
        if watching then
            Print("UNIT_AURA 등록 시도... 차단 알림이 뜨면 이 호출이 원인입니다.")
            known = {}
            frame:RegisterUnitEvent("UNIT_AURA", "player")
        else
            frame:UnregisterEvent("UNIT_AURA")
            Print("UNIT_AURA 해제")
        end
    elseif cmd == "인사" then
        local target = arg ~= "" and arg or nil
        Print("PerformEmote(HELLO, " .. tostring(target) .. ") 호출. 차단 알림이 뜨면 이 호출이 원인입니다.")
        local ok = C_ChatInfo.PerformEmote("HELLO", target)
        Print("반환값: " .. tostring(ok))
    elseif cmd == "토큰" then
        -- /fbg 토큰 <토큰> [이름] : 토큰 문제인지 가리기 위해 다른 이모트로 PerformEmote 시험
        local token, target = arg:match("^(%S+)%s*(.-)$")
        if not token then Print("사용법: /fbg 토큰 <토큰> [이름]  예) /fbg 토큰 WAVE"); return end
        target = (target ~= "") and target or nil
        Print("PerformEmote(" .. token .. ", " .. tostring(target) .. ") 호출")
        Print("반환값: " .. tostring(C_ChatInfo.PerformEmote(token, target)))
    elseif cmd == "구" then
        -- /fbg 구 <토큰> [이름] : 옛 전역 함수 DoEmote 시험 (반환값 없음, 차단 알림 여부만 확인)
        local token, target = arg:match("^(%S+)%s*(.-)$")
        if not token then Print("사용법: /fbg 구 <토큰> [이름]  예) /fbg 구 HELLO"); return end
        target = (target ~= "") and target or nil
        Print("DoEmote(" .. token .. ", " .. tostring(target) .. ") 호출. 차단 알림이 뜨면 이 호출이 원인입니다.")
        DoEmote(token, target)
        Print("호출 끝 (캐릭터가 인사했는지 확인)")
    else
        Print("진단 명령: /fbg 오라 | 인사 [이름] | 토큰 <토큰> [이름] | 구 <토큰> [이름]")
    end
end
