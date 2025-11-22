#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <rage/const>

// Stub out optional perk lookup used by PlayerInfo in rage/const.
stock bool FindPerk(const char[] perk, PerkData data)
{
#pragma unused perk, data
	return false;
}

public Plugin myinfo =
{
	name = "[Tests] Rage Classes",
	author = "Codex",
	description = "Sanity checks for Rage Survivor class metadata.",
	version = "1.0",
	url = "https://steamcommunity.com/groups/RageGaming"
};

bool g_bFailed;

void ExpectEqual(int actual, int expected, const char[] subject)
{
	if (actual == expected)
	{
		return;
	}

	LogError("[RageClassesTest] %s mismatch (expected %d, got %d)", subject, expected, actual);
	g_bFailed = true;
}

void ExpectTrue(bool expression, const char[] fmt, any ...)
{
	if (expression)
	{
		return;
	}

	char buffer[256];
	VFormat(buffer, sizeof(buffer), fmt, 2);
	LogError("[RageClassesTest] %s", buffer);
	g_bFailed = true;
}

void CheckMenuOptions()
{
	ExpectEqual(sizeof(MENU_OPTIONS), MAXCLASSES, "MENU_OPTIONS length");

	char entry[64];
	for (int i = 0; i < sizeof(MENU_OPTIONS); i++)
	{
		strcopy(entry, sizeof(entry), MENU_OPTIONS[i]);
		TrimString(entry);
		ExpectTrue(entry[0] != '\0', "MENU_OPTIONS[%d] should not be empty", i);
	}
}

void CheckClassTips()
{
	ExpectEqual(sizeof(ClassTips), MAXCLASSES, "ClassTips length");

	char entry[128];
	for (int i = 0; i < sizeof(ClassTips); i++)
	{
		strcopy(entry, sizeof(entry), ClassTips[i]);
		TrimString(entry);
		ExpectTrue(entry[0] == ',' || entry[0] == '.', "ClassTips[%d] should start with punctuation", i);
		ExpectTrue(strlen(entry) > 2, "ClassTips[%d] should describe a real bonus", i);
	}
}

void CheckClassModels()
{
	ExpectEqual(sizeof(ClassCustomModels), MAXCLASSES, "ClassCustomModels length");

	char entry[64];
	for (int i = 0; i < sizeof(ClassCustomModels); i++)
	{
		strcopy(entry, sizeof(entry), ClassCustomModels[i]);
		TrimString(entry);
		ExpectTrue(StrContains(entry, ".mdl", false) != -1, "ClassCustomModels[%d] must reference a model (.mdl)", i);
	}
}

void CheckSpecialReadyTips()
{
	ExpectEqual(sizeof(SpecialReadyTips), MAXCLASSES, "SpecialReadyTips length");

	char entry[64];
	for (int i = 0; i < sizeof(SpecialReadyTips); i++)
	{
		strcopy(entry, sizeof(entry), SpecialReadyTips[i]);
		TrimString(entry);
		ExpectTrue(entry[0] != '\0', "SpecialReadyTips[%d] must not be empty", i);
	}
}

public void OnPluginStart()
{
	CheckMenuOptions();
	CheckClassTips();
	CheckClassModels();
	CheckSpecialReadyTips();

	if (g_bFailed)
	{
		SetFailState("Rage class metadata validation failed. Check error log for specific mismatches.");
	}

	PrintToServer("[RageClassesTest] Class metadata validated for %d entries.", MAXCLASSES);
}
