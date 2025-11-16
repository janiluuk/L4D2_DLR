#define PLUGIN_VERSION "1.0"

#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name = "[DLR] Tutorial Guide",
    author = "Yani",
    description = "Interactive tutorial that explains DLR classes, skills and commands.",
    version = PLUGIN_VERSION,
    url = "https://steamcommunity.com/groups/DLRGaming"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_dlrtutorial", CmdGuideMenu, "Open the DLR tutorial guide");

    CreateNative("DLRGuide_ShowMainMenu", Native_ShowGuideMenu);
    RegPluginLibrary("dlr_talents_guide");
}

public int Native_ShowGuideMenu(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if (IsValidPlayer(client))
    {
        DisplayGuideMainMenu(client);
    }
    return 0;
}

public Action CmdGuideMenu(int client, int args)
{
    if (!IsValidPlayer(client))
    {
        PrintToServer("[DLR] This command can only be used in-game.");
        return Plugin_Handled;
    }

    DisplayGuideMainMenu(client);
    return Plugin_Handled;
}

bool IsValidPlayer(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

void PrintGuideLine(int client, const char[] message)
{
    PrintToChat(client, "\x04[DLR]\x01 %s", message);
}

void DisplayGuideMainMenu(int client)
{
    Menu menu = CreateMenu(MenuHandler_GuideMain);
    SetMenuTitle(menu, "DLR Tutorial Guide");
    AddMenuItem(menu, "overview", "What is DLR Rage Edition?");
    AddMenuItem(menu, "classes", "Survivor class guides");
    AddMenuItem(menu, "skills", "Special skills & commands");
    AddMenuItem(menu, "gamemodes", "Game modes overview");
    AddMenuItem(menu, "tips", "Gameplay tips");
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_GuideMain(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, param2, info, sizeof(info));
            if (StrEqual(info, "overview"))
            {
                PrintGuideLine(param1, "DLR Rage Edition is a modular class overhaul for Left 4 Dead 2 with perk-driven gameplay.");
                PrintGuideLine(param1, "Every survivor picks a class with unique passives plus a !skill ability, so coordinate before leaving the saferoom.");
                DisplayGuideMainMenu(param1);
            }
            else if (StrEqual(info, "classes"))
            {
                DisplayClassListMenu(param1);
            }
            else if (StrEqual(info, "skills"))
            {
                DisplaySkillMenu(param1);
            }
            else if (StrEqual(info, "gamemodes"))
            {
                DisplayGameModeMenu(param1);
            }
            else if (StrEqual(info, "tips"))
            {
                DisplayTipsMenu(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
    return 0;
}

void DisplayClassListMenu(int client)
{
    Menu menu = CreateMenu(MenuHandler_ClassList);
    SetMenuTitle(menu, "Survivor Classes");
    AddMenuItem(menu, "soldier", "Soldier");
    AddMenuItem(menu, "athlete", "Athlete");
    AddMenuItem(menu, "commando", "Commando");
    AddMenuItem(menu, "medic", "Medic");
    AddMenuItem(menu, "engineer", "Engineer");
    AddMenuItem(menu, "saboteur", "Saboteur");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_ClassList(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, param2, info, sizeof(info));
            if (StrEqual(info, "soldier"))
            {
                DisplaySoldierMenu(param1);
            }
            else if (StrEqual(info, "athlete"))
            {
                DisplayAthleteMenu(param1);
            }
            else if (StrEqual(info, "commando"))
            {
                DisplayCommandoMenu(param1);
            }
            else if (StrEqual(info, "medic"))
            {
                DisplayMedicMenu(param1);
            }
            else if (StrEqual(info, "engineer"))
            {
                DisplayEngineerMenu(param1);
            }
            else if (StrEqual(info, "saboteur"))
            {
                DisplaySaboteurMenu(param1);
            }
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayGuideMainMenu(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
    return 0;
}

void DisplaySoldierMenu(int client)
{
    Menu menu = CreateMenu(MenuHandler_Soldier);
    SetMenuTitle(menu, "Soldier Guide");
    AddMenuItem(menu, "overview", "Role overview");
    AddMenuItem(menu, "airstrike", "Airstrike skill");
    AddMenuItem(menu, "weapons", "Weapon handling");
    AddMenuItem(menu, "nightvision", "Night vision");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_Soldier(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, param2, info, sizeof(info));
            if (StrEqual(info, "overview"))
            {
                PrintGuideLine(param1, "Soldiers run faster, shrug off damage and excel as the frontline tank for the squad.");
                DisplaySoldierMenu(param1);
            }
            else if (StrEqual(info, "airstrike"))
            {
                PrintGuideLine(param1, "Aim at a target and press !skill to call in the F-18 missile barrage. Give teammates a warning before painting.");
                DisplaySoldierMenu(param1);
            }
            else if (StrEqual(info, "weapons"))
            {
                PrintGuideLine(param1, "Ninja-level melee swings and faster gun handling let you stagger commons with blades or rifles alike.");
                DisplaySoldierMenu(param1);
            }
            else if (StrEqual(info, "nightvision"))
            {
                PrintGuideLine(param1, "Toggle night vision with the N key (or bind sm_nightvision) to scout stormy maps and spot spawns.");
                DisplaySoldierMenu(param1);
            }
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayClassListMenu(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
    return 0;
}

void DisplayAthleteMenu(int client)
{
    Menu menu = CreateMenu(MenuHandler_Athlete);
    SetMenuTitle(menu, "Athlete Guide");
    AddMenuItem(menu, "mobility", "Mobility perks");
    AddMenuItem(menu, "parachute", "Parachute & jumps");
    AddMenuItem(menu, "ninja", "Ninja kick");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_Athlete(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, param2, info, sizeof(info));
            if (StrEqual(info, "mobility"))
            {
                PrintGuideLine(param1, "Athletes sprint faster and get mobility perks like bunnyhop, double jump, long jump and high jump.");
                DisplayAthleteMenu(param1);
            }
            else if (StrEqual(info, "parachute"))
            {
                PrintGuideLine(param1, "Hold USE in mid-air to pop the parachute and chain long jumps to reposition without fall damage.");
                DisplayAthleteMenu(param1);
            }
            else if (StrEqual(info, "ninja"))
            {
                PrintGuideLine(param1, "Leap into infected to deliver a ninja kick that knocks them down—great for peeling specials off teammates.");
                DisplayAthleteMenu(param1);
            }
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayClassListMenu(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
    return 0;
}

void DisplayCommandoMenu(int client)
{
    Menu menu = CreateMenu(MenuHandler_Commando);
    SetMenuTitle(menu, "Commando Guide");
    AddMenuItem(menu, "damage", "Damage tuning");
    AddMenuItem(menu, "berserk", "Berserk mode");
    AddMenuItem(menu, "reload", "Reload & finishers");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_Commando(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, param2, info, sizeof(info));
            if (StrEqual(info, "damage"))
            {
                PrintGuideLine(param1, "Commandos carry weapon-specific damage modifiers—swap to whatever gun the team needs and keep pressure on tanks.");
                DisplayCommandoMenu(param1);
            }
            else if (StrEqual(info, "berserk"))
            {
                PrintGuideLine(param1, "Build rage by dealing damage, then press !skill or !berserker to enter Berserk for huge speed and tank immunity.");
                DisplayCommandoMenu(param1);
            }
            else if (StrEqual(info, "reload"))
            {
                PrintGuideLine(param1, "You reload faster and can stomp downed infected. Sprint forward to execute specials before they recover.");
                DisplayCommandoMenu(param1);
            }
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayClassListMenu(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
    return 0;
}

void DisplayMedicMenu(int client)
{
    Menu menu = CreateMenu(MenuHandler_Medic);
    SetMenuTitle(menu, "Medic Guide");
    AddMenuItem(menu, "aura", "Healing aura");
    AddMenuItem(menu, "orbs", "Healing orbs & drops");
    AddMenuItem(menu, "support", "Revive & cleanse");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_Medic(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, param2, info, sizeof(info));
            if (StrEqual(info, "aura"))
            {
                PrintGuideLine(param1, "Medics pulse heals to nearby survivors and get movement boosts while healing—stay near the front line.");
                DisplayMedicMenu(param1);
            }
            else if (StrEqual(info, "orbs"))
            {
                PrintGuideLine(param1, "Press !skill to toss healing orbs that glow and ping the team. You can also drop med items for others.");
                DisplayMedicMenu(param1);
            }
            else if (StrEqual(info, "support"))
            {
                PrintGuideLine(param1, "Faster revive and heal speeds plus the !unvomit cleanse make you the antidote to bile or chip damage.");
                DisplayMedicMenu(param1);
            }
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayClassListMenu(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
    return 0;
}

void DisplayEngineerMenu(int client)
{
    Menu menu = CreateMenu(MenuHandler_Engineer);
    SetMenuTitle(menu, "Engineer Guide");
    AddMenuItem(menu, "kits", "Upgrade kits");
    AddMenuItem(menu, "turrets", "Turret workshop");
    AddMenuItem(menu, "defense", "Defensive tools");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_Engineer(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, param2, info, sizeof(info));
            if (StrEqual(info, "kits"))
            {
                PrintGuideLine(param1, "Engineers spawn ready-to-use upgrade packs for ammo, armor or barricades—drop them between events.");
                DisplayEngineerMenu(param1);
            }
            else if (StrEqual(info, "turrets"))
            {
                PrintGuideLine(param1, "Use !skill to open the turret menu, pick a gun and ammo, left-click to deploy and press USE to pick it up.");
                DisplayEngineerMenu(param1);
            }
            else if (StrEqual(info, "defense"))
            {
                PrintGuideLine(param1, "Deploy shields, laser grids and barricades. Turrets are non-blocking but can be detonated if infected overrun them.");
                DisplayEngineerMenu(param1);
            }
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayClassListMenu(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
    return 0;
}

void DisplaySaboteurMenu(int client)
{
    Menu menu = CreateMenu(MenuHandler_Saboteur);
    SetMenuTitle(menu, "Saboteur Guide");
    AddMenuItem(menu, "stealth", "Cloak & stealth");
    AddMenuItem(menu, "sight", "Extended sight");
    AddMenuItem(menu, "mines", "Mines & gadgets");
    AddMenuItem(menu, "damage", "Damage profile");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_Saboteur(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, param2, info, sizeof(info));
            if (StrEqual(info, "stealth"))
            {
                PrintGuideLine(param1, "Use the Dead Ringer !skill (aliases !fd or !cloak) to vanish, drop a fake corpse and sprint past ambushes.");
                DisplaySaboteurMenu(param1);
            }
            else if (StrEqual(info, "sight"))
            {
                PrintGuideLine(param1, "!extendedsight highlights special infected for 20 seconds every two minutes—call targets for your team.");
                DisplaySaboteurMenu(param1);
            }
            else if (StrEqual(info, "mines"))
            {
                PrintGuideLine(param1, "Hold SHIFT to plant up to twenty mine types ranging from freeze traps to airstrikes. Mines glow to warn teammates.");
                DisplaySaboteurMenu(param1);
            }
            else if (StrEqual(info, "damage"))
            {
                PrintGuideLine(param1, "Saboteurs trade lower survivor damage for higher infected damage—use your gadgets to set up assassinations.");
                DisplaySaboteurMenu(param1);
            }
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayClassListMenu(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
    return 0;
}

void DisplaySkillMenu(int client)
{
    Menu menu = CreateMenu(MenuHandler_Skills);
    SetMenuTitle(menu, "Special Skills & Commands");
    AddMenuItem(menu, "skill", "Class skill command");
    AddMenuItem(menu, "grenades", "Prototype grenades");
    AddMenuItem(menu, "deadringer", "Dead Ringer");
    AddMenuItem(menu, "sight", "Extended sight");
    AddMenuItem(menu, "multiturret", "Multiturret controls");
    AddMenuItem(menu, "music", "Music player");
    AddMenuItem(menu, "unvomit", "Unvomit cleanse");
    AddMenuItem(menu, "berserk", "Berserk reminders");
    AddMenuItem(menu, "airstrike", "Airstrike reminders");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_Skills(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, param2, info, sizeof(info));
            if (StrEqual(info, "skill"))
            {
                PrintGuideLine(param1, "Bind a key to !skill (or type the command) to trigger your class ability consistently every round.");
            }
            else if (StrEqual(info, "grenades"))
            {
                PrintGuideLine(param1, "Equip any grenade, hold FIRE and tap SHOVE (or use sm_grenade) to cycle through experimental prototypes.");
            }
            else if (StrEqual(info, "deadringer"))
            {
                PrintGuideLine(param1, "Saboteurs can type !fd or !cloak to drop a fake corpse, gain invisibility and reset aggro.");
            }
            else if (StrEqual(info, "sight"))
            {
                PrintGuideLine(param1, "!extendedsight paints special infected through walls for 20 seconds with a two-minute cooldown.");
            }
            else if (StrEqual(info, "multiturret"))
            {
                PrintGuideLine(param1, "Engineers open the turret picker with !skill, choose turret + ammo, left-click to place and USE to pick up.");
            }
            else if (StrEqual(info, "music"))
            {
                PrintGuideLine(param1, "Type !music to opt into custom tracks, adjust volume or disable songs per map.");
            }
            else if (StrEqual(info, "unvomit"))
            {
                PrintGuideLine(param1, "Medics can cleanse Boomer bile with !unvomit to keep survivors firing.");
            }
            else if (StrEqual(info, "berserk"))
            {
                PrintGuideLine(param1, "Commandos hit !berserker or !skill once rage is full. Berserk grants burst damage and immunity to tank knockdowns.");
            }
            else if (StrEqual(info, "airstrike"))
            {
                PrintGuideLine(param1, "Soldiers aim and press !skill to mark a strike zone; warn teammates before raining missiles.");
            }
            DisplaySkillMenu(param1);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayGuideMainMenu(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
    return 0;
}

void DisplayGameModeMenu(int client)
{
    Menu menu = CreateMenu(MenuHandler_GameModes);
    SetMenuTitle(menu, "Game Modes");
    AddMenuItem(menu, "versus", "Versus variants");
    AddMenuItem(menu, "objective", "Objective modes");
    AddMenuItem(menu, "dlr", "DLR customs");
    AddMenuItem(menu, "switch", "How to switch modes");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_GameModes(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, param2, info, sizeof(info));
            if (StrEqual(info, "versus"))
            {
                PrintGuideLine(param1, "Versus, Team Versus and Competitive variants keep the classic flow with extra perks and balance tweaks.");
            }
            else if (StrEqual(info, "objective"))
            {
                PrintGuideLine(param1, "Scavenge, Team Scavenge, Survival, Co-op and Realism are all playable through the game menu.");
            }
            else if (StrEqual(info, "dlr"))
            {
                PrintGuideLine(param1, "Escort Run, Deathmatch and Race Jockey are custom DLR chaos modes—experiment when you want a break from Versus.");
            }
            else if (StrEqual(info, "switch"))
            {
                PrintGuideLine(param1, "Admins open !dlr then pick \"Vote for gamemode\" to swap modes and can return to Versus at any time.");
            }
            DisplayGameModeMenu(param1);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayGuideMainMenu(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
    return 0;
}

void DisplayTipsMenu(int client)
{
    Menu menu = CreateMenu(MenuHandler_Tips);
    SetMenuTitle(menu, "Gameplay Tips");
    AddMenuItem(menu, "team", "Team composition");
    AddMenuItem(menu, "resources", "Resource flow");
    AddMenuItem(menu, "hud", "HUD & music");
    AddMenuItem(menu, "shortcuts", "Command shortcuts");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_Tips(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, param2, info, sizeof(info));
            if (StrEqual(info, "team"))
            {
                PrintGuideLine(param1, "Mix roles—Soldier tanks, Medic heals, Engineer builds cover, Saboteur scouts and Athlete runs objectives.");
            }
            else if (StrEqual(info, "resources"))
            {
                PrintGuideLine(param1, "Medics drop orbs, Engineers deploy kits and Saboteurs plant mines. Communicate so nothing goes to waste.");
            }
            else if (StrEqual(info, "hud"))
            {
                PrintGuideLine(param1, "Toggle the HUD or music player from the admin menu to match your focus for each round.");
            }
            else if (StrEqual(info, "shortcuts"))
            {
                PrintGuideLine(param1, "Bind !skill, !music, !unvomit, !extendedsight and !dlrtutorial for instant access mid-fight.");
            }
            DisplayTipsMenu(param1);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayGuideMainMenu(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
    return 0;
}
