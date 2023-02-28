
new bool:disableInfected = false;

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

new String:CommandText[][] = {
"Debugging Options",
"Tools",
"Inspect registered skills"
};

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

public Action Cmd_ClearHUD(int client, int args) {

	ReplyToCommand(client, "Hud Cleared");
	ClearHUD();
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

