#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.4"

enum SelfHelpState
{
	SHS_NONE = 0,
	SHS_START_SELF = 1,
	SHS_START_OTHER = 2,
	SHS_CONTINUE = 3,
	SHS_END = 4
};

ConVar shEnable, shUse, shIncapPickup, shDelay, shKillAttacker, shBot, shBotChance, shHardHP,
	shTempHP, shMaxCount, cvarReviveDuration, cvarMaxIncapCount, cvarAdrenalineDuration;

bool bIsL4D, bEnabled, bIncapPickup, bKillAttacker, bBot;
float fAdrenalineDuration, fDelay, fTempHP, fLastPos[MAXPLAYERS+1][3], fSelfHelpTime[MAXPLAYERS+1];
int iSurvivorClass, iKillAttacker, iUse, iBotChance, iHardHP, iMaxCount, iAttacker[MAXPLAYERS+1],
	iBotHelp[MAXPLAYERS+1], iReviveDuration, iMaxIncapCount, iSHCount[MAXPLAYERS+1];

Handle hSHTime[MAXPLAYERS+1] = null, hSHGameData = null, hSHSetTempHP = null, hSHAdrenalineRush = null,
	hSHOnRevived = null, hSHStagger = null;

char sGameSounds[6][] =
{
	"music/terror/PuddleOfYou.wav",
	"music/terror/ClingingToHellHit1.wav",
	"music/terror/ClingingToHellHit2.wav",
	"music/terror/ClingingToHellHit3.wav",
	"music/terror/ClingingToHellHit4.wav",
	"player/heartbeatloop.wav"
};

SelfHelpState shsBit[MAXPLAYERS+1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion evRetVal = GetEngineVersion();
	if (evRetVal != Engine_Left4Dead && evRetVal != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "[SH] Plugin Supports L4D And L4D2 Only!");
		return APLRes_SilentFailure;
	}
	
	bIsL4D = (evRetVal == Engine_Left4Dead) ? true : false;
	iSurvivorClass = (evRetVal == Engine_Left4Dead2) ? 9 : 6;
	
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "Self-Help (Reloaded) - DLR edition",
	author = "yani, cravenge, panxiaohai",
	description = "Lets Players Help Themselves When Troubled.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=281620"
};

public void OnPluginStart()
{
	hSHGameData = LoadGameConfigFile("self_help");
	if (hSHGameData == null)
	{
		SetFailState("[SH] Game Data Missing!");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hSHGameData, SDKConf_Signature, "OnStaggered");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
	hSHStagger = EndPrepSDKCall();
	if (hSHStagger == null)
	{
		SetFailState("[SH] Signature 'OnStaggered' Broken!");
	}
	
	if (!bIsL4D)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hSHGameData, SDKConf_Signature, "OnRevived");
		hSHOnRevived = EndPrepSDKCall();
		if (hSHOnRevived == null)
		{
			SetFailState("[SH] Signature 'OnRevived' Broken!");
		}
		
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hSHGameData, SDKConf_Signature, "SetHealthBuffer");
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		hSHSetTempHP = EndPrepSDKCall();
		if (hSHSetTempHP == null)
		{
			SetFailState("[SH] Signature 'SetHealthBuffer' Broken!");
		}
		
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hSHGameData, SDKConf_Signature, "OnAdrenalineUsed");
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		hSHAdrenalineRush = EndPrepSDKCall();
		if (hSHAdrenalineRush == null)
		{
			SetFailState("[SH] Signature 'OnAdrenalineUsed' Broken!");
		}
		
		delete hSHGameData;
	}
	
	cvarReviveDuration = FindConVar("survivor_revive_duration");
	iReviveDuration = cvarReviveDuration.IntValue;
	cvarReviveDuration.AddChangeHook(OnSHCVarsChanged);
	
	if (bIsL4D)
	{
		delete cvarAdrenalineDuration;
	}
	else
	{
		delete shMaxCount;
		
		cvarMaxIncapCount = FindConVar("survivor_max_incapacitated_count");
		iMaxIncapCount = cvarMaxIncapCount.IntValue;
		cvarMaxIncapCount.AddChangeHook(OnSHCVarsChanged);
		
		cvarAdrenalineDuration = FindConVar("adrenaline_duration");
		fAdrenalineDuration = cvarAdrenalineDuration.FloatValue;
		cvarAdrenalineDuration.AddChangeHook(OnSHCVarsChanged);
	}
	
	CreateConVar("self_help_version", PLUGIN_VERSION, "Self-Help (Reloaded) Version", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	shEnable = CreateConVar("self_help_enable", "1", "Enable/Disable Plugin", FCVAR_NOTIFY|FCVAR_SPONLY, true, 0.0, true, 1.0);
	shUse = CreateConVar("self_help_use", "3", "Use: 0=None, 1=Pills And Adrenalines, 2=First Aid Kits Only, 3=Both", FCVAR_NOTIFY|FCVAR_SPONLY, true, 0.0, true, 3.0);
	shIncapPickup = CreateConVar("self_help_incap_pickup", "1", "Enable/Disable Item Pick-Ups While Incapacitated", FCVAR_NOTIFY|FCVAR_SPONLY, true, 0.0, true, 1.0);
	shDelay = CreateConVar("self_help_delay", "1.0", "Delay Before Plugin Mechanism Kicks In", FCVAR_NOTIFY|FCVAR_SPONLY);
	shKillAttacker = CreateConVar("self_help_kill_attacker", "2", "0=Unpin using gear 1=Unpin and kill attacker 2=Unpin disabled", FCVAR_NOTIFY|FCVAR_SPONLY, true, 0.0, true, 2.0);
	shBot = CreateConVar("self_help_bot", "1", "Enable/Disable Bot Self-Help", FCVAR_NOTIFY|FCVAR_SPONLY, true, 0.0, true, 1.0);
	shBotChance = CreateConVar("self_help_bot_chance", "4", "Chance Of Bot Self-Helping: 1=Sometimes, 2=Often, 3=Seldom 4=Always", FCVAR_NOTIFY|FCVAR_SPONLY, true, 1.0, true, 4.0);
	shHardHP = CreateConVar("self_help_hard_hp", "50", "Health Given After Self-Helping", FCVAR_NOTIFY|FCVAR_SPONLY, true, 1.0);
	shTempHP = CreateConVar("self_help_temp_hp", "50.0", "Temporary Health Given After Self-Helping", FCVAR_NOTIFY|FCVAR_SPONLY, true, 1.0);
	
	if (bIsL4D)
	{
		shMaxCount = CreateConVar("self_help_max_count", "3", "Maximum Attempts of Self-Help", FCVAR_NOTIFY|FCVAR_SPONLY, true, 3.0);
		iMaxCount = shMaxCount.IntValue;
		shMaxCount.AddChangeHook(OnSHCVarsChanged);
	}
	
	iUse = shUse.IntValue;
	iBotChance = shBotChance.IntValue;
	iHardHP = shHardHP.IntValue;
	
	bEnabled = shEnable.BoolValue;
	bIncapPickup = shIncapPickup.BoolValue;
	bKillAttacker = shKillAttacker.BoolValue;
	iKillAttacker = shKillAttacker.IntValue;

	bBot = shBot.BoolValue;
	
	fDelay = shDelay.FloatValue;
	fTempHP = shTempHP.FloatValue;
	
	shEnable.AddChangeHook(OnSHCVarsChanged);
	shUse.AddChangeHook(OnSHCVarsChanged);
	shIncapPickup.AddChangeHook(OnSHCVarsChanged);
	shDelay.AddChangeHook(OnSHCVarsChanged);
	shKillAttacker.AddChangeHook(OnSHCVarsChanged);

	shBot.AddChangeHook(OnSHCVarsChanged);
	shBotChance.AddChangeHook(OnSHCVarsChanged);
	shHardHP.AddChangeHook(OnSHCVarsChanged);
	shTempHP.AddChangeHook(OnSHCVarsChanged);
	
	AutoExecConfig(true, "self_help");
	
	HookEvent("round_start", OnRoundEvents);
	HookEvent("round_end", OnRoundEvents);
	HookEvent("finale_win", OnRoundEvents);
	HookEvent("mission_lost", OnRoundEvents);
	HookEvent("map_transition", OnRoundEvents);
	
	HookEvent("player_incapacitated", OnPlayerDown);
	HookEvent("player_ledge_grab", OnPlayerDown);
	
	HookEvent("player_bot_replace", OnReplaceEvents);
	HookEvent("bot_player_replace", OnReplaceEvents);
	
	HookEvent("revive_begin", OnReviveBegin);
	HookEvent("revive_end", OnReviveEnd);
	HookEvent("revive_success", OnReviveSuccess);
	
	HookEvent("heal_success", OnHealSuccess);
	
	HookEvent("tongue_grab", OnInfectedGrab);
	HookEvent("lunge_pounce", OnInfectedGrab);
	if (!bIsL4D)
	{
		HookEvent("jockey_ride", OnInfectedGrab);
		HookEvent("charger_pummel_start", OnInfectedGrab);
		
		HookEvent("jockey_ride_end", OnInfectedRelease);
		HookEvent("charger_pummel_end", OnInfectedRelease);
		
		HookEvent("defibrillator_used", OnDefibrillatorUsed);
	}
	HookEvent("tongue_release", OnInfectedRelease);
	HookEvent("pounce_stopped", OnInfectedRelease);
	
	AddNormalSoundHook(OnSHSoundsFix);
	
	CreateTimer(0.1, RecordLastPosition, _, TIMER_REPEAT);
}

public void OnSHCVarsChanged(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	if (!bIsL4D)
	{
		iMaxIncapCount = cvarMaxIncapCount.IntValue;
		
		fAdrenalineDuration = cvarAdrenalineDuration.FloatValue;
	}
	
	iReviveDuration = cvarReviveDuration.IntValue;
	
	iUse = shUse.IntValue;
	iBotChance = shBotChance.IntValue;
	iHardHP = shHardHP.IntValue;
	
	bEnabled = shEnable.BoolValue;
	bIncapPickup = shIncapPickup.BoolValue;
	bKillAttacker = shKillAttacker.BoolValue;
	iKillAttacker = shKillAttacker.IntValue;

	bBot = shBot.BoolValue;
	
	fDelay = shDelay.FloatValue;
	fTempHP = shTempHP.FloatValue;
	
	if (bIsL4D)
	{
		iMaxCount = shMaxCount.IntValue;
	}
}

public Action OnSHSoundsFix(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (StrEqual(sample, "music/tags/PuddleOfYouHit.wav", false) || StrEqual(sample, "music/tags/ClingingToHellHit1.wav", false) || StrEqual(sample, "music/tags/ClingingToHellHit2.wav", false) || 
		StrEqual(sample, "music/tags/ClingingToHellHit3.wav", false) || StrEqual(sample, "music/tags/ClingingToHellHit4.wav", false))
	{
		numClients = 0;
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || GetClientTeam(i) == 3 || IsFakeClient(i))
			{
				continue;
			}
			
			clients[numClients++] = i;
		}
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Action RecordLastPosition(Handle timer)
{
	if (!IsServerProcessing())
	{
		return Plugin_Continue;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i))
		{
			continue;
		}
		
		if (!GetEntProp(i, Prop_Send, "m_isHangingFromLedge", 1))
		{
			if (!bBot && IsFakeClient(i))
			{
				continue;
			}
			
			float fCurrentPos[3];
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", fCurrentPos);
			
			fLastPos[i] = fCurrentPos;
		}
	}
	
	return Plugin_Continue;
}

public void OnMapStart()
{
	if (!bIsL4D && !IsSoundPrecached("weapons/knife/knife_deploy.wav"))
	{
		PrecacheSound("weapons/knife/knife_deploy.wav", true);
	}
	
	if (!IsSoundPrecached("weapons/knife/knife_hitwall1.wav"))
	{
		PrecacheSound("weapons/knife/knife_hitwall1.wav", true);
	}
}

public void OnRoundEvents(Event event, const char[] name, bool dontBroadcast)
{
	if (!bEnabled)
	{
		return;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			shsBit[i] = SHS_NONE;
			
			iAttacker[i] = 0;
			iBotHelp[i] = 0;
			
			if (bIsL4D)
			{
				iSHCount[i] = 0;
			}
			
			fSelfHelpTime[i] = 0.0;
			
			if (hSHTime[i] != null)
			{
				hSHTime[i] = null;
			}
		}
	}
}

public void OnPlayerDown(Event event, const char[] name, bool dontBroadcast)
{
	if (!bEnabled)
	{
		return;
	}
	
	int wounded = GetClientOfUserId(event.GetInt("userid"));
	if (IsSurvivor(wounded))
	{
		if (GetEntProp(wounded, Prop_Send, "m_zombieClass") != iSurvivorClass)
		{
			return;
		}
		
		CreateTimer(fDelay, FireUpMechanism, GetClientUserId(wounded));
		PrintToChat(wounded, "You Got Incapacitated! |%N|", name);

		if (StrEqual(name, "player_incapacitated"))
		{
			PrintHintText(wounded, "Hold R To Revive Other Incapacitated Survivors!");
			
			if (bIsL4D)
			{
				if (iSHCount[wounded] + 1 > iMaxCount)
				{
					iSHCount[wounded] = iMaxCount - 1;
				}
				
				//CPrintToChat(wounded, "You Got Incapacitated! |{green}%d/%i{default}|", iSHCount[wounded] + 1, iMaxCount);
				if (iSHCount[wounded] == iMaxCount)
				{
					for (int i = 1; i <= MaxClients; i++)
					{
						if (!IsClientInGame(i) || IsFakeClient(i) || i == wounded)
						{
							continue;
						}
						
						PrintHintText(i, "\n%N Will Be In B/W State After Revive/Self-Help!", wounded);
					}
				}
			}
			else
			{
				int iReviveCount = GetEntProp(wounded, Prop_Send, "m_currentReviveCount");
				if (iReviveCount + 1 > iMaxIncapCount)
				{
					iReviveCount = iMaxIncapCount - 1;
				}
				
				PrintToChat(wounded, "You Got Incapacitated! |%d/%i|", iReviveCount + 1, iMaxIncapCount);
				if (iReviveCount == iMaxIncapCount)
				{
					for (int i = 1; i <= MaxClients; i++)
					{
						if (!IsClientInGame(i) || IsFakeClient(i) || i == wounded)
						{
							continue;
						}
						
						PrintHintText(i, "\n%N Will Be In B/W State After Revive/Self-Help!", wounded);
					}
				}
			}
		}
	}
}

public Action FireUpMechanism(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsSurvivor(client) || !IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}
	
	shsBit[client] = SHS_NONE;
	if (hSHTime[client] == null)
	{
		if (!GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) && !GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1))
		{
			if (iAttacker[client] == 0 || (iAttacker[client] != 0 && (!IsClientInGame(iAttacker[client]) || !IsPlayerAlive(iAttacker[client]) || iKillAttacker == 2)))
			{
				return Plugin_Stop;
			}
		}
		
		if (GetEntProp(client, Prop_Send, "m_reviveOwner") > 0 && GetEntProp(client, Prop_Send, "m_reviveOwner") != client)
		{
			return Plugin_Stop;
		}
		
		if (bBot && IsFakeClient(client) && iBotHelp[client] == 0 && (GetRandomInt(1, 3) == iBotChance || iBotChance > 3))
		{
			iBotHelp[client] = 1;
		}
		
		fSelfHelpTime[client] = 0.0;
		
		if (IsSelfHelpAble(client) && !IsFakeClient(client))
		{
			CPrintToChat(client, "Press {green}CROUCH{default} To Self-Help!");
		}
		hSHTime[client] = CreateTimer(0.1, AnalyzePlayerState, GetClientUserId(client), TIMER_REPEAT);
	}
	
	return Plugin_Stop;
}

public Action AnalyzePlayerState(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsSurvivor(client) || !IsPlayerAlive(client) || (!bBot && IsFakeClient(client)) || shsBit[client] == SHS_END)
	{
		shsBit[client] = SHS_NONE;
		
		if (hSHTime[client] != null)
		{
			if (!bIsL4D)
			{
				KillTimer(hSHTime[client]);
			}
			hSHTime[client] = null;
		}
		return Plugin_Stop;
	}
	
	if (!GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) && !GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1))
	{
		if (iAttacker[client] == 0 || (iAttacker[client] != 0 && (!IsClientInGame(iAttacker[client]) || !IsPlayerAlive(iAttacker[client]) || iKillAttacker == 2)))
		{
			iAttacker[client] = 0;
			
			if (hSHTime[client] != null)
			{
				if (!bIsL4D)
				{
					KillTimer(hSHTime[client]);
				}
				hSHTime[client] = null;
			}
			return Plugin_Stop;
		}
	}
	
	if (hSHTime[client] == null)
	{
		return Plugin_Stop;
	}
	
	int iButtons = GetClientButtons(client);
	char sSHMessage[128];
	
	if (IsSelfHelpAble(client))
	{
		if (iButtons & IN_DUCK)
		{
			if (shsBit[client] == SHS_NONE || shsBit[client] == SHS_CONTINUE)
			{
				shsBit[client] = SHS_START_SELF;
				if (!IsFakeClient(client))
				{
					strcopy(sSHMessage, sizeof(sSHMessage), "REVIVING YOURSELF");
					DisplaySHProgressBar(client, client, iReviveDuration, sSHMessage, true);
					
					if (!bIsL4D)
					{
						PrintHintText(client, "Helping Yourself!");
					}
				}
				
				DataPack dpSHRevive = new DataPack();
				dpSHRevive.WriteCell(GetClientUserId(client));
				CreateTimer(0.1, SHReviveCompletion, dpSHRevive, TIMER_REPEAT|TIMER_DATA_HNDL_CLOSE);
			}
		}
		else
		{
			if (shsBit[client] == SHS_START_SELF)
			{
				shsBit[client] = SHS_NONE;
			}
		}
	}
	
	if (iButtons & IN_RELOAD)
	{
		float fPos[3], fOtherPos[3];
		
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos);
		
		int iTarget = 0;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i) || i == client)
			{
				continue;
			}
			
			if (GetEntProp(i, Prop_Send, "m_isIncapacitated", 1) && iAttacker[i] == 0)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", fOtherPos);
				
				if (GetVectorDistance(fOtherPos, fPos) > 100.0)
				{
					continue;
				}
				
				iTarget = i;
				break;
			}
		}
		if (IsSurvivor(iTarget) && IsPlayerAlive(iTarget) && GetEntProp(iTarget, Prop_Send, "m_isIncapacitated", 1) && iAttacker[iTarget] == 0)
		{
			if (shsBit[client] == SHS_NONE || shsBit[client] == SHS_CONTINUE)
			{
				shsBit[client] = SHS_START_OTHER;
				if (!IsFakeClient(client))
				{
					strcopy(sSHMessage, sizeof(sSHMessage), "HELPING TEAMMATE");
					DisplaySHProgressBar(client, iTarget, iReviveDuration, sSHMessage, true);
					
					if (!bIsL4D)
					{
						PrintHintText(client, "You Are Helping %N!", iTarget);
					}
				}
				
				if (!IsFakeClient(iTarget))
				{
					Format(sSHMessage, sizeof(sSHMessage), "BEING HELPED");
					DisplaySHProgressBar(iTarget, client, iReviveDuration, sSHMessage);
					
					if (!bIsL4D)
					{
						PrintHintText(iTarget, "%N Is Helping You!", client);
					}
				}
				
				DataPack dpSHReviveOther = new DataPack();
				dpSHReviveOther.WriteCell(GetClientUserId(client));
				dpSHReviveOther.WriteCell(GetClientUserId(iTarget));
				CreateTimer(0.1, SHReviveOtherCompletion, dpSHReviveOther, TIMER_REPEAT|TIMER_DATA_HNDL_CLOSE);
			}
		}
		else
		{
			iTarget = 0;
			
			if (shsBit[client] == SHS_START_OTHER)
			{
				shsBit[client] = SHS_NONE;
			}
		}
	}
	else
	{
		if (shsBit[client] == SHS_START_OTHER || shsBit[client] == SHS_CONTINUE)
		{
			shsBit[client] = SHS_NONE;
		}
	}
	
	if ((iButtons & IN_DUCK) && bIncapPickup)
	{
		int iItemEnt = -1;
		float fPos[3], fItemPos[3];
		
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos);
		
		if (!CheckPlayerSupply(client, 3))
		{
			while ((iItemEnt = FindEntityByClassname(iItemEnt, "weapon_first_aid_kit")) != -1)
			{
				if (!IsValidEntity(iItemEnt) || !IsValidEdict(iItemEnt))
				{
					continue;
				}
				
				GetEntPropVector(iItemEnt, Prop_Send, "m_vecOrigin", fItemPos);
				
				if (GetVectorDistance(fPos, fItemPos) <= 150.0)
				{
					ExecuteCommand(client, "give", "first_aid_kit");
					PrintHintText(client, "Grabbing First Aid Kit!");
					
					AcceptEntityInput(iItemEnt, "Kill");
					RemoveEdict(iItemEnt);
					
					break;
				}
			}
		}
		else if (!CheckPlayerSupply(client, 4))
		{
			while ((iItemEnt = FindEntityByClassname(iItemEnt, "weapon_pain_pills")) != -1)
			{
				if (!IsValidEntity(iItemEnt) || !IsValidEdict(iItemEnt))
				{
					continue;
				}
				
				GetEntPropVector(iItemEnt, Prop_Send, "m_vecOrigin", fItemPos);
				
				if (GetVectorDistance(fPos, fItemPos) <= 150.0)
				{
					ExecuteCommand(client, "give", "pain_pills");
					PrintHintText(client, "Grabbing Pain Pills!");
					
					AcceptEntityInput(iItemEnt, "Kill");
					RemoveEdict(iItemEnt);
					
					break;
				}
			}
			
			if (!bIsL4D)
			{
				while ((iItemEnt = FindEntityByClassname(iItemEnt, "weapon_adrenaline")) != -1)
				{
					if (!IsValidEntity(iItemEnt) || !IsValidEdict(iItemEnt))
					{
						continue;
					}
					
					GetEntPropVector(iItemEnt, Prop_Send, "m_vecOrigin", fItemPos);
					
					if (GetVectorDistance(fPos, fItemPos) <= 150.0)
					{
						ExecuteCommand(client, "give", "adrenaline");
					//	PrintHintText(client, "[SH]\nGrabbing Adrenaline!");
						
						AcceptEntityInput(iItemEnt, "Kill");
						RemoveEdict(iItemEnt);
						
						break;
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action SHReviveCompletion(Handle timer, Handle dpSHRevive)
{
	ResetPack(dpSHRevive);
	
	int client = GetClientOfUserId(ReadPackCell(dpSHRevive));
	if (!IsSurvivor(client) || !IsPlayerAlive(client) || !(GetClientButtons(client) & IN_DUCK))
	{
		RemoveSHProgressBar(client, true);
		
		fSelfHelpTime[client] = 0.0;
		return Plugin_Stop;
	}
	
	if (hSHTime[client] == null || shsBit[client] == SHS_NONE || (GetEntProp(client, Prop_Send, "m_reviveOwner") > 0 && GetEntProp(client, Prop_Send, "m_reviveOwner") != client))
	{
		RemoveSHProgressBar(client, true, true);
		
		fSelfHelpTime[client] = 0.0;
		return Plugin_Stop;
	}
	
	if (fSelfHelpTime[client] >= float(iReviveDuration) + 0.1)
	{
		RemoveSHProgressBar(client, true);
		
		bool bAidCheck;
		SHStatsFixer(client, (GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1)) ? true : false, _, bAidCheck);
		
		if (!GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
		{
			SetEntProp(client, Prop_Send, "m_isIncapacitated", 1, 1);
			
			Event ePlayerIncapacitated = CreateEvent("player_incapacitated");
			ePlayerIncapacitated.SetInt("userid", GetClientUserId(client));
			ePlayerIncapacitated.SetInt("attacker", GetClientUserId(iAttacker[client]));
			ePlayerIncapacitated.Fire();
			
			DataPack dpSHReviveDelay = new DataPack();
			dpSHReviveDelay.WriteCell(GetClientUserId(client));
			dpSHReviveDelay.WriteCell(bAidCheck);
			int dominator = iAttacker[client];
			if (iKillAttacker == 2 && dominator != 0 && IsClientInGame(dominator) && GetClientTeam(dominator) == 3 && IsPlayerAlive(dominator)) {
				//
			} else {
				CreateTimer(0.1, SelfReviveDelay, dpSHReviveDelay, TIMER_DATA_HNDL_CLOSE);
			}
		}
		else
		{
			Event eReviveSuccess = CreateEvent("revive_success");
			eReviveSuccess.SetInt("userid", GetClientUserId(client));
			eReviveSuccess.SetInt("subject", GetClientUserId(client));
			eReviveSuccess.SetBool("ledge_hang", (!GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1)) ? false : true);
			if (bIsL4D)
			{
				eReviveSuccess.SetBool("lastlife", (iSHCount[client] + 1 >= iMaxCount) ? true : false);
			}
			else
			{
				eReviveSuccess.SetBool("lastlife", (GetEntProp(client, Prop_Send, "m_currentReviveCount") == iMaxIncapCount) ? true : false);
			}
			eReviveSuccess.Fire();
			
			DoSelfHelp(client, bAidCheck);
			
			for (int i = 0; i < 5; i++)
			{
				UnloopAnnoyingMusic(client, sGameSounds[i]);
			}
		}
		
		
		RemoveHindrance(client);
		
		fSelfHelpTime[client] = 0.0;
		return Plugin_Stop;
	}
	
	fSelfHelpTime[client] += 0.1;
	return Plugin_Continue;
}

public Action SelfReviveDelay(Handle timer, Handle dpSHReviveDelay)
{
	ResetPack(dpSHReviveDelay);
	
	int client = GetClientOfUserId(ReadPackCell(dpSHReviveDelay));
	if (!IsSurvivor(client) || !IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}
	
	if (!bIsL4D)
	{
		SDKCall(hSHOnRevived, client);
	}
	else
	{
		//iSHCount[client] -= 1;
		
		Event eReviveSuccess = CreateEvent("revive_success");
		eReviveSuccess.SetInt("userid", GetClientUserId(client));
		eReviveSuccess.SetInt("subject", GetClientUserId(client));
		eReviveSuccess.SetBool("ledge_hang", (!GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1)) ? false : true);
		eReviveSuccess.SetBool("lastlife", (iSHCount[client] + 1 >= iMaxCount) ? true : false);
		eReviveSuccess.Fire();
		
		bool bLastAidCheck = view_as<bool>(ReadPackCell(dpSHReviveDelay));
		DoSelfHelp(client, bLastAidCheck);
	}
	return Plugin_Stop;
}

public Action SHReviveOtherCompletion(Handle timer, Handle dpSHReviveOther)
{
	ResetPack(dpSHReviveOther);
	
	int reviver = GetClientOfUserId(ReadPackCell(dpSHReviveOther));
	if (!IsSurvivor(reviver) || !IsPlayerAlive(reviver) || !(GetClientButtons(reviver) & IN_RELOAD))
	{
		RemoveSHProgressBar(reviver, true);
		
		fSelfHelpTime[reviver] = 0.0;
		return Plugin_Stop;
	}
	
	int revived = GetClientOfUserId(ReadPackCell(dpSHReviveOther));
	if (!IsSurvivor(revived) || !IsPlayerAlive(revived) || !GetEntProp(revived, Prop_Send, "m_isIncapacitated", 1) || iAttacker[revived] != 0)
	{
		RemoveSHProgressBar(reviver, true);
		RemoveSHProgressBar(revived);
		
		fSelfHelpTime[reviver] = 0.0;
		return Plugin_Stop;
	}
	
	if (hSHTime[reviver] == null || shsBit[reviver] == SHS_NONE || (GetEntProp(revived, Prop_Send, "m_reviveOwner") > 0 && GetEntProp(revived, Prop_Send, "m_reviveOwner") != reviver))
	{
		RemoveSHProgressBar(reviver, true);
		RemoveSHProgressBar(revived, _, true);
		
		fSelfHelpTime[reviver] = 0.0;
		return Plugin_Stop;
	}
	
	if (fSelfHelpTime[reviver] >= float(iReviveDuration) + 0.1)
	{
		RemoveSHProgressBar(reviver, true);
		RemoveSHProgressBar(revived);
		
		bool bTempCheck;
		SHStatsFixer(revived, (!GetEntProp(revived, Prop_Send, "m_isHangingFromLedge", 1)) ? false : true, false, bTempCheck);
		
		Event eReviveSuccess = CreateEvent("revive_success");
		eReviveSuccess.SetInt("userid", GetClientUserId(reviver));
		eReviveSuccess.SetInt("subject", GetClientUserId(revived));
		eReviveSuccess.SetBool("ledge_hang", (GetEntProp(revived, Prop_Send, "m_isHangingFromLedge", 1)) ? true : false);
		if (bIsL4D)
		{
			eReviveSuccess.SetBool("lastlife", (iSHCount[revived] + 1 >= iMaxCount) ? true : false);
		}
		else
		{
			eReviveSuccess.SetBool("lastlife", (GetEntProp(revived, Prop_Send, "m_currentReviveCount") == iMaxIncapCount) ? true : false);
		}
		eReviveSuccess.Fire();
		
		DoSelfHelp(revived);
		
		for (int i = 0; i < 5; i++)
		{
			UnloopAnnoyingMusic(revived, sGameSounds[i]);
		}
		
		fSelfHelpTime[reviver] = 0.0;
		return Plugin_Stop;
	}
	
	fSelfHelpTime[reviver] += 0.1;
	return Plugin_Continue;
}

public void OnReplaceEvents(Event event, const char[] name, bool dontBroadcast)
{
	if (!bEnabled)
	{
		return;
	}
	
	int player = GetClientOfUserId(event.GetInt("player"));
	if (player > 0 && IsClientInGame(player) && !IsFakeClient(player))
	{
		int	bot = GetClientOfUserId(event.GetInt("bot"));
		
		if (StrEqual(name, "player_bot_replace"))
		{
			if (bIsL4D)
			{
				iSHCount[bot] = iSHCount[player];
				iSHCount[player] = 0;
			}
			
			iAttacker[bot] = iAttacker[player];
			iAttacker[player] = 0;
			
			for (int i = 0; i < 6; i++)
			{
				UnloopAnnoyingMusic(player, sGameSounds[i]);
			}
		}
		else
		{
			if (GetClientTeam(player) != 2)
			{
				return;
			}
			
			if (bIsL4D)
			{
				iSHCount[player] = iSHCount[bot];
				iSHCount[bot] = 0;
			}
			
			iAttacker[player] = iAttacker[bot];
			iAttacker[bot] = 0;
			
			CreateTimer(fDelay, FireUpMechanism, GetClientUserId(player));
		}
	}
}

public void OnReviveBegin(Event event, const char[] name, bool dontBroadcast)
{
	if (!bEnabled)
	{
		return;
	}
	
	int revived = GetClientOfUserId(event.GetInt("subject"));
	if (IsSurvivor(revived))
	{
		if (hSHTime[revived] == null)
		{
			return;
		}
		
		hSHTime[revived] = null;
	}
}

public void OnReviveEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!bEnabled)
	{
		return;
	}
	
	int revived = GetClientOfUserId(event.GetInt("subject"));
	if (IsSurvivor(revived))
	{
		if (!IsPlayerAlive(revived) || !GetEntProp(revived, Prop_Send, "m_isIncapacitated", 1))
		{
			return;
		}
		
		CreateTimer(fDelay, FireUpMechanism, GetClientUserId(revived));
	}
}

public void OnReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	if (!bEnabled)
	{
		return;
	}
	
	int reviver = GetClientOfUserId(event.GetInt("userid")),
		revived = GetClientOfUserId(event.GetInt("subject"));
	
	if (IsSurvivor(reviver) && IsSurvivor(revived))
	{
		if (bBot && IsFakeClient(revived) && iBotHelp[revived] == 1)
		{
			iBotHelp[revived] = 0;
		}
		
		if (event.GetBool("ledge_hang"))
		{
			if (reviver != revived)
			{
				if (!IsFakeClient(reviver))
				{
					CPrintToChat(reviver, "{default}You Helped{olive} %N{default}!", revived);
				}
				
				if (!IsFakeClient(revived))
				{
					CPrintToChat(revived, "{olive}%N{default} Helped You!", reviver);
				}
			}
			else
			{
				if (!IsFakeClient(revived))
				{
					CPrintToChat(revived, "{default}You Helped Yourself!");
				}
			}
		}
		else
		{
			if (!bIsL4D)
			{
				int iReviveCount = GetEntProp(revived, Prop_Send, "m_currentReviveCount");
				if (iReviveCount > iMaxIncapCount)
				{
					iReviveCount = iMaxIncapCount;
				}
				
				if (reviver == revived)
				{
					if (!IsFakeClient(revived))
					{
						CPrintToChat(revived, "{default}You Helped Yourself!");
					}
				}
				else
				{
					if (!IsFakeClient(reviver))
					{
						if (GetEntProp(reviver, Prop_Send, "m_isIncapacitated", 1))
						{
							CPrintToChatAll("{olive}%N{default} Saved{olive} %N {default}While Incapacitated!", reviver, revived);
						}
						
						CPrintToChat(reviver, "{default}You Helped{olive} %N{default}!", revived);
					}
					
					if (!IsFakeClient(revived))
					{
						CPrintToChat(revived, "{olive}%N{default} Helped You! ", reviver);
					}
				}
			}
			else
			{
				if (iSHCount[revived] >= iMaxCount - 1)
				{
					iSHCount[revived] = iMaxCount;
					
					SetEntProp(revived, Prop_Send, "m_currentReviveCount", 2);
					SetEntProp(revived, Prop_Send, "m_isGoingToDie", 1, 1);
				}
				else
				{
					iSHCount[revived] += 1;
					if (iSHCount[revived] != 0)
					{
						SetEntProp(revived, Prop_Send, "m_currentReviveCount", 1);
						SetEntProp(revived, Prop_Send, "m_isGoingToDie", 0, 1);
					}
				}
				
				if (reviver == revived)
				{
					if (!IsFakeClient(revived))
					{
						CPrintToChat(revived, "{default}You Helped Yourself! ");
					}
				}
				else
				{
					if (!IsFakeClient(reviver))
					{
						if (GetEntProp(reviver, Prop_Send, "m_isIncapacitated", 1))
						{
						//	CPrintToChatAll("{blue}[SH] {olive}%N{default} Saved{olive} %N {default}While Incapacitated!", reviver, revived);
						}
						
						CPrintToChat(reviver, "You Helped %N!", revived);
					}
					
					if (!IsFakeClient(revived))
					{
						CPrintToChat(revived, "%N Helped You!", reviver);
					}
				}
			}
		}
		
		if (hSHTime[revived] == null)
		{
			return;
		}
		
		hSHTime[revived] = null;
	}
}

public void OnHealSuccess(Event event, const char[] name, bool dontBroadcast)
{
	if (!bEnabled)
	{
		return;
	}
	
	int healer = GetClientOfUserId(event.GetInt("userid")),
		healed = GetClientOfUserId(event.GetInt("subject"));
	
	if (IsSurvivor(healer))
	{
		if (!IsSurvivor(healed))
		{
			return;
		}
		
		UnloopAnnoyingMusic(healed, sGameSounds[5]);
		//PrintHintTextToAll("[SH]\n%N Has Been Fully Healed By %N!", healed, healer);
		
		if (bIsL4D && iSHCount[healed] != 0)
		{
			iSHCount[healed] = 0;
		}
	}
}

public void OnInfectedGrab(Event event, const char[] name, bool dontBroadcast)
{
	if (!bEnabled)
	{
		return;
	}
	
	int grabber = GetClientOfUserId(event.GetInt("userid")),
		grabbed = GetClientOfUserId(event.GetInt("victim"));
	
	if (grabber && IsSurvivor(grabbed))
	{
		iAttacker[grabbed] = grabber;
		if (iKillAttacker != 2) {
			CreateTimer(fDelay, FireUpMechanism, GetClientUserId(grabbed));
		}
	}
}

public void OnInfectedRelease(Event event, const char[] name, bool dontBroadcast)
{
	if (!bEnabled)
	{
		return;
	}
	
	int released = GetClientOfUserId(event.GetInt("victim"));
	if (IsSurvivor(released))
	{
		if (bBot && IsFakeClient(released) && iBotHelp[released] == 1)
		{
			iBotHelp[released] = 0;
		}
		
		if (StrEqual(name, "pounce_stopped"))
		{
			iAttacker[released] = 0;
		}
		else
		{
			int releaser = GetClientOfUserId(event.GetInt("userid"));
			if (!releaser || iAttacker[released] != releaser)
			{
				return;
			}
			
			iAttacker[released] = 0;
		}
	}
}

public void OnDefibrillatorUsed(Event event, const char[] name, bool dontBroadcast)
{
	if (!bEnabled)
	{
		return;
	}
	
	int defibber = GetClientOfUserId(event.GetInt("userid")),
		defibbed = GetClientOfUserId(event.GetInt("subject"));
	
	if (IsSurvivor(defibber))
	{
		if (!IsSurvivor(defibbed))
		{
			return;
		}
		
		DataPack dpDefibAnnounce = new DataPack();
		dpDefibAnnounce.WriteCell(GetClientUserId(defibber));
		dpDefibAnnounce.WriteCell(GetClientUserId(defibbed));
		CreateTimer(0.1, DelaySHNotify, dpDefibAnnounce, TIMER_DATA_HNDL_CLOSE);
	}
}

public Action DelaySHNotify(Handle timer, Handle dpDefibAnnounce)
{
	ResetPack(dpDefibAnnounce);
	
	int defibber = GetClientOfUserId(ReadPackCell(dpDefibAnnounce)),
		defibbed = GetClientOfUserId(ReadPackCell(dpDefibAnnounce));
	
	if (!IsSurvivor(defibber) || !IsSurvivor(defibbed))
	{
		return Plugin_Stop;
	}
	
	int iReviveCount = GetEntProp(defibbed, Prop_Send, "m_currentReviveCount");
	
	if (defibber == defibbed)
	{
		if (!IsFakeClient(defibbed))
		{
			//PrintToChat(defibbed, "{default}You Defibbed Yourself! |{green}%d{default}/{green}%i{default}|", iReviveCount, iMaxIncapCount);
		}
	}
	else
	{
		if (!IsFakeClient(defibber))
		{
			CPrintToChat(defibber, "{default}You Defibbed{olive} %N{default}! |{green}%d{default}/{green}%i{default}|", defibbed, iReviveCount, iMaxIncapCount);
		}
		
		if (!IsFakeClient(defibbed))
		{
			CPrintToChat(defibbed, "{olive}%N{default} Defibbed You! |{green}%d{default}/{green}%i{default}|", defibber, iReviveCount, iMaxIncapCount);
		}
	}
	
	return Plugin_Stop;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (!bEnabled || !bBot)
	{
		return Plugin_Continue;
	}
	
	if (IsSurvivor(client))
	{
		if (!IsPlayerAlive(client) || !IsFakeClient(client) || iBotHelp[client] == 0)
		{
			return Plugin_Continue;
		}
		
		if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
		{
			int iTarget = 0;
			float fPlayerPos[2][3];
			
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPlayerPos[0]);
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i) || i == client || iAttacker[i] != 0)
				{
					continue;
				}
				
				if (GetEntProp(i, Prop_Send, "m_isIncapacitated", 1) && GetEntProp(i, Prop_Send, "m_reviveOwner") < 1)
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", fPlayerPos[1]);
					
					if (GetVectorDistance(fPlayerPos[0], fPlayerPos[1]) > 100.0)
					{
						continue;
					}
					
					iTarget = i;
					break;
				}
			}
			if (IsSurvivor(iTarget) && IsPlayerAlive(iTarget) && GetEntProp(iTarget, Prop_Send, "m_isIncapacitated", 1) && GetEntProp(iTarget, Prop_Send, "m_reviveOwner") < 1)
			{
				buttons |= IN_RELOAD;
			}
			else
			{
				if (buttons & IN_RELOAD)
				{
					buttons ^= IN_RELOAD;
				}
				
				if (IsSelfHelpAble(client))
				{
					buttons |= IN_DUCK;
				}
			}
		}
		else if (iAttacker[client] != 0)
		{
			if (!IsSelfHelpAble(client))
			{
				return Plugin_Continue;
			}
			
			buttons |= IN_DUCK;
		}
	}
	
	return Plugin_Continue;
}

bool IsSelfHelpAble(int client)
{
	bool bHasPA = CheckPlayerSupply(client, 4), bHasMedkit = CheckPlayerSupply(client, 3);
	
	if ((iUse == 1 || iUse == 3) && bHasPA)
	{
		return true;
	}
	else if ((iUse == 2 || iUse == 3) && bHasMedkit)
	{
		return true;
	}
	
	return false;
}

bool CheckPlayerSupply(int client, int iSlot, int &iItem = 0, char sItemName[64] = "")
{
	if (!IsSurvivor(client) || !IsPlayerAlive(client))
	{
		return false;
	}
	
	int iSupply = GetPlayerWeaponSlot(client, iSlot);
	if (IsValidEnt(iSupply))
	{
		char sSupplyClass[64];
		GetEdictClassname(iSupply, sSupplyClass, sizeof(sSupplyClass));
		
		if (iSlot == 3 && StrEqual(sSupplyClass, "weapon_first_aid_kit", false))
		{
			iItem = iSupply;
			strcopy(sItemName, sizeof(sItemName), sSupplyClass);
			
			return true;
		}
		else if (iSlot == 4 && (StrEqual(sSupplyClass, "weapon_pain_pills", false) || (!bIsL4D && StrEqual(sSupplyClass, "weapon_adrenaline", false))))
		{
			iItem = iSupply;
			strcopy(sItemName, sizeof(sItemName), sSupplyClass);
			
			return true;
		}
	}
	
	return false;
}

void DisplaySHProgressBar(int client, int other = 0, int iDuration, char[] sMsg, bool bReverse = false)
{
	if (bReverse)
	{
		SetEntProp(client, Prop_Send, "m_reviveTarget", other);
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_reviveOwner", other);
	}
	
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	if (bIsL4D)
	{
		SetEntProp(client, Prop_Send, "m_iProgressBarDuration", iDuration);
		
		SetEntPropString(client, Prop_Send, "m_progressBarText", sMsg);
	}
	else
	{
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", float(iDuration));
	}
}

void RemoveSHProgressBar(int client, bool bReverse = false, bool bExclude = false)
{
	if (!IsValidClient(client) || IsFakeClient(client))
	{
		return;
	}
	
	if (bReverse)
	{
		SetEntProp(client, Prop_Send, "m_reviveTarget", -1);
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_reviveOwner", -1);
	}
	
	if (!bExclude)
	{
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
		if (!bIsL4D)
		{
			SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0);
			
			SetEntPropString(client, Prop_Send, "m_progressBarText", "");
		}
	}
}

void SHStatsFixer(int client, bool bDoNotTamper, bool bUseItem = true, bool &bMedkitUsed)
{
	if (shsBit[client] == SHS_START_SELF)
	{
		shsBit[client] = SHS_END;
	}
	else if (shsBit[client] == SHS_START_OTHER)
	{
		shsBit[client] = SHS_CONTINUE;
	}
	
	if (bUseItem)
	{
		int iUsedItem;
		bool bEmergencyUsed, bFirstAidUsed, bSmartHeal;
		char sUsedItemName[64];
		
		if (iUse == 3)
		{
			if (!bIsL4D)
			{
				if (GetEntProp(client, Prop_Send, "m_currentReviveCount") < iMaxIncapCount)
				{
					if (CheckPlayerSupply(client, 4, iUsedItem, sUsedItemName))
					{
						bEmergencyUsed = true;
						bFirstAidUsed = false;
						bSmartHeal = false;
					}
					else if (CheckPlayerSupply(client, 3, iUsedItem))
					{
						bFirstAidUsed = true;
						bEmergencyUsed = false;
						bSmartHeal = true;
					}
				}
				else
				{
					if (CheckPlayerSupply(client, 3, iUsedItem))
					{
						bFirstAidUsed = true;
						bEmergencyUsed = false;
						bSmartHeal = true;
				}
					else if (CheckPlayerSupply(client, 4, iUsedItem, sUsedItemName))
					{
						bEmergencyUsed = true;
						bFirstAidUsed = false;
						bSmartHeal = false;

					}
				}
			}
			else
			{
				if (iSHCount[client] >= iMaxCount)
				{
					if (CheckPlayerSupply(client, 3, iUsedItem))
					{
						bFirstAidUsed = true;
						bEmergencyUsed = false;
						bSmartHeal = true;
					}
					else if (CheckPlayerSupply(client, 4, iUsedItem, sUsedItemName))
					{
						bEmergencyUsed = true;
						bFirstAidUsed = false;
						bSmartHeal = false;
					}
				}
				else
				{
					if (CheckPlayerSupply(client, 4, iUsedItem, sUsedItemName))
					{
						bEmergencyUsed = true;
						bFirstAidUsed = false;
						bSmartHeal = false;
					}
					else if (CheckPlayerSupply(client, 3, iUsedItem))
					{
						bFirstAidUsed = true;
						bEmergencyUsed = false;
						bSmartHeal = true;
					}
				}
			}
		}
		else
		{
			if (iUse == 1)
			{
				CheckPlayerSupply(client, 4, iUsedItem, sUsedItemName);
				
				bEmergencyUsed = true;
				bFirstAidUsed = false;
			}
			else if (iUse == 2)
			{
				CheckPlayerSupply(client, 3, iUsedItem);
				
				bFirstAidUsed = true;
				bEmergencyUsed = false;
			}
			
			bSmartHeal = false;
		}
		
		if ((bEmergencyUsed || bFirstAidUsed) && RemovePlayerItem(client, iUsedItem))
		{

			AcceptEntityInput(iUsedItem, "Kill");
			RemoveEdict(iUsedItem);
			
			if (bFirstAidUsed)
			{
				CPrintToChatAll("{olive}%N {default}Helped Themselves With{green} Medkit{default}!", client);
				
				if (bSmartHeal)
				{	
					Event eHealSuccess = CreateEvent("heal_success");
					eHealSuccess.SetInt("userid", GetClientUserId(client));
					eHealSuccess.SetInt("subject", GetClientUserId(client));
					eHealSuccess.Fire();
					
					if (bIsL4D)
					{
						SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);
						
						if (GetEntProp(client, Prop_Send, "m_isGoingToDie", 1))
						{
							SetEntProp(client, Prop_Send, "m_isGoingToDie", 0, 1);
						}
					}
					else
					{
						SetEntProp(client, Prop_Send, "m_currentReviveCount", -1);
					}
				}
			}
			else if (bEmergencyUsed)
			{
				if (!bIsL4D && StrEqual(sUsedItemName, "weapon_adrenaline", false))
				{
					if (!GetEntProp(client, Prop_Send, "m_bAdrenalineActive", 1))
					{
						SetEntProp(client, Prop_Send, "m_bAdrenalineActive", 1, 1);
					}
					
					Event eAdrenalineUsed = CreateEvent("adrenaline_used", true);
					eAdrenalineUsed.SetInt("userid", GetClientUserId(client));
					eAdrenalineUsed.Fire();
					
					SDKCall(hSHAdrenalineRush, client, fAdrenalineDuration);
					CPrintToChatAll("{olive}%N {default}Helped Themselves With{green} Adrenaline{default}!", client);
				}
				else
				{
					Event ePillsUsed = CreateEvent("pills_used", true);
					ePillsUsed.SetInt("userid", GetClientUserId(client));
					ePillsUsed.SetInt("subject", GetClientUserId(client));
					ePillsUsed.Fire();
					
					CPrintToChatAll("{olive}%N {default}Helped Themselves With{green} Pills{default}!", client);
				}
			}
		}
		
		bMedkitUsed = bFirstAidUsed;
	}
	
	if (!bDoNotTamper && !bIsL4D)
	{
		int iReviveCount = GetEntProp(client, Prop_Send, "m_currentReviveCount");
		if (iReviveCount >= iMaxIncapCount - 1)
		{
			SetEntProp(client, Prop_Send, "m_currentReviveCount", iMaxIncapCount);
			SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1, 1);
			SetEntProp(client, Prop_Send, "m_isGoingToDie", 1, 1);
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_currentReviveCount", iReviveCount);
			SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0, 1);
			SetEntProp(client, Prop_Send, "m_isGoingToDie", 0, 1);
		}
	}
}

void DoSelfHelp(int client, bool bWasMedkitUsed = false)
{

	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
	{
		SetEntProp(client, Prop_Send, "m_isIncapacitated", 0, 1);
		if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1))
		{
			SetEntProp(client, Prop_Send, "m_isHangingFromLedge", 0, 1);
			SetEntProp(client, Prop_Send, "m_isFallingFromLedge", 0, 1);
		}
	}
	
	TeleportEntity(client, fLastPos[client], NULL_VECTOR, NULL_VECTOR);
	if (bWasMedkitUsed)
	{
		SetEntProp(client, Prop_Send, "m_iHealth", GetEntProp(client, Prop_Send, "m_iMaxHealth"));
		if (bIsL4D)
		{
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
			SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
		}
		else
		{
			SDKCall(hSHSetTempHP, client, 0.0);
		}
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_iHealth", iHardHP);
		if (!bIsL4D)
		{
			SDKCall(hSHSetTempHP, client, fTempHP);
		}
		else
		{
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fTempHP);
			SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
		}
	}
}

void UnloopAnnoyingMusic(int client, const char[] sGivenSound)
{
	StopSound(client, SNDCHAN_REPLACE, sGivenSound);
	StopSound(client, SNDCHAN_AUTO, sGivenSound);
	StopSound(client, SNDCHAN_WEAPON, sGivenSound);
	StopSound(client, SNDCHAN_VOICE, sGivenSound);
	StopSound(client, SNDCHAN_ITEM, sGivenSound);
	StopSound(client, SNDCHAN_BODY, sGivenSound);
	StopSound(client, SNDCHAN_STREAM, sGivenSound);
	StopSound(client, SNDCHAN_STATIC, sGivenSound);
	StopSound(client, SNDCHAN_VOICE_BASE, sGivenSound);
	StopSound(client, SNDCHAN_USER_BASE, sGivenSound);
}

void RemoveHindrance(int client)
{
	int dominator = iAttacker[client];
	iAttacker[client] = 0;
	
	if (dominator != 0 && IsClientInGame(dominator) && GetClientTeam(dominator) == 3 && IsPlayerAlive(dominator) && iKillAttacker != 2)
	{
		switch (GetEntProp(dominator, Prop_Send, "m_zombieClass"))
		{
			case 1:
			{
				Event eTonguePullStopped = CreateEvent("tongue_pull_stopped", true);
				eTonguePullStopped.SetInt("userid", GetClientUserId(client));
				eTonguePullStopped.SetInt("victim", GetClientUserId(client));
				eTonguePullStopped.Fire();
			}
			case 3:
			{
				Event ePounceStopped = CreateEvent("pounce_stopped");
				ePounceStopped.SetInt("userid", GetClientUserId(client));
				ePounceStopped.SetInt("victim", GetClientUserId(client));
				ePounceStopped.Fire();
			}
			case 5:
			{
				if (!bIsL4D)
				{
					Event eJockeyRideEnd = CreateEvent("jockey_ride_end");
					eJockeyRideEnd.SetInt("userid", GetClientUserId(dominator));
					eJockeyRideEnd.SetInt("victim", GetClientUserId(client));
					eJockeyRideEnd.SetInt("rescuer", GetClientUserId(client));
					eJockeyRideEnd.Fire();
				}
			}
			case 6:
			{
				if (!bIsL4D)
				{
					Event eChargerPummelEnd = CreateEvent("charger_pummel_end");
					eChargerPummelEnd.SetInt("userid", GetClientUserId(dominator));
					eChargerPummelEnd.SetInt("victim", GetClientUserId(client));
					eChargerPummelEnd.SetInt("rescuer", GetClientUserId(client));
					eChargerPummelEnd.Fire();
				}
			}
		}
		
		if (iKillAttacker == 0)
		{
			float fStaggerPos[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", fStaggerPos);
			SDKCall(hSHStagger, dominator, client, fStaggerPos);

		} 
		else
		{
			ForcePlayerSuicide(dominator);
			Event ePlayerDeath = CreateEvent("player_death");
			ePlayerDeath.SetInt("userid", GetClientUserId(dominator));
			ePlayerDeath.SetInt("attacker", GetClientUserId(client));
			ePlayerDeath.Fire();

		}
		
		if (bIsL4D)
		{
			EmitSoundToAll("weapons/knife/knife_hitwall1.wav", client, SNDCHAN_WEAPON);
		}
		else
		{
			int iRandSound = GetRandomInt(1, 2);
			switch (iRandSound)
			{
				case 1: EmitSoundToAll("weapons/knife/knife_deploy.wav", client, SNDCHAN_WEAPON);
				case 2: EmitSoundToAll("weapons/knife/knife_hitwall1.wav", client, SNDCHAN_WEAPON);
			}
		}
	}
}

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

stock bool IsSurvivor(int client)
{
	return (IsValidClient(client) && GetClientTeam(client) == 2);
}

stock bool IsValidEnt(int entity)
{
	return (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity));
}

stock void ExecuteCommand(int client, const char[] sCommand, const char[] sArgument)
{
	int iFlags = GetCommandFlags(sCommand);
	SetCommandFlags(sCommand, iFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", sCommand, sArgument);
	SetCommandFlags(sCommand, iFlags);
}


/**************************************************************************
 *                                                                        *
 *                       Colored Chat Functions                           *
 *                   Author: exvel, Editor: Popoklopsi, Powerlord, Bara   *
 *                           Version: 2.0.0-MC                            *
 *                                                                        *
 **************************************************************************/
 

#if defined _colors_included
 #endinput
#endif
#define _colors_included
 
#define MAX_MESSAGE_LENGTH 256
#define MAX_COLORS 18

#define SERVER_INDEX 0
#define NO_INDEX -1
#define NO_PLAYER -2

enum C_Colors
{
 	Color_Default = 0,
	Color_Darkred,
	Color_Green,
	Color_Lightgreen,
	Color_Red,
	Color_Blue,
	Color_Olive,
	Color_Lime,
	Color_Lightred,
	Color_Purple,
	Color_Grey,
	Color_Yellow,
	Color_Orange,
	Color_Bluegrey,
	Color_Lightblue,
	Color_Darkblue,
	Color_Grey2,
	Color_Orchid,
	Color_Lightred2
}

/* C_Colors' properties */
char C_Tag[][] = {"{default}", "{darkred}", "{green}", "{lightgreen}", "{red}", "{blue}", "{olive}", "{lime}", "{lightred}", "{purple}", "{grey}", "{yellow}", "{orange}", "{bluegrey}", "{lightblue}", "{darkblue}", "{grey2}", "{orchid}", "{lightred2}"};
char C_TagCode[][] = {"\x01", "\x02", "\x04", "\x03", "\x03", "\x03", "\x05", "\x06", "\x07", "\x03", "\x08", "\x09", "\x10", "\x0A", "\x0B", "\x0C", "\x0D", "\x0E", "\x0F"};
bool C_TagReqSayText2[] = {false, false, false, true, true, true, false, false, false, false, false, false, false, false, false, false, false, false, false};
bool C_EventIsHooked = false;
bool C_SkipList[MAXPLAYERS+1] = {false,...};

/* Game default profile */
bool C_Profile_Colors[] = {true, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false};
int C_Profile_TeamIndex[] = {NO_INDEX, NO_INDEX, NO_INDEX, NO_INDEX, NO_INDEX, NO_INDEX, NO_INDEX, NO_INDEX, NO_INDEX, NO_INDEX, NO_INDEX, NO_INDEX, NO_INDEX, NO_INDEX, NO_INDEX, NO_INDEX, NO_INDEX, NO_INDEX, NO_INDEX};
bool C_Profile_SayText2 = false;

static ConVar sm_show_activity = null;

/**
 * Prints a message to a specific client in the chat area.
 * Supports color tags.
 *
 * @param client	  Client index.
 * @param szMessage   Message (formatting rules).
 * @return			  No return
 * 
 * On error/Errors:   If the client is not connected an error will be thrown.
 */
stock void CPrintToChat(int client, const char[] szMessage, any ...)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client))
		ThrowError("Invalid client index %d", client);
	
	char szBuffer[MAX_MESSAGE_LENGTH];
	char szCMessage[MAX_MESSAGE_LENGTH];
	
	SetGlobalTransTarget(client);
	
	Format(szBuffer, sizeof(szBuffer), "\x01%s", szMessage);
	VFormat(szCMessage, sizeof(szCMessage), szBuffer, 3);
	
	int index = C_Format(szCMessage, sizeof(szCMessage));
	if (index == NO_INDEX)
		PrintToChat(client, "%s", szCMessage);
	else
		C_SayText2(client, index, szCMessage);
}

/**
 * Reples to a message in a command. A client index of 0 will use PrintToServer().
 * If the command was from the console, PrintToConsole() is used. If the command was from chat, C_PrintToChat() is used.
 * Supports color tags.
 *
 * @param client	  Client index, or 0 for server.
 * @param szMessage   Formatting rules.
 * @param ...         Variable number of format parameters.
 * @return			  No return
 * 
 * On error/Errors:   If the client is not connected or invalid.
 */
stock void C_ReplyToCommand(int client, const char[] szMessage, any ...)
{
	char szCMessage[MAX_MESSAGE_LENGTH];
	SetGlobalTransTarget(client);
	VFormat(szCMessage, sizeof(szCMessage), szMessage, 3);
	
	if (client == 0)
	{
		C_RemoveTags(szCMessage, sizeof(szCMessage));
		PrintToServer("%s", szCMessage);
	}
	else if (GetCmdReplySource() == SM_REPLY_TO_CONSOLE)
	{
		C_RemoveTags(szCMessage, sizeof(szCMessage));
		PrintToConsole(client, "%s", szCMessage);
	}
	else
	{
		CPrintToChat(client, "%s", szCMessage);
	}
}

/**
 * Reples to a message in a command. A client index of 0 will use PrintToServer().
 * If the command was from the console, PrintToConsole() is used. If the command was from chat, C_PrintToChat() is used.
 * Supports color tags.
 *
 * @param client	  Client index, or 0 for server.
 * @param author      Author index whose color will be used for teamcolor tag.
 * @param szMessage   Formatting rules.
 * @param ...         Variable number of format parameters.
 * @return			  No return
 * 
 * On error/Errors:   If the client is not connected or invalid.
 */
stock void C_ReplyToCommandEx(int client, int author, const char[] szMessage, any ...)
{
	char szCMessage[MAX_MESSAGE_LENGTH];
	SetGlobalTransTarget(client);
	VFormat(szCMessage, sizeof(szCMessage), szMessage, 4);
	
	if (client == 0)
	{
		C_RemoveTags(szCMessage, sizeof(szCMessage));
		PrintToServer("%s", szCMessage);
	}
	else if (GetCmdReplySource() == SM_REPLY_TO_CONSOLE)
	{
		C_RemoveTags(szCMessage, sizeof(szCMessage));
		PrintToConsole(client, "%s", szCMessage);
	}
	else
	{
		C_PrintToChatEx(client, author, "%s", szCMessage);
	}
}

/**
 * Prints a message to all clients in the chat area.
 * Supports color tags.
 *
 * @param client	  Client index.
 * @param szMessage   Message (formatting rules)
 * @return			  No return
 */
stock void CPrintToChatAll(const char[] szMessage, any ...)
{
	char szBuffer[MAX_MESSAGE_LENGTH];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || C_SkipList[i])
		{
			C_SkipList[i] = false;
			continue;
		}
		
		SetGlobalTransTarget(i);
		VFormat(szBuffer, sizeof(szBuffer), szMessage, 2);
		
		CPrintToChat(i, "%s", szBuffer);
	}
}

/**
 * Prints a message to a specific client in the chat area.
 * Supports color tags and teamcolor tag.
 *
 * @param client	  Client index.
 * @param author	  Author index whose color will be used for teamcolor tag.
 * @param szMessage   Message (formatting rules).
 * @return			  No return
 * 
 * On error/Errors:   If the client or author are not connected an error will be thrown.
 */
stock void C_PrintToChatEx(int client, int author, const char[] szMessage, any ...)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client))
		ThrowError("Invalid client index %d", client);
	
	if (author < 0 || author > MaxClients)
		ThrowError("Invalid client index %d", author);
	
	char szBuffer[MAX_MESSAGE_LENGTH];
	char szCMessage[MAX_MESSAGE_LENGTH];
	
	SetGlobalTransTarget(client);
	
	Format(szBuffer, sizeof(szBuffer), "\x01%s", szMessage);
	VFormat(szCMessage, sizeof(szCMessage), szBuffer, 4);
	
	int index = C_Format(szCMessage, sizeof(szCMessage), author);
	if (index == NO_INDEX)
		PrintToChat(client, "%s", szCMessage);
	else
		C_SayText2(client, author, szCMessage);
}

/**
 * Prints a message to all clients in the chat area.
 * Supports color tags and teamcolor tag.
 *
 * @param author	  Author index whos color will be used for teamcolor tag.
 * @param szMessage   Message (formatting rules).
 * @return			  No return
 * 
 * On error/Errors:   If the author is not connected an error will be thrown.
 */
stock void C_PrintToChatAllEx(int author, const char[] szMessage, any ...)
{
	if (author < 0 || author > MaxClients || !IsClientInGame(author))
		ThrowError("Invalid client index %d", author);
	
	char szBuffer[MAX_MESSAGE_LENGTH];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || C_SkipList[i])
		{
			C_SkipList[i] = false;
			continue;
		}
		
		SetGlobalTransTarget(i);
		VFormat(szBuffer, sizeof(szBuffer), szMessage, 3);
		
		C_PrintToChatEx(i, author, "%s", szBuffer);
	}
}

/**
 * Removes color tags from the string.
 *
 * @param szMessage   String.
 * @return			  No return
 */
stock void C_RemoveTags(char[] szMessage, int maxlength)
{
	for (int i = 0; i < MAX_COLORS; i++)
	{
		ReplaceString(szMessage, maxlength, C_Tag[i], "", false);
	}
	
	ReplaceString(szMessage, maxlength, "{teamcolor}", "", false);
}

/**
 * Checks whether a color is allowed or not
 *
 * @param tag   		Color Tag.
 * @return			 	True when color is supported, otherwise false
 */
stock bool C_ColorAllowed(C_Colors color)
{
	if (!C_EventIsHooked)
	{
		C_SetupProfile();
		C_EventIsHooked = true;
	}
	
	return C_Profile_Colors[color];
}

/**
 * Replace the color with another color
 * Handle with care!
 *
 * @param color   			color to replace.
 * @param newColor   		color to replace with.
 * @noreturn
 */
stock void C_ReplaceColor(C_Colors color, C_Colors newColor)
{
	if (!C_EventIsHooked)
	{
		C_SetupProfile();
		C_EventIsHooked = true;
	}
	
	C_Profile_Colors[color] = C_Profile_Colors[newColor];
	C_Profile_TeamIndex[color] = C_Profile_TeamIndex[newColor];
	
	C_TagReqSayText2[color] = C_TagReqSayText2[newColor];
	Format(C_TagCode[color], sizeof(C_TagCode[]), C_TagCode[newColor]);
}

/**
 * This function should only be used right in front of
 * C_PrintToChatAll or C_PrintToChatAllEx and it tells
 * to those funcions to skip specified client when printing
 * message to all clients. After message is printed client will
 * no more be skipped.
 * 
 * @param client   Client index
 * @return		   No return
 */
stock void C_SkipNextClient(int client)
{
	if (client < 1 || client > MaxClients)
		ThrowError("Invalid client index %d", client);
	
	C_SkipList[client] = true;
}

/**
 * Replaces color tags in a string with color codes
 *
 * @param szMessage   String.
 * @param maxlength   Maximum length of the string buffer.
 * @return			  Client index that can be used for SayText2 author index
 * 
 * On error/Errors:   If there is more then one team color is used an error will be thrown.
 */
stock int C_Format(char[] szMessage, int maxlength, int author = NO_INDEX)
{
	if (!C_EventIsHooked)
	{
		C_SetupProfile();
		HookEvent("server_spawn", C_Event_MapStart, EventHookMode_PostNoCopy);
		
		C_EventIsHooked = true;
	}
	
	int iRandomPlayer = NO_INDEX;
	
	if (GetEngineVersion() == Engine_CSGO)
	{
		Format(szMessage, maxlength, " %s", szMessage);
	}
	
	if (author != NO_INDEX)
	{
		if (C_Profile_SayText2)
		{
			ReplaceString(szMessage, maxlength, "{teamcolor}", "\x03", false);
			iRandomPlayer = author;
		}
		else
		{
			ReplaceString(szMessage, maxlength, "{teamcolor}", C_TagCode[Color_Green], false);
		}
	}
	else
	{
		ReplaceString(szMessage, maxlength, "{teamcolor}", "", false);
	}

	/* For other color tags we need a loop */
	for (int i = 0; i < MAX_COLORS; i++)
	{
		if (StrContains(szMessage, C_Tag[i], false) == -1)
		{
			continue;
		}
		
		if (!C_Profile_Colors[i])
		{
			ReplaceString(szMessage, maxlength, C_Tag[i], C_TagCode[Color_Green], false);
		}
		else if (!C_TagReqSayText2[i])
		{
			ReplaceString(szMessage, maxlength, C_Tag[i], C_TagCode[i], false);
		}
		else
		{
			if (!C_Profile_SayText2)
			{
				ReplaceString(szMessage, maxlength, C_Tag[i], C_TagCode[Color_Green], false);
			}
			else 
			{
				if (iRandomPlayer == NO_INDEX)
				{
					iRandomPlayer = C_FindRandomPlayerByTeam(C_Profile_TeamIndex[i]);
					if (iRandomPlayer == NO_PLAYER)
					{
						ReplaceString(szMessage, maxlength, C_Tag[i], C_TagCode[Color_Green], false);
					}
					else
					{
						ReplaceString(szMessage, maxlength, C_Tag[i], C_TagCode[i], false);
					}

				}
				else
				{
					if (C_Profile_TeamIndex[i] != GetClientTeam(iRandomPlayer))
						ThrowError("Using two team colors in one message is not allowed");
					
					ReplaceString(szMessage, maxlength, C_Tag[i], C_TagCode[i], false);
				}
			}

		}
	}

	return iRandomPlayer;
}

/**
 * Finds a random player with specified team
 *
 * @param color_team  Client team.
 * @return			  Client index or NO_PLAYER if no player found
 */
stock int C_FindRandomPlayerByTeam(int color_team)
{
	if (color_team == SERVER_INDEX)
	{
		return 0;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != color_team)
		{
			continue;
		}
		
		return i;
	}
	
	return NO_PLAYER;
}

/**
 * Sends a SayText2 usermessage to a client
 *
 * @param szMessage   Client index
 * @param maxlength   Author index
 * @param szMessage   Message
 * @return			  No return.
 */
stock void C_SayText2(int client, int author, const char[] szMessage)
{
	Handle hBuffer = StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	
	if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf) 
	{
		PbSetInt(hBuffer, "ent_idx", author);
		PbSetBool(hBuffer, "chat", true);
		PbSetString(hBuffer, "msg_name", szMessage);
		PbAddString(hBuffer, "params", "");
		PbAddString(hBuffer, "params", "");
		PbAddString(hBuffer, "params", "");
		PbAddString(hBuffer, "params", "");
	}
	else
	{
		BfWriteByte(hBuffer, author);
		BfWriteByte(hBuffer, true);
		BfWriteString(hBuffer, szMessage);
	}

	EndMessage();
}

/**
 * Creates game color profile 
 * This function must be edited if you want to add more games support
 *
 * @return			  No return.
 */
stock void C_SetupProfile()
{
	EngineVersion engine = GetEngineVersion();

	if (engine == Engine_CSS)
	{
		C_Profile_Colors[Color_Lightgreen] = true;
		C_Profile_Colors[Color_Red] = true;
		C_Profile_Colors[Color_Blue] = true;
		C_Profile_Colors[Color_Olive] = true;
		C_Profile_TeamIndex[Color_Lightgreen] = SERVER_INDEX;
		C_Profile_TeamIndex[Color_Red] = 2;
		C_Profile_TeamIndex[Color_Blue] = 3;
		C_Profile_SayText2 = true;
	}
	else if (engine == Engine_CSGO)
	{
		C_Profile_Colors[Color_Red] = true;
		C_Profile_Colors[Color_Blue] = true;
		C_Profile_Colors[Color_Olive] = true;
		C_Profile_Colors[Color_Darkred] = true;
		C_Profile_Colors[Color_Lime] = true;
		C_Profile_Colors[Color_Lightred] = true;
		C_Profile_Colors[Color_Purple] = true;
		C_Profile_Colors[Color_Grey] = true;
		C_Profile_Colors[Color_Yellow] = true;
		C_Profile_Colors[Color_Orange] = true;
		C_Profile_Colors[Color_Bluegrey] = true;
		C_Profile_Colors[Color_Lightblue] = true;
		C_Profile_Colors[Color_Darkblue] = true;
		C_Profile_Colors[Color_Grey2] = true;
		C_Profile_Colors[Color_Orchid] = true;
		C_Profile_Colors[Color_Lightred2] = true;
		C_Profile_TeamIndex[Color_Red] = 2;
		C_Profile_TeamIndex[Color_Blue] = 3;
		C_Profile_SayText2 = true;
	}
	else if (engine == Engine_TF2)
	{
		C_Profile_Colors[Color_Lightgreen] = true;
		C_Profile_Colors[Color_Red] = true;
		C_Profile_Colors[Color_Blue] = true;
		C_Profile_Colors[Color_Olive] = true;
		C_Profile_TeamIndex[Color_Lightgreen] = SERVER_INDEX;
		C_Profile_TeamIndex[Color_Red] = 2;
		C_Profile_TeamIndex[Color_Blue] = 3;
		C_Profile_SayText2 = true;
	}
	else if (engine == Engine_Left4Dead || engine == Engine_Left4Dead2)
	{
		C_Profile_Colors[Color_Lightgreen] = true;
		C_Profile_Colors[Color_Red] = true;
		C_Profile_Colors[Color_Blue] = true;
		C_Profile_Colors[Color_Olive] = true;
		C_Profile_TeamIndex[Color_Lightgreen] = SERVER_INDEX;
		C_Profile_TeamIndex[Color_Red] = 3;
		C_Profile_TeamIndex[Color_Blue] = 2;
		C_Profile_SayText2 = true;
	}
	else if (engine == Engine_HL2DM)
	{
		if (FindConVar("mp_teamplay").BoolValue)
		{
			C_Profile_Colors[Color_Red] = true;
			C_Profile_Colors[Color_Blue] = true;
			C_Profile_Colors[Color_Olive] = true;
			C_Profile_TeamIndex[Color_Red] = 3;
			C_Profile_TeamIndex[Color_Blue] = 2;
			C_Profile_SayText2 = true;
		}
		else
		{
			C_Profile_SayText2 = false;
			C_Profile_Colors[Color_Olive] = true;
		}
	}
	else if (engine == Engine_DODS)
	{
		C_Profile_Colors[Color_Olive] = true;
		C_Profile_SayText2 = false;
	}
	else
	{
		if (GetUserMessageId("SayText2") == INVALID_MESSAGE_ID)
		{
			C_Profile_SayText2 = false;
		}
		else
		{
			C_Profile_Colors[Color_Red] = true;
			C_Profile_Colors[Color_Blue] = true;
			C_Profile_TeamIndex[Color_Red] = 2;
			C_Profile_TeamIndex[Color_Blue] = 3;
			C_Profile_SayText2 = true;
		}
	}
}

public void C_Event_MapStart(Event event, const char[] name, bool dontBroadcast)
{
	C_SetupProfile();
	
	for (int i = 1; i <= MaxClients; i++)
	{
		C_SkipList[i] = false;
	}
}

/**
 * Displays usage of an admin command to users depending on the 
 * setting of the sm_show_activity cvar.  
 *
 * This version does not display a message to the originating client 
 * if used from chat triggers or menus.  If manual replies are used 
 * for these cases, then this function will suffice.  Otherwise, 
 * C_ShowActivity2() is slightly more useful.
 * Supports color tags.
 *
 * @param client		Client index doing the action, or 0 for server.
 * @param format		Formatting rules.
 * @param ...			Variable number of format parameters.
 * @noreturn
 * @error
 */
stock int C_ShowActivity(int client, const char[] format, any ...)
{
	if (sm_show_activity == null)
		sm_show_activity = FindConVar("sm_show_activity");
	
	char tag[] = "[SM] ";
	
	char szBuffer[MAX_MESSAGE_LENGTH];
	int  value = sm_show_activity.IntValue;
	ReplySource replyto = GetCmdReplySource();
	
	char name[MAX_NAME_LENGTH] = "Console";
	char sign[MAX_NAME_LENGTH] = "ADMIN";
	bool display_in_chat = false;
	
	if (client != 0)
	{
		if (client < 0 || client > MaxClients || !IsClientConnected(client))
			ThrowError("Client index %d is invalid", client);
		
		GetClientName(client, name, sizeof(name));
		
		AdminId id = GetUserAdmin(client);
		if (id == INVALID_ADMIN_ID || !GetAdminFlag(id, Admin_Generic, Access_Effective))
		{
			sign = "PLAYER";
		}
		
		if (replyto == SM_REPLY_TO_CONSOLE)
		{
			SetGlobalTransTarget(client);
			VFormat(szBuffer, sizeof(szBuffer), format, 3);
			
			C_RemoveTags(szBuffer, sizeof(szBuffer));
			PrintToConsole(client, "%s%s\n", tag, szBuffer);
			
			display_in_chat = true;
		}
	}
	else
	{
		SetGlobalTransTarget(LANG_SERVER);
		VFormat(szBuffer, sizeof(szBuffer), format, 3);
		
		C_RemoveTags(szBuffer, sizeof(szBuffer));
		PrintToServer("%s%s\n", tag, szBuffer);
	}
	
	if (!value)
	{
		return 1;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)|| IsFakeClient(i) || (display_in_chat && i == client))
		{
			continue;
		}
		
		SetGlobalTransTarget(i);
		
		AdminId id = GetUserAdmin(i);
		if (id == INVALID_ADMIN_ID || !GetAdminFlag(id, Admin_Generic, Access_Effective))
		{
			if ((value & 1) | (value & 2))
			{
				char newsign[MAX_NAME_LENGTH];
				newsign = sign;
				
				if ((value & 2) || (i == client))
				{
					newsign = name;
				}
				VFormat(szBuffer, sizeof(szBuffer), format, 3);
				
				C_PrintToChatEx(i, client, "%s%s: %s", tag, newsign, szBuffer);
			}
		}
		else
		{
			bool is_root = GetAdminFlag(id, Admin_Root, Access_Effective);
			if ((value & 4) || (value & 8) || ((value & 16) && is_root))
			{
				char newsign[MAX_NAME_LENGTH];
				newsign = sign;
				
				if ((value & 8) || ((value & 16) && is_root) || (i == client))
				{
					newsign = name;
				}
				VFormat(szBuffer, sizeof(szBuffer), format, 3);
				
				C_PrintToChatEx(i, client, "%s%s: %s", tag, newsign, szBuffer);
			}
		}
	}
	
	return 1;
}

/**
 * Same as C_ShowActivity(), except the tag parameter is used instead of "[SM] " (note that you must supply any spacing).
 * Supports color tags.
 *
 * @param client		Client index doing the action, or 0 for server.
 * @param tags			Tag to display with.
 * @param format		Formatting rules.
 * @param ...			Variable number of format parameters.
 * @noreturn
 * @error
 */
stock int C_ShowActivityEx(int client, const char[] tag, const char[] format, any ...)
{
	if (sm_show_activity == null)
		sm_show_activity = FindConVar("sm_show_activity");
	
	char szBuffer[MAX_MESSAGE_LENGTH];
	int value = sm_show_activity.IntValue;
	ReplySource replyto = GetCmdReplySource();
	
	char name[MAX_NAME_LENGTH] = "Console";
	char sign[MAX_NAME_LENGTH] = "ADMIN";
	bool display_in_chat = false;
	if (client != 0)
	{
		if (client < 0 || client > MaxClients || !IsClientConnected(client))
			ThrowError("Client index %d is invalid", client);
		
		GetClientName(client, name, sizeof(name));
		
		AdminId id = GetUserAdmin(client);
		if (id == INVALID_ADMIN_ID || !GetAdminFlag(id, Admin_Generic, Access_Effective))
		{
			sign = "PLAYER";
		}
		
		if (replyto == SM_REPLY_TO_CONSOLE)
		{
			SetGlobalTransTarget(client);
			VFormat(szBuffer, sizeof(szBuffer), format, 4);
			
			C_RemoveTags(szBuffer, sizeof(szBuffer));
			PrintToConsole(client, "%s%s\n", tag, szBuffer);
			display_in_chat = true;
		}
	}
	else
	{
		SetGlobalTransTarget(LANG_SERVER);
		VFormat(szBuffer, sizeof(szBuffer), format, 4);

		C_RemoveTags(szBuffer, sizeof(szBuffer));
		PrintToServer("%s%s\n", tag, szBuffer);
	}
	
	if (!value)
	{
		return 1;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || (display_in_chat && i == client))
		{
			continue;
		}
		
		SetGlobalTransTarget(i);
		
		AdminId id = GetUserAdmin(i);
		if (id == INVALID_ADMIN_ID || !GetAdminFlag(id, Admin_Generic, Access_Effective))
		{
			if ((value & 1) | (value & 2))
			{
				char newsign[MAX_NAME_LENGTH];
				newsign = sign;
				
				if ((value & 2) || (i == client))
				{
					newsign = name;
				}
				VFormat(szBuffer, sizeof(szBuffer), format, 4);
				
				C_PrintToChatEx(i, client, "%s%s: %s", tag, newsign, szBuffer);
			}
		}
		else
		{
			bool is_root = GetAdminFlag(id, Admin_Root, Access_Effective);
			if ((value & 4) || (value & 8) || ((value & 16) && is_root))
			{
				char newsign[MAX_NAME_LENGTH];
				newsign = sign;
				
				if ((value & 8) || ((value & 16) && is_root) || (i == client))
				{
					newsign = name;
				}
				VFormat(szBuffer, sizeof(szBuffer), format, 4);
				
				C_PrintToChatEx(i, client, "%s%s: %s", tag, newsign, szBuffer);
			}
		}
	}
	
	return 1;
}

/**
 * Displays usage of an admin command to users depending on the setting of the sm_show_activity cvar.
 * All users receive a message in their chat text, except for the originating client, 
 * who receives the message based on the current ReplySource.
 * Supports color tags.
 *
 * @param client		Client index doing the action, or 0 for server.
 * @param tags			Tag to prepend to the message.
 * @param format		Formatting rules.
 * @param ...			Variable number of format parameters.
 * @noreturn
 * @error
 */
stock int C_ShowActivity2(int client, const char[] tag, const char[] format, any ...)
{
	if (sm_show_activity == null)
		sm_show_activity = FindConVar("sm_show_activity");
	
	char szBuffer[MAX_MESSAGE_LENGTH];
	int value = sm_show_activity.IntValue;
	
	char name[MAX_NAME_LENGTH] = "Console";
	char sign[MAX_NAME_LENGTH] = "ADMIN";
	
	if (client != 0)
	{
		if (client < 0 || client > MaxClients || !IsClientConnected(client))
			ThrowError("Client index %d is invalid", client);
		
		GetClientName(client, name, sizeof(name));
		
		AdminId id = GetUserAdmin(client);
		if (id == INVALID_ADMIN_ID || !GetAdminFlag(id, Admin_Generic, Access_Effective))
		{
			sign = "PLAYER";
		}
		
		SetGlobalTransTarget(client);
		VFormat(szBuffer, sizeof(szBuffer), format, 4);
		
		C_PrintToChatEx(client, client, "%s%s", tag, szBuffer);
	}
	else
	{
		SetGlobalTransTarget(LANG_SERVER);
		VFormat(szBuffer, sizeof(szBuffer), format, 4);
		
		C_RemoveTags(szBuffer, sizeof(szBuffer));
		PrintToServer("%s%s\n", tag, szBuffer);
	}
	
	if (!value)
	{
		return 1;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || i == client)
		{
			continue;
		}
		
		SetGlobalTransTarget(i);
		
		AdminId id = GetUserAdmin(i);
		if (id == INVALID_ADMIN_ID || !GetAdminFlag(id, Admin_Generic, Access_Effective))
		{
			if ((value & 1) | (value & 2))
			{
				char newsign[MAX_NAME_LENGTH];
				newsign = sign;
				
				if ((value & 2))
				{
					newsign = name;
				}
				VFormat(szBuffer, sizeof(szBuffer), format, 4);

				C_PrintToChatEx(i, client, "%s%s: %s", tag, newsign, szBuffer);
			}
		}
		else
		{
			bool is_root = GetAdminFlag(id, Admin_Root, Access_Effective);
			if ((value & 4) || (value & 8) || ((value & 16) && is_root))
			{
				char newsign[MAX_NAME_LENGTH];
				newsign = sign;
				
				if ((value & 8) || ((value & 16) && is_root))
				{
					newsign = name;
				}
				VFormat(szBuffer, sizeof(szBuffer), format, 4);

				C_PrintToChatEx(i, client, "%s%s: %s", tag, newsign, szBuffer);
			}
		}
	}
	
	return 1;
}
