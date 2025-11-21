#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define PLUGIN_SKILL_NAME "Nightvision"
#define PLUGIN_DESCRIPTION "Toggle nightvision goggles"

/****************************************************/
#tryinclude <RageCore>
#if !defined _RageCore_included
    // Optional native from Rage Survivor
    native void OnSpecialSkillSuccess(int client, char[] skillName);
    native void OnSpecialSkillFail(int client, char[] skillName, char[] reason);
    native void GetPlayerSkillName(int client, char[] skillName, int size);
    native int RegisterRageSkill(char[] skillName, int type);
    native int GetPlayerClassName(int client, char[] className, int size);
#endif
/****************************************************/

public Plugin myinfo =
{
    name = "[Rage] Nightvision",
    author = "Pan Xiaohai & Mr. Zero, Yani",
    description = PLUGIN_DESCRIPTION,
    version = PLUGIN_VERSION,
    url = "https://steamcommunity.com/id/limeponypower/"
};

int g_iClassID = -1;
bool g_bRage;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if (GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
        return APLRes_SilentFailure;
    }

    RegPluginLibrary(PLUGIN_SKILL_NAME);
    MarkNativeAsOptional("OnSpecialSkillFail");
    MarkNativeAsOptional("OnSpecialSkillSuccess");
    MarkNativeAsOptional("GetPlayerSkillName");
    MarkNativeAsOptional("GetPlayerClassName");
    MarkNativeAsOptional("RegisterRageSkill");
    MarkNativeAsOptional("Rage_OnPluginState");

    return APLRes_Success;
}

public void OnPluginStart()
{
    RegConsoleCmd("sm_nightvision", Command_NightVision);
    RegConsoleCmd("sm_nv", Command_NightVision);
}

public void OnAllPluginsLoaded()
{
    g_bRage = LibraryExists("rage_survivor");
    if (g_bRage && g_iClassID == -1)
    {
        g_iClassID = RegisterRageSkill(PLUGIN_SKILL_NAME, 0);
    }
}

public void Rage_OnPluginState(char[] plugin, int state)
{
    if (StrEqual(plugin, "rage_survivor"))
    {
        if (state == 1 && g_iClassID == -1)
        {
            g_iClassID = RegisterRageSkill(PLUGIN_SKILL_NAME, 0);
        }
        else if (state == 0)
        {
            g_iClassID = -1;
        }
    }
}

public void OnClientPutInServer(int client)
{
    if (IsFakeClient(client))
        return;

    ClientCommand(client, "bind n sm_nightvision");
}

public int OnSpecialSkillUsed(int client, int skill, int type)
{
    char skillName[32];
    GetPlayerSkillName(client, skillName, sizeof(skillName));
    if (StrEqual(skillName, PLUGIN_SKILL_NAME))
    {
        ToggleNightVision(client);
        OnSpecialSkillSuccess(client, PLUGIN_SKILL_NAME);
        return 1;
    }
    return 0;
}

public Action Command_NightVision(int client, int args)
{
    if (!client || !IsClientInGame(client))
        return Plugin_Handled;

    char className[32];
    GetPlayerClassName(client, className, sizeof(className));
    if (!StrEqual(className, "Soldier", false))
    {
        PrintToChat(client, "\x04[Error]\x01 Nightvision is available to soldiers only");
        OnSpecialSkillFail(client, PLUGIN_SKILL_NAME, "not_soldier");
        return Plugin_Handled;
    }

    ToggleNightVision(client);
    OnSpecialSkillSuccess(client, PLUGIN_SKILL_NAME);
    return Plugin_Handled;
}

void ToggleNightVision(int client)
{
    int current = GetEntProp(client, Prop_Send, "m_bNightVisionOn");
    int next = current ? 0 : 1;
    SetEntProp(client, Prop_Send, "m_bNightVisionOn", next);
    PrintToChat(client, "\x04[Nightvision]\x01 %s", next ? "Enabled" : "Disabled");
}
