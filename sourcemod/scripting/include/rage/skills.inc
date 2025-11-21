#if defined _RageSkills_included
#endinput
#endif
#define _RageSkills_included

#include <RageCore>

/**
 * Helpers for optional Rage Talents skill registration.
 */

stock void RageSkills_MarkNativesOptional()
{
    MarkNativeAsOptional("RegisterRageSkill");
    MarkNativeAsOptional("UnregisterRageSkill");
    MarkNativeAsOptional("Rage_OnPluginState");
    MarkNativeAsOptional("Rage_OnRoundState");
}

stock bool RageSkills_IsAvailable()
{
    return LibraryExists(RAGE_PLUGIN_NAME);
}

stock void RageSkills_Refresh(const char[] skillName, int skillType, int &skillId, bool &available)
{
    available = RageSkills_IsAvailable();
    if (available && skillId == -1)
    {
        skillId = RegisterRageSkill(skillName, skillType);
    }
}

stock void RageSkills_OnLibraryAdded(const char[] name, const char[] skillName, int skillType, int &skillId, bool &available)
{
    if (StrEqual(name, RAGE_PLUGIN_NAME, false))
    {
        available = true;
        if (skillId == -1)
        {
            skillId = RegisterRageSkill(skillName, skillType);
        }
    }
}

stock void RageSkills_OnLibraryRemoved(const char[] name, bool &available)
{
    if (StrEqual(name, RAGE_PLUGIN_NAME, false))
    {
        available = false;
    }
}
