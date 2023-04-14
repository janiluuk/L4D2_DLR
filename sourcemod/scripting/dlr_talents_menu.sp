#define PLUGIN_VERSION "0.3"
#include <sourcemod>
#include <extra_menu>

#pragma semicolon 1
#pragma newdecls required

int	g_iMenuID;
int	g_iGuideMenuID;

// ====================================================================================================
//					PLUGIN INFO
// ====================================================================================================
public Plugin myinfo =
{
	name		= "[DLR] Game Menu",
	author		= "Yani",
	description = "Contains guide / game control menus for DLR",
	version		= PLUGIN_VERSION,
	url			= ""

}

// ====================================================================================================
//					MAIN FUNCTIONS
// ====================================================================================================
public void
	OnPluginStart()
{
	RegAdminCmd("sm_dlr", CmdDLRMenu, ADMFLAG_ROOT);
	RegAdminCmd("sm_guide", CmdDLRGuideMenu, ADMFLAG_ROOT);
}

public void OnLibraryAdded(const char[] name)
{
	if (strcmp(name, "extra_menu") == 0)
	{
		// Menu movement type: False = W/A/S/D. True = 1/3/4/5
		bool buttons_nums = false;
		// bool buttons_nums = false;

		// Create a new main menu
		int	 menu_id;

		// if( buttons_nums )
		// menu_id = ExtraMenu_Create(false, "", true); // No back button, no translation, 1/2/3/4 type selection menu
		menu_id = ExtraMenu_Create();	 // W/A/S/D type selection menu

		// Add the entries
		ExtraMenu_AddEntry(menu_id, "GAME MENU:", MENU_ENTRY);
		if (!buttons_nums)
			ExtraMenu_AddEntry(menu_id, "Use W/S to move row and A/D to select", MENU_ENTRY);
		ExtraMenu_AddEntry(menu_id, " ", MENU_ENTRY);	
		 // Space to add blank entry
		ExtraMenu_AddEntry(menu_id, "1. Get Kit (1 left)", MENU_SELECT_LIST);
		ExtraMenu_AddOptions(menu_id, "Medic kit|Rambo kit|Counter-terrorist kit|Ninja kit");

		ExtraMenu_AddEntry(menu_id, "2. Set yourself away", MENU_SELECT_ONLY);
		ExtraMenu_AddEntry(menu_id, "3. Select team", MENU_SELECT_ONLY);
		ExtraMenu_AddEntry(menu_id, "4. Change class", MENU_SELECT_LIST);

		ExtraMenu_AddEntry(menu_id, "5. See your ranking", MENU_SELECT_ONLY);
		ExtraMenu_AddEntry(menu_id, "6. Vote for custom map", MENU_SELECT_ADD, false, 250, 10, 100, 300);
		ExtraMenu_AddEntry(menu_id, "7. Vote for gamemode", MENU_SELECT_LIST);
		ExtraMenu_AddOptions(menu_id, "Off|Escort run|Deathmatch|Race Jockey");
		ExtraMenu_NewPage(menu_id);	   // New Page

		ExtraMenu_AddEntry(menu_id, "GAME OPTIONS:", MENU_ENTRY);
		if (!buttons_nums)
			ExtraMenu_AddEntry(menu_id, "Use W/S to move row and A/D to select", MENU_ENTRY);
		ExtraMenu_AddEntry(menu_id, " ", MENU_ENTRY);	 // Space to add blank entry
		ExtraMenu_AddEntry(menu_id, "1. 3rd person mode: _OPT_", MENU_SELECT_LIST);
		ExtraMenu_AddOptions(menu_id, "Off|Melee Only|Always");
		ExtraMenu_AddEntry(menu_id, "2. Multiple Equipment Mode: _OPT_", MENU_SELECT_LIST);
		ExtraMenu_AddOptions(menu_id, "Off|Single Tap|Double tap");
		ExtraMenu_AddEntry(menu_id, "3. HUD: _OPT_", MENU_SELECT_ONOFF);
		ExtraMenu_AddEntry(menu_id, "4. Music player: _OPT_", MENU_SELECT_ONOFF);
		ExtraMenu_AddEntry(menu_id, "5. Music Volume: _OPT_", MENU_SELECT_LIST);
		ExtraMenu_AddOptions(menu_id, "□□□□□□□□□□|■□□□□□□□□□|■■□□□□□□□□|■■■□□□□□□□|■■■■□□□□□□|■■■■■□□□□□|■■■■■■□□□□|■■■■■■■□□□|■■■■■■■■□□|■■■■■■■■■□|■■■■■■■■■■");	  // Various selectable options

		ExtraMenu_AddEntry(menu_id, "6. Change Character: _OPT_", MENU_SELECT_ONOFF);
		ExtraMenu_AddEntry(menu_id, " ", MENU_ENTRY);

		ExtraMenu_NewPage(menu_id);	   // New Page

		ExtraMenu_AddEntry(menu_id, "ADMIN MENU:", MENU_ENTRY);
	
		ExtraMenu_AddEntry(menu_id, "2. Spawn Items: _OPT_", MENU_SELECT_LIST);
		ExtraMenu_AddOptions(menu_id, "New cabinet|New weapon|Special Infected|Special tank");
		ExtraMenu_AddEntry(menu_id, "3. Reload _OPT_", MENU_SELECT_LIST);
		ExtraMenu_AddOptions(menu_id, "Map|DLR Plugins|All plugins|Restart server");
		ExtraMenu_AddEntry(menu_id, "4. Manage skills", MENU_SELECT_ONLY, true);
		ExtraMenu_AddEntry(menu_id, "5. Manage perks", MENU_SELECT_ONLY, true);			ExtraMenu_AddEntry(menu_id, "5. Manage perks", MENU_SELECT_ONLY, true);
		ExtraMenu_AddEntry(menu_id, "6. Apply effect on player", MENU_SELECT_ONLY, true);			ExtraMenu_AddEntry(menu_id, "5. Manage perks", MENU_SELECT_ONLY, true);

		ExtraMenu_AddEntry(menu_id, " ", MENU_ENTRY);
		ExtraMenu_AddEntry(menu_id, "DEBUG COMMANDS:", MENU_ENTRY);
		ExtraMenu_AddEntry(menu_id, "1. Debug mode: _OPT_", MENU_SELECT_LIST);

		ExtraMenu_AddOptions(menu_id, "Off|Log to file|Log to chat|Tracelog to chat");
		ExtraMenu_AddEntry(menu_id, "2. Halt game: _OPT_", MENU_SELECT_LIST);
		ExtraMenu_AddOptions(menu_id, "Off|Only survivors|All");
		ExtraMenu_AddEntry(menu_id, "3. Infected spawn: _OPT_", MENU_SELECT_ONOFF, false, 1);
		ExtraMenu_AddEntry(menu_id, "4. God mode: _OPT_", MENU_SELECT_ONOFF, false, 1);

		ExtraMenu_AddEntry(menu_id, "5. Remove weapons from map", MENU_SELECT_ONLY);
		ExtraMenu_AddEntry(menu_id, "6. Game speed: _OPT_", MENU_SELECT_LIST);
		ExtraMenu_AddOptions(menu_id, "□□□□□□□□□□|■□□□□□□□□□|■■□□□□□□□□|■■■□□□□□□□|■■■■□□□□□□|■■■■■□□□□□|■■■■■■□□□□|■■■■■■■□□□|■■■■■■■■□□|■■■■■■■■■□|■■■■■■■■■■");	  // Various selectable options
		ExtraMenu_AddEntry(menu_id, " ", MENU_ENTRY);																												  // Space to add blank entry

		// Store menu ID to use later
		g_iMenuID = menu_id;

		//////////////////////////////////////////////////////////////////////////////////////
		// Create a new guide menu
		//////////////////////////////////////////////////////////////////////////////////////

		int guide_menu_id;

		guide_menu_id = ExtraMenu_Create();	   // W/A/S/D type selection menu

		// Guide entries
		ExtraMenu_AddEntry(guide_menu_id, "DLR GUIDE:", MENU_ENTRY);
		ExtraMenu_AddEntry(guide_menu_id, "Use W/S to move row and A/D to select", MENU_ENTRY);
		ExtraMenu_AddEntry(guide_menu_id, " ", MENU_ENTRY);	 // Space to add blank entry
		ExtraMenu_AddEntry(guide_menu_id, "1. What is it", MENU_ENTRY, false, 250, 10, 100, 300);
		ExtraMenu_AddEntry(guide_menu_id, "2. Features", MENU_SELECT_LIST);
		ExtraMenu_AddOptions(guide_menu_id, "Common|Infected|Survivors");
		ExtraMenu_AddEntry(guide_menu_id, "3. How to", MENU_SELECT_LIST);
		ExtraMenu_AddOptions(guide_menu_id, "Missiles|Turrets|Special skills");
		ExtraMenu_AddEntry(guide_menu_id, "4. Gameplay Tips", MENU_SELECT_ONLY);
		ExtraMenu_AddEntry(guide_menu_id, "5. Survivor classes", MENU_SELECT_ONLY);
		ExtraMenu_AddEntry(guide_menu_id, "6. Custom game modes", MENU_SELECT_ONLY);
		ExtraMenu_AddEntry(guide_menu_id, "7. Add DLR servers to your serverlist", MENU_SELECT_ONLY);
		ExtraMenu_NewPage(guide_menu_id);	   // New Page

		// Store your menu ID to use later
		g_iGuideMenuID = guide_menu_id;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (strcmp(name, "extra_menu") == 0)
	{
		OnPluginEnd();
	}
}

// Always clean up the menu when finished
public void OnPluginEnd()
{
	ExtraMenu_Delete(g_iMenuID);
	ExtraMenu_Delete(g_iGuideMenuID);
}

// Display menu
Action CmdDLRMenu(int client, int args)
{
	ExtraMenu_Display(client, g_iMenuID, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

// Display menu
Action CmdDLRGuideMenu(int client, int args)
{
	ExtraMenu_Display(client, g_iGuideMenuID, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

// Game Menu selection handling
public void DLRMenu_OnSelect(int client, int menu_id, int option, int value)
{
	if (menu_id == g_iMenuID)
	{
	
		PrintToChatAll("SELECTED %N Option: %d Value: %d", client, option, value);

		switch( option )
		{
			case 0: ClientCommand(client, "sm_godmode @me");
			case 1: ClientCommand(client, "sm_noclip @me");
			case 2: ClientCommand(client, "sm_beacon @me");
			case 3: PrintToChat(client, "Speed changed to %d", value);
			case 4: PrintToChat(client, "Difficulty to %d", value);
			case 5: PrintToChat(client, "Tester to %d", value);
			case 6: FakeClientCommand(client, "sm_slay @me");
			case 7: PrintToChat(client, "Default value changed to %d", value);
			case 8: PrintToChat(client, "Close after use %d", value);
			case 9: PrintToChat(client, "Meter value %d", value);
			case 10, 11, 12: PrintToChat(client, "Second page option %d", option - 9);
		}

	}
}

// Guide Menu selection handling
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
