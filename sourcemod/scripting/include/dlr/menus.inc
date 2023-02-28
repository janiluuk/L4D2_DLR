

///////////////////////////////////////////////////////////////////////////////////
// Class menu
///////////////////////////////////////////////////////////////////////////////////

stock bool:CreatePlayerClassMenu(client)
{
	new Handle:hPanel;
	decl String:buffer[256];
	if((hPanel = CreatePanel()) == INVALID_HANDLE)
	{
		LogError("Cannot create hPanel on CreatePlayerClassMenu");
		return false;
	}
	
	if (!client ||  !IsClientInGame(client) || GetClientTeam(client) != 2) {
		return false;
	}
	
	// if client has a class already and round has started, dont give them the menu
	if (ClientData[client].ChosenClass != NONE && RoundStarted == true)
	{
		PrintToChat(client,"Round has started, your class is locked, You are a %s",MENU_OPTIONS[ClientData[client].ChosenClass]);
		return false;
	}
	
	if(IsClientInGame(client) && ClientData[client].ChosenClass == NONE && RoundStarted == false)
	{
		setPlayerDefaultHealth(client);
	}
	
	SetPanelTitle(hPanel, "Select Your Class");
	
	for (new i = 1; i < view_as<int>(MAXCLASSES); i++)
	{
		if( GetMaxWithClass(i) >= 0 )
		Format(buffer, sizeof(buffer), "%i/%i %s", CountPlayersWithClass(i), GetMaxWithClass(i),  MENU_OPTIONS[i]);
		else
		Format(buffer, sizeof(buffer), "%s", MENU_OPTIONS[i]);
		DrawPanelItem(hPanel, buffer);
	}
	
	DrawPanelText(hPanel, " ");
	DrawPanelItem(hPanel, "Exit");
	
	SendPanelToClient(hPanel, client, PanelHandler_SelectClass, MENU_OPEN_TIME);
	CloseHandle(hPanel);
	
	return true;
}

public PanelHandler_SelectClass(Handle:menu, MenuAction:action, client, param)
{
	ClassTypes OldClass;
	OldClass = ClientData[client].ChosenClass;

	switch (action)
	{
		case MenuAction_Select:
		{
			if (!client || param >= view_as<int>(MAXCLASSES) || GetClientTeam(client)!=2 )
			{
				return;
			}
			
			if( GetMaxWithClass( param ) >= 0 && CountPlayersWithClass( param ) >= GetMaxWithClass( param ) && view_as<int>(ClientData[client].ChosenClass)!= param ) 
			{
				PrintToChat( client, "%sThe \x04%s\x01 class is full, please choose another.", PRINT_PREFIX, MENU_OPTIONS[ param ] );
				CreatePlayerClassMenu( client );
			} 
			else
			{
				//DrawConfirmPanel(client, param);
				
				LastClassConfirmed[client] = param;
				ClientData[client].ChosenClass = view_as<ClassTypes>(param);	

				// Inform other plugins.
				Call_StartForward(g_hfwdOnPlayerClassChange);
				Call_PushCell(client);
				Call_PushCell(ClientData[client].ChosenClass);
				Call_PushCell(LastClassConfirmed[client]);
				Call_Finish();				

				PrintToConsole(client, "Class is setting up");
				
				SetupClasses(client, param);
				EmitSoundToClient(client, SOUND_CLASS_SELECTED);
				RebuildCache();
				if(view_as<int>(OldClass) == 0)
				{
					PrintToChatAll("\x04%N\x01 is a \x05%s\x01%s",client,MENU_OPTIONS[param],ClassTips);
				}	
				else
				{
					PrintToChatAll("\x04%N\x01 : class changed from \x05%s\x01 to \x05%s\x01",client,MENU_OPTIONS[OldClass],MENU_OPTIONS[param]);
				}
			}
		}	
	}	
}

///////////////////////////////////////////////////////////////////////////////////
// Engineer 
///////////////////////////////////////////////////////////////////////////////////

public CreatePlayerEngineerMenu(client)
{
	if (!client)
	return false;
	
	new Handle:hPanel;
	
	if((hPanel = CreatePanel()) == INVALID_HANDLE)
	{
		LogError("Cannot create hPanel on CreatePlayerEngineerMenu");
		return false;
	}
	
	SetPanelTitle(hPanel, "Engineer:");
	DrawPanelItem(hPanel, "Ammo Pile");
	DrawPanelItem(hPanel, "Deploy Turret");
	DrawPanelItem(hPanel, "Incendiary Rounds");
	DrawPanelItem(hPanel, "Frag Rounds");
	DrawPanelText(hPanel, " ");
	DrawPanelItem(hPanel, "Exit");
	
	SendPanelToClient(hPanel, client, PanelHandler_SelectEngineerItem, MENU_TIME_FOREVER);
	CloseHandle(hPanel);
	
	return true;
}

public PanelHandler_SelectEngineerItem(Handle:menu, MenuAction:action, client, param)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if( param >= 1 && param <= 4 )//was 5
			CalculateEngineerPlacePos(client, param - 1);
		}
	}
}

public void CalculateEngineerPlacePos(client, type)
{
	decl Float:vAng[3], Float:vPos[3], Float:endPos[3];
	
	GetClientEyeAngles(client, vAng);
	GetClientEyePosition(client, vPos);

	new Handle:trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, TraceFilter, client);

	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(endPos, trace);
		CloseHandle(trace);
		
		if (GetVectorDistance(endPos, vPos) <= GetConVarFloat(ENGINEER_MAX_BUILD_RANGE))
		{
			vAng[0] = 0.0;
			vAng[2] = 0.0;
			
			switch(type) {
				case 0: 
				{
					new ammo = CreateEntityByName("weapon_ammo_spawn");
					DispatchSpawn(ammo);
					TeleportEntity(ammo, endPos, NULL_VECTOR, NULL_VECTOR);
					ClientData[client].SpecialsUsed++;
					ClientData[client].LastDropTime = GetGameTime();
				}
				case 1:
				{
					useSpecialSkill(client, 0);
				}
				case 3: 
				{
					new upgrade = CreateEntityByName("upgrade_ammo_explosive");
					SetEntityModel(upgrade, MODEL_EXPLO);
					TeleportEntity(upgrade, endPos, NULL_VECTOR, NULL_VECTOR);
					DispatchSpawn(upgrade);
					PrintHintText(client ,"%N deployed explosive ammo", client);
					ClientData[client].LastDropTime = GetGameTime();
					ClientData[client].SpecialsUsed++;
				}
				case 2: 
				{
					new upgrade = CreateEntityByName("upgrade_ammo_incendiary");
					SetEntityModel(upgrade, MODEL_INCEN);
					TeleportEntity(upgrade, endPos, NULL_VECTOR, NULL_VECTOR);
					PrintHintText(client ,"%N deployed incendiary ammo", client);
					ClientData[client].LastDropTime = GetGameTime();
					ClientData[client].SpecialsUsed++;
					DispatchSpawn(upgrade);

				}
				default: {
					CloseHandle( trace );
					return;
				}
			}
				
		}
		else
		PrintToChat(client, "%sCould not place the item because you were looking too far away.", PRINT_PREFIX);
	}
	else
	CloseHandle(trace);
}

///////////////////////////////////////////////////////////////////////////////////
// Health modifiers & medic
///////////////////////////////////////////////////////////////////////////////////

public bool:CreatePlayerMedicMenu(client)
{
	if (!client)
	return false;
	
	new Handle:hPanel;
	
	if((hPanel = CreatePanel()) == INVALID_HANDLE)
	{
		LogError("Cannot create hPanel on CreatePlayerMedicMenu");
		return false;
	}
	
	SetPanelTitle(hPanel, "Medic:");
	DrawPanelItem(hPanel, "Defibrillator");
	DrawPanelItem(hPanel, "Medkit");
	DrawPanelItem(hPanel, "Adrenaline");
	DrawPanelItem(hPanel, "Pills");
	DrawPanelItem(hPanel, "Exit");
	SendPanelToClient(hPanel, client, PanelHandler_SelectMedicItem, MENU_OPEN_TIME);
	CloseHandle(hPanel);
	
	return true;
}

public PanelHandler_SelectMedicItem(Handle:menu, MenuAction:action, client, param)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if( param >= 1 && param <= 4 )
			CalculateMedicPlacePos(client, param - 1);
			ClientData[client].LastDropTime = GetGameTime();
		}
	}
}

public DlrSkillMenuHandler(Handle:hMenu, MenuAction:action, client, iSkillSelection)
{
    if(action == MenuAction_Select)
    {
        /* Start Function Call */
        Call_StartForward(g_hOnSkillSelected);
        Call_PushCell(client);
        Call_PushCell(iSkillSelection);        
        Call_Finish();
    }
}

public PanelHandler_DlrMenu(Handle:menu, MenuAction:action, client, param)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if( param == 1)
			{
				PrintHintText(client,"Debug mode is %s",  (getDebugMode() == true) ? "ON" : "OFF");
			}
			if (param == 2) 
			{
				disableInfected = (disableInfected == true) ? false : true;

				if (disableInfected == true) {
					SetConVarInt(FindConVar("director_no_bosses"), 1);
					SetConVarInt(FindConVar("director_no_mobs"), 1);
					SetConVarInt(FindConVar("z_common_limit"), 0);
					SetConVarInt(FindConVar("z_boomer_limit"), 0);
					SetConVarInt(FindConVar("z_charger_limit"), 0);
					SetConVarInt(FindConVar("z_hunter_limit"), 0);
					SetConVarInt(FindConVar("z_jockey_limit"), 0);
					SetConVarInt(FindConVar("z_smoker_limit"), 0);
					SetConVarInt(FindConVar("z_spitter_limit"), 0);
				} else {
					ResetConVar(FindConVar("director_no_bosses"));
					ResetConVar(FindConVar("director_no_mobs"));
					ResetConVar(FindConVar("z_common_limit"));
					ResetConVar(FindConVar("z_boomer_limit"));
					ResetConVar(FindConVar("z_charger_limit"));
					ResetConVar(FindConVar("z_hunter_limit"));
					ResetConVar(FindConVar("z_jockey_limit"));
					ResetConVar(FindConVar("z_smoker_limit"));
					ResetConVar(FindConVar("z_spitter_limit"));  
				}
				PrintHintText(client,"Infected are now %s", disableInfected ? "DISABLED" : "ENABLED");
			}
			if( param == 3)
			{
			        DisplayMenu(g_hSkillMenu, client, MENU_TIME_FOREVER);
			}
		}
	}
}

//////////////////////////
// Saboteur 
//////////////////////////
public bool:CreatePlayerSaboteurMenu(client)
{
	if (!client)
	return false;
	
	new Handle:menu = CreateMenu(SelectSaboteurItem);
	
	SetMenuExitButton(menu, true);
	SetMenuTitle(menu, "Select mine type:");	
	for (new i = 0; i < MAX_BOMBS; i++ ) {

		char bombInfo[32];
		char bombIndex[3];
		IntToString(g_AvailableBombs[i].bombIndex, bombIndex, sizeof(bombIndex));
		Format(bombInfo, sizeof(bombInfo), "%s", g_AvailableBombs[i].getItem());

		if (!StrEqual(bombInfo, "")) {
			AddMenuItem(menu, bombIndex, bombInfo);
		}
	}

	DisplayMenu(menu, client, MENU_TIME_FOREVER);

	return true;
}

public SelectSaboteurItem(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if (StringToInt(menucmd) > 0) {
				CalculateSaboteurPlacePos(param1, StringToInt(menucmd));
			}
		}
		case MenuAction_Cancel:
		{
			
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

///////////////////////////////////////////////////////////////////////////////////
// DLR menu
///////////////////////////////////////////////////////////////////////////////////

public bool:isAdmin(client)
{
	if (client == 0 && GetUserAdmin(client) == INVALID_ADMIN_ID) { return false; }
	else { return true; }
}

