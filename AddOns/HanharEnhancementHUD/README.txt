HANHAR ENHANCEMENT HUD 2.2.4
An all-in-one HUD for Enhancement shamans in World of Warcraft: Forever.
By Roman A. Vitanza.

Type /ehud in game to open the settings window. Everything below can be
changed there; the slash commands at the end are shortcuts.


=============================================================================
1. WHAT'S ON THE HUD
=============================================================================

  Top row          Weapon imbue timer, Lightning Shield (charges and time),
                   Reincarnation cooldown with your Ankh count. Flurry on the
                   right.
  Cooldown row     The spells you pick on the Tracking tab: Stormstrike, your
                   shocks, Fire Nova. An icon turns red when your target is
                   out of that spell's range.
  Totem row        Fire, Earth, Water and Air. Timers for the totems you
                   track. Shows FAR with a red border when you've walked out
                   of a totem's range.
  Swing bar        Main-hand swing timer. Shows NOT ATTACKING when you're in
                   combat with an enemy targeted and your weapon stops
                   swinging (out of range, facing away, auto-attack off).
  Flame Shock bar  Time left on your Flame Shock on the current target.
                   Turns red near the end and shows REAPPLY at zero.
  Stormstrike bar  Time left on Stormstrike's nature damage bonus.

  Test mode (button on the settings window, or /ehud test) fills the HUD
  with sample data for 15 seconds so you can see and place everything.


=============================================================================
2. ALERTS
=============================================================================

  WINDFURY!               a Windfury proc
  Totem down              a totem you track died before its time ran out
  Pre-pull reminder       in a dungeon or raid, when you target an enemy out
                          of combat: "Drop: Windfury. Refresh: Lightning
                          Shield, imbue (2m left)." Covers totems you've
                          starred plus a missing or 1-charge Lightning Shield
                          and an imbue that's missing or under 2 minutes.
  No weapon imbue         entering combat without one
  Imbue expiring          under 60 seconds (adjustable)
  Flame Shock expired     in combat
  Out of Ankhs            when your last Ankh is used or sold
  NOT ATTACKING           see the swing bar above
  Totems out of range     "Out of range: Windfury. Resummon!" in combat
  Ready check             "Missing: Flask, Mark of the Wild" (see below)

  Alerts are on-screen text only. Each alert has its own text and sound
  switches and a choice of four sounds (Alerts tab). Unlock the HUD to drag
  the alert text anywhere; its size is on the Alerts tab. The only things
  the HUD ever posts to a chat channel are the optional HEH, Mark, Vark,
  67 and Let It Ride replies.

  In chat after each fight: "Windfury: 7 procs in 42 swings (17%)." New
  personal bests get their own line (most procs in a fight, best rate over
  15+ swings, longest back-to-back proc streak).


=============================================================================
3. SETTINGS WINDOW
=============================================================================

  Open it with /ehud, the minimap button, the AddOns dropdown by the
  minimap, or Options > AddOns > Hanhar Enhancement HUD. Esc closes it.

  GENERAL
    Display     Lock the HUD (unlock it to drag the HUD and the alert text),
                nudge buttons (Shift-click moves 10 pixels), Center, scale,
                opacity out of combat.
    Auto-hide   While mounted, while resting, or out of combat unless an
                enemy is targeted. Never hides in combat or while unlocked.
    Show        Turn each section on or off.
    Keybinds    Show or hide the HUD, lock or unlock, test mode, open
                settings. Click a button, press a key; right-click clears.
                These win over WoW's own binding for the same key.
    Settings    "Remember my settings between launches." See section 5.

  TRACKING
    Cooldowns   Stormstrike, Earth Shock, Flame Shock, Frost Shock and Fire
                Nova always have a checkbox; ones you haven't learned are
                greyed out until you do. New shocks Forever adds appear too.
    Totems      Every totem you know, by element. Unchecked totems are
                hidden and never alert. Uncheck all of an element and its
                slot disappears. Click a totem's star to include it in the
                pre-pull reminder. New Forever totems sit under "Other" until
                you drop one, then the HUD learns their element.

  ALERTS
    Per-alert text and sound, sound choice, master sound switch, alert text
    size, and timing: imbue warning, totem pulse, and when the Flame Shock
    bar turns red. Ready check: what to check and how many elixirs you
    need, plus a "Check now" button.

  EXTRAS
    Swing and Windfury   NOT ATTACKING, fight summary, records
    Totems and buffs     totem range warning, pre-pull buff check,
                         Stormstrike bar
    Leveling             old-rank warning and "Check my bars now"
    Solo and group       separate setups that switch in dungeons and raids
    Chat and minimap     HEH, Mark, Vark, 67 and Let It Ride replies,
                         minimap button
    Share and save       per-character settings, export and import
    Diagnostics          the diagnostics log and its summary


=============================================================================
4. HOW IT WORKS WITH FOREVER'S COMBAT RULES
=============================================================================

  Forever runs on the modern WoW engine, which hides many combat numbers
  from addons during a fight. The HUD is built around that:

  - Cooldown and totem timers are drawn by Blizzard's own cooldown widget,
    which may show numbers addons can't read.
  - Your own spell casts stay readable, so imbue, shield, totem and debuff
    timers start from your casts and count on the HUD's own clock.
  - Lightning Shield charges used up mid-fight can't be seen, so the count
    shows "?" in combat. A resisted Flame Shock still starts its bar.
  - The swing timer uses the game's built-in swing event. A main-hand swing
    that lands far too early counts as a Windfury extra attack.
  - Flurry and buff-based checks work when the client allows buff reads,
    which may be out of combat only.
  - Totem range uses your position when it's readable, then the totem's
    buff, and otherwise stays quiet rather than guess.
  - The imbue is checked three ways (the weapon's imbue enchant, the older
    enchant check, a buff with the imbue's name). NONE means all three said
    no.

  If a section runs into something the client blocks, the HUD prints one
  line naming it and keeps running instead of spamming errors.


=============================================================================
5. SAVING SETTINGS (BACKUP IN MACROS)
=============================================================================

  The Forever beta wrote addon settings to disk but never read them back,
  so every addon started fresh after a game restart. As a safeguard, check
  "Remember my settings between launches" and the HUD also keeps your
  settings in general macros, which survive a restart either way:

    HanharHUD, HanharHUD2     your settings and tracking choices
    HanharHUD3, HanharHUD4    your other solo/group setup, if that's on

  With "Separate settings for this character" on (Extras tab), the same
  macros are this character's own, named HanharChar to HanharChar4, and
  every other shaman keeps using the account-wide set. Don't delete these
  macros. Unchecking "Remember" removes them. Changes made in combat are
  saved when the fight ends.

  Settings saved before 2.2.0, in macros named EnhanceHUD or EHUDchar, move
  to the new names by themselves the first time each character logs in.

  Sharing: Extras > Export setup gives one line of text to paste to another
  shaman, who uses Import setup. Keybinds, records and save choices are
  personal and never change on import.


=============================================================================
6. SOLO AND GROUP SETUPS
=============================================================================

  Optional (Extras tab). The HUD keeps two setups and swaps them when you
  enter or leave a dungeon or raid: position, scale, opacity, sections,
  auto-hide, tracked cooldowns and totems, pre-pull stars, Stormstrike bar
  and the pre-pull buff check. Alerts, keybinds and records are shared. Your
  first dungeon starts as a copy of your solo setup. /ehud setup solo or
  /ehud setup group switches by hand.


=============================================================================
7. UPDATES, FILES AND RESTARTS
=============================================================================

  WoW only loads addon files that existed when the game started. The HUD
  ships spare files so updates load with /reload:

    Slot01 to Slot10.lua   feature code (all in use; new features now go
                           into existing files, still /reload only)
    Media1 to Media3.tga   spare art
    icon.tga               the icon (AddOns list, minimap button, window)

  Only a change to HanharEnhancementHUD.toc needs a full restart. Don't
  delete the Slot or Media files. After an update, one chat line says
  what's new.

  File map:
    Compat.lua     safe wrappers for Forever's restricted API
    Core.lua       settings, HUD frame, alerts, visibility, /ehud
    Spellbook.lua  finds your shocks, totems and spell ranks
    Totems.lua     totem row and pre-pull reminder
    Swing.lua      swing timer, NOT ATTACKING, Windfury detection and stats
    Buffs.lua      imbue and Lightning Shield
    Procs.lua      cooldown row, range tint, Flurry
    Dots.lua       Flame Shock and Stormstrike bars
    Reinc.lua      Reincarnation and Ankhs
    Persist.lua    saving settings in macros
    Options.lua    the settings window
    Heh.lua        the HEH, Mark, Vark, 67 and Let It Ride replies
    Slot01         Windfury records      Slot06  old-rank warning
    Slot02         keybinds              Slot07  solo and group setups
    Slot03         AddOns menu, what's new   Slot08  logo, minimap button
    Slot04         totem range           Slot09  export and import
    Slot05         diagnostics log       Slot10  ready check


=============================================================================
8. DIAGNOSTICS
=============================================================================

  On by default. Counts what the client lets addons read, in and out of
  combat, in the open world and in instances: your position, buffs, totems,
  cooldowns, weapon speed, imbue, mana, swing events, and your target's
  GUID, range, debuffs and spellcasts. It also keeps short fight summaries
  (zone, length, swings, procs) and addon errors. No chat or names.

  The game writes it to:
    World of Warcraft\_forever_\WTF\Account\<account>\SavedVariables\HanharEnhancementHUD.lua
  when you log out or /reload. /ehud diag shows a summary.


=============================================================================
9. EXTRAS
=============================================================================

  Ready check       When your raid leader starts a ready check, a checklist
                    appears under the alert text for 20 seconds (click it to
                    close) with one alert line:
                      Food        the Well Fed buff
                      Flask       any flask
                      Elixirs     at least your chosen number (default 2):
                                  Mongoose, Giants, Juju, Firewater and more
                      Raid buffs  only from classes in your group: Fortitude
                                  (priest), Mark of the Wild (druid), Arcane
                                  Intellect (mage), a Blessing (paladin)
                      Your own    Lightning Shield and weapon imbue
                    Green is good, yellow is under 5 minutes left, red is
                    missing. It's screen-only. /ehud readycheck or "Check
                    now" runs it any time. In combat the game hides buffs,
                    so it says it couldn't check.

  Old spell ranks   Forever lists every rank separately and your bars keep
                    the rank you placed. After you train, the HUD lists
                    buttons that still hold an old rank, for example "Earth
                    Shock is rank 3 on bar 1, button 5. You know rank 4."
  Chat replies      When a guildmate's whole message is "HEH" (any case),
                    you answer "HEH." "Mark," "Vark" and "67" work the same
                    way, and "Let It Ride" gets "Let it Ride." If they run
                    this addon too, the replies go back and forth: up to 3
                    from you per volley, 1.5 seconds apart. Each word has
                    its own volley, which ends after 30 quiet seconds. Never answers you, quiet when the game
                    hides chat from addons. Works on every character, not
                    just shamans.


=============================================================================
10. COMMANDS
=============================================================================

  /ehud                        open settings (/hanhar works too)
  /ehud help                   list commands
  /ehud version                installed version
  /ehud test                   sample data for 15 seconds
  /ehud lock | unlock          lock or move the HUD
  /ehud scale 1.2              size, 0.5 to 2
  /ehud fade 0.6               out-of-combat opacity, 0 to 1
  /ehud imbue 60               seconds before the imbue warning
  /ehud sound                  master alert sound switch
  /ehud wf                     WINDFURY! alert text
  /ehud totems | swing | buffs | procs | dots | reinc    toggle a section
  /ehud stats                  Windfury fight summary
  /ehud records [on | off | reset]    Windfury records
  /ehud swingwarn              NOT ATTACKING warning
  /ehud rangecheck             what the totem range check can see
  /ehud ranks                  list old spell ranks on your bars
  /ehud setup solo | group     switch setups
  /ehud export | import        share your setup
  /ehud minimap                show or hide the minimap button
  /ehud readycheck             run the ready-check checklist now
  /ehud diag [clear | on | off]    diagnostics summary
  /ehud imbuecheck             what each imbue check reports
  /ehud heh (or mark, vark, 67, ride)  guild chat replies
  /ehud reset                  back to defaults
