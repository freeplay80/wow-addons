
	----------------------------------------------------------------------
	-- Leatrix Plus Media for Forever
	----------------------------------------------------------------------

	local void, Leatrix_Plus = ...
	local L = Leatrix_Plus.L

	local ZoneList = {}
	local prefol = "|cffffffaa{" .. L["right-click to go back"] .. "}"

	local gameversion, gamebuild, gamedate, gametocversion = GetBuildInfo()

	-- Create a table for each heading
	ZoneList = {L["Zones"], L["Dungeons"], L["Various"], L["Random"], L["Search"], L["Movies"]}
	for k, v in ipairs(ZoneList) do
		ZoneList[v] = {}
	end

	-- Function to create a table for each zone
	local function Zn(where, category, zone, tracklist)
		tinsert(ZoneList[where], {category = category, zone = zone, tracks = tracklist})
	end

	----------------------------------------------------------------------
	-- Movies  *** MANUALLY EDITED ***
	-- make_ltp_media.R copies this section as-is from the current Leatrix_Plus_Media.lua.
	-- Cinematics (under Various) is generated from the movie IDs here, e.g. |r(1098).
	----------------------------------------------------------------------

	Zn(L["Movies"], L["Movies"], "|cffffd800" .. L["Movies"], {""})
	Zn(L["Movies"], L["Movies"], L["World of Warcraft"], {"|cffffd800" .. L["Movies"] .. ": " .. L["World of Warcraft"], prefol,
		"|cffffd800", "|cffffd800" .. L["World of Warcraft"],
		L["Ten Years of Warcraft"] .. " |r(1)",
		L["World of Warcraft"] .. " |r(2)",
		L["New Horizons"] .. " |r(1098)",
	})

	----------------------------------------------------------------------
	-- Zones: Eastern Kingdoms
	----------------------------------------------------------------------

	Zn(L["Zones"], L["Eastern Kingdoms"], "|cffffd800" .. L["Eastern Kingdoms"], {""})

	Zn(L["Zones"], L["Eastern Kingdoms"], L["Alterac Mountains"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Alterac Mountains"], prefol,
		"|cffffd800", "|cffffd800" .. "Alterac Mountains",
		"forever/mus_c_day_forest_1.mp3#8180778",
		"forever/mus_c_day_forest_2.mp3#8180780",
		"forever/mus_c_day_forest_3.mp3#8180782",

		"|cffffd800", "|cffffd800" .. "Dalaran, City of Dalaran, The Silver Enclave, Runeweaver Lounge, The Threads of Fate, The Linguist's Lounge, Old Dalaran Ruins",
		"forever/mus_c_dalaran_1.mp3#8285938",
		"forever/mus_c_dalaran_2.mp3#8285940",
		"forever/mus_c_dalaran_3.mp3#8285942",
		"forever/mus_c_dalaran_4.mp3#8285944",

		"|cffffd800", "|cffffd800" .. "The Violet Citadel, The Purple Parlor",
		"forever/mus_c_dalaran_spire.mp3#8451379",

		"|cffffd800", "|cffffd800" .. "The Underbelly, Cantrips & Crows",
		"forever/mus_c_dalaran_sewer_1.mp3#8451330",
		"forever/mus_c_dalaran_sewer_2.mp3#8451332",
		"forever/mus_c_dalaran_sewer_3.mp3#8451334",
		"forever/mus_c_dalaran_sewer_4.mp3#8451336",

		"|cffffd800", "|cffffd800" .. "Strahnbrad, Ruins of Alterac, Crushridge Hold, Slaughter Hollow, Gallows' Corner, Growless Cave",
		"forever/mus_c_day_volcanic_1.mp3#8181275",
		"forever/mus_c_day_volcanic_2.mp3#8181277",
		"forever/mus_c_night_volcanic_1.mp3#8181279",
		"forever/mus_c_night_volcanic_2.mp3#8181281",

		"|cffffd800", "|cffffd800" .. "Ruins of Alterac",
		"forever/mus_c_battle_6.mp3#8180909",

		"|cffffd800", "|cffffd800" .. "Crushridge Hold, Growless Cave",
		"forever/mus_c_cursed_land_4.mp3#8180744#1",
		"forever/mus_c_cursed_land_5.mp3#8180746#1",
		"forever/mus_c_cursed_land_6.mp3#8180748#1",

		"|cffffd800", "|cffffd800" .. "Alterac Valley",
		"forever/mus_c_cursed_land_1.mp3#8180738",
		"forever/mus_c_cursed_land_2.mp3#8180740",
		"forever/mus_c_cursed_land_3.mp3#8180742",
		"forever/mus_c_cursed_land_4.mp3#8180744#2",
		"forever/mus_c_cursed_land_5.mp3#8180746#2",
		"forever/mus_c_cursed_land_6.mp3#8180748#2",

		"|cffffd800", "|cffffd800" .. "Ravenholdt Manor",
		"forever/mus_c_mystery_3.mp3#8180937",
		"forever/mus_c_mystery_4.mp3#8180939",
		"forever/mus_c_mystery_10.mp3#8180951",
		"forever/mus_c_mystery_5.mp3#8180941",
		"forever/mus_c_mystery_2.mp3#8180935",
		"forever/mus_c_mystery_6.mp3#8180943",
		"forever/mus_c_mystery_7.mp3#8180945",
		"forever/mus_c_mystery_8.mp3#8180947",
		"forever/mus_c_mystery_9.mp3#8180949",
		"forever/mus_c_mystery_1.mp3#8180933",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_battle_3.mp3#8180903",
		"forever/mus_c_dalaran_intro.mp3#8285946",
		"forever/mus_c_battle_1.mp3#8180899",
		"forever/mus_c_haunted_2.mp3#8181315",
	})

	Zn(L["Zones"], L["Eastern Kingdoms"], L["Arathi Highlands"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Arathi Highlands"], prefol,
		"|cffffd800", "|cffffd800" .. "Arathi Highlands",
		"forever/mus_c_day_mountain_1.mp3#8181287",
		"forever/mus_c_day_mountain_2.mp3#8181289",
		"forever/mus_c_day_mountain_3.mp3#8181291",
		"forever/mus_c_night_mountain_3.mp3#8181297",
		"forever/mus_c_night_mountain_4.mp3#8181299",
		"forever/mus_c_night_mountain_1.mp3#8181293",
		"forever/mus_c_night_mountain_2.mp3#8181295",
		"forever/mus_c_mystery_3.mp3#8180937",
		"forever/mus_c_mystery_4.mp3#8180939",
		"forever/mus_c_mystery_10.mp3#8180951",
		"forever/mus_c_mystery_5.mp3#8180941",
		"forever/mus_c_mystery_2.mp3#8180935",
		"forever/mus_c_mystery_6.mp3#8180943",
		"forever/mus_c_mystery_7.mp3#8180945",
		"forever/mus_c_mystery_8.mp3#8180947",
		"forever/mus_c_mystery_9.mp3#8180949",
		"forever/mus_c_mystery_1.mp3#8180933",

		"|cffffd800", "|cffffd800" .. "Boulderfist Hall, Boulderfist Outpost",
		"forever/mus_c_day_volcanic_1.mp3#8181275",
		"forever/mus_c_day_volcanic_2.mp3#8181277",
		"forever/mus_c_night_volcanic_1.mp3#8181279",
		"forever/mus_c_night_volcanic_2.mp3#8181281",

		"|cffffd800", "|cffffd800" .. "Witherbark Village, Faldir's Cove, Witherbark Caverns",
		"forever/mus_c_day_jungle_1.mp3#8181259",
		"forever/mus_c_day_jungle_2.mp3#8181261",
		"forever/mus_c_day_jungle_3.mp3#8181263",
		"forever/mus_c_night_jungle_1.mp3#8181265",
		"forever/mus_c_night_jungle_2.mp3#8181267",
		"forever/mus_c_night_jungle_3.mp3#8181269",

		"|cffffd800", "|cffffd800" .. "Witherbark Village, The Drowned Reef",
		"forever/mus_c_night_desert_1.mp3#8181133",
		"forever/mus_c_night_desert_2.mp3#8181135",
		"forever/mus_c_night_desert_3.mp3#8181137",

		"|cffffd800", "|cffffd800" .. "Drywhisker Gorge, The Tower of Arathor, Faldir's Cove",
		"forever/mus_c_cursed_land_4.mp3#8180744",
		"forever/mus_c_cursed_land_5.mp3#8180746",
		"forever/mus_c_cursed_land_6.mp3#8180748",

		"|cffffd800", "|cffffd800" .. "Hammerfall",
		"forever/mus_c_orgrimmar_2_zone.mp3#8181037",
		"forever/mus_c_orgrimmar_1_zone.mp3#8181033",

		"|cffffd800", "|cffffd800" .. "Stromgarde Keep",
		"forever/mus_c_stormwind_8.mp3#8180880",
		"forever/mus_c_battle_5.mp3#8180907",

		"|cffffd800", "|cffffd800" .. "Crypt",
		"forever/mus_c_haunted_1.mp3#8181313",

		"|cffffd800", "|cffffd800" .. "The Sanctum",
		"forever/mus_c_gloomy_1.mp3#8181325#1",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_gloomy_1.mp3#8181325#2",
		"forever/mus_c_battle_3.mp3#8180903",
		"forever/mus_c_stormwind_3.mp3#8180870",
		"forever/mus_c_stormwind_1.mp3#8180866",
		"forever/mus_c_haunted_2.mp3#8181315",
	})

	Zn(L["Zones"], L["Eastern Kingdoms"], L["Badlands"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Badlands"], prefol,
		"|cffffd800", "|cffffd800" .. "Badlands",
		"forever/mus_c_night_barren_dry_1.mp3#8181055",
		"forever/mus_c_night_barren_dry_2.mp3#8181057",
		"forever/mus_c_day_barren_dry_2.mp3#8181051",
		"forever/mus_c_day_barren_dry_3.mp3#8181053",
		"forever/mus_c_night_barren_dry_3.mp3#8181059",
		"forever/mus_c_day_barren_dry_1.mp3#8181049",

		"|cffffd800", "|cffffd800" .. "Angor Fortress",
		"forever/mus_c_soggy_place_zone_2.mp3#8181013",
		"forever/mus_c_soggy_place_zone_5.mp3#8181019",
		"forever/mus_c_soggy_place_zone_1.mp3#8181011",
		"forever/mus_c_soggy_place_zone_3.mp3#8181015",
		"forever/mus_c_soggy_place_zone_4.mp3#8181017",

		"|cffffd800", "|cffffd800" .. "Dustbelch Grotto, Uldaman",
		"forever/mus_c_day_volcanic_1.mp3#8181275",
		"forever/mus_c_day_volcanic_2.mp3#8181277",
		"forever/mus_c_night_volcanic_1.mp3#8181279",
		"forever/mus_c_night_volcanic_2.mp3#8181281",

		"|cffffd800", "|cffffd800" .. "South Common Hall",
		"forever/mus_c_battle_2.mp3#8180901",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_battle_5.mp3#8180907",
	})

	Zn(L["Zones"], L["Eastern Kingdoms"], L["Blasted Lands"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Blasted Lands"], prefol,
		"|cffffd800", "|cffffd800" .. "Blasted Lands",
		"forever/mus_c_night_barren_dry_1.mp3#8181055",
		"forever/mus_c_night_barren_dry_2.mp3#8181057",
		"forever/mus_c_day_barren_dry_2.mp3#8181051",
		"forever/mus_c_day_barren_dry_3.mp3#8181053",
		"forever/mus_c_night_barren_dry_3.mp3#8181059",
		"forever/mus_c_day_barren_dry_1.mp3#8181049",

		"|cffffd800", "|cffffd800" .. "The Tainted Scar, Dreadmaul Post, Serpent's Coil, Altar of Storms, Garrison Armory, Nethergarde Mines",
		"forever/mus_c_day_volcanic_1.mp3#8181275",
		"forever/mus_c_day_volcanic_2.mp3#8181277",
		"forever/mus_c_night_volcanic_1.mp3#8181279",
		"forever/mus_c_night_volcanic_2.mp3#8181281",

		"|cffffd800", "|cffffd800" .. "Dreadmaul Hold",
		"forever/mus_c_battle_6.mp3#8180909",

		"|cffffd800", "|cffffd800" .. "Nethergarde Keep",
		"forever/mus_c_cursed_land_4.mp3#8180744",
		"forever/mus_c_cursed_land_5.mp3#8180746",
		"forever/mus_c_cursed_land_6.mp3#8180748",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_battle_3.mp3#8180903",
		"forever/mus_c_gloomy_2.mp3#8181327",
	})

	Zn(L["Zones"], L["Eastern Kingdoms"], L["Burning Steppes"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Burning Steppes"], prefol,
		"|cffffd800", "|cffffd800" .. "Burning Steppes",
		"forever/mus_c_day_volcanic_1.mp3#8181275",
		"forever/mus_c_day_volcanic_2.mp3#8181277",
		"forever/mus_c_night_volcanic_1.mp3#8181279",
		"forever/mus_c_night_volcanic_2.mp3#8181281",

		"|cffffd800", "|cffffd800" .. "Burning Steppes, The Masonary, Slither Rock",
		"forever/mus_c_cursed_land_4.mp3#8180744",
		"forever/mus_c_cursed_land_5.mp3#8180746",
		"forever/mus_c_cursed_land_6.mp3#8180748",

		"|cffffd800", "|cffffd800" .. "Dreadmaul Rock, Flame Crest",
		"forever/mus_c_soggy_place_zone_2.mp3#8181013",
		"forever/mus_c_soggy_place_zone_5.mp3#8181019",
		"forever/mus_c_soggy_place_zone_1.mp3#8181011",
		"forever/mus_c_soggy_place_zone_3.mp3#8181015",
		"forever/mus_c_soggy_place_zone_4.mp3#8181017",

		"|cffffd800", "|cffffd800" .. "Blackrock Stronghold",
		"forever/mus_c_orgrimmar_2_zone.mp3#8181037",
		"forever/mus_c_orgrimmar_1_zone.mp3#8181033",

		"|cffffd800", "|cffffd800" .. "The Pillar of Ash",
		"forever/mus_c_mystery_3.mp3#8180937",
		"forever/mus_c_mystery_4.mp3#8180939",
		"forever/mus_c_mystery_10.mp3#8180951",
		"forever/mus_c_mystery_5.mp3#8180941",
		"forever/mus_c_mystery_2.mp3#8180935",
		"forever/mus_c_mystery_6.mp3#8180943",
		"forever/mus_c_mystery_7.mp3#8180945",
		"forever/mus_c_mystery_8.mp3#8180947",
		"forever/mus_c_mystery_9.mp3#8180949",
		"forever/mus_c_mystery_1.mp3#8180933",

		"|cffffd800", "|cffffd800" .. "Blackrock Mountain",
		"forever/mus_c_cursed_land_2.mp3#8180740",
		"forever/mus_c_cursed_land_3.mp3#8180742#1",

		"|cffffd800", "|cffffd800" .. "Blackrock Spire",
		"forever/mus_c_cursed_land_1.mp3#8180738",
		"forever/mus_c_cursed_land_3.mp3#8180742#2",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_battle_3.mp3#8180903",
		"forever/mus_c_battle_5.mp3#8180907",
		"forever/mus_c_haunted_2.mp3#8181315",
	})

	Zn(L["Zones"], L["Eastern Kingdoms"], L["Deadwind Pass"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Deadwind Pass"], prefol,
		"|cffffd800", "|cffffd800" .. "Deadwind Pass",
		"forever/mus_c_day_evil_forest_1.mp3#8180772",
		"forever/mus_c_day_evil_forest_3.mp3#8180776",
		"forever/mus_c_night_evil_forest_1.mp3#8180758",
		"forever/mus_c_day_evil_forest_2.mp3#8180774",
		"forever/mus_c_night_evil_forest_2.mp3#8180760",
		"forever/mus_c_night_evil_forest_3.mp3#8180762",

		"|cffffd800", "|cffffd800" .. "The Vice",
		"forever/mus_c_mystery_3.mp3#8180937",
		"forever/mus_c_mystery_4.mp3#8180939",
		"forever/mus_c_mystery_10.mp3#8180951",
		"forever/mus_c_mystery_5.mp3#8180941",
		"forever/mus_c_mystery_2.mp3#8180935",
		"forever/mus_c_mystery_6.mp3#8180943",
		"forever/mus_c_mystery_7.mp3#8180945",
		"forever/mus_c_mystery_8.mp3#8180947",
		"forever/mus_c_mystery_9.mp3#8180949",
		"forever/mus_c_mystery_1.mp3#8180933",

		"|cffffd800", "|cffffd800" .. "Morgan's Plot",
		"forever/mus_c_haunted_1.mp3#8181313",

		"|cffffd800", "|cffffd800" .. "Grosh'gok Compound",
		"forever/mus_c_day_volcanic_1.mp3#8181275",
		"forever/mus_c_day_volcanic_2.mp3#8181277",
		"forever/mus_c_night_volcanic_1.mp3#8181279",
		"forever/mus_c_night_volcanic_2.mp3#8181281",
	})

	Zn(L["Zones"], L["Eastern Kingdoms"], L["Dun Morogh"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Dun Morogh"], prefol,
		"|cffffd800", "|cffffd800" .. "Dun Morogh",
		"forever/mus_c_day_mountain_1.mp3#8181287",
		"forever/mus_c_day_mountain_2.mp3#8181289",
		"forever/mus_c_day_mountain_3.mp3#8181291",
		"forever/mus_c_night_mountain_3.mp3#8181297",
		"forever/mus_c_night_mountain_4.mp3#8181299",
		"forever/mus_c_night_mountain_1.mp3#8181293",
		"forever/mus_c_night_mountain_2.mp3#8181295",

		"|cffffd800", "|cffffd800" .. "Dun Morogh, Iceflow Lake, Chill Breeze Valley, Shimmer Ridge, Amberstill Ranch",
		"forever/mus_c_mystery_3.mp3#8180937",
		"forever/mus_c_mystery_4.mp3#8180939",
		"forever/mus_c_mystery_10.mp3#8180951",
		"forever/mus_c_mystery_5.mp3#8180941",
		"forever/mus_c_mystery_2.mp3#8180935",
		"forever/mus_c_mystery_6.mp3#8180943",
		"forever/mus_c_mystery_7.mp3#8180945",
		"forever/mus_c_mystery_8.mp3#8180947",
		"forever/mus_c_mystery_9.mp3#8180949",
		"forever/mus_c_mystery_1.mp3#8180933",

		"|cffffd800", "|cffffd800" .. "Gol'Bolar Quarry Mine, The Grizzled Den",
		"forever/mus_c_night_evil_forest_1.mp3#8180758",
		"forever/mus_c_night_evil_forest_2.mp3#8180760",
		"forever/mus_c_night_evil_forest_3.mp3#8180762",

		"|cffffd800", "|cffffd800" .. "Frostmane Hold",
		"forever/mus_c_soggy_place_zone_2.mp3#8181013",
		"forever/mus_c_soggy_place_zone_5.mp3#8181019",
		"forever/mus_c_soggy_place_zone_1.mp3#8181011",
		"forever/mus_c_soggy_place_zone_3.mp3#8181015",
		"forever/mus_c_soggy_place_zone_4.mp3#8181017",

		"|cffffd800", "|cffffd800" .. "Thunderbrew Distillery",
		"forever/mus_c_tavern_alliance_1.mp3#8180983",
		"forever/mus_c_tavern_alliance_2.mp3#8180985",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_swamp_1.mp3#8181335",
	})

	Zn(L["Zones"], L["Eastern Kingdoms"], L["Duskwood"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Duskwood"], prefol,
		"|cffffd800", "|cffffd800" .. "Duskwood",
		"forever/mus_c_day_evil_forest_1.mp3#8180772",
		"forever/mus_c_day_evil_forest_3.mp3#8180776",
		"forever/mus_c_night_evil_forest_1.mp3#8180758",
		"forever/mus_c_day_evil_forest_2.mp3#8180774",
		"forever/mus_c_night_evil_forest_2.mp3#8180760",
		"forever/mus_c_night_evil_forest_3.mp3#8180762",
		"forever/mus_c_cursed_land_4.mp3#8180744",
		"forever/mus_c_cursed_land_5.mp3#8180746",
		"forever/mus_c_cursed_land_6.mp3#8180748",

		"|cffffd800", "|cffffd800" .. "Duskwood, Dawning Wood Catacombs, Roland's Doom",
		"forever/mus_c_cursed_land_1.mp3#8180738",
		"forever/mus_c_cursed_land_3.mp3#8180742",

		"|cffffd800", "|cffffd800" .. "The World Tree",
		"forever/mus_c_enchanted_forest_5.mp3#8180792",
		"forever/mus_c_enchanted_forest_1.mp3#8180784",
		"forever/mus_c_enchanted_forest_4.mp3#8180790",
		"forever/mus_c_enchanted_forest_2.mp3#8180786",
		"forever/mus_c_enchanted_forest_3.mp3#8180788",

		"|cffffd800", "|cffffd800" .. "Vul'Gol Ogre Mound",
		"forever/mus_c_orgrimmar_2_zone.mp3#8181037",
		"forever/mus_c_day_volcanic_1.mp3#8181275",
		"forever/mus_c_day_volcanic_2.mp3#8181277",
		"forever/mus_c_night_volcanic_1.mp3#8181279",
		"forever/mus_c_night_volcanic_2.mp3#8181281",

		"|cffffd800", "|cffffd800" .. "Tranquil Gardens Cemetery, Raven Hill Cemetery",
		"forever/mus_c_haunted_1.mp3#8181313",
	})

	Zn(L["Zones"], L["Eastern Kingdoms"], L["Eastern Plaguelands"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Eastern Plaguelands"], prefol,
		"|cffffd800", "|cffffd800" .. "Eastern Plaguelands",
		"forever/mus_c_cursed_land_4.mp3#8180744",
		"forever/mus_c_cursed_land_5.mp3#8180746",
		"forever/mus_c_cursed_land_6.mp3#8180748",

		"|cffffd800", "|cffffd800" .. "The Fungal Vale",
		"forever/mus_c_undercity_1.mp3#8181003",
		"forever/mus_c_undercity_2.mp3#8181005",
		"forever/mus_c_undercity_3.mp3#8181007",

		"|cffffd800", "|cffffd800" .. "The Marris Stead, Tyr's Hand Abbey, The Scarlet Basilica",
		"forever/mus_c_mystery_3.mp3#8180937",
		"forever/mus_c_mystery_4.mp3#8180939",
		"forever/mus_c_mystery_10.mp3#8180951",
		"forever/mus_c_mystery_5.mp3#8180941",
		"forever/mus_c_mystery_2.mp3#8180935",
		"forever/mus_c_mystery_6.mp3#8180943",
		"forever/mus_c_mystery_7.mp3#8180945",
		"forever/mus_c_mystery_8.mp3#8180947",
		"forever/mus_c_mystery_9.mp3#8180949",
		"forever/mus_c_mystery_1.mp3#8180933",

		"|cffffd800", "|cffffd800" .. "The Undercroft",
		"forever/mus_c_haunted_1.mp3#8181313",

		"|cffffd800", "|cffffd800" .. "Tyr's Hand",
		"forever/mus_c_cursed_land_1.mp3#8180738",
		"forever/mus_c_cursed_land_3.mp3#8180742",

		"|cffffd800", "|cffffd800" .. "Zul'Mashar, Terrorweb Tunnel",
		"forever/mus_c_soggy_place_zone_2.mp3#8181013",
		"forever/mus_c_soggy_place_zone_5.mp3#8181019",
		"forever/mus_c_soggy_place_zone_1.mp3#8181011",
		"forever/mus_c_soggy_place_zone_3.mp3#8181015",
		"forever/mus_c_soggy_place_zone_4.mp3#8181017",

		"|cffffd800", "|cffffd800" .. "Quel'Lithien Lodge",
		"forever/mus_c_darnasssus_walking_1.mp3#8180752",
		"forever/mus_c_darnasssus_walking_2.mp3#8180754",
		"forever/mus_c_darnasssus_walking_3.mp3#8180756",

		"|cffffd800", "|cffffd800" .. "New Avalon",
		"musical moments/mystery/mystery04-zone.mp3#53243",
		"musical moments/mystery/mystery05-zone.mp3#53244",
		"musical moments/mystery/mystery06-zone.mp3#53245",
		"unknown/1.15.7 - raid - scarlet enclave - new avalon - walk_6865468.mp3#6865468",
		"unknown/1.15.7 - raid - scarlet enclave - new avalon - walk_6865470.mp3#6865470",
		"unknown/1.15.7 - raid - scarlet enclave - new avalon - walk_6865472.mp3#6865472",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_sacred_1.mp3#8181301",
	})

	Zn(L["Zones"], L["Eastern Kingdoms"], L["Elwynn Forest"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Elwynn Forest"], prefol,
		"|cffffd800", "|cffffd800" .. "Elwynn Forest",
		"forever/mus_c_day_forest_1.mp3#8180778",
		"forever/mus_c_day_forest_2.mp3#8180780",
		"forever/mus_c_day_forest_3.mp3#8180782",

		"|cffffd800", "|cffffd800" .. "Northshire Abbey",
		"forever/mus_c_stormwind_3.mp3#8180870",

		"|cffffd800", "|cffffd800" .. "Echo Ridge Mine, Jasperlode Mine, Fargodeep Mine",
		"forever/mus_c_cursed_land_4.mp3#8180744",
		"forever/mus_c_cursed_land_5.mp3#8180746",
		"forever/mus_c_cursed_land_6.mp3#8180748",

		"|cffffd800", "|cffffd800" .. "Westbrook Garrison",
		"forever/mus_c_stormwind_7.mp3#8180878",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_sacred_1.mp3#8181301",
		"forever/mus_c_gloomy_2.mp3#8181327",
		"forever/mus_c_battle_3.mp3#8180903",
	})

	Zn(L["Zones"], L["Eastern Kingdoms"], L["Hillsbrad Foothills"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Hillsbrad Foothills"], prefol,
		"|cffffd800", "|cffffd800" .. "Hillsbrad Foothills",
		"forever/mus_c_day_forest_1.mp3#8180778",
		"forever/mus_c_day_forest_2.mp3#8180780",
		"forever/mus_c_day_forest_3.mp3#8180782",

		"|cffffd800", "|cffffd800" .. "Tarren Mill",
		"forever/mus_c_undercity_1.mp3#8181003",
		"forever/mus_c_undercity_2.mp3#8181005",
		"forever/mus_c_undercity_3.mp3#8181007",

		"|cffffd800", "|cffffd800" .. "Durnholde Keep",
		"forever/mus_c_night_forest_1.mp3#8180764",
		"forever/mus_c_night_forest_2.mp3#8180766",
		"forever/mus_c_night_forest_3.mp3#8180768",
		"forever/mus_c_night_forest_4.mp3#8180770",

		"|cffffd800", "|cffffd800" .. "Southpoint Tower",
		"forever/mus_c_day_evil_forest_1.mp3#8180772",
		"forever/mus_c_day_evil_forest_3.mp3#8180776",
		"forever/mus_c_night_evil_forest_1.mp3#8180758",
		"forever/mus_c_day_evil_forest_2.mp3#8180774",
		"forever/mus_c_night_evil_forest_2.mp3#8180760",
		"forever/mus_c_night_evil_forest_3.mp3#8180762",

		"|cffffd800", "|cffffd800" .. "Dun Garok",
		"forever/mus_c_soggy_place_zone_2.mp3#8181013",
		"forever/mus_c_soggy_place_zone_5.mp3#8181019",
		"forever/mus_c_soggy_place_zone_1.mp3#8181011",
		"forever/mus_c_soggy_place_zone_3.mp3#8181015",
		"forever/mus_c_soggy_place_zone_4.mp3#8181017",

		"|cffffd800", "|cffffd800" .. "Purgation Isle",
		"forever/mus_c_cursed_land_1.mp3#8180738",
		"forever/mus_c_cursed_land_3.mp3#8180742",

		"|cffffd800", "|cffffd800" .. "Darrow Hill",
		"forever/mus_c_cursed_land_4.mp3#8180744",
		"forever/mus_c_cursed_land_5.mp3#8180746",
		"forever/mus_c_cursed_land_6.mp3#8180748",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_gloomy_1.mp3#8181325",
		"forever/mus_c_battle_3.mp3#8180903",
		"forever/mus_c_battle_5.mp3#8180907",
	})

	Zn(L["Zones"], L["Eastern Kingdoms"], L["Hinterlands"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Hinterlands"], prefol,
		"|cffffd800", "|cffffd800" .. "The Hinterlands",
		"forever/mus_c_day_forest_1.mp3#8180778",
		"forever/mus_c_day_forest_2.mp3#8180780",
		"forever/mus_c_day_forest_3.mp3#8180782",

		"|cffffd800", "|cffffd800" .. "Aerie Peak, Jintha'Alor, Featherbeard's Hovel",
		"forever/mus_c_mystery_3.mp3#8180937",
		"forever/mus_c_mystery_4.mp3#8180939",
		"forever/mus_c_mystery_10.mp3#8180951",
		"forever/mus_c_mystery_5.mp3#8180941",
		"forever/mus_c_mystery_2.mp3#8180935",
		"forever/mus_c_mystery_6.mp3#8180943",
		"forever/mus_c_mystery_7.mp3#8180945",
		"forever/mus_c_mystery_8.mp3#8180947",
		"forever/mus_c_mystery_9.mp3#8180949",
		"forever/mus_c_mystery_1.mp3#8180933",

		"|cffffd800", "|cffffd800" .. "Wildhammer Keep, Jintha'Alor",
		"forever/mus_c_soggy_place_zone_2.mp3#8181013",
		"forever/mus_c_soggy_place_zone_5.mp3#8181019",
		"forever/mus_c_soggy_place_zone_1.mp3#8181011",
		"forever/mus_c_soggy_place_zone_3.mp3#8181015",
		"forever/mus_c_soggy_place_zone_4.mp3#8181017",

		"|cffffd800", "|cffffd800" .. "Quel'Danil Lodge",
		"forever/mus_c_enchanted_forest_5.mp3#8180792",
		"forever/mus_c_enchanted_forest_1.mp3#8180784",
		"forever/mus_c_enchanted_forest_4.mp3#8180790",
		"forever/mus_c_enchanted_forest_2.mp3#8180786",
		"forever/mus_c_enchanted_forest_3.mp3#8180788",

		"|cffffd800", "|cffffd800" .. "Skulk Rock, Bogen's Ledge",
		"forever/mus_c_cursed_land_4.mp3#8180744",
		"forever/mus_c_cursed_land_5.mp3#8180746",
		"forever/mus_c_cursed_land_6.mp3#8180748",

		"|cffffd800", "|cffffd800" .. "Shadra'Alor, Jintha'Alor",
		"forever/mus_c_day_jungle_1.mp3#8181259",
		"forever/mus_c_day_jungle_2.mp3#8181261",
		"forever/mus_c_day_jungle_3.mp3#8181263",
		"forever/mus_c_night_jungle_1.mp3#8181265",
		"forever/mus_c_night_jungle_2.mp3#8181267",
		"forever/mus_c_night_jungle_3.mp3#8181269",

		"|cffffd800", "|cffffd800" .. "The Altar of Zul",
		"forever/mus_c_day_desert_1.mp3#8181127",
		"forever/mus_c_day_desert_2.mp3#8181129",
		"forever/mus_c_day_desert_3.mp3#8181131",
		"forever/mus_c_night_desert_1.mp3#8181133",
		"forever/mus_c_night_desert_2.mp3#8181135",
		"forever/mus_c_night_desert_3.mp3#8181137",

		"|cffffd800", "|cffffd800" .. "Seradane",
		"forever/mus_c_darnasssus_walking_1.mp3#8180752",
		"forever/mus_c_darnasssus_walking_2.mp3#8180754",
		"forever/mus_c_darnasssus_walking_3.mp3#8180756",
	})

	Zn(L["Zones"], L["Eastern Kingdoms"], L["Ironforge"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Ironforge"], prefol,
		"|cffffd800", "|cffffd800" .. "City of Ironforge",
		"forever/mus_c_ironforge_walking_1.mp3#8180965",
		"citymusic/ironforge/ironforge walking 03 (glenn).mp3#53194",
		"forever/mus_c_ironforge_walking_4.mp3#8180971",

		"|cffffd800", "|cffffd800" .. "The Stonefire Tavern, The Military Ward, Cask 'n' Anvil, The Great Forge",
		"forever/mus_c_tavern_alliance_1.mp3#8180983",
		"forever/mus_c_tavern_alliance_2.mp3#8180985",

		"|cffffd800", "|cffffd800" .. "The Forlorn Cavern",
		"forever/mus_c_mystery_3.mp3#8180937",
		"forever/mus_c_mystery_4.mp3#8180939",
		"forever/mus_c_mystery_10.mp3#8180951",
		"forever/mus_c_mystery_5.mp3#8180941",
		"forever/mus_c_mystery_2.mp3#8180935",
		"forever/mus_c_mystery_6.mp3#8180943",
		"forever/mus_c_mystery_7.mp3#8180945",
		"forever/mus_c_mystery_8.mp3#8180947",
		"forever/mus_c_mystery_9.mp3#8180949",
		"forever/mus_c_mystery_1.mp3#8180933",

		"|cffffd800", "|cffffd800" .. "Hall of Mysteries",
		"forever/mus_c_stormwind_3.mp3#8180870",

		"|cffffd800", "|cffffd800" .. "Tinker Town",
		"forever/mus_c_tinkertown_intro_moment.mp3#8181317",

		"|cffffd800", "|cffffd800" .. "Hall of Arms",
		"forever/mus_c_warrior_terrace.mp3#8181337",

		"|cffffd800", "|cffffd800" .. "The High Seat",
		"forever/mus_c_ironforge_walking_2.mp3#8180967",

		"|cffffd800", "|cffffd800" .. "Ironforge",
		"forever/mus_c_dwarves_tavern_1a.mp3#8195263",
		"forever/mus_c_dwarves_tavern_1b.mp3#8195265",
		"forever/mus_c_dwarves_tavern_2a.mp3#8195267",
		"forever/mus_c_dwarves_tavern_2b.mp3#8195269",
		"forever/mus_c_dwarves_tavern_3.mp3#8195271",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_ironforge_intro.mp3#8180963",
		"forever/mus_c_sacred_1.mp3#8181301",
	})

	Zn(L["Zones"], L["Eastern Kingdoms"], L["Loch Modan"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Loch Modan"], prefol,
		"|cffffd800", "|cffffd800" .. "Loch Modan",
		"forever/mus_c_day_forest_1.mp3#8180778",
		"forever/mus_c_day_forest_2.mp3#8180780",
		"forever/mus_c_day_forest_3.mp3#8180782",

		"|cffffd800", "|cffffd800" .. "Loch Modan, Stonesplinter Valley, Grizzlepaw Ridge",
		"forever/mus_c_cursed_land_4.mp3#8180744",
		"forever/mus_c_cursed_land_5.mp3#8180746",
		"forever/mus_c_cursed_land_6.mp3#8180748",

		"|cffffd800", "|cffffd800" .. "Mo'grosh Stronghold",
		"forever/mus_c_orgrimmar_2_zone.mp3#8181037",
		"forever/mus_c_orgrimmar_1_zone.mp3#8181033",
		"forever/mus_c_day_volcanic_1.mp3#8181275",
		"forever/mus_c_day_volcanic_2.mp3#8181277",
		"forever/mus_c_night_volcanic_1.mp3#8181279",
		"forever/mus_c_night_volcanic_2.mp3#8181281",

		"|cffffd800", "|cffffd800" .. "Silver Stream Mine",
		"forever/mus_c_night_evil_forest_1.mp3#8180758#1",
		"forever/mus_c_night_evil_forest_2.mp3#8180760#1",
		"forever/mus_c_night_evil_forest_3.mp3#8180762#1",

		"|cffffd800", "|cffffd800" .. "The Loch, Stonesplinter Valley",
		"forever/mus_c_mystery_3.mp3#8180937",
		"forever/mus_c_mystery_4.mp3#8180939",
		"forever/mus_c_mystery_10.mp3#8180951",
		"forever/mus_c_mystery_5.mp3#8180941",
		"forever/mus_c_mystery_2.mp3#8180935",
		"forever/mus_c_mystery_6.mp3#8180943",
		"forever/mus_c_mystery_7.mp3#8180945",
		"forever/mus_c_mystery_8.mp3#8180947",
		"forever/mus_c_mystery_9.mp3#8180949",
		"forever/mus_c_mystery_1.mp3#8180933",

		"|cffffd800", "|cffffd800" .. "South Gate Pass",
		"forever/mus_c_day_mountain_1.mp3#8181287",
		"forever/mus_c_day_mountain_2.mp3#8181289",
		"forever/mus_c_day_mountain_3.mp3#8181291",
		"forever/mus_c_night_mountain_3.mp3#8181297",
		"forever/mus_c_night_mountain_4.mp3#8181299",
		"forever/mus_c_night_mountain_1.mp3#8181293",
		"forever/mus_c_night_mountain_2.mp3#8181295",

		"|cffffd800", "|cffffd800" .. "Stonesplinter Valley",
		"forever/mus_c_day_evil_forest_1.mp3#8180772",
		"forever/mus_c_day_evil_forest_3.mp3#8180776",
		"forever/mus_c_night_evil_forest_1.mp3#8180758#2",
		"forever/mus_c_day_evil_forest_2.mp3#8180774",
		"forever/mus_c_night_evil_forest_2.mp3#8180760#2",
		"forever/mus_c_night_evil_forest_3.mp3#8180762#2",

		"|cffffd800", "|cffffd800" .. "Algaz Station",
		"forever/mus_c_gloomy_1.mp3#8181325",

		"|cffffd800", "|cffffd800" .. "Stoutlager Inn",
		"forever/mus_c_tavern_alliance_1.mp3#8180983",
		"forever/mus_c_tavern_alliance_2.mp3#8180985",
	})

	Zn(L["Zones"], L["Eastern Kingdoms"], L["Redridge Mountains"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Redridge Mountains"], prefol,
		"|cffffd800", "|cffffd800" .. "Redridge Mountains",
		"forever/mus_c_day_forest_1.mp3#8180778",
		"forever/mus_c_day_forest_2.mp3#8180780",
		"forever/mus_c_day_forest_3.mp3#8180782",

		"|cffffd800", "|cffffd800" .. "Lakeshire Inn",
		"forever/mus_c_tavern_alliance_1.mp3#8180983",
		"forever/mus_c_tavern_alliance_2.mp3#8180985",

		"|cffffd800", "|cffffd800" .. "Tower of Ilgalar",
		"forever/mus_c_mystery_3.mp3#8180937",
		"forever/mus_c_mystery_4.mp3#8180939",
		"forever/mus_c_mystery_10.mp3#8180951",
		"forever/mus_c_mystery_5.mp3#8180941",
		"forever/mus_c_mystery_2.mp3#8180935",
		"forever/mus_c_mystery_6.mp3#8180943",
		"forever/mus_c_mystery_7.mp3#8180945",
		"forever/mus_c_mystery_8.mp3#8180947",
		"forever/mus_c_mystery_9.mp3#8180949",
		"forever/mus_c_mystery_1.mp3#8180933",

		"|cffffd800", "|cffffd800" .. "Rethban Caverns, Stonewatch Keep",
		"forever/mus_c_day_evil_forest_1.mp3#8180772",
		"forever/mus_c_day_evil_forest_3.mp3#8180776",
		"forever/mus_c_night_evil_forest_1.mp3#8180758",
		"forever/mus_c_day_evil_forest_2.mp3#8180774",
		"forever/mus_c_night_evil_forest_2.mp3#8180760",
		"forever/mus_c_night_evil_forest_3.mp3#8180762",

		"|cffffd800", "|cffffd800" .. "Render's Valley, Galardell Valley",
		"forever/mus_c_cursed_land_4.mp3#8180744",
		"forever/mus_c_cursed_land_5.mp3#8180746",
		"forever/mus_c_cursed_land_6.mp3#8180748",

		"|cffffd800", "|cffffd800" .. "Render's Rock",
		"forever/mus_c_soggy_place_zone_2.mp3#8181013",
		"forever/mus_c_soggy_place_zone_5.mp3#8181019",
		"forever/mus_c_soggy_place_zone_1.mp3#8181011",
		"forever/mus_c_soggy_place_zone_3.mp3#8181015",
		"forever/mus_c_soggy_place_zone_4.mp3#8181017",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_haunted_2.mp3#8181315",
		"forever/mus_c_warrior_terrace.mp3#8181337",
	})

	Zn(L["Zones"], L["Eastern Kingdoms"], L["Riverglades"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Riverglades"], prefol,
		"|cffffd800", "|cffffd800" .. "Riverglades",
		"forever/mus_c60_riverglades_general_a.mp3#8158714",
		"forever/mus_c60_riverglades_general_b.mp3#8158716",
		"forever/mus_c60_riverglades_general_c.mp3#8158718",
		"forever/mus_c60_riverglades_general_d.mp3#8173715",
		"forever/mus_c60_riverglades_general_e.mp3#8173717",
		"forever/mus_c_night_desert_1.mp3#8181133",
		"forever/mus_c_night_desert_2.mp3#8181135",
		"forever/mus_c_night_desert_3.mp3#8181137",

		"|cffffd800", "|cffffd800" .. "Farholde Iron Mine",
		"forever/mus_c_cursed_land_1.mp3#8180738",
		"forever/mus_c_cursed_land_3.mp3#8180742",

		"|cffffd800", "|cffffd800" .. "Twilight's Shroud, Forlorn Pit",
		"forever/mus_c60_twilights_shroud_a.mp3#8158728",
		"forever/mus_c60_twilights_shroud_b.mp3#8158730",
		"forever/mus_c60_twilights_shroud_c.mp3#8269366#1",
		"forever/mus_c60_twilights_shroud_d.mp3#8269368#1",

		"|cffffd800", "|cffffd800" .. "Sunnyglade",
		"forever/mus_c60_sunnyglade_a.mp3#8173719",
		"forever/mus_c60_sunnyglade_b.mp3#8173721",
		"forever/mus_c60_sunnyglade_c.mp3#8173723",
		"forever/mus_c60_twilights_shroud_c.mp3#8269366#2",
		"forever/mus_c60_twilights_shroud_d.mp3#8269368#2",
		"forever/mus_c_day_evil_forest_1.mp3#8180772",
		"forever/mus_c_day_evil_forest_3.mp3#8180776",
		"forever/mus_c_night_evil_forest_1.mp3#8180758",
		"forever/mus_c_day_evil_forest_2.mp3#8180774",
		"forever/mus_c_night_evil_forest_2.mp3#8180760",
		"forever/mus_c_night_evil_forest_3.mp3#8180762",

		"|cffffd800", "|cffffd800" .. "The Undercroft, Crypt",
		"forever/mus_c_haunted_1.mp3#8181313",

		"|cffffd800", "|cffffd800" .. "Farholde Keep, Southern Watch",
		"forever/mus_c60_farholde_keep_a.mp3#8158708",
		"forever/mus_c60_farholde_keep_b.mp3#8158710",
		"forever/mus_c60_farholde_keep_c.mp3#8269352",
		"forever/mus_c60_farholde_keep_d.mp3#8269354",

		"|cffffd800", "|cffffd800" .. "Wheeler's Grange, Elbrim's Farm, Twilight Hollow",
		"forever/mus_c60_wheelers_grange_a.mp3#8158732",
		"forever/mus_c60_wheelers_grange_b.mp3#8158734",
		"forever/mus_c60_wheelers_grange_c.mp3#8158736",

		"|cffffd800", "|cffffd800" .. "Bolder'ok, Krol'dok Stronghold",
		"forever/mus_c60_bolderok_a.mp3#8158694",
		"forever/mus_c60_bolderok_b.mp3#8158696",
		"forever/mus_c60_bolderok_c.mp3#8158698",
		"forever/mus_c60_bolderok_d.mp3#8158700",

		"|cffffd800", "|cffffd800" .. "Powderfuse Port, Eastwind Shore, Windstead",
		"forever/mus_c60_eastwind_shore_a.mp3#8158702",
		"forever/mus_c60_eastwind_shore_b.mp3#8158704",
		"forever/mus_c60_eastwind_shore_c.mp3#8158706",

		"|cffffd800", "|cffffd800" .. "Rog'mar",
		"forever/mus_c60_rogmar_outpost_a.mp3#8158720#1",
		"forever/mus_c60_rogmar_outpost_b.mp3#8158722",
		"forever/mus_c60_rogmar_outpost_c.mp3#8158724",
		"forever/mus_c60_rogmar_outpost_d.mp3#8158726",

		"|cffffd800", "|cffffd800" .. "Twilight Hollow",
		"forever/mus_c_day_volcanic_1.mp3#8181275",
		"forever/mus_c_day_volcanic_2.mp3#8181277",
		"forever/mus_c_night_volcanic_1.mp3#8181279",
		"forever/mus_c_night_volcanic_2.mp3#8181281",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c60_farholde_keep_intro.mp3#8173705",
		"forever/mus_c60_rogmar_outpost_a.mp3#8158720#2",
	})

	Zn(L["Zones"], L["Eastern Kingdoms"], L["Searing Gorge"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Searing Gorge"], prefol,
		"|cffffd800", "|cffffd800" .. "Searing Gorge",
		"forever/mus_c_day_volcanic_1.mp3#8181275",
		"forever/mus_c_day_volcanic_2.mp3#8181277",
		"forever/mus_c_night_volcanic_1.mp3#8181279",
		"forever/mus_c_night_volcanic_2.mp3#8181281",

		"|cffffd800", "|cffffd800" .. "The Cauldron",
		"forever/mus_c_mystery_3.mp3#8180937",
		"forever/mus_c_mystery_4.mp3#8180939",
		"forever/mus_c_mystery_10.mp3#8180951",
		"forever/mus_c_mystery_5.mp3#8180941",
		"forever/mus_c_mystery_2.mp3#8180935",
		"forever/mus_c_mystery_6.mp3#8180943",
		"forever/mus_c_mystery_7.mp3#8180945",
		"forever/mus_c_mystery_8.mp3#8180947",
		"forever/mus_c_mystery_9.mp3#8180949",
		"forever/mus_c_mystery_1.mp3#8180933",

		"|cffffd800", "|cffffd800" .. "Firewatch Ridge",
		"forever/mus_c_day_desert_1.mp3#8181127",
		"forever/mus_c_day_desert_2.mp3#8181129",
		"forever/mus_c_day_desert_3.mp3#8181131",
		"forever/mus_c_night_desert_1.mp3#8181133",
		"forever/mus_c_night_desert_2.mp3#8181135",
		"forever/mus_c_night_desert_3.mp3#8181137",

		"|cffffd800", "|cffffd800" .. "Blackchar Cave",
		"forever/mus_c_day_jungle_1.mp3#8181259",
		"forever/mus_c_day_jungle_2.mp3#8181261",
		"forever/mus_c_day_jungle_3.mp3#8181263",
		"forever/mus_c_night_jungle_1.mp3#8181265",
		"forever/mus_c_night_jungle_2.mp3#8181267",
		"forever/mus_c_night_jungle_3.mp3#8181269",
	})

	Zn(L["Zones"], L["Eastern Kingdoms"], L["Silverpine Forest"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Silverpine Forest"], prefol,
		"|cffffd800", "|cffffd800" .. "Silverpine Forest",
		"forever/mus_c_day_evil_forest_1.mp3#8180772",
		"forever/mus_c_day_evil_forest_3.mp3#8180776",
		"forever/mus_c_night_evil_forest_1.mp3#8180758#1",
		"forever/mus_c_day_evil_forest_2.mp3#8180774",
		"forever/mus_c_night_evil_forest_2.mp3#8180760#1",
		"forever/mus_c_night_evil_forest_3.mp3#8180762#1",

		"|cffffd800", "|cffffd800" .. "Pyrewood Village, Beren's Peril, Ambermill",
		"forever/mus_c_night_forest_1.mp3#8180764",
		"forever/mus_c_night_forest_2.mp3#8180766",
		"forever/mus_c_night_forest_3.mp3#8180768",
		"forever/mus_c_night_forest_4.mp3#8180770",

		"|cffffd800", "|cffffd800" .. "Deep Elem Mine",
		"forever/mus_c_battle_4.mp3#8180905",

		"|cffffd800", "|cffffd800" .. "The Skittering Dark",
		"forever/mus_c_night_evil_forest_1.mp3#8180758#2",
		"forever/mus_c_night_evil_forest_2.mp3#8180760#2",
		"forever/mus_c_night_evil_forest_3.mp3#8180762#2",

		"|cffffd800", "|cffffd800" .. "The Sepulcher",
		"forever/mus_c_haunted_1.mp3#8181313",

		"|cffffd800", "|cffffd800" .. "Beren's Peril",
		"forever/mus_c_cursed_land_1.mp3#8180738",
		"forever/mus_c_cursed_land_3.mp3#8180742",

		"|cffffd800", "|cffffd800" .. "Fenris Keep",
		"forever/mus_c_battle_6.mp3#8180909",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_battle_3.mp3#8180903",
		"forever/mus_c_battle_5.mp3#8180907",
		"forever/mus_c_haunted_2.mp3#8181315",
	})

	Zn(L["Zones"], L["Eastern Kingdoms"], L["Stormwind City"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Stormwind City"], prefol,
		"|cffffd800", "|cffffd800" .. "Stormwind City",
		"forever/mus_c_stormwind_5.mp3#8180874",
		"forever/mus_c_stormwind_6.mp3#8180876",
		"forever/mus_c_stormwind_7.mp3#8180878",
		"forever/mus_c_stormwind_8.mp3#8180880",
		"forever/mus_c_stormwind_1.mp3#8180866",
		"forever/mus_c_stormwind_3.mp3#8180870",
		"forever/mus_c_stormwind_4.mp3#8180872",
		"forever/mus_c_stormwind_2.mp3#8180868",
		"forever/mus_c_warrior_terrace.mp3#8181337",

		"|cffffd800", "|cffffd800" .. "Wizard's Sanctum",
		"forever/mus_c_magic_1_zone_2.mp3#8180957",
		"forever/mus_c_magic_1_zone_1.mp3#8180955",

		"|cffffd800", "|cffffd800" .. "The Slaughtered Lamb",
		"forever/mus_c_tavern_alliance_1.mp3#8180983",
		"forever/mus_c_tavern_alliance_2.mp3#8180985",
		"forever/mus_c_haunted_1.mp3#8181313",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_stormwind_intro_moment.mp3#8180884",
		"forever/mus_c_ironforge_walking_2.mp3#8180967",
		"forever/mus_c_battle_3.mp3#8180903",
	})

	Zn(L["Zones"], L["Eastern Kingdoms"], L["Stranglethorn Vale"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Stranglethorn Vale"], prefol,
		"|cffffd800", "|cffffd800" .. "Stranglethorn Vale",
		"forever/mus_c_day_jungle_1.mp3#8181259",
		"forever/mus_c_day_jungle_2.mp3#8181261",
		"forever/mus_c_day_jungle_3.mp3#8181263",
		"forever/mus_c_night_jungle_1.mp3#8181265",
		"forever/mus_c_night_jungle_2.mp3#8181267",
		"forever/mus_c_night_jungle_3.mp3#8181269",
		"forever/mus_c_cursed_land_4.mp3#8180744",
		"forever/mus_c_cursed_land_5.mp3#8180746",
		"forever/mus_c_cursed_land_6.mp3#8180748",

		"|cffffd800", "|cffffd800" .. "Ruins of Zul'Mamwe, Spirit Den",
		"forever/mus_c_mystery_3.mp3#8180937",
		"forever/mus_c_mystery_4.mp3#8180939",
		"forever/mus_c_mystery_10.mp3#8180951",
		"forever/mus_c_mystery_5.mp3#8180941",
		"forever/mus_c_mystery_2.mp3#8180935",
		"forever/mus_c_mystery_6.mp3#8180943",
		"forever/mus_c_mystery_7.mp3#8180945",
		"forever/mus_c_mystery_8.mp3#8180947",
		"forever/mus_c_mystery_9.mp3#8180949",
		"forever/mus_c_mystery_1.mp3#8180933",

		"|cffffd800", "|cffffd800" .. "Mosh'Ogg Ogre Mound",
		"forever/mus_c_day_volcanic_1.mp3#8181275",
		"forever/mus_c_day_volcanic_2.mp3#8181277",
		"forever/mus_c_night_volcanic_1.mp3#8181279",
		"forever/mus_c_night_volcanic_2.mp3#8181281",

		"|cffffd800", "|cffffd800" .. "The Stockpile, Crystalvein Mine",
		"forever/mus_c_soggy_place_zone_2.mp3#8181013",
		"forever/mus_c_soggy_place_zone_5.mp3#8181019",
		"forever/mus_c_soggy_place_zone_1.mp3#8181011",
		"forever/mus_c_soggy_place_zone_3.mp3#8181015",
		"forever/mus_c_soggy_place_zone_4.mp3#8181017",

		"|cffffd800", "|cffffd800" .. "Grom'gol Base Camp",
		"citymusic/orgrimmar/orgrimmar02-zone.mp3#53200",
		"forever/mus_c_day_barren_dry_3.mp3#8181053",
		"forever/mus_c_orgrimmar_1_zone.mp3#8181033",
		"forever/mus_c_thunder_bluff_walking_3.mp3#8181001",
		"forever/mus_c_orgrimmar_2_zone.mp3#8181037",

		"|cffffd800", "|cffffd800" .. "Yojamba Isle",
		"forever/mus_c_zulgurub_voodoo.mp3#8181341",

		"|cffffd800", "|cffffd800" .. "Sunken Hollow",
		"forever/mus_c_night_desert_1.mp3#8181133",
		"forever/mus_c_night_desert_2.mp3#8181135",
		"forever/mus_c_night_desert_3.mp3#8181137",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_battle_6.mp3#8180909",
		"forever/mus_c_stormwind_high_seas_moment.mp3#8180882",
	})

	Zn(L["Zones"], L["Eastern Kingdoms"], L["Swamp of Sorrows"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Swamp of Sorrows"], prefol,
		"|cffffd800", "|cffffd800" .. "Swamp of Sorrows",
		"forever/mus_c_soggy_place_zone_1.mp3#8181011",
		"forever/mus_c_soggy_place_zone_3.mp3#8181015",
		"forever/mus_c_soggy_place_zone_4.mp3#8181017",

		"|cffffd800", "|cffffd800" .. "Misty Valley",
		"forever/mus_c_mystery_3.mp3#8180937",
		"forever/mus_c_mystery_4.mp3#8180939",
		"forever/mus_c_mystery_10.mp3#8180951",
		"forever/mus_c_mystery_5.mp3#8180941",
		"forever/mus_c_mystery_2.mp3#8180935",
		"forever/mus_c_mystery_6.mp3#8180943",
		"forever/mus_c_mystery_7.mp3#8180945",
		"forever/mus_c_mystery_8.mp3#8180947",
		"forever/mus_c_mystery_9.mp3#8180949",
		"forever/mus_c_mystery_1.mp3#8180933",

		"|cffffd800", "|cffffd800" .. "Itharius's Cave",
		"forever/mus_c_cursed_land_4.mp3#8180744",
		"forever/mus_c_cursed_land_5.mp3#8180746",
		"forever/mus_c_cursed_land_6.mp3#8180748",

		"|cffffd800", "|cffffd800" .. "Stagalbog Cave",
		"forever/mus_c_night_evil_forest_1.mp3#8180758",
		"forever/mus_c_night_evil_forest_2.mp3#8180760",
		"forever/mus_c_night_evil_forest_3.mp3#8180762",
	})

	Zn(L["Zones"], L["Eastern Kingdoms"], L["Tirisfal Glades"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Tirisfal Glades"], prefol,
		"|cffffd800", "|cffffd800" .. "Tirisfal Glades",
		"forever/mus_c_day_evil_forest_1.mp3#8180772",
		"forever/mus_c_day_evil_forest_3.mp3#8180776",
		"forever/mus_c_night_evil_forest_1.mp3#8180758#1",
		"forever/mus_c_day_evil_forest_2.mp3#8180774",
		"forever/mus_c_night_evil_forest_2.mp3#8180760#1",
		"forever/mus_c_night_evil_forest_3.mp3#8180762#1",

		"|cffffd800", "|cffffd800" .. "Ruins of Lordaeron",
		"forever/mus_c_undercity_1.mp3#8181003",
		"forever/mus_c_undercity_2.mp3#8181005",
		"forever/mus_c_undercity_3.mp3#8181007",

		"|cffffd800", "|cffffd800" .. "Deathknell, Agamand Mills, Agamand Family Crypt, Brill, Balnir Farmstead, Shadow Grave, Bandarion Keep, Whispering Forest, Shadowvale",
		"forever/mus_c_haunted_1.mp3#8181313",

		"|cffffd800", "|cffffd800" .. "Night Web's Hollow",
		"forever/mus_c_night_evil_forest_1.mp3#8180758#2",
		"forever/mus_c_night_evil_forest_2.mp3#8180760#2",
		"forever/mus_c_night_evil_forest_3.mp3#8180762#2",

		"|cffffd800", "|cffffd800" .. "Venomweb Vale",
		"forever/mus_c_night_desert_1.mp3#8181133",
		"forever/mus_c_night_desert_2.mp3#8181135",
		"forever/mus_c_night_desert_3.mp3#8181137",

		"|cffffd800", "|cffffd800" .. "Gallows' End Tavern",
		"forever/mus_c_tavern_horde_3.mp3#8180991",
		"forever/mus_c_haunted_2.mp3#8181315",
	})

	Zn(L["Zones"], L["Eastern Kingdoms"], L["Undercity"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Undercity"], prefol,
		"|cffffd800", "|cffffd800" .. "Undercity",
		"forever/mus_c_undercity_1.mp3#8181003",
		"forever/mus_c_undercity_2.mp3#8181005",
		"forever/mus_c_undercity_3.mp3#8181007",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_undercity_intro_moment.mp3#8181009",
	})

	Zn(L["Zones"], L["Eastern Kingdoms"], L["Western Plaguelands"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Western Plaguelands"], prefol,
		"|cffffd800", "|cffffd800" .. "Western Plaguelands",
		"forever/mus_c_cursed_land_4.mp3#8180744",
		"forever/mus_c_cursed_land_5.mp3#8180746",
		"forever/mus_c_cursed_land_6.mp3#8180748",

		"|cffffd800", "|cffffd800" .. "Hearthglen, Mardenholde Keep",
		"forever/mus_c_cursed_land_1.mp3#8180738",
		"forever/mus_c_cursed_land_3.mp3#8180742",

		"|cffffd800", "|cffffd800" .. "Ruins of Andorhal, Uther's Tomb, Crypt, Scholomance",
		"forever/mus_c_haunted_1.mp3#8181313",

		"|cffffd800", "|cffffd800" .. "The Weeping Cave",
		"forever/mus_c_soggy_place_zone_2.mp3#8181013",
		"forever/mus_c_soggy_place_zone_5.mp3#8181019",
		"forever/mus_c_soggy_place_zone_1.mp3#8181011",
		"forever/mus_c_soggy_place_zone_3.mp3#8181015",
		"forever/mus_c_soggy_place_zone_4.mp3#8181017",

		"|cffffd800", "|cffffd800" .. "Felstone Field, Dalson's Tears, Gahrron's Withering, The Writhing Haunt",
		"forever/mus_c_day_volcanic_1.mp3#8181275",
		"forever/mus_c_day_volcanic_2.mp3#8181277",
		"forever/mus_c_night_volcanic_1.mp3#8181279",
		"forever/mus_c_night_volcanic_2.mp3#8181281",
	})

	Zn(L["Zones"], L["Eastern Kingdoms"], L["Westfall"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Westfall"], prefol,
		"|cffffd800", "|cffffd800" .. "Westfall",
		"forever/mus_c_night_plains_1.mp3#8181309",
		"forever/mus_c_day_plains_2.mp3#8181307",
		"forever/mus_c_night_plains_2.mp3#8181311",
		"forever/mus_c_day_plains_1.mp3#8181305",

		"|cffffd800", "|cffffd800" .. "Moonbrook",
		"forever/mus_c_mystery_3.mp3#8180937",
		"forever/mus_c_mystery_4.mp3#8180939",
		"forever/mus_c_mystery_10.mp3#8180951",
		"forever/mus_c_mystery_5.mp3#8180941",
		"forever/mus_c_mystery_2.mp3#8180935",
		"forever/mus_c_mystery_6.mp3#8180943",
		"forever/mus_c_mystery_7.mp3#8180945",
		"forever/mus_c_mystery_8.mp3#8180947",
		"forever/mus_c_mystery_9.mp3#8180949",
		"forever/mus_c_mystery_1.mp3#8180933",

		"|cffffd800", "|cffffd800" .. "Lighthouse",
		"forever/mus_c_night_barren_dry_1.mp3#8181055",
		"forever/mus_c_night_barren_dry_2.mp3#8181057",
		"forever/mus_c_day_barren_dry_2.mp3#8181051",
		"forever/mus_c_day_barren_dry_3.mp3#8181053",
		"forever/mus_c_night_barren_dry_3.mp3#8181059",
		"forever/mus_c_day_barren_dry_1.mp3#8181049",

		"|cffffd800", "|cffffd800" .. "Jangolode Mine",
		"forever/mus_c_night_evil_forest_1.mp3#8180758#1",
		"forever/mus_c_night_evil_forest_2.mp3#8180760#1",
		"forever/mus_c_night_evil_forest_3.mp3#8180762#1",

		"|cffffd800", "|cffffd800" .. "Gold Coast Quarry",
		"forever/mus_c_day_evil_forest_1.mp3#8180772",
		"forever/mus_c_day_evil_forest_3.mp3#8180776",
		"forever/mus_c_night_evil_forest_1.mp3#8180758#2",
		"forever/mus_c_day_evil_forest_2.mp3#8180774",
		"forever/mus_c_night_evil_forest_2.mp3#8180760#2",
		"forever/mus_c_night_evil_forest_3.mp3#8180762#2",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_spooky_1_moment.mp3#8181333",
	})

	Zn(L["Zones"], L["Eastern Kingdoms"], L["Wetlands"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Wetlands"], prefol,
		"|cffffd800", "|cffffd800" .. "Wetlands",
		"forever/mus_c_soggy_place_zone_2.mp3#8181013",
		"forever/mus_c_soggy_place_zone_5.mp3#8181019",
		"forever/mus_c_soggy_place_zone_1.mp3#8181011",
		"forever/mus_c_soggy_place_zone_3.mp3#8181015",
		"forever/mus_c_soggy_place_zone_4.mp3#8181017",

		"|cffffd800", "|cffffd800" .. "Wetlands, Whelgar's Excavation Site",
		"forever/mus_c_cursed_land_4.mp3#8180744",
		"forever/mus_c_cursed_land_5.mp3#8180746",
		"forever/mus_c_cursed_land_6.mp3#8180748",

		"|cffffd800", "|cffffd800" .. "Whelgar's Excavation Site, Menethil Harbor, Dun Modr",
		"forever/mus_c_night_forest_1.mp3#8180764",
		"forever/mus_c_night_forest_2.mp3#8180766",
		"forever/mus_c_night_forest_3.mp3#8180768",
		"forever/mus_c_night_forest_4.mp3#8180770",

		"|cffffd800", "|cffffd800" .. "Dun Modr, Lion's Pride Inn, Deepwater Tavern",
		"forever/mus_c_tavern_alliance_1.mp3#8180983",
		"forever/mus_c_tavern_alliance_2.mp3#8180985",

		"|cffffd800", "|cffffd800" .. "Dun Modr, Baradin Bay, Menethil Keep",
		"forever/mus_c_day_jungle_1.mp3#8181259",
		"forever/mus_c_day_jungle_2.mp3#8181261",
		"forever/mus_c_day_jungle_3.mp3#8181263",
		"forever/mus_c_night_jungle_1.mp3#8181265",
		"forever/mus_c_night_jungle_2.mp3#8181267",
		"forever/mus_c_night_jungle_3.mp3#8181269",

		"|cffffd800", "|cffffd800" .. "Dun Modr, Thelgen Rock, Sundown Marsh",
		"forever/mus_c_mystery_3.mp3#8180937",
		"forever/mus_c_mystery_4.mp3#8180939",
		"forever/mus_c_mystery_10.mp3#8180951",
		"forever/mus_c_mystery_5.mp3#8180941",
		"forever/mus_c_mystery_2.mp3#8180935",
		"forever/mus_c_mystery_6.mp3#8180943",
		"forever/mus_c_mystery_7.mp3#8180945",
		"forever/mus_c_mystery_8.mp3#8180947",
		"forever/mus_c_mystery_9.mp3#8180949",
		"forever/mus_c_mystery_1.mp3#8180933",

		"|cffffd800", "|cffffd800" .. "Ironbeard's Tomb",
		"forever/mus_c_haunted_1.mp3#8181313",

		"|cffffd800", "|cffffd800" .. "Deepwater Tavern",
		"forever/mus_c_haunted_2.mp3#8181315",

		"|cffffd800", "|cffffd800" .. "Excavation Site: Wetlands",
		"forever/mus_c60_dungeons_wetlands_a.mp3#8270379",
		"forever/mus_c60_dungeons_wetlands_b.mp3#8270381",
		"forever/mus_c60_dungeons_wetlands_c.mp3#8270383",
		"forever/mus_c60_dungeons_wetlands_d.mp3#8270385",

		"|cffffd800", "|cffffd800" .. "The Drunken Dwarf",
		"forever/mus_c_dwarves_tavern_1a.mp3#8195263",
		"forever/mus_c_dwarves_tavern_1b.mp3#8195265",
		"forever/mus_c_dwarves_tavern_2a.mp3#8195267",
		"forever/mus_c_dwarves_tavern_2b.mp3#8195269",
		"forever/mus_c_dwarves_tavern_3.mp3#8195271",
	})

	----------------------------------------------------------------------
	-- Zones: Kalimdor
	----------------------------------------------------------------------

	Zn(L["Zones"], L["Kalimdor"], "|cffffd800", {""})
	Zn(L["Zones"], L["Kalimdor"], "|cffffd800" .. L["Kalimdor"], {""})

	Zn(L["Zones"], L["Kalimdor"], L["Ashenvale"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Ashenvale"], prefol,
		"|cffffd800", "|cffffd800" .. "Ashenvale",
		"forever/mus_c_enchanted_forest_5.mp3#8180792",
		"forever/mus_c_enchanted_forest_1.mp3#8180784",
		"forever/mus_c_enchanted_forest_4.mp3#8180790",
		"forever/mus_c_enchanted_forest_2.mp3#8180786",
		"forever/mus_c_enchanted_forest_3.mp3#8180788",

		"|cffffd800", "|cffffd800" .. "Blackfathom Deeps, The Zoram Strand",
		"forever/mus_c_day_desert_1.mp3#8181127",
		"forever/mus_c_day_desert_2.mp3#8181129",
		"forever/mus_c_day_desert_3.mp3#8181131",
		"forever/mus_c_night_desert_1.mp3#8181133",
		"forever/mus_c_night_desert_2.mp3#8181135",
		"forever/mus_c_night_desert_3.mp3#8181137",

		"|cffffd800", "|cffffd800" .. "Bathran's Haunt, The Ruins of Ordil'Aran, The Dor'Danil Barrow Den",
		"forever/mus_c_cursed_land_4.mp3#8180744",
		"forever/mus_c_cursed_land_5.mp3#8180746",
		"forever/mus_c_cursed_land_6.mp3#8180748",

		"|cffffd800", "|cffffd800" .. "The Shrine of Aessina, Moonwell",
		"forever/mus_c_magic_1_zone_2.mp3#8180957",
		"forever/mus_c_magic_1_zone_1.mp3#8180955",

		"|cffffd800", "|cffffd800" .. "Fire Scar Shrine, The Ruins of Stardust, Felfire Hill, Demon Fall Canyon, Demon Fall Ridge",
		"forever/mus_c_cursed_land_1.mp3#8180738",
		"forever/mus_c_cursed_land_3.mp3#8180742#1",

		"|cffffd800", "|cffffd800" .. "The Howling Vale, The Shady Nook",
		"forever/mus_c_mystery_3.mp3#8180937",
		"forever/mus_c_mystery_4.mp3#8180939",
		"forever/mus_c_mystery_10.mp3#8180951",
		"forever/mus_c_mystery_5.mp3#8180941",
		"forever/mus_c_mystery_2.mp3#8180935",
		"forever/mus_c_mystery_6.mp3#8180943",
		"forever/mus_c_mystery_7.mp3#8180945",
		"forever/mus_c_mystery_8.mp3#8180947",
		"forever/mus_c_mystery_9.mp3#8180949",
		"forever/mus_c_mystery_1.mp3#8180933",

		"|cffffd800", "|cffffd800" .. "Iris Lake, The Dor'Danil Barrow Den, Demon Fall Ridge, Thistlefur Village",
		"forever/mus_c_cursed_land_2.mp3#8180740",
		"forever/mus_c_cursed_land_3.mp3#8180742#2",

		"|cffffd800", "|cffffd800" .. "Raynewood Retreat, Solace Glade",
		"forever/mus_c_darnasssus_walking_1.mp3#8180752",
		"forever/mus_c_darnasssus_walking_2.mp3#8180754",
		"forever/mus_c_darnasssus_walking_3.mp3#8180756",

		"|cffffd800", "|cffffd800" .. "Night Run, Xavian, Satyrnaar",
		"forever/mus_c_day_jungle_1.mp3#8181259",
		"forever/mus_c_day_jungle_2.mp3#8181261",
		"forever/mus_c_day_jungle_3.mp3#8181263",
		"forever/mus_c_night_jungle_1.mp3#8181265",
		"forever/mus_c_night_jungle_2.mp3#8181267",
		"forever/mus_c_night_jungle_3.mp3#8181269",

		"|cffffd800", "|cffffd800" .. "Splintertree Post, Warsong Lumber Camp, Kargathia Keep",
		"citymusic/orgrimmar/orgrimmar02-zone.mp3#53200",
		"forever/mus_c_day_barren_dry_3.mp3#8181053",
		"forever/mus_c_orgrimmar_1_zone.mp3#8181033",
		"forever/mus_c_thunder_bluff_walking_3.mp3#8181001",
		"forever/mus_c_orgrimmar_2_zone.mp3#8181037",

		"|cffffd800", "|cffffd800" .. "Bough Shadow, Forest Song",
		"forever/mus_c_warrior_terrace.mp3#8181337",

		"|cffffd800", "|cffffd800" .. "Kargathia Keep",
		"forever/mus_c_battle_6.mp3#8180909",

		"|cffffd800", "|cffffd800" .. "Zoram'gar Outpost",
		"forever/mus_c_tavern_horde_1.mp3#8180987",
		"forever/mus_c_tavern_horde_2.mp3#8180989",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_angelic_1.mp3#8181319",
		"forever/mus_c_swamp_1.mp3#8181335",
		"forever/mus_c_battle_3.mp3#8180903",
	})

	Zn(L["Zones"], L["Kalimdor"], L["Azshara"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Azshara"], prefol,
		"|cffffd800", "|cffffd800" .. "Azshara",
		"forever/mus_c_cursed_land_4.mp3#8180744",
		"forever/mus_c_cursed_land_5.mp3#8180746",
		"forever/mus_c_cursed_land_6.mp3#8180748",

		"|cffffd800", "|cffffd800" .. "Southfury River",
		"forever/mus_c_day_mountain_1.mp3#8181287",
		"forever/mus_c_day_mountain_2.mp3#8181289",
		"forever/mus_c_day_mountain_3.mp3#8181291",
		"forever/mus_c_night_mountain_3.mp3#8181297",
		"forever/mus_c_night_mountain_4.mp3#8181299",
		"forever/mus_c_night_mountain_1.mp3#8181293",
		"forever/mus_c_night_mountain_2.mp3#8181295",

		"|cffffd800", "|cffffd800" .. "Blackmaw Hold, Ruins of Eldarath, Hetaera's Clutch, Temple of Arkkoran, Bay of Storms, The Shattered Strand, Tower of Eldara, Jagged Reef, Southridge Beach, Ravencrest Monument, The Ruined Reaches",
		"forever/mus_c_day_desert_1.mp3#8181127",
		"forever/mus_c_day_desert_2.mp3#8181129",
		"forever/mus_c_day_desert_3.mp3#8181131",
		"forever/mus_c_night_desert_1.mp3#8181133#1",
		"forever/mus_c_night_desert_2.mp3#8181135#1",
		"forever/mus_c_night_desert_3.mp3#8181137#1",

		"|cffffd800", "|cffffd800" .. "Thalassian Base Camp",
		"forever/mus_c_darnasssus_walking_1.mp3#8180752",
		"forever/mus_c_darnasssus_walking_2.mp3#8180754",
		"forever/mus_c_darnasssus_walking_3.mp3#8180756",

		"|cffffd800", "|cffffd800" .. "Hetaera's Clutch, Temple of Zin-Malor, Shadowsong Shrine",
		"forever/mus_c_haunted_1.mp3#8181313",

		"|cffffd800", "|cffffd800" .. "Temple of Arkkoran",
		"forever/mus_c_mystery_3.mp3#8180937",
		"forever/mus_c_mystery_4.mp3#8180939",
		"forever/mus_c_mystery_10.mp3#8180951",
		"forever/mus_c_mystery_5.mp3#8180941",
		"forever/mus_c_mystery_2.mp3#8180935",
		"forever/mus_c_mystery_6.mp3#8180943",
		"forever/mus_c_mystery_7.mp3#8180945",
		"forever/mus_c_mystery_8.mp3#8180947",
		"forever/mus_c_mystery_9.mp3#8180949",
		"forever/mus_c_mystery_1.mp3#8180933",

		"|cffffd800", "|cffffd800" .. "Forlorn Ridge",
		"forever/mus_c_battle_5.mp3#8180907",
		"forever/mus_c_night_desert_1.mp3#8181133#2",
		"forever/mus_c_night_desert_2.mp3#8181135#2",
		"forever/mus_c_night_desert_3.mp3#8181137#2",

		"|cffffd800", "|cffffd800" .. "Haldarr Encampment",
		"forever/mus_c_day_jungle_1.mp3#8181259",
		"forever/mus_c_day_jungle_2.mp3#8181261",
		"forever/mus_c_day_jungle_3.mp3#8181263",
		"forever/mus_c_night_jungle_1.mp3#8181265",
		"forever/mus_c_night_jungle_2.mp3#8181267",
		"forever/mus_c_night_jungle_3.mp3#8181269",

		"|cffffd800", "|cffffd800" .. "Valormok",
		"citymusic/orgrimmar/orgrimmar02-zone.mp3#53200",
		"forever/mus_c_day_barren_dry_3.mp3#8181053",
		"forever/mus_c_orgrimmar_1_zone.mp3#8181033",
		"forever/mus_c_thunder_bluff_walking_3.mp3#8181001",
		"forever/mus_c_orgrimmar_2_zone.mp3#8181037",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_gloomy_1.mp3#8181325",
		"forever/mus_c_battle_3.mp3#8180903",
		"forever/mus_c_swamp_1.mp3#8181335",
	})

	Zn(L["Zones"], L["Kalimdor"], L["Barrens"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Barrens"], prefol,
		"|cffffd800", "|cffffd800" .. "The Barrens",
		"forever/mus_c_night_barren_dry_1.mp3#8181055",
		"forever/mus_c_night_barren_dry_2.mp3#8181057",
		"forever/mus_c_day_barren_dry_2.mp3#8181051",
		"forever/mus_c_day_barren_dry_3.mp3#8181053#1",
		"forever/mus_c_night_barren_dry_3.mp3#8181059",
		"forever/mus_c_day_barren_dry_1.mp3#8181049",

		"|cffffd800", "|cffffd800" .. "Camp Taurajo",
		"forever/mus_c_thunder_bluff_walking_1.mp3#8180997",
		"forever/mus_c_thunder_bluff_walking_2.mp3#8180999",
		"forever/mus_c_thunder_bluff_walking_3.mp3#8181001#1",

		"|cffffd800", "|cffffd800" .. "The Crossroads",
		"citymusic/orgrimmar/orgrimmar02-zone.mp3#53200",
		"forever/mus_c_day_barren_dry_3.mp3#8181053#2",
		"forever/mus_c_orgrimmar_1_zone.mp3#8181033",
		"forever/mus_c_thunder_bluff_walking_3.mp3#8181001#2",
		"forever/mus_c_orgrimmar_2_zone.mp3#8181037",

		"|cffffd800", "|cffffd800" .. "Boulder Lode Mine",
		"forever/mus_c_battle_6.mp3#8180909",

		"|cffffd800", "|cffffd800" .. "The Sludge Fen, Northwatch Hold, The Forgotten Pools, Lushwater Oasis, The Stagnant Oasis, The Merchant Coast, Ratchet, The Tidus Stair, Fray Island",
		"forever/mus_c_day_jungle_1.mp3#8181259",
		"forever/mus_c_day_jungle_2.mp3#8181261",
		"forever/mus_c_day_jungle_3.mp3#8181263",
		"forever/mus_c_night_jungle_1.mp3#8181265",
		"forever/mus_c_night_jungle_2.mp3#8181267",
		"forever/mus_c_night_jungle_3.mp3#8181269",

		"|cffffd800", "|cffffd800" .. "Dreadmist Peak, Dreadmist Den",
		"forever/mus_c_day_volcanic_1.mp3#8181275",
		"forever/mus_c_day_volcanic_2.mp3#8181277",
		"forever/mus_c_night_volcanic_1.mp3#8181279",
		"forever/mus_c_night_volcanic_2.mp3#8181281",

		"|cffffd800", "|cffffd800" .. "Ratchet",
		"forever/mus_c_tavern_alliance_1.mp3#8180983",
		"forever/mus_c_tavern_alliance_2.mp3#8180985",

		"|cffffd800", "|cffffd800" .. "Razorfen Downs",
		"forever/mus_c_day_desert_1.mp3#8181127",
		"forever/mus_c_day_desert_2.mp3#8181129",
		"forever/mus_c_day_desert_3.mp3#8181131",
		"forever/mus_c_night_desert_1.mp3#8181133",
		"forever/mus_c_night_desert_2.mp3#8181135",
		"forever/mus_c_night_desert_3.mp3#8181137",
		"forever/mus_c_undercity_1.mp3#8181003",
		"forever/mus_c_undercity_2.mp3#8181005",
		"forever/mus_c_undercity_3.mp3#8181007",

		"|cffffd800", "|cffffd800" .. "The Bone Pile",
		"forever/mus_c_undead_dance.mp3#8180993",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_battle_3.mp3#8180903",
		"forever/mus_c_swamp_1.mp3#8181335",
	})

	Zn(L["Zones"], L["Kalimdor"], L["Darkshore"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Darkshore"], prefol,
		"|cffffd800", "|cffffd800" .. "Darkshore",
		"forever/mus_c_night_forest_1.mp3#8180764",
		"forever/mus_c_night_forest_2.mp3#8180766",
		"forever/mus_c_night_forest_3.mp3#8180768",
		"forever/mus_c_night_forest_4.mp3#8180770",

		"|cffffd800", "|cffffd800" .. "Darkshore, Tower of Althalaxx",
		"forever/mus_c_cursed_land_4.mp3#8180744",
		"forever/mus_c_cursed_land_5.mp3#8180746",
		"forever/mus_c_cursed_land_6.mp3#8180748",

		"|cffffd800", "|cffffd800" .. "Ruins of Mathystra",
		"forever/mus_c_day_desert_1.mp3#8181127",
		"forever/mus_c_day_desert_2.mp3#8181129",
		"forever/mus_c_day_desert_3.mp3#8181131",
		"forever/mus_c_night_desert_1.mp3#8181133",
		"forever/mus_c_night_desert_2.mp3#8181135",
		"forever/mus_c_night_desert_3.mp3#8181137",

		"|cffffd800", "|cffffd800" .. "Ameth'Aran",
		"forever/mus_c_haunted_1.mp3#8181313",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_angelic_1.mp3#8181319",
		"forever/mus_c_gloomy_1.mp3#8181325",
	})

	Zn(L["Zones"], L["Kalimdor"], L["Darnassus"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Darnassus"], prefol,
		"|cffffd800", "|cffffd800" .. "Darnassus",
		"forever/mus_c_darnasssus_walking_1.mp3#8180752",
		"forever/mus_c_darnasssus_walking_2.mp3#8180754",
		"forever/mus_c_darnasssus_walking_3.mp3#8180756",

		"|cffffd800", "|cffffd800" .. "Temple of the Moon",
		"forever/mus_c_magic_1_zone_2.mp3#8180957",
		"forever/mus_c_magic_1_zone_1.mp3#8180955",

		"|cffffd800", "|cffffd800" .. "Cenarion Enclave",
		"forever/mus_c_warrior_terrace.mp3#8181337",
		"forever/mus_c_druid_grove.mp3#8181323#1",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_darnasssus_intro.mp3#8180750",
		"forever/mus_c_druid_grove.mp3#8181323#2",
	})

	Zn(L["Zones"], L["Kalimdor"], L["Desolace"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Desolace"], prefol,
		"|cffffd800", "|cffffd800" .. "Desolace",
		"forever/mus_c_day_desert_1.mp3#8181127",
		"forever/mus_c_day_desert_2.mp3#8181129",
		"forever/mus_c_day_desert_3.mp3#8181131",
		"forever/mus_c_night_desert_1.mp3#8181133",
		"forever/mus_c_night_desert_2.mp3#8181135",
		"forever/mus_c_night_desert_3.mp3#8181137",

		"|cffffd800", "|cffffd800" .. "Kodo Graveyard, Bolgan's Hole, Magram Village, Gelkis Village, Valley of Spears, Kolkar Village, Kormek's Hut",
		"forever/mus_c_night_barren_dry_1.mp3#8181055",
		"forever/mus_c_night_barren_dry_2.mp3#8181057",
		"forever/mus_c_day_barren_dry_2.mp3#8181051",
		"forever/mus_c_day_barren_dry_3.mp3#8181053#1",
		"forever/mus_c_night_barren_dry_3.mp3#8181059",
		"forever/mus_c_day_barren_dry_1.mp3#8181049",

		"|cffffd800", "|cffffd800" .. "Ghost Walker Post, Scrabblescrew's Camp",
		"forever/mus_c_thunder_bluff_walking_1.mp3#8180997",
		"forever/mus_c_thunder_bluff_walking_2.mp3#8180999",
		"forever/mus_c_thunder_bluff_walking_3.mp3#8181001",

		"|cffffd800", "|cffffd800" .. "Sar'theris Strand, Ethel Rethor",
		"forever/mus_c_soggy_place_zone_2.mp3#8181013",
		"forever/mus_c_soggy_place_zone_5.mp3#8181019",
		"forever/mus_c_soggy_place_zone_1.mp3#8181011",
		"forever/mus_c_soggy_place_zone_3.mp3#8181015",
		"forever/mus_c_soggy_place_zone_4.mp3#8181017",

		"|cffffd800", "|cffffd800" .. "Thunder Axe Fortress, Mannoroc Coven",
		"forever/mus_c_cursed_land_1.mp3#8180738",
		"forever/mus_c_cursed_land_3.mp3#8180742",

		"|cffffd800", "|cffffd800" .. "Thunder Axe Fortress",
		"forever/mus_c_battle_6.mp3#8180909",
		"forever/mus_c_battle_5.mp3#8180907",

		"|cffffd800", "|cffffd800" .. "Bolgan's Hole",
		"forever/mus_c_night_evil_forest_1.mp3#8180758",
		"forever/mus_c_night_evil_forest_2.mp3#8180760",
		"forever/mus_c_night_evil_forest_3.mp3#8180762",

		"|cffffd800", "|cffffd800" .. "Sargeron",
		"forever/mus_c_darnasssus_walking_1.mp3#8180752",
		"forever/mus_c_darnasssus_walking_2.mp3#8180754",
		"forever/mus_c_darnasssus_walking_3.mp3#8180756",

		"|cffffd800", "|cffffd800" .. "Nijel's Point",
		"forever/mus_c_gloomy_1.mp3#8181325",

		"|cffffd800", "|cffffd800" .. "Shadowbreak Ravine",
		"forever/mus_c_day_barren_dry_3.mp3#8181053#2",
		"forever/mus_c_mystery_3.mp3#8180937",
		"forever/mus_c_mystery_4.mp3#8180939",
		"forever/mus_c_mystery_10.mp3#8180951",
		"forever/mus_c_mystery_5.mp3#8180941",
		"forever/mus_c_mystery_2.mp3#8180935",
		"forever/mus_c_mystery_6.mp3#8180943",
		"forever/mus_c_mystery_7.mp3#8180945",
		"forever/mus_c_mystery_8.mp3#8180947",
		"forever/mus_c_mystery_9.mp3#8180949",
		"forever/mus_c_mystery_1.mp3#8180933",

		"|cffffd800", "|cffffd800" .. "Shadowprey Village",
		"forever/mus_c_tavern_horde_1.mp3#8180987",
		"forever/mus_c_tavern_horde_2.mp3#8180989",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_battle_3.mp3#8180903",
		"forever/mus_c_druid_grove.mp3#8181323",
	})

	Zn(L["Zones"], L["Kalimdor"], L["Durotar"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Durotar"], prefol,
		"|cffffd800", "|cffffd800" .. "Durotar",
		"forever/mus_c_night_plains_1.mp3#8181309",
		"forever/mus_c_day_plains_2.mp3#8181307",
		"forever/mus_c_night_plains_2.mp3#8181311",
		"forever/mus_c_day_plains_1.mp3#8181305",

		"|cffffd800", "|cffffd800" .. "Burning Blade Coven, Echo Isles, Skull Rock",
		"forever/mus_c_day_jungle_1.mp3#8181259",
		"forever/mus_c_day_jungle_2.mp3#8181261",
		"forever/mus_c_day_jungle_3.mp3#8181263",
		"forever/mus_c_night_jungle_1.mp3#8181265",
		"forever/mus_c_night_jungle_2.mp3#8181267",
		"forever/mus_c_night_jungle_3.mp3#8181269",

		"|cffffd800", "|cffffd800" .. "Sen'jin Village",
		"forever/mus_c_tavern_horde_1.mp3#8180987",
		"forever/mus_c_tavern_horde_2.mp3#8180989",

		"|cffffd800", "|cffffd800" .. "Dustwind Cave",
		"forever/mus_c_night_desert_1.mp3#8181133",
		"forever/mus_c_night_desert_2.mp3#8181135",
		"forever/mus_c_night_desert_3.mp3#8181137",

		"|cffffd800", "|cffffd800" .. "Tiragarde Keep",
		"forever/mus_c_stormwind_8.mp3#8180880",

		"|cffffd800", "|cffffd800" .. "Orgrimmar UNUSED",
		"forever/mus_c_orgrimmar_2_zone.mp3#8181037",
		"forever/mus_c_orgrimmar_1_zone.mp3#8181033",

		"|cffffd800", "|cffffd800" .. "Razor Hill Barracks",
		"forever/mus_c_mystery_3.mp3#8180937",
		"forever/mus_c_mystery_4.mp3#8180939",
		"forever/mus_c_mystery_10.mp3#8180951",
		"forever/mus_c_mystery_5.mp3#8180941",
		"forever/mus_c_mystery_2.mp3#8180935",
		"forever/mus_c_mystery_6.mp3#8180943",
		"forever/mus_c_mystery_7.mp3#8180945",
		"forever/mus_c_mystery_8.mp3#8180947",
		"forever/mus_c_mystery_9.mp3#8180949",
		"forever/mus_c_mystery_1.mp3#8180933",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_day_barren_dry_3.mp3#8181053",
		"forever/mus_c_battle_3.mp3#8180903",
		"forever/mus_c_orgrimmar_intro_moment.mp3#8181039",
	})

	Zn(L["Zones"], L["Kalimdor"], L["Dustwallow Marsh"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Dustwallow Marsh"], prefol,
		"|cffffd800", "|cffffd800" .. "Dustwallow Marsh",
		"forever/mus_c_soggy_place_zone_2.mp3#8181013",
		"forever/mus_c_soggy_place_zone_5.mp3#8181019",
		"forever/mus_c_soggy_place_zone_1.mp3#8181011",
		"forever/mus_c_soggy_place_zone_3.mp3#8181015",
		"forever/mus_c_soggy_place_zone_4.mp3#8181017",

		"|cffffd800", "|cffffd800" .. "Brackenwall Village",
		"forever/mus_c_orgrimmar_2_zone.mp3#8181037",

		"|cffffd800", "|cffffd800" .. "Darkmist Cavern",
		"forever/mus_c_night_evil_forest_1.mp3#8180758",
		"forever/mus_c_night_evil_forest_2.mp3#8180760",
		"forever/mus_c_night_evil_forest_3.mp3#8180762",

		"|cffffd800", "|cffffd800" .. "Beezil's Wreck, Alcaz Island",
		"forever/mus_c_day_jungle_1.mp3#8181259",
		"forever/mus_c_day_jungle_2.mp3#8181261",
		"forever/mus_c_day_jungle_3.mp3#8181263",
		"forever/mus_c_night_jungle_1.mp3#8181265",
		"forever/mus_c_night_jungle_2.mp3#8181267",
		"forever/mus_c_night_jungle_3.mp3#8181269",

		"|cffffd800", "|cffffd800" .. "Sentry Point, North Point Tower, Lost Point",
		"forever/mus_c_night_forest_1.mp3#8180764",
		"forever/mus_c_night_forest_2.mp3#8180766",
		"forever/mus_c_night_forest_3.mp3#8180768",
		"forever/mus_c_night_forest_4.mp3#8180770",

		"|cffffd800", "|cffffd800" .. "The Den of Flame",
		"forever/mus_c_day_volcanic_1.mp3#8181275",
		"forever/mus_c_day_volcanic_2.mp3#8181277",
		"forever/mus_c_night_volcanic_1.mp3#8181279",
		"forever/mus_c_night_volcanic_2.mp3#8181281",

		"|cffffd800", "|cffffd800" .. "Theramore Isle, Foothold Citadel",
		"forever/mus_c_stormwind_5.mp3#8180874",
		"forever/mus_c_stormwind_6.mp3#8180876",
		"forever/mus_c_stormwind_7.mp3#8180878",
		"forever/mus_c_stormwind_8.mp3#8180880",
		"forever/mus_c_stormwind_1.mp3#8180866",
		"forever/mus_c_stormwind_3.mp3#8180870",
		"forever/mus_c_stormwind_4.mp3#8180872",
		"forever/mus_c_stormwind_2.mp3#8180868",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_ironforge_walking_2.mp3#8180967",
	})

	Zn(L["Zones"], L["Kalimdor"], L["Felwood"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Felwood"], prefol,
		"|cffffd800", "|cffffd800" .. "Felwood",
		"forever/mus_c_cursed_land_1.mp3#8180738",
		"forever/mus_c_cursed_land_3.mp3#8180742#1",

		"|cffffd800", "|cffffd800" .. "Deadwood Village, Felpaw Village",
		"forever/mus_c_cursed_land_2.mp3#8180740",
		"forever/mus_c_cursed_land_3.mp3#8180742#2",

		"|cffffd800", "|cffffd800" .. "Irontree Cavern",
		"forever/mus_c_night_evil_forest_1.mp3#8180758#1",
		"forever/mus_c_night_evil_forest_2.mp3#8180760#1",
		"forever/mus_c_night_evil_forest_3.mp3#8180762#1",

		"|cffffd800", "|cffffd800" .. "Timbermaw Hold, Shadow Hold",
		"forever/mus_c_soggy_place_zone_2.mp3#8181013",
		"forever/mus_c_soggy_place_zone_5.mp3#8181019",
		"forever/mus_c_soggy_place_zone_1.mp3#8181011",
		"forever/mus_c_soggy_place_zone_3.mp3#8181015",
		"forever/mus_c_soggy_place_zone_4.mp3#8181017",

		"|cffffd800", "|cffffd800" .. "Shrine of the Deceiver",
		"forever/mus_c_day_evil_forest_1.mp3#8180772",
		"forever/mus_c_day_evil_forest_3.mp3#8180776",
		"forever/mus_c_night_evil_forest_1.mp3#8180758#2",
		"forever/mus_c_day_evil_forest_2.mp3#8180774",
		"forever/mus_c_night_evil_forest_2.mp3#8180760#2",
		"forever/mus_c_night_evil_forest_3.mp3#8180762#2",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_haunted_2.mp3#8181315",
		"forever/mus_c_battle_6.mp3#8180909",
		"forever/mus_c_battle_5.mp3#8180907",
	})

	Zn(L["Zones"], L["Kalimdor"], L["Feralas"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Feralas"], prefol,
		"|cffffd800", "|cffffd800" .. "Feralas",
		"forever/mus_c_day_jungle_1.mp3#8181259",
		"forever/mus_c_day_jungle_2.mp3#8181261",
		"forever/mus_c_day_jungle_3.mp3#8181263",
		"forever/mus_c_night_jungle_1.mp3#8181265",
		"forever/mus_c_night_jungle_2.mp3#8181267",
		"forever/mus_c_night_jungle_3.mp3#8181269",

		"|cffffd800", "|cffffd800" .. "Camp Mojache",
		"forever/mus_c_thunder_bluff_walking_1.mp3#8180997",
		"forever/mus_c_thunder_bluff_walking_2.mp3#8180999",
		"forever/mus_c_thunder_bluff_walking_3.mp3#8181001",

		"|cffffd800", "|cffffd800" .. "The Writhing Deep",
		"forever/mus_c_day_desert_1.mp3#8181127",
		"forever/mus_c_day_desert_2.mp3#8181129",
		"forever/mus_c_day_desert_3.mp3#8181131",
		"forever/mus_c_night_desert_1.mp3#8181133#1",
		"forever/mus_c_night_desert_2.mp3#8181135#1",
		"forever/mus_c_night_desert_3.mp3#8181137#1",

		"|cffffd800", "|cffffd800" .. "Feral Scar Vale, Ruins of Isildien",
		"forever/mus_c_mystery_3.mp3#8180937",
		"forever/mus_c_mystery_4.mp3#8180939",
		"forever/mus_c_mystery_10.mp3#8180951",
		"forever/mus_c_mystery_5.mp3#8180941",
		"forever/mus_c_mystery_2.mp3#8180935",
		"forever/mus_c_mystery_6.mp3#8180943",
		"forever/mus_c_mystery_7.mp3#8180945",
		"forever/mus_c_mystery_8.mp3#8180947",
		"forever/mus_c_mystery_9.mp3#8180949",
		"forever/mus_c_mystery_1.mp3#8180933",

		"|cffffd800", "|cffffd800" .. "Feral Scar Vale, Rage Scar Hold",
		"forever/mus_c_soggy_place_zone_2.mp3#8181013",
		"forever/mus_c_soggy_place_zone_5.mp3#8181019",
		"forever/mus_c_soggy_place_zone_1.mp3#8181011",
		"forever/mus_c_soggy_place_zone_3.mp3#8181015",
		"forever/mus_c_soggy_place_zone_4.mp3#8181017",

		"|cffffd800", "|cffffd800" .. "Isle of Dread, Shalzaru's Lair",
		"forever/mus_c_night_desert_1.mp3#8181133#2",
		"forever/mus_c_night_desert_2.mp3#8181135#2",
		"forever/mus_c_night_desert_3.mp3#8181137#2",

		"|cffffd800", "|cffffd800" .. "High Wilderness",
		"forever/mus_c_day_volcanic_1.mp3#8181275",
		"forever/mus_c_day_volcanic_2.mp3#8181277",
		"forever/mus_c_night_volcanic_1.mp3#8181279",
		"forever/mus_c_night_volcanic_2.mp3#8181281",

		"|cffffd800", "|cffffd800" .. "Lower Wilds, Woodpaw Den",
		"forever/mus_c_cursed_land_4.mp3#8180744",
		"forever/mus_c_cursed_land_5.mp3#8180746",
		"forever/mus_c_cursed_land_6.mp3#8180748",

		"|cffffd800", "|cffffd800" .. "Lariss Pavilion, Dire Maul, Eldreth Row, Broken Commons",
		"forever/mus_c_enchanted_forest_5.mp3#8180792",
		"forever/mus_c_enchanted_forest_1.mp3#8180784",
		"forever/mus_c_enchanted_forest_4.mp3#8180790",
		"forever/mus_c_enchanted_forest_2.mp3#8180786",
		"forever/mus_c_enchanted_forest_3.mp3#8180788",

		"|cffffd800", "|cffffd800" .. "Dire Maul",
		"forever/mus_c_spooky_1_moment.mp3#8181333",
		"forever/mus_c_gloomy_1.mp3#8181325",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_angelic_1.mp3#8181319",
	})

	Zn(L["Zones"], L["Kalimdor"], L["Moonglade"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Moonglade"], prefol,
		"|cffffd800", "|cffffd800" .. "Moonglade",
		"forever/mus_c_night_forest_1.mp3#8180764",
		"forever/mus_c_night_forest_2.mp3#8180766",
		"forever/mus_c_night_forest_3.mp3#8180768",
		"forever/mus_c_night_forest_4.mp3#8180770",

		"|cffffd800", "|cffffd800" .. "Stormrage Barrow Dens",
		"forever/mus_c_day_evil_forest_1.mp3#8180772",
		"forever/mus_c_day_evil_forest_3.mp3#8180776",
		"forever/mus_c_night_evil_forest_1.mp3#8180758",
		"forever/mus_c_day_evil_forest_2.mp3#8180774",
		"forever/mus_c_night_evil_forest_2.mp3#8180760",
		"forever/mus_c_night_evil_forest_3.mp3#8180762",
		"forever/mus_c_cursed_land_2.mp3#8180740",
		"forever/mus_c_cursed_land_3.mp3#8180742",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_magic_1_moment.mp3#8180953",
	})

	Zn(L["Zones"], L["Kalimdor"], L["Mount Hyjal"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Mount Hyjal"], prefol,
		"|cffffd800", "|cffffd800" .. "Mount Hyjal",
		"forever/mus_c60_hyjal_general_a.mp3#8158670",
		"forever/mus_c60_hyjal_general_b.mp3#8158672",
		"forever/mus_c60_hyjal_general_c.mp3#8158674",
		"forever/mus_c60_hyjal_general_d.mp3#8173713",

		"|cffffd800", "|cffffd800" .. "Barkskin Burrow",
		"forever/mus_c_mystery_3.mp3#8180937",
		"forever/mus_c_mystery_4.mp3#8180939",
		"forever/mus_c_mystery_10.mp3#8180951",
		"forever/mus_c_mystery_5.mp3#8180941",
		"forever/mus_c_mystery_2.mp3#8180935",
		"forever/mus_c_mystery_6.mp3#8180943",
		"forever/mus_c_mystery_7.mp3#8180945",
		"forever/mus_c_mystery_8.mp3#8180947",
		"forever/mus_c_mystery_9.mp3#8180949",
		"forever/mus_c_mystery_1.mp3#8180933",

		"|cffffd800", "|cffffd800" .. "Deadwood Den",
		"forever/mus_c_cursed_land_4.mp3#8180744",
		"forever/mus_c_cursed_land_5.mp3#8180746",
		"forever/mus_c_cursed_land_6.mp3#8180748",
		"forever/mus_c_cursed_land_2.mp3#8180740",
		"forever/mus_c_cursed_land_3.mp3#8180742",

		"|cffffd800", "|cffffd800" .. "Hermit's Abode",
		"forever/mus_c_day_jungle_1.mp3#8181259",
		"forever/mus_c_day_jungle_2.mp3#8181261",
		"forever/mus_c_day_jungle_3.mp3#8181263",
		"forever/mus_c_night_jungle_1.mp3#8181265",
		"forever/mus_c_night_jungle_2.mp3#8181267",
		"forever/mus_c_night_jungle_3.mp3#8181269",

		"|cffffd800", "|cffffd800" .. "Elderwild",
		"forever/mus_c60_elderwild_a.mp3#8197333#1",
		"forever/mus_c60_elderwild_b.mp3#8197335",
		"forever/mus_c60_elderwild_c.mp3#8197337",

		"|cffffd800", "|cffffd800" .. "Summit of Eternity",
		"forever/mus_c60_summit_of_eternity_a.mp3#8158682",
		"forever/mus_c60_summit_of_eternity_b.mp3#8158684",
		"forever/mus_c60_summit_of_eternity_c.mp3#8282581",

		"|cffffd800", "|cffffd800" .. "Tainted Foothills",
		"forever/mus_c60_tainted_foothills_a.mp3#8269360",
		"forever/mus_c60_tainted_foothills_b.mp3#8269362",
		"forever/mus_c60_tainted_foothills_c.mp3#8269364",

		"|cffffd800", "|cffffd800" .. "Dae'gun",
		"forever/mus_c60_daegun_a.mp3#8198465",
		"forever/mus_c60_daegun_b.mp3#8198467",
		"forever/mus_c60_daegun_c.mp3#8269348",
		"forever/mus_c60_daegun_d.mp3#8269350",

		"|cffffd800", "|cffffd800" .. "Shrine of Aviana",
		"forever/mus_c60_shrine_of_aviana_c.mp3#8281865",
		"forever/mus_c60_shrine_of_aviana_d.mp3#8281867",
		"forever/mus_c60_shrine_of_aviana_a.mp3#8282397",
		"forever/mus_c60_shrine_of_aviana_b.mp3#8282399",

		"|cffffd800", "|cffffd800" .. "Mourning's Rest",
		"forever/mus_c60_mournings_rest_a.mp3#8158676",
		"forever/mus_c60_mournings_rest_b.mp3#8158678",
		"forever/mus_c60_mournings_rest_c.mp3#8158680",

		"|cffffd800", "|cffffd800" .. "Felblood Scar",
		"forever/mus_c60_felblood_scar_a.mp3#8173707",
		"forever/mus_c60_felblood_scar_b.mp3#8269356",
		"forever/mus_c60_felblood_scar_c.mp3#8269358",

		"|cffffd800", "|cffffd800" .. "Malorne's Retreat",
		"forever/mus_c60_malornes_retreat_a.mp3#8190628",
		"forever/mus_c60_malornes_retreat_b.mp3#8190630",
		"forever/mus_c60_malornes_retreat_c.mp3#8190632",
		"forever/mus_c60_malornes_retreat_d.mp3#8190634",
		"forever/mus_c60_malornes_retreat_e.mp3#8190636",
		"forever/mus_c60_malornes_retreat_f.mp3#8190638",

		"|cffffd800", "|cffffd800" .. "Cradle of Tranquility",
		"forever/mus_c60_cradle_of_tranquility_a.mp3#8173701",
		"forever/mus_c60_cradle_of_tranquility_b.mp3#8173703",
		"forever/mus_c60_cradle_of_tranquility_c.mp3#8175594#1",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c60_elderwild_a.mp3#8197333#2",
		"forever/mus_c60_summit_of_eternity_intro.mp3#8158686",
		"forever/mus_c60_cradle_of_tranquility_c.mp3#8175594#2",
	})

	Zn(L["Zones"], L["Kalimdor"], L["Mulgore"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Mulgore"], prefol,
		"|cffffd800", "|cffffd800" .. "Mulgore",
		"forever/mus_c_night_plains_1.mp3#8181309",
		"forever/mus_c_day_plains_2.mp3#8181307",
		"forever/mus_c_night_plains_2.mp3#8181311",
		"forever/mus_c_day_plains_1.mp3#8181305",
		"forever/mus_c_night_desert_1.mp3#8181133",
		"forever/mus_c_night_desert_2.mp3#8181135",
		"forever/mus_c_night_desert_3.mp3#8181137",

		"|cffffd800", "|cffffd800" .. "Mulgore, Brambleblade Ravine",
		"forever/mus_c_cursed_land_4.mp3#8180744",
		"forever/mus_c_cursed_land_5.mp3#8180746",
		"forever/mus_c_cursed_land_6.mp3#8180748",

		"|cffffd800", "|cffffd800" .. "Bloodhoof Village",
		"forever/mus_c_thunder_bluff_walking_1.mp3#8180997",
		"forever/mus_c_thunder_bluff_walking_2.mp3#8180999",
		"forever/mus_c_thunder_bluff_walking_3.mp3#8181001",

		"|cffffd800", "|cffffd800" .. "The Venture Co. Mine",
		"forever/mus_c_day_volcanic_1.mp3#8181275",
		"forever/mus_c_day_volcanic_2.mp3#8181277",
		"forever/mus_c_night_volcanic_1.mp3#8181279",
		"forever/mus_c_night_volcanic_2.mp3#8181281",

		"|cffffd800", "|cffffd800" .. "Palemane Rock",
		"forever/mus_c_soggy_place_zone_2.mp3#8181013",
		"forever/mus_c_soggy_place_zone_5.mp3#8181019",
		"forever/mus_c_soggy_place_zone_1.mp3#8181011",
		"forever/mus_c_soggy_place_zone_3.mp3#8181015",
		"forever/mus_c_soggy_place_zone_4.mp3#8181017",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_warrior_terrace.mp3#8181337",
		"forever/mus_c_swamp_1.mp3#8181335",
	})

	Zn(L["Zones"], L["Kalimdor"], L["Orgrimmar"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Orgrimmar"], prefol,
		"|cffffd800", "|cffffd800" .. "Orgrimmar",
		"forever/mus_c_night_barren_dry_1.mp3#8181055",
		"forever/mus_c_night_barren_dry_2.mp3#8181057",
		"forever/mus_c_day_barren_dry_2.mp3#8181051",
		"forever/mus_c_day_barren_dry_3.mp3#8181053",
		"forever/mus_c_night_barren_dry_3.mp3#8181059",
		"forever/mus_c_day_barren_dry_1.mp3#8181049",
		"forever/mus_c_orgrimmar_2_zone.mp3#8181037",
		"forever/mus_c_orgrimmar_1_zone.mp3#8181033",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_orgrimmar_intro_moment.mp3#8181039",
	})

	Zn(L["Zones"], L["Kalimdor"], L["Shen'dralas"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Shen'dralas"], prefol,
		"|cffffd800", "|cffffd800" .. "Shen'dralas",
		"forever/mus_c_terrokar_bone_wastes_walking_1.mp3#8286132",
		"forever/mus_c_terrokar_bone_wastes_walking_2.mp3#8286134",
		"forever/mus_c_terrokar_bone_wastes_walking_3.mp3#8286136",
		"forever/mus_c_terrokar_bone_wastes_walking_4.mp3#8286138",
	})

	Zn(L["Zones"], L["Kalimdor"], L["Silithus"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Silithus"], prefol,
		"|cffffd800", "|cffffd800" .. "Silithus",
		"forever/mus_c_day_desert_1.mp3#8181127",
		"forever/mus_c_day_desert_2.mp3#8181129",
		"forever/mus_c_day_desert_3.mp3#8181131",
		"forever/mus_c_night_desert_1.mp3#8181133",
		"forever/mus_c_night_desert_2.mp3#8181135",
		"forever/mus_c_night_desert_3.mp3#8181137",

		"|cffffd800", "|cffffd800" .. "Twilight's Run",
		"forever/mus_c_soggy_place_zone_2.mp3#8181013",
		"forever/mus_c_soggy_place_zone_5.mp3#8181019",
		"forever/mus_c_soggy_place_zone_1.mp3#8181011",
		"forever/mus_c_soggy_place_zone_3.mp3#8181015",
		"forever/mus_c_soggy_place_zone_4.mp3#8181017",

		"|cffffd800", "|cffffd800" .. "Ortell's Hideout",
		"forever/mus_c_mystery_3.mp3#8180937",
		"forever/mus_c_mystery_4.mp3#8180939",
		"forever/mus_c_mystery_10.mp3#8180951",
		"forever/mus_c_mystery_5.mp3#8180941",
		"forever/mus_c_mystery_2.mp3#8180935",
		"forever/mus_c_mystery_6.mp3#8180943",
		"forever/mus_c_mystery_7.mp3#8180945",
		"forever/mus_c_mystery_8.mp3#8180947",
		"forever/mus_c_mystery_9.mp3#8180949",
		"forever/mus_c_mystery_1.mp3#8180933",
	})

	Zn(L["Zones"], L["Kalimdor"], L["Stonetalon Mountains"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Stonetalon Mountains"], prefol,
		"|cffffd800", "|cffffd800" .. "Stonetalon Mountains",
		"forever/mus_c_night_barren_dry_1.mp3#8181055",
		"forever/mus_c_night_barren_dry_2.mp3#8181057",
		"forever/mus_c_day_barren_dry_2.mp3#8181051",
		"forever/mus_c_day_barren_dry_3.mp3#8181053#1",
		"forever/mus_c_night_barren_dry_3.mp3#8181059",
		"forever/mus_c_day_barren_dry_1.mp3#8181049",

		"|cffffd800", "|cffffd800" .. "Sun Rock Retreat",
		"citymusic/orgrimmar/orgrimmar02-zone.mp3#53200",
		"forever/mus_c_day_barren_dry_3.mp3#8181053#2",
		"forever/mus_c_orgrimmar_1_zone.mp3#8181033",
		"forever/mus_c_thunder_bluff_walking_3.mp3#8181001#1",
		"forever/mus_c_orgrimmar_2_zone.mp3#8181037",

		"|cffffd800", "|cffffd800" .. "Stonetalon Peak, The Talon Den",
		"forever/mus_c_enchanted_forest_5.mp3#8180792",
		"forever/mus_c_enchanted_forest_1.mp3#8180784",
		"forever/mus_c_enchanted_forest_4.mp3#8180790",
		"forever/mus_c_enchanted_forest_2.mp3#8180786",
		"forever/mus_c_enchanted_forest_3.mp3#8180788",

		"|cffffd800", "|cffffd800" .. "The Talon Den",
		"forever/mus_c_day_evil_forest_1.mp3#8180772",
		"forever/mus_c_day_evil_forest_3.mp3#8180776",
		"forever/mus_c_night_evil_forest_1.mp3#8180758#1",
		"forever/mus_c_day_evil_forest_2.mp3#8180774",
		"forever/mus_c_night_evil_forest_2.mp3#8180760#1",
		"forever/mus_c_night_evil_forest_3.mp3#8180762#1",
		"forever/mus_c_night_forest_1.mp3#8180764",
		"forever/mus_c_night_forest_2.mp3#8180766",
		"forever/mus_c_night_forest_3.mp3#8180768",
		"forever/mus_c_night_forest_4.mp3#8180770",

		"|cffffd800", "|cffffd800" .. "Windshear Mine",
		"forever/mus_c_cursed_land_4.mp3#8180744",
		"forever/mus_c_cursed_land_5.mp3#8180746",
		"forever/mus_c_cursed_land_6.mp3#8180748",

		"|cffffd800", "|cffffd800" .. "Grimtotem Post, Camp Aparaje",
		"forever/mus_c_thunder_bluff_walking_1.mp3#8180997",
		"forever/mus_c_thunder_bluff_walking_2.mp3#8180999",
		"forever/mus_c_thunder_bluff_walking_3.mp3#8181001#2",

		"|cffffd800", "|cffffd800" .. "Malaka'jin",
		"forever/mus_c_tavern_horde_1.mp3#8180987",
		"forever/mus_c_tavern_horde_2.mp3#8180989",

		"|cffffd800", "|cffffd800" .. "Boulderslide Ravine, Boulderslide Cavern",
		"forever/mus_c_day_jungle_1.mp3#8181259",
		"forever/mus_c_day_jungle_2.mp3#8181261",
		"forever/mus_c_day_jungle_3.mp3#8181263",
		"forever/mus_c_night_jungle_1.mp3#8181265",
		"forever/mus_c_night_jungle_2.mp3#8181267",
		"forever/mus_c_night_jungle_3.mp3#8181269",

		"|cffffd800", "|cffffd800" .. "Sishir Canyon",
		"forever/mus_c_night_evil_forest_1.mp3#8180758#2",
		"forever/mus_c_night_evil_forest_2.mp3#8180760#2",
		"forever/mus_c_night_evil_forest_3.mp3#8180762#2",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_magic_1_moment.mp3#8180953",
	})

	Zn(L["Zones"], L["Kalimdor"], L["Tanaris"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Tanaris"], prefol,
		"|cffffd800", "|cffffd800" .. "Tanaris",
		"forever/mus_c_day_desert_1.mp3#8181127",
		"forever/mus_c_day_desert_2.mp3#8181129",
		"forever/mus_c_day_desert_3.mp3#8181131",
		"forever/mus_c_night_desert_1.mp3#8181133",
		"forever/mus_c_night_desert_2.mp3#8181135",
		"forever/mus_c_night_desert_3.mp3#8181137",

		"|cffffd800", "|cffffd800" .. "Steamwheedle Port",
		"forever/mus_c_day_jungle_1.mp3#8181259",
		"forever/mus_c_day_jungle_2.mp3#8181261",
		"forever/mus_c_day_jungle_3.mp3#8181263",
		"forever/mus_c_night_jungle_1.mp3#8181265",
		"forever/mus_c_night_jungle_2.mp3#8181267",
		"forever/mus_c_night_jungle_3.mp3#8181269",

		"|cffffd800", "|cffffd800" .. "Dunemaul Compound",
		"forever/mus_c_day_volcanic_1.mp3#8181275",
		"forever/mus_c_day_volcanic_2.mp3#8181277",
		"forever/mus_c_night_volcanic_1.mp3#8181279",
		"forever/mus_c_night_volcanic_2.mp3#8181281",
	})

	Zn(L["Zones"], L["Kalimdor"], L["Teldrassil"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Teldrassil"], prefol,
		"|cffffd800", "|cffffd800" .. "Teldrassil",
		"forever/mus_c_enchanted_forest_5.mp3#8180792",
		"forever/mus_c_enchanted_forest_1.mp3#8180784",
		"forever/mus_c_enchanted_forest_4.mp3#8180790",
		"forever/mus_c_enchanted_forest_2.mp3#8180786",
		"forever/mus_c_enchanted_forest_3.mp3#8180788",

		"|cffffd800", "|cffffd800" .. "Darnassus UNUSED, Craftsmen's Terrace UNUSED, Tradesmen's Terrace UNUSED, The Temple Gardens UNUSED, Temple of Elune UNUSED, Cenarion Enclave UNUSED, Warrior's Terrace UNUSED",
		"forever/mus_c_darnasssus_walking_1.mp3#8180752",
		"forever/mus_c_darnasssus_walking_2.mp3#8180754",
		"forever/mus_c_darnasssus_walking_3.mp3#8180756",

		"|cffffd800", "|cffffd800" .. "Shadowthread Cave",
		"forever/mus_c_night_evil_forest_1.mp3#8180758",
		"forever/mus_c_night_evil_forest_2.mp3#8180760",
		"forever/mus_c_night_evil_forest_3.mp3#8180762",

		"|cffffd800", "|cffffd800" .. "Fel Rock",
		"forever/mus_c_soggy_place_zone_2.mp3#8181013",
		"forever/mus_c_soggy_place_zone_5.mp3#8181019",
		"forever/mus_c_soggy_place_zone_1.mp3#8181011",
		"forever/mus_c_soggy_place_zone_3.mp3#8181015",
		"forever/mus_c_soggy_place_zone_4.mp3#8181017",

		"|cffffd800", "|cffffd800" .. "Lake Al'Ameth, The Cleft, Ban'ethil Hollow",
		"forever/mus_c_mystery_3.mp3#8180937",
		"forever/mus_c_mystery_4.mp3#8180939",
		"forever/mus_c_mystery_10.mp3#8180951",
		"forever/mus_c_mystery_5.mp3#8180941",
		"forever/mus_c_mystery_2.mp3#8180935",
		"forever/mus_c_mystery_6.mp3#8180943",
		"forever/mus_c_mystery_7.mp3#8180945",
		"forever/mus_c_mystery_8.mp3#8180947",
		"forever/mus_c_mystery_9.mp3#8180949",
		"forever/mus_c_mystery_1.mp3#8180933",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_darnasssus_intro.mp3#8180750",
	})

	Zn(L["Zones"], L["Kalimdor"], L["Thousand Needles"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Thousand Needles"], prefol,
		"|cffffd800", "|cffffd800" .. "Thousand Needles",
		"forever/mus_c_night_plains_1.mp3#8181309",
		"forever/mus_c_day_plains_2.mp3#8181307",
		"forever/mus_c_night_plains_2.mp3#8181311",
		"forever/mus_c_day_plains_1.mp3#8181305",

		"|cffffd800", "|cffffd800" .. "The Rustmaul Dig Site",
		"forever/mus_c_day_desert_1.mp3#8181127",
		"forever/mus_c_day_desert_2.mp3#8181129",
		"forever/mus_c_day_desert_3.mp3#8181131",
		"forever/mus_c_night_desert_1.mp3#8181133#1",
		"forever/mus_c_night_desert_2.mp3#8181135#1",
		"forever/mus_c_night_desert_3.mp3#8181137#1",

		"|cffffd800", "|cffffd800" .. "Freewind Post, Darkcloud Pinnacle",
		"forever/mus_c_thunder_bluff_walking_1.mp3#8180997",
		"forever/mus_c_thunder_bluff_walking_2.mp3#8180999",
		"forever/mus_c_thunder_bluff_walking_3.mp3#8181001",

		"|cffffd800", "|cffffd800" .. "Roguefeather Den",
		"forever/mus_c_night_desert_1.mp3#8181133#2",
		"forever/mus_c_night_desert_2.mp3#8181135#2",
		"forever/mus_c_night_desert_3.mp3#8181137#2",

		"|cffffd800", "|cffffd800" .. "The Weathered Nook, Darkcloud Pinnacle",
		"forever/mus_c_mystery_3.mp3#8180937",
		"forever/mus_c_mystery_4.mp3#8180939",
		"forever/mus_c_mystery_10.mp3#8180951",
		"forever/mus_c_mystery_5.mp3#8180941",
		"forever/mus_c_mystery_2.mp3#8180935",
		"forever/mus_c_mystery_6.mp3#8180943",
		"forever/mus_c_mystery_7.mp3#8180945",
		"forever/mus_c_mystery_8.mp3#8180947",
		"forever/mus_c_mystery_9.mp3#8180949",
		"forever/mus_c_mystery_1.mp3#8180933",

		"|cffffd800", "|cffffd800" .. "Splithoof Hold",
		"forever/mus_c_soggy_place_zone_2.mp3#8181013",
		"forever/mus_c_soggy_place_zone_5.mp3#8181019",
		"forever/mus_c_soggy_place_zone_1.mp3#8181011",
		"forever/mus_c_soggy_place_zone_3.mp3#8181015",
		"forever/mus_c_soggy_place_zone_4.mp3#8181017",
	})

	Zn(L["Zones"], L["Kalimdor"], L["Thunder Bluff"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Thunder Bluff"], prefol,
		"|cffffd800", "|cffffd800" .. "Thunder Bluff",
		"forever/mus_c_thunder_bluff_walking_1.mp3#8180997",
		"forever/mus_c_thunder_bluff_walking_2.mp3#8180999",
		"forever/mus_c_thunder_bluff_walking_3.mp3#8181001",

		"|cffffd800", "|cffffd800" .. "The Pools of Vision",
		"forever/mus_c_mystery_3.mp3#8180937",
		"forever/mus_c_mystery_4.mp3#8180939",
		"forever/mus_c_mystery_10.mp3#8180951",
		"forever/mus_c_mystery_5.mp3#8180941",
		"forever/mus_c_mystery_2.mp3#8180935",
		"forever/mus_c_mystery_6.mp3#8180943",
		"forever/mus_c_mystery_7.mp3#8180945",
		"forever/mus_c_mystery_8.mp3#8180947",
		"forever/mus_c_mystery_9.mp3#8180949",
		"forever/mus_c_mystery_1.mp3#8180933",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_thunder_bluff_intro.mp3#8180995",
	})

	Zn(L["Zones"], L["Kalimdor"], L["Un'Goro Crater"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Un'Goro Crater"], prefol,
		"|cffffd800", "|cffffd800" .. "Un'Goro Crater",
		"forever/mus_c_soggy_place_zone_1.mp3#8181011",
		"forever/mus_c_soggy_place_zone_3.mp3#8181015",
		"forever/mus_c_soggy_place_zone_4.mp3#8181017",

		"|cffffd800", "|cffffd800" .. "Fire Plume Ridge",
		"forever/mus_c_mystery_3.mp3#8180937",
		"forever/mus_c_mystery_4.mp3#8180939",
		"forever/mus_c_mystery_10.mp3#8180951",
		"forever/mus_c_mystery_5.mp3#8180941",
		"forever/mus_c_mystery_2.mp3#8180935",
		"forever/mus_c_mystery_6.mp3#8180943",
		"forever/mus_c_mystery_7.mp3#8180945",
		"forever/mus_c_mystery_8.mp3#8180947",
		"forever/mus_c_mystery_9.mp3#8180949",
		"forever/mus_c_mystery_1.mp3#8180933",

		"|cffffd800", "|cffffd800" .. "The Slithering Scar, Marshal's Refuge",
		"forever/mus_c_day_desert_1.mp3#8181127",
		"forever/mus_c_day_desert_2.mp3#8181129",
		"forever/mus_c_day_desert_3.mp3#8181131",
		"forever/mus_c_night_desert_1.mp3#8181133",
		"forever/mus_c_night_desert_2.mp3#8181135",
		"forever/mus_c_night_desert_3.mp3#8181137",

		"|cffffd800", "|cffffd800" .. "Fungal Rock",
		"forever/mus_c_day_jungle_1.mp3#8181259",
		"forever/mus_c_day_jungle_2.mp3#8181261",
		"forever/mus_c_day_jungle_3.mp3#8181263",
		"forever/mus_c_night_jungle_1.mp3#8181265",
		"forever/mus_c_night_jungle_2.mp3#8181267",
		"forever/mus_c_night_jungle_3.mp3#8181269",

		"|cffffd800", "|cffffd800" .. "The Shaper's Terrace, Pillar of Assimilation",
		"forever/mus_c_sholazar_walk_day_4.mp3#8286116",
		"forever/mus_c_sholazar_walk_day_5.mp3#8286118",
		"forever/mus_c_sholazar_walk_day_6.mp3#8286120",
		"forever/mus_c_sholazar_walk_night_1.mp3#8286122",
		"forever/mus_c_sholazar_walk_night_2.mp3#8286124",
		"forever/mus_c_sholazar_walk_night_3.mp3#8286126",
		"forever/mus_c_sholazar_walk_night_4.mp3#8286128",
		"forever/mus_c_sholazar_walk_night_5.mp3#8286130",
	})

	Zn(L["Zones"], L["Kalimdor"], L["Winterspring"], {"|cffffd800" .. L["Zones"] .. ": " .. L["Winterspring"], prefol,
		"|cffffd800", "|cffffd800" .. "Winterspring",
		"forever/mus_c_day_mountain_1.mp3#8181287",
		"forever/mus_c_day_mountain_2.mp3#8181289",
		"forever/mus_c_day_mountain_3.mp3#8181291",
		"forever/mus_c_night_mountain_3.mp3#8181297",
		"forever/mus_c_night_mountain_4.mp3#8181299",
		"forever/mus_c_night_mountain_1.mp3#8181293",
		"forever/mus_c_night_mountain_2.mp3#8181295",

		"|cffffd800", "|cffffd800" .. "The Barrow Deeps",
		"forever/mus_c_mystery_3.mp3#8180937#1",
		"forever/mus_c_mystery_2.mp3#8180935#1",
		"forever/mus_c_mystery_9.mp3#8180949#1",
		"forever/mus_c_mystery_1.mp3#8180933#1",

		"|cffffd800", "|cffffd800" .. "Mazthoril",
		"forever/mus_c_soggy_place_zone_1.mp3#8181011",
		"forever/mus_c_soggy_place_zone_3.mp3#8181015",
		"forever/mus_c_soggy_place_zone_4.mp3#8181017",
		"forever/mus_c_soggy_place_zone_2.mp3#8181013",
		"forever/mus_c_soggy_place_zone_5.mp3#8181019",

		"|cffffd800", "|cffffd800" .. "Ice Thistle Hills",
		"forever/mus_c_night_evil_forest_1.mp3#8180758#1",
		"forever/mus_c_night_evil_forest_2.mp3#8180760#1",
		"forever/mus_c_night_evil_forest_3.mp3#8180762#1",

		"|cffffd800", "|cffffd800" .. "Owl Wing Thicket, Darkwhisper Gorge, Moon Horror Den",
		"forever/mus_c_mystery_3.mp3#8180937#2",
		"forever/mus_c_mystery_4.mp3#8180939",
		"forever/mus_c_mystery_10.mp3#8180951",
		"forever/mus_c_mystery_5.mp3#8180941",
		"forever/mus_c_mystery_2.mp3#8180935#2",
		"forever/mus_c_mystery_6.mp3#8180943",
		"forever/mus_c_mystery_7.mp3#8180945",
		"forever/mus_c_mystery_8.mp3#8180947",
		"forever/mus_c_mystery_9.mp3#8180949#2",
		"forever/mus_c_mystery_1.mp3#8180933#2",

		"|cffffd800", "|cffffd800" .. "Starfall Village",
		"forever/mus_c_darnasssus_walking_1.mp3#8180752",
		"forever/mus_c_darnasssus_walking_2.mp3#8180754",
		"forever/mus_c_darnasssus_walking_3.mp3#8180756",
		"forever/mus_c_gloomy_1.mp3#8181325",

		"|cffffd800", "|cffffd800" .. "Ban'Thallow Barrow Den",
		"forever/mus_c_day_evil_forest_1.mp3#8180772",
		"forever/mus_c_day_evil_forest_3.mp3#8180776",
		"forever/mus_c_night_evil_forest_1.mp3#8180758#2",
		"forever/mus_c_day_evil_forest_2.mp3#8180774",
		"forever/mus_c_night_evil_forest_2.mp3#8180760#2",
		"forever/mus_c_night_evil_forest_3.mp3#8180762#2",

		"|cffffd800", "|cffffd800" .. "Everlook",
		"forever/mus_c_gnomeragon_1.mp3#8181329",
		"forever/mus_c_gnomeragon_2.mp3#8181331",

		"|cffffd800", "|cffffd800" .. "Darkwhisper Gorge",
		"forever/mus_c_cursed_land_4.mp3#8180744",
		"forever/mus_c_cursed_land_5.mp3#8180746",
		"forever/mus_c_cursed_land_6.mp3#8180748",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_battle_3.mp3#8180903",
		"forever/mus_c_druid_grove.mp3#8181323",
	})

	----------------------------------------------------------------------
	-- Dungeons: World of Warcraft
	----------------------------------------------------------------------

	Zn(L["Dungeons"], L["World of Warcraft"], "|cffffd800" .. L["World of Warcraft"], {""})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Ahn'Qiraj Temple"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Ahn'Qiraj Temple"], prefol,
		"|cffffd800", "|cffffd800" .. "Ahn'Qiraj Temple",
		"forever/mus_c_ahnqiraj_exterior_walking_1.mp3#8176626",
		"forever/mus_c_ahnqiraj_exterior_walking_2.mp3#8176628",
		"forever/mus_c_ahnqiraj_exterior_walking_3.mp3#8176630",
		"forever/mus_c_ahnqiraj_exterior_walking_4.mp3#8176632",
		"forever/mus_c_ahnqiraj_interior_1.mp3#8176671",
		"forever/mus_c_ahnqiraj_interior_2.mp3#8176673",
		"forever/mus_c_ahnqiraj_interior_3.mp3#8176675",
		"forever/mus_c_ahnqiraj_interior_center_room_1.mp3#8176681",
		"forever/mus_c_ahnqiraj_king_room.mp3#8176685",
		"forever/mus_c_ahnqiraj_triangle_room_1.mp3#8176689",
		"forever/mus_c_ahnqiraj_triangle_room_2.mp3#8176691",
		"forever/mus_c_ahnqiraj_triangle_room_3.mp3#8176693",
		"forever/mus_c_ahnqiraj_triangle_room_4.mp3#8176695",
		"forever/mus_c_ahnqiraj_triangle_room_5.mp3#8176697",
		"forever/mus_c_ahnqiraj_triangle_room_6.mp3#8176699",
		"forever/mus_c_ahnqiraj_triangle_room_7.mp3#8176701",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_ahnqiraj_interior_intro_main.mp3#8176683",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Blackfathom Deeps"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Blackfathom Deeps"], prefol,
		"|cffffd800", "|cffffd800" .. "Blackfathom Deeps",
		"forever/mus_c_day_desert_1.mp3#8181127",
		"forever/mus_c_day_desert_2.mp3#8181129",
		"forever/mus_c_day_desert_3.mp3#8181131",
		"forever/mus_c_night_desert_1.mp3#8181133",
		"forever/mus_c_night_desert_2.mp3#8181135",
		"forever/mus_c_night_desert_3.mp3#8181137",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Blackwing Lair"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Blackwing Lair"], prefol,
		"|cffffd800", "|cffffd800" .. "Blackwing Lair",
		"forever/mus_c_cursed_land_4.mp3#8180744",
		"forever/mus_c_cursed_land_5.mp3#8180746",
		"forever/mus_c_cursed_land_6.mp3#8180748",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Burning of Andorhal"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Burning of Andorhal"], prefol,
		"|cffffd800", "|cffffd800" .. "Burning of Andorhal",
		"forever/mus_c_haunted_1.mp3#8181313",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["City of Dalaran"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["City of Dalaran"], prefol,
		"|cffffd800", "|cffffd800" .. "City of Dalaran",
		"forever/mus_c_dalaran_1.mp3#8285938",
		"forever/mus_c_dalaran_2.mp3#8285940",
		"forever/mus_c_dalaran_3.mp3#8285942",
		"forever/mus_c_dalaran_4.mp3#8285944",

		"|cffffd800", "|cffffd800" .. "The Violet Citadel, The Purple Parlor",
		"forever/mus_c_dalaran_spire.mp3#8451379",

		"|cffffd800", "|cffffd800" .. "The Underbelly, Cantrips & Crows",
		"forever/mus_c_dalaran_sewer_1.mp3#8451330",
		"forever/mus_c_dalaran_sewer_2.mp3#8451332",
		"forever/mus_c_dalaran_sewer_3.mp3#8451334",
		"forever/mus_c_dalaran_sewer_4.mp3#8451336",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_dalaran_intro.mp3#8285946",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Crystal Vale"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Crystal Vale"], prefol,
		"|cffffd800", "|cffffd800" .. "Crystal Vale",
		"forever/mus_c_day_barren_dry_3.mp3#8181053",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Deadmines"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Deadmines"], prefol,
		"|cffffd800", "|cffffd800" .. "Westfall",
		"forever/mus_c_night_plains_1.mp3#8181309",
		"forever/mus_c_day_plains_2.mp3#8181307",
		"forever/mus_c_night_plains_2.mp3#8181311",
		"forever/mus_c_day_plains_1.mp3#8181305",

		"|cffffd800", "|cffffd800" .. "The Deadmines, Goblin Foundry, Ironclad Cove",
		"forever/mus_c_mystery_3.mp3#8180937",
		"forever/mus_c_mystery_4.mp3#8180939",
		"forever/mus_c_mystery_10.mp3#8180951",
		"forever/mus_c_mystery_5.mp3#8180941",
		"forever/mus_c_mystery_2.mp3#8180935",
		"forever/mus_c_mystery_6.mp3#8180943",
		"forever/mus_c_mystery_7.mp3#8180945",
		"forever/mus_c_mystery_8.mp3#8180947",
		"forever/mus_c_mystery_9.mp3#8180949",
		"forever/mus_c_mystery_1.mp3#8180933",

		"|cffffd800", "|cffffd800" .. "The Deadmines",
		"forever/mus_c_battle_6.mp3#8180909#1",
		"forever/mus_c_cursed_land_1.mp3#8180738",
		"forever/mus_c_cursed_land_3.mp3#8180742",

		"|cffffd800", "|cffffd800" .. "Ironclad Cove",
		"forever/mus_c_battle_2.mp3#8180901",

		"|cffffd800", "|cffffd800" .. "Mast Room",
		"forever/mus_c_orgrimmar_2_zone.mp3#8181037",
		"forever/mus_c_orgrimmar_1_zone.mp3#8181033",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_spooky_1_moment.mp3#8181333",
		"forever/mus_c_battle_6.mp3#8180909#2",
		"forever/mus_c_stormwind_2.mp3#8180868",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Deadwind Pass"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Deadwind Pass"], prefol,
		"|cffffd800", "|cffffd800" .. "Redridge Mountains",
		"forever/mus_c_day_forest_1.mp3#8180778",
		"forever/mus_c_day_forest_2.mp3#8180780",
		"forever/mus_c_day_forest_3.mp3#8180782",

		"|cffffd800", "|cffffd800" .. "Deadwind Pass, Duskwood, Beggar's Haunt, Darkshire, Brightwood Grove, The Darkened Bank",
		"forever/mus_c_day_evil_forest_1.mp3#8180772",
		"forever/mus_c_day_evil_forest_3.mp3#8180776",
		"forever/mus_c_night_evil_forest_1.mp3#8180758",
		"forever/mus_c_day_evil_forest_2.mp3#8180774",
		"forever/mus_c_night_evil_forest_2.mp3#8180760",
		"forever/mus_c_night_evil_forest_3.mp3#8180762",

		"|cffffd800", "|cffffd800" .. "Blasted Lands, The Tainted Scar",
		"forever/mus_c_night_barren_dry_1.mp3#8181055",
		"forever/mus_c_night_barren_dry_2.mp3#8181057",
		"forever/mus_c_day_barren_dry_2.mp3#8181051",
		"forever/mus_c_day_barren_dry_3.mp3#8181053",
		"forever/mus_c_night_barren_dry_3.mp3#8181059",
		"forever/mus_c_day_barren_dry_1.mp3#8181049",

		"|cffffd800", "|cffffd800" .. "Swamp of Sorrows",
		"forever/mus_c_soggy_place_zone_1.mp3#8181011",
		"forever/mus_c_soggy_place_zone_3.mp3#8181015",
		"forever/mus_c_soggy_place_zone_4.mp3#8181017",

		"|cffffd800", "|cffffd800" .. "Stranglethorn Vale, Zul'Gurub",
		"forever/mus_c_day_jungle_1.mp3#8181259",
		"forever/mus_c_day_jungle_2.mp3#8181261",
		"forever/mus_c_day_jungle_3.mp3#8181263",
		"forever/mus_c_night_jungle_1.mp3#8181265",
		"forever/mus_c_night_jungle_2.mp3#8181267",
		"forever/mus_c_night_jungle_3.mp3#8181269",

		"|cffffd800", "|cffffd800" .. "Tranquil Gardens Cemetery",
		"forever/mus_c_haunted_1.mp3#8181313",

		"|cffffd800", "|cffffd800" .. "Altar of Storms",
		"forever/mus_c_day_volcanic_1.mp3#8181275",
		"forever/mus_c_day_volcanic_2.mp3#8181277",
		"forever/mus_c_night_volcanic_1.mp3#8181279",
		"forever/mus_c_night_volcanic_2.mp3#8181281",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Demon Fall Canyon"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Demon Fall Canyon"], prefol,
		"|cffffd800", "|cffffd800" .. "Demon Fall Canyon",
		"forever/mus_c_cursed_land_1.mp3#8180738",
		"forever/mus_c_cursed_land_3.mp3#8180742",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Dire Maul"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Dire Maul"], prefol,
		"|cffffd800", "|cffffd800" .. "Dire Maul",
		"forever/mus_c_enchanted_forest_5.mp3#8180792",
		"forever/mus_c_enchanted_forest_1.mp3#8180784",
		"forever/mus_c_enchanted_forest_4.mp3#8180790",
		"forever/mus_c_enchanted_forest_2.mp3#8180786",
		"forever/mus_c_enchanted_forest_3.mp3#8180788",
		"forever/mus_c_night_evil_forest_1.mp3#8180758",
		"forever/mus_c_night_evil_forest_2.mp3#8180760",
		"forever/mus_c_night_evil_forest_3.mp3#8180762",
		"forever/mus_c_spooky_1_moment.mp3#8181333",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Excavation Site: Wetlands"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Excavation Site: Wetlands"], prefol,
		"|cffffd800", "|cffffd800" .. "Excavation Site: Wetlands",
		"forever/mus_c60_dungeons_wetlands_a.mp3#8270379",
		"forever/mus_c60_dungeons_wetlands_b.mp3#8270381",
		"forever/mus_c60_dungeons_wetlands_c.mp3#8270383",
		"forever/mus_c60_dungeons_wetlands_d.mp3#8270385",

		"|cffffd800", "|cffffd800" .. "Stalker's Thicket, Lost Dig Site",
		"forever/mus_c_soggy_place_zone_2.mp3#8181013",
		"forever/mus_c_soggy_place_zone_5.mp3#8181019",
		"forever/mus_c_soggy_place_zone_1.mp3#8181011",
		"forever/mus_c_soggy_place_zone_3.mp3#8181015",
		"forever/mus_c_soggy_place_zone_4.mp3#8181017",

		"|cffffd800", "|cffffd800" .. "Site of the Guardian",
		"forever/mus_c_nerubian_nest_c.mp3#8270576",
		"forever/mus_c_nerubian_nest_e.mp3#8270578",
		"forever/mus_c_silken_path_a.mp3#8270580",
		"forever/mus_c_silken_path_e.mp3#8270582",
		"forever/mus_c_weavers_lair_c.mp3#8270584",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Gnomeregan"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Gnomeregan"], prefol,
		"|cffffd800", "|cffffd800" .. "Gnomeregan",
		"forever/mus_c_gnomeragon_1.mp3#8181329",
		"forever/mus_c_gnomeragon_2.mp3#8181331",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Hall of Thanes"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Hall of Thanes"], prefol,
		"|cffffd800", "|cffffd800" .. "Hall of Thanes",
		"forever/mus_c_mystery_3.mp3#8180937",
		"forever/mus_c_mystery_2.mp3#8180935",
		"forever/mus_c_mystery_9.mp3#8180949",
		"forever/mus_c_mystery_1.mp3#8180933",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Maraudon"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Maraudon"], prefol,
		"|cffffd800", "|cffffd800" .. "Maraudon",
		"forever/mus_c_night_barren_dry_1.mp3#8181055",
		"forever/mus_c_night_barren_dry_2.mp3#8181057",
		"forever/mus_c_day_barren_dry_2.mp3#8181051",
		"forever/mus_c_day_barren_dry_3.mp3#8181053",
		"forever/mus_c_night_barren_dry_3.mp3#8181059",
		"forever/mus_c_day_barren_dry_1.mp3#8181049",
		"forever/mus_c_soggy_place_zone_2.mp3#8181013",
		"forever/mus_c_soggy_place_zone_5.mp3#8181019",
		"forever/mus_c_soggy_place_zone_1.mp3#8181011",
		"forever/mus_c_soggy_place_zone_3.mp3#8181015",
		"forever/mus_c_soggy_place_zone_4.mp3#8181017",
		"forever/mus_c_battle_2.mp3#8180901",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_swamp_1.mp3#8181335",
		"forever/mus_c_spooky_1_moment.mp3#8181333",
		"forever/mus_c_battle_3.mp3#8180903",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Naxxramas"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Naxxramas"], prefol,
		"|cffffd800", "|cffffd800" .. "The Arachnid Quarter",
		"zonemusic/naxxramas/naxxramasspiderwing1.mp3#53611",
		"zonemusic/naxxramas/naxxramasspiderwing2.mp3#53612",
		"zonemusic/naxxramas/naxxramasspiderwing3.mp3#53613#1",

		"|cffffd800", "|cffffd800" .. "The Outer Ring, The Construct Quarter",
		"zonemusic/naxxramas/naxxramasabominationwing1.mp3#53593",
		"zonemusic/naxxramas/naxxramasabominationwing2.mp3#53594",
		"zonemusic/naxxramas/naxxramasabominationwing3.mp3#53595",

		"|cffffd800", "|cffffd800" .. "The Outer Ring, The Military Quarter",
		"forever/mus_c_naxxramas_walking_1.mp3#8180911",
		"forever/mus_c_naxxramas_walking_2.mp3#8180913",
		"forever/mus_c_naxxramas_walking_3.mp3#8180915",
		"forever/mus_c_naxxramas_walking_4.mp3#8180917",
		"forever/mus_c_naxxramas_walking_5.mp3#8180919",
		"forever/mus_c_naxxramas_walking_6.mp3#8180921",

		"|cffffd800", "|cffffd800" .. "The Outer Ring, The Plague Quarter",
		"zonemusic/naxxramas/naxxramasplaguewing1.mp3#53606#1",
		"zonemusic/naxxramas/naxxramasplaguewing2.mp3#53607#1",
		"zonemusic/naxxramas/naxxramasplaguewing3.mp3#53608",

		"|cffffd800", "|cffffd800" .. "The Necrotic Vault",
		"zonemusic/naxxramas/naxxramasplagueboss1.mp3#53605",
		"zonemusic/naxxramas/naxxramasplaguewing1.mp3#53606#2",
		"zonemusic/naxxramas/naxxramasplaguewing2.mp3#53607#2",

		"|cffffd800", "|cffffd800" .. "Maexxna's Nest",
		"zonemusic/naxxramas/naxxramasspiderboss1.mp3#53609",
		"zonemusic/naxxramas/naxxramasspiderwing3.mp3#53613#2",
		"zonemusic/naxxramas/naxxramasspiderboss2.mp3#53610",

		"|cffffd800", "|cffffd800" .. "Naxxramas, Sapphiron's Lair",
		"zonemusic/naxxramas/naxxramasfrostwyrm1.mp3#53596",
		"zonemusic/naxxramas/naxxramasfrostwyrm2.mp3#53597",
		"zonemusic/naxxramas/naxxramasfrostwyrm3.mp3#53598",
		"zonemusic/naxxramas/naxxramasfrostwyrm4.mp3#53599",

		"|cffffd800", "|cffffd800" .. "Kel'Thuzad's Chamber",
		"zonemusic/naxxramas/naxxramaskelthuzad1.mp3#53602",
		"zonemusic/naxxramas/naxxramaskelthuzad2.mp3#53603",
		"zonemusic/naxxramas/naxxramaskelthuzad3.mp3#53604",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Nightmare Grove"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Nightmare Grove"], prefol,
		"|cffffd800", "|cffffd800" .. "Azshara",
		"forever/mus_c_cursed_land_4.mp3#8180744",
		"forever/mus_c_cursed_land_5.mp3#8180746",
		"forever/mus_c_cursed_land_6.mp3#8180748",

		"|cffffd800", "|cffffd800" .. "Mount Hyjal",
		"forever/mus_c60_hyjal_general_a.mp3#8158670",
		"forever/mus_c60_hyjal_general_b.mp3#8158672",
		"forever/mus_c60_hyjal_general_c.mp3#8158674",
		"forever/mus_c60_hyjal_general_d.mp3#8173713",

		"|cffffd800", "|cffffd800" .. "Xavian, Satyrnaar, Haldarr Encampment, Feralas",
		"forever/mus_c_day_jungle_1.mp3#8181259",
		"forever/mus_c_day_jungle_2.mp3#8181261",
		"forever/mus_c_day_jungle_3.mp3#8181263",
		"forever/mus_c_night_jungle_1.mp3#8181265",
		"forever/mus_c_night_jungle_2.mp3#8181267",
		"forever/mus_c_night_jungle_3.mp3#8181269",

		"|cffffd800", "|cffffd800" .. "Bough Shadow, Forest Song",
		"forever/mus_c_warrior_terrace.mp3#8181337",

		"|cffffd800", "|cffffd800" .. "Warsong Lumber Camp",
		"citymusic/orgrimmar/orgrimmar02-zone.mp3#53200",
		"forever/mus_c_day_barren_dry_3.mp3#8181053#1",
		"forever/mus_c_orgrimmar_1_zone.mp3#8181033",
		"forever/mus_c_thunder_bluff_walking_3.mp3#8181001",
		"forever/mus_c_orgrimmar_2_zone.mp3#8181037#1",

		"|cffffd800", "|cffffd800" .. "Shadowsong Shrine, Raven Hill Cemetery",
		"forever/mus_c_haunted_1.mp3#8181313",

		"|cffffd800", "|cffffd800" .. "Southfury River",
		"forever/mus_c_day_mountain_1.mp3#8181287",
		"forever/mus_c_day_mountain_2.mp3#8181289",
		"forever/mus_c_day_mountain_3.mp3#8181291",
		"forever/mus_c_night_mountain_3.mp3#8181297",
		"forever/mus_c_night_mountain_4.mp3#8181299",
		"forever/mus_c_night_mountain_1.mp3#8181293",
		"forever/mus_c_night_mountain_2.mp3#8181295",

		"|cffffd800", "|cffffd800" .. "Desolace, Gelkis Village",
		"forever/mus_c_night_barren_dry_1.mp3#8181055",
		"forever/mus_c_night_barren_dry_2.mp3#8181057",
		"forever/mus_c_day_barren_dry_2.mp3#8181051",
		"forever/mus_c_day_barren_dry_3.mp3#8181053#2",
		"forever/mus_c_night_barren_dry_3.mp3#8181059",
		"forever/mus_c_day_barren_dry_1.mp3#8181049",

		"|cffffd800", "|cffffd800" .. "Valley of Bones, Mannoroc Coven",
		"forever/mus_c_cursed_land_1.mp3#8180738",
		"forever/mus_c_cursed_land_3.mp3#8180742",

		"|cffffd800", "|cffffd800" .. "The Hinterlands, Skulk Rock, The Overlook Cliffs, Elwynn Forest, Forest's Edge, The Stonefield Farm, The Maclure Vineyards, Tower of Azora, Fargodeep Mine, Brackwell Pumpkin Patch",
		"forever/mus_c_day_forest_1.mp3#8180778",
		"forever/mus_c_day_forest_2.mp3#8180780",
		"forever/mus_c_day_forest_3.mp3#8180782",

		"|cffffd800", "|cffffd800" .. "Seradane",
		"forever/mus_c_darnasssus_walking_1.mp3#8180752",
		"forever/mus_c_darnasssus_walking_2.mp3#8180754",
		"forever/mus_c_darnasssus_walking_3.mp3#8180756",

		"|cffffd800", "|cffffd800" .. "Duskwood, The Darkened Bank, Addle's Stead, Twilight Grove, Darkshire, The Yorgen Farmstead, Forlorn Rowe, Brightwood Grove, The Rotting Orchard, Raven Hill",
		"forever/mus_c_day_evil_forest_1.mp3#8180772",
		"forever/mus_c_day_evil_forest_3.mp3#8180776",
		"forever/mus_c_night_evil_forest_1.mp3#8180758",
		"forever/mus_c_day_evil_forest_2.mp3#8180774",
		"forever/mus_c_night_evil_forest_2.mp3#8180760",
		"forever/mus_c_night_evil_forest_3.mp3#8180762",

		"|cffffd800", "|cffffd800" .. "Westfall",
		"forever/mus_c_night_plains_1.mp3#8181309",
		"forever/mus_c_day_plains_2.mp3#8181307",
		"forever/mus_c_night_plains_2.mp3#8181311",
		"forever/mus_c_day_plains_1.mp3#8181305",

		"|cffffd800", "|cffffd800" .. "Vul'Gol Ogre Mound",
		"forever/mus_c_orgrimmar_2_zone.mp3#8181037#2",

		"|cffffd800", "|cffffd800" .. "Ashenvale",
		"forever/mus_c_enchanted_forest_5.mp3#8180792",
		"forever/mus_c_enchanted_forest_1.mp3#8180784",
		"forever/mus_c_enchanted_forest_4.mp3#8180790",
		"forever/mus_c_enchanted_forest_2.mp3#8180786",
		"forever/mus_c_enchanted_forest_3.mp3#8180788",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_swamp_1.mp3#8181335",
		"forever/mus_c_battle_3.mp3#8180903",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Onyxia's Lair"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Onyxia's Lair"], prefol,
		"|cffffd800", "|cffffd800" .. "Onyxia's Lair",
		"forever/mus_c_day_barren_dry_3.mp3#8181053",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Razorfen Downs"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Razorfen Downs"], prefol,
		"|cffffd800", "|cffffd800" .. "Razorfen Downs",
		"forever/mus_c_day_desert_1.mp3#8181127",
		"forever/mus_c_day_desert_2.mp3#8181129",
		"forever/mus_c_day_desert_3.mp3#8181131",
		"forever/mus_c_night_desert_1.mp3#8181133",
		"forever/mus_c_night_desert_2.mp3#8181135",
		"forever/mus_c_night_desert_3.mp3#8181137",
		"forever/mus_c_undercity_1.mp3#8181003",
		"forever/mus_c_undercity_2.mp3#8181005",
		"forever/mus_c_undercity_3.mp3#8181007",

		"|cffffd800", "|cffffd800" .. "The Bone Pile",
		"forever/mus_c_undead_dance.mp3#8180993",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Ruins of Ahn'Qiraj"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Ruins of Ahn'Qiraj"], prefol,
		"|cffffd800", "|cffffd800" .. "Ruins of Ahn'Qiraj",
		"forever/mus_c_ahnqiraj_exterior_walking_1.mp3#8176626",
		"forever/mus_c_ahnqiraj_exterior_walking_2.mp3#8176628",
		"forever/mus_c_ahnqiraj_exterior_walking_3.mp3#8176630",
		"forever/mus_c_ahnqiraj_exterior_walking_4.mp3#8176632",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Ruins of Lordaeron"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Ruins of Lordaeron"], prefol,
		"|cffffd800", "|cffffd800" .. "Ruins of Lordaeron",
		"forever/mus_c_undercity_1.mp3#8181003#1",
		"forever/mus_c_undercity_2.mp3#8181005#1",
		"forever/mus_c_undercity_3.mp3#8181007#1",
		"forever/mus_c60_mournings_rest_a.mp3#8158676",
		"forever/mus_c60_mournings_rest_b.mp3#8158678",
		"forever/mus_c60_mournings_rest_c.mp3#8158680",

		"|cffffd800", "|cffffd800" .. "Ruins of Lordaeron, War Quarter, Canals, Sewers, Rogues' Quarter, Magic Quarter, Royal Quarter",
		"forever/mus_c_undercity_1.mp3#8181003#2",
		"forever/mus_c_undercity_2.mp3#8181005#2",
		"forever/mus_c_undercity_3.mp3#8181007#2",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_undercity_intro_moment.mp3#8181009",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Scarlet Enclave"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Scarlet Enclave"], prefol,
		"|cffffd800", "|cffffd800" .. "Scarlet Enclave",
		"musical moments/mystery/mystery01-zone.mp3#53240",
		"musical moments/mystery/mystery02-zone.mp3#53241",
		"musical moments/mystery/mystery03-zone.mp3#53242",
		"unknown/1.15.7 - raid - scarlet enclave - general - walk_6865484.mp3#6865484",
		"unknown/1.15.7 - raid - scarlet enclave - general - walk_6865486.mp3#6865486",

		"|cffffd800", "|cffffd800" .. "New Avalon, Arcane Sanctum",
		"musical moments/mystery/mystery04-zone.mp3#53243",
		"musical moments/mystery/mystery05-zone.mp3#53244",
		"musical moments/mystery/mystery06-zone.mp3#53245",
		"unknown/1.15.7 - raid - scarlet enclave - new avalon - walk_6865468.mp3#6865468",
		"unknown/1.15.7 - raid - scarlet enclave - new avalon - walk_6865470.mp3#6865470",
		"unknown/1.15.7 - raid - scarlet enclave - new avalon - walk_6865472.mp3#6865472",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Scarlet Monastery"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Scarlet Monastery"], prefol,
		"|cffffd800", "|cffffd800" .. "Scarlet Monastery",
		"forever/mus_c_cursed_land_4.mp3#8180744",
		"forever/mus_c_cursed_land_5.mp3#8180746",
		"forever/mus_c_cursed_land_6.mp3#8180748",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Scholomance"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Scholomance"], prefol,
		"|cffffd800", "|cffffd800" .. "Scholomance",
		"forever/mus_c_haunted_1.mp3#8181313",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Shadow Hold"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Shadow Hold"], prefol,
		"|cffffd800", "|cffffd800" .. "Felwood",
		"forever/mus_c_cursed_land_1.mp3#8180738",
		"forever/mus_c_cursed_land_3.mp3#8180742",

		"|cffffd800", "|cffffd800" .. "Ameth'Aran",
		"forever/mus_c_haunted_1.mp3#8181313",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_haunted_2.mp3#8181315",
		"forever/mus_c_gloomy_1.mp3#8181325",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Shadowfang Keep"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Shadowfang Keep"], prefol,
		"|cffffd800", "|cffffd800" .. "Shadowfang Keep",
		"forever/mus_c_day_evil_forest_1.mp3#8180772",
		"forever/mus_c_day_evil_forest_3.mp3#8180776",
		"forever/mus_c_night_evil_forest_1.mp3#8180758",
		"forever/mus_c_day_evil_forest_2.mp3#8180774",
		"forever/mus_c_night_evil_forest_2.mp3#8180760",
		"forever/mus_c_night_evil_forest_3.mp3#8180762",
		"forever/mus_c_mystery_3.mp3#8180937",
		"forever/mus_c_mystery_4.mp3#8180939",
		"forever/mus_c_mystery_10.mp3#8180951",
		"forever/mus_c_mystery_5.mp3#8180941",
		"forever/mus_c_mystery_2.mp3#8180935",
		"forever/mus_c_mystery_6.mp3#8180943",
		"forever/mus_c_mystery_7.mp3#8180945",
		"forever/mus_c_mystery_8.mp3#8180947",
		"forever/mus_c_mystery_9.mp3#8180949",
		"forever/mus_c_mystery_1.mp3#8180933",
		"forever/mus_c_battle_4.mp3#8180905",
		"forever/mus_c_battle_1.mp3#8180899",
		"forever/mus_c_battle_2.mp3#8180901",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_haunted_2.mp3#8181315",
		"forever/mus_c_spooky_1_moment.mp3#8181333",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Starfall Barrow Den"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Starfall Barrow Den"], prefol,
		"|cffffd800", "|cffffd800" .. "Starfall Barrow Den",
		"forever/mus_c_darnasssus_walking_1.mp3#8180752",
		"forever/mus_c_darnasssus_walking_2.mp3#8180754",
		"forever/mus_c_darnasssus_walking_3.mp3#8180756",

		"|cffffd800", "|cffffd800" .. L["Intro Music"],
		"forever/mus_c_druid_grove.mp3#8181323",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Storm Cliffs"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Storm Cliffs"], prefol,
		"|cffffd800", "|cffffd800" .. "Storm Cliffs",
		"forever/mus_c_day_barren_dry_3.mp3#8181053",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Stratholme"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Stratholme"], prefol,
		"|cffffd800", "|cffffd800" .. "Stratholme",
		"forever/mus_c_undercity_1.mp3#8181003",
		"forever/mus_c_undercity_2.mp3#8181005",
		"forever/mus_c_undercity_3.mp3#8181007",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Tainted Scar"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Tainted Scar"], prefol,
		"|cffffd800", "|cffffd800" .. "Tainted Scar",
		"forever/mus_c_day_barren_dry_3.mp3#8181053",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Temple of Atal'Hakkar"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Temple of Atal'Hakkar"], prefol,
		"|cffffd800", "|cffffd800" .. "The Temple of Atal'Hakkar",
		"forever/mus_c_day_jungle_1.mp3#8181259",
		"forever/mus_c_day_jungle_2.mp3#8181261",
		"forever/mus_c_day_jungle_3.mp3#8181263",
		"forever/mus_c_night_jungle_1.mp3#8181265",
		"forever/mus_c_night_jungle_2.mp3#8181267",
		"forever/mus_c_night_jungle_3.mp3#8181269",
		"forever/mus_c_soggy_place_zone_2.mp3#8181013",
		"forever/mus_c_soggy_place_zone_5.mp3#8181019",
		"forever/mus_c_soggy_place_zone_1.mp3#8181011",
		"forever/mus_c_soggy_place_zone_3.mp3#8181015",
		"forever/mus_c_soggy_place_zone_4.mp3#8181017",

		"|cffffd800", "|cffffd800" .. "Lair of the Chosen",
		"forever/mus_c_battle_2.mp3#8180901",

		"|cffffd800", "|cffffd800" .. "The Pit of Sacrifice",
		"forever/mus_c_battle_6.mp3#8180909",

		"|cffffd800", "|cffffd800" .. "Chamber of the Dreamer",
		"forever/mus_c_battle_5.mp3#8180907",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Wailing Caverns"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Wailing Caverns"], prefol,
		"|cffffd800", "|cffffd800" .. "The Wailing Caverns",
		"forever/mus_c_cursed_land_4.mp3#8180744",
		"forever/mus_c_cursed_land_5.mp3#8180746",
		"forever/mus_c_cursed_land_6.mp3#8180748",

		"|cffffd800", "|cffffd800" .. "Cavern of Mists",
		"forever/mus_c_day_jungle_1.mp3#8181259",
		"forever/mus_c_day_jungle_2.mp3#8181261",
		"forever/mus_c_day_jungle_3.mp3#8181263",
		"forever/mus_c_night_jungle_1.mp3#8181265",
		"forever/mus_c_night_jungle_2.mp3#8181267",
		"forever/mus_c_night_jungle_3.mp3#8181269",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Zul'Farrak"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Zul'Farrak"], prefol,
		"|cffffd800", "|cffffd800" .. "Zul'Farrak",
		"forever/mus_c_day_desert_1.mp3#8181127",
		"forever/mus_c_day_desert_2.mp3#8181129",
		"forever/mus_c_day_desert_3.mp3#8181131",
		"forever/mus_c_night_desert_1.mp3#8181133",
		"forever/mus_c_night_desert_2.mp3#8181135",
		"forever/mus_c_night_desert_3.mp3#8181137",
	})

	Zn(L["Dungeons"], L["World of Warcraft"], L["Zul'Gurub"], {"|cffffd800" .. L["Dungeons"] .. ": " .. L["Zul'Gurub"], prefol,
		"|cffffd800", "|cffffd800" .. "Zul'Gurub",
		"forever/mus_c_day_jungle_1.mp3#8181259",
		"forever/mus_c_day_jungle_2.mp3#8181261",
		"forever/mus_c_day_jungle_3.mp3#8181263",
		"forever/mus_c_night_jungle_1.mp3#8181265",
		"forever/mus_c_night_jungle_2.mp3#8181267",
		"forever/mus_c_night_jungle_3.mp3#8181269",

		"|cffffd800", "|cffffd800" .. "Temple of Bethekk",
		"forever/mus_c_swamp_1.mp3#8181335",

		"|cffffd800", "|cffffd800" .. "The Bloodfire Pit",
		"forever/mus_c_zulgurub_voodoo.mp3#8181341",
	})

	----------------------------------------------------------------------
	-- Various
	----------------------------------------------------------------------

	Zn(L["Various"], L["Various"], "|cffffd800" .. L["Various"], {""})

	Zn(L["Various"], L["Various"], L["Battlegrounds"], {"|cffffd800" .. L["Various"] .. ": " .. L["Battlegrounds"], prefol,
		"|cffffd800", "|cffffd800" .. L["Alterac Valley"],
		"forever/mus_c_cursed_land_1.mp3#8180738#1",
		"forever/mus_c_cursed_land_2.mp3#8180740",
		"forever/mus_c_cursed_land_3.mp3#8180742#1",
		"forever/mus_c_cursed_land_4.mp3#8180744",
		"forever/mus_c_cursed_land_5.mp3#8180746",
		"forever/mus_c_cursed_land_6.mp3#8180748",
		"forever/mus_c_gloomy_1.mp3#8181325",

		"|cffffd800", "|cffffd800" .. L["Arathi Basin"],
		"forever/mus_c_battle_6.mp3#8180909",
		"forever/mus_c_cursed_land_1.mp3#8180738#2",
		"forever/mus_c_cursed_land_3.mp3#8180742#2",

		"|cffffd800", "|cffffd800" .. L["Darkspear Islands"],
		"forever/mus_c_pvp_2.mp3#8181023#1",
		"forever/mus_c_pvp_1.mp3#8181021#1",
		"forever/mus_c_pvp_3.mp3#8181025#1",
		"forever/mus_c_pvp_4.mp3#8181027#1",
		"forever/mus_c_pvp_5.mp3#8181029#1",

		"|cffffd800", "|cffffd800" .. L["Warsong Gulch"],
		"forever/mus_c_pvp_2.mp3#8181023#2",
		"forever/mus_c_pvp_1.mp3#8181021#2",
		"forever/mus_c_pvp_3.mp3#8181025#2",
		"forever/mus_c_pvp_4.mp3#8181027#2",
		"forever/mus_c_pvp_5.mp3#8181029#2",
	})

	Zn(L["Various"], L["Various"], L["Cinematics"], {"|cffffd800" .. L["Various"] .. ": " .. L["Cinematics"], prefol,
		"|cffffd800", "|cffffd800" .. L["World of Warcraft"],
		"|Cffffffff" .. L["Ten Years of Warcraft"] .. " |r#625988", -- interface/cinematics/logo.mp3
		"|Cffffffff" .. L["World of Warcraft"] .. " |r#625564", -- interface/cinematics/wow_intro.mp3
		"|Cffffffff" .. L["New Horizons"] .. " |r#8510709", -- interface/cinematics/for_160_cm.mp3
	})

	Zn(L["Various"], L["Various"], L["Credits"], {"|cffffd800" .. L["Various"] .. ": " .. L["Credits"], prefol,
		"|cffffd800", "|cffffd800" .. L["World of Warcraft"],
		"forever/mus_c_stormwind_intro_moment.mp3#8180884",
	})

	Zn(L["Various"], L["Various"], L["Main Titles"], {"|cffffd800" .. L["Various"] .. ": " .. L["Main Titles"], prefol,
		"|cffffd800", "|cffffd800" .. L["World of Warcraft"],
		"sound/ui/mus_1_0_maintitle_original_0_8176610.ogg#8176610",
	})

	Zn(L["Various"], L["Various"], L["Narration"], {"|cffffd800" .. L["Various"] .. ": " .. L["Narration"], prefol,
		"|cffffd800", "|cffffd800" .. L["Narration"],
		"sound/cinematicvoices/dwarfnarration.mp3#222759",
		"sound/cinematicvoices/gnomenarration.mp3#222760",
		"sound/cinematicvoices/humannarration.mp3#222761",
		"sound/cinematicvoices/nightelfnarration.mp3#222762",
		"sound/cinematicvoices/orcnarration.mp3#222763",
		"sound/cinematicvoices/taurennarration.mp3#222764",
		"sound/cinematicvoices/trollnarration.mp3#222765",
		"sound/cinematicvoices/undeadnarration.mp3#222766",
	})

	----------------------------------------------------------------------
	-- End
	----------------------------------------------------------------------

	-- Give zone table a file level scope (its used in search)
	Leatrix_Plus["ZoneList"] = ZoneList
