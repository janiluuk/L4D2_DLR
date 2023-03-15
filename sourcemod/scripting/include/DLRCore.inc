
#if defined _DLRCore_included
#endinput
#endif
#define _DLRCore_included
#define DLRCore_version "1.0.0"
#define DLR_PLUGIN_NAME = "dlr_talents"
#define DLR_PLUGIN_FILE = "dlr_talents.smx"
stock int checkDlrPluginState(char[] pluginName, int type=0)
{
    #if defined PLUGIN_SKILL_NAME
        bool libraryCheck = LibraryExists("dlr_talents");
        if (libraryCheck == true) {
            return RegisterDLRSkill(PLUGIN_SKILL_NAME, 0);
        }
    #endif
        return -1;
}
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

forward DLR_GetClientSkill(int client, char[] skillName);


/**
 * Get player skillname
 *
 * @param client  Client index.

 * @param skillName String to assign the name to 
 * @param size 		Size of the string
 * @return        	int
 */
native int GetPlayersWithSkillName(int client, char[] skillName, int size);


/**
 * Get skill ID by name
 *
 * @param skillName Name of the skill
 * @return        ID || -1
 */
native int FindSkillIdByName(char[] skillName);

/**
 * Get skill name by id
 *
 * @param skillId ID of the skill
 * @return       void
 */
native void FindSkillNameById(int skillId, char[] skillName, int size);

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
forward DLR_OnRoundState(int roundstate);

/**
 * Called when client hooks up with the skil
 * @param int client
 * @noreturn
 */
forward DLR_OnLoad(int client);
/**
 * Called when plugin becomes available
 *
 *
 * @param state 	int value, 1=Available/0=Unloaded
 * @noreturn
 */
forward void DLR_OnPluginState(char[] plugin, int pluginstate);

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

native int UnregisterDLRSkill(char[] skillName);  

public SharedPlugin __pl_DLRCore = 
{
    name = "dlr_talents",
    file = "dlr_talents.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_DLRCore_SetNTVOptional()
{
    MarkNativeAsOptional(" PlayerClassName");
    MarkNativeAsOptional("OnSpecialSkillFail");
    MarkNativeAsOptional("OnSpecialSkillSuccess");
    MarkNativeAsOptional("RegisterDLRSkill");
    MarkNativeAsOptional("UnregisterDLRSkill");
    MarkNativeAsOptional("FindSkillIdByName");
    MarkNativeAsOptional("FindSkillNameByName");
    MarkNativeAsOptional("OnPluginStateChange");
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
