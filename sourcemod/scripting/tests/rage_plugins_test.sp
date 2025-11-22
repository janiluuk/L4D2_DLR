#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <rage/const>

// Stub optional perk lookup referenced by rage/const PlayerInfo.
stock bool FindPerk(const char[] perk, PerkData data)
{
#pragma unused perk, data
	return false;
}

public Plugin myinfo =
{
	name = "[Tests] Rage Plugins",
	author = "Codex",
	description = "Ensures Rage skill plugins and enums stay in sync.",
	version = "1.0",
	url = "https://steamcommunity.com/groups/RageGaming"
};

bool g_bFailed;

static const char g_SpecialSkillNames[][] =
{
	"Airstrike",
	"Berzerk",
	"Grenades",
	"Multiturret"
};

static const SpecialSkill g_SpecialSkillOrder[] =
{
	view_as<SpecialSkill>(F18_airstrike),
	view_as<SpecialSkill>(Berzerk),
	view_as<SpecialSkill>(Grenade),
	view_as<SpecialSkill>(Multiturret)
};

static const char g_SkillPluginFiles[][] =
{
	"rage_survivor_plugin_airstrike.smx",
	"rage_survivor_plugin_berzerk.smx",
	"rage_survivor_plugin_grenades.smx",
	"rage_survivor_plugin_multiturret.smx"
};

void ExpectTrue(bool expression, const char[] fmt, any ...)
{
	if (expression)
	{
		return;
	}

	char buffer[256];
	VFormat(buffer, sizeof(buffer), fmt, 2);
	LogError("[RagePluginsTest] %s", buffer);
	g_bFailed = true;
}

void ExpectEqual(int actual, int expected, const char[] subject, const char[] name = "")
{
	if (actual == expected)
	{
		return;
	}

	if (name[0] != '\0')
	{
		LogError("[RagePluginsTest] %s mismatch for %s (expected %d, got %d)", subject, name, expected, actual);
	}
	else
	{
		LogError("[RagePluginsTest] %s mismatch (expected %d, got %d)", subject, expected, actual);
	}
	g_bFailed = true;
}

void CheckSpecialSkillEnumOrder()
{
	ExpectEqual(sizeof(g_SpecialSkillNames), sizeof(g_SpecialSkillOrder), "Test array size");
	ExpectEqual(sizeof(g_SpecialSkillNames), sizeof(g_SkillPluginFiles), "Plugin file list size");

	for (int i = 0; i < sizeof(g_SpecialSkillOrder); i++)
	{
		int expectedValue = i + 1; // skip No_Skill
		ExpectEqual(view_as<int>(g_SpecialSkillOrder[i]), expectedValue, "SpecialSkill enum order", g_SpecialSkillNames[i]);
	}

	ExpectEqual(sizeof(g_SpecialSkillNames), view_as<int>(Multiturret), "SpecialSkill::Multiturret value");
}

void CheckPluginArtifacts()
{
	char path[PLATFORM_MAX_PATH];
	for (int i = 0; i < sizeof(g_SkillPluginFiles); i++)
	{
		BuildPath(Path_SM, path, sizeof(path), "plugins/%s", g_SkillPluginFiles[i]);
		ExpectTrue(FileExists(path), "Missing compiled plugin: %s", path);
	}
}

public void OnPluginStart()
{
	CheckSpecialSkillEnumOrder();
	CheckPluginArtifacts();

	if (g_bFailed)
	{
		SetFailState("Rage plugin validation failed. Review the error log.");
	}

	PrintToServer("[RagePluginsTest] Verified %d plugin skill artifacts.", sizeof(g_SkillPluginFiles));
}
