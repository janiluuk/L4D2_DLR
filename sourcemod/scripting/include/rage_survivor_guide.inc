#if defined _rage_survivor_guide_included
    #endinput
#endif
#define _rage_survivor_guide_included

/**
 * Opens the interactive Rage tutorial menu for the specified player.
 */
native void RageGuide_ShowMainMenu(int client);

public SharedPlugin __pl_rage_survivor_guide =
{
    name = "rage_survivor_guide",
    file = "rage_survivor_guide.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_rage_survivor_guide_SetNTVOptional()
{
    MarkNativeAsOptional("RageGuide_ShowMainMenu");
}
#endif
