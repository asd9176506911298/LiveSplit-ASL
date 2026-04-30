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

	settings.Add("RadioTower", false, "Radio Tower", "il");
	settings.Add("Temperance", false, "Temperance", "il");
	settings.Add("Utopia", false, "Utopia", "il");

	vars.TargetLookup = new Dictionary<string, HashSet<int>> {
        { "RadioTower", new HashSet<int> { 1, 2, 3, 5 } },
        { "Temperance",  new HashSet<int> { 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 73  } },
		{ "Utopia",  new HashSet<int> { 79, 80  } }
    };

    vars.Collected = new HashSet<int>();
}

init
{
	vars.JitSave = vars.Uhara.CreateTool("Unity", "DotNet", "JitSave");
	vars.Instance = vars.Uhara.CreateTool("Unity", "DotNet", "Instance");
    vars.Utils = vars.Uhara.CreateTool("Unity", "Utils");

	vars.Instance.Watch<bool>("PlayerStart", "PersonController", "completelyStarted");
	vars.Instance.Watch<bool>("PlayerMoving", "PersonController", "moving");
	vars.Instance.Watch<bool>("IsAllLandmarksLoaded", "Raft_Network", "IsAllLandmarksLoaded");
	vars.Instance.Watch<bool>("IsLoadingLobbyScene", "LoadSceneManager", "IsLoadingLobbyScene");

	byte[] AsmMovRdx = new byte[] { 0x48, 0x89, 0x15, 0xF1, 0xFF, 0xFF, 0xFF, 0x90 };

	IntPtr pPickNoteBook = vars.JitSave.Add("Assembly-CSharp", "", "Pickup", "PickupNoteBookNote", 2, 0, 16, AsmMovRdx);
	IntPtr pRelayFinish = vars.JitSave.AddFlag("NoteBook", "UnlockSpecificNoteNetworked");
	IntPtr pInteractLate = vars.JitSave.AddFlag("QuestInteractable_Cutscene", "InteractLate");

	vars.JitSave.ProcessQueue();

	vars.Resolver.Watch<IntPtr>("PickNoteBook",pPickNoteBook);
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

	current.NotebookID = game.ReadValue<int>((IntPtr)(current.PickNoteBook + 0x68));

    if ((long)current.PickNoteBook != (long)old.PickNoteBook && (long)current.PickNoteBook != 0)
    {
        // 遍歷所有設定，找出被勾選且存在於字典中的關卡
        foreach (var entry in vars.TargetLookup)
        {
            if (settings[entry.Key]) // 如果使用者勾選了該關卡 (例如 RadioTower)
            {
                if (entry.Value.Contains(current.NotebookID))
                {
                    vars.Collected.Add(current.NotebookID);
                    print("Settings [" + entry.Key + "] added ID: " + current.NotebookID);
                }
            }
        }
    }

	if(current.PickNoteBook != old.PickNoteBook)
	{
		// print("PickNoteBook: " + current.PickNoteBook.ToString("X"));
		print("PickNoteBookId: " + game.ReadValue<int>((IntPtr)(current.PickNoteBook + 0x68)).ToString());
	}

	if(current.PlayerStart != old.PlayerStart)
	{
		print("PlayerStart: " + old.PlayerStart + " - > " + current.PlayerStart);
	}

	if(!old.PlayerStart && current.PlayerStart)
	{
		vars.playerStartTime = (float)timer.CurrentTime.RealTime.Value.TotalSeconds;
	}

	// if(current.RelayFinish != old.RelayFinish)
	// {
	// 	print("RelayFinish: " + old.RelayFinish + " - > " + current.RelayFinish);
	// }

	// if(current.PickNoteBook != old.PickNoteBook)
	// {
	// 	print("PickNoteBook: " + old.PickNoteBook + " - > " + current.PickNoteBook);
	// }

	if(current.utopia != old.utopia)
	{
		print("utopia: " + old.utopia + " - > " + current.utopia);
	}

	// if(current.PlayerMoving != old.PlayerMoving)
	// {
	// 	print("PlayerMoving: " + old.PlayerMoving + " - > " + current.PlayerMoving);
	// }

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
	if (settings["il"])
    {
        foreach (var entry in vars.TargetLookup)
        {
            if (settings[entry.Key]) // 找出目前被啟用的關卡設定
            {
                // 檢查收集箱是否跟該關卡的目標完全吻合
                if (vars.Collected.SetEquals(entry.Value))
                {
                    vars.Collected.Clear(); // 成功集齊後重置
                    return true;
                }
            }
        }
    }else{
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
}

isLoading
{
    if (current.IsLoadingLobbyScene) return true;

    if (current.ActiveScene != "MainMenuScene" && !current.IsAllLandmarksLoaded) return true;

    return false;
}
