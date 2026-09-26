state("Aooni"){}

startup 
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
    vars.Uhara.EnableDebug();
}

init
{
    vars.Instance = vars.Uhara.CreateTool("Unity", "DotNet", "Instance");

    //                                                                                                                       <AssetName>k__BackingField->string
    var ptr_CurrentSceneName = vars.Instance.Get("MainGameScene", "<CurrentMap>k__BackingField", "<MapData>k__BackingField", "0x20", "0x14");
    vars.Resolver.WatchString("CurrentSceneName", ptr_CurrentSceneName.Base, ptr_CurrentSceneName.Offsets);
}

update
{
    vars.Uhara.Update();

    if (current.CurrentSceneName != old.CurrentSceneName)
    {
        print(old.CurrentSceneName + " - > " + current.CurrentSceneName);
    }
}


start
{
    return old.CurrentSceneName != "Opening" && current.CurrentSceneName == "Opening";
}

/*
split
{
    
}
*/