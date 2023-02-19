
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
native int GetPlayerClassName(client);

native int GetPlayerSkillName(int client, char[] skillName, int size);

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
forward OnSpecialSkillUsed(int iClient, int skill);  

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

native int RegisterDLRSkill(char[] skillName);  

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

}
#endif
