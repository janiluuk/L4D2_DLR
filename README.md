# L4D2: Rage Edition

A celebratory remix of Left 4 Dead 2 that turns every round into a playable action movie. Rage Edition keeps the co-op chaos you love and layers on bold classes, dramatic abilities, and a stack of quality-of-life touches that make the whole server feel alive.

## What you'll experience
- **Playable heroes instead of plain survivors.** Pick a role, unlock its signature move with `!skill`, and swap at any time through the in-game menu.
- **Mix-and-match perks.** Stack advantages, accept trade-offs, and discover combos that keep each run fresh.
- **Instant clarity.** A toggleable HUD calls out kills, warnings, and supplies, while the guide menu explains every talent in clear language.
- **Fast admin access.** Type `!adm` for spawn tools, debug switches, and quick clean-up options without leaving the fight.
- **Hold-to-open game menu.** Press and hold ALT to pop up a full-screen selector with 3rd-person view, kit pickup, class change, music control, and more. Release the key and it disappears.
- **Now playing overlay.** The active track title and playtime stay pinned to every menu page so the entire lobby knows what’s on the air.
- **Testing currently dynamically generated music based on your current situation** **Improved social skills for bots, your chat will be routed to 1-3 LLM's biased on the character persona, and live dialog is sent back. tension amped up between the 3 other bots.

## Play your way
### Soldierboy
- Moves faster, shrugs off more hits, and slashes like a blender.
- Aims and taps `!skill` to rain down an airstrike.
- Flips night vision on or off whenever the fight slips into darkness.

### Ninja
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
- **Music player** – Type `!music` to choose the soundtrack, skip songs, or go silent. Preferences stick with you between maps.
- **Away toggle** – Need a breather? Mark yourself AFK directly from the menu and hop back in when ready.
- **Multiple equipment mode** – Pick how forgiving pickups are, from classic single-use kits to double-tap weapon swaps.
- **Voting hub** – Launch game mode and map votes without fumbling chat commands.
- **Command parity** – Every feature also has an `sm_` console command so you can bind keys or build macros exactly how you like.

## Soundtrack corner
Drop a list of 44.1 kHz MP3s into the supplied music text files, point your fast-download host at them, and the plugin does the rest. First-time players can even hear a special welcome track if you enable the option.

## Admin corner
Need to tidy the battlefield? `!adm` opens a dedicated panel with spawn helpers, restart controls, god mode, and slow-motion toggles. Everything is grouped for quick decisions mid-round.

### New saboteur class. 

- Hold crouch 4 sec, and you'll get 20 sec total invisibility with decoy outline.
- Middle click to activate cloak mode 30 sec. If you get pinned, you leave a doppelganger ragdoll with fake weapon for them to toy with and have 10 seconds invisibility to make escape without ability to shoot.
- During cloak you can see outlines of all special infected.
- 7 minetypes to plant. Selection of best variation assigned as default.
- Nightvision

### Misc

- Each class have now own playermodel. Current ones are guidelines, final models TBD
-:3rd person with saveable preferences. Either always, melee only and disabled.
- Soldier now throws realistic marker grenade for airstrike
- Custom music player, includes free Doom 2 heavymetal remake album in playlist.

### Music player controls

Use the in-game menu (open with `sm_dlr`) and navigate to **Game Options** to control the music player.

- **4. Music player** – play or pause the current track. The track name is echoed to chat after each toggle.
- **5. Music Volume** – set the volume from 0 to 10 without resuming paused music.
- **6. Next track** – skip to the next song and print its title.

Opening the menu or changing any setting always prints the current track name so players know what is playing. If background music is enabled, map-specific ambient sounds from `sourcemod/configs/ambient_sounds.cfg` will automatically play whenever the playlist is idle.

## Adding a plugin

Adding new plugin requires including DLRCore.sp file, and implementing following methods:
```
/**
 * Called when player changed class
 *
 * @param client         The client index of the player playing tetris.
 * @param className      Classname that user just selected
 * @param previousClass  Previous class of user
 * @noreturn
 */
forward OnPlayerClassChange(client, className, previousClass);  

/**
 * Called when player uses special skill. 
 * Plugin should react to this to initiate the skill, then call either or OnSpecialSkillFail / OnSpecialSkillSuccess
 * @param client         The client index of the player playing tetris.
 * @param skillName      Skill that user just used
 * @noreturn
 */
forward OnSpecialSkillUsed(client, skillName);  


/**
 * Called when player has successfully used special skill. 
 * This is required for plugin to implement
 *
 * @param client         The client index of the player playing tetris.
 * @param className      Skill that user just used
 * @noreturn
 */
native void OnSpecialSkillSuccess(int client, char[] skillName);  

/**
 * Called when player has failed using special skill. This prevents from affecting the inventory.
 *
 * @param client         The client index of the player playing tetris.
 * @param className      Skill that user just used
 * @param reason         Reason for failure
 * @noreturn
 */
native void OnSpecialSkillFail(int client, char[] skillName, char[] reason);  

/**
 * Register skill from plugin
 *
 * @param client         The client index of the player playing tetris.
 * @param className      Skill that user just used
 * @param reason         Reason for failure
 * @noreturn
 */
native int RegisterDLRSkill(char[] skillName);  

``` 

Native helper methods that are available:

```

/**
 * Called when player uses special skill. 
 * Plugin should react to this to initiate the skill, then call either or OnSpecialSkillFail / OnSpecialSkillSuccess
 * @param skillName         The client index of the player playing tetris.
 * @param skillId     Assign ID to this var
 * @noreturn
 */
forward FindSkillIdByName(skillName, skillId);  

/**
 * Get player classname
 *
 * @param client  Client index.
 * @return        Classname
 */
native int:GetPlayerClassName(client);

``` 

Add DLRCore.sp in your include folder and make sure you have dlr_talents.smx available.
Include this in the plugin file header that you want to implement


```
/****************************************************/
#tryinclude <DLRCore>
#if !defined _DLRCore_included
	// Optional native from DLR Talents
	native void OnSpecialSkillSuccess(int client, char[] skillName);
	native void OnSpecialSkillFail(int client, char[] skillName, char[] reason);
	native void GetPlayerSkillName(int client, char[] skillName, int size);
	native int  RegisterDLRSkill(char[] skillName, 0);  
#endif
static bool DLR_Available = false;
#define PLUGIN_SKILL_NAME "Plugin Name"
/****************************************************/
``` 

Include these functions;
``` 
public void DLR_OnPluginState(int pluginstate)
{
	DLR_Available = IntToBool(pluginstate);
	g_iClassID = DLR_Available ? RegisterDLRSkill(PLUGIN_SKILL_NAME, 0) : -1;
    ....
}

public void OnPluginStart()
{
....
	if (DLR_Available) {
		g_iClassID = RegisterDLRSkill(PLUGIN_SKILL_NAME);
}

public void OnSpecialSkillUsed(int iClient, int skill)
{
	if (skill == FindSkillIdByName(PLUGIN_SKILL_NAME) {

		CMD_MainMenu(iClient, 0);
	}
}
public void OnSpecialSkillSuccess(int iClient, int skill)
{
	if (skill == FindSkillIdByName(PLUGIN_SKILL_NAME) {

		CMD_MainMenu(iClient, 0);
	}
}
public void OnSpecialSkillFail(int iClient, int skill, char[] reason)
{
	if (skill == FindSkillIdByName(PLUGIN_SKILL_NAME) {
		CMD_MainMenu(iClient, 0);
	}
}


```

See Multiturret implementation as example

Grab the files, drop them on your server, and let the rage weekend begin.
