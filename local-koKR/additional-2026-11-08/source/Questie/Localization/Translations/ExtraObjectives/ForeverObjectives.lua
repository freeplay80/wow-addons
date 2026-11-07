---@type l10n
local l10n = QuestieLoader:ImportModule("l10n")

local foreverObjectiveLocals = {
    ["Use the Flutterfly Swatter"] = {
        ["enUS"] = true,
        ["deDE"] = false,
        ["esES"] = false,
        ["esMX"] = false,
        ["frFR"] = false,
        ["koKR"] = false,
        ["ptBR"] = false,
        ["ruRU"] = false,
        ["zhCN"] = false,
        ["zhTW"] = false,
    },
    ["Knock on Kuramaa's Stump"] = {
        ["enUS"] = true,
        ["deDE"] = false,
        ["esES"] = false,
        ["esMX"] = false,
        ["frFR"] = false,
        ["koKR"] = false,
        ["ptBR"] = false,
        ["ruRU"] = false,
        ["zhCN"] = false,
        ["zhTW"] = false,
    },
}

for k, v in pairs(foreverObjectiveLocals) do
    l10n.translations[k] = v
end

-- Local Korean UI supplement (2026-11-08)
local korean = {
  ["Use the Flutterfly Swatter"] = "Flutterfly Swatter 사용",
  ["Knock on Kuramaa's Stump"] = "Kuramaa의 그루터기 두드리기",
}
for key, text in pairs(korean) do
  l10n.translations[key].koKR = text
end
