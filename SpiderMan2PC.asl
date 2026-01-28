state("Webhead")
{
    // Loading state: 1 = Loading, 0 = In-Game
    byte isLoadingEngine : "Engine.dll", 0x5F5908, 0x0;

    // Current map file name
    string64 mapName : "Engine.dll", 0x5EBCA0, 0x34, 0x14C, 0x0;
}

startup
{
    refreshRate = 60;
}

init
{
    print("--- Spider-Man 2 ASL Script Initialized ---");
}

start
{
    string cur = (current.mapName ?? "").Trim().ToLower();
    string oldM = (old.mapName ?? "").Trim().ToLower();

    // TRIGGER START: When map changes from startup to cb3_citystreet
    // This is the most reliable way to start when clicking 'New Game'
    if (oldM.Contains("startup") && cur.Contains("cb3_citystreet"))
    {
        print("--- Start Triggered: Map changed from startup to " + cur + " ---");
        return true;
    }
}

split
{
    // Only split if the timer is already running
    if (timer.CurrentPhase != TimerPhase.Running) return false;

    string cur = (current.mapName ?? "").Trim().ToLower();
    string oldM = (old.mapName ?? "").Trim().ToLower();

    if (string.IsNullOrEmpty(cur) || string.IsNullOrEmpty(oldM)) return false;

    // TRIGGER SPLIT: Whenever the map name changes
    // EXCEPT:
    // 1. When entering the first level (that's the Start)
    // 2. When going back to startup/main menu
    if (cur != oldM)
    {
        if (!cur.Contains("cb3_citystreet") && !cur.Contains("startup"))
        {
            print("--- Split Triggered: Map changed from " + oldM + " to " + cur + " ---");
            return true;
        }
    }
}

isLoading
{
    // Pauses Game Time when isLoadingEngine is 1
    return current.isLoadingEngine == 1;
}

update
{
    // Debug log to monitor map and loading transitions
    if (current.mapName != old.mapName)
    {
        print("Map Change: [" + old.mapName + "] -> [" + current.mapName + "] | Loading State: " + current.isLoadingEngine);
    }
}
