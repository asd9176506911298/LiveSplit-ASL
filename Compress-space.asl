state("Compress-space") {}

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
    current.activeScene = vars.Utils.GetActiveSceneName() ?? current.activeScene;

    if(current.activeScene != old.activeScene)
    {
        vars.Uhara.Log("old.activeScene: " + old.activeScene + " - > current.activeScene: " + current.activeScene);
    }
}