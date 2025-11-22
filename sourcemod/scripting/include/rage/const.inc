/** CLASS SYSTEM **/

StringMap g_AllPerks, g_SlotPerks;
ArrayList g_SlotIndexes;
GlobalForward g_fwPerkName, g_fwPerkDescription, g_fwCanAccessPerk, g_fwSlotName, g_fwPerkPre, g_fwPerkPost;

enum struct playerClassProperties {
    float maxHealth
    float jumpVelocity
    float attackDamage
    float attackRate
    float armorRate
    float healingRate
    float tankStumbleBlock
}

enum struct playerClass {
	int perkId
	char className[32]
	char classDescription[32]
    playerClassProperties properties
}

enum struct skillAction {
	int client
	int actionId
	int actionType // 1 = Execute standard OnSpecialSKillUsed hooks // 2 = use OnCustomCommand hook // 3 = execute on startup	
	int pluginName
	char parameter[3]
	char bindToKey[2]
	int interval
	float lastUsed
	bool runInStartup
	char successText[128]
	char failureText[128]
	char announceText[128]
}


enum struct skillSet {
	int skillSetId
	char skillSetName[32]
	char skillSetDescription[128]
	char skillISetdentifier[32]
	int maxPlayers
	int	skillSetType 
	char menuIdentifier[16]
	int actions[16]
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
		else if(value > data.maxLevel)
			value = data.maxLevel;
		
		if(value == this.GetPerk(name))
			return false;
		
		if(value == 0)
			this.perks.Remove(name);
		else
			this.perks.SetValue(name, value);
		
		return true;
	}
}

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
}

stock String:ClassTips[][] =
{
	", He can't do shit.",
	", He has high attack melee & shoot rate, takes less damage and moves faster.",
	", He can Jump high",
	", He can heal nearby players, revive others faster, drop supplies. Speciality: Healing orbs.",
	", He can go invisible, drop variety of mines. Speciality: Nightvision.",
	", He has increased damage, fast reload and immune to Tank knockdowns! Speciality: Berzerk mode!",
	", He can drop auto turrets and ammo supplies. Speciality: Protective shield granades.",
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
	"Brute force is ready to unleash again"
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
}

enum struct Mine
{
    int index;
    char bombName[32];
    int bombIndex;
	
	void setItem(int number, int bombIndex) { 
		this.index = number;
		this.bombName = getBombName(bombIndex);
		this.bombIndex = bombIndex;
	}

	char[] getItem() {
		char temp[32];
		temp = this.bombName;

		if (this.index < 0 || StrEqual(temp, "")) return temp;
		char text[32];
		Format(text, sizeof(text), "%s", this.bombName);
		return text;
	}
}

stock char[] formatBombName(char[] bombName) {
	char temp[32];
	Format(temp, sizeof(temp), "%s", bombName);
	return temp;
}

stock char[] getBombName(int index) {

	char bombName[32];

	switch( index - 1 )
	{
		case 0: return formatBombName("Bomb");
		case 1: return formatBombName("Cluster");
		case 2: return formatBombName("Firework");
		case 3: return formatBombName("Smoke");
		case 4: return formatBombName("BlackHole");
		case 5: return formatBombName("Flashbang");
		case 6: return formatBombName("Shield");
		case 7: return formatBombName("Tesla");
		case 8: return formatBombName("Chemical");
		case 9: return formatBombName("Freeze");
		case 10: return formatBombName("Medic");
		case 11: return formatBombName("Vaporizer");
		case 12: return formatBombName("Extinguisher");
		case 13: return formatBombName("Glow");
		case 14: return formatBombName("Anti-Gravity");
		case 15: return formatBombName("Fire Cluster");
		case 16: return formatBombName("Bullets");
		case 17: return formatBombName("Flak");
		case 18: return formatBombName("Airstrike");
		case 19: return formatBombName("Weapon");
	}
	return bombName;
}
