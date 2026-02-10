state("MrShifty") { }

startup 
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "MrShifty";
    vars.hasLevelLoaded = false;
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        vars.Helper["stageName"] = mono.MakeString("Game", 1, "_instance", "m_levelManager","m_currentStage","m_id");
        vars.Helper["LevelScenePath"] = mono.MakeString("Game", 1, "_instance", "m_levelManager","m_currentLevelScenePath");
        vars.Helper["loading"] = mono.Make<bool>("Game", 1, "_instance", "m_levelManager","m_isInitialisingLevel");
        vars.Helper["loading2"] = mono.Make<bool>("Game", 1, "_instance", "m_levelManager","m_loadingStage");
        vars.Helper["loading3"] = mono.Make<bool>("Game", 1, "_instance", "m_levelManager","m_sceneLoading");
        vars.Helper["dead"] = mono.Make<bool>("Player", "m_dead");
        return true;
    });
    vars.hasLevelLoaded = false;
}

update
{
    if(current.loading != old.loading){
        print("Loading1: " + current.loading.ToString());
    }

    if(current.loading2 != old.loading2){
        print("Loading2: " + current.loading2.ToString());
    }

    if(current.loading3 != old.loading3){
        print("Loading3: " + current.loading3.ToString());
    }

    if(current.stageName != old.stageName){
        print("stageName: " + current.stageName.ToString());
    }

    if(current.dead != old.dead){
        print("dead: " + current.dead.ToString());
    }

    if(current.LevelScenePath != old.LevelScenePath){
        print("LevelScenePath: " + current.LevelScenePath.ToString());
    }

    // Set flag when LevelScenePath becomes S1Level1
    if(current.LevelScenePath == "S1Level1" && old.LevelScenePath != "S1Level1")
    {
        vars.hasLevelLoaded = true;
        print("S1Level1 flag set");
    }
    
    // Reset flag when leaving S1Level1
    if(current.LevelScenePath != "S1Level1")
    {
        vars.hasLevelLoaded = false;
    }
}

start
{
    // Start timer when S1Level1 is fully loaded and all loading flags are done
    if(vars.hasLevelLoaded &&
       !current.loading && 
       !current.loading2 && 
       !current.loading3)
    {
        print("Start triggered!");
        vars.hasLevelLoaded = false;  // Reset to prevent duplicate trigger
        return true;
    }
    return false;
}

split
{
    // Split when stage name changes, ignore empty strings to avoid false triggers
    if(current.stageName != old.stageName && 
       !string.IsNullOrEmpty(current.stageName) &&
       !string.IsNullOrEmpty(old.stageName))
    {
        print("Split triggered: Stage changed from \"" + old.stageName + "\" to \"" + current.stageName + "\"");
        return true;
    }
    
    return false;
}

isLoading
{
    // Do not pause timer while player is dead
    if(current.dead)
        return false;

    // Pause timer during any loading state
    return current.loading || current.loading2 || current.loading3;
}