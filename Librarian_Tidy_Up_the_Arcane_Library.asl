state("Librarian-Win64-Shipping"){}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
    vars.Uhara.AlertLoadless();


    settings.Add("milestones", true, "Row Milestones");


    for (int i = 1; i <= 9; i++)
    {
        settings.Add("split" + i, false, i + " Rows", "milestones");
    }
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

    IntPtr GameModePtr = vars.Events.FunctionParentPtr("BP_LibrarianGameMode_C", "BP_LibrarianGameMode_C", "");

    // LibrarianGameMode_C 
    //   0x3F8 UGameManager GameManager
    //     0x30 int InsertedBookNum
    //     0x34 int CurrentFinishedRowNum
    //     0x38 int MaxFinishedRowNum
    //     0x3C float TotalPlayTime

    vars.Resolver.Watch<int>("MaxFinishedRowNum", GameModePtr, 0x3F8, 0x38);
    vars.Resolver.Watch<float>("TotalPlayTime", GameModePtr, 0x3F8, 0x3C);

    var targets = new int[49];
    for (int i = 0; i < 9; i++) targets[i] = i + 1;        // targets[0~8] = 1~9
    for (int i = 0; i < 40; i++) targets[9 + i] = (i + 1) * 10;  // targets[9~48] = 10~400
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

    // if(current.MaxFinishedRowNum != old.MaxFinishedRowNum)
    // {
    //     print("old MaxFinishedRowNum: " + old.MaxFinishedRowNum + " new MaxFinishedRowNum: " + current.MaxFinishedRowNum);
    // }
}   

split
{
    if(!vars.gameStarted) return false;
    
    if (current.MaxFinishedRowNum == old.MaxFinishedRowNum) return false;

    foreach (int t in (int[])vars.SplitTargets)
    {
        if (settings["split" + t] && current.MaxFinishedRowNum == t) return true;
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

isLoading
{
    return true;
}

gameTime
{
    if (!vars.gameStarted) return null;
    return TimeSpan.FromSeconds(current.TotalPlayTime);
}
