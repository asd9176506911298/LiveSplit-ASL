state("Gnomium") {}


startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
}

init
{   
    vars.Instance = vars.Uhara.CreateTool("Unity", "DotNet", "Instance");
    vars.JitSave = vars.Uhara.CreateTool("Unity", "DotNet", "JitSave");
    vars.Utils = vars.Uhara.CreateTool("Unity", "Utils");

    IntPtr pGameStart = vars.JitSave.AddFlag("PlayerController", "Instance_onGameStarted");

    vars.JitSave.ProcessQueue();

    vars.Resolver.Watch<int>("gameStart", pGameStart);
}

update
{
    vars.Uhara.Update();
    current.activeScene = vars.Utils.GetActiveSceneName() ?? current.activeScene;

    if(current.activeScene != old.activeScene)
    {
        vars.Uhara.Log("old.activeScene: " + old.activeScene + " - > current.activeScene: " + current.activeScene);
    }
}

start
{
     if (current.gameStart != old.gameStart)
    {
        vars.Uhara.Log("Game Start");
        return true;
    }
}

reset
{
    if(old.activeScene != "MainMenu" && current.activeScene == "MainMenu")
    {
        vars.Uhara.Log("Reset");
        return true;
    }
}
