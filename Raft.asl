state ("Raft")
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
	vars.Instance.Watch<bool>("PlayerStart", "PersonController", "completelyStarted");
	vars.Instance.Watch<bool>("PlayerMoving", "PersonController", "moving");

	IntPtr pPickNoteBook = vars.JitSave.AddFlag("Pickup", "PickupNoteBookNote");
	IntPtr pRelayFinish = vars.JitSave.AddFlag("NoteBook", "UnlockSpecificNoteNetworked");

	vars.JitSave.ProcessQueue();

	vars.Resolver.Watch<int>("PickNoteBook",pPickNoteBook); // use for balboa finish will trigger triple times
	vars.Resolver.Watch<int>("RelayFinish",pRelayFinish); // use for balboa finish will trigger triple times

	vars.lastSplitRelayCount = 0;
}

start
{
    return !old.PlayerStart && current.PlayerStart;
}

update
{
    vars.Uhara.Update();
	current.ActiveScene = vars.Utils.GetActiveSceneName() ?? current.ActiveScene;
    current.LoadingScene = vars.Utils.GetLoadingSceneName() ?? current.LoadingScene;

	if(current.PlayerStart != old.PlayerStart)
	{
		print("PlayerStart: " + old.PlayerStart + " - > " + current.PlayerStart);
	}

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

	if(current.RelayFinish != old.RelayFinish)
	{
		print("RelayFinish: " + old.RelayFinish + " - > " + current.RelayFinish);
	}

	if(current.PickNoteBook != old.PickNoteBook)
	{
		print("PickNoteBook: " + old.PickNoteBook + " - > " + current.PickNoteBook);
	}

	if(current.PlayerMoving != old.PlayerMoving)
	{
		print("PlayerMoving: " + old.PlayerMoving + " - > " + current.PlayerMoving);
	}
}

split
{
    if (current.RelayFinish >= vars.lastSplitRelayCount + 3)
    {
        vars.lastSplitRelayCount = current.RelayFinish;
        return true;
    }

	if (current.PickNoteBook != old.PickNoteBook)
	{
		return true;
	}
}

// isLoading
// {
//     if (current.ActiveScene == "MainMenuScene")
//         return false;

//     if (current.LoadingScene == "MainMenuScene")
//         return true;
    
//     return current.IsLoadingScene || !current.IsGameSceneLoaded;
// }
