<h1 align="center">GatherRadar</h1>

<p align="center">
  <b>Herb & ore tracker for World of Warcraft: herbs, mining nodes, treasure and fishing pools on your minimap and world map</b>
</p>

<p align="center">
<a href="https://github.com/Pirson-s-Addons/GatherRadar/releases/latest">
<img src="https://img.shields.io/github/v/release/Pirson-s-Addons/GatherRadar?style=for-the-badge&color=A78BFA">
</a>
<img src="https://img.shields.io/badge/WoW_Forever-1.60.1-C4B5FD?style=for-the-badge">
<a href="LICENSE">
<img src="https://img.shields.io/badge/License-MIT-E9D5FF?style=for-the-badge">
</a>
</p>

<p align="center">
<a href="README.es.md">🇪🇸 Español</a>
</p>

---

## What it does

**GatherRadar** turns Find Herbs, Find Minerals, Find Treasure and Find Fish into a real gathering radar. Every node on your minimap gets the **icon of what it gives** (Peacebloom, Copper Ore, a chest...) with a ring that tells you your chance of a skill-up. The minimap shows only what is **detected right now** for the professions you know, and every node you gather or see is **remembered** on the **world map**, so you can plan your farming route at a glance.

## Features

- **Minimap icons**: the real item icon on every herb, vein, chest and fishing pool, round, with a ring colored like the profession window (orange, yellow, green, gray; red if your skill is too low).
- **Remembers every node**: the ones you gather (exact position) and, optionally, the ones the scan sees on the minimap, to find them later on the world map.
- **World map pins** for every saved node of the zone. Shift + right-click a pin to delete it.
- **No duplicates**: two nodes of the same kind closer than 15 yards (you choose) are the same place and only one is kept.
- **Known nodes included**: one click imports the WoW Forever herbs, ore and treasure (Wowhead data from GatherMate2_Data) and fishing pools you are missing, the kinds you choose, no other addon needed. Your own nodes are never replaced.
- **Map filter**: a round button on the world map chooses which kinds (herbs, ore, treasure, fishing pools) are shown on the minimap and the world map. The arrow follows it too.
- **Arrow to the nearest node** with its name and distance, preferring what is on the minimap right now.
- **Party sharing**: group members with GatherRadar see the nodes you find, and you see theirs, live.
- **Session panel**: nodes gathered and materials obtained, with icons, totals and per hour.
- **Works in your language**: herbs, ore, treasure and fishing pools are recognized by their in-game name in every official language; nodes new to Forever are learned as you gather.
- Settings in the game's own **Options → AddOns** panel, 20 languages, no libraries.

## Installation

1. Download the zip from [CurseForge](https://www.curseforge.com/wow/addons/gather-radar) or the [latest release](https://github.com/Pirson-s-Addons/GatherRadar/releases/latest).
2. Extract the `GatherRadar` folder into `World of Warcraft/_classic_beta_/Interface/AddOns/`.
3. Restart WoW and enable the addon.

## Usage

- Turn on **Find Herbs**, **Find Minerals**, **Find Treasure** or **Find Fish** in the minimap tracking menu. GatherRadar does the rest.
- `/gr` opens the settings. `/gr session` shows the session panel, `/gr arrow` the arrow, `/gr import` imports the Wowhead nodes.
- **Options → AddOns → GatherRadar → General**: what to show and where, the radar and the icon sizes.
- **Options → AddOns → GatherRadar → Data**: saved nodes, duplicates, import (choose the kinds), delete and forget everything.

## Notes

- Addons cannot ask the game where nodes are: GatherRadar reads the minimap with a virtual mouse, the same dots you see. Without a tracking spell turned on, GatherRadar shows nothing on the minimap; saved nodes are still on the world map.
- Fishing pools are saved from the minimap only (fishing loot comes from the bobber, not the pool).
- Nodes new to WoW Forever (Cold Iron Deposit, Dreamroot...) are recognized in English; in other languages their name is learned the first time you gather them. Herbs with an extra word in their name (Wilted Peacebloom) count as the herb.

---

**Author**: Pirson · [GitHub](https://github.com/Pirson-s-Addons) · [CurseForge](https://www.curseforge.com/members/pirson/projects) · MIT License
