untyped

global function PugRebalance_StalematesInit_cl

struct
{
	var rui = null
    float duration = 45.0
} timer

void function PugRebalance_StalematesInit_cl() {
    timer.duration = PugRebalance_Get_Stalemate_Time()
    AddCallback_GameStateEnter( eGameState.Playing, startRui)
}

void function startRui() {
    thread threaded_ruiThink()
}

void function threaded_ruiThink() {
    while (true) {
        bool stalemating = GetGlobalNetBool("Stalemates_stalemating");
        
        if (stalemating != (timer.rui != null)) {
            if (stalemating) StartTimer()
            else EndTimer()
        }

        if (timer.rui != null) {
            //RuiTrackGameTime doesnt work with netvars ?? most cancer solution ever
            float startTime = Time() - GetGlobalNetTime("Stalemates_elapsed");
            RuiSetGameTime(timer.rui, "startTime", startTime)
            RuiSetGameTime(timer.rui, "endTime", startTime + timer.duration)
        }
        WaitFrame();
    }
}
void function StartTimer() {
    if (timer.rui != null) {
        RuiDestroyIfAlive( timer.rui )
    }
    timer.rui = CreateCockpitRui( $"ui/circle_timer.rpak", 250) 
    RuiSetString(timer.rui, "messageText", "Stalemate")
    //RuiSetImage(timer.rui, "imageName", $"")
    RuiSetColorAlpha(timer.rui, "imageColor", <1, 1, 0>, 0.5)
    RuiSetGameTime(timer.rui, "startTime", Time())
    RuiSetGameTime(timer.rui, "endTime", Time() + timer.duration)
}

void function EndTimer() {
    if (timer.rui == null) {
        return
    }
    RuiDestroyIfAlive( timer.rui )
    timer.rui = null
}