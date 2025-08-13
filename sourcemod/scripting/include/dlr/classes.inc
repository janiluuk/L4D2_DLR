#define MAX_SKILL_NAME_LENGTH 32
#define MAX_SKILL_FLAG_LENGTH 32
//Allow MAX_PERKS to be defined elsewhere
#if defined MAX_SKILLS
#else
    #define MAX_SKILLS 49
#endif

Skill Skills[MAX_PERKS+1];

ArrayList classes;
ArrayList categories;
static int categoryID = -1;
static int classID  = -1;

enum skillModifier {
    SkillMod_Invalid = 0,
	SkillMod_Instant = 1 << 0,
	SkillMod_Constant = 1 << 1,
    SkillMod_PlayerOnly = 1 << 2, // Does the perk only work on players, not bots? If set, perk only applied on real user. If not, perk applied to both bot and idler
}

enum skillFlag {
    Flag_1 = 1 << 0,
    Flag_2 = 1 << 1,
    Flag_3 = 1 << 2,
    Flag_4 = 1 << 3,
    Flag_5 = 1 << 4,
    Flag_6 = 1 << 5,
    Flag_7 = 1 << 6,
    Flag_8 = 1 << 7,
}

StringMap skillKV;

int SetupSkill(const char[] name, const char description[128], int mods) {
    static int i = 0;
    if(mods == 0) {
        ThrowError("Skill \"%s\" has no modifiers defined.", name);
        return -1;
    } else if(i == MAX_PERKS + 1) {
        ThrowError("Maximum number of skills (%d) reached. Up MAX_SKILLS value.", MAX_PERKS);
        return -1;
    }
    g_skillAddPromptIndex = 0;
    Skills[i].id = i;
    strcopy(Skills[i].name, MAX_SKILL_NAME_LENGTH, name);
    strcopy(Skills[i].description, 128, description);
    Skills[i].pluginID = 0; 
    Skills[i].categoryID = categoryID;
    Skills[i].classID = classID;    
    Skills[i].mods = mods;
    Skills[i].flagPrompts = new ArrayList(sizeof(SkillFlagPrompt));

    strcopy(skillIds[i], MAX_SKILL_NAME_LENGTH, name); 
    skillKV.SetValue(name, i);
    return i++;
}

public void SetClass(const char[] newClass) {
    classID = classes.FindString(newSkill);
    if(classID == -1)
        classID = classes.PushString(newClass);
}
void GetClass(int class, char[] buffer, int size) {
    classes.GetString(class, buffer, size);
} 

// Gets the Perk enum struct via name
// Returns index of perk enum
int GetSkill(const char[] name, Skill skill) {
    static int i = 0;
    if(skillKV.GetValue(name, i)) {
        skill = Skills[i];
        return i;
    }
    ThrowError("GetSkill: Skill was not found \"%s\"", name);
    return -1;
}

int GetSkillID(const char[] name) {
    static int i = 0;
    if(skillKV.GetValue(name, i)) {
        return i;
    }
    PrintToServer("GetSkillID: Skill was not found \"%s\"", name);
    return -1;
}

void GetSkillByKeyIndex(int index, Skill skill) {
    skill = Skills[index];
}

void ToggleSkill(int client, const char[] name, int flags = 0) {
    static Skill skill;
    GetSkill(name, skill);
    if(skill.IsActive(client))
        skill.activeFlagClients[client] = -1;
    else
        skill.activeFlagClients[client] = flags;
}

void SetSkillFlags(int client, const char[] name, int flags = -1) {
    int index = GetSkillID(name);
    Skills[index].activeFlagClients[client] = flags;
}

void EnableSkill(int client, const char[] skill, int flags = 0) {
    SetSkillFlags(client, skill, flags);
}

void DisablePerk(int client, const char[] perk) {
    SetSkillFlags(client, skill, -1);
}


void ApplySkill(int player, const char[] name, int activator, perkModifier modifier, int flags = 0, bool silent = false) {
}


enum struct Skill {
    int id;
    int categoryID;
    int pluginID;

    char name[MAX_SKILL_NAME_LENGTH];
    char description[128];
    bool hidden;

    int mods;

    // Flags
    int activeFlagClients[MAXPLAYERS+1];
    char flagPrompt[MAX_SKILL_FLAG_LENGTH];
    ArrayList flagNames;
    ArrayList flagPrompts;

    bool HasMod(skillModifier mod) {
        return ((this.mods >> (view_as<int>(mod)) - 1) & 1) == 1;
    }

    // Gets the default modifier to use
    perkModifier GetDefaultMod() {
        // If the flags is equal to the 2^n flag, then it must be the only flag:
        if(this.mods == view_as<int>(SkillMod_Instant)) return SkillMod_Instant;
        else if(this.mods == view_as<int>(SkillMod_Constant)) return SkillMod_Constant;
        else return SkillMod_Invalid;
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
        SkillFlagPrompt prompt;
        prompt.multiselect = multiselect;
        prompt.requireFlags = requireFlags;
        strcopy(prompt.promptText, MAX_SKILL_FLAG_LENGTH, promptText);
        int index = this.flagPrompts.PushArray(prompt);
        g_skillAddPromptIndex = index;
        return index;
    }

    int AddFlagPrompt(bool multiselect = false, int requireFlags = 0) {
        //g_perkAddPromptIndex
        PerkFlagPrompt prompt;
        prompt.multiselect = multiselect;
        prompt.requireFlags = requireFlags;
        int index = this.flagPrompts.PushArray(prompt);
        g_skillAddPromptIndex = index;
        return index;
    }

    int AddFlag(const char[] name, bool defaultOn) {
        if(this.flagNames == null) this.flagNames = new ArrayList(MAX_SKILL_FLAG_LENGTH);

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
        this.flagPrompts.SetArray(g_skillAddPromptIndex, prompt); //May not be required
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
            if(StrEqual(buffer, flagName, false)) return this.IsFlagActive(client, view_as<skillFlag>(i));
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
        if(modifier == SkillMod_Invalid) modifier = this.GetDefaultMod();
        // Sadly, unable to pass in <this> to ApplyPerk, so it has to do unnecessary lookup via string
        ApplySkill(client, this.name, activator, modifier, flags, silent);
    }

    void Toggle(int client, int flags) {
        ToggleSkill(client, this.name, flags);
    }

    void Enable(int client, int flags) {
        EnableSkill(client, this.name, flags);
    }

    void Disable(int client) {
        DisableSkill(client, this.name);
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

enum struct SkillFlagPrompt {
    char promptText[MAX_SKILL_FLAG_LENGTH];
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

