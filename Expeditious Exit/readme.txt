=====================================================================================
                                  Expeditious  Exit                                  
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
    * EasyMCM (https://www.nexusmods.com/morrowind/mods/46427) for in-game config.

=====================================================================================
 ABOUT THIS MOD:
=====================================================================================

 This mod is for people who seem to have issues crashing or losing mouse control on
 exit. By hijacking the exit buttons, this mod will force the game to exit.

 Doing it this way isn't wonderful! In a perfect world we wouldn't do it this way,
 but if it helps you, great.

=====================================================================================
 INSTALLATION:
=====================================================================================

 Extract the archive into your Morrowind installation directory. The mod should
 contain the following files:
    .\Data Files\MWSE\config\Expeditious Exit.json
    .\Data Files\MWSE\mods\Expeditious Exit\config.lua
    .\Data Files\MWSE\mods\Expeditious Exit\main.lua
    .\Data Files\MWSE\mods\Expeditious Exit\mcm.lua

=====================================================================================
 PLAYING THIS PLUGIN:
=====================================================================================

 There is no esp file to activate. Simply install the MWSE 2.1 and this mod, and
 load up an old or new game.

 If you want the original yes/no confirmation box before close, navigate to the
 configuration file and set messageBox to true.

=====================================================================================
 KNOWN ISSUES OR BUGS:
=====================================================================================

 None. Please report any issues on the Nexus page or at GitHub:
    https://github.com/NullCascade/morrowind-mods/issues

=====================================================================================
 VERSION HISTORY
=====================================================================================

 1.2.1 [2019-04-09]:
    * Minor refactor for new MWSE folder structure.
    * Minor API changes.
    * Switch to using EasyMCM for the mod config menu.

 1.2.0 [2018-07-12]:
    * Added support for the MWSE Mod Config Menu to modify the config file.

 1.1.0 [2018-05-07]:
    * Added a config file. By setting messageBox to true, a message box will be
      displayed prior to close, like with the vanilla exit.

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
