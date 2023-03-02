
new bool:disableInfected = false;


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

// Format very top level admin menu entry
public Admin_TopDebugMenu(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {

	
	switch (action)
	{
		case TopMenuAction_DisplayTitle, TopMenuAction_DisplayOption:
		{
			Format(buffer, maxlength, "DLR Settings");
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

new String:CommandText[][] = {
"Debugging Options",
"Tools",
"Inspect registered skills"
};
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
			else if (index == 1) { ShowDebugMenu(param); } /**
			else if (index == 2) { Command_Unscramble(param, 0); }
			else if (index == 3) { Command_SwapTeams(param, 0); }	
			else if (index == 4) { Command_PauseGame(param, 0); }	
			else if (index == 5) { Command_UnpauseGame(param, 0); }	
			
			else if (index == 6) { ShowCurrTeamPanel(param, 0); }
			else if (index == 7) { ShowLastRoundTeamPanel(param, 0); }	*/
			else if (index == 0) { (param); }	
		}			
	}
}


public Action:CreatePlayerClassMenuDelay(Handle:hTimer, any:client)
{
	CreatePlayerClassMenu(client);
}

stock Action:CmdClasses(client, args)
{	
	for (new i = 1; i <= MaxClients; i++)
	{

		if(ClientData[i].ChosenClass != NONE)
		{
			PrintToChatAll("\x04%N\x01 : is a %s",i,ClassTips[i]);
		}
	}
}


public Action:CmdClassInfo(client, args)
{
	PrintToChat(client,"\x05Soldier\x01 = Has faster attack rate, runs faster and takes less damage");
	PrintToChat(client,"\x05Athlete\x01 = Jumps higher, has parachute.");
	PrintToChat(client,"\x05Medic\x01 = Heals others, plants medical supplies. Faster revive & heal speed");
	PrintToChat(client,"\x05Saboteur\x01 = Can go invisible, plants powerful mines and throws special grenades");
	PrintToChat(client,"\x05Commando\x01 = Has fast reload, deals extra damage");
	PrintToChat(client,"\x05Engineer\x01 = Drops auto turrets and ammo");
	PrintToChat(client,"\x05Brawler\x01 = Has Lots of health");	
}

public Action:CmdClassMenu(client, args)
{
	if (GetClientTeam(client) != 2)
	{
		PrintToChat(client, "%sOnly Survivors can choose a class.", PRINT_PREFIX);
		return;
	}
	CreatePlayerClassMenu(client);
}

public Action:CmdDlrMenu(client, args)
{
	if (isAdmin(client)) 
		CreateDlrMenu(client);
}

public CreateDlrMenu(client) {

	if (!client)
	return false;
	
	new Handle:hPanel;
	
	if((hPanel = CreatePanel()) == INVALID_HANDLE)
	{
		LogError("Cannot create hPanel on DlrMenu");
		return false;
	}
	
	SetPanelTitle(hPanel, "Functions:");
	DrawPanelItem(hPanel, "Toggle Debug Messages");
	DrawPanelItem(hPanel, "Toggle infected");
	DrawPanelItem(hPanel, "List registered skills");
	DrawPanelText(hPanel, " ");
	DrawPanelItem(hPanel, "Exit");
	SendPanelToClient(hPanel, client, PanelHandler_DlrMenu, MENU_OPEN_TIME);
	CloseHandle(hPanel);
	
	return true;
}

public Action:CmdPlugins(client, args)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if(ClientData[i].ChosenClass != NONE)
		{
			PrintToChat(client, "\x04%N\x01 : is a %s",i,MENU_OPTIONS[ClientData[i].ChosenClass]);
		}
	}
}


public Action Cmd_SetVictim(int client, int args) {
	if(args == 0) {
		ReplyToCommand(client, "Please enter a player to target");
	}else{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));

		char target_name[MAX_TARGET_LENGTH];
		int target_list[1], target_count;
		bool tn_is_ml;

		if ((target_count = ProcessTargetString(
				arg1,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_ALIVE, /* Only allow alive players */
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			/* This function replies to the admin with a failure message */
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		for(int i = 0; i < target_count; i++) {
			int victim = target_list[i];
			//g_iSITargets
			g_bIsVictim[victim] = !g_bIsVictim[victim];
			ReplyToCommand(client, "Successfully toggled %N victim status to: %b", victim, g_bIsVictim[victim]);
			ShowActivity(client, "toggled special infected victim status for %N to %b", victim, g_bIsVictim[victim]);
		}
	}
	return Plugin_Handled;
}
public Action Cmd_GetHud(int client, int args) {

	char arg1[128];

	int hud = getCurrentHud();
	ReplyToCommand(client, "Current HUD id: %i", hud);
	
	return Plugin_Handled;
}

public Action Cmd_SetupHud(int client, int args) {

	char arg1[64];
	char arg2[64];
	char arg3[64];
	char arg4[64];
	char arg5[64];
	char arg6[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	GetCmdArg(4, arg4, sizeof(arg4));
	GetCmdArg(5, arg5, sizeof(arg5));
	GetCmdArg(6, arg6, sizeof(arg6));

	if(args < 6) {
		ReplyToCommand(client, "Give position ID, flags, xpos, ypos, width, height. (Min 0.0, Max 1.0) ");
	} else {

		SetupMessageHud(view_as<hudPosition>(StringToInt(arg1)), StringToInt(arg2), StringToFloat(arg3), StringToFloat(arg4), StringToFloat(arg5),StringToFloat(arg6));


		setCurrentHud(view_as<hudPosition>(StringToInt(arg1)));
		ReplyToCommand(client, "Set current HUD to %i", arg1);
	}

	return Plugin_Handled;
}
public Action Cmd_SetHud(int client, int args) {

	char arg1[128];

	if(args == 0) {
		ReplyToCommand(client, "Give position ID");
	} else {
		GetCmdArg(1, arg1, sizeof(arg1));
		setCurrentHud(StringToInt(arg1));
		ReplyToCommand(client, "Set current HUD to %i", arg1);
	}

	return Plugin_Handled;
}
public Action Cmd_ClearHUD(int client, int args) {

	ReplyToCommand(client, "Hud Cleared");
	ClearHUD();
	return Plugin_Handled;
}
public Action Cmd_CloseHUD(int client, int args) {

	ReplyToCommand(client, "Hud Closed");
	ClearHUD();
	return Plugin_Handled;
}
public Action Cmd_DeleteHUD(int client, int args) {

	char arg1[128];

	if(args == 0) {
		ReplyToCommand(client, "Deleting all huds");
		DeleteAllHUD();
	} else {
		GetCmdArg(1, arg1, sizeof(arg1));
	}
	
	int index = StringToInt(arg1);
	int a = 1;
	for (int i = 1; i < 16; i++) {
		if (i == index) {
			DeleteHUD(view_as<hudPosition>(a));
		}
		a=a*2;
	}

	ReplyToCommand(client, "Deleted hud %i (1-15)", StringToInt(arg1));

	return Plugin_Handled;
}

public Action Cmd_PrintToHUD(int client, int args) {
	char arg1[128];

	if(args == 0) {
		ReplyToCommand(client, "Please enter message and position (1-15)");
	} else {
		GetCmdArg(1, arg1, sizeof(arg1));
	}
	if (args < 2) {
		PrintToHud(arg1);
	} else {
		char arg2[3];
		GetCmdArg(2, arg2, sizeof(arg2));
		PrintToHudPosition(arg1, StringToInt(arg2));
	}

	return Plugin_Handled;
}

public Action:GrenadeCommand(client, args)
{
	if (isAdmin(client)) {
		// Index
		int index;
		char str[3];
		new type=GetCmdArg(1, str, 32);
		if(type==0) {
		}
		else
		{
			int c = StringToInt(str);
			index = c;
		}			
		useCustomCommand("Grenades", client, -1, index);
	}			
	
	return Plugin_Handled;
}

public Action:HideCommand(client, args)
{
	if (client > 0 && IsClientInGame(client) && isAdmin(client)) {

		new String:str[32];
		new type=GetCmdArg(1, str, 32);
		if(type==0) {
		}
		else
		{
			int c = StringToInt(str);
			if (c || IsValidEntity(c) || IsClientInGame(c)){
				client = c;					
			}
		}			
		HidePlayer(client);
	}
	return Plugin_Handled;
}

