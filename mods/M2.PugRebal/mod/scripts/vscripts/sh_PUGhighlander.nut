untyped
global function PugRebalance_Highlander_Init
// TODO: sfx, ui, clean up weapon names, show msg on titan loadout swap

void function PugRebalance_Highlander_Init() {
    if (GetCurrentPlaylistVarInt("pugs_highlander", 0)) {
        #if SERVER
            AddCallback_OnPlayerGetsNewPilotLoadout( ValidateLoadout )
        #endif
    }
}

#if SERVER
struct {
    array<string> highlander_exemptions = [
        "mp_weapon_thermite_grenade"
    ]
} file

void function ValidateLoadout( entity player, PilotLoadoutDef loadout ) {
    int team = player.GetTeam()

    table< string, array<entity> > conflicts

    foreach (entity ally in GetPlayerArrayOfTeam_Alive( team )) {
        //PilotLoadoutDef allyLoadout = GetActivePilotLoadout( ally )
        //if (player == ally) continue
        array<string> matches = CompareLoadouts(player, ally, loadout)
        foreach (string match in matches) {
            if (!(match in conflicts)) {
                conflicts[match] <- []
            }
            conflicts[match].append(ally)
        }
    }

    foreach (string conflict, array<entity> players in conflicts) {
        string red = "\x1b[31m"
        string reset = "\x1b[0m"
        string msg = red + "Highlander: " + reset + conflict + " already in use by: "
        foreach (entity player in players) {
            msg += player.GetPlayerName() + ", "
        }
        Chat_ServerPrivateMessage(player, msg, false, true)
    }
}

array<string> function CompareLoadouts( entity a, entity b, PilotLoadoutDef a_newLoadout) {
    array<string> matches = []

    TitanLoadoutDef aT = GetActiveTitanLoadout(a)
    PilotLoadoutDef aP = a_newLoadout //GetActivePilotLoadout(a) // GetActiveLoadout gets the persisted loadout, not the new one. have to send in from the callback hahahaha

    TitanLoadoutDef bT = GetActiveTitanLoadout(a)
    PilotLoadoutDef bP = GetActivePilotLoadout(a)

    if (aT.titanClass == bT.titanClass && file.highlander_exemptions.find(aT.titanClass) < 0) {
        matches.append(aT.titanClass)
    }
    if (aP.ordnance == bP.ordnance && file.highlander_exemptions.find(aP.ordnance) < 0) {
        matches.append(aP.ordnance)
    }
    
    return matches
}
#endif