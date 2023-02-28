public Action Command_InstaSpecial(int client, int args) {
	if(args < 1) {
		Menu menu = new Menu(Insta_PlayerHandler);
		menu.SetTitle("InstaSpecial: Choose a player");
		for(int i = 1; i < MaxClients; i++) {
			if(IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2) {
				static char userid[8], display[16];
				Format(userid, sizeof(userid), "%d|0", GetClientUserId(i));
				GetClientName(i, display, sizeof(display));
				menu.AddItem(userid, display);
			}
		}
		menu.ExitButton = true;
		menu.Display(client, 0);
	} else {
		char arg1[32], arg2[32] = "jockey";
		GetCmdArg(1, arg1, sizeof(arg1));
		if(args >= 2) {
			GetCmdArg(2, arg2, sizeof(arg2));
		}
		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;
		if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MaxClients,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0
		) {
			/* This function replies to the admin with a failure message */
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		SpecialType specialType = GetSpecialType(arg2);
		if(specialType == Special_Invalid) {
			ReplyToCommand(client, "Unknown special \"%s\"", arg2);
			return Plugin_Handled;
		}

		int successes = 0;
		for (int i = 0; i < target_count; i++) {
			int target = target_list[i];
			if(GetClientTeam(target) == 2) {
				if(SpawnSpecialForTarget(specialType, target)) {
					LogAction(client, target, "\"%L\" spawned Insta-%s™ nearby \"%L\"", client, arg2, target);
					successes++;
				} else {
					ReplyToCommand(client, "[DLR] Could not spawn %s near %s", arg2, target_name);
				}
			} else {
				ReplyToTargetError(client, target_count);
			}
		}
		if(successes > 0)
			ShowActivityEx(client, "[DLR] ", "spawned Insta-%s™ near %s", arg2, target_name);
	}


	return Plugin_Handled;
}

public Action Command_InstaSpecialFace(int client, int args) {
	if(args < 1) {
		Menu menu = new Menu(Insta_PlayerHandler);
		menu.SetTitle("Inface: Choose a player");
		for(int i = 1; i < MaxClients; i++) {
			if(IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2) {
				static char userid[8], display[16];
				Format(userid, sizeof(userid), "%d|1", GetClientUserId(i));
				GetClientName(i, display, sizeof(display));
				menu.AddItem(userid, display);
			}
		}
		menu.ExitButton = true;
		menu.Display(client, 0);
	} else {
		char arg1[32], arg2[32] = "jockey";
		GetCmdArg(1, arg1, sizeof(arg1));
		if(args >= 2) {
			GetCmdArg(2, arg2, sizeof(arg2));
		}
		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;
		if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MaxClients,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0
		) {
			/* This function replies to the admin with a failure message */
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		SpecialType specialType = GetSpecialType(arg2);
		if(specialType == Special_Invalid) {
			ReplyToCommand(client, "Unknown special \"%s\"", arg2);
			return Plugin_Handled;
		}

		int successes = 0;
		for (int i = 0; i < target_count; i++) {
			int target = target_list[i];
			if(GetClientTeam(target) == 2) {
				if(SpawnSpecialForTarget(specialType, target, view_as<int>(Special_OnTarget))) {
					LogAction(client, target, "\"%L\" spawned Insta-%s™ at player \"%L\"", client, arg2, target);
					successes++;
				} else {
					ReplyToCommand(client, "[DLR] Could not spawn %s on %s", arg2, target_name);
				}
			}else{
				ReplyToTargetError(client, target_count);
			}
		}
		if(successes > 0)
			ShowActivityEx(client, "[DLR] ", "spawned Insta-%s™ on %s", arg2, target_name);
	}
	return Plugin_Handled;
}


public Action Command_WitchAttack(int client, int args) {
	if(args < 1) {
		ReplyToCommand(client, "Usage: sm_witch_attack <user> [# of witches or 0 for all]");
	}else{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		char target_name[MAX_TARGET_LENGTH];
		int target_list[1], target_count;
		bool tn_is_ml;
		if ((target_count = ProcessTargetString(
				arg1,
				client,
				target_list,
				1,
				COMMAND_FILTER_ALIVE, /* Only allow alive players */
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			/* This function replies to the admin with a failure message */
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		int target = target_list[0];
		if(GetClientTeam(target) == 2) {
			GetCmdArg(2, arg1, sizeof(arg1));

			int maxCount = StringToInt(arg1);
			if(maxCount < 0) maxCount = 0;
			int count;

			int witch = INVALID_ENT_REFERENCE;
			while ((witch = FindEntityByClassname(witch, "witch")) != INVALID_ENT_REFERENCE) {
				if(SetWitchTarget(witch, target)) {
					++count;
				}
				if(maxCount > 0 && count >= maxCount) break;
			}
			ShowActivity(client, "set %d witches to target %s", count, target_name);
		}else{
			ReplyToTargetError(client, target_count);
		}
	}
	return Plugin_Handled;
}

public Action Command_CrescendoPerk(int client, int args) {
	if(lastCrescendoUser > -1) {
		ActivateAutoPunish(lastCrescendoUser);
		ReplyToCommand(client, "Activated auto punish on %N", lastCrescendoUser);
		LogAction(client, lastCrescendoUser, "\"%L\" autopunished crescendo rusher \"%L\"", client, lastCrescendoUser);
		ShowActivityEx(client, "[DLR] ", "activated autopunish for crescendo activator %N",lastCrescendoUser);
	}else{
		ReplyToCommand(client, "No player could be found to autopunish.");
	}
	return Plugin_Handled;
}

public Action Command_ResetUser(int client, int args) {
	if(args < 1) {
		ReplyToCommand(client, "Usage: sm_perkr <user(s)>");
	}else{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;
		if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_IMMUNITY, /* Only allow alive players */
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0
		) {
			/* This function replies to the admin with a failure message */
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		for (int i = 0; i < target_count; i++) {
			if(IsAnyPerkActive(target_list[i])) {
				LogAction(client, target_list[i], "\"%L\" reset all perk effects for \"%L\"", client, target_list[i]);
			}
			ResetClient(target_list[i], true);
		}
		ShowActivityEx(client, "[DLR] ", "reset perk effects for %s.",target_name);
	}
	return Plugin_Handled;
}

public Action Command_ApplyUser(int client, int args) {
	if(args < 1) {
		SilentMenuSelected[client] = false;
		ShowPerkMenu(client, false);
	}else{
		char arg1[32], arg2[16];
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		StringToLower(arg2);

		static char target_name[MAX_TARGET_LENGTH];
		int target_list[1], target_count;
		bool tn_is_ml;
		if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			1,
			COMMAND_FILTER_NO_MULTI | COMMAND_FILTER_NO_IMMUNITY, 
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0
		&& target_list[0] > 0) {
			/* This function replies to the admin with a failure message */
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		if(args == 2) {
			static char key[32];
			for(int i = 0; i < classes.Length; i++) {
				classes.GetString(i, key, sizeof(key));
				if(StrEqual(key, arg2, false)) {
					SilentMenuSelected[client] = false;
					ShowPerksForCategory(client, GetClientUserId(target_list[0]), i);
					return Plugin_Handled;
				}
			} 
			ReplyToCommand(client, "[DLR] Unknown class: '%s'", arg2);
		} else if(args == 1) {
			SetupClassMenu(client, GetClientUserId(target_list[0]));
		}
		
		SilentMenuSelected[client] = false;
		SetupClassMenu(client, GetClientUserId(target_list[0]));
	}
	return Plugin_Handled;
}

public Action Command_ApplyComboPerks(int client, int args) {
	if(args < 1) {
		ShowPerkMenu(client, true);
	}else{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));

		static char target_name[MAX_TARGET_LENGTH];
		int target_list[1], target_count;
		bool tn_is_ml;
		if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			1,
			COMMAND_FILTER_NO_MULTI, 
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0
		&& target_list[0] > 0) {
			/* This function replies to the admin with a failure message */
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		ShowPerkCombosMenu(client, GetClientUserId(target_list[0]));
	}
	return Plugin_Handled;	
}

public Action Command_ApplyUserSilent(int client, int args) {
	if(args < 1) {
		SilentMenuSelected[client] = true;
		ShowPerkMenu(client, false);
	}else{
		char arg1[32], arg2[16];
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		StringToLower(arg2);

		static char target_name[MAX_TARGET_LENGTH];
		int target_list[1], target_count;
		bool tn_is_ml;
		if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			1,
			COMMAND_FILTER_NO_MULTI, 
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0
		&& target_list[0] > 0) {
			/* This function replies to the admin with a failure message */
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		SilentMenuSelected[client] = true;
		if(args == 2) {
			static char key[32];
			for(int i = 0; i < classes.Length; i++) {
				classes.GetString(i, key, sizeof(key));
				if(StrEqual(key, arg2, false)) {
					ShowPerksForClass(client, GetClientUserId(target_list[0]), i);
					return Plugin_Handled;
				}
			} 
			ReplyToCommand(client, "[DLR] Unknown class: '%s'", arg2);
		}
		SetupClassMenu(client, GetClientUserId(target_list[0]));
	}
	return Plugin_Handled;
}

public Action Command_ListModes(int client, int args) {
	for(int i = 0; i <= MAX_PERKS; i++) {
		if(Perks[i].hidden) continue;
		ReplyToCommand(client, "%d. %s - %s", i, Perks[i].name, Perks[i].description);
	}
	return Plugin_Handled;
}

public Action Command_ListThePerks(int client, int args) {
	// View more info about a user
	if(args == 1) {
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));

		static char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;
		if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			0, 
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0
		|| target_list[0] == 0) {
			/* This function replies to the admin with a failure message */
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		for(int p = 0; p < target_count; p++) {
			int target = target_list[p];
			if(IsPlayerAlive(target))
				ReplyToCommand(client, "> Active Perks for %N:", target);
			else
				ReplyToCommand(client, "> Active Perks for %N:  (Paused)", target);

			if(IsFakeClient(target)) {
				int player = GetRealClient(target);
				if(player != -1) target = player;
			}

			for(int j = 1; j <= MAX_PERKS; j++) {
				if(Perks[j].hidden) continue;
				if(perkIds[j][0] != '\0' && IsPerkActive(target, perkIds[j])) {
					if(Perks[j].activeFlagClients[target] > 0) {
						static char list[MAX_PERK_FLAG_LENGTH*8]; //May in future need to up magic number 8 (supports 8 active flags )
						static char buffer[MAX_PERK_FLAG_LENGTH];
						for(int i = 0; i < Perks[j].flagNames.Length; i++) {
							int a = (1 << i);
							if(Perks[j].activeFlagClients[target] & a) {
								Perks[j].flagNames.GetString(i, buffer, sizeof(buffer));
								Format(list, sizeof(list), "%s%s;", list, buffer);
							} else {
								Perks[j].flagNames.GetString(i, buffer, sizeof(buffer));
							}
						}
						ReplyToCommand(client, "\"%s\" Flags: %s", perkIds[j], list);
					} else
						ReplyToCommand(client, perkIds[j]);
				}
			}
		}
		return Plugin_Handled;
	}

	int count = 0;
	char[][] modeListArr = new char[MAX_PERKS+1][MAX_PERK_NAME_LENGTH];
	static char modeList[255];
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) > 1 && IsAnyPerkActive(i)) {
			if(IsFakeClient(i)) {
				int player = GetRealClient(i);
				if(player != -1) i = player;
			}
			int modeCount = 0;
			for(int j = 1; j <= MAX_PERKS; j++) {
				if(perkIds[j][0] != '\0' && IsPerkActive(i, perkIds[j])) {
					if(Perks[j].activeFlagClients[i] > 0)
						Format(modeListArr[modeCount], MAX_PERK_NAME_LENGTH, "%s(%d)", perkIds[j], Perks[j].activeFlagClients[i]);
					else
						strcopy(modeListArr[modeCount], MAX_PERK_NAME_LENGTH, perkIds[j]);
					modeCount++;
				}
			}

			ImplodeStrings(modeListArr, modeCount, ", ", modeList, sizeof(modeList));
			if(IsPlayerAlive(i))
				ReplyToCommand(client, "%N | %s", i, modeList);
			else
				ReplyToCommand(client, "%N (Paused) | %s", i, modeList);
			count++;
		}
	}
	if(count == 0) {
		ReplyToCommand(client, "No clients have a mode applied.");
	}
	return Plugin_Handled;
}

public Action Command_MarkPendingPerk(int client, int args) {
	if(args == 0) {
		Menu menu = new Menu(ChooseMarkedPerk);
		menu.SetTitle("Choose a perk to mark");
		static char userid[8], display[16];
		for(int i = 1; i < MaxClients; i++) {
			if(IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i)) {
				if(GetUserAdmin(i) == INVALID_ADMIN_ID) {
					Format(userid, sizeof(userid), "%d", GetClientUserId(i));
					GetClientName(i, display, sizeof(display));
					menu.AddItem(userid, display);
				} else {
					ReplyToCommand(client, "%N is an admin cannot be marked.", i);
				}
			}
		}
		menu.ExitButton = true;
		menu.Display(client, 0);
	} else {
		static char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		char target_name[MAX_TARGET_LENGTH];
		int target_list[1], target_count;
		bool tn_is_ml;
		if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			1,
			COMMAND_FILTER_NO_MULTI , /* Only allow alive players */
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0
		) {
			/* This function replies to the admin with a failure message */
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		int target = target_list[0];
		if (GetClientTeam(target) == 2) {
			ToggleMarkPlayer(client, target);
		} else {
			ReplyToCommand(client, "Player does not exist or is not a survivor.");
		}
	}
	return Plugin_Handled;
}

public Action Command_PerkMenu(int client, int args) {
	ReplyToCommand(client, "sm_perksl [player(s)] - Lists all the active perks on players. Will show flag names if a player is specified.");
	ReplyToCommand(client, "sm_perksm - Lists all available perks & descriptions");
	ReplyToCommand(client, "sm_perksr <player(s)> - Resets target users' of any active perks");
	ReplyToCommand(client, "sm_perksa [player] [class] - Apply a perk on a player, with optional shortcut to player and/or class");
	ReplyToCommand(client, "sm_perks - Shows this text");
	ReplyToCommand(client, "sm_punish - Will apply a punishment to the last crescendo/event activator");
	ReplyToCommand(client, "sm_mark - Marks the user to be banned on disconnect, prevents their FF.");
	return Plugin_Handled;
}

public Action Command_BotsAttack(int client, int args) {
	if(args > 0) {
		static char arg1[32], arg2[4];
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));

		int targetHP;
		if(StringToIntEx(arg2, targetHP) == 0 || targetHP < 0 || targetHP > 100) {
			ReplyToCommand(client, "Invalid target HP value. Must be between 0 and 100");
			return Plugin_Handled;
		}

		int target_list[1], target_count;
		static char target_name[MAX_TARGET_LENGTH];
		bool tn_is_ml;
		if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			1,
			COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_MULTI,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0
		) {
			/* This function replies to the admin with a failure message */
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		int target = target_list[0];
		for(int i = 1; i <= MaxClients; i++) {
			if(IsClientConnected(i) && IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2) {
				if(!SetBotTarget(target, i, targetHP, 80)) {
					ReplyToCommand(client, "%N could not target %s", i, target_name);
				}
			}
		}
		ShowActivity(client, "set all bots to attack %s", target_name);
	} else {
		ReplyToCommand(client, "syntax: sm_bots_attack <target player> [target-hp]");
	}
	return Plugin_Handled;
}

public Action Command_Stagger(int client, int args) {
	if(args > 0) {
		static char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));

		int target_list[MAXPLAYERS], target_count;
		static char target_name[MAX_TARGET_LENGTH];
		bool tn_is_ml;
		if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MaxClients,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0
		) {
			/* This function replies to the admin with a failure message */
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		for(int i = 0; i < target_count; i++) {
			L4D_StaggerPlayer(target_list[i], target_list[i], NULL_VECTOR);
		}
	} else {
		ReplyToCommand(client, "syntax: sm_stagger <target player>");
	}
	return Plugin_Handled;
}

public Action Command_SmartCharge(int client, int args) {
	if(args > 0) {
		static char arg1[32], arg2[8];
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		int timeout = StringToInt(arg2);
		if(timeout == 0) timeout = 15;

		int target_list[1], target_count;
		static char target_name[MAX_TARGET_LENGTH];
		bool tn_is_ml;
		if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			1,
			COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_MULTI,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0
		) {
			/* This function replies to the admin with a failure message */
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		if(pdata[target_list[0]].smartChargeActivator > 0) {
			ReplyToCommand(client, "Target already has auto smart charge enabled");
		} else {
			pdata[target_list[0]].smartChargeAttempts = 0;
			pdata[target_list[0]].smartChargeMaxAttempts = timeout;
			pdata[target_list[0]].smartChargeActivator = GetClientUserId(client);
			CreateTimer(1.0, Timer_CheckForChargerOpportunity, GetClientUserId(target_list[0]), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			ShowActivity(client, "Enabling smart auto-charge on %N for %d seconds", target_list[0], timeout);
		}
	} else {
		ReplyToCommand(client, "syntax: sm_smartcharge <target player> [timeout or default 10s]");
	}
	return Plugin_Handled;
}

public Action Command_HealTarget(int client, int args) {
	if(args > 0) {
		char arg1[32], arg2[4];
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		int target_list[1], target_count;
		static char target_name[MAX_TARGET_LENGTH];
		bool tn_is_ml;
		if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			1,
			COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_MULTI | COMMAND_FILTER_NO_IMMUNITY,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0
		) {
			/* This function replies to the admin with a failure message */
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		int target = target_list[0];
		int targetUserId = GetClientUserId(target);
		if(targetUserId == healTargetPlayer) {
			ShowActivity(client, "cleared bots healing for %N", target);
			StopHealingBots();
		} else {
			healTargetPlayer = targetUserId;
			CreateTimer(2.0, Timer_UpdateHealTargetPos, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

			int limit = StringToInt(arg2);
			bool addBots = limit < 0;
			if(limit < 0) limit = -limit;
			else if(limit == 0) limit = MaxClients;
			for(int i = 1; i <= MaxClients; i++) {
				if(IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && IsFakeClient(i)) {
					int kit = GetPlayerWeaponSlot(i, 3);
					if(kit > 0) {
						GetEntityClassname(kit, arg1, sizeof(arg1));
						if(StrEqual(arg1, "weapon_first_aid_kit")) {
							pdata[i].flags |= view_as<int>(Flag_IsTargettingHealer);

							if(--limit == 0) {
								break;
							}
						}
					}
				}
			}
			if(addBots && limit > 0) {
				wasAbmAutoHard = hAbmAutoHard.IntValue;
				hAbmAutoHard.IntValue = 0;
				CreateTimer(0.2, Timer_SpawnHealBots, limit, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
			}
			ShowActivity(client, "made all bots heal %N", target);
			wasSbFixEnabled = hSbFixEnabled.BoolValue;
			hSbFixEnabled.BoolValue = false;
		}
	} else {
		ReplyToCommand(client, "Usage: /healbots <player> [# of bots or 0 for all]");
	}
	return Plugin_Handled;
}