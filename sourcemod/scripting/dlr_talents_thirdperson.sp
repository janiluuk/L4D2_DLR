#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#pragma semicolon 1
#pragma newdecls required

#define THIRDPERSON_LIBRARY "dlr_talents_thirdperson"
#define THIRDPERSON_CONFIG "dlr_thirdperson"

enum ThirdPersonMode
{
	ThirdPersonMode_Off = 0,
	ThirdPersonMode_MeleeOnly = 1,
	ThirdPersonMode_Always = 2
};

ConVar g_hPluginEnabled;
Cookie g_hCookie;

int g_iClientModePref[MAXPLAYERS + 1] = {0, ...};
bool g_bThirdMelee[MAXPLAYERS + 1] = {false, ...};
bool g_bThirdMeleeAlways[MAXPLAYERS + 1] = {false, ...};

public Plugin myinfo =
{
	name = "[L4D2] Thirdperson with Melee-Only and Always on modes",
	author = "Yani & MasterMind420",
	description = "Enable third person on melee only, always or never. Preference is autosaved.",
	version = "1.3",
	url = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("DLRThirdPerson_IsAllowed", Native_IsAllowed);
	CreateNative("DLRThirdPerson_GetMode", Native_GetMode);
	CreateNative("DLRThirdPerson_SetMode", Native_SetMode);

	RegPluginLibrary(THIRDPERSON_LIBRARY);
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hPluginEnabled = CreateConVar("l4d_thirdperson_allow", "1", "0=Plugin off, 1=Plugin on.", FCVAR_NOTIFY);
	RegConsoleCmd("sm_tp", sm_tp);
	RegConsoleCmd("sm_tps", sm_tp_select);
	g_hCookie = RegClientCookie("l4d_tp_preference", "Third person - Mode", CookieAccess_Protected);
	g_hPluginEnabled.AddChangeHook(ConVarChanged_Allow);

	AutoExecConfig(true, THIRDPERSON_CONFIG);
	SyncAllClients();
}

public void OnConfigsExecuted()
{
	SyncAllClients();
}

public void OnMapStart()
{
	SyncAllClients();
}

public void OnClientPutInServer(int client)
{
	ResetClientState(client, true);

	if (IsHumanClient(client) && AreClientCookiesCached(client))
	{
		LoadClientPreference(client);
		ApplySavedMode(client);
	}
}

public void OnClientDisconnect(int client)
{
	ResetClientState(client, true);
}

public void OnClientCookiesCached(int client)
{
	if (!IsHumanClient(client))
	{
		return;
	}

	LoadClientPreference(client);
	ApplySavedMode(client);
}

void ConVarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar.BoolValue)
	{
		SyncAllClients();
	}
	else
	{
		ResetAllClientsView();
	}
}

public Action sm_tp_select(int client, int args)
{
	if (!IsHumanClient(client))
	{
		return Plugin_Handled;
	}

	if (args < 1)
	{
		ReplyToCommand(client, "Usage: !tps <0|1|2> (0: Disable, 1: Melee only, 2: Always on)");
		return Plugin_Handled;
	}

	char arg[3];
	GetCmdArg(1, arg, sizeof(arg));

	ThirdPersonMode mode = ClampThirdPersonMode(view_as<ThirdPersonMode>(StringToInt(arg)));
	bool applied = ApplyThirdPersonMode(client, mode);

	char modeLabel[32];
	GetModeLabel(mode, modeLabel, sizeof(modeLabel));

	ReplyToCommand(client, "[DLR] Third person %s%s", modeLabel, applied ? "" : " (saved, waiting for enable)");
	return Plugin_Handled;
}


public Action sm_tp(int client, int args)
{
	if (IsHumanClient(client))
	{
		ModeSelectMenu(client);
	}

	return Plugin_Handled;
}

void ModeSelectMenu(int client)
{
	if (client <= 0 || !IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		return;
	}

	Menu menu = CreateMenu(MenuSelector1);
	SetMenuTitle(menu, "Please Select 3rd person Mode (!tp)");

	AddMenuItem(menu, "0", "3rd person disabled");
	AddMenuItem(menu, "1", "3rd person with melee weapon");
	AddMenuItem(menu, "2", "3rd person always enabled");

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 10);
}

public int MenuSelector1(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Select)
	{
		char item[32];
		GetMenuItem(menu, param2, item, sizeof(item));

		ThirdPersonMode mode = ClampThirdPersonMode(view_as<ThirdPersonMode>(StringToInt(item)));
		ApplyThirdPersonMode(client, mode);
	}

	return 0;
}


public void OnGameFrame()
{
	if (!IsThirdPersonAllowed())
	{
		return;
	}

	char sClassName[64];

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!g_bThirdMelee[client] || !IsHumanClient(client) || !IsPlayerAlive(client))
		{
			continue;
		}

		int weaponSlot = GetPlayerWeaponSlot(client, 1);
		if (weaponSlot == -1)
		{
			continue;
		}

		int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		GetEdictClassname(weaponSlot, sClassName, sizeof(sClassName));

		if (g_bThirdMeleeAlways[client] || (StrEqual(sClassName, "weapon_melee") && weaponSlot == activeWeapon))
		{
			SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 99999.3);
		}
		else
		{
			SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 0.0);
		}
	}
}

// Helper functions
bool IsHumanClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client));
}

ThirdPersonMode ClampThirdPersonMode(ThirdPersonMode mode)
{
	if (mode < ThirdPersonMode_Off || mode > ThirdPersonMode_Always)
	{
		return ThirdPersonMode_Off;
	}

	return mode;
}


void GetModeLabel(ThirdPersonMode mode, char[] buffer, int maxlen)
{
	switch (mode)
	{
		case ThirdPersonMode_MeleeOnly:
		{
			strcopy(buffer, maxlen, "enabled for melee only");
		}
		case ThirdPersonMode_Always:
		{
			strcopy(buffer, maxlen, "always enabled");
		}
		default:
		{
			strcopy(buffer, maxlen, "disabled");
		}
	}
}


void LoadClientPreference(int client)
{
	char sCookie[3];
	GetClientCookie(client, g_hCookie, sCookie, sizeof(sCookie));
	g_iClientModePref[client] = view_as<int>(ClampThirdPersonMode(view_as<ThirdPersonMode>(StringToInt(sCookie))));
}

void SetClientPrefs(int client)
{
	if (!IsHumanClient(client))
	{
		return;
	}

	char sCookie[3];
	IntToString(g_iClientModePref[client], sCookie, sizeof(sCookie));
	SetClientCookie(client, g_hCookie, sCookie);
}

bool ApplyThirdPersonMode(int client, ThirdPersonMode mode)
{
	if (!IsHumanClient(client))
	{
		return false;
	}

	mode = ClampThirdPersonMode(mode);

	g_iClientModePref[client] = view_as<int>(mode);
	g_bThirdMelee[client] = (mode != ThirdPersonMode_Off);
	g_bThirdMeleeAlways[client] = (mode == ThirdPersonMode_Always);
	SetClientPrefs(client);

	if (!IsThirdPersonAllowed())
	{
		SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 0.0);
		return false;
	}

	if (mode == ThirdPersonMode_Always)
	{
		SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 99999.3);
	}
	else
	{
		SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 0.0);
	}

	return true;
}

void ApplySavedMode(int client)
{
	ApplyThirdPersonMode(client, ClampThirdPersonMode(view_as<ThirdPersonMode>(g_iClientModePref[client])));
}

bool IsThirdPersonAllowed()
{
	return (g_hPluginEnabled != null && g_hPluginEnabled.BoolValue);
}

void SyncAllClients()
{
	if (!IsThirdPersonAllowed())
	{
		ResetAllClientsView();
		return;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsHumanClient(i))
		{
			continue;
		}

		if (AreClientCookiesCached(i))
		{
			LoadClientPreference(i);
			ApplySavedMode(i);
		}
	}
}

void ResetClientState(int client, bool clearPreference)
{
	if (client <= 0 || client > MaxClients)
	{
		return;
	}

	g_bThirdMelee[client] = false;
	g_bThirdMeleeAlways[client] = false;

	if (clearPreference)
	{
		g_iClientModePref[client] = 0;
	}
}

void ResetAllClientsView()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}

		SetEntPropFloat(i, Prop_Send, "m_TimeForceExternalView", 0.0);
		g_bThirdMelee[i] = false;
		g_bThirdMeleeAlways[i] = false;
	}
}

// Native bindings
public int Native_IsAllowed(Handle plugin, int numParams)
{
	return IsThirdPersonAllowed();
}

public int Native_GetMode(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (client <= 0 || client > MaxClients)
	{
		return view_as<int>(ThirdPersonMode_Off);
	}

	return g_iClientModePref[client];
}

public int Native_SetMode(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	ThirdPersonMode mode = ClampThirdPersonMode(view_as<ThirdPersonMode>(GetNativeCell(2)));
	return ApplyThirdPersonMode(client, mode);
}
