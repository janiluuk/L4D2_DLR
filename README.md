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
- Calls in airstrikes (example plugin included)
- **Toggleable night vision**

### Athlete
- Faster movement and a parachute
- Jump karate kicks that knock enemies down

### Commando
- Configurable weapon-specific damage modifiers
- Berserk mode and immunity to tank knockdowns
- Stomps downed infected and reloads faster

### Medic
- Expanded spawn options
- Faster healing and revival; movement boost while healing
- Throws healing orbs that glow and announce to others
- Players notified when healed; healed players gain a special glow
- Default health for classless players configurable

### Engineer
- Spawns ready-to-use upgrade packs
- Two turret types with eight ammo options and improved AI
- Deploys protective shields and barricades doors/windows
- Turrets notify nearby players, can be blown up by infected and are non-blocking
- "Single turret mode" for old-school play
- Deployment countdowns for engineer, medic and saboteur

### Saboteur
- Faster crouch movement with visibility status
- Visual effects for cloak and glow indicators
- Night vision and 20 mine types with unique effects
- Mines glow, warn nearby players and offer arming countdowns
- Reduced survivor damage, increased infected damage

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
