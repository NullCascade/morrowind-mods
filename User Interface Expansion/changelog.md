## Changelog

### In Development

- Inventory menu:
	- Fixed issue where filtering for tradeable items would still be shown even when not bartering.
- Tooltips:
	- Improved icon bars in tooltips. The position of icon bars can now be customized.
- Stats menu:
	- Fixed resistances not counting when showing attribute damage.
- Map menu:
	- Map expansion is now enabled by default.
	- Extra map controls are disabled when the map is pinned.
	- The map mode (local/world) will now toggle if the cell type has changed. Generally improved the behavior of the mechanic.
- Console menu:
	- Ctrl+Tab toggles the script mode.
	- Long script input will now wrap instead of overflowing.
- Removed textInput module. This is now handled by MWSE directly.
- Improved the way that search focusing behavior.
- Rewrote many aspects of the codebase to make use of newer MWSE functionality.
- Various other bug fixes and minor changes.

Contributors: abot, Assumeru, NullCascade, Petethegoat, sirrus233

### 1.7.3

- Bugfix. Disable direct item transfers when pickpocketing.

### 1.7.2

- Bugfix for drawing markers when imported unextended saves.

### 1.7.1

- The mod will now warn you if you have the map expansion enabled, but did not correctly install the required DLL file.

### 1.7.0

- New module: Map Expansion. Expands the world map to cover a much larger area. The map can be zoomed smoothly, and panning behaves much better than vanilla.

### 1.6.4

- Fixed crash when dealing with a barter reference that is deleted.

### 1.6.3

- Added support for HD class images in tooltips.
- Changed weapon damage ordering to vanilla's chop/slash/thrust.
- Added metadata file for improved mod dependency checks.

### 1.6.2

- Fixed console's input box having focus when the console is hidden.
- Fixed numbering of choices to be consistent and not fail if the choice text begins with numbers.

### 1.6.1

- Added class images to character sheet class tooltips.
- Made console history function better.
- Key press events are triggered when using text input. Allow copying/pasting into things like search bars to update properly.
- Updated to use standardized MWSE placeholder text on search bars. Improves the behavior of them as a result.
- Fixed issue when showing the save menu in wilderness cells that lack a region.
- Fixed issue where deleting a save would duplicate the character list.
- Fixed tooltip for power cooldowns.
- Internal code improvements.

### 1.6.0

- Changed everything to use MWSE's new `mwse.loadTranslations`/i18n support. This broke existing translation files, but makes adding new ones much cleaner and reliable.
- Allow searching inventory, contents, barter, item select, and magic menus by effect, type names, and contained souls. Example: Searching "restore" can show you amulets that can restore health, even if their name doesn't mention it.
- Added more keyboard convenience functions to text input, like text jumping with home/end/control.
- Spell service menu: Added spell icons. Spells with unknown effects are highlighted, much like unique dialogs are.
- Added filtering/searching to the magic select menu.
- Made it so that map switching, scroll bar manipulation, dialog filtering, or inventory taking doesn't trigger when typing in a text box.
- Improved compatibility with other UI-altering mods.
- Added `cls()` console function to clear the console.
- Tooltip fixes.
- Fixed issue where search text could be backspaced into the placeholder text.
- Removed close functionality using spacebar. Use right click menu exit mod instead.
- Fixed take all key binding.
- Codebase cleanup.
- Improved compatibility with NPC soultrapping.
- Improved selection of dialogue answers using the number keys.
- Display player dialogue choices in the menu.

### 1.5.2

- Improvement: Console functions that return multiple values will have all values printed.
- Improvement: Console lua functions that span multiple lines now run correctly and consecutively.
- Fix: Console no longer errors out when copy/pasting from an empty input box.

### 1.5.1

- Bug Fix: Corrected power names not always being accurate.
- Bug Fix: Fixed use of accidental global variable in training module.

### 1.5

- Feature: Added copy & paste module. Allows any text input to be copied from or pasted to using ctrl+c and ctrl+v.
- Feature: Added persistent console history. A configurable amount (default: 10) of the last console commands are saved and available between game sessions.
- Feature: Show what hour the player will rest or wait until in the rest/wait menu.
- Improvement: Redid mod config menu to expose more customization to users.
- Improvement: Made cell change map toggles configurable.
- Improvement: Reduced amount of less-useful info that was logged.
- Improvement: Repeated console commands are no longer added to the history.
- Bug Fix: Ensured that unused translations didn't remain in memory.
- Bug Fix: Stopped durability bars from showing up for thrown weapons and bolts.
- Bug Fix: Fixed potential crash when using number keys to answer dialog choices.
- Known Issue: Not all translation keys have been updated for the new MCM.

### 1.4

- Allow modders to intercept console commands.
- Minor updates to make use of MWSE changes.
- Sort spell service list.

### 1.3

- Fixed typo (thanks abot)
- Added optional value/weight icon to tooltips by Necrolesian
- Added UIEXP:sandboxConsole event so others can add easy extensions to it
- Added Deutsche translation by Monsterzeichner
- Added config option to prevent filters from being reset when entering the menus.
- Added effect icons to magic items in the spell list.
- Better positioned the clear filters icon in the search bar.

### 1.2.1

- Used powers in the spell list are now dulled out. Tooltips display how many hours remain until recharge.
- Improved ownership access detection when transfering items.
- Fix invalid memory pointer in new save menu. Fixes incompatibility with Wine.
- Fix errors when trying to focus search before the magic menu is enabled during character generation.

### 1.2

- Magic menu now shows an icon of the first effect in the spell.
- Added new skill training UI with high resolution skill icons.
- Ingredient selection window now grays out icons if no (known) effects match other used ingredients.
- Filled soul gem selection menu now shows the souls in the soul gem without having to look at tooltips.
- Added numeric hotkeys/prefix to dialog choices.
- Added automatic map compatibility with abot's Smart Map.
- Added clear/clickable icon for search fields.
- Fixes to soul gem tooltips.
- Added French and Russian translations.
- Improved Ashfall compatibility with publicans.

