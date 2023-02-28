public int Insta_PlayerHandler(Menu menu, MenuAction action, int client, int param2) {
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select) {
		static char info[16];
		menu.GetItem(param2, info, sizeof(info));

		static char str[2][8];
		ExplodeString(info, "|", str, 2, 8, false);

		int userid = StringToInt(str[0]);
		int instaMode = StringToInt(str[1]);
		ShowInstaSpecialChooser(client, userid, instaMode);
	} else if (action == MenuAction_End)
		delete menu;
	return 0;
}

void ShowInstaSpecialChooser(int activator, int userid, int instaMode) {
	Menu spMenu = new Menu(Insta_SpecialHandler);
	spMenu.SetTitle("Choose a Insta-Special™");
	static char data[16];
	for(int i = 1; i <= 8; i++) {
		Format(data, sizeof(data), "%d|%d|%d", userid, instaMode, i);
		spMenu.AddItem(data, SPECIAL_NAMES[i-1]);
	}
	spMenu.ExitButton = true;
	spMenu.Display(activator, 0);
}

public int Insta_SpecialHandler(Menu menu, MenuAction action, int client, int param2) {
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select) {
		static char info[16];
		menu.GetItem(param2, info, sizeof(info));
		static char str[3][8];
		ExplodeString(info, "|", str, 3, 8, false);
		int userid = StringToInt(str[0]);
		int target = GetClientOfUserId(userid);
		bool inFace = StrEqual(str[1], "1");
		int specialInt = StringToInt(str[2]);
		if(specialInt < 0 || specialInt > 8) {
			ReplyToCommand(client, "Invalid special id");
			return 0;
		}
		SpecialType special = view_as<SpecialType>(specialInt);
		if(inFace) {
			if(SpawnSpecialForTarget(special, target, view_as<int>(Special_OnTarget))) {
				LogAction(client, target, "\"%L\" spawned Insta-%s™ on \"%L\"", client, SPECIAL_NAMES[specialInt-1], target);
				ShowActivityEx(client, "[DLR] ", "spawned Insta-%s™ on %N", SPECIAL_NAMES[specialInt-1], target);
			} else {
				ReplyToCommand(client, "Could not spawn special.");
			}
		} else {
			if(SpawnSpecialForTarget(special, target)) {
				LogAction(client, target, "\"%L\" spawned Insta-%s™ near \"%L\"", client, SPECIAL_NAMES[specialInt-1], target);
				ShowActivityEx(client, "[DLR] ", "spawned Insta-%s™ near %N", SPECIAL_NAMES[specialInt-1], target);
			} else {
				ReplyToCommand(client, "Could not spawn special.");
			}
		}
		ShowInstaSpecialChooser(client, userid, inFace);
	} else if (action == MenuAction_End)
		delete menu;
	return 0;
}


public int ChooseMarkedPerk(Menu menu, MenuAction action, int activator, int param2) {
	if (action == MenuAction_Select) {
		static char info[16];
		menu.GetItem(param2, info, sizeof(info));
		int target = GetClientOfUserId(StringToInt(info));
		ToggleMarkPlayer(activator, target);
	} else if (action == MenuAction_End)
		delete menu;
	return 0;
}

public int ChoosePlayerHandler(Menu menu, MenuAction action, int param1, int param2) {
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select) {
		static char info[8];
		menu.GetItem(param2, info, sizeof(info));
		int userid = StringToInt(info);
		int victim = GetClientOfUserId(userid);

		if(victim == 0) {
			ReplyToCommand(param1, "[DLR] Could not acquire player");
			return 0;
		}
		
		SetupCategoryMenu(param1, userid);
	} else if (action == MenuAction_End)
		delete menu;
	return 0;
}

public int ChoosePlayerHandlerForCombos(Menu menu, MenuAction action, int client, int param2) {
	if (action == MenuAction_Select) {
		static char info[8];
		menu.GetItem(param2, info, sizeof(info));
		int userid = StringToInt(info);
		int victim = GetClientOfUserId(userid);

		if(victim == 0) {
			ReplyToCommand(victim, "[DLR] Could not acquire player");
			return 0;
		}
		
		ShowPerkCombosMenu(client, userid);
	} else if (action == MenuAction_End)
		delete menu;
	return 0;
}

public int ChooseComboHandler(Menu menu, MenuAction action, int client, int param2) {
	if (action == MenuAction_Select) {
		static char info[16];
		menu.GetItem(param2, info, sizeof(info));
		static char str[2][8];
		ExplodeString(info, "|", str, 2, 8, false);
		int userid = StringToInt(str[0]);
		int victim = GetClientOfUserId(userid);
		int comboID = StringToInt(str[1]);

		if(victim == 0) {
			ReplyToCommand(client, "[DLR] Could not acquire player");
			return 0;
		}
		
		static PerkCombo combo;
		combos.GetArray(comboID, combo, sizeof(combo));
		combo.Activate(client, victim);
	} else if (action == MenuAction_End)
		delete menu;
	return 0;
}

static int iMenuPlayerID[MAXPLAYERS+1];

public int ChooseCategoryHandler(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
		ShowPerkMenu(param1, false);
	else if (action == MenuAction_Select) {
		static char info[32];
		menu.GetItem(param2, info, sizeof(info));
		static char str[2][8];
		ExplodeString(info, "|", str, 2, 8, false);
		int userid = StringToInt(str[0]);
		int victim = GetClientOfUserId(userid);
		if(victim == 0) {
			ReplyToCommand(param1, "DLR/ChooseCategoryHandler: Could not acquire player");
			return 0;
		}
		
		iMenuPlayerID[param1] = userid;
		int category = StringToInt(str[1]);

		// Reset perk:
		if(category == -1) {
			ApplyPerk(GetClientOfUserId(userid), "Reset User", param1, PerkMod_Instant);
			return 0;
		}
		
		ShowPerksForCategory(param1, userid, category);
	} else if (action == MenuAction_End)
		delete menu;
	return 0;
}
public int ChooseClassHandler(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
		ShowPerkMenu(param1, false);
	else if (action == MenuAction_Select) {
		static char info[32];
		menu.GetItem(param2, info, sizeof(info));
		static char str[2][8];
		ExplodeString(info, "|", str, 2, 8, false);
		int userid = StringToInt(str[0]);
		int victim = GetClientOfUserId(userid);
		if(victim == 0) {
			ReplyToCommand(param1, "DLR/ChooseClassHandler: Could not acquire player");
			return 0;
		}
		
		iMenuPlayerID[param1] = userid;
		int class = StringToInt(str[1]);

		// Reset perk:
		if(class == -1) {
			ApplyPerk(GetClientOfUserId(userid), "Reset User", param1, PerkMod_Instant);
			return 0;
		}
		
		ShowPerksForClass(param1, userid, class);
	} else if (action == MenuAction_End)
		delete menu;
	return 0;
}

public int ChooseModeMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Cancel) {
		if(param2 == MenuCancel_ExitBack) {
			if(iMenuPlayerID[param1] == 0) {
				ReplyToCommand(param1, "DLR/ChooseModeMenuHandler: Could not acquire player");
			}
			SetupCategoryMenu(param1, iMenuPlayerID[param1]);
		}
	} else if (action == MenuAction_Select) {
		static char info[32];
		menu.GetItem(param2, info, sizeof(info));
		static char str[2][8];
		ExplodeString(info, "|", str, 2, 8, false);
		int userid = StringToInt(str[0]);
		int client = GetClientOfUserId(userid);
		if(client == 0) {
			ReplyToCommand(param1, "[DLR] Could not acquire player");
			return 0;
		}

		int keyIndex = StringToInt(str[1]);
		static Perk perk;
		GetPerkByKeyIndex(keyIndex, perk);
		//If perk has multiple flags, prompt:
		if(StrEqual(perk.name, "Throw It All")) {
			// Setup menu to call itself, but with an extra data point
			ShowThrowItAllMenu(param1, userid);
		} else if(!perk.IsActive(client) && perk.HasMod(PerkMod_Instant) && perk.HasMod(PerkMod_Constant)) {
			Menu modiferMenu = new Menu(ChoosePerkModiferHandler); 
			Format(info, sizeof(info), "%s: Choose Modifier", perk.name);
			modiferMenu.SetTitle(info);

			Format(info, sizeof(info), "%d|%d|1", userid, keyIndex);
			modiferMenu.AddItem(info, "Activate Once");
			Format(info, sizeof(info), "%d|%d|2", userid, keyIndex);
			modiferMenu.AddItem(info, "Activate Periodically");
			Format(info, sizeof(info), "%d|%d|3", userid, keyIndex);
			modiferMenu.AddItem(info, "Activate Periodically & Instantly");

			modiferMenu.ExitButton = true;
			modiferMenu.Display(param1, 0);
		} else if(perk.HasFlags() && !perk.IsActive(client)) {
 			ShowSelectFlagMenu(param1, userid, -1, perk);
		} else {
			perk.Activate(client, param1);
			ShowPerksForCategory(param1, userid, perk.categoryID);
		}
		
	} else if (action == MenuAction_End)
		delete menu;
	return 0;
}

public int ChooseClumsySlotHandler(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		static char info[8];
		menu.GetItem(param2, info, sizeof(info));
		static char str[2][8];
		ExplodeString(info, "|", str, 2, 8, false);
		int userid = StringToInt(str[0]);
		int client = GetClientOfUserId(userid);
		int slot = StringToInt(str[1]);
		if(client == 0) {
			ReplyToCommand(param1, "[DLR] Could not acquire player");
			return 0;
		}else if(slot == -1) {
			for(int i = 0; i <= 4; i++) {
				ThrowItemToPlayer(client, param1, i);
			}
		} else if(slot == -2) {
			ShowThrowItAllMenu(param1, userid);
		} else {
			ThrowItemToPlayer(client, param1, slot);
		}
		LogAction(param1, client, "\"%L\" activated perk \"Throw It all\" slot=%d for \"%L\"", param1, slot, client);
		ShowActivityEx(param1, "[DLR] ", "activated perk \"Throw It All\" for %N. ", client);

		ShowThrowItAllMenu(param1, userid);
	} else if (action == MenuAction_End)	
		delete menu;
	return 0;
}

public int ChoosePerkModiferHandler(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		static char info[16];
		menu.GetItem(param2, info, sizeof(info));
		static char str[3][8];
		ExplodeString(info, "|", str, 3, 8, false);
		int userid = StringToInt(str[0]);
		int client = GetClientOfUserId(userid);
		int keyIndex = StringToInt(str[1]);
		int modifiers = StringToInt(str[2]);

		if(client == 0) {
			ReplyToCommand(param1, "[DLR] Could not acquire player");
			return 0;
		}

		static Perk perk;
		GetPerkByKeyIndex(keyIndex, perk);

		if(!perk.IsActive(client) && perk.HasFlags()) {
			// Show flag selection if perk is not enabled already
 			ShowSelectFlagMenu(param1, userid, modifiers, perk);
		} else {
			if(modifiers == 1 || modifiers == 3)
				perk.Activate(client, param1, PerkMod_Instant);
			if(modifiers == 2 || modifiers == 3)
				perk.Activate(client, param1, PerkMod_Constant);	
			ShowPerksForCategory(param1, userid, perk.categoryID);
		}
		
	} else if (action == MenuAction_End)	
		delete menu;
	return 0;
}

public int ChoosePerkFlagHandler(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		static char info[32];
		menu.GetItem(param2, info, sizeof(info));
		static char str[6][8];
		ExplodeString(info, "|", str, 6, 8, false);
		int userid = StringToInt(str[0]);
		int client = GetClientOfUserId(userid);
		int keyIndex = StringToInt(str[1]);
		int modifiers = StringToInt(str[2]);
		int flags = StringToInt(str[3]);
		int index = StringToInt(str[4]);
		bool isDone = StringToInt(str[5]) == 1; // 0 = cont, 1 = done

		if(client == 0) {
			ReplyToCommand(param1, "[DLR] Could not acquire player");
			return 0;
		}

		static Perk perk;
		GetPerkByKeyIndex(keyIndex, perk);

		// If told to go to next prompt, find the next VALID prompt
		// Valid prompt is one where the required flags for it, are active

		if(isDone || index == -1) {
			int nextIndex = GetNextPrompt(perk, flags, index);
			// If there is a prompt available, show it, else fall down 
			if(nextIndex != -1) {
				ShowSelectFlagMenu(param1, userid, modifiers, perk, flags, nextIndex);
				return 0;
			}
			// else fall through & apply
		} else {
			ShowSelectFlagMenu(param1, userid, modifiers, perk, flags, index);
			return 0;
		}

		// Done with prompts, apply flags & modifiers
		if(modifiers > 0) {
			if(modifiers & view_as<int>(PerkMod_Instant))
				perk.Activate(client, param1, PerkMod_Instant, flags);
			if(modifiers & view_as<int>(PerkMod_Constant))
				perk.Activate(client, param1, PerkMod_Constant, flags);
		} else {
			perk.Activate(client, param1, PerkMod_Invalid, flags);
		}
		// Jump back to selection screen
		ShowPerksForCategory(param1, userid, perk.categoryID);
	} else if (action == MenuAction_End)	
		delete menu;
	return 0;	
}


public void StopItemGive(int client) {
	pdata[client].flags &= ~view_as<int>(Flag_PendingItemGive);
}

void SetupCategoryMenu(int client, int victimUserID) {
	iMenuPlayerID[client] = victimUserID;
	Menu categoryMenu = new Menu(ChooseCategoryHandler);
	static char category[64], id[16];
	// Title with [ in name cause failure
	Format(category, sizeof(category), "Choose perk category");
	categoryMenu.SetTitle(category);

	Format(id, sizeof(id), "%d|-1", victimUserID);
	categoryMenu.AddItem(id, "Reset User");
	for(int i = 0; i < categories.Length; i++) {
		categories.GetString(i, category, sizeof(category));
		Format(id, sizeof(id), "%d|%d", victimUserID, i);
		categoryMenu.AddItem(id, category);
	}
	categoryMenu.ExitButton = true;
	categoryMenu.ExitBackButton = true;
	categoryMenu.Display(client, 0);
}

void SetupClassMenu(int client, int playerUserID) {
	iMenuPlayerID[client] = playerUserID;
	Menu classMenu = new Menu(ChooseClassHandler);
	static char class[64], id[16];
	// Title with [ in name cause failure
	Format(class, sizeof(class), "Choose perk class");
	classMenu.SetTitle(class);

	Format(id, sizeof(id), "%d|-1", playerUserID);
	classMenu.AddItem(id, "Reset User");
	for(int i = 0; i < classes.Length; i++) {
		classes.GetString(i, class, sizeof(class));
		Format(id, sizeof(id), "%d|%d", playerUserID, i);
		classMenu.AddItem(id, class);
	}
	classMenu.ExitButton = true;
	classMenu.ExitBackButton = true;
	classMenu.Display(client, 0);
}

void ShowPerkCombosMenu(int client, int victimUserID) {
	Menu comboMenu = new Menu(ChooseComboHandler);
	static char id[32];
	Format(id, sizeof(id), "Choose perk combo");
	comboMenu.SetTitle(id);

	static PerkCombo combo;

	if(combos.Length == 0) {
		ReplyToCommand(client, "[DLR] No perk combos available");
		return;
	} 

	for(int i = 0; i < combos.Length; i++) {
		combos.GetArray(i, combo, sizeof(combo));
		Format(id, sizeof(id), "%d|%d", victimUserID, i);
		comboMenu.AddItem(id, combo.name);
	}

	comboMenu.ExitButton = true;
	comboMenu.ExitBackButton = true;
	comboMenu.Display(client, 0);
}

void ShowPerkMenu(int client, bool isComboList) {
	Menu menu = isComboList ? new Menu(ChoosePlayerHandlerForCombos) : new Menu(ChoosePlayerHandler);
	menu.SetTitle("Choose a player to perk");
	static char userid[8], display[64];
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2) {
			IntToString(GetClientUserId(i), userid, sizeof(userid));
			int specClient = GetSpectatorClient(i);
			// Incase player is idle, grab their bot instead of them
			if(specClient > 0) {
				if(IsPlayerAlive(specClient))
					Format(display, sizeof(display), "%N (AFK)", specClient);
				else
					Format(display, sizeof(display), "%N (AFK/Dead)", specClient);
			} else if(!IsPlayerAlive(i))
				Format(display, sizeof(display), "%N (Dead)", i);

			GetClientName(i, display, sizeof(display));
			menu.AddItem(userid, display);
		}
	}
	menu.ExitButton = true;
	menu.Display(client, 0);
}
void ShowPerksForClass(int client, int userid, int class) {
	static char info[32];
	Menu perkMenu = new Menu(ChooseModeMenuHandler);
	GetClass(class, info, sizeof(info));
	Format(info, sizeof(info), "Class: %s", info);
	perkMenu.SetTitle(info);
	
	static Perk perk;

	int victim = GetClientOfUserId(userid);

	// Add all menus that have same class to list
	static char name[MAX_PERK_NAME_LENGTH+8];
	for(int i = 0; i < perkKV.Size; i++) {
		GetPerkByKeyIndex(i, perk);
		// If perk is hidden and using normal menu, do not show
		if(perk.hidden && !SilentMenuSelected[client]) continue;
		if(perk.classID == class) {
			Format(info, sizeof(info), "%d|%d", userid, i);
			if(perk.IsActive(victim)) {
				Format(name, sizeof(name), "%s (Active)", perk.name);
				perkMenu.AddItem(info, name);
			} else
				perkMenu.AddItem(info, perk.name);
		}
	}
	perkMenu.ExitButton = true;
	perkMenu.ExitBackButton = true;
	perkMenu.Display(client, 0);
}


void ShowPerksForCategory(int client, int userid, int category) {
	static char info[32];
	Menu perkMenu = new Menu(ChooseModeMenuHandler);
	GetCategory(category, info, sizeof(info));
	Format(info, sizeof(info), "Category: %s", info);
	perkMenu.SetTitle(info);
	
	static Perk perk;

	int victim = GetClientOfUserId(userid);

	// Add all menus that have same category ID to list
	static char name[MAX_PERK_NAME_LENGTH+8];
	for(int i = 0; i < perkKV.Size; i++) {
		GetPerkByKeyIndex(i, perk);
		// If perk is hidden and using normal menu, do not show
		if(perk.hidden && !SilentMenuSelected[client]) continue;
		if(perk.categoryID == category) {
			Format(info, sizeof(info), "%d|%d", userid, i);
			if(perk.IsActive(victim)) {
				Format(name, sizeof(name), "%s (Active)", perk.name);
				perkMenu.AddItem(info, name);
			} else
				perkMenu.AddItem(info, perk.name);
		}
	}
	perkMenu.ExitButton = true;
	perkMenu.ExitBackButton = true;
	perkMenu.Display(client, 0);
}

// Called with defaults on start, then recalled by ChoosePerkFlagHandler until prompt selection finished
void ShowSelectFlagMenu(int activator, int victimUserID, int modifiers, Perk perk, int prevFlags = -1, int promptIndex = 0) {
	static char info[MAX_PERK_NAME_LENGTH+16]; //victimUSERID|perkID|modifiers|flags||flagIndex
	static char name[32];

	Menu flagMenu = new Menu(ChoosePerkFlagHandler);

	PerkFlagPrompt prompt;
	perk.GetFlagPrompt(promptIndex, prompt);
	prompt.GetPromptText(info, sizeof(info));

	Format(info, sizeof(info), "%s: %s", perk.name, info);
	flagMenu.SetTitle(info);

	if(prompt.multiselect) {
		if(prevFlags == -1) prevFlags = prompt.defaults;
		
		Format(info, sizeof(info), "%d|%d|%d|%d|%d|1", victimUserID, perk.id, modifiers, prevFlags, promptIndex);
		flagMenu.AddItem(info, "Apply / Next Prompt");

		for(int i = 0; i < perk.flagNames.Length; i++) {
			int a = 1 << i;
			if(prompt.flags & a) {
				perk.flagNames.GetString(i, name, sizeof(name));
				// If flag is enabled, show indication (On)
				if(prevFlags > 0 && prevFlags & a)
					Format(name, sizeof(name), "%s ✓", name);
				int newFlags = prevFlags ^ a; //Toggle the flag instead of setting like below, as it's toggleable here
				Format(info, sizeof(info), "%d|%d|%d|%d|%d|0", victimUserID, perk.id, modifiers, newFlags, promptIndex);
				flagMenu.AddItem(info, name);
			}
		}
	} else {
		// Single choice only
		if(prevFlags == -1) prevFlags = 0;
		for(int i = 0; i < perk.flagNames.Length; i++) {
			int a = 1 << i;
			if(prompt.flags & a) {
				perk.flagNames.GetString(i, name, sizeof(name));
				// Add (default) indicator

				if(prompt.defaults & a)
					Format(name, sizeof(name), "%s (default)", name);
				int newFlags = prevFlags | a; //Set flag with any from previous prompts
				Format(info, sizeof(info), "%d|%d|%d|%d|%d|1", victimUserID, perk.id, modifiers, newFlags, promptIndex);
				flagMenu.AddItem(info, name);
			}
		}
	}
	flagMenu.ExitButton = true;
	flagMenu.Display(activator, 0);
}

void ShowThrowItAllMenu(int client, int userid) {
	static char info[32];
	Menu itmMenu = new Menu(ChooseClumsySlotHandler); 
	itmMenu.SetTitle("Choose Item To Throw");

	static char itmName[32];
	Format(info, sizeof(info), "%d|-2", userid);
	itmMenu.AddItem(info, "Refresh");

	Format(info, sizeof(info), "%d|-1", userid);
	itmMenu.AddItem(info, "All Items");

	int victim = GetClientOfUserId(userid);
	if(victim == 0) {
		ReplyToCommand(client, "[DLR] Could not acquire player");
		return;
	}
	
	// Grab all the items the player has, add to menu
	for(int slot = 0; slot <= 5; slot++) {
		int item = GetPlayerWeaponSlot(victim, slot);
		if(item > -1) {
			GetEdictClassname(item, itmName, sizeof(itmName));
			Format(info, sizeof(info), "%d|%d", userid, slot);
			itmMenu.AddItem(info, itmName[7]);
		}
	}

	itmMenu.ExitButton = true;
	itmMenu.Display(client, 0);
}

int GetNextPrompt(Perk perk, int flags, int currentPrompt = 0) {
	static PerkFlagPrompt prompt;
	//If this prompt requires flags but they don't exist, skip to next that is valid or be done:
	if(currentPrompt + 1 == perk.flagPrompts.Length) return -1;
	for(int i = currentPrompt + 1; i < perk.flagPrompts.Length; i++) {
		perk.GetFlagPrompt(i, prompt);
		if(flags & prompt.requireFlags == prompt.requireFlags) {
			return i;
		}
	}
	// No suitable prompts found, mark it as done:
	return -1;
}