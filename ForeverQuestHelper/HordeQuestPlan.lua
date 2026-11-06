local _, helper = ...
local plan = {}
helper.HordeQuestPlan = plan

local isSecret = issecretvalue or function() return false end
local empty = {}
local stages = { "수락", "수행", "반납" }
local progressByStage = { "unstarted", "active", "active", "completed", "active" }
local notesByStage = { [1] = "DB 수락 조건 충족", [3] = "반납 가능", [5] = "실패" }
local turnInRadius, objectiveRadius, followUpRadius = 35, 650, 200
local seasonalSorts = { [-22] = true, [-366] = true, [-367] = true, [-370] = true, [-376] = true, [-374] = true }
-- Wowhead Forever quest text confirms that these objectives are fulfilled at the finisher.
local verifiedDeliveries = {
    [804] = true,  -- https://www.wowhead.com/forever/de/quest=804/sarkoth
    [2161] = true, -- https://www.wowhead.com/forever/quest=2161/a-peons-burden
    [4641] = true, -- https://www.wowhead.com/forever/quest=4641/your-place-in-the-world
}
plan.stages = stages

function plan.GetStepLabel(step)
    return step.verifyTurnIn and "반납 확인" or stages[step.stage]
end

local function Public(value)
    if not isSecret(value) then return value end
end

local function Read(func, ...)
    if not func then return end
    local ok, a, b, c, d, e, f, g = pcall(func, ...)
    if ok then return Public(a), Public(b), Public(c), Public(d), Public(e), Public(f), Public(g) end
end

function plan.IsHorde()
    return Read(UnitFactionGroup, "player") == "Horde"
end

local function GetProvider()
    local db = LibQuestieDB
    if type(db) ~= "table" then
        if Read(C_AddOns and C_AddOns.GetAddOnInfo, "QuestieDB") == "QuestieDB" then
            return nil, nil, "QuestieDB를 불러오지 못했습니다. 포에버용인지와 활성화 상태를 확인하세요."
        end
        return nil, nil, "QuestieDB가 없습니다. 포에버용 QuestieDB를 설치하세요."
    end
    if db.flavor and (type(db.flavor) ~= "table" or db.flavor.name ~= "Forever") then
        return nil, nil, "QuestieDB가 다른 게임 버전용입니다. 포에버용으로 교체하세요."
    end
    if Read(db.RequireContract, 4) ~= true then
        return nil, nil, "QuestieDB API가 호환되지 않습니다. 포에버용 호환 버전이 필요합니다."
    end
    local zones = Read(type(db.Support) == "table" and db.Support.Get, "ZoneDB")
    if type(zones) ~= "table" or type(zones.private) ~= "table"
        or type(zones.private.areaIdToUiMapId) ~= "string" then
        return nil, nil, "QuestieDB에서 포에버 지도 데이터를 읽을 수 없습니다."
    end
    return db, zones.private
end

function plan.GetDataIssue()
    local _, _, issue = GetProvider()
    return issue
end

local function Overlaps(a, b)
    -- Skyborne race masks are wider than WoW's 32-bit bit library.
    while a > 0 and b > 0 do
        if a % 2 == 1 and b % 2 == 1 then return true end
        a, b = math.floor(a / 2), math.floor(b / 2)
    end
    return false
end

local function HasFlag(value, flag)
    return math.floor(value / flag) % 2 == 1
end

local function Append(target, value)
    target[#target + 1] = value
end

local function Point(mapID, x, y, label, entrance)
    if not mapID or type(x) ~= "number" or type(y) ~= "number"
        or not (x >= 0 and x <= 1 and y >= 0 and y <= 1) then return end
    if not Read(C_Map.GetMapInfo, mapID) then return end
    local point = { mapID = mapID, x = x, y = y, label = label, entrance = entrance }
    if CreateVector2D then
        local world, position = Read(C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(x, y))
        if position then
            point.wx, point.wy = Read(position.GetXY, position)
            if point.wx and point.wy then point.world = world end
        end
    end
    return point
end

local function MakeLocations(db, zones)
    local areaMaps = assert(loadstring(zones.areaIdToUiMapId))()
    local dungeons = {}
    for area, entry in pairs(zones.dungeons or empty) do
        dungeons[area] = entry
        for _, alternative in ipairs(entry[2] or empty) do dungeons[alternative] = entry end
    end
    local function AddSpawns(points, spawns, label)
        for area, coordinates in pairs(spawns or empty) do
            for _, coordinate in ipairs(coordinates) do
                local x, y, phase = unpack(coordinate)
                if not phase or phase == 0 then
                    if x == -1 and y == -1 and dungeons[area] then
                        for _, entrance in ipairs(dungeons[area][4]) do
                            Append(points, Point(areaMaps[entrance[1]], entrance[2] / 100, entrance[3] / 100,
                                label, dungeons[area][1]))
                        end
                    else
                        Append(points, Point(areaMaps[area], x / 100, y / 100, label))
                    end
                end
            end
        end
    end
    local entities = { db.Npc, db.Object, db.Item }
    local function AddEntity(points, kind, id, label, depth)
        if not kind or not id or id <= 0 then return end
        local entity = entities[kind]
        label = label or entity.name(id)
        if kind == 3 then
            -- Container drops may point back to the same item.
            depth = depth or 0
            if depth == 3 then return end
            for _, npc in ipairs(entity.npcDrops(id) or empty) do AddEntity(points, 1, npc, label) end
            for _, object in ipairs(entity.objectDrops(id) or empty) do AddEntity(points, 2, object, label) end
            for _, vendor in ipairs(entity.vendors(id) or empty) do
                if db.Npc.friendlyToFaction(vendor) ~= "A" then AddEntity(points, 1, vendor, label) end
            end
            for _, item in ipairs(entity.itemDrops(id) or empty) do AddEntity(points, 3, item, label, depth + 1) end
        else
            AddSpawns(points, entity.spawns(id), label)
        end
    end
    local function Givers(list)
        local points = {}
        for kind = 1, 2 do
            for _, id in ipairs(list[kind] or empty) do
                if kind ~= 1 or db.Npc.friendlyToFaction(id) ~= "A" then
                    local first = #points + 1
                    AddEntity(points, kind, id)
                    for index = first, #points do
                        points[index].giverID, points[index].giverKind = id, kind
                    end
                end
            end
        end
        return points
    end
    local function Objectives(id)
        local steps = {}
        local function Add(label, points)
            Append(steps, { label = label or "수행 목표", points = points })
        end
        local objectives = db.Quest.objectives(id)
        for kind = 1, 3 do
            for _, row in ipairs(objectives[kind] or empty) do
                local points = {}
                AddEntity(points, kind, row[1], row[2])
                Add(row[2] or entities[kind].name(row[1]), points)
            end
        end
        for _, row in ipairs(objectives[5] or empty) do
            local points = {}
            for _, npc in ipairs(row[1] or empty) do AddEntity(points, 1, npc, row[3]) end
            if #points == 0 then AddEntity(points, 1, row[2], row[3]) end
            Add(row[3] or db.Npc.name(row[2]), points)
        end
        for _, row in ipairs(objectives[6] or empty) do
            -- The item in a spell objective is a tool. Its drop site is not the casting location.
            Add(row[2] or ("주문 #%d"):format(row[1]), {})
        end
        local trigger = db.Quest.triggerEnd(id)
        if trigger then
            local points = {}
            AddSpawns(points, trigger[2], trigger[1])
            Add(trigger[1], points)
        end
        for _, row in ipairs(db.Quest.extraObjectives(id) or empty) do
            local points = {}
            AddSpawns(points, row[1], row[3])
            for _, ref in ipairs(row[5] or empty) do
                AddEntity(points, ({ monster = 1, object = 2, item = 3 })[ref[1]], ref[2], row[3])
            end
            if row[4] > 0 and steps[row[4]] then
                for _, point in ipairs(points) do Append(steps[row[4]].points, point) end
            else
                Add(row[3], points)
            end
        end
        if objectives[4] then Add("평판 목표", {}) end
        return steps
    end
    return Givers, Objectives, AddEntity
end

local function Snapshot(db)
    local _, _, raceID = Read(UnitRace, "player")
    local _, class = Read(UnitClass, "player")
    local mapID = Read(C_Map.GetBestMapForUnit, "player")
    local position = mapID and Read(C_Map.GetPlayerMapPosition, mapID, "player")
    local x, y
    if position then x, y = Read(position.GetXY, position) end
    local state = {
        race = db.Enum.raceMaskById[raceID] or 0,
        class = db.Enum.classKeys[class] or 0,
        level = Read(UnitLevel, "player") or 0,
        origin = Point(mapID, x, y),
        done = {}, active = {}, skills = {}, items = {}, rep = {},
    }
    local completed = Read(C_QuestLog.GetAllCompletedQuestIDs)
    state.hasHistory = completed ~= nil
    for _, id in ipairs(completed or empty) do state.done[id] = true end
    local entries, count = Read(C_QuestLog.GetNumQuestLogEntries)
    local capacity = Read(C_QuestLog.GetMaxNumQuestsCanAccept) or 0
    state.free = math.max(0, capacity - (count or capacity))
    -- IsOnQuest is also checked against catalog IDs, including collapsed log headers.
    for index = 1, entries or 0 do
        local info = Read(C_QuestLog.GetInfo, index)
        if info and type(Public(info.questID)) == "number" and info.questID > 0
            and Public(info.isHeader) == false and Public(info.isHidden) == false then
            state.active[info.questID] = true
        end
    end
    local professions = { Read(GetProfessions) }
    for index = 1, 6 do
        if professions[index] then
            local _, _, skill, maximum, _, _, id = Read(GetProfessionInfo, professions[index])
            if id then state.skills[id] = { skill, maximum } end
        end
    end
    return state
end

local function ItemCount(state, id)
    if state.items[id] == nil then
        state.items[id] = Read(C_Item and C_Item.GetItemCount, id, false) or 0
    end
    return state.items[id]
end

local function Reputation(state, id)
    if state.rep[id] == nil then
        local info = Read(C_Reputation and C_Reputation.GetFactionDataByID, id)
        local standing = info and Public(info.currentStanding)
        state.rep[id] = type(standing) == "number" and standing or false
    end
    return state.rep[id]
end

local function SpellKnown(id)
    local book = C_SpellBook and C_SpellBook.IsSpellKnown
    return Read(book, id)
end

local function StaticBlock(q, state)
    if state.race == 0 or (q.races ~= 0 and not Overlaps(q.races, state.race)) then return "종족 조건" end
    if state.class == 0 or (q.classes ~= 0 and not Overlaps(q.classes, state.class)) then return "직업 조건" end
    if q.minLevel < 1 then return "최소 수락 레벨 확인 필요" end
    if state.level < q.minLevel then return ("최소 레벨 %d"):format(q.minLevel) end
    if q.maxLevel > 0 and state.level > q.maxLevel then return ("최대 레벨 %d"):format(q.maxLevel) end
    if q.minRep then
        local standing = Reputation(state, q.minRep[1])
        if not standing or standing < q.minRep[2] then return "최소 평판 조건" end
    end
    if q.maxRep then
        local standing = Reputation(state, q.maxRep[1])
        if not standing or standing >= q.maxRep[2] then return "최대 평판 조건" end
    end
    if q.skill then
        local skill = state.skills[q.skill[1]]
        if not skill or not skill[1] or skill[1] < q.skill[2] then return "전문기술 숙련 조건" end
    end
    if q.ranks then return "전문기술 등급 조건 확인 필요" end
    if q.spec ~= 0 and SpellKnown(q.spec) ~= true then return "전문기술 전문화 조건" end
    if q.spell ~= 0 and SpellKnown(math.abs(q.spell)) ~= (q.spell > 0) then return "주문 습득 조건" end
    if seasonalSorts[q.sort] or HasFlag(q.flags, 4096) or HasFlag(q.flags, 32768) then
        return "이벤트·반복 수락 가능 여부 확인 필요"
    end
    for _, id in ipairs(q.items or empty) do
        if ItemCount(state, id) == 0 then return ("필요 아이템 #%d"):format(id) end
    end
end

local function HasAny(ids, lookup)
    for _, id in ipairs(ids or empty) do
        if lookup[id] then return true end
    end
end

local function QuestBlock(q, state, questDB)
    local done, active = state.done, state.active
    if q.block then return q.block end
    if not state.hasHistory then return "완료 기록을 읽을 수 없음" end
    if HasAny(q.exclusive, done) or HasAny(q.exclusive, active) then return "배타 퀘스트 진행 또는 완료" end
    if done[q.next] or active[q.next] or done[q.breadcrumbFor] or active[q.breadcrumbFor] then
        return "후속 퀘스트 진행 또는 완료"
    end
    if done[q.untilDone] or active[q.disabledBy] or HasAny(q.breadcrumbs, active) then return "연계 진행 상태로 잠김" end
    if (q.parent ~= 0 and not active[q.parent])
        or (q.startWith ~= 0 and not (done[q.startWith] or active[q.startWith])) then
        return "연계 퀘스트 진행 필요"
    end
    if q.any then
        if not HasAny(q.any, done) then return "대체 선행 중 하나 완료 필요" end
    else
        for _, id in ipairs(q.all or empty) do
            if not done[math.abs(id)] and not (id > 0 and HasAny(questDB.exclusiveTo(id), done)) then
                return "필수 선행 완료 필요"
            end
        end
    end
end

local function ReadQuest(db, id)
    local q = db.Quest
    return {
        id = id, title = q.name(id) or ("퀘스트 #%d"):format(id), verifiedDelivery = verifiedDeliveries[id],
        races = q.requiredRaces(id), classes = q.requiredClasses(id),
        minLevel = q.requiredLevel(id), maxLevel = q.requiredMaxLevel(id),
        minRep = q.requiredMinRep(id), maxRep = q.requiredMaxRep(id),
        skill = q.requiredSkill(id), ranks = q.requiredRanks(id),
        spec = q.requiredSpecialization(id), spell = q.requiredSpell(id), items = q.requiredSourceItems(id),
        flags = q.questFlags(id), sort = q.zoneOrSort(id),
        any = q.preQuestSingle(id), all = q.preQuestGroup(id), exclusive = q.exclusiveTo(id),
        parent = q.parentQuest(id), next = q.nextQuestInChain(id), children = q.childQuests(id),
        breadcrumbs = q.breadcrumbs(id), breadcrumbFor = q.breadcrumbForQuestId(id),
        untilDone = q.availableUntilCompleted(id), startWith = q.availableStartingWith(id),
        disabledBy = q.disabledByQuest(id),
    }
end

local function Distance(from, to, sizes)
    if to.world and to.world == from.world then
        local dx, dy = to.wx - from.wx, to.wy - from.wy
        local yards = math.sqrt(dx * dx + dy * dy)
        return yards, yards
    end
    if to.mapID == from.mapID then
        if not sizes[to.mapID] then
            local width, height = Read(C_Map.GetMapWorldSize, to.mapID)
            sizes[to.mapID] = { width or 0, height or 0 }
        end
        local width, height = unpack(sizes[to.mapID])
        local dx, dy = to.x - from.x, to.y - from.y
        if width > 0 and height > 0 then
            local yards = math.sqrt((dx * width)^2 + (dy * height)^2)
            return yards, yards
        end
        return math.sqrt(dx * dx + dy * dy) * 5000
    end
    return 80000
end

local function BestPoint(points, from, sizes, rank)
    local best, bestScore, yards, bestRank
    for _, point in ipairs(points) do
        local score, distance = Distance(from, point, sizes)
        local priority = rank and rank(point) or 0
        local tied = best and priority == bestRank and score == bestScore
        local earlier = tied and
            (point.mapID < best.mapID or (point.mapID == best.mapID and
                (point.x < best.x or (point.x == best.x and point.y < best.y))))
        if not best or priority < bestRank or (priority == bestRank and score < bestScore) or earlier then
            best, bestScore, yards, bestRank = point, score, distance, priority
        end
    end
    return best, bestScore, yards, bestRank
end

local function RegionRank(origin)
    local regions = {}
    local function Region(mapID)
        if regions[mapID] then return regions[mapID] end
        local id, visited = mapID, {}
        while not visited[id] do
            visited[id] = true
            local info = Read(C_Map.GetMapInfo, id)
            local mapType, parent = info and Public(info.mapType), info and Public(info.parentMapID)
            if not (mapType and mapType > Enum.UIMapType.Zone and parent and parent > 0) then break end
            id = parent
        end
        regions[mapID] = id
        return id
    end
    local region = Region(origin.mapID)
    return function(point)
        if Region(point.mapID) == region then return 0 end
        if origin.world and point.world and origin.world == point.world then return 1 end
        return 2
    end
end

local function NearbyObjectives(quest, hub, sizes)
    local objectives = {}
    for index, step in ipairs(quest.remaining or empty) do
        local points = {}
        for _, point in ipairs(step.points) do
            local _, yards = Distance(hub, point, sizes)
            if not point.entrance and yards and yards <= objectiveRadius then Append(points, point) end
        end
        if #points == 0 then return end
        objectives[index] = points
    end
    if #objectives > 0 then return objectives end
end

local function ObjectiveTrip(origin, objectives, hub, sizes)
    local visited, total, first = {}, 0
    for _ = 1, #objectives do
        local nextPoint, nextIndex, nextYards
        for index, points in ipairs(objectives) do
            if not visited[index] then
                local point, _, yards = BestPoint(points, origin, sizes)
                if yards and (not nextYards or yards < nextYards) then
                    nextPoint, nextIndex, nextYards = point, index, yards
                end
            end
        end
        if not nextPoint then return end
        first = first or { point = nextPoint, objective = nextIndex, yards = nextYards }
        visited[nextIndex], origin, total = true, nextPoint, total + nextYards
    end
    local _, back = Distance(origin, hub, sizes)
    if back then return total + back, first end
end

local function FindTurnInBatch(catalog, origin, hub, direct, sizes, locations, skipped, rank, bestRank)
    local choice
    for _, quest in ipairs(catalog) do
        if quest.stage == 2 and not quest.unconfirmed and not skipped[quest.id] then
            local finisher, _, separation = BestPoint(locations(quest)[3], hub, sizes)
            if separation and separation <= turnInRadius and not finisher.entrance then
                local objectives = NearbyObjectives(quest, hub, sizes)
                if objectives then
                    local workFirst, first = ObjectiveTrip(origin, objectives, hub, sizes)
                    local turnInFirst = ObjectiveTrip(hub, objectives, finisher, sizes)
                    if workFirst and turnInFirst and (not rank or rank(first.point) <= bestRank) then
                        local saved = direct + turnInFirst - workFirst - separation
                        if saved >= 25 and (not choice or saved > choice.saved) then
                            first.quest, first.saved, first.finisher = quest, saved, finisher
                            choice = first
                        end
                    end
                end
            end
        end
    end
    return choice
end

local function DescribeTurnIn(quest, point, sizes, locations)
    local giver = point.giverID and point
    if not giver then
        -- A live quest POI gives coordinates but does not identify the NPC.
        for _, candidate in ipairs(locations(quest)[3]) do
            local _, yards = Distance(point, candidate, sizes)
            if yards and yards <= turnInRadius and not candidate.entrance then
                if giver and (giver.giverID ~= candidate.giverID or giver.giverKind ~= candidate.giverKind) then
                    giver = nil
                    break
                end
                giver = candidate
            end
        end
    end
    return {
        id = quest.id, title = quest.title, giver = giver and giver.label,
        giverID = giver and giver.giverID, giverKind = giver and giver.giverKind,
    }
end

local function IndexFollowUps(catalog)
    local links = {}
    for _, quest in ipairs(catalog) do
        for _, requirement in ipairs(quest.any or quest.all or empty) do
            local id = math.abs(requirement)
            links[id] = links[id] or {}
            Append(links[id], quest)
        end
    end
    return links
end

local function UnlocksNearby(quest, point, followUps, state, questDB, sizes, locations, skipped)
    local id = quest.id
    for _, followUp in ipairs(followUps[id] or empty) do
        if followUp.stage == 1 and not skipped[followUp.id] and not followUp.block
            and QuestBlock(followUp, state, questDB) then
            local wasDone, wasActive = state.done[id], state.active[id]
            state.done[id], state.active[id] = true, nil
            local unlocked = not QuestBlock(followUp, state, questDB)
            state.done[id], state.active[id] = wasDone, wasActive
            if unlocked then
                local _, _, yards = BestPoint(locations(followUp)[1], point, sizes)
                if yards and yards <= followUpRadius then return true end
            end
        end
    end
end

local function LiveWaypoint(id)
    local mapID, x, y = Read(C_QuestLog.GetNextWaypoint, id)
    if x == 0 and y == 0 then return end
    return Point(mapID, x, y, "게임이 표시한 다음 지점")
end

local function Locate(q, db, state, givers, objectives, addEntity)
    if q.locations then return q.locations end
    local starter = db.Quest.startedBy(q.id) or empty
    local locations = { givers(starter), objectives(q.id), givers(db.Quest.finishedBy(q.id) or empty) }
    local needsItem, hasItem = false, false
    for _, id in ipairs(starter[3] or empty) do
        needsItem = true
        if ItemCount(state, id) > 0 then hasItem = true end
    end
    if #locations[1] == 0 and needsItem then
        locations.itemStarts = {}
        for _, id in ipairs(starter[3]) do addEntity(locations.itemStarts, 3, id) end
        locations.pickupNote = hasItem and "가방의 시작 아이템 사용" or "시작 아이템 획득 필요"
    end
    q.locations = locations
    return locations
end

local function ActiveSteps(q, locations, origin)
    if Read(C_QuestLog.ReadyForTurnIn, q.id) == true then
        local points = {}
        for _, poi in ipairs(origin and Read(C_QuestLog.GetQuestsOnMap, origin.mapID) or empty) do
            if not isSecret(poi) and Public(poi.questID) == q.id and Public(poi.isMapIndicatorQuest) == false
                and not isSecret(poi.isQuestStart) and not poi.isQuestStart then
                Append(points, Point(origin.mapID, Public(poi.x), Public(poi.y), "게임 지도 반납 지점"))
            end
        end
        return 3, #points > 0 and points or locations[3]
    end
    local live = Read(C_QuestLog.GetQuestObjectives, q.id) or empty
    local steps, confirmed = {}, #live > 0
    local matched = {}
    -- Live objective text can differ from database ordering. Only prune a uniquely named match.
    for _, objective in ipairs(live) do
        local match, matches = nil, 0
        local text = not isSecret(objective) and Public(objective.text)
        for index, step in ipairs(locations[2]) do
            if type(text) == "string" and step.label ~= "" and step.label ~= "수행 목표"
                and text:find(step.label, 1, true) then
                match, matches = index, matches + 1
            end
        end
        if matches == 1 and matched[match] == nil and type(Public(objective.finished)) == "boolean" then
            matched[match] = objective.finished
        else
            confirmed = false
        end
    end
    for index, step in ipairs(locations[2]) do
        if matched[index] ~= true then Append(steps, step) end
        if matched[index] == nil then confirmed = false end
    end
    if not confirmed or #steps == 0 then
        local point = LiveWaypoint(q.id)
        if point then
            q.livePoint = point
            return 2, nil, { { label = point.label, points = { point } } }, true
        end
    end
    if q.verifiedDelivery and #locations[2] == 0 and #locations[3] > 0 then
        return 3, locations[3], nil, true
    end
    return 2, nil, steps, not confirmed
end

function plan.Build(limit, pause, options)
    if not plan.IsHorde() then return nil, "호드 캐릭터에서 사용할 수 있습니다." end
    local db, zones, issue = GetProvider()
    if issue then return nil, issue end
    local givers, objectives, addEntity = MakeLocations(db, zones)
    options = options or empty
    local skipped = options.skipped or empty
    local state = Snapshot(db)
    local sizes, result = {}, { route = {}, catalog = {}, byID = {}, pending = 0, missing = 0, free = state.free }
    local ids = db.Quest.GetAllIds()
    for index, id in ipairs(ids) do
        local races = db.Quest.requiredRaces(id)
        local active = state.active[id] or Read(C_QuestLog.IsOnQuest, id) == true
        if active or races == 0 or Overlaps(races, db.Enum.factionRaceMasks.Horde) then
            local starters = db.Quest.startedBy(id) or empty
            local horde = starters[2] or starters[3] or not starters[1]
            for _, npc in ipairs(starters[1] or empty) do
                if db.Npc.friendlyToFaction(npc) ~= "A" then horde = true end
            end
            if active or horde then
                local q = ReadQuest(db, id)
                q.stage = state.done[id] and 4 or 1
                if q.stage == 1 and not active then q.block = StaticBlock(q, state) end
                if active then
                    state.active[id] = true
                    local loc = Locate(q, db, state, givers, objectives, addEntity)
                    q.stage, q.turnInPoints, q.remaining, q.unconfirmed = ActiveSteps(q, loc, state.origin)
                    if Read(C_QuestLog.IsFailed, id) then q.stage = 5 end
                end
                Append(result.catalog, q)
                result.byID[id] = q
            end
        end
        if index % 100 == 0 then pause() end
    end
    for id in pairs(state.active) do
        if not result.byID[id] then
            local q = { id = id, title = Read(C_QuestLog.GetTitleForQuestID, id) or ("퀘스트 #%d"):format(id) }
            q.locations = { {}, {}, {} }
            q.stage, q.turnInPoints, q.remaining, q.unconfirmed = ActiveSteps(q, q.locations, state.origin)
            if Read(C_QuestLog.IsFailed, id) then q.stage = 5 end
            Append(result.catalog, q)
            result.byID[id] = q
        end
    end
    for index, q in ipairs(result.catalog) do
        for _, id in ipairs(q.exclusive or empty) do
            local other = result.byID[id]
            if other then
                other.exclusive = other.exclusive or {}
                if not tContains(other.exclusive, q.id) then Append(other.exclusive, q.id) end
            end
        end
        if index % 200 == 0 then pause() end
    end
    for index, q in ipairs(result.catalog) do
        local reason = q.stage == 1 and QuestBlock(q, state, db.Quest)
        -- Capture character progress before the planner simulates any quest steps.
        q.progress = q.stage == 1 and not state.hasHistory and "unknown" or progressByStage[q.stage]
        q.failed = q.stage == 5
        q.canStart = q.progress == "unstarted" and not reason
        q.status = reason or (q.stage == 3 and q.unconfirmed and "반납 조건 확인") or notesByStage[q.stage]
        if reason then result.pending = result.pending + 1 end
        if index % 200 == 0 then pause() end
    end
    result.locations = function(q) return Locate(q, db, state, givers, objectives, addEntity) end
    result.startPoints = function(q) return givers(db.Quest.startedBy(q.id) or empty) end
    if not state.origin then
        result.notice = "현재 위치를 읽을 수 있어야 동선을 계산합니다."
        return result
    end

    local from = state.origin
    local followUps = limit > 0 and IndexFollowUps(result.catalog)
    local rank = options.localFirst and RegionRank(state.origin)
    for index = 1, limit do
        local best, bestPoint, bestScore, bestYards, bestObjective
        local bestRank, bestPreferred
        local hasTurnIn
        local function Consider(q, points, objective, pickupOnly)
            local point, score, yards, priority = BestPoint(points, from, sizes, rank)
            if not point then return end
            local preferred = index == 1 and q.id == options.questID and 0 or 1
            if q.stage == 3 and not q.unconfirmed and not point.entrance then hasTurnIn = true end
            -- A small pickup cost favors finishing work nearby and freeing quest log slots.
            if q.stage == 1 then score = score + 150 end
            if pickupOnly then score = score + 500 end
            if not best or preferred < bestPreferred or (preferred == bestPreferred and
                (priority < bestRank or (priority == bestRank and
                    (score < bestScore or (score == bestScore and q.id < best.id))))) then
                best, bestPoint, bestScore, bestYards, bestObjective = q, point, score, yards, objective
                bestRank, bestPreferred = priority, preferred
            end
        end
        for index, q in ipairs(result.catalog) do
            if not skipped[q.id] then
                if q.stage == 1 and state.free > 0 and not QuestBlock(q, state, db.Quest) then
                    local loc = result.locations(q)
                    Consider(q, loc[1], nil, #loc[2] == 0 and #loc[3] == 0)
                elseif q.stage == 2 then
                    for objective, step in ipairs(q.remaining or empty) do Consider(q, step.points, objective) end
                elseif q.stage == 3 then
                    Consider(q, q.turnInPoints or result.locations(q)[3])
                end
            end
            if index % 500 == 0 then pause() end
        end
        if index == 1 and options.questID and bestPreferred ~= 0 then result.preferredUnavailable = true end
        if not best then break end
        local reason, turnIns
        if bestPreferred == 0 then
            reason = "직접 선택한 퀘스트"
        elseif best.stage == 3 and not best.unconfirmed and not bestPoint.entrance then
            if state.free == 0 then
                reason = "먼저 반납 · 퀘스트 기록 공간 확보"
            elseif UnlocksNearby(best, bestPoint, followUps, state, db.Quest, sizes, result.locations, skipped) then
                reason = "먼저 반납 · 가까운 후속 퀘스트 열림"
            elseif bestYards then
                local batch = FindTurnInBatch(result.catalog, from, bestPoint, bestYards, sizes, result.locations,
                    skipped, rank, bestRank)
                if batch then
                    turnIns = {
                        DescribeTurnIn(best, bestPoint, sizes, result.locations),
                        DescribeTurnIn(batch.quest, batch.finisher, sizes, result.locations),
                    }
                    best, bestPoint, bestObjective, bestYards = batch.quest, batch.point, batch.objective, batch.yards
                    reason = ("수행 후 함께 반납 · 약 %d m 절약"):format(math.floor(batch.saved * 0.9144 + 0.5))
                else
                    reason = "먼저 반납 · 가까운 지점 우선"
                end
            else
                reason = "먼저 반납 · 비교 거리 미확인"
            end
        elseif hasTurnIn and bestYards and best.stage < 3 then
            reason = stages[best.stage] .. " 먼저 · 가까운 지점 우선"
        end
        local loc = result.locations(best)
        Append(result.route, {
            quest = best, stage = best.stage, point = bestPoint, yards = bestYards,
            objective = bestObjective and best.remaining[bestObjective].label,
            branch = best.stage == 1 and best.exclusive ~= nil,
            verifyTurnIn = best.stage == 3 and best.unconfirmed,
            reason = reason,
            turnIns = turnIns,
            remote = state.origin.world and bestPoint.world and state.origin.world ~= bestPoint.world,
        })
        from = bestPoint
        if best.stage == 1 then
            best.stage, best.remaining = 2, { unpack(loc[2]) }
            state.free = state.free - 1
            state.active[best.id] = true
            if #best.remaining == 0 and #loc[3] > 0 then
                best.stage, best.unconfirmed = 3, not best.verifiedDelivery
            end
        elseif best.stage == 2 then
            table.remove(best.remaining, bestObjective)
            if #best.remaining == 0 and not best.unconfirmed and not bestPoint.entrance then best.stage = 3 end
            if bestPoint.entrance then best.unconfirmed = true end
        else
            best.stage = 4
            if not bestPoint.entrance and not best.unconfirmed then
                state.free = state.free + 1
                state.active[best.id], state.done[best.id] = nil, true
            end
        end
        pause()
    end
    for _, q in ipairs(result.catalog) do
        local unreachable = q.stage == 2
        for _, step in ipairs(q.remaining or empty) do
            if #step.points > 0 then unreachable = false break end
        end
        if q.unconfirmed or unreachable
            or (q.stage == 1 and not q.block and q.locations
                and (#q.locations[1] == 0 or (#q.locations[2] == 0 and #q.locations[3] == 0)))
            or (q.stage == 3 and #(q.turnInPoints or result.locations(q)[3]) == 0) then
            result.missing = result.missing + 1
        end
    end
    return result
end
