#define PLUGIN_VERSION "1.2.3"
#define PLUGIN_NAME "Extended sight"
#define PLUGIN_SKILL_NAME "extended_sight"

#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

Handle g_rageCvarDuration;
Handle g_rageCvarCooldown;
Handle g_rageCvarGlow;
Handle g_rageCvarGlowMode;
Handle g_rageCvarGlowFade;
Handle g_rageCvarNotify;
Handle g_rageTimer[MAXPLAYERS+1] = { INVALID_HANDLE, ...};
Handle g_rageRemoveTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};

int g_rageGlowColor, g_rageGlowColorFade1, g_rageGlowColorFade2, g_rageGlowColorFade3, g_rageGlowColorFade4, g_rageGlowColorFade5, g_ragePropGhost;
bool g_rageActive[MAXPLAYERS+1] = {false, ...};
bool g_rageExtended[MAXPLAYERS+1] = {false, ...};
bool g_rageForever[MAXPLAYERS+1] = {false, ...};
float g_rageNextUse[MAXPLAYERS+1] = {0.0, ...};
char g_rageGameName[64] = "";
int g_rageHasAbility[MAXPLAYERS+1] = {-1, ...};
const int CLASS_SABOTEUR = 4;
/****************************************************/
#tryinclude <RageCore>
#if !defined _DLRCore_included
	// Optional native from DLR Talents
	native void OnSpecialSkillSuccess(int client, char[] skillName);
	native void OnSpecialSkillFail(int client, char[] skillName, char[] reason);
	native void GetPlayerSkillName(int client, char[] skillName, int size);
	native int FindSkillIdByName(char[] skillName);
	native int RegisterDLRSkill(char[] skillName, int type);
	#define DLR_PLUGIN_NAME	"rage_talents"
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
	name = "[Rage] Extended Survivor Sight Plugin",
	author = "Yani, Jack'lul",
        description = "Saboteurs can briefly see Special Infected through walls on demand.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2085325"
}

public void OnPluginStart()
{
	GetGameFolderName(g_rageGameName, sizeof(g_rageGameName));
	if (!StrEqual(g_rageGameName, "left4dead2", false))
	{
		SetFailState("Plugin only supports Left 4 Dead 2!");
		return;
	}
	
	LoadTranslations("rage_extendedsight.phrases");
	
	CreateConVar("l4d2_extendedsight_version", PLUGIN_VERSION, "Extended Survivor Sight Version", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
        g_rageCvarNotify = CreateConVar("l4d2_extendedsight_notify", "1", "Notify players when they gain Extended Sight? 0 - disable, 1 - hintbox, 2 - chat", FCVAR_NOTIFY, true, 0.0, true, 2.0);
        g_rageCvarDuration = CreateConVar("l4d2_extendedsight_duration", "20", "How long should the Extended Sight last?", FCVAR_NOTIFY, true, 1.0);
        g_rageCvarCooldown = CreateConVar("l4d2_extendedsight_cooldown", "120", "Cooldown between uses in seconds", FCVAR_NOTIFY, true, 1.0);
	g_rageCvarGlow = CreateConVar("l4d2_extendedsight_glowcolor", "255 75 75", "Glow color, use RGB, seperate values with spaces", FCVAR_NOTIFY);
	g_rageCvarGlowMode = CreateConVar("l4d2_extendedsight_glowmode", "1", "Glow mode. 0 - persistent glow, 1 - fading glow", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_rageCvarGlowFade = CreateConVar("l4d2_extendedsight_glowfadeinterval", "3", "Interval between each glow fade", FCVAR_NOTIFY, true, 1.5, true, 10.0);
	
        RegConsoleCmd("sm_extendedsight", Command_ExtendedSight, "Trigger Extended Survivor Sight");
	
	AutoExecConfig(true, "l4d2_extendedsight");
	
	g_ragePropGhost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
	
	HookConVarChange(g_rageCvarGlow, Changed_PluginCvarGlow);
}


public void OnPluginEnd() {
        DisableGlow();
}

//---------------------------------------------------------------------------------------------------------------

public int OnPlayerClassChange(int client, int newClass, int previousClass)
{
        g_rageHasAbility[client] = (newClass == CLASS_SABOTEUR) ? 1 : 0;
	return g_rageHasAbility[client];
}

public void OnMapStart()
{
    SetGlowColor();
    for(int i = 1; i <= MaxClients; ++i)
    {
        g_rageActive[i] = false;
        g_rageExtended[i] = false;
        g_rageForever[i] = false;
    }
}




public Action Command_ExtendedSight(int client, int args)
{
        if (g_rageHasAbility[client] <= 0) return Plugin_Handled;

        if (g_rageActive[client])
        {
                ReplyToCommand(client, "%t", "ALREADYACTIVE");
                OnSpecialSkillFail(client, PLUGIN_SKILL_NAME, "active");
                return Plugin_Handled;
        }

        float now = GetGameTime();
        float cooldown = GetConVarFloat(g_rageCvarCooldown);
        if (now < g_rageNextUse[client])
        {
                int remain = RoundToCeil(g_rageNextUse[client] - now);
                ReplyToCommand(client, "%t", "COOLDOWN", remain);
                OnSpecialSkillFail(client, PLUGIN_SKILL_NAME, "cooldown");
                return Plugin_Handled;
        }

        g_rageNextUse[client] = now + cooldown;
        AddExtendedSight(GetConVarFloat(g_rageCvarDuration), client);
        OnSpecialSkillSuccess(client, PLUGIN_SKILL_NAME);

        return Plugin_Handled;
}


public void Changed_PluginCvarGlow(Handle convar, const char[] oldValue, const char[] newValue) {
        SetGlowColor();
}

public Action TimerRemoveSight(Handle timer)
{
	RemoveExtendedSight();
	
	if(GetConVarInt(g_rageCvarNotify) != 0)
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

	if(g_rageActive[client])
		SetGlow(color, client);
	else if (g_rageTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_rageTimer[client]);
		g_rageTimer[client] = INVALID_HANDLE;
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

	if(g_rageActive[client])
	{
		Handle hPack = CreateDataPack();
		WritePackCell(hPack, userId);
		WritePackCell(hPack, g_rageGlowColor);
		
		CreateTimer(0.1, TimerChangeGlow, hPack, TIMER_FLAG_NO_MAPCHANGE);
		Handle hPack1 = CreateDataPack();
		WritePackCell(hPack1, userId);
		WritePackCell(hPack1, g_rageGlowColorFade1);
		CreateTimer(0.5, TimerChangeGlow, hPack1, TIMER_FLAG_NO_MAPCHANGE);
		Handle hPack2 = CreateDataPack();
		WritePackCell(hPack2, userId);
		WritePackCell(hPack2, g_rageGlowColorFade2);
		CreateTimer(0.7, TimerChangeGlow, hPack2, TIMER_FLAG_NO_MAPCHANGE);
		Handle hPack3 = CreateDataPack();
		WritePackCell(hPack3, userId);
		WritePackCell(hPack3, g_rageGlowColorFade3);		
		CreateTimer(0.9, TimerChangeGlow, hPack3, TIMER_FLAG_NO_MAPCHANGE);
		Handle hPack4 = CreateDataPack();		
		WritePackCell(hPack4, userId);
		WritePackCell(hPack4, g_rageGlowColorFade4);
		CreateTimer(1.1, TimerChangeGlow, hPack4, TIMER_FLAG_NO_MAPCHANGE);
		Handle hPack5 = CreateDataPack();
		WritePackCell(hPack5, userId);
		WritePackCell(hPack5, g_rageGlowColorFade5);
		CreateTimer(1.3, TimerChangeGlow, hPack5, TIMER_FLAG_NO_MAPCHANGE);
		Handle hPack6 = CreateDataPack();
		WritePackCell(hPack6, userId);
		WritePackCell(hPack6, 0);
		CreateTimer(1.4, TimerChangeGlow, hPack6, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (g_rageTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_rageTimer[client]);
		g_rageTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	return Plugin_Continue;
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

	if(g_rageActive[client])
	{		
		if (g_rageRemoveTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_rageRemoveTimer[client]);
			g_rageRemoveTimer[client] = INVALID_HANDLE;	
		}
		g_rageExtended[client] = true;
	}
	
	g_rageActive[client] = true;
	
	if(time == 0.0)
		g_rageForever[client] = true;
	
	if(GetConVarInt(g_rageCvarGlowMode) == 1 && !g_rageExtended[client])
		g_rageTimer[client] = CreateTimer(GetConVarFloat(g_rageCvarGlowFade), TimerGlowFading, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	else if(!g_rageExtended[client]) {
		int userId = GetClientUserId(client);
		Handle hPack = CreateDataPack();
		WritePackCell(hPack, userId);
		WritePackCell(hPack, g_rageGlowColor);
		g_rageTimer[client] = CreateTimer(0.1, TimerChangeGlow, hPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if(time > 0.0 && GetConVarInt(g_rageCvarGlowMode) == 1)
		g_rageRemoveTimer[client] = CreateTimer(time, TimerRemoveSight, TIMER_FLAG_NO_MAPCHANGE);
	else if(time > 0.0)
		g_rageRemoveTimer[client] = CreateTimer(time+GetConVarFloat(g_rageCvarGlowFade), TimerRemoveSight, TIMER_FLAG_NO_MAPCHANGE);
		
	if(time > 0.0 && GetConVarInt(g_rageCvarNotify) != 0)
		NotifyPlayers();
}

void RemoveExtendedSight()
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(g_rageActive[iClient])
		{
			g_rageActive[iClient] = false;
			g_rageExtended[iClient] = false;
			g_rageForever[iClient] = false;
			
			DisableGlow();
		}
	}
}

void SetGlow(any color, int client)
{
	if (g_rageHasAbility[client] <= 0) return;

	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsClientInGame(iClient) && IsPlayerAlive(iClient) && GetClientTeam(iClient) == 3 && g_rageActive[client] == true && color != 0 && GetEntData(iClient, g_ragePropGhost, 1)!=1)
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
			if(GetClientTeam(iClient) == 2)
			{
				if(g_rageActive[iClient] && !g_rageExtended[iClient])
				{
					if(GetConVarInt(g_rageCvarNotify)==1)
						PrintHintText(iClient, "%t", "ACTIVATED");
					else
						PrintToChat(iClient, "%t", "ACTIVATED");
				}
				else if(g_rageExtended[iClient])
				{
					if(GetConVarInt(g_rageCvarNotify)==1)
						PrintHintText(iClient, "%t", "DURATIONEXTENDED");
					else
						PrintToChat(iClient, "%t", "DURATIONEXTENDED");
				}
				else
				{	
					if(GetConVarInt(g_rageCvarNotify)==1)
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
	
	GetConVarString(g_rageCvarGlow, sPluginCvarGlow, sizeof(sPluginCvarGlow));
	ExplodeString(sPluginCvarGlow, " ", split, 3, 4);
	
	int rgb[3];
	rgb[0] = StringToInt(split[0]);
	rgb[1] = StringToInt(split[1]);
	rgb[2] = StringToInt(split[2]);
	
	g_rageGlowColor = rgb[0]+256*rgb[1]+256*256*rgb[2];
	
	g_rageGlowColorFade1 = (RoundFloat(rgb[0]/1.5))+256*(RoundFloat(rgb[1]/1.5))+256*256*(RoundFloat(rgb[2]/1.5));
	g_rageGlowColorFade2 = (RoundFloat(rgb[0]/2.0))+256*(RoundFloat(rgb[1]/2.0))+256*256*(RoundFloat(rgb[2]/2.0));
	g_rageGlowColorFade3 = (RoundFloat(rgb[0]/2.5))+256*(RoundFloat(rgb[1]/2.5))+256*256*(RoundFloat(rgb[2]/2.5));
	g_rageGlowColorFade4 = (RoundFloat(rgb[0]/3.0))+256*(RoundFloat(rgb[1]/3.0))+256*256*(RoundFloat(rgb[2]/3.0));
	g_rageGlowColorFade5 = (RoundFloat(rgb[0]/3.5))+256*(RoundFloat(rgb[1]/3.5))+256*256*(RoundFloat(rgb[2]/3.5));
}

