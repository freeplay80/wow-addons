local _, ns = ...;

local koKR = {
	["Show quest item sparkles"] = "퀘스트 아이템 반짝임 표시",
	["Keeps the game's loot sparkle on, even after a graphics preset turns it off. Your outline mode is left as you set it. Switching this off takes effect after restarting the game."] = "그래픽 프리셋을 바꿔도 전리품 반짝임을 유지합니다. 게임의 윤곽선 설정은 유지됩니다. 이 옵션을 끄면 게임을 다시 시작한 뒤 적용됩니다.",
	["|cffff8000Forever Loot Sparkles:|r restart the game to remove the sparkles. /reload is not enough."] = "|cffff8000Forever Loot Sparkles:|r 반짝임을 끄려면 게임을 완전히 종료한 뒤 다시 실행하세요.",
};

local texts = GetLocale() == "koKR" and koKR or nil;
function ns.Text(english)
	return texts and texts[english] or english;
end
