=====================================================================================
                                  Happy  Harvesting                                  
                                 Author: NullCascade                                 
                                    Version 1.1.0                                    
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

 This mod provides a very simple, generic-case auto-harvesting for organic
 containers in Morrowind. There are no graphic replacements. There are no fancy
 effects. It behaves just like the vanilla interaction with ingredients, save for
 that it auto-loots the inventory instead of opening the interface. It applies
 to any organic, unscripted container in the game. This makes it compatible with
 any graphic herbalism mod, it will just harvest anything that those mods miss.

=====================================================================================
 INSTALLATION:
=====================================================================================

 Extract the archive into your Morrowind installation directory. The mod consists of
 a single file, which should end up located at:
    .\Data Files\MWSE\mods\Happy Harvesting\main.lua

=====================================================================================
 PLAYING THIS PLUGIN:
=====================================================================================

 There is no esp file to activate. Simply install the MWSE 2.1 and this mod, and
 load up an old or new game. When you try to loot any unscripted, organic container
 the contents will be transferred to your inventory with a message of what was
 looted.

=====================================================================================
 KNOWN ISSUES OR BUGS:
=====================================================================================

 None. Please report any issues on the Nexus page or at GitHub:
    https://github.com/NullCascade/morrowind-mods/issues

=====================================================================================
 VERSION HISTORY
=====================================================================================

 1.1.0 [2009-04-10]:
    * Adapted to new MWSE folder structure.
    * Added ability to blacklist certain container IDs. Defaults to blacklisting
      Ahnassi's food and drink barrels.
    * Added Mod Config Menu support to allow for easy blacklisting.

 1.0.1 [2018-05-26]:
    * Fix function scope to prevent potential issues with other mods.

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

 The plugin is documented to help new MWSE-Lua modders learn how to make this style
 of mod. It is MIT licensed. Please use it to learn and make cool things!

 Special thanks to Greatness7 for his help in progressing MWSE 2.1 and to DarkElfGuy
 for inspiring people to create and release mods for the yearly modathon.

 Copyright 2018 NullCascade

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
