stock Action TimerStart(Handle timer)
{
	ResetPlugin();
	OnRoundState(1);
	DmgHookUnhook(true);

	return Plugin_Continue;
}

public Action:TimerThink(Handle:hTimer, any:userid)
{
	int client = GetClientOfUserId(userid);
	if (client <= 0 || !IsValidEntity(client) || !IsClientInGame(client) || IsFakeClient(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2)
	{
		return Plugin_Stop;
	}
	
	new buttons = GetClientButtons(client);
	new Float:fCanDropTime = (GetGameTime() - ClientData[client].LastDropTime);
	new bool:CanDrop = (fCanDropTime >= ClientData[client].SpecialDropInterval);
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	int iDropTime = RoundToFloor(fCanDropTime);

	switch (ClientData[client].ChosenClass)
	{
		case athlete:
		{	
			SetEntDataFloat(client, g_flLaggedMovementValue, GetConVarFloat(ATHLETE_SPEED), true);
			if (buttons & IN_ZOOM) {

				char pendingMessage[128] = "Wait %i seconds to use anti-gravity grenade again";
				
				if (canUseSpecialSkill(client, pendingMessage)) {
					//useSpecialSkill(client, 11);
					useCustomCommand("Grenades", client, -1, 15);
					ClientData[client].LastDropTime = GetGameTime();
				}

			}
		}
		
		case saboteur:
		{
			if (BombActive == true) {

				if (iDropTime > 0 && iDropTime < GetConVarInt(SABOTEUR_BOMB_ACTIVATE)) {

						PrintHintText(client, "Mine is arming in %i seconds", client, GetConVarInt(SABOTEUR_BOMB_ACTIVATE) - iDropTime);
					
				}
				else if (iDropTime == GetConVarInt(SABOTEUR_BOMB_ACTIVATE)) {
										
					if (BombHintTimestamp != iDropTime) {
						PrintHintTextToAll("%N's mine is now armed!", client);
						BombHintTimestamp = iDropTime;
					}
				}
			}
			if (buttons & IN_ZOOM) {
					char pendingMessage[128] = "Wait for %i seconds to activate cloak again";
					if (canUseSpecialSkill(client, pendingMessage)) {
						useSpecialSkill(client, 1);						
						ClientData[client].LastDropTime = GetGameTime();
					}

			}
			if (buttons & IN_DUCK)
			{
				int hidingTime = RoundToFloor(GetGameTime() - ClientData[client].HideStartTime);
				if (hidingTime >= GetConVarInt(SABOTEUR_INVISIBLE_TIME)) {
					if (InvisibilityTimestamp != hidingTime && InvisibilityHint == false) 
					{
						SetRenderProperties(client);

                                                FakeClientCommand(client, "sm_nap_apply 7");
                                                FakeClientCommand(client, "sm_extendedsight");

						//HidePlayer(client);

						//SetEntityRenderFx(client, RENDERFX_PULSE_SLOW);
						InvisibilityTimestamp = hidingTime;
						InvisibilityHint = true;

					}
				}
				if (hidingTime < GetConVarInt(SABOTEUR_INVISIBLE_TIME) && (hidingTime > 2)){
					GlowPlayer(client, "Blue", FX:FxHologram);

					if (InvisibilityTimestamp != hidingTime) {
						PrintHintText(client,"Becoming invisible in %i seconds", GetConVarInt(SABOTEUR_INVISIBLE_TIME) - hidingTime);
						InvisibilityTimestamp = hidingTime;
					}
				}
			}
			
			else if (buttons & IN_SPEED)
			{
				if(!(GetEntityFlags(client) & FL_ONGROUND)) {
				} else {
					if (CanDrop == false && (iDropTime > 0 && iDropTime < GetConVarInt(MINIMUM_DROP_INTERVAL))) 
					{
							PrintHintText(client ,"Wait %i seconds to another mine", (GetConVarInt(MINIMUM_DROP_INTERVAL) - iDropTime));
					} else {

						if (CanDrop == true && !IsPlayerInSaferoom(client) && !IsInEndingSaferoom(client))
						{
							if (ClientData[client].SpecialsUsed >= GetConVarInt(SABOTEUR_MAX_BOMBS)) {
								PrintHintText(client ,"You're out of mines");
							} else {
								CreatePlayerSaboteurMenu(client);
							}
						}
					}
				}
			}
			else
			{
				InvisibilityHint = false;
			}

		}
		case commando:
		{
			if (buttons & IN_ZOOM) {

					char pendingMessage[128] = "Wait for %i seconds to activate berzerk mode again";
					if (canUseSpecialSkill(client, pendingMessage)) {
						useSpecialSkill(client, 1);
						PrintHintText(client, "You activated berzerk mode!");
					}
			}
		}
		case medic:
		{
			if (buttons & IN_SPEED)
			{
				if (CanDrop) 
				{	
					if (ClientData[client].SpecialsUsed > GetConVarInt(MEDIC_MAX_ITEMS)) {
						PrintHintText(client ,"You're out of items (Max %i)", GetConVarInt(MEDIC_MAX_ITEMS));
					}
					if (ClientData[client].SpecialsUsed < GetConVarInt(MEDIC_MAX_ITEMS))
					{	
						CreatePlayerMedicMenu(client);	
					}
				}
				else if (CanDrop == false && (iDropTime < GetConVarInt(MINIMUM_DROP_INTERVAL))) {
					if (!(ClientData[client].LastButtons & IN_SPEED))					
					PrintHintText(client ,"Wait %i seconds to deploy", (GetConVarInt(MINIMUM_DROP_INTERVAL) - iDropTime));
				}

			}

			if (buttons & IN_ZOOM) {

				char pendingMessage[128] = "Wait %i seconds to use healing orb again";
				
				if (canUseSpecialSkill(client, pendingMessage)) {
					//useSpecialSkill(client, 11);
					useCustomCommand("Grenades", client, -1, 11);
					ClientData[client].LastDropTime = GetGameTime();
				}

			}

			if (buttons & IN_DUCK) 
			{
				SetEntDataFloat(client, g_flLaggedMovementValue, 1.7, true);

				if ((GetGameTime() - ClientData[client].HealStartTime) >= 3.0) {
					if (MedicHint == false) {
						PrintHintTextToAll("%N is healing everyone around him!", client);
						MedicHint = true;
					}
				}
			} else {
				SetEntDataFloat(client, g_flLaggedMovementValue, 1.0, true);					
				MedicHint = false;
			}
		}
			
		case engineer:
		{
			if (buttons & IN_SPEED && RoundStarted == true)// && ClientData[client].SpecialsUsed < GetConVarInt(ENGINEER_MAX_BUILDS)) 
			{	
				if (CanDrop == false && (iDropTime < GetConVarInt(MINIMUM_DROP_INTERVAL))) {
					PrintHintText(client ,"Wait %i seconds to deploy again", (GetConVarInt(MINIMUM_DROP_INTERVAL) - iDropTime));
				}
				if (CanDrop == true) {
					if(ClientData[client].SpecialsUsed < GetConVarInt(ENGINEER_MAX_BUILDS))
					{
						CreatePlayerEngineerMenu(client);
					}
					else
					{
						PrintHintText(client ,"You're out of items (Max %i)", GetConVarInt(ENGINEER_MAX_BUILDS));
					}
				}					
			}
			else if (buttons & IN_ZOOM) {

				char pendingMessage[128] = "Wait %i seconds to activate shield again";
				
				if (canUseSpecialSkill(client, pendingMessage)) {
					useCustomCommand("Grenades", client, -1, 7);
					PrintHintText(client ,"You threw a protective shield (Max %i)", GetConVarInt(ENGINEER_MAX_BUILDS));

					ClientData[client].LastDropTime = GetGameTime();
				}

			}
		}
		case soldier:
		{
			SetEntDataFloat(client, g_flLaggedMovementValue, GetConVarFloat(SOLDIER_SPEED), true);

			if (buttons & IN_ZOOM)
			{
				char pendingMessage[128] = "Wait %d seconds to order new airstrike.";
				
				if (canUseSpecialSkill(client, pendingMessage)) {
					useCustomCommand("Grenades", client, -1, 19);
					ClientData[client].LastDropTime = GetGameTime();
				}
			}
		}
	}

	ClientData[client].LastButtons = buttons;
	return Plugin_Continue;
}


public Action:TimerLoadClient(Handle:hTimer, any:client)
{
	if (!client ||  !IsValidEntity(client) || !IsClientInGame(client)) 
	return Plugin_Stop;

	ResetPlugin();
	ResetClientVariables(client);	
	if (RoundStarted == false && !IsPlayerInSaferoom(client) && !IsInEndingSaferoom(client)) {
		RoundStarted = true;	
	}
	return Plugin_Stop;
}

public Action Timer_Ready(Handle timer, int client) {
	if (!IsValidClient(client) ||  !IsPlayerAlive(client) || GetClientTeam(client) != 2)
	{ return Plugin_Stop; }

	GetPlayerSkillReadyHint(client);
	//KillTimer(g_ReadyTimer, true);
	g_ReadyTimer[client] = null;
	return Plugin_Stop;
}

public Action:TimerRestorePlayer(Handle:hTimer, Handle:hPack)
{
	ResetPack(hPack);
	new userid = ReadPackCell(hPack);
	new client = GetClientOfUserId(userid);
	new chosenClass = ReadPackCell(hPack);
	CloseHandle(hPack);
	ClientData[client].ChosenClass = view_as<ClassTypes>(chosenClass);

	return Plugin_Stop;

}
public Action:TimerSetClientTempHealth(Handle:hTimer, Handle:hPack)
{
	ResetPack(hPack);
	new client = ReadPackCell(hPack);
	new iValue = ReadPackCell(hPack);
	CloseHandle(hPack);
	
	if(!client
		|| !IsValidEntity(client)
		|| !IsClientInGame(client)
		|| !IsPlayerAlive(client)
		|| IsClientObserver(client)
		|| GetClientTeam(client) != 2)
	return;
	
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", iValue*1.0);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}

public Action:GlowTimer(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	int client = ReadPackCell(pack);
	int health = ReadPackCell(pack);
	CloseHandle(pack);

	if (!IsClientInGame(client) || !IsPlayerAlive(client)) return Plugin_Stop;
	new newHp = GetClientHealth(client);
	new TempHealth = GetClientTempHealth(client);
	new totalHp = newHp+TempHealth;

	if (totalHp > health) {
		new Handle:hPack = CreateDataPack();
		WritePackCell(hPack, client);
		WritePackCell(hPack, totalHp);

		CreateTimer(1.0, GlowTimer, hPack, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Continue;
	} else {
		SetRenderProperties(client);
	}

	return Plugin_Stop;
}

public Action:TimerDetectHealthChanges(Handle:hTimer, any:client)
{
	if (!client
		|| !IsValidEntity(client)
		|| !IsClientInGame(client)
		|| ClientData[client].ChosenClass != medic)
	return Plugin_Stop;
	
	if(!IsPlayerAlive(client) || GetClientTeam(client) != 2)
	{	return Plugin_Continue; }
	
	new btns = GetClientButtons(client);

	if (btns & IN_DUCK)
	{
		CreateParticle(client, MEDIC_GLOW, true, 1.0);

		decl Float:pos[3];
		decl String:sMessage[256];	
		GetClientAbsOrigin(client, pos);
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && i != client)
			{
				decl Float:tpos[3];
				GetClientAbsOrigin(i, tpos);
				
				if (GetVectorDistance(pos, tpos) <= GetConVarFloat(MEDIC_HEAL_DIST))
				{
					// pre-heal set values
					new MaxHealth = GetEntProp(i, Prop_Send, "m_iMaxHealth");
					new TempHealth = GetClientTempHealth(i);

					Format(sMessage, sizeof(sMessage), "%N is healing you!", client);

					ShowBar(i, sMessage, float(GetClientHealth(i)), float(MaxHealth));
					SetEntityHealth(i, GetClientHealth(i) + GetConVarInt(MEDIC_HEALTH_VALUE));
					SetClientTempHealth(i, TempHealth);
					
					// post-heal set values
					new newHp = GetClientHealth(i);
					new totalHp = newHp + TempHealth;
					GlowPlayer(i, "Green", FX:FxEnvRain);
					new Handle:hPack = CreateDataPack();
					WritePackCell(hPack, i);
					WritePackCell(hPack, totalHp);

					CreateTimer(1.0, GlowTimer, hPack, TIMER_FLAG_NO_MAPCHANGE ); 	
					
					if (totalHp > MaxHealth)
					{
						new diff = totalHp - MaxHealth;
						
						if (TempHealth >= diff)
						{
							SetClientTempHealth(i, TempHealth - diff);
							continue;
						}
						
						SetClientTempHealth(i, 0);
						SetEntityHealth(i, MaxHealth);
					}
				}
			}
		}
	} else {

		MedicHint = false;
	}
	
	return Plugin_Continue;
}

public Action:TimerAirstrike(Handle timer, Handle:hPack)
{
	new Float:pos[3];
	new Float:time;
	int client;
	int entity;
	int userId;
	ResetPack(hPack);
	userId = ReadPackCell(hPack);		
	client = GetClientOfUserId(userId);
	pos[0] = ReadPackFloat(hPack);
	pos[1] = ReadPackFloat(hPack);
	pos[2] = ReadPackFloat(hPack);
	time =  ReadPackFloat(hPack);
	entity = ReadPackCell(hPack);

	if (client > 0 && IsClientInGame(client) && RoundToFloor(GetGameTime()-time) <= 10) {
		PrintHintTextToAll("Airstrike in %i, take cover!",10-(RoundToFloor(GetGameTime()-time)));
		
		return Plugin_Continue;
	} else {

		g_bAirstrikeValid = true;
		PrintHintTextToAll("Airstrike completed!");
		ClientData[client].SpecialsUsed++;
		F18_ShowAirstrike(pos, GetRandomFloat(0.0, 180.0));

		if(IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "Kill");
		}
	}

	return Plugin_Stop;
}

public Action:TimerActivateBomb(Handle:hTimer, Handle:hPack)
{
	CreateTimer(0.3, TimerCheckBombSensors, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Stop;
}

public Action:TimerCheckBombSensors(Handle:hTimer, Handle:hPack)
{
	new Float:pos[3];
	decl Float:clientpos[3];
	
	ResetPack(hPack);
	pos[0] = ReadPackFloat(hPack);
	pos[1] = ReadPackFloat(hPack);
	pos[2] = ReadPackFloat(hPack);
	new ownerUser = ReadPackCell(hPack);
	new owner = GetClientOfUserId(ownerUser);
	
	if (IsValidSurvivor(owner, false) != true) {
		return Plugin_Stop;
	}

	new session = ReadPackCell(hPack);
	int index = ReadPackCell(hPack);
	int bombType = ReadPackCell(hPack);
	int entity = ReadPackCell(hPack);

	if (index < 0) index = 0;

	if (session != RndSession)
	return Plugin_Stop;
	
	for (new client = 1; client <= MaxClients; client++)
	{

		if (!IsValidEntity(client) || !IsClientInGame(client))
		continue;

		if(GetClientTeam(client) == 3 || GetClientTeam(client) == 2 || IsWitch(client))
		{
			char classname[32];
			GetClientAbsOrigin(client, clientpos);
			GetEdictClassname(client, classname, sizeof(classname));

			if (GetVectorDistance(pos, clientpos) < GetConVarFloat(SABOTEUR_BOMB_RADIUS))
			{
				if (GetClientTeam(client) == 3 || IsWitch(client) || IsTank(client)) {
	
					
					if (GetConVarInt(SABOTEUR_BOMB_TYPES) == 1) {
						PrintDebugAll("Enabling single minetype mode");
						CreateExplosion(pos, client);					
					}
					
					if (!IsValidEntity(owner) || !IsClientInGame(owner)) {
						return Plugin_Stop;
					}
					BombActive = false;
					BombIndex[index] = false;
					PrintHintTextToAll("%N's mine detonated!", owner);
		

					PrintDebugAll("Detonating Mine %s on entity %i", getBombName(bombType), entity );

					useCustomCommand("Grenades", owner, entity, bombType-1);					
					
					return Plugin_Stop;
				}
				else if (GetClientTeam(client) == 2) {
					
					if (!mineWarning[client] || mineWarning[client] < GetGameTime() + 5) {
						PrintHintText(client, "Warning! You are nearby armed mine.");
						mineWarning[client] = GetGameTime();
					}
				}
			}
			
		}
	}
	return Plugin_Continue;
}

/**
 * @note Validates if the current client is valid to run the plugin.
 *
 * @param client		The client index.
 * @return              False if the client is not the Tank, true otherwise.
 */

stock bool IsTank(int client)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 33)
		if(GetEntProp(client, Prop_Send, "m_zombieClass") == 8)
			return true;
	
	return false;
}


public Action:TimerRemovePrecacheParticle(Handle:timer, any:Particle)
{
	if (IsValidEdict(Particle))
	AcceptEntityInput(Particle, "Kill");
}

public Action:timerHurtEntity(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new attacker = ReadPackCell(pack);
	new Float:amount = ReadPackFloat(pack);
	new type = ReadPackCell(pack);
	CloseHandle(pack);
	HurtEntity(client, attacker, amount, type);
}

public Action:TimerStopFire(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new particle = ReadPackCell(pack);
	new hurt = ReadPackCell(pack);
	CloseHandle(pack);
	
	if(IsValidEntity(particle))
	{
		AcceptEntityInput(particle, "Stop");
	}
	
	if(IsValidEntity(hurt))
	{
		AcceptEntityInput(hurt, "TurnOff");
	}
}

public Action:TimerDeleteParticles(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	
	new entity;
	for (new i = 1; i <= 7; i++)
	{
		entity = ReadPackCell(pack);
		
		if(IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
	
	CloseHandle(pack);
}

public Action:TimerActivateBombParticle(Handle:timer, any:entity)
{
	if (entity > 0 && IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "Kill");
	}

}

public Action:TimerStopAndRemoveParticle(Handle:timer, any:entity)
{
	if (entity > 0 && IsValidEntity(entity))
	{
		if (BombActive == true) {
			CreateTimer(3.0, TimerStopAndRemoveParticle, entity, TIMER_FLAG_NO_MAPCHANGE);			
		} else {
			AcceptEntityInput(entity, "Kill");
		}
	}		
}

public Action:TimerStopAndRemoveBombParticle(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	int entity = ReadPackCell(pack);
	int index = ReadPackCell(pack);
	int mine = ReadPackCell(pack);	
	CloseHandle(pack);
	if (entity > 0 && IsValidEntity(entity)) 
	{
		if (BombActive == false) {
			AcceptEntityInput(entity, "Kill");
		} else {
			static float vPos[3];
			char color[12];
			new Handle:hPack = CreateDataPack();
			WritePackCell(hPack, index);
			WritePackCell(hPack, entity);
			GetConVarString(SABOTEUR_ACTIVE_BOMB_COLOR, color, sizeof(color));
			SetupPrjEffects(entity, vPos, color); // Red
			int defibParticle;
			int elmosParticle;
			// Particle
			defibParticle = DisplayParticle(entity, PARTICLE_DEFIB, vPos, NULL_VECTOR);				
			WritePackCell(hPack, defibParticle);

			if (defibParticle) InputKill(defibParticle, 2.0);
			elmosParticle = DisplayParticle(entity, PARTICLE_ELMOS, vPos, NULL_VECTOR);
			if (elmosParticle) InputKill(elmosParticle, 3.0);
			WritePackCell(hPack, elmosParticle);
			WritePackCell(hPack, mine);

			CreateTimer(15.0, TimerDeleteBombs, hPack, TIMER_FLAG_NO_MAPCHANGE);			
		}
	}
}

public Action:TimerDeleteBombs(Handle:timer, Handle:pack)
{		
	ResetPack(pack);
	int index = ReadPackCell(pack);
	bool removed = false;

	if (BombIndex[index] == false) {
		for (new i = 0; i < 3; i++)
		{
			int entity = ReadPackCell(pack);
			if(entity > 0 && IsValidEntity(entity))
			{
				AcceptEntityInput(entity, "Kill");
				removed = true;
			}
		}
		CloseHandle(pack);

	} else {
		new Handle:hPack = CreateDataPack();
		WritePackCell(hPack, index);
		int entity = ReadPackCell(pack);
		WritePackCell(hPack, entity);
		int defibParticle = ReadPackCell(pack);
		WritePackCell(hPack, defibParticle);
		int elmosParticle = ReadPackCell(pack);
		WritePackCell(hPack, elmosParticle);
		int mine = ReadPackCell(pack);
		WritePackCell(hPack, mine);
		CloseHandle(pack);
		CreateTimer(5.0, TimerDeleteBombs, hPack, TIMER_FLAG_NO_MAPCHANGE);		
		return Plugin_Continue;
	}
	if (removed == true) {
		return Plugin_Stop;
	} 
	return Plugin_Continue;
}

public Action Timer_Parachute( Handle timer, any iEntity)
{
	int iParachute = EntRefToEntIndex(iEntity);
	if (IsValidEntity(iParachute))
	{
		RotateParachute(iParachute, 100.0, 1);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}