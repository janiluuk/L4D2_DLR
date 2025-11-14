#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

bool GetPerkName(int client, const char[] name, int level, char[] result, int maxlen)
{
	Action state = Plugin_Changed;
	
	Call_StartForward(g_fwPerkName);
	Call_PushCell(client);
	Call_PushString(name);
	Call_PushCell(level);
	Call_PushStringEx(result, maxlen, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(maxlen);
	if(Call_Finish(state) != SP_ERROR_NONE)
		return false;
	
	return state == Plugin_Changed;
}

bool GetPerkDescription(int client, const char[] name, int level, char[] result, int maxlen)
{
	Action state = Plugin_Changed;
	
	Call_StartForward(g_fwPerkDescription);
	Call_PushCell(client);
	Call_PushString(name);
	Call_PushCell(level);
	Call_PushStringEx(result, maxlen, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(maxlen);
	if(Call_Finish(state) != SP_ERROR_NONE)
		return false;
	
	return state == Plugin_Changed;
}

PerkPerm GetPerkAccess(int client, int slot, const char[] perk, PerkPerm perm = (CAN_USE | CAN_VIEW))
{
	int clonePerm = view_as<int>(perm);
	Action state = Plugin_Continue;
	
	Call_StartForward(g_fwCanAccessPerk);
	Call_PushCell(client);
	Call_PushCell(slot);
	Call_PushString(perk);
	Call_PushCellRef(clonePerm);
	if(Call_Finish(state) != SP_ERROR_NONE)
		state = Plugin_Continue;
	
	if(state >= Plugin_Handled)
		return NO_ACCESS;
	
	if(state == Plugin_Changed)
	{
		perm = view_as<PerkPerm>(clonePerm);
	}
	
	return perm;
}

bool GetSlotName(int client, int slot, char[] result, int maxlen)
{
	Action state = Plugin_Changed;
	
	Call_StartForward(g_fwSlotName);
	Call_PushCell(client);
	Call_PushCell(slot);
	Call_PushStringEx(result, maxlen, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(maxlen);
	if(Call_Finish(state) != SP_ERROR_NONE)
		return false;
	
	return state == Plugin_Changed;
}

public any Native_GetPerkName(Handle plugin, int argc)
{
	int client = GetNativeCell(1);
	int level = GetNativeCell(5);
	
	char name[128];
	GetNativeString(2, name, sizeof(name));
	GetPerkName(client, name, level, name, sizeof(name));
	
	SetNativeString(3, name, GetNativeCell(4), true);
	return name[0] != EOS;
}

public any Native_GetPerkDescription(Handle plugin, int argc)
{
	int client = GetNativeCell(1);
	int level = GetNativeCell(5);
	
	char name[128];
	GetNativeString(2, name, sizeof(name));
	GetPerkDescription(client, name, level, name, sizeof(name));
	
	SetNativeString(3, name, GetNativeCell(4), true);
	return name[0] != EOS;
}

public any Native_GetPerkAccess(Handle plugin, int argc)
{
	int client = GetNativeCell(1);
	
	char name[64];
	GetNativeString(2, name, sizeof(name));
	
	PerkData data;
	if(!FindPerk(name, data))
		return false;
	
	return GetPerkAccess(client, data.slot, name);
}

public any Native_RegPerk(Handle plugin, int argc)
{
	char name[255];
	GetNativeString(2, name, sizeof(name));
	
	PerkData data;
	if(FindPerk(name, data))
		return false;
	
	data.slot = GetNativeCell(1);
	if(data.slot < 0 || data.slot >= g_SlotIndexes.Length)
		return false;
	
	data.maxLevel = GetNativeCell(3);
	
	g_AllPerks.SetArray(name, data, sizeof(data));
	
	StringMap slot = g_SlotIndexes.Get(data.slot);
	slot.SetArray(name, data, sizeof(data));
	
	return true;
}

char SlotIdToSlotClassname(int slotId, char[] result, int maxlen)
{
	char buffer[64] = "";
	if(slotId < 0 || slotId >= g_SlotIndexes.Length) {
		GetNativeString(2, buffer, sizeof(buffer));

		return;
	}
	
	StringMap slot = g_SlotIndexes.Get(slotId);
	if(!slot.GetString("#slotName", buffer, sizeof(buffer))) {
		return;
	}

	GetNativeString(2, buffer, sizeof(buffer));

	strcopy(result, maxlen, buffer);
}

int SlotClassnameToSlotId(const char[] classname)
{
	StringMap slot = null;
	if(!g_SlotPerks.GetValue(classname, slot))
		return -1;
	
	int slotId = -1;
	if(!slot.GetValue("#slotId", slotId))
		return -1;
	
	return slotId;
}

bool FindPerk(const char[] perk, PerkData data)
{
	return g_AllPerks.GetArray(perk, data, sizeof(data));
}

void NotifyPerkPost(int client, int level, const char[] perk)
{
	Call_StartForward(g_fwPerkPost);
	Call_PushCell(client);
	Call_PushCell(level);
	Call_PushString(perk);
	Call_Finish();
}

bool NotifyPerkPre(int client, int& level, char[] perk, int maxlen)
{
	int cloneLevel = level;
	char clonePerk[64];
	Action state = Plugin_Continue;
	strcopy(clonePerk, sizeof(clonePerk), perk);
	
	Call_StartForward(g_fwPerkPre);
	Call_PushCell(client);
	Call_PushCell(level);
	Call_PushStringEx(clonePerk, sizeof(clonePerk), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(sizeof(clonePerk));
	if(Call_Finish(state) != SP_ERROR_NONE)
		state = Plugin_Continue;
	
	if(state >= Plugin_Handled)
	{
		// PrintToChat(client, "NotifyPerkPre, state=%d", state);
		return false;
	}
	
	if(state == Plugin_Changed)
	{
		level = cloneLevel;
		strcopy(perk, maxlen, clonePerk);
	}
	
	return true;
}

bool GivePerk(int client, const char[] perk, int level)
{
	char buffer[64];
	strcopy(buffer, sizeof(buffer), perk);
	
	level += ClientData[client].GetPerk(buffer);
	if(!NotifyPerkPre(client, level, buffer, sizeof(buffer)))
		return false;
	
	// PrintToChat(client, "skill %s, lv %d", buffer, level);
	bool result = ClientData[client].SetPerk(buffer, level);
	
	NotifyPerkPost(client, level, buffer);
	
	// PrintToServer("client %N perk %s of %d", client, buffer, level);
	return result;
}

public any Native_FindPerk(Handle plugin, int argc)
{
	char name[255];
	GetNativeString(1, name, sizeof(name));
	
	PerkData data;
	if(FindPerk(name, data))
		return false;
	
	SetNativeArray(2, data, sizeof(data));
	return true;
}

public Native_GetPlayerPerk(Handle:plugin, numParams)
{
	int client = GetNativeCell(1);

	char name[255];
	GetNativeString(2, name, sizeof(name));

	return ClientData[client].GetPerk(name);
}

public Native_GetAllPerks(Handle plugin, any argc)
{
	return CloneHandle(g_AllPerks.Snapshot(), plugin);
}
