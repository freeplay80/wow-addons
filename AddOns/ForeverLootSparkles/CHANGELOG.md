# Changelog

## 1.3.1

- The addon no longer touches your outline mode, so the Self Highlight outline around your character works again. It only keeps the loot sparkle switched on. Up to 1.3.0 it switched the outline mode off; pick it again under Options > Graphics if you want it back.
- Fixed: searching the game's Options (e.g. for "name" or "display") with the addon enabled raised `ADDON_ACTION_FORBIDDEN … IsUserOAuthed()` and blamed ForeverLootSparkles. The restart reminder is no longer a line in the options panel; it is printed in chat when you switch the sparkles off.
- Fixed: the addon no longer switches on all of **Interact Key Icons**, which put icons on every chair and NPC. It only keeps the icons on world objects, which the herb and ore sparkle needs; the rest goes back to what you had before 1.2.0.
- Fixed: **Enable Interact Key** and the icons on world objects are no longer switched back on at every login and `/reload`. The addon turns them on when the sparkles start and when you tick a sparkle checkbox; if you switch them off afterwards, they stay off (and nodes and corpses don't sparkle).

## 1.3.0

- Corpses that still hold loot for you sparkle as you approach them after the fight, bosses included (the game's own loot sparkle left boss corpses out). New checkbox "Corpses with loot" (on; off if you had switched all sparkles off before).
- Fewer Lua errors blaming ForeverLootSparkles ("GetAuraDataByIndex(): Auras cannot be accessed when secret while tainted", seen on level up): the soft targeting console variables are now only written when their value actually changes.

## 1.2.1

- Fixed: killed mobs kept a nameplate with 0% health until they were looted. The soft target nameplate is now switched off when combat starts, so nodes don't sparkle during combat.

## 1.2.0

- Ore veins and herbs sparkle as you approach them, using Blizzard's soft targeting (adapted from Lueur). The glints are dim out of reach, brighten in reach and turn grey when the node can't be gathered.
- The game's soft target icons are switched on (also for world objects), and the soft target range is set to the maximum.
- New checkboxes under Options > AddOns > Forever Loot Sparkles: Ore veins and Herbs (on), Quest objects (off).
- The soft targeting console variables are saved and restored once all three are switched off.

## 1.1.1

- Addon icon in the addon list.
- The addon list shows "dev" instead of the raw version placeholder when running from a source checkout.

## 1.1.0

- Options panel under Esc > Options > AddOns > Forever Loot Sparkles with a checkbox to switch the sparkles on or off (on by default).
- Switching it off turns the loot sparkle off and sets the outline mode back to High.
- Switching it on works at once; switching it off takes effect after restarting the game (`/reload` is not enough), and the panel shows a reminder.

## 1.0.0

- Initial release: quest items always sparkle. The addon turns the outline mode off and the loot sparkle on at login, and again whenever a graphics change resets them.
