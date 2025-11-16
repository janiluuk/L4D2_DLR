# L4D2: Rage Edition

A celebratory remix of Left 4 Dead 2 that turns every round into a playable action movie. Rage Edition keeps the co-op chaos you love and layers on bold classes, dramatic abilities, and a stack of quality-of-life touches that make the whole server feel alive.

## What you'll experience
- **Playable heroes instead of plain survivors.** Pick a role, unlock its signature move with `!skill`, and swap at any time through the in-game menu.
- **Mix-and-match perks.** Stack advantages, accept trade-offs, and discover combos that keep each run fresh.
- **Instant clarity.** A toggleable HUD calls out kills, warnings, and supplies, while the guide menu explains every talent in clear language.
- **Fast admin access.** Type `!adm` for spawn tools, debug switches, and quick clean-up options without leaving the fight.
- **Hold-to-open game menu.** Press and hold ALT to pop up a full-screen selector with 3rd-person view (Off / Melee Only / Always), kit pickup, class change, music control, and more. Release the key and it disappears.
- **Now playing overlay.** The active track title and playtime stay pinned to every menu page so the entire lobby knows what’s on the air.

## Play your way
### Soldier
- Moves faster, shrugs off more hits, and slashes like a blender.
- Aims and taps `!skill` to rain down an airstrike.
- Flips night vision on or off whenever the fight slips into darkness.

### Athlete
- Built for motion: sprint boosts, double jumps, and mid-air karate kicks.
- Deploys a parachute to float over chaos or escape a wipe.

### Commando
- Tunes damage per weapon, reloads on instinct, and shrugs off tank knockdowns.
- Builds rage meter to unleash a Berserk rush that melts specials.

### Medic
- Patches teammates in record time and blasts glowing heal orbs across the room.
- Healed players get a reassuring glow so you always know who’s safe.

### Engineer
- Drops upgrade packs, barricades chokepoints, and deploys turrets from an in-game shop.
- Shields, door blocks, and “single turret mode” keep builds tidy.

### Saboteur
- Sneaks with a Dead Ringer decoy, mines the map, and spots infected through walls on a timer.
- Night vision and mine warnings help the whole team stay alert.

## Toys, tricks, and server spice
- **Prototype grenades** – Equip one and experiment with gravity wells, lightning storms, medic clouds, and more just by cycling the throw style.
- **Third-person camera** – Switch between off, melee-only, or always-on views from the ALT menu or `!tps <0|1|2>` command; your choice is saved per player.
- **Music player** – Type `!music` to choose the soundtrack, skip songs, or go silent. Preferences stick with you between maps.
- **Away toggle** – Need a breather? Mark yourself AFK directly from the menu and hop back in when ready.
- **Multiple equipment mode** – Pick how forgiving pickups are, from classic single-use kits to double-tap weapon swaps.
- **Voting hub** – Launch game mode and map votes without fumbling chat commands.
- **Command parity** – Every feature also has an `sm_` console command so you can bind keys or build macros exactly how you like.

## Soundtrack corner
Drop a list of 44.1 kHz MP3s into the supplied music text files, point your fast-download host at them, and the plugin does the rest. First-time players can even hear a special welcome track if you enable the option.

## Admin corner
Need to tidy the battlefield? `!adm` opens a dedicated panel with spawn helpers, restart controls, god mode, and slow-motion toggles. Everything is grouped for quick decisions mid-round.

## Configuration quick hits
- `cfg/sourcemod/dlr_thirdperson.cfg` – flip `l4d_thirdperson_allow` to disable or re-enable the third-person camera toggle if you need to lock everyone to first-person.

## Ready to tinker?
Rage Edition is built from modular SourceMod plugins, so you can add new talents, swap out effects, or write your own class packs without touching the core. Check the `sourcemod/scripting` folder for clean, well-documented examples.

Grab the files, drop them on your server, and let the rage weekend begin.
