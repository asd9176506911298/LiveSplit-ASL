state("Aooni2"){}

startup 
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
    vars.Uhara.EnableDebug();

    // All scenes (AssetName only)
    vars.Scenes = new string[]
    {
        "Op_NewBldgFront",
        "BFPrison_Solitary",
        "BFPrison_Solitaryroom",
        "BFPrison_CommunalroomPassage1",
        "BFPrison_CommunalroomPassage4",
        "BFPrison_Securityroom",
        "BFPrison_Libraryroom",
        "BFPrison_Passage",
        "BFPrison_Communalroom",
        "BFPrison_GroundStairs",
        "New_1FWestStairs",
        "New_1FWestHallway",
        "New_1FFWC",
        "New_1FArtroom",
        "New_1FLunchroomFront",
        "New_1FLunchroom",
        "New_1FEastHealthroom",
        "New_1FHallway",
        "New_1FWestHealthroom",
        "New_1FScienceroom",
        "New_1FArtWarehouse",
        "New_1FConnectingPassage",
        "New_1FEastHallway",
        "New_1FLounge",
        "New_1FLectureroom",
        "New_1FHiddenStairs",
        "New_2FEastStairs",
        "New_2FSimpleArchive",
        "New_2FBackClassroomStairs",
        "New_3FStairLanding",
        "New_3FEastHallway",
        "New_3FMWC",
        "New_3FStaffStairs",
        "New_2FEastHallway",
        "New_2FFWC",
        "New_2FPrincipalOffice",
        "New_2FClassroom",
        "New_3FBalcony",
        "New_3FReferenceroomFront",
        "New_3FReferenceroom",
        "New_3FMusicroomFront",
        "New_3FMusicroom",
        "New_3FBackMusicroomStairs",
        "New_3FBulletinBoardArea",
        "RooftopPool",
        "RooftopPool_East",
        "RooftopPool_Machineroom",
        "RooftopPool_Dressingroom",
        "RooftopPool_Equipmentroom",
        "RooftopPool_EquipmentroomFurther",
        "New_3FStaircase",
        "New_3FLounge",
        "New_3FMidSizeLectureroom",
        "New_2FStaircase",
        "Gym_Front",
        "Gym_MLockerroom",
        "Gym_FLockerroom",
        "Gym_SouthEntrance",
        "Gym_CollapsedHallway",
        "Gym_CentralGymnasium",
        "Gym_WaterStorageroomFront",
        "Gym_WaterStorageroom",
        "Gym_Warehouse",
        "BehGym_Lounge",
        "BehGym_Hallway",
        "BehGym_Janitorsroom",
        "BehGym_EastPassage",
        "BehGym_Preparationroom",
        "BehGym_Storageroom",
        "CentPlaza",
        "CentPlaza_West",
        "CentPlaza_Courtyard",
        "New_1FLectureroom2",
        "CentPlaza_StaffEmergencyExit",
        "Ebasement_PlazaUnderPassage",
        "Ebasement_GarbageStorage",
        "Ebasement_Passage",
        "Ebasement_LShapedPassage",
        "Ebasement_DeadEnd",
        "Ebasement_Solitary",
        "Ebasement_LargeCell",
        "Ebasement_Smallroom",
        "Ebasement_Altar",
        "Ebasement_Chapel",
        "Ebasement_Receptionroom",
        "Ebasement_OldBldgConnectingStairs",
        "Old_1FEntrance",
        "Old_1FClassroom",
        "Old_1FBroadcastroomFront",
        "Old_1FBroadcastroom",
        "Old_1FNaproom",
        "Old_1FWarehouse",
        "Old_2FHallway",
        "Old_2FMWC",
        "Old_2F2ndGradeClassroom",
        "Old_2FArtroom",
        "Old_2FOldBldgStair",
        "Old_3FCentralPassage",
        "Old_3FHallway",
        "Old_3FArtworkDryingroom",
        "Old_3FOldMechanismroom",
        "Old_3FJapanstyleroom",
        "Old_3FImitationHiroen",
        "OldRooftopFront_Passage",
        "OldRooftopFront_Staircase",
        "OldRooftopFront_Penthouse",
        "OldRooftop",
        "OldRooftop_Lounge",
        "OldRooftop_GalleryFront",
        "OldRooftop_MachineroomUnderPenthouse",
        "OldRooftop_SecretGallery",
        "OldRooftop_EmergencyStaircaseFront",
        "EmergencyStaircase",
        "BackGate",
        "Ed_Escapeway",
        "HiddenPrison",
        // SeasideSchoolList
        "SS_Op_Beach_Daytime",
        "SS_Op_BldgFront",
        "SS_ClosedSch_1FEntrance",
        "SS_ClosedSch_1FFrontHallway",
        "SS_ClosedSch_1FFrontHallwayWest",
        "SS_ClosedSch_1FMWC",
        "SS_ClosedSch_1FFrontClassroomWest",
        "SS_ClosedSch_1FStaffroomFront",
        "SS_ClosedSch_1FFWC",
        "SS_ClosedSch_1FStaffroom",
        "SS_ClosedSch_1FPrincipalsofficeFront",
        "SS_ClosedSch_1FPrincipalsoffice",
        "SS_ClosedSch_1FStairArea",
        "SS_ClosedSch_1FHealthroom",
        "SS_ClosedSch_1FBroadcastroom",
        "SS_ClosedSch_1FClassRoom6",
        "SS_ClosedSch_1FClassRoom2",
        "SS_ClosedSch_1FClassRoom7",
        "SS_ClosedSch_1FClassRoom4",
        "SS_ClosedSch_1FClassRoom8",
        "SS_ClosedSch_1FGym3",
        "SS_ClosedSch_1FGym4",
        "SS_ClosedSch_2FHallwayWest",
        "SS_ClosedSch_2FArtroomFront",
        "SS_ClosedSch_2FArtPreparationroom",
        "SS_ClosedSch_2FHallwayEast",
        "SS_ClosedSch_2FLaboratoryEquipmentroom",
        "SS_ClosedSch_2FArtroom",
        "SS_ClosedSch_2FLaboratoly",
        "SS_HiddenPassage",
        "SS_ResearchFacility",
        "SS_ShipDock",
        "SS_Exit",
        "SS_LastRun",
        "SS_Ed_Beach_Sunrise",
        "SS_Ed_Beach_Daytime",
        "SS_Ed_Beach_Evening"
    };
    // AssetName -> SceneName（只用來顯示）
    vars.SceneNames = new Dictionary<string, string>
    {
        {"Op_NewBldgFront", "OP校舎前"},
        {"BFPrison_Solitary", "地下牢_独房"},
        {"BFPrison_Solitaryroom", "地下牢_独房部屋"},
        {"BFPrison_CommunalroomPassage1", "地下牢_共同房連絡通路Ⅰ"},
        {"BFPrison_CommunalroomPassage4", "地下牢_共同房連絡通路Ⅳ"},
        {"BFPrison_Securityroom", "地下牢_看守室"},
        {"BFPrison_Libraryroom", "地下牢_書庫室"},
        {"BFPrison_Passage", "地下牢_通路"},
        {"BFPrison_Communalroom", "地下牢_共同房Ⅱ"},
        {"BFPrison_GroundStairs", "地下牢_地上階段"},
        {"New_1FWestStairs", "新校舎1F_西階段"},
        {"New_1FWestHallway", "新校舎1F_西側廊下"},
        {"New_1FFWC", "新校舎1F_女子トイレ"},
        {"New_1FArtroom", "新校舎1F_美術室"},
        {"New_1FLunchroomFront", "新校舎1F_給食室前"},
        {"New_1FLunchroom", "新校舎1F_給食室"},
        {"New_1FEastHealthroom", "新校舎1F_保健室東"},
        {"New_1FHallway", "新校舎1F_廊下"},
        {"New_1FWestHealthroom", "新校舎1F_保健室西"},
        {"New_1FScienceroom", "新校舎1F_理科室"},
        {"New_1FArtWarehouse", "新校舎1F_美術倉庫"},
        {"New_1FConnectingPassage", "新校舎1F_連絡通路"},
        {"New_1FEastHallway", "新校舎1F_東側廊下"},
        {"New_1FLounge", "新校舎1F_ラウンジ"},
        {"New_1FLectureroom", "新校舎1F_講義室"},
        {"New_1FHiddenStairs", "新校舎1F_隠し階段"},
        {"New_2FEastStairs", "新校舎2F_東階段"},
        {"New_2FSimpleArchive", "新校舎2F_簡易書庫"},
        {"New_2FBackClassroomStairs", "新校舎2F_教室裏階段"},
        {"New_3FStairLanding", "新校舎3F_踊り場"},
        {"New_3FEastHallway", "新校舎3F_東廊下"},
        {"New_3FMWC", "新校舎3F_男子トイレ"},
        {"New_3FStaffStairs", "新校舎3F_職員階段"},
        {"New_2FEastHallway", "新校舎2F_東廊下"},
        {"New_2FFWC", "新校舎2F_女子トイレ"},
        {"New_2FPrincipalOffice", "新校舎2F_校長室"},
        {"New_2FClassroom", "新校舎2F_教室"},
        {"New_3FBalcony", "新校舎3F_ベランダ"},
        {"New_3FReferenceroomFront", "新校舎3F_資料室前"},
        {"New_3FReferenceroom", "新校舎3F_資料室"},
        {"New_3FMusicroomFront", "新校舎3F_音楽室前"},
        {"New_3FMusicroom", "新校舎3F_音楽室"},
        {"New_3FBackMusicroomStairs", "新校舎3F_音楽室裏階段"},
        {"New_3FBulletinBoardArea", "新校舎3F_掲示板エリア"},
        {"RooftopPool", "屋上プール"},
        {"RooftopPool_East", "屋上プール東"},
        {"RooftopPool_Machineroom", "屋上プール_機械室"},
        {"RooftopPool_Dressingroom", "屋上プール_女子更衣室"},
        {"RooftopPool_Equipmentroom", "屋上プール_用具入れ"},
        {"RooftopPool_EquipmentroomFurther", "屋上プール_用具入れ奥"},
        {"New_3FStaircase", "新校舎3F_階段通路"},
        {"New_3FLounge", "新校舎3F_ラウンジ"},
        {"New_3FMidSizeLectureroom", "新校舎3F_中講義室"},
        {"New_2FStaircase", "新校舎2F_階段"},
        {"Gym_Front", "体育館前"},
        {"Gym_MLockerroom", "体育館_男子ロッカールーム"},
        {"Gym_FLockerroom", "体育館_女子ロッカールーム"},
        {"Gym_SouthEntrance", "体育館_南出入り口"},
        {"Gym_CollapsedHallway", "崩落した廊下"},
        {"Gym_CentralGymnasium", "中央体育館"},
        {"Gym_WaterStorageroomFront", "貯水槽前"},
        {"Gym_WaterStorageroom", "貯水槽"},
        {"Gym_Warehouse", "体育館倉庫"},
        {"BehGym_Lounge", "体育館横ラウンジ"},
        {"BehGym_Hallway", "体育館裏_廊下"},
        {"BehGym_Janitorsroom", "体育館裏_用務員室"},
        {"BehGym_EastPassage", "体育館裏_東通路"},
        {"BehGym_Preparationroom", "体育館裏_準備室"},
        {"BehGym_Storageroom", "体育館裏_物置部屋"},
        {"CentPlaza", "中央広場"},
        {"CentPlaza_West", "中央広場西"},
        {"CentPlaza_Courtyard", "中庭"},
        {"New_1FLectureroom2", "新校舎1F_講義室 (2)"},   // 與 New_1FLectureroom 同名，加 (2) 區分
        {"CentPlaza_StaffEmergencyExit", "職員用避難通路"},
        {"Ebasement_PlazaUnderPassage", "東地下_広場下通路"},
        {"Ebasement_GarbageStorage", "東地下_ゴミ置き場"},
        {"Ebasement_Passage", "東地下_通路"},
        {"Ebasement_LShapedPassage", "東地下_L字路"},
        {"Ebasement_DeadEnd", "東地下_袋小路"},
        {"Ebasement_Solitary", "東地下_独房"},
        {"Ebasement_LargeCell", "地下大牢"},
        {"Ebasement_Smallroom", "東地下_小部屋"},
        {"Ebasement_Altar", "東地下_祭壇"},
        {"Ebasement_Chapel", "東地下_礼拝堂"},
        {"Ebasement_Receptionroom", "東地下_応接間"},
        {"Ebasement_OldBldgConnectingStairs", "旧校舎接続階段"},
        {"Old_1FEntrance", "旧校舎1F_下駄箱"},
        {"Old_1FClassroom", "旧校舎1F_教室"},
        {"Old_1FBroadcastroomFront", "旧校舎1F_放送室前"},
        {"Old_1FBroadcastroom", "旧校舎1F_放送室"},
        {"Old_1FNaproom", "旧校舎1F_仮眠室"},
        {"Old_1FWarehouse", "旧校舎1F_倉庫"},
        {"Old_2FHallway", "旧校舎2F_廊下"},
        {"Old_2FMWC", "旧校舎2F_男子トイレ"},
        {"Old_2F2ndGradeClassroom", "旧校舎2F_2年生教室"},
        {"Old_2FArtroom", "旧校舎2F_美術室"},
        {"Old_2FOldBldgStair", "旧校舎2F_階段"},
        {"Old_3FCentralPassage", "旧校舎3F_中央通路"},
        {"Old_3FHallway", "旧校舎3F_廊下"},
        {"Old_3FArtworkDryingroom", "旧校舎3F_作品乾燥室"},
        {"Old_3FOldMechanismroom", "旧校舎3F_古仕掛部屋"},
        {"Old_3FJapanstyleroom", "旧校舎3F_和室"},
        {"Old_3FImitationHiroen", "旧校舎3F_ラウンジ"},
        {"OldRooftopFront_Passage", "旧校舎屋上前_通路"},
        {"OldRooftopFront_Staircase", "旧校舎屋上前_階段"},
        {"OldRooftopFront_Penthouse", "旧校舎屋上前_塔屋"},
        {"OldRooftop", "旧校舎屋上"},
        {"OldRooftop_Lounge", "旧校舎屋上_ラウンジ"},
        {"OldRooftop_GalleryFront", "旧校舎屋上_ギャラリー前"},
        {"OldRooftop_MachineroomUnderPenthouse", "旧校舎屋上_塔屋下機械室"},
        {"OldRooftop_SecretGallery", "旧校舎屋上_秘密のギャラリー"},
        {"OldRooftop_EmergencyStaircaseFront", "旧校舎屋上_非常階段前"},
        {"EmergencyStaircase", "非常階段"},
        {"BackGate", "裏門出口"},
        {"Ed_Escapeway", "ラストラン"},
        {"HiddenPrison", "隠し牢屋"},
        // SeasideSchoolList
        {"SS_Op_Beach_Daytime", "OP海岸通り"},
        {"SS_Op_BldgFront", "OP用校舍前"},
        {"SS_ClosedSch_1FEntrance", "廢校舍1F_玄關"},
        {"SS_ClosedSch_1FFrontHallway", "廢校舍1F_正面走廊"},
        {"SS_ClosedSch_1FFrontHallwayWest", "廢校舍1F_正面走廊西側"},
        {"SS_ClosedSch_1FMWC", "廢校舍1F_男廁"},
        {"SS_ClosedSch_1FFrontClassroomWest", "廢校舍1F_教室前西側"},
        {"SS_ClosedSch_1FStaffroomFront", "廢校舍1F_教職員室前"},
        {"SS_ClosedSch_1FFWC", "廢校舍1F_女廁"},
        {"SS_ClosedSch_1FStaffroom", "廢校舍1F_教職員室"},
        {"SS_ClosedSch_1FPrincipalsofficeFront", "廢校舍1F_校長室前"},
        {"SS_ClosedSch_1FPrincipalsoffice", "廢校舍1F_校長室"},
        {"SS_ClosedSch_1FStairArea", "廢校舍1F_樓梯區域"},
        {"SS_ClosedSch_1FHealthroom", "廢校舍1F_保健室"},
        {"SS_ClosedSch_1FBroadcastroom", "廢校舍1F_廣播室"},
        {"SS_ClosedSch_1FClassRoom6", "廢校舍1F_一年級教室 (6)"},
        {"SS_ClosedSch_1FClassRoom2", "廢校舍1F_一年級教室 (2)"},
        {"SS_ClosedSch_1FClassRoom7", "廢校舍1F_一年級教室 (7)"},
        {"SS_ClosedSch_1FClassRoom4", "廢校舍1F_一年級教室 (4)"},
        {"SS_ClosedSch_1FClassRoom8", "廢校舍1F_一年級教室 (8)"},
        {"SS_ClosedSch_1FGym3", "廢校舍1F_體育館 (3)"},
        {"SS_ClosedSch_1FGym4", "廢校舍1F_體育館 (4)"},
        {"SS_ClosedSch_2FHallwayWest", "廢校舍2F_西側走廊"},
        {"SS_ClosedSch_2FArtroomFront", "廢校舍2F_美術教室前"},
        {"SS_ClosedSch_2FArtPreparationroom", "廢校舍2F_美術準備室"},
        {"SS_ClosedSch_2FHallwayEast", "廢校舍2F_東側走廊"},
        {"SS_ClosedSch_2FLaboratoryEquipmentroom", "廢校舍2F_實驗器材室"},
        {"SS_ClosedSch_2FArtroom", "廢校舍2F_美術教室"},
        {"SS_ClosedSch_2FLaboratoly", "廢校舍2F_實驗室"},
        {"SS_HiddenPassage", "隱藏通道"},
        {"SS_ResearchFacility", "海洋生物研究設施"},
        {"SS_ShipDock", "船塢"},
        {"SS_Exit", "船塢出口"},
        {"SS_LastRun", "SS_LastRun"},
        {"SS_Ed_Beach_Sunrise", "SS_Ed_Beach_Sunrise"},
        {"SS_Ed_Beach_Daytime", "SS_Ed_Beach_Daytime"},
        {"SS_Ed_Beach_Evening", "ED海岸（藍エンド用）"}
    };

    // Create a checkbox for every scene：ID 用 AssetName，顯示文字用 SceneName
    foreach (var scene in vars.Scenes)
    {
        string display;
        if (!vars.SceneNames.TryGetValue(scene, out display))
            display = scene;   // 沒有對照的（例如 SS_ 開頭）就顯示 AssetName
        settings.Add(scene, false, display);
    }

    // Remember which scenes have already split
    vars.SplitDone = new Dictionary<string, bool>();
    var sceneNames = (Dictionary<string, string>)vars.SceneNames;
    vars.toName = (Func<string, string>)(asset =>
    {
        string name = null;
        if (asset != null && sceneNames.TryGetValue(asset, out name))
            return name;
        return asset;
    });
}

init
{
    // AssetName -> SceneName，找不到就顯示 AssetName

    vars.Instance = vars.Uhara.CreateTool("Unity", "IL2CPP", "Instance");

    //                                                                                                                       <AssetName>k__BackingField->string
    var ptr_CurrentSceneName = vars.Instance.Get("MainGameScene", "<CurrentMap>k__BackingField", "<MapData>k__BackingField", "0x20", "0x14");
    vars.Resolver.WatchString("CurrentSceneName", ptr_CurrentSceneName.Base, ptr_CurrentSceneName.Offsets);

    var ptr_CurrentSchoolSceneName = vars.Instance.Get("SeasideSchoolGameScene", "<CurrentMap>k__BackingField", "<MapData>k__BackingField", "0x20", "0x14");
    vars.Resolver.WatchString("CurrentSchoolSceneName", ptr_CurrentSchoolSceneName.Base, ptr_CurrentSchoolSceneName.Offsets);

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
        print("[Main] " + vars.toName(old.CurrentSceneName) + " → " + vars.toName(current.CurrentSceneName));

    if (current.CurrentSchoolSceneName != old.CurrentSchoolSceneName)
        print("[School] " + vars.toName(old.CurrentSchoolSceneName) + " → " + vars.toName(current.CurrentSchoolSceneName));
}

start
{
    // 主線：進入 Op_NewBldgFront
    if (old.CurrentSceneName != "Op_NewBldgFront" && current.CurrentSceneName == "Op_NewBldgFront")
        return true;

    // 海邊學校：進入 SS_Op_Beach_Daytime
    if (old.CurrentSchoolSceneName != "SS_Op_Beach_Daytime" && current.CurrentSchoolSceneName == "SS_Op_Beach_Daytime")
        return true;

    return false;
}

split
{
    var splitDone = (Dictionary<string, bool>)vars.SplitDone;

    // 收集這個 tick 剛切換到的場景（主線、海邊學校各一個）
    string[] changed = new string[2];
    if (current.CurrentSceneName != old.CurrentSceneName)
        changed[0] = current.CurrentSceneName;
    if (current.CurrentSchoolSceneName != old.CurrentSchoolSceneName)
        changed[1] = current.CurrentSchoolSceneName;

    foreach (string scene in changed)
    {
        if (scene == null)
            continue;

        // 不在清單內的場景（或空字串）直接略過，避免 KeyNotFoundException
        bool done;
        if (!splitDone.TryGetValue(scene, out done))
            continue;

        // 有勾選，而且從來沒分過
        if (settings[scene] && !done)
        {
            splitDone[scene] = true;   // 標記已分段，不會再分
            return true;
        }
    }

    return false;
}
onReset
{
    foreach (var scene in vars.Scenes)
    {
        vars.SplitDone[scene] = false;
    }
}
