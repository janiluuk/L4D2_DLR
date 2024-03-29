stock PrintToHud(char[] text) 
{
	static char buffer[64];
	VFormat(buffer, sizeof(buffer), text, 2);

	AddMessageToHud(buffer);
}
stock deleteHUD(int pos) 
{
	DeleteHUD(view_as<hudPosition>(pos));
}

stock ClearHUD() 
{
	ClearMessageHud();
}

stock SetupHud(hudPosition pos, int flags, float xpos, float ypos, float width, float height) {
	SetupHUD(pos, flags, xpos, ypos, width, height);
}

stock PrintToHudPosition(char[] text, int pos)
{
	static char buffer[64];
	FormatEx(buffer, sizeof(buffer), text);
	hudPosition position = HUD_POSITION_MID_TOP;

	switch (pos) {
		case 1: 
			position = HUD_POSITION_FAR_RIGHT;
    	case 2:
			position = HUD_POSITION_FAR_LEFT;
    	case 3:
 			position = HUD_POSITION_MID_BOX;
    	case 4:
			position = HUD_POSITION_MID_TOP;
    	case 5:
			position = HUD_POSITION_TICKER;
    	case 6:
			position = HUD_POSITION_SCORE_TITLE;
    	case 7:
			position = HUD_POSITION_SCORE_1;    	
    	case 8:
			position = HUD_POSITION_SCORE_2;    	
    	case 9:
			position = HUD_POSITION_SCORE_3;
    	case 10:
			position = HUD_POSITION_SCORE_4;
    	case 11:
			position = HUD_POSITION_LEFT_TOP;
    	case 12:
			position = HUD_POSITION_LEFT_BOT;
    	case 13:
			position = HUD_POSITION_FAR_LEFT;
    	case 14:
			position = HUD_POSITION_MID_BOX;    	
    	default:
			position = HUD_POSITION_MID_BOT;  
    }
	
	int flags = (HUD_FLAG_ALIGN_CENTER | HUD_FLAG_COUNTDOWN_WARN | HUD_FLAG_TEAM_SURVIVORS);
	//deleteHUD(position);
	//SetupMessageHud(position, HUD_FLAG_ALIGN_CENTER | HUD_FLAG_TEAM_SURVIVORS | HUD_FLAG_COUNTDOWN_WARN);
	SetupMessageHud(position, flags);
	AddMessageToHud(buffer);

}

stock setupHUD()
{
	int flags =  HUD_FLAG_ALIGN_LEFT | HUD_FLAG_NOBG | HUD_FLAG_TEAM_SURVIVORS;

	SetupHUD(HUD_POSITION_FAR_LEFT, flags,0.0, 0.0, 1.0, 1.0);
	SetupHUD(HUD_POSITION_RIGHT_BOT, flags,0.0, 0.0, 1.0, 1.0);
	SetupHUD(HUD_POSITION_LEFT_BOT, flags,0.0, 0.0, 1.0, 1.0);
	SetupHUD(HUD_POSITION_RIGHT_TOP, HUD_FLAG_ALIGN_LEFT | HUD_FLAG_NOBG | HUD_FLAG_TEAM_SURVIVORS,0.0, 0.0, 1.0, 1.0);
	SetupHUD(HUD_POSITION_MID_BOT, HUD_FLAG_TEAM_INFECTED | HUD_FLAG_NOBG | HUD_FLAG_NOBG,0.0, 0.0, 1.0, 1.0);
	SetupHUD(HUD_POSITION_MID_BOX, HUD_FLAG_ALIGN_CENTER | HUD_FLAG_TEAM_SURVIVORS | HUD_FLAG_BEEP | HUD_FLAG_NOBG,0.0, 0.0, 1.0, 1.0);
	SetupHUD(HUD_POSITION_TICKER, HUD_FLAG_ALIGN_CENTER | HUD_FLAG_COUNTDOWN_WARN | HUD_FLAG_TEAM_SURVIVORS,0.0, 0.0, 1.0, 1.0);
	SetupHUD(HUD_POSITION_LEFT_TOP, HUD_FLAG_AS_TIME | HUD_FLAG_ALIGN_CENTER | HUD_FLAG_TEAM_SURVIVORS,0.0, 0.0, 1.0, 1.0);
	SetupHUD(HUD_POSITION_SCORE_TITLE, HUD_FLAG_ALIGN_CENTER | HUD_FLAG_NOBG | HUD_FLAG_TEAM_SURVIVORS,0.0, 0.0, 1.0, 1.0);
	SetupHUD(HUD_POSITION_SCORE_1, HUD_FLAG_ALIGN_LEFT | HUD_FLAG_NOBG | HUD_FLAG_TEAM_SURVIVORS,0.0, 0.0, 1.0, 1.0);
	SetupHUD(HUD_POSITION_SCORE_2,  HUD_FLAG_ALIGN_LEFT | HUD_FLAG_NOBG | HUD_FLAG_TEAM_SURVIVORS,0.0, 0.0, 1.0, 1.0);
	SetupHUD(HUD_POSITION_SCORE_3,  HUD_FLAG_ALIGN_LEFT | HUD_FLAG_NOBG | HUD_FLAG_TEAM_SURVIVORS,0.0, 0.0, 1.0, 1.0);
	SetupHUD(HUD_POSITION_SCORE_4,  HUD_FLAG_ALIGN_LEFT | HUD_FLAG_NOBG | HUD_FLAG_TEAM_SURVIVORS,0.0, 0.0, 1.0, 1.0);
	SetupHUD(MSG_HUD_POS, flags , 0.0, 0.0, 1.0, 1.0);
}
