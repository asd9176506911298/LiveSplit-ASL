state("Aooni"){}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
    vars.Uhara.EnableDebug();

    // AssetName -> 顯示名稱（也是設定項清單，順序即顯示順序）
    var names = new Dictionary<string, string>
    {
        {"Opening", "Opening"},
        // 本館
        {"Entrance", "本館_玄関"},
        {"EastHallway", "本館_東側廊下"},
        {"LivingRoom", "本館_リビング"},
        {"Library", "本館_図書室"},
        {"WestHallway", "本館_西側廊下"},
        {"Bathroom", "本館_風呂場"},
        {"ToiletRoom", "本館_トイレ"},
        {"NorthHallway", "本館_北側廊下"},
        {"TatamiRoom", "本館_和室"},
        {"HiddenRoom", "本館_隠し部屋"},
        {"PrisonRoom", "本館_牢屋"},
        {"SecondHallway", "本館_2F廊下"},
        {"TakeshiRoom", "本館_2F個室"},
        {"PianoRoom", "本館_2Fピアノ部屋"},
        {"MikaRoom", "本館_子供部屋"},
        {"ThirdHallway", "本館_3F廊下"},
        {"DoorRoom", "本館_3F個室"},
        {"Bedroom", "本館_3F寝室"},
        {"BasementLibrary", "本館_地下書庫室"},
        {"BasementWestRoom", "本館_地下西側個室"},
        {"BasementEastRoom", "本館_地下東側個室"},
        {"BasementPrisonRoom", "本館_地下牢"},
        {"BigStairs", "本館_地下通路"},
        // 別館
        {"AnnexEntrance", "別館_玄関"},
        {"AnnexPrivateRoom", "別館_個室"},
        {"AnnexNorthHallway", "別館_北側廊下"},
        {"AnnexEastRoom", "別館_東側個室"},
        {"AnnexWestRoom", "別館_西側個室"},
        {"AnnexManagementRoom", "別館_管理室"},
        {"AnnexBasementEastHallway", "別館_東側廊下"},
        {"AnnexSecondFloorHallway", "別館_2F廊下"},
        {"AnnexSecondFloorBedRoom", "別館_2F寝室"},
        {"AnnexSecondFloorFireplaceRoom", "別館_2F暖炉部屋"},
        {"AnnexThirdFloorHallway", "別館_3F廊下"},
        {"AnnexThirdFloorRoom", "別館_3F個室"},
        {"AnnexBasementManagementRoom", "別館_地下管理室"},
        {"AnnexBasementSquare", "別館_地下中央広場"},
        {"AnnexBasementSouthWestRoom", "別館_地下南西個室"},
        {"AnnexBasementNorthWestRoom", "別館_地下北西個室"},
        {"AnnexBasementPassage", "別館_地下通路"},
        {"AnnexBasementSouthEastRoom", "別館_地下南東個室"},
        {"AnnexBasementNorthEastRoom", "別館_地下北東個室"},
        {"AnnexBasementNorthRoom", "別館_地下北側個室"},
        {"AnnexBasementPrisonRoom", "別館_地下牢"},
        {"AnnexBasementWestPassage", "別館_地下隠し通路 (西)"},
        {"AnnexBasementEastPassage", "別館_地下隠し通路 (東)"},
        {"AnnexWestBackDoor", "裏口 (AnnexWestBackDoor)"},
        {"AnnexEastBackDoor", "裏口 (AnnexEastBackDoor)"},
        // 離れ屋敷
        {"LastEntrance", "離れ屋敷_廊下"},
        {"LastNorthRoom", "離れ屋敷_北側個室"},
        {"LastWestRoom", "離れ屋敷_西側個室"},
        {"Chapel", "離れ屋敷_祭壇"},
        {"LastHallway2F", "離れ屋敷_2F廊下"},
        {"LastBedroom", "離れ屋敷_2F寝室"},
        {"Study", "離れ屋敷_2F書斎部屋"},
        {"RakugakiRoom", "離れ屋敷_2F個室"},
        {"LastHiddenRoom", "離れ屋敷_2F隠し部屋"},
        {"UnderChapel", "離れ屋敷_地下管理室"},
        {"LastBasementPassage", "離れ屋敷_地下通路"},
        {"LastBasementEastPassage", "離れ屋敷_地下東側通路"},
        {"LastBasementEastRoom", "離れ屋敷_地下東側個室"},
        {"LastBasementPrison", "離れ屋敷_地下牢屋"},
        {"PolygonRoom", "離れ屋敷_地下寝室"},
        {"BlueberryFarm", "離れ屋敷_地下大牢屋"},
        {"LastExit", "離れ屋敷_地下北側通路"},
        {"LastBackDoor", "裏口 (LastBackDoor)"},
        // Ending（沒有名字，直接用 AssetName）
        {"EndingRoad", "EndingRoad"},
        {"Ending", "Ending"},
        {"EndingEntrance", "EndingEntrance"}
    };

    // 謎の部屋（沒有個別名字，直接用 AssetName）
    var mystery = new List<string>();
    for (int i = 1; i <= 25; i++) mystery.Add("a" + i.ToString("00"));
    for (int i = 1; i <= 10; i++) mystery.Add("b" + i.ToString("00"));
    for (int i = 1; i <= 9;  i++) mystery.Add("c" + i.ToString("00"));
    mystery.Add("d01");
    foreach (var m in mystery)
        names[m] = m;

    vars.SceneNames = names;

    foreach (var kv in names)
        settings.Add(kv.Key, false, kv.Value);

    vars.SplitDone = new HashSet<string>();

    vars.toName = (Func<string, string>)(asset =>
        asset != null && names.ContainsKey(asset) ? names[asset] : asset);
}

init
{
    vars.Instance = vars.Uhara.CreateTool("Unity", "DotNet", "Instance");
    vars.Utils = vars.Uhara.CreateTool("Unity", "Utils");

    var ptr = vars.Instance.Get("GameScene", "Instance", "<CurrentMap>k__BackingField",
                                "<MapData>k__BackingField", "0x20", "0x14");
    vars.Resolver.WatchString("CurrentSceneName", ptr.Base, ptr.Offsets);
}

update
{
    vars.Uhara.Update();

    current.activeScene = vars.Utils.GetActiveSceneName() ?? current.activeScene;

    if (current.CurrentSceneName != old.CurrentSceneName)
        print(old.CurrentSceneName + " → " + current.CurrentSceneName
            + "  (" + vars.toName(old.CurrentSceneName) + " → " + vars.toName(current.CurrentSceneName) + ")");

    if (current.activeScene != old.activeScene)
    {
        print(old.activeScene + " - > " + current.activeScene);
    }
}

start
{
    // 主場景切換到 Opening
    if (current.CurrentSceneName != old.CurrentSceneName && current.CurrentSceneName == "Opening")
        return true;

    // Unity 的 activeScene 切換到 RogueGameScene
    if (old.activeScene == "LoadingScene" && current.activeScene == "RogueGameScene")
        return true;

    return false;
}
split
{
    var s = current.CurrentSceneName;
    if (s == null || s == old.CurrentSceneName)
        return false;

    // 有勾選，且 Add 成功（代表之前沒分過）才分段
    return settings.ContainsKey(s) && settings[s]
        && ((HashSet<string>)vars.SplitDone).Add(s);
}

onReset
{
    ((HashSet<string>)vars.SplitDone).Clear();
}
