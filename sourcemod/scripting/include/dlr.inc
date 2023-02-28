// top menu
new Handle:hTopMenu = INVALID_HANDLE;

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
new Handle:g_hForwardPluginState = INVALID_HANDLE;
new Handle:g_hForwardRoundState = INVALID_HANDLE;

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
enum ClassTypes {
	NONE=0,
	soldier,
	athlete,
	medic,
	saboteur,
	commando,
	engineer,
	brawler, 
	MAXCLASSES
};

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
	ClassTypes ChosenClass;
	float LastDropTime;
	int SpecialDropInterval;
	int SpecialLimit;
	SpecialSkill SpecialSkill;			
	char EquippedGun[64];
}

stock PlayerInfo ClientData[MAXPLAYERS+1];

// API
stock bool g_bLeft4Dead2, g_bLateLoad, g_bDmgHooked;
stock bool g_bAirstrike, g_bAirstrikeValid;

// Soldier vars

stock int g_iSoldierIndex[64] = { -1 };
stock int g_iSoldierCount = 0;
stock int g_iEntityIndex[64] = { -1 };
stock int g_iMeleeEntityIndex[64] = { -1 };
stock int g_iNotMeleeEntityIndex[64] =  { -1 };
//these are similar to those used by Double Tap
stock float g_flNextMeleeAttackTime[64] = { -1.0 };
//this tracks the attack count, similar to 
stock int g_iMeleeAttackCount[64] = { -1 };
stock Float:g_fNextAttackTime[MAXPLAYERS+1] = { -1.0 };
int g_iNextPrimaryAttack = -1;
int g_iNextSecondaryAttack = -1;
int g_hActiveWeapon = -1;
new g_hActiveWeaponOffset;
float g_flReloadRate = 0.6;
float g_flAttackRate = 0.666;
float g_flMeleeRate = 0.45;

//This keeps track of the default values for reload speeds for the different shotgun types
//NOTE: Pump and Chrome have identical values
const Float:g_flAutoShotgunS = 0.4;
const Float:g_flAutoShotgunI = 0.4;
const Float:g_flAutoShotgunE = 0.4;
const Float:g_flShotgunSpasS = 0.2;
const Float:g_flShotgunSpasI = 0.2;
const Float:g_flShotgunSpasE = 0.2;
const Float:g_flPumpShotgunS = 0.4;
const Float:g_flPumpShotgunI = 0.4;
const Float:g_flPumpShotgunE = 0.4;

// Speed vars
new g_flLaggedMovementValue;

// Commando vars
new g_iPlaybackRate = -1;
new g_iVMStartTimeO  = -1;
new g_iViewModelO = -1;
new g_iNextAttack = -1;
new g_iTimeWeaponIdle = -1;
new g_reloadStartDuration = -1;
new g_reloadInsertDuration = -1;
new g_reloadEndDuration = -1;
new g_iReloadState = -1;
new g_iShovePenalty = 0;


// Parachute

bool g_bParachute[MAXPLAYERS+1];
int g_iVelocity = -1, g_iParaEntRef[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};

enum Water_Level
{
	WATER_LEVEL_NOT_IN_WATER = 0,
	WATER_LEVEL_FEET_IN_WATER,
	WATER_LEVEL_WAIST_IN_WATER,
	WATER_LEVEL_HEAD_IN_WATER
};

// Bomb related stuff
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
#define MAX_BOMBS 7
stock Mine g_AvailableBombs[MAX_BOMBS];



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
new Handle:SOLDIER_ATTACK_RATE;
new Handle:SOLDIER_MELEE_ATTACK_RATE;
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
new bool:g_PluginLoaded;
new Handle:pluginEnabled;

new bool:g_iPlayerSpawn;
new bool:ClassHint =false;
new bool:InvisibilityHint = false;
new bool:MedicHint = false;
new Float:mineWarning[16];
// saboteur
new BombHintTimestamp = 0;
new InvisibilityTimestamp = 0;
new bool:g_bHide[MAXPLAYERS+1];

// Is target of infected 
stock g_bIsVictim[MAXPLAYERS+1];
stock int b_attackerTarget[MAXPLAYERS+1];

ConVar healthModEnabled;
ConVar parachuteEnabled;

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dlr/const>
#include <dlr/timers>
#include <dlr/commands>
#include <dlr/classes>
#include <dlr/debug>
#include <dlr/effects>
#include <dlr/hud>
#include <dlr/menus>