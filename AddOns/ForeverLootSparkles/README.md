# Forever Loot Sparkles

<img src="https://raw.githubusercontent.com/svengabr/ForeverLootSparkles/main/media/logo.png" alt="ForeverLootSparkles logo" width="128">

A small addon for **World of Warcraft: Forever** that makes lootable things sparkle, so you never walk past them.

- **Quest items** always show the game's loot sparkle, even after a graphics preset turns it off.
- **Herbs and ore veins** sparkle as you approach them, which the game can't do on its own.
- Everything is optional, under Esc > Options > AddOns. No slash commands, nothing to set up.

![Forever Loot Sparkles](https://raw.githubusercontent.com/svengabr/ForeverLootSparkles/main/media/gallery/01-overview.jpg)

## Quest item sparkles

Graphics presets switch the game's loot sparkle off, so the addon switches it back on at login, and again about a second after any graphics change resets it. Your outline mode, and with it the Self Highlight outline around your character, is left as you set it. During combat it waits until the fight is over.

![Survives graphics presets](https://raw.githubusercontent.com/svengabr/ForeverLootSparkles/main/media/gallery/02-presets.jpg)

## Herb and ore sparkles

The game has no sparkle for ore veins and herbs, so the addon adds its own. As you approach a node, a small cluster of golden glints twinkles over it.

- **Out of reach:** the glints are dim.
- **In reach:** they brighten with a short burst, so you know you can gather now.
- **Can't gather:** they turn grey, for example when your skill is too low.

This uses Blizzard's soft targeting, which picks the nearest interactable object around you, up to about 15 yards away. Only one node sparkles at a time: the one the game would interact with. Quest objects can get the same treatment, but that is off by default, since the loot sparkle above already marks most of them.

The addon only switches on the game's nameplate for nodes that sparkle. NPCs, mailboxes and other objects still work with the interact key as usual.

Soft targeting is the game's **Enable Interact Key** setting, and the sparkle hangs on the nameplate the game only gives world objects while their interact icons are on. The addon switches both on when the sparkles start and whenever you tick one of the checkboxes below, so the node you're heading for also shows the game's gathering icon. If you switch them off yourself afterwards, they stay off, and nodes and corpses don't sparkle. During combat nodes don't sparkle; they come back as soon as the fight is over.

## Corpse sparkles

The game's loot sparkle leaves some corpses out, bosses among them. Once the fight is over, a corpse that still holds loot for you gets the same golden glints as you approach it. The game doesn't let addons say what is in a corpse before it is opened, so the glints only say "there is loot left", not what it is.

![Herbs and ore sparkle too](https://raw.githubusercontent.com/svengabr/ForeverLootSparkles/main/media/gallery/04-gathering.jpg)

## Options

Open **Esc > Options > AddOns > Forever Loot Sparkles**.

| Checkbox | Default | What it does |
| --- | --- | --- |
| Show quest item sparkles | on | Keeps the loot sparkle on. |
| Ore veins | on | Sparkles on mining nodes. |
| Herbs | on | Sparkles on herbs. |
| Quest objects | off | Extra sparkles on quest objects nearby. |
| Corpses with loot | on | Sparkles on corpses that still hold loot for you, after the fight. |

The four bottom checkboxes take effect at once. **Show quest item sparkles** works at once when you switch it on, but switching it off only takes effect after **restarting the game** (`/reload` is not enough). A reminder appears in chat.

![Options](https://raw.githubusercontent.com/svengabr/ForeverLootSparkles/main/media/gallery/03-options.jpg)

## Install

1. Download the latest release zip, or install it with the CurseForge app.
2. Extract it so you have `World of Warcraft\_classic_beta_\Interface\AddOns\ForeverLootSparkles`.
3. Restart the game or type `/reload`.

## FAQ

**Why don't herbs get the same sparkle as quest items?**
The game has no setting for that. The quest item sparkle replaces the outline that quest items have, and herbs and ore have no such outline. That is why the addon draws its own glints instead.

**Can the range be larger than 15 yards?**
The addon asks the game for the largest range, but the game itself drops the target at about 15 yards.

**I see an icon above NPCs, chairs or other objects.**
That comes from the game's **Interact Key Icons** setting (Accessibility). Versions up to 1.3.0 switched on all of it, chairs and NPCs included. Now the addon only switches on the icons on world objects, which the sparkle needs, and put the rest back to what you had before. Pick "Default" there if you still see them.

**Why don't nodes sparkle during combat?**
The game doesn't let addons change these settings during combat. Keeping the sparkle on through a fight would also show a 0% health nameplate over every lootable corpse, so the addon switches it off when combat starts.

**The corpse I walk up to shows a name and health bar.**
That is the game's own nameplate, which the corpse sparkle hangs on. Only the one corpse the game would loot next gets it, and only while it still holds loot for you. Untick **Corpses with loot** if you'd rather not see it.

**Does it work together with Lueur?**
Don't run both at once. They change the same soft targeting settings and get in each other's way.

## Turning it off again

The easiest way is the checkboxes under Options (see above), which put the settings back for you. Untick all of them before you disable the addon.

Disabling the addon in the addon list does **not** undo the settings, because WoW saves console variables itself. After disabling it, either pick a graphics preset again, or type:

```
/console outlineModeShowLootEffectWhenDisabled 0
```

Then restart the game.

The soft targeting settings are put back as soon as **Ore veins**, **Herbs**, **Quest objects** and **Corpses with loot** are all off.

## What it sets

For the quest item sparkles:

| Console variable | Value |
| --- | --- |
| `outlineModeShowLootEffectWhenDisabled` | 1 |

Versions up to 1.3.0 also switched the outline mode off. If you want it back, pick it under Options > Graphics (Outline Mode), or type `/console graphicsOutlineMode 2`.

For the herb and ore sparkles, while at least one of their checkboxes is on (the original values are saved and restored):

| Console variable | Value |
| --- | --- |
| `SoftTargetInteract` | 3, once (stays as you set it afterwards) |
| `SoftTargetInteractRange` | 60 (the game still stops at about 15 yards) |
| `SoftTargetInteractArc` | 2 |
| `SoftTargetInteractOnlyInRange` | 0 |
| `SoftTargetIconGameObject` | 1, once (stays as you set it afterwards) |
| `SoftTargetNameplateInteract` | 1 on a node that sparkles, otherwise 0 |

## Support

The addon is free and always will be. If it made your game a bit nicer, you can [buy me a coffee](https://buymeacoffee.com/conoar).
