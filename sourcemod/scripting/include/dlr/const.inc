/** CLASS SYSTEM **/

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



