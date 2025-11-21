#if defined _perk_included_
  #endinput
#endif
#define _perk_included_
 

enum PerkModifier {
    PerkMod_Invalid = 0,
	PerkMod_Instant = 1 << 0,
	PerkMod_Constant = 1 << 1,
    PerkMod_PlayerOnly = 1 << 2, // Does the perk only work on players, not bots? If set, troll only applied on real user. If not, perk applied to both bot and idler
}

native void ApplyPerk(int victim, const char[] name, PerkModifier modifier = PerkMod_Invalid, int flags, int activator, bool silent = false);

forward void OnPerkApplied(int victim, const char[] trollName, int flags = 0, int activator = 0); 

forward void OnPerkMarked(int activator, int victim); 
