
stock MENU_OPEN_TIME = view_as<int>(99999);
stock const String:MENU_OPTIONS[][] =
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
stock String:ClassTips[][] =
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
//Player Related Variables
stock int g_iPlayerSkill[MAXPLAYERS+1];

stock int SESSION_DEBUG;
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

