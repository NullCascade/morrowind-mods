=====================================================================================
                              Proportional  Progression                              
                                 Author: NullCascade                                 
                                    Version 1.0.0                                    
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

 This mod allows you to configure the rate at which skills level in a way that is
 more detailed than the simple game settings. The following scales can be used:

  * Global scale. All progress will be modified by a given value.
  * Skill-based scale. A given skill will level faster/slower.
  * Level-based scale. Alters the leveling rate based on the player's overall level.
  * Skill level-based scale. Alters the rate based on the skill's level.

 All of these work together, and are configurable via the provided json file.

=====================================================================================
 INSTALLATION:
=====================================================================================

 Extract the archive into your Morrowind installation directory. The mod should
 contain the following files:
    .\Data Files\MWSE\nc_xpscale_config.json
    .\Data Files\MWSE\lua\nc\xpscale\mod_init.lua

 The nc_xpscale_config.json file MUST  be used to configure the mod for it to change
 anything. If you do not change the configuration, the default values remain at 1.0.

 Configuration details:
 {
   "scale": 1.0,            ; The global scale to apply to all skill progressions.
   "skillSpecific": {
     "use": true,           ; If true, the values below will also be used.
     "values": {
       "acrobatics": 1.0,
       "alchemy": 1.0,
       "alteration": 1.0,
       "armorer": 1.0,
       "athletics": 1.0,
       "axe": 1.0,
       "block": 1.0,
       "bluntWeapon": 1.0,
       "conjuration": 1.0,
       "destruction": 1.0,
       "enchant": 1.0,
       "handToHand": 1.0,
       "heavyArmor": 1.0,
       "illusion": 1.0,
       "lightArmor": 1.0,
       "longBlade": 1.0,
       "marksman": 1.0,
       "mediumArmor": 1.0,
       "mercantile": 1.0,
       "mysticism": 1.0,
       "restoration": 1.0,
       "security": 1.0,
       "shortBlade": 1.0,
       "sneak": 1.0,
       "spear": 1.0,
       "speechcraft": 1.0,
       "unarmored": 1.0
     }
   },
   "levelSpecific": {
     "use": true,           ; If true, the values below will also be used.
     "values": {
       "0": 1.0,            ; Alters the rate when the player is level 1-9
       "10": 1.0,           ; Alters the rate when the player is level 10-19
       "20": 1.0,           ; etc...
       "30": 1.0,
       "40": 1.0,
       "50": 1.0,
       "60": 1.0,
       "70": 1.0,
       "80": 1.0,
       "90": 1.0,
       "100": 1.0
     }
   },
   "skillLevelSpecific": {
     "use": true,           ; If true, the values below will also be used.
     "values": {
       "0": 1.0,            ; Alters the rate when the skill level is 1-9
       "10": 1.0,           ; Alters the rate when the skill level is 10-19
       "20": 1.0,           ; etc...
       "30": 1.0,
       "40": 1.0,
       "50": 1.0,
       "60": 1.0,
       "70": 1.0,
       "80": 1.0,
       "90": 1.0,
       "100": 1.0
     }
   }
 }

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
