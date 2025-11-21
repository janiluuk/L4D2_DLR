
#define PLUGIN_VERSION "0.3"
#include <sourcemod>
#include <extra_menu>
#include <rage_survivor_guide>

#define GAMEMODE_OPTION_COUNT 11

static const char g_sGameModeNames[GAMEMODE_OPTION_COUNT][] =
{
    "Versus",
    "Competitive",
    "Escort run",
    "Deathmatch",
    "Race Jockey",
    "Team Versus",
    "Scavenge",
    "Team Scavenge",
    "Survival",
    "Co-op",
    "Realism"
};

static const char g_sGameModeCvarNames[GAMEMODE_OPTION_COUNT][] =
{
    "rage_gamemode_versus",
    "rage_gamemode_competitive",
    "rage_gamemode_escort",
    "rage_gamemode_deathmatch",
    "rage_gamemode_racejockey",
    "rage_gamemode_teamversus",
    "rage_gamemode_scavenge",
    "rage_gamemode_teamscavenge",
    "rage_gamemode_survival",
    "rage_gamemode_coop",
    "rage_gamemode_realism"
};

static const char g_sGameModeDefaults[GAMEMODE_OPTION_COUNT][] =
{
    "versus",
    "rage_competitive",
    "rage_escortrun",
    "rage_deathmatch",
    "rage_racejockey",
    "teamversus",
    "scavenge",
    "teamscavenge",
    "survival",
    "coop",
    "realism"
};

static const char g_sGameModeDescriptions[GAMEMODE_OPTION_COUNT][] =
{
    "mp_gamemode value for standard Versus.",
    "mp_gamemode value for competitive Versus.",
    "mp_gamemode value for escort run mode.",
    "mp_gamemode value for deathmatch mode.",
    "mp_gamemode value for race jockey mode.",
    "mp_gamemode value for team-based Versus.",
    "mp_gamemode value for standard Scavenge.",
    "mp_gamemode value for team-based Scavenge.",
    "mp_gamemode value for Survival.",
    "mp_gamemode value for Co-op.",
    "mp_gamemode value for Realism."
};

#pragma semicolon 1
#pragma newdecls required

int g_iMenuID;
int g_iGuideOptionIndex = -1;
int g_iSelectableEntryCount = 0;
bool g_bGuideNativeAvailable = false;

ConVar g_hCvarMPGameMode;
ConVar g_hGameModeCvars[GAMEMODE_OPTION_COUNT];

void AddGameModeOptions(int menu_id);
void TrackSelectableEntry(EXTRA_MENU_TYPE type);
void RefreshGuideLibraryStatus();
bool TryShowGuideMenu(int client);

// ====================================================================================================
//					PLUGIN INFO
// ====================================================================================================
public Plugin myinfo =
{
    name = "[Rage] Game Menu",
    author = "Yani",
    description = "Contains guide / game control menus for Rage",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnPluginStart()
{
    RegAdminCmd("sm_rage", CmdRageMenu, ADMFLAG_ROOT);
    RegConsoleCmd("sm_guide", CmdRageGuideMenu, "Open the Rage tutorial guide");

    g_hCvarMPGameMode = FindConVar("mp_gamemode");

    for (int i = 0; i < GAMEMODE_OPTION_COUNT; i++)
    {
        g_hGameModeCvars[i] = CreateConVar(g_sGameModeCvarNames[i], g_sGameModeDefaults[i], g_sGameModeDescriptions[i], FCVAR_NONE);
    }

    RefreshGuideLibraryStatus();
}

public void OnAllPluginsLoaded()
{
    RefreshGuideLibraryStatus();
}

public void OnLibraryAdded(const char[] name)
{
    if (strcmp(name, "extra_menu") == 0)
    {
        bool buttons_nums = false;

        g_iSelectableEntryCount = 0;
        g_iGuideOptionIndex = -1;

        int menu_id;
        menu_id = ExtraMenu_Create();

        ExtraMenu_AddEntry(menu_id, "GAME MENU:", MENU_ENTRY);
        if (!buttons_nums)
            ExtraMenu_AddEntry(menu_id, "Use W/S to move row and A/D to select", MENU_ENTRY);
        ExtraMenu_AddEntry(menu_id, " ", MENU_ENTRY);
        ExtraMenu_AddEntry(menu_id, "1. Get Kit (1 left)", MENU_SELECT_LIST);
        TrackSelectableEntry(MENU_SELECT_LIST);
        ExtraMenu_AddOptions(menu_id, "Medic kit|Rambo kit|Counter-terrorist kit|Ninja kit");

        ExtraMenu_AddEntry(menu_id, "2. Set yourself away", MENU_SELECT_ONLY);
        TrackSelectableEntry(MENU_SELECT_ONLY);
        ExtraMenu_AddEntry(menu_id, "3. Select team", MENU_SELECT_ONLY);
        TrackSelectableEntry(MENU_SELECT_ONLY);
        ExtraMenu_AddEntry(menu_id, "4. Change class", MENU_SELECT_LIST);
        TrackSelectableEntry(MENU_SELECT_LIST);

        ExtraMenu_AddEntry(menu_id, "5. See your ranking", MENU_SELECT_ONLY);
        TrackSelectableEntry(MENU_SELECT_ONLY);
        ExtraMenu_AddEntry(menu_id, "6. Vote for custom map", MENU_SELECT_ADD, false, 250, 10, 100, 300);
        TrackSelectableEntry(MENU_SELECT_ADD);
        ExtraMenu_AddEntry(menu_id, "7. Vote for gamemode", MENU_SELECT_LIST);
        TrackSelectableEntry(MENU_SELECT_LIST);
        AddGameModeOptions(menu_id);
        ExtraMenu_NewPage(menu_id);

        ExtraMenu_AddEntry(menu_id, "GAME OPTIONS:", MENU_ENTRY);
        if (!buttons_nums)
            ExtraMenu_AddEntry(menu_id, "Use W/S to move row and A/D to select", MENU_ENTRY);
        ExtraMenu_AddEntry(menu_id, " ", MENU_ENTRY);
        ExtraMenu_AddEntry(menu_id, "1. 3rd person mode: _OPT_", MENU_SELECT_LIST);
        TrackSelectableEntry(MENU_SELECT_LIST);
        ExtraMenu_AddOptions(menu_id, "Off|Melee Only|Always");
        ExtraMenu_AddEntry(menu_id, "2. Multiple Equipment Mode: _OPT_", MENU_SELECT_LIST);
        TrackSelectableEntry(MENU_SELECT_LIST);
        ExtraMenu_AddOptions(menu_id, "Off|Single Tap|Double tap");
        ExtraMenu_AddEntry(menu_id, "3. HUD: _OPT_", MENU_SELECT_ONOFF);
        TrackSelectableEntry(MENU_SELECT_ONOFF);
        ExtraMenu_AddEntry(menu_id, "4. Music player: _OPT_", MENU_SELECT_ONOFF);
        TrackSelectableEntry(MENU_SELECT_ONOFF);
        ExtraMenu_AddEntry(menu_id, "5. Music Volume: _OPT_", MENU_SELECT_LIST);
        TrackSelectableEntry(MENU_SELECT_LIST);
        ExtraMenu_AddOptions(menu_id, "----------|#---------|##--------|###-------|####------|#####-----|######----|#######---|########--|#########-|##########");

        ExtraMenu_AddEntry(menu_id, "6. Change Character: _OPT_", MENU_SELECT_ONOFF);
        TrackSelectableEntry(MENU_SELECT_ONOFF);
        ExtraMenu_AddEntry(menu_id, " ", MENU_ENTRY);

        ExtraMenu_NewPage(menu_id);

        ExtraMenu_AddEntry(menu_id, "ADMIN MENU:", MENU_ENTRY);

        ExtraMenu_AddEntry(menu_id, "1. Spawn Items: _OPT_", MENU_SELECT_LIST);
        TrackSelectableEntry(MENU_SELECT_LIST);
        ExtraMenu_AddOptions(menu_id, "New cabinet|New weapon|Special Infected|Special tank");
        ExtraMenu_AddEntry(menu_id, "2. Reload _OPT_", MENU_SELECT_LIST);
        TrackSelectableEntry(MENU_SELECT_LIST);
        ExtraMenu_AddOptions(menu_id, "Map|Rage Plugins|All plugins|Restart server");
        ExtraMenu_AddEntry(menu_id, "3. Manage skills", MENU_SELECT_ONLY, true);
        TrackSelectableEntry(MENU_SELECT_ONLY);
        ExtraMenu_AddEntry(menu_id, "4. Manage perks", MENU_SELECT_ONLY, true);
        TrackSelectableEntry(MENU_SELECT_ONLY);
        ExtraMenu_AddEntry(menu_id, "5. Apply effect on player", MENU_SELECT_ONLY, true);
        TrackSelectableEntry(MENU_SELECT_ONLY);

        ExtraMenu_AddEntry(menu_id, " ", MENU_ENTRY);
        ExtraMenu_AddEntry(menu_id, "DEBUG COMMANDS:", MENU_ENTRY);
        ExtraMenu_AddEntry(menu_id, "1. Debug mode: _OPT_", MENU_SELECT_LIST);
        TrackSelectableEntry(MENU_SELECT_LIST);
        ExtraMenu_AddOptions(menu_id, "Off|Log to file|Log to chat|Tracelog to chat");
        ExtraMenu_AddEntry(menu_id, "2. Halt game: _OPT_", MENU_SELECT_LIST);
        TrackSelectableEntry(MENU_SELECT_LIST);
        ExtraMenu_AddOptions(menu_id, "Off|Only survivors|All");
        ExtraMenu_AddEntry(menu_id, "3. Infected spawn: _OPT_", MENU_SELECT_ONOFF, false, 1);
        TrackSelectableEntry(MENU_SELECT_ONOFF);
        ExtraMenu_AddEntry(menu_id, "4. God mode: _OPT_", MENU_SELECT_ONOFF, false, 1);
        TrackSelectableEntry(MENU_SELECT_ONOFF);
        ExtraMenu_AddEntry(menu_id, "5. Remove weapons from map", MENU_SELECT_ONLY);
        TrackSelectableEntry(MENU_SELECT_ONLY);
        ExtraMenu_AddEntry(menu_id, "6. Game speed: _OPT_", MENU_SELECT_LIST);
        TrackSelectableEntry(MENU_SELECT_LIST);
        ExtraMenu_AddOptions(menu_id, "----------|#---------|##--------|###-------|####------|#####-----|######----|#######---|########--|#########-|##########");

        g_iGuideOptionIndex = g_iSelectableEntryCount;
        ExtraMenu_AddEntry(menu_id, "Open Rage tutorial guide", MENU_SELECT_ONLY, true);
        TrackSelectableEntry(MENU_SELECT_ONLY);
        ExtraMenu_AddEntry(menu_id, " ", MENU_ENTRY);

        g_iMenuID = menu_id;
    }

    if (strcmp(name, "rage_survivor_guide") == 0)
    {
        RefreshGuideLibraryStatus();
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if (strcmp(name, "extra_menu") == 0)
    {
        OnPluginEnd();
    }

    if (strcmp(name, "rage_survivor_guide") == 0)
    {
        RefreshGuideLibraryStatus();
    }
}

public void OnPluginEnd()
{
    if (g_iMenuID != 0)
    {
        ExtraMenu_Delete(g_iMenuID);
        g_iMenuID = 0;
    }
}

Action CmdRageMenu(int client, int args)
{
    if (client <= 0 || !IsClientInGame(client))
    {
        PrintToServer("[Rage] This command can only be used in-game.");
        return Plugin_Handled;
    }

    PrintHintText(client, "Use W/S to move and A/D to select options.");
    ExtraMenu_Display(client, g_iMenuID, MENU_TIME_FOREVER);

    return Plugin_Handled;
}

Action CmdRageGuideMenu(int client, int args)
{
    if (client <= 0 || !IsClientInGame(client))
    {
        PrintToServer("[Rage] This command can only be used in-game.");
        return Plugin_Handled;
    }

    if (!TryShowGuideMenu(client))
    {
        PrintToChat(client, "[Rage] Tutorial plugin is not available right now.");
    }

    return Plugin_Handled;
}

public void RageMenu_OnSelect(int client, int menu_id, int option, int value)
{
    if (menu_id == g_iMenuID)
    {
        PrintToChatAll("SELECTED %N Option: %d Value: %d", client, option, value);

        if (option == g_iGuideOptionIndex && g_iGuideOptionIndex != -1)
        {
            if (!TryShowGuideMenu(client))
            {
                PrintToChat(client, "[Rage] Tutorial plugin is not available right now.");
            }
            return;
        }

        switch (option)
        {
            case 0: ClientCommand(client, "sm_godmode @me");
            case 1: ClientCommand(client, "sm_noclip @me");
            case 2: ClientCommand(client, "sm_beacon @me");
            case 3: PrintToChat(client, "Speed changed to %d", value);
            case 4: PrintToChat(client, "Difficulty to %d", value);
            case 5: PrintToChat(client, "Tester to %d", value);
            case 6: ChangeGameModeByIndex(client, value);
            case 7: PrintToChat(client, "Default value changed to %d", value);
            case 8: PrintToChat(client, "Close after use %d", value);
            case 9: PrintToChat(client, "Meter value %d", value);
            case 10, 11, 12: PrintToChat(client, "Second page option %d", option - 9);
        }
    }
}

public void ExtraMenu_OnSelect(int client, int menu_id, int option, int value)
{
    RageMenu_OnSelect(client, menu_id, option, value);
}

void TrackSelectableEntry(EXTRA_MENU_TYPE type)
{
    if (type != MENU_ENTRY)
    {
        g_iSelectableEntryCount++;
    }
}

void RefreshGuideLibraryStatus()
{
    g_bGuideNativeAvailable = (GetFeatureStatus(FeatureType_Native, "RageGuide_ShowMainMenu") == FeatureStatus_Available);
}

bool TryShowGuideMenu(int client)
{
    if (!g_bGuideNativeAvailable || client <= 0 || !IsClientInGame(client))
    {
        return false;
    }

    RageGuide_ShowMainMenu(client);
    return true;
}

void AddGameModeOptions(int menu_id)
{
    char options[512];
    options[0] = '\0';

    for (int i = 0; i < GAMEMODE_OPTION_COUNT; i++)
    {
        if (options[0] != '\0')
        {
            StrCat(options, sizeof(options), "|");
        }

        StrCat(options, sizeof(options), g_sGameModeNames[i]);
    }

    ExtraMenu_AddOptions(menu_id, options);
}

void ChangeGameModeByIndex(int client, int modeIndex)
{
    if (modeIndex < 0 || modeIndex >= GAMEMODE_OPTION_COUNT)
    {
        PrintToChat(client, "[Rage] Unknown game mode option.");
        return;
    }

    if (g_hCvarMPGameMode == null)
    {
        PrintToChat(client, "[Rage] Unable to change game mode right now.");
        return;
    }

    ConVar cvar = g_hGameModeCvars[modeIndex];
    if (cvar == null)
    {
        PrintToChat(client, "[Rage] Game mode option is not configured.");
        return;
    }

    char targetMode[64];
    cvar.GetString(targetMode, sizeof(targetMode));
    TrimString(targetMode);

    if (targetMode[0] == '\0')
    {
        PrintToChat(client, "[Rage] Game mode value is empty.");
        return;
    }

    char currentMode[64];
    g_hCvarMPGameMode.GetString(currentMode, sizeof(currentMode));

    if (StrEqual(currentMode, targetMode, false))
    {
        PrintToChat(client, "[Rage] %s is already active.", g_sGameModeNames[modeIndex]);
        return;
    }

    g_hCvarMPGameMode.SetString(targetMode);
    LogAction(client, -1, "\"%L\" changed game mode to \"%s\"", client, targetMode);
    ShowActivity2(client, "[Rage] ", "changed game mode to %s.", g_sGameModeNames[modeIndex]);
    PrintToChatAll("[Rage] %N switched the game mode to %s (\"%s\").", client, g_sGameModeNames[modeIndex], targetMode);
}
