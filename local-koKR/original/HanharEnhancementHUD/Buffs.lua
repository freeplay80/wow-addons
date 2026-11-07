-- Buffs.lua
-- Weapon imbue timer and shield watcher.
--
-- Forever hides your own buffs from addons during combat, so this section
-- reads everything it can before the pull, then keeps time on its own clock.
-- Recasting an imbue or shield mid-fight is picked up from your own cast
-- event, which stays readable.

local _, ns = ...
local C = ns.C
local M = {}
ns.RegisterModule("buffs", M)

-- Lightning Shield, Water Shield, Earth Shield. Missing IDs are skipped.
local SHIELD_IDS = { 324, 24398, 974 }
-- Rockbiter, Flametongue, Frostbrand, Windfury Weapon.
local IMBUE_IDS = { 8017, 8024, 8033, 8232 }
local IMBUE_ENGLISH = { "Rockbiter Weapon", "Flametongue Weapon", "Frostbrand Weapon", "Windfury Weapon" }

local FALLBACK_WEAPON = "Interface\\Icons\\INV_Axe_01"
local SOURCE_NAMES = { "item API", "legacy", "buff" }
local FALLBACK_SHIELD = "Interface\\Icons\\Spell_Nature_LightningShield"

function M:Init(parent)
  self.imbueIcon = ns.CreateIcon(parent, 32)
  self.imbueIcon:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
  self.shieldIcon = ns.CreateIcon(parent, 32)
  self.shieldIcon:SetPoint("LEFT", self.imbueIcon, "RIGHT", 4, 0)

  -- What we know, in plain numbers on our own clock.
  self.imbue = { full = 300 }
  self.shield = { full = 600, maxCount = 3 }
  self.nextTick = 0
  self:ResolveNames()

  local ev = CreateFrame("Frame")
  C.Register(ev, "SPELLS_CHANGED")
  C.Register(ev, "PLAYER_ENTERING_WORLD")
  C.Register(ev, "UNIT_SPELLCAST_SUCCEEDED", "player")
  C.Register(ev, "UNIT_AURA", "player")
  C.Register(ev, "UNIT_INVENTORY_CHANGED", "player")
  C.Register(ev, "PLAYER_EQUIPMENT_CHANGED")
  C.Register(ev, "WEAPON_ENCHANT_CHANGED")
  C.Register(ev, "PLAYER_REGEN_ENABLED")
  ev:SetScript("OnEvent", function(_, event, _, _, spellID)
    ns.Safe("buffs", function()
      if event == "SPELLS_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
        self:ResolveNames()
      elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        self:OnCast(spellID)
      end
      -- Something changed: re-read on the next tick.
      self.readDue = true
      self.nextTick = 0
    end)
  end)

  -- Built once: the three imbue sources, tried in order.
  self.sources = { M.FromItemAPI, M.FromLegacy, function() return self:FromAura() end }
  self.readDue = true
  self.nextRead = 0
end

function M:ResolveNames()
  self.shieldNames = {}
  for _, id in ipairs(SHIELD_IDS) do
    local name, icon = C.SpellInfo(id)
    if name then
      self.shieldNames[name] = true
      if id == 324 then self.lsName, self.lsIcon = name, icon end
    end
  end
  self.lsName = self.lsName or "Lightning Shield"
  self.shieldNames[self.lsName] = true
  self.lsKnown = C.KnowsSpell(self.lsName)

  self.imbueNames = {}
  for i, id in ipairs(IMBUE_IDS) do
    self.imbueNames[C.SpellInfo(id) or IMBUE_ENGLISH[i]] = true
    self.imbueNames[IMBUE_ENGLISH[i]] = true
  end
end

function M:SetEnabled(on)
  self.enabled = on
  ns.SetShownC(self.imbueIcon, on)
  ns.SetShownC(self.shieldIcon, on)
  if not on then
    ns.SetPulse(self.imbueIcon, false)
    ns.SetPulse(self.shieldIcon, false)
  end
end

-- Your own casts stay readable in combat.
function M:OnCast(spellID)
  local id = C.PlainNumber(spellID)
  if not id then return end
  local name = C.SpellName(id)
  if not name then return end
  local now = GetTime()
  if self.imbueNames[name] then
    self.imbue.expires = now + self.imbue.full
    self.imbue.charges = nil
    self.imbue.known = true
    self.imbue.present = true
  elseif self.shieldNames[name] then
    local sh = self.shield
    sh.present = true
    sh.expires = now + sh.full
    sh.count = (name == self.lsName) and sh.maxCount or nil
    sh.estimated = true
    local _, icon = C.SpellInfo(id)
    sh.icon = icon or sh.icon
  end
end

-- Seconds from an enchant time that may be in milliseconds (the older API)
-- or seconds. Imbues last minutes, so anything over an hour must be ms.
local function ToSeconds(v)
  if v > 3600 then return v / 1000 end
  return v
end

-- Each source returns present (true/false) or nil when it can't tell,
-- plus seconds left, charges and an icon when it knows them.

-- 1. C_Item.GetWeaponEnchantInfo: reports the "Imbue" enchant type that
--    shaman weapon imbues use on this client.
function M.FromItemAPI()
  if not (C_Item and C_Item.GetWeaponEnchantInfo) then return nil end
  local slot = (Enum and Enum.WeaponSlot and Enum.WeaponSlot.MainHand) or 0
  local ok, list = pcall(C_Item.GetWeaponEnchantInfo, slot)
  if not ok or type(list) ~= "table" or C.Secret(list) then return nil end
  if list.hasEnchant ~= nil then list = { list } end -- a single struct
  for _, e in ipairs(list) do
    if type(e) ~= "table" or C.Secret(e) then return nil end
    local has, kind = C.Plain(e.hasEnchant), C.PlainNumber(e.enchantType)
    if has == nil then return nil end
    if has and kind ~= 1 then -- 1 = permanent enchant, not an imbue
      local left = C.PlainNumber(e.timeLeft)
      return true, left and left > 0 and ToSeconds(left) or nil, C.PlainNumber(e.charges), C.Plain(e.enchantIconID)
    end
  end
  return false
end

-- 2. The older GetWeaponEnchantInfo (temporary enchants).
function M.FromLegacy()
  local ok, hasMH, mhExp, mhCharges = C.Call(GetWeaponEnchantInfo)
  if not ok or C.Secret(hasMH) or hasMH == nil then return nil end
  if not hasMH then return false end
  local ms = C.PlainNumber(mhExp)
  return true, ms and ms > 0 and ms / 1000 or nil, C.PlainNumber(mhCharges)
end

-- 3. A buff on you named after the imbue.
function M:FromAura()
  local b, readable = C.FindBuff(self.imbueNames)
  if not readable then return nil end
  if not b then return false end
  local left = (b.expirationTime and b.expirationTime > 0) and (b.expirationTime - GetTime()) or nil
  return true, left, b.count, b.icon
end

function M:ReadImbue(now)
  local st = self.imbue
  local sawAnswer, found = false, false
  for srcIndex, src in ipairs(self.sources) do
    local okS, present, left, charges, icon = pcall(src)
    if okS and present ~= nil then
      sawAnswer = true
      if present then
        found = true
        if ns.Diag then ns.Diag:Fact("imbueSource", SOURCE_NAMES[srcIndex] or "?") end
        if left then
          st.expires = now + left
          if left > st.full then st.full = left end
        elseif not st.expires or st.expires <= now then
          st.expires = nil
          st.noTimer = true
        end
        st.charges = charges
        st.icon = icon or st.icon
        break
      end
    end
  end
  if not sawAnswer then return end -- in combat: keep what we had
  st.known = true
  st.present = found
  if not found then
    st.expires, st.charges, st.icon, st.noTimer = nil, nil, nil, nil
  elseif st.expires then
    st.noTimer = nil
  end
end

-- /ehud imbuecheck: show what each source reports, for troubleshooting.
function M:DebugImbue()
  local names = {}
  for n in pairs(self.imbueNames) do names[#names + 1] = n end
  local function show(label, ok, ...)
    local parts = {}
    for i = 1, select("#", ...) do
      local v = select(i, ...)
      parts[#parts + 1] = C.Secret(v) and "<secret>" or tostring(v)
    end
    ns.Print(label .. ": " .. (ok and table.concat(parts, ", ") or "error"))
  end
  show("item API (present, sec, charges, icon)", pcall(M.FromItemAPI))
  show("legacy (present, sec, charges)", pcall(M.FromLegacy))
  show("buff (present, sec, count, icon)", pcall(function() return self:FromAura() end))
  if C_Item and C_Item.GetWeaponEnchantInfo then
    local ok, list = pcall(C_Item.GetWeaponEnchantInfo, (Enum and Enum.WeaponSlot and Enum.WeaponSlot.MainHand) or 0)
    if ok and type(list) == "table" and not C.Secret(list) then
      if list.hasEnchant ~= nil then list = { list } end
      for i, e in ipairs(list) do
        show("  raw enchant " .. i .. " (has, type, timeLeft, charges, id)", true,
          e.hasEnchant, e.enchantType, e.timeLeft, e.charges, e.enchantID)
      end
    end
  end
end

function M:ReadShield(now)
  local b, readable = C.FindBuff(self.shieldNames)
  local sh = self.shield
  if not readable then return end -- in combat: keep what we had
  sh.estimated = false
  if b then
    sh.present = true
    sh.icon = b.icon or sh.icon
    sh.count = b.count
    if b.name == self.lsName and b.count and b.count > sh.maxCount then sh.maxCount = b.count end
    if b.expirationTime and b.expirationTime > 0 then
      sh.expires = b.expirationTime
      if b.duration and b.duration > 0 then sh.full = b.duration end
    else
      sh.expires = nil
    end
  else
    sh.present = false
    sh.expires = nil
  end
end

-- For the pre-pull reminder: what needs refreshing before a pull.
function M:PrepullItems(now)
  local items = {}
  local st, sh = self.imbue, self.shield
  local okT, tex = C.Call(GetInventoryItemTexture, "player", 16)
  if okT and C.Plain(tex) and st.known then
    if not st.present and not (st.expires and st.expires > now) then
      items[#items + 1] = "imbue"
    elseif st.expires and st.expires - now < 120 then
      items[#items + 1] = string.format("imbue (%s left)", ns.FormatTime(st.expires - now))
    end
  end
  if C.KnowsSpell(self.lsName) then
    local present = sh.present and not (sh.expires and sh.expires <= now)
    if not present then
      items[#items + 1] = "Lightning Shield"
    elseif sh.count and sh.count <= 1 and not sh.estimated then
      items[#items + 1] = "Lightning Shield (1 charge)"
    end
  end
  return items
end

function M:OnCombatStart()
  local st = self.imbue
  local hasWeapon = GetInventoryItemTexture and C.Plain(GetInventoryItemTexture("player", 16))
  if hasWeapon and st.known and not st.present and not (st.expires and st.expires > GetTime()) then
    ns.Alert("No weapon imbue!", 1, 0.25, 0.25, "imbueMissing")
  end
end

function M:DrawImbue(now)
  local ic = self.imbueIcon
  local st = self.imbue
  local tex = self.weaponTex
  local expires, charges = st.expires, st.charges
  if ns.testMode then tex, expires, charges = tex or FALLBACK_WEAPON, now + 45, nil end
  local present = ns.testMode or (expires and expires > now) or (st.present and st.noTimer)

  if not tex then
    ns.SetShownC(ic, false)
    ns.SetPulse(ic, false)
    return
  end
  ns.SetShownC(ic, true)
  ns.SetTex(ic.icon, (not ns.testMode and st.icon) or tex)

  local left = expires and (expires - now) or 0
  if present then
    local warn = left > 0 and left <= ns.db.imbueWarn
    ns.SetDesat(ic.icon, false)
    ns.SetFont(ic.text, "NumberFontNormal")
    ns.SetText(ic.text, left > 0 and ns.FormatTime(left) or "")
    ns.SetTextColorC(ic.text, 1, 1, 1)
    ns.SetText(ic.count, (charges and charges > 0) and charges or "")
    ns.SetBorder(ic, warn and ns.COLORS.warn or ns.COLORS.ok)
    ns.SetPulse(ic, warn and (ns.inCombat or ns.testMode))
    if warn and not st.warned and not ns.testMode then
      st.warned = true
      ns.Alert("Weapon imbue expiring", 1, 0.85, 0.2, "imbueExpiring")
    elseif not warn then
      st.warned = false
    end
  elseif st.known then
    st.warned = false
    ns.SetDesat(ic.icon, true)
    ns.SetFont(ic.text, "GameFontNormalSmall")
    ns.SetText(ic.text, "NONE")
    ns.SetTextColorC(ic.text, 1, 0.3, 0.3)
    ns.SetText(ic.count, "")
    ns.SetBorder(ic, ns.COLORS.bad)
    ns.SetPulse(ic, ns.inCombat)
  else
    ns.SetText(ic.text, "")
    ns.SetBorder(ic, ns.COLORS.off)
    ns.SetPulse(ic, false)
  end
end

function M:DrawShield(now)
  local ic = self.shieldIcon
  local sh = self.shield
  local present, expires, count, icon, estimated = sh.present, sh.expires, sh.count, sh.icon, sh.estimated
  if ns.testMode then present, expires, count, icon, estimated = true, now + 380, 1, self.lsIcon, false end

  if present and expires and expires <= now then
    present = false
    sh.present = false
  end

  if present then
    ns.SetShownC(ic, true)
    ns.SetTex(ic.icon, icon or self.lsIcon or FALLBACK_SHIELD)
    ns.SetDesat(ic.icon, false)
    ns.SetFont(ic.text, "NumberFontNormal")
    ns.SetText(ic.text, expires and ns.FormatTime(expires - now) or "")
    ns.SetTextColorC(ic.text, 1, 1, 1)
    -- In combat, charges used up by hits can't be seen, so show "?" instead of a guess.
    if estimated or (ns.inCombat and not ns.testMode and count == nil) then
      ns.SetText(ic.count, "?")
    else
      ns.SetText(ic.count, (count and count > 0) and count or "")
    end
    local low = (not estimated) and count and count > 0 and count <= 1
    ns.SetBorder(ic, low and ns.COLORS.warn or ns.COLORS.ok)
    ns.SetPulse(ic, low and (ns.inCombat or ns.testMode) or false)
  elseif self.lsKnown then
    ns.SetShownC(ic, true)
    ns.SetTex(ic.icon, self.lsIcon or FALLBACK_SHIELD)
    ns.SetDesat(ic.icon, true)
    ns.SetFont(ic.text, "GameFontNormalSmall")
    ns.SetText(ic.text, "NONE")
    ns.SetTextColorC(ic.text, 1, 0.3, 0.3)
    ns.SetText(ic.count, "")
    ns.SetBorder(ic, ns.COLORS.bad)
    ns.SetPulse(ic, ns.inCombat)
  else
    ns.SetShownC(ic, false)
    ns.SetPulse(ic, false)
  end
end

function M:OnUpdate(now)
  if now < self.nextTick then return end
  self.nextTick = now + 0.2
  if not ns.testMode and (self.readDue or now >= self.nextRead) then
    self.readDue = false
    self.nextRead = now + 5
    local okT, tex = C.Call(GetInventoryItemTexture, "player", 16)
    self.weaponTex = okT and C.Plain(tex) or nil
    self:ReadImbue(now)
    self:ReadShield(now)
  end
  self:DrawImbue(now)
  self:DrawShield(now)
end

function M:Test()
  self.nextTick = 0
  self.readDue = true
end
