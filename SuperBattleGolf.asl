state("Super Battle Golf") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
    vars.Uhara.AlertLoadless();
}

init
{   
    vars.Instance = vars.Uhara.CreateTool("Unity", "DotNet", "Instance");
    vars.JitSave = vars.Uhara.CreateTool("Unity", "DotNet", "JitSave");
    vars.Utils = vars.Uhara.CreateTool("Unity", "Utils");

    vars.JitSave.SetOuter("GameAssembly.dll", "");

    IntPtr hBallDispenser = vars.JitSave.AddFlag("BallDispenser", "LocalPlayerInteract");
    IntPtr hGolfHole      = vars.JitSave.AddFlag("GolfHole", "ServerOnBallScored");
    IntPtr hCancelMatch   = vars.JitSave.AddFlag("CourseManager", "EndCourse");
    IntPtr hStartMatch    = vars.JitSave.AddFlag("MatchSetupMenu", "StartOrCancelMatch");

    vars.JitSave.ProcessQueue();

    vars.Resolver.Watch<int>("ballDispensed", hBallDispenser);
    vars.Resolver.Watch<int>("ballHoled",     hGolfHole);
    vars.Resolver.Watch<int>("cancelReset",   hCancelMatch);
    vars.Resolver.Watch<int>("startReset",    hStartMatch);

    vars.Instance.Watch<bool>("isExitingToMainMenu", "GameAssembly::GameManager", "isExitingToMainMenu");
    vars.Instance.Watch<bool>("isChangingScene", "GameAssembly::BNetworkManager", "isChangingScene");
    vars.Instance.Watch<int>("MatchState", "GameAssembly::CourseManager", "matchState");
}

update
{
    vars.Uhara.Update();
    current.activeScene = vars.Utils.GetActiveSceneName() ?? current.activeScene;

    // if (current.activeScene != old.activeScene)
    // {
    //     vars.Uhara.Log("Scene changed: " + current.activeScene);
    // }
}

start
{
    if (current.activeScene == "Driving range")
        return current.ballDispensed != old.ballDispensed;

    return old.MatchState != 3 && current.MatchState == 3;
}

split
{
    return current.ballHoled != old.ballHoled;
}

reset
{
    if (timer.CurrentPhase != TimerPhase.Running) return false;

    if (current.ballDispensed != old.ballDispensed)
    {
        // vars.Uhara.Log("Reset: Driving range ball dispensed");
        return true;
    }

    if (current.isExitingToMainMenu && current.isExitingToMainMenu != old.isExitingToMainMenu)
    {
        // vars.Uhara.Log("Reset: Exit to main menu");
        return true;
    }

    if (current.cancelReset != old.cancelReset)
    {
        // vars.Uhara.Log("Reset: Cancel match");
        return true;
    }

    if (current.activeScene == "Driving range" && current.startReset != old.startReset)
    {
        // vars.Uhara.Log("Reset: Start match (driving range scene)");
        return true;
    }

    return false;
}

isLoading
{
    // Pause the Game Time timer during scene transitions
    return current.isChangingScene;
}
