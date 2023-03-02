/**
* =============================================================================
* Talents Plugin by DLR / Neil / Spirit / panxiaohai / Yani
* Incorporates Survivor classes.
*
* (C)2023 DeadLandRape / Neil / Yani.  All rights reserved.
* =============================================================================
*
*	Developed for DeadLandRape Gaming. This plugin is DLR proprietary software.
*	DLR claims complete rights to this plugin, including, but not limited to:
*
*		- The right to use this plugin in their servers
*		- The right to modify this plugin
*		- The right to claim ownership of this plugin
*		- The right to re-distribute this plugin as they see fit
*/

#define PLUGIN_NAME "Talents Plugin 2023 anniversary edition"
#define PLUGIN_VERSION "1.7b"
#define PLUGIN_IDENTIFIER "dlr_talents"
#pragma semicolon 1
#define DEBUG 0
#define DEBUG_LOG 1
#define DEBUG_TRACE 0
stock int DEBUG_MODE = 0;

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "DLR / Ken / Neil / Spirit / panxiaohai / Yani",
	description = "Incorporates Survivor Classes",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=273312"
};

#include <adminmenu>
#include <l4d2hud>
#include <dlr>
#include <jutils>
#include <l4d2>

// ====================================================================================================
//					L4D2 - Native
// ====================================================================================================

native void F18_ShowAirstrike(float origin[3], float direction);

/**
* PLUGIN LOGIC
*/

public OnPluginStart( )
{
	// Concommands
	RegConsoleCmd("sm_class", CmdClassMenu, "Shows the class selection menu");
	RegConsoleCmd("sm_classinfo", CmdClassInfo, "Shows class descriptions");
	RegConsoleCmd("sm_classes", CmdClasses, "Shows class descriptions");
	RegAdminCmd("sm_dlrm", CmdDlrMenu, ADMFLAG_ROOT, "Debug & Manage");
	RegAdminCmd("sm_hide", HideCommand, ADMFLAG_ROOT, "Hide player");
	RegAdminCmd("sm_dlr_plugins", CmdPlugins, ADMFLAG_ROOT, "List plugins");	
	RegAdminCmd("sm_yay", GrenadeCommand, ADMFLAG_ROOT, "Test grenades");
	RegAdminCmd("sm_hud", Cmd_PrintToHUD, ADMFLAG_ROOT, "Test HUD");
	RegAdminCmd("sm_hud_clear", Cmd_ClearHUD, ADMFLAG_ROOT, "Clear HUD");
	RegAdminCmd("sm_hud_delete", Cmd_DeleteHUD, ADMFLAG_ROOT, "Delete HUD");
	RegAdminCmd("sm_hud_close", Cmd_CloseHUD, ADMFLAG_ROOT, "Delete HUD");
	RegAdminCmd("sm_hud_get", Cmd_GetHud, ADMFLAG_ROOT, "Delete HUD");
	RegAdminCmd("sm_hud_set", Cmd_SetHud, ADMFLAG_ROOT, "Delete HUD");
	RegAdminCmd("sm_hud_setup", Cmd_SetupHud, ADMFLAG_ROOT, "Delete HUD");
	RegAdminCmd("sm_setvictim", Cmd_SetVictim, ADMFLAG_ROOT, "Set horde to attack player #");
	RegAdminCmd("sm_debug", Command_Debug, ADMFLAG_GENERIC, "sm_debug [0 = Off|1 = PrintToChat|2 = LogToFile|3 = PrintToChat AND LogToFile]");

	// Api

	g_hfwdOnPlayerClassChange = CreateGlobalForward("OnPlayerClassChange", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hfwdOnSpecialSkillUsed = CreateGlobalForward("OnSpecialSkillUsed", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hfwdOnCustomCommand = CreateGlobalForward("OnCustomCommand", ET_Ignore, Param_String, Param_Cell, Param_Cell, Param_Cell);
	//Create a Class Selection forward
	g_hOnSkillSelected = CreateGlobalForward("OnSkillSelected", ET_Event, Param_Cell, Param_Cell);	
	g_hForwardPluginState = CreateGlobalForward("DLR_OnPluginState", ET_Ignore, Param_String, Param_Cell);
	g_hForwardRoundState = CreateGlobalForward("DLR_OnRoundState", ET_Ignore, Param_Cell);

	//Create menu and set properties
	g_hSkillMenu = CreateMenu(DlrSkillMenuHandler);
	SetMenuTitle(g_hSkillMenu, "Registered plugins");
	SetMenuExitButton(g_hSkillMenu, true);
	//Create a Class Selection forward

	if (g_hSkillArray == INVALID_HANDLE)
		g_hSkillArray = CreateArray(16);
	
	if (g_hSkillTypeArray == INVALID_HANDLE)
		g_hSkillTypeArray = CreateArray(16);

	// Offsets
	g_iNextPrimaryAttack = FindSendPropInfo("CBaseCombatWeapon", "m_flNextPrimaryAttack");
	g_iActiveWeapon = FindSendPropInfo("CBaseCombatCharacter", "m_hActiveWeapon");
	g_flLaggedMovementValue = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	g_iPlaybackRate = FindSendPropInfo("CBaseCombatWeapon", "m_flPlaybackRate");
	g_iNextAttack = FindSendPropInfo("CTerrorPlayer", "m_flNextAttack");
	g_iTimeWeaponIdle = FindSendPropInfo("CTerrorGun", "m_flTimeWeaponIdle");
	g_reloadStartDuration = FindSendPropInfo("CBaseShotgun", "m_reloadStartDuration");
	g_reloadInsertDuration = FindSendPropInfo("CBaseShotgun", "m_reloadInsertDuration");
	g_reloadEndDuration = FindSendPropInfo("CBaseShotgun", "m_reloadEndDuration");
	g_iReloadState = FindSendPropInfo("CBaseShotgun", "m_reloadState");
	g_iVMStartTimeO = FindSendPropInfo("CTerrorViewModel","m_flLayerStartTime");
	g_iViewModelO = FindSendPropInfo("CTerrorPlayer","m_hViewModel");
	g_iActiveWeaponOffset = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon");
	g_iNextSecondaryAttack	= FindSendPropInfo("CBaseCombatWeapon","m_flNextSecondaryAttack");
	g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	g_iShovePenalty = FindSendPropInfo("CTerrorPlayer", "m_iShovePenalty");
	g_flMeleeRate = 0.45;	
	g_flAttackRate = 0.666;
	g_flReloadRate = 0.5;

	// Hooks
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundChange);
	HookEvent("round_start_post_nav", Event_RoundChange);
	HookEvent("round_start", Event_RoundStart,	EventHookMode_PostNoCopy);	
	HookEvent("mission_lost", Event_RoundChange);
	HookEvent("weapon_reload", Event_RelCommandoClass);
	HookEvent("player_entered_checkpoint", Event_EnterSaferoom);
	HookEvent("player_left_checkpoint", Event_LeftSaferoom);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_left_start_area",Event_LeftStartArea);
	HookEvent("heal_begin", Event_HealBegin, EventHookMode_Pre);
	HookEvent("revive_begin", Event_ReviveBegin, EventHookMode_Pre);
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("server_cvar", Event_ServerCvar, EventHookMode_Pre);

	// Convars
	new Handle:hVersion = CreateConVar("talents_version", PLUGIN_VERSION, "Version of this release", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
	// Convars
	g_hPluginEnabled = CreateConVar("talents_enabled","1","Enables/Disables Plugin 0 = OFF, 1 = ON.", FCVAR_NOTIFY);

	MAX_SOLDIER = CreateConVar("talents_soldier_max", "1", "Max number of soldiers");
	MAX_ATHLETE = CreateConVar("talents_athelete_max", "1", "Max number of athletes");
	MAX_MEDIC = CreateConVar("talents_medic_max", "1", "Max number of medics");
	MAX_SABOTEUR = CreateConVar("talents_saboteur_max", "1", "Max number of saboteurs");
	MAX_COMMANDO = CreateConVar("talents_commando_max", "1", "Max number of commandos");
	MAX_ENGINEER = CreateConVar("talents_engineer_max", "1", "Max number of engineers");
	MAX_BRAWLER = CreateConVar("talents_brawler_max", "1", "Max number of brawlers");
	
	NONE_HEALTH = CreateConVar("talents_none_health", "150", "How much health a default player should have");
	SOLDIER_HEALTH = CreateConVar("talents_soldier_health", "300", "How much health a soldier should have");
	ATHLETE_HEALTH = CreateConVar("talents_athelete_health", "150", "How much health an athlete should have");
	MEDIC_HEALTH = CreateConVar("talents_medic_health_start", "150", "How much health a medic should have");
	SABOTEUR_HEALTH = CreateConVar("talents_saboteur_health", "150", "How much health a saboteur should have");
	COMMANDO_HEALTH = CreateConVar("talents_commando_health", "300", "How much health a commando should have");
	ENGINEER_HEALTH = CreateConVar("talents_engineer_health", "150", "How much health a engineer should have");
	BRAWLER_HEALTH = CreateConVar("talents_brawler_health", "600", "How much health a brawler should have");

	SOLDIER_MELEE_ATTACK_RATE = CreateConVar("talents_soldier_melee_rate", "0.45", "The interval for soldier swinging melee weapon (clamped between 0.3 < 0.9)", FCVAR_NOTIFY, true, 0.3, true, 0.9);
	HookConVarChange(SOLDIER_MELEE_ATTACK_RATE, Convar_Melee_Rate);	
	SOLDIER_ATTACK_RATE = CreateConVar("talents_soldier_attack_rate", "0.6666", "How fast the soldier should shoot with guns. Lower values = faster. Between 0.2 and 0.9", FCVAR_NONE|FCVAR_NOTIFY, true, 0.2, true, 0.9);
	HookConVarChange(SOLDIER_ATTACK_RATE, Convar_Attack_Rate);	
	SOLDIER_SPEED = CreateConVar("talents_soldier_speed", "1.15", "How fast soldier should run. A value of 1.0 = normal speed");
	SOLDIER_DAMAGE_REDUCE_RATIO = CreateConVar("talents_soldier_damage_reduce_ratio", "0.75", "Ratio for how much armor reduces damage for soldier");
	SOLDIER_SHOVE_PENALTY = CreateConVar("talents_soldier_shove_penalty_enabled","0.0","Enables/Disables shove penalty for soldier. 0 = OFF, 1 = ON.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	SOLDIER_MAX_AIRSTRIKES = CreateConVar("talents_soldier_max_airstrikes","3.0","Number of tactical airstrikes per round. 0 = OFF", FCVAR_NOTIFY, true, 0.0, true, 16.0);

	ATHLETE_JUMP_VEL = CreateConVar("talents_athlete_jump", "450.0", "How high a soldier should be able to jump. Make this higher to make them jump higher, or 0.0 for normal height");
	ATHLETE_SPEED = CreateConVar("talents_athlete_speed", "1.20", "How fast athlete should run. A value of 1.0 = normal speed");
	parachuteEnabled = CreateConVar("talents_athlete_enable_parachute","0.0","Enable parachute for athlete. Hold E in air to use it. 0 = OFF, 1 = ON.", FCVAR_NOTIFY, true, 0.0, true, 1.0);		
	
	MEDIC_HEAL_DIST = CreateConVar("talents_medic_heal_dist", "256.0", "How close other survivors have to be to heal. Larger values = larger radius");
	MEDIC_HEALTH_VALUE = CreateConVar("talents_medic_health", "10", "How much health to restore");
	MEDIC_MAX_ITEMS = CreateConVar("talents_medic_max_items", "3", "How many items the medic can drop");
	MEDIC_HEALTH_INTERVAL = CreateConVar("talents_medic_health_interval", "2.0", "How often to heal players within range");
	MEDIC_REVIVE_RATIO = CreateConVar("talents_medic_revive_ratio", "0.5", "How much faster medic revives. lower is faster");
	MEDIC_HEAL_RATIO = CreateConVar("talents_medic_heal_ratio", "0.5", "How much faster medic heals, lower is faster");
	MEDIC_MAX_BUILD_RANGE = CreateConVar("talents_medic_build_range", "120.0", "Maximum distance away an object can be dropped by medic");

	SABOTEUR_INVISIBLE_TIME = CreateConVar("talents_saboteur_invis_time", "5.0", "How long it takes for the saboteur to become invisible");
	SABOTEUR_BOMB_ACTIVATE = CreateConVar("talents_saboteur_bomb_activate", "5.0", "How long before the dropped bomb becomes sensitive to motion");
	SABOTEUR_BOMB_RADIUS = CreateConVar("talents_saboteur_bomb_radius", "128.0", "Radius of bomb motion detection");
	SABOTEUR_MAX_BOMBS = CreateConVar("talents_saboteur_max_bombs", "5", "How many bombs a saboteur can drop per round");
	SABOTEUR_BOMB_TYPES = CreateConVar("talents_saboteur_bomb_types", "2,10,5,15,12,16,9", "Define max 7 mine types to use. (2,10,5,15,12,16,9 are nice combo) 1=Bomb, 2=Cluster, 3=Firework, 4=Smoke, 5=Black Hole, 6=Flashbang, 7=Shield, 8=Tesla, 9=Chemical, 10=Freeze, 11=Medic, 12=Vaporizer, 13=Extinguisher, 14=Glow, 15=Anti-Gravity, 16=Fire Cluster, 17=Bullets, 18=Flak, 19=Airstrike, 20=Weapon");
	SABOTEUR_BOMB_DAMAGE_SURV = CreateConVar("talents_saboteur_bomb_dmg_surv", "0", "How much damage a bomb does to survivors");
	SABOTEUR_BOMB_DAMAGE_INF = CreateConVar("talents_saboteur_bomb_dmg_inf", "1500", "How much damage a bomb does to infected");
	SABOTEUR_BOMB_POWER = CreateConVar("talents_saboteur_bomb_power", "2.0", "How much blast power a bomb has. Higher values will throw survivors farther away");
	SABOTEUR_ACTIVE_BOMB_COLOR = CreateConVar("talents_bomb_active_glow_color","255 0 0", "Glow color for active bombs (Default Red)");
	SABOTEUR_ENABLE_NIGHT_VISION = CreateConVar( "talents_saboteur_enable_nightvision", "1", "1 - Enable Night Vision for Saboteur; 0 - Disable");

	COMMANDO_DAMAGE = CreateConVar("talents_commando_dmg", "5.0", "How much bonus damage a Commando does by default");
	COMMANDO_DAMAGE_RIFLE = CreateConVar("talents_commando_dmg_rifle", "10.0", "How much bonus damage a Commando does with rifle");
	COMMANDO_DAMAGE_GRENADE = CreateConVar("talents_commando_dmg_grenade", "20.0", "How much bonus damage a Commando does with grenade");
	COMMANDO_DAMAGE_SHOTGUN = CreateConVar("talents_commando_dmg_shotfun", "5.0", "How much bonus damage a Commando does with shotgun");
	COMMANDO_DAMAGE_SNIPER = CreateConVar("talents_commando_dmg_sniper", "15.0", "How much bonus damage a Commando does with sniper");
	COMMANDO_DAMAGE_HUNTING = CreateConVar("talents_commando_dmg_hunting", "15.0", "How much bonus damage a Commando does with hunting rifle");
	COMMANDO_DAMAGE_PISTOL = CreateConVar("talents_commando_dmg_pistol", "25.0", "How much bonus damage a Commando does with pistol");
	COMMANDO_DAMAGE_SMG = CreateConVar("talents_commando_dmg_smg", "7.0", "How much bonus damage a Commando does with smg");
	COMMANDO_RELOAD_RATIO = CreateConVar("talents_commando_reload_ratio", "0.5", "Ratio for how fast a Commando should be able to reload. Between 0.3 and 0.9",FCVAR_NONE|FCVAR_NOTIFY, true, 0.3, true, 0.9);
	HookConVarChange(COMMANDO_RELOAD_RATIO, Convar_Reload_Rate);
	COMMANDO_ENABLE_STUMBLE_BLOCK = CreateConVar("talents_commando_enable_stumble_block", "1", "Enable blocking tank knockdowns for Commando. 0 = Disable, 1 = Enable");
	COMMANDO_ENABLE_STOMPING = CreateConVar("talents_commando_enable_stomping", "1", "Enable stomping of downed infected  0 = Disable, 1 = Enable");
	COMMANDO_STOMPING_SLOWDOWN = CreateConVar("talents_commando_stomping_slowdown", "0", "Should movement slow down after stomping: 0 = Disable, 1 = Enable");

	ENGINEER_MAX_BUILDS = CreateConVar("talents_engineer_max_builds", "5", "How many times an engineer can build per round");
	ENGINEER_MAX_BUILD_RANGE = CreateConVar("talents_engineer_build_range", "120.0", "Maximum distance away an object can be built by the engineer");
	
	MINIMUM_DROP_INTERVAL = CreateConVar("talents_drop_interval", "30.0", "Time before an engineer, medic, or saboteur can drop another item");
	MINIMUM_AIRSTRIKE_INTERVAL = CreateConVar("talents_airstrike_interval", "180.0", "Time before soldier can order airstrikes again.");

	// Revive & health modifiers
	healthModEnabled = CreateConVar("talents_health_modifiers_enabled","0.0","Enables/Disables health modifiers. 0 = OFF, 1 = ON.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	REVIVE_DURATION = CreateConVar("talents_revive_duration", "4.0", "Default reviving duration in seconds");
	HEAL_DURATION = CreateConVar("talents_heal_duration", "4.0", "Default healing duration in seconds");
	REVIVE_HEALTH =  CreateConVar("talents_revive_health", "100.0", "Default health given 0n revive");
	PILLS_HEALTH_BUFFER =  CreateConVar("talents_pills_health_buffer", "75.0", "Default health given on pills");	
	ADRENALINE_DURATION =  CreateConVar("talents_adrenaline_duration", "30.0", "Default adrenaline duration");
	ADRENALINE_HEALTH_BUFFER =  CreateConVar("talents_adrenaline_health_buffer", "75.0", "Default health given on adrenaline");

	AutoExecConfig(true, "talents");
	ApplyHealthModifiers();
	parseAvailableBombs();
	
	if (LibraryExists("adminmenu") && ((hTopMenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(hTopMenu);
	}
}

public ResetClientVariables(client)
{
	ClientData[client].SpecialsUsed = 0;	
	ClientData[client].HideStartTime= GetGameTime();
	ClientData[client].HealStartTime= GetGameTime();
	ClientData[client].LastButtons = 0;
	ClientData[client].SpecialDropInterval = 0;
	ClientData[client].ChosenClass = NONE;
	ClientData[client].SpecialSkill = SpecialSkill:No_Skill;
	ClientData[client].LastDropTime = 0.0;
	g_bInSaferoom[client] = false;
	g_bHide[client] = false; 
}

public ClearCache()
{
	g_iSoldierCount = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		g_iSoldierIndex[i]= -1;
		g_iEntityIndex[i] = -1;
		g_fNextAttackTime[i]= -1.0;
	}
}

public RebuildCache()
{
	ClearCache();

	if (!IsServerProcessing())
	return;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && ClientData[i].ChosenClass == soldier)
		{
			g_iSoldierCount++;
			g_iSoldierIndex[g_iSoldierCount] = i;
			#if DEBUG
			PrintToChatAll("\x03-registering \x01%N as Soldier",i);
			#endif			
		}
	}
}

public void SetupClasses(client, class)
{
	if (!client
		|| !IsValidEntity(client)
		|| !IsClientInGame(client)
		|| !IsPlayerAlive(client)
		|| GetClientTeam(client) != 2)
	return;
	
	ClientData[client].ChosenClass = view_as<ClassTypes>(class);
	ClientData[client].SpecialDropInterval = GetConVarInt(MINIMUM_DROP_INTERVAL);	
	ClientData[client].SpecialLimit = 5;
	new MaxPossibleHP = GetConVarInt(NONE_HEALTH);
	DisableAllUpgrades(client);

	switch (view_as<ClassTypes>(class))
	{
		case soldier:	
		{
			char text[64];
			if (g_bAirstrike == true) {
				text = "Press SHIFT for Airstrike!";
			}

			PrintHintText(client,"You have armor, fast attack rate and movement %s", text );
			ClientData[client].SpecialDropInterval = GetConVarInt(MINIMUM_AIRSTRIKE_INTERVAL);
			ClientData[client].SpecialLimit = GetConVarInt(SOLDIER_MAX_AIRSTRIKES);
			MaxPossibleHP = GetConVarInt(SOLDIER_HEALTH);
		}
		
		case medic:
		{
			PrintHintText(client,"Hold CROUCH to heal others, Press SHIFT to drop medkits & supplies. Press MIDDLE button to throw healing grenade");
			CreateTimer(GetConVarFloat(MEDIC_HEALTH_INTERVAL), TimerDetectHealthChanges, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			ClientData[client].SpecialLimit = GetConVarInt(MEDIC_MAX_ITEMS);
			MaxPossibleHP = GetConVarInt(MEDIC_HEALTH);
		}
		
		case athlete:
		{
			decl String:text[64];
			text = "";
			if (parachuteEnabled.BoolValue) {
				text = "While in air, hold E to use parachute!";
			}
			PrintHintText(client,"You move faster, Hold JUMP to bunny hop! %s", text);
			MaxPossibleHP = GetConVarInt(ATHLETE_HEALTH);
		}
		
		case commando:
		{
			decl String:text[64];
			text = "";
			if (GetConVarBool(COMMANDO_ENABLE_STUMBLE_BLOCK)) {
				text = ", You're immune to Tank knockdowns";
			} 

			PrintHintText(client,"You have faster reload and cause more damage%s!\nPress MIDDLE button to activate Berzerk mode!", text);
			MaxPossibleHP = GetConVarInt(COMMANDO_HEALTH);
		}
		
		case engineer:
		{
			PrintHintText(client,"Press SHIFT to drop ammo supplies and auto turrets!");
			MaxPossibleHP = GetConVarInt(ENGINEER_HEALTH);
			ClientData[client].SpecialLimit = GetConVarInt(ENGINEER_MAX_BUILDS);
		}
		
		case saboteur:
		{
			PrintHintText(client,"Press SHIFT to drop mines! Hold CROUCH over 5 sec to go invisible.\nPress MIDDLE button to toggle Nightvision");
			MaxPossibleHP = GetConVarInt(SABOTEUR_HEALTH);
			ClientData[client].SpecialLimit = GetConVarInt(SABOTEUR_MAX_BOMBS);
			ToggleNightVision(client);
		}
		
		case brawler:
		{
			PrintHintText(client,"You've got lots of health!");
			MaxPossibleHP = GetConVarInt(BRAWLER_HEALTH);
		}
	}

	AssignSkills(client);
	setPlayerHealth(client, MaxPossibleHP);
}

/* Temporarily hardcoded until get config right */

public AssignSkills(client)
{	
	if (client < 1 || client > MaxClients) return;

	g_iPlayerSkill[client] = -1;

	switch (ClientData[client].ChosenClass) {
		case engineer:
		{
			int skillId = FindSkillIdByName("Multiturret");
			if (skillId > -1) {
				g_iPlayerSkill[client] = skillId;
			}
		}

		case soldier:
		{
			int skillId = FindSkillIdByName("Airstrike");
			if (skillId > -1) {
				g_iPlayerSkill[client] = skillId;
			}
		}
		case medic:
		{
			int skillId = FindSkillIdByName("Grenades");
			if (skillId > -1) {
				g_iPlayerSkill[client] = skillId;
			}
		}
		case commando:
		{
			int skillId = FindSkillIdByName("Berzerk");
			if (skillId > -1) {
				g_iPlayerSkill[client] = skillId;
			}
		}		
	}
	if (g_iPlayerSkill[client] >= 0) {
		
		char skillName[32];
		int skillSize = sizeof(skillName);

		PlayerIdToSkillName(client, skillName, skillSize);
		PrintDebugAll("Assigned skill %s to client", skillName);
		/* Start Function Call */
		Call_StartForward(g_hOnSkillSelected);
		/* Add details to Function Call */
		Call_PushCell(client);
		Call_PushCell(g_iPlayerSkill[client]);
		Call_Finish();		
	}
}
// ====================================================================================================
//					Register plugins
// ====================================================================================================

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	RegPluginLibrary(PLUGIN_IDENTIFIER);
	CreateNative("GetPlayerClassName", Native_GetPlayerClassName);
	CreateNative("RegisterDLRSkill", Native_RegisterSkill);
	CreateNative("UnregisterDLRSkill", Native_UnregisterSkill);	
	CreateNative("OnSpecialSkillSuccess", Native_OnSpecialSkillSuccess);
	CreateNative("OnSpecialSkillFail", Native_OnSpecialSkillFail);
	CreateNative("GetPlayerSkillID", Native_GetPlayerSkillID);
	CreateNative("FindSkillNameById", Native_FindSkillNameById);
	CreateNative("FindSkillIdByName", Native_FindSkillIdByName);
	CreateNative("GetPlayerSkillName", Native_GetPlayerSkillName);
	MarkNativeAsOptional("LMC_GetEntityOverlayModel"); // LMC
	MarkNativeAsOptional("F18_ShowAirstrike");
	MarkNativeAsOptional("OnCustomCommand");

	//MarkNativeAsOptional("DLR_Berzerk");
	//MarkNativeAsOptional("DLR_Infected2023");

	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginEnd()
{
	ResetPlugin();
	char plugin[32];
	plugin = "dlr_talents";
	
	Call_StartForward(g_hForwardPluginState);
	Call_PushString(plugin);
	Call_PushCell(0);
	Call_Finish();	
}

public void OnLibraryAdded(const char[] sName)
{
	if( g_bLeft4Dead2 && strcmp(sName, "l4d2_airstrike") == 0 )
	{
		g_bAirstrike = true;
		// Assuming valid for late load
		if( g_bLateLoad )
		g_bAirstrikeValid = true;
	}
}

public void OnLibraryRemoved(const char[] sName)
{
	if( g_bLeft4Dead2 && strcmp(sName, "l4d2_airstrike") == 0 )
		g_bAirstrike = false;
}

public InitSkillArray()
{
    g_hSkillArray = CreateArray(8, 32);
    
    char cIndexValid;
    char cIndexUserid;
    int cSkillId;
    bool bUserAlive;
    char cSkillName;    
    int cSkillType;
    char cSkillParameter;
    int iPerkID;

    for(new i = 1; i <= MAXPLAYERS; i++)
    {
		if(!IsClientInGame(i))
		continue;
		//
		SetArrayCell(g_hSkillArray, (i - 1), false, cIndexValid);
		SetArrayCell(g_hSkillArray, (i - 1), GetClientUserId(i), cIndexUserid);
		SetArrayCell(g_hSkillArray, (i - 1), IsPlayerAlive(i), bUserAlive);
		SetArrayCell(g_hSkillArray, (i - 1), -1, cSkillId);
		SetArrayCell(g_hSkillArray, (i - 1), false, cSkillName);
		SetArrayCell(g_hSkillArray, (i - 1), -1, cSkillType);
		SetArrayCell(g_hSkillArray, (i - 1), -1, cSkillParameter);
		SetArrayCell(g_hSkillArray, (i - 1), -1, iPerkID);
    }
}

public Native_RegisterSkill(Handle:plugin, numParams)
{
	if (g_hPluginEnabled == INVALID_HANDLE) 
	{
		PrintDebugAll("DLR plugin is not yet loading, queueing");
	}
	char szItemInfo[3];
	int type;
	int len;
	GetNativeStringLength(1, len);
 
	if (len <= 0)
	{
		return -1;
	}
	char[] szSkillName = new char[len + 1];
	GetNativeString(1, szSkillName, len + 1);
	if (g_hSkillArray == INVALID_HANDLE) {
		return -1;
	}

	if(++g_iSkillCounter <= view_as<int>(MAXCLASSES))
	{
		IntToString(g_iSkillCounter, szItemInfo, sizeof(szItemInfo));
		int index = FindStringInArray(g_hSkillArray, szSkillName);		
		if (index >= 0) {
			PrintDebugAll("Skill %s already exists on index %i", szSkillName, index);
			return index;
		}
		index = PushArrayString(g_hSkillArray, szSkillName);
		type = GetNativeCell(2);
		PushArrayCell(g_hSkillTypeArray, type);
		AddMenuItem(g_hSkillMenu, szItemInfo, szSkillName);

		PrintDebugAll("Registered skill %s with type %i and index %i", szSkillName, type, index);
		return index;
	}
	
	return -1;
}

public Native_UnregisterSkill(Handle:plugin, numParams)
{
	int len;
	GetNativeStringLength(1, len);
 
	if (len <= 0)
	{
		return -1;
	}
	char[] szSkillName = new char[len + 1];
	GetNativeString(1, szSkillName, len + 1);
	if (g_hSkillArray == INVALID_HANDLE) {
		return -1;
	}

	int index = FindStringInArray(g_hSkillArray, szSkillName);	
	if (index > -1) {
		RemoveFromArray(g_hSkillArray, index);
		ShiftArrayUp(g_hSkillArray, index);
		return 1;
	}
	return 0;
}
// ====================================================================================================
//					L4D2 - F-18 AIRSTRIKE
// ====================================================================================================

public void F18_OnRoundState(int roundstate)
{
	static int mystate;
	if(roundstate == 1 && mystate == 0 )
	{
		mystate = 1;
		g_bAirstrikeValid = true;
	}
	else if(roundstate == 0 && mystate == 1)
	{
		mystate = 0;
		g_bAirstrikeValid = false;
	}
}

public void F18_OnPluginState(int pluginstate)
{
	static int mystate;
	if(pluginstate == 1 && mystate == 0)
	{
		mystate = 1;
		g_bAirstrikeValid = true;
	}
	else if(pluginstate == 0 && mystate == 1)
	{
		mystate = 0;
		g_bAirstrikeValid = false;
	}
}
// ====================================================================================================
//					Native events
// ====================================================================================================

any Native_OnSpecialSkillSuccess(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}

	int len;
	GetNativeStringLength(2, len);
 
	if (len <= 0)
	{
		return 0;
	}
 
	char[] str = new char[len + 1];
	GetNativeString(2, str, len + 1);
	ClientData[client].SpecialsUsed++;
	ClientData[client].LastDropTime = GetGameTime();
	return 1;
}

any Native_OnSpecialSkillFail(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}

	int len;
	GetNativeStringLength(2, len);
	if (len <= 0)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Empty plugin name!");
	} 
	char[] name = new char[len + 1];
	GetNativeString(2, name, len + 1);
	GetNativeStringLength(3, len);
	if (len <= 0)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Empty reason!");
	}
	char[] reason = new char[len + 1];
	GetNativeString(3, reason, len + 1);
	PrintToChat(client, "%s failed due to: %s", name, reason);
	return 0;
}

// ====================================================================================================
//		Events & Timers
// ====================================================================================================

public OnMapStart()
{
	// Sounds
	PrecacheSound(SOUND_CLASS_SELECTED);
	PrecacheSound(SOUND_DROP_BOMB);
	PrecacheModel(MODEL_INCEN, true);
	PrecacheModel(MODEL_EXPLO, true);
	PrecacheModel(MODEL_SPRITE, true);
	PrecacheModel(SPRITE_GLOW, true);
	PrecacheModel(MODEL_MINE, true);
	PrecacheSound(SOUND_SQUEAK, true);
	PrecacheSound(SOUND_TUNNEL, true);
	PrecacheSound(SOUND_NOISE, true);
	PrecacheSound(SOUND_BUTTON2, true);

	// Sprites
	g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/glow01.vmt");
	PrecacheModel(ENGINEER_MACHINE_GUN);
	PrecacheModel(AMMO_PILE);
	PrecacheModel(FAN_BLADE);
	PrecacheModel(PARACHUTE);
	// Particles
	PrecacheParticle(EXPLOSION_PARTICLE);
	PrecacheParticle(EXPLOSION_PARTICLE2);
	PrecacheParticle(EXPLOSION_PARTICLE3);
	PrecacheParticle(EFIRE_PARTICLE);
	PrecacheParticle(MEDIC_GLOW);
	PrecacheParticle(BOMB_GLOW);

	// Cache
	ClearCache();
	RoundStarted = false;
	ClassHint = false;
	// Shake

	// Pre-cache env_shake -_- WTF
	int shake = CreateEntityByName("env_shake");
	if( shake != -1 )
	{
		DispatchKeyValue(shake, "spawnflags", "8");
		DispatchKeyValue(shake, "amplitude", "16.0");
		DispatchKeyValue(shake, "frequency", "1.5");
		DispatchKeyValue(shake, "duration", "0.9");
		DispatchKeyValue(shake, "radius", "50");
		TeleportEntity(shake, view_as<float>({ 0.0, 0.0, -1000.0 }), NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(shake);
		ActivateEntity(shake);
		AcceptEntityInput(shake, "Enable");
		AcceptEntityInput(shake, "StartShake");
		RemoveEdict(shake);
	}
}

public void OnMapEnd()
{
	// Cache
	RoundStarted=false;
	ClearCache();
	OnRoundState(0);
}

public void OnConfigsExecuted()
{
	OnPluginReady();
}

public OnPluginReady() {
	
	if(g_bPluginLoaded == false && GetConVarBool(g_hPluginEnabled) == true) {
	
		PrintDebugAll("Talents plugin is now ready");
		Call_StartForward(g_hForwardPluginState);

		Call_PushString("dlr_talents");
		Call_PushCell(1);
		Call_Finish();
		g_bPluginLoaded = true;

		if( g_bLateLoad == true )
		{
			g_bLateLoad = false;
			OnRoundState(1);
		}
	} else if(g_bPluginLoaded == true && GetConVarBool(g_hPluginEnabled) == false) {
		PrintDebugAll("Talents plugin is disabled");
		g_bPluginLoaded = false;
		ResetPlugin();
		Call_StartForward(g_hForwardPluginState);
		Call_PushString("dlr_talents");
		Call_PushCell(0);
		Call_Finish();
	}
}

void ResetPlugin()
{
	RoundStarted=false;
	g_iPlayerSpawn = false;
}

public OnClientPutInServer(client)
{
	if (!client || !IsValidEntity(client) || !IsClientInGame(client) || g_bPluginLoaded == false)
	return;

	ResetClientVariables(client);
	RebuildCache();
	HookPlayer(client);
}

void DmgHookUnhook(bool enabled)
{
	if( !enabled && g_bDmgHooked )
	{
		g_bDmgHooked = false;
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				UnhookPlayer(i);
			}
		}
	}

	if( enabled && !g_bDmgHooked )
	{
		g_bDmgHooked = true;
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				HookPlayer(i);
			}
		}
	}
}
public Action:OnWeaponDrop(client, weapon)
{
//	RebuildCache();
}

public Action:OnWeaponSwitch(client, weapon)
{
//	RebuildCache();
}

public Action:OnWeaponEquip(client, weapon)
{
//	RebuildCache();
}

public OnClientDisconnect(client)
{
	UnhookPlayer(false);
	RebuildCache();
	ResetClientVariables(client);
}

// Inform other plugins.

public void useCustomCommand(char[] pluginName, int client, int entity, int type )
{
	new String:szPluginName[32];
	Format(szPluginName, sizeof(szPluginName), "%s", pluginName);
	Call_StartForward(g_hfwdOnCustomCommand);

	Call_PushString(szPluginName);
	Call_PushCell(client);
	Call_PushCell(entity);
	Call_PushCell(type);	
	Call_Finish();
}	

public void useSpecialSkill(int client, int type)
{
	int skill = g_iPlayerSkill[client];

	if (g_iPlayerSkill[client] >= 0) {
		Call_StartForward(g_hfwdOnSpecialSkillUsed);
		Call_PushCell(client);
		Call_PushCell(skill); 
		Call_PushCell(type);		
		Call_Finish();
	}
}	

public bool canUseSpecialSkill(client, char[] pendingMessage)
{	
	new Float:fCanDropTime = (GetGameTime() - ClientData[client].LastDropTime);
	if (ClientData[client].LastDropTime == 0) {
		fCanDropTime+=ClientData[client].SpecialDropInterval;
	}
	new bool:CanDrop = (fCanDropTime >= ClientData[client].SpecialDropInterval);
	char pendMsg[128];
	char outOfMsg[128];

	int iDropTime = RoundToFloor(fCanDropTime);

	if (IsPlayerInSaferoom(client) || IsInEndingSaferoom(client)) {
			PrintHintText(client, "Cannot deploy inside safe areas");
			return false;
	}
	else if (CanDrop == false)
	{
		Format(pendMsg, sizeof(pendMsg), pendingMessage, (ClientData[client].SpecialDropInterval-iDropTime));
		PrintHintText(client, pendMsg );
		return false;
	} else if (ClientData[client].SpecialsUsed >= ClientData[client].SpecialLimit) {
		Format(outOfMsg, sizeof(outOfMsg), "You're out of supplies! (Max %d / round)", ClientData[client].SpecialLimit);
		PrintHintText(client, outOfMsg);
		return false;
	} 

	return true;
}

stock SetupProgressBar(client, Float:time)
{
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", time);
}

stock KillProgressBar(client)
{
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
}

public ShowBar(client, String:msg[], Float:pos, Float:max)
{
	new String:Gauge1[2] = "-";
	new String:Gauge3[2] = "#";
	new i;
	new String:ChargeBar[100];
	Format(ChargeBar, sizeof(ChargeBar), "");
	
	new Float:GaugeNum = pos/max*100;
	if(GaugeNum > 100.0)
	GaugeNum = 100.0;
	if(GaugeNum<0.0)
	GaugeNum = 0.0;
	for(i=0; i<100; i++)
	ChargeBar[i] = Gauge1[0];
	new p=RoundFloat( GaugeNum);
	
	if(p>=0 && p<100)ChargeBar[p] = Gauge3[0]; 
	/* Display gauge */
	PrintHintText(client, "%s  %3.0f %\n<< %s >>", msg, GaugeNum, ChargeBar);
}

public Event_RoundChange(Handle:event, String:name[], bool:dontBroadcast)
{
	for (new i = 1; i < MAXPLAYERS; i++)
	{
		ResetClientVariables(i);
		LastClassConfirmed[i] = 0;
		DisableAllUpgrades(i);
	}

	DmgHookUnhook(false);
	
	RndSession++;
	RoundStarted = false;
}

public Event_RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	if( g_iPlayerSpawn == true && RoundStarted == true )
		CreateTimer(1.0, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);
	
	RoundStarted = true;
}

public void OnRoundState(int roundstate)
{
	static int dlrstate;

	if( roundstate == 1 && dlrstate == 0 )
	{
		dlrstate = 1;
		Call_StartForward(g_hForwardRoundState);
		Call_PushCell(1);
		Call_Finish();
	}
	else if( roundstate == 0 && dlrstate == 1 )
	{
		dlrstate = 0;
		Call_StartForward(g_hForwardRoundState);
		Call_PushCell(0);
		Call_Finish();
	}
}

public Event_PlayerSpawn(Handle:hEvent, String:sName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(client > 0 && IsValidEntity(client) && IsClientInGame(client))
	{
		GetClientAbsOrigin(client, g_SpawnPos[client]);
		
		if (GetClientTeam(client) == 2)
		{
			CreateTimer(0.3, TimerLoadClient, client, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(0.1, TimerThink, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			
			if (LastClassConfirmed[client] != 0)
				ClientData[client].ChosenClass = view_as<ClassTypes>(LastClassConfirmed[client]);
			else
				CreateTimer(1.0, CreatePlayerClassMenuDelay, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		
		g_iPlayerSpawn = true;
	}
}

public Event_PlayerDeath(Handle:hEvent, String:sName[], bool:bDontBroadcast)
{
	RebuildCache();
	
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2) DisableAllUpgrades(client);

	ResetClientVariables(client);
}

public Event_EnterSaferoom(Handle:event, String:Event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_bInSaferoom[client] = true;
}

public Event_LeftSaferoom(Handle:event, String:Event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_bInSaferoom[client] = false;
}

public Action:Event_LeftStartArea(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundStarted = true;
	PrintToChatAll("%sPlayers left safe area, classes now locked!",PRINT_PREFIX);	
}

public Event_PlayerTeam(Handle:hEvent, String:sName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new team = GetEventInt(hEvent, "team");
	
	if (team == 2 && LastClassConfirmed[client] != 0)
	{
		ClientData[client].ChosenClass = view_as<ClassTypes>(LastClassConfirmed[client]);
		PrintToChat(client, "You are currently a \x04%s", MENU_OPTIONS[LastClassConfirmed[client]]);
	}
}

///////////////////////////////////////////////////////////////////////////////////
// Class selections
///////////////////////////////////////////////////////////////////////////////////

public int GetMaxWithClass( class ) {

	switch(view_as<ClassTypes>(class)) {
		case soldier:
		return GetConVarInt( MAX_SOLDIER );
		case athlete:
		return GetConVarInt( MAX_ATHLETE );
		case medic:
		return GetConVarInt( MAX_MEDIC );
		case saboteur:
		return GetConVarInt( MAX_SABOTEUR );
		case commando:
		return GetConVarInt( MAX_COMMANDO );
		case engineer:
		return GetConVarInt( MAX_ENGINEER );
		case brawler:
		return GetConVarInt( MAX_BRAWLER );
		default:
		return -1;
	}
}

public int FindSkillIdByName(char[] name)
{
	int index = FindStringInArray(g_hSkillArray, name);
	return index;
}

public Native_FindSkillNameById(Handle:plugin, numParams)
{
	new skillId = GetNativeCell(1);

	if (skillId < 0 || skillId > 32)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid skill index (%d)", skillId);
	}
	int iSize = 32;
	char buffer[32];

	GetArrayString(g_hSkillArray, skillId, buffer, iSize);
	SetNativeString(2, buffer, iSize);	
	return;
}

public Native_FindSkillIdByName(Handle:plugin, numParams)
{
	int len;
	GetNativeStringLength(1, len);
 
	if (len <= 0)
	{
		return -1;
	}
 
	char[] szSkillName = new char[len + 1];
	GetNativeString(1, szSkillName, len + 1);	
	if(strlen(szSkillName) > 0)
	{
		return FindSkillIdByName(szSkillName);
		
	} else {
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid skill name (%s)", szSkillName);
	}	
}

public Native_GetPlayerClassName(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);

	if (client < 1 || client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}

	new iSize = GetNativeCell(3);
	new String:szSkillName[32];
	Format(szSkillName, iSize, "%s", MENU_OPTIONS[ClientData[client].ChosenClass]);
	SetNativeString(2, szSkillName, iSize);	
	return;
}

public PlayerIdToSkillName(int client, char[] name, int size)
{
	char szSkillName[32] = "None";
	int iSize = 32;
	char buffer[32];

	if (!client ||  !IsClientInGame(client) || GetClientTeam(client) != 2) {
		Format(name, size, "%s", szSkillName);
	}
	if (g_iPlayerSkill[client] > -1) {
		GetArrayString(g_hSkillArray, g_iPlayerSkill[client], buffer, iSize);
	}
	Format(name, iSize, "%s", buffer);
}

public PlayerIdToClassName(int client, char[] name, int size)
{
	if (!client ||  !IsClientInGame(client) || GetClientTeam(client) != 2) {
		return;
	}
	Format(name, size, "%s", MENU_OPTIONS[ClientData[client].ChosenClass]);
}

////////////////////
/// Skill register 
////////////////////

public Native_GetPlayerSkillID(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    if (client < 1 || client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
    return g_iPlayerSkill[client];
}

public Native_GetPlayerSkillName(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}

	int iSize = GetNativeCell(3);
	char szSkillName[32];
	int index = g_iPlayerSkill[client];
	if (index >= 0) {
		GetArrayString(g_hSkillArray, index, szSkillName, iSize);
		PrintDebugAll("Found player skillname %s, %i", szSkillName, index);
		SetNativeString(2, szSkillName, iSize);
		return true;
	}
	return false;
} 

public UpgradeQuickHeal(client)
{
	if(ClientData[client].ChosenClass == medic)
	SetConVarFloat(g_flFirstAidDuration, FirstAidDuration * GetConVarFloat(MEDIC_HEAL_RATIO), false, false);
	else
	SetConVarFloat(g_flFirstAidDuration, FirstAidDuration * 1.0, false, false);
}

public UpgradeQuickRevive(client)
{
	if(ClientData[client].ChosenClass == medic)
	SetConVarFloat(g_flReviveDuration, ReviveDuration * GetConVarFloat(MEDIC_REVIVE_RATIO), false, false);
	else
	SetConVarFloat(g_flReviveDuration, ReviveDuration * 1.0, false, false);
}

public setPlayerHealth(client, MaxPossibleHP)
{
	if (!client) return;
	new OldMaxHealth = GetEntProp(client, Prop_Send, "m_iMaxHealth");
	new OldHealth = GetClientHealth(client);
	new OldTempHealth = GetClientTempHealth(client);
	if (MaxPossibleHP == OldMaxHealth) return;

	SetEntProp(client, Prop_Send, "m_iMaxHealth", MaxPossibleHP);
	SetEntityHealth(client, MaxPossibleHP - (OldMaxHealth - OldHealth));
	SetClientTempHealth(client, OldTempHealth);
	
	if ((GetClientHealth(client) + GetClientTempHealth(client)) > MaxPossibleHP)
	{
		SetEntityHealth(client, MaxPossibleHP);
		SetClientTempHealth(client, 0);
	}
}

public setPlayerDefaultHealth(client)
{
	if (!client
		|| !IsValidEntity(client)
		|| !IsClientInGame(client)
		|| !IsPlayerAlive(client)
		|| GetClientTeam(client) != 2)
	return;
	
	new MaxPossibleHP = GetConVarInt(NONE_HEALTH);
	setPlayerHealth(client, MaxPossibleHP);
}

stock GetClientTempHealth(client)
{
	if (!client
		|| !IsValidEntity(client)
		|| !IsClientInGame(client)
		|| !IsPlayerAlive(client)
		|| IsClientObserver(client)
		|| GetClientTeam(client) != 2)
	{
		return -1;
	}
	
	new Float:buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	
	new Float:TempHealth;
	
	if (buffer <= 0.0)
	TempHealth = 0.0;
	else
	{
		new Float:difference = GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
		new Float:decay = GetConVarFloat(FindConVar("pain_pills_decay_rate"));
		new Float:constant = 1.0/decay;
		TempHealth = buffer - (difference / constant);
	}
	
	if(TempHealth < 0.0)
	TempHealth = 0.0;
	
	return RoundToFloor(TempHealth);
}

stock SetClientTempHealth(client, iValue)
{
	if (!client
		|| !IsValidEntity(client)
		|| !IsClientInGame(client)
		|| !IsPlayerAlive(client)
		|| IsClientObserver(client)
		|| GetClientTeam(client) != 2)
	return;
	
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", iValue*1.0);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	
	new Handle:hPack = CreateDataPack();
	WritePackCell(hPack, client);
	WritePackCell(hPack, iValue);
	
	CreateTimer(0.1, TimerSetClientTempHealth, hPack, TIMER_FLAG_NO_MAPCHANGE);
}

//////////////////////////////////////////7
// Health 
///////////////////////////////////////////

public void Event_ServerCvar( Event hEvent, const char[] sName, bool bDontBroadcast ) 
{
	if ( !healthModEnabled.BoolValue ) return;
	
	InitHealthModifiers();
}

public Event_HealBegin(Handle:event, const String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	UpgradeQuickHeal(client);
}

public Event_ReviveBegin(Handle:event, const String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	UpgradeQuickRevive(client);
}
public ApplyHealthModifiers()
{
	FirstAidDuration = GetConVarFloat(FindConVar("first_aid_kit_use_duration"));
	ReviveDuration = GetConVarFloat(FindConVar("survivor_revive_duration"));
	g_flFirstAidDuration = FindConVar("first_aid_kit_use_duration");
	g_flReviveDuration = FindConVar("survivor_revive_duration");
}

public InitHealthModifiers()
{
	FindConVar("first_aid_heal_percent").FloatValue = 1.0; 	
	FindConVar("first_aid_kit_use_duration").IntValue = GetConVarInt(HEAL_DURATION); 
	FindConVar("survivor_revive_duration").IntValue = GetConVarInt(REVIVE_DURATION);
	FindConVar("survivor_revive_health").IntValue = GetConVarInt(REVIVE_HEALTH);
	FindConVar("pain_pills_health_value").IntValue = GetConVarInt(PILLS_HEALTH_BUFFER);
	FindConVar("adrenaline_duration").IntValue = GetConVarInt(ADRENALINE_DURATION); 
	FindConVar("adrenaline_health_buffer").IntValue = GetConVarInt(ADRENALINE_HEALTH_BUFFER);
	SetConVarFloat(FindConVar("first_aid_kit_use_duration"), GetConVarFloat(HEAL_DURATION), false, false);
	SetConVarFloat(FindConVar("survivor_revive_duration"), GetConVarFloat(REVIVE_DURATION), false, false);	
	ApplyHealthModifiers();	
}

///////////////////////////////////////////////////////////////////////////////////
// Commando
///////////////////////////////////////////////////////////////////////////////////

public Action L4D_OnKnockedDown(int client, int reason)
{
	if( GetConVarBool(COMMANDO_ENABLE_STUMBLE_BLOCK) && ClientData[client].ChosenClass == commando && reason == 2 )
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action L4D_TankClaw_OnPlayerHit_Pre(int tank, int claw, int player)
{
	if( GetConVarBool(COMMANDO_ENABLE_STUMBLE_BLOCK) && ClientData[player].ChosenClass == commando)
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Event_RelCommandoClass(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if (ClientData[client].ChosenClass != commando)
	return;
	
	int weapon = GetEntDataEnt2(client, g_iActiveWeapon);

	if (!IsValidEntity(weapon))
	return;
	#if DEBUG
	PrintDebugAll("\x03Client \x01%i\x03; start of reload detected",client );
	#endif
	float flGameTime = GetGameTime();
	float flNextTime_calc;
	decl String:bNetCl[64];
	decl String:stClass[32];
	float flStartTime_calc;
	GetEntityNetClass(weapon, bNetCl, sizeof(bNetCl));
	GetEntityNetClass(weapon,stClass,32);
	#if DEBUG
	PrintDebugAll("\x03-class of gun: \x01%s",stClass );
	#endif

	if (StrContains(bNetCl, "shotgun", false) == -1)
	{

		new Handle:hPack = CreateDataPack();
		WritePackCell(hPack, client);
		float flNextPrimaryAttack = GetEntDataFloat(weapon, g_iNextPrimaryAttack);		
		#if DEBUG
		PrintDebugAll("\x03- pre, gametime \x01%f\x03, retrieved nextattack\x01 %i %f\x03, retrieved time idle \x01%i %f",
		flGameTime,
		g_iNextPrimaryAttack,
		GetEntDataFloat(weapon,g_iNextPrimaryAttack),
		g_iTimeWeaponIdle,
		GetEntDataFloat(weapon,g_iTimeWeaponIdle)
		);
		#endif

		new Float:fReloadRatio = g_flReloadRate;
		flNextTime_calc = (flNextPrimaryAttack - flGameTime) * fReloadRatio;

		SetEntDataFloat(weapon, g_iPlaybackRate, 1.0 / fReloadRatio, true);
		CreateTimer( flNextTime_calc, CommandoRelFireEnd, weapon);

		flStartTime_calc = flGameTime - ( flNextPrimaryAttack - flGameTime ) * ( 1 - fReloadRatio ) ;
		WritePackFloat(hPack, flStartTime_calc);
		if ( (flNextTime_calc - 0.4) > 0 )
			CreateTimer( flNextTime_calc - 0.4 , CommandoRelFireEnd2, hPack);
		
		flNextTime_calc += flGameTime;
		SetEntDataFloat(weapon, g_iTimeWeaponIdle, flNextTime_calc, true);
		SetEntDataFloat(weapon, g_iNextPrimaryAttack, flNextTime_calc, true);
		SetEntDataFloat(client, g_iNextAttack, flNextTime_calc, true);
		#if DEBUG
		PrintDebugAll("\x03- post, calculated nextattack \x01%f\x03, gametime \x01%f\x03, retrieved nextattack\x01 %i %f\x03, retrieved time idle \x01%i %f",
		flNextTime_calc,
		flGameTime,
		g_iNextPrimaryAttack,
		GetEntDataFloat(weapon,g_iNextPrimaryAttack),
		g_iTimeWeaponIdle,
		GetEntDataFloat(weapon,g_iTimeWeaponIdle)
		);
		#endif
	}
	else
	{
		new Handle:hPack = CreateDataPack();
		WritePackCell(hPack, weapon);
		WritePackCell(hPack, client);		

		if (StrContains(bNetCl, "CShotgun_SPAS", false) != -1)
		{

			#if DEBUG
				PrintDebugAll("Shotgun Class: %s", stClass);
			#endif
			WritePackFloat(hPack, g_flShotgunSpasS);
			WritePackFloat(hPack, g_flShotgunSpasI);
			WritePackFloat(hPack, g_flShotgunSpasE);

			CreateTimer(0.1, CommandoPumpShotReload, hPack);
		}
		else if (StrContains(bNetCl, "pumpshotgun", false) != -1)
		{

			WritePackFloat(hPack, g_flPumpShotgunS);
			WritePackFloat(hPack, g_flPumpShotgunI);
			WritePackFloat(hPack, g_flPumpShotgunE);

			CreateTimer(0.1, CommandoPumpShotReload, hPack);
		}
		else if (StrContains(bNetCl, "autoshotgun", false) != -1)
		{
			WritePackFloat(hPack, g_flAutoShotgunS);
			WritePackFloat(hPack, g_flAutoShotgunI);
			WritePackFloat(hPack, g_flAutoShotgunE);

			CreateTimer(0.1, CommandoPumpShotReload, hPack);
		}
		else {
		#if DEBUG
			PrintDebugAll("\x03 did not find: \x01%s",stClass );
		#endif
			CloseHandle(hPack);

		}
	}
}

public Action:CommandoRelFireEnd(Handle:timer, any:weapon)
{
	if (weapon <= 0 || !IsValidEntity(weapon))
	return Plugin_Stop;
	
	SetEntDataFloat(weapon, g_iPlaybackRate, 1.0, true);
	KillTimer(timer);

	return Plugin_Stop;
}

public Action:CommandoRelFireEnd2(Handle:timer, Handle:hPack)
{
	KillTimer(timer);
	if (IsServerProcessing()==false)
	{
		CloseHandle(hPack);
		return Plugin_Stop;
	}
	ResetPack(hPack);

	new client = ReadPackCell(hPack);
	new Float:flStartTime_calc = ReadPackFloat(hPack);
	CloseHandle(hPack);

	if (client <= 0
		|| IsValidEntity(client)==false
		|| IsClientInGame(client)==false)
		return Plugin_Stop;

	new iVMid = GetEntDataEnt2(client,g_iViewModelO);
	SetEntDataFloat(iVMid, g_iVMStartTimeO, flStartTime_calc, true);
	return Plugin_Stop;
}

public Action:CommandoPumpShotReload(Handle:timer, Handle:hOldPack)
{
	ResetPack(hOldPack);
	new weapon = ReadPackCell(hOldPack);
	new client = ReadPackCell(hOldPack);	
	new Float:fReloadRatio = g_flReloadRate;
	new Float:start = ReadPackFloat(hOldPack);
	new Float:insert = ReadPackFloat(hOldPack);
	new Float:end = ReadPackFloat(hOldPack);
	CloseHandle(hOldPack);
	#if DEBUG
		PrintDebugAll("Starting reload");
	#endif

	if (client <= 0
		|| weapon <= 0
		|| IsValidEntity(weapon)==false
		|| IsValidEntity(client)==false
		|| IsClientInGame(client)==false)
		return Plugin_Stop;

	SetEntDataFloat(weapon,	g_reloadStartDuration,	start * fReloadRatio,	true);
	SetEntDataFloat(weapon,	g_reloadInsertDuration,	insert * fReloadRatio,	true);
	SetEntDataFloat(weapon,	g_reloadEndDuration, end * fReloadRatio,	true);
	SetEntDataFloat(weapon, g_iPlaybackRate, 1.0 / fReloadRatio, true);
	
	#if DEBUG
		PrintDebugAll("\x03-spas shotgun detected, ratio \x01%i\x03, startO \x01%i\x03, insertO \x01%i\x03, endO \x01%i", fReloadRatio, g_reloadStartDuration, g_reloadInsertDuration, g_reloadEndDuration);
	#endif

	new Handle:hPack = CreateDataPack();
	WritePackCell(hPack, weapon);
	WritePackCell(hPack, client);

	if (GetEntData(weapon, g_iReloadState) != 2)
	{
		WritePackFloat(hPack, 0.2);
		CreateTimer(0.3, CommandoShotCalculate, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		WritePackFloat(hPack, 1.0);
		CreateTimer(0.3, CommandoShotCalculate, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Stop;
}

public Action:CommandoShotCalculate(Handle:timer, Handle:hPack)
{
	ResetPack(hPack);
	new weapon = ReadPackCell(hPack);
	new client  = ReadPackCell(hPack);

	new Float:addMod = ReadPackFloat(hPack);
	
	if (IsServerProcessing()==false
		|| client <= 0
		|| weapon <= 0
		|| IsValidEntity(client)==false
		|| IsValidEntity(weapon)==false
		|| IsClientInGame(client)==false)
	{
		KillTimer(timer);
		return Plugin_Stop;
	}
	#if DEBUG
	PrintDebugAll("Shotgun finished reloading");
	#endif

	if (GetEntData(weapon, g_iReloadState) == 0 || GetEntData(weapon, g_iReloadState) == 2 )
	{

		new Float:flNextTime = GetGameTime() + addMod;
		
		SetEntDataFloat(weapon, g_iPlaybackRate, 1.0, true);
		SetEntDataFloat(client, g_iNextAttack, flNextTime, true);
		SetEntDataFloat(weapon,	g_iTimeWeaponIdle, flNextTime, true);
		SetEntDataFloat(weapon,	g_iNextPrimaryAttack, flNextTime, true);
		KillTimer(timer);
		CloseHandle(hPack);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(ClientData[client].ChosenClass == NONE && GetClientTeam(client) == 2 && client > 0 && client <= MaxClients && IsClientInGame( client ) && ClassHint == false)
	{
		if (RoundStarted == true) {
			ClassHint = true;
		}
		PrintHintText(client,"You really should pick a class, 1,5,7 are good for beginners.");
		CreatePlayerClassMenu(client);
	}


	if(ClientData[client].ChosenClass == commando)
	{
		GetEventString(event, "weapon", ClientData[client].EquippedGun, 64);
		//PrintToChat(client,"weapon shot fired");	
	}
	return Plugin_Continue;
}

public getCommandoDamageBonus(client)
{
	if (StrContains(ClientData[client].EquippedGun,"grenade", false)!=-1)
	{
		return GetConVarInt(COMMANDO_DAMAGE_GRENADE);
	}
	if (StrContains(ClientData[client].EquippedGun,"shotgun", false)!=-1)
	{
		return GetConVarInt(COMMANDO_DAMAGE_SHOTGUN);
	}
	if (StrContains(ClientData[client].EquippedGun, "sniper", false)!=-1)
	{
		return GetConVarInt(COMMANDO_DAMAGE_SNIPER);
	}
	if (StrContains(ClientData[client].EquippedGun, "hunting", false)!=-1)
	{
		return GetConVarInt(COMMANDO_DAMAGE_HUNTING);
	}
	if (StrContains(ClientData[client].EquippedGun, "pistol", false)!=-1)
	{
		return GetConVarInt(COMMANDO_DAMAGE_PISTOL);
	}
	if (StrContains(ClientData[client].EquippedGun, "smg", false)!=-1)
	{
		return GetConVarInt(COMMANDO_DAMAGE_SMG);
	}
	if (StrContains(ClientData[client].EquippedGun,"rifle", false)!=-1)
	{
		return GetConVarInt(COMMANDO_DAMAGE_RIFLE);
	}
	// default
	return GetConVarInt(COMMANDO_DAMAGE);
}

public void OnClientPostAdminCheck(int client)
{
	SDKHook(client, SDKHook_StartTouch, _MF_Touch);
	SDKHook(client, SDKHook_Touch, 		_MF_Touch);
}

stock Action _MF_Touch(int entity, int other)
{
	if (!GetConVarBool(COMMANDO_ENABLE_STOMPING)) return Plugin_Continue;
 	if (ClientData[entity].ChosenClass != commando || other < 32 || !IsValidEntity(other)) return Plugin_Continue;
	
	static char classname[12];
	GetEntityClassname(other, classname, sizeof(classname));	
	if (strcmp(classname, "infected") == 0)
	{
		int i = GetEntProp(other, Prop_Data, ENTPROP_ANIM_SEQUENCE);
		float f = GetEntPropFloat(other, Prop_Data, ENTPROP_ANIM_CYCLE);
		//PrintDebugAll("Touch fired on Infected, Sequence %i, Cycle %f", i, f);
		
		if ((i >= ANIM_SEQUENCES_DOWNED_BEGIN && i <= ANIM_SEQUENCES_DOWNED_END) || i == ANIM_SEQUENCE_WALLED)
		{
			if (f >= DOWNED_ANIM_MIN_CYCLE && f <= DOWNED_ANIM_MAX_CYCLE)
			{
				PrintDebugAll("Infected found downed. STOMPING HIM!!!");
				SmashInfected(other, entity);
				
				if (GetConVarBool(COMMANDO_STOMPING_SLOWDOWN))
				{
					SetEntPropFloat(entity, Prop_Data, SPEED_MODIFY_ENTPROP, GetEntPropFloat(entity, Prop_Data, SPEED_MODIFY_ENTPROP) - STOMP_MOVE_PENALTY);
				}
			}
		}
	}
	
	return Plugin_Continue;
}

stock void SmashInfected(int zombie, int client)
{
	EmitSoundToAll(STOMP_SOUND_PATH, zombie, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
	AcceptEntityInput(zombie, "BecomeRagdoll");
	SetEntProp(zombie, Prop_Send, "m_CollisionGroup", 0);
	SetEntProp(zombie, Prop_Data, "m_iHealth", 1);
	SDKHooks_TakeDamage(zombie, client, client, 10000.0, DMG_GENERIC);
}

///////////////////////////////////////////////////////////////////////////////////
// Saboteur
///////////////////////////////////////////////////////////////////////////////////

enum BombType {
	Bomb = 0, 
	Cluster, 
	Firework,
	Smoke, 
	BlackHole,
	Flashbang, 
	Shield, 
	Tesla, 
	Chemical, 
	Freeze, 
	Medic, 
	Vaporizer, 
	Extinguisher, 
	Glowing, 
	AntiGravity, 
	FireCluster, 
	Bullets, 
	Flak, 
	Airstrike, 
	Weapon
}

stock char[] formatBombName(char[] bombName) {
	char temp[32];
	Format(temp, sizeof(temp), "%s", bombName);
	return temp;
}

stock char[] getBombName(int index) {

	char bombName[32];

	switch( index - 1 )
	{
		case 0: return formatBombName("Bomb");
		case 1: return formatBombName("Cluster");
		case 2: return formatBombName("Firework");
		case 3: return formatBombName("Smoke");
		case 4: return formatBombName("BlackHole");
		case 5: return formatBombName("Flashbang");
		case 6: return formatBombName("Shield");
		case 7: return formatBombName("Tesla");
		case 8: return formatBombName("Chemical");
		case 9: return formatBombName("Freeze");
		case 10: return formatBombName("Medic");
		case 11: return formatBombName("Vaporizer");
		case 12: return formatBombName("Extinguisher");
		case 13: return formatBombName("Glow");
		case 14: return formatBombName("Anti-Gravity");
		case 15: return formatBombName("Fire Cluster");
		case 16: return formatBombName("Bullets");
		case 17: return formatBombName("Flak");
		case 18: return formatBombName("Airstrike");
		case 19: return formatBombName("Weapon");
	}
	return bombName;
}

public parseAvailableBombs()
{
	char buffers[MAX_BOMBS][3];

	char bombs[128];
	GetConVarString(SABOTEUR_BOMB_TYPES, bombs, sizeof(bombs));

	int amount = ExplodeString(bombs, ",", buffers, sizeof(buffers), sizeof(buffers[]));
	PrintDebugAll("Found %i amount of mines from bombs: %s ",amount, bombs);

	if (amount == 1) {

		g_AvailableBombs[0].setItem(0, StringToInt(buffers[0]));
		PrintDebugAll("Added single bombtype to inventory: %s", g_AvailableBombs[0].getItem());
		return;
	}

	for( int i = 0; i < MAX_BOMBS; i++ )
	{	
		int item = StringToInt(buffers[i]);
		if (item < 1) {
			continue;
		}

		g_AvailableBombs[i].setItem(i, item);
		PrintDebugAll("Added %i bombtype to inventory: %s", getBombName(item), g_AvailableBombs[i].getItem());
	}
}

public void CalculateSaboteurPlacePos(client, int value)
{
	decl Float:vAng[3], Float:vPos[3], Float:endPos[3];
	
	GetClientEyeAngles(client, vAng);
	GetClientEyePosition(client, vPos);
	
	new Handle:trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, TraceFilter, client);
	if (TR_DidHit(trace)) {
		TR_GetEndPosition(endPos, trace);
		CloseHandle(trace);
		
		if (GetVectorDistance(endPos, vPos) <= GetConVarFloat(ENGINEER_MAX_BUILD_RANGE)) {
			vAng[0] = 0.0;
			vAng[2] = 0.0;
			DropBomb(client, value);
			PrintDebugAll("%N dropped a mine with index of %i to %f %f %f" , client, value, vPos[0], vPos[1], vPos[2]);			
			ClientData[client].SpecialsUsed++;
			ClientData[client].LastDropTime = GetGameTime();				
		} else {
			PrintToChat(client, "%sCould not place the item because you were looking too far away.", PRINT_PREFIX);
		}
		
	} else
		CloseHandle(trace);
}

public void OnClientWeaponEquip(int client, int weapon)
{
	if (ClientData[client].ChosenClass == saboteur && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2) {
		
		ToggleNightVision(client);
	}
}

public void ToggleNightVision(client)
{
	if (GetConVarBool(SABOTEUR_ENABLE_NIGHT_VISION) && ClientData[client].ChosenClass == saboteur && client < MaxClients && client > 0 && !IsFakeClient(client) && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
			int iWeapon = GetPlayerWeaponSlot(client, 0); // Get primary weapon
			if(iWeapon > 0 && IsValidEdict(iWeapon) && IsValidEntity(iWeapon))
			{					
				char netclass[128];
				GetEntityNetClass(iWeapon, netclass, sizeof(netclass));
				PrintDebug(client, "Toggling nightvision!");
				SetEntProp(client, Prop_Send, "m_bNightVisionOn", !GetEntProp(client, Prop_Send, "m_bNightVisionOn"));
				SetEntProp(client, Prop_Send, "m_bHasNightVision", !GetEntProp(client, Prop_Send, "m_bHasNightVision"));
				if (!GetEntProp(client, Prop_Send, "m_bHasNightVision"))
				return;
				if(FindSendPropInfo(netclass, "m_upgradeBitVec") < 1)
				return; // This weapon does not support laser upgrade

				new cl_upgrades = GetEntProp(iWeapon, Prop_Send, "m_upgradeBitVec");
				if (cl_upgrades > 4194304) {
					return; // already has nightvision
				} else {
					SetEntProp(iWeapon, Prop_Send, "m_upgradeBitVec", cl_upgrades + 4194304, 4);
				}
		}
	}
}

public Action L4D2_OnChooseVictim(int attacker, int &curTarget) {
	// =========================
	// OVERRIDE VICTIM
	// =========================
	L4D2Infected class = view_as<L4D2Infected>(GetEntProp(attacker, Prop_Send, "m_zombieClass"));
	if(class != L4D2Infected_Tank) {
		int existingTarget = GetClientOfUserId(b_attackerTarget[attacker]);
		if(existingTarget > 0) {
			return Plugin_Changed;
		}

		float closestDistance, survPos[3], spPos[3];
		GetClientAbsOrigin(attacker, spPos); 
		int closestClient = -1;
		for(int i = 1; i <= MaxClients; i++) {
			if(g_bIsVictim[i] && IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2) {
				GetClientAbsOrigin(i, survPos);
				float dist = GetVectorDistance(survPos, spPos, true);
				if(closestClient == -1 || dist < closestDistance) {
					closestDistance = dist;
					closestClient = i;
				}
			}
		}
		
		if(closestClient > 0) {
			PrintToConsoleAll("Attacker %N new target: %N", attacker, closestClient);
			b_attackerTarget[attacker] = GetClientUserId(closestClient);
			curTarget = closestClient;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

/*
public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	b_attackerTarget[client] = 0;
}

public void OnClientDisconnect(int client) {
	b_attackerTarget[client] = 0;
}
*/

stock DisableAllUpgrades(client)
{
	if (client > 0 && client <= 16 && IsValidEntity(client) && !IsFakeClient(client) && IsClientInGame(client) && GetClientTeam(client) == 2) {
		int iWeapon = GetPlayerWeaponSlot(client, 0); // Get primary weapon
		if(iWeapon > 0 && IsValidEdict(iWeapon) && IsValidEntity(iWeapon))
		{	
			char netclass[128];
			GetEntityNetClass(iWeapon, netclass, sizeof(netclass));
			if(FindSendPropInfo(netclass, "m_upgradeBitVec") < 1)
			return; // This weapon does not support laser upgrade
			SetEntProp(iWeapon, Prop_Send, "m_upgradeBitVec", 0, 4);
			SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0, 4);
			SetEntProp(client, Prop_Send, "m_bHasNightVision", 0, 4);
		}
	}
}

stock UnhookPlayer(client)
{
	if (client > 0 && client <= 16 && IsValidEntity(client) && IsClientInGame(client) && GetClientTeam(client) == 2) {
		
		SDKUnhook(client, SDKHook_WeaponEquipPost, OnClientWeaponEquip);
		SDKUnhook(client, SDKHook_WeaponDropPost, OnClientWeaponEquip);
		SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamagePre);	
		SDKUnhook(client, SDKHook_StartTouch, _MF_Touch);
		SDKUnhook(client, SDKHook_Touch, _MF_Touch);
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamagePre);

	}
}

stock HookPlayer(client) 
{
	if (client > 0 && client <= 16 && IsValidEntity(client) && IsClientInGame(client) && GetClientTeam(client) == 2) {

		SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
		SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
		SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
		SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
		SDKHook(client, SDKHook_WeaponEquipPost, OnClientWeaponEquip);
		SDKHook(client, SDKHook_WeaponDropPost, OnClientWeaponEquip);
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamagePre);
	}
}
///////////////////////////////////////////////////////////////////////////////////
// Soldier
///////////////////////////////////////////////////////////////////////////////////

void Convar_Reload_Rate (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<0.1)
		flF=0.1;
	else if (flF>0.9)
		flF=0.9;
	g_flReloadRate = flF;
}
void Convar_Attack_Rate (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<0.1)
		flF=0.1;
	else if (flF>0.9)
		flF=0.9;
	g_flAttackRate = flF;
}
void Convar_Melee_Rate (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<0.1)
		flF=0.1;
	else if (flF>0.9)
		flF=0.9;
	g_flMeleeRate = flF;
}

public OnGameFrame()
{
	if (!IsServerProcessing())  { return; } // RoundStarted
	else
	{
		MA_OnGameFrame();
		DT_OnGameFrame();
	}
}

void DT_OnGameFrame()
{
	if (g_iSoldierCount <= 0) {return;}

	decl client;
	decl iActiveWeapon;

	//this tracks the calculated next attack
	float flNextTime_calc;
	//this, on the other hand, tracks the current next attack
	decl Float:flNextPrimaryAttack;
	//and this tracks next melee attack times
	decl Float:flNextSecondaryAttack;
	//and this tracks the game time
	float flGameTime = GetGameTime();

	for (new i = 1; i <= g_iSoldierCount; i++)
	{
		client = g_iSoldierIndex[i];

		if (client <= 0) return;
		if(ClientData[client].ChosenClass != soldier) continue;

		iActiveWeapon = GetEntDataEnt2(client, g_iActiveWeapon);

		if(iActiveWeapon <= 0) 
		continue;

		//and here is the retrieved next attack time
		flNextPrimaryAttack = GetEntDataFloat(iActiveWeapon, g_iNextPrimaryAttack);
		//and for retrieved next melee time
		flNextSecondaryAttack = GetEntDataFloat(iActiveWeapon,g_iNextSecondaryAttack);

		if (g_iEntityIndex[client] == iActiveWeapon && g_fNextAttackTime[client] >= flNextPrimaryAttack)
			continue;
		
		if (flNextSecondaryAttack > flGameTime)
		{
			//----RSDEBUG----
			#if DEBUG
			PrintDebugAll("\x03DT client \x01%i\x03; melee attack inferred",client );
			#endif
			continue;
		}

		if (g_iEntityIndex[client] == iActiveWeapon && g_fNextAttackTime[client] < flNextPrimaryAttack)
		{
			#if DEBUG
			PrintDebugAll("\x03DT after adjusted shot\n-pre, client \x01%i\x03; entid \x01%i\x03; enginetime\x01 %f\x03; NextTime_orig \x01 %f\x03; interval \x01%f",client,iActiveWeapon,flGameTime,flNextPrimaryAttack, flNextPrimaryAttack-flGameTime );
			#endif

			flNextTime_calc = ( flNextPrimaryAttack - flGameTime ) * g_flAttackRate + flGameTime;
			g_fNextAttackTime[client] = flNextTime_calc;
			SetEntDataFloat(iActiveWeapon, g_iNextPrimaryAttack, flNextTime_calc, true);
			#if DEBUG
			PrintDebugAll("\x03-post, NextTime_calc \x01 %f\x03; new interval \x01%f",GetEntDataFloat(iActiveWeapon,g_iNextPrimaryAttack), GetEntDataFloat(iActiveWeapon,g_iNextPrimaryAttack)-flGameTime );
			#endif
			continue;
		}
		
		if (g_iEntityIndex[client] != iActiveWeapon)
		{
			g_iEntityIndex[client] = iActiveWeapon;
			g_fNextAttackTime[client] = flNextPrimaryAttack;
			continue;
		}
	}
}

/* ***************************************************************************/
//Since this is called EVERY game frame, we need to be careful not to run too many functions
//kinda hard, though, considering how many things we have to check for =.=

int MA_OnGameFrame()
{
	if (g_iSoldierCount <= 0) {return 0;}

	int iCid;
	//this tracks the player's ability id
	int iEntid;
	//this tracks the calculated next attack
	float flNextTime_calc;
	//this, on the other hand, tracks the current next attack
	float flNextPrimaryAttack;
	//and this tracks the game time
	float flGameTime = GetGameTime();

	//theoretically, to get on the MA registry, all the necessary checks would have already
	//been run, so we don't bother with any checks here
	for (new i = 1; i <= g_iSoldierCount; i++)
	{
		iCid = g_iSoldierIndex[i];
		if(ClientData[iCid].ChosenClass != soldier) {continue;}

		//PRE-CHECKS 1: RETRIEVE VARS
		//---------------------------

		//stop on this client when the next client id is null
		if (iCid <= 0) continue;
		if(!IsClientInGame(iCid)) continue;
		if(!IsClientConnected(iCid)) continue; 
		if (!IsPlayerAlive(iCid)) continue;
		if(GetClientTeam(iCid) != 2) continue;
		if(ClientData[iCid].ChosenClass != soldier) { continue;}

		iEntid = GetEntDataEnt2(iCid, g_iActiveWeaponOffset);

		if (GetConVarBool(SOLDIER_SHOVE_PENALTY) == false )
		{
			//If the player is pressing the right click of the mouse, proceed
			if(GetClientButtons(iCid) & IN_ATTACK2)
			{
				//This will reset the penalty, so it doesnt even get applied.
				SetEntData(iCid, g_iShovePenalty, 0, 4);
			}
		}
		//if the retrieved gun id is -1, then...
		//wtf mate? just move on
		if (iEntid == -1) continue;
		//and here is the retrieved next attack time
		flNextPrimaryAttack = GetEntDataFloat(iEntid, g_iNextPrimaryAttack);

		//CHECK 1: IS PLAYER USING A KNOWN NON-MELEE WEAPON?
		//--------------------------------------------------
		//as the title states... to conserve processing power,
		//if the player's holding a gun for a prolonged time
		//then we want to be able to track that kind of state
		//and not bother with any checks
		//checks: weapon is non-melee weapon
		//actions: do nothing
		if (iEntid == g_iNotMeleeEntityIndex[iCid])
		{
			continue;
		}

		//CHECK 1.5: THE PLAYER HASN'T SWUNG HIS WEAPON FOR A WHILE
		//---------------------------------------------------------
		//in this case, if the player made 1 swing of his 2 strikes, and then paused long enough, 
		//we should reset his strike count so his next attack will allow him to strike twice
		//checks: is the delay between attacks greater than 1.5s?
		//actions: set attack count to 0, and CONTINUE CHECKS
		if (g_iMeleeEntityIndex[iCid] == iEntid && g_iMeleeAttackCount[iCid] != 0 && (flGameTime - flNextPrimaryAttack) > 1.0)
		{
			g_iMeleeAttackCount[iCid] = 0;
		}

		//CHECK 2: BEFORE ADJUSTED ATT IS MADE
		//------------------------------------
		//since this will probably be the case most of the time, we run this first
		//checks: weapon is unchanged; time of shot has not passed
		//actions: do nothing
		if (g_iMeleeEntityIndex[iCid] == iEntid && g_flNextMeleeAttackTime[iCid] >= flNextPrimaryAttack)
		{
			continue;
		}

		//CHECK 3: AFTER ADJUSTED ATT IS MADE
		//------------------------------------
		//at this point, either a gun was swapped, or the attack time needs to be adjusted
		//checks: stored gun id same as retrieved gun id,
		//        and retrieved next attack time is after stored value
		//actions: adjusts next attack time
		if (g_iMeleeEntityIndex[iCid] == iEntid && g_flNextMeleeAttackTime[iCid] < flNextPrimaryAttack)
		{
			//this is a calculation of when the next primary attack will be after applying double tap values
			//flNextTime_calc = ( flNextPrimaryAttack - flGameTime ) * g_flMeleeRate + flGameTime;
			flNextTime_calc = flGameTime + g_flMeleeRate;
			// flNextTime_calc = flGameTime + melee_speed[iCid] ;

			//then we store the value
			g_flNextMeleeAttackTime[iCid] = flNextTime_calc;

			//and finally adjust the value in the gun
			SetEntDataFloat(iEntid, g_iNextPrimaryAttack, flNextTime_calc, true);
			#if DEBUG
			PrintDebugAll("\x03-melee attack, original: \x01 %f\x03; new \x01%f",flNextPrimaryAttack, GetEntDataFloat(iEntid,g_iNextPrimaryAttack - flGameTime);
			#endif
			continue;
		}

		//CHECK 4: CHECK THE WEAdPON
		//-------------------------
		//lastly, at this point we need to check if we are, in fact, using a melee weapon =P
		//we check if the current weapon is the same one stored in memory; if it is, move on;
		//otherwise, check if it's a melee weapon - if it is, store and continue; else, continue.
		//checks: if the active weapon is a melee weapon
		//actions: store the weapon's entid into either
		//         the known-melee or known-non-melee variable

		//check if the weapon is a melee
		char stName[32];
		GetEntityNetClass(iEntid,stName,32);
		if (StrEqual(stName,"CTerrorMeleeWeapon",false)==true)
		{
			//if yes, then store in known-melee var
			g_iMeleeEntityIndex[iCid]=iEntid;
			g_flNextMeleeAttackTime[iCid]=flNextPrimaryAttack;
			continue;
		}
		else
		{
			//if no, then store in known-non-melee var
			g_iNotMeleeEntityIndex[iCid]=iEntid;
			continue;
		}
	}
	return 0;
}

public Action:OnTakeDamagePre(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (!IsServerProcessing())
	return Plugin_Continue;
	
	if (victim && attacker && IsValidEntity(attacker) && attacker <= MaxClients && IsValidEntity(victim) && victim <= MaxClients)
	{
		if( damagetype & DMG_BLAST && GetEntProp(inflictor, Prop_Data,  "m_iHammerID") == 1078682)
		{
			if(GetClientTeam(victim) == 2 )
				damage = GetConVarFloat(SABOTEUR_BOMB_DAMAGE_SURV);
			else if(GetClientTeam(victim) == 3 ) {

				damage = GetConVarFloat(SABOTEUR_BOMB_DAMAGE_INF);
			}
			PrintDebugAll("%N caused damage to %N for %i points", attacker, victim, damage);
			return Plugin_Changed;
		}

		//PrintToChatAll("%s", m_attacker);
		if(ClientData[victim].ChosenClass == soldier && GetClientTeam(victim) == 2)
		{
			//PrintToChat(victim, "Damage: %f, New: %f", damage, damage*0.5);
			damage = damage * GetConVarFloat(SOLDIER_DAMAGE_REDUCE_RATIO);
			return Plugin_Changed;
		}
		if (ClientData[attacker].ChosenClass == commando && GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 3)
		{
			damage = damage + getCommandoDamageBonus(attacker);
			//PrintToChat(attacker,"%f",damage);
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

///////////////////////////////////////////////////////////////////////////////////
// Mines & Airstrikes
///////////////////////////////////////////////////////////////////////////////////

public void DropBomb(client, bombType)
{
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	int index = ClientData[client].SpecialsUsed;		
	char bombName[32];

	bombName = getBombName(bombType);

	new Handle:hPack = CreateDataPack();

	WritePackFloat(hPack, pos[0]);
	WritePackFloat(hPack, pos[1]);
	WritePackFloat(hPack, pos[2]);
	WritePackCell(hPack, GetClientUserId(client));
	WritePackCell(hPack, RndSession);
	WritePackCell(hPack, index);
	WritePackCell(hPack, bombType);	


	TE_SetupBeamRingPoint(pos, 10.0, 256.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greenColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos, 10.0, 256.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, redColor, 10, 0);
	TE_SendToAll();
	BombActive = true;
	BombIndex[index] = true;


	int entity = CreateBombParticleInPos(pos, BOMB_GLOW, index);
	WritePackCell(hPack, entity);	
	CreateTimer(GetConVarFloat(SABOTEUR_BOMB_ACTIVATE), TimerActivateBomb, hPack, TIMER_FLAG_NO_MAPCHANGE);
	EmitSoundToAll(SOUND_DROP_BOMB);
	PrintHintTextToAll("%N planted a %s mine! (%i/%i)", client, bombName, ClientData[client].SpecialsUsed, GetConVarInt(SABOTEUR_MAX_BOMBS));
}

public DropMineEntity(Float:pos[3], int index)
{
	char mineName[32];
	Format(mineName, sizeof(mineName), "mineExplosive%d", index);
	int entity = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(entity, "model", MODEL_MINE);
	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(entity);	
	SetEntProp(entity, Prop_Send, "m_iGlowType", 2);
	SetEntProp(entity, Prop_Send, "m_glowColorOverride", GetColor("255 0 0"));
	SetEntProp(entity, Prop_Send, "m_nGlowRange", 520);
	SetEntProp(entity, Prop_Data, "m_iHammerID", 1078682);
	SetEntProp(entity, Prop_Data, "m_usSolidFlags", 152);
	SetEntProp(entity, Prop_Data, "m_CollisionGroup", 1);
	SetEntityMoveType(entity, MOVETYPE_NONE);
	SetEntProp(entity, Prop_Data, "m_MoveCollide", 0);
	SetEntProp(entity, Prop_Data, "m_nSolidType", 6);
	DispatchKeyValue(entity, "targetname", mineName);

	return entity;
}


public void CreateAirStrike(int client) {
	
	float vPos[3];

	if (SetClientLocation(client, vPos)) {
		char color[12];

		int entity = CreateEntityByName("info_particle_system");
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(entity, "effect_name", BOMB_GLOW);
		DispatchSpawn(entity);
		DispatchSpawn(entity);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "start");

		CreateBeamRing(entity, { 255, 0, 255, 255 },0.1, 180.0, 3);		
		PrintHintTextToAll("%N ordered airstrike, take cover!", client);
		GetConVarString(SABOTEUR_ACTIVE_BOMB_COLOR, color, sizeof(color));
		SetupPrjEffects(entity, vPos, color); // Red

		EmitSoundToAll(SOUND_DROP_BOMB);

		new Handle:pack = CreateDataPack();
		WritePackCell(pack, client);
		WritePackFloat(pack, vPos[0]);
		WritePackFloat(pack, vPos[1]);
		WritePackFloat(pack, vPos[2]);
		WritePackFloat(pack, GetGameTime());
		WritePackCell(pack, entity);									
		CreateTimer(1.0, TimerAirstrike, pack, TIMER_FLAG_NO_MAPCHANGE ); 	
 		CreateTimer(10.0, DeleteParticles, entity, TIMER_FLAG_NO_MAPCHANGE ); 													
	} 
}
/**
* STOCK FUNCTIONS
*/

stock bool:IsWitch(client)
{
	if(client > 0 && IsValidEntity(client) && IsValidEdict(client))
	{
		decl String:strClassName[64];
		GetEdictClassname(client, strClassName, sizeof(strClassName));
		return StrEqual(strClassName, "witch");
	}
	return false;
}

stock IsGhost(client)
{
	return GetEntProp(client, Prop_Send, "m_isGhost",1);
}

stock bool:IsIncapacitated(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

stock bool:IsHanging(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

stock FindAttacker(iClient)
{
	//Pummel
	new iAttacker = GetEntPropEnt(iClient, Prop_Send, "m_pummelAttacker");
	if (iAttacker > 0)
	return iAttacker;
	
	//Pounce
	iAttacker = GetEntPropEnt(iClient, Prop_Send, "m_pounceAttacker");
	if (iAttacker > 0)
	return iAttacker;
	
	//Jockey
	iAttacker = GetEntPropEnt(iClient, Prop_Send, "m_jockeyAttacker");
	if (iAttacker > 0)
	return iAttacker;
	
	//Smoker
	iAttacker = GetEntPropEnt(iClient, Prop_Send, "m_tongueOwner");
	if (iAttacker > 0)
	return iAttacker;
	
	iAttacker = 0;
	return iAttacker;
}

stock bool:IsValidSurvivor(client, bool:isAlive = false) {
	if(client >= 1 && client <= MaxClients && GetClientTeam(client) == 2 && IsClientConnected(client) && IsClientInGame(client) && (isAlive == false || IsPlayerAlive(client)))
	{	 
		return true;
	} 
	return false;
}

stock int CountPlayersWithClass( class ) {
	new count = 0;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
		continue;

		if(ClientData[i].ChosenClass == view_as<ClassTypes>(class))
		count++;
	}

	return count;
}

stock bool:IsInEndingSaferoom(client)
{
	decl String:class[128], Float:pos[3], Float:dpos[3];
	GetClientAbsOrigin(client, pos);
	for (new i = MaxClients+1; i < 2048; i++)
	{
		if (IsValidEntity(i) && IsValidEdict(i))
		{
			GetEdictClassname(i, class, sizeof(class));
			if (StrEqual(class, "prop_door_rotating_checkpoint"))
			{
				GetEntPropString(i, Prop_Data, "m_ModelName", class, sizeof(class));
				if (StrContains(class, "checkpoint_door_02") != -1)
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", dpos);
					if (GetVectorDistance(pos, dpos) <= 600.0)
					return true;
				}
			}
		}
	}
	return false;
}

stock bool:IsPlayerInSaferoom(client)
{
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	return g_bInSaferoom[client] || GetVectorDistance(g_SpawnPos[client], pos) <= 600.0;
}

stock Water_Level:GetClientWaterLevel(client)
{	
	return Water_Level:GetEntProp(client, Prop_Send, "m_nWaterLevel");
}

stock bool:IsClientOnLadder(client)
{	
	new MoveType:movetype = GetEntityMoveType(client);
	
	if (movetype == MOVETYPE_LADDER)
	return true;
	
	return false;
}

public int getDebugMode() {
	return DEBUG_MODE;
}

public setDebugMode(int mode) {
	DEBUG_MODE=mode;
}

///////////////////////////////////////////////////////////////////////////////////
// Parachute 
///////////////////////////////////////////////////////////////////////////////////

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2)
	return Plugin_Continue;
	
	new flags = GetEntityFlags(client);
	
	if (!(buttons & IN_DUCK) || !(flags & FL_ONGROUND)) {
		ClientData[client].HideStartTime= GetGameTime();
		ClientData[client].HealStartTime= GetGameTime();
	}

	if (IsFakeClient(client) || IsHanging(client) || IsIncapacitated(client) || FindAttacker(client) > 0 || IsClientOnLadder(client) || GetClientWaterLevel(client) > Water_Level:WATER_LEVEL_FEET_IN_WATER)
	return Plugin_Continue;
	
	if (ClientData[client].ChosenClass == athlete)
	{
		if (buttons & IN_JUMP && flags & FL_ONGROUND )
		{
			PushEntity(client, Float:{-90.0,0.0,0.0}, GetConVarFloat(ATHLETE_JUMP_VEL));
			flags &= ~FL_ONGROUND;
			SetEntityFlags(client,flags);

		}

		if(parachuteEnabled.BoolValue == false) return Plugin_Continue;

		if(g_bParachute[client])
		{
			if(!(buttons & IN_USE) || !IsPlayerAlive(client))
			{
				DisableParachute(client);
				return Plugin_Continue;
			}

			float fVel[3];
			GetEntDataVector(client, g_iVelocity, fVel);

			if(fVel[2] >= 0.0)
			{
				DisableParachute(client);
				return Plugin_Continue;
			}

			if(GetEntityFlags(client) & FL_ONGROUND)
			{
				DisableParachute(client);
				return Plugin_Continue;
			}
			
			float fOldSpeed = fVel[2];

			if(fVel[2] < 100.0 * -1.0) fVel[2] = 100.0 * -1.0;

			if(fOldSpeed != fVel[2])
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVel);
		}
		else
		{
			if(!(buttons & IN_USE) || !IsPlayerAlive(client))
			return Plugin_Continue;

			if(GetEntityFlags(client) & FL_ONGROUND)
			return Plugin_Continue;

			float fVel[3];
			GetEntDataVector(client, g_iVelocity, fVel);

			if(fVel[2] >= 0.0)
			return Plugin_Continue;

			int iEntity = CreateEntityByName("prop_dynamic_override"); 
			DispatchKeyValue(iEntity, "model", g_bLeft4Dead2 ? PARACHUTE : FAN_BLADE);
			DispatchSpawn(iEntity);
			
			SetEntityMoveType(iEntity, MOVETYPE_NOCLIP);

			float ParachutePos[3], ParachuteAng[3];
			GetClientAbsOrigin(client, ParachutePos);
			GetClientAbsAngles(client, ParachuteAng);
			ParachutePos[2] += 80.0;
			ParachuteAng[0] = 0.0;

			TeleportEntity(iEntity, ParachutePos, ParachuteAng, NULL_VECTOR);
			
			int R = GetRandomInt(0, 255), G = GetRandomInt(0, 255), B = GetRandomInt(0, 255); 
			SetEntProp(iEntity, Prop_Send, "m_nGlowRange", 1000);
			SetEntProp(iEntity, Prop_Send, "m_iGlowType", 3);
			SetEntProp(iEntity, Prop_Send, "m_glowColorOverride", R + (G * 256) + (B * 65536));
			SetEntPropFloat(iEntity, Prop_Data, "m_flModelScale", 0.3);

			SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
			SetEntityRenderColor(iEntity, 255, 255, 255, 2);
			SetVariantString("!activator");
			AcceptEntityInput(iEntity, "SetParent", client);
			g_iParaEntRef[client] = EntIndexToEntRef(iEntity);
			g_bParachute[client] = true;
		}

	}	
	ClientData[client].LastButtons = buttons;
	
	return Plugin_Continue;
}

public void RotateParachute(int index, float value, int axis)
{
	if (IsValidEntity(index))
	{
		float s_rotation[3];
		GetEntPropVector(index, Prop_Data, "m_angRotation", s_rotation);
		s_rotation[axis] += value;
		TeleportEntity( index, NULL_VECTOR, s_rotation, NULL_VECTOR);
	}
}

public void DisableParachute(int client)
{
	int iEntity = EntRefToEntIndex(g_iParaEntRef[client]);
	if(iEntity != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(iEntity, "ClearParent");
		AcceptEntityInput(iEntity, "kill");
	}

	ParachuteDrop(client);
	g_bParachute[client] = false;
	g_iParaEntRef[client] = INVALID_ENT_REFERENCE;
}

public void ParachuteDrop(int client)
{
	if (!IsClientInGame(client))
	return;
	if( !g_bLeft4Dead2 ) StopSound(client, SNDCHAN_STATIC, SOUND_HELICOPTER);	
}

///////////////////////////////////////////////////////////////////////////////////
// Invisibility
///////////////////////////////////////////////////////////////////////////////////

public bool:IsPlayerHidden(client) 
{
	if (ClientData[client].ChosenClass == saboteur && (GetGameTime() - ClientData[client].HideStartTime) >= (GetConVarFloat(SABOTEUR_INVISIBLE_TIME))) 
	{
		return true;
	}
	return false;
}

public Action:Hook_SetTransmit(entity, client) 
{ 
	if (DEBUG_MODE) {
		//	PrintToChatAll("client %i entity %i, client is %s", client, entity, g_bHide[client] ? "hidden" : "not hidden");
	}
	return !(entity < MAXPLAYERS && g_bHide[entity] == true && client != entity) ? Plugin_Continue : Plugin_Handled; 
}

public bool IsPlayerVisible(client) {
	return g_bHide[client] ? true:false;
}

public Action:HidePlayer(client)
{
	g_bHide[client] = !g_bHide[client];
	PrintHintText(client, "You are %s", g_bHide[client] ? "invisible" : "visible again");
	return Plugin_Handled;
}

public Action:UnhidePlayer(client)
{
	if (g_bHide[client] == true) HidePlayer(client);
	g_bHide[client] = false;
}
