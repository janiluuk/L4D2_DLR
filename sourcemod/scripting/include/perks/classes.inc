// UP THE VALUE 'MAX_PERKS' in base.inc before adding new ones!

int slipperyShoesIndex = 0;
int stickyGooIndex = 0;
int invertedPerkIndex;
// int fireSpitMagnetPerkIndex;

void SetupPerks() {
	perkKV = new StringMap();
	categories = new ArrayList(ByteCountToCells(16));
	gRandomClients = new ArrayList();
	int index;
	SetupPerk("Reset User", "Resets the user, removes all perk effects", PerkMod_Instant);

	/// CATEGORY: Magnets
	SetCategory("Magnets");
	index = SetupPerk("Special Magnet", "Attracts ALL specials to any alive target with this perk enabled", PerkMod_Constant);
	AddMagnetFlags(index);
	index = SetupPerk("Tank Magnet", "Attracts ALL tanks to any alive target with this perk enabled", PerkMod_Constant);
	AddMagnetFlags(index);
	#if defined _actions_included
	index = SetupPerk("Witch Magnet", "All witches when startled will target any player with this perk", PerkMod_Constant);
	#endif
	index = SetupPerk("Projectile Magnet", "Makes all projectiles (biles, molotovs, pipes, tank rocks) go to player", PerkMod_Constant);
	Perks[index].AddCustomFlagPrompt("Target Sources", true);
	// Tied to: ProjectileMagnetType
	Perks[index].AddFlag("Infected (rocks/goo)", true);
	Perks[index].AddFlag("Teammates (grenades)", false);
	Perks[index].AddFlag("Thrown Tank Objects", false);

	/// CATEGORY: Infected
	SetCategory("Infected");
	SetupPerk("Swarm", "Swarms a player with zombies. Requires swarm plugin", PerkMod_Instant | PerkMod_Constant);
	SetupPerk("Vomit Player", "Shortcut to sm_vomitplayer. vomits the player.", PerkMod_Instant);
	SetupPerk("Inface Special", "Shortcut to sm_inface", PerkMod_Instant);
	SetupPerk("Insta Special", "Shortcut to sm_insta", PerkMod_Instant);
	SetupPerk("Goo", "Spawns a spitter puddle underneath them", PerkMod_Instant);
	index = SetupPerk("Sticky Goo", "Slows player down in goo", PerkMod_Constant);
	Perks[index].AddFlagPrompt(false);
	Perks[index].AddFlag("90% Movement Speed", true);
	Perks[index].AddFlag("80% MovemSDKHook_WeaponCanUseent Speed", false);
	Perks[index].AddFlag("70% Movement Speed", false);
	Perks[index].AddFlag("50% Movement Speed", false);
	Perks[index].AddFlag("30% Movement Speed", false);
	Perks[index].AddFlag("0% Movement Speed", false);
	stickyGooIndex = index;
	index = SetupPerk("Vocalize Specials", "Spawn commons on special vocals", PerkMod_Constant);
	Perks[index].AddFlagPrompt(false);
	Perks[index].AddFlag("Mute Vocalization", true);
	Perks[index].AddFlag("Do not mute", false);
	index = SetupPerk("Instant Commons", "Spawns commons behind or infront", PerkMod_Instant | PerkMod_Constant);
	Perks[index].AddFlagPrompt(false);
	Perks[index].AddFlag("In Back", true);
	Perks[index].AddFlag("In Front", false);
	index = SetupPerk("Smart Charge", "Waits until coast is clear to charge", PerkMod_Constant);
	Perks[index].AddCustomFlagPrompt("Attempt Timeout", false);
	Perks[index].AddFlag("15 Seconds", true);
	Perks[index].AddFlag("30 Seconds", false);
	Perks[index].AddFlag("1 minute", false);
	Perks[index].AddFlag("5 minutes", false);

	// CATEGORY: Projectiles
	SetCategory("Projectiles");
	index = SetupPerk("Rock Dropper", "Drops on a rock. On their head.", PerkMod_Instant);
	// Perks[index].AddFlagPrompt(false);
	// Perks[index].AddFlag("Drop From Above", true);
	// Perks[index].AddFlag("From behind", false);
	index = SetupPerk("Car Splat", "Car. splats.", PerkMod_Instant);
	Perks[index].AddFlagPrompt(false);
	Perks[index].AddFlag("On Top", true);
	Perks[index].AddFlag("Into (Infront)", false);
	Perks[index].AddFlag("Into (Behind)", false);
	index = SetupPerk("Bad Throw", "Player drops throwables on throw, and biles/molotovs themselves", PerkMod_Constant);
	Perks[index].AddFlagPrompt(true);
	Perks[index].AddFlag("Biles", true);
	Perks[index].AddFlag("Molotovs", true);
	Perks[index].AddFlag("Pipebombs", true);
	SetupPerk("Molotov Bath", "Throws a molotov on their feet", PerkMod_Instant);

	// CATEGORY: Items
	SetCategory("Items");
	SetupPerk("Throw It All", "Player throws their item(s) periodically to a nearby player", PerkMod_Instant);
	index = SetupPerk("Spicy Gas", "Gascans player picks up just ignite. Magic.", PerkMod_Constant);
	Perks[index].AddFlagPrompt(false);
	Perks[index].AddFlag("Always (100%)", false);
	Perks[index].AddFlag("Half Time (50%)", true);
	Perks[index].AddFlag("Rare (10%)", false);
	index = SetupPerk("No Pickup", "Prevents a player from picking up ANY (new) item. Use ThrowItAll to make them drop", PerkMod_Constant);
	Perks[index].AddFlagPrompt(true);
	Perks[index].AddFlag("No Primary", false);
	Perks[index].AddFlag("No Melee", false);
	Perks[index].AddFlag("No Throwables", true);
	Perks[index].AddFlag("No Kits", true);
	Perks[index].AddFlag("No Pills / Adr", true);
	Perks[index].AddFlag("No GASCANS", true);
	index = SetupPerk("UziRules / AwpSmells", "Picking up a weapon gives them a UZI or AWP instead", PerkMod_Constant);
	Perks[index].AddFlagPrompt(false);
	Perks[index].AddFlag("UZI Only", true);
	Perks[index].AddFlag("AWP Only", false);
	SetupPerk("Primary Disable", "Player cannot pickup any weapons, only melee/pistols", PerkMod_Constant);
	index = SetupPerk("Dull Melee", "Player's melee weapon does 0 damage (based on %). Headshots still work", PerkMod_Constant);
	Perks[index].AddFlagPrompt(false);
	Perks[index].AddFlag("Always (100%)", false);
	Perks[index].AddFlag("Half Time (50%)", true);
	Perks[index].AddFlag("Rare (10%)", false);
	SetupPerk("Nerf Gun", "When they shoot it does no damage.", PerkMod_Constant);
	SetupPerk("Randomize Clip Ammo", "Randomly changes their clip ammo downwards", PerkMod_Constant | PerkMod_Instant);
	SetupPerk("CameTooEarly", "When they shoot, random chance they empty whole clip", PerkMod_Constant);


	/// CATEGORY: Chat
	SetCategory("Chat");
	SetupPerk("Typoos", "", PerkMod_Constant);
	SetupPerk("iCantSpellNoMore", "Chat messages letter will randomly changed with wrong letters", PerkMod_Constant);
	index = SetupPerk("No Profanity", "Replaces some words with random phrases", PerkMod_Constant);
	Perks[index].AddFlagPrompt(false);
	Perks[index].AddFlag("Only Replace Swears", false);
	Perks[index].AddFlag("Replace Full Messages", true);
	Perks[index].AddFlagPrompt(false);
	Perks[index].AddFlag("Show Modified to Them", true);
	Perks[index].AddFlag("Show Original to Them", false);
	index = SetupPerk("Vocalize Gag", "Prevents player from sending any vocalizations (even automatic)", PerkMod_Constant);
	// Perks[index].AddFlagPrompt(false);
	// Perks[index].AddFlag("Mute for All", true);
	// Perks[index].AddFlag("Mute For All But Them", false);
	index = SetupPerk("Honk / Meow / Woof", "Custom sounds", PerkMod_Constant);
	Perks[index].AddCustomFlagPrompt("Choose Sound:");
	Perks[index].AddFlag("Honk", true);
	Perks[index].AddFlag("Meow", false);
	Perks[index].AddFlag("Woof", false);
	Perks[index].AddCustomFlagPrompt("Choose Chat modifier:", false, 1);
	Perks[index].AddFlag("Show Modified to Them", true);
	Perks[index].AddFlag("Show Original to Them", false);
	Perks[index].AddFlag("Show Modified Only To Them", false);
	SetupPerk("Reversed", "Reserves their message", PerkMod_Constant);
	SetupPerk("Voice Mute", "Mutes from voice", PerkMod_Constant);
	SetupPerk("No Rushing Us", "Decreases player speed everytime they yell hurry up", PerkMod_Constant);

	/// CATEGORY: Health
	SetCategory("Health");
	SetupPerk("Damage Boost", "Makes a player take more damage than normal", PerkMod_Constant);
	SetupPerk("Temp Health Quick Drain", "Makes a player's temporarily health drain very quickly", PerkMod_Constant);
	SetupPerk("Slow Drain", "Will make the player slowly lose health over time", PerkMod_Constant);
	SetupPerk("KillMeSoftly", "Make player eat or waste pills whenever possible", PerkMod_Instant | PerkMod_Constant);
	index = SetupPerk("Reverse FF", "All damage dealt to a player is reversed", PerkMod_Constant);
	Perks[index].AddCustomFlagPrompt("Choose Reverse FF", false);
	Perks[index].AddFlag("1:1 Ratio", true); //1 
	Perks[index].AddFlag("2x Ratio", false); //2
	Perks[index].AddFlag("0.5x Ratio", false); //4
	Perks[index].AddFlag("0.0x Ratio (None)", false); //8
	Perks[index].AddFlag("3x Ratio", false); //16
	index = SetupPerk("Dep Bots", "Makes bots heal a player. At any cost", PerkMod_Constant);
	Perks[index].AddFlagPrompt(false);
	Perks[index].AddFlag("Do not spawn extra", true); // 1 
	Perks[index].AddFlag("Spawn extra bots (broke)", false); // 2
	Perks[index].AddCustomFlagPrompt("# Of Bots", false);
	Perks[index].AddFlag("1", false); // 4
	Perks[index].AddFlag("2", false); // 8
	Perks[index].AddFlag("3", false); // 16
	Perks[index].AddFlag("4", true); // 32
	Perks[index].AddFlag("5", false); // 64
	Perks[index].AddCustomFlagPrompt("Auto Timeout", false);
	Perks[index].AddFlag("Until Healed / Map Change", false); // 128
	Perks[index].AddFlag("15 seconds", true); // 255
	Perks[index].AddFlag("30 seconds", false); // 512
	Perks[index].AddFlag("1 minute", false); //1024
	Perks[index].AddFlag("5 minutes", false); //2048

	/// CATEGORY: Movement
	SetCategory("Movement");
	index = SetupPerk("Slow Speed", "Sets player speed to 0.8x of normal speed", PerkMod_Constant);
	Perks[index].AddFlagPrompt(false);
	Perks[index].AddFlag("90% Movement Speed", true);
	Perks[index].AddFlag("80% Movement Speed", false);
	Perks[index].AddFlag("70% Movement Speed", false);
	Perks[index].AddFlag("50% Movement Speed", false);
	Perks[index].AddFlag("30% Movement Speed", false);
	Perks[index].AddFlag("0% Movement Speed", false);
	SetupPerk("Higher Gravity", "Sets player gravity to 1.3x of normal gravity", PerkMod_Constant);
	invertedPerkIndex = SetupPerk("Inverted Controls", "Well, aint it obvious", PerkMod_Constant);
	SetupPerk("Stagger", "Like a slap, but different", PerkMod_Instant);
	index = SetupPerk("Slippery Shoes", "Periodically stumbles around.", PerkMod_Constant);
	Perks[index].AddFlagPrompt(true);
	Perks[index].AddFlag("Periodically", true);
	Perks[index].AddFlag("When using doors", false);
	Perks[index].AddFlag("On throwable use", false);
	Perks[index].AddFlag("On pills/adrenaline use", false);
	Perks[index].AddFlag("On zombie bite", false);
	slipperyShoesIndex = index;

	/// CATEGORY: MISC
	SetCategory("Misc");
	SetupPerk("Gun Jam", "On reload, small chance their gun gets jammed - Can't reload.", PerkMod_Constant);
	SetupPerk("No Shove", "Prevents a player from shoving", PerkMod_Constant);
	SetupPerk("No Button Touchie", "Stops people from pressing buttons", PerkMod_Constant);
	index = SetupPerk("Meta: Inverse", "Uhm you are not supposed to see this...", PerkMod_Instant);
	Perks[index].hidden = true;
	Perks[index].AddFlagPrompt(false);
	Perks[index].AddFlag("100%", true);
	Perks[index].AddFlag("50%", false);
	Perks[index].AddFlag("10%", false);

	

	// Initialize the default flag values to -1
	for(int i = 0; i <= MAX_PERKS; i++) {
		for(int j = 1; j <= MAXPLAYERS; j++) {
			Perks[i].activeFlagClients[j] = -1;
		}
	}

}

void AddMagnetFlags(int index) {
	Perks[index].AddCustomFlagPrompt("Choose Magnet Chance:", false);
	Perks[index].AddFlag("Always (100%)", true);
	Perks[index].AddFlag("Half Time (50%)", false);
	Perks[index].AddFlag("Rare (10%)", false);
}

bool ApplyAffect(int victim, const Perk perk, int activator, perkModifier modifier, int flags) {
	bool toActive = IsPerkActiveByRawID(victim, perk.id);
	if(StrEqual(perk.name, "Reset User")) {
		LogAction(activator, victim, "\"%L\" reset all effects for \"%L\"", activator, victim);
		ShowActivityEx(activator, "[FTT] ", "reset effects for %N. ", victim);
		for(int i = 0; i <= MAX_PERKS; i++) {
			Perks[i].activeFlagClients[victim] = -1;
		}
		SetEntityGravity(victim, 1.0);
		SetEntPropFloat(victim, Prop_Send, "m_flLaggedMovementValue", 1.0);
		return false;
	} else if(StrEqual(perk.name, "Slow Speed")) {
		if(toActive) {
			float movement = 0.0;
			if(flags & 1) movement = 0.9;
			else if(flags & 2) movement = 0.8;
			else if(flags & 4) movement = 0.7;
			else if(flags & 8) movement = 0.5;
			else if(flags & 16) movement = 0.3;
			SetEntPropFloat(victim, Prop_Send, "m_flLaggedMovementValue", movement);
		} else 
			SetEntPropFloat(victim, Prop_Send, "m_flLaggedMovementValue", 1.0);
	} else if(StrEqual(perk.name, "Higher Gravity"))
		SetEntityGravity(victim, toActive ? 1.3 : 1.0);
	else if(StrEqual(perk.name, "UziRules / AwpSmells")) {
		DisablePerk(victim, "No Pickup");
		DisablePerk(victim, "Primary Disable");
	} else if(StrEqual(perk.name, "Primary Disable")) {
		DisablePerk(victim, "UziRules / AwpSmells");
		DisablePerk(victim, "No Pickup");
		SDKHook(victim, SDKHook_WeaponCanUse, Event_ItemPickup);
	} else if(StrEqual(perk.name, "No Pickup")) {
		DisablePerk(victim, "UziRules / AwpSmells");
		DisablePerk(victim, "Primary Disable");
		SDKHook(victim, SDKHook_WeaponCanUse, Event_ItemPickup);
	} else if(StrEqual(perk.name, "CameTooEarly")) {
		ReplyToCommand(activator, "This perk mode is not implemented.");
	} else if(StrEqual(perk.name, "KillMeSoftly")) {
		static char wpn[32];
		GetClientWeaponName(victim, 4, wpn, sizeof(wpn));
		if(StrEqual(wpn, "weapon_adrenaline") || StrEqual(wpn, "weapon_pain_pills")) {
			ClientCommand(victim, "slot5");
			pdata[victim].flags |= view_as<int>(Flag_PendingItemGive);
		}else{
			ReplyToCommand(activator, "User does not have pills or adrenaline");
			return false;
		}
		//TODO: Implement PerkMod_Constant
		return false;
	} else if(StrEqual(perk.name, "Throw It All")) {
		if(modifier & PerkMod_Instant) {
			if(flags & 1) { // Hacky, just throw their kit
				ThrowItemToPlayer(victim, activator, 3);
			} else ThrowAllItems(victim);
		}
		if(hThrowTimer == INVALID_HANDLE && modifier & PerkMod_Constant) {
			hThrowTimer = CreateTimer(hThrowItemInterval.FloatValue, Timer_ThrowTimer, _, TIMER_REPEAT);
		}
	} else if(StrEqual(perk.name, "Swarm")) {
		if(modifier & PerkMod_Instant) {
			L4D2_RunScript("RushVictim(GetPlayerFromUserID(%d), %d)", victim, 15000);
		}
		return true;
	} else if(StrEqual(perk.name, "Gun Jam")) {
		int wpn = GetClientWeaponEntIndex(victim, 0);
		if(wpn > -1)
			SDKHook(wpn, SDKHook_Reload, Event_WeaponReload);
		else {
			ReplyToCommand(activator, "Victim does not have a primary weapon.");
			return false;
		}
	} else if(StrEqual(perk.name, "Vomit Player"))
		L4D_CTerrorPlayer_OnVomitedUpon(victim, victim);
	else if(StrEqual(perk.name, "Inface Special")) {
		ShowInstaSpecialChooser(activator, GetClientUserId(victim), 1);
		return false;
	} else if(StrEqual(perk.name, "Insta Special")) {
		ShowInstaSpecialChooser(activator, GetClientUserId(victim), 0);
		return false;
	} else if(StrEqual(perk.name, "Goo")) {
		static float pos[3], ang[3];
		GetClientAbsOrigin(victim, pos);
		GetClientAbsAngles(victim, ang);
		L4D2_SpitterPrj(victim, pos, ang);
	} else if(StrEqual(perk.name, "Stagger")) {
		L4D_StaggerPlayer(victim, victim, NULL_VECTOR);
	} else if(StrEqual(perk.name, "Voice Mute")) {
		BaseComm_SetClientMute(victim, toActive);
	} else if(StrEqual(perk.name, "Spicy Gas")) {
		SDKHook(victim, SDKHook_WeaponCanUse, Event_ItemPickup);
	} else if(StrEqual(perk.name, "Car Splat")) {
		if(flags & 1) {
			if(!SpawnCarOnPlayer(victim)) {
				ReplyToCommand(activator, "Could not find a suitable area to spawn a car. Requires vertical space above victim.");
				return false;
			}
		} else if(flags & 2) {
			if(!SpawnCarToPlayer(victim, 450.0)) {
				ReplyToCommand(activator, "Could not find a suitable area to spawn a car. Requires space ahead of victim");
				return false;
			}
		} else if(flags & 4) {
			if(!SpawnCarToPlayer(victim, -450.0)) {
				ReplyToCommand(activator, "Could not find a suitable area to spawn a car. Requires space behind victim");
				return false;
			}
		}
	} else if(StrEqual(perk.name, "Instant Commons")) {
		if(modifier & PerkMod_Instant) {
			float pos[3];
			GetHorizontalPositionFromClient(victim, flags & 1 ? -40.0 : 40.0, pos);
			int victimId = GetClientUserId(victim);
			for(int i = 0; i < 30; i++) {
				int c = L4D_SpawnCommonInfected(pos);
				L4D2_RunScript("CommandABot({cmd=0,bot=EntIndexToHScript(%i),target=GetPlayerFromUserID(%i)})", c, victimId);
			}
		}
	} else if(StrEqual(perk.name, "Randomize Clip Ammo")) {
		if(modifier & PerkMod_Instant) {
			int primaryWpn = GetPlayerWeaponSlot(victim, 0);
			if(primaryWpn > 0) {
				int maxCap = GetEntProp(primaryWpn, Prop_Send, "m_iClip1");
				SetEntProp(primaryWpn, Prop_Send, "m_iClip1", GetRandomInt(0, maxCap));
			}
		}
	} else if(StrEqual(perk.name, "Rock Dropper")) {
		float pos[3], dropPos[3];
		GetClientEyePosition(victim, pos);
		dropPos = pos;
		dropPos[2] += 150.0;
		TR_TraceRayFilter(pos, dropPos, MASK_SOLID, RayType_EndPoint, Filter_IgnorePlayer, victim);
		if(TR_DidHit()) {
			ReplyToCommand(activator, "Could not find a suitable area. Requires vertical space.");
			return false;
		}
		float ang[3];
		ang[0] = 90.0;
		L4D_TankRockPrj(0, dropPos, ang);
	} else if(StrEqual(perk.name, "Molotov Bath")) {
		float pos[3], dropPos[3];
		GetClientEyePosition(victim, pos);
		dropPos = pos;
		dropPos[2] += 20.0;
		TR_TraceRayFilter(pos, dropPos, MASK_SOLID, RayType_EndPoint, Filter_IgnorePlayer, victim);
		if(TR_DidHit()) {
			ReplyToCommand(activator, "Could not find a suitable area. Requires vertical space.");
			return false;
		}
		if(IsAnySurvivorInRange(pos, 55.0, victim)) {
			ReplyToCommand(activator, "Victim is too close to other players.");
			return false;
		}
		float vel[3];
		vel[2] = -90.0;
		L4D_MolotovPrj(victim, dropPos, vel);
	} else if(StrEqual(perk.name, "Dep Bots")) {
		if(!toActive) {
			StopHealingBots();
			return true;
		} else if(healTargetPlayer != 0) {
			if(IsValidHandle(stopHealingTimer)) {
				TriggerTimer(stopHealingTimer);
			}
			return true;
		}
		bool spawnExtra = flags & 2 > 0;

		int numBots = 4;
		if(flags & 4) numBots = 1;
		else if(flags & 8) numBots = 2;
		else if(flags & 16) numBots = 3;
		else if(flags & 64) numBots = 5;

		float timeout = 0.0;
		if(flags & 255) timeout = 15.0;
		else if(flags & 512) timeout = 30.0;
		else if(flags & 1024) timeout = 60.0;
		else if(flags & 2048) timeout = 300.0;

		// TODO: Extract this !!
		healTargetPlayer = GetClientUserId(victim);

		char buffer[32];
		for(int i = 1; i <= MaxClients; i++) {
			if(IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && IsFakeClient(i)) {
				int kit = GetPlayerWeaponSlot(i, 3);
				if(kit > 0) {
					GetEntityClassname(kit, buffer, sizeof(buffer));
					if(StrEqual(buffer, "weapon_first_aid_kit")) {
						PrintToServer("[FTT] Dep Bots: Found bot %N", i);
						pdata[i].flags |= view_as<int>(Flag_IsTargettingHealer);

						if(--numBots == 0) {
							break;
						}
					}
				}
			}
		}
		CreateTimer(2.0, Timer_UpdateHealTargetPos, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		if(timeout > 0.0) {
			DataPack pack;
			stopHealingTimer = CreateDataTimer(timeout, Timer_StopHealBots, pack);
			pack.WriteCell(GetClientUserId(activator));
			pack.WriteCell(GetClientUserId(victim))
		}

		if(spawnExtra && numBots > 0) {
			if(hAbmAutoHard != null) {
				wasAbmAutoHard = hAbmAutoHard.IntValue;
				hAbmAutoHard.IntValue = 0;
			}
			CreateTimer(0.2, Timer_SpawnHealBots, numBots, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
		}

		if(hSbFixEnabled != null) {
			wasSbFixEnabled = hSbFixEnabled.BoolValue;
			hSbFixEnabled.BoolValue = false;
		}
	} else if(StrEqual(perk.name, "Smart Charge")) {
		if(pdata[victim].smartChargeActivator > 0) {
			ReplyToCommand(activator, "Target already has smart charge enabled");
			return false;
		} 
		int timeout = 15;
		if(flags & 2) timeout = 30;
		else if(flags & 4) timeout = 60;
		else if(flags & 8) timeout = 300;
		pdata[victim].smartChargeAttempts = 0;
		pdata[victim].smartChargeMaxAttempts = timeout;
		pdata[victim].smartChargeActivator = GetClientUserId(activator);
		CreateTimer(1.0, Timer_CheckForChargerOpportunity, GetClientUserId(victim), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}  else if(StrEqual(perk.name, "No Rushing Us")) {
		SetEntPropFloat(victim, Prop_Send, "m_flLaggedMovementValue", 1.0);
	} else if(~modifier & PerkMod_Constant) {
		PrintToServer("[FTT] Warn: Possibly invalid perk, no apply action defined for \"%s\"", perk.name);
		#if defined DEBUG
		ReplyToCommand(activator, "[FTT/Debug] If nothing occurs, this perk possibly was not implemented correctly. ");
		#endif
	}  
	return true;
}

bool Filter_IgnorePlayer(int entity, int contentsMask, any data) {
	return entity != data;
}
