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
    - don't forget to edit translations/rage_music.phrases.txt greetings and congratulations.
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
#include <soundlib>

public Plugin myinfo =
{
    name = "[Rage] Music Controller",
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

EngineVersion g_rageEngine;

ArrayList g_rageSoundPath;
ArrayList g_rageSoundPathNewly;

Handle g_rageCookieMusic = INVALID_HANDLE;
Handle g_rageTimerMusic[MAXPLAYERS+1];
Handle g_rageAmbientLoop[MAXPLAYERS+1];
Handle g_rageAmbientResume[MAXPLAYERS+1];

bool g_rageMusicPlaying[MAXPLAYERS+1];

int g_rageSndIdx = -1;
int g_rageSndIdxNewly = -1;
int g_rageCookie[MAXPLAYERS+1];

int g_rageSoundVolume[MAXPLAYERS+1];

char g_rageListPath[PLATFORM_MAX_PATH];
char g_rageListPathNewly[PLATFORM_MAX_PATH];

KeyValues g_rageAmbientConfig;
char g_rageAmbientSound[PLATFORM_MAX_PATH];
char g_rageMapName[PLATFORM_MAX_PATH];
float g_rageAmbientDuration;
float g_rageAmbientVolume = 1.0;
bool g_rageAmbientLoopEnabled = true;
bool g_rageAmbientLoaded = false;
bool g_rageClientAllowsDownload[MAXPLAYERS+1];

bool g_rageFirstConnect[MAXPLAYERS+1] = {true, ...};

ConVar g_rageCvarStartEnabled;
ConVar g_rageCvarDelay;
ConVar g_rageCvarShowMenu;
ConVar g_rageCvarUseNewly;
ConVar g_rageCvarDisplayName;
ConVar g_rageCvarPlayRoundStart;
ConVar g_rageCvarAmbient;

bool g_rageEnabled;

public void OnPluginStart()
{
    LoadTranslations("rage_music.phrases");
    
    g_rageEngine = GetEngineVersion();
    
    CreateConVar(                            "l4d_music_mapstart_version",                PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD );
    g_rageCvarStartEnabled = CreateConVar(            "start_music_enabled",                "1",            "Play music when a map or round starts? (1 - Yes, 0 - No)", CVAR_FLAGS );
    g_rageCvarDelay = CreateConVar(             "l4d_music_mapstart_delay",                 "17",           "Delay (in sec.) between player join and playing the music", CVAR_FLAGS );
    g_rageCvarShowMenu = CreateConVar(          "l4d_music_mapstart_showmenu",              "1",            "Show !music menu on round start? (1 - Yes, 0 - No)", CVAR_FLAGS );
    g_rageCvarUseNewly = CreateConVar(          "l4d_music_mapstart_use_firstconnect_list", "0",            "Use separate music list for newly connected players? (1 - Yes, 0 - No)", CVAR_FLAGS );
    g_rageCvarDisplayName = CreateConVar(       "l4d_music_mapstart_display_in_chat",       "1",            "Display music name in chat? (1 - Yes, 0 - No)", CVAR_FLAGS );
    g_rageCvarPlayRoundStart = CreateConVar(    "l4d_music_mapstart_play_roundstart",       "1",            "Play music on round start as well? (1 - Yes, 0 - No, mean play on new map start only)", CVAR_FLAGS );
    g_rageCvarAmbient = CreateConVar(           "ambient_music_enabled",               "1",            "Enable ambient background sound when music stops? (1 - Yes, 0 - No)", CVAR_FLAGS );
    
    AutoExecConfig(true,            "l4d_music_mapstart");
    
    RegConsoleCmd("sm_music",            Cmd_Music,          "Player menu, optionally: <idx> of music, or -1 to play next");
    RegConsoleCmd("sm_music_update",    Cmd_MusicUpdate,    "Populate music list from config");
    RegConsoleCmd("sm_music_play",      Cmd_MusicPlay,      "Play current music track");
    RegConsoleCmd("sm_music_pause",     Cmd_MusicPause,     "Pause current music");
    RegConsoleCmd("sm_music_volume",    Cmd_MusicVolume,    "Set music volume 0-10");
    RegConsoleCmd("sm_music_current",   Cmd_MusicCurrent,   "Show current music track");
    RegConsoleCmd("sm_music_next",      Cmd_MusicNext,      "Skip to next music track");
    RegAdminCmd("sm_reload_ambient",    Cmd_ReloadAmbient,  ADMFLAG_GENERIC, "Reload ambient sound configuration");
    
    g_rageSoundPath = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
    g_rageSoundPathNewly = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
    
    BuildPath(Path_SM, g_rageListPath, sizeof(g_rageListPath), "data/music_mapstart.txt");
    BuildPath(Path_SM, g_rageListPathNewly, sizeof(g_rageListPathNewly), "data/music_mapstart_newly.txt");

    if (!UpdateList())
        SetFailState("Cannot open config file \"%s\" or \"%s\"!", g_rageListPath, g_rageListPathNewly);

    g_rageAmbientConfig = new KeyValues("AmbientSounds");
    LoadAmbientConfig();

    g_rageCookieMusic = RegClientCookie("music_mapstart_cookie", "", CookieAccess_Protected);
    
    HookConVarChange(g_rageCvarStartEnabled,             ConVarChanged);
    GetCvars();
    
    SetRandomSeed(GetTime());
}

public void OnPluginEnd()
{
    delete g_rageSoundPath;
    delete g_rageSoundPathNewly;
    CloseHandle(g_rageCookieMusic);
    StopAllAmbient();
    delete g_rageAmbientConfig;
}

public void OnMapInit(const char[] mapName)
{
    strcopy(g_rageMapName, sizeof(g_rageMapName), mapName);
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
        g_rageSoundPath.GetString(g_rageSndIdx, sPath, sizeof(sPath));
        StopCurrentSound(client);
        PrintToChat(client, "stop - %i - %s", g_rageSndIdx, sPath);
        
        if (iIdx == -1) { // play next
            iIdx = g_rageSndIdx + 1;
            if (iIdx >= g_rageSoundPath.Length)
                iIdx = 0;
        }
        
        g_rageSoundPath.GetString(iIdx, sPath, sizeof(sPath));
        PrintToChat(client, "play - %i - %s", iIdx, sPath);
        PrecacheSound(sPath);
        EmitSoundCustom(client, sPath);
        
        g_rageSndIdx = iIdx;
    }
    return Plugin_Handled;
}

public Action Cmd_MusicPlay(int client, int args)
{
    if (client == 0) return Plugin_Handled;
    char sPath[PLATFORM_MAX_PATH];
    if (g_rageFirstConnect[client] && g_rageCvarUseNewly.IntValue == 1 && g_rageSoundPathNewly.Length > 0)
        g_rageSoundPathNewly.GetString(g_rageSndIdxNewly, sPath, sizeof(sPath));
    else if (g_rageSoundPath.Length > 0)
        g_rageSoundPath.GetString(g_rageSndIdx, sPath, sizeof(sPath));
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
    if (g_rageFirstConnect[client] && g_rageCvarUseNewly.IntValue == 1 && g_rageSoundPathNewly.Length > 0)
    {
        if (++g_rageSndIdxNewly >= g_rageSoundPathNewly.Length)
            g_rageSndIdxNewly = 0;
        g_rageSoundPathNewly.GetString(g_rageSndIdxNewly, sPath, sizeof(sPath));
    }
    else if (g_rageSoundPath.Length > 0)
    {
        if (++g_rageSndIdx >= g_rageSoundPath.Length)
            g_rageSndIdx = 0;
        g_rageSoundPath.GetString(g_rageSndIdx, sPath, sizeof(sPath));
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
    g_rageSoundVolume[client] = vol;
    g_rageCookie[client] = (g_rageCookie[client] & 0x0F) | (g_rageSoundVolume[client] << 4);
    SaveCookie(client);
    PrintToChat(client, "Volume set to %d%%", vol * 10);
    if (g_rageMusicPlaying[client])
    {
        char sPath[PLATFORM_MAX_PATH];
        if (g_rageFirstConnect[client] && g_rageCvarUseNewly.IntValue == 1 && g_rageSoundPathNewly.Length > 0)
            g_rageSoundPathNewly.GetString(g_rageSndIdxNewly, sPath, sizeof(sPath));
        else if (g_rageSoundPath.Length > 0)
            g_rageSoundPath.GetString(g_rageSndIdx, sPath, sizeof(sPath));
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
    if (g_rageFirstConnect[client] && g_rageCvarUseNewly.IntValue == 1 && g_rageSoundPathNewly.Length > 0)
        g_rageSoundPathNewly.GetString(g_rageSndIdxNewly, sPath, sizeof(sPath));
    else if (g_rageSoundPath.Length > 0)
        g_rageSoundPath.GetString(g_rageSndIdx, sPath, sizeof(sPath));
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
    g_rageEnabled = g_rageCvarStartEnabled.BoolValue;
    InitHook();
}

void InitHook()
{
    static bool bHooked;
    
    if (g_rageEnabled) {
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
    GetClientCookie(client, g_rageCookieMusic, sCookie, sizeof(sCookie));
    if(sCookie[0] != '\0')
    {
        g_rageCookie[client] = StringToInt(sCookie);
    }
    g_rageSoundVolume[client] = GetCookieVolume(client);
}

public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    g_rageCookie[client] = 0;
    g_rageTimerMusic[client] = INVALID_HANDLE;
    g_rageFirstConnect[client] = true;
    g_rageMusicPlaying[client] = false;
    StopClientAmbientSound(client);
    if (g_rageAmbientResume[client] != null)
    {
        KillTimer(g_rageAmbientResume[client]);
        g_rageAmbientResume[client] = null;
    }
}

public Action Cmd_MusicUpdate(int client, int args)
{
    ReadCookie(client);
    UpdateList(client);
    g_rageSndIdx = -1;
    g_rageSndIdxNewly = -1;
    OnMapStart();
    return Plugin_Handled;
}

bool UpdateList(int client = 0)
{
    return UpdateListDefault(client) && UpdateListNewly(client);
}

bool UpdateListDefault(int client = 0)
{
    g_rageSoundPath.Clear();

    char sLine[PLATFORM_MAX_PATH];
    File hFile = OpenFile(g_rageListPath, "r");
    if( hFile == null )
    {
        if (client != 0)
            PrintToChat(client, "Cannot open config file \"%s\"!", g_rageListPath);
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
                g_rageSoundPath.PushString(sLine);
            }
        }
        CloseHandle(hFile);
    }
    return true;
}
bool UpdateListNewly(int client = 0)
{
    g_rageSoundPathNewly.Clear();
    
    if (g_rageCvarUseNewly.IntValue == 0) {
        return true;
    }
    
    char sLine[PLATFORM_MAX_PATH];
    File hFile = OpenFile(g_rageListPathNewly, "r");
    if( hFile == null )
    {
        if (client != 0)
            PrintToChat(client, "Cannot open config file \"%s\"!", g_rageListPathNewly);
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
            g_rageSoundPathNewly.PushString(sLine);
        }
        CloseHandle(hFile);
    }
    return true;
}

public void OnClientPutInServer(int client)
{
    if (client && !IsFakeClient(client))
    {
        QueryClientConVar(client, "cl_downloadfilter", CheckDownloads);
        if (g_rageTimerMusic[client] == INVALID_HANDLE)
        {
            g_rageTimerMusic[client] = CreateTimer(g_rageCvarDelay.FloatValue, Timer_PlayMusic, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public void OnClientPostAdminCheck(int client)
{
    if (g_rageAmbientLoaded && strlen(g_rageAmbientSound) > 0)
        CreateTimer(15.0, Timer_DelayedClientAmbient, GetClientUserId(client));
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if (g_rageCvarPlayRoundStart.IntValue == 0)
        return;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            if (g_rageTimerMusic[i] == INVALID_HANDLE)
            {
                g_rageTimerMusic[i] = CreateTimer(g_rageCvarDelay.FloatValue, Timer_PlayMusic, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    ResetTimer();
}
public void OnMapEnd()
{
    ResetTimer();
    StopAllAmbient();
}

void ResetTimer()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        g_rageTimerMusic[i] = INVALID_HANDLE;
    }
}

public Action Timer_PlayMusic(Handle timer, int UserId)
{
    int client = GetClientOfUserId(UserId);
    g_rageTimerMusic[client] = INVALID_HANDLE;
    
    if (client != 0 && IsClientInGame(client)) 
    {
        if (GetCookiePlayMusic(client))
        {
            char sPath[PLATFORM_MAX_PATH];
            
            if (g_rageFirstConnect[client] && g_rageCvarUseNewly.IntValue == 1 && g_rageSoundPathNewly.Length > 0)
            {
                g_rageSoundPathNewly.GetString(g_rageSndIdxNewly, sPath, sizeof(sPath));
            }
            else if (g_rageSoundPath.Length > 0)
            {
                g_rageSoundPath.GetString(g_rageSndIdx, sPath, sizeof(sPath));
            }
            
            EmitSoundCustom(client, sPath);
        }
        if (GetCookieShowMenu(client))
        {
            if (g_rageCvarShowMenu.BoolValue)
                ShowMusicMenu(client);
        }
        g_rageFirstConnect[client] = false;
    }
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
            delete menu;
        
        case MenuAction_Select:
        {
            int client = param1;
            int ItemIndex = param2;
            
            char sItem[16];
            char sPath[PLATFORM_MAX_PATH];
            menu.GetItem(ItemIndex, sItem, sizeof(sItem));
            
            switch(StringToInt(sItem)) {
                case 5: {
                    StopCurrentSound(client);
                }
                case 6: {
                    StopCurrentSound(client);
                    
                    if (g_rageSoundPath.Length > 0)
                    {
                        g_rageSoundPath.GetString(g_rageSndIdx, sPath, sizeof(sPath));
                        EmitSoundCustom(client, sPath);
                    }
                    else if (g_rageCvarUseNewly.IntValue == 1 && g_rageSoundPathNewly.Length > 0)
                    {
                        g_rageSoundPathNewly.GetString(g_rageSndIdxNewly, sPath, sizeof(sPath));
                        EmitSoundCustom(client, sPath);
                    }
                }
                case -1: {
                    ShowMenuSettings(client);
                    return;
                }
            }
            ShowMusicMenu(client);
        }
    }
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
    if (GetCookieAmbient(client))
    {
        menu.AddItem("11", Translate(client, "%t", "DisableAmbient"));
    }
    else {
        menu.AddItem("11", Translate(client, "%t", "EnableAmbient"));
    }
    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}


public int MenuHandler_MenuSettings(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_End:
            delete menu;
        
        case MenuAction_Cancel:
            if (param2 == MenuCancel_ExitBack)
                ShowMusicMenu(param1);
        
        case MenuAction_Select:
        {
            int client = param1;
            int ItemIndex = param2;
            
            char sItem[16];
            menu.GetItem(ItemIndex, sItem, sizeof(sItem));
            
            switch(StringToInt(sItem)) {
                case 7: {
                    ShowVolumeMenu(client);
                    return;
                }
                case 8: {
                    FakeClientCommand(client, "sm_music -1");
                }
                case 9: {
                    g_rageCookie[client] ^= 4;
                    SaveCookie(client);
                }
                case 10: {
                    g_rageCookie[client] ^= 2;
                    SaveCookie(client);
                }
                case 11: {
                    g_rageCookie[client] ^= 8;
                    SaveCookie(client);
                    if (GetCookieAmbient(client))
                    {
                        if (!g_rageMusicPlaying[client])
                            StartClientAmbientSound(client);
                    }
                    else
                        StopClientAmbientSound(client);
                }
            }
            ShowMenuSettings(client);
        }
    }
}

void StopCurrentSound(int client)
{
    char sPath[PLATFORM_MAX_PATH];
    
    if (g_rageSoundPath.Length > 0)
    {
        g_rageSoundPath.GetString(g_rageSndIdx, sPath, sizeof(sPath));
        StopSound(client, SNDCHAN_DEFAULT, sPath);
    }
    if (g_rageCvarUseNewly.IntValue == 1 && g_rageSoundPathNewly.Length > 0)
    {
        g_rageSoundPathNewly.GetString(g_rageSndIdxNewly, sPath, sizeof(sPath));
        StopSound(client, SNDCHAN_DEFAULT, sPath);
    }
    g_rageMusicPlaying[client] = false;
    if (g_rageAmbientResume[client] != null)
    {
        KillTimer(g_rageAmbientResume[client]);
        g_rageAmbientResume[client] = null;
    }
    if (g_rageCvarAmbient.BoolValue && GetCookieAmbient(client))
        StartClientAmbientSound(client);
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
        Format(sDisplay, sizeof(sDisplay), "%s%.1f", vol == g_rageSoundVolume[client] ? "> " : "", float(vol) / 10.0);
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
            delete menu;
        
        case MenuAction_Cancel:
            if (param2 == MenuCancel_ExitBack)
                ShowMusicMenu(param1);
        
        case MenuAction_Select:
        {
            int client = param1;
            int ItemIndex = param2;
            
            char sItem[16];
            char sPath[PLATFORM_MAX_PATH];
            menu.GetItem(ItemIndex, sItem, sizeof(sItem));
            
            g_rageSoundVolume[client] = StringToInt(sItem);
            g_rageCookie[client] = (g_rageCookie[client] & 0x0F) | (g_rageSoundVolume[client] << 4);
            SaveCookie(client);
            g_rageSoundPath.GetString(g_rageSndIdx, sPath, sizeof(sPath));
            StopSound(client, SNDCHAN_DEFAULT, sPath);
            EmitSoundCustom(client, sPath);
            ShowVolumeMenu(client);
        }
    }
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
    LoadAmbientSound();
    // remove already played track from the list
    if (g_rageSndIdx != -1 && g_rageSoundPath.Length > 0)
    {
        g_rageSoundPath.Erase(g_rageSndIdx);
    }
    if (g_rageSndIdxNewly != -1 && g_rageCvarUseNewly.IntValue == 1 && g_rageSoundPathNewly.Length > 0)
    {
        g_rageSoundPathNewly.Erase(g_rageSndIdxNewly);
    }
    
    // fill the list if it become empty
    if (g_rageSoundPath.Length == 0)
    {
        UpdateListDefault();
    }
    if (g_rageCvarUseNewly.IntValue == 1 && g_rageSoundPathNewly.Length == 0)
    {
        UpdateListNewly();
    }
    
    // select random track
    if (g_rageSoundPath.Length > 0)
    {
        g_rageSndIdx = GetRandomInt(0, g_rageSoundPath.Length - 1);
    }
    if (g_rageCvarUseNewly.IntValue == 1 && g_rageSoundPathNewly.Length > 0)
    {
        g_rageSndIdxNewly = GetRandomInt(0, g_rageSoundPathNewly.Length - 1);
    }
    
    char sSoundPath[PLATFORM_MAX_PATH];
    char sDLPath[PLATFORM_MAX_PATH];
    char sSoundPathNewly[PLATFORM_MAX_PATH];
    char sDLPathNewly[PLATFORM_MAX_PATH];
    
    #if CACHE_ALL_SOUNDS
        if (g_rageSoundPath.Length > 0)
        {
            for (int i = 0; i < g_rageSoundPath.Length; i++) {
                g_rageSoundPath.GetString(i, sSoundPath, sizeof(sSoundPath));
                Format(sDLPath, sizeof(sDLPath), "sound/%s", sSoundPath);
                AddFileToDownloadsTable(sDLPath);
                #if (DEBUG)
                    PrintToChatAll("added to downloads: %s", sDLPath);
                #endif
                PrecacheSound(sSoundPath, true);
            }
        }
        if (g_rageCvarUseNewly.IntValue == 1 && g_rageSoundPathNewly.Length > 0)
        {
            for (int i = 0; i < g_rageSoundPathNewly.Length; i++) {
                g_rageSoundPathNewly.GetString(i, sSoundPathNewly, sizeof(sSoundPathNewly));
                Format(sDLPathNewly, sizeof(sDLPathNewly), "sound/%s", sSoundPathNewly);
                AddFileToDownloadsTable(sDLPathNewly);
                #if (DEBUG)
                    PrintToChatAll("added to downloads: %s", sDLPathNewly);
                #endif
                PrecacheSound(sSoundPathNewly, true);
            }
        }
    #else
        if (g_rageSoundPath.Length > 0)
        {
            g_rageSoundPath.GetString(g_rageSndIdx, sSoundPath, sizeof(sSoundPath));
            Format(sDLPath, sizeof(sDLPath), "sound/%s", sSoundPath);
            AddFileToDownloadsTable(sDLPath);
            PrecacheSound(sSoundPath, true);
        }
        if (g_rageCvarUseNewly.IntValue == 1 && g_rageSoundPathNewly.Length > 0)
        {
            g_rageSoundPathNewly.GetString(g_rageSndIdxNewly, sSoundPathNewly, sizeof(sSoundPathNewly));
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
    return (g_rageCookie[client] & 1) != 0;
}
bool GetCookieShowMenu(int client)
{
    if (!IsCookieLoaded(client))
        return true;
    return (g_rageCookie[client] & 2) != 0;
}
bool GetCookiePlayMusic(int client)
{
    if (!IsCookieLoaded(client))
        return true;
    return (g_rageCookie[client] & 4) != 0;
}
bool GetCookieAmbient(int client)
{
    if (!IsCookieLoaded(client))
        return true;
    return (g_rageCookie[client] & 8) != 0;
}
int GetCookieVolume(int client)
{
    if (!IsCookieLoaded(client))
        return 10;
    int volume = (g_rageCookie[client] & 0xF0) >> 4;
    return volume == 0 ? 10 : volume;
}
void SaveCookie(int client)
{
    if (client < 1 || !IsClientInGame(client) || IsFakeClient(client))
        return;
    
    char sCookie[16];
    g_rageCookie[client] |= 1;
    IntToString(g_rageCookie[client], sCookie, sizeof(sCookie));
    
    if (AreClientCookiesCached(client)) {
        SetClientCookie(client, g_rageCookieMusic, sCookie);
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
    
    if (g_rageEngine == Engine_Left4Dead || g_rageEngine == Engine_Left4Dead2)
        level = SNDLEVEL_GUNFIRE;

    volume = float(g_rageSoundVolume[client]) / 10.0;
    if (volume < 0.0)
        volume = 0.0;

    StopClientAmbientSound(client);

    float fLen;
    if (IsValidGetSoundLength(sound, fLen))
    {
        g_rageMusicPlaying[client] = true;
        if (g_rageAmbientResume[client] != null)
        {
            KillTimer(g_rageAmbientResume[client]);
            g_rageAmbientResume[client] = null;
        }
        if (g_rageCvarAmbient.BoolValue && GetCookieAmbient(client))
            g_rageAmbientResume[client] = CreateTimer(fLen, Timer_ResumeAmbient, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
    }
    else
    {
        g_rageMusicPlaying[client] = true;
    }
    
    if (g_rageCvarDisplayName.IntValue == 1)
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

void LoadAmbientConfig()
{
    char sConfigPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sConfigPath, sizeof(sConfigPath), "configs/ambient_sounds.cfg");
    if (!g_rageAmbientConfig.ImportFromFile(sConfigPath))
    {
        LogError("Could not load ambient sounds config file: %s", sConfigPath);
    }
}

void LoadAmbientSound()
{
    g_rageAmbientLoaded = false;
    g_rageAmbientSound[0] = '\0';
    if (!g_rageCvarAmbient.BoolValue)
        return;
    if (g_rageAmbientConfig == null)
        return;
    if (g_rageAmbientConfig.JumpToKey(g_rageMapName))
    {
        char sSoundPath[PLATFORM_MAX_PATH];
        g_rageAmbientConfig.GetString("sound", sSoundPath, sizeof(sSoundPath));
        if (strlen(sSoundPath) > 0 && IsValidGetSoundLength(sSoundPath, g_rageAmbientDuration))
        {
            g_rageAmbientVolume = g_rageAmbientConfig.GetFloat("volume", 1.0);
            g_rageAmbientLoopEnabled = view_as<bool>(g_rageAmbientConfig.GetNum("loop"));
            strcopy(g_rageAmbientSound, sizeof(g_rageAmbientSound), sSoundPath);
            char sDLPath[PLATFORM_MAX_PATH];
            Format(sDLPath, sizeof(sDLPath), "sound/%s", sSoundPath);
            AddFileToDownloadsTable(sDLPath);
            PrecacheSound(sSoundPath, true);
            g_rageAmbientLoaded = true;
        }
        g_rageAmbientConfig.GoBack();
    }
}

public Action Cmd_ReloadAmbient(int client, int args)
{
    LoadAmbientConfig();
    LoadAmbientSound();
    StopAllAmbient();
    return Plugin_Handled;
}

void StartClientAmbientSound(int client)
{
    if (!g_rageAmbientLoaded || !IsClientInGame(client) || IsFakeClient(client))
        return;
    StopClientAmbientSound(client);
    EmitSoundToClient(client, g_rageAmbientSound, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, g_rageAmbientVolume);
    if (g_rageAmbientLoopEnabled)
        g_rageAmbientLoop[client] = CreateTimer(g_rageAmbientDuration, Timer_AmbientLoop, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_AmbientLoop(Handle timer, any data)
{
    int userid = data;
    int client = GetClientOfUserId(userid);
    if (client == 0 || !IsClientInGame(client) || IsFakeClient(client))
        return Plugin_Stop;
    if (!g_rageAmbientLoaded || !g_rageAmbientLoopEnabled)
        return Plugin_Stop;
    EmitSoundToClient(client, g_rageAmbientSound, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, g_rageAmbientVolume);
    return Plugin_Continue;
}

void StopClientAmbientSound(int client)
{
    if (g_rageAmbientLoop[client] != null)
    {
        KillTimer(g_rageAmbientLoop[client]);
        g_rageAmbientLoop[client] = null;
    }
    if (g_rageAmbientResume[client] != null)
    {
        KillTimer(g_rageAmbientResume[client]);
        g_rageAmbientResume[client] = null;
    }
    if (strlen(g_rageAmbientSound) > 0 && IsClientInGame(client) && !IsFakeClient(client))
        StopSound(client, SNDCHAN_STATIC, g_rageAmbientSound);
}

void StopAllAmbient()
{
    for (int i = 1; i <= MaxClients; i++)
        StopClientAmbientSound(i);
}

public Action Timer_DelayedClientAmbient(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client > 0 && IsClientInGame(client) && !IsFakeClient(client) && g_rageClientAllowsDownload[client] && g_rageCvarAmbient.BoolValue && GetCookieAmbient(client) && !g_rageMusicPlaying[client])
        StartClientAmbientSound(client);
    return Plugin_Stop;
}

public Action Timer_ResumeAmbient(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    g_rageAmbientResume[client] = null;
    g_rageMusicPlaying[client] = false;
    if (client > 0 && IsClientInGame(client) && !IsFakeClient(client) && g_rageCvarAmbient.BoolValue && GetCookieAmbient(client))
        StartClientAmbientSound(client);
    return Plugin_Stop;
}

void CheckDownloads(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
    g_rageClientAllowsDownload[client] = StrEqual(cvarValue, "all");
}

bool IsValidGetSoundLength(const char[] sFile, float &fLength, bool bIsGameSound = false)
{
    SoundFile soundFile = new SoundFile(sFile);
    if (!soundFile)
        return false;
    fLength = soundFile.LengthFloat;
    delete soundFile;
    return true;
}

