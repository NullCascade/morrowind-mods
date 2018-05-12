=====================================================================================
                              Sophisticated Save System                              
                                 Author: NullCascade                                 
                                    Version 1.0.1                                    
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

 This mod changes how saves are handled by Morrowind. The goal of the mod is to
 provide more types of autosaves, as well as a rotating list of quicksaves/autosaves
 so that the player always has a save to go back to.

 Features:

    * Overrides autosaves and quicksaves to keep a rotating queue of saves. By
      default there are 10 save slots. This can be changed in the mod's config menu.
    * Changes the quickload behavior to load the newest save (be it manual, auto, or
      quicksave) instead of the quicksave. This can be turned off in the config, in
      which case the latest quicksave is loaded instead.
    * Allows a hard save to be performed, creating a brand new save in a slot that
      the doesn't count against the rotating slot system. This save will have a name
      that includes the timestamp of the save. To create a hard save, hold Alt and
      press the QuickSave key.
    * Autosaves are expanded to happen on other events. These events can be turned
      off individually in the config menu. To prevent saves from happening too close
      to one another, a minimum time between saves option (default of 1 minute) can
      be set. The current events are:
        * Every X minutes (configurable, 10 by default).
        * On combat start.
        * On combat end.
        * On cell change.
    * The mod contains a configuration menu to configure autosave timings, and other
      features. To access it, hold Alt and Shift while pressing the QuickSave key.

=====================================================================================
 INSTALLATION:
=====================================================================================

 Extract the archive into your Morrowind installation directory. The mod consists of
 a single file, which should end up located at:
    <Morrowind Install Directory>\Data Files\MWSE\lua\nc\save\mod_init.lua

=====================================================================================
 PLAYING THIS PLUGIN:
=====================================================================================

 There is no esp file to activate. Simply install the MWSE 2.1 and this mod, and
 load up an old or new game. Press Alt+Shift+[QuickSave] to bring up the config
 menu.

=====================================================================================
 KNOWN ISSUES OR BUGS:
=====================================================================================

 None. Please report any issues on the Nexus page or at GitHub:
    https://github.com/NullCascade/morrowind-mods/issues

=====================================================================================
 VERSION HISTORY
=====================================================================================

 1.0.1 [2018-05-11]:
    * Fixed issue where autosaves could occur during loading a saved game.
    * Prevent issue with newer MWSE 2.1 builds that caused hard save functionality
      to crash.
    * Minor changes to tighten up the configuration menu.

 1.0.0 [2018-05-01]:
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

 Special thanks to Greatness7 for his help in progressing MWSE 2.1, to sveng for his
 help testing, and to DarkElfGuy for inspiring people to create and release mods for
 the yearly modathon.

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
