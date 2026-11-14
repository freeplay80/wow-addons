-- Classic disenchant results by item level.
-- The game has no API that tells what disenchanting yields, and Auctionator's disenchant price API returned
-- nothing on Forever (user screenshot, 2026-11-15), so the results are listed here.
-- Source: Warcraft Wiki, "Disenchanting tables" (https://warcraft.wiki.gg/wiki/Disenchanting_tables, read
-- 2026-11-15; the page itself is marked outdated). Chances are split evenly over the quantity range.
-- Not verified against the Forever server; Forever-only items may disenchant differently.
local _, ns = ...

local STRANGE, SOUL, VISION, DREAM, ILLUSION = 10940, 11083, 11137, 11176, 16204
local LESSER_MAGIC, GREATER_MAGIC, LESSER_ASTRAL, GREATER_ASTRAL = 10938, 10939, 10998, 11082
local LESSER_MYSTIC, GREATER_MYSTIC, LESSER_NETHER, GREATER_NETHER = 11134, 11135, 11174, 11175
local LESSER_ETERNAL, GREATER_ETERNAL = 16202, 16203
local SMALL_GLIMMERING, LARGE_GLIMMERING, SMALL_GLOWING, LARGE_GLOWING = 10978, 11084, 11138, 11139
local SMALL_RADIANT, LARGE_RADIANT, SMALL_BRILLIANT, LARGE_BRILLIANT = 11177, 11178, 14343, 14344
local NEXUS = 20725

-- Each entry: { item, chance, min, max }. A row covers item levels up to `upTo`.
local uncommonArmor = {
    { upTo = 15, { STRANGE, 0.80, 1, 2 }, { LESSER_MAGIC, 0.20, 1, 2 } },
    { upTo = 20, { STRANGE, 0.75, 2, 3 }, { GREATER_MAGIC, 0.20, 1, 2 }, { SMALL_GLIMMERING, 0.05, 1, 1 } },
    { upTo = 25, { STRANGE, 0.75, 4, 6 }, { LESSER_ASTRAL, 0.15, 1, 2 }, { SMALL_GLIMMERING, 0.10, 1, 1 } },
    { upTo = 30, { SOUL, 0.75, 1, 2 }, { GREATER_ASTRAL, 0.20, 1, 2 }, { LARGE_GLIMMERING, 0.05, 1, 1 } },
    { upTo = 35, { SOUL, 0.75, 2, 5 }, { LESSER_MYSTIC, 0.20, 1, 2 }, { SMALL_GLOWING, 0.05, 1, 1 } },
    { upTo = 40, { VISION, 0.75, 1, 2 }, { GREATER_MYSTIC, 0.20, 1, 2 }, { LARGE_GLOWING, 0.05, 1, 1 } },
    { upTo = 45, { VISION, 0.75, 2, 5 }, { LESSER_NETHER, 0.20, 1, 2 }, { SMALL_RADIANT, 0.05, 1, 1 } },
    { upTo = 50, { DREAM, 0.75, 1, 2 }, { GREATER_NETHER, 0.20, 1, 2 }, { LARGE_RADIANT, 0.05, 1, 1 } },
    { upTo = 55, { DREAM, 0.75, 2, 5 }, { LESSER_ETERNAL, 0.20, 1, 2 }, { SMALL_BRILLIANT, 0.05, 1, 1 } },
    { upTo = 60, { ILLUSION, 0.75, 1, 2 }, { GREATER_ETERNAL, 0.20, 1, 2 }, { LARGE_BRILLIANT, 0.05, 1, 1 } },
    { upTo = 65, { ILLUSION, 0.75, 2, 5 }, { GREATER_ETERNAL, 0.20, 2, 3 }, { LARGE_BRILLIANT, 0.05, 1, 1 } },
}

local uncommonWeapon = {
    { upTo = 15, { LESSER_MAGIC, 0.80, 1, 2 }, { STRANGE, 0.20, 1, 2 } },
    { upTo = 20, { GREATER_MAGIC, 0.75, 1, 2 }, { STRANGE, 0.20, 2, 3 }, { SMALL_GLIMMERING, 0.05, 1, 1 } },
    { upTo = 25, { LESSER_ASTRAL, 0.75, 1, 2 }, { STRANGE, 0.15, 4, 6 }, { SMALL_GLIMMERING, 0.10, 1, 1 } },
    { upTo = 30, { GREATER_ASTRAL, 0.75, 1, 2 }, { SOUL, 0.20, 1, 2 }, { LARGE_GLIMMERING, 0.05, 1, 1 } },
    { upTo = 35, { LESSER_MYSTIC, 0.75, 1, 2 }, { SOUL, 0.20, 2, 5 }, { SMALL_GLOWING, 0.05, 1, 1 } },
    { upTo = 40, { GREATER_MYSTIC, 0.75, 1, 2 }, { VISION, 0.20, 1, 2 }, { LARGE_GLOWING, 0.05, 1, 1 } },
    { upTo = 45, { LESSER_NETHER, 0.75, 1, 2 }, { VISION, 0.20, 2, 5 }, { SMALL_RADIANT, 0.05, 1, 1 } },
    { upTo = 50, { GREATER_NETHER, 0.75, 1, 2 }, { DREAM, 0.20, 1, 2 }, { LARGE_RADIANT, 0.05, 1, 1 } },
    { upTo = 55, { LESSER_ETERNAL, 0.75, 1, 2 }, { DREAM, 0.22, 2, 5 }, { SMALL_BRILLIANT, 0.03, 1, 1 } },
    { upTo = 60, { GREATER_ETERNAL, 0.75, 1, 2 }, { ILLUSION, 0.22, 1, 2 }, { LARGE_BRILLIANT, 0.03, 1, 1 } },
    { upTo = 65, { GREATER_ETERNAL, 0.75, 2, 3 }, { ILLUSION, 0.22, 2, 5 }, { LARGE_BRILLIANT, 0.03, 1, 1 } },
}

local rare = {
    { upTo = 25, { SMALL_GLIMMERING, 1, 1, 1 } },
    { upTo = 30, { LARGE_GLIMMERING, 1, 1, 1 } },
    { upTo = 35, { SMALL_GLOWING, 1, 1, 1 } },
    { upTo = 40, { LARGE_GLOWING, 1, 1, 1 } },
    { upTo = 45, { SMALL_RADIANT, 1, 1, 1 } },
    { upTo = 50, { LARGE_RADIANT, 1, 1, 1 } },
    { upTo = 55, { SMALL_BRILLIANT, 1, 1, 1 } },
    { upTo = 65, { LARGE_BRILLIANT, 0.995, 1, 1 }, { NEXUS, 0.005, 1, 1 } },
}

-- The page has no epic row below item level 40.
local epic = {
    { from = 40, upTo = 45, { SMALL_RADIANT, 1, 2, 4 } },
    { upTo = 50, { LARGE_RADIANT, 1, 2, 4 } },
    { upTo = 55, { SMALL_BRILLIANT, 1, 2, 4 } },
    { upTo = 60, { NEXUS, 1, 1, 1 } },
    { upTo = 88, { NEXUS, 1, 1, 2 } },
}

local WEAPON, ARMOR = 2, 4

-- Possible results as a list of { itemID, chance, min, max }, most likely first; nil when the item level is
-- outside the table or the item is not a disenchantable weapon or armor.
function ns.DisenchantOutcomes(quality, itemLevel, classID)
    if type(itemLevel) ~= "number" or (classID ~= WEAPON and classID ~= ARMOR) then return end
    local rows = quality == 2 and (classID == WEAPON and uncommonWeapon or uncommonArmor)
        or quality == 3 and rare or quality == 4 and epic
    if not rows or (rows[1].from and itemLevel < rows[1].from) then return end
    for _, row in ipairs(rows) do
        if itemLevel <= row.upTo then
            local list = {}
            for _, entry in ipairs(row) do
                list[#list + 1] = { itemID = entry[1], chance = entry[2], min = entry[3], max = entry[4] }
            end
            return list
        end
    end
end
