#define PLUGIN_VERSION "0.1"
#include <sourcemod>
#include <extra_menu>

#pragma semicolon 1
#pragma newdecls required

bool g_bExtraMenuLoaded;
int g_iAdminMenuID;

public Plugin myinfo =
{
    name = "[Rage] Admin Menu",
    author = "Yani",
    description = "Provides admin specific menu options for Rage",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnPluginStart()
{
    RegAdminCmd("sm_adm", CmdRageAdminMenu, ADMFLAG_ROOT);
}

public void OnLibraryAdded(const char[] name)
{
    if (strcmp(name, "extra_menu") == 0)
    {
        g_bExtraMenuLoaded = true;
        BuildAdminMenu();
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if (strcmp(name, "extra_menu") == 0)
    {
        DeleteAdminMenu();
        g_bExtraMenuLoaded = false;
    }
}

public void OnPluginEnd()
{
    DeleteAdminMenu();
}

Action CmdRageAdminMenu(int client, int args)
{
    if (!IsValidClient(client) || !g_bExtraMenuLoaded || g_iAdminMenuID == 0)
    {
        return Plugin_Handled;
    }

    PrintHintText(client, "Use W/S to move and A/D to select options.");
    ExtraMenu_Display(client, g_iAdminMenuID, MENU_TIME_FOREVER);

    return Plugin_Handled;
}

public void ExtraMenu_OnSelect(int client, int menu_id, int option, int value)
{
    if (!IsValidClient(client) || menu_id != g_iAdminMenuID)
    {
        return;
    }

    // Placeholder for future admin actions.
}

void BuildAdminMenu()
{
    DeleteAdminMenu();

    g_iAdminMenuID = ExtraMenu_Create();

    ExtraMenu_AddEntry(g_iAdminMenuID, "ADMIN MENU:", MENU_ENTRY);
    ExtraMenu_AddEntry(g_iAdminMenuID, "Use W/S to move row and A/D to select", MENU_ENTRY);
    ExtraMenu_AddEntry(g_iAdminMenuID, " ", MENU_ENTRY);

    ExtraMenu_AddEntry(g_iAdminMenuID, "1. Spawn Items: _OPT_", MENU_SELECT_LIST);
    ExtraMenu_AddOptions(g_iAdminMenuID, "New cabinet|New weapon|Special Infected|Special tank");
    ExtraMenu_AddEntry(g_iAdminMenuID, "2. Reload _OPT_", MENU_SELECT_LIST);
    ExtraMenu_AddOptions(g_iAdminMenuID, "Map|Rage Plugins|All plugins|Restart server");
    ExtraMenu_AddEntry(g_iAdminMenuID, "3. Manage skills", MENU_SELECT_ONLY, true);
    ExtraMenu_AddEntry(g_iAdminMenuID, "4. Manage perks", MENU_SELECT_ONLY, true);
    ExtraMenu_AddEntry(g_iAdminMenuID, "5. Apply effect on player", MENU_SELECT_ONLY, true);

    ExtraMenu_AddEntry(g_iAdminMenuID, " ", MENU_ENTRY);
    ExtraMenu_AddEntry(g_iAdminMenuID, "DEBUG COMMANDS:", MENU_ENTRY);
    ExtraMenu_AddEntry(g_iAdminMenuID, "1. Debug mode: _OPT_", MENU_SELECT_LIST);
    ExtraMenu_AddOptions(g_iAdminMenuID, "Off|Log to file|Log to chat|Tracelog to chat");
    ExtraMenu_AddEntry(g_iAdminMenuID, "2. Halt game: _OPT_", MENU_SELECT_LIST);
    ExtraMenu_AddOptions(g_iAdminMenuID, "Off|Only survivors|All");
    ExtraMenu_AddEntry(g_iAdminMenuID, "3. Infected spawn: _OPT_", MENU_SELECT_ONOFF, false, 1);
    ExtraMenu_AddEntry(g_iAdminMenuID, "4. God mode: _OPT_", MENU_SELECT_ONOFF, false, 1);
    ExtraMenu_AddEntry(g_iAdminMenuID, "5. Remove weapons from map", MENU_SELECT_ONLY);
    ExtraMenu_AddEntry(g_iAdminMenuID, "6. Game speed: _OPT_", MENU_SELECT_LIST);
    ExtraMenu_AddOptions(g_iAdminMenuID, "□□□□□□□□□□|■□□□□□□□□□|■■□□□□□□□□|■■■□□□□□□□|■■■■□□□□□□|■■■■■□□□□□|■■■■■■□□□□|■■■■■■■□□□|■■■■■■■■□□|■■■■■■■■■□|■■■■■■■■■■");
    ExtraMenu_AddEntry(g_iAdminMenuID, " ", MENU_ENTRY);
}

void DeleteAdminMenu()
{
    if (g_iAdminMenuID != 0 && LibraryExists("extra_menu"))
    {
        ExtraMenu_Delete(g_iAdminMenuID);
        g_iAdminMenuID = 0;
    }
    else if (g_iAdminMenuID != 0)
    {
        g_iAdminMenuID = 0;
    }
}

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}
