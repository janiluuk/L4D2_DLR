# L4D2: Rage Edition

A celebratory remix of Left 4 Dead 2 that turns every round into a playable action movie. Rage Edition keeps the co-op chaos you love and layers on bold classes, dramatic abilities, and a stack of quality-of-life touches that make the whole server feel alive.

## Core Features
- Sourcemod 1.21 compatible
- Plugin-based architecture: drop in new perks or classes via `RageCore` and optional skill plugins
- Configurable skill bindings per class via `configs/rage_class_skills.cfg` (special, secondary, deploy)
- Modular perk system with negative effects and combo chaining; class-based skins and custom class definitions
- Optional HUD with alerts, kill counter and supply warnings
- Expanded help system with class descriptions and a night vision tutorial
- Adjustable adrenaline, pills, revive and heal timings
- Rewritten invisibility and fixed gun reload glitches
- Debug modes, admin menu and useful tools

## Play your way

### Soldierboy
- Moves faster, shrugs off more hits, and slashes like a blender.
- Aims and taps `!skill` to rain down an airstrike.
- Flips night vision on or off whenever the fight slips into darkness.

### Ninja
- Built for motion: sprint boosts, double jumps, and mid-air karate kicks.
- Deploys a parachute to float over chaos or escape a wipe.

### Trooper
- Tunes damage per weapon, reloads on instinct, and shrugs off tank knockdowns.
- Builds rage meter to unleash a Berserk rush that melts specials.

### Medic
- Expanded spawn options
- Faster healing and revival; movement boost while healing
- Throws healing orbs that glow and announce to others; cleanses bile with `sm_unvomit`
- Players notified when healed; healed players gain a special glow; look down + **Shift** to drop medkits/supplies
- Default health for classless players configurable

### Engineer
- Spawns ready-to-use upgrade packs
- `!skill` opens a turret menu with two turret types and eight ammo options; look down + **Shift** to drop ammo supplies
- Deploys protective shields and barricades doors/windows; single-turret mode for old-school play
- Turrets notify nearby players, can be blown up by infected and are non-blocking
- Deployment countdowns for engineer, medic and saboteur

### Saboteur
- Faster crouch movement with visibility status
- Dead Ringer decoy: middle-click or type `!skill` (`sm_fd`/`sm_cloak`) to vanish and drop a fake corpse
- Extended survivor sight: `!extendedsight` reveals special infected for 20 s every 2 min
- Night vision and 20 mine types; look down + **Shift** to plant mines that glow and warn nearby players
- Reduced survivor damage, increased infected damage

## Additional Features & Commands
- **Prototype Grenades** – Equip any grenade and press **Primary Fire** to throw. Hold **Primary Fire** and tap **Shove** (or type `sm_grenade`) to cycle through 20 experimental types like Black Hole vortices, Tesla lightning, Medic healing clouds, or an Airstrike marker.
- **Class Skill Command** – Bind a key or type `!skill` to trigger your class's special ability. Secondary actions (Use+Attack) and deploy actions (look down + Shift) are configurable per class in `configs/rage_class_skills.cfg`.
- **Dead Ringer Cloak** – Saboteur-only decoy and invisibility; `sm_fd` toggles the effect and `sm_cloak` triggers it immediately.
- **Extended Survivor Sight** – Saboteur-only wallhack for 20 s on a 2 min cooldown; activate with `sm_extendedsight`.
- **Unvomit** – Clear Boomer bile with `sm_unvomit` as a Medic cleanse.
- **Map Music** – `!music` menu lets players enable round-start tracks. Server var `start_music_enabled` controls the default.
- **Multiturret** – Engineer presses the class skill key (default middle mouse or `sm_skill`) to open a turret menu. Pick a gun and ammo, left-click to deploy, and press **Use** to pick it back up. Look down + **Shift** to drop ammo supplies. Admins can remove a turret via `sm_removemachine`.
- **Ninja Kick** – Athlete leap‑kicks infected by jumping into them, knocking targets to the ground.
- **Berserk Mode** – Commando builds rage as they deal damage; press `!skill` (or `sm_berserker`) when prompted for a short speed and damage surge.
- **Airstrike** – Soldier aims and hits `!skill` to mark a target for a missile barrage.
- **3rd Person Mode** – Switch to shoulder cam via the Game Options menu (`!rage`); modes include Off, Melee-only, and Always, your selection is remembered per-player, and you can bind a key (e.g., Alt) to `+rage_menu` to hold the menu open while choosing.

## Toys, tricks, and server spice
- **Prototype grenades** – Equip one and experiment with gravity wells, lightning storms, medic clouds, and more just by cycling the throw style.
- **Music player** – Type `!music` to choose the soundtrack, skip songs, or go silent. Preferences stick with you between maps.
- **Away toggle** – Need a breather? Mark yourself AFK directly from the menu and hop back in when ready.
- **Multiple equipment mode** – Pick how forgiving pickups are, from classic single-use kits to double-tap weapon swaps.
- **Voting hub** – Launch game mode and map votes without fumbling chat commands.
- **Command parity** – Every feature also has an `sm_` console command so you can bind keys or build macros exactly how you like.

## Soundtrack corner
Drop a list of 44.1 kHz MP3s into the supplied music text files, point your fast-download host at them, and the plugin does the rest. First-time players can even hear a special welcome track if you enable the option.

## Admin corner
Need to tidy the battlefield? `!adm` opens a dedicated panel with spawn helpers, restart controls, god mode, and slow-motion toggles. Everything is grouped for quick decisions mid-round.

## Ready to tinker?
Rage Edition is built from modular SourceMod plugins, so you can add new talents, swap out effects, or write your own class packs without touching the core. Check the `sourcemod/scripting` folder for clean, well-documented examples.

Grab the files, drop them on your server, tweak `configs/rage_class_skills.cfg` to taste, and let the rage weekend begin.
