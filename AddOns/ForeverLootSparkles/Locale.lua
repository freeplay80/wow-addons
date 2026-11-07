local _, ns = ...;

local koKR = {
	["Show quest item sparkles"] = "퀘스트 아이템 반짝임 표시",
	["Keeps the game's loot sparkle on, even after a graphics preset turns it off. Your outline mode is left as you set it. Switching this off takes effect after restarting the game."] = "그래픽 설정을 바꿔도 게임의 전리품 반짝임을 유지합니다. 윤곽선 설정은 그대로 둡니다. 이 기능을 끄면 게임을 다시 시작한 뒤 적용됩니다.",
	["|cffff8000Forever Loot Sparkles:|r restart the game to remove the sparkles. /reload is not enough."] = "|cffff8000Forever Loot Sparkles:|r 반짝임을 끄려면 게임을 완전히 종료한 뒤 다시 실행하세요.",
	["Sparkles while approaching"] = "가까이 가면 반짝임 표시",
	["Ore veins"] = "광맥",
	["Herbs"] = "약초",
	["Quest objects"] = "퀘스트 물체",
	["Corpses with loot"] = "전리품이 남은 시체",
	["Sparkles on mining nodes as you approach them."] = "광맥에 다가가면 반짝임을 표시합니다.",
	["Sparkles on herbs as you approach them."] = "약초에 다가가면 반짝임을 표시합니다.",
	["Extra sparkles on quest objects as you approach them. Off by default: the game's loot sparkle already marks most of them."] = "퀘스트 물체에 다가가면 반짝임을 추가로 표시합니다. 게임의 기본 전리품 반짝임이 대부분을 표시하므로 기본값은 꺼짐입니다.",
	["Sparkles on a corpse that still holds loot for you, bosses included. Only after the fight: the game doesn't let addons switch the nameplate it hangs on during combat."] = "전리품을 획득할 수 있는 시체(우두머리 포함)에 반짝임을 표시합니다. 전투 중에는 애드온이 해당 이름표를 바꿀 수 없어 전투가 끝난 뒤 표시합니다.",
	[" Uses Blizzard's soft targeting: the nearest object within about 15 yards sparkles, brighter once you can reach it. Needs the game's Enable Interact Key setting and its interact icons on objects; switching this on turns both on, and with them off nothing sparkles."] = " 게임의 자동 대상 지정을 사용합니다. 약 15미터 안에서 가장 가까운 물체가 반짝이고, 상호작용 범위에 들어오면 더 밝아집니다. 이 기능을 켜면 게임의 상호작용 키와 물체의 상호작용 아이콘도 켜집니다. 두 설정이 켜져 있어야 반짝임이 표시됩니다.",
};

local texts = GetLocale() == "koKR" and koKR or nil;
function ns.Text(english)
	return texts and texts[english] or english;
end
