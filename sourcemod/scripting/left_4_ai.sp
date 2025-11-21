// left_4_ai - renamed from new_left_4_chat_2
// NOTE: This is the renamed source. Replace with your existing .sp contents if different.
#include <sourcemod>
#include <sdktools>
#include <left_4_ai>

public Plugin myinfo = {
    name = "left_4_ai",
    author = "original authors, integrated by Rage",
    description = "AI chat for L4D2",
    version = "1.0.0",
    url = "https://github.com/janiluuk/L4D2_Rage"
};

public void OnPluginStart() {
    RegConsoleCmd("sm_ai", Cmd_AI);
}

public Action Cmd_AI(int client, int args) {
    if (client <= 0 || !IsClientInGame(client)) return Plugin_Handled;
    PrintToChat(client, "\x04[AI]\x01 This is a stub. Replace with the real ported code.");
    return Plugin_Handled;
}
