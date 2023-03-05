
ArrayList combos;

enum struct SpecifiedPerk {
    int id;
    perkModifier mod;
    int flags;
}
enum struct PerkCombo {
    char name[32];
    ArrayList perks;

    void AddPerk(const char[] name, int flags = 0, perkModifier mod = PerkMod_Invalid) {
        int id = GetPerkID(name);
        if(mod == PerkMod_Invalid) mod = Perks[id].GetDefaultMod();
        SpecifiedPerk perk;
        perk.id = id;
        perk.mod = mod;
        perk.flags = flags;
        this.perks.PushArray(perk, sizeof(perk));
    }

    void Activate(int client, int target) {
        for(int i = 0; i < this.perks.Length; i++) {
            SpecifiedPerk perk;
            this.perks.GetArray(i, perk, sizeof(perk));
            Perks[perk.id].Activate(target, client, perk.mod, perk.flags);
        }
    }
}

void SetupCombo(PerkCombo combo, const char[] name) {
    strcopy(combo.name, sizeof(combo.name), name);
    combo.perks = new ArrayList(sizeof(SpecifiedPerk));
    combos.PushArray(combo, sizeof(combo));
}

void SetupsPerkCombos() {
    combos = new ArrayList(sizeof(PerkCombo));

    PerkCombo combo;
    SetupCombo(combo, "Magnet Galore");
    combo.AddPerk("Special Magnet");
    combo.AddPerk("Tank Magnet");
    #if defined _behavior_included
    combo.AddPerk("Witch Magnet");
    #endif

    SetupCombo(combo, "Tank Run Noob");
    combo.AddPerk("Slow Speed");
    combo.AddPerk("Tank Magnet");

    SetupCombo(combo, "Nuclear");
    combo.AddPerk("Slow Speed");
    combo.AddPerk("Special Magnet");
    combo.AddPerk("Tank Magnet");
    #if defined _behavior_included
    combo.AddPerk("Witch Magnet");
    #endif
    combo.AddPerk("Reverse FF", .flags=2);
    combo.AddPerk("Vomit Player");

    SetupCombo(combo, "No more survival");
    combo.AddPerk("No Pickup", .flags = 8)
    combo.AddPerk("Throw It All", .flags = 1)

    SetupCombo(combo, "Shut up");
    combo.AddPerk("Vocalize Gag");
    combo.AddPerk("Honk / Meow / Woof", .flags=1);

    SetupCombo(combo, "Weakness Compels You");
    combo.AddPerk("No Shove");
    combo.AddPerk("Dull Melee", .flags=2);
    combo.AddPerk("Temp Health Quick Drain");

    PrintToServer("[FTT] Loaded %d perk combos", combos.Length);
}