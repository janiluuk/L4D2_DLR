
#define PLUGIN_VERSION "0.3"
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
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
bool g_bExtraMenuLoaded = false;
bool g_bMenuHeld[MAXPLAYERS + 1];

enum ThirdPersonMode
{
    TP_Off = 0,
    TP_MeleeOnly,
    TP_Always
};

ThirdPersonMode g_ThirdPersonMode[MAXPLAYERS + 1];
bool g_ThirdPersonActive[MAXPLAYERS + 1];
Handle g_hThirdPersonCookie = INVALID_HANDLE;

ConVar g_hCvarMPGameMode;
ConVar g_hGameModeCvars[GAMEMODE_OPTION_COUNT];

enum RageMenuOption
{
    Menu_GetKit = 0,
    Menu_SetAway,
    Menu_SelectTeam,
    Menu_ChangeClass,
    Menu_ViewRank,
    Menu_VoteCustomMap,
    Menu_VoteGameMode,
    Menu_ThirdPerson,
    Menu_MultiEquip,
    Menu_HudToggle,
    Menu_MusicToggle,
    Menu_MusicVolume,
    Menu_ChangeCharacter,
    Menu_SpawnItems,
    Menu_Reload,
    Menu_ManageSkills,
    Menu_ManagePerks,
    Menu_ApplyEffect,
    Menu_DebugMode,
    Menu_HaltGame,
    Menu_InfectedSpawn,
    Menu_GodMode,
    Menu_RemoveWeapons,
    Menu_GameSpeed,
    Menu_Guide
};

void AddGameModeOptions(int menu_id);
void TrackSelectableEntry(EXTRA_MENU_TYPE type);
void RefreshGuideLibraryStatus();
bool TryShowGuideMenu(int client);
bool DisplayRageMenu(int client, bool showHint);
bool HasRageMenuAccess(int client);
void ApplyThirdPersonMode(int client);
void PersistThirdPersonMode(int client);
bool IsMeleeWeapon(int weapon);

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
    RegConsoleCmd("+rage_menu", CmdRageMenuHoldStart, "Hold to open Rage menu");
    RegConsoleCmd("-rage_menu", CmdRageMenuHoldEnd, "Release to close Rage menu");
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);

    g_hCvarMPGameMode = FindConVar("mp_gamemode");

    for (int i = 0; i < GAMEMODE_OPTION_COUNT; i++)
    {
        g_hGameModeCvars[i] = CreateConVar(g_sGameModeCvarNames[i], g_sGameModeDefaults[i], g_sGameModeDescriptions[i], FCVAR_NONE);
    }

    g_hThirdPersonCookie = RegClientCookie("rage_tp_mode", "Rage third person preference", CookieAccess_Public);

    g_bExtraMenuLoaded = LibraryExists("extra_menu");
    if (g_bExtraMenuLoaded)
    {
        OnLibraryAdded("extra_menu");
    }

    RefreshGuideLibraryStatus();
}

public void OnAllPluginsLoaded()
{
    RefreshGuideLibraryStatus();
}

public void OnClientPutInServer(int client)
{
    g_bMenuHeld[client] = false;
    g_ThirdPersonActive[client] = false;
    g_ThirdPersonMode[client] = TP_Off;
    SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
}

public void OnClientDisconnect(int client)
{
    g_bMenuHeld[client] = false;
    g_ThirdPersonActive[client] = false;
    g_ThirdPersonMode[client] = TP_Off;
}

public void OnClientCookiesCached(int client)
{
    if (g_hThirdPersonCookie == INVALID_HANDLE || !IsClientInGame(client))
    {
        return;
    }

    char buffer[8];
    GetClientCookie(client, g_hThirdPersonCookie, buffer, sizeof(buffer));
    if (buffer[0] != '\0')
    {
        g_ThirdPersonMode[client] = view_as<ThirdPersonMode>(StringToInt(buffer));
    }

    ApplyThirdPersonMode(client);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client <= 0 || !IsClientInGame(client))
    {
        return;
    }

    ApplyThirdPersonMode(client);
}

public Action OnWeaponSwitchPost(int client, int weapon)
{
    if (client <= 0 || !IsClientInGame(client))
    {
        return Plugin_Continue;
    }

    ApplyThirdPersonMode(client);
    return Plugin_Continue;
}

public void OnLibraryAdded(const char[] name)
{
    if (strcmp(name, "extra_menu") == 0)
    {
        g_bExtraMenuLoaded = true;
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
        g_bExtraMenuLoaded = false;
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
    DisplayRageMenu(client, true);
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

Action CmdRageMenuHoldStart(int client, int args)
{
    if (client <= 0 || !IsClientInGame(client))
    {
        return Plugin_Handled;
    }

    if (g_bMenuHeld[client])
    {
        return Plugin_Handled;
    }

    if (DisplayRageMenu(client, false))
    {
        g_bMenuHeld[client] = true;
    }

    return Plugin_Handled;
}

Action CmdRageMenuHoldEnd(int client, int args)
{
    if (client <= 0 || !IsClientInGame(client))
    {
        return Plugin_Handled;
    }

    if (g_bMenuHeld[client])
    {
        CancelClientMenu(client, true);
        g_bMenuHeld[client] = false;
    }

    return Plugin_Handled;
}

public void RageMenu_OnSelect(int client, int menu_id, int option, int value)
{
    if (menu_id == g_iMenuID)
    {
        // Option indexes are 0-based, matching the order entries are added.

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
            case Menu_GetKit:
            {
                PrintHintText(client, "Kit presets are not available yet.");
            }
            case Menu_SetAway:
            {
                PrintHintText(client, "Away mode is not available here.");
            }
            case Menu_SelectTeam:
            {
                PrintHintText(client, "Team selection is not available in this menu.");
            }
            case Menu_ChangeClass:
            {
                ClientCommand(client, "sm_class");
            }
            case Menu_ViewRank:
            {
                PrintHintText(client, "Ranking view is not available.");
            }
            case Menu_VoteCustomMap:
            {
                PrintHintText(client, "Custom map voting is not configured.");
            }
            case Menu_VoteGameMode:
            {
                ChangeGameModeByIndex(client, value);
            }
            case Menu_ThirdPerson:
            {
                if (value < 0 || value > 2)
                {
                    PrintHintText(client, "Invalid camera selection.");
                    return;
                }

                ThirdPersonMode newMode = view_as<ThirdPersonMode>(value);
                g_ThirdPersonMode[client] = newMode;
                PersistThirdPersonMode(client);
                ApplyThirdPersonMode(client);
                PrintHintText(client, "Camera mode set to %s.", (newMode == TP_Always) ? "Always" : (newMode == TP_MeleeOnly) ? "Melee only" : "Off");
            }
            case Menu_MultiEquip:
            {
                PrintHintText(client, "Multiple equipment mode is not configured.");
            }
            case Menu_HudToggle:
            {
                PrintHintText(client, "HUD toggle is not configured.");
            }
            case Menu_MusicToggle:
            {
                if (value == 0)
                {
                    FakeClientCommand(client, "sm_music_pause");
                    PrintHintText(client, "Music paused.");
                }
                else
                {
                    FakeClientCommand(client, "sm_music_play");
                    FakeClientCommand(client, "sm_music"); // open menu for quick control
                    PrintHintText(client, "Music playing. Use menu to change track.");
                }
            }
            case Menu_MusicVolume:
            {
                // Value from ExtraMenu list index (0-10). Clamp defensively.
                int vol = value;
                if (vol < 0)
                {
                    vol = 0;
                }
                else if (vol > 10)
                {
                    vol = 10;
                }

                FakeClientCommand(client, "sm_music_volume %d", vol);
                PrintHintText(client, "Music volume set to %d%%", vol * 10);
            }
            case Menu_ChangeCharacter:
            {
                PrintHintText(client, "Character change is not configured.");
            }
            case Menu_SpawnItems:
            {
                PrintHintText(client, "Item spawning is not available.");
            }
            case Menu_Reload:
            {
                PrintHintText(client, "Reload options are not available.");
            }
            case Menu_ManageSkills:
            {
                PrintHintText(client, "Skill management is not available.");
            }
            case Menu_ManagePerks:
            {
                PrintHintText(client, "Perk management is not available.");
            }
            case Menu_ApplyEffect:
            {
                PrintHintText(client, "Apply-effect option is not available.");
            }
            case Menu_DebugMode:
            {
                PrintHintText(client, "Debug mode toggle is not wired here.");
            }
            case Menu_HaltGame:
            {
                PrintHintText(client, "Halt game is not available.");
            }
            case Menu_InfectedSpawn:
            {
                PrintHintText(client, "Infected spawn toggle is not available.");
            }
            case Menu_GodMode:
            {
                PrintHintText(client, "God mode toggle is not available.");
            }
            case Menu_RemoveWeapons:
            {
                PrintHintText(client, "Remove weapons option is not available.");
            }
            case Menu_GameSpeed:
            {
                PrintHintText(client, "Game speed control is not available.");
            }
            case Menu_Guide:
            {
                if (!TryShowGuideMenu(client))
                {
                    PrintToChat(client, "[Rage] Tutorial plugin is not available right now.");
                }
            }
            default:
            {
                PrintHintText(client, "This menu option is not configured.");
            }
        }
    }
}

public void ExtraMenu_OnSelect(int client, int menu_id, int option, int value)
{
    RageMenu_OnSelect(client, menu_id, option, value);
}

public void TrackSelectableEntry(EXTRA_MENU_TYPE type)
{
    if (type != MENU_ENTRY)
    {
        g_iSelectableEntryCount++;
    }
}

public void RefreshGuideLibraryStatus()
{
    g_bGuideNativeAvailable = (GetFeatureStatus(FeatureType_Native, "RageGuide_ShowMainMenu") == FeatureStatus_Available);
}

public bool TryShowGuideMenu(int client)
{
    if (!g_bGuideNativeAvailable || client <= 0 || !IsClientInGame(client))
    {
        return false;
    }

    RageGuide_ShowMainMenu(client);
    return true;
}

public void AddGameModeOptions(int menu_id)
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

public bool HasRageMenuAccess(int client)
{
    return client > 0 && IsClientInGame(client) && CheckCommandAccess(client, "sm_rage", ADMFLAG_ROOT);
}

public bool DisplayRageMenu(int client, bool showHint)
{
    if (!HasRageMenuAccess(client))
    {
        PrintToChat(client, "[Rage] You do not have access to this menu.");
        return false;
    }

    if (!g_bExtraMenuLoaded || g_iMenuID == 0)
    {
        PrintToChat(client, "[Rage] Menu system is not ready yet.");
        return false;
    }

    if (showHint)
    {
        PrintHintText(client, "Hold ALT (bind \"+rage_menu\") and use W/S/A/D to navigate.");
    }

    ExtraMenu_Display(client, g_iMenuID, MENU_TIME_FOREVER);
    return true;
}

public bool IsMeleeWeapon(int weapon)
{
    if (weapon <= 0 || !IsValidEntity(weapon))
    {
        return false;
    }

    char cls[64];
    GetEntityClassname(weapon, cls, sizeof(cls));
    return StrContains(cls, "melee", false) != -1 || StrEqual(cls, "weapon_chainsaw", false);
}

public void PersistThirdPersonMode(int client)
{
    if (g_hThirdPersonCookie == INVALID_HANDLE || IsFakeClient(client))
    {
        return;
    }

    char buffer[8];
    IntToString(view_as<int>(g_ThirdPersonMode[client]), buffer, sizeof(buffer));
    SetClientCookie(client, g_hThirdPersonCookie, buffer);
}

public void ApplyThirdPersonMode(int client)
{
    if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
    {
        return;
    }

    bool shouldThird = false;
    switch (g_ThirdPersonMode[client])
    {
        case TP_MeleeOnly:
        {
            int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
            shouldThird = IsMeleeWeapon(weapon);
        }
        case TP_Always:
        {
            shouldThird = true;
        }
    }

    if (shouldThird == g_ThirdPersonActive[client])
    {
        return;
    }

    g_ThirdPersonActive[client] = shouldThird;

    if (shouldThird)
    {
        ClientCommand(client, "thirdpersonshoulder");
    }
    else
    {
        ClientCommand(client, "firstperson");
    }
}
