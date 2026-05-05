state ("Gamble With Your Friends")
{
}

startup 
{
	Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
    vars.Uhara.AlertLoadless();
}

init
{
    vars.JitSave = vars.Uhara.CreateTool("Unity", "DotNet", "JitSave");
    vars.Instance = vars.Uhara.CreateTool("Unity", "DotNet", "Instance");
    vars.Utils = vars.Uhara.CreateTool("Unity", "Utils");

    vars.Instance.Watch<bool>("isTransitioning", "GameManager", "_isTransitioning");

    IntPtr pStart = vars.JitSave.AddFlag("SpawnBoxPlayerRagdollTrigger", "EnableLidColliders");
    IntPtr pLimo = vars.JitSave.AddFlag("DaySummaryUI", "Show");
    IntPtr pEndingPay = vars.JitSave.AddFlag("WinSceneManager", "ServerInitializePayDebt");

    vars.JitSave.ProcessQueue();

    vars.Resolver.Watch<int>("breakBox",pStart);
    vars.Resolver.Watch<int>("limo",pLimo);
    vars.Resolver.Watch<int>("endingPay",pEndingPay);
}

start
{
    return old.breakBox != current.breakBox;
}

split
{
    if(current.limo != old.limo)
        return true;

    if(current.endingPay != old.endingPay)
        return true;
}

update
{
    vars.Uhara.Update();

    current.ActiveScene = vars.Utils.GetActiveSceneName() ?? current.ActiveScene;
    current.LoadingScene = vars.Utils.GetLoadingSceneName() ?? current.LoadingScene;

    if(current.ActiveScene != old.ActiveScene)
    {
        print("old.ActiveScene: " + old.ActiveScene + " - > current.ActiveScene: " + current.ActiveScene);
    }
    
    if(current.LoadingScene != old.LoadingScene)
    {
        print("old.LoadingScene: " + old.LoadingScene + " - > current.LoadingScene: " + current.LoadingScene);
    }

    if(current.isTransitioning != old.isTransitioning)
    {
        print("old.isTransitioning: " + old.isTransitioning + " - > current.isTransitioning: " + current.isTransitioning);
    }
}

reset
{
    if(old.ActiveScene != "MainMenuScene" && current.ActiveScene == "MainMenuScene")
    {
        print("Reset");
        return true;
    }
}

isLoading
{
    return current.isTransitioning;
}
