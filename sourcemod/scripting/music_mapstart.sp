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
     - don't forget to edit translations/MusicMapStart.phrases.txt greetings and congratulations.
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
    name = "Map start music",
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

EngineVersion g_Engine;

ArrayList g_SoundPath;
ArrayList g_SoundPathNewly;

Handle g_hCookieMusic = INVALID_HANDLE;
Handle g_hTimerMusic[MAXPLAYERS+1];
Handle g_hAmbientLoop[MAXPLAYERS+1];
Handle g_hAmbientResume[MAXPLAYERS+1];

bool g_bMusicPlaying[MAXPLAYERS+1];

int g_iSndIdx = -1;
int g_iSndIdxNewly = -1;
int g_iCookie[MAXPLAYERS+1];

int g_iSoundVolume[MAXPLAYERS+1];

char g_sListPath[PLATFORM_MAX_PATH];
char g_sListPathNewly[PLATFORM_MAX_PATH];

KeyValues g_hAmbientConfig;
char g_sAmbientSound[PLATFORM_MAX_PATH];
char g_sMapName[PLATFORM_MAX_PATH];
float g_fAmbientDuration;
float g_fAmbientVolume = 1.0;
bool g_bAmbientLoop = true;
bool g_bAmbientLoaded = false;
bool g_bClientAllowsDownload[MAXPLAYERS+1];

bool g_bFirstConnect[MAXPLAYERS+1] = {true, ...};

ConVar g_hCvarEnable;
ConVar g_hCvarDelay;
ConVar g_hCvarShowMenu;
ConVar g_hCvarUseNewly;
ConVar g_hCvarDisplayName;
ConVar g_hCvarPlayRoundStart;
ConVar g_hCvarAmbient;

bool g_bEnabled;

public void OnPluginStart()
{
    LoadTranslations("MusicMapStart.phrases");
    
    g_Engine = GetEngineVersion();
    
    CreateConVar(                            "l4d_music_mapstart_version",                PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD );
    g_hCvarEnable = CreateConVar(            "l4d_music_mapstart_enable",                "1",            "Enable plugin (1 - On / 0 - Off)", CVAR_FLAGS );
    g_hCvarDelay = CreateConVar(             "l4d_music_mapstart_delay",                 "17",           "Delay (in sec.) between player join and playing the music", CVAR_FLAGS );
    g_hCvarShowMenu = CreateConVar(          "l4d_music_mapstart_showmenu",              "1",            "Show !music menu on round start? (1 - Yes, 0 - No)", CVAR_FLAGS );
    g_hCvarUseNewly = CreateConVar(          "l4d_music_mapstart_use_firstconnect_list", "0",            "Use separate music list for newly connected players? (1 - Yes, 0 - No)", CVAR_FLAGS );
    g_hCvarDisplayName = CreateConVar(       "l4d_music_mapstart_display_in_chat",       "1",            "Display music name in chat? (1 - Yes, 0 - No)", CVAR_FLAGS );
    g_hCvarPlayRoundStart = CreateConVar(    "l4d_music_mapstart_play_roundstart",       "1",            "Play music on round start as well? (1 - Yes, 0 - No, mean play on new map start only)", CVAR_FLAGS );
    g_hCvarAmbient = CreateConVar(           "l4d_music_mapstart_ambient",               "1",            "Enable ambient background sound when music stopped? (1 - Yes, 0 - No)", CVAR_FLAGS );
    
    AutoExecConfig(true,            "l4d_music_mapstart");
    
    RegConsoleCmd("sm_music",            Cmd_Music,          "Player menu, optionally: <idx> of music, or -1 to play next");
    RegConsoleCmd("sm_music_update",    Cmd_MusicUpdate,    "Populate music list from config");
    RegConsoleCmd("sm_music_play",      Cmd_MusicPlay,      "Play current music track");
    RegConsoleCmd("sm_music_pause",     Cmd_MusicPause,     "Pause current music");
    RegConsoleCmd("sm_music_volume",    Cmd_MusicVolume,    "Set music volume 0-10");
    RegConsoleCmd("sm_music_current",   Cmd_MusicCurrent,   "Show current music track");
    RegConsoleCmd("sm_music_next",      Cmd_MusicNext,      "Skip to next music track");
    RegAdminCmd("sm_reload_ambient",    Cmd_ReloadAmbient,  ADMFLAG_GENERIC, "Reload ambient sound configuration");
    
    g_SoundPath = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
    g_SoundPathNewly = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
    
    BuildPath(Path_SM, g_sListPath, sizeof(g_sListPath), "data/music_mapstart.txt");
    BuildPath(Path_SM, g_sListPathNewly, sizeof(g_sListPathNewly), "data/music_mapstart_newly.txt");

    if (!UpdateList())
        SetFailState("Cannot open config file \"%s\" or \"%s\"!", g_sListPath, g_sListPathNewly);

    g_hAmbientConfig = new KeyValues("AmbientSounds");
    LoadAmbientConfig();

    g_hCookieMusic = RegClientCookie("music_mapstart_cookie", "", CookieAccess_Protected);
    
    HookConVarChange(g_hCvarEnable,             ConVarChanged);
    GetCvars();
    
    SetRandomSeed(GetTime());
}

public void OnPluginEnd()
{
    delete g_SoundPath;
    delete g_SoundPathNewly;
    CloseHandle(g_hCookieMusic);
    StopAllAmbient();
    delete g_hAmbientConfig;
}

public void OnMapInit(const char[] mapName)
{
    strcopy(g_sMapName, sizeof(g_sMapName), mapName);
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
        g_SoundPath.GetString(g_iSndIdx, sPath, sizeof(sPath));
        StopCurrentSound(client);
        PrintToChat(client, "stop - %i - %s", g_iSndIdx, sPath);
        
        if (iIdx == -1) { // play next
            iIdx = g_iSndIdx + 1;
            if (iIdx >= g_SoundPath.Length)
                iIdx = 0;
        }
        
        g_SoundPath.GetString(iIdx, sPath, sizeof(sPath));
        PrintToChat(client, "play - %i - %s", iIdx, sPath);
        PrecacheSound(sPath);
        EmitSoundCustom(client, sPath);
        
        g_iSndIdx = iIdx;
    }
    return Plugin_Handled;
}

public Action Cmd_MusicPlay(int client, int args)
{
    if (client == 0) return Plugin_Handled;
    char sPath[PLATFORM_MAX_PATH];
    if (g_bFirstConnect[client] && g_hCvarUseNewly.IntValue == 1 && g_SoundPathNewly.Length > 0)
        g_SoundPathNewly.GetString(g_iSndIdxNewly, sPath, sizeof(sPath));
    else if (g_SoundPath.Length > 0)
        g_SoundPath.GetString(g_iSndIdx, sPath, sizeof(sPath));
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
    if (g_bFirstConnect[client] && g_hCvarUseNewly.IntValue == 1 && g_SoundPathNewly.Length > 0)
    {
        if (++g_iSndIdxNewly >= g_SoundPathNewly.Length)
            g_iSndIdxNewly = 0;
        g_SoundPathNewly.GetString(g_iSndIdxNewly, sPath, sizeof(sPath));
    }
    else if (g_SoundPath.Length > 0)
    {
        if (++g_iSndIdx >= g_SoundPath.Length)
            g_iSndIdx = 0;
        g_SoundPath.GetString(g_iSndIdx, sPath, sizeof(sPath));
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
    g_iSoundVolume[client] = vol;
    g_iCookie[client] = (g_iCookie[client] & 0x0F) | (g_iSoundVolume[client] << 4);
    SaveCookie(client);
    PrintToChat(client, "Volume set to %d%%", vol * 10);
    if (g_bMusicPlaying[client])
    {
        char sPath[PLATFORM_MAX_PATH];
        if (g_bFirstConnect[client] && g_hCvarUseNewly.IntValue == 1 && g_SoundPathNewly.Length > 0)
            g_SoundPathNewly.GetString(g_iSndIdxNewly, sPath, sizeof(sPath));
        else if (g_SoundPath.Length > 0)
            g_SoundPath.GetString(g_iSndIdx, sPath, sizeof(sPath));
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
    if (g_bFirstConnect[client] && g_hCvarUseNewly.IntValue == 1 && g_SoundPathNewly.Length > 0)
        g_SoundPathNewly.GetString(g_iSndIdxNewly, sPath, sizeof(sPath));
    else if (g_SoundPath.Length > 0)
        g_SoundPath.GetString(g_iSndIdx, sPath, sizeof(sPath));
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
    g_bEnabled = g_hCvarEnable.BoolValue;
    InitHook();
}

void InitHook()
{
    static bool bHooked;
    
    if (g_bEnabled) {
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
    GetClientCookie(client, g_hCookieMusic, sCookie, sizeof(sCookie));
    if(sCookie[0] != '\0')
    {
        g_iCookie[client] = StringToInt(sCookie);
    }
    g_iSoundVolume[client] = GetCookieVolume(client);
}

public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    g_iCookie[client] = 0;
    g_hTimerMusic[client] = INVALID_HANDLE;
    g_bFirstConnect[client] = true;
    g_bMusicPlaying[client] = false;
    StopClientAmbientSound(client);
    if (g_hAmbientResume[client] != null)
    {
        KillTimer(g_hAmbientResume[client]);
        g_hAmbientResume[client] = null;
    }
}

public Action Cmd_MusicUpdate(int client, int args)
{
    ReadCookie(client);
    UpdateList(client);
    g_iSndIdx = -1;
    g_iSndIdxNewly = -1;
    OnMapStart();
    return Plugin_Handled;
}

bool UpdateList(int client = 0)
{
    return UpdateListDefault(client) && UpdateListNewly(client);
}

bool UpdateListDefault(int client = 0)
{
    g_SoundPath.Clear();

    char sLine[PLATFORM_MAX_PATH];
    File hFile = OpenFile(g_sListPath, "r");
    if( hFile == null )
    {
        if (client != 0)
            PrintToChat(client, "Cannot open config file \"%s\"!", g_sListPath);
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
                g_SoundPath.PushString(sLine);
            }
        }
        CloseHandle(hFile);
    }
    return true;
}
bool UpdateListNewly(int client = 0)
{
    g_SoundPathNewly.Clear();
    
    if (g_hCvarUseNewly.IntValue == 0) {
        return true;
    }
    
    char sLine[PLATFORM_MAX_PATH];
    File hFile = OpenFile(g_sListPathNewly, "r");
    if( hFile == null )
    {
        if (client != 0)
            PrintToChat(client, "Cannot open config file \"%s\"!", g_sListPathNewly);
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
            g_SoundPathNewly.PushString(sLine);
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
        if (g_hTimerMusic[client] == INVALID_HANDLE)
        {
            g_hTimerMusic[client] = CreateTimer(g_hCvarDelay.FloatValue, Timer_PlayMusic, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public void OnClientPostAdminCheck(int client)
{
    if (g_bAmbientLoaded && strlen(g_sAmbientSound) > 0)
        CreateTimer(15.0, Timer_DelayedClientAmbient, GetClientUserId(client));
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if (g_hCvarPlayRoundStart.IntValue == 0)
        return;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            if (g_hTimerMusic[i] == INVALID_HANDLE)
            {
                g_hTimerMusic[i] = CreateTimer(g_hCvarDelay.FloatValue, Timer_PlayMusic, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
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
        g_hTimerMusic[i] = INVALID_HANDLE;
    }
}

public Action Timer_PlayMusic(Handle timer, int UserId)
{
    int client = GetClientOfUserId(UserId);
    g_hTimerMusic[client] = INVALID_HANDLE;
    
    if (client != 0 && IsClientInGame(client)) 
    {
        if (GetCookiePlayMusic(client))
        {
            char sPath[PLATFORM_MAX_PATH];
            
            if (g_bFirstConnect[client] && g_hCvarUseNewly.IntValue == 1 && g_SoundPathNewly.Length > 0)
            {
                g_SoundPathNewly.GetString(g_iSndIdxNewly, sPath, sizeof(sPath));
            }
            else if (g_SoundPath.Length > 0)
            {
                g_SoundPath.GetString(g_iSndIdx, sPath, sizeof(sPath));
            }
            
            EmitSoundCustom(client, sPath);
        }
        if (GetCookieShowMenu(client))
        {
            if (g_hCvarShowMenu.BoolValue)
                ShowMusicMenu(client);
        }
        g_bFirstConnect[client] = false;
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
                    
                    if (g_SoundPath.Length > 0)
                    {
                        g_SoundPath.GetString(g_iSndIdx, sPath, sizeof(sPath));
                        EmitSoundCustom(client, sPath);
                    }
                    else if (g_hCvarUseNewly.IntValue == 1 && g_SoundPathNewly.Length > 0)
                    {
                        g_SoundPathNewly.GetString(g_iSndIdxNewly, sPath, sizeof(sPath));
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
        menu.AddItem("11", "Disable background music");
    }
    else {
        menu.AddItem("11", "Enable background music");
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
                    g_iCookie[client] ^= 4;
                    SaveCookie(client);
                }
                case 10: {
                    g_iCookie[client] ^= 2;
                    SaveCookie(client);
                }
                case 11: {
                    g_iCookie[client] ^= 8;
                    SaveCookie(client);
                    if (GetCookieAmbient(client))
                    {
                        if (!g_bMusicPlaying[client])
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
    
    if (g_SoundPath.Length > 0)
    {
        g_SoundPath.GetString(g_iSndIdx, sPath, sizeof(sPath));
        StopSound(client, SNDCHAN_DEFAULT, sPath);
    }
    if (g_hCvarUseNewly.IntValue == 1 && g_SoundPathNewly.Length > 0)
    {
        g_SoundPathNewly.GetString(g_iSndIdxNewly, sPath, sizeof(sPath));
        StopSound(client, SNDCHAN_DEFAULT, sPath);
    }
    g_bMusicPlaying[client] = false;
    if (g_hAmbientResume[client] != null)
    {
        KillTimer(g_hAmbientResume[client]);
        g_hAmbientResume[client] = null;
    }
    if (g_hCvarAmbient.BoolValue && GetCookieAmbient(client))
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
        Format(sDisplay, sizeof(sDisplay), "%s%.1f", vol == g_iSoundVolume[client] ? "> " : "", float(vol) / 10.0);
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
            
            g_iSoundVolume[client] = StringToInt(sItem);
            g_iCookie[client] = (g_iCookie[client] & 0x0F) | (g_iSoundVolume[client] << 4);
            SaveCookie(client);
            g_SoundPath.GetString(g_iSndIdx, sPath, sizeof(sPath));
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
    if (g_iSndIdx != -1 && g_SoundPath.Length > 0)
    {
        g_SoundPath.Erase(g_iSndIdx);
    }
    if (g_iSndIdxNewly != -1 && g_hCvarUseNewly.IntValue == 1 && g_SoundPathNewly.Length > 0)
    {
        g_SoundPathNewly.Erase(g_iSndIdxNewly);
    }
    
    // fill the list if it become empty
    if (g_SoundPath.Length == 0)
    {
        UpdateListDefault();
    }
    if (g_hCvarUseNewly.IntValue == 1 && g_SoundPathNewly.Length == 0)
    {
        UpdateListNewly();
    }
    
    // select random track
    if (g_SoundPath.Length > 0)
    {
        g_iSndIdx = GetRandomInt(0, g_SoundPath.Length - 1);
    }
    if (g_hCvarUseNewly.IntValue == 1 && g_SoundPathNewly.Length > 0)
    {
        g_iSndIdxNewly = GetRandomInt(0, g_SoundPathNewly.Length - 1);
    }
    
    char sSoundPath[PLATFORM_MAX_PATH];
    char sDLPath[PLATFORM_MAX_PATH];
    char sSoundPathNewly[PLATFORM_MAX_PATH];
    char sDLPathNewly[PLATFORM_MAX_PATH];
    
    #if CACHE_ALL_SOUNDS
        if (g_SoundPath.Length > 0)
        {
            for (int i = 0; i < g_SoundPath.Length; i++) {
                g_SoundPath.GetString(i, sSoundPath, sizeof(sSoundPath));
                Format(sDLPath, sizeof(sDLPath), "sound/%s", sSoundPath);
                AddFileToDownloadsTable(sDLPath);
                #if (DEBUG)
                    PrintToChatAll("added to downloads: %s", sDLPath);
                #endif
                PrecacheSound(sSoundPath, true);
            }
        }
        if (g_hCvarUseNewly.IntValue == 1 && g_SoundPathNewly.Length > 0)
        {
            for (int i = 0; i < g_SoundPathNewly.Length; i++) {
                g_SoundPathNewly.GetString(i, sSoundPathNewly, sizeof(sSoundPathNewly));
                Format(sDLPathNewly, sizeof(sDLPathNewly), "sound/%s", sSoundPathNewly);
                AddFileToDownloadsTable(sDLPathNewly);
                #if (DEBUG)
                    PrintToChatAll("added to downloads: %s", sDLPathNewly);
                #endif
                PrecacheSound(sSoundPathNewly, true);
            }
        }
    #else
        if (g_SoundPath.Length > 0)
        {
            g_SoundPath.GetString(g_iSndIdx, sSoundPath, sizeof(sSoundPath));
            Format(sDLPath, sizeof(sDLPath), "sound/%s", sSoundPath);
            AddFileToDownloadsTable(sDLPath);
            PrecacheSound(sSoundPath, true);
        }
        if (g_hCvarUseNewly.IntValue == 1 && g_SoundPathNewly.Length > 0)
        {
            g_SoundPathNewly.GetString(g_iSndIdxNewly, sSoundPathNewly, sizeof(sSoundPathNewly));
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
    return (g_iCookie[client] & 1) != 0;
}
bool GetCookieShowMenu(int client)
{
    if (!IsCookieLoaded(client))
        return true;
    return (g_iCookie[client] & 2) != 0;
}
bool GetCookiePlayMusic(int client)
{
    if (!IsCookieLoaded(client))
        return true;
    return (g_iCookie[client] & 4) != 0;
}
bool GetCookieAmbient(int client)
{
    if (!IsCookieLoaded(client))
        return true;
    return (g_iCookie[client] & 8) != 0;
}
int GetCookieVolume(int client)
{
    if (!IsCookieLoaded(client))
        return 10;
    int volume = (g_iCookie[client] & 0xF0) >> 4;
    return volume == 0 ? 10 : volume;
}
void SaveCookie(int client)
{
    if (client < 1 || !IsClientInGame(client) || IsFakeClient(client))
        return;
    
    char sCookie[16];
    g_iCookie[client] |= 1;
    IntToString(g_iCookie[client], sCookie, sizeof(sCookie));
    
    if (AreClientCookiesCached(client)) {
        SetClientCookie(client, g_hCookieMusic, sCookie);
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
    
    if (g_Engine == Engine_Left4Dead || g_Engine == Engine_Left4Dead2)
        level = SNDLEVEL_GUNFIRE;

    volume = float(g_iSoundVolume[client]) / 10.0;
    if (volume < 0.0)
        volume = 0.0;

    StopClientAmbientSound(client);

    float fLen;
    if (IsValidGetSoundLength(sound, fLen))
    {
        g_bMusicPlaying[client] = true;
        if (g_hAmbientResume[client] != null)
        {
            KillTimer(g_hAmbientResume[client]);
            g_hAmbientResume[client] = null;
        }
        if (g_hCvarAmbient.BoolValue && GetCookieAmbient(client))
            g_hAmbientResume[client] = CreateTimer(fLen, Timer_ResumeAmbient, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
    }
    else
    {
        g_bMusicPlaying[client] = true;
    }
    
    if (g_hCvarDisplayName.IntValue == 1)
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
    if (!g_hAmbientConfig.ImportFromFile(sConfigPath))
    {
        LogError("Could not load ambient sounds config file: %s", sConfigPath);
    }
}

void LoadAmbientSound()
{
    g_bAmbientLoaded = false;
    g_sAmbientSound[0] = '\0';
    if (!g_hCvarAmbient.BoolValue)
        return;
    if (g_hAmbientConfig == null)
        return;
    if (g_hAmbientConfig.JumpToKey(g_sMapName))
    {
        char sSoundPath[PLATFORM_MAX_PATH];
        g_hAmbientConfig.GetString("sound", sSoundPath, sizeof(sSoundPath));
        if (strlen(sSoundPath) > 0 && IsValidGetSoundLength(sSoundPath, g_fAmbientDuration))
        {
            g_fAmbientVolume = g_hAmbientConfig.GetFloat("volume", 1.0);
            g_bAmbientLoop = view_as<bool>(g_hAmbientConfig.GetNum("loop"));
            strcopy(g_sAmbientSound, sizeof(g_sAmbientSound), sSoundPath);
            char sDLPath[PLATFORM_MAX_PATH];
            Format(sDLPath, sizeof(sDLPath), "sound/%s", sSoundPath);
            AddFileToDownloadsTable(sDLPath);
            PrecacheSound(sSoundPath, true);
            g_bAmbientLoaded = true;
        }
        g_hAmbientConfig.GoBack();
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
    if (!g_bAmbientLoaded || !IsClientInGame(client) || IsFakeClient(client))
        return;
    StopClientAmbientSound(client);
    EmitSoundToClient(client, g_sAmbientSound, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, g_fAmbientVolume);
    if (g_bAmbientLoop)
        g_hAmbientLoop[client] = CreateTimer(g_fAmbientDuration, Timer_AmbientLoop, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_AmbientLoop(Handle timer, any data)
{
    int userid = data;
    int client = GetClientOfUserId(userid);
    if (client == 0 || !IsClientInGame(client) || IsFakeClient(client))
        return Plugin_Stop;
    if (!g_bAmbientLoaded || !g_bAmbientLoop)
        return Plugin_Stop;
    EmitSoundToClient(client, g_sAmbientSound, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, g_fAmbientVolume);
    return Plugin_Continue;
}

void StopClientAmbientSound(int client)
{
    if (g_hAmbientLoop[client] != null)
    {
        KillTimer(g_hAmbientLoop[client]);
        g_hAmbientLoop[client] = null;
    }
    if (g_hAmbientResume[client] != null)
    {
        KillTimer(g_hAmbientResume[client]);
        g_hAmbientResume[client] = null;
    }
    if (strlen(g_sAmbientSound) > 0 && IsClientInGame(client) && !IsFakeClient(client))
        StopSound(client, SNDCHAN_STATIC, g_sAmbientSound);
}

void StopAllAmbient()
{
    for (int i = 1; i <= MaxClients; i++)
        StopClientAmbientSound(i);
}

public Action Timer_DelayedClientAmbient(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client > 0 && IsClientInGame(client) && !IsFakeClient(client) && g_bClientAllowsDownload[client] && g_hCvarAmbient.BoolValue && GetCookieAmbient(client) && !g_bMusicPlaying[client])
        StartClientAmbientSound(client);
    return Plugin_Stop;
}

public Action Timer_ResumeAmbient(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    g_hAmbientResume[client] = null;
    g_bMusicPlaying[client] = false;
    if (client > 0 && IsClientInGame(client) && !IsFakeClient(client) && g_hCvarAmbient.BoolValue && GetCookieAmbient(client))
        StartClientAmbientSound(client);
    return Plugin_Stop;
}

void CheckDownloads(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
    g_bClientAllowsDownload[client] = StrEqual(cvarValue, "all");
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

