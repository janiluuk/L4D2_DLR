# L4D2_DLRTalents

This is anniversary update for the infamous DLR mode for Left 4 Dead 2. Original is from 2013

Changes:
- Sourcemod 11 compatible
- Rewrite for internal variable structure, variable naming and functionality.
- Plugin support, adding new features should be a matter of including the plugin and adding hook to it
- Soldier has faster moving speed and takes less damage. configurable. 
- Soldier can order airstrikes. (Requires F18_Airstrike plugin)
- Athlete has faster moving speed and a parachute. configurable.
- Commando reload rate actually works now
- Commando damage modifiers are configurable per weapon, default one is used for rest
- Medic has more options to spawn. Has faster healing and revival times.
- Includes modifiers for adrenaline/pills/revive/heal durations in the config. disable with "talents_health_modifiers_enabled" 
- Announcement to other players when healing spot is active.
- Players get notified when theyre being healed.
- Default health for players without class configurable. Menu does not spam you if you don't choose a class.
- Engineer spawns ready-to-use upgrade packs instead of deployable boxes.
- Engineer now spawns 2 different types of turrets. 8 different ammo types for various situations. (Requires plugin from https://github.com/janiluuk/L4D2_Machine)
- Engineer can now barricade open doors & windows. Requires plugin version of (https://forums.alliedmods.net/showthread.php?p=2780813). Adding the plugin version as soon as have tested it properly
- Engineer, medic and saboteur get countdown for next deployment when trying to deploy too early
- Turrets don't block anymore, so you cannot abuse it by boxing in opponents.
- Saboteur moves faster when crouched and shows visibility status.
- Saboteur changes color when invisible to enemies.
- Mines do less damage to survivors. Standing really close to the mine can still incap.
- Mines do more damage to infected, 1500hp. Some edge over tank
- Mines glow now so players know to avoid the spot or lure someone to it.
- Notifications on placing mines.
* Warnings for players that go near armed mine
- Countdown notification before mine becoming armed.
- Support for multiple types of mines (freeze, vomit, antigravity, black hole), ui missing
- Engineer, medic and saboteur get countdown for next deployment when trying to deploy too early, and notification if out of supplies.
- More helpful class descriptions and help system.
- Support for external plugins for turret system.
- Internal turret system fixed
- Gun reload glitches fixed
- Mine placement rewrite, now we keep track of the type and index of each mine and their particles, so effects can vary individually.
- Redefine visual effect to be more minimalistic for mines
- Invisibility rewrite, it never really worked properly before.
- Wipe out all infected from admin menu
- Debug mode for admins

Roadmap
- Cleaner UI, menu option to turn hint texts off. Common HUD component which manages, prioritizes and combines the hint texts properly.
- Integrate game instructor UI to be utilized for counters, and other live indicators. 
- Engineer can build different types of defences
- Saboteur can see infected outlines when in "predator mode". Instakill if manages to sneak up behind.
- Smoker should have much more visible and thick cloud when gets killed.
- Show specific glow on people being healed by medic
- Rewrite for missile plugin to fit better with this one
- Add more plugins including berserk mode, jetpack, special grenades.
- Incap players can fight with attacker with some keys, if indicator goes back to zero, player is freed.
- When incapacitated without supplies and you have kit available, ask survivor if want to consume it.
- Revamp infected skills to match the added ones for survivors;
    - Infected can bite survivors, after defined about of time player turns into a witch for 30 seconds. If the witch gets killed, player gets killed, otherwise transform back to playable character.
    - Charger can drop survivor and continue running
    - Hunter can use boost for ultra long jumps
    - Smoker can shove opponent to any direction when pinned, e.g throw out of window.
    - More suggestions welcome!


See https://forums.alliedmods.net/showthread.php?t=273312 for more info
