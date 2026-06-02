untyped

global function PugRebalance_StalematesInit_sv

void function PugRebalance_StalematesInit_sv() {
    //Chat_ServerBroadcast("i love spamming other peoples servers with chat messages when i have a good reason")
    thread threaded_StalemateInit_sv()
}

struct {
    bool stalemating = false
    bool paused = false
    float elapsed = 0.0
} file

void function threaded_NetVarsXD() {
    while (true) {
        SetGlobalNetTime("Stalemates_elapsed", file.elapsed);
        SetGlobalNetBool("Stalemates_stalemating", file.stalemating);
        WaitFrame()
    }
}

void function threaded_StalemateInit_sv() {
    while (
        !GameHasFlags()
        || !(TEAM_MILITIA in level.teamFlags)
        || !(TEAM_IMC in level.teamFlags)
    ) {
        WaitFrame()
    }
    thread threaded_NetVarsXD()
    AddCallback_OnCTFFlagStateChange( StalemateDecide )
}

void function StalemateDecide(entity flag) {
    //Chat_ServerBroadcast("state changed")
    int team = flag.GetTeam()
    int enemyTeam = GetOtherTeam( team )
    entity enemyFlag = GetFlagForTeam( enemyTeam )

    switch (GetFlagState(flag)) {
        case eFlagState.Away: // dropped
            PauseStalemate()
        break;
        case eFlagState.Held: // held
            if (!IsFlagHome(enemyFlag)) {
                PlayStalemate()
            }
        break;
        case eFlagState.Home: // reset/capped
        default:
            EndStalemate()
        break;
    }
    //Chat_ServerBroadcast(team.tostring() + " friendlystate: " + GetFlagState(flag).tostring())
    //Chat_ServerBroadcast(enemyTeam.tostring() + " enemystate: " + GetFlagState(enemyFlag).tostring())
}

void function threaded_StalemateTimer() {

	GetFlagForTeam( TEAM_MILITIA ).EndSignal( "OnDestroy" )
	GetFlagForTeam( TEAM_IMC ).EndSignal( "OnDestroy" )

    OnThreadEnd(
	function() : ( )
		{
            if (file.stalemating) {
                ResetFlag( GetFlagForTeam( TEAM_MILITIA ) )
                ResetFlag( GetFlagForTeam( TEAM_IMC ) )
            }
            EndStalemate()
		}
	)

    float stalemate_timeout = PugRebalance_Get_Stalemate_Time()
    file.elapsed = 0
    float oldTime = Time()
    while (file.elapsed < stalemate_timeout && file.stalemating) {
        float newTime = Time()
        float delta = newTime - oldTime
        if (!file.paused) {
            file.elapsed += delta
        }
        oldTime = newTime;
        WaitFrame()
    }

}

void function PlayStalemate() {
    if (file.stalemating && file.paused) { // resume
        file.paused = false
    }
    else if (!file.stalemating) { // begin
        file.stalemating = true;
        file.paused = false;
        file.elapsed = 0
        thread threaded_StalemateTimer()
    }
}

void function PauseStalemate() {
    if (!file.stalemating || file.paused) { return }

    file.paused = true
}

void function EndStalemate() {
    if (!file.stalemating) { return }

    file.stalemating = false;
    file.paused = false;
}