state ("Raft")
{
}

startup 
{
	Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
    vars.Uhara.AlertLoadless();

	settings.Add("runType", true, "Run Type");

    settings.Add("fullGame", true, "Full Game (Start on load)", "runType");
    settings.SetToolTip("fullGame", "Starts when player loads into world");

    settings.Add("il", false, "Individual Level (Start on movement)", "runType");
    settings.SetToolTip("il", "Starts on first detected movement (no filtering)");
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
	vars.Instance.Watch<float>("TimePlayed", "GameManager", "TimePlayed");

	IntPtr pPickNoteBook = vars.JitSave.AddFlag("Pickup", "PickupNoteBookNote");
	IntPtr pRelayFinish = vars.JitSave.AddFlag("NoteBook", "UnlockSpecificNoteNetworked");

	vars.JitSave.ProcessQueue();

	vars.Resolver.Watch<int>("PickNoteBook",pPickNoteBook);
	vars.Resolver.Watch<int>("RelayFinish",pRelayFinish); // use for balboa finish will trigger triple times

	vars.lastSplitRelayCount = 0;
	vars.playerStartTime = 0.0;
}

start
{
     // Prevent invalid dual-selection
    if (settings["fullGame"] == settings["il"])
        return false;

    // FULL GAME START
    if (settings["fullGame"])
    {
        return current.PlayerStart != old.PlayerStart;
    }

    // IL START
    if (settings["il"])
    {
        return !old.PlayerMoving && current.PlayerMoving;
    }

    return false;
}

update
{
    vars.Uhara.Update();
	current.ActiveScene = vars.Utils.GetActiveSceneName() ?? current.ActiveScene;
    current.LoadingScene = vars.Utils.GetLoadingSceneName() ?? current.LoadingScene;

	if(current.PlayerStart != old.PlayerStart)
	{
		print("PlayerStart: " + old.PlayerStart + " - > " + current.PlayerStart);
		vars.playerStartTime = (float)timer.CurrentTime.RealTime.Value.TotalSeconds;
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

	// if(current.PlayerMoving != old.PlayerMoving)
	// {
	// 	print("PlayerMoving: " + old.PlayerMoving + " - > " + current.PlayerMoving);
	// }


	// if(current.TimePlayed != old.TimePlayed)
	// {
	// 	print("TimePlayed: " + old.TimePlayed + " - > " + current.TimePlayed);
	// }
}

onReset
{
	vars.lastSplitRelayCount = 0;
}

split
{
    float now = (float)timer.CurrentTime.RealTime.Value.TotalSeconds;
    float elapsed = now - vars.playerStartTime;

    if (elapsed <= 10.0f)
    {
        vars.lastSplitRelayCount = current.RelayFinish;
        return false;
    }

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
