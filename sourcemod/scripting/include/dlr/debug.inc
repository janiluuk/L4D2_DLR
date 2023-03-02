
#include <adminmenu>

stock void PrintDebug(int client, const char[] format, any ...)
{
	if (getSessionDebug() >= 1) {
		static char buffer[192];
		VFormat(buffer, sizeof(buffer), format, 2);		
		PrintToChat(client, "[Debug] %s", buffer);
		if (getSessionDebug() == 2) {
			PrintToConsole(0, "[Debug] %s", buffer);
			LogMessage("%s", buffer);
		}
		return;
	}

	#if DEBUG || DEBUG_LOG || DEBUG_TRACE
	static char buffer[192];
	
	VFormat(buffer, sizeof(buffer), format, 2);
	#if DEBUG_LOG
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
	if (getSessionDebug() >= 1) {
		static char buffer[192];
		VFormat(buffer, sizeof(buffer), format, 2);		
		PrintToChatAll("[Debug] %s", buffer);
		if (getSessionDebug() == 2) {
			PrintToConsole(0, "[Debug] %s", buffer);
			LogMessage("%s", buffer);
		}
		return;
	}

	#if DEBUG || DEBUG_LOG || DEBUG_TRACE
	static char buffer[192];
	VFormat(buffer, sizeof(buffer), format, 2);
	#if DEBUG_LOG
	PrintToConsole(0, "[Debug] %s", buffer);
	LogMessage("%s", buffer);
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



public OnAdminMenuReady(Handle:topmenu) {
	
	
	// Check ..
	if (topmenu == hTopMenu) return;
		
	// We save the handle
	hTopMenu = topmenu;

	new TopMenuObject:debug_menu = AddToTopMenu(hTopMenu, "DlrDebugMenu", TopMenuObject_Category, Admin_TopDebugMenu, INVALID_TOPMENUOBJECT); 
	
	// now we add the function ...
	if (debug_menu != INVALID_TOPMENUOBJECT)
	{
		
		AddToTopMenu(hTopMenu, "debugpanel", TopMenuObject_Item, Admin_TopMenuHandler, debug_menu, "debugpanel", ADMFLAG_GENERIC, "1");
			
	}
}



