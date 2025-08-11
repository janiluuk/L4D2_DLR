#define PLUGIN_VERSION "0.3"
#include <sourcemod>
#include <extra_menu>

#pragma semicolon 1
#pragma newdecls required

int	g_iMenuID;
int	g_iGuideMenuID;

// Menu option identifiers. Keep in sync with creation order in OnLibraryAdded
enum DLRMenuOption
{
        MENU_GET_KIT = 0,
        MENU_SET_AWAY,
        MENU_SELECT_TEAM,
        MENU_CHANGE_CLASS,
        MENU_VIEW_RANK,
        MENU_VOTE_MAP,
        MENU_VOTE_GAMEMODE,
        MENU_THIRD_PERSON,
        MENU_EQUIP_MODE,
        MENU_TOGGLE_HUD,
        MENU_MUSIC_PLAYER,
        MENU_MUSIC_VOLUME,
        MENU_CHANGE_CHARACTER,
        MENU_ADMIN_SPAWN,
        MENU_ADMIN_RELOAD,
        MENU_ADMIN_MANAGE_SKILLS,
        MENU_ADMIN_MANAGE_PERKS,
        MENU_ADMIN_APPLY_EFFECT,
        MENU_DEBUG_MODE,
        MENU_HALT_GAME,
        MENU_INFECTED_SPAWN,
        MENU_GOD_MODE,
        MENU_REMOVE_WEAPONS,
        MENU_GAME_SPEED
};

// Helper function declarations
void HandleKit(int client, int kit);
void HandleSetAway(int client);
void HandleSelectTeam(int client);
void HandleChangeClass(int client, int classIndex);
void HandleShowRank(int client);
void HandleVoteMap(int client, int value);
void HandleVoteGamemode(int client, int mode);
void HandleThirdPerson(int client, int mode);
void HandleEquipMode(int client, int mode);
void HandleHud(int client, int state);
void HandleMusicPlayer(int client, int state);
void HandleMusicVolume(int client, int level);
void HandleChangeCharacter(int client, int state);
void HandleAdminSpawn(int client, int type);
void HandleAdminReload(int client, int type);
void HandleManageSkills(int client);
void HandleManagePerks(int client);
void HandleApplyEffect(int client);
void HandleDebugMode(int client, int mode);
void HandleHaltGame(int client, int mode);
void HandleInfectedSpawn(int client, int state);
void HandleGodMode(int client, int state);
void HandleRemoveWeapons(int client);
void HandleGameSpeed(int client, int level);
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
                switch (option)
                {
                        case MENU_GET_KIT:                HandleKit(client, value);
                        case MENU_SET_AWAY:               HandleSetAway(client);
                        case MENU_SELECT_TEAM:            HandleSelectTeam(client);
                        case MENU_CHANGE_CLASS:           HandleChangeClass(client, value);
                        case MENU_VIEW_RANK:              HandleShowRank(client);
                        case MENU_VOTE_MAP:               HandleVoteMap(client, value);
                        case MENU_VOTE_GAMEMODE:          HandleVoteGamemode(client, value);
                        case MENU_THIRD_PERSON:           HandleThirdPerson(client, value);
                        case MENU_EQUIP_MODE:             HandleEquipMode(client, value);
                        case MENU_TOGGLE_HUD:             HandleHud(client, value);
                        case MENU_MUSIC_PLAYER:           HandleMusicPlayer(client, value);
                        case MENU_MUSIC_VOLUME:           HandleMusicVolume(client, value);
                        case MENU_CHANGE_CHARACTER:       HandleChangeCharacter(client, value);
                        case MENU_ADMIN_SPAWN:            HandleAdminSpawn(client, value);
                        case MENU_ADMIN_RELOAD:           HandleAdminReload(client, value);
                        case MENU_ADMIN_MANAGE_SKILLS:    HandleManageSkills(client);
                        case MENU_ADMIN_MANAGE_PERKS:     HandleManagePerks(client);
                        case MENU_ADMIN_APPLY_EFFECT:     HandleApplyEffect(client);
                        case MENU_DEBUG_MODE:             HandleDebugMode(client, value);
                        case MENU_HALT_GAME:              HandleHaltGame(client, value);
                        case MENU_INFECTED_SPAWN:         HandleInfectedSpawn(client, value);
                        case MENU_GOD_MODE:               HandleGodMode(client, value);
                        case MENU_REMOVE_WEAPONS:         HandleRemoveWeapons(client);
                        case MENU_GAME_SPEED:             HandleGameSpeed(client, value);
                        default:                          LogMessage("Unhandled menu option %d (value %d) from client %N", option, value, client);
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

// ====================================================================================================
// Helper Implementations
// ====================================================================================================

void HandleKit(int client, int kit)
{
        static const char cmds[][] =
        {
                "sm_kit_medic",
                "sm_kit_rambo",
                "sm_kit_ct",
                "sm_kit_ninja"
        };

        if (kit >= 0 && kit < sizeof(cmds))
        {
                FakeClientCommand(client, cmds[kit]);
        }
        else
        {
                LogMessage("Unknown kit index %d", kit);
        }
}

void HandleSetAway(int client)
{
        FakeClientCommand(client, "sm_afk");
}

void HandleSelectTeam(int client)
{
        FakeClientCommand(client, "sm_team");
}

void HandleChangeClass(int client, int classIndex)
{
        char cmd[32];
        Format(cmd, sizeof(cmd), "sm_class %d", classIndex);
        FakeClientCommand(client, cmd);
}

void HandleShowRank(int client)
{
        FakeClientCommand(client, "sm_rank");
}

void HandleVoteMap(int client, int value)
{
        FakeClientCommand(client, "sm_votemap");
}

void HandleVoteGamemode(int client, int mode)
{
        static const char modes[][] = { "off", "escort", "deathmatch", "race" };
        if (mode >= 0 && mode < sizeof(modes))
        {
                char cmd[64];
                Format(cmd, sizeof(cmd), "sm_votegamemode %s", modes[mode]);
                FakeClientCommand(client, cmd);
        }
        else
        {
                LogMessage("Unknown gamemode %d", mode);
        }
}

void HandleThirdPerson(int client, int mode)
{
        if (mode == 0)
        {
                ClientCommand(client, "firstperson");
        }
        else
        {
                ClientCommand(client, "thirdpersonshoulder");
        }
}

void HandleEquipMode(int client, int mode)
{
        char cmd[32];
        Format(cmd, sizeof(cmd), "sm_equipment %d", mode);
        FakeClientCommand(client, cmd);
}

void HandleHud(int client, int state)
{
        char cmd[16];
        Format(cmd, sizeof(cmd), "sm_hud %d", state);
        FakeClientCommand(client, cmd);
}

void HandleMusicPlayer(int client, int state)
{
        char cmd[24];
        Format(cmd, sizeof(cmd), "sm_music %d", state);
        FakeClientCommand(client, cmd);
}

void HandleMusicVolume(int client, int level)
{
        char cmd[32];
        Format(cmd, sizeof(cmd), "sm_musicvolume %d", level);
        FakeClientCommand(client, cmd);
}

void HandleChangeCharacter(int client, int state)
{
        if (state)
        {
                FakeClientCommand(client, "sm_changechar");
        }
}

void HandleAdminSpawn(int client, int type)
{
        static const char cmds[][] =
        {
                "sm_spawn_cabinet",
                "sm_spawn_weapon",
                "sm_spawn_si",
                "sm_spawn_tank"
        };

        if (type >= 0 && type < sizeof(cmds))
        {
                FakeClientCommand(client, cmds[type]);
        }
        else
        {
                LogMessage("Unknown spawn type %d", type);
        }
}

void HandleAdminReload(int client, int type)
{
        char map[64];
        switch (type)
        {
                case 0:
                {
                        GetCurrentMap(map, sizeof(map));
                        ServerCommand("changelevel %s", map);
                        break;
                }
                case 1:
                {
                        ServerCommand("sm_reload_dlr");
                        break;
                }
                case 2:
                {
                        ServerCommand("sm_reloadplugins");
                        break;
                }
                case 3:
                {
                        ServerCommand("_restart");
                        break;
                }
                default:
                {
                        LogMessage("Unknown reload type %d", type);
                        break;
                }
        }
}

void HandleManageSkills(int client)
{
        FakeClientCommand(client, "sm_skill");
}

void HandleManagePerks(int client)
{
        FakeClientCommand(client, "sm_perks");
}

void HandleApplyEffect(int client)
{
        FakeClientCommand(client, "sm_effect");
}

void HandleDebugMode(int client, int mode)
{
        char cmd[32];
        Format(cmd, sizeof(cmd), "sm_debug %d", mode);
        ServerCommand("%s", cmd);
}

void HandleHaltGame(int client, int mode)
{
        char cmd[32];
        Format(cmd, sizeof(cmd), "sm_halt %d", mode);
        ServerCommand("%s", cmd);
}

void HandleInfectedSpawn(int client, int state)
{
        char cmd[32];
        Format(cmd, sizeof(cmd), "sm_infectedspawn %d", state);
        ServerCommand("%s", cmd);
}

void HandleGodMode(int client, int state)
{
        char cmd[32];
        Format(cmd, sizeof(cmd), "sm_godmode %d", state);
        FakeClientCommand(client, cmd);
}

void HandleRemoveWeapons(int client)
{
        ServerCommand("sm_removeweapons");
}

void HandleGameSpeed(int client, int level)
{
        float scale = float(level) / 10.0;
        char cmd[32];
        Format(cmd, sizeof(cmd), "host_timescale %.2f", scale);
        ServerCommand("%s", cmd);
}
