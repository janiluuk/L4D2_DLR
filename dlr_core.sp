
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
native int:GetPlayerClassName(client);

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
 * @param iSize          Size of skillname
 * @noreturn
 */
forward OnSpecialSkillUsed(client, skillName, iSize);  

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

stock char[] Translate(int iClient, const char[] format, any ...)
{
	char buffer[192];
	SetGlobalTransTarget(iClient);
	VFormat(buffer, sizeof(buffer), format, 3);
	return buffer;
}

/**
*   @note Used for in-line string translation.
*
*   @param  iClient     Client Index, translation is apllied to.
*   @param  format      String formatting rules. By default, you should pass at least "%t" specifier.
*   @param  ...			Variable number of format parameters.
*   @return char[192]	Resulting string. Note: output buffer is hardly limited.
*/
stock char[] TranslateNoColor(int iClient, const char[] format, any ...)
{
	char buffer[192];
	SetGlobalTransTarget(iClient);
	VFormat(buffer, sizeof(buffer), format, 3);
	RemoveColor(buffer, sizeof(buffer));
	return buffer;
}

/**
*   @note Prints a message to a specific client in the chat area. Supports named colors in translation file.
*
*   @param  iClient     Client Index.
*   @param  format		Formatting rules.
*   @param  ...			Variable number of format parameters.
*   @no return
*/
stock void CPrintToChat(int iClient, const char[] format, any ...)
{
    char buffer[192];
    SetGlobalTransTarget(iClient);
    VFormat(buffer, sizeof(buffer), format, 3);
    ReplaceColor(buffer, sizeof(buffer));
    PrintToChat(iClient, "\x01%s", buffer);
}

/**
*   @note Prints a message to all clients in the chat area. Supports named colors in translation file.
*
*   @param  format		Formatting rules.
*   @param  ...			Variable number of format parameters.
*   @no return
*/
stock void CPrintToChatAll(const char[] format, any ...)
{
    char buffer[192];
    for( int i = 1; i <= MaxClients; i++ )
    {
        if( IsClientInGame(i) && !IsFakeClient(i) )
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 2);
            ReplaceColor(buffer, sizeof(buffer));
            PrintToChat(i, "\x01%s", buffer);
        }
    }
}

/**
*   @note Converts named color to control character. Used internally by string translation functions.
*
*   @param  char[]		Input/Output string for convertion.
*   @param  maxLen		Maximum length of string buffer (includes NULL terminator).
*   @no return
*/
stock void ReplaceColor(char[] message, int maxLen)
{
    ReplaceString(message, maxLen, "{white}", "\x01", false);
    ReplaceString(message, maxLen, "{cyan}", "\x03", false);
    ReplaceString(message, maxLen, "{orange}", "\x04", false);
    ReplaceString(message, maxLen, "{green}", "\x05", false);
}

/**
* @note Removes named color to empty string. Used internally by string translation functions.
*
*   @param  char[]		Input/Output string for convertion.
*   @param  maxLen		Maximum length of string buffer (includes NULL terminator).
*   @no return
*/
stock void RemoveColor(char[] message, int maxLen)
{
    ReplaceString(message, maxLen, "{white}", "", false);
    ReplaceString(message, maxLen, "{cyan}", "", false);
    ReplaceString(message, maxLen, "{orange}", "", false);
    ReplaceString(message, maxLen, "{green}", "", false);
}

/**
*   @note Prints a hint message to all clients. Supports individual string translation for each client.
*
*   @param  format		Formatting rules.
*   @param  ...			Variable number of format parameters.
*   @no return
*/
stock void CPrintHintTextToAll(const char[] format, any ...)
{
    char buffer[192];
    for( int i = 1; i <= MaxClients; i++ )
    {
        if( IsClientInGame(i) && !IsFakeClient(i) )
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 2);
            PrintHintText(i, buffer);
        }
    }
}

/**
*   @note Prints a center screen message to all clients. Supports individual string translation for each client.
*
*   @param  format		Formatting rules.
*   @param  ...			Variable number of format parameters.
*   @no return
*/
stock void CPrintCenterTextAll(const char[] format, any ...)
{
    char buffer[192];
    for( int i = 1; i <= MaxClients; i++ )
    {
        if( IsClientInGame(i) && !IsFakeClient(i) )
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 2);
            PrintCenterText(i, buffer);
        }
    }
}

public SharedPlugin:__pl_dlr_talents_2023 = 
{
	name = "dlr_talents_2023",
	file = "dlr_talents_2023.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_dlr_talents_2023_SetNTVOptional()
{
	MarkNativeAsOptional("GetPlayerClassName");
}
#endif
