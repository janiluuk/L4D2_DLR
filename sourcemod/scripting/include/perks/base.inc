
#define MAX_PERK_NAME_LENGTH 32
#define MAX_PERK_FLAG_LENGTH 32
//Allow MAX_PERKS to be defined elsewhere
#if defined MAX_PERKS
#else
    #define MAX_PERKS 49
#endif

enum perkModifier {
    PerkMod_Invalid = 0,
	PerkMod_Instant = 1 << 0,
	PerkMod_Constant = 1 << 1,
    PerkMod_PlayerOnly = 1 << 2, // Does the perk only work on players, not bots? If set, perk only applied on real user. If not, perk applied to both bot and idler
}

//up to 30 flags technically possiible
enum perkFlag {
    Flag_1 = 1 << 0,
    Flag_2 = 1 << 1,
    Flag_3 = 1 << 2,
    Flag_4 = 1 << 3,
    Flag_5 = 1 << 4,
    Flag_6 = 1 << 5,
    Flag_7 = 1 << 6,
    Flag_8 = 1 << 7,
}

StringMap perkKV;
char perkIds[MAX_PERKS+1][MAX_PERK_NAME_LENGTH];
char DEFAULT_FLAG_PROMPT_MULTIPLE[] = "Enable options (Multiple)";
char DEFAULT_FLAG_PROMPT[] = "Select an option";
bool SilentMenuSelected[MAXPLAYERS+1];

static int g_perkAddPromptIndex;
ArrayList gRandomClients;

char SPECIAL_NAMES[][] = {
	"Smoker", "Boomer", "Hunter", "Spitter", "Jockey", "Charger", "Witch", "Tank"
};

enum struct PerkFlagPrompt {
    char promptText[MAX_PERK_FLAG_LENGTH];
    int flags;
    int defaults;
    bool multiselect;
    int requireFlags;

    void GetPromptText(char[] prompt, int maxlength) {
        if(this.promptText[0] != '\0') {
            strcopy(prompt, maxlength, this.promptText);
        } else if(this.multiselect) {
            strcopy(prompt, maxlength, DEFAULT_FLAG_PROMPT_MULTIPLE);
        } else {
            strcopy(prompt, maxlength, DEFAULT_FLAG_PROMPT);
        }
    }
}

int GetIndexFromPower(int powerOfTwo) {
    for(int i = 0; i < 16; i++) {
        if(1 << i == powerOfTwo) {
            return i;
        }
    }
    return -1;
}

enum struct Perk {
    int id;
    int categoryID;
    int classID;
    int pluginID;

    char name[MAX_PERK_NAME_LENGTH];
    char description[128];
    bool hidden;

    int mods;

    // Flags
    int activeFlagClients[MAXPLAYERS+1];
    char flagPrompt[MAX_PERK_FLAG_LENGTH];
    ArrayList flagNames;
    ArrayList flagPrompts;

    bool HasMod(perkModifier mod) {
        return ((this.mods >> (view_as<int>(mod)) - 1) & 1) == 1;
    }

    // Gets the default modifier to use
    perkModifier GetDefaultMod() {
        // If the flags is equal to the 2^n flag, then it must be the only flag:
        if(this.mods == view_as<int>(PerkMod_Instant)) return PerkMod_Instant;
        else if(this.mods == view_as<int>(PerkMod_Constant)) return PerkMod_Constant;
        else return PerkMod_Invalid;
    }

    // Gets the default modifier to use
    char[] GetPlugin() {
        char plugin[32];
        return plugin;
    }

    bool GetFlagName(int index, char[] buffer, int maxlength) {
        if(this.flagNames == null) return false;
        this.flagNames.GetString(index, buffer, maxlength);
        return true;
    }

    int AddCustomFlagPrompt(const char[] promptText, bool multiselect = false, int requireFlags = 0) {
        PerkFlagPrompt prompt;
        prompt.multiselect = multiselect;
        prompt.requireFlags = requireFlags;
        strcopy(prompt.promptText, MAX_PERK_FLAG_LENGTH, promptText);
        int index = this.flagPrompts.PushArray(prompt);
        g_perkAddPromptIndex = index;
        return index;
    }

    int AddFlagPrompt(bool multiselect = false, int requireFlags = 0) {
        //g_perkAddPromptIndex
        PerkFlagPrompt prompt;
        prompt.multiselect = multiselect;
        prompt.requireFlags = requireFlags;
        int index = this.flagPrompts.PushArray(prompt);
        g_perkAddPromptIndex = index;
        return index;
    }

    int AddFlag(const char[] name, bool defaultOn) {
        if(this.flagNames == null) this.flagNames = new ArrayList(MAX_PERK_FLAG_LENGTH);

        // Check if flag already added
        int flagIndex = this.GetFlagIndex(name);
        if(flagIndex == -1) flagIndex = this.flagNames.PushString(name);
        
        // Grab the prompt
        static PerkFlagPrompt prompt;
        this.flagPrompts.GetArray(g_perkAddPromptIndex, prompt);

        prompt.flags |= (1 << flagIndex);

        if(defaultOn) {
            // If out of bounds, set to default -1 -> pick global prompt
            if(this.flagPrompts.Length == 0) {
                ThrowError("Perk \"%s\" does not have any flag prompts, thus a default value cannot be set. (flag=\"%s\")", this.name, name);
                return -1;
            }
            if(!prompt.multiselect && prompt.defaults > 0) {
                ThrowError("Flag \"%s\" cannot be set as default flag in single select mode, as one has already been set for prompt %d", name, g_perkAddPromptIndex);
                return -1;
            }
            prompt.defaults |= (1 << flagIndex);
        }
        this.flagPrompts.SetArray(g_perkAddPromptIndex, prompt); //May not be required
        return flagIndex;
    }

    int GetFlagIndex(const char[] flagName) {
        static char comprFlag[MAX_PERK_FLAG_LENGTH]; 
        for(int i = 0; i < this.flagNames.Length; i++) {
            this.flagNames.GetString(i, comprFlag, sizeof(comprFlag));
            if(StrEqual(comprFlag, flagName)) {
                return i;
            }
        }
        return -1;
    }

    bool HasFlags() {
        return this.flagNames != null && this.flagNames.Length > 0 && this.flagPrompts.Length > 0;
    }

    bool IsFlagActive(int client, perkFlag flag) {
        return this.activeFlagClients[client] & view_as<int>(flag) != 0;
    }

    bool IsFlagNameActive(int client, const char[] flagName) {
        static char buffer[MAX_PERK_FLAG_LENGTH];
        for(int i = 0; i < this.flagNames.Length; i++) {
            this.flagNames.GetString(i, buffer, sizeof(buffer));
            if(StrEqual(buffer, flagName, false)) return this.IsFlagActive(client, view_as<perkFlag>(i));
        }
        return false;
    }

    int GetClientFlags(int client) {
        return this.activeFlagClients[client];
    }

    void SetFlagPrompt(const char[] prompt) {
        strcopy(this.flagPrompt, MAX_PERK_FLAG_LENGTH, prompt);
    }

    void GetFlagPrompt(int index, PerkFlagPrompt prompt) {
        this.flagPrompts.GetArray(index, prompt);
    }

/////// PERK ACTIVATION

    void Activate(int client, int activator, perkModifier modifier = PerkMod_Invalid, int flags = 0, bool silent = false) {
        if(modifier == PerkMod_Invalid) modifier = this.GetDefaultMod();
        // Sadly, unable to pass in <this> to ApplyPerk, so it has to do unnecessary lookup via string
        ApplyPerk(client, this.name, activator, modifier, flags, silent);
    }


    void Toggle(int client, int flags) {
        TogglePerk(client, this.name, flags);
    }

    void Enable(int client, int flags) {
        EnablePerk(client, this.name, flags);
    }

    void Disable(int client) {
        DisablePerk(client, this.name);
    }

    bool IsActive(int client) {
        return this.activeFlagClients[client] != -1;
    }

    int GetRandomClient(int start = 0) {
        gRandomClients.Clear();
        for(int i = start + 1; i <= MaxClients; i++) {
            if(this.activeFlagClients[i] != -1) {
                gRandomClients.Push(i);
            }
        }
        if(gRandomClients.Length == 0) return -1;
        return GetRandomInt(0, gRandomClients.Length);
    }
}

Perk Perks[MAX_PERKS+1];

ArrayList classes;
ArrayList categories;
static int categoryID = -1;
static int classID  = -1;

void ResetClient(int player, bool wipe = true) {
    if(player == 0 || !IsClientConnected(player)) return;
    if(wipe) {
        for(int i = 0; i <= MAX_PERKS; i++) {
            Perks[i].activeFlagClients[player] = -1;
        }
    }
    BaseComm_SetClientMute(player, false);
    SetEntityGravity(player, 1.0);
    SetEntPropFloat(player, Prop_Send, "m_flLaggedMovementValue", 1.0);
    SDKUnhook(player, SDKHook_WeaponCanUse, Event_ItemPickup);
    int wpn = GetClientWeaponEntIndex(player, 0);
    if(wpn > -1)
        SDKUnhook(wpn, SDKHook_Reload, Event_WeaponReload);
}

int SetupPerk(const char[] name, const char description[128], int mods) {
    static int i = 0;
    if(mods == 0) {
        ThrowError("Perk \"%s\" has no modifiers defined.", name);
        return -1;
    } else if(i == MAX_PERKS + 1) {
        ThrowError("Maximum number of perks (%d) reached. Up MAX_PERKS value.", MAX_PERKS);
        return -1;
    }
    g_perkAddPromptIndex = 0;
    Perks[i].id = i;
    strcopy(Perks[i].name, MAX_PERK_NAME_LENGTH, name);
    strcopy(Perks[i].description, 128, description);
    Perks[i].pluginID = 0; 
    Perks[i].categoryID = categoryID;
    Perks[i].classID = classID;    
    Perks[i].mods = mods;
    Perks[i].flagPrompts = new ArrayList(sizeof(PerkFlagPrompt));

    strcopy(perkIds[i], MAX_PERK_NAME_LENGTH, name); 
    perkKV.SetValue(name, i);
    return i++;
}

// Gets the Perk enum struct via name
// Returns index of perk enum
int GetPerk(const char[] name, Perk perk) {
    static int i = 0;
    if(perkKV.GetValue(name, i)) {
        perk = Perks[i];
        return i;
    }
    ThrowError("GetPerk: Perk was not found \"%s\"", name);
    return -1;
}
int GetPerkID(const char[] name) {
    static int i = 0;
    if(perkKV.GetValue(name, i)) {
        return i;
    }
    PrintToServer("GetPerkID: Perk was not found \"%s\"", name);
    return -1;
}

bool IsAnyPerkActive(int player) {
    for(int i = 0; i <= MAX_PERKS; i++) {
        if(Perks[i].activeFlagClients[player] >= 0) return true;
    }
    return false;
}
// Gets the Perk enum struct via key index
// Returns index of perk enum
void GetPerkByKeyIndex(int index, Perk perk) {
    perk = Perks[index];
}

void TogglePerk(int client, const char[] name, int flags = 0) {
    static Perk perk;
    GetPerk(name, perk);
    if(perk.IsActive(client))
        perk.activeFlagClients[client] = -1;
    else
        perk.activeFlagClients[client] = flags;
}

void SetPerkFlags(int client, const char[] name, int flags = -1) {
    int index = GetPerkID(name);
    Perks[index].activeFlagClients[client] = flags;
}

void ApplyPerk(int player, const char[] name, int activator, perkModifier modifier, int flags = 0, bool silent = false) {
    static Perk perk;
    int perkIndex = GetPerk(name, perk);
    if(perkIndex == -1) {
        ReplyToCommand(activator, "Unknown perk \"%s\"", name);
        PrintToServer("[Rage] %N attempted to apply unknown perk: %s", activator, name);
        return;
    }

    if(!silent && SilentMenuSelected[activator]) silent = true;

    static int MetaInversePerkID;
    if(!MetaInversePerkID) MetaInversePerkID = GetPerkID("Meta: Inverse");

    if(activator > 0 && Perks[MetaInversePerkID].IsActive(activator)) {
        float max = 1.0;
        if(Perks[MetaInversePerkID].activeFlagClients[activator] & 2) max = 0.5;
        else if(Perks[MetaInversePerkID].activeFlagClients[activator] & 4) max = 0.1;
        if(GetRandomFloat() <= max) {
            player = activator;
        }
    }

    // If player is a survivor bot, check if has an idle player
    if(IsFakeClient(player) && GetClientTeam(player) == 2) {
        int player = GetSpectatorClient(player);
        if(player > 0) {
            // If there is an idle player, apply perk to them
            ApplyPerk(player, name, activator, modifier, flags, silent);
            // And continue IF there is PerkMod_PlayerOnly mod
            if(perk.mods & view_as<int>(PerkMod_PlayerOnly)) return;
            // Don't want to show two logs, so just ignore the bot
            silent = true;
        }
    }

    bool isActive = Perks[perkIndex].activeFlagClients[player] > -1;

    // Toggle on flags for client, if it's not a single run.
    if(modifier & PerkMod_Constant) {
        Perks[perkIndex].activeFlagClients[player] = isActive ? -1 : flags;
    }

    // Applies any custom logic needed for a perk, mostly only used for PerkMod_Instant
    if(!ApplyAffect(player, perk, activator, modifier, flags)) {
        return;
    }

    // Log all actions, indicating if constant or single-fire, and if any flags
    if(!silent) {
        if(isActive) {
            CShowActivityEx(activator, "[Rage] ", "deactivated {yellow}\"%s\"{default} on %N. ", perk.name, player);
            LogAction(activator, player, "\"%L\" deactivated {yellow}\"%s\"{default} on \"%L\"", activator, perk.name, player);
        } else {
            static char flagName[MAX_PERK_FLAG_LENGTH];
            // strcopy(flagName, sizeof(flagName), perk.name)
            // Call_StartForward(g_PerkAppliedForward);
            // Call_PushCell(player);
            // Call_PushString(flagName);
            // Call_PushCell(flags);
            // Call_PushCell(activator);
            // Call_Finish();
            flagName[0] = '\0';
            for(int i = 0; i < 32; i++) {
                if(flags & (1 << i)) {
                    // If at least one flag already, reset to none:
                    if(flagName[0] != '\0') {
                        flagName[0] = '\0';
                        break;
                    }
                    perk.GetFlagName(i, flagName, sizeof(flagName));
                }
            }
            if(flags > 0 && flags & flags - 1 == 0 && flags & flags + 1 == 0) {
                // Get the flag name if there is only one flag set
                perk.GetFlagName(GetIndexFromPower(flags), flagName, sizeof(flagName));
            }
            if(modifier & PerkMod_Constant) {
                if(flags > 0) {
                    if(flagName[0] != '\0') {
                        CShowActivityEx(activator, "[Rage] ", "activated constant {yellow}%s{default} ({yellow}%s{default}) for %N. ", perk.name, flagName, player);
                    } else {
                        CShowActivityEx(activator, "[Rage] ", "activated constant {yellow}%s{default} ({yellow}%d{default}) for %N. ", perk.name, flags, player);
                    }
                } else
                    CShowActivityEx(activator, "[Rage] ", "activated constant {yellow}%s{default} for %N. ", perk.name, player);
            } else if(flags > 0) {
                if(flagName[0] != '\0') {
				    CShowActivityEx(activator, "[Rage] ", "activated {yellow}%s{default} ({yellow}%s{default}) for %N. ", perk.name, flagName, player);
                } else {
				    CShowActivityEx(activator, "[Rage] ", "activated {yellow}%s{default} ({yellow}%d{default}) for %N. ", perk.name, flags, player);
                }
            } else
				CShowActivityEx(activator, "[Rage] ", "activated {yellow}%s{default} for %N. ", perk.name, player);
            
            LogAction(activator, player, "\"%L\" activated \"%s\" (%d) for \"%L\"", activator, perk.name, flags, player);
        }
    } else {
        CReplyToCommand(activator, "ftt: Applied {yellow}\"%s\"{default} on %N with flags=%d", perk.name, player, flags);
    }
}

bool IsPerkActive(int client, const char[] perk) {
    if(perk[0] == '\0') {
        ThrowError("Perk name is empty");
        return false;
    }
    static int i = 0;
    if(perkKV.GetValue(perk, i)) {
        return Perks[i].activeFlagClients[client] != -1;
    }
    ThrowError("Perk \"%s\" does not exist", perk);
    return false; //errors instead but compiler no like
}

bool IsPerkActiveByRawID(int client, int id) {
    return Perks[id].activeFlagClients[client] != -1;
}

void EnablePerk(int client, const char[] perk, int flags = 0) {
    SetPerkFlags(client, perk, flags);
}

void DisablePerk(int client, const char[] perk) {
    SetPerkFlags(client, perk, -1);
}
public void SetClass(const char[] newClass) {
    classID = classes.FindString(newClass);
    if(classID == -1)
        classID = classes.PushString(newClass);
}
void GetClass(int class, char[] buffer, int size) {
    classes.GetString(class, buffer, size);
} 

public void SetCategory(const char[] newCat) {
    categoryID = categories.FindString(newCat);
    if(categoryID == -1)
        categoryID = categories.PushString(newCat);
}
void GetCategory(int category, char[] buffer, int size) {
    categories.GetString(category, buffer, size);
} 


public int Native_ApplyPerk(Handle plugin, int numParams) {
    int player = GetNativeCell(1);
    char name[MAX_PERK_NAME_LENGTH];
    GetNativeString(2, name, sizeof(name));
    perkModifier modifier = view_as<perkModifier>(GetNativeCell(3));
    if(view_as<int>(modifier) < 0) {
        ThrowNativeError(SP_ERROR_NATIVE, "Provided modifier is invalid (out of range)");
    }
    int flags = GetNativeCell(4);
    int activator = GetNativeCell(5);

    int index = GetPerkID(name);
    if(index > 0) {
        Perks[index].Activate(player, activator, modifier, flags, GetNativeCell(7));
    } else {
        ThrowNativeError(SP_ERROR_NATIVE, "Could not find perk with name \"%s\"", name);
    }
    return 0;
}
 