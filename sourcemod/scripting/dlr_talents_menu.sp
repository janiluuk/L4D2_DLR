#define PLUGIN_VERSION "0.3"
#include <sourcemod>
#include <extra_menu>

#pragma semicolon 1
#pragma newdecls required

bool g_bExtraMenuLoaded;
int g_iGuideMenuID;
int g_iClientMenuID[MAXPLAYERS + 1];
int g_iKitUsesLeft[MAXPLAYERS + 1];
bool g_bClientHoldingMenu[MAXPLAYERS + 1];
float g_fMenuHoldGraceUntil[MAXPLAYERS + 1];

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

    ResetAllClientData();
}

public void OnLibraryAdded(const char[] name)
{
    if (strcmp(name, "extra_menu") == 0)
    {
        g_bExtraMenuLoaded = true;
        g_iGuideMenuID = BuildGuideMenu();
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
        g_bClientHoldingMenu[client] = true;
        g_fMenuHoldGraceUntil[client] = GetGameTime() + 0.2;
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

    if (menu_id != g_iClientMenuID[client])
    {
        return;
    }

    switch (option)
    {
        case MENU_OPTION_GET_KIT:
        {
            HandleKitSelection(client);
            break;
        }
        case MENU_OPTION_SET_AWAY:
        {
            ClientCommand(client, "sm_afk");
            break;
        }
        case MENU_OPTION_CHANGE_CLASS:
        {
            ClientCommand(client, "sm_class");
            break;
        }
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
        g_iClientMenuID[i] = 0;
        g_iKitUsesLeft[i] = 1;
        g_bClientHoldingMenu[i] = false;
        g_fMenuHoldGraceUntil[i] = 0.0;
    }
}

public void OnClientPutInServer(int client)
{
    if (client > 0 && client <= MaxClients)
    {
        g_iKitUsesLeft[client] = 1;
        g_bClientHoldingMenu[client] = false;
        g_fMenuHoldGraceUntil[client] = 0.0;
    }
}

public void OnClientDisconnect(int client)
{
    if (client > 0 && client <= MaxClients)
    {
        CloseClientGameMenu(client);
        g_iKitUsesLeft[client] = 1;
    }
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

    if (g_iClientMenuID[client] != 0)
    {
        ExtraMenu_Delete(g_iClientMenuID[client]);
        g_iClientMenuID[client] = 0;
    }

    int menu_id = ExtraMenu_Create();

    ExtraMenu_AddEntry(menu_id, "GAME MENU:", MENU_ENTRY);
    ExtraMenu_AddEntry(menu_id, "Use W/S to move row and A/D to select", MENU_ENTRY);
    ExtraMenu_AddEntry(menu_id, " ", MENU_ENTRY);

    ExtraMenu_AddEntry(menu_id, "1. 3rd person mode: _OPT_", MENU_SELECT_LIST);
    ExtraMenu_AddOptions(menu_id, "Off|Melee Only|Always");

    char sBuffer[64];
    Format(sBuffer, sizeof(sBuffer), "2. Get Kit (%d left)", g_iKitUsesLeft[client]);
    ExtraMenu_AddEntry(menu_id, sBuffer, MENU_SELECT_LIST);
    ExtraMenu_AddOptions(menu_id, "Medic kit|Rambo kit|Counter-terrorist kit|Ninja kit");

    ExtraMenu_AddEntry(menu_id, "3. Change class", MENU_SELECT_ONLY);
    ExtraMenu_AddEntry(menu_id, "4. Set yourself away", MENU_SELECT_ONLY);
    ExtraMenu_AddEntry(menu_id, "5. Select team", MENU_SELECT_ONLY);
    ExtraMenu_AddEntry(menu_id, "6. Change character", MENU_SELECT_ONOFF);
    ExtraMenu_AddEntry(menu_id, "7. See your ranking", MENU_SELECT_ONLY);

    ExtraMenu_AddEntry(menu_id, " ", MENU_ENTRY);
    ExtraMenu_AddEntry(menu_id, "MATCH VOTES:", MENU_ENTRY);
    ExtraMenu_AddEntry(menu_id, "Use W/S to move row and A/D to select", MENU_ENTRY);
    ExtraMenu_AddEntry(menu_id, "8. Vote for gamemode", MENU_SELECT_LIST);
    ExtraMenu_AddOptions(menu_id, "Off|Escort run|Deathmatch|Race Jockey");
    ExtraMenu_AddEntry(menu_id, "9. Vote for custom map", MENU_SELECT_ADD, false, 250, 10, 100, 300);

    ExtraMenu_NewPage(menu_id);

    ExtraMenu_AddEntry(menu_id, "GAME OPTIONS:", MENU_ENTRY);
    ExtraMenu_AddEntry(menu_id, "Use W/S to move row and A/D to select", MENU_ENTRY);
    ExtraMenu_AddEntry(menu_id, " ", MENU_ENTRY);
    ExtraMenu_AddEntry(menu_id, "1. Multiple Equipment Mode: _OPT_", MENU_SELECT_LIST);
    ExtraMenu_AddOptions(menu_id, "Off|Single Tap|Double tap");
    ExtraMenu_AddEntry(menu_id, "2. HUD: _OPT_", MENU_SELECT_ONOFF);
    ExtraMenu_AddEntry(menu_id, "3. Music player: _OPT_", MENU_SELECT_ONOFF);
    ExtraMenu_AddEntry(menu_id, "4. Music Volume: _OPT_", MENU_SELECT_LIST);
    ExtraMenu_AddOptions(menu_id, "□□□□□□□□□□|■□□□□□□□□□|■■□□□□□□□□|■■■□□□□□□□|■■■■□□□□□□|■■■■■□□□□□|■■■■■■□□□□|■■■■■■■□□□|■■■■■■■□□|■■■■■■■■■□|■■■■■■■■■■");
    ExtraMenu_AddEntry(menu_id, " ", MENU_ENTRY);

    g_iClientMenuID[client] = menu_id;

    return menu_id;
}

bool ExtraMenuAvailable()
{
    return LibraryExists("extra_menu");
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
    if (g_iKitUsesLeft[client] <= 0)
    {
        PrintToChat(client, "[DLR] You have already collected your kit.");
        RefreshClientMenu(client);
        return;
    }

    g_iKitUsesLeft[client]--;
    ClientCommand(client, "sm_kit");
    RefreshClientMenu(client);
}

void RefreshClientMenu(int client)
{
    if (!g_bExtraMenuLoaded || !g_bClientHoldingMenu[client])
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
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

void CloseClientGameMenu(int client)
{
    if (client <= 0 || client > MaxClients)
    {
        return;
    }

    if (g_iClientMenuID[client] != 0)
    {
        CancelClientMenu(client);

        if (ExtraMenuAvailable())
        {
            ExtraMenu_Delete(g_iClientMenuID[client]);
        }

        g_iClientMenuID[client] = 0;
    }

    g_bClientHoldingMenu[client] = false;
    g_fMenuHoldGraceUntil[client] = 0.0;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
    if (!IsValidClient(client) || IsFakeClient(client))
    {
        return Plugin_Continue;
    }

    if (!g_bClientHoldingMenu[client] || g_iClientMenuID[client] == 0)
    {
        return Plugin_Continue;
    }

    float gameTime = GetGameTime();

    if (buttons & IN_SPEED)
    {
        g_fMenuHoldGraceUntil[client] = gameTime + 0.1;
    }
    else if (gameTime > g_fMenuHoldGraceUntil[client])
    {
        CloseClientGameMenu(client);
    }

    return Plugin_Continue;
}
