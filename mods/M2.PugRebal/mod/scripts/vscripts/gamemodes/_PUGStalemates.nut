untyped

global function PugRebalance_StalematesInit_sv

void function PugRebalance_StalematesInit_sv() {
    thread threaded_StalemateInit_sv()
}

struct {
    bool stalemating = false
    bool paused = false
    float elapsed = 0.0
    entity milFlag = null
    entity imcFlag = null
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

    file.milFlag = GetFlagForTeam( TEAM_MILITIA )
    file.imcFlag = GetFlagForTeam( TEAM_IMC )
    AddCallback_OnCTFFlagStateChange( StalemateDecide )
}

void function StalemateDecide(entity flag) {
    printt("decideFired")
    int team = flag.GetTeam()
    int enemyTeam = GetOtherTeam( team )
    entity enemyFlag = GetFlagForTeam( enemyTeam )

    switch (GetFlagState(flag)) {
        case eFlagState.Away: // dropped
            PauseStalemate()
        break;
        case eFlagState.Held: // held
            if (GetFlagState(enemyFlag) != eFlagState.Home) {
                PlayStalemate()
            }
        break;
        case eFlagState.Home: // reset/capped
        default:
            EndStalemate()
        break;
    }
    printt("friendlystate: " + GetFlagState(flag).tostring())
    printt("enemystate: " + GetFlagState(enemyFlag).tostring())
}

void function threaded_StalemateTimer() {
    file.imcFlag.EndSignal( "CTF_ReturnedFlag" )
	file.imcFlag.EndSignal( "OnDestroy" )
    file.milFlag.EndSignal( "CTF_ReturnedFlag" )
	file.milFlag.EndSignal( "OnDestroy" )

    float stalemate_timeout = PugRebalance_Get_Stalemate_Time()
    file.elapsed = 0
    float oldTime = Time()
    while (file.elapsed < stalemate_timeout) {
        float newTime = Time()
        float delta = newTime - oldTime
        if (!file.paused) {
            file.elapsed += delta
        }
        oldTime = newTime;
        WaitFrame()
    }
    ResetFlag( file.imcFlag )
    ResetFlag( file.milFlag )
    EndStalemate()

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