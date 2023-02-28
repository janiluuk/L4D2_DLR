
///////////////////////////////////////////////////////////////////////////////////	
// Graphics & effects
///////////////////////////////////////////////////////////////////////////////////
stock g_BeamSprite = -1, g_HaloSprite = -1;
stock redColor[4]		= {255, 75, 75, 255};
stock greenColor[4]	= {75, 255, 75, 255};
stock String:g_ColorNames[12][32] = {"Red", "Green", "Blue", "Yellow", "Purple", "Cyan", "Orange", "Pink", "Olive", "Lime", "Violet", "Lightblue"};
stock g_Colors[12][3] = {{255,0,0},{0,255,0},{0,0,255},{255,255,0},{255,0,255},{0,255,255},{255,128,0},{255,0,128},{128,255,0},{0,255,128},{128,0,255},{0,128,255}};
// None, White, Red, Green, Blue, Yellow, Purple, Cyan, Orange, Pink, Olive, Lime, Violet, and Lightblue
stock FindColor(String:color[])
{
	for (new i = 0; i < 12; i++)
	{
		if(strcmp(color, g_ColorNames[i], false) == 0)
			return i;
	}
	
	return -1;
}

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

stock int CreateBombParticleInPos(Float:pos[3], String:Particle_Name[], int index)
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

stock ShowParticle(Float:pos[3], Float:ang[3],String:particlename[], Float:time)
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

stock void InputKill(int entity, float time)
{
	static char temp[40];
	Format(temp, sizeof(temp), "OnUser4 !self:Kill::%f:-1", time);
	SetVariantString(temp);
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser4");
}
stock Action:DeleteParticles(Handle:timer, any:particle)
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

stock Action:RemoveGlowFromAll() {

	for(new i = 0; i < MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
			SetRenderProperties(i);		
	}
	return Plugin_Handled;
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

stock int GetColor(char[] sTemp)
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

stock void SetupPrjEffects(int entity, float vPos[3], const char[] color)
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

stock void CreateBeamRing(int entity, int iColor[4], float min, float max, max_rings)
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
stock void MakeEnvSteam(int target, const float vPos[3], const float vAng[3], const char[] sColor)
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

stock void CreateEnvSprite(int target, const char[] sColor)
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

stock int MakeLightDynamic(int target, const float vPos[3])
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

stock int DisplayParticle(int target, const char[] sParticle, const float vPos[3], const float vAng[3], float refire = 0.0)
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

stock bool SetClientLocation(int client, float vPos[3])
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

stock bool ExcludeSelf_Filter(int entity, int contentsMask, any client)
{
	if( entity == client )
	return false;
	return true;
}
