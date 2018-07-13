=====================================================================================
                               Controlled  Consumption                               
                                 Author: NullCascade                                 
                                    Version 1.2.1                                    
=====================================================================================

 INDEX:

 -> Requirements
 -> About this Mod
 -> Installation
 -> Playing this Plugin
 -> Known Bugs & Issues
 -> Version History
 -> Incompatibilities & Save Game Warnings
 -> Credits & Usage

=====================================================================================
 REQUIREMENTS:
=====================================================================================

 This is a MWSE-Lua mod, and requires a valid installation of MWSE 2.1 or later.

    * Morrowind, Tribunal, and Bloodmoon.
    * MGE-XE 0.10.0
    * MWSE 2.1

=====================================================================================
 ABOUT THIS MOD:
=====================================================================================

 This simple balance mod attempts to balance Morrowind's alchemy system by
 restricting how many potions the player can consume at once. By default this uses
 the same cooldown that NPCs must use, but supports custom modules.

 Currently there are 2 consumption modules to choose from:

  * Vanilla NPC: The default module. Like vanilla NPCs, the player can drink a new
    potion only once every 5 seconds. Attempting to drink a potion before 5 seconds
    have passed will show a message and prevent drinking.

  * Oblivion Style: This module attempts to replicate the behavior of Oblivion's
    consumption restrictions. The player is allowed to have up to 4 active potions,
    with the longest duration on the potion used for the cooldown calculation.

=====================================================================================
 INSTALLATION:
=====================================================================================

 Extract the archive into your Morrowind installation directory. The mod should
 contain the following files:
    .\Data Files\MWSE\lua\nc\consume\mod_init.lua
    .\Data Files\MWSE\lua\nc\consume\module\vanilla_npc.lua
    .\Data Files\MWSE\lua\nc\consume\module\oblivion.lua

  The nc_consume_config.json file can be used to configure the mod. Change the 
  module entry in the json file to "vanilla_npc" or "oblivion" to use that module.

=====================================================================================
 PLAYING THIS PLUGIN:
=====================================================================================

 There is no esp file to activate. Simply install the MWSE 2.1 and this mod, and
 load up an old or new game.

=====================================================================================
 KNOWN ISSUES OR BUGS:
=====================================================================================

 None. Please report any issues on the Nexus page or at GitHub:
    https://github.com/NullCascade/morrowind-mods/issues

=====================================================================================
 VERSION HISTORY
=====================================================================================

 1.2.1
    * Fixed mistake in readme file.

 1.2.0
    * Added support for MWSE's Mod Config Menu.
    * Fixed issue where saving and reloading would bypass restrictions.
    * Added visual representation next to the sneak indicator, showing if a potion
      can be consumed.
    * Made it so that resting or otherwise advancing game time also advanced the
      cooldown time.

 1.1.0
    * Ensured that the mod will only affect the player, with changes to MWSE 2.1.
    * The mod will not affect targeted potions anymore.
    * Added interop module so that other mods can suppress this one for a single
      consumption. This will get better when there is event prioritization.

 1.0.0 [2018-05-04]:
    * Initial release.

=====================================================================================
 INCOMPATIBILITIES & SAVED GAME WARNINGS:
=====================================================================================

 This mod does not alter the save game contents in any way, and is clean to run with
 any other known mod. If a conflict is found, please report it on the Nexus or on
 GitHub.

=====================================================================================
 CREDITS & USAGE:
=====================================================================================

 Special thanks to Greatness7 for his help in progressing MWSE 2.1 and to DarkElfGuy
 for inspiring people to create and release mods for the yearly modathon.

 Copyright 2018 Michael Wallar

 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in the
 Software without restriction, including without limitation the rights to use, copy,
 modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
 and to permit persons to whom the Software is furnished to do so, subject to the
 following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
 AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
