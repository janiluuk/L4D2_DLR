#define PLUGIN_VERSION        "1.3"

/*
    ChangeLog:
    
    1.3 (25-Jun-2022)
     - Removed "finale_win" event from hooking in CSS (not exist).
    
    1.2 (25-Dec-2019)
     - Fixed volume level is incorrectly saved in cookie.
    
    1.1 (23-Dec-2019)
     - Menu is reorganized a little bit
     - Added info in chat about ability to stop music or adjust menu
     - Added colors of chat message (in translation file)
     - Fixed debug item "Next track" is not worked.
     - Added ability to disable some tracks using // in data file.
    
    1.0 (31-Oct-2019)
     - Added cookies for "Volume level", "Show this menu on start", "Play music on start".
     - Menu is appended appropriate.
     - Added missed CloseHandle.
     - Timers initialization is reworked.
     - Added functionality to play music from separate list to new-comers (required "data/music_mapstart_newly.txt" file). This could incready join server delay.
     - Added ConVar "l4d_music_mapstart_use_firstconnect_list" - "Use separate music list for newly connected players? (1 - Yes, 0 - No)"
     - Added ConVar "l4d_music_mapstart_display_in_chat" - Display music name in chat? (1 - Yes, 0 - No)
     - Added ConVar "l4d_music_mapstart_play_roundstart" - Play music on round start as well? (1 - Yes, 0 - No, mean play on new map start only)
     - Enabled ability to use sm_music <arg> for root admins without debug mode (use with caution and for debug purposes only).
     - Moved precache sound on more earlier stage - possibly, solves the bug when sound didn't want to play sometimes.
     - Improved music tracks randomization. Now, already played track is removed from the list, so you will listen no repeats.
    
    0.3 (24-Mar-2019)
     - Little optimizations.
     - Added "Next track" menu in debug mode.
    
    0.2 (09-Mar-2019)
     - Added external file list config.
     - Added batch file to simplify file list preparation.
     - Extended debug-mode. Command: sm_music -1 to play (test) next sound.
     - Added ConVars.
    
    0.1 (14-Feb-2019)
     - First alpha release

    Description:
     
     This plugin is intended to play one random music on each new map start (the same one music will be played on round re-start).
     Only one song will be downloaded to client each map start, so it will reduce client connection delay.
     In this way, you can install infinite number of music tracks on your server without sacrificing connection speed.
     
    Required:
     - music in 44100 Hz sample rate (e.g.: use https://www.inspire-soft.net/software/mp3-quality-modifier tool).
     - content-server with uploaded tracks.
     - run sound/valentine/create_list.bat file to create the list.
     - ConVars in your server.cfg:
     1. sm_cvar sv_allowdownload "1"
     2. sm_cvar sv_downloadurl "http://your-content-server.com/game/left4dead/" <= here is your sound/valentine/ *.mp3
    - don't forget to edit translations/dlr_music.phrases.txt greetings and congratulations.
     - set #define DEBUG 1, compile plugin and test it with sm_music -1 to check every track is correctly played.
     
    Commands:
     
     sm_music - open music menu
     sm_music <arg> - play specific music by id, where arg should be 0 .. to max or -1 to play next index (Use together with #DEBUG 1 mode only!)
     sm_music_update - populate music list from config (use, if you replaced config file without server/plugin restart).

    Known bugs:
     - sometimes "PlayAgain" button is not working. You need to press it several times.
     - some map start game sounds interrupt music sound, so you need to set large enough value for "l4d_music_mapstart_delay" ConVar (like > 10, by default == 17)

    Thanks to:
     
     - Lux - for some suggestions on sound channel
*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

public Plugin myinfo =
{
    name = "[DLR] Music Controller",
    author = "Dragokas",
    description = "Download and play one random music on map start",
    version = PLUGIN_VERSION,
    url = "https://github.com/dragokas/"
}

#define DEBUG 0

#if DEBUG
    #define CACHE_ALL_SOUNDS 1
#else
    #define CACHE_ALL_SOUNDS 0
#endif

#define CVAR_FLAGS      FCVAR_NOTIFY
#define SNDCHAN_DEFAULT SNDCHAN_STATIC // SNDCHAN_AUTO

EngineVersion g_dlrEngine;

ArrayList g_dlrSoundPath;
ArrayList g_dlrSoundPathNewly;

Handle g_dlrCookieMusic = INVALID_HANDLE;
Handle g_dlrTimerMusic[MAXPLAYERS+1];

bool g_dlrMusicPlaying[MAXPLAYERS+1];
char g_dlrCurrentTrack[MAXPLAYERS+1][PLATFORM_MAX_PATH];
float g_dlrTrackStartedAt[MAXPLAYERS+1];

int g_dlrSndIdx = -1;
int g_dlrSndIdxNewly = -1;
int g_dlrCookie[MAXPLAYERS+1];

int g_dlrSoundVolume[MAXPLAYERS+1];

char g_dlrListPath[PLATFORM_MAX_PATH];
char g_dlrListPathNewly[PLATFORM_MAX_PATH];

bool g_dlrFirstConnect[MAXPLAYERS+1] = {true, ...};

ConVar g_dlrCvarStartEnabled;
ConVar g_dlrCvarDelay;
ConVar g_dlrCvarShowMenu;
ConVar g_dlrCvarUseNewly;
ConVar g_dlrCvarDisplayName;
ConVar g_dlrCvarPlayRoundStart;

bool g_dlrEnabled;

void ClearClientTrackState(int client);
void BeginTrackingClientTrack(int client, const char[] sound);

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("DLR_Music_IsPlaying", Native_DLR_Music_IsPlaying);
    CreateNative("DLR_Music_GetCurrentTrack", Native_DLR_Music_GetCurrentTrack);
    CreateNative("DLR_Music_GetPlaybackTime", Native_DLR_Music_GetPlaybackTime);
    RegPluginLibrary("dlr_music");

    return APLRes_Success;
}

public void OnPluginStart()
{
    LoadTranslations("dlr_music.phrases");

    g_dlrEngine = GetEngineVersion();
    
    CreateConVar(                            "l4d_music_mapstart_version",                PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD );
    g_dlrCvarStartEnabled = CreateConVar(            "start_music_enabled",                "1",            "Play music when a map or round starts? (1 - Yes, 0 - No)", CVAR_FLAGS );
    g_dlrCvarDelay = CreateConVar(             "l4d_music_mapstart_delay",                 "17",           "Delay (in sec.) between player join and playing the music", CVAR_FLAGS );
    g_dlrCvarShowMenu = CreateConVar(          "l4d_music_mapstart_showmenu",              "1",            "Show !music menu on round start? (1 - Yes, 0 - No)", CVAR_FLAGS );
    g_dlrCvarUseNewly = CreateConVar(          "l4d_music_mapstart_use_firstconnect_list", "0",            "Use separate music list for newly connected players? (1 - Yes, 0 - No)", CVAR_FLAGS );
    g_dlrCvarDisplayName = CreateConVar(       "l4d_music_mapstart_display_in_chat",       "1",            "Display music name in chat? (1 - Yes, 0 - No)", CVAR_FLAGS );
    g_dlrCvarPlayRoundStart = CreateConVar(    "l4d_music_mapstart_play_roundstart",       "1",            "Play music on round start as well? (1 - Yes, 0 - No, mean play on new map start only)", CVAR_FLAGS );
    
    AutoExecConfig(true,            "l4d_music_mapstart");
    
    RegConsoleCmd("sm_music",            Cmd_Music,          "Player menu, optionally: <idx> of music, or -1 to play next");
    RegConsoleCmd("sm_music_update",    Cmd_MusicUpdate,    "Populate music list from config");
    RegConsoleCmd("sm_music_play",      Cmd_MusicPlay,      "Play current music track");
    RegConsoleCmd("sm_music_pause",     Cmd_MusicPause,     "Pause current music");
    RegConsoleCmd("sm_music_volume",    Cmd_MusicVolume,    "Set music volume 0-10");
    RegConsoleCmd("sm_music_current",   Cmd_MusicCurrent,   "Show current music track");
    RegConsoleCmd("sm_music_next",      Cmd_MusicNext,      "Skip to next music track");
    
    g_dlrSoundPath = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
    g_dlrSoundPathNewly = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));

    BuildPath(Path_SM, g_dlrListPath, sizeof(g_dlrListPath), "data/music_mapstart.txt");
    BuildPath(Path_SM, g_dlrListPathNewly, sizeof(g_dlrListPathNewly), "data/music_mapstart_newly.txt");

    if (!UpdateList())
        SetFailState("Cannot open config file \"%s\" or \"%s\"!", g_dlrListPath, g_dlrListPathNewly);

    g_dlrCookieMusic = RegClientCookie("music_mapstart_cookie", "", CookieAccess_Protected);
    
    HookConVarChange(g_dlrCvarStartEnabled,             ConVarChanged);
    GetCvars();

    SetRandomSeed(GetTime());

    for (int i = 1; i <= MaxClients; i++)
    {
        ClearClientTrackState(i);
    }
}

public void OnPluginEnd()
{
    delete g_dlrSoundPath;
    delete g_dlrSoundPathNewly;
    CloseHandle(g_dlrCookieMusic);
}

public Action Cmd_Music(int client, int args)
{
    bool bDebug = false;
    #if DEBUG
        bDebug = true;
    #endif
    
    if (args == 0)
        ShowMusicMenu(client);
    
    if (args > 0 && (bDebug || IsClientRootAdmin(client)))
    {
        char sIdx[10];
        int iIdx;
        GetCmdArgString(sIdx, sizeof(sIdx));
        iIdx = StringToInt(sIdx);
        
        char sPath[PLATFORM_MAX_PATH];
        g_dlrSoundPath.GetString(g_dlrSndIdx, sPath, sizeof(sPath));
        StopCurrentSound(client);
        PrintToChat(client, "stop - %i - %s", g_dlrSndIdx, sPath);
        
        if (iIdx == -1) { // play next
            iIdx = g_dlrSndIdx + 1;
            if (iIdx >= g_dlrSoundPath.Length)
                iIdx = 0;
        }
        
        g_dlrSoundPath.GetString(iIdx, sPath, sizeof(sPath));
        PrintToChat(client, "play - %i - %s", iIdx, sPath);
        PrecacheSound(sPath);
        EmitSoundCustom(client, sPath);
        
        g_dlrSndIdx = iIdx;
    }
    return Plugin_Handled;
}

public Action Cmd_MusicPlay(int client, int args)
{
    if (client == 0) return Plugin_Handled;
    char sPath[PLATFORM_MAX_PATH];
    if (g_dlrFirstConnect[client] && g_dlrCvarUseNewly.IntValue == 1 && g_dlrSoundPathNewly.Length > 0)
        g_dlrSoundPathNewly.GetString(g_dlrSndIdxNewly, sPath, sizeof(sPath));
    else if (g_dlrSoundPath.Length > 0)
        g_dlrSoundPath.GetString(g_dlrSndIdx, sPath, sizeof(sPath));
    else
        sPath[0] = '\0';
    if (sPath[0])
    {
        StopCurrentSound(client);
        EmitSoundCustom(client, sPath);
    }
    else
    {
        PrintToChat(client, "No music track loaded.");
    }
    return Plugin_Handled;
}

public Action Cmd_MusicPause(int client, int args)
{
    if (client == 0) return Plugin_Handled;
    StopCurrentSound(client);
    return Plugin_Handled;
}

public Action Cmd_MusicNext(int client, int args)
{
    if (client == 0) return Plugin_Handled;
    char sPath[PLATFORM_MAX_PATH];
    if (g_dlrFirstConnect[client] && g_dlrCvarUseNewly.IntValue == 1 && g_dlrSoundPathNewly.Length > 0)
    {
        if (++g_dlrSndIdxNewly >= g_dlrSoundPathNewly.Length)
            g_dlrSndIdxNewly = 0;
        g_dlrSoundPathNewly.GetString(g_dlrSndIdxNewly, sPath, sizeof(sPath));
    }
    else if (g_dlrSoundPath.Length > 0)
    {
        if (++g_dlrSndIdx >= g_dlrSoundPath.Length)
            g_dlrSndIdx = 0;
        g_dlrSoundPath.GetString(g_dlrSndIdx, sPath, sizeof(sPath));
    }
    else
        sPath[0] = '\0';

    if (sPath[0])
    {
        StopCurrentSound(client);
        PrecacheSound(sPath);
        EmitSoundCustom(client, sPath);
    }
    else
    {
        PrintToChat(client, "No music track loaded.");
    }
    return Plugin_Handled;
}

public Action Cmd_MusicVolume(int client, int args)
{
    if (client == 0) return Plugin_Handled;
    if (args < 1) return Plugin_Handled;
    char sArg[8];
    GetCmdArg(1, sArg, sizeof(sArg));
    int vol = StringToInt(sArg);
    if (vol < 0) vol = 0;
    if (vol > 10) vol = 10;
    g_dlrSoundVolume[client] = vol;
    g_dlrCookie[client] = (g_dlrCookie[client] & 0x0F) | (g_dlrSoundVolume[client] << 4);
    SaveCookie(client);
    PrintToChat(client, "Volume set to %d%%", vol * 10);
    if (g_dlrMusicPlaying[client])
    {
        char sPath[PLATFORM_MAX_PATH];
        if (g_dlrFirstConnect[client] && g_dlrCvarUseNewly.IntValue == 1 && g_dlrSoundPathNewly.Length > 0)
            g_dlrSoundPathNewly.GetString(g_dlrSndIdxNewly, sPath, sizeof(sPath));
        else if (g_dlrSoundPath.Length > 0)
            g_dlrSoundPath.GetString(g_dlrSndIdx, sPath, sizeof(sPath));
        else
            sPath[0] = '\0';
        if (sPath[0])
        {
            StopCurrentSound(client);
            EmitSoundCustom(client, sPath);
        }
    }
    return Plugin_Handled;
}

public Action Cmd_MusicCurrent(int client, int args)
{
    if (client == 0) return Plugin_Handled;
    char sPath[PLATFORM_MAX_PATH];
    if (g_dlrFirstConnect[client] && g_dlrCvarUseNewly.IntValue == 1 && g_dlrSoundPathNewly.Length > 0)
        g_dlrSoundPathNewly.GetString(g_dlrSndIdxNewly, sPath, sizeof(sPath));
    else if (g_dlrSoundPath.Length > 0)
        g_dlrSoundPath.GetString(g_dlrSndIdx, sPath, sizeof(sPath));
    else
        sPath[0] = '\0';
    if (sPath[0])
    {
        int last = -1;
        for (int i = 0; i < strlen(sPath); i++)
            if (sPath[i] == '/')
                last = i;
        char sName[PLATFORM_MAX_PATH];
        if (last != -1)
            strcopy(sName, sizeof(sName), sPath[last + 1]);
        else
            strcopy(sName, sizeof(sName), sPath);
        PrintToChat(client, "Current track: %s", sName);
    }
    else
    {
        PrintToChat(client, "No music track loaded.");
    }
    return Plugin_Handled;
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    InitHook();
}

void GetCvars()
{
    g_dlrEnabled = g_dlrCvarStartEnabled.BoolValue;
    InitHook();
}

void InitHook()
{
    static bool bHooked;
    
    if (g_dlrEnabled) {
        if (!bHooked) {
            HookEvent("round_start",            Event_RoundStart,  EventHookMode_PostNoCopy);
            HookEvent("round_end",              Event_RoundEnd,    EventHookMode_PostNoCopy);
            HookEventEx("finale_win",           Event_RoundEnd,    EventHookMode_PostNoCopy);
            HookEvent("mission_lost",           Event_RoundEnd,    EventHookMode_PostNoCopy);
            HookEvent("map_transition",        Event_RoundEnd,    EventHookMode_PostNoCopy);
            HookEvent("player_disconnect",      Event_PlayerDisconnect,     EventHookMode_Pre);
            bHooked = true;
        }
    } else {
        if (bHooked) {
            UnhookEvent("round_start",         Event_RoundStart,  EventHookMode_PostNoCopy);
            UnhookEvent("round_end",           Event_RoundEnd,    EventHookMode_PostNoCopy);
            UnhookEvent("mission_lost",        Event_RoundEnd,    EventHookMode_PostNoCopy);
            UnhookEvent("map_transition",      Event_RoundEnd,    EventHookMode_PostNoCopy);
            UnhookEvent("player_disconnect",   Event_PlayerDisconnect,      EventHookMode_Pre);
            UnhookEvent("finale_win",          Event_RoundEnd,    EventHookMode_PostNoCopy);
            bHooked = false;
        }
    }
}

public void OnClientCookiesCached(int client)
{
    ReadCookie(client);
}

void ReadCookie(int client)
{
    char sCookie[16];
    GetClientCookie(client, g_dlrCookieMusic, sCookie, sizeof(sCookie));
    if(sCookie[0] != '\0')
    {
        g_dlrCookie[client] = StringToInt(sCookie);
    }
    g_dlrSoundVolume[client] = GetCookieVolume(client);
}

public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    g_dlrCookie[client] = 0;
    g_dlrTimerMusic[client] = INVALID_HANDLE;
    g_dlrFirstConnect[client] = true;
    ClearClientTrackState(client);
}

public Action Cmd_MusicUpdate(int client, int args)
{
    ReadCookie(client);
    UpdateList(client);
    g_dlrSndIdx = -1;
    g_dlrSndIdxNewly = -1;
    OnMapStart();
    return Plugin_Handled;
}

bool UpdateList(int client = 0)
{
    return UpdateListDefault(client) && UpdateListNewly(client);
}

bool UpdateListDefault(int client = 0)
{
    g_dlrSoundPath.Clear();

    char sLine[PLATFORM_MAX_PATH];
    File hFile = OpenFile(g_dlrListPath, "r");
    if( hFile == null )
    {
        if (client != 0)
            PrintToChat(client, "Cannot open config file \"%s\"!", g_dlrListPath);
        return false;
    }
    else {
        while( !hFile.EndOfFile() && hFile.ReadLine(sLine, sizeof(sLine)) )
        {
            TrimString(sLine); // walkaround against line break bug
            if (sLine[0] != '/' && sLine[1] != '/')
            {
                #if DEBUG
                if (client != 0)
                    PrintToChat(client, "Added: %s", sLine);
                #endif
                g_dlrSoundPath.PushString(sLine);
            }
        }
        CloseHandle(hFile);
    }
    return true;
}
bool UpdateListNewly(int client = 0)
{
    g_dlrSoundPathNewly.Clear();
    
    if (g_dlrCvarUseNewly.IntValue == 0) {
        return true;
    }
    
    char sLine[PLATFORM_MAX_PATH];
    File hFile = OpenFile(g_dlrListPathNewly, "r");
    if( hFile == null )
    {
        if (client != 0)
            PrintToChat(client, "Cannot open config file \"%s\"!", g_dlrListPathNewly);
        return false;
    }
    else {
        while( !hFile.EndOfFile() && hFile.ReadLine(sLine, sizeof(sLine)) )
        {
            #if DEBUG
            if (client != 0)
                PrintToChat(client, "Added: %s", sLine);
            #endif
            
            TrimString(sLine); // walkaround against line break bug
            g_dlrSoundPathNewly.PushString(sLine);
        }
        CloseHandle(hFile);
    }
    return true;
}

public void OnClientPutInServer(int client)
{
    if (client && !IsFakeClient(client))
    {
        ClearClientTrackState(client);

        if (g_dlrTimerMusic[client] == INVALID_HANDLE)
        {
            g_dlrTimerMusic[client] = CreateTimer(g_dlrCvarDelay.FloatValue, Timer_PlayMusic, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public void OnClientDisconnect(int client)
{
    if (client < 1 || client > MaxClients)
    {
        return;
    }

    ClearClientTrackState(client);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if (g_dlrCvarPlayRoundStart.IntValue == 0)
    {
        return Plugin_Continue;
    }

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            if (g_dlrTimerMusic[i] == INVALID_HANDLE)
            {
                g_dlrTimerMusic[i] = CreateTimer(g_dlrCvarDelay.FloatValue, Timer_PlayMusic, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }

    return Plugin_Continue;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    ResetTimer();

    return Plugin_Continue;
}
public void OnMapEnd()
{
    ResetTimer();
}

void ResetTimer()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        g_dlrTimerMusic[i] = INVALID_HANDLE;
    }
}

public Action Timer_PlayMusic(Handle timer, int UserId)
{
    int client = GetClientOfUserId(UserId);
    if (client < 1 || client > MaxClients)
    {
        return Plugin_Stop;
    }

    g_dlrTimerMusic[client] = INVALID_HANDLE;

    if (IsClientInGame(client))
    {
        if (GetCookiePlayMusic(client))
        {
            char sPath[PLATFORM_MAX_PATH];

            if (g_dlrFirstConnect[client] && g_dlrCvarUseNewly.IntValue == 1 && g_dlrSoundPathNewly.Length > 0)
            {
                g_dlrSoundPathNewly.GetString(g_dlrSndIdxNewly, sPath, sizeof(sPath));
            }
            else if (g_dlrSoundPath.Length > 0)
            {
                g_dlrSoundPath.GetString(g_dlrSndIdx, sPath, sizeof(sPath));
            }
            
            EmitSoundCustom(client, sPath);
        }
        if (GetCookieShowMenu(client))
        {
            if (g_dlrCvarShowMenu.BoolValue)
                ShowMusicMenu(client);
        }
        g_dlrFirstConnect[client] = false;
    }

    return Plugin_Stop;
}

void ShowMusicMenu(int client)
{
    Menu menu = new Menu(MenuHandler_MenuMusic, MENU_ACTIONS_DEFAULT);    
    menu.SetTitle("!music");
    menu.AddItem("0", Translate(client, "%t", "Congratulation1"), ITEMDRAW_DISABLED);
    menu.AddItem("1", Translate(client, "%t", "Congratulation2"), ITEMDRAW_DISABLED);
    menu.AddItem("2", Translate(client, "%t", "Congratulation3"), ITEMDRAW_DISABLED);
    menu.AddItem("3", "", ITEMDRAW_DISABLED);
    menu.AddItem("5", Translate(client, "%t", "StopMusic"));
    menu.AddItem("6", Translate(client, "%t", "PlayAgain"));
    menu.AddItem("-1", Translate(client, "%t", "Settings"));
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_MenuMusic(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_End:
        {
            delete menu;
            break;
        }
        case MenuAction_Select:
        {
            int client = param1;
            int itemIndex = param2;

            char sItem[16];
            char sPath[PLATFORM_MAX_PATH];
            menu.GetItem(itemIndex, sItem, sizeof(sItem));

            switch (StringToInt(sItem))
            {
                case 5:
                {
                    StopCurrentSound(client);
                    break;
                }
                case 6:
                {
                    StopCurrentSound(client);

                    if (g_dlrSoundPath.Length > 0)
                    {
                        g_dlrSoundPath.GetString(g_dlrSndIdx, sPath, sizeof(sPath));
                        EmitSoundCustom(client, sPath);
                    }
                    else if (g_dlrCvarUseNewly.IntValue == 1 && g_dlrSoundPathNewly.Length > 0)
                    {
                        g_dlrSoundPathNewly.GetString(g_dlrSndIdxNewly, sPath, sizeof(sPath));
                        EmitSoundCustom(client, sPath);
                    }

                    break;
                }
                case -1:
                {
                    ShowMenuSettings(client);
                    return 0;
                }
            }

            ShowMusicMenu(client);
            break;
        }
    }

    return 0;
}

void ShowMenuSettings(int client)
{
    Menu menu = new Menu(MenuHandler_MenuSettings, MENU_ACTIONS_DEFAULT);
    menu.SetTitle("!music - %T", "Settings", client);
    
    menu.AddItem("7", Translate(client, "%t", "Volume"));
    #if (DEBUG)
        menu.AddItem("8", Translate(client, "%t", "GoNext"));
    #endif
    if (GetCookiePlayMusic(client))
    {
        menu.AddItem("9", Translate(client, "%t", "NoMusicNextMap"));
    }
    else {
        menu.AddItem("9", Translate(client, "%t", "MusicNextMap"));
    }
    if (GetCookieShowMenu(client))
    {
        menu.AddItem("10", Translate(client, "%t", "NoMenuAutostart"));
    }
    else {
        menu.AddItem("10", Translate(client, "%t", "MenuAutostart"));
    }
    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}


public int MenuHandler_MenuSettings(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_End:
        {
            delete menu;
            break;
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                ShowMusicMenu(param1);
            }

            break;
        }
        case MenuAction_Select:
        {
            int client = param1;
            int itemIndex = param2;

            char sItem[16];
            menu.GetItem(itemIndex, sItem, sizeof(sItem));

            switch (StringToInt(sItem))
            {
                case 7:
                {
                    ShowVolumeMenu(client);
                    return 0;
                }
                case 8:
                {
                    FakeClientCommand(client, "sm_music -1");
                    break;
                }
                case 9:
                {
                    g_dlrCookie[client] ^= 4;
                    SaveCookie(client);
                    break;
                }
                case 10:
                {
                    g_dlrCookie[client] ^= 2;
                    SaveCookie(client);
                    break;
                }
            }

            ShowMenuSettings(client);
            break;
        }
    }

    return 0;
}

void StopCurrentSound(int client)
{
    char sPath[PLATFORM_MAX_PATH];

    if (g_dlrSoundPath.Length > 0)
    {
        g_dlrSoundPath.GetString(g_dlrSndIdx, sPath, sizeof(sPath));
        StopSound(client, SNDCHAN_DEFAULT, sPath);
    }
    if (g_dlrCvarUseNewly.IntValue == 1 && g_dlrSoundPathNewly.Length > 0)
    {
        g_dlrSoundPathNewly.GetString(g_dlrSndIdxNewly, sPath, sizeof(sPath));
        StopSound(client, SNDCHAN_DEFAULT, sPath);
    }
    g_dlrMusicPlaying[client] = false;
    g_dlrTrackStartedAt[client] = 0.0;
}

void ShowVolumeMenu(int client)
{
    Menu menu = new Menu(MenuHandler_MenuVolume, MENU_ACTIONS_DEFAULT);    
    menu.SetTitle("%t", "NextVolume", client);
    char sItem[16];
    char sDisplay[16];
    
    for (int vol = 2; vol <= 10; vol += 2)
    {
        IntToString(vol, sItem, sizeof(sItem));
        Format(sDisplay, sizeof(sDisplay), "%s%.1f", vol == g_dlrSoundVolume[client] ? "> " : "", float(vol) / 10.0);
        menu.AddItem(sItem, sDisplay);
    }
    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_MenuVolume(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_End:
        {
            delete menu;
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                ShowMusicMenu(param1);
            }

        }
        case MenuAction_Select:
        {
            int client = param1;
            int itemIndex = param2;

            char sItem[16];
            char sPath[PLATFORM_MAX_PATH];
            menu.GetItem(itemIndex, sItem, sizeof(sItem));

            g_dlrSoundVolume[client] = StringToInt(sItem);
            g_dlrCookie[client] = (g_dlrCookie[client] & 0x0F) | (g_dlrSoundVolume[client] << 4);
            SaveCookie(client);
            g_dlrSoundPath.GetString(g_dlrSndIdx, sPath, sizeof(sPath));
            StopSound(client, SNDCHAN_DEFAULT, sPath);
            EmitSoundCustom(client, sPath);
            ShowVolumeMenu(client);
        }
    }

    return 0;
}

stock char[] Translate(int client, const char[] format, any ...)
{
    char buffer[192];
    SetGlobalTransTarget(client);
    VFormat(buffer, sizeof(buffer), format, 3);
    return buffer;
}

stock void ReplaceColor(char[] message, int maxLen)
{
    ReplaceString(message, maxLen, "{white}", "\x01", false);
    ReplaceString(message, maxLen, "{cyan}", "\x03", false);
    ReplaceString(message, maxLen, "{orange}", "\x04", false);
    ReplaceString(message, maxLen, "{green}", "\x05", false);
}

stock void CPrintToChat(int iClient, const char[] format, any ...)
{
    char buffer[192];
    SetGlobalTransTarget(iClient);
    VFormat(buffer, sizeof(buffer), format, 3);
    ReplaceColor(buffer, sizeof(buffer));
    PrintToChat(iClient, "\x01%s", buffer);
}

public void OnMapStart()
{
    // remove already played track from the list
    if (g_dlrSndIdx != -1 && g_dlrSoundPath.Length > 0)
    {
        g_dlrSoundPath.Erase(g_dlrSndIdx);
    }
    if (g_dlrSndIdxNewly != -1 && g_dlrCvarUseNewly.IntValue == 1 && g_dlrSoundPathNewly.Length > 0)
    {
        g_dlrSoundPathNewly.Erase(g_dlrSndIdxNewly);
    }
    
    // fill the list if it become empty
    if (g_dlrSoundPath.Length == 0)
    {
        UpdateListDefault();
    }
    if (g_dlrCvarUseNewly.IntValue == 1 && g_dlrSoundPathNewly.Length == 0)
    {
        UpdateListNewly();
    }
    
    // select random track
    if (g_dlrSoundPath.Length > 0)
    {
        g_dlrSndIdx = GetRandomInt(0, g_dlrSoundPath.Length - 1);
    }
    if (g_dlrCvarUseNewly.IntValue == 1 && g_dlrSoundPathNewly.Length > 0)
    {
        g_dlrSndIdxNewly = GetRandomInt(0, g_dlrSoundPathNewly.Length - 1);
    }
    
    char sSoundPath[PLATFORM_MAX_PATH];
    char sDLPath[PLATFORM_MAX_PATH];
    char sSoundPathNewly[PLATFORM_MAX_PATH];
    char sDLPathNewly[PLATFORM_MAX_PATH];
    
    #if CACHE_ALL_SOUNDS
        if (g_dlrSoundPath.Length > 0)
        {
            for (int i = 0; i < g_dlrSoundPath.Length; i++) {
                g_dlrSoundPath.GetString(i, sSoundPath, sizeof(sSoundPath));
                Format(sDLPath, sizeof(sDLPath), "sound/%s", sSoundPath);
                AddFileToDownloadsTable(sDLPath);
                #if (DEBUG)
                    PrintToChatAll("added to downloads: %s", sDLPath);
                #endif
                PrecacheSound(sSoundPath, true);
            }
        }
        if (g_dlrCvarUseNewly.IntValue == 1 && g_dlrSoundPathNewly.Length > 0)
        {
            for (int i = 0; i < g_dlrSoundPathNewly.Length; i++) {
                g_dlrSoundPathNewly.GetString(i, sSoundPathNewly, sizeof(sSoundPathNewly));
                Format(sDLPathNewly, sizeof(sDLPathNewly), "sound/%s", sSoundPathNewly);
                AddFileToDownloadsTable(sDLPathNewly);
                #if (DEBUG)
                    PrintToChatAll("added to downloads: %s", sDLPathNewly);
                #endif
                PrecacheSound(sSoundPathNewly, true);
            }
        }
    #else
        if (g_dlrSoundPath.Length > 0)
        {
            g_dlrSoundPath.GetString(g_dlrSndIdx, sSoundPath, sizeof(sSoundPath));
            Format(sDLPath, sizeof(sDLPath), "sound/%s", sSoundPath);
            AddFileToDownloadsTable(sDLPath);
            PrecacheSound(sSoundPath, true);
        }
        if (g_dlrCvarUseNewly.IntValue == 1 && g_dlrSoundPathNewly.Length > 0)
        {
            g_dlrSoundPathNewly.GetString(g_dlrSndIdxNewly, sSoundPathNewly, sizeof(sSoundPathNewly));
            Format(sDLPathNewly, sizeof(sDLPathNewly), "sound/%s", sSoundPathNewly);
            if (strcmp(sDLPathNewly, sDLPath) != 0)
            {
                AddFileToDownloadsTable(sDLPathNewly);
                PrecacheSound(sSoundPathNewly, true);
            }
        }
    #endif
}

bool IsCookieLoaded(int client)
{
    return (g_dlrCookie[client] & 1) != 0;
}
bool GetCookieShowMenu(int client)
{
    if (!IsCookieLoaded(client))
        return true;
    return (g_dlrCookie[client] & 2) != 0;
}
bool GetCookiePlayMusic(int client)
{
    if (!IsCookieLoaded(client))
        return true;
    return (g_dlrCookie[client] & 4) != 0;
}
int GetCookieVolume(int client)
{
    if (!IsCookieLoaded(client))
        return 10;
    int volume = (g_dlrCookie[client] & 0xF0) >> 4;
    return volume == 0 ? 10 : volume;
}
void SaveCookie(int client)
{
    if (client < 1 || !IsClientInGame(client) || IsFakeClient(client))
        return;
    
    char sCookie[16];
    g_dlrCookie[client] |= 1;
    IntToString(g_dlrCookie[client], sCookie, sizeof(sCookie));
    
    if (AreClientCookiesCached(client)) {
        SetClientCookie(client, g_dlrCookieMusic, sCookie);
    }
}

// Custom EmitSound to allow compatibility with all game engines
void EmitSoundCustom(
    int client, 
    const char[] sound, 
    int entity = SOUND_FROM_PLAYER,
    int channel = SNDCHAN_DEFAULT,
    int level = SNDLEVEL_NORMAL,
    int flags = SND_NOFLAGS,
    float volume = SNDVOL_NORMAL,
    int pitch = SNDPITCH_NORMAL,
    int speakerentity = -1,
    const float origin[3] = NULL_VECTOR,
    const float dir[3] = NULL_VECTOR,
    bool updatePos = true,
    float soundtime = 0.0)
{
    int clients[1];
    clients[0] = client;
    
    if (g_dlrEngine == Engine_Left4Dead || g_dlrEngine == Engine_Left4Dead2)
        level = SNDLEVEL_GUNFIRE;

    volume = float(g_dlrSoundVolume[client]) / 10.0;
    if (volume < 0.0)
        volume = 0.0;

    BeginTrackingClientTrack(client, sound);

    if (g_dlrCvarDisplayName.IntValue == 1)
    {
        CPrintToChat(client, "%t%s", "Playing", sound);
        CPrintToChat(client, "%t", "Info");
    }
    
    EmitSound(clients, 1, sound, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
}

stock bool IsClientRootAdmin(int client)
{
    return ((GetUserFlagBits(client) & ADMFLAG_ROOT) != 0);
}


void GetTrackDisplayName(const char[] path, char[] output, int maxlen)
{
    int start = 0;
    int length = strlen(path);

    for (int i = 0; i < length; i++)
    {
        if (path[i] == '/' || path[i] == '\\')
        {
            start = i + 1;
        }
    }

    if (start < length)
    {
        strcopy(output, maxlen, path[start]);
    }
    else
    {
        output[0] = '\0';
    }

    int end = strlen(output);
    for (int i = end - 1; i >= 0; i--)
    {
        if (output[i] == '.')
        {
            output[i] = '\0';
            break;
        }
    }
}

void ClearClientTrackState(int client)
{
    if (client < 1 || client > MaxClients)
    {
        return;
    }

    g_dlrMusicPlaying[client] = false;
    g_dlrCurrentTrack[client][0] = '\0';
    g_dlrTrackStartedAt[client] = 0.0;
}

void BeginTrackingClientTrack(int client, const char[] sound)
{
    if (client < 1 || client > MaxClients)
    {
        return;
    }

    g_dlrMusicPlaying[client] = true;
    g_dlrTrackStartedAt[client] = GetGameTime();
    GetTrackDisplayName(sound, g_dlrCurrentTrack[client], sizeof(g_dlrCurrentTrack[]));
}

public any Native_DLR_Music_IsPlaying(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if (client < 1 || client > MaxClients)
    {
        return false;
    }

    return g_dlrMusicPlaying[client];
}

public any Native_DLR_Music_GetCurrentTrack(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    int maxlen = GetNativeCell(3);

    if (maxlen > 0)
    {
        SetNativeString(2, "", maxlen);
    }

    if (client < 1 || client > MaxClients || maxlen <= 0)
    {
        return false;
    }

    SetNativeString(2, g_dlrCurrentTrack[client], maxlen);
    return g_dlrCurrentTrack[client][0] != '\0';
}

public any Native_DLR_Music_GetPlaybackTime(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    if (client < 1 || client > MaxClients || !g_dlrMusicPlaying[client])
    {
        return view_as<any>(0.0);
    }

    float elapsed = GetGameTime() - g_dlrTrackStartedAt[client];
    if (elapsed < 0.0)
    {
        elapsed = 0.0;
    }

    return view_as<any>(elapsed);
}


