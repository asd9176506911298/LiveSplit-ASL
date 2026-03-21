state("Game")
{
    string64 mapName: "Game.exe", 0x53EF78, 0x84, 0x0;
    byte startFlag: "Game.exe", 0x53EF7C, 0x29;
    float loadTimer: "Game.exe", 0x53EF78, 0x8;
    float startTimer: "Game.exe", 0x53EF7C, 0x2C; 
    byte winFlag: "Game.exe", 0x53EF6C, 0x5A4;
}

startup
{
    settings.Add("FinaleSplit", false, "Only Split On Finale");
}

update
{
    if(current.startFlag != old.startFlag)
    {
        print("Flag: " + old.startFlag + " -> " + current.startFlag);
    }
}

start
{
    if (old.startFlag == 1 && current.startFlag == 0)
    {
        print(">>> START! <<<");
        return true;
    }
}

split
{
    if (old.winFlag == 0 && current.winFlag == 1)
    {
        // If the setting is ON, we ONLY split if we are on the Finale map
        if (settings["FinaleSplit"])
        {
            return current.mapName == "Data/Maps/Finale.eem";
        }

        // If the setting is OFF, we split on every winFlag transition (any map)
        return true;
    }
}

isLoading
{
    // 第一關（未 Split 過）用 startTimer，之後用 loadTimer
    if (timer.CurrentSplitIndex == 0)
    {
        return current.startTimer > 0.0;
    }
    else
    {
        return current.loadTimer > 0.0;
    }
}
