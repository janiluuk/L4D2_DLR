/**
 * vim: set ts=4 :
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
 
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>


/**
 * CONFIGURABLE VARIABLES
 * Feel free to change the following code-related values.
 */


/// MENU AND UI RELATED STUFF

// This is what to display on the class selection menu.
static const String:MENU_OPTIONS[][] =
{
	// What should be displayed if the player does not have a class?
	"None",
	
	// You can change how the menus display here.
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
static const float:MENU_OPEN_TIME = 99999;

// What formatting string to use when printing to the chatbox
#define PRINT_PREFIX 	"\x05[DLR] \x01" 

/// SOUNDS AND OTHER
/// PRECACHE DATA

#define SOUND_CLASS_SELECTED "ui/pickup_misc42.wav" /**< What sound to play when a class is selected. Do not include "sounds/" prefix. */
#define SOUND_DROP_BOMB "ui/beep22.wav"
#define AMMO_PILE "models/props/terror/ammo_stack.mdl"
#define MODEL_INCEN	"models/props/terror/incendiary_ammo.mdl"
#define MODEL_EXPLO	"models/props/terror/exploding_ammo.mdl"
#define MODEL_SPRITE "models/sprites/glow01.spr"
#define PARTICLE_DEFIB                  "item_defibrillator_body"
#define PARTICLE_ELMOS                  "st_elmos_fire_cp0"

/**
 * OTHER GLOBAL VARIABLES
 * Do not change these unless you know what you are doing.
 */

enum CLASSES {
	NONE = 0,
	SOLDIER,
	ATHLETE,
	MEDIC,
	SABOTEUR,
	COMMANDO,
	ENGINEER,
	BRAWLER,
	MAXCLASSES
};

enum struct PlayerInfo 
{
	int BombsUsed;
	int ItemsBuilt;
	float HideStartTime;
	float HealStartTime;
	int LastButtons;
	int ChosenClass;
	float LastDropTime;
	char EquippedGun[64];

}

PlayerInfo ClientData[MAXPLAYERS+1];

// Stores client plugin data
//new ClientData[MAXPLAYERS+1][PLAYERDATA];

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
new g_ioNA = -1;
new g_ioTI = -1;
new g_iSSD = -1;
new g_iSID = -1;
new g_iSED = -1;
new g_iSRS = -1;

// Enums (doc'd by SMLib)
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

#define PUNCH_SOUND "melee_tonfa_02.wav"
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
new g_CollisionOffset;

// Max classes
new Handle:MAX_SOLDIER;
new Handle:MAX_ATHLETE;
new Handle:MAX_MEDIC;
new Handle:MAX_SABOTEUR;
new Handle:MAX_COMMANDO;
new Handle:MAX_ENGINEER;
new Handle:MAX_BRAWLER;

// Everyone
new Handle:SOLDIER_HEALTH;
new Handle:ATHLETE_HEALTH;
new Handle:MEDIC_HEALTH;
new Handle:SABOTEUR_HEALTH;
new Handle:COMMANDO_HEALTH;
new Handle:ENGINEER_HEALTH;
new Handle:BRAWLER_HEALTH;

new Handle:DEFAULT_REVIVE_DURATION;
new Handle:DEFAULT_HEAL_DURATION;

// Soldier
new Handle:SOLDIER_FIRE_RATE;
new Handle:SOLDIER_DAMAGE_REDUCE_RATIO;
new Handle:SOLDIER_SPEED;

// Athlete
//new Handle:ATHLETE_SPEED;
new Handle:ATHLETE_JUMP_VEL;

// Medic
new Handle:MEDIC_HEAL_DIST;
new Handle:MEDIC_HEALTH_VALUE;
new Handle:MEDIC_MAX_ITEMS;
new Handle:MEDIC_HEALTH_INTERVAL;
new Handle:MEDIC_HEAL_RATIO;
new Handle:MEDIC_REVIVE_RATIO;

new Handle:MAX_MEDIC_BUILD_RANGE;


// Saboteur
new Handle:SABOTEUR_INVISIBLE_TIME;
new Handle:SABOTEUR_BOMB_ACTIVATE;
new Handle:SABOTEUR_BOMB_RADIUS;
new Handle:SABOTEUR_MAX_BOMBS;
new Handle:SABOTEUR_BOMB_DAMAGE_SURV;
new Handle:SABOTEUR_BOMB_DAMAGE_INF;
new Handle:SABOTEUR_BOMB_POWER;

// Commando
new Handle:COMMANDO_DAMAGE;
new Handle:COMMANDO_RELOAD_RATIO;

// Engineer
new Handle:ENGINEER_MAX_BUILDS;
new Handle:MAX_ENGINEER_BUILD_RANGE;

// Saboteur, Engineer, Medic
new Handle:MINIMUM_DROP_INTERVAL;
new Handle:ENGINEER_TURRET_EXTERNAL_PLUGIN;

// Saferoom checks for saboteur
new bool:g_bInSaferoom[MAXPLAYERS+1] = false;
new Float:g_SpawnPos[MAXPLAYERS+1][3];
new Handle:g_VarFirstAidDuration = INVALID_HANDLE;
new Handle:g_VarReviveDuration = INVALID_HANDLE;
new Float:FirstAidDuration;
new Float:ReviveDuration;
new Float:DefaultHealDuration;
new Float:DefaultReviveDuration;
new bool:BombActive = false;
new String:Engineer_Turret_Spawn_Cmd[16] = "sm_dlrpmkai";
new String:Engineer_Turret_Remove_Cmd[16] = "sm_dlrpmkairm";
new Handle:GLOW_COLOR_ACTIVE;

// Last class taken
new LastClassConfirmed[MAXPLAYERS+1];

new bool:RoundStarted =false;
new bool:InvisibilityHint = false;
new bool:MedicHint = false;


/**
 * STOCK FUNCTIONS
 */

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
	new iDamageSurv = GetConVarInt(SABOTEUR_BOMB_DAMAGE_SURV);
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
	DispatchSpawn(exEntity);
	TeleportEntity(exEntity, expPos, NULL_VECTOR, NULL_VECTOR);
	
	//Set up physics movement explosion
	DispatchKeyValue(exPhys, "radius", sRadius);
	DispatchKeyValue(exPhys, "magnitude", sPower);
	DispatchKeyValue(exPhys, "spawnflags", "1");

	DispatchSpawn(exPhys);
	TeleportEntity(exPhys, expPos, NULL_VECTOR, NULL_VECTOR);
	
	
	//Set up hurt point
	DispatchKeyValue(exHurt, "DamageRadius", sRadius);
	DispatchKeyValue(exHurt, "DamageDelay", sInterval);
	DispatchKeyValue(exHurt, "Damage", "1");
	DispatchKeyValue(exHurt, "DamageType", "128");
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
		if (IsValidEntity(i))
		{
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

stock CreateParticleInPos(Float:pos[3], String:Particle_Name[])
{
	new Particle = CreateEntityByName("info_particle_system");
	TeleportEntity(Particle, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(Particle, "effect_name", Particle_Name);
	
	DispatchSpawn(Particle);
	DispatchSpawn(Particle);

	ActivateEntity(Particle);
	AcceptEntityInput(Particle, "start");

	CreateTimer(5.0, TimerStopAndRemoveBombParticle, Particle, TIMER_FLAG_NO_MAPCHANGE);

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

int GetColor(ConVar hCvar)
{
    char sTemp[12];
    hCvar.GetString(sTemp, sizeof(sTemp));
    if( sTemp[0] == 0 )
    	return 0;

    char sColors[3][4];
    int color = ExplodeString(sTemp, " ", sColors, sizeof(sColors), sizeof(sColors[]));

    if( color != 3 )
            return 0;

    color = StringToInt(sColors[0]);
    color += 256 * StringToInt(sColors[1]);
    color += 65536 * StringToInt(sColors[2]);

    return color;
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
			CreateTimer(5.0, TimerStopAndRemoveParticle, entity, TIMER_FLAG_NO_MAPCHANGE);			
		} else {
			AcceptEntityInput(entity, "Kill");
		}
	}		
}
public Action:TimerStopAndRemoveBombParticle(Handle:timer, any:entity)
{
	if (entity > 0 && IsValidEntity(entity)) 
	{
		if (BombActive == false) {
			AcceptEntityInput(entity, "Kill");
		} else {

			int color = GetColor(GLOW_COLOR_ACTIVE);
			// Grenade Pos + Effects
			static float vPos[3];

			SetupPrjEffects(entity, vPos, "255 0 0"); // Red
			AcceptEntityInput(entity, "start");
			CreateTimer(15.0, TimerStopAndRemoveParticle, entity, TIMER_FLAG_NO_MAPCHANGE);

			int entId;
			// Particle
			entId = DisplayParticle(entity, PARTICLE_DEFIB,         vPos, NULL_VECTOR);
			if (entId)  InputKill(entId, 15.0);
			CreateTimer(15.0, TimerStopAndRemoveParticle, entId, TIMER_FLAG_NO_MAPCHANGE);
			entId = DisplayParticle(entity, PARTICLE_ELMOS,         vPos, NULL_VECTOR);
			if (entId) InputKill(entId, 20.0);
			CreateTimer(15.0, TimerStopAndRemoveParticle, entId, TIMER_FLAG_NO_MAPCHANGE);			

		}
	}
}

void InputKill(int entity, float time)
{
        static char temp[40];
        Format(temp, sizeof(temp), "OnUser4 !self:Kill::%f:-1", time);
        SetVariantString(temp);
        AcceptEntityInput(entity, "AddOutput");
        AcceptEntityInput(entity, "FireUser4");
}


stock IsGhost(client)
{
	return GetEntProp(client, Prop_Send, "m_isGhost");
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

/**
 * PLUGIN LOGIC
 */

public OnPluginStart( )
{
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

	g_CollisionOffset = FindSendPropInfo( "CBaseEntity", "m_CollisionGroup" );
	
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

	// Concommands
	RegConsoleCmd("sm_class", CmdClassMenu, "Shows the class selection menu");
	RegConsoleCmd("sm_classinfo", CmdClassInfo, "Shows class descriptions");
	RegConsoleCmd("sm_classes", CmdClasses, "Shows class descriptions");
	
	// Convars
	MAX_SOLDIER = CreateConVar("talents_soldier_max", "1", "Max number of soldiers");
	MAX_ATHLETE = CreateConVar("talents_athelete_max", "1", "Max number of athletes");
	MAX_MEDIC = CreateConVar("talents_medic_max", "1", "Max number of medics");
	MAX_SABOTEUR = CreateConVar("talents_saboteur_max", "1", "Max number of saboteurs");
	MAX_COMMANDO = CreateConVar("talents_commando_max", "1", "Max number of commandos");
	MAX_ENGINEER = CreateConVar("talents_engineer_max", "1", "Max number of engineers");
	MAX_BRAWLER = CreateConVar("talents_brawler_max", "1", "Max number of brawlers");
	
	SOLDIER_HEALTH = CreateConVar("talents_soldier_health", "300", "How much health a soldier should have");
	ATHLETE_HEALTH = CreateConVar("talents_athelete_health", "150", "How much health an athlete should have");
	MEDIC_HEALTH = CreateConVar("talents_medic_health_start", "150", "How much health a medic should have");
	SABOTEUR_HEALTH = CreateConVar("talents_saboteur_health", "150", "How much health a saboteur should have");
	COMMANDO_HEALTH = CreateConVar("talents_commando_health", "300", "How much health a commando should have");
	ENGINEER_HEALTH = CreateConVar("talents_engineer_health", "150", "How much health a engineer should have");
	BRAWLER_HEALTH = CreateConVar("talents_brawler_health", "600", "How much health a brawler should have");
	
	
	SOLDIER_FIRE_RATE = CreateConVar("talents_soldier_fire_rate", "0.6666", "How fast the soldier should fire. Lower values = faster");
	SOLDIER_SPEED = CreateConVar("talents_soldier_speed", "1.25", "How fast soldier should run. A value of 1.0 = normal speed", FCVAR_PLUGIN);

	ATHLETE_JUMP_VEL = CreateConVar("talents_athlete_jump", "450.0", "How high a soldier should be able to jump. Make this higher to make them jump higher, or 0.0 for normal height");

	MEDIC_HEAL_DIST = CreateConVar("talents_medic_heal_dist", "256.0", "How close other survivors have to be to heal. Larger values = larger radius");
	MEDIC_HEALTH_VALUE = CreateConVar("talents_medic_health", "10", "How much health to restore");
	MEDIC_MAX_ITEMS = CreateConVar("talents_medic_max_items", "3", "How many items the medic can drop");
	MEDIC_HEALTH_INTERVAL = CreateConVar("talents_medic_health_interval", "2.0", "How often to heal players within range");
	MEDIC_REVIVE_RATIO = CreateConVar("talents_medic_revive_ratio", "0.5", "How much faster medic revives. lower is faster");
	MEDIC_HEAL_RATIO = CreateConVar("talents_medic_heal_ratio", "0.5", "How much faster medic heals, lower is faster");
	DEFAULT_REVIVE_DURATION = CreateConVar("talents_default_revive_duration", "4.0", "Default reviving duration in seconds");
	DEFAULT_HEAL_DURATION = CreateConVar("talents_default_heal_duration", "4.0", "Default healing duration in seconds");

	MAX_MEDIC_BUILD_RANGE = CreateConVar("talents_medic_build_range", "120.0", "Maximum distance away an object can be dropped by medic");

	SABOTEUR_INVISIBLE_TIME = CreateConVar("talents_saboteur_invis_time", "5.0", "How long it takes for the saboteur to become invisible");
	SABOTEUR_BOMB_ACTIVATE = CreateConVar("talents_saboteur_bomb_activate", "5.0", "How long before the dropped bomb becomes sensitive to motion");
	SABOTEUR_BOMB_RADIUS = CreateConVar("talents_saboteur_bomb_radius", "128.0", "Radius of bomb motion detection");
	SABOTEUR_MAX_BOMBS = CreateConVar("talents_saboteur_max_bombs", "5", "How many bombs a saboteur can drop per round");
	SABOTEUR_BOMB_DAMAGE_SURV = CreateConVar("talents_saboteur_bomb_dmg_surv", "0", "How much damage a bomb does to survivors");
	SABOTEUR_BOMB_DAMAGE_INF = CreateConVar("talents_saboteur_bomb_dmg_inf", "1000", "How much damage a bomb does to infected");
	SABOTEUR_BOMB_POWER = CreateConVar("talents_saboteur_bomb_power", "2.0", "How much blast power a bomb has. Higher values will throw survivors farther away");

	//COMMANDO_DAMAGE_RATIO = CreateConVar("talents_commando_dmg_ratio", "1.5", "How many more times commando class does damage", FCVAR_PLUGIN);
	//COMMANDO_DAMAGE_CRITICAL_CHANCE = CreateConVar("talents_commando_dmg_critical_chance", "25", "Percent chance that damage will be critical", FCVAR_PLUGIN);
	//COMMANDO_DAMAGE_CRITICAL_RATIO = CreateConVar("talents_commando_dmg_critical_ratio", "3.0", "Critical damage ratio", FCVAR_PLUGIN);
	COMMANDO_DAMAGE = CreateConVar("talents_commando_dmg", "5", "How much bonus damage a Commando does");
	COMMANDO_RELOAD_RATIO = CreateConVar("talents_commando_reload_ratio", "0.44", "Ratio for how fast a Commando should be able to reload");
	SOLDIER_DAMAGE_REDUCE_RATIO = CreateConVar("talents_soldier_damage_reduce_ratio", "0.5", "Ratio for how much to reduce damage for soldier");
	ENGINEER_MAX_BUILDS = CreateConVar("talents_engineer_max_builds", "5", "How many times an engineer can build per round");
	MAX_ENGINEER_BUILD_RANGE = CreateConVar("talents_engineer_build_range", "120.0", "Maximum distance away an object can be built by the engineer");
	ENGINEER_TURRET_EXTERNAL_PLUGIN = CreateConVar("talents_engineer_machinegun_plugin", "1", "Whether to use external plugin for turrets.");
	MINIMUM_DROP_INTERVAL = CreateConVar("talents_drop_interval", "30.0", "Time before an engineer, medic, or saboteur can drop another item");
	GLOW_COLOR_ACTIVE = CreateConVar("talents_bomb_active_glow_color", "0 255 0", "Glow color for active bombs");

	DefaultHealDuration = GetConVarFloat(DEFAULT_HEAL_DURATION);
	DefaultReviveDuration = GetConVarFloat(DEFAULT_REVIVE_DURATION);

	SetConVarFloat(FindConVar("first_aid_kit_use_duration"), DefaultHealDuration, false, false);
	SetConVarFloat(FindConVar("survivor_revive_duration"), DefaultReviveDuration, false, false);
		
	FirstAidDuration = GetConVarFloat(FindConVar("first_aid_kit_use_duration"));
	ReviveDuration = GetConVarFloat(FindConVar("survivor_revive_duration"));

	g_VarFirstAidDuration = FindConVar("first_aid_kit_use_duration");
	g_VarReviveDuration = FindConVar("survivor_revive_duration");

	
	ResetAllState();//turrets stuff
	
	AutoExecConfig(true, "talents");
}

ResetClientVariables(client)
{
	ClientData[client].BombsUsed = 0;
	ClientData[client].ItemsBuilt = 0;
	ClientData[client].HideStartTime= GetGameTime();
	ClientData[client].HealStartTime= GetGameTime();
	ClientData[client].LastButtons = 0;
	ClientData[client].ChosenClass = NONE;
	ClientData[client].LastDropTime = 0.0;
	g_bInSaferoom[client] = false;
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

public Event_RoundChange(Handle:event, String:name[], bool:dontBroadcast)
{
	for (new i = 1; i < MAXPLAYERS; i++)
	{
		ResetClientVariables(i);
		LastClassConfirmed[i] = 0;
	}
	
	RndSession++;
	RoundStarted = false;
	ResetAllState();//turrets stuff
}

public OnMapStart()
{
	// Sounds
	PrecacheSound(SOUND_CLASS_SELECTED);
	PrecacheSound(SOUND_DROP_BOMB);
	PrecacheModel(MODEL_INCEN, true);
	PrecacheModel(MODEL_EXPLO, true);
	PrecacheModel(MODEL_SPRITE, true);
	PrecacheModel(SPRITE_GLOW, true);

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
	PrecacheTurret();//turretstuff
}

public OnMapEnd()
{
	// Cache
	ClearCache();
	
	RndSession = 0;
}

public OnClientPutInServer(client)
{
	if (!client || !IsValidEntity(client) || !IsClientInGame(client) || IsFakeClient(client))
		return;
	
	ResetClientVariables(client);
	RebuildCache();
}

public Action:TimerLoadGlobal(Handle:hTimer, any:client)
{
	if (!client || !IsValidEntity(client) || !IsClientInGame(client) || IsFakeClient(client))
		return;
	
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamagePre);
}

public Action:TimerLoadClient(Handle:hTimer, any:client)
{
	if (!client || !IsValidEntity(client) || !IsClientInGame(client) || IsFakeClient(client))
	return;
	
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
	SDKHook(client, SDKHook_SetTransmit, SetTransmitInvisible);
}

public OnClientDisconnect(client)
{
	RebuildCache();
	ResetClientVariables(client);
}

public Action:CreatePlayerClassMenuDelay(Handle:hTimer, any:client)
{
	CreatePlayerClassMenu(client);
}

public Action:TimerThink(Handle:hTimer, any:client)
{
	if (!IsValidEntity(client) || !IsClientInGame(client) || IsFakeClient(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2)
		return Plugin_Stop;
	
	new flags = GetEntityFlags(client);
	
	if (IsHanging(client) || IsIncapacitated(client) || FindAttacker(client) > 0 || IsClientOnLadder(client) || !(flags & FL_ONGROUND) || GetClientWaterLevel(client) > Water_Level:WATER_LEVEL_FEET_IN_WATER)
		return Plugin_Continue;
	
	new buttons = GetClientButtons(client);
	new bool:CanDrop = (GetGameTime() - ClientData[client].LastDropTime) >= GetConVarFloat(MINIMUM_DROP_INTERVAL);
	new float:iCanDropTime = (GetGameTime() - ClientData[client].LastDropTime);
	

	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	
	switch (ClientData[client].ChosenClass)
	{
		//case ATHLETE:
		//	SetEntDataFloat(client, g_ioLMV, GetConVarFloat(ATHLETE_SPEED), true);
		
		case SABOTEUR:
		{
			if (BombActive == true && RoundToFloor(iCanDropTime) < GetConVarInt(SABOTEUR_BOMB_ACTIVATE)) {
					PrintHintTextToAll("%N's mine becomes active in %i seconds", client, GetConVarInt(SABOTEUR_BOMB_ACTIVATE) - (RoundToFloor(iCanDropTime)));
			}
			if (BombActive == true && RoundToFloor(iCanDropTime) == GetConVarInt(SABOTEUR_BOMB_ACTIVATE)) {
					PrintHintTextToAll("%N's mine is active!", client);
			}

			if (buttons & IN_DUCK )//&& 
			{
				if (GetGameTime() - ClientData[client].HideStartTime >= GetConVarFloat(SABOTEUR_INVISIBLE_TIME)) {
					if (InvisibilityHint == false) 
					{
						PrintHintText(client,"You are now invisible!");
						InvisibilityHint = true;						
					}
				}

				//SetEntityRenderFx(client, RENDERFX_FADE_SLOW);
			//else
				SetEntityRenderFx(client, RENDERFX_NONE);
				SetEntDataFloat(client, g_ioLMV, 1.5, true);
			}
			else
			{
				InvisibilityHint = false;
				SetEntDataFloat(client, g_ioLMV, 1.0, true);
			}
			
			if (buttons & IN_SPEED)
			{
				if (CanDrop == false && (RoundToFloor(iCanDropTime) > GetConVarInt(SABOTEUR_BOMB_ACTIVATE))) {
					PrintHintText(client ,"Next bomb available in %i seconds", (GetConVarInt(MINIMUM_DROP_INTERVAL) - RoundToFloor(iCanDropTime)));
				} else {

					if (CanDrop == true && !IsPlayerInSaferoom(client) && !IsInEndingSaferoom(client))
					{
						if (ClientData[client].ItemsBuilt > GetConVarInt(SABOTEUR_MAX_BOMBS)) {
							PrintHintText(client ,"Maximum amount of bombs used!");
						} else {
							DropBomb(client);							
							ClientData[client].ItemsBuilt++;
							ClientData[client].LastDropTime = GetGameTime();
						}
					}
				}
			}
		}
		
		case MEDIC:
		{
			if (buttons & IN_SPEED && CanDrop && ClientData[client].ItemsBuilt < GetConVarInt(MEDIC_MAX_ITEMS))
			{	
				CreatePlayerMedicMenu(client);	
				ClientData[client].LastDropTime = GetGameTime();
			}
			if (buttons & IN_DUCK && (GetGameTime() - ClientData[client].HealStartTime) >= 3.0) {
					if (MedicHint == false) {
			 			PrintHintTextToAll("\x03%N\x01 is healing everyone around him!", client);
						MedicHint = true;
					}
			} else {
				MedicHint = false;
			}
		}
		
		case ENGINEER:
		{
			if (buttons & IN_SPEED && RoundStarted == true && CanDrop)// && ClientData[client].ItemsBuilt < GetConVarInt(ENGINEER_MAX_BUILDS)) 
			{	
				if(ClientData[client].ItemsBuilt < GetConVarInt(ENGINEER_MAX_BUILDS))
				{
					CreatePlayerEngineerMenu(client);	
					ClientData[client].LastDropTime = GetGameTime();
				}
				else
				{
					CreateRemoveTurretMenu(client);
				}
				
				
			}
		}
		case SOLDIER:
		{
			SetEntDataFloat(client, g_ioLMV, GetConVarFloat(SOLDIER_SPEED), true);
		}
		
	}
	
	return Plugin_Continue;
}

CreateRemoveTurretMenu(client)
{
	if (!client)
		return false;
	
	new Handle:hPanel;
	
	if((hPanel = CreatePanel()) == INVALID_HANDLE)
	{
		LogError("Cannot create hPanel on CreateRemoveTurretMenu");
		return false;
	}
	
	SetPanelTitle(hPanel, "Turret:");
	DrawPanelItem(hPanel, "Remove ");
	DrawPanelText(hPanel, " ");
	DrawPanelItem(hPanel, "Exit");
	
	SendPanelToClient(hPanel, client, PanelHandler_RemoveTurretMenu, MENU_OPEN_TIME);
	CloseHandle(hPanel);
	
	return true;
}
public PanelHandler_RemoveTurretMenu(Handle:menu, MenuAction:action, client, param)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if( param == 1 && removemachine(client))//was 5
			{
				ClientData[client].ItemsBuilt--;
			}	
		}
	}
}
CreatePlayerMedicMenu(client)
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
			if( param >= 1 && param <= 4 )//was 5
				CalculateMedicPlacePos(client, param - 1);
		}
	}
}

CreatePlayerEngineerMenu(client)
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
	DrawPanelItem(hPanel, "Turret");
	DrawPanelItem(hPanel, "Frag Rounds");
	DrawPanelItem(hPanel, "Incendiary Rounds");
	DrawPanelItem(hPanel, "Remove Turret");/// what ive added for remove tureet
	DrawPanelText(hPanel, " ");
	DrawPanelItem(hPanel, "Exit");
	
	SendPanelToClient(hPanel, client, PanelHandler_SelectEngineerItem, MENU_OPEN_TIME);
	CloseHandle(hPanel);
	
	return true;
}

public PanelHandler_SelectEngineerItem(Handle:menu, MenuAction:action, client, param)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if( param >= 1 && param <= 5 )//was 5
				CalculateEngineerPlacePos(client, param - 1);
		}
	}
}

CalculateMedicPlacePos(client, type)
{
	decl Float:vAng[3], Float:vPos[3], Float:endPos[3];
	
	GetClientEyeAngles(client, vAng);
	GetClientEyePosition(client, vPos);

	new Handle:trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, TraceFilter, client);

	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(endPos, trace);
		CloseHandle(trace);
		
		if (GetVectorDistance(endPos, vPos) <= GetConVarFloat(MAX_MEDIC_BUILD_RANGE))
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

					ClientData[client].ItemsBuilt++;
				}
				case 1:{
					new entity = CreateEntityByName("weapon_first_aid_kit");
					DispatchKeyValue(entity, "solid", "0");
					DispatchSpawn(entity);
					TeleportEntity(entity, endPos, NULL_VECTOR, NULL_VECTOR);

					ClientData[client].ItemsBuilt++;
				}
				case 2: {
					new entity = CreateEntityByName("weapon_adrenaline_spawn");
					DispatchKeyValue(entity, "solid", "0");
					DispatchKeyValue(entity, "disableshadows", "1");
					TeleportEntity(entity, endPos, NULL_VECTOR, NULL_VECTOR);
					DispatchSpawn(entity);
					ClientData[client].ItemsBuilt++;

				}
				case 3: {
					new pills = CreateEntityByName("weapon_pain_pills_spawn", -1);
					DispatchKeyValue(pills, "solid", "6");
					DispatchKeyValue(pills, "disableshadows", "1");
					TeleportEntity(pills, endPos, NULL_VECTOR, NULL_VECTOR);
					DispatchSpawn(pills);
					ClientData[client].ItemsBuilt++;

				}				
				default: {
					CloseHandle( trace );
					return;
				}
			}
			
			//ClientData[client].ItemsBuilt++;
		}
		else
			PrintToChat(client, "%sCould not place the item because you were looking too far away.", PRINT_PREFIX);
	}
	else
		CloseHandle(trace);
}

CalculateEngineerPlacePos(client, type)
{
	decl Float:vAng[3], Float:vPos[3], Float:endPos[3];
	
	GetClientEyeAngles(client, vAng);
	GetClientEyePosition(client, vPos);

	new Handle:trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, TraceFilter, client);

	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(endPos, trace);
		CloseHandle(trace);
		
		if (GetVectorDistance(endPos, vPos) <= GetConVarFloat(MAX_ENGINEER_BUILD_RANGE))
		{
			vAng[0] = 0.0;
			vAng[2] = 0.0;
			
			switch(type) {
				case 0: {
					new ammo = CreateEntityByName("weapon_ammo_spawn");
					DispatchSpawn(ammo);
					TeleportEntity(ammo, endPos, NULL_VECTOR, NULL_VECTOR);
					ClientData[client].ItemsBuilt++;
				}
				case 1:{

					if (GetConVarInt(ENGINEER_TURRET_EXTERNAL_PLUGIN) > 0) 
					{
						ClientCommand(client, Engineer_Turret_Spawn_Cmd);
					} else {

						if(CreateMachine(client))
						{
							ClientData[client].ItemsBuilt++;
						}
					}
				}
				case 2: {
					new upgrade = CreateEntityByName("upgrade_ammo_explosive");
					SetEntityModel(upgrade, MODEL_EXPLO);
					TeleportEntity(upgrade, endPos, NULL_VECTOR, NULL_VECTOR);
					DispatchSpawn(upgrade);
					ClientData[client].ItemsBuilt++;
					ClientData[client].LastDropTime = GetGameTime();

				}
				case 3: {
					new upgrade = CreateEntityByName("upgrade_ammo_incendiary");
					SetEntityModel(upgrade, MODEL_INCEN);
					TeleportEntity(upgrade, endPos, NULL_VECTOR, NULL_VECTOR);
					ClientData[client].ItemsBuilt++;
					DispatchSpawn(upgrade);
					ClientData[client].LastDropTime = GetGameTime();

				}
				
				case 4: {
					if (GetConVarInt(ENGINEER_TURRET_EXTERNAL_PLUGIN) > 0) 
					{
						ClientCommand(client, Engineer_Turret_Remove_Cmd);
					} else {

						if (removemachine(client))
						{
							ClientData[client].ItemsBuilt--;	
						}
					}
				}
				default: {
					CloseHandle( trace );
					return;
				}
			}
			
			//ClientData[client].ItemsBuilt++;
			ClientData[client].LastDropTime = GetGameTime();
		}
		else
			PrintToChat(client, "%sCould not place the item because you were looking too far away.", PRINT_PREFIX);
	}
	else
		CloseHandle(trace);
}
/*
SpawnMiniGun(Float:vAng[3], Float:vPos[3])
{
	new entity = CreateEntityByName("prop_minigun");
	SetEntityModel(entity, ENGINEER_MACHINE_GUN);
	DispatchKeyValueFloat(entity, "MaxPitch", 360.00);
	DispatchKeyValueFloat(entity, "MinPitch", -360.00);
	DispatchKeyValueFloat(entity, "MaxYaw", 90.00);
	TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

	SetEntData( entity, g_CollisionOffset, 1, 4, true );

	DispatchSpawn(entity);
}
*/
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
public Action:SetTransmitInvisible(client, entity)
{
	if (ClientData[client].ChosenClass == SABOTEUR && ((GetGameTime() - ClientData[client].HideStartTime) >= (GetConVarFloat(SABOTEUR_INVISIBLE_TIME))) && client != entity) {

		if (InvisibilityHint == false) 
		{
			PrintHintText(client,"You are now invisible!");
			InvisibilityHint = true;						
		}
		SetEntityRenderFx(client, RENDERFX_NONE);
		SetEntDataFloat(client, g_ioLMV, 1.5, true);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

DropBomb(client)
{
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	
	new Handle:hPack = CreateDataPack();
	WritePackFloat(hPack, pos[0]);
	WritePackFloat(hPack, pos[1]);
	WritePackFloat(hPack, pos[2]);
	WritePackCell(hPack, client);
	WritePackCell(hPack, RndSession);
	CreateTimer(GetConVarFloat(SABOTEUR_BOMB_ACTIVATE), TimerActivateBomb, hPack, TIMER_FLAG_NO_MAPCHANGE);

	TE_SetupBeamRingPoint(pos, 10.0, 256.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greenColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos, 10.0, 256.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, redColor, 10, 0);
	TE_SendToAll();
	BombActive = true;
	CreateParticleInPos(pos, BOMB_GLOW);
	EmitSoundToAll(SOUND_DROP_BOMB);
	
	PrintHintTextToAll("%N dropped a regular mine!", client);
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
	
	if (session != RndSession)
		return Plugin_Stop;
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsValidEntity(client) || !IsClientInGame(client) || !IsPlayerAlive(client) || IsGhost(client))
			continue;
		if(GetClientTeam(client) == 3)
		{
			GetClientAbsOrigin(client, clientpos);
		
			if (GetVectorDistance(pos, clientpos) < GetConVarFloat(SABOTEUR_BOMB_RADIUS))
			{
				PrintHintTextToAll("\x03%N\x01's \x04mine \x01detonated!", owner);
				CreateExplosion(pos, owner, false);
				BombActive = false;
				CloseHandle(hPack);

				return Plugin_Stop;
			}
		}	
	}
	
	return Plugin_Continue;
}

public Action:OnTakeDamagePre(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (!IsServerProcessing())
		return Plugin_Continue;
	
	if (victim && attacker && IsValidEntity(attacker) && attacker <= MaxClients && IsValidEntity(victim) && victim <= MaxClients)
	{

		//PrintToChatAll("%s", m_attacker);
		if(ClientData[attacker].ChosenClass == SOLDIER && GetClientTeam(victim) == 2)
		{
			//PrintToChat(victim, "Damage: %f, New: %f", damage, damage*0.5);
			damage = damage * GetConVarFloat(SOLDIER_DAMAGE_REDUCE_RATIO);
			return Plugin_Changed;
		}
		if (ClientData[attacker].ChosenClass == COMMANDO && GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 3)
		{
			/*if (GetConVarInt(COMMANDO_DAMAGE_CRITICAL_CHANCE) <= GetRandomInt(1, 100))
				damage *= GetConVarFloat(COMMANDO_DAMAGE_CRITICAL_RATIO);
			else
				damage *= GetConVarFloat(COMMANDO_DAMAGE_RATIO);*/
			damage = damage + getdamage(attacker);
			//PrintToChat(attacker,"%f",damage);
			//damage += GetConVarInt(COMMANDO_DAMAGE);
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}
public Action:CmdClassInfo(client, args)
{
	PrintToChat(client,"\x05Soldier\x01 = Has faster attack rate, runs faster and takes less damage");
	PrintToChat(client,"\x05Athlete\x01 = Jumps higher");
	PrintToChat(client,"\x05Medic\x01 = Heals others, plants medical supplies. Faster revive & heal speed");
	PrintToChat(client,"\x05Saboteur\x01 = Can go invisible, plants powerful mines and throws special grenades");
	PrintToChat(client,"\x05Commando\x01 = Has fast reload, deals extra damage");
	PrintToChat(client,"\x05Engineer\x01 = Drops auto turrets and ammo");
	PrintToChat(client,"\x05Brawler\x01 = Has Lots of health");	
}

public Action:CmdClasses(client, args)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if(ClientData[i].ChosenClass != _:NONE)
		{
			PrintToChatAll("\x04%N\x01 : is a %s",i,MENU_OPTIONS[ClientData[i].ChosenClass]);
		}
	}
}

CreatePlayerClassMenu(client)
{
	if (!client)
		return false;
	
	// if client has a class already and round has started, dont give them the menu
	if (ClientData[client].ChosenClass !=  _:NONE && RoundStarted == true)
	{
		PrintToChat(client,"Round has started, your class is locked, You are a %s",MENU_OPTIONS[ClientData[client].ChosenClass]);
		return false;
	}
	
	new Handle:hPanel;
	decl String:buffer[256];
	
	if((hPanel = CreatePanel()) == INVALID_HANDLE)
	{
		LogError("Cannot create hPanel on CreatePlayerClassMenu");
		return false;
	}
	
	SetPanelTitle(hPanel, "Select Your Class");
	
	for (new i = 1; i < _:MAXCLASSES; i++)
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
			if (!client || param >= _:MAXCLASSES || GetClientTeam(client)!=2 )
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
/*
DrawConfirmPanel(client, chosenClass)
{
	if (!client || chosenClass >= _:MAXCLASSES)
		return false;
	
	LastChosenClass[client] = chosenClass;
	
	new Handle:hPanel;
	decl String:buffer[256];
	
	if((hPanel = CreatePanel()) == INVALID_HANDLE)
	{
		LogError("Cannot create hPanel on CreatePlayerClassMenu");
		return false;
	}
	
	Format(buffer, sizeof(buffer), "Select the %s talent?", MENU_OPTIONS[chosenClass]);
	SetPanelTitle(hPanel, buffer);
	
	
	DrawPanelItem(hPanel, "Yes");
	DrawPanelItem(hPanel, "No");
	
	SendPanelToClient(hPanel, client, PanelHandler_ConfirmClass, MENU_OPEN_TIME);
	CloseHandle(hPanel);
	
	return true;
}

public PanelHandler_ConfirmClass(Handle:menu, MenuAction:action, client, param)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			new class = LastChosenClass[client];
			
			if( param == 1 && class < _:MAXCLASSES && ( CountPlayersWithClass( class ) < GetMaxWithClass( class ) || ClientData[client].ChosenClass != class || GetMaxWithClass( class ) < 0 ) )
			{
				LastClassConfirmed[client] = class;
				
				PrintToConsole(client, "Class is setting up");
				
				SetupClasses(client, class);
				EmitSoundToClient(client, SOUND_CLASS_SELECTED);
				PrintToChat(client, "%sYou are now a \x04%s", PRINT_PREFIX, MENU_OPTIONS[class]);
			}
			else
				CreatePlayerClassMenu(client);
		}
	}
}
*/


SetupClasses(client, class)
{
	if (!client
		|| !IsValidEntity(client)
		|| !IsClientInGame(client)
		|| !IsPlayerAlive(client)
		|| GetClientTeam(client) != 2)
			return;
	
	ClientData[client].ChosenClass = class;
	new MaxPossibleHP = 100;
	
	switch (class)
	{
		case SOLDIER:	
		{
			PrintHintText(client,"You have increased attack rate, reduced damage and faster movement!");
			MaxPossibleHP = GetConVarInt(SOLDIER_HEALTH);
		}
		
		case MEDIC:
		{
			PrintHintText(client,"Hold CTRL to heal mates around you, Press SHIFT to open droppable menu!");
			CreateTimer(GetConVarFloat(MEDIC_HEALTH_INTERVAL), TimerDetectHealthChanges, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			MaxPossibleHP = GetConVarInt(MEDIC_HEALTH);
		}
		
		case ATHLETE:
		{
			PrintHintText(client,"Hold JUMP to bunny hop!");
			MaxPossibleHP = GetConVarInt(ATHLETE_HEALTH);
		}
		
		case COMMANDO:
		{
			PrintHintText(client,"You have increased reload and fire rate!");
			MaxPossibleHP = GetConVarInt(COMMANDO_HEALTH);
		}
		
		case ENGINEER:
		{
			PrintHintText(client,"Press SHIFT to open equipment menu, the turret is automatic");
			MaxPossibleHP = GetConVarInt(ENGINEER_HEALTH);
		}
		
		case SABOTEUR:
		{
			PrintHintText(client,"Hold CROUCH 5 sec to go invisible from humans. Press SHIFT to drop mine!");
			MaxPossibleHP = GetConVarInt(SABOTEUR_HEALTH);
		}
		
		case BRAWLER:
		{
			PrintHintText(client,"You've got a lot of health, try to waste it well!");
			MaxPossibleHP = GetConVarInt(BRAWLER_HEALTH);
		}
	}
	
	// HEALTH
	new OldMaxHealth = GetEntProp(client, Prop_Send, "m_iMaxHealth");
	new OldHealth = GetClientHealth(client);
	new OldTempHealth = GetClientTempHealth(client);
	
	SetEntProp(client, Prop_Send, "m_iMaxHealth", MaxPossibleHP);
	SetEntityHealth(client, MaxPossibleHP - (OldMaxHealth - OldHealth));
	SetClientTempHealth(client, OldTempHealth);
	
	if ((GetClientHealth(client) + GetClientTempHealth(client)) > MaxPossibleHP)
	{
		SetEntityHealth(client, MaxPossibleHP);
		SetClientTempHealth(client, 0);
	}
}

public Action:CmdClassMenu(client, args)
{
	if (GetClientTeam(client) != 2)
	{
		PrintToChat(client, "%sOnly Survivors can choose a class.", PRINT_PREFIX);
		return;
	}
	
	//if (ClientData[client].ChosenClass != _:NONE)
	//{
	//	PrintToChat(client, "%sYou have already chosen a class this round.", PRINT_PREFIX);
	//	return;
	//}
	
	CreatePlayerClassMenu(client);
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
					
					SetEntityHealth(i, GetClientHealth(i) + GetConVarInt(MEDIC_HEALTH_VALUE));
					SetClientTempHealth(i, TempHealth);
					
					// post-heal set values
					new newHp = GetClientHealth(i);
					new totalHp = newHp + TempHealth;
					
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
		|| ClientData[client].ChosenClass != SOLDIER)
			continue;
		
		bweapon = GetEntDataEnt2(client, g_oAW);
		
		if(bweapon <= 0) 
			continue;
		
		fNTR = GetEntDataFloat(bweapon, g_iNPA);
		
		if (g_iEi[client] == bweapon && g_fNT[client] >= fNTR)
			continue;
		
		if (g_iEi[client] == bweapon && g_fNT[client] < fNTR)
		{
			fNTC = ( fNTR - fGT ) * GetConVarFloat(SOLDIER_FIRE_RATE) + fGT;
			g_fNT[client] = fNTC;
			SetEntDataFloat(bweapon, g_iNPA, fNTC, true);
			continue;
		}
		
		if (g_iEi[client] != bweapon)
		{
			g_iEi[client] = bweapon;
			g_fNT[client] = fNTR;
			continue;
		}
	}
}

ClearCache()
{
	g_iRC = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		g_iRI[i]= -1;
		g_iEi[i] = -1;
		g_fNT[i]= -1.0;
	}
}

RebuildCache()
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
	ResetClientVariables(client);
}

public Action:OnWeaponSwitch(client, weapon)
{
	RebuildCache();
}

public Action:OnWeaponEquip(client, weapon)
{
	RebuildCache();
}

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
	}
	
	ClientData[client].LastButtons = buttons;
	
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
	GetEntityNetClass(weapon, bNetCl, sizeof(bNetCl));
	
	if (StrContains(bNetCl, "shotgun", false) == -1)
	{
		new Float:fRLRat = GetConVarFloat(COMMANDO_RELOAD_RATIO);
		new Float:fNTC = (GetEntDataFloat(weapon, g_iNPA) - flGT) * fRLRat;
		new Float:NA = fNTC + flGT;
		
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
		
		if (StrContains(bNetCl, "pumpshotgun", false) != -1)
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
	
	return Plugin_Stop;
}

public Action:CommandoPumpShotReload(Handle:timer, Handle:hOldPack)
{
	ResetPack(hOldPack);
	new weapon = ReadPackCell(hOldPack);
	new Float:fRLRat = GetConVarFloat(COMMANDO_RELOAD_RATIO);
	
	SetEntDataFloat(weapon,	g_iSSD,	ReadPackFloat(hOldPack) * fRLRat,	true);
	SetEntDataFloat(weapon,	g_iSID,	ReadPackFloat(hOldPack) * fRLRat,	true);
	SetEntDataFloat(weapon,	g_iSED, ReadPackFloat(hOldPack) * fRLRat,	true);
	SetEntDataFloat(weapon, g_ioPR, 1.0 / fRLRat, true);
	
	CloseHandle(hOldPack);
	
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
		return Plugin_Stop;
	}
	
	if (GetEntData(weapon, g_iSRS) == 0)
	{
		new Float:flNextTime = GetGameTime() + addMod;
		
		SetEntDataFloat(weapon, g_ioPR, 1.0, true);
		SetEntDataFloat(GetEntPropEnt(weapon, Prop_Data, "m_hOwner"), g_ioNA, flNextTime, true);
		SetEntDataFloat(weapon,	g_ioTI, flNextTime, true);
		SetEntDataFloat(weapon,	g_iNPA, flNextTime, true);
		
		CloseHandle(hPack);
		
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
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


public Plugin:myinfo =
{
	name = "Talents Plugin 2023 anniversary edition",
	author = "DLR / Ken / Neil / Spirit / panxiaohai / Yani",
	description = "Incorporates Survivor Classes",
	version = "v1.2",
	url = "https://forums.alliedmods.net/showthread.php?t=273312"
};

CountPlayersWithClass( class ) {
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

GetMaxWithClass( class ) {
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

	return -1;
}

public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (ClientData[client].ChosenClass == _:NONE && GetClientTeam(client) == 2)
	{
		if(client >0 && client < MAXPLAYERS + 1)
		{
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

getdamage(client)
{
	if (StrContains(ClientData[client].EquippedGun,"rifle", false)!=-1)
	{
		return 10;
	}
	if (StrContains(ClientData[client].EquippedGun,"shotgun", false)!=-1)
	{
		return 5;
	}
	if (StrContains(ClientData[client].EquippedGun, "commando", false)!=-1)
	{
		return 15;
	}
	if (StrContains(ClientData[client].EquippedGun, "hunting", false)!=-1)
	{
		return 15;
	}
	if (StrContains(ClientData[client].EquippedGun, "pistol", false)!=-1)
	{
		return 25;
	}
	if (StrContains(ClientData[client].EquippedGun, "smg", false)!=-1)
	{
		return 7;
	}
	return 0;
}

public Action:Event_LeftStartArea(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundStarted = true;
	PrintToChatAll("%sPlayers left safe area, classes now locked!",PRINT_PREFIX);	
}
stock bool:IsWitch(iEntity)
{
    if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
    {
        decl String:strClassName[64];
        GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
        return StrEqual(strClassName, "witch");
    }
    return false;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////

#include <sdktools_functions>

#define Pai 3.14159265358979323846 
#define DEBUG false

#define PARTICLE_MUZZLE_FLASH		"weapon_muzzle_flash_autoshotgun"  
#define PARTICLE_WEAPON_TRACER		"weapon_tracers" 
#define PARTICLE_WEAPON_TRACER2		"weapon_tracers_50cal"//weapon_tracers_50cal" //"weapon_tracers_explosive" weapon_tracers_50cal
 
#define PARTICLE_BLOOD		"blood_impact_red_01"
#define PARTICLE_BLOOD2		"blood_impact_headshot_01"

#define SOUND_IMPACT1		"physics/flesh/flesh_impact_bullet1.wav"  
#define SOUND_IMPACT2		"physics/concrete/concrete_impact_bullet1.wav"  
#define SOUND_FIRE		"weapons/50cal/50cal_shoot.wav"  
#define MODEL_GUN "models/w_models/weapons/w_minigun.mdl"

new MachineCount = 0;

#define EnemyArraySize 300
new InfectedsArray[EnemyArraySize];
new InfectedCount;

new UseCount[MAXPLAYERS+1]; 

new Float:ScanTime=0.0;

new Gun[MAXPLAYERS+1];
new GunOwner[MAXPLAYERS+1];
new GunEnemy[MAXPLAYERS+1];

new Float:GunFireStopTime[MAXPLAYERS+1];
new Float:GunFireTime[MAXPLAYERS+1];
new Float:GunFireTotolTime[MAXPLAYERS+1];
new GunScanIndex[MAXPLAYERS+1]; 
new Float:LastTime[MAXPLAYERS+1]; 


new Float:FireIntervual=0.08; 
new Float:FireOverHeatTime=10.0;
new Float:FireRange=1000.0;

GetMinigun(client )
{ 
	new ent= GetClientAimTarget(client, false);
	if(ent>0)
	{			
		decl String:classname[64];
		GetEdictClassname(ent, classname, 64);			
		if(StrEqual(classname, "prop_minigun") || StrEqual(classname, "prop_minigun_l4d1"))
		{
		}
		else ent=0;
	}  
	return ent;
}
 
machine(client)
{
	if(ClientData[client].ItemsBuilt>=4)
	{
		PrintToChat(client, "You can use it more than %d times",4);
		return;
	}
	if(client>0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		CreateMachine(client);
	}
}
bool:removemachine(client)
{
	if(client>0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		new gun=GetMinigun(client);
		new index=FindGunIndex(gun);
		if(index<0)
		{
			return false;
		}
		else
		{
			RemoveMachine(index);
			return true;
		}
	}
	return false;
} 
/*public Action:witch_harasser_set(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	new witch =  GetEventInt(hEvent, "witchid") ; 
	InfectedsArray[0]=witch;	
	for(new i=0; i<MachineCount; i++)
	{
		GunEnemy[i]=witch;
		GunScanIndex[i]=0;
	}
}*/
public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	} 
	return true;
}
CopyVector(Float:source[3], Float:target[3])
{
	target[0]=source[0];
	target[1]=source[1];
	target[2]=source[2];
}

public void PrecacheTurret()
{
	PrecacheModel(MODEL_GUN);
	 
	PrecacheSound(SOUND_FIRE);
	PrecacheSound(SOUND_IMPACT1);	
	PrecacheSound(SOUND_IMPACT2);
 
	PrecacheParticle(PARTICLE_MUZZLE_FLASH);
		
	PrecacheParticle(PARTICLE_WEAPON_TRACER2);
	PrecacheParticle(PARTICLE_BLOOD);
	PrecacheParticle(PARTICLE_BLOOD2);

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

ShowMuzzleFlash(Float:pos[3],  Float:angle[3])
{  
 	new particle = CreateEntityByName("info_particle_system");
	DispatchKeyValue(particle, "effect_name", PARTICLE_MUZZLE_FLASH); 
	DispatchSpawn(particle);
	ActivateEntity(particle); 
	TeleportEntity(particle, pos, angle, NULL_VECTOR);
	AcceptEntityInput(particle, "start");	
	CreateTimer(0.01, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);	
}
ResetAllState()
{
	MachineCount=0;
	ScanTime=0.0;
	for(new i=1; i<=MaxClients; i++)
	{ 
		UseCount[i]=0;
	} 
	InfectedCount=0;	
} 
ScanEnemys()
{	
	if(IsWitch(InfectedsArray[0]))
	{
		InfectedCount=1;
	}
	else InfectedCount=0;
	
	for(new i=1 ; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			InfectedsArray[InfectedCount++]=i;
		}
	}
	new ent=-1;
	while ((ent = FindEntityByClassname(ent,  "infected" )) != -1 && InfectedCount<EnemyArraySize-1)
	{
		InfectedsArray[InfectedCount++]=ent;
	} 
}
bool:CreateMachine(client)
{
	if(MachineCount >= 4)
	{
		PrintToChat(client, "There are too many machine");
		return false;
	} 
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(!(GetEntityFlags(client) & FL_ONGROUND))return false;
		Gun[MachineCount]=SpawnMiniGun(client);  
		LastTime[MachineCount]=GetEngineTime();
		
		GunScanIndex[MachineCount]=0;
		GunEnemy[MachineCount]=0;
		GunFireTime[MachineCount]=0.0;
		GunFireStopTime[MachineCount]=0.0;
		GunFireTotolTime[MachineCount]=0.0;
		GunOwner[MachineCount]=client;		
		
		SDKUnhook( Gun[MachineCount], SDKHook_Think,  PreThinkGun); 
		SDKHook( Gun[MachineCount], SDKHook_Think,  PreThinkGun); 

		UseCount[client]++;
		if(MachineCount==0)
		{
			ScanEnemys();
		} 
		MachineCount++;
		return true;
	}
	return false;
}
RemoveMachine(index)
{
	SDKUnhook( Gun[index], SDKHook_Think,  PreThinkGun);   
	if(Gun[index]>0 && IsValidEdict(Gun[index]) && IsValidEntity(Gun[index]))AcceptEntityInput((Gun[index]), "Kill");
	Gun[index]=0;
	if(MachineCount>1)
	{		
		Gun[index]=Gun[MachineCount-1];
		LastTime[index]=LastTime[MachineCount-1];
 
		GunScanIndex[index]=GunScanIndex[MachineCount-1];
		GunEnemy[index]=GunEnemy[MachineCount-1];
		GunFireTime[index]=GunFireTime[MachineCount-1];
		GunFireStopTime[index]=GunFireStopTime[MachineCount-1];
		GunFireTotolTime[index]=GunFireTotolTime[MachineCount-1];
		GunOwner[index]=GunOwner[MachineCount-1];
	}
	MachineCount--;
 
	if(MachineCount<0)MachineCount=0; 
}

SpawnMiniGun(client)
{
	decl Float:VecOrigin[3], Float:VecAngles[3], Float:VecDirection[3]; 
	new gun=0;
	gun=CreateEntityByName ( "prop_minigun"); 
	SetEntityModel (gun, MODEL_GUN);		
	DispatchSpawn(gun);
	GetClientAbsOrigin(client, VecOrigin);
	GetClientEyeAngles(client, VecAngles);
	GetAngleVectors(VecAngles, VecDirection, NULL_VECTOR, NULL_VECTOR);
	VecOrigin[0] += VecDirection[0] * 45;
	VecOrigin[1] += VecDirection[1] * 45;
	VecOrigin[2] += VecDirection[2] * 1;   
	VecAngles[0] = 0.0;
	VecAngles[2] = 0.0;
	DispatchKeyValueVector(gun, "Angles", VecAngles);
	TeleportEntity(gun, VecOrigin, NULL_VECTOR, NULL_VECTOR);
	SetEntProp(gun, Prop_Send, "m_iTeamNum", 2);  
	SetColor(gun);
	return gun;
}
SetColor(gun)
{
	SetEntProp(gun, Prop_Send, "m_iGlowType", 3);
	SetEntProp(gun, Prop_Send, "m_nGlowRange", 0);
	SetEntProp(gun, Prop_Send, "m_nGlowRangeMin", 1);
	new red=0;
	new gree=250;
	new blue=0;
	SetEntProp(gun, Prop_Send, "m_glowColorOverride", red + (gree * 256) + (blue* 65536));	
}

FindGunIndex(gun)
{
	new index=-1;
	for(new i=0; i<MachineCount; i++)
	{
		if(Gun[i]==gun)
		{
			index=i;
			break;
		}
	}
	return index;
}

public PreThinkGun(gun)
{	
	new index=FindGunIndex(gun);	
	if(index!=-1)
	{
		new Float:time=GetEngineTime( );
		new Float:intervual=time-LastTime[index];  
		LastTime[index]=time; 
		ScanAndShotEnmey(index, time, intervual); 
	}
}
ScanAndShotEnmey(index , Float:time, Float:intervual)
{
	new gun1=Gun[index]; 
	new user=GunOwner[index];
	if(user>0 && IsClientInGame(user))user=user+0;
	else user=0;
	
	if(time-ScanTime>1.0)
	{
		ScanTime=time;
		ScanEnemys(); 
	}	
	
	decl Float:gun1pos[3];
	decl Float:gun1angle[3];
	decl Float:hitpos[3];
	decl Float:temp[3];
	decl Float:shotangle[3];
	decl Float:gunDir[3];
	 
	GetEntPropVector(gun1, Prop_Send, "m_vecOrigin", gun1pos);	
	GetEntPropVector(gun1, Prop_Send, "m_angRotation", gun1angle);	
	 
	GetAngleVectors(gun1angle, gunDir, NULL_VECTOR, NULL_VECTOR );
	NormalizeVector(gunDir, gunDir);
	CopyVector(gunDir, temp);	
	ScaleVector(temp, 50.0);
	AddVectors(gun1pos, temp ,gun1pos);
	GetAngleVectors(gun1angle, NULL_VECTOR, NULL_VECTOR, temp );
	NormalizeVector(temp, temp);
	//ShowDir(2, gun1pos, temp, 0.06);
	ScaleVector(temp, 43.0);
 
	AddVectors(gun1pos, temp ,gun1pos);
 
	new newenemy=GunEnemy[index];
	if( IsVilidEenmey(newenemy))
	{
		newenemy = IsEnemyVisible(gun1, newenemy, gun1pos, hitpos,shotangle);		
	}
	else newenemy=0;
 
	if(InfectedCount>0 && newenemy==0)
	{
		if(GunScanIndex[index]>=InfectedCount)
		{
			GunScanIndex[index]=0;
		}
		GunEnemy[index]=InfectedsArray[GunScanIndex[index]];
		GunScanIndex[index]++;
		newenemy=0;
		
	}

	if(newenemy==0)
	{
		SetEntProp(gun1, Prop_Send, "m_firing", 0);

		return;
	}
	decl Float:enemyDir[3]; 
	decl Float:newGunAngle[3]; 
	if(newenemy>0)
	{
		SubtractVectors(hitpos, gun1pos, enemyDir);				
	}
	else
	{
		CopyVector(gunDir, enemyDir); 
		enemyDir[2]=0.0; 
	}
	NormalizeVector(enemyDir,enemyDir);	 
	
	decl Float:targetAngle[3]; 
	GetVectorAngles(enemyDir, targetAngle);
	new Float:diff0=AngleDiff(targetAngle[0], gun1angle[0]);
	new Float:diff1=AngleDiff(targetAngle[1], gun1angle[1]);
	
	new Float:turn0=45.0*Sign(diff0)*intervual;
	new Float:turn1=180.0*Sign(diff1)*intervual;
	if(FloatAbs(turn0)>=FloatAbs(diff0))
	{
		turn0=diff0;
	}
	if(FloatAbs(turn1)>=FloatAbs(diff1))
	{
		turn1=diff1;
	}
	 
	newGunAngle[0]=gun1angle[0]+turn0;
	newGunAngle[1]=gun1angle[1]+turn1; 
	 
	newGunAngle[2]=0.0; 
	
	DispatchKeyValueVector(gun1, "Angles", newGunAngle);
	new overheated=GetEntProp(gun1, Prop_Send, "m_overheated");
	
	GetAngleVectors(newGunAngle, gunDir, NULL_VECTOR, NULL_VECTOR); 
	
	if(overheated==0)
	{
		if( newenemy>0 && FloatAbs(diff1)<40.0)
		{ 
			if(time>=GunFireTime[index] )
			{
				GunFireTime[index]=time+FireIntervual;  								
				Shot(user,index, gun1, gun1pos, newGunAngle); 
				
				GunFireStopTime[index]=time+0.05; 	
			} 
		} 
	}
	new Float:heat=GetEntPropFloat(gun1, Prop_Send, "m_heat"); 
	
	if(time<GunFireStopTime[index])
	{
		GunFireTotolTime[index]+=intervual;
		heat=GunFireTotolTime[index]/FireOverHeatTime;
		if(heat>=1.0)heat=1.0;
		SetEntProp(gun1, Prop_Send, "m_firing", 1); 		
		SetEntPropFloat(gun1, Prop_Send, "m_heat", heat);
	}
	else 
	{
		SetEntProp(gun1, Prop_Send, "m_firing", 0); 	
		heat=heat-intervual/4.0;
		if(heat<0.0)
		{
			heat=0.0;
			SetEntProp(gun1, Prop_Send, "m_overheated", 0);
			SetEntPropFloat(gun1, Prop_Send, "m_heat", 0.0 );
		}
		else SetEntPropFloat(gun1, Prop_Send, "m_heat", heat ); 
		GunFireTotolTime[index]=FireOverHeatTime*heat; 
	}

	return;
}
IsEnemyVisible( gun, ent, Float:gunpos[3], Float:hitpos[3], Float:angle[3])
{		
	if(ent<=0)return 0;
	
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", hitpos);
	hitpos[2]+=35.0; 

	SubtractVectors(hitpos, gunpos, angle);
	GetVectorAngles(angle, angle); 
	new Handle:trace=TR_TraceRayFilterEx(gunpos, angle, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelf, gun); 	 

	new newenemy=0;
	 
	if(TR_DidHit(trace))
	{		 
		TR_GetEndPosition(hitpos, trace);
		newenemy = TR_GetEntityIndex(trace);  
		if(GetVectorDistance(gunpos, hitpos)>FireRange)newenemy=0;	 
	}
	else
	{
		newenemy=ent;
	}
	if(newenemy>0)
	{		 
		if(newenemy<=MaxClients)
		{
			if(!(IsClientInGame(newenemy) && IsPlayerAlive(newenemy) && GetClientTeam(newenemy)== 3))
				newenemy = 0;
		}
		else	
		{
			decl String:classname[32];
			GetEdictClassname(newenemy, classname,32);
			if(StrEqual(classname, "infected", true) || StrEqual(classname, "witch", true) )
			{
				newenemy=newenemy+0;
			}
			else newenemy=0;
		}
	} 
	CloseHandle(trace); 
	return newenemy;
}
Shot(client, index  ,gun, Float:gunpos[3],  Float:shotangle[3])
{
	decl Float:temp[3];
	decl Float:ang[3];
	GetAngleVectors(shotangle, temp, NULL_VECTOR,NULL_VECTOR); 
	NormalizeVector(temp, temp); 
	 
	new Float:acc=0.020; // add some spread
	temp[0] += GetRandomFloat(-1.0, 1.0)*acc;
	temp[1] += GetRandomFloat(-1.0, 1.0)*acc;
	temp[2] += GetRandomFloat(-1.0, 1.0)*acc;
	GetVectorAngles(temp, ang);

	new Handle:trace= TR_TraceRayFilterEx(gunpos, ang, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelf, gun); 
	new enemy=0;	
	 
	if(TR_DidHit(trace))
	{			
		decl Float:hitpos[3];		 
		TR_GetEndPosition(hitpos, trace);		
		enemy=TR_GetEntityIndex(trace); 
		
		if(enemy>0)
		{			
			decl String:classname[32];
			GetEdictClassname(enemy, classname, 32);	
			if(enemy >=1 && enemy<=MaxClients)//if enemy is a client
			{
				if(GetClientTeam(enemy)==2 ) {enemy=0;}	
			}
			else if(StrEqual(classname, "infected") || StrEqual(classname, "witch" ) )
			{

			} 	
			else enemy=0;
		} 
		if(enemy>0)
		{
			if(client>0 && IsPlayerAlive(client))client=client+0;
			else client=0;
			HurtEntity(enemy, client, 25.0, 0);
			decl Float:Direction[3];
			GetAngleVectors(ang, Direction, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(Direction, -1.0);
			GetVectorAngles(Direction,Direction);
			ShowParticle(hitpos, Direction, PARTICLE_BLOOD, 0.1);				
			EmitSoundToAll(SOUND_IMPACT1, 0,  SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS,1.0, SNDPITCH_NORMAL, -1,hitpos, NULL_VECTOR,true, 0.0);
		}
		else
		{		
			decl Float:Direction[3];
			Direction[0] = GetRandomFloat(-1.0, 1.0);
			Direction[1] = GetRandomFloat(-1.0, 1.0);
			Direction[2] = GetRandomFloat(-1.0, 1.0);
			TE_SetupSparks(hitpos,Direction,1,3);
			TE_SendToAll();
			EmitSoundToAll(SOUND_IMPACT2, 0,  SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS,1.0, SNDPITCH_NORMAL, -1,hitpos, NULL_VECTOR,true, 0.0);
		}
		ShowMuzzleFlash(gunpos, ang);
		EmitSoundToAll(SOUND_FIRE, 0,  SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS,1.0, SNDPITCH_NORMAL, -1,gunpos, NULL_VECTOR,true, 0.0);
	}
	CloseHandle(trace);
}
Float:AngleDiff(Float:a, Float:b)
{
	new Float:d=0.0;
	if(a>=b)
	{
		d=a-b;
		if(d>=180.0)d=d-360.0;
	}
	else
	{
		d=a-b;
		if(d<=-180.0)d=360+d;
	}
	return d;
}
Float:Sign(Float:v)
{	// positive or negitive number returns 1, 0 ,-1
	if(v==0.0)return 0.0;
	else if(v>0.0)return 1.0;
	else return -1.0;
}
bool:IsVilidEenmey(enemy)
{	
	new bool:r=false;
	if(enemy<=0)return r;
	if( enemy<=MaxClients)
	{ //if enemy is a client
		if(IsClientInGame(enemy) && IsPlayerAlive(enemy) && GetClientTeam(enemy)== 3)
		{
			r=true;
		} 
	}
	else if( IsValidEntity(enemy) && IsValidEdict(enemy))
	{
		decl String:classname[32];
		GetEdictClassname(enemy, classname,32);
		if(StrEqual(classname, "infected", true) )
		{
			r=true;
			new flag=GetEntProp(enemy, Prop_Send, "m_bIsBurning");
			if(flag==1)
			{
				r=false; 
			}
		}
		else if (StrEqual(classname, "witch", true))
		{
			r=true;
		}
	} 
	return r;
}
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


