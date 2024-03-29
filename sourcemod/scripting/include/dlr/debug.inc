
stock void PrintDebug(int client, const char[] format, any ...)
{
	if (getDebugMode() >= 1) {
		static char buffer[192];
		VFormat(buffer, sizeof(buffer), format, 2);		
		PrintToChat(client, "[Debug] %s", buffer);
		if (getDebugMode() == 2) {
			PrintToConsole(0, "[Debug] %s", buffer);
			LogMessage("%s", buffer);
		}
		return;
	}

	#if DEBUG || DEBUG_LOG || DEBUG_TRACE
	static char buffer[192];
	
	VFormat(buffer, sizeof(buffer), format, 2);
	#if DEBUG_LOG
	PrintToConsoleAll("[Debug] %s", buffer);	
	PrintToConsole(0, "[Debug] %s", buffer);
	LogMessage("[Debug] %s", buffer);
	#endif 
	#if DEBUG || DEBUG_TRACE
	PrintToChat(client, "[Debug] %s", buffer);
	#endif

	#else
	//suppress "format" never used warning
	if(format[0])
		return;
	else
		return;
	#endif
}

stock void PrintDebugAll(const char[] format, any ...)
{
	if (getDebugMode() >= 1) {
		static char buffer[192];
		VFormat(buffer, sizeof(buffer), format, 2);		
		PrintToChatAll("[Debug] %s", buffer);
		if (getDebugMode() == 2) {
			PrintToConsole(0, "[Debug] %s", buffer);
			LogMessage("%s", buffer);
		}
		return;
	}

	#if DEBUG || DEBUG_LOG || DEBUG_TRACE
	static char buffer[192];
	VFormat(buffer, sizeof(buffer), format, 2);
	#if DEBUG_LOG
	PrintToConsoleAll("[Debug] %s", buffer);	
	PrintToConsole(0, "[Debug] %s", buffer);
	LogMessage("[Debug] %s", buffer);
	#endif
	#if DEBUG || DEBUG_TRACE
	PrintToChatAll("[Debug] %s", buffer);
	#endif
	#else
	if(format[0])
		return;
	else
		return;
	#endif
}

/**
*   @note Converts named color to control character. Used internally by string translation functions.
*
*   @param  char[]		Input/Output string for convertion.
*   @param  maxLen		Maximum length of string buffer (includes NULL terminator).
*   @no return
*/
stock void ReplaceColors(char[] message, int maxLen)
{
    ReplaceString(message, maxLen, "{white}", "\x01", false);
    ReplaceString(message, maxLen, "{cyan}", "\x03", false);
    ReplaceString(message, maxLen, "{orange}", "\x04", false);
    ReplaceString(message, maxLen, "{green}", "\x05", false);
}

any Clamp(any value, any min = 0.0, any max)
{
	if( value < min )
		value = min;
	else if( value > max )
		value = max;
	return value;
}
