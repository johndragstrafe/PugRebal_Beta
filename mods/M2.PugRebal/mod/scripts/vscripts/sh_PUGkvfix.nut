#if CLIENT
// We need to call weapon_reparse on client (otherwise client does not reparse files).
// However, we need to make sure the server is local, so we let the server send a command to the client to trigger it.
global function PugRebalance_KVFix_ClInit
global function PugRebalance_KVFix_KeyValuesOn

void function PugRebalance_KVFix_ClInit()
{
	AddServerToClientStringCommandCallback( "pugrebalance_can_reparse", PugRebalance_KVFix_SendClientCommand )
}

void function PugRebalance_KVFix_SendClientCommand( array<string> args )
{
	thread PugRebalance_KVFix_SendClientCommandInternal()
}

void function PugRebalance_KVFix_SendClientCommandInternal()
{
	while( !GetLocalClientPlayer() || GetGameState() != eGameState.Playing )
		WaitFrame()
	thread PugRebalance_KVFix_ClRecompile( GetLocalClientPlayer() )
}

void function PugRebalance_KVFix_ClRecompile( entity player )
{
	bool keyValuesOn = PugRebalance_KVFix_KeyValuesOn()
	// unlike ltsr we dont check if the mod is enabled since kvfix is in the same mod
	// this means the kvs will stay applied even if you join a different server without the mod
	// this will break peoples games on other servers but we dont care xd. just fix the client
	if ( keyValuesOn )
		return

	if ( GetMapName() != "mp_lobby" ) {
		Chat_GameWriteLine("ALERT: Detected keyvalue mismatch, reparsing files")
		wait 1.0
		Chat_GameWriteLine("ALERT: Please wait while files load")
	}

	print( "Pug Rebalance KVFix - Attempting reparse")
	int netChanModeOriginal = GetConVarInt( "net_chan_limit_mode" )
	int svCheatsOriginal = GetConVarInt( "sv_cheats" )
	// These are server-only vars, so we have to use client command instead of SetConVar
	player.ClientCommand( "net_chan_limit_mode 0" )	// Don't want to kick the player back to main menu when recompiling
	player.ClientCommand( "sv_cheats 1" )			// Need sv_cheats to execute command
	player.ClientCommand( "weapon_reparse" )
	wait 0.1
	player.ClientCommand( "sv_cheats " + svCheatsOriginal )
	player.ClientCommand( "net_chan_limit_mode " + netChanModeOriginal )

	if ( GetMapName() != "mp_lobby" ) {
		Chat_GameWriteLine("ALERT: Success")
	}
}
#else // if SERVER
// Server runs some simple checks to run KVFix in the multiplayer lobby. This should prevent reparsing in actual matches.
// The client must be triggered by the server in this way so that the client does not attempt reparse on nonlocal servers.
// The client must also tell the server to reparse, since the server's will fail if it attempts to do so during the client's.
global function PugRebalance_KVFix_Init
global function PugRebalance_KVFix_KeyValuesOn

void function PugRebalance_KVFix_Init()
{
	AddCallback_OnClientConnected(PugRebalance_KVFix_AlertClient)
}

void function PugRebalance_KVFix_AlertClient(entity player)
{
	ServerToClientStringCommand( player, "pugrebalance_can_reparse" )
	
}
#endif

#if SERVER || CLIENT
bool function PugRebalance_KVFix_KeyValuesOn()
{
	string[2] testDummy = [ "mp_weapon_car", "base_lowttk" ] // Some weapon and an AIO mod to check if it was compiled
	return GetWeaponMods_Global( testDummy[0] ).contains( testDummy[1] )
}
#endif