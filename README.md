# Ultimate Records

A mod for [Dungeon Rampage Haxe](https://github.com/Tutez64/Dungeon-Rampage-Haxe): a board of your Ultimate Rampage floors, for every hero on every map.

<!-- drh:show -->
See at a glance how deep each of your heroes got on each Ultimate Rampage map, and where you still need a legendary chest this week. Handy to pick who plays which hero before a duo or trio run.

Open it from the **round chest button** under the options button, on the town's home screen.

- **This week:** each hero's floor on each map, as the game's server counts it for the week. A chest next to a floor is the map's legendary chest: bright once earned (floor 15 cleared), grey while still to get. The bottom row counts each hero's legendary chests, and the countdown shows when the week starts over.
- **Best ever:** the deepest floor each hero reached on each map, kept by this mod from the runs you play with it, plus this week's.
- **Recent runs:** your last 10 Ultimate Rampage runs: hero, map, deepest floor and when.

The deepest floor of each row is in gold.
<!-- /drh:show -->

## How it works

- **This week** reads the weekly scores the game's server already sends for the world map (`getIIAvatarScoreForNode`), so it includes runs played before the mod was installed.
- **Best ever** and **Recent runs** come from the floors the mod sees you enter in Ultimate Rampage. They are saved on every floor in `records.json`, in the mod's data folder.
- The board is the game's own town popup and buttons, from `db_UI_town.swf`, with its fonts and icons.

It reaches the game's own classes (popups, account scores), so it is an `extends` mod: a DRH update may break it.
