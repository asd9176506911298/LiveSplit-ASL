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

	vars.Instance.Watch<bool>("PlayerStart", "PersonController", "completelyStarted");
	vars.Instance.Watch<bool>("PlayerMoving", "PersonController", "moving");
	vars.Instance.Watch<bool>("IsLoadingScene", "LoadSceneManager", "IsLoadingScene");
	vars.Instance.Watch<bool>("IsAllLandmarksLoaded", "Raft_Network", "IsAllLandmarksLoaded");
	vars.Instance.Watch<bool>("IsLoadingLobbyScene", "LoadSceneManager", "IsLoadingLobbyScene");

	IntPtr pPickNoteBook = vars.JitSave.AddFlag("Pickup", "PickupNoteBookNote");
	IntPtr pRelayFinish = vars.JitSave.AddFlag("NoteBook", "UnlockSpecificNoteNetworked");
	IntPtr pInteractLate = vars.JitSave.AddFlag("QuestInteractable_Cutscene", "InteractLate");

	vars.JitSave.ProcessQueue();

	vars.Resolver.Watch<int>("PickNoteBook",pPickNoteBook);
	vars.Resolver.Watch<int>("RelayFinish",pRelayFinish); // use for balboa finish will trigger triple times
	vars.Resolver.Watch<int>("utopia",pInteractLate);

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
        return !old.PlayerStart && current.PlayerStart;
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
	}

	if(!old.PlayerStart && current.PlayerStart)
	{
		vars.playerStartTime = (float)timer.CurrentTime.RealTime.Value.TotalSeconds;
	}

	if(current.RelayFinish != old.RelayFinish)
	{
		print("RelayFinish: " + old.RelayFinish + " - > " + current.RelayFinish);
	}

	if(current.PickNoteBook != old.PickNoteBook)
	{
		print("PickNoteBook: " + old.PickNoteBook + " - > " + current.PickNoteBook);
	}

	if(current.utopia != old.utopia)
	{
		print("utopia: " + old.utopia + " - > " + current.utopia);
	}

	// if(current.PlayerMoving != old.PlayerMoving)
	// {
	// 	print("PlayerMoving: " + old.PlayerMoving + " - > " + current.PlayerMoving);
	// }

	if(current.IsLoadingScene != old.IsLoadingScene)
    	print("IsLoadingScene: " + old.IsLoadingScene + " - > " + current.IsLoadingScene);
	if(current.IsAllLandmarksLoaded != old.IsAllLandmarksLoaded)
    	print("IsAllLandmarksLoaded: " + old.IsAllLandmarksLoaded + " - > " + current.IsAllLandmarksLoaded);
	if(current.IsLoadingLobbyScene != old.IsLoadingLobbyScene)
    	print("IsLoadingLobbyScene: " + old.IsLoadingLobbyScene + " - > " + current.IsLoadingLobbyScene);
}

onReset
{
    vars.lastSplitRelayCount = 0;
}

split
{
    float now = (float)timer.CurrentTime.RealTime.Value.TotalSeconds;
    float elapsed = now - (float)vars.playerStartTime;

    if (elapsed > 20.0f && current.RelayFinish >= vars.lastSplitRelayCount + 3)
    {
        vars.lastSplitRelayCount = current.RelayFinish;
        return true;
    }

    if (elapsed <= 20.0f)
    {
        vars.lastSplitRelayCount = current.RelayFinish;
    }

    if (current.PickNoteBook != old.PickNoteBook)
    {
        return true;
    }

    if (current.utopia != old.utopia)
    {
        return true;
    }
}

isLoading
{
    if (current.IsLoadingScene || current.IsLoadingLobbyScene) return true;

    if (current.ActiveScene != "MainMenuScene" && !current.IsAllLandmarksLoaded) return true;

    return false;
}
