state("Aooni"){}

startup 
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
    vars.Uhara.EnableDebug();

    // All scenes (AssetName only)
    vars.Scenes = new string[]
    {
        "Opening",
        "Entrance",
        "EastHallway",
        "LivingRoom",
        "Library",
        "WestHallway",
        "Bathroom",
        "ToiletRoom",
        "NorthHallway",
        "TatamiRoom",
        "HiddenRoom",
        "PrisonRoom",
        "SecondHallway",
        "TakeshiRoom",
        "PianoRoom",
        "MikaRoom",
        "ThirdHallway",
        "DoorRoom",
        "Bedroom",
        "BasementLibrary",
        "BasementWestRoom",
        "BasementEastRoom",
        "BasementPrisonRoom",
        "BigStairs",
        "AnnexEntrance",
        "AnnexPrivateRoom",
        "AnnexNorthHallway",
        "AnnexEastRoom",
        "AnnexWestRoom",
        "AnnexManagementRoom",
        "AnnexBasementEastHallway",
        "AnnexSecondFloorHallway",
        "AnnexSecondFloorBedRoom",
        "AnnexSecondFloorFireplaceRoom",
        "AnnexThirdFloorHallway",
        "AnnexThirdFloorRoom",
        "AnnexBasementManagementRoom",
        "AnnexBasementSquare",
        "AnnexBasementSouthWestRoom",
        "AnnexBasementNorthWestRoom",
        "AnnexBasementPassage",
        "AnnexBasementSouthEastRoom",
        "AnnexBasementNorthEastRoom",
        "AnnexBasementNorthRoom",
        "AnnexBasementPrisonRoom",
        "AnnexBasementWestPassage",
        "AnnexBasementEastPassage",
        "AnnexWestBackDoor",
        "AnnexEastBackDoor",
        "LastEntrance",
        "LastNorthRoom",
        "LastWestRoom",
        "Chapel",
        "LastHallway2F",
        "LastBedroom",
        "Study",
        "RakugakiRoom",
        "LastHiddenRoom",
        "UnderChapel",
        "LastBasementPassage",
        "LastBasementEastPassage",
        "LastBasementEastRoom",
        "LastBasementPrison",
        "PolygonRoom",
        "BlueberryFarm",
        "LastExit",
        "LastBackDoor",
        "EndingRoad",
        "Ending",
        "EndingEntrance"
    };

    // Create a checkbox for every scene
    foreach (var scene in vars.Scenes)
    {
        settings.Add(scene, false, scene);
    }

    // Remember which scenes have already split
    vars.SplitDone = new Dictionary<string, bool>();
}

init
{
    vars.Instance = vars.Uhara.CreateTool("Unity", "DotNet", "Instance");

    //                                                                                                                       <AssetName>k__BackingField->string
    var ptr_CurrentSceneName = vars.Instance.Get("MainGameScene", "<CurrentMap>k__BackingField", "<MapData>k__BackingField", "0x20", "0x14");
    vars.Resolver.WatchString("CurrentSceneName", ptr_CurrentSceneName.Base, ptr_CurrentSceneName.Offsets);

    // Reset the split-done flags every time the game is started/restarted
    vars.SplitDone.Clear();
    foreach (var scene in vars.Scenes)
    {
        vars.SplitDone[scene] = false;
    }
}

update
{
    vars.Uhara.Update();

    if (current.CurrentSceneName != old.CurrentSceneName)
    {
        print(old.CurrentSceneName + " → " + current.CurrentSceneName);
    }
}

start
{
    return old.CurrentSceneName != "Opening" && current.CurrentSceneName == "Opening";
}

split
{
    // Only care when the scene actually changes
    if (current.CurrentSceneName == old.CurrentSceneName)
        return false;

    string scene = current.CurrentSceneName;

    // Is this scene selected in the settings AND have we never split on it before?
    if (settings[scene] && !vars.SplitDone[scene])
    {
        vars.SplitDone[scene] = true;   // mark as done so it never splits again
        return true;
    }

    return false;
}
