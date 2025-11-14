#define PLUGIN_VERSION "0.3"
#include <sourcemod>
#include <extra_menu>

#if !defined IN_WALK
#define IN_WALK (1<<18)
#endif
#if !defined IN_ALT1
#define IN_ALT1 (1<<13)
#endif

native bool DLR_Music_IsPlaying(int client);
native bool DLR_Music_GetCurrentTrack(int client, char[] buffer, int maxlen);
native float DLR_Music_GetPlaybackTime(int client);

const float MENU_OPEN_GRACE = 0.2;
const float MENU_RELEASE_GRACE = 0.1;

#pragma semicolon 1
#pragma newdecls required

bool g_bExtraMenuLoaded;
bool g_bMusicLibraryAvailable;
int g_iGuideMenuID;
ConVar g_hHudEnabledCvar;

enum struct ClientMenuState
{
    int menuId;
    int kitUsesLeft;
    bool holdingMenu;
    float graceEndsAt;
}

ClientMenuState g_ClientMenu[MAXPLAYERS + 1];

bool IsValidClient(int client);
bool IsValidClientIndex(int client);

public Plugin myinfo =
{
    name = "[DLR] Game Menu",
    author = "Yani",
    description = "Contains guide / game control menus for DLR",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnPluginStart()
{
    RegAdminCmd("sm_dlr", CmdDLRMenu, ADMFLAG_ROOT);
    RegAdminCmd("sm_guide", CmdDLRGuideMenu, ADMFLAG_ROOT);

    MarkNativeAsOptional("DLR_Music_IsPlaying");
    MarkNativeAsOptional("DLR_Music_GetCurrentTrack");
    MarkNativeAsOptional("DLR_Music_GetPlaybackTime");

    g_bExtraMenuLoaded = LibraryExists("extra_menu");
    g_bMusicLibraryAvailable = LibraryExists("dlr_music");
    g_hHudEnabledCvar = FindConVar("l4d2_scripted_hud_enable");

    if (g_bExtraMenuLoaded)
    {
        g_iGuideMenuID = BuildGuideMenu();
    }

    ResetAllClientData();
}

public void OnLibraryAdded(const char[] name)
{
    if (strcmp(name, "extra_menu") == 0)
    {
        g_bExtraMenuLoaded = true;
        if (g_iGuideMenuID == 0)
        {
            g_iGuideMenuID = BuildGuideMenu();
        }
    }
    else if (strcmp(name, "dlr_music") == 0)
    {
        g_bMusicLibraryAvailable = true;
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if (strcmp(name, "extra_menu") == 0)
    {
        DeleteGuideMenu();
        DeleteAllClientMenus();
        g_bExtraMenuLoaded = false;
    }
    else if (strcmp(name, "dlr_music") == 0)
    {
        g_bMusicLibraryAvailable = false;
    }
}

public void OnPluginEnd()
{
    DeleteGuideMenu();
    DeleteAllClientMenus();
}

Action CmdDLRMenu(int client, int args)
{
    if (!IsValidClient(client) || !g_bExtraMenuLoaded)
    {
        return Plugin_Handled;
    }

    int menu_id = BuildGameMenu(client);
    if (menu_id)
    {
        g_ClientMenu[client].holdingMenu = true;
        g_ClientMenu[client].graceEndsAt = GetGameTime() + MENU_OPEN_GRACE;
        PrintHintText(client, "Use W/S to move and A/D to select options.");
        ExtraMenu_Display(client, menu_id, MENU_TIME_FOREVER);
    }

    return Plugin_Handled;
}

Action CmdDLRGuideMenu(int client, int args)
{
    if (!IsValidClient(client) || !g_bExtraMenuLoaded || g_iGuideMenuID == 0)
    {
        return Plugin_Handled;
    }

    PrintHintText(client, "Use W/S to move and A/D to select options.");
    ExtraMenu_Display(client, g_iGuideMenuID, MENU_TIME_FOREVER);

    return Plugin_Handled;
}

public void ExtraMenu_OnSelect(int client, int menu_id, int option, int value)
{
    if (!IsValidClient(client))
    {
        return;
    }

    if (menu_id == g_iGuideMenuID)
    {
        return;
    }

    if (menu_id != g_ClientMenu[client].menuId)
    {
        return;
    }

    if (option == MENU_OPTION_GET_KIT)
    {
        HandleKitSelection(client);
    }
    else if (option == MENU_OPTION_SET_AWAY)
    {
        ClientCommand(client, "sm_afk");
    }
    else if (option == MENU_OPTION_CHANGE_CLASS)
    {
        ClientCommand(client, "sm_class");
    }
    else if (option == MENU_OPTION_HUD)
    {
        HandleHudSelection(client, value);
    }
}

public void DLRGuideMenu_OnSelect(int client, int menu_id, int option, int value)
{
    if (menu_id == g_iGuideMenuID)
    {
        PrintToChatAll("SELECTED %N Option: %d Value: %d", client, option, value);

        switch (option)
        {
            // foobar
        }
    }
}

enum MenuOptions
{
    MENU_OPTION_3RD_PERSON,
    MENU_OPTION_GET_KIT,
    MENU_OPTION_CHANGE_CLASS,
    MENU_OPTION_SET_AWAY,
    MENU_OPTION_SELECT_TEAM,
    MENU_OPTION_CHANGE_CHARACTER,
    MENU_OPTION_SEE_RANKING,
    MENU_OPTION_VOTE_GAMEMODE,
    MENU_OPTION_VOTE_CUSTOM_MAP,
    MENU_OPTION_MULTIPLE_EQUIPMENT,
    MENU_OPTION_HUD,
    MENU_OPTION_MUSIC_PLAYER,
    MENU_OPTION_MUSIC_VOLUME
};

void ResetAllClientData()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        ResetClientState(i);
    }
}

public void OnClientPutInServer(int client)
{
    ResetClientState(client);
}

public void OnClientDisconnect(int client)
{
    if (!IsValidClientIndex(client))
    {
        return;
    }

    ResetClientState(client);
}

int BuildGuideMenu()
{
    int guide_menu_id = ExtraMenu_Create();

    ExtraMenu_AddEntry(guide_menu_id, "DLR GUIDE:", MENU_ENTRY);
    ExtraMenu_AddEntry(guide_menu_id, "Use W/S to move row and A/D to select", MENU_ENTRY);
    ExtraMenu_AddEntry(guide_menu_id, "!skill triggers your class ability", MENU_ENTRY);
    ExtraMenu_AddEntry(guide_menu_id, "Soldier: aim and !skill for an airstrike", MENU_ENTRY);
    ExtraMenu_AddEntry(guide_menu_id, "Commando: build rage then !skill to berserk", MENU_ENTRY);
    ExtraMenu_AddEntry(guide_menu_id, "Engineer: !skill opens a turret menu", MENU_ENTRY);
    ExtraMenu_AddEntry(guide_menu_id, " ", MENU_ENTRY);
    ExtraMenu_AddEntry(guide_menu_id, "1. What is it", MENU_ENTRY, false, 250, 10, 100, 300);
    ExtraMenu_AddEntry(guide_menu_id, "2. Features", MENU_SELECT_LIST);
    ExtraMenu_AddOptions(guide_menu_id, "Common|Infected|Survivors");
    ExtraMenu_AddEntry(guide_menu_id, "3. How to", MENU_SELECT_LIST);
    ExtraMenu_AddOptions(guide_menu_id, "Missiles|Turrets|Special skills");
    ExtraMenu_AddEntry(guide_menu_id, "4. Gameplay Tips", MENU_SELECT_ONLY);
    ExtraMenu_AddEntry(guide_menu_id, "5. Survivor classes", MENU_SELECT_ONLY);
    ExtraMenu_AddEntry(guide_menu_id, "6. Custom game modes", MENU_SELECT_ONLY);
    ExtraMenu_AddEntry(guide_menu_id, "7. Add DLR servers to your serverlist", MENU_SELECT_ONLY);
    ExtraMenu_NewPage(guide_menu_id);

    return guide_menu_id;
}

int BuildGameMenu(int client)
{
    if (!g_bExtraMenuLoaded)
    {
        return 0;
    }

    if (g_ClientMenu[client].menuId != 0)
    {
        ExtraMenu_Delete(g_ClientMenu[client].menuId);
        g_ClientMenu[client].menuId = 0;
    }

    int menu_id = ExtraMenu_Create();

    AddGameMenuHeader(menu_id, client);
    AddPlayerActionsSection(menu_id, client);
    AddVotingSection(menu_id);

    ExtraMenu_NewPage(menu_id);

    AddOptionsPage(menu_id, client);

    g_ClientMenu[client].menuId = menu_id;

    return menu_id;
}

void AddGameMenuHeader(int menu_id, int client)
{
    ExtraMenu_AddEntry(menu_id, "GAME MENU:", MENU_ENTRY);
    ExtraMenu_AddEntry(menu_id, "Use W/S to move row and A/D to select", MENU_ENTRY);
    AppendTrackHeader(menu_id, client);
    ExtraMenu_AddEntry(menu_id, " ", MENU_ENTRY);
}

void AddPlayerActionsSection(int menu_id, int client)
{
    ExtraMenu_AddEntry(menu_id, "1. 3rd person mode: _OPT_", MENU_SELECT_LIST);
    ExtraMenu_AddOptions(menu_id, "Off|Melee Only|Always");

    char kitLine[64];
    Format(kitLine, sizeof(kitLine), "2. Get Kit (%d left)", g_ClientMenu[client].kitUsesLeft);
    ExtraMenu_AddEntry(menu_id, kitLine, MENU_SELECT_LIST);
    ExtraMenu_AddOptions(menu_id, "Medic kit|Rambo kit|Counter-terrorist kit|Ninja kit");

    ExtraMenu_AddEntry(menu_id, "3. Change class", MENU_SELECT_ONLY);
    ExtraMenu_AddEntry(menu_id, "4. Set yourself away", MENU_SELECT_ONLY);
    ExtraMenu_AddEntry(menu_id, "5. Select team", MENU_SELECT_ONLY);
    ExtraMenu_AddEntry(menu_id, "6. Change character", MENU_SELECT_ONOFF);
    ExtraMenu_AddEntry(menu_id, "7. See your ranking", MENU_SELECT_ONLY);

    ExtraMenu_AddEntry(menu_id, " ", MENU_ENTRY);
}

void AddVotingSection(int menu_id)
{
    ExtraMenu_AddEntry(menu_id, "MATCH VOTES:", MENU_ENTRY);
    ExtraMenu_AddEntry(menu_id, "Use W/S to move row and A/D to select", MENU_ENTRY);
    ExtraMenu_AddEntry(menu_id, "8. Vote for gamemode", MENU_SELECT_LIST);
    ExtraMenu_AddOptions(menu_id, "Off|Escort run|Deathmatch|Race Jockey");
    ExtraMenu_AddEntry(menu_id, "9. Vote for custom map", MENU_SELECT_ADD, false, 250, 10, 100, 300);
}

void AddOptionsPage(int menu_id, int client)
{
    ExtraMenu_AddEntry(menu_id, "GAME OPTIONS:", MENU_ENTRY);
    ExtraMenu_AddEntry(menu_id, "Use W/S to move row and A/D to select", MENU_ENTRY);
    AppendTrackHeader(menu_id, client);
    ExtraMenu_AddEntry(menu_id, " ", MENU_ENTRY);
    ExtraMenu_AddEntry(menu_id, "1. Multiple Equipment Mode: _OPT_", MENU_SELECT_LIST);
    ExtraMenu_AddOptions(menu_id, "Off|Single Tap|Double tap");
    ExtraMenu_AddEntry(menu_id, "2. HUD: _OPT_", MENU_SELECT_ONOFF, false, GetHudOptionDefault());
    ExtraMenu_AddEntry(menu_id, "3. Music player: _OPT_", MENU_SELECT_ONOFF);
    ExtraMenu_AddEntry(menu_id, "4. Music Volume: _OPT_", MENU_SELECT_LIST);
    ExtraMenu_AddOptions(menu_id, "□□□□□□□□□□|■□□□□□□□□□|■■□□□□□□□□|■■■□□□□□□□|■■■■□□□□□□|■■■■■□□□□□|■■■■■■□□□□|■■■■■■■□□□|■■■■■■■■□□|■■■■■■■■■□|■■■■■■■■■■");
    ExtraMenu_AddEntry(menu_id, " ", MENU_ENTRY);
}

bool ExtraMenuAvailable()
{
    return LibraryExists("extra_menu");
}

void ResetClientState(int client)
{
    if (!IsValidClientIndex(client))
    {
        return;
    }

    CloseClientGameMenu(client);
    g_ClientMenu[client].kitUsesLeft = 1;
}

void DeleteGuideMenu()
{
    if (g_iGuideMenuID != 0 && ExtraMenuAvailable())
    {
        ExtraMenu_Delete(g_iGuideMenuID);
        g_iGuideMenuID = 0;
    }
    else if (g_iGuideMenuID != 0)
    {
        g_iGuideMenuID = 0;
    }
}

void DeleteAllClientMenus()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        CloseClientGameMenu(i);
    }
}

void HandleKitSelection(int client)
{
    if (g_ClientMenu[client].kitUsesLeft <= 0)
    {
        PrintToChat(client, "[DLR] You have already collected your kit.");
        RefreshClientMenu(client);
        return;
    }

    g_ClientMenu[client].kitUsesLeft--;
    ClientCommand(client, "sm_kit");
    RefreshClientMenu(client);
}

void RefreshClientMenu(int client)
{
    if (!g_bExtraMenuLoaded || !g_ClientMenu[client].holdingMenu)
    {
        return;
    }

    int menu_id = BuildGameMenu(client);
    if (menu_id != 0)
    {
        ExtraMenu_Display(client, menu_id, MENU_TIME_FOREVER);
    }
}

bool IsValidClient(int client)
{
    return IsValidClientIndex(client) && IsClientInGame(client);
}

bool IsValidClientIndex(int client)
{
    return (client > 0 && client <= MaxClients);
}

void CloseClientGameMenu(int client)
{
    if (!IsValidClientIndex(client))
    {
        return;
    }

    if (g_ClientMenu[client].menuId != 0)
    {
        if (IsClientInGame(client))
        {
            CancelClientMenu(client);
        }

        if (ExtraMenuAvailable())
        {
            ExtraMenu_Delete(g_ClientMenu[client].menuId);
        }

        g_ClientMenu[client].menuId = 0;
    }

    g_ClientMenu[client].holdingMenu = false;
    g_ClientMenu[client].graceEndsAt = 0.0;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
    if (!IsValidClient(client) || IsFakeClient(client))
    {
        return Plugin_Continue;
    }

    if (!g_ClientMenu[client].holdingMenu || g_ClientMenu[client].menuId == 0)
    {
        return Plugin_Continue;
    }

    float gameTime = GetGameTime();

    if (buttons & (IN_SPEED | IN_WALK | IN_ALT1))
    {
        g_ClientMenu[client].graceEndsAt = gameTime + MENU_RELEASE_GRACE;
    }
    else if (gameTime > g_ClientMenu[client].graceEndsAt)
    {
        CloseClientGameMenu(client);
    }

    return Plugin_Continue;
}

void AppendTrackHeader(int menu_id, int client)
{
    char sLine[128];

    if (!g_bMusicLibraryAvailable)
    {
        ExtraMenu_AddEntry(menu_id, "♫ Music player unavailable", MENU_ENTRY);
        return;
    }

    char sTrack[96];
    bool hasTrack = DLR_Music_GetCurrentTrack(client, sTrack, sizeof(sTrack));

    if (!hasTrack || sTrack[0] == '\0')
    {
        strcopy(sLine, sizeof(sLine), "♫ Music: Not playing");
    }
    else if (DLR_Music_IsPlaying(client))
    {
        float elapsed = DLR_Music_GetPlaybackTime(client);
        if (elapsed < 0.0)
        {
            elapsed = 0.0;
        }

        int totalSeconds = RoundToFloor(elapsed);
        if (totalSeconds < 0)
        {
            totalSeconds = 0;
        }

        int minutes = totalSeconds / 60;
        int seconds = totalSeconds % 60;
        Format(sLine, sizeof(sLine), "♫ %s (%d:%02d)", sTrack, minutes, seconds);
    }
    else
    {
        Format(sLine, sizeof(sLine), "♫ %s (stopped)", sTrack);
    }

    ExtraMenu_AddEntry(menu_id, sLine, MENU_ENTRY);
}

int GetHudOptionDefault()
{
    if (g_hHudEnabledCvar == null)
    {
        return 0;
    }

    return g_hHudEnabledCvar.BoolValue ? 1 : 0;
}

void HandleHudSelection(int client, int value)
{
    if (g_hHudEnabledCvar == null)
    {
        PrintToChat(client, "[DLR] HUD controls are currently unavailable.");
        return;
    }

    bool enable = (value != 0);
    g_hHudEnabledCvar.SetBool(enable);

    if (enable)
    {
        PrintToChat(client, "[DLR] HUD enabled.");
    }
    else
    {
        PrintToChat(client, "[DLR] HUD disabled.");
    }
}
