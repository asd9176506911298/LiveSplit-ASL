state("Librarian-Win64-Shipping"){}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");

    settings.Add("milestones", true, "Row Milestones");

    for (int i = 1; i <= 40; i++)
    {
        settings.Add("split" + (i * 10), false, (i * 10) + " Rows", "milestones");
    }
}

init
{
    vars.Events = vars.Uhara.CreateTool("UnrealEngine", "Events");

    vars.Events.FunctionFlag("startFlag", "WBP_Title_C", "TitleUMG", "StartGame");
    vars.Events.FunctionFlag("resetFlag", "WBP_PauseMenu_C", "WBP_PauseMenu_C", "OnBackToTitleMenu");

    IntPtr playerInfoPtr = vars.Events.FunctionParentPtr("WBP_PlayerInfo_C", "WBP_PlayerInfo", "");
    // WBP_PlayerInfo -> Text_CurrentBookNum 0x3D8 -> Text 0x188 -> Pointer 0x18
    // WBP_PlayerInfo -> Text_FinishRowNum 0x3E8 -> Text 0x188 -> Pointer 0x18
    // WBP_PlayerInfo -> UTextBlock          -> FText 
    // Text_CurrentBookNum 0x3D8
    // Text_FinishRowNum 0x3E8
    // vars.Resolver.WatchString("currentBooks", playerInfoPtr, 0x3D8, 0x188, 0x18, 0x0);
    vars.Resolver.WatchString("currentRows", playerInfoPtr, 0x3E8, 0x188, 0x18, 0x0);

    var targets = new int[40];
    for (int i = 0; i < 40; i++) targets[i] = (i + 1) * 10;
    vars.SplitTargets = targets;

    vars.gameStarted = false;
}

start
{
    if (vars.Resolver.CheckFlag("startFlag"))
    {
        vars.gameStarted = true;
        return true;
    }
}

update
{
    vars.Uhara.Update();

    if((string)current.currentRows == "1" && (string)old.currentRows == "0")
    {
        // print("Start");
        vars.gameStarted = true;
    }

    // if(current.currentRows != old.currentRows && vars.gameStarted)
    // {
    //     print("currentRows: " + current.currentRows.ToString());
    // }
}

split
{
    if(!vars.gameStarted) return false;
    
    string cur  = (string)current.currentRows;
    string prev = (string)old.currentRows;

    if (cur == prev) return false;

    foreach (int t in (int[])vars.SplitTargets)
    {
        if (settings["split" + t] && cur == t.ToString()) return true;
    }
}

reset
{
    if (vars.Resolver.CheckFlag("resetFlag"))
    {
        vars.gameStarted = false;
        return true;
    }
}

onReset
{
    vars.gameStarted = false;
}
