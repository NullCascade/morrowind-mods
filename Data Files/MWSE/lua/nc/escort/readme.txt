=====================================================================================
                                     Easy Escort                                     
                                 Author: NullCascade                                 
                                    Version 1.1.1                                    
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

 This mod provides a generic-case companion teleportation script. Any following NPC
 or creature will reliably follow the PC through doors, or warp to them if they get
 too far away. They'll even follow the NPC through non-traditional movement, like
 scripted activators.

=====================================================================================
 INSTALLATION:
=====================================================================================

 Extract the archive into your Morrowind installation directory. The mod should
 contain the following files:
    .\Data Files\MWSE\lua\nc\escort\mod_init.lua
    .\Data Files\MWSE\nc_escort_config.json

 To configure the mod, edit the above-named json file. The config entries function
 as described below:

 pollRate: The number of seconds between checks. Default of 5. This means that every
 five seconds player followers will have their position and cell checked.

 followDistance: The maximum distance a follower can get before they'll be warped.

 blackList: The object IDs of the creatures/NPCs to exclude from this script. If a
 companion has their own scripts that conflict with this, you can add their ID to
 this array and they will be ignored.

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

 1.1.1 [2018-06-04]:
    * Blacklisted the chargen boat guide from following you up onto the ship.
    * Fixed issue where dead companions would still follow the player.

 1.1.0 [2018-05-30]:
    * Added interop module so that other mods can, from lua, dynamically add/remove/
      find companions from the blacklist.

 1.0.0 [2018-05-28]:
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
