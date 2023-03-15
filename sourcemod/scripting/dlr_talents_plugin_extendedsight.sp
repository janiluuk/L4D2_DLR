#define PLUGIN_VERSION "1.2.3"
#define PLUGIN_NAME "Extended sight"
#define PLUGIN_SKILL_NAME = "extended_sight"

#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

Handle PluginCvarMode;
Handle PluginCvarDuration;
Handle PluginCvarModesOn;
Handle PluginCvarModesOff;
Handle PluginCvarGlow;
Handle PluginCvarGlowMode;
Handle PluginCvarGlowFadeInterval;
Handle PluginCvarNotify;
Handle GameMode = INVALID_HANDLE;
Handle ExtendedSightTimer[MAXPLAYERS+1] = { INVALID_HANDLE, ...};
Handle ExtendedSightRemoveTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};

int GlowColor, GlowColor_Fade1, GlowColor_Fade2, GlowColor_Fade3, GlowColor_Fade4, GlowColor_Fade5, PropGhost;
bool ExtendedSightActive[MAXPLAYERS+1] = {false, ...};
bool ExtendedSightExtended[MAXPLAYERS+1] = {false, ...}; 
bool ExtendedSightForever[MAXPLAYERS+1] = {false, ...};
bool isAllowed = false;
char GameName[64] = "";
int g_iHasAbility[MAXPLAYERS+1] = {-1, ...};
/****************************************************/
#tryinclude <DLRCore>
#if !defined _DLRCore_included
	// Optional native from DLR Talents
	native void OnSpecialSkillSuccess(int client, char[] skillName);
	native void OnSpecialSkillFail(int client, char[] skillName, char[] reason);
	native void GetPlayerSkillName(int client, char[] skillName, int size);
	native int FindSkillIdByName(char[] skillName);
	native int RegisterDLRSkill(char[] skillName, int type);
	#define DLR_PLUGIN_NAME	"dlr_talents"
#endif
/****************************************************/

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
		return APLRes_SilentFailure;
	}

	RegPluginLibrary("extended_sight");
	MarkNativeAsOptional("OnSpecialSkillFail");	
	MarkNativeAsOptional("OnSpecialSkillSuccess");		
	MarkNativeAsOptional("OnPlayerClassChange");
	MarkNativeAsOptional("GetPlayerSkillName");	
	MarkNativeAsOptional("RegisterDLRSkill");
	MarkNativeAsOptional("DLR_OnPluginState");	
	return APLRes_Success;

}
public Plugin myinfo = 
{
	name = "[DLR] Extended Survivor Sight Plugin",
	author = "Yani, Jack'lul",
	description = "Gives Survivor ability to see Special Infected through walls for a configurable time after killing Tank or Witch.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2085325"
}

public void OnPluginStart()
{
	GetGameFolderName(GameName, sizeof(GameName));
	if (!StrEqual(GameName, "left4dead2", false))
	{
		SetFailState("Plugin only supports Left 4 Dead 2!");
		return;
	}
	
	LoadTranslations("l4d2_extendedsight.phrases");
	
	CreateConVar("l4d2_extendedsight_version", PLUGIN_VERSION, "Extended Survivor Sight Version", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	
	PluginCvarMode = CreateConVar("l4d2_extendedsight_mode", "3", "When to reward Survivors with Extended Sight? 1 - when Tank is killed, 2 - when Witch is killed, 3 - when Tank or Witch is killed, 4 - active all the time, 0 - disabled", FCVAR_NOTIFY, true, 0.0, true, 4.0);
	PluginCvarNotify = CreateConVar("l4d2_extendedsight_notify", "1", "Notify players when they gain Extended Sight? 0 - disable, 1 - hintbox, 2 - chat", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	PluginCvarDuration = CreateConVar("l4d2_extendedsight_duration", "30", "How long should the Extended Sight last?", FCVAR_NOTIFY, true, 10.0);
	PluginCvarGlow = CreateConVar("l4d2_extendedsight_glowcolor", "255 75 75", "Glow color, use RGB, seperate values with spaces", FCVAR_NOTIFY);
	PluginCvarGlowMode = CreateConVar("l4d2_extendedsight_glowmode", "1", "Glow mode. 0 - persistent glow, 1 - fading glow", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	PluginCvarGlowFadeInterval = CreateConVar("l4d2_extendedsight_glowfadeinterval", "3", "Interval between each glow fade", FCVAR_NOTIFY, true, 1.5, true, 10.0);
	PluginCvarModesOn =	CreateConVar("l4d2_extendedsight_modes_on", "", "Plugin will be enabled on these game modes. Empty = All", FCVAR_NOTIFY);
	PluginCvarModesOff = CreateConVar("l4d2_extendedsight_modes_off", "versus,teamversus,scavenge,teamscavenge,mutation12,teamrealismversus,mutation11,mutation13,mutation15,mutation18,mutation19,community3,community6,l4d1vs", "Plugin will be disabled on these game modes. Empty = None", FCVAR_NOTIFY);
	
	RegAdminCmd("sm_extendedsight", Command_ExtendedSight, ADMFLAG_BAN, "Extended Survivor Sight On/Off");
	
	AutoExecConfig(true, "l4d2_extendedsight");
	
	PropGhost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
	
	HookConVarChange(PluginCvarGlow, Changed_PluginCvarGlow);
}

public void OnConfigsExecuted()
{
	bool CheckAllowed = IsAllowedGameMode();
	
	SetGlowColor();
	
	if(isAllowed == false && GetConVarInt(PluginCvarMode) != 0 && CheckAllowed == true)
	{
		isAllowed = true;
		HookEvent("tank_killed", Event_TankKilled);
		HookEvent("witch_killed", Event_WitchKilled);
		HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	}
	else if(isAllowed == true && (GetConVarInt(PluginCvarMode) == 0 || CheckAllowed == false))
	{
		isAllowed = false;
		UnhookEvent("tank_killed", Event_TankKilled);
		UnhookEvent("witch_killed", Event_WitchKilled);
		UnhookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	}
}

public void OnPluginEnd() {
	DisableGlow();
}

//---------------------------------------------------------------------------------------------------------------

public void OnMapStart()
{
	if(GetConVarInt(PluginCvarMode) != 0)
	{
		GameMode = FindConVar("mp_gamemode");
		for(int i = 1; i <= MaxClients; ++i)
		{
			ExtendedSightActive[i] = false;
			ExtendedSightExtended[i] = false;
			ExtendedSightForever[i] = false;
			if(GetConVarInt(PluginCvarMode) == 4 && g_iHasAbility[i] > 0 && IsValidEntity(i) && IsClientInGame(i) && GetClientTeam(i) == 2)
				AddExtendedSight(0.0, i);		
			}
	}

}

public void Event_TankKilled(Handle event, const char[] name, bool dontBroadcast)
{	
	int killerUserId = GetEventInt(event, "attacker");
	int killerClient = GetClientOfUserId(killerUserId);		
	
	if(killerClient > 0 && IsValidEntity(killerClient) && IsClientInGame(killerClient) && g_iHasAbility[killerClient] > 0 && GetConVarInt(PluginCvarMode) == 1 || GetConVarInt(PluginCvarMode) == 3 && !ExtendedSightForever[killerClient]) {
		AddExtendedSight(GetConVarFloat(PluginCvarDuration), killerClient);
	}
}

public void Event_WitchKilled(Handle event, const char[] name, bool dontBroadcast)
{
	int killerUserId = GetEventInt(event, "attacker");
	int killerClient = GetClientOfUserId(killerUserId);

	if(killerClient > 0 && IsValidEntity(killerClient) && IsClientInGame(killerClient) && g_iHasAbility[killerClient] > 0 && GetConVarInt(PluginCvarMode) == 2 || GetConVarInt(PluginCvarMode) == 3 && !ExtendedSightForever[killerClient]) 
		AddExtendedSight(GetConVarFloat(PluginCvarDuration), killerClient);
}

public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if(GetConVarInt(PluginCvarMode) != 4)
		RemoveExtendedSight();
	else
		DisableGlow();
}

public Action Command_ExtendedSight(int client, any args) 
{	
	char arg[5];
	GetCmdArg(1, arg, sizeof(arg));
	if (g_iHasAbility[client] <= 0) return Plugin_Handled;

	if(StrEqual(arg, "on", false) || StringToInt(arg) == 1 && args != 0)
	{
		if(!ExtendedSightActive[client])
		{
			ReplyToCommand(client, "%t", "ACTIVATEDPERMANENTLY");
			AddExtendedSight(0.0, client);
		}
		else
			ReplyToCommand(client, "%t", "ALREADYACTIVE");
	}
	else if(StrEqual(arg, "off", false) || StringToInt(arg) == 0 && args != 0)
	{
		if(ExtendedSightActive[client])
		{
			ReplyToCommand(client, "%t", "DEACTIVATED");
			RemoveExtendedSight();
		}
		else
			ReplyToCommand(client, "%t", "NOTACTIVE");
	}
	else
		ReplyToCommand(client, "%t", "COMMANDUSAGE");
	
	return Plugin_Handled;
}

public void Changed_PluginCvarGlow(Handle convar, const char[] oldValue, const char[] newValue) {
	SetGlowColor();
}

public Action TimerRemoveSight(Handle timer)
{
	RemoveExtendedSight();
	
	if(GetConVarInt(PluginCvarNotify) != 0)
		NotifyPlayers();
	return Plugin_Handled;
}

public Action TimerChangeGlow(Handle timer, Handle hPack)
{
	ResetPack(hPack);
	int userId = ReadPackCell(hPack);
	int color = ReadPackCell(hPack);
	int client = GetClientOfUserId(userId);
		if (!client
		|| !IsValidEntity(client)
		|| !IsClientInGame(client)
		|| !IsPlayerAlive(client)
		)
	return Plugin_Stop;


	if(ExtendedSightActive[client])
		SetGlow(color, client);
	else if (ExtendedSightTimer[client] != INVALID_HANDLE)
	{
		KillTimer(ExtendedSightTimer[client]);
		ExtendedSightTimer[client] = INVALID_HANDLE;
	}

	CloseHandle(hPack);

	return Plugin_Stop;
}

public Action TimerGlowFading(Handle timer, int userId)
{	
	int client = GetClientOfUserId(userId);
	if (!client
		|| !IsValidEntity(client)
		|| !IsClientInGame(client)
		|| !IsPlayerAlive(client)
		)
	return Plugin_Stop;

	if(ExtendedSightActive[client])
	{
		Handle hPack = CreateDataPack();
		WritePackCell(hPack, userId);
		WritePackCell(hPack, GlowColor);
		
		CreateTimer(0.1, TimerChangeGlow, hPack, TIMER_FLAG_NO_MAPCHANGE);
		Handle hPack1 = CreateDataPack();
		WritePackCell(hPack1, userId);
		WritePackCell(hPack1, GlowColor_Fade1);
		CreateTimer(0.5, TimerChangeGlow, hPack1, TIMER_FLAG_NO_MAPCHANGE);
		Handle hPack2 = CreateDataPack();
		WritePackCell(hPack2, userId);
		WritePackCell(hPack2, GlowColor_Fade2);
		CreateTimer(0.7, TimerChangeGlow, hPack2, TIMER_FLAG_NO_MAPCHANGE);
		Handle hPack3 = CreateDataPack();
		WritePackCell(hPack3, userId);
		WritePackCell(hPack3, GlowColor_Fade3);		
		CreateTimer(0.9, TimerChangeGlow, hPack3, TIMER_FLAG_NO_MAPCHANGE);
		Handle hPack4 = CreateDataPack();		
		WritePackCell(hPack4, userId);
		WritePackCell(hPack4, GlowColor_Fade4);
		CreateTimer(1.1, TimerChangeGlow, hPack4, TIMER_FLAG_NO_MAPCHANGE);
		Handle hPack5 = CreateDataPack();
		WritePackCell(hPack5, userId);
		WritePackCell(hPack5, GlowColor_Fade5);
		CreateTimer(1.3, TimerChangeGlow, hPack5, TIMER_FLAG_NO_MAPCHANGE);
		Handle hPack6 = CreateDataPack();
		WritePackCell(hPack6, userId);
		WritePackCell(hPack6, 0);
		CreateTimer(1.4, TimerChangeGlow, hPack6, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (ExtendedSightTimer[client] != INVALID_HANDLE)
	{
		KillTimer(ExtendedSightTimer[client]);
		ExtendedSightTimer[client] = INVALID_HANDLE;
	}

}

//---------------------------------------------------------------------------------------------------------------

void AddExtendedSight(float time, int client)
{
	if (!client
		|| !IsValidEntity(client)
		|| !IsClientInGame(client)
		|| !IsPlayerAlive(client)
	) {
		return;
	}

	if(ExtendedSightActive[client])
	{		
		if (ExtendedSightRemoveTimer[client] != INVALID_HANDLE)
		{
			KillTimer(ExtendedSightRemoveTimer[client]);
			ExtendedSightRemoveTimer[client] = INVALID_HANDLE;	
		}
		ExtendedSightExtended[client] = true;
	}
	
	ExtendedSightActive[client] = true;
	
	if(time == 0.0)
		ExtendedSightForever[client] = true;
	
	if(GetConVarInt(PluginCvarGlowMode) == 1 && !ExtendedSightExtended[client])
		ExtendedSightTimer[client] = CreateTimer(GetConVarFloat(PluginCvarGlowFadeInterval), TimerGlowFading, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	else if(!ExtendedSightExtended[client]) {
		int userId = GetClientUserId(client);
		Handle hPack = CreateDataPack();
		WritePackCell(hPack, userId);
		WritePackCell(hPack, GlowColor);
		ExtendedSightTimer[client] = CreateTimer(0.1, TimerChangeGlow, hPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if(time > 0.0 && GetConVarInt(PluginCvarGlowMode) == 1)
		ExtendedSightRemoveTimer[client] = CreateTimer(time, TimerRemoveSight, TIMER_FLAG_NO_MAPCHANGE);
	else if(time > 0.0)
		ExtendedSightRemoveTimer[client] = CreateTimer(time+GetConVarFloat(PluginCvarGlowFadeInterval), TimerRemoveSight, TIMER_FLAG_NO_MAPCHANGE);
		
	if(time > 0.0 && GetConVarInt(PluginCvarNotify) != 0)
		NotifyPlayers();
}

void RemoveExtendedSight()
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(ExtendedSightActive[iClient])
		{
			ExtendedSightActive[iClient] = false;
			ExtendedSightExtended[iClient] = false;
			ExtendedSightForever[iClient] = false;
			
			DisableGlow();
		}
	}
}

void SetGlow(any color, int client)
{
	if (g_iHasAbility[client] <= 0) return;

	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsClientInGame(iClient) && IsPlayerAlive(iClient) && GetClientTeam(iClient) == 3 && ExtendedSightActive[client] == true && color != 0 && GetEntData(iClient, PropGhost, 1)!=1)
		{
			SetEntProp(iClient, Prop_Send, "m_iGlowType", 3);
			SetEntProp(iClient, Prop_Send, "m_glowColorOverride", color);
		}
		else if(IsClientInGame(iClient))
		{
			SetEntProp(iClient, Prop_Send, "m_iGlowType", 0);
			SetEntProp(iClient, Prop_Send, "m_glowColorOverride", 0);	
		}
	}
}

void DisableGlow()
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsClientInGame(iClient))
		{
			SetEntProp(iClient, Prop_Send, "m_iGlowType", 0);
			SetEntProp(iClient, Prop_Send, "m_glowColorOverride", 0);	
		}
	}	
}

void NotifyPlayers()
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsClientInGame(iClient))
		{
			if(GetClientTeam(iClient) == 2 && GetConVarInt(PluginCvarMode) != 4)
			{
				if(ExtendedSightActive[iClient] && !ExtendedSightExtended[iClient])
				{
					if(GetConVarInt(PluginCvarNotify)==1)
						PrintHintText(iClient, "%t", "ACTIVATED");
					else
						PrintToChat(iClient, "%t", "ACTIVATED");
				}
				else if(ExtendedSightExtended[iClient])
				{
					if(GetConVarInt(PluginCvarNotify)==1)
						PrintHintText(iClient, "%t", "DURATIONEXTENDED");
					else
						PrintToChat(iClient, "%t", "DURATIONEXTENDED");
				}
				else
				{	
					if(GetConVarInt(PluginCvarNotify)==1)
						PrintHintText(iClient, "%t", "DEACTIVATED");
					else
						PrintToChat(iClient, "%t", "DEACTIVATED");
				}
			}
		}	
	}
}

void SetGlowColor()
{
	char split[3][3];
	char sPluginCvarGlow[64];
	
	GetConVarString(PluginCvarGlow, sPluginCvarGlow, sizeof(sPluginCvarGlow));
	ExplodeString(sPluginCvarGlow, " ", split, 3, 4);
	
	int rgb[3];
	rgb[0] = StringToInt(split[0]);
	rgb[1] = StringToInt(split[1]);
	rgb[2] = StringToInt(split[2]);
	
	GlowColor = rgb[0]+256*rgb[1]+256*256*rgb[2];
	
	GlowColor_Fade1 = (RoundFloat(rgb[0]/1.5))+256*(RoundFloat(rgb[1]/1.5))+256*256*(RoundFloat(rgb[2]/1.5));
	GlowColor_Fade2 = (RoundFloat(rgb[0]/2.0))+256*(RoundFloat(rgb[1]/2.0))+256*256*(RoundFloat(rgb[2]/2.0));
	GlowColor_Fade3 = (RoundFloat(rgb[0]/2.5))+256*(RoundFloat(rgb[1]/2.5))+256*256*(RoundFloat(rgb[2]/2.5));
	GlowColor_Fade4 = (RoundFloat(rgb[0]/3.0))+256*(RoundFloat(rgb[1]/3.0))+256*256*(RoundFloat(rgb[2]/3.0));
	GlowColor_Fade5 = (RoundFloat(rgb[0]/3.5))+256*(RoundFloat(rgb[1]/3.5))+256*256*(RoundFloat(rgb[2]/3.5));
}

// credits for this code and code in OnConfigsExecuted() goes to Silvers - https://forums.alliedmods.net/member.php?u=85778
bool IsAllowedGameMode()
{
	if( GameMode == INVALID_HANDLE )
		return false;
	
	char sGameModes[64];
	char sGameMode[64];
	GetConVarString(GameMode, sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);
	
	GetConVarString(PluginCvarModesOn, sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}
	
	GetConVarString(PluginCvarModesOff, sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}
	
	return true;
}