
#if defined _DLRCore_included
#endinput
#endif
#define _DLRCore_included
#define DLRCore_version "1.0.0"

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

forward OnCustomCommand(char[] name, int client, int entity, int type);  

public SharedPlugin __pl_DLRCore = 
{
    name = "dlr_talents_2023",
    file = "dlr_talents_2023.smx",
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
