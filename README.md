# L4D2_DLRTalents

This is anniversary update for the infamous DLR mode for Left 4 Dead 2. Original is from 2013

Changes:
- Sourcemod 11 compatible
- Rewrite for internal variable structure, variable naming and functionality.
- Plugin support, adding new features should be a matter of including the plugin and adding hook to it
- Soldier has faster moving speed and takes less damage. Also by default melee penalty is off. Configurable. 
- Soldier can order airstrikes. (Requires included example plugin)
- Athlete has faster moving speed and a parachute. configurable.
- Commando reload rate actually works now
- Commando damage modifiers are configurable per weapon, default one is used for rest.
- Commando is immune to knockdowns
- Commando can stomp downed infected
- Medic has more options to spawn. Has faster healing and revival times.
- Medic moves faster when in healing mode (crouched)
- Includes modifiers for adrenaline/pills/revive/heal durations in the config. disable with "talents_health_modifiers_enabled" 
- Announcement to other players when healing spot is active.
- Players get notified when theyre being healed.
- Players healed by medic have special glow
- Default health for players without class configurable. Menu does not spam you if you don't choose a class.
- Engineer spawns ready-to-use upgrade packs instead of deployable boxes.
- Engineer now spawns 2 different types of turrets. 8 different ammo types for various situations. (Requires plugin from https://github.com/janiluuk/L4D2_Machine)
- Engineer can now barricade open doors & windows. Requires plugin version of (https://forums.alliedmods.net/showthread.php?p=2780813). Adding the plugin version as soon as have tested it properly
- Engineer, medic and saboteur get countdown for next deployment when trying to deploy too early
- Turrets don't block anymore, so you cannot abuse it by boxing in opponents.
- Saboteur moves faster when crouched and shows visibility status.
- Saboteur has visual effect on turning invisible and specific glow.
- Saboteur has nightvision
- Redefine visual effect for mines, and actually leave a visible mine. 
* Saboteur has 20 different types of mines with cool effects. You can assign 7 of them at one time. Antigravity, blackhole, freeze, vaporizer and many more. (Needs included grenades plugin example)
- Mines do less damage to survivors. Standing really close to the mine can still incap.
- Mines do more damage to infected, 1500hp. Some edge over tank
- Mines glow now so players know to avoid the spot or lure someone to it.
- Notifications on placing mines.
* Warnings for players that go near armed mine
- Countdown notification before mine becoming armed.
- Engineer, medic and saboteur get notification if out of supplies.
- More helpful class descriptions and help system.
- Internal turret system fixed
- Gun reload glitches fixed
- Invisibility rewrite, it never really worked properly before.
- Wipe out all infected from admin menu
- Debug mode for admins. You can test the registered skills straight from menu

Roadmap
- Cleaner UI, menu option to turn hint texts off. Common HUD component which manages, prioritizes and combines the hint texts properly.
- Integrate game instructor UI to be utilized for counters, and other live indicators. 
- Show player class above their head (Using "Hats" plugin, missing graphics for it)
- Engineer can build different types of defences
- Saboteur can see infected outlines when in "predator mode". Instakill if manages to sneak up behind.
- Smoker should have much more visible and thick cloud when gets killed.
- Rewrite for missile plugin to fit better with this one
- Add more plugins including berserk mode, jetpack, special grenades.
- Incap players can fight with attacker with some keys, if indicator goes back to zero, player is freed.
- When incapacitated without supplies and you have kit available, ask survivor if want to consume it.
- Revamp infected skills to match the added ones for survivors;
    - Infected can bite survivors, after defined about of time player turns into a witch for 30 seconds. If the witch gets killed, player gets killed, otherwise transform back to playable character.
    - Charger can drop survivor and continue running
    - Hunter can use boost for ultra long jumps
    - Jockey can make player shoot others with FF damage while riding
    - Smoker can shove opponent to any direction when pinned, e.g throw out of window.
    - Hunter can masquerade as survivor for 30 second time (Using LMC)
    - More suggestions welcome!


See https://forums.alliedmods.net/showthread.php?t=273312 for more info

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
 * Called when player uses special skill. 
 * Plugin should react to this to initiate the skill, then call either or OnSpecialSkillFail / OnSpecialSkillSuccess
 * @param skillName         The client index of the player playing tetris.
 * @param skillId     Assign ID to this var
 * @noreturn
 */
forward FindSkillIdByName(skillName, skillId);  

``` 

Native methods that are available:

```
/**
 * Get player classname
 *
 * @param client  Client index.
 * @return        Classname
 */
native int:GetPlayerClassName(client);

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
# Plugin file changes
Add DLRCore.sp in your include folder and make sure you have dlr_talents_2023.smx available.
Include this in the plugin file header that you want to implement


```
/****************************************************/
#tryinclude <DLRCore>
#if !defined _DLRCore_included
	// Optional native from DLR Talents
	native void OnSpecialSkillSuccess(int client, char[] skillName);
	native void OnSpecialSkillFail(int client, char[] skillName, char[] reason);
	native void GetPlayerSkillName(int client, char[] skillName, int size);
	native int RegisterDLRSkill(char[] skillName);  
#endif
static bool DLR_Available = false;
#define PLUGIN_SKILL_NAME "Foobar"
/****************************************************/
``` 

Include these functions;
``` 
public void OnAllPluginsLoaded()
{
	DLR_Available = LibraryExists("dlr_talents_2023");
    ....
}

public void OnLibraryAdded(const char[] sName)
{
	if( StrEqual( sName, "dlr_talents_2023" ) )
		DLR_Available = true;
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
```

See Multiturret implementation as example

