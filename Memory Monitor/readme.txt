=====================================================================================
                                   Memory  Monitor                                   
                                 Author: NullCascade                                 
                                    Version 2.1.1                                    
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

 This simple mod provides a fillbar on the interface, above the map. The bar shows
 how much memory Morrowind is using. A crash can be expected when the bar fills up.

 When using large mod lists, this can be useful to monitor how at risk of a crash
 you are.

=====================================================================================
 INSTALLATION:
=====================================================================================

 Extract the archive into your Morrowind installation directory. The mod consists of
 two files, which should end up located at:
    .\Data Files\MWSE\config\Memory Monitor.json
    .\Data Files\MWSE\mods\Memory Monitor\main.lua

=====================================================================================
 PLAYING THIS PLUGIN:
=====================================================================================

 There is no esp file to activate. Simply install the MWSE 2.1 and this mod, and
 load up an old or new game.

 The memory thresholds for displaying the bar can be configured in
 Memory Monitor.json.

=====================================================================================
 KNOWN ISSUES OR BUGS:
=====================================================================================

 None. Please report any issues on the Nexus page or at GitHub:
    https://github.com/NullCascade/morrowind-mods/issues

=====================================================================================
 VERSION HISTORY
=====================================================================================

 2.1.1 [2021-09-26]:
    * Fixed an issue where if the widget was destroyed, the mod would cause a crash.

 2.1.0 [2021-07-06]:
    * Add tooltip information on lua VM usage.

 2.0.0 [2020-09-18]:
    * No longer displays message boxes. Instead shows a HUD element.
    * When the warning threshold is hit, it shows a blocking message box prompting
      the user to save.
    * From the message, the user can save and quit.

 1.0.1 [2018-07-26]:
    * Minor refactor for new MWSE folder structure.

 1.0.0 [2018-05-24]:
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
