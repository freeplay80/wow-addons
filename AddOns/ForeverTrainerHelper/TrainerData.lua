local _, ns = ...
local isSecret = issecretvalue or function() return false end
local empty = {}
local englishClass = {
    WARRIOR = "Warrior", PALADIN = "Paladin", HUNTER = "Hunter", ROGUE = "Rogue", PRIEST = "Priest",
    SHAMAN = "Shaman", MAGE = "Mage", WARLOCK = "Warlock", DRUID = "Druid",
}
local announcedLogin

local function Public(value)
    if not isSecret(value) then return value end
end

local function Read(func, ...)
    if type(func) ~= "function" then return end
    local ok, a, b, c, d, e, f, g = pcall(func, ...)
    if ok then return Public(a), Public(b), Public(c), Public(d), Public(e), Public(f), Public(g) end
end
ns.Read = Read

function ns.GetDB()
    if type(ForeverTrainerHelperDB) ~= "table" then ForeverTrainerHelperDB = {} end
    local db = ForeverTrainerHelperDB
    db.skills = type(db.skills) == "table" and db.skills or {}
    db.trainers = type(db.trainers) == "table" and db.trainers or {}
    return db
end

function ns.IsEnabled(feature)
    return type(ForeverTrainerHelperDB) ~= "table" or ForeverTrainerHelperDB[feature] ~= false
end

-- Returns the class token and the names under which this class's trainers may be labelled.
function ns.GetClass()
    local localized, file = Read(UnitClass, "player")
    if type(file) ~= "string" then return end
    local names = {}
    if type(localized) == "string" and localized ~= "" then names[#names + 1] = localized end
    if englishClass[file] then names[#names + 1] = englishClass[file] end
    return file, names
end

function ns.TextNamesClass(text, names)
    if type(text) ~= "string" then return false end
    for _, name in ipairs(names or empty) do
        if text:find(name, 1, true) then return true end
    end
    return false
end

local function Money(copper)
    copper = math.floor(tonumber(copper) or 0)
    if copper <= 0 then return "무료" end
    local gold, silver, rest = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
    local parts = {}
    if gold > 0 then parts[#parts + 1] = gold .. "g" end
    if silver > 0 then parts[#parts + 1] = silver .. "s" end
    if rest > 0 then parts[#parts + 1] = rest .. "c" end
    return table.concat(parts, " ")
end

ns.Money = Money

local function Print(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd785훈련사 도우미|r · " .. text)
end

local function SpellLabel(entry)
    if entry.rank and entry.rank ~= "" then return entry.name .. " (" .. entry.rank .. ")" end
    return entry.name
end

local function IsKnown(entry)
    local spellID = entry.id
    if type(spellID) ~= "number" then
        -- Older saves and clients without spell links only have a name to look up.
        local query = entry.name
        if entry.rank and entry.rank ~= "" then query = query .. "(" .. entry.rank .. ")" end
        local info, _, _, _, _, _, id = Read(C_Spell and C_Spell.GetSpellInfo or GetSpellInfo, query)
        if type(info) == "table" then id = Public(info.spellID) end
        spellID = id
    end
    if type(spellID) ~= "number" then return false end
    local known = Read(C_SpellBook and C_SpellBook.IsSpellKnown or IsSpellKnown, spellID)
    return known == true
end

-- Skills saved from an earlier trainer visit that the player can learn at the current level.
function ns.GetLearnable(level)
    local class = ns.GetClass()
    local saved = class and ns.GetDB().skills[class]
    local result = {}
    level = level or Read(UnitLevel, "player")
    if type(saved) ~= "table" or type(level) ~= "number" then return result, saved ~= nil end
    for _, entry in pairs(saved) do
        if type(entry) == "table" and type(entry.name) == "string" and (entry.level or 0) <= level
            and not IsKnown(entry) then
            result[#result + 1] = entry
        end
    end
    table.sort(result, function(a, b)
        if (a.level or 0) ~= (b.level or 0) then return (a.level or 0) < (b.level or 0) end
        return SpellLabel(a) < SpellLabel(b)
    end)
    return result, true
end

local function Summarize(list, limit)
    local names, cost = {}, 0
    for index, entry in ipairs(list) do
        cost = cost + (tonumber(entry.cost) or 0)
        if index <= limit then names[#names + 1] = SpellLabel(entry) end
    end
    local text = table.concat(names, ", ")
    if #list > limit then text = text .. (" 외 %d개"):format(#list - limit) end
    return text, cost
end

local function Announce(prefix, onlyLevel)
    if not ns.IsEnabled("alerts") then return end
    local list, hasData = ns.GetLearnable()
    if not hasData then
        if onlyLevel then
            Print("저장된 스킬 목록이 없습니다. 내 직업 훈련사를 한 번 방문하면 이후부터 알려드립니다.")
        end
        return
    end
    if onlyLevel then
        local fresh = {}
        for _, entry in ipairs(list) do
            if (entry.level or 0) == onlyLevel then fresh[#fresh + 1] = entry end
        end
        if #fresh == 0 and #list == 0 then return end
        if #fresh > 0 then
            local text, cost = Summarize(fresh, 6)
            Print(("%s 레벨 %d에 새로 배울 스킬 %d개: %s (비용 %s)"):format(prefix, onlyLevel, #fresh, text, Money(cost)))
        end
        if #list > #fresh then
            Print(("아직 배우지 않은 스킬이 모두 %d개입니다. /fth 로 목록을 봅니다."):format(#list))
        end
    elseif #list > 0 then
        local text, cost = Summarize(list, 6)
        Print(("%s 배울 수 있는 스킬 %d개: %s (비용 %s)"):format(prefix, #list, text, Money(cost)))
    end
end

-- Merges the open trainer window into the saved list for the player's class.
local function ScanTrainer()
    local class, names = ns.GetClass()
    if not class then return end
    local count = Read(GetNumTrainerServices)
    if type(count) ~= "number" or count <= 0 then return end

    -- Only the class trainer's list is kept; profession and pet trainers are ignored.
    local tooltip = Read(C_TooltipInfo and C_TooltipInfo.GetUnit, "npc")
    local isClassTrainer = false
    if type(tooltip) == "table" and type(tooltip.lines) == "table" then
        for index = 2, math.min(#tooltip.lines, 3) do
            local line = tooltip.lines[index]
            if type(line) == "table" and ns.TextNamesClass(Public(line.leftText), names) then
                isClassTrainer = true
            end
        end
    end
    if not isClassTrainer then return end

    local db = ns.GetDB()
    -- Version 2 keys skills by spell ID; earlier saves collapsed different ranks into one entry.
    if db.skillsVersion ~= 2 then
        db.skills = {}
        db.skillsVersion = 2
    end
    local saved = type(db.skills[class]) == "table" and db.skills[class] or {}
    db.skills[class] = saved
    -- The return order of GetTrainerServiceInfo differs between clients (name, rank, category, ... or
    -- name, category, ...), so the category is found by value instead of by position.
    local kinds = { available = true, unavailable = true, used = true, header = true }
    local seen, learnableNow, samples, sources = {}, 0, {}, { link = 0, tooltip = 0, none = 0 }
    local function SpellIDFor(index)
        local link = Read(GetTrainerServiceItemLink, index)
        local fromLink = type(link) == "string" and tonumber(link:match("spell:(%d+)"))
        if fromLink then
            sources.link = sources.link + 1
            return fromLink
        end
        local data = Read(C_TooltipInfo and C_TooltipInfo.GetTrainerService, index)
        local fromTooltip = type(data) == "table" and Public(data.id)
        if type(fromTooltip) == "number" then
            sources.tooltip = sources.tooltip + 1
            return fromTooltip
        end
        sources.none = sources.none + 1
    end
    for index = 1, count do
        local name, second, third, fourth = Read(GetTrainerServiceInfo, index)
        local category = kinds[second] and second or kinds[third] and third or kinds[fourth] and fourth
        -- The rank text (for example "1 레벨") may arrive in any position after the name.
        local rank = ""
        for _, value in ipairs({ second, third, fourth }) do
            if type(value) == "string" and value ~= "" and not kinds[value] then
                rank = value
                break
            end
        end
        seen[tostring(category)] = (seen[tostring(category)] or 0) + 1
        if type(name) == "string" and category ~= "header" then
            local spellID = SpellIDFor(index)
            local level = Read(GetTrainerServiceLevelReq, index)
            local key = spellID or (name .. "|" .. rank .. "|" .. tostring(level))
            if category == "used" then
                saved[key] = nil
            elseif category == "available" or category == "unavailable" then
                local cost = Read(GetTrainerServiceCost, index)
                saved[key] = {
                    id = spellID, name = name, rank = rank,
                    level = type(level) == "number" and level or 0,
                    cost = type(cost) == "number" and cost or 0,
                }
                if category == "available" then
                    learnableNow = learnableNow + 1
                    samples[#samples + 1] = ("%s[%s] 레벨%s ID%s"):format(name, rank, tostring(level), tostring(spellID))
                end
            end
        end
    end
    -- Kept so /fth status can show what the last trainer window contained.
    db.lastScan = { services = count, categories = seen, learnable = learnableNow, sources = sources, samples = samples }

    -- Remember where this trainer stands so the map can show it without QuestieDB.
    local guid = Read(UnitGUID, "npc")
    local npcID = type(guid) == "string" and tonumber((select(6, strsplit("-", guid))))
    local mapID = Read(C_Map.GetBestMapForUnit, "player")
    local position = mapID and Read(C_Map.GetPlayerMapPosition, mapID, "player")
    local x, y = Read(position and position.GetXY, position)
    if npcID and mapID and type(x) == "number" and type(y) == "number" and (x > 0 or y > 0) then
        local trainers = type(db.trainers[class]) == "table" and db.trainers[class] or {}
        db.trainers[class] = trainers
        trainers[npcID] = { name = Read(UnitName, "npc"), mapID = mapID, x = x, y = y }
    end
    if ns.OnTrainerRecorded then ns.OnTrainerRecorded() end
end

local function PrintList()
    local list, hasData = ns.GetLearnable()
    if not hasData then
        Print("저장된 스킬 목록이 없습니다. 내 직업 훈련사 창을 한 번 열어 주세요.")
    elseif #list == 0 then
        Print("지금 레벨에서 배울 수 있는 스킬이 없습니다.")
    else
        Print(("지금 배울 수 있는 스킬 %d개"):format(#list))
        for _, entry in ipairs(list) do
            DEFAULT_CHAT_FRAME:AddMessage(("  레벨 %d · %s · %s"):format(entry.level or 0, SpellLabel(entry),
                Money(entry.cost)))
        end
    end
end

SLASH_FORTRAINERHELPER1 = "/fth"
SlashCmdList["FORTRAINERHELPER"] = function(message)
    local command = (message or ""):lower():match("^%s*(%S*)")
    if command == "alerts" or command == "pins" or command == "hud" then
        local db = ns.GetDB()
        db[command] = not ns.IsEnabled(command)
        local labels = { alerts = "스킬 알림", pins = "훈련사 지도 핀", hud = "훈련사 HUD" }
        Print(labels[command] .. (db[command] and " 켬" or " 끔"))
        if command == "pins" and ns.RefreshPins then ns.RefreshPins() end
        if command == "hud" and ns.RefreshHud then ns.RefreshHud() end
    elseif command == "status" then
        local class = ns.GetClass()
        local db = ns.GetDB()
        local saved = class and db.skills[class]
        local savedCount = 0
        for _ in pairs(saved or {}) do savedCount = savedCount + 1 end
        local list = ns.GetLearnable()
        local points, ready = {}, false
        if ns.GetTrainerPoints then points, ready = ns.GetTrainerPoints() end
        Print(("직업 %s · 저장된 스킬 %d개 · 지금 배울 스킬 %d개 · 훈련사 위치 %d곳(%s) · HUD %s"):format(
            tostring(class), savedCount, #list, #points, ready and "로드됨" or "로드 중", ns.IsEnabled("hud") and "켬" or "끔"))
        local scan = db.lastScan
        if scan then
            local parts = {}
            for kind, number in pairs(scan.categories or {}) do parts[#parts + 1] = kind .. "=" .. number end
            Print(("마지막 훈련사 창: 서비스 %d개 (%s)"):format(scan.services or 0, table.concat(parts, ", ")))
            local sources = scan.sources
            for index, text in ipairs(scan.samples or {}) do
                if index <= 4 then Print("배울 수 있음: " .. text) end
            end
            if sources then
                Print(("스킬 ID 출처: 링크 %d · 툴팁 %d · 못 찾음 %d"):format(sources.link or 0, sources.tooltip or 0,
                    sources.none or 0))
            end
        else
            Print("훈련사 창을 연 기록이 없습니다.")
        end
    elseif command == "" or command == "list" then
        PrintList()
    else
        Print("/fth — 지금 배울 수 있는 스킬 · /fth alerts · /fth pins · /fth hud — 알림·지도 핀·HUD 켜기/끄기 (HUD는 끌어서 이동)")
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_LEVEL_UP")
events:RegisterEvent("TRAINER_SHOW")
events:RegisterEvent("TRAINER_UPDATE")
events:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_ENTERING_WORLD" then
        if not announcedLogin then
            announcedLogin = true
            -- Give the spellbook a moment to load before checking what is already known.
            C_Timer.After(3, function() Announce("접속 시점에") end)
        end
    elseif event == "PLAYER_LEVEL_UP" then
        local level = Public(arg1)
        if type(level) == "number" then
            C_Timer.After(1, function() Announce("축하합니다!", level) end)
        end
    else
        ScanTrainer()
    end
end)
