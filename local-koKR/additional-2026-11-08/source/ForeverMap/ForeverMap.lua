local isAdmin = false 
local isVisible = true

-- [제작자 캐릭터 설정: "설쁘"]
local DEVELOPER_NAME = "설쁘"

-- [관리자 권한 체크 함수 ("설쁘"만 허용)]
local function CheckAdminPermission()
    local playerName = UnitName("player")
    if playerName == DEVELOPER_NAME then
        return true
    end
    return false
end

-- [★ 한국 클라이언트에서 한글 출력을 위해 false로 설정]
local FORCE_ENGLISH_FOR_SCREENSHOT = false

local function IsEnglishMode()
    if FORCE_ENGLISH_FOR_SCREENSHOT then
        return true
    end
    return GetLocale() ~= "koKR"
end

-- [다국어(Localization) 및 텍스트 설정]
local L = {
    TITLE = "FOREVER MAP", ADD = "Add", DELETE = "Delete", EXPORT = "Export", IMPORT = "IMPORT", APPLY = "Apply", CLOSE = "Close",
    AUTHOR = "By 설쁘",
    ADMIN_ON = "|cff00ff00Admin mode enabled.|r",
    ADMIN_OFF = "|cffff0000Admin mode disabled.|r",
    SHAPE_PIN = "Shape Pin",
    MAP_HIDE = "Hide Map Notes",
    MAP_SHOW = "Show Map Notes",
    MAP_ON = "|cff00ff00Map notes enabled|r",
    MAP_OFF = "|cffff0000Map notes disabled|r",
    NO_ADMIN = "|cffff0000[ForeverMap] Only the author (설쁘) can use this command.|r",
    HIDE_BTN = "[Hide]",
    SHOW_BTN = "[Show]",
    LOADED = "Loaded",
    SIZE = "Size: ",
    NEXT_COMPACT = "|cffff0000[ForeverMap] Will display in compact mode on next login.|r",
    NEXT_FULL = "|cff00ff00[ForeverMap] Developer info will be displayed on next login.|r",
    WAYPOINT_ADDED = "|cff00ff00[ForeverMap]|r Waypoint set.",
    WAYPOINT_CLEARED = "|cffff0000[ForeverMap]|r Waypoint cleared.",
}

if not IsEnglishMode() then
    L.ADD = "추가"
    L.DELETE = "삭제"
    L.EXPORT = "내보내기"
    L.IMPORT = "가져오기"
    L.APPLY = "데이터 적용"
    L.CLOSE = "닫기"
    L.ADMIN_ON = "|cff00ff00관리자 모드가 활성화되었습니다.|r"
    L.ADMIN_OFF = "|cffff0000관리자 모드가 비활성화되었습니다.|r"
    L.SHAPE_PIN = "도형 핀"
    L.MAP_HIDE = "지도 숨기기"
    L.MAP_SHOW = "지도 보이기"
    L.MAP_ON = "|cff00ff00맵 메모 켜짐|r"
    L.MAP_OFF = "|cffff0000맵 메모 꺼짐|r"
    L.NO_ADMIN = "|cffff0000[ForeverMap] 제작자(설쁘)만 사용할 수 있습니다.|r"
    L.HIDE_BTN = "[숨기기]"
    L.SHOW_BTN = "[다시 표시]"
    L.LOADED = "로드 완료"
    L.SIZE = "크기: "
    L.NEXT_COMPACT = "|cffff0000[ForeverMap] 다음 로그인부터 축약 형태로 표시됩니다.|r"
    L.NEXT_FULL = "|cff00ff00[ForeverMap] 다음 로그인부터 제작자 정보가 다시 표시됩니다.|r"
    L.WAYPOINT_ADDED = "|cff00ff00[ForeverMap]|r 길안내 핀을 설정했습니다."
    L.WAYPOINT_CLEARED = "|cffff0000[ForeverMap]|r 길안내 핀을 삭제했습니다."
end

-- [글로벌 전용 초단축 영문 약어 변환 테이블]
local ABBREVIATIONS = {
    ["경매장"] = "AH",
    ["은행"] = "BNK",
    ["여관"] = "INN",
    ["여관/요리"] = "INN/CK",
    ["와이번"] = "FP",
    ["미용실"] = "BAR",
    ["미용"] = "BAR",
    ["야수 관리인"] = "PET",
    ["야수"] = "PET",
    ["가죽/무두"] = "LW/SK",
    ["가세/무두\n재봉"] = "LW/SK\nTAI",
    ["가세/무두"] = "LW/SK",
    ["채광"] = "MIN",
    ["기공"] = "ENG",
    ["대장"] = "BS",
    ["연금"] = "ALC",
    ["마부"] = "ENC",
    ["약초"] = "HER",
    ["재봉"] = "TAI",
    ["요리"] = "CK",
    ["낚시"] = "FSH",
    ["응급"] = "FA",
    ["장교 막사"] = "PVP",
    ["사냥꾼"] = "HUN",
    ["전사"] = "WAR",
    ["사냥꾼/전사"] = "HUN/WAR",
    ["전투모병/전사"] = "WAR",
    ["흑마법사"] = "WLK",
    ["마법사"] = "MAG",
    ["사제"] = "PRI",
    ["주술사"] = "SHA",
    ["도적"] = "ROG",
    ["드루"] = "DRU",
    ["성기사"] = "PAL",
    ["마법사/흑마법사"] = "MAG/WLK",
    ["전사/사제/성기사"] = "WAR/PRI/PAL",
    ["마법사/사제/주술사"] = "MAG/PRI/SHA",
    ["상급 사냥꾼"] = "HUN",
    ["전투모병/상급 전사"] = "WAR",
    ["상급 흑마법사"] = "WLK",
    ["상급 마법사"] = "MAG",
    ["상급 사제"] = "PRI",
    ["상급 주술사"] = "SHA",
    ["상급 도적"] = "ROG",
    ["무기 전문가"] = "WEAPON",
}

local function GetLocalizedText(str)
    if not str or str == "" then return "" end
    if not IsEnglishMode() then return str end
    
    local cleanStr = str:gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
    return ABBREVIATIONS[cleanStr] or ABBREVIATIONS[str] or cleanStr
end

local function GetLocalizedTooltip(koTip, enTip)
    if not IsEnglishMode() then
        return koTip
    else
        return enTip
    end
end

local function GetGlobalFont()
    if not IsEnglishMode() then
        return "Fonts\\2002.TTF"
    else
        return "Fonts\\FRIZQT__.TTF"
    end
end

-- [통합 DB V49로 일원화]
MyMapNotesDB_V49 = MyMapNotesDB_V49 or {
    [1] = {["y"] = 0.68354235437816, ["mapID"] = 1454, ["x"] = 0.57349427283773, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "여관\n", ["textSize"] = 20, ["shape"] = "DOT"},
    [2] = {["y"] = 0.68558726053752, ["mapID"] = 1454, ["x"] = 0.54144412109959, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [3] = {["y"] = 0.63475657937056, ["mapID"] = 1454, ["x"] = 0.59150156160448, ["color"] = {[1]=0,[2]=0.8,[3]=1}, ["text"] = "경매장", ["textSize"] = 20, ["shape"] = "DOT"},
    [4] = {["y"] = 0.63676777000199, ["mapID"] = 1454, ["x"] = 0.54693048918456, ["color"] = {[1]=0,[2]=0.8,[3]=1}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [5] = {["y"] = 0.69408937557015, ["mapID"] = 1454, ["x"] = 0.49463554612969, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [6] = {["y"] = 0.72927513807834, ["mapID"] = 1454, ["x"] = 0.49435240956975, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "은행", ["textSize"] = 20, ["shape"] = "DOT"},
    [7] = {["y"] = 0.44770685070289, ["mapID"] = 1454, ["x"] = 0.62470085467482, ["color"] = {[1]=1,[2]=0.5,[3]=0}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [8] = {["y"] = 0.44644073669068, ["mapID"] = 1454, ["x"] = 0.68101502265763, ["color"] = {[1]=1,[2]=0.5,[3]=0}, ["text"] = "가죽/무두", ["textSize"] = 20, ["shape"] = "DOT"},
    [9] = {["y"] = 0.26295973726375, ["mapID"] = 1454, ["x"] = 0.72456535144035, ["color"] = {[1]=1,[2]=1,[3]=0}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [10] = {["y"] = 0.26236638052021, ["mapID"] = 1454, ["x"] = 0.69279115229678, ["color"] = {[1]=1,[2]=1,[3]=0}, ["text"] = "채광", ["textSize"] = 20, ["shape"] = "DOT"},
    [11] = {["y"] = 0.21418150028069, ["mapID"] = 1454, ["x"] = 0.75194442950376, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "기공", ["textSize"] = 20, ["shape"] = "DOT"},
    [12] = {["y"] = 0.24868582537074, ["mapID"] = 1454, ["x"] = 0.75219295587335, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [13] = {["y"] = 0.22897973888648, ["mapID"] = 1454, ["x"] = 0.81890184968796, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [14] = {["y"] = 0.26458950385362, ["mapID"] = 1454, ["x"] = 0.82162955603505, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "대장", ["textSize"] = 20, ["shape"] = "DOT"},
    [15] = {["y"] = 0.29688811159419, ["mapID"] = 1454, ["x"] = 0.69770839194972, ["color"] = {[1]=0,[2]=0.8,[3]=1}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [16] = {["y"] = 0.32783289012795, ["mapID"] = 1454, ["x"] = 0.69881174547805, ["color"] = {[1]=0,[2]=0.8,[3]=1}, ["text"] = "낚시", ["textSize"] = 20, ["shape"] = "DOT"},
    [17] = {["y"] = 0.11018097472048, ["mapID"] = 1454, ["x"] = 0.70577703200916, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "야수 관리인", ["textSize"] = 20, ["shape"] = "DOT"},
    [18] = {["y"] = 0.1492123175524, ["mapID"] = 1454, ["x"] = 0.70229539671933, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [19] = {["y"] = 0.15158163287682, ["mapID"] = 1454, ["x"] = 0.66476054529975, ["color"] = {[1]=0,[2]=1,[3]=0}, ["text"] = "사냥꾼", ["textSize"] = 20, ["shape"] = "DOT"},
    [20] = {["y"] = 0.18465085515005, ["mapID"] = 1454, ["x"] = 0.66699029282193, ["color"] = {[1]=0,[2]=1,[3]=0}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [21] = {["y"] = 0.30416130020233, ["mapID"] = 1454, ["x"] = 0.79268259180598, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [22] = {["y"] = 0.34675168705558, ["mapID"] = 1454, ["x"] = 0.79804396955333, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "전투모병/전사", ["textSize"] = 20, ["shape"] = "DOT"},
    [23] = {["y"] = 0.33344675395303, ["mapID"] = 1454, ["x"] = 0.55747498468639, ["color"] = {[1]=0,[2]=1,[3]=0}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [24] = {["y"] = 0.2997852256912, ["mapID"] = 1454, ["x"] = 0.55972950870387, ["color"] = {[1]=0,[2]=1,[3]=0}, ["text"] = "연금", ["textSize"] = 20, ["shape"] = "DOT"},
    [25] = {["y"] = 0.37876056054395, ["mapID"] = 1454, ["x"] = 0.50023432214341, ["color"] = {[1]=0,[2]=0.8,[3]=1}, ["text"] = "마부", ["textSize"] = 20, ["shape"] = "DOT"},
    [26] = {["y"] = 0.37840810079061, ["mapID"] = 1454, ["x"] = 0.53169411334837, ["color"] = {[1]=0,[2]=0.8,[3]=1}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [27] = {["y"] = 0.46313928843972, ["mapID"] = 1454, ["x"] = 0.48204196075111, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [28] = {["y"] = 0.42586978752456, ["mapID"] = 1454, ["x"] = 0.48706164410305, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "흑마법사", ["textSize"] = 20, ["shape"] = "DOT"},
    [29] = {["y"] = 0.53947311675477, ["mapID"] = 1454, ["x"] = 0.46334430971161, ["color"] = {[1]=0,[2]=0.8,[3]=1}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [30] = {["y"] = 0.57374650418401, ["mapID"] = 1454, ["x"] = 0.46350184680067, ["color"] = {[1]=0,[2]=0.8,[3]=1}, ["text"] = "미용실", ["textSize"] = 20, ["shape"] = "DOT"},
    [31] = {["y"] = 0.39669292701219, ["mapID"] = 1454, ["x"] = 0.54936820702245, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [32] = {["y"] = 0.42855318720469, ["mapID"] = 1454, ["x"] = 0.55067810922478, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "약초", ["textSize"] = 20, ["shape"] = "DOT", ["tooltip"] = GetLocalizedTooltip("위층", "Upper Floor")},
    [33] = {["y"] = 0.53199772634906, ["mapID"] = 1454, ["x"] = 0.57374728315096, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [34] = {["y"] = 0.4940201079774, ["mapID"] = 1454, ["x"] = 0.57595269279235, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "요리", ["textSize"] = 20, ["shape"] = "DOT", ["tooltip"] = GetLocalizedTooltip("위층", "Upper Floor")},
    [35] = {["y"] = 0.84100561084862, ["mapID"] = 1454, ["x"] = 0.33361215900644, ["color"] = {[1]=0,[2]=0.8,[3]=1}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [36] = {["y"] = 0.83846260116486, ["mapID"] = 1454, ["x"] = 0.30174719520022, ["color"] = {[1]=0,[2]=0.8,[3]=1}, ["text"] = "응급", ["textSize"] = 20, ["shape"] = "DOT"},
    [37] = {["y"] = 0.5, ["mapID"] = 1454, ["x"] = 0.62450048788528, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [38] = {["y"] = 0.53828507840276, ["mapID"] = 1454, ["x"] = 0.62197197953507, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "재봉", ["textSize"] = 20, ["shape"] = "DOT"},
    [39] = {["y"] = 0.84713279130216, ["mapID"] = 1454, ["x"] = 0.38195999468592, ["color"] = {[1]=0,[2]=0.8,[3]=1}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [40] = {["y"] = 0.80991559970879, ["mapID"] = 1454, ["x"] = 0.38691797393263, ["color"] = {[1]=0,[2]=0.8,[3]=1}, ["text"] = "마법사", ["textSize"] = 20, ["shape"] = "DOT"},
    [41] = {["y"] = 0.86585313260198, ["mapID"] = 1454, ["x"] = 0.35652715829771, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [42] = {["y"] = 0.89957384577768, ["mapID"] = 1454, ["x"] = 0.35476237742031, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "사제", ["textSize"] = 20, ["shape"] = "DOT"},
    [43] = {["y"] = 0.37200868343879, ["mapID"] = 1454, ["x"] = 0.42381533022728, ["color"] = {[1]=0,[2]=0.4,[3]=1}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [44] = {["y"] = 0.33577449593002, ["mapID"] = 1454, ["x"] = 0.4266525587343, ["color"] = {[1]=0,[2]=0.4,[3]=1}, ["text"] = "주술사", ["textSize"] = 20, ["shape"] = "DOT"},
    [45] = {["y"] = 0.53130290322675, ["mapID"] = 1454, ["x"] = 0.43217651414843, ["color"] = {[1]=1,[2]=1,[3]=0}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [46] = {["y"] = 0.49441094312839, ["mapID"] = 1454, ["x"] = 0.43446821377609, ["color"] = {[1]=1,[2]=1,[3]=0}, ["text"] = "도적", ["textSize"] = 20, ["shape"] = "DOT"},
    [47] = {["y"] = 0.69015840998667, ["mapID"] = 1454, ["x"] = 0.400044986014, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [48] = {["y"] = 0.72778535031987, ["mapID"] = 1454, ["x"] = 0.39994191305244, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "장교 막사", ["textSize"] = 20, ["shape"] = "DOT"},
    [49] = {["y"] = 0.64261851053752, ["mapID"] = 1454, ["x"] = 0.46099430405581, ["color"] = {[1]=0,[2]=1,[3]=0}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [50] = {["y"] = 0.61061891110357, ["mapID"] = 1454, ["x"] = 0.46380909742349, ["color"] = {[1]=0,[2]=1,[3]=0}, ["text"] = "와이번", ["textSize"] = 20, ["shape"] = "DOT"},

    -- [썬더블러프 51~86]
    [51] = {["y"] = 0.56609933818886, ["mapID"] = 1456, ["x"] = 0.39546932164301, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [52] = {["y"] = 0.53284710181687, ["mapID"] = 1456, ["x"] = 0.39801339755345, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "대장", ["textSize"] = 20, ["shape"] = "DOT"},
    [53] = {["y"] = 0.60173482380941, ["mapID"] = 1456, ["x"] = 0.44652388990039, ["color"] = {[1]=0,[2]=1,[3]=0}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [54] = {["y"] = 0.6367106180705, ["mapID"] = 1456, ["x"] = 0.45277770552781, ["color"] = {[1]=0,[2]=1,[3]=0}, ["text"] = "야수 \n", ["textSize"] = 20, ["shape"] = "DOT"},
    [55] = {["y"] = 0.58319475550851, ["mapID"] = 1456, ["x"] = 0.47074573565602, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [56] = {["y"] = 0.58045196533203, ["mapID"] = 1456, ["x"] = 0.49939072968621, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "은행", ["textSize"] = 20, ["shape"] = "DOT"},
    [57] = {["y"] = 0.53474047084055, ["mapID"] = 1456, ["x"] = 0.51584764015032, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [58] = {["y"] = 0.53092051980024, ["mapID"] = 1456, ["x"] = 0.58024377391191, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "여관/요리", ["textSize"] = 20, ["shape"] = "DOT"},
    [59] = {["y"] = 0.50182863338265, ["mapID"] = 1456, ["x"] = 0.39638889966716, ["color"] = {[1]=0,[2]=0.8,[3]=1}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [60] = {["y"] = 0.46941713801401, ["mapID"] = 1456, ["x"] = 0.39915640525855, ["color"] = {[1]=0,[2]=0.8,[3]=1}, ["text"] = "경매장", ["textSize"] = 20, ["shape"] = "DOT"},
    [61] = {["y"] = 0.29248914889947, ["mapID"] = 1456, ["x"] = 0.76903654007457, ["color"] = {[1]=1,[2]=0.5,[3]=0}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [62] = {["y"] = 0.25955922018268, ["mapID"] = 1456, ["x"] = 0.77121869892799, ["color"] = {[1]=1,[2]=0.5,[3]=0}, ["text"] = "드루", ["textSize"] = 20, ["shape"] = "DOT"},
    [63] = {["y"] = 0.81449307653005, ["mapID"] = 1456, ["x"] = 0.60361148474675, ["color"] = {[1]=0,[2]=1,[3]=0}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [64] = {["y"] = 0.78249455069353, ["mapID"] = 1456, ["x"] = 0.60300302142334, ["color"] = {[1]=0,[2]=1,[3]=0}, ["text"] = "사냥꾼/전사", ["textSize"] = 20, ["shape"] = "DOT"},
    [65] = {["y"] = 0.21202000600849, ["mapID"] = 1456, ["x"] = 0.23426607269677, ["color"] = {[1]=0,[2]=0.8,[3]=1}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [66] = {["y"] = 0.18093575117831, ["mapID"] = 1456, ["x"] = 0.24097080247642, ["shape"] = "DOT", ["color"] = {[1]=0,[2]=0.8,[3]=1}, ["text"] = "마법사/사제/주술사", ["textSize"] = 20, ["tooltip"] = GetLocalizedTooltip("마법사/사제는 동굴 아래 있음", "Mages & Priests are in the lower cave")},
    [67] = {["y"] = 0.14206106220177, ["mapID"] = 1456, ["x"] = 0.25248049722817, ["color"] = {[1]=1,[2]=0.4,[3]=0.7}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [68] = {["y"] = 0.10760114292899, ["mapID"] = 1456, ["x"] = 0.25099890240278, ["shape"] = "DOT", ["color"] = {[1]=1,[2]=0.4,[3]=0.7}, ["text"] = "성기사", ["textSize"] = 20, ["tooltip"] = GetLocalizedTooltip("성기사는 동굴 아래 있음", "Paladin is in the lower cave")},
    [69] = {["y"] = 0.33565900425711, ["mapID"] = 1456, ["x"] = 0.46739291590246, ["color"] = {[1]=0,[2]=1,[3]=0}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [70] = {["y"] = 0.30262093915197, ["mapID"] = 1456, ["x"] = 0.47000143572709, ["color"] = {[1]=0,[2]=1,[3]=0}, ["text"] = "연금", ["textSize"] = 20, ["shape"] = "DOT"},
    [71] = {["y"] = 0.37674379634286, ["mapID"] = 1456, ["x"] = 0.4465240389263, ["color"] = {[1]=0,[2]=0.8,[3]=1}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [72] = {["y"] = 0.40804697367959, ["mapID"] = 1456, ["x"] = 0.4465240389263, ["color"] = {[1]=0,[2]=0.8,[3]=1}, ["text"] = "마부", ["textSize"] = 20, ["shape"] = "DOT"},
    [73] = {["y"] = 0.21431608828242, ["mapID"] = 1456, ["x"] = 0.30287329985578, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [74] = {["y"] = 0.2499315638742, ["mapID"] = 1456, ["x"] = 0.3047416943005, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "응급", ["textSize"] = 20, ["shape"] = "DOT"},
    [75] = {["y"] = 0.46099926611621, ["mapID"] = 1456, ["x"] = 0.561741027435, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [76] = {["y"] = 0.4302261718019, ["mapID"] = 1456, ["x"] = 0.56094851484184, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "낚시", ["textSize"] = 20, ["shape"] = "DOT"},
    [77] = {["y"] = 0.40609083346978, ["mapID"] = 1456, ["x"] = 0.49608726296874, ["color"] = {[1]=0,[2]=1,[3]=0}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [78] = {["y"] = 0.37382425091224, ["mapID"] = 1456, ["x"] = 0.49810964630129, ["color"] = {[1]=0,[2]=1,[3]=0}, ["text"] = "약초", ["textSize"] = 20, ["shape"] = "DOT"},
    [79] = {["y"] = 0.43892349882754, ["mapID"] = 1456, ["x"] = 0.43058853419939, ["color"] = {[1]=1,[2]=0.5,[3]=0}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [80] = {["y"] = 0.4567594242667, ["mapID"] = 1456, ["x"] = 0.49240127579306, ["color"] = {[1]=1,[2]=0.5,[3]=0}, ["text"] = "가세/무두\n재봉", ["textSize"] = 20, ["shape"] = "DOT"},
    [81] = {["y"] = 0.57043192058266, ["mapID"] = 1456, ["x"] = 0.34478928222722, ["color"] = {[1]=1,[2]=1,[3]=0}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [82] = {["y"] = 0.57229924915793, ["mapID"] = 1456, ["x"] = 0.31218198675391, ["color"] = {[1]=1,[2]=1,[3]=0}, ["text"] = "채광", ["textSize"] = 20, ["shape"] = "DOT"},
    [83] = {["y"] = 0.53130290322675, ["mapID"] = 1456, ["x"] = 0.3473974106715, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [84] = {["y"] = 0.4941308484106, ["mapID"] = 1456, ["x"] = 0.35131090654927, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "미용", ["textSize"] = 20, ["shape"] = "DOT"},
    [85] = {["y"] = 0.49908570615117, ["mapID"] = 1456, ["x"] = 0.46586931311563, ["color"] = {[1]=0,[2]=1,[3]=0}, ["text"] = "", ["textSize"] = 20, ["shape"] = "DOT"},
    [86] = {["y"] = 0.53199800045904, ["mapID"] = 1456, ["x"] = 0.4695258798231, ["color"] = {[1]=0,[2]=1,[3]=0}, ["text"] = "와이번", ["textSize"] = 20, ["shape"] = "DOT"},

    -- [언더시티 87~124]
    [87] = {["y"] = 0.44108444487977, ["mapID"] = 1458, ["x"] = 0.66600098046089, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "", ["shape"] = "DOT", ["textSize"] = 20},
    [88] = {["y"] = 0.4080468823096, ["mapID"] = 1458, ["x"] = 0.66825311363034, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "은행", ["shape"] = "DOT", ["textSize"] = 20},
    [89] = {["y"] = 0.48434704078172, ["mapID"] = 1458, ["x"] = 0.62651700831022, ["color"] = {[1]=0,[2]=1,[3]=0}, ["text"] = "", ["shape"] = "DOT", ["textSize"] = 20},
    [90] = {["y"] = 0.51284844861059, ["mapID"] = 1458, ["color"] = {[1]=0,[2]=1,[3]=0}, ["text"] = "와이번", ["textSize"] = 20, ["x"] = 0.62684277277703},
    [91] = {["y"] = 0.36891804769368, ["mapID"] = 1458, ["x"] = 0.67999196431405, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "", ["shape"] = "DOT", ["textSize"] = 20},
    [92] = {["y"] = 0.33370268130731, ["mapID"] = 1458, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "여관", ["textSize"] = 20, ["x"] = 0.68129684958106},
    [93] = {["y"] = 0.35646696718867, ["mapID"] = 1458, ["x"] = 0.65846527108958, ["color"] = {[1]=0,[2]=0.8,[3]=1}, ["text"] = "", ["shape"] = "DOT", ["textSize"] = 20},
    [94] = {["y"] = 0.35372435975218, ["mapID"] = 1458, ["color"] = {[1]=0,[2]=0.8,[3]=1}, ["text"] = "경매장", ["textSize"] = 20, ["x"] = 0.6188489495101},
    [95] = {["y"] = 0.14979781647642, ["mapID"] = 1458, ["x"] = 0.85346263932933, ["color"] = {[1]=0,[2]=0.8,[3]=1}, ["text"] = "", ["shape"] = "DOT", ["textSize"] = 20},
    [96] = {["y"] = 0.11653776796992, ["mapID"] = 1458, ["color"] = {[1]=0,[2]=0.8,[3]=1}, ["text"] = "마법사/흑마법사", ["textSize"] = 20, ["x"] = 0.85607253169001},
    [97] = {["y"] = 0.18305676854299, ["mapID"] = 1458, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "", ["textSize"] = 20, ["x"] = 0.48956582138666},
    [98] = {["y"] = 0.14758524637736, ["mapID"] = 1458, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "전사/사제/성기사", ["textSize"] = 20, ["x"] = 0.48956569194584},
    [99] = {["y"] = 0.7171630859375, ["mapID"] = 1458, ["x"] = 0.84041999981848, ["color"] = {[1]=1,[2]=1,[3]=0}, ["text"] = "", ["shape"] = "DOT", ["textSize"] = 20},
    [100] = {["y"] = 0.67999039153139, ["mapID"] = 1458, ["x"] = 0.83911596733803, ["color"] = {[1]=1,[2]=1,[3]=0}, ["text"] = "도적", ["shape"] = "DOT", ["textSize"] = 20},
    [101] = {["y"] = 0.71716290319751, ["mapID"] = 1458, ["x"] = 0.47260974434129, ["color"] = {[1]=0,[2]=1,[3]=0}, ["text"] = "", ["shape"] = "DOT", ["textSize"] = 20},
    [102] = {["y"] = 0.68143289531776, ["mapID"] = 1458, ["x"] = 0.47738805973331, ["color"] = {[1]=0,[2]=1,[3]=0}, ["text"] = "연금", ["shape"] = "DOT", ["textSize"] = 20},
    [103] = {["y"] = 0.24240783874146, ["mapID"] = 1458, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "대장", ["textSize"] = 20, ["x"] = 0.61137764587739},
    [104] = {["y"] = 0.27892198391303, ["mapID"] = 1458, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "", ["textSize"] = 20, ["x"] = 0.61347388149276},
    [105] = {["y"] = 0.43596745108416, ["mapID"] = 1458, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "요리", ["textSize"] = 20, ["x"] = 0.59417749162457},
    [106] = {["y"] = 0.43739401080651, ["mapID"] = 1458, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "", ["textSize"] = 20, ["x"] = 0.62390796873611},
    [107] = {["y"] = 0.64477520788501, ["mapID"] = 1458, ["color"] = {[1]=0,[2]=0.8,[3]=1}, ["text"] = "마부", ["textSize"] = 20, ["x"] = 0.61608255558691},
    [108] = {["y"] = 0.60760324443886, ["mapID"] = 1458, ["color"] = {[1]=0,[2]=0.8,[3]=1}, ["text"] = "", ["textSize"] = 20, ["x"] = 0.61999526216151},
    [109] = {["y"] = 0.7289013891163, ["mapID"] = 1458, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "", ["textSize"] = 20, ["x"] = 0.75824950695231},
    [110] = {["y"] = 0.69421784178226, ["mapID"] = 1458, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "기공", ["textSize"] = 20, ["x"] = 0.75993958072878},
    [111] = {["y"] = 0.52177790110697, ["mapID"] = 1458, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "", ["textSize"] = 20, ["x"] = 0.68720935201245},
    [112] = {["y"] = 0.55673674623409, ["mapID"] = 1458, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "응급", ["textSize"] = 20, ["x"] = 0.68912226273026},
    [113] = {["y"] = 0.26914027779402, ["mapID"] = 1458, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "낚시", ["textSize"] = 20, ["x"] = 0.82085561415891},
    [114] = {["y"] = 0.30826865555997, ["mapID"] = 1458, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "", ["textSize"] = 20, ["x"] = 0.81694290758431},
    [115] = {["y"] = 0.49816720928261, ["mapID"] = 1458, ["x"] = 0.51211678741414, ["color"] = {[1]=0,[2]=1,[3]=0}, ["text"] = "약초", ["shape"] = "DOT", ["textSize"] = 20},
    [116] = {["y"] = 0.50000018273999, ["mapID"] = 1458, ["x"] = 0.5430417520037, ["color"] = {[1]=0,[2]=1,[3]=0}, ["text"] = "", ["shape"] = "DOT", ["textSize"] = 20},
    [117] = {["y"] = 0.62748416740737, ["mapID"] = 1458, ["x"] = 0.70483337418587, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "가세/무두", ["shape"] = "DOT", ["textSize"] = 20},
    [118] = {["y"] = 0.59390715639034, ["mapID"] = 1458, ["x"] = 0.70477503825509, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "", ["shape"] = "DOT", ["textSize"] = 20},
    [119] = {["y"] = 0.39880338189619, ["mapID"] = 1458, ["x"] = 0.56148274365071, ["color"] = {[1]=1,[2]=1,[3]=0}, ["text"] = "채광", ["shape"] = "DOT", ["textSize"] = 20},
    [120] = {["y"] = 0.36604724815506, ["mapID"] = 1458, ["x"] = 0.55920599388345, ["color"] = {[1]=1,[2]=1,[3]=0}, ["text"] = "", ["shape"] = "DOT", ["textSize"] = 20},
    [121] = {["y"] = 0.25412782223639, ["mapID"] = 1458, ["x"] = 0.71033286147841, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "재봉", ["shape"] = "DOT", ["textSize"] = 20},
    [122] = {["y"] = 0.29444574595925, ["mapID"] = 1458, ["x"] = 0.70955252392585, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "", ["shape"] = "DOT", ["textSize"] = 20},
    [123] = {["y"] = 0.4705436386748, ["mapID"] = 1458, ["x"] = 0.71146604788056, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "", ["shape"] = "DOT", ["textSize"] = 20},
    [124] = {["y"] = 0.43518107522747, ["mapID"] = 1458, ["x"] = 0.71329397246194, ["color"] = {[1]=1,[2]=1,[3]=1}, ["text"] = "미용", ["shape"] = "DOT", ["textSize"] = 20},
    [125] = {["y"] = 0.31805273729884, ["mapID"] = 1458, ["x"] = 0.56912788381197, ["color"] = {[1]=1,[2]=0,[3]=0}, ["text"] = "", ["shape"] = "DOT", ["textSize"] = 20},
    [126] = {["y"] = 0.31805191496889, ["mapID"] = 1458, ["x"] = 0.50521810960488, ["color"] = {[1]=1,[2]=0,[3]=0}, ["text"] = "무기 전문가", ["shape"] = "DOT", ["textSize"] = 20, ["tooltip"] = GetLocalizedTooltip("단검류, 한손 도검류, 양손 도검류, 장창류, 석궁류", "Daggers, One-Handed Swords, Two-Handed Swords, Polearms, Crossbows")},
    [127] = {["y"] = 0.62325501584721, ["mapID"] = 1456, ["x"] = 0.41000345439471, ["color"] = {[1]=1,[2]=0,[3]=0}, ["text"] = "", ["shape"] = "DOT", ["textSize"] = 20},
    [128] = {["y"] = 0.6225049595633, ["mapID"] = 1456, ["x"] = 0.34554539934137, ["color"] = {[1]=1,[2]=0,[3]=0}, ["text"] = "무기 전문가", ["shape"] = "DOT", ["textSize"] = 20, ["tooltip"] = GetLocalizedTooltip("한손·양손 둔기류, 지팡이류, 총기류", "One-Handed & Two-Handed Maces, Staves, Guns")},
    [129] = {["y"] = 0.19279448000971, ["mapID"] = 1454, ["x"] = 0.81415621048819, ["color"] = {[1]=1,[2]=0,[3]=0}, ["text"] = "", ["shape"] = "DOT", ["textSize"] = 20},
    [130] = {["y"] = 0.15566715080581, ["mapID"] = 1454, ["x"] = 0.82216031668594, ["color"] = {[1]=1,[2]=0,[3]=0}, ["text"] = "무기 전문가", ["shape"] = "DOT", ["textSize"] = 20, ["tooltip"] = GetLocalizedTooltip("단검류, 한손·양손 도끼류, 장착 무기류, 투척 무기류, 활류", "Daggers, One-Handed & Two-Handed Axes, Fist Weapons, Thrown, Bows")},
}

local colorPalette = {
    {r = 1, g = 0, b = 0}, {r = 0, g = 0.4, b = 1}, {r = 0, g = 1, b = 0},
    {r = 1, g = 1, b = 0}, {r = 0, g = 0.8, b = 1}, {r = 1, g = 1, b = 1},
    {r = 1, g = 0.4, b = 0.7}, {r = 1, g = 0.5, b = 0}, {r = 0.6, g = 0.2, b = 1} 
}
local pinPool, rowPool = {}, {}
local activePins, activeRows = {}, {}
local rowMap = {} 

local lastTomTomWaypoint = nil

local function SetWaypoint(mapID, x, y)
    if TomTom then
        if lastTomTomWaypoint then TomTom:RemoveWaypoint(lastTomTomWaypoint) end
        lastTomTomWaypoint = TomTom:AddWaypoint(mapID, x, y, { persistent = false, minimap = true, world = true })
        print(L.WAYPOINT_ADDED)
    elseif C_Map and C_Map.SetUserWaypoint then
        local point = UiMapPoint.CreateFromCoordinates(mapID, x, y)
        C_Map.SetUserWaypoint(point)
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
            C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        end
        print(L.WAYPOINT_ADDED)
    end
end

local function ClearWaypoint()
    if TomTom and lastTomTomWaypoint then
        TomTom:RemoveWaypoint(lastTomTomWaypoint)
        lastTomTomWaypoint = nil
        print(L.WAYPOINT_CLEARED)
    elseif C_Map and C_Map.ClearUserWaypoint then
        C_Map.ClearUserWaypoint()
        print(L.WAYPOINT_CLEARED)
    end
end

local function ApplyStyle(f)
    f:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    f:SetBackdropColor(0.05, 0.05, 0.05, 0.9); f:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
end

local MapToggleButton = CreateFrame("Button", nil, WorldMapFrame, "UIPanelButtonTemplate")
MapToggleButton:SetSize(110, 30)
MapToggleButton:SetPoint("TOPRIGHT", WorldMapFrame:GetCanvasContainer(), "TOPRIGHT", -50, -5)
MapToggleButton:SetFrameStrata("FULLSCREEN_DIALOG")
MapToggleButton:SetText(L.MAP_HIDE)
MapToggleButton:SetScript("OnClick", function()
    isVisible = not isVisible
    RefreshEverything()
    MapToggleButton:SetText(isVisible and L.MAP_HIDE or L.MAP_SHOW)
end)

local function GetPin()
    local canvas = WorldMapFrame:GetCanvas()
    if not canvas then return nil end
    local pin = table.remove(pinPool)
    if not pin then
        pin = CreateFrame("Frame", nil, canvas)
        pin:SetFrameStrata("HIGH"); pin:SetFrameLevel(5000)
        pin:EnableMouse(true); pin:SetMovable(true)
        pin.text = pin:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        pin.text:SetJustifyH("CENTER")
        pin.text:SetPoint("CENTER", pin, "CENTER", 0, 0)
        pin:RegisterForDrag("LeftButton")
    end
    pin:SetParent(canvas); table.insert(activePins, pin); return pin
end

local function GetRow(parent)
    local row = table.remove(rowPool)
    if not row then
        row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        row:SetSize(265, 120); ApplyStyle(row)
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); row.name:SetPoint("TOPLEFT", 10, -8)
        row.del = CreateFrame("Button", nil, row, "BackdropTemplate"); row.del:SetSize(40, 18); row.del:SetPoint("TOPRIGHT", -5, -5); ApplyStyle(row.del); row.del.t = row.del:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); row.del.t:SetPoint("CENTER"); row.del.t:SetText(L.DELETE)
        row.sizeTxt = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); row.sizeTxt:SetPoint("TOPRIGHT", -55, -25)
        row.mBtn = CreateFrame("Button", nil, row, "BackdropTemplate"); row.mBtn:SetSize(18, 18); row.mBtn:SetPoint("TOPRIGHT", -30, -23); ApplyStyle(row.mBtn); row.mBtn.t = row.mBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal"); row.mBtn.t:SetPoint("CENTER"); row.mBtn.t:SetText("-")
        row.pBtn = CreateFrame("Button", nil, row, "BackdropTemplate"); row.pBtn:SetSize(18, 18); row.pBtn:SetPoint("TOPRIGHT", -10, -23); ApplyStyle(row.pBtn); row.pBtn.t = row.pBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal"); row.pBtn.t:SetPoint("CENTER"); row.pBtn.t:SetText("+")
        row.colorBtns = {}
        for ci, c in ipairs(colorPalette) do
            local cb = CreateFrame("Button", nil, row, "BackdropTemplate")
            cb:SetSize(18, 18); cb:SetPoint("TOPLEFT", ((ci-1) % 8) * 26 + 10, ci > 8 and -67 or -45)
            cb:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"}); cb:SetBackdropColor(c.r, c.g, c.b); row.colorBtns[ci] = cb
        end
        row.shapeBtns = {}
        local icons = {"●", "▲", "▼", "◀", "▶"}
        for si = 1, 5 do
            local sb = CreateFrame("Button", nil, row, "BackdropTemplate")
            sb:SetSize(40, 22); sb:SetPoint("TOPLEFT", (si-1)*45 + 10, -92); ApplyStyle(sb); sb.t = sb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); sb.t:SetPoint("CENTER"); sb.t:SetText(icons[si]); row.shapeBtns[si] = sb
        end
    end
    row:SetParent(parent); table.insert(activeRows, row); return row
end

function RefreshEverything()
    local currentMapID = WorldMapFrame:GetMapID()
    if not currentMapID then return end

    if currentMapID == 1454 or currentMapID == 1456 or currentMapID == 1458 then
        MapToggleButton:Show()
    else
        MapToggleButton:Hide()
    end

    local faction = UnitFactionGroup("player")
    if faction ~= "Horde" then
        MapToggleButton:Hide()
        for _, p in ipairs(activePins) do p:Hide(); table.insert(pinPool, p) end activePins = {}
        for _, r in ipairs(activeRows) do r:Hide(); table.insert(rowPool, r) end activeRows = {}
        if ForeverMapListFrame then ForeverMapListFrame:Hide() end
        return
    end

    for _, p in ipairs(activePins) do p:Hide(); table.insert(pinPool, p) end activePins = {}
    for _, r in ipairs(activeRows) do r:Hide(); table.insert(rowPool, r) end activeRows = {}
    rowMap = {} 

    local hasAdmin = CheckAdminPermission()
    if hasAdmin and isAdmin and ForeverMapListFrame then ForeverMapListFrame:Show() elseif ForeverMapListFrame then ForeverMapListFrame:Hide() end
    if not isVisible then return end

    local rowIdx = 0
    local globalFont = GetGlobalFont()

    for i, data in ipairs(MyMapNotesDB_V49) do
        if data.mapID == currentMapID then 
            local pin = GetPin()
            if pin then
                pin.data = data; pin.id = i; pin:SetAlpha(1.0)
                
                local rawText = data.text or ""
                local localizedText = GetLocalizedText(rawText)
                local isShapeOnly = (localizedText:gsub("%s+", "") == "")

                pin:SetPassThroughButtons()
                
                local size = data.textSize or 40
                pin.text:SetFont(globalFont, size, "OUTLINE")
                
                local displayText = localizedText
                if isShapeOnly then
                    displayText = (({DOT="●", UP="▲", DOWN="▼", LEFT="◀", RIGHT="▶"})[data.shape or "DOT"])
                end
                
                pin.text:SetText(displayText)
                pin.text:SetTextColor(unpack(data.color or {1,1,1}))
                pin:SetSize(pin.text:GetStringWidth() + 5, pin.text:GetStringHeight() + 5)
                local currentListPos = rowIdx 

                pin:SetScript("OnEnter", function(self)
                    self:SetAlpha(0.05)
                    local tipText = data.tooltip
                    if type(tipText) == "table" then
                        tipText = GetLocalizedTooltip(tipText.ko, tipText.en)
                    end
                    if tipText and tipText ~= "" then
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:SetText(tipText, 1, 1, 1, 1, true)
                        GameTooltip:Show()
                    end
                end)
                pin:SetScript("OnLeave", function(self)
                    self:SetAlpha(1.0)
                    local tipText = data.tooltip
                    if type(tipText) == "table" then
                        tipText = GetLocalizedTooltip(tipText.ko, tipText.en)
                    end
                    if tipText and tipText ~= "" then
                        GameTooltip:Hide()
                    end
                end)

                pin:SetScript("OnMouseDown", function(self, button)
                    if hasAdmin and isAdmin and not IsShiftKeyDown() then
                        ForeverMapInputFrame.mode = "EDIT"; ForeverMapInputFrame.targetIdx = i; ForeverMapInputEditBox:SetText(data.text or ""); ForeverMapInputFrame:Show()
                    elseif hasAdmin and isAdmin and IsShiftKeyDown() then
                        local scrollMax = ForeverMapScrollFrame:GetVerticalScrollRange()
                        ForeverMapScrollFrame:SetVerticalScroll(math.min(currentListPos * 125, scrollMax))
                    else
                        if isShapeOnly then
                            if button == "LeftButton" then
                                SetWaypoint(data.mapID, data.x, data.y)
                            elseif button == "RightButton" then
                                ClearWaypoint()
                            end
                        end
                    end
                end)
                pin:SetScript("OnDragStart", function(self) if hasAdmin and isAdmin and IsShiftKeyDown() then self.isDragging = true; self:StartMoving() end end)
                pin:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); self.isDragging = false; if self.data then local canvas = WorldMapFrame:GetCanvas(); local w, h = canvas:GetSize(); local left, top = self:GetCenter(); local cL, cT = canvas:GetLeft(), canvas:GetTop(); self.data.x = (left - cL) / w; self.data.y = (cT - top) / h end end)
                pin:SetScript("OnUpdate", function(self) if not self.isDragging and self.data and self.data.mapID == WorldMapFrame:GetMapID() and WorldMapFrame:IsVisible() then local canvas = WorldMapFrame:GetCanvas(); local cw, ch = canvas:GetSize(); if cw > 0 and ch > 0 then self:ClearAllPoints(); self:SetPoint("CENTER", canvas, "TOPLEFT", self.data.x * cw, -self.data.y * ch); self:Show() end elseif not self.isDragging then self:Hide() end end)
                pin:Show()
            end
        end
        if hasAdmin and isAdmin then
            local row = GetRow(ForeverMapListFrame.Content)
            row:SetPoint("TOPLEFT", 0, -rowIdx*125); row:Show()
            rowMap[i] = row
            
            local rowText = data.text or ""
            if rowText:gsub("%s+", "") == "" then rowText = "" end
            
            row.name:SetText("["..i.."] "..(rowText ~= "" and rowText:gsub("\n", " ") or L.SHAPE_PIN))
            row.sizeTxt:SetText(L.SIZE .. (data.textSize or 40))
            row.del:SetScript("OnClick", function() table.remove(MyMapNotesDB_V49, i); RefreshEverything() end)
            row.mBtn:SetScript("OnClick", function() data.textSize = math.max(10, (data.textSize or 40) - 10); RefreshEverything() end)
            row.pBtn:SetScript("OnClick", function() data.textSize = (data.textSize or 40) + 10; RefreshEverything() end)
            for ci, cb in ipairs(row.colorBtns) do local c = colorPalette[ci]; cb:SetScript("OnClick", function() data.color = {c.r, c.g, c.b}; RefreshEverything() end) end
            for si, sb in ipairs(row.shapeBtns) do sb:SetScript("OnClick", function() data.shape = ({"DOT", "UP", "DOWN", "LEFT", "RIGHT"})[si]; data.text = ""; RefreshEverything() end) end
            rowIdx = rowIdx + 1
        end
    end
    if ForeverMapListFrame and ForeverMapListFrame.Content then
        ForeverMapListFrame.Content:SetHeight(rowIdx * 125)
    end
end

local MainFrame = CreateFrame("Frame", "ForeverMapListFrame", WorldMapFrame, "BackdropTemplate")
MainFrame:SetSize(305, 600); MainFrame:SetPoint("RIGHT", WorldMapFrame, "LEFT", -15, 0); ApplyStyle(MainFrame); MainFrame:Hide()
local Title = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); Title:SetPoint("TOP", 0, -15); Title:SetText(L.TITLE)
local ScrollFrame = CreateFrame("ScrollFrame", "ForeverMapScrollFrame", MainFrame, "UIPanelScrollFrameTemplate")
ScrollFrame:SetPoint("TOPLEFT", 10, -50); ScrollFrame:SetPoint("BOTTOMRIGHT", -30, 90)
MainFrame.Content = CreateFrame("Frame", nil, ScrollFrame); MainFrame.Content:SetSize(260, 1); ScrollFrame:SetScrollChild(MainFrame.Content)

local InputFrame = CreateFrame("Frame", "ForeverMapInputFrame", UIParent, "BackdropTemplate")
InputFrame:SetSize(350, 220); InputFrame:SetPoint("CENTER"); InputFrame:SetFrameStrata("FULLSCREEN_DIALOG"); ApplyStyle(InputFrame); InputFrame:Hide()
local InputScroll = CreateFrame("ScrollFrame", nil, InputFrame, "UIPanelScrollFrameTemplate")
InputScroll:SetPoint("TOPLEFT", 15, -40); InputScroll:SetPoint("BOTTOMRIGHT", -35, 60)

local InputEditBox = CreateFrame("EditBox", "ForeverMapInputEditBox", InputScroll)
InputEditBox:SetMultiLine(true)
InputEditBox:SetWidth(290)
InputEditBox:SetAutoFocus(true)
InputEditBox:SetFontObject("ChatFontNormal")
InputScroll:SetScrollChild(InputEditBox)

local function MyMapNotesSave()
    local text = InputEditBox:GetText()
    if InputFrame.mode == "ADD" then 
        table.insert(MyMapNotesDB_V49, { mapID = WorldMapFrame:GetMapID(), x = 0.5, y = 0.5, text = text, textSize = 40, color = {1,1,1}, shape = "DOT" })
    else 
        MyMapNotesDB_V49[InputFrame.targetIdx].text = text 
    end
    InputFrame:Hide(); RefreshEverything()
end
InputEditBox:SetScript("OnEnterPressed", function(self) if IsControlKeyDown() then MyMapNotesSave() else self:Insert("\n") end end)
InputEditBox:SetScript("OnEscapePressed", function() InputFrame:Hide() end)

local ApplyBtn = CreateFrame("Button", nil, InputFrame, "BackdropTemplate"); ApplyBtn:SetSize(100, 30); ApplyBtn:SetPoint("BOTTOMLEFT", 50, 15); ApplyStyle(ApplyBtn); ApplyBtn.t = ApplyBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal"); ApplyBtn.t:SetPoint("CENTER"); ApplyBtn.t:SetText(L.APPLY); ApplyBtn:SetScript("OnClick", MyMapNotesSave)
local CloseBtn = CreateFrame("Button", nil, InputFrame, "BackdropTemplate"); CloseBtn:SetSize(100, 30); CloseBtn:SetPoint("BOTTOMRIGHT", -50, 15); ApplyStyle(CloseBtn); CloseBtn.t = CloseBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal"); CloseBtn.t:SetPoint("CENTER"); CloseBtn.t:SetText(L.CLOSE); CloseBtn:SetScript("OnClick", function() InputFrame:Hide() end)

local function serializeTable(val)
    if type(val) == "table" then local res = "{"; for k, v in pairs(val) do local key = type(k) == "string" and string.format("[%q]", k) or string.format("[%d]", k); res = res .. key .. "=" .. serializeTable(v) .. "," end; return res .. "}"
    elseif type(val) == "string" then return string.format("%q", val) else return tostring(val) end
end

local IOFrame = CreateFrame("Frame", "ForeverMapIOFrame", UIParent, "BackdropTemplate"); IOFrame:SetSize(450, 450); IOFrame:SetPoint("CENTER"); ApplyStyle(IOFrame); IOFrame:Hide(); IOFrame:SetFrameStrata("FULLSCREEN_DIALOG")
local IOScroll = CreateFrame("ScrollFrame", nil, IOFrame, "UIPanelScrollFrameTemplate"); IOScroll:SetPoint("TOPLEFT", 20, -20); IOScroll:SetPoint("BOTTOMRIGHT", -35, 70)
local IOEditBox = CreateFrame("EditBox", nil, IOScroll); IOEditBox:SetMultiLine(true); IOEditBox:SetWidth(380); IOEditBox:SetFontObject("ChatFontNormal"); IOScroll:SetScrollChild(IOEditBox)
local IOSaveBtn = CreateFrame("Button", nil, IOFrame, "BackdropTemplate"); IOSaveBtn:SetSize(120, 35); IOSaveBtn:SetPoint("BOTTOMLEFT", 60, 20); ApplyStyle(IOSaveBtn); IOSaveBtn.t = IOSaveBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal"); IOSaveBtn.t:SetPoint("CENTER"); IOSaveBtn.t:SetText(L.APPLY); IOSaveBtn:SetScript("OnClick", function() local func, err = loadstring("return " .. IOEditBox:GetText()); if func then MyMapNotesDB_V49 = func(); RefreshEverything(); IOFrame:Hide() end end)
local IOCloseBtn = CreateFrame("Button", nil, IOFrame, "BackdropTemplate"); IOCloseBtn:SetSize(120, 35); IOCloseBtn:SetPoint("BOTTOMRIGHT", -60, 20); ApplyStyle(IOCloseBtn); IOCloseBtn.t = IOCloseBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal"); IOCloseBtn.t:SetPoint("CENTER"); IOCloseBtn.t:SetText(L.CLOSE); IOCloseBtn:SetScript("OnClick", function() IOFrame:Hide() end)

local function CreateActionButton(text, pos)
    local b = CreateFrame("Button", nil, MainFrame, "BackdropTemplate"); b:SetSize(85, 40); b:SetPoint("BOTTOMLEFT", pos, 20); ApplyStyle(b); b.t = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); b.t:SetPoint("CENTER"); b.t:SetText(text); return b
end
local addBtn = CreateActionButton(L.ADD, 15); addBtn:SetScript("OnClick", function() ForeverMapInputEditBox:SetText(""); ForeverMapInputFrame.mode = "ADD"; ForeverMapInputFrame:Show() end)
local exportBtn = CreateActionButton(L.EXPORT, 105); exportBtn:SetScript("OnClick", function() IOFrame:Show(); IOSaveBtn:Hide(); IOEditBox:SetText(serializeTable(MyMapNotesDB_V49)); IOEditBox:HighlightText() end)
local importBtn = CreateActionButton(L.IMPORT, 195); importBtn:SetScript("OnClick", function() IOFrame:Show(); IOSaveBtn:Show(); IOEditBox:SetText("") end)

SLASH_FOREVERMAP1 = "/smm"
SlashCmdList["FOREVERMAP"] = function(msg)
    if not CheckAdminPermission() then
        print(L.NO_ADMIN)
        return
    end

    local cmd = strtrim(msg)
    if cmd == "관리자" or cmd == "admin" then 
        isAdmin = not isAdmin
        RefreshEverything()
        print(isAdmin and L.ADMIN_ON or L.ADMIN_OFF)
    elseif cmd == "켜기" or cmd == "on" then 
        isVisible = true; RefreshEverything(); print(L.MAP_ON)
    elseif cmd == "끄기" or cmd == "off" then 
        isVisible = false; RefreshEverything(); print(L.MAP_OFF)
    else 
        RefreshEverything() 
    end
end

hooksecurefunc("SetItemRef", function(link, text, button)
    if link == "smm_hide_msg" then
        MyMapNotesOptions = MyMapNotesOptions or {}
        MyMapNotesOptions.hideWelcomeMsg = true
        print(L.NEXT_COMPACT)
    elseif link == "smm_show_msg" then
        MyMapNotesOptions = MyMapNotesOptions or {}
        MyMapNotesOptions.hideWelcomeMsg = false
        print(L.NEXT_FULL)
    end
end)

WorldMapFrame:HookScript("OnShow", RefreshEverything)
hooksecurefunc(WorldMapFrame, "OnMapChanged", RefreshEverything)

local isFirstLogin = true
local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:SetScript("OnEvent", function(self, event)
    if RefreshEverything then RefreshEverything() end
    if isFirstLogin then
        MyMapNotesOptions = MyMapNotesOptions or {}
        
        if MyMapNotesOptions.hideWelcomeMsg then
            local showLink = "|Hsmm_show_msg|h|cff00ff00" .. L.SHOW_BTN .. "|r|h"
            print("|cffffff00ForeverMap|r " .. L.LOADED .. " " .. showLink)
        else
            local hideLink = "|Hsmm_hide_msg|h|cff888888" .. L.HIDE_BTN .. "|r|h"
            print("|cffffff00ForeverMap|r |cffaaaaaaBy|r |cff00ccff설쁘|r " .. hideLink)
        end
        
        isFirstLogin = false
    end
end)