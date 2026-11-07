-- Spellbook.lua
-- Finds the shocks, Stormstrike and totems you know, so the Tracking tab
-- can offer them. Forever lists every rank as its own spellbook entry;
-- ranks are merged by name here.

local _, ns = ...
local C = ns.C

local B = {
  cooldowns = {}, -- Stormstrike and shocks: { name, id, icon }
  totems = {},    -- every "... Totem" you know
  byName = {},
  isTotem = {},
  ids = {},       -- name -> lowest-rank spell ID (used for saving settings)
  learned = {},   -- totem name -> element slot, learned in game
  nameOf = {},    -- any rank's spell ID -> name
  rankOf = {},    -- spell ID -> rank number (nil if the spell has no ranks)
  maxRank = {},   -- name -> highest rank you know
  topId = {},     -- name -> spell ID of that highest rank
  listeners = {},
}
ns.Book = B

-- Cooldowns offered on the Tracking tab. They always get a checkbox, even
-- before you learn them. `match` finds the spell in your spellbook: exact
-- name, or any spell containing it (so "Fire Nova Totem" or a renamed
-- "Fire Nova" both count).
local CATALOG = {
  { key = "Stormstrike", id = 17364 },
  { key = "Earth Shock", id = 8042 },
  { key = "Flame Shock", id = 8050 },
  { key = "Frost Shock", id = 8056 },
  { key = "Fire Nova",   id = 1535, contains = "Fire Nova" },
}
B.CATALOG = CATALOG
B.DEFAULT_COOLDOWNS = { ["Stormstrike"] = true, ["Earth Shock"] = true, ["Fire Nova"] = true }

-- Element slot for the original totems (1 Fire, 2 Earth, 3 Water, 4 Air).
-- New Forever totems are learned the first time you drop them.
local ELEMENT = {
  ["Searing Totem"] = 1, ["Fire Nova Totem"] = 1, ["Magma Totem"] = 1,
  ["Flametongue Totem"] = 1, ["Frost Resistance Totem"] = 1,
  ["Stoneskin Totem"] = 2, ["Earthbind Totem"] = 2, ["Stoneclaw Totem"] = 2,
  ["Strength of Earth Totem"] = 2, ["Tremor Totem"] = 2,
  ["Healing Stream Totem"] = 3, ["Mana Spring Totem"] = 3, ["Poison Cleansing Totem"] = 3,
  ["Disease Cleansing Totem"] = 3, ["Fire Resistance Totem"] = 3, ["Mana Tide Totem"] = 3,
  ["Grounding Totem"] = 4, ["Nature Resistance Totem"] = 4, ["Windfury Totem"] = 4,
  ["Sentry Totem"] = 4, ["Windwall Totem"] = 4, ["Grace of Air Totem"] = 4,
  ["Tranquil Air Totem"] = 4,
}

function B.ElementOf(name)
  if not name then return nil end
  return B.learned[name] or ELEMENT[name]
end

function B.Learn(name, slot)
  if name and slot and not B.ElementOf(name) then B.learned[name] = slot end
end

function B.IsTotemName(name)
  return name ~= nil and (B.isTotem[name] or name:find("Totem$") ~= nil)
end

function B.OnChange(fn)
  table.insert(B.listeners, fn)
end

local function Scan()
  local found, order = {}, {}
  if not (C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines) then return found, order end
  local bank = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) or 0
  local okN, lines = pcall(C_SpellBook.GetNumSpellBookSkillLines)
  lines = okN and C.PlainNumber(lines) or 0
  for line = 1, lines do
    local ok, info = pcall(C_SpellBook.GetSpellBookSkillLineInfo, line)
    if ok and type(info) == "table" and not C.Secret(info) then
      local off, num = C.PlainNumber(info.itemIndexOffset), C.PlainNumber(info.numSpellBookItems)
      if off and num then
        for i = off + 1, off + num do
          local okI, item = pcall(C_SpellBook.GetSpellBookItemInfo, i, bank)
          if okI and type(item) == "table" and not C.Secret(item) then
            local id, name = C.PlainNumber(item.spellID), C.Plain(item.name)
            if id and type(name) == "string" and not C.Plain(item.isPassive) then
              local e = found[name]
              if not e then
                e = { name = name, id = id, icon = C.Plain(item.iconID), ranks = {} }
                found[name] = e
                order[#order + 1] = e
              elseif id < e.id then
                e.id = id
              end
              -- "Rank 3" -> 3, from the spellbook entry or the spell's subtext.
              local sub = C.Plain(item.subName)
              if (type(sub) ~= "string" or sub == "") and C_Spell and C_Spell.GetSpellSubtext then
                local okS, t = pcall(C_Spell.GetSpellSubtext, id)
                sub = okS and C.Plain(t) or nil
              end
              local rank = type(sub) == "string" and tonumber(sub:match("(%d+)")) or nil
              table.insert(e.ranks, { id = id, rank = rank })
            end
          end
        end
      end
    end
  end
  return found, order
end

function B.Rebuild()
  local found, order = Scan()
  B.byName = found
  B.cooldowns, B.totems, B.isTotem = {}, {}, {}

  -- Catalog cooldowns first, known or not.
  local claimed = {}
  for _, c in ipairs(CATALOG) do
    local localName = C.SpellName(c.id) or c.key
    local hit = found[localName] or found[c.key]
    if not hit and c.contains then
      for _, e in ipairs(order) do
        if e.name:find(c.contains, 1, true) then
          hit = e
          break
        end
      end
    end
    local entry = { key = c.key, label = hit and hit.name or localName, known = hit ~= nil }
    if hit then
      entry.name, entry.icon, entry.id = hit.name, hit.icon, hit.id
      claimed[hit.name] = true
    else
      local _, icon = C.SpellInfo(c.id)
      entry.name, entry.icon, entry.id = localName, icon, c.id
    end
    table.insert(B.cooldowns, entry)
  end

  B.nameOf, B.rankOf, B.maxRank, B.topId = {}, {}, {}, {}
  for _, e in ipairs(order) do
    for _, r in ipairs(e.ranks or {}) do
      B.nameOf[r.id] = e.name
      B.rankOf[r.id] = r.rank
      if r.rank and r.rank > (B.maxRank[e.name] or 0) then
        B.maxRank[e.name] = r.rank
        B.topId[e.name] = r.id
      end
    end
  end

  for _, e in ipairs(order) do
    B.ids[e.name] = e.id
    if e.name:find("Shock") and not claimed[e.name] then
      -- A shock Forever added that isn't in the catalog.
      table.insert(B.cooldowns, { key = e.name, name = e.name, label = e.name, icon = e.icon, id = e.id, known = true })
    elseif e.name:find("Totem$") then
      table.insert(B.totems, e)
      B.isTotem[e.name] = true
    end
  end

  table.sort(B.totems, function(a, b) return a.name < b.name end)

  for _, fn in ipairs(B.listeners) do ns.Safe("spellbook", fn) end
end

local ev = CreateFrame("Frame")
C.Register(ev, "SPELLS_CHANGED")
ev:SetScript("OnEvent", function()
  if ns.initialized then ns.Safe("spellbook", B.Rebuild) end
end)
