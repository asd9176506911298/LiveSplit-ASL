state("Tall Trails") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
}

init
{
    vars.Utils = vars.Uhara.CreateTool("Unity", "Utils");
}

update
{
    vars.Uhara.Update();
    
    current.ActiveScene = vars.Utils.GetActiveSceneName() ?? current.ActiveScene;

    if(current.ActiveScene != old.ActiveScene)
    {
        print("old.ActiveScene: " + old.ActiveScene + " - > current.ActiveScene: " + current.ActiveScene);
    }
}

start
{
    if(old.ActiveScene == "TITLE-SCENE" && current.ActiveScene == "GAME-SCENE")
    {
        vars.Uhara.Log("Start");
        return true;
    }
}