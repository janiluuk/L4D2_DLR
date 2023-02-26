
#if defined _DLRCore_included
#endinput
#endif
#define _DLRCore_included
#define DLRCore_version "1.0.0"
#define DLRCORE_PLUGIN_NAME = "dlr_talents_2023"
#define DLRCORE_PLUGIN_FILE = "dlr_talents.smx"

/**
 * Get player classname
 *
 * @param client  Client index.
 * @return        Classname
 */
native int GetPlayerClassName(int client, char[] skillName, int size);

/**
 * Get player skillname
 *
 * @param client  Client index.

 * @param skillName String to assign the name to 
 * @param size 		Size of the string
 * @return        	int
 */

native int GetPlayerSkillName(int client, char[] skillName, int size);

/**
 * Get skill ID by name
 *
 * @param skillName Name of the skill
 * @return        ID || -1
 */
native int FindSkillIdByName(char[] skillName);

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
 * Called when player uses special skill
 *
 * @param client         The client index of the player playing tetris.
 * @param skillName      Skill that user just used
 * @noreturn
 */
forward OnSpecialSkillUsed(int iClient, int skill, int type);  

/**
 * Called when round starts or finishes
 *
 * @param state 	int value, 1=Started/0=Finished
 * @noreturn
 */
forward DLR_OnRoundState(int state);

/**
 * Called when plugin becomes available
 *
 *
 * @param state 	int value, 1=Available/0=Unloaded
 * @noreturn
 */
forward DLR_OnPluginStateq(int state);

/**
 * Called when plugin wants to execute custom command instead
 *
 * @param name           Custom command name
 * @param client         Client ID
 * @param int            Custom param
 * @param int            Custom param 2
 * @noreturn
 */
forward OnCustomCommand(char[] name, int client, int param, int param2);  

/**
 * Called when player has successfully used special skill
 *
 * @param client         The client index of the player playing tetris.
 * @param className      Skill that user just used
 * @noreturn
 */
native void OnSpecialSkillSuccess(int client, char[] skillName);  

/**
 * Called when player has failed using special skill
 *
 * @param client         The client index of the player playing tetris.
 * @param className      Skill that user just used
 * @param reason         Reason for failure
 * @noreturn
 */
native void OnSpecialSkillFail(int client, char[] skillName, char[] reason);  

/**
 * Register plugin 
 *
 * @param skillName      Unique identifier for plugin
 * @param type       	 0 = On Demand skill (e.g. push button), 1 = Constant perk that is applied throughout the game
 * @return int
 */
native int RegisterDLRSkill(char[] skillName, int type);  



stock function OnDLRAvailable() {

	bool DLR_Available = LibraryExists("dlr_talents_2023");
	int classId;
	if (DLR_Available) {
		classId = RegisterDLRSkill(PLUGIN_SKILL_NAME, 0);
	} else {
		classId = -1;
	}
	return classId;
}

public SharedPlugin __pl_DLRCore = 
{
    name = DLRCORE_PLUGIN_NAME,
    file = DLRCORE_PLUGIN_FILE,
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_DLRCore_SetNTVOptional()
{
    MarkNativeAsOptional("GetPlayerClassName");
    MarkNativeAsOptional("OnSpecialSkillFail");
    MarkNativeAsOptional("OnSpecialSkillSuccess");
    MarkNativeAsOptional("RegisterDLRSkill");
    MarkNativeAsOptional("FindSkillIdByName");
}
#endif

/**
 TIMERS 
**/
stock Handle:g_ClientTimers[MAXPLAYERS+1];

stock CreateClientTimer(client, Float:interval, Timer:func, flags=TIMER_REPEAT)
{
    if (g_ClientTimers[client] == INVALID_HANDLE)
        g_ClientTimers[client] = CreateTimer(interval,func,client,flags);
}

stock KillClientTimer(client)
{
    new Handle:timer=g_ClientTimers[client];
    if (timer != INVALID_HANDLE)
    {
        KillTimer(timer);
        g_ClientTimers[client] = INVALID_HANDLE;    
    }
}

stock KillAllClientTimers()
{
    for (new i = 1; i <= MaxClients; i++)
        KillClientTimer(i);
}  


#define MAXPROPERTIES			16										// Total data entries to read from a grenades config
#define MAXCLASS				8	


/** CLASS SYSTEM **/

enum struct playerClass {
	int perkId
	char className[32]
	char classDescription[32]
    playerClassProperties properties
}

enum struct playerClassProperties {
    float maxHealth
    float jumpVelocity
    float attackDamage
    float attackRate
    float armorRate
    float healingRate
    float tankStumbleBlock
}

enum struct skillSet {
	int skillSetId
	char skillSetName[32]
	char skillSetDescription[128]
	char skillISetdentifier[32]
	int maxPlayers
	int	skillSetType 
	int action // 1 = Plugin, 2 = Internal command, 3 = perk, ran on round start and reset in end
	char menuIdentifier[16]
	skillAction[MAXPROPERTIES] actions
}

enum struct skillAction {
	int client
	int actionId
	int actionType // 1 = Execute standard OnSpecialSKillUsed hooks // 2 = use OnCustomCommand hook // 3 = execute on startup	
	int pluginName
	char parameter[3];
	char[2] bindToKey
	int interval
	float lastUsed
	bool runInStartup
	char successText[128]
	char failureText[128]
	char announceText[128]
}


