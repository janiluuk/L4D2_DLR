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
#define PLUGIN_VERSION "1.6"
#define PLUGIN_IDENTIFIER "dlr_talents_2023"
#pragma semicolon 1
#define DEBUG 0
#define DEBUG_LOG 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

/**
* CONFIGURABLE VARIABLES
* Feel free to change the following code-related values.
*/

/// MENU AND UI RELATED STUFF

static const String:MENU_OPTIONS[][] =
{
	"None",
	"Soldier",
	"Athlete",
	"Medic",
	"Saboteur",
	"Commando",
	"Engineer",
	"Brawler"
};

static const String:ClassTips[][] =
{
	", Is a noob who didnt pick a class.",
	", He can shoot fast, takes less damage and moves faster.",
	", He can Jump high.",
	", He can heal his team by crouching, heal and revive faster and drop supplies. ",
	", He is invisible while hes crouched and drops mines",
	", He does loads of damage and has fast reload.",
	", He can drop auto turrets and ammo supplies.",
	", He has lots of health."
};

// How long should the Class Select menu stay open?
static const MENU_OPEN_TIME = view_as<int>(9999);
static bool:DEBUG_MODE = false;

// API
new Handle:g_hfwdOnSpecialSkillUsed;
new Handle:g_hfwdOnCustomCommand;
new Handle:g_hfwdOnPlayerClassChange;

new g_iSkillCounter = -1;
new Handle:g_hSkillArray = INVALID_HANDLE;
new Handle:g_hSkillTypeArray = INVALID_HANDLE;

//Menu Handlers
new Handle:g_hSkillMenu = INVALID_HANDLE;

//Forward Handlers
new Handle:g_hOnSkillSelected = INVALID_HANDLE;

//Player Related Variables
new g_iPlayerSkill[MAXPLAYERS+1];

//Class variables
// What formatting string to use when printing to the chatbox
#define PRINT_PREFIX 	"\x05[DLR] \x01" 

/// SOUNDS AND OTHER
/// PRECACHE DATA

#define STOMP_SOUND_PATH		"player/survivor/hit/rifle_swing_hit_infected9.wav"
#define SOUND_CLASS_SELECTED "ui/pickup_misc42.wav" /**< What sound to play when a class is selected. Do not include "sounds/" prefix. */
#define SOUND_DROP_BOMB "ui/beep22.wav"
#define SOUND_BUTTON2	"ui/menu_countdown.wav"
#define AMMO_PILE "models/props/terror/ammo_stack.mdl"
#define MODEL_INCEN	"models/props/terror/incendiary_ammo.mdl"
#define MODEL_EXPLO	"models/props/terror/exploding_ammo.mdl"
#define MODEL_SPRITE "models/sprites/glow01.spr"
#define PARTICLE_DEFIB "item_defibrillator_body"
#define PARTICLE_ELMOS "st_elmos_fire_cp0"
#define MODEL_MINE "models/props_buildables/mine_02.mdl"

/** Stomping **/

#define ANIM_SEQUENCES_DOWNED_BEGIN		128
#define ANIM_SEQUENCES_DOWNED_END		132
#define ANIM_SEQUENCE_WALLED			138
#define DOWNED_ANIM_MIN_CYCLE			0.27
#define DOWNED_ANIM_MAX_CYCLE			0.53
#define STOMP_MOVE_PENALTY				0.25
#define ENTPROP_ANIM_SEQUENCE	"m_nSequence"
#define ENTPROP_ANIM_CYCLE		"m_flCycle"
#define SPEED_MODIFY_ENTPROP	"m_flVelocityModifier"

/**
* OTHER GLOBAL VARIABLES
* Do not change these unless you know what you are doing.
*/

const NONE = view_as<int>(0);
const SOLDIER = view_as<int>(1);
const ATHLETE= view_as<int>(2);
const MEDIC=view_as<int>(3);
const SABOTEUR=view_as<int>(4);
const COMMANDO=view_as<int>(5);
const ENGINEER=view_as<int>(6);
const BRAWLER=view_as<int>(7);
const MAXCLASSES=view_as<int>(8);

enum SpecialSkill {
	No_Skill = 0,
	F18_airstrike, 
	Berzerk,
	Grenade,
	Multiturret
}

enum SkillType {
	On_Demand = 0,
	Perk
}

enum struct PlayerInfo 
{
	int SpecialsUsed;
	float HideStartTime;
	float HealStartTime;
	int LastButtons;
	int ChosenClass;
	float LastDropTime;
	int SpecialDropInterval;
	int SpecialLimit;
	SpecialSkill SpecialSkill;			
	char EquippedGun[64];
}

PlayerInfo ClientData[MAXPLAYERS+1];

// API
bool g_bLeft4Dead2, g_bLateLoad;
bool g_bAirstrike, g_bAirstrikeValid;

// Rapid fire variables
new g_iRI[MAXPLAYERS+1] = { -1 },
g_iRC, g_iEi[MAXPLAYERS+1] = { -1 },
Float:g_fNT[MAXPLAYERS+1] = { -1.0 },
g_iNPA = -1,
g_oAW = -1;

// Speed vars
new g_ioLMV;

// Commando vars
new g_ioPR = -1;
new g_iVMStartTimeO  = -1;
new g_iViewModelO = -1;
new g_ioNA = -1;
new g_ioTI = -1;
new g_iSSD = -1;
new g_iSID = -1;
new g_iSED = -1;
new g_iSRS = -1;
new g_iShovePenalty = 0;


// Parachute

bool g_bParachute[MAXPLAYERS+1];
int g_iVelocity = -1, g_iParaEntRef[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};

static char g_sModels[2][] =
{
	"models/props_swamp/parachute01.mdl",
	"models/props/de_inferno/ceiling_fan_blade.mdl"
};

enum Water_Level
{
	WATER_LEVEL_NOT_IN_WATER = 0,
	WATER_LEVEL_FEET_IN_WATER,
	WATER_LEVEL_WAIST_IN_WATER,
	WATER_LEVEL_HEAD_IN_WATER
};

// Bomb related stuff
new g_BeamSprite = -1, g_HaloSprite = -1;
new redColor[4]		= {255, 75, 75, 255};
new greenColor[4]	= {75, 255, 75, 255};
new RndSession;

#define SOUND_HELICOPTER "vehicles/airboat/fan_blade_fullthrottle_loop1.wav"
#define PUNCH_SOUND "melee_tonfa_02.wav"
#define SOUND_TUNNEL "ambient/atmosphere/tunnel1.wav"
#define SOUND_SQUEAK "ambient/random_amb_sfx/randommetalsqueak01.wav"
#define SOUND_NOISE	"ambient/atmosphere/noise2.wav"
#define EXPLOSION_SOUND "weapons/hegrenade/explode5.wav"
#define EXPLOSION_SOUND2 "weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav"
#define EXPLOSION_SOUND3 "ambient/explosions/explode_3.wav"
#define EXPLOSION_PARTICLE "gas_explosion_main_fallback"
#define EXPLOSION_PARTICLE2 "weapon_grenade_explosion"
#define EXPLOSION_PARTICLE3 "explosion_huge_b"
#define EFIRE_PARTICLE "gas_explosion_ground_fire"
#define MEDIC_GLOW "fire_medium_01_glow"
#define BOMB_GLOW "fire_medium_01_glow"
#define ENGINEER_MACHINE_GUN "models/w_models/weapons/50cal.mdl"
#define SPRITE_GLOW "sprites/blueglow1.vmt"

// Convars (change these via the created cfg files)

// CLASS RELATED STUFF

// Max classes
new Handle:MAX_SOLDIER;
new Handle:MAX_ATHLETE;
new Handle:MAX_MEDIC;
new Handle:MAX_SABOTEUR;
new Handle:MAX_COMMANDO;
new Handle:MAX_ENGINEER;
new Handle:MAX_BRAWLER;

// Everyone
new Handle:NONE_HEALTH;
new Handle:SOLDIER_HEALTH;
new Handle:ATHLETE_HEALTH;
new Handle:MEDIC_HEALTH;
new Handle:SABOTEUR_HEALTH;
new Handle:COMMANDO_HEALTH;
new Handle:ENGINEER_HEALTH;
new Handle:BRAWLER_HEALTH;

// Health
new Handle:REVIVE_DURATION;
new Handle:HEAL_DURATION;
new Handle:REVIVE_HEALTH;
new Handle:PILLS_HEALTH_BUFFER;
new Handle:ADRENALINE_DURATION;
new Handle:ADRENALINE_HEALTH_BUFFER;

// Soldier
new Handle:SOLDIER_FIRE_RATE;
new Handle:SOLDIER_DAMAGE_REDUCE_RATIO;
new Handle:SOLDIER_SPEED;
new Handle:SOLDIER_SHOVE_PENALTY;
new Handle:SOLDIER_MAX_AIRSTRIKES;

// Athlete
new Handle:ATHLETE_SPEED;
new Handle:ATHLETE_JUMP_VEL;

// Medic
new Handle:MEDIC_HEAL_DIST;
new Handle:MEDIC_HEALTH_VALUE;
new Handle:MEDIC_MAX_ITEMS;
new Handle:MEDIC_HEALTH_INTERVAL;
new Handle:MEDIC_HEAL_RATIO;
new Handle:MEDIC_REVIVE_RATIO;
new Handle:MEDIC_MAX_BUILD_RANGE;

// Saboteur
new Handle:SABOTEUR_INVISIBLE_TIME;
new Handle:SABOTEUR_BOMB_ACTIVATE;
new Handle:SABOTEUR_BOMB_RADIUS;
new Handle:SABOTEUR_MAX_BOMBS;
new Handle:SABOTEUR_BOMB_TYPES;
new Handle:SABOTEUR_BOMB_DAMAGE_SURV;
new Handle:SABOTEUR_BOMB_DAMAGE_INF;
new Handle:SABOTEUR_BOMB_POWER;
new Handle:SABOTEUR_ENABLE_NIGHT_VISION;

// Commando
new Handle:COMMANDO_DAMAGE;
new Handle:COMMANDO_RELOAD_RATIO;
new Handle:COMMANDO_DAMAGE_RIFLE;
new Handle:COMMANDO_DAMAGE_GRENADE;
new Handle:COMMANDO_DAMAGE_SHOTGUN;
new Handle:COMMANDO_DAMAGE_SNIPER;
new Handle:COMMANDO_DAMAGE_HUNTING;
new Handle:COMMANDO_DAMAGE_PISTOL;
new Handle:COMMANDO_DAMAGE_SMG;
new Handle:COMMANDO_ENABLE_STUMBLE_BLOCK;
new Handle:COMMANDO_ENABLE_STOMPING;
new Handle:COMMANDO_STOMPING_SLOWDOWN;

// Engineer
new Handle:ENGINEER_MAX_BUILDS;
new Handle:ENGINEER_MAX_BUILD_RANGE;

// Saboteur, Engineer, Medic
new Handle:MINIMUM_DROP_INTERVAL;
new Handle:MINIMUM_AIRSTRIKE_INTERVAL;

// Saferoom checks for saboteur
new bool:g_bInSaferoom[MAXPLAYERS+1];
new Float:g_SpawnPos[MAXPLAYERS+1][3];
new Handle:g_VarFirstAidDuration = INVALID_HANDLE;
new Handle:g_VarReviveDuration = INVALID_HANDLE;

new Float:FirstAidDuration;
new Float:ReviveDuration;
new bool:BombActive = false;

new Handle:SABOTEUR_ACTIVE_BOMB_COLOR;

// Last class taken
new LastClassConfirmed[MAXPLAYERS+1];

new bool:BombIndex[16];
new bool:RoundStarted =false;
new bool:ClassHint =false;
new bool:InvisibilityHint = false;
new bool:MedicHint = false;
new Float:mineWarning[16];

new BombHintTimestamp = 0;
new InvisibilityTimestamp = 0;
new bool:disableInfected = false;
new bool:g_bHide[MAXPLAYERS+1];

ConVar healthModEnabled;
ConVar parachuteEnabled;

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "DLR / Ken / Neil / Spirit / panxiaohai / Yani",
	description = "Incorporates Survivor Classes",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=273312"
};

// ====================================================================================================
//					L4D2 - Native
// ====================================================================================================

native void F18_ShowAirstrike(float origin[3], float direction);

/**
* PLUGIN LOGIC
*/

public OnPluginStart( )
{
	// Api

	g_hfwdOnPlayerClassChange = CreateGlobalForward("OnPlayerClassChange", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hfwdOnSpecialSkillUsed = CreateGlobalForward("OnSpecialSkillUsed", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hfwdOnCustomCommand = CreateGlobalForward("OnCustomCommand", ET_Ignore, Param_String, Param_Cell, Param_Cell, Param_Cell);
	//Create a Class Selection forward
	g_hOnSkillSelected = CreateGlobalForward("OnSkillSelected", ET_Event, Param_Cell, Param_Cell);

	//Create menu and set properties
	g_hSkillMenu = CreateMenu(DlrSkillMenuHandler);

	//Create a Class Selection forward
	SetMenuTitle(g_hSkillMenu, "Registered classes");
	SetMenuExitButton(g_hSkillMenu, true);
	g_hSkillArray = CreateArray(16);
	g_hSkillTypeArray = CreateArray(16);

	// Offsets
	g_iNPA = FindSendPropInfo("CBaseCombatWeapon", "m_flNextPrimaryAttack");
	g_oAW = FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon");
	g_ioLMV = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	g_ioPR = FindSendPropInfo("CBaseCombatWeapon", "m_flPlaybackRate");
	g_ioNA = FindSendPropInfo("CTerrorPlayer", "m_flNextAttack");
	g_ioTI = FindSendPropInfo("CTerrorGun", "m_flTimeWeaponIdle");
	g_iSSD = FindSendPropInfo("CBaseShotgun", "m_reloadStartDuration");
	g_iSID = FindSendPropInfo("CBaseShotgun", "m_reloadInsertDuration");
	g_iSED = FindSendPropInfo("CBaseShotgun", "m_reloadEndDuration");
	g_iSRS = FindSendPropInfo("CBaseShotgun", "m_reloadState");
	g_iVMStartTimeO = FindSendPropInfo("CTerrorViewModel","m_flLayerStartTime");
	g_iViewModelO = FindSendPropInfo("CTerrorPlayer","m_hViewModel");
	g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");

	// Hooks
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundChange);
	HookEvent("round_start_post_nav", Event_RoundChange);
	HookEvent("mission_lost", Event_RoundChange);
	HookEvent("weapon_reload", Event_RelCommandoClass);
	HookEvent("player_entered_checkpoint", Event_EnterSaferoom);
	HookEvent("player_left_checkpoint", Event_LeftSaferoom);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_left_start_area",Event_LeftStartArea);
	HookEvent("heal_begin", event_HealBegin, EventHookMode_Pre);
	HookEvent("revive_begin", event_ReviveBegin, EventHookMode_Pre);
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("server_cvar", Event_ServerCvar, EventHookMode_Pre);

	// Concommands
	RegConsoleCmd("sm_class", CmdClassMenu, "Shows the class selection menu");
	RegConsoleCmd("sm_classinfo", CmdClassInfo, "Shows class descriptions");
	RegConsoleCmd("sm_classes", CmdClasses, "Shows class descriptions");
	RegConsoleCmd("sm_dlrm", CmdDlrMenu, "Debug & Manage");
	RegConsoleCmd("sm_hide", HideCommand, "Hide player");
	RegConsoleCmd("sm_yay", GrenadeCommand, "Test grenade");

	// Convars
	new Handle:hVersion = CreateConVar("talents_version", PLUGIN_VERSION, "Version of this release", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);

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
	
	SOLDIER_FIRE_RATE = CreateConVar("talents_soldier_fire_rate", "0.6666", "How fast the soldier should fire. Lower values = faster");
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
	SABOTEUR_BOMB_TYPES = CreateConVar("talents_saboteur_bomb_types", "1", "Define max 7 mine types to use. (2,10,5,15,12,16,9 are nice combo) 1=Bomb, 2=Cluster, 3=Firework, 4=Smoke, 5=Black Hole, 6=Flashbang, 7=Shield, 8=Tesla, 9=Chemical, 10=Freeze, 11=Medic, 12=Vaporizer, 13=Extinguisher, 14=Glow, 15=Anti-Gravity, 16=Fire Cluster, 17=Bullets, 18=Flak, 19=Airstrike, 20=Weapon");
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
	COMMANDO_RELOAD_RATIO = CreateConVar("talents_commando_reload_ratio", "0.44", "Ratio for how fast a Commando should be able to reload");
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
}

/* Temporarily hardcoded until get config right */

public AssignSkills(client)
{	
	if (client < 1 || client > MaxClients) return;

	g_iPlayerSkill[client] = -1;

	switch (ClientData[client].ChosenClass) {
		case ENGINEER:
		{
			int skillId = FindSkillByName("Multiturret");
			if (skillId > -1) {
				g_iPlayerSkill[client] = skillId;
			}
		}

		case SOLDIER:
		{
			int skillId = FindSkillByName("Airstrike");
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
	CreateNative("OnSpecialSkillSuccess", Native_OnSpecialSkillSuccess);
	CreateNative("OnSpecialSkillFail", Native_OnSpecialSkillFail);
	CreateNative("GetPlayerSkillID", Native_GetPlayerSkillID);
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

// Register skill
public Native_RegisterSkill(Handle:plugin, numParams)
{
	char szItemInfo[3];
	int type;
	int len;
	GetNativeStringLength(1, len);
 
	if (len <= 0)
	{
		return 0;
	}
 
	char[] szSkillName = new char[len + 1];
	GetNativeString(1, szSkillName, len + 1);

	if(++g_iSkillCounter <= MAXCLASSES)
	{
		IntToString(g_iSkillCounter, szItemInfo, sizeof(szItemInfo));
		PushArrayString(g_hSkillArray, szSkillName);
		int index = FindStringInArray(g_hSkillArray, szSkillName);		
		type = GetNativeCell(2);
		PushArrayCell(g_hSkillTypeArray, type);
		AddMenuItem(g_hSkillMenu, szItemInfo, szSkillName);
		PrintDebugAll("Registered skill %s with type %i and index %i", szSkillName, type, index);
		return index;
	}
	
	return -1;
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
//					DLR - Multiturret
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

	for (int i = 0; i < 2; i++)
		PrecacheModel(g_sModels[i]);

	for (int i = 0; i < MAXPLAYERS +1; i++)
		g_bHide[i] = false;
		
	g_iShovePenalty = FindSendPropInfo("CTerrorPlayer", "m_iShovePenalty");
}

public void OnMapEnd()
{
	// Cache
	ClearCache();
	RoundStarted=false;
	RndSession = 0;
}

public OnClientPutInServer(client)
{
	if (!client || !IsValidEntity(client) || !IsClientInGame(client))
	return;

	g_bHide[client] = false; 
	DisableAllUpgrades(client);
	ResetClientVariables(client);
	RebuildCache();
}

public Action:TimerLoadGlobal(Handle:hTimer, any:client)
{
	if (!client || !IsValidEntity(client) || !IsClientInGame(client))
	return;
	
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamagePre);	
}

public Action:TimerLoadClient(Handle:hTimer, any:client)
{
	if (!client ||  !IsValidEntity(client) || !IsClientInGame(client))
	return;
	
	if (RoundStarted == false && !IsPlayerInSaferoom(client) && !IsInEndingSaferoom(client)) {
		RoundStarted = true;
	}

	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
	SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
	SDKHook(client, SDKHook_WeaponEquipPost, OnClientWeaponEquip);
	SDKHook(client, SDKHook_WeaponDropPost, OnClientWeaponEquip);

	ResetClientVariables(client);
	RebuildCache();		
}

public Action:OnWeaponDrop(client, weapon)
{
	RebuildCache();
}

public Action:OnWeaponSwitch(client, weapon)
{
	RebuildCache();
}

public Action:OnWeaponEquip(client, weapon)
{
	RebuildCache();
}

public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_WeaponEquipPost, OnClientWeaponEquip);
	SDKUnhook(client, SDKHook_WeaponDropPost, OnClientWeaponEquip);
	RebuildCache();
	ResetClientVariables(client);

}

public Action:TimerThink(Handle:hTimer, any:client)
{
	if (!IsValidEntity(client) || !IsClientInGame(client) || IsFakeClient(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2)
	{
		return Plugin_Stop;
	}
	
	new buttons = GetClientButtons(client);
	new Float:fCanDropTime = (GetGameTime() - ClientData[client].LastDropTime);
	new bool:CanDrop = (fCanDropTime >= ClientData[client].SpecialDropInterval);
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	int iDropTime = RoundToFloor(fCanDropTime);

	switch (ClientData[client].ChosenClass)
	{
		case ATHLETE:
		{	
			SetEntDataFloat(client, g_ioLMV, GetConVarFloat(ATHLETE_SPEED), true);
		}
		
		case SABOTEUR:
		{
			if (BombActive == true) {

				if (iDropTime < GetConVarInt(SABOTEUR_BOMB_ACTIVATE)) {

						PrintHintText(client, "Mine is arming in %i seconds", client, GetConVarInt(SABOTEUR_BOMB_ACTIVATE) - iDropTime);
					
				}
				else if (iDropTime == GetConVarInt(SABOTEUR_BOMB_ACTIVATE)) {
										
					if (BombHintTimestamp != iDropTime) {
						PrintHintTextToAll("%N's mine is now armed!", client);
						BombHintTimestamp = iDropTime;
					}
				}
			}

			if (buttons & IN_DUCK)
			{

				float hidingTime = GetGameTime() - ClientData[client].HideStartTime;

				if (hidingTime >= GetConVarFloat(SABOTEUR_INVISIBLE_TIME)) {
					if (InvisibilityTimestamp != RoundToFloor(hidingTime) && InvisibilityHint == false) 
					{
						SetEntDataFloat(client, g_ioLMV, 1.8, true);

						HidePlayer(client);

						//SetEntityRenderFx(client, RENDERFX_PULSE_SLOW);
						InvisibilityTimestamp = RoundToFloor(hidingTime);
						InvisibilityHint = true;

					}
				}
				if (hidingTime < GetConVarFloat(SABOTEUR_INVISIBLE_TIME) && (RoundToFloor(hidingTime) > 2)){
					GlowPlayer(client, "Blue", FX:FxHologram);

					if (InvisibilityTimestamp != RoundToFloor(hidingTime)) {
						PrintHintText(client,"Becoming invisible in %i seconds", RoundToFloor(GetConVarFloat(SABOTEUR_INVISIBLE_TIME) - hidingTime));
						InvisibilityTimestamp = RoundToFloor(hidingTime);
					}
				}
			}
			else
			{
				if (IsPlayerVisible(client) == false)  
				{
					UnhidePlayer(client);
					SetRenderProperties(client);
				}
				SetEntDataFloat(client, g_ioLMV, 1.0, true);

				InvisibilityHint = false;
			}
			
			if (buttons & IN_SPEED)
			{
				if (CanDrop == false && (iDropTime > 0 && iDropTime < GetConVarInt(MINIMUM_DROP_INTERVAL))) 
				{
					if (!(ClientData[client].LastButtons & IN_SPEED))
						PrintHintText(client ,"Wait %i seconds to deploy", (GetConVarInt(MINIMUM_DROP_INTERVAL) - iDropTime));
				} else {

					if (CanDrop == true && !IsPlayerInSaferoom(client) && !IsInEndingSaferoom(client))
					{
						if (ClientData[client].SpecialsUsed >= GetConVarInt(SABOTEUR_MAX_BOMBS)) {
							PrintHintText(client ,"You're out of mines");
						} else {
							CreatePlayerSaboteurMenu(client);
						}
					}
				}
			}
		}
			
		case MEDIC:
		{
			if (buttons & IN_SPEED)
			{
				if (CanDrop) 
				{	
					if (ClientData[client].SpecialsUsed > GetConVarInt(MEDIC_MAX_ITEMS)) {
						PrintHintText(client ,"You're out of items (Max %i)", GetConVarInt(MEDIC_MAX_ITEMS));
					}
					if (ClientData[client].SpecialsUsed < GetConVarInt(MEDIC_MAX_ITEMS))
					{	
						CreatePlayerMedicMenu(client);	
					}
				}
				else if (CanDrop == false && (iDropTime < GetConVarInt(MINIMUM_DROP_INTERVAL))) {
					PrintHintText(client ,"Wait %i seconds to deploy", (GetConVarInt(MINIMUM_DROP_INTERVAL) - iDropTime));
				} 		
			}

			if (buttons & IN_DUCK) 
			{
				SetEntDataFloat(client, g_ioLMV, 1.7, true);

				if ((GetGameTime() - ClientData[client].HealStartTime) >= 2.5) {
					if (MedicHint == false) {
						PrintHintTextToAll("%N is healing everyone around him!", client);
						MedicHint = true;
					}
				}
			} else {
				SetEntDataFloat(client, g_ioLMV, 1.0, true);					
				MedicHint = false;
			}
		}
			
		case ENGINEER:
		{

			if (buttons & IN_SPEED && RoundStarted == true)// && ClientData[client].SpecialsUsed < GetConVarInt(ENGINEER_MAX_BUILDS)) 
			{	
				if (CanDrop == false && (iDropTime < GetConVarInt(MINIMUM_DROP_INTERVAL))) {
					PrintHintText(client ,"Wait %i seconds to deploy again", (GetConVarInt(MINIMUM_DROP_INTERVAL) - iDropTime));
				}
				if (CanDrop == true) {
					if(ClientData[client].SpecialsUsed < GetConVarInt(ENGINEER_MAX_BUILDS))
					{
						CreatePlayerEngineerMenu(client);
					}
					else
					{
						PrintHintText(client ,"You're out of items (Max %i)", GetConVarInt(ENGINEER_MAX_BUILDS));
					}
				}					
			}
		}
		case SOLDIER:
		{
			SetEntDataFloat(client, g_ioLMV, GetConVarFloat(SOLDIER_SPEED), true);

			if (buttons & IN_SPEED)
			{
				if (g_bAirstrike && g_bAirstrikeValid == false) {

					ClientData[client].LastButtons = buttons;
					return Plugin_Continue;
				}	
				char pendingMessage[128] = "Wait %d seconds to order new airstrike.";
				
				if (g_bAirstrike && g_bAirstrikeValid && canUseSpecialSkill(client, pendingMessage)) {
					g_bAirstrikeValid = false;
					CreateAirStrike(client);
					useSpecialSkill(client, 0);
					ClientData[client].LastDropTime = GetGameTime();
				}
			}
		}
	}

	ClientData[client].LastButtons = buttons;
	return Plugin_Continue;
}

// Inform other plugins.
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

new String:Gauge1[2] = "-";
new String:Gauge3[2] = "#";

public ShowBar(client, String:msg[], Float:pos, Float:max)
{
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

public ClearCache()
{
	g_iRC = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		g_iRI[i]= -1;
		g_iEi[i] = -1;
		g_fNT[i]= -1.0;
	}
}

public RebuildCache()
{
	ClearCache();

	if (!IsServerProcessing())
	return;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && ClientData[i].ChosenClass == SOLDIER)
		{
			g_iRC++;
			g_iRI[g_iRC] = i;
		}
	}
}

public Event_RoundChange(Handle:event, String:name[], bool:dontBroadcast)
{
	for (new i = 1; i < MAXPLAYERS; i++)
	{
		ResetClientVariables(i);
		LastClassConfirmed[i] = 0;
		DisableAllUpgrades(i);		
	}
	
	RndSession++;
	RoundStarted = false;
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
			ClientData[client].ChosenClass = LastClassConfirmed[client];
			else
			CreateTimer(1.0, CreatePlayerClassMenuDelay, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		
		CreateTimer(0.3, TimerLoadGlobal, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	RebuildCache();
}

public Event_PlayerHurt(Handle:hEvent, String:sName[], bool:bDontBroadcast)
{
	RebuildCache();
}

public Event_PlayerDeath(Handle:hEvent, String:sName[], bool:bDontBroadcast)
{
	RebuildCache();
	
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2) DisableAllUpgrades(client);

	ResetClientVariables(client);
}

public Event_EnterSaferoom(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_bInSaferoom[client] = true;
}

public Event_LeftSaferoom(Handle:event, String:event_name[], bool:dontBroadcast)
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
		ClientData[client].ChosenClass = LastClassConfirmed[client];
		PrintToChat(client, "You are currently a \x04%s", MENU_OPTIONS[LastClassConfirmed[client]]);
	}
}

///////////////////////////////////////////////////////////////////////////////////
// Class selections
///////////////////////////////////////////////////////////////////////////////////

public Action:CmdClassInfo(client, args)
{
	PrintToChat(client,"\x05Soldier\x01 = Has faster attack rate, runs faster and takes less damage");
	PrintToChat(client,"\x05Athlete\x01 = Jumps higher, has parachute.");
	PrintToChat(client,"\x05Medic\x01 = Heals others, plants medical supplies. Faster revive & heal speed");
	PrintToChat(client,"\x05Saboteur\x01 = Can go invisible, plants powerful mines and throws special grenades");
	PrintToChat(client,"\x05Commando\x01 = Has fast reload, deals extra damage");
	PrintToChat(client,"\x05Engineer\x01 = Drops auto turrets and ammo");
	PrintToChat(client,"\x05Brawler\x01 = Has Lots of health");	
}

public Action:CreatePlayerClassMenuDelay(Handle:hTimer, any:client)
{
	CreatePlayerClassMenu(client);
}

public Action:CmdClasses(client, args)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if(ClientData[i].ChosenClass != NONE)
		{
			PrintToChatAll("\x04%N\x01 : is a %s",i,MENU_OPTIONS[ClientData[i].ChosenClass]);
		}
	}
}

public bool:CreatePlayerClassMenu(client)
{
	new Handle:hPanel;
	decl String:buffer[256];
	
	if((hPanel = CreatePanel()) == INVALID_HANDLE)
	{
		LogError("Cannot create hPanel on CreatePlayerClassMenu");
		return false;
	}
	
	if (!client ||  !IsClientInGame(client) || GetClientTeam(client) != 2) {
		return false;
	}
	
	// if client has a class already and round has started, dont give them the menu
	if (ClientData[client].ChosenClass != NONE && RoundStarted == true)
	{
		PrintToChat(client,"Round has started, your class is locked, You are a %s",MENU_OPTIONS[ClientData[client].ChosenClass]);
		return false;
	}
	
	if(IsClientInGame(client) && ClientData[client].ChosenClass == NONE && RoundStarted == false)
	{
		setPlayerDefaultHealth(client);
	}
	
	SetPanelTitle(hPanel, "Select Your Class");
	
	for (new i = 1; i < MAXCLASSES; i++)
	{
		if( GetMaxWithClass(i) >= 0 )
		Format(buffer, sizeof(buffer), "%i/%i %s", CountPlayersWithClass(i), GetMaxWithClass(i),  MENU_OPTIONS[i]);
		else
		Format(buffer, sizeof(buffer), "%s", MENU_OPTIONS[i]);
		DrawPanelItem(hPanel, buffer);
	}
	
	DrawPanelText(hPanel, " ");
	DrawPanelItem(hPanel, "Exit");
	
	SendPanelToClient(hPanel, client, PanelHandler_SelectClass, MENU_OPEN_TIME);
	CloseHandle(hPanel);
	
	return true;
}

public PanelHandler_SelectClass(Handle:menu, MenuAction:action, client, param)
{
	new OldClass;
	OldClass = ClientData[client].ChosenClass;
	
	switch (action)
	{
		case MenuAction_Select:
		{
			if (!client || param >= MAXCLASSES || GetClientTeam(client)!=2 )
			{
				return;
			}
			
			if( GetMaxWithClass( param ) >= 0 && CountPlayersWithClass( param ) >= GetMaxWithClass( param ) && ClientData[client].ChosenClass != param ) 
			{
				PrintToChat( client, "%sThe \x04%s\x01 class is full, please choose another.", PRINT_PREFIX, MENU_OPTIONS[ param ] );
				CreatePlayerClassMenu( client );
			} 
			else
			{
				//DrawConfirmPanel(client, param);
				
				LastClassConfirmed[client] = param;
				ClientData[client].ChosenClass = param;	

				// Inform other plugins.
				Call_StartForward(g_hfwdOnPlayerClassChange);
				Call_PushCell(client);
				Call_PushCell(ClientData[client].ChosenClass);
				Call_PushCell(LastClassConfirmed[client]);
				Call_Finish();				

				PrintToConsole(client, "Class is setting up");
				
				SetupClasses(client, param);
				EmitSoundToClient(client, SOUND_CLASS_SELECTED);
				
				if(OldClass == 0)
				{
					PrintToChatAll("\x04%N\x01 is a \x05%s\x01%s",client,MENU_OPTIONS[param],ClassTips[param]);
				}	
				else
				{
					PrintToChatAll("\x04%N\x01 : class changed from \x05%s\x01 to \x05%s\x01",client,MENU_OPTIONS[OldClass],MENU_OPTIONS[param]);
				}
			}
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
	
	ClientData[client].ChosenClass = class;
	ClientData[client].SpecialDropInterval = GetConVarInt(MINIMUM_DROP_INTERVAL);	
	ClientData[client].SpecialLimit = 5;
	new MaxPossibleHP = GetConVarInt(NONE_HEALTH);
	DisableAllUpgrades(client);

	switch (class)
	{
		case SOLDIER:	
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
		
		case MEDIC:
		{
			PrintHintText(client,"Hold CROUCH to heal others, Press SHIFT to drop medkits & supplies");
			CreateTimer(GetConVarFloat(MEDIC_HEALTH_INTERVAL), TimerDetectHealthChanges, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			ClientData[client].SpecialLimit = GetConVarInt(MEDIC_MAX_ITEMS);
			MaxPossibleHP = GetConVarInt(MEDIC_HEALTH);
		}
		
		case ATHLETE:
		{
			decl String:text[64];
			text = "";
			if (parachuteEnabled.BoolValue) {
				text = "While in air, hold E to use parachute!";
			}
			PrintHintText(client,"You move faster, Hold JUMP to bunny hop! %s", text);
			MaxPossibleHP = GetConVarInt(ATHLETE_HEALTH);
		}
		
		case COMMANDO:
		{
			decl String:text[64];
			text = "";
			if (GetConVarBool(COMMANDO_ENABLE_STUMBLE_BLOCK)) {
				text = ", You're immune to Tank knockdowns";
			} 

			PrintHintText(client,"You have faster reload and cause more damage%s!", text);
			MaxPossibleHP = GetConVarInt(COMMANDO_HEALTH);
		}
		
		case ENGINEER:
		{
			PrintHintText(client,"Press SHIFT to drop ammo supplies and auto turrets!");
			MaxPossibleHP = GetConVarInt(ENGINEER_HEALTH);
			ClientData[client].SpecialLimit = GetConVarInt(ENGINEER_MAX_BUILDS);
		}
		
		case SABOTEUR:
		{

			PrintHintText(client,"Press SHIFT to drop mines! Hold CROUCH over 5 sec to go invisible");
			MaxPossibleHP = GetConVarInt(SABOTEUR_HEALTH);
			ClientData[client].SpecialLimit = GetConVarInt(SABOTEUR_MAX_BOMBS);
			ToggleNightVision(client);
		}
		
		case BRAWLER:
		{
			PrintHintText(client,"You've got lots of health!");
			MaxPossibleHP = GetConVarInt(BRAWLER_HEALTH);
		}
	}

	AssignSkills(client);
	setPlayerHealth(client, MaxPossibleHP);
}

public Action:CmdClassMenu(client, args)
{
	if (GetClientTeam(client) != 2)
	{
		PrintToChat(client, "%sOnly Survivors can choose a class.", PRINT_PREFIX);
		return;
	}
	CreatePlayerClassMenu(client);
}

public int GetMaxWithClass( class ) {

	switch(class) {
		case SOLDIER:
		return GetConVarInt( MAX_SOLDIER );
		case ATHLETE:
		return GetConVarInt( MAX_ATHLETE );
		case MEDIC:
		return GetConVarInt( MAX_MEDIC );
		case SABOTEUR:
		return GetConVarInt( MAX_SABOTEUR );
		case COMMANDO:
		return GetConVarInt( MAX_COMMANDO );
		case ENGINEER:
		return GetConVarInt( MAX_ENGINEER );
		case BRAWLER:
		return GetConVarInt( MAX_BRAWLER );
		default:
		return -1;
	}
}

public int FindSkillByName(char[] name)
{
	int index = FindStringInArray(g_hSkillArray, name);
	return index;
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
		return FindSkillByName(szSkillName);
		
	} else {
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid skill name (%s)", szSkillName);
	}	
}

PlayerIdToSkillName(int client, char[] name, int size)
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

PlayerIdToClassName(int client, char[] name, int size)
{
	if (!client ||  !IsClientInGame(client) || GetClientTeam(client) != 2) {
		return;
	}
	Format(name, size, "%s", MENU_OPTIONS[ClientData[client].ChosenClass]);
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

///////////////////////////////////////////////////////////////////////////////////
// DLR menu
///////////////////////////////////////////////////////////////////////////////////

stock void PrintDebug(int client, const char[] format, any ...)
{
	#if DEBUG || DEBUG_LOG
	static char buffer[192];
	
	VFormat(buffer, sizeof(buffer), format, 2);
	#if DEBUG_LOG
	PrintToConsole(0, "[Debug] %s", buffer);
	LogMessage("%s", buffer);	
	#endif 

	#else
	//suppress "format" never used warning
	if(format[0])
		return;
	else
		return;
	#endif
}

stock void PrintDebugAll(const char[] format, any ...)
{
	#if DEBUG || DEBUG_LOG
	static char buffer[192];
	VFormat(buffer, sizeof(buffer), format, 2);
	#if DEBUG_LOG
	PrintToConsole(0, "[Debug] %s", buffer);
	LogMessage("%s", buffer);
	#endif
	#if DEBUG
	PrintToChatAll("[Debug] %s", buffer);
	#endif
	#else
	if(format[0])
		return;
	else
		return;
	#endif
}

public bool:isAdmin(client)
{
	if (client == 0 && GetUserAdmin(client) == INVALID_ADMIN_ID) { return false; }
	else { return true; }
}

public Action:CmdDlrMenu(client, args)
{
	if (isAdmin(client)) 
		CreateDlrMenu(client);
}

public CreateDlrMenu(client) {

	if (!client)
	return false;
	
	new Handle:hPanel;
	
	if((hPanel = CreatePanel()) == INVALID_HANDLE)
	{
		LogError("Cannot create hPanel on DlrMenu");
		return false;
	}
	
	SetPanelTitle(hPanel, "Functions:");
	DrawPanelItem(hPanel, "Toggle Debug Messages");
	DrawPanelItem(hPanel, "Toggle infected");
	DrawPanelItem(hPanel, "List registered skills");
	DrawPanelText(hPanel, " ");
	DrawPanelItem(hPanel, "Exit");
	SendPanelToClient(hPanel, client, PanelHandler_DlrMenu, MENU_OPEN_TIME);
	CloseHandle(hPanel);
	
	return true;
}

public DlrSkillMenuHandler(Handle:hMenu, MenuAction:action, client, iSkillSelection)
{
    if(action == MenuAction_Select)
    {
        /* Start Function Call */
        Call_StartForward(g_hOnSkillSelected);
        Call_PushCell(client);
        Call_PushCell(iSkillSelection);        
        Call_Finish();
    }
}
public PanelHandler_DlrMenu(Handle:menu, MenuAction:action, client, param)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if( param == 1)
			{
				DEBUG_MODE = (DEBUG_MODE == true) ? false : true;
				PrintHintText(client,"Debug mode is %s", DEBUG_MODE ? "ON" : "OFF");
			}
			if (param == 2) 
			{
				disableInfected = (disableInfected == true) ? false : true;

				if (disableInfected == true) {
					SetConVarInt(FindConVar("director_no_bosses"), 1);
					SetConVarInt(FindConVar("director_no_mobs"), 1);
					SetConVarInt(FindConVar("z_common_limit"), 0);
					SetConVarInt(FindConVar("z_boomer_limit"), 0);
					SetConVarInt(FindConVar("z_charger_limit"), 0);
					SetConVarInt(FindConVar("z_hunter_limit"), 0);
					SetConVarInt(FindConVar("z_jockey_limit"), 0);
					SetConVarInt(FindConVar("z_smoker_limit"), 0);
					SetConVarInt(FindConVar("z_spitter_limit"), 0);
				} else {
					ResetConVar(FindConVar("director_no_bosses"));
					ResetConVar(FindConVar("director_no_mobs"));
					ResetConVar(FindConVar("z_common_limit"));
					ResetConVar(FindConVar("z_boomer_limit"));
					ResetConVar(FindConVar("z_charger_limit"));
					ResetConVar(FindConVar("z_hunter_limit"));
					ResetConVar(FindConVar("z_jockey_limit"));
					ResetConVar(FindConVar("z_smoker_limit"));
					ResetConVar(FindConVar("z_spitter_limit"));  
				}
				PrintHintText(client,"Infected are now %s", disableInfected ? "DISABLED" : "ENABLED");
			}
			if( param == 3)
			{
			        DisplayMenu(g_hSkillMenu, client, MENU_TIME_FOREVER);
			}
		}
	}
}

////////////////////
/// Skill register / debug menu
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

///////////////////////////////////////////////////////////////////////////////////
// Engineer 
///////////////////////////////////////////////////////////////////////////////////

public CreatePlayerEngineerMenu(client)
{
	if (!client)
	return false;
	
	new Handle:hPanel;
	
	if((hPanel = CreatePanel()) == INVALID_HANDLE)
	{
		LogError("Cannot create hPanel on CreatePlayerEngineerMenu");
		return false;
	}
	
	SetPanelTitle(hPanel, "Engineer:");
	DrawPanelItem(hPanel, "Ammo Pile");
	DrawPanelItem(hPanel, "Deploy Turret");
	DrawPanelItem(hPanel, "Incendiary Rounds");
	DrawPanelItem(hPanel, "Frag Rounds");
	DrawPanelText(hPanel, " ");
	DrawPanelItem(hPanel, "Exit");
	
	SendPanelToClient(hPanel, client, PanelHandler_SelectEngineerItem, MENU_TIME_FOREVER);
	CloseHandle(hPanel);
	
	return true;
}

public PanelHandler_SelectEngineerItem(Handle:menu, MenuAction:action, client, param)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if( param >= 1 && param <= 4 )//was 5
			CalculateEngineerPlacePos(client, param - 1);
		}
	}
}

public void CalculateEngineerPlacePos(client, type)
{
	decl Float:vAng[3], Float:vPos[3], Float:endPos[3];
	
	GetClientEyeAngles(client, vAng);
	GetClientEyePosition(client, vPos);

	new Handle:trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, TraceFilter, client);

	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(endPos, trace);
		CloseHandle(trace);
		
		if (GetVectorDistance(endPos, vPos) <= GetConVarFloat(ENGINEER_MAX_BUILD_RANGE))
		{
			vAng[0] = 0.0;
			vAng[2] = 0.0;
			
			switch(type) {
				case 0: 
				{
					new ammo = CreateEntityByName("weapon_ammo_spawn");
					DispatchSpawn(ammo);
					TeleportEntity(ammo, endPos, NULL_VECTOR, NULL_VECTOR);
					ClientData[client].SpecialsUsed++;
					ClientData[client].LastDropTime = GetGameTime();
				}
				case 1:
				{
					useSpecialSkill(client, 0);
				}
				case 3: 
				{
					new upgrade = CreateEntityByName("upgrade_ammo_explosive");
					SetEntityModel(upgrade, MODEL_EXPLO);
					TeleportEntity(upgrade, endPos, NULL_VECTOR, NULL_VECTOR);
					DispatchSpawn(upgrade);
					PrintHintText(client ,"%N deployed explosive ammo", client);
					ClientData[client].LastDropTime = GetGameTime();
					ClientData[client].SpecialsUsed++;
				}
				case 2: 
				{
					new upgrade = CreateEntityByName("upgrade_ammo_incendiary");
					SetEntityModel(upgrade, MODEL_INCEN);
					TeleportEntity(upgrade, endPos, NULL_VECTOR, NULL_VECTOR);
					PrintHintText(client ,"%N deployed incendiary ammo", client);
					ClientData[client].LastDropTime = GetGameTime();
					ClientData[client].SpecialsUsed++;
					DispatchSpawn(upgrade);

				}
				default: {
					CloseHandle( trace );
					return;
				}
			}
				
		}
		else
		PrintToChat(client, "%sCould not place the item because you were looking too far away.", PRINT_PREFIX);
	}
	else
	CloseHandle(trace);
}

///////////////////////////////////////////////////////////////////////////////////
// Health modifiers & medic
///////////////////////////////////////////////////////////////////////////////////

public bool:CreatePlayerMedicMenu(client)
{
	if (!client)
	return false;
	
	new Handle:hPanel;
	
	if((hPanel = CreatePanel()) == INVALID_HANDLE)
	{
		LogError("Cannot create hPanel on CreatePlayerMedicMenu");
		return false;
	}
	
	SetPanelTitle(hPanel, "Medic:");
	DrawPanelItem(hPanel, "Defibrillator");
	DrawPanelItem(hPanel, "Medkit");
	DrawPanelItem(hPanel, "Adrenaline");
	DrawPanelItem(hPanel, "Pills");
	DrawPanelItem(hPanel, "Exit");
	SendPanelToClient(hPanel, client, PanelHandler_SelectMedicItem, MENU_OPEN_TIME);
	CloseHandle(hPanel);
	
	return true;
}

public PanelHandler_SelectMedicItem(Handle:menu, MenuAction:action, client, param)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if( param >= 1 && param <= 4 )
			CalculateMedicPlacePos(client, param - 1);
			ClientData[client].LastDropTime = GetGameTime();
		}
	}
}

public void CalculateMedicPlacePos(client, type)
{
	decl Float:vAng[3], Float:vPos[3], Float:endPos[3];
	
	GetClientEyeAngles(client, vAng);
	GetClientEyePosition(client, vPos);

	new Handle:trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, TraceFilter, client);

	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(endPos, trace);
		CloseHandle(trace);
		
		if (GetVectorDistance(endPos, vPos) <= GetConVarFloat(MEDIC_MAX_BUILD_RANGE))
		{
			vAng[0] = 0.0;
			vAng[2] = 0.0;
			
			switch(type) {
				case 0: {
					new entity = CreateEntityByName("weapon_defibrillator");
					DispatchKeyValue(entity, "solid", "0");
					DispatchKeyValue(entity, "disableshadows", "1");
					DispatchSpawn(entity);
					TeleportEntity(entity, endPos, NULL_VECTOR, NULL_VECTOR);
					PrintHintText(client ,"%N deployed a defibrillator", client);

					ClientData[client].SpecialsUsed++;
				}
				case 1:{
					new entity = CreateEntityByName("weapon_first_aid_kit");
					DispatchKeyValue(entity, "solid", "0");
					DispatchSpawn(entity);
					TeleportEntity(entity, endPos, NULL_VECTOR, NULL_VECTOR);
					PrintHintText(client ,"%N deployed a medkit", client);

					ClientData[client].SpecialsUsed++;
				}
				case 2: {
					new entity = CreateEntityByName("weapon_adrenaline_spawn");
					DispatchKeyValue(entity, "solid", "0");
					DispatchKeyValue(entity, "disableshadows", "1");
					TeleportEntity(entity, endPos, NULL_VECTOR, NULL_VECTOR);
					DispatchSpawn(entity);
					ClientData[client].SpecialsUsed++;

				}
				case 3: {
					new pills = CreateEntityByName("weapon_pain_pills_spawn", -1);
					DispatchKeyValue(pills, "solid", "6");
					DispatchKeyValue(pills, "disableshadows", "1");
					TeleportEntity(pills, endPos, NULL_VECTOR, NULL_VECTOR);
					DispatchSpawn(pills);
					ClientData[client].SpecialsUsed++;

				}				
				default: {
					CloseHandle( trace );
					return;
				}
			}
		}
		else
		PrintToChat(client, "%sCould not place the item because you were looking too far away.", PRINT_PREFIX);
	}
	else
	CloseHandle(trace);
}

public UpgradeQuickHeal(client)
{
	if(ClientData[client].ChosenClass == MEDIC)
	SetConVarFloat(g_VarFirstAidDuration, FirstAidDuration * GetConVarFloat(MEDIC_HEAL_RATIO), false, false);
	else
	SetConVarFloat(g_VarFirstAidDuration, FirstAidDuration * 1.0, false, false);
}

public UpgradeQuickRevive(client)
{
	if(ClientData[client].ChosenClass == MEDIC)
	SetConVarFloat(g_VarReviveDuration, ReviveDuration * GetConVarFloat(MEDIC_REVIVE_RATIO), false, false);
	else
	SetConVarFloat(g_VarReviveDuration, ReviveDuration * 1.0, false, false);
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

public Action:TimerSetClientTempHealth(Handle:hTimer, Handle:hPack)
{
	ResetPack(hPack);
	new client = ReadPackCell(hPack);
	new iValue = ReadPackCell(hPack);
	CloseHandle(hPack);
	
	if(!client
		|| !IsValidEntity(client)
		|| !IsClientInGame(client)
		|| !IsPlayerAlive(client)
		|| IsClientObserver(client)
		|| GetClientTeam(client) != 2)
	return;
	
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", iValue*1.0);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}

//////////////////////////////////////////7
// Health 
///////////////////////////////////////////
public void Event_ServerCvar( Event hEvent, const char[] sName, bool bDontBroadcast ) 
{
	if ( !healthModEnabled.BoolValue ) return;
	
	InitHealthModifiers();
}

public event_HealBegin(Handle:event, const String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	UpgradeQuickHeal(client);
}

public event_ReviveBegin(Handle:event, const String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	UpgradeQuickRevive(client);
}

public Action:TimerDetectHealthChanges(Handle:hTimer, any:client)
{
	if (!client
		|| !IsValidEntity(client)
		|| !IsClientInGame(client)
		|| ClientData[client].ChosenClass != MEDIC)
	return Plugin_Stop;
	
	if(!IsPlayerAlive(client) || GetClientTeam(client) != 2)
	{	return Plugin_Continue; }
	
	new btns = GetClientButtons(client);

	if (btns & IN_DUCK)
	{
		CreateParticle(client, MEDIC_GLOW, true, 1.0);

		decl Float:pos[3];
		decl String:sMessage[256];	
		GetClientAbsOrigin(client, pos);
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && i != client)
			{
				decl Float:tpos[3];
				GetClientAbsOrigin(i, tpos);
				
				if (GetVectorDistance(pos, tpos) <= GetConVarFloat(MEDIC_HEAL_DIST))
				{
					// pre-heal set values
					new MaxHealth = GetEntProp(i, Prop_Send, "m_iMaxHealth");
					new TempHealth = GetClientTempHealth(i);

					Format(sMessage, sizeof(sMessage), "%N is healing you!", client);

					ShowBar(i, sMessage, float(GetClientHealth(i)), float(MaxHealth));
					SetEntityHealth(i, GetClientHealth(i) + GetConVarInt(MEDIC_HEALTH_VALUE));
					SetClientTempHealth(i, TempHealth);
					
					// post-heal set values
					new newHp = GetClientHealth(i);
					new totalHp = newHp + TempHealth;
					GlowPlayer(i, "Green", FX:FxEnvRain);
					new Handle:hPack = CreateDataPack();
					WritePackCell(hPack, i);
					WritePackCell(hPack, totalHp);

					CreateTimer(1.0, GlowTimer, hPack, TIMER_FLAG_NO_MAPCHANGE ); 	
					
					if (totalHp > MaxHealth)
					{
						new diff = totalHp - MaxHealth;
						
						if (TempHealth >= diff)
						{
							SetClientTempHealth(i, TempHealth - diff);
							continue;
						}
						
						SetClientTempHealth(i, 0);
						SetEntityHealth(i, MaxHealth);
					}
				}
			}
		}
	} else {

		MedicHint = false;
	}
	
	return Plugin_Continue;
}

public ApplyHealthModifiers()
{
	FirstAidDuration = GetConVarFloat(FindConVar("first_aid_kit_use_duration"));
	ReviveDuration = GetConVarFloat(FindConVar("survivor_revive_duration"));
	g_VarFirstAidDuration = FindConVar("first_aid_kit_use_duration");
	g_VarReviveDuration = FindConVar("survivor_revive_duration");
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
	if( GetConVarBool(COMMANDO_ENABLE_STUMBLE_BLOCK) && ClientData[client].ChosenClass == COMMANDO && reason == 2 )
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action L4D_TankClaw_OnPlayerHit_Pre(int tank, int claw, int player)
{
	if( GetConVarBool(COMMANDO_ENABLE_STUMBLE_BLOCK) && ClientData[player].ChosenClass == COMMANDO)
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Event_RelCommandoClass(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if (ClientData[client].ChosenClass != COMMANDO)
	return;
	
	new weapon = GetEntDataEnt2(client, g_oAW);

	if (!IsValidEntity(weapon))
	return;
	
	new Float:flGT = GetGameTime();
	decl String:bNetCl[64];
	decl String:stClass[32];

	GetEntityNetClass(weapon, bNetCl, sizeof(bNetCl));
	GetEntityNetClass(weapon,stClass,32);

	if (DEBUG_MODE)
	PrintToChatAll("\x03-class of gun: \x01%s",stClass );

	if (StrContains(bNetCl, "shotgun", false) == -1)
	{
		new Handle:hPack = CreateDataPack();
		WritePackCell(hPack, weapon);

		new Float:fRLRat = GetConVarFloat(COMMANDO_RELOAD_RATIO);
		new Float:fNTC = (GetEntDataFloat(weapon, g_iNPA) - flGT) * fRLRat;
		new Float:NA = fNTC + flGT;
		new Float:flNextTime_ret = GetEntDataFloat(weapon, g_iNPA);
		new Float:flStartTime_calc = flGT - ( flNextTime_ret - flGT ) * ( 1 - fRLRat ) ;
		WritePackFloat(hPack, flStartTime_calc);
		
		if ( (fNTC - 0.4) > 0 )
		CreateTimer( fNTC - 0.4, CommandoRelFireEnd2, hPack);
		
		SetEntDataFloat(weapon, g_ioPR, 1.0 / fRLRat, true);
		SetEntDataFloat(weapon, g_ioTI, NA, true);
		SetEntDataFloat(weapon, g_iNPA, NA, true);
		SetEntDataFloat(client, g_ioNA, NA, true);
		CreateTimer(fNTC, CommandoRelFireEnd, weapon);
	}
	else
	{
		new Handle:hPack = CreateDataPack();
		WritePackCell(hPack, weapon);
		if (DEBUG_MODE) 
		PrintToChatAll("Class: %s", stClass);

		if (StrContains(bNetCl, "shotgun_spas", false) != -1)
		{
			WritePackFloat(hPack, 0.293939);
			WritePackFloat(hPack, 0.272999);
			WritePackFloat(hPack, 0.675000);

			CreateTimer(0.1, CommandoPumpShotReload, hPack);
		}
		else if (StrContains(bNetCl, "pumpshotgun", false) != -1)
		{

			WritePackFloat(hPack, 0.393939);
			WritePackFloat(hPack, 0.472999);
			WritePackFloat(hPack, 0.875000);

			CreateTimer(0.1, CommandoPumpShotReload, hPack);
		}
		else if (StrContains(bNetCl, "autoshotgun", false) != -1)
		{
			WritePackFloat(hPack, 0.416666);
			WritePackFloat(hPack, 0.395999);
			WritePackFloat(hPack, 1.000000);

			CreateTimer(0.1, CommandoPumpShotReload, hPack);
		}
		else
		CloseHandle(hPack);
	}
}

public Action:CommandoRelFireEnd(Handle:timer, any:weapon)
{
	if (weapon <= 0 || !IsValidEntity(weapon))
	return Plugin_Stop;
	
	SetEntDataFloat(weapon, g_ioPR, 1.0, true);
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

	new weapon = ReadPackCell(hPack);
	new iCid = GetEntPropEnt(weapon, Prop_Data, "m_hOwner");
	if (iCid <= 0 || IsValidEntity(iCid)==false || IsClientInGame(iCid)==false)
	return Plugin_Stop;

	new Float:flStartTime_calc = ReadPackFloat(hPack);
	CloseHandle(hPack);
	new iVMid = GetEntDataEnt2(iCid,g_iViewModelO);
	SetEntDataFloat(iVMid, g_iVMStartTimeO, flStartTime_calc, true);
	return Plugin_Stop;
}

public Action:CommandoPumpShotReload(Handle:timer, Handle:hOldPack)
{
	ResetPack(hOldPack);
	new weapon = ReadPackCell(hOldPack);
	new Float:fRLRat = GetConVarFloat(COMMANDO_RELOAD_RATIO);
	new Float:start = ReadPackFloat(hOldPack);
	new Float:insert = ReadPackFloat(hOldPack);
	new Float:end = ReadPackFloat(hOldPack);

	SetEntDataFloat(weapon,	g_iSSD,	start * fRLRat,	true);
	SetEntDataFloat(weapon,	g_iSID,	insert * fRLRat,	true);
	SetEntDataFloat(weapon,	g_iSED, end * fRLRat,	true);
	SetEntDataFloat(weapon, g_ioPR, 1.0 / fRLRat, true);
	
	CloseHandle(hOldPack);
	if (DEBUG_MODE == true) {
		PrintToChatAll("\x03-spas shotgun detected, ratio \x01%i\x03, startO \x01%i\x03, insertO \x01%i\x03, endO \x01%i", fRLRat, g_iSSD, g_iSID, g_iSED);
	}
	
	new Handle:hPack = CreateDataPack();
	WritePackCell(hPack, weapon);
	
	if (GetEntData(weapon, g_iSRS) != 2)
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
	new Float:addMod = ReadPackFloat(hPack);
	
	if (weapon <= 0 || !IsValidEntity(weapon))
	{
		CloseHandle(hPack);
		KillTimer(timer);
		return Plugin_Stop;
	}
	
	if (GetEntData(weapon, g_iSRS) == 0 || GetEntData(weapon, g_iSRS) == 2 )
	{
		new Float:flNextTime = GetGameTime() + addMod;
		
		SetEntDataFloat(weapon, g_ioPR, 1.0, true);
		SetEntDataFloat(GetEntPropEnt(weapon, Prop_Data, "m_hOwner"), g_ioNA, flNextTime, true);
		SetEntDataFloat(weapon,	g_ioTI, flNextTime, true);
		SetEntDataFloat(weapon,	g_iNPA, flNextTime, true);
		KillTimer(timer);
		CloseHandle(hPack);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (ClientData[client].ChosenClass == NONE && GetClientTeam(client) == 2)
	{
		if(client > 0 && client <= MaxClients && IsClientInGame( client ) && ClassHint == false)
		{
			if (RoundStarted == true) {
				ClassHint = true;
			}
			PrintHintText(client,"You really should pick a class, 1,5,7 are good for beginners.");
			CreatePlayerClassMenu(client);
		}
	}
	
	if(ClientData[client].ChosenClass == COMMANDO)
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

Action _MF_Touch(int entity, int other)
{
	if (!GetConVarBool(COMMANDO_ENABLE_STOMPING)) return Plugin_Continue;
 	if (ClientData[entity].ChosenClass != COMMANDO) return Plugin_Continue;

	if (other < 32 || !IsValidEntity(other)) return Plugin_Continue;
	
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

void SmashInfected(int zombie, int client)
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


// Saboteur vars
#define MAX_BOMBS 7
Mine g_AvailableBombs[MAX_BOMBS];

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

char[] formatBombName(char[] bombName) {
	char temp[32];
	Format(temp, sizeof(temp), "%s", bombName);
	return temp;
}

char[] getBombName(int index) {

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

enum struct Mine
{
    int index;
    char bombName[32];
    int bombIndex;
	
	void setItem(int number, int bombIndex) { 
		this.index = number;
		this.bombName = getBombName(bombIndex);
		this.bombIndex = bombIndex;
	}

	char[] getItem() {
		char temp[32];
		temp = this.bombName;

		if (this.index < 0 || StrEqual(temp, "")) return temp;
		char text[32];
		Format(text, sizeof(text), "%s", this.bombName);
		return text;
	}
}


public parseAvailableBombs()
{
	char buffers[MAX_BOMBS][3];

	char bombs[128];
	GetConVarString(SABOTEUR_BOMB_TYPES, bombs, sizeof(bombs));

	int amount = ExplodeString(bombs, ",", buffers, sizeof(buffers), sizeof(buffers[]));
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
		PrintDebugAll("Added %i bombtype to inventory: %s", g_AvailableBombs[i].getItem());
	}
}

public bool:CreatePlayerSaboteurMenu(client)
{
	if (!client)
	return false;
	
	new Handle:menu = CreateMenu(SelectSaboteurItem);
	
	SetMenuExitButton(menu, true);
	SetMenuTitle(menu, "Select mine type:");	
	for (new i = 0; i < MAX_BOMBS; i++ ) {

		char bombInfo[32];
		char bombIndex[3];
		IntToString(g_AvailableBombs[i].bombIndex, bombIndex, sizeof(bombIndex));
		Format(bombInfo, sizeof(bombInfo), "%s", g_AvailableBombs[i].getItem());

		if (!StrEqual(bombInfo, "")) {
			AddMenuItem(menu, bombIndex, bombInfo);
		}
	}

	DisplayMenu(menu, client, MENU_TIME_FOREVER);

	return true;
}

public SelectSaboteurItem(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if (StringToInt(menucmd) > 0) {
				CalculateSaboteurPlacePos(param1, StringToInt(menucmd));
			}
		}
		case MenuAction_Cancel:
		{
			
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
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
	if (ClientData[client].ChosenClass == SABOTEUR && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2) {
		ToggleNightVision(client);
	}
}

public void ToggleNightVision(client)
{
	if (GetConVarBool(SABOTEUR_ENABLE_NIGHT_VISION) && ClientData[client].ChosenClass == SABOTEUR && client < MaxClients && client > 0 && !IsFakeClient(client) && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
			int iWeapon = GetPlayerWeaponSlot(client, 0); // Get primary weapon
			if(iWeapon > 0 && IsValidEdict(iWeapon) && IsValidEntity(iWeapon))
			{					
				char netclass[128];
				GetEntityNetClass(iWeapon, netclass, sizeof(netclass));
				if(FindSendPropInfo(netclass, "m_upgradeBitVec") < 1)
				return; // This weapon does not support laser upgrade

				new cl_upgrades = GetEntProp(iWeapon, Prop_Send, "m_upgradeBitVec");
				if (cl_upgrades > 4194304) {
					return; // already has nightvision
				}
				SetEntProp(iWeapon, Prop_Send, "m_upgradeBitVec", cl_upgrades + 4194304, 4);

				SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1, 4);
				SetEntProp(client, Prop_Send, "m_bHasNightVision", 1, 4);
			}
	}
}

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
		SDKUnhook(client, SDKHook_WeaponEquipPost, OnClientWeaponEquip);
		SDKUnhook(client, SDKHook_WeaponDropPost, OnClientWeaponEquip);
	}
}

///////////////////////////////////////////////////////////////////////////////////
// Soldier
///////////////////////////////////////////////////////////////////////////////////

public OnGameFrame()
{
	if (!g_iRC)
	return;

	decl client;
	decl bweapon;
	decl Float:fNTC;
	decl Float:fNTR;
	new Float:fGT = GetGameTime();
	
	for (new i = 1; i <= g_iRC; i++)
	{
		client = g_iRI[i];
		
		if (!client
			|| client >= MAXPLAYERS
			|| !IsValidEntity(client)
			|| !IsClientInGame(client)
			|| !IsPlayerAlive(client)
			|| GetClientTeam(client) != 2
			|| (ClientData[client].ChosenClass != SOLDIER && ClientData[client].ChosenClass != COMMANDO) 
			)
		continue;
		

		if(ClientData[client].ChosenClass == SOLDIER && GetConVarBool(SOLDIER_SHOVE_PENALTY) == false)
		{
			//If the player is pressing the right click of the mouse, proceed
			if(GetClientButtons(client) & IN_ATTACK2)
			{
				//This will reset the penalty, so it doesnt even get applied.
				SetEntData(i, g_iShovePenalty, 0, 4);
			}
		}

		bweapon = GetEntDataEnt2(client, g_oAW);
		
		if(bweapon <= 0) 
		continue;
		
		fNTC = fNTR;

		if (g_iNPA == -1) {
			SetEntDataFloat(bweapon, g_iNPA, fNTC, true);

		}

		if (g_iEi[client] == bweapon && g_fNT[client] >= fNTR)
		continue;
		
		if (ClientData[client].ChosenClass == SOLDIER && g_iEi[client] == bweapon && g_fNT[client] < fNTR)
		{

			fNTC = ( fNTR - fGT ) * GetConVarFloat(SOLDIER_FIRE_RATE) + fGT;
			g_fNT[client] = fNTC;
			SetEntDataFloat(bweapon, g_iNPA, fNTC, true);
			continue;
		}
		g_fNT[client] = fNTC;

		if (g_iEi[client] != bweapon)
		{
			g_iEi[client] = bweapon;	
			g_fNT[client] = fNTR;
			continue;
		}
	}
}

public Action:OnTakeDamagePre(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (!IsServerProcessing())
	return Plugin_Continue;
	
	if (victim && attacker && IsValidEntity(attacker) && attacker <= MaxClients && IsValidEntity(victim) && victim <= MaxClients)
	{
		if( damagetype & DMG_BLAST && GetEntProp(inflictor, Prop_Data, "m_iHammerID") == 1078682)
		{
			if(GetClientTeam(victim) == 2 )
				damage = GetConVarFloat(SABOTEUR_BOMB_DAMAGE_SURV);
			else if(GetClientTeam(victim) == 3 )
				damage = GetConVarFloat(SABOTEUR_BOMB_DAMAGE_INF);
			return Plugin_Changed;
		}

		//PrintToChatAll("%s", m_attacker);
		if(ClientData[victim].ChosenClass == SOLDIER && GetClientTeam(victim) == 2)
		{
			//PrintToChat(victim, "Damage: %f, New: %f", damage, damage*0.5);
			damage = damage * GetConVarFloat(SOLDIER_DAMAGE_REDUCE_RATIO);
			return Plugin_Changed;
		}
		if (ClientData[attacker].ChosenClass == COMMANDO && GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 3)
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
	WritePackCell(hPack, client);
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

public Action:TimerAirstrike(Handle timer, Handle:hPack)
{
	new Float:pos[3];
	new Float:time;
	int client;
	int entity;
	ResetPack(hPack);
	client = ReadPackCell(hPack);		
	pos[0] = ReadPackFloat(hPack);
	pos[1] = ReadPackFloat(hPack);
	pos[2] = ReadPackFloat(hPack);
	time =  ReadPackFloat(hPack);
	entity = ReadPackCell(hPack);
	CloseHandle(hPack);

	if (RoundToFloor(GetGameTime()-time) < 10) {
		PrintHintTextToAll("Airstrike in %i, take cover!",10-(RoundToFloor(GetGameTime()-time)));
		new Handle:pack = CreateDataPack();
		WritePackCell(pack, client);
		WritePackFloat(pack, pos[0]);
		WritePackFloat(pack, pos[1]);
		WritePackFloat(pack, pos[2]);
		WritePackFloat(pack, time);
		WritePackCell(pack, entity);
		CreateTimer(1.0, TimerAirstrike, pack, TIMER_FLAG_NO_MAPCHANGE ); 									

	} else {

		g_bAirstrikeValid = true;
		PrintHintTextToAll("Airstrike completed!");

		if(IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "Kill");
		}
		ClientData[client].SpecialsUsed++;
		F18_ShowAirstrike(pos, GetRandomFloat(0.0, 180.0));
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public Action:TimerActivateBomb(Handle:hTimer, Handle:hPack)
{
	CreateTimer(0.3, TimerCheckBombSensors, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Stop;
}

public Action:TimerCheckBombSensors(Handle:hTimer, Handle:hPack)
{
	new Float:pos[3];
	decl Float:clientpos[3];
	
	ResetPack(hPack);
	pos[0] = ReadPackFloat(hPack);
	pos[1] = ReadPackFloat(hPack);
	pos[2] = ReadPackFloat(hPack);
	new owner = ReadPackCell(hPack);
	new session = ReadPackCell(hPack);
	int index = ReadPackCell(hPack);
	int bombType = ReadPackCell(hPack);
	int entity = ReadPackCell(hPack);

	if (index < 0) index = 0;

	if (session != RndSession)
	return Plugin_Stop;
	
	for (new client = 1; client <= MaxClients; client++)
	{

		if (!IsValidEntity(client) || !IsClientInGame(client))
		continue;
		if(GetClientTeam(client) == 3 || GetClientTeam(client) == 2 || IsWitch(client))
		{
			char classname[32];
			GetClientAbsOrigin(client, clientpos);
			GetEdictClassname(client, classname, sizeof(classname));

			if (GetVectorDistance(pos, clientpos) < GetConVarFloat(SABOTEUR_BOMB_RADIUS))
			{
				if (GetClientTeam(client) == 3 || IsWitch(client)) {
					PrintHintTextToAll("%N's mine detonated!", owner);
					
					new ent = CreateEntityByName("pipe_bomb_projectile");
					TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
					DispatchSpawn(ent);

					if (GetConVarInt(SABOTEUR_BOMB_TYPES) == 1) {
						PrintDebugAll("Detonating bomb extras for single bomb mode");
						CreateExplosion(pos, client);					
					}

					PrintDebugAll("Detonating Grenade type: %s", getBombName(bombType-1));

					useCustomCommand("Grenades", owner, entity, bombType);					
					BombActive = false;
					BombIndex[index] = false;
					CloseHandle(hPack);
					return Plugin_Stop;
				}
				else if (GetClientTeam(client) == 2) {
					if (!mineWarning[client] || mineWarning[client] < GetGameTime() + 5) {
						PrintHintText(client, "Warning! You are nearby armed mine.");
						mineWarning[client] = GetGameTime();
					}
				}
			}
			
		}
	}
	return Plugin_Continue;
}

public Action:timerHurtEntity(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new attacker = ReadPackCell(pack);
	new Float:amount = ReadPackFloat(pack);
	new type = ReadPackCell(pack);
	CloseHandle(pack);
	HurtEntity(client, attacker, amount, type);
}

stock DetonateMolotov(Float:pos[3], owner)
{
	pos[2]+=5.0;
	new Handle:sdkDetonateFire;
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetSignature(SDKLibrary_Server, "\x8B\x44**\x8B\x4C**\x53\x56\x57\x8B\x7C**\x57\x50\x51\x68****\xE8****\x8B\x5C**\xD9**\x83\xEC*\xDD***\x8B\xF0\xD9**\x8B\x44**\xDD***\xD9*\xDD***\xD9**\xDD***\xD9**\xDD***\xD9*\xDD**\x68****", 85))
	PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN18CMolotovProjectile6CreateERK6VectorRK6QAngleS2_S2_P20CBaseCombatCharacter", 0);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	sdkDetonateFire = EndPrepSDKCall();
	if(sdkDetonateFire == INVALID_HANDLE)
	{
		LogError("Invalid Function Call at DetonateMolotov()");
		CloseHandle(sdkDetonateFire);
		return;
	}
	new Float:vec[3];
	SDKCall(sdkDetonateFire, pos, vec, vec, vec, owner);
	CloseHandle(sdkDetonateFire);
}

stock DealDamage(iVictim, iAttacker, Float:flAmount, iType = 0)
{
	new Handle:hPack = CreateDataPack();
	WritePackCell(hPack, iVictim);
	WritePackCell(hPack, iAttacker);
	WritePackFloat(hPack, flAmount);
	WritePackCell(hPack, iType);
	CreateTimer(0.1, timerHurtEntity, hPack);
}

stock HurtEntity(client, attacker, Float:amount, type)
{
	new damage = RoundFloat(amount);
	if (IsValidEntity(client))
	{
		decl String:sUser[256], String:sDamage[11], String:sType[11];
		IntToString(client+25, sUser, sizeof(sUser));
		IntToString(damage, sDamage, sizeof(sDamage));
		IntToString(type, sType, sizeof(sType));
		new iDmgEntity = CreateEntityByName("point_hurt");
		DispatchKeyValue(client, "targetname", sUser);
		DispatchKeyValue(iDmgEntity, "DamageTarget", sUser);
		DispatchKeyValue(iDmgEntity, "Damage", sDamage);
		DispatchKeyValue(iDmgEntity, "DamageType", sType);
		DispatchSpawn(iDmgEntity);
		if (IsValidEntity(iDmgEntity))
		{
			AcceptEntityInput(iDmgEntity, "Hurt", client);
			AcceptEntityInput(iDmgEntity, "Kill");
		}
	}
}

stock CreateExplosion(Float:expPos[3], attacker = 0, bool:panic = true)
{
	decl String:sRadius[16], String:sPower[16], String:sInterval[11];
	new Float:flMxDistance = 450.0;
	new Float:power = GetConVarFloat(SABOTEUR_BOMB_POWER);
	//new iDamageSurv = GetConVarInt(SABOTEUR_BOMB_DAMAGE_SURV);
	new Float:iDamageInf = GetConVarFloat(SABOTEUR_BOMB_DAMAGE_INF);
	new Float:flInterval = 0.1;
	FloatToString(flInterval, sInterval, sizeof(sInterval));
	IntToString(450, sRadius, sizeof(sRadius));
	IntToString(800, sPower, sizeof(sPower));
	
	new exParticle2 = CreateEntityByName("info_particle_system");
	new exParticle3 = CreateEntityByName("info_particle_system");
	new exTrace = CreateEntityByName("info_particle_system");
	new exPhys = CreateEntityByName("env_physexplosion");
	new exHurt = CreateEntityByName("point_hurt");
	new exParticle = CreateEntityByName("info_particle_system");
	new exEntity = CreateEntityByName("env_explosion");
	
	//Set up the particle explosion
	DispatchKeyValue(exParticle, "effect_name", EXPLOSION_PARTICLE);
	DispatchSpawn(exParticle);
	ActivateEntity(exParticle);
	TeleportEntity(exParticle, expPos, NULL_VECTOR, NULL_VECTOR);
	
	DispatchKeyValue(exParticle2, "effect_name", EXPLOSION_PARTICLE2);
	DispatchSpawn(exParticle2);
	ActivateEntity(exParticle2);
	TeleportEntity(exParticle2, expPos, NULL_VECTOR, NULL_VECTOR);
	
	DispatchKeyValue(exParticle3, "effect_name", EXPLOSION_PARTICLE3);
	DispatchSpawn(exParticle3);
	ActivateEntity(exParticle3);
	TeleportEntity(exParticle3, expPos, NULL_VECTOR, NULL_VECTOR);
	
	DispatchKeyValue(exTrace, "effect_name", EFIRE_PARTICLE);
	DispatchSpawn(exTrace);
	ActivateEntity(exTrace);
	TeleportEntity(exTrace, expPos, NULL_VECTOR, NULL_VECTOR);
	
	//Set up explosion entity
	DispatchKeyValue(exEntity, "fireballsprite", "sprites/muzzleflash4.vmt");
	DispatchKeyValue(exEntity, "iMagnitude", "150");
	DispatchKeyValue(exEntity, "iRadiusOverride", sRadius);
	DispatchKeyValue(exEntity, "spawnflags", "828");
	SetEntProp(exEntity, Prop_Data, "m_iHammerID", 1078682);	

	DispatchSpawn(exEntity);
	TeleportEntity(exEntity, expPos, NULL_VECTOR, NULL_VECTOR);
	
	//Set up physics movement explosion
	DispatchKeyValue(exPhys, "radius", sRadius);
	DispatchKeyValue(exPhys, "magnitude", sPower);
	DispatchKeyValue(exPhys, "spawnflags", "1");
	SetEntProp(exPhys, Prop_Data, "m_iHammerID", 1078682);	

	DispatchSpawn(exPhys);
	TeleportEntity(exPhys, expPos, NULL_VECTOR, NULL_VECTOR);
	
	//Set up hurt point
	DispatchKeyValue(exHurt, "DamageRadius", sRadius);
	DispatchKeyValue(exHurt, "DamageDelay", sInterval);
	DispatchKeyValue(exHurt, "Damage", "1");
	DispatchKeyValue(exHurt, "DamageType", "128");
	SetEntProp(exHurt, Prop_Data, "m_iHammerID", 1078682);	
	DispatchSpawn(exHurt);
	TeleportEntity(exHurt, expPos, NULL_VECTOR, NULL_VECTOR);
	
	//DetonateMolotov(expPos, attacker);
	
	for(new i = 1; i <= 2; i++)
	//DetonateMolotov(expPos, attacker);
	
	switch(GetRandomInt(1,3))
	{
		case 1:
		EmitSoundToAll(EXPLOSION_SOUND);
		
		case 2:
		EmitSoundToAll(EXPLOSION_SOUND2);
		
		case 3:
		EmitSoundToAll(EXPLOSION_SOUND3);
	}
	
	AcceptEntityInput(exParticle, "Start");
	AcceptEntityInput(exParticle2, "Start");
	AcceptEntityInput(exParticle3, "Start");
	AcceptEntityInput(exTrace, "Start");
	AcceptEntityInput(exEntity, "Explode");
	AcceptEntityInput(exPhys, "Explode");
	AcceptEntityInput(exHurt, "TurnOn");
	
	new Handle:pack2 = CreateDataPack();
	WritePackCell(pack2, exParticle);
	WritePackCell(pack2, exParticle2);
	WritePackCell(pack2, exParticle3);
	WritePackCell(pack2, exTrace);
	WritePackCell(pack2, exEntity);
	WritePackCell(pack2, exPhys);
	WritePackCell(pack2, exHurt);
	CreateTimer(6.0, TimerDeleteParticles, pack2, TIMER_FLAG_NO_MAPCHANGE);
	
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, exTrace);
	WritePackCell(pack, exHurt);
	CreateTimer(4.5, TimerStopFire, pack, TIMER_FLAG_NO_MAPCHANGE);
	
	decl Float:survivorPos[3], Float:traceVec[3], Float:resultingFling[3], Float:currentVelVec[3];
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
		continue;

		GetEntPropVector(i, Prop_Data, "m_vecOrigin", survivorPos);
		
		if (GetVectorDistance(expPos, survivorPos) <= flMxDistance)
		{
			MakeVectorFromPoints(expPos, survivorPos, traceVec);
			GetVectorAngles(traceVec, resultingFling);
			
			resultingFling[0] = Cosine(DegToRad(resultingFling[1])) * power;
			resultingFling[1] = Sine(DegToRad(resultingFling[1])) * power;
			resultingFling[2] = power;
			
			GetEntPropVector(i, Prop_Data, "m_vecVelocity", currentVelVec);
			resultingFling[0] += currentVelVec[0];
			resultingFling[1] += currentVelVec[1];
			resultingFling[2] += currentVelVec[2];
			
			TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, resultingFling);
			
			if (attacker > 0)
			{
				if (GetClientTeam(i) == 2) {
					//DealDamage(i, attacker, iDamageSurv, 8);
				}
				else
				DealDamage(i, attacker, iDamageInf, 8);
			}
		}
	}
	
	decl String:class[32];
	for (new i=MaxClients+1; i<=2048; i++)
	{
		if (!IsValidEntity(i))  continue;

		GetEdictClassname(i, class, sizeof(class));
		if (StrEqual(class, "prop_physics") || StrEqual(class, "prop_physics_multiplayer"))
		{
			GetEntPropVector(i, Prop_Data, "m_vecOrigin", survivorPos);
			
			//Vector and radius distance calcs by AtomicStryker!
			if (GetVectorDistance(expPos, survivorPos) <= flMxDistance)
			{
				MakeVectorFromPoints(expPos, survivorPos, traceVec);
				GetVectorAngles(traceVec, resultingFling);
				
				resultingFling[0] = Cosine(DegToRad(resultingFling[1])) * power;
				resultingFling[1] = Sine(DegToRad(resultingFling[1])) * power;
				resultingFling[2] = power;
				
				GetEntPropVector(i, Prop_Data, "m_vecVelocity", currentVelVec);
				resultingFling[0] += currentVelVec[0];
				resultingFling[1] += currentVelVec[1];
				resultingFling[2] += currentVelVec[2];
				
				TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, resultingFling);
			}
		}
	}
}

public Action:TimerStopFire(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new particle = ReadPackCell(pack);
	new hurt = ReadPackCell(pack);
	CloseHandle(pack);
	
	if(IsValidEntity(particle))
	{
		AcceptEntityInput(particle, "Stop");
	}
	
	if(IsValidEntity(hurt))
	{
		AcceptEntityInput(hurt, "TurnOff");
	}
}

public Action:TimerDeleteParticles(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	
	new entity;
	for (new i = 1; i <= 7; i++)
	{
		entity = ReadPackCell(pack);
		
		if(IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
	
	CloseHandle(pack);
}

stock PrecacheParticle(const String:ParticleName[])
{
	new Particle = CreateEntityByName("info_particle_system");
	if (IsValidEntity(Particle) && IsValidEdict(Particle))
	{
		DispatchKeyValue(Particle, "effect_name", ParticleName);
		DispatchSpawn(Particle);
		ActivateEntity(Particle);
		AcceptEntityInput(Particle, "start");
		CreateTimer(0.3, TimerRemovePrecacheParticle, Particle, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:TimerRemovePrecacheParticle(Handle:timer, any:Particle)
{
	if (IsValidEdict(Particle))
	AcceptEntityInput(Particle, "Kill");
}

public int CreateBombParticleInPos(Float:pos[3], String:Particle_Name[], int index)
{
	new Particle = CreateEntityByName("info_particle_system");
	TeleportEntity(Particle, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(Particle, "effect_name", Particle_Name);
	int mine = DropMineEntity(pos, index);
	DispatchSpawn(Particle);
	ActivateEntity(Particle);
	AcceptEntityInput(Particle, "start");
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, Particle);
	WritePackCell(pack, index);
	WritePackCell(pack, mine);
	CreateTimer(5.0, TimerStopAndRemoveBombParticle, pack, TIMER_FLAG_NO_MAPCHANGE);
	return mine;
}

stock CreateParticle(client, String:Particle_Name[], bool:Parent, Float:duration)
{
	decl Float:pos[3], String:sName[64], String:sTargetName[64];
	new Particle = CreateEntityByName("info_particle_system");
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	TeleportEntity(Particle, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(Particle, "effect_name", Particle_Name);
	
	if (Parent)
	{
		Format(sName, sizeof(sName), "%d", client+25);
		DispatchKeyValue(client, "targetname", sName);
		GetEntPropString(client, Prop_Data, "m_iName", sName, sizeof(sName));
		
		Format(sTargetName, sizeof(sTargetName), "%d", client+1000);
		DispatchKeyValue(Particle, "targetname", sTargetName);
		DispatchKeyValue(Particle, "parentname", sName);
	}
	
	DispatchSpawn(Particle);
	DispatchSpawn(Particle);
	
	if (Parent)
	{
		SetVariantString(sName);
		AcceptEntityInput(Particle, "SetParent", Particle, Particle);
	}
	
	ActivateEntity(Particle);
	AcceptEntityInput(Particle, "start");
	CreateTimer(duration, TimerActivateBombParticle, Particle, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:TimerActivateBombParticle(Handle:timer, any:entity)
{
	if (entity > 0 && IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "Kill");
	}

}

public Action:TimerStopAndRemoveParticle(Handle:timer, any:entity)
{
	if (entity > 0 && IsValidEntity(entity))
	{
		if (BombActive == true) {
			CreateTimer(3.0, TimerStopAndRemoveParticle, entity, TIMER_FLAG_NO_MAPCHANGE);			
		} else {
			AcceptEntityInput(entity, "Kill");
		}
	}		
}

public Action:TimerStopAndRemoveBombParticle(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	int entity = ReadPackCell(pack);
	int index = ReadPackCell(pack);
	int mine = ReadPackCell(pack);	
	CloseHandle(pack);
	if (entity > 0 && IsValidEntity(entity)) 
	{
		if (BombActive == false) {
			AcceptEntityInput(entity, "Kill");
		} else {
			AcceptEntityInput(entity, "stop");
			BombActive = true;
			static float vPos[3];
			char color[12];
			new Handle:hPack = CreateDataPack();
			WritePackCell(hPack, index);
			WritePackCell(hPack, entity);
			GetConVarString(SABOTEUR_ACTIVE_BOMB_COLOR, color, sizeof(color));
			SetupPrjEffects(entity, vPos, color); // Red
			int defibParticle;
			int elmosParticle;
			// Particle
			defibParticle = DisplayParticle(false, PARTICLE_DEFIB, vPos, NULL_VECTOR);				
			WritePackCell(hPack, defibParticle);

			if (defibParticle) InputKill(defibParticle, 2.0);
			elmosParticle = DisplayParticle(false, PARTICLE_ELMOS, vPos, NULL_VECTOR);
			if (elmosParticle) InputKill(elmosParticle, 3.0);
			WritePackCell(hPack, elmosParticle);
			WritePackCell(hPack, mine);

			CreateTimer(15.0, TimerDeleteBombs, hPack, TIMER_FLAG_NO_MAPCHANGE);			
		}
	}
}

public Action:TimerDeleteBombs(Handle:timer, Handle:pack)
{		
	ResetPack(pack);
	int index = ReadPackCell(pack);
	bool removed = false;

	if (BombIndex[index] == false) {
		for (new i = 0; i <= 3; i++)
		{
			int entity = ReadPackCell(pack);
			if(entity > 0 && IsValidEntity(entity))
			{
				AcceptEntityInput(entity, "Kill");
				removed = true;
			}
		}
		CloseHandle(pack);

	} else {
		new Handle:hPack = CreateDataPack();
		WritePackCell(hPack, index);
		int entity = ReadPackCell(pack);
		WritePackCell(hPack, entity);
		int defibParticle = ReadPackCell(pack);
		WritePackCell(hPack, defibParticle);
		int elmosParticle = ReadPackCell(pack);
		WritePackCell(hPack, elmosParticle);
		int mine = ReadPackCell(pack);
		WritePackCell(hPack, mine);
		CloseHandle(pack);

		CreateTimer(5.0, TimerDeleteBombs, hPack, TIMER_FLAG_NO_MAPCHANGE);		
		return Plugin_Continue;
	}
	if (removed == true) {
		KillTimer(timer);
		return Plugin_Stop;
	} 
	return Plugin_Continue;
}

///////////////////////////////////////////////////////////////////////////////////	
// Graphics & effects
///////////////////////////////////////////////////////////////////////////////////

new String:g_ColorNames[12][32] = {"Red", "Green", "Blue", "Yellow", "Purple", "Cyan", "Orange", "Pink", "Olive", "Lime", "Violet", "Lightblue"};
new g_Colors[12][3] = {{255,0,0},{0,255,0},{0,0,255},{255,255,0},{255,0,255},{0,255,255},{255,128,0},{255,0,128},{128,255,0},{0,255,128},{128,0,255},{0,128,255}};

enum FX
{
	FxNone = 0,
	FxPulseFast,
	FxPulseSlowWide,
	FxPulseFastWide,
	FxFadeSlow,
	FxFadeFast,
	FxSolidSlow,
	FxSolidFast,
	FxStrobeSlow,
	FxStrobeFast,
	FxStrobeFaster,
	FxFlickerSlow,
	FxFlickerFast,
	FxNoDissipation,
	FxDistort,               // Distort/scale/translate flicker
	FxHologram,              // kRenderFxDistort + distance fade
	FxExplode,               // Scale up really big!
	FxGlowShell,             // Glowing Shell
	FxClampMinScale,         // Keep this sprite from getting very small (SPRITES only!)
	FxEnvRain,               // for environmental rendermode, make rain
	FxEnvSnow,               //  "        "            "    , make snow
	FxSpotlight,     
	FxRagdoll,
	FxPulseFastWider,
};

enum Render
{
	Normal = 0, 		// src
	TransColor, 		// c*a+dest*(1-a)
	TransTexture,		// src*a+dest*(1-a)
	Glow,				// src*a+dest -- No Z buffer checks -- Fixed size in screen space
	TransAlpha,			// src*srca+dest*(1-srca)
	TransAdd,			// src*a+dest
	Environmental,		// not drawn, used for environmental effects
	TransAddFrameBlend,	// use a fractional frame value to blend between animation frames
	TransAlphaAdd,		// src + dest*(1-a)
	WorldGlow,			// Same as kRenderGlow but not fixed size in screen space
	None,				// Don't render.
};

#define BEAM_OFFSET			100.0									// Increase beam diameter by this value to correct visual size.
#define BEAM_RINGS			5										// Number of beam rings.
#define SHAKE_RANGE			150.0									// How far to increase the shake from the effect range.

new Render:g_Render = Render:Glow;

public ShowParticle(Float:pos[3], Float:ang[3],String:particlename[], Float:time)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename); 
		DispatchSpawn(particle);
		ActivateEntity(particle);
		TeleportEntity(particle, pos, ang, NULL_VECTOR);
		AcceptEntityInput(particle, "start");		
		CreateTimer(time, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
		return particle;
	}  
	return 0;
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
	if (IsValidEntity(particle))
	{
		decl String:classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "stop");
			AcceptEntityInput(particle, "kill");
			RemoveEdict(particle);
		}
	}
}

stock GlowPlayer(int client, char[] sColor, FX:fx=FxGlowShell)
{
	decl String:colorString[32];
	Format(colorString, sizeof(colorString), "%s", sColor);

	if (!IsClientInGame(client) || !IsPlayerAlive(client)) return false;
	
	new color = FindColor(colorString);
	
	if (color == -1 && strcmp(sColor, "none", false) != 0)
	{
		return;
	}

	if (color == -1)
	{
		SetRenderProperties(client);
	}
	else
	{
		SetRenderProperties(client, fx, g_Colors[color][0], g_Colors[color][1], g_Colors[color][2], g_Render, 250);
	}

	return;	
}

public Action:RemoveGlowFromAll() {

	for(new i = 0; i < MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
			SetRenderProperties(i);		
	}
	return Plugin_Handled;
}

public Action:GlowTimer(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	int client = ReadPackCell(pack);
	int health = ReadPackCell(pack);
	CloseHandle(pack);

	if (!IsClientInGame(client) || !IsPlayerAlive(client)) return Plugin_Stop;
	new newHp = GetClientHealth(client);
	new TempHealth = GetClientTempHealth(client);
	new totalHp = newHp+TempHealth;

	if (totalHp > health) {
		new Handle:hPack = CreateDataPack();
		WritePackCell(hPack, client);
		WritePackCell(hPack, totalHp);

		CreateTimer(1.0, GlowTimer, hPack, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Continue;
	} else {
		SetRenderProperties(client);
	}

	return Plugin_Stop;
}

// None, White, Red, Green, Blue, Yellow, Purple, Cyan, Orange, Pink, Olive, Lime, Violet, and Lightblue
FindColor(String:color[])
{
	for (new i = 0; i < 12; i++)
	{
		if(strcmp(color, g_ColorNames[i], false) == 0)
			return i;
	}
	
	return -1;
}

stock SetRenderProperties(index, FX:fx=FxNone, r=255, g=255, b=255, Render:render=Normal, amount=255)
{
	SetEntProp(index, Prop_Send, "m_nRenderFX", _:fx, 1);
	SetEntProp(index, Prop_Send, "m_nRenderMode", _:render, 1);

	new offset = GetEntSendPropOffs(index, "m_clrRender");
	
	SetEntData(index, offset, r, 1, true);
	SetEntData(index, offset + 1, g, 1, true);
	SetEntData(index, offset + 2, b, 1, true);
	SetEntData(index, offset + 3, amount, 1, true);
}

int GetColor(char[] sTemp)
{
	if (strcmp(sTemp, "") == 0) {
		return 0;
	}
	
	char sColors[3][4];
	int iColor = ExplodeString(sTemp, " ", sColors, 3, 4);

	if (iColor != 3) {
		return 0;
	}
	
	iColor = StringToInt(sColors[0]);
	iColor += 256 * StringToInt(sColors[1]);
	iColor += 65536 * StringToInt(sColors[2]);

	return iColor;
}

void SetupPrjEffects(int entity, float vPos[3], const char[] color)
{
	// Grenade Pos
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPos);

	// Sprite
	CreateEnvSprite(entity, color);

	// Steam
	static float vAng[3];
	GetEntPropVector(entity, Prop_Data, "m_angRotation", vAng);
	MakeEnvSteam(entity, vPos, vAng, color);

	// Light
	int light = MakeLightDynamic(entity, vPos);
	SetVariantEntity(light);
	SetVariantString(color);
	AcceptEntityInput(light, "color");
	AcceptEntityInput(light, "TurnOn");
}

void CreateBeamRing(int entity, int iColor[4], float min, float max, max_rings)
{
	// Grenade Pos
	static float vPos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPos);

	// Make beam rings
	for( int i = 1; i <= max_rings; i++ )
	{
		vPos[2] += 20;
		TE_SetupBeamRingPoint(vPos, min, max, g_BeamSprite, g_HaloSprite, 0, 15, 1.0, 1.0, 2.0, iColor, 20, 0);
		TE_SendToAll();
	}
}
void MakeEnvSteam(int target, const float vPos[3], const float vAng[3], const char[] sColor)
{
	int entity = CreateEntityByName("env_steam");
	if( entity == -1 )
	{
		LogError("Failed to create 'env_steam'");
		return;
	}
	static char sTemp[16];
	Format(sTemp, sizeof(sTemp), "silv_steam_%d", target);
	DispatchKeyValue(entity, "targetname", sTemp);
	DispatchKeyValue(entity, "SpawnFlags", "1");
	DispatchKeyValue(entity, "rendercolor", sColor);
	DispatchKeyValue(entity, "SpreadSpeed", "10");
	DispatchKeyValue(entity, "Speed", "100");
	DispatchKeyValue(entity, "StartSize", "5");
	DispatchKeyValue(entity, "EndSize", "10");
	DispatchKeyValue(entity, "Rate", "50");
	DispatchKeyValue(entity, "JetLength", "100");
	DispatchKeyValue(entity, "renderamt", "150");
	DispatchKeyValue(entity, "InitialState", "1");
	DispatchSpawn(entity);
	AcceptEntityInput(entity, "TurnOn");
	TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

	// Attach
	if( target )
	{
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", target);
	}

	return;
}

void CreateEnvSprite(int target, const char[] sColor)
{
	int entity = CreateEntityByName("env_sprite");
	if( entity == -1)
	{
		LogError("Failed to create 'env_sprite'");
		return;
	}

	DispatchKeyValue(entity, "rendercolor", sColor);
	DispatchKeyValue(entity, "model", MODEL_SPRITE);
	DispatchKeyValue(entity, "spawnflags", "3");
	DispatchKeyValue(entity, "rendermode", "9");
	DispatchKeyValue(entity, "GlowProxySize", "0.1");
	DispatchKeyValue(entity, "renderamt", "175");
	DispatchKeyValue(entity, "scale", "0.1");
	DispatchSpawn(entity);

	// Attach
	if( target )
	{
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", target);
	}
}

int MakeLightDynamic(int target, const float vPos[3])
{
	int entity = CreateEntityByName("light_dynamic");
	if( entity == -1 )
	{
		LogError("Failed to create 'light_dynamic'");
		return 0;
	}

	DispatchKeyValue(entity, "_light", "0 255 0 0");
	DispatchKeyValue(entity, "brightness", "0.1");
	DispatchKeyValueFloat(entity, "spotlight_radius", 32.0);
	DispatchKeyValueFloat(entity, "distance", 600.0);
	DispatchKeyValue(entity, "style", "6");
	DispatchSpawn(entity);
	AcceptEntityInput(entity, "TurnOff");

	TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
	// Attach
	if( target )
	{
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", target);
	}
	return entity;
}

int DisplayParticle(int target, const char[] sParticle, const float vPos[3], const float vAng[3], float refire = 0.0)
{
	int entity = CreateEntityByName("info_particle_system");	
	if( entity == -1)
	{
		LogError("Failed to create 'info_particle_system'");
		return 0;
	}

	DispatchKeyValue(entity, "effect_name", sParticle);
	DispatchSpawn(entity);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "start");
	TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

	// Refire
	if( refire )
	{
		static char sTemp[48];
		Format(sTemp, sizeof(sTemp), "OnUser1 !self:Stop::%f:-1", refire - 0.05);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnUser1 !self:FireUser2::%f:-1", refire);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
		SetVariantString("OnUser2 !self:Start::0:-1");
		AcceptEntityInput(entity, "AddOutput");
		SetVariantString("OnUser2 !self:FireUser1::0:-1");
		AcceptEntityInput(entity, "AddOutput");
	}
	// Attach
	if( target )
	{
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", target);
	}

	return entity;
}

// Get Position on map

public bool SetClientLocation(int client, float vPos[3])
{
	GetClientEyePosition(client, vPos);
	static float vAng[3];
	GetClientEyeAngles(client, vAng);
	static Handle trace;
	trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, ExcludeSelf_Filter, client);

	if( TR_DidHit(trace) )
	{
		TR_GetEndPosition(vPos, trace);

		static float vDir[3];
		GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
		vPos[0] -= vDir[0] * 10;
		vPos[1] -= vDir[1] * 10;
		vPos[2] -= vDir[2] * 10;
	}
	else
	{
		delete trace;
		return false;
	}

	delete trace;
	return true;
}

public bool ExcludeSelf_Filter(int entity, int contentsMask, any client)
{
	if( entity == client )
	return false;
	return true;
}

/**
* STOCK FUNCTIONS
*/

void InputKill(int entity, float time)
{
	static char temp[40];
	Format(temp, sizeof(temp), "OnUser4 !self:Kill::%f:-1", time);
	SetVariantString(temp);
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser4");
}

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

stock int CountPlayersWithClass( class ) {
	new count = 0;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
		continue;

		if(ClientData[i].ChosenClass == class)
		count++;
	}

	return count;
}

stock PushEntity(client, Float:clientEyeAngle[3], Float:power)
{
	decl Float:forwardVector[3], Float:newVel[3];
	
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", newVel);
	GetAngleVectors(clientEyeAngle, forwardVector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(forwardVector, forwardVector);
	ScaleVector(forwardVector, power);
	AddVectors(forwardVector, newVel, newVel);
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, newVel);
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
	
	if (ClientData[client].ChosenClass == ATHLETE)
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
			DispatchKeyValue(iEntity, "model", g_bLeft4Dead2 ? g_sModels[0] : g_sModels[1]);
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

public Action Timer_Parachute( Handle timer, any iEntity)
{
	int iParachute = EntRefToEntIndex(iEntity);
	if (IsValidEntity(iParachute))
	{
		RotateParachute(iParachute, 100.0, 1);
		return Plugin_Continue;
	}
	return Plugin_Stop;
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

public bool:TraceFilter(entity, contentsMask, any:client)
{
	if( entity == client )
	return false;
	return true;
}

public bool:IsPlayerHidden(client) 
{
	if (ClientData[client].ChosenClass == SABOTEUR && (GetGameTime() - ClientData[client].HideStartTime) >= (GetConVarFloat(SABOTEUR_INVISIBLE_TIME))) 
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

public Action:GrenadeCommand(client, args)
{
	if (isAdmin(client)) {
		// Index
		int index;
		char str[3];
		new type=GetCmdArg(1, str, 32);
		if(type==0) {
		}
		else
		{
			int c = StringToInt(str);
			index = c;
		}			
		useCustomCommand("Grenades", client, -1, index);
	}			
	
	return Plugin_Handled;
}

public Action:HideCommand(client, args)
{
	if (client > 0 && IsClientInGame(client) && isAdmin(client)) {

		new String:str[32];
		new type=GetCmdArg(1, str, 32);
		if(type==0) {
		}
		else
		{
			int c = StringToInt(str);
			if (c || IsValidEntity(c) || IsClientInGame(c)){
				client = c;					
			}
		}			
		HidePlayer(client);
	}
	
	return Plugin_Handled;
}
