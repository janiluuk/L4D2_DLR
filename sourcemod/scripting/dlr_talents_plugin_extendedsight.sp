#define PLUGIN_VERSION "1.2.3"
#define PLUGIN_NAME "Extended sight"
#define PLUGIN_SKILL_NAME "extended_sight"

#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

Handle g_dlrCvarDuration;
Handle g_dlrCvarCooldown;
Handle g_dlrCvarGlow;
Handle g_dlrCvarGlowMode;
Handle g_dlrCvarGlowFade;
Handle g_dlrCvarNotify;
Handle g_dlrTimer[MAXPLAYERS+1] = { INVALID_HANDLE, ...};
Handle g_dlrRemoveTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};

int g_dlrGlowColor, g_dlrGlowColorFade1, g_dlrGlowColorFade2, g_dlrGlowColorFade3, g_dlrGlowColorFade4, g_dlrGlowColorFade5, g_dlrPropGhost;
bool g_dlrActive[MAXPLAYERS+1] = {false, ...};
bool g_dlrExtended[MAXPLAYERS+1] = {false, ...};
bool g_dlrForever[MAXPLAYERS+1] = {false, ...};
float g_dlrNextUse[MAXPLAYERS+1] = {0.0, ...};
char g_dlrGameName[64] = "";
int g_dlrHasAbility[MAXPLAYERS+1] = {-1, ...};
const int CLASS_SABOTEUR = 4;
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
        description = "Saboteurs can briefly see Special Infected through walls on demand.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2085325"
}

public void OnPluginStart()
{
	GetGameFolderName(g_dlrGameName, sizeof(g_dlrGameName));
	if (!StrEqual(g_dlrGameName, "left4dead2", false))
	{
		SetFailState("Plugin only supports Left 4 Dead 2!");
		return;
	}
	
	LoadTranslations("dlr_extendedsight.phrases");
	
	CreateConVar("l4d2_extendedsight_version", PLUGIN_VERSION, "Extended Survivor Sight Version", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
        g_dlrCvarNotify = CreateConVar("l4d2_extendedsight_notify", "1", "Notify players when they gain Extended Sight? 0 - disable, 1 - hintbox, 2 - chat", FCVAR_NOTIFY, true, 0.0, true, 2.0);
        g_dlrCvarDuration = CreateConVar("l4d2_extendedsight_duration", "20", "How long should the Extended Sight last?", FCVAR_NOTIFY, true, 1.0);
        g_dlrCvarCooldown = CreateConVar("l4d2_extendedsight_cooldown", "120", "Cooldown between uses in seconds", FCVAR_NOTIFY, true, 1.0);
	g_dlrCvarGlow = CreateConVar("l4d2_extendedsight_glowcolor", "255 75 75", "Glow color, use RGB, seperate values with spaces", FCVAR_NOTIFY);
	g_dlrCvarGlowMode = CreateConVar("l4d2_extendedsight_glowmode", "1", "Glow mode. 0 - persistent glow, 1 - fading glow", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_dlrCvarGlowFade = CreateConVar("l4d2_extendedsight_glowfadeinterval", "3", "Interval between each glow fade", FCVAR_NOTIFY, true, 1.5, true, 10.0);
	
        RegConsoleCmd("sm_extendedsight", Command_ExtendedSight, "Trigger Extended Survivor Sight");
	
	AutoExecConfig(true, "l4d2_extendedsight");
	
	g_dlrPropGhost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
	
	HookConVarChange(g_dlrCvarGlow, Changed_PluginCvarGlow);
}


public void OnPluginEnd() {
        DisableGlow();
}

//---------------------------------------------------------------------------------------------------------------

public int OnPlayerClassChange(int client, int newClass, int previousClass)
{
        g_dlrHasAbility[client] = (newClass == CLASS_SABOTEUR) ? 1 : 0;
	return g_dlrHasAbility[client];
}

public void OnMapStart()
{
    SetGlowColor();
    for(int i = 1; i <= MaxClients; ++i)
    {
        g_dlrActive[i] = false;
        g_dlrExtended[i] = false;
        g_dlrForever[i] = false;
    }
}




public Action Command_ExtendedSight(int client, int args)
{
        if (g_dlrHasAbility[client] <= 0) return Plugin_Handled;

        if (g_dlrActive[client])
        {
                ReplyToCommand(client, "%t", "ALREADYACTIVE");
                OnSpecialSkillFail(client, PLUGIN_SKILL_NAME, "active");
                return Plugin_Handled;
        }

        float now = GetGameTime();
        float cooldown = GetConVarFloat(g_dlrCvarCooldown);
        if (now < g_dlrNextUse[client])
        {
                int remain = RoundToCeil(g_dlrNextUse[client] - now);
                ReplyToCommand(client, "%t", "COOLDOWN", remain);
                OnSpecialSkillFail(client, PLUGIN_SKILL_NAME, "cooldown");
                return Plugin_Handled;
        }

        g_dlrNextUse[client] = now + cooldown;
        AddExtendedSight(GetConVarFloat(g_dlrCvarDuration), client);
        OnSpecialSkillSuccess(client, PLUGIN_SKILL_NAME);

        return Plugin_Handled;
}


public void Changed_PluginCvarGlow(Handle convar, const char[] oldValue, const char[] newValue) {
        SetGlowColor();
}

public Action TimerRemoveSight(Handle timer)
{
	RemoveExtendedSight();
	
	if(GetConVarInt(g_dlrCvarNotify) != 0)
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

	if(g_dlrActive[client])
		SetGlow(color, client);
	else if (g_dlrTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_dlrTimer[client]);
		g_dlrTimer[client] = INVALID_HANDLE;
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

	if(g_dlrActive[client])
	{
		Handle hPack = CreateDataPack();
		WritePackCell(hPack, userId);
		WritePackCell(hPack, g_dlrGlowColor);
		
		CreateTimer(0.1, TimerChangeGlow, hPack, TIMER_FLAG_NO_MAPCHANGE);
		Handle hPack1 = CreateDataPack();
		WritePackCell(hPack1, userId);
		WritePackCell(hPack1, g_dlrGlowColorFade1);
		CreateTimer(0.5, TimerChangeGlow, hPack1, TIMER_FLAG_NO_MAPCHANGE);
		Handle hPack2 = CreateDataPack();
		WritePackCell(hPack2, userId);
		WritePackCell(hPack2, g_dlrGlowColorFade2);
		CreateTimer(0.7, TimerChangeGlow, hPack2, TIMER_FLAG_NO_MAPCHANGE);
		Handle hPack3 = CreateDataPack();
		WritePackCell(hPack3, userId);
		WritePackCell(hPack3, g_dlrGlowColorFade3);		
		CreateTimer(0.9, TimerChangeGlow, hPack3, TIMER_FLAG_NO_MAPCHANGE);
		Handle hPack4 = CreateDataPack();		
		WritePackCell(hPack4, userId);
		WritePackCell(hPack4, g_dlrGlowColorFade4);
		CreateTimer(1.1, TimerChangeGlow, hPack4, TIMER_FLAG_NO_MAPCHANGE);
		Handle hPack5 = CreateDataPack();
		WritePackCell(hPack5, userId);
		WritePackCell(hPack5, g_dlrGlowColorFade5);
		CreateTimer(1.3, TimerChangeGlow, hPack5, TIMER_FLAG_NO_MAPCHANGE);
		Handle hPack6 = CreateDataPack();
		WritePackCell(hPack6, userId);
		WritePackCell(hPack6, 0);
		CreateTimer(1.4, TimerChangeGlow, hPack6, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (g_dlrTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_dlrTimer[client]);
		g_dlrTimer[client] = INVALID_HANDLE;
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

	if(g_dlrActive[client])
	{		
		if (g_dlrRemoveTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_dlrRemoveTimer[client]);
			g_dlrRemoveTimer[client] = INVALID_HANDLE;	
		}
		g_dlrExtended[client] = true;
	}
	
	g_dlrActive[client] = true;
	
	if(time == 0.0)
		g_dlrForever[client] = true;
	
	if(GetConVarInt(g_dlrCvarGlowMode) == 1 && !g_dlrExtended[client])
		g_dlrTimer[client] = CreateTimer(GetConVarFloat(g_dlrCvarGlowFade), TimerGlowFading, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	else if(!g_dlrExtended[client]) {
		int userId = GetClientUserId(client);
		Handle hPack = CreateDataPack();
		WritePackCell(hPack, userId);
		WritePackCell(hPack, g_dlrGlowColor);
		g_dlrTimer[client] = CreateTimer(0.1, TimerChangeGlow, hPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if(time > 0.0 && GetConVarInt(g_dlrCvarGlowMode) == 1)
		g_dlrRemoveTimer[client] = CreateTimer(time, TimerRemoveSight, TIMER_FLAG_NO_MAPCHANGE);
	else if(time > 0.0)
		g_dlrRemoveTimer[client] = CreateTimer(time+GetConVarFloat(g_dlrCvarGlowFade), TimerRemoveSight, TIMER_FLAG_NO_MAPCHANGE);
		
	if(time > 0.0 && GetConVarInt(g_dlrCvarNotify) != 0)
		NotifyPlayers();
}

void RemoveExtendedSight()
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(g_dlrActive[iClient])
		{
			g_dlrActive[iClient] = false;
			g_dlrExtended[iClient] = false;
			g_dlrForever[iClient] = false;
			
			DisableGlow();
		}
	}
}

void SetGlow(any color, int client)
{
	if (g_dlrHasAbility[client] <= 0) return;

	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsClientInGame(iClient) && IsPlayerAlive(iClient) && GetClientTeam(iClient) == 3 && g_dlrActive[client] == true && color != 0 && GetEntData(iClient, g_dlrPropGhost, 1)!=1)
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
				if(g_dlrActive[iClient] && !g_dlrExtended[iClient])
				{
					if(GetConVarInt(g_dlrCvarNotify)==1)
						PrintHintText(iClient, "%t", "ACTIVATED");
					else
						PrintToChat(iClient, "%t", "ACTIVATED");
				}
				else if(g_dlrExtended[iClient])
				{
					if(GetConVarInt(g_dlrCvarNotify)==1)
						PrintHintText(iClient, "%t", "DURATIONEXTENDED");
					else
						PrintToChat(iClient, "%t", "DURATIONEXTENDED");
				}
				else
				{	
					if(GetConVarInt(g_dlrCvarNotify)==1)
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
	
	GetConVarString(g_dlrCvarGlow, sPluginCvarGlow, sizeof(sPluginCvarGlow));
	ExplodeString(sPluginCvarGlow, " ", split, 3, 4);
	
	int rgb[3];
	rgb[0] = StringToInt(split[0]);
	rgb[1] = StringToInt(split[1]);
	rgb[2] = StringToInt(split[2]);
	
	g_dlrGlowColor = rgb[0]+256*rgb[1]+256*256*rgb[2];
	
	g_dlrGlowColorFade1 = (RoundFloat(rgb[0]/1.5))+256*(RoundFloat(rgb[1]/1.5))+256*256*(RoundFloat(rgb[2]/1.5));
	g_dlrGlowColorFade2 = (RoundFloat(rgb[0]/2.0))+256*(RoundFloat(rgb[1]/2.0))+256*256*(RoundFloat(rgb[2]/2.0));
	g_dlrGlowColorFade3 = (RoundFloat(rgb[0]/2.5))+256*(RoundFloat(rgb[1]/2.5))+256*256*(RoundFloat(rgb[2]/2.5));
	g_dlrGlowColorFade4 = (RoundFloat(rgb[0]/3.0))+256*(RoundFloat(rgb[1]/3.0))+256*256*(RoundFloat(rgb[2]/3.0));
	g_dlrGlowColorFade5 = (RoundFloat(rgb[0]/3.5))+256*(RoundFloat(rgb[1]/3.5))+256*256*(RoundFloat(rgb[2]/3.5));
}

