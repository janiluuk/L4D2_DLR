#if defined _dlr_talents_guide_included
    #endinput
#endif
#define _dlr_talents_guide_included

/**
 * Opens the interactive DLR tutorial menu for the specified player.
 */
native void DLRGuide_ShowMainMenu(int client);

public SharedPlugin __pl_dlr_talents_guide =
{
    name = "dlr_talents_guide",
    file = "dlr_talents_guide.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_dlr_talents_guide_SetNTVOptional()
{
    MarkNativeAsOptional("DLRGuide_ShowMainMenu");
}
#endif
