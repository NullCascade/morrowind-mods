=====================================================================================
                                Consistent Enchanting
                                 Author: NullCascade
                                    Version 1.3.0
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

 This mod ensures that information is preserved when enchanting an item. The item's
 script, script variables, condition, and any lua data will get moved over to the
 newly enchanted item.

 Additionally, the lua data variable ncceEnchantedFrom is available on enchanted
 items to preserve the ID (pre-lowercased) of the item that it used to be before
 being enchanted.

=====================================================================================
 INSTALLATION:
=====================================================================================

 Extract the archive into your Morrowind installation directory.

=====================================================================================
 PLAYING THIS PLUGIN:
=====================================================================================

 There is no esp file to activate. Simply install the MWSE 2.1 and this mod, and
 load up an old or new game.

 Previously enchanted items won't have the ncceEnchantedFrom data.

=====================================================================================
 KNOWN ISSUES OR BUGS:
=====================================================================================

 None. Please report any issues on the Nexus page or at GitHub:
    https://github.com/NullCascade/morrowind-mods/issues

=====================================================================================
 VERSION HISTORY
=====================================================================================

 1.3.0 [unpublished]:
    * Modernized mod's structure. Added metadata file and localization support.

 1.2.0 [2022-03-05]:
    * Blacklist enchanted books, until MWSE can create a patch that makes them not break the magic selection when they have item data.

 1.1.1 [2021-08-05]:
    * Fixed MCM setting for toggling soul preservation.

 1.1.0 [2021-07-09]:
    * Added preservation of the soul used to enchant the item.

 1.0.0 [2021-07-08]:
    * Initial release.

=====================================================================================
 INCOMPATIBILITIES & SAVED GAME WARNINGS:
=====================================================================================

 If a conflict is found, please report it on the Nexus or on
 GitHub.

=====================================================================================
 CREDITS & USAGE:
=====================================================================================

 The plugin is documented to help new MWSE-Lua modders learn how to make this style
 of mod. It is MIT licensed. Please use it to learn and make cool things!

 Special thanks to Greatness7 for his help in progressing MWSE 2.1, to sveng for his
 help testing, and to DarkElfGuy for inspiring people to create and release mods for
 the yearly modathon.

 Copyright 2021 NullCascade

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
