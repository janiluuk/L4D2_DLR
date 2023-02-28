
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

public Action:Command_Debug(client, args) {
	
	if (args < 1)
	{
		ReplyToCommand(client, "\x03[DLR]\x01 Usage: \x04sm_debug\x01 [0 = Off|1 = On]");
		return Plugin_Handled;
	}
		
	decl String:arg[MAX_NAME_LENGTH];
	GetCmdArg(1, arg, sizeof(arg));

	setSessionDebug(StringToInt(arg));

	bool debugMode =  StringToInt(arg) > 0 ? true:false;
	setDebugMode(debugMode);

	return Plugin_Handled;
	
}

stock ShowDebugMenu(client) {

	new Handle:menu = CreateMenu(Admin_MnuHdlr_DebugOpts);	
	
	decl String:title[100];
	Format(title, sizeof(title), "Debugging Options");
	
	SetMenuTitle(menu, title);
	
	decl String:name[64];
	
	Format(name, sizeof(name),  "Debugging Off"); 
	AddMenuItem(menu, "0", name); 
			
	Format(name, sizeof(name),  "Print Debug Info to Chat"); 
	AddMenuItem(menu, "1", name); 

	Format(name, sizeof(name),  "Log Debug Info to File"); 
	AddMenuItem(menu, "2", name); 	
	
	Format(name, sizeof(name),  "Print Trace Debug Info to Chat"); 
	AddMenuItem(menu, "3", name); 	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
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

// Format very top level admin menu entry
public Admin_TopDebugMenu(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {

	
	switch (action)
	{
		case TopMenuAction_DisplayTitle, TopMenuAction_DisplayOption:
		{
			Format(buffer, maxlength, "DLR Menu and Game Control");
		}
	}

}
public Admin_MnuHdlr_DebugOpts(Handle:menu, MenuAction:action, param1, param2) {

	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_Select:
		{
			decl String:info[32];
				
			GetMenuItem(menu, param2, info, sizeof(info));
			new debugopt = StringToInt(info);
			
			if (debugopt < 0) debugopt = 0;
			if (debugopt > 2) debugopt = 2;
			bool debugMode = debugopt > 0 ? true : false;
			setDebugMode(debugMode);
			setSessionDebug(debugopt);

			PrintToChatAll("Server Debugging has been set to: %d.", getSessionDebug());
		}
	}

}

// Handle the switch menu items (switch player/swap players)
public Admin_TopMenuHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	
	
	new String:mnuinfo[MAX_NAME_LENGTH];
	GetTopMenuInfoString(topmenu, object_id, mnuinfo, sizeof(mnuinfo));
	
	new index = StringToInt(mnuinfo);
	
	switch(action)
	{
		case TopMenuAction_DisplayOption:
		{
			Format(buffer, maxlength, CommandText[index]);
		}
		case TopMenuAction_SelectOption:
		{
			if (index == 0) { ShowDebugMenu(param); }
		/*	else if (index == 1) { Admin_ChoosePlayerMenu(param, true); }
			else if (index == 2) { Command_Unscramble(param, 0); }
			else if (index == 3) { Command_SwapTeams(param, 0); }	
			else if (index == 4) { Command_PauseGame(param, 0); }	
			else if (index == 5) { Command_UnpauseGame(param, 0); }	
			else if (index == 6) { ShowCurrTeamPanel(param, 0); }
			else if (index == 7) { ShowLastRoundTeamPanel(param, 0); }	
			else if (index == 0) { (param); }	*/
		}			
	}
}

