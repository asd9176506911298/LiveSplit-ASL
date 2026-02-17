state("Doriano")
{
    
}

startup 
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");

    vars.Helper.LoadSceneManager = true;
    vars.Helper.GameName = "Doriano";
    vars.Helper.AlertLoadless();
}

init
{
    var Instance = vars.Uhara.CreateTool("Unity", "DotNet", "Instance");

    Instance.Watch<IntPtr>("PlayState", "ExternalCutsceneManager","endingDirector","0x10","0x88");

    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        vars.Helper["collectedNum"] = mono.Make<int>("GameManager","currentGameManager","collectedItems",0x18);

        return true;
    });
}

update
{
    vars.Uhara.Update();
    
    current.activeScene = vars.Helper.Scenes.Active.Name ?? current.activeScene;
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