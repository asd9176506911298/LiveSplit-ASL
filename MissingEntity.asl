state("Missing Entity")
{
    
}

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
    
    if (old.activeScene != current.activeScene)
    {
        print(old.activeScene + " -> " + current.activeScene);
    }
}

start
{
    return old.activeScene == "Demo1" && current.activeScene == "Mars Landscape 3D Overview";
}

split
{
    return old.activeScene == "Mars Landscape 3D Overview" && current.activeScene == "TP";
}