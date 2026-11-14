local _, ns = ...
local isSecret = issecretvalue or function() return false end
local CALLER = "ForeverItemValue"
-- Assumption: the auction house keeps 5% of a sale (the Classic rule). Not confirmed on Forever, so the
-- tooltip says so whenever the cut changes the recommendation.
local AUCTION_CUT = 0.05
local hookMode = "없음"

local function Public(value)
    if not isSecret(value) then return value end
end

local function Read(func, ...)
    if type(func) ~= "function" then return end
    local ok, a, b, c, d, e, f, g = pcall(func, ...)
    if ok then return Public(a), Public(b), Public(c), Public(d), Public(e), Public(f), Public(g) end
end
ns.Read = Read

-- Like Read, but keeps every return value (GetItemInfo returns more than seven).
local function Pack(ok, ...)
    if not ok then return end
    local values = {}
    for index = 1, select("#", ...) do values[index] = Public((select(index, ...))) end
    return values
end

local function ReadAll(func, ...)
    if type(func) ~= "function" then return end
    return Pack(pcall(func, ...))
end

function ns.GetDB()
    if type(ForeverItemValueDB) ~= "table" then ForeverItemValueDB = {} end
    local db = ForeverItemValueDB
    db.recipes = type(db.recipes) == "table" and db.recipes or {}
    return db
end

function ns.IsEnabled(feature)
    return type(ForeverItemValueDB) ~= "table" or ForeverItemValueDB[feature] ~= false
end

local function Print(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd785가치 비교|r · " .. text)
end

local function Money(copper)
    copper = math.floor((tonumber(copper) or 0) + 0.5)
    local coins = GetCoinTextureString or (C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString)
    local text = copper > 0 and Read(coins, copper)
    if type(text) == "string" and text ~= "" then return text end
    if copper <= 0 then return "0c" end
    local gold, silver, rest = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
    local parts = {}
    if gold > 0 then parts[#parts + 1] = gold .. "g" end
    if silver > 0 then parts[#parts + 1] = silver .. "s" end
    if rest > 0 then parts[#parts + 1] = rest .. "c" end
    return table.concat(parts, " ")
end
ns.Money = Money

local function ItemIDFrom(link)
    return type(link) == "string" and tonumber(link:match("item:(%d+)")) or nil
end

-- Auction and disenchant prices come from Auctionator's public API (an optional dependency). The game has
-- no official API for auction history or disenchant results, so without Auctionator these lines are hidden.
local function AuctionatorAPI()
    local api = type(Auctionator) == "table" and type(Auctionator.API) == "table" and Auctionator.API.v1
    if type(api) == "table" then return api end
end

local function Positive(value)
    if type(value) == "number" and value > 0 then return value end
end

local function AuctionPrice(link, itemID)
    local api = AuctionatorAPI()
    if not api then return end
    local price = type(link) == "string" and Positive(Read(api.GetAuctionPriceByItemLink, CALLER, link))
    if not price and type(itemID) == "number" then
        price = Positive(Read(api.GetAuctionPriceByItemID, CALLER, itemID))
    end
    return price
end

local function DisenchantPrice(link)
    local api = AuctionatorAPI()
    if api and type(link) == "string" then
        return Positive(Read(api.GetDisenchantPriceByItemLink, CALLER, link))
    end
end

-- Average disenchant value from the result table (DisenchantData.lua) and each material's auction price.
-- Returns value, outcomes, and the total chance of results that have no price (the value is then a minimum).
local function DisenchantValue(fullLink, quality, baseLevel, classID)
    local level = Read(C_Item and C_Item.GetDetailedItemLevelInfo or GetDetailedItemLevelInfo, fullLink)
    if type(level) ~= "number" then level = baseLevel end
    local outcomes = ns.DisenchantOutcomes and ns.DisenchantOutcomes(quality, level, classID)
    if not outcomes then
        -- Outside the table (for example above item level 65): Auctionator's own estimate, if it has one.
        return DisenchantPrice(fullLink), nil, 0
    end
    local value, missing = 0, 0
    for _, outcome in ipairs(outcomes) do
        outcome.price = AuctionPrice(nil, outcome.itemID)
        if outcome.price then
            value = value + outcome.chance * (outcome.min + outcome.max) / 2 * outcome.price
        else
            missing = missing + outcome.chance
        end
    end
    if missing > 0.999 then return nil, outcomes, missing end
    return value, outcomes, missing
end

-- Crafting cost uses recipes saved from the profession window, priced at the reagents' auction values.
local function CraftCost(itemID)
    local recipe = ns.GetDB().recipes[itemID]
    if type(recipe) ~= "table" or type(recipe.reagents) ~= "table" or #recipe.reagents == 0 then return end
    local total, priced = 0, 0
    for _, reagent in ipairs(recipe.reagents) do
        local price = AuctionPrice(nil, reagent.id)
        if price then
            total = total + price * reagent.count
            priced = priced + 1
        end
    end
    -- With no priced reagent the sum would read as a cost of zero, so no cost is shown at all.
    if priced == 0 then return end
    local made = tonumber(recipe.made) or 1
    if made < 1 then made = 1 end
    return total / made, priced, #recipe.reagents
end

local boundTexts = {}
for _, key in ipairs({ "ITEM_SOULBOUND", "ITEM_ACCOUNTBOUND", "ITEM_BNETACCOUNTBOUND", "ITEM_BIND_QUEST" }) do
    if type(_G[key]) == "string" then boundTexts[_G[key]] = true end
end

-- Bound items cannot be listed on the auction house; the tooltip data says so in its text lines.
local function IsBound(data)
    local lines = type(data) == "table" and type(data.lines) == "table" and data.lines
    for _, line in ipairs(lines or {}) do
        local text = type(line) == "table" and Public(line.leftText)
        if text and boundTexts[text] then return true end
    end
    return false
end

-- Collects every known value for one item and picks the best way to turn it into money.
function ns.Evaluate(link, data)
    local info = ReadAll(C_Item and C_Item.GetItemInfo or GetItemInfo, link)
    local fullLink = info and info[2]
    if type(fullLink) ~= "string" then return end
    local itemID = ItemIDFrom(fullLink) or ItemIDFrom(link)
    local result = { itemID = itemID, bound = IsBound(data) }
    result.vendor = Positive(info[11])
    if not result.bound then result.auction = AuctionPrice(fullLink, itemID) end
    local quality, classID = info[3], info[12]
    result.disenchant, result.outcomes, result.disenchantMissing = DisenchantValue(fullLink, quality, info[4], classID)
    -- Uncommon to epic weapons (class 2) and armor (class 4) can be disenchanted; used only to explain a
    -- missing disenchant price, never to invent one.
    result.canDisenchant = result.outcomes ~= nil or type(quality) == "number" and quality >= 2 and quality <= 4
        and (classID == 2 or classID == 4)
    if itemID then result.craft, result.craftPriced, result.craftReagents = CraftCost(itemID) end

    local options = {}
    if result.vendor then options[#options + 1] = { key = "vendor", label = "상점 판매", value = result.vendor } end
    if result.auction then
        options[#options + 1] = { key = "auction", label = "경매 판매", value = result.auction * (1 - AUCTION_CUT) }
    end
    if result.disenchant then
        -- The materials are sold on the auction house too, so the same cut applies.
        options[#options + 1] = { key = "disenchant", label = "마력 추출", value = result.disenchant * (1 - AUCTION_CUT) }
    end
    table.sort(options, function(a, b) return a.value > b.value end)
    if #options >= 2 then result.best = options[1] end
    if result.craft and result.craftPriced == result.craftReagents and result.auction then
        result.craftProfit = result.auction * (1 - AUCTION_CUT) - result.craft
    end
    return result
end

local function Describe(result)
    local rows = {}
    local function Row(key, label, value, note)
        if not value then return end
        local best = result.best and result.best.key == key
        rows[#rows + 1] = {
            left = label .. (note and (" |cff999999" .. note .. "|r") or "") .. (best and " |cff40ff40추천|r" or ""),
            right = Money(value),
        }
    end
    Row("vendor", "상점 판매", result.vendor)
    Row("auction", "경매 시세", result.auction)
    Row("disenchant", "마력 추출", result.disenchant, (result.disenchantMissing or 0) > 0
        and "일부 재료 시세 없음 · 최소 금액" or "재료 시세 기준 평균")
    if result.canDisenchant and not result.disenchant then
        rows[#rows + 1] = {
            left = "마력 추출 |cff999999" .. (AuctionatorAPI() and "경매장에서 Auctionator 스캔 필요"
                or "Auctionator 필요") .. "|r",
            right = "|cff999999시세 없음|r",
        }
    end
    for _, outcome in ipairs(result.outcomes or {}) do
        local name = Read(C_Item and C_Item.GetItemNameByID or GetItemInfo, outcome.itemID)
        if type(name) ~= "string" then
            Read(C_Item and C_Item.RequestLoadItemDataByID, outcome.itemID)
            name = "아이템 " .. outcome.itemID
        end
        local amount = outcome.min == outcome.max and (outcome.min .. "개") or (outcome.min .. "-" .. outcome.max .. "개")
        local tenths = math.floor(outcome.chance * 1000 + 0.5)
        local chance = tenths % 10 == 0 and ("%d"):format(tenths / 10) or ("%.1f"):format(tenths / 10)
        rows[#rows + 1] = {
            left = ("    |cffbbbbbb%s %s%% %s|r"):format(name, chance, amount),
            right = outcome.price and ("|cffbbbbbb개당|r " .. Money(outcome.price)) or "|cff999999시세 없음|r",
        }
    end
    if result.craft then
        local note = result.craftPriced < result.craftReagents
            and ("재료 %d/%d종만 시세 있음 · 최소 금액"):format(result.craftPriced, result.craftReagents) or nil
        Row("craft", "제작 원가", result.craft, note)
        if result.craftProfit then
            local profit = result.craftProfit
            rows[#rows + 1] = {
                left = "제작 후 경매 이익",
                right = (profit < 0 and "|cffff6060-" or "|cff40ff40") .. Money(math.abs(profit)) .. "|r",
            }
        end
    end
    return rows
end
ns.Describe = Describe

local function AddLines(tooltip, result)
    local rows = Describe(result)
    if #rows == 0 then return end
    tooltip:AddLine(result.bound and "가치 비교 (1개 · 귀속되어 경매 불가)" or "가치 비교 (1개 기준)", 1, 0.82, 0)
    for _, row in ipairs(rows) do
        tooltip:AddDoubleLine("  " .. row.left, row.right, 1, 1, 1, 1, 1, 1)
    end
    if result.best and (result.best.key ~= "vendor") then
        tooltip:AddLine(("  경매 수수료 %d%%를 뺀 값으로 비교"):format(AUCTION_CUT * 100), 0.6, 0.6, 0.6)
    end
end

local function LinkFromTooltip(tooltip, data)
    local link
    if tooltip.GetItem then
        local _, itemLink = Read(tooltip.GetItem, tooltip)
        link = itemLink
    end
    if type(link) ~= "string" then
        local id = type(data) == "table" and Public(data.id)
        if type(id) == "number" then link = "item:" .. id end
    end
    return link
end

local function OnItemTooltip(tooltip, data)
    if not ns.IsEnabled("tooltip") then return end
    if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then return end
    local link = LinkFromTooltip(tooltip, data)
    if not link then return end
    local ok, result = pcall(ns.Evaluate, link, data)
    if ok and result then AddLines(tooltip, result) end
end

if TooltipDataProcessor and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnItemTooltip)
    hookMode = "TooltipDataProcessor"
elseif GameTooltip and GameTooltip.HookScript then
    GameTooltip:HookScript("OnTooltipSetItem", function(tooltip) OnItemTooltip(tooltip) end)
    hookMode = "OnTooltipSetItem"
end

-- Recipes are read from the open profession window. Which API the Forever client fills is not known yet,
-- so both are tried and /fiv status reports the one that produced data.
local function ScanModern()
    local ui = C_TradeSkillUI
    local ids = ui and Read(ui.GetAllRecipeIDs)
    if type(ids) ~= "table" or #ids == 0 then return nil, 0, 0 end
    local recipes, saved = {}, 0
    for _, rawID in ipairs(ids) do
        local recipeID = Public(rawID)
        local schematic = type(recipeID) == "number" and Read(ui.GetRecipeSchematic, recipeID, false)
        local output = type(schematic) == "table" and Public(schematic.outputItemID)
        local slots = type(schematic) == "table" and schematic.reagentSlotSchematics
        if type(output) == "number" and output > 0 and type(slots) == "table" then
            local reagents, complete = {}, true
            for _, slot in ipairs(slots) do
                if type(slot) == "table" and Public(slot.required) ~= false then
                    local first = type(slot.reagents) == "table" and slot.reagents[1]
                    local id = type(first) == "table" and Public(first.itemID)
                    local count = Public(slot.quantityRequired)
                    if type(id) == "number" and type(count) == "number" and count > 0 then
                        reagents[#reagents + 1] = { id = id, count = count }
                    else
                        complete = false
                    end
                end
            end
            if complete and #reagents > 0 then
                local low, high = Public(schematic.quantityMin), Public(schematic.quantityMax)
                local made = type(low) == "number" and low > 0 and low or 1
                if type(high) == "number" and high > made then made = (made + high) / 2 end
                recipes[output] = { reagents = reagents, made = made, recipeID = recipeID, source = "modern" }
                saved = saved + 1
            end
        end
    end
    return recipes, saved, #ids
end

local function ScanLegacy()
    local count = Read(GetNumTradeSkills)
    if type(count) ~= "number" or count <= 0 then return nil, 0, 0 end
    local recipes, saved = {}, 0
    for index = 1, count do
        local _, kind = Read(GetTradeSkillInfo, index)
        local output = kind ~= "header" and kind ~= "subheader" and ItemIDFrom(Read(GetTradeSkillItemLink, index))
        if output then
            local reagentCount = Read(GetTradeSkillNumReagents, index)
            local reagents = {}
            for slot = 1, type(reagentCount) == "number" and reagentCount or 0 do
                local _, _, needed = Read(GetTradeSkillReagentInfo, index, slot)
                local id = ItemIDFrom(Read(GetTradeSkillReagentItemLink, index, slot))
                if id and type(needed) == "number" and needed > 0 then
                    reagents[#reagents + 1] = { id = id, count = needed }
                end
            end
            if #reagents > 0 and #reagents == reagentCount then
                local low, high = Read(GetTradeSkillNumMade, index)
                local made = type(low) == "number" and low > 0 and low or 1
                if type(high) == "number" and high > made then made = (made + high) / 2 end
                recipes[output] = { reagents = reagents, made = made, source = "legacy" }
                saved = saved + 1
            end
        end
    end
    return recipes, saved, count
end

function ns.ScanRecipes()
    local db = ns.GetDB()
    local recipes, saved, total = ScanModern()
    local source = "modern"
    if not recipes or saved == 0 then
        local legacy, legacySaved, legacyTotal = ScanLegacy()
        if legacy and legacySaved > 0 then
            recipes, saved, total, source = legacy, legacySaved, legacyTotal, "legacy"
        elseif not recipes then
            total = legacyTotal
        end
    end
    for itemID, entry in pairs(recipes or {}) do db.recipes[itemID] = entry end
    db.lastScan = { source = saved > 0 and source or "none", saved = saved, total = total or 0 }
end

local pending
local function QueueScan()
    if pending then return end
    pending = true
    C_Timer.After(0.5, function()
        pending = false
        local ok, problem = pcall(ns.ScanRecipes)
        if not ok then ns.GetDB().lastScan = { source = "error", saved = 0, total = 0, error = tostring(problem) } end
    end)
end

local function CountRecipes()
    local count = 0
    for _ in pairs(ns.GetDB().recipes) do count = count + 1 end
    return count
end

local function PrintItem(link)
    local result = ns.Evaluate(link)
    if not result then
        Print("아이템 정보를 읽지 못했습니다. 아이템 링크를 붙여 넣거나 잠시 후 다시 시도하세요.")
        return
    end
    local rows = Describe(result)
    if #rows == 0 then
        Print(link .. " · 비교할 가격이 없습니다.")
        return
    end
    Print(link)
    for _, row in ipairs(rows) do DEFAULT_CHAT_FRAME:AddMessage("  " .. row.left .. " · " .. row.right) end
end

SLASH_FOREVERITEMVALUE1 = "/fiv"
SlashCmdList["FOREVERITEMVALUE"] = function(message)
    message = message or ""
    local command = message:lower():match("^%s*(%S*)")
    if message:find("|Hitem:", 1, true) or message:find("item:%d+") then
        PrintItem(message:match("|c%x+|Hitem:.-|h|r") or message:match("item:[%d:%-]+"))
    elseif command == "tooltip" then
        local db = ns.GetDB()
        db.tooltip = not ns.IsEnabled("tooltip")
        Print("툴팁 표시 " .. (db.tooltip and "켬" or "끔"))
    elseif command == "status" then
        local scan = ns.GetDB().lastScan
        Print(("Auctionator %s · 툴팁 연결 %s · 저장된 제작법 %d개"):format(
            AuctionatorAPI() and "연결됨" or "없음", hookMode, CountRecipes()))
        if scan then
            Print(("마지막 전문기술 창 읽기: 방식 %s · 저장 %d / 목록 %d%s"):format(scan.source, scan.saved or 0,
                scan.total or 0, scan.error and (" · 오류 " .. scan.error) or ""))
        else
            Print("전문기술 창을 연 기록이 없습니다. 제작 원가는 전문기술 창을 한 번 열면 표시됩니다.")
        end
    else
        Print("/fiv 아이템링크 — 가격 비교를 채팅에 출력 · /fiv tooltip — 툴팁 표시 켜기/끄기 · /fiv status — 연결 상태")
    end
end

local events = CreateFrame("Frame")
for _, event in ipairs({ "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE", "TRADE_SKILL_DATA_SOURCE_CHANGED" }) do
    pcall(events.RegisterEvent, events, event)
end
events:SetScript("OnEvent", QueueScan)
