# L4D2 DLR Talents

A brutal anniversary overhaul of the infamous DLR mode for Left 4 Dead 2. DLR Talents resurrects the 2013 classic with modular perks, class-based abilities and a plugin-friendly core that lets you sculpt chaotic co-op sessions.

## Core Features
- Sourcemod 1.11 compatible
- Plugin-based architecture: drop in new perks or classes via `DLRCore`
- Modular perk system with negative effects and combo chaining
- Keybinding support (Soldier night vision bound to `N`)
- Custom class creation and configuration
- Class-based skins
- Optional HUD with alerts, kill counter and supply warnings
- Expanded help system with class descriptions and a night vision tutorial
- Adjustable adrenaline, pills, revive and heal timings
- Rewritten invisibility and fixed gun reload glitches
- Debug modes, admin menu and useful tools

## Class Highlights
### Soldier
- Faster movement and reduced damage
- Ninja-level melee rate
- Aim and press `!skill` to call in an airstrike
- **Toggleable night vision**

### Athlete
- Faster movement and a parachute
- Mobility perks: bunnyhop, double-jump, high-jump and long-jump
- Jump karate kicks that knock enemies down

### Commando
- Configurable weapon-specific damage modifiers
- Build rage and press `!skill` to trigger Berserk; immune to tank knockdowns
- Stomps downed infected and reloads faster

### Medic
- Expanded spawn options
- Faster healing and revival; movement boost while healing
- Throws healing orbs that glow and announce to others
- Players notified when healed; healed players gain a special glow
- Default health for classless players configurable

### Engineer
- Spawns ready-to-use upgrade packs
- `!skill` opens a turret menu with two turret types and eight ammo options
- Deploys protective shields and barricades doors/windows
- Turrets notify nearby players, can be blown up by infected and are non-blocking
- "Single turret mode" for old-school play
- Deployment countdowns for engineer, medic and saboteur

### Saboteur
- Faster crouch movement with visibility status
- Dead Ringer decoy: middle-click or type `!skill` (`sm_fd`/`sm_cloak`) to vanish and drop a fake corpse
- Extended survivor sight: `!extendedsight` reveals special infected for 20 s every 2 min
- Night vision and 20 mine types; press **Shift** to plant mines that glow and warn nearby players
- Reduced survivor damage, increased infected damage

## Additional Features & Commands
- **Prototype Grenades** – Throw standard grenades to deploy wild effects. Hold **Primary Fire + Shove** (or open `sm_grenade`) to pick from 20 types such as Black Hole vortices, Tesla lightning, Medic healing clouds, or an Airstrike marker.
- **Class Skill Command** – Bind a key or type `!skill` to trigger your class's special ability.
- **Dead Ringer Cloak** – Saboteur-only decoy and invisibility; `sm_fd` toggles the effect and `sm_cloak` triggers it immediately.
- **Extended Survivor Sight** – Saboteur-only wallhack for 20 s on a 2 min cooldown; activate with `sm_extendedsight`.
- **Unvomit** – Clear Boomer bile with `sm_unvomit` as a Medic cleanse.
- **Map & Ambient Music** – `!music` menu lets players enable round-start tracks and looping ambience. Server vars `start_music_enabled` and `ambient_music_enabled` control the defaults.
- **Multiturret** – Engineer presses the class skill key (default middle mouse or `sm_skill`) to open a turret menu. Pick a gun and ammo, left-click to deploy, and press **Use** to pick it back up. Admins can remove a turret via `sm_removemachine`.
- **Ninja Kick** – Athlete leap‑kicks infected by jumping into them, knocking targets to the ground.
- **Berserk Mode** – Commando builds rage as they deal damage; `sm_berserker` toggles the boost once charged.
- **Airstrike** – Soldier calls in artillery at their crosshair using the class skill key.

All special skills provide a corresponding `sm_` console command so abilities can be activated consistently regardless of keybinds.

### Adding Music
Store 44.1 kHz MP3s on a fast‑download server and list them in `data/music_mapstart.txt` (and optionally `music_mapstart_newly.txt` for first‑time players). Ambient loops and durations go into `configs/ambient_sounds.cfg`. Players can open `!music` to adjust volume or disable all custom tracks; their choices are saved in cookies until they opt back in.

## Game Menu & Guide
A full-screen menu replaces tiny SourceMod popups. Navigate with **W/S** and **A/D**. Admins open the game menu with `sm_dlr` or the guide with `sm_guide`; players see the same overlay when using options like the music player.

## Roadmap
- Cleaner UI with unified hint system and game instructor integration
- Random game modes (melee-only rounds, jockey race, horror mode, etc.)
- Class indicators above players and expanded infected skills
- Reworked missile plugin and turret configuration
- Docker image with integrated RCON web admin
- Skill editor for generating new perks/classes
- Additional co-op mechanics (struggles, transformations, etc.)

## Developing Plugins
Include `DLRCore.sp` and implement the required callbacks:

```sourcepawn
forward OnSpecialSkillUsed(int client, const char[] skillName);
native void OnSpecialSkillSuccess(int client, const char[] skillName);
native void OnSpecialSkillFail(int client, const char[] skillName, const char[] reason);
native int RegisterDLRSkill(char[] skillName);
```

Helper natives:

```sourcepawn
forward FindSkillIdByName(const char[] skillName, int &skillId);
native int GetPlayerClassName(int client);
```

Add `DLRCore.sp` to your include folder and register your skill during `OnPluginStart` or `DLR_OnPluginState`. See the multiturret plugin for a complete example.

See https://forums.alliedmods.net/showthread.php?t=273312 for more info.

Grab the files, drop them on your server, and let the rage weekend begin.
