// This is a temp fix for some plugins that incorrectly clear the screenoverlay command.
// This is not an excuse to keep your plugins unfixed. This is a quick fix while you search and correct your plugins.

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_VERSION	"1.0"
#define PLUGIN_DESC	"Temp Solution to any bad command use of r_screenoverlay."
#define PLUGIN_NAME	"[ANY] Screen Overlay Hotfix"
#define PLUGIN_AUTH	"Glubbable"
#define PLUGIN_URL	"https://steamcommunity.com/groups/GlubsServers"

float g_flCoolDown = 0.0;

Handle g_ConVarEnable;
Handle g_ConVarDebugLevel;

Handle g_ConVarLogFile;

bool g_bEnabled;

int g_iDebugLevel = 0;

public const Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTH,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL,
}

public void OnPluginStart()
{
	g_ConVarEnable = CreateConVar("sm_enable_screenoverlay_fix", "1", "When enabled, will correct any incorrect clearing of screenoverlay.", _, true, 0.0, true, 1.0);
	g_ConVarDebugLevel = CreateConVar("sm_screenoverlay_debug_level", "1", "If above 0, will print information into logs.", _, true, 0.0, true, 2.0);

	HookConVarChange(g_ConVarEnable, Hook_ConVarChange);
	HookConVarChange(g_ConVarDebugLevel, Hook_ConVarChange);
	
	g_ConVarLogFile = FindConVar("con_logfile");

	AddCommandListener(Hook_CommandScreenOverlay, "r_screenoverlay");
	
	g_flCoolDown = GetEngineTime();
	
	EnablePlugin();
}

stock void EnablePlugin()
{
	bool bEnable = GetConVarBool(g_ConVarEnable);
	int iDebugLevel = GetConVarInt(g_ConVarDebugLevel);
	
	switch (iDebugLevel)
	{
		case 0, 1:
			g_iDebugLevel = iDebugLevel;
			
		case 2: 
		{
			char sGetDate[256];
			FormatTime(sGetDate, sizeof(sGetDate), "addons/sourcemod/logs/server-console-%Y-%m-%d.log", GetTime());
	
			SetConVarString(g_ConVarLogFile, sGetDate);
			g_iDebugLevel = iDebugLevel;
		}
	}
	
	if (bEnable)
	{
		g_bEnabled = true;
	}
	
	else
	{
		g_bEnabled = false;
	}
}

public void Hook_ConVarChange(Handle hCvar, const char[] sOldValue, const char[] sNewValue)
{
	if (hCvar == g_ConVarEnable)
	{
		bool bEnabled = view_as<bool>(StringToInt(sNewValue));
		
		if (bEnabled)
		{
			EnablePlugin();
		}
		
		else
		{
			DisablePlugin();
		}
	}
	
	else if (hCvar == g_ConVarDebugLevel)
	{
		if (!g_bEnabled) return;
		
		int iDebugLevel = StringToInt(sNewValue);
		
		if (iDebugLevel == g_iDebugLevel) return;
		
		else
		{
			switch (iDebugLevel)
			{
				case 0, 1:
				{
					if (g_iDebugLevel == 2)
						SetConVarString(g_ConVarLogFile, "");
							
					g_iDebugLevel = iDebugLevel;
				}
					
				case 2: 
				{
					char sGetDate[256];
					FormatTime(sGetDate, sizeof(sGetDate), "addons/sourcemod/logs/server-console-%Y-%m-%d.log", GetTime());
		
					SetConVarString(g_ConVarLogFile, sGetDate);
					g_iDebugLevel = iDebugLevel;
				}
			}
		}
	}
}

stock void DisablePlugin()
{
	g_bEnabled = false;
	
	if (g_iDebugLevel == 2)
		SetConVarString(g_ConVarLogFile, "");
	
	g_iDebugLevel = 0;
}

public void OnMapStart()
{
	EnablePlugin();
}

public void OnMapEnd()
{
	DisablePlugin();
}

public Action OnClientCommand(int iClient, int iArgs)
{
	if (g_bEnabled)
	{
		char sCommand[3];
		GetCmdArg(0, sCommand, sizeof(sCommand));
		
		if (strcmp(sCommand, "r_screenoverlay") == 0)
		{
			char sArg[3];
			GetCmdArg(1, sArg, sizeof(sArg));
		
			CheckScreenOverlay(iClient, sArg);
		}		
	}
}

public Action Hook_CommandScreenOverlay(int iClient, const char[] sString, int iArgs)
{
	if (g_bEnabled)
	{
		char sArg[3];
		GetCmdArg(1, sArg, sizeof(sArg));
		
		CheckScreenOverlay(iClient, sArg);
	}
}

stock void CheckScreenOverlay(int iClient, char sArg[3])
{
	if (strcmp(sArg, "0") == 0)
	{
		if (IsClientInGame(iClient))
		{
			ClientCommand(iClient, "r_screenoverlay \"\"");
			
			if (g_iDebugLevel > 0)
			{
				// Prevents possible spam if applied to multiple clients at once.
				if (g_flCoolDown <= GetEngineTime())
				{
					g_flCoolDown = GetEngineTime() + 4.0;
					
					char sCurrentMap[PLATFORM_MAX_PATH];
					GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
						
					// Prints the current map and an error log so you are aware of what map and server this is occuring on.
					LogError("[SM] A plugin has incorrectly cleared the command 'r_screenoverlay' on %s, please update it!", sCurrentMap);
					
					if (g_iDebugLevel > 1)
					{
						// We print all of the plugis that were loaded at the time into a log file.
						// I don't know of a way to determin which plugin called the command at this current time.
						ServerCommand("sm plugins list");
					}
				}
			}
		}
	}
}