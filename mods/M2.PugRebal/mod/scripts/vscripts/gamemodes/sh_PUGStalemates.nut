untyped

global function PugRebalance_StalematesGamemode
global function PugRebalance_Get_Stalemate_Time

struct {
    float stalemate_timer = 45.0
} file

void function PugRebalance_StalematesGamemode() {
    AddCallback_OnCustomGamemodesInit(AddFunc)
    AddCallback_OnRegisteringCustomNetworkVars(RegisterNetVars)
}
void function AddFunc() {
    array<string> gamemodes = [ CAPTURE_THE_FLAG, GAMEMODE_CTF_COMP ]
    foreach (string gamemode in gamemodes ) {
        GameMode_AddSharedInit( gamemode, PugRebalance_StalematesInit_sh)
        #if CLIENT
            GameMode_AddClientInit( gamemode, PugRebalance_StalematesInit_cl)
        #endif
        #if SERVER
            GameMode_AddServerInit( gamemode, PugRebalance_StalematesInit_sv)
        #endif
    }
}

void function RegisterNetVars()
{
    RegisterNetworkedVariable("Stalemates_elapsed", SNDC_GLOBAL, SNVT_TIME, 0)
    RegisterNetworkedVariable("Stalemates_stalemating", SNDC_GLOBAL, SNVT_BOOL, false)
}

void function PugRebalance_StalematesInit_sh() {
    file.stalemate_timer = GetCurrentPlaylistVarFloat( "ctf_stalemate_time", 75.0 )
}

float function PugRebalance_Get_Stalemate_Time() {
    return file.stalemate_timer
}