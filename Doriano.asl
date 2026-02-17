state("Doriano")
{
    
}

startup 
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
    vars.Uhara.AlertLoadless();
}

init
{
    var Instance = vars.Uhara.CreateTool("Unity", "DotNet", "Instance");
    vars.Utils = vars.Uhara.CreateTool("Unity", "Utils");

    Instance.Watch<IntPtr>("PlayState", "ExternalCutsceneManager","endingDirector","0x10","0x88"); // m_CachedPtr -> m_Graph when play will not null
    Instance.Watch<int>("collectedNum", "GameManager","currentGameManager","collectedItems","0x18"); // collectedItems->Size
}

update
{
    vars.Uhara.Update();
    
    current.activeScene = vars.Utils.GetActiveSceneName() ?? current.activeScene;
}

start
{
    return old.activeScene != "World1" && current.activeScene == "World1";
}

split
{
    if (current.collectedNum > old.collectedNum) {
        print("Item Add from " + old.collectedNum + " to " + current.collectedNum);
        return true;
    }

    if (old.PlayState == IntPtr.Zero && current.PlayState != IntPtr.Zero) {
        print("Ending，Trigger Split");
        return true;
    }
}

isLoading
{
    return false;
}
