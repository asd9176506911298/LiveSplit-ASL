state ("raft")
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


	vars.Instance.Watch<bool>("IsLoadingScene", "LoadSceneManager", "IsLoadingScene");
	vars.Instance.Watch<bool>("IsGameSceneLoaded", "LoadSceneManager", "IsGameSceneLoaded");

	IntPtr pPlayerStart = vars.JitSave.AddFlag("PersonController", "Start");

	vars.JitSave.ProcessQueue();

	vars.Resolver.Watch<int>("PlayerStart",pPlayerStart);

	vars.enteredGame = false;
}

start
{
    return current.PlayerStart != old.PlayerStart;
}

update
{
    vars.Uhara.Update();
	current.ActiveScene = vars.Utils.GetActiveSceneName() ?? current.ActiveScene;
    current.LoadingScene = vars.Utils.GetLoadingSceneName() ?? current.LoadingScene;

	if(current.IsLoadingScene != old.IsLoadingScene)
	{
		print("IsLoadingScene: " + old.IsLoadingScene + " - > " + current.IsLoadingScene);
	}

	if(current.IsGameSceneLoaded != old.IsGameSceneLoaded)
	{
		print("IsGameSceneLoaded: " + old.IsGameSceneLoaded + " - > " + current.IsGameSceneLoaded);
	}

	if(current.ActiveScene != old.ActiveScene)
	{
		print("ActiveScene: " + old.ActiveScene + " - > " + current.ActiveScene);
	}
}

isLoading
{
    if (current.ActiveScene == "MainMenuScene")
        return false;

    if (current.LoadingScene == "MainMenuScene")
        return true;
    
    return current.IsLoadingScene || !current.IsGameSceneLoaded;
}
