/** CLASS SYSTEM **/

StringMap g_AllPerks, g_SlotPerks;
ArrayList g_SlotIndexes;
GlobalForward g_fwPerkName, g_fwPerkDescription, g_fwCanAccessPerk, g_fwSlotName, g_fwPerkPre, g_fwPerkPost;

enum struct playerClassProperties {
    float maxHealth;
    float jumpVelocity;
    float attackDamage;
    float attackRate;
    float armorRate;
    float healingRate;
    float tankStumbleBlock;
}

enum struct playerClass {
        int perkId;
        char className[32];
        char classDescription[32];
    playerClassProperties properties;
}

enum struct skillAction {
        int client;
        int actionId;
        // 1 = Execute standard OnSpecialSkillUsed hooks
        // 2 = use OnCustomCommand hook
        // 3 = execute on startup
        int actionType;
        char pluginName[64];
        char parameter[3];
        char bindToKey[2];
        int interval;
        float lastUsed;
        bool runInStartup;
        char successText[128];
        char failureText[128];
        char announceText[128];
}

enum struct skillSet {
        int skillSetId;
        char skillSetName[32];
        char skillSetDescription[128];
        char skillISetdentifier[32];
        int maxPlayers;
        int     skillSetType;
        char menuIdentifier[16];
        int actions[16];
}

enum ClassTypes {
        NONE=0,
        soldier,
        athlete,
        medic,
        saboteur,
        commando,
        engineer,
        brawler,
        MAXCLASSES
};

enum SpecialSkill {
        No_Skill = 0,
        F18_airstrike,
        Berzerk,
        Grenade,
        Multiturret
}

enum SkillType {
        On_Demand = 0,
        Perk,
        Constant
}

enum struct PerkData
{
        int slot;
        char parameter[3];
        int maxLevel;
}

enum PerkPerm
{
        NO_ACCESS = 0,
        CAN_VIEW = (1 << 0),
        CAN_USE = (1 << 2),
        FULL = (1 << 3)
}

enum struct PlayerInfo
{
        int SpecialsUsed;
        float HideStartTime;
        float HealStartTime;
        int LastButtons;
        ClassTypes ChosenClass;
        float LastDropTime;
        int SpecialDropInterval;
        int SpecialLimit;
        SpecialSkill SpecialSkill;
        char EquippedGun[64];
        StringMap perks;

        int GetPerk(const char[] name)
        {
                int result = 0;
                if(!this.perks.GetValue(name, result))
                        return 0;

                return result;
        }

        bool SetPerk(const char[] name, int value)
        {
                PerkData data;
                if(!FindPerk(name, data))
                        return false;

                if(value < 0)
                        value = 0;

                if(value == 0)
                        this.perks.Remove(name);
                else
                        this.perks.SetValue(name, value);

                return true;
        }
}

PlayerInfo ClientData[MAXPLAYERS+1];

enum Water_Level
{
        WATER_LEVEL_NOT_IN_WATER = 0,
        WATER_LEVEL_FEET_IN_WATER,
        WATER_LEVEL_WAIST_IN_WATER,
        WATER_LEVEL_HEAD_IN_WATER
};

stock const String:MENU_OPTIONS[][] =
{
        "None",
        "Soldier",
        "Athlete",
        "Medic",
        "Saboteur",
        "Commando",
        "Engineer",
        "Brawler"
};

stock const String:ClassCustomModels[][64] =
{
        "models/infected/common_male_suit.mdl",
        "models/infected/common_male_fallen_survivor.mdl",
        "models/infected/common_female_tshirt_skirt_swamp.mdl",
        "models/infected/common_male_roadcrew_rain.mdl",
        "models/infected/common_male_suit.mdl",
        "models/infected/common_male_riot.mdl",
        "models/npcs/rescue_pilot_01.mdl",
        "models/infected/common_military_male01.mdl"
};

stock String:ClassTips[][] =
{
        ", He can't do shit.",
        ", He has high attack melee & shoot rate, takes less damage and moves faster. Speciality: Airstrike",
        ", He can Jump high, Speciality: Anti-gravity grenades",
        ", He can heal nearby players, revive others faster, drop supplies. Speciality: Healing orbs.",
        ", He can go invisible, drop variety of mines. Speciality: Cloak",
        ", He has increased damage, fast reload and immune to Tank knockdowns! Speciality: Berzerk mode",
        ", He can drop auto turrets and ammo supplies. Speciality: Protective shield",
        ", He has lots of health."
};

stock String:SpecialReadyTips[][] =
{
        "No go",
        "Airstrike is ready!",
        "Anti-Gravity grenade is ready!",
        "You can deploy and throw healing grenades again",
        "You can plant mines or use cloak again",
        "Berzerk mode is ready!",
        "You can deploy or throw armoring grenades again",
        ""
};

enum BombType {
        Bomb = 0,
        Cluster,
        Firework,
        Smoke,
        BlackHole,
        Flashbang,
        Shield,
        Tesla,
        Chemical,
        Freeze,
        Medic,
        Vaporizer,
        Extinguisher,
        Glowing,
        AntiGravity,
        FireCluster,
        Bullets,
        Flak,
  Airstrike,
  Weapon
};

#define BOMB_NAME_LENGTH 32

enum struct Mine
{
    int index;
    char bombName[BOMB_NAME_LENGTH];
    int bombIndex;

        void setItem(int number, int bombIndex)
        {
                this.index = number;
                Format(this.bombName, sizeof(Mine::bombName), "%s", GetBombName(bombIndex));
                this.bombIndex = bombIndex;
        }

        void getItem(char[] buffer, int maxlen)
        {
                if (this.index < 0 || this.bombName[0] == '\0')
                {
                        buffer[0] = '\0';
                        return;
                }
                Format(buffer, maxlen, "%s", this.bombName);
        }
};

stock const char[] GetBombName(int index)
{
        switch( index - 1 )
        {
                case 0: return "Bomb";
                case 1: return "Cluster";
                case 2: return "Firework";
                case 3: return "Smoke";
                case 4: return "BlackHole";
                case 5: return "Flashbang";
                case 6: return "Shield";
                case 7: return "Tesla";
                case 8: return "Chemical";
                case 9: return "Freeze";
                case 10: return "Medic";
                case 11: return "Vaporizer";
                case 12: return "Extinguisher";
                case 13: return "Glow";
                case 14: return "Anti-Gravity";
                case 15: return "Fire Cluster";
                case 16: return "Bullets";
                case 17: return "Flak";
                case 18: return "Airstrike";
                case 19: return "Weapon";
        }
        return "";
}

