state("Inari") { }

startup 
{
    // Load external helper components
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
    
    vars.Helper.LoadSceneManager = true;
    vars.Uhara.AlertLoadless(); // Prompt user to switch LiveSplit to "Game Time"

    // Settings Configuration
    settings.Add("NoLoadingTime", false, "Remove Loading Times (Loadless Mode)");
    
    settings.Add("splitList", true, "Split on");

    settings.Add("Elevator_Outskirts", false, "Elevator Outskirts", "splitList");
    settings.Add("Elevator_Citadel", false, "Elevator Citadel", "splitList");
    settings.Add("Elevator_Lower_Citadel", false, "Elevator Lower Citadel", "splitList");
    settings.Add("KamuraStart", false, "Kamura Start", "splitList");
    settings.Add("KamuraDead", false, "Kamura Dead", "splitList");

    settings.Add("BossPractice", true, "BossPractice");

    settings.Add("PracticeKamuraStart", false, "Kamura Start", "BossPractice");
    settings.Add("PracticeKamuraDead", false, "Kamura Dead", "BossPractice");
}

init
{
    var Instance = vars.Uhara.CreateTool("Unity", "DotNet", "Instance");
    vars.JitSave = vars.Uhara.CreateTool("Unity", "DotNet", "JitSave");

    // --- Core State Monitoring ---
    Instance.Watch<int>("PlayMode", "GameManager", "PlayMode");
    Instance.Watch<bool>("isInputable","GameManager", "playerStateMachine", "inputController","isInputable");
    Instance.Watch<int>("PlayerState", "GameManager", "playerStateMachine", "currentStateType");
    Instance.Watch<bool>("IsLoadingScene", "GameManager", "SceneTranslationManager", "IsLoadingScene");
    Instance.Watch<float>("BossLife", "BossBlackboard", "bossRunTimeData", "CurrentHp");

    // --- Timeline & Scene Info (Deep Pointers) ---
    // Accessing the Director's current time for cutscene-based splits
    var TTime = Instance.Get("GameManager", "CurrentGameSequenceManager", "currentSceneRoot", "ModulePlayer", "director", "0x10", "0x98", "0x28", "0x60");
    vars.Resolver.Watch<double>("DirectorTime", TTime.Base, TTime.Offsets);

    // Current Scene Name String
    var ptr_SceneName = Instance.Get("GameManager", "DataManager", "OutGameData", "CurrentSceneName", "0x14");
    vars.Resolver.WatchString("CurrentSceneName", ptr_SceneName.Base, ptr_SceneName.Offsets);

    // Scene GUID for accurate location tracking
    var ptr_SceneGuid = Instance.Get("GameManager", "CurrentGameSequenceManager", "currentSceneRoot", "SceneReferenceData", "SceneReference", "guid", "0x14");
    vars.Resolver.WatchString("ScreenRootSceneGuid", ptr_SceneGuid.Base, ptr_SceneGuid.Offsets);

    // --- JIT Event Flags (Boss Logic) ---
    IntPtr BossStartPtr = vars.JitSave.AddFlag("BossBlackboard", "OnTimelineComplete");
    IntPtr BossDeadPtr = vars.JitSave.AddFlag("BossBlackboard", "OnDead");
    
    vars.Resolver.Watch<int>("BossStartCount", BossStartPtr);
    vars.Resolver.Watch<int>("BossDeadCount", BossDeadPtr);

    vars.JitSave.ProcessQueue();
}

update
{
    // Required update for the Uhara toolset
    vars.Uhara.Update();

    if(current.CurrentSceneName != old.CurrentSceneName)
    {
        print("CurrentSceneName changed: " + old.CurrentSceneName + " -> " + current.CurrentSceneName);
    }

    if(current.IsLoadingScene != old.IsLoadingScene)
    {
        print("IsLoadingScene changed: " + old.IsLoadingScene + " -> " + current.IsLoadingScene);
    }

    if(current.BossStartCount != old.BossStartCount)
    {
        print("BossStart changed: " + old.BossStartCount + " -> " + current.BossStartCount);
    }
}

start
{
    vars.hasBossStarted = false;

    // 1. Regular Run Start Logic: Start when input is enabled in TenshinLand
    if (current.CurrentSceneName == "TenshinLand")
    {
        if (old.isInputable == false && current.isInputable == true)
        {
            return true;
        }
    }

    // 2. Boss Practice Start Logic: Start when Kamura Boss timeline finishes
    if (settings["PracticeKamuraStart"])
    {
        if (current.BossStartCount > old.BossStartCount && current.BossLife > 0)
        {
            return true;
        }
    }
}

split
{
    if (string.IsNullOrEmpty(current.CurrentSceneName)) return false;

    // --- Final Cutscene Split ---
    // Triggers when the specific cutscene reaches the end timestamp
    if (current.CurrentSceneName == "Cutscene_DemoEnd" && old.CurrentSceneName == "Cutscene_DemoEnd") 
    {
        if (old.DirectorTime < 73.95 && current.DirectorTime >= 73.95) return true;
    }

    // --- Regular Boss Splits ---
    // Standard boss start trigger (requires BossLife to be active)
    if (settings["KamuraStart"] && current.BossStartCount > old.BossStartCount && current.BossLife > 0 && !vars.hasBossStarted)
    {
        vars.hasBossStarted = true;
        return true;
    }

    // Standard boss death trigger
    if (settings["KamuraDead"] && current.BossDeadCount > old.BossDeadCount)
    {
        return true;
    }

    // --- Practice Mode Boss Split ---
    // Independent trigger for practice sessions
    if (settings["PracticeKamuraDead"] && current.BossDeadCount > old.BossDeadCount)
    {
        return true;
    }

    // --- Elevator / Scene Change Splits ---
    // Triggers only on the frame the scene changes
    if (current.CurrentSceneName != old.CurrentSceneName)
    {
        // Outskirts
        if (settings["Elevator_Outskirts"] && current.CurrentSceneName == "Scene_GameDesign_STG2_ART") 
            return true;

        // Citadel
        if (settings["Elevator_Citadel"] && current.CurrentSceneName == "Scene_GameDesign_STG6_ART") 
            return true;

        // Lower Citadel
        if (settings["Elevator_Lower_Citadel"] && current.CurrentSceneName == "Scene_GameDesign_STG9_ART") 
            return true;
    }
}

isLoading
{
    // Return true to pause the timer when the game is loading.
    // Logic: (Feature enabled by user) AND (Game reports it is loading)
    return settings["NoLoadingTime"] && current.IsLoadingScene;
}

reset
{
    // Check if the practice mode flags are enabled in the settings.
    // This prevents the timer from resetting accidentally during a full run.
    bool isPracticeMode = settings["PracticeKamuraStart"] || settings["PracticeKamuraDead"];

    // Trigger reset only if in Practice Mode and the player's state transitions to Dead (18).
    // Edge detection (old != 18) ensures the reset triggers only at the exact moment of death.
    if (isPracticeMode && old.PlayerState != 18 && current.PlayerState == 18)
    {
        return true;
    }

    return false;
}