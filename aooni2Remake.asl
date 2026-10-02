state("Aooni2"){}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
    vars.Uhara.EnableDebug();

    // AssetName -> 顯示名稱（同時也是設定項清單，順序即顯示順序）
    vars.SceneNames = new Dictionary<string, string>
    {
        {"Op_NewBldgFront", "OP校舍前"},
        {"BFPrison_Solitary", "地下牢_独房"},
        {"BFPrison_Solitaryroom", "地下牢_独房部屋"},
        {"BFPrison_CommunalroomPassage1", "地下牢_共同房連絡通路Ⅰ"},
        {"BFPrison_CommunalroomPassage4", "地下牢_共同房連絡通路Ⅳ"},
        {"BFPrison_Securityroom", "地下牢_看守室"},
        {"BFPrison_Libraryroom", "地下牢_書庫室"},
        {"BFPrison_Passage", "地下牢_通路"},
        {"BFPrison_Communalroom", "地下牢_共同房Ⅱ"},
        {"BFPrison_GroundStairs", "地下牢_地上階段"},
        {"New_1FWestStairs", "新校舍1F_西階段"},
        {"New_1FWestHallway", "新校舍1F_西側廊下"},
        {"New_1FFWC", "新校舍1F_女子トイレ"},
        {"New_1FArtroom", "新校舍1F_美術室"},
        {"New_1FLunchroomFront", "新校舍1F_給食室前"},
        {"New_1FLunchroom", "新校舍1F_給食室"},
        {"New_1FEastHealthroom", "新校舍1F_保健室東"},
        {"New_1FHallway", "新校舍1F_廊下"},
        {"New_1FWestHealthroom", "新校舍1F_保健室西"},
        {"New_1FScienceroom", "新校舍1F_理科室"},
        {"New_1FArtWarehouse", "新校舍1F_美術倉庫"},
        {"New_1FConnectingPassage", "新校舍1F_連絡通路"},
        {"New_1FEastHallway", "新校舍1F_東側廊下"},
        {"New_1FLounge", "新校舍1F_ラウンジ"},
        {"New_1FLectureroom", "新校舍1F_講義室"},
        {"New_1FHiddenStairs", "新校舍1F_隠し階段"},
        {"New_2FEastStairs", "新校舍2F_東階段"},
        {"New_2FSimpleArchive", "新校舍2F_簡易書庫"},
        {"New_2FBackClassroomStairs", "新校舍2F_教室裏階段"},
        {"New_3FStairLanding", "新校舍3F_踊り場"},
        {"New_3FEastHallway", "新校舍3F_東廊下"},
        {"New_3FMWC", "新校舍3F_男子トイレ"},
        {"New_3FStaffStairs", "新校舍3F_職員階段"},
        {"New_2FEastHallway", "新校舍2F_東廊下"},
        {"New_2FFWC", "新校舍2F_女子トイレ"},
        {"New_2FPrincipalOffice", "新校舍2F_校長室"},
        {"New_2FClassroom", "新校舍2F_教室"},
        {"New_3FBalcony", "新校舍3F_ベランダ"},
        {"New_3FReferenceroomFront", "新校舍3F_資料室前"},
        {"New_3FReferenceroom", "新校舍3F_資料室"},
        {"New_3FMusicroomFront", "新校舍3F_音楽室前"},
        {"New_3FMusicroom", "新校舍3F_音楽室"},
        {"New_3FBackMusicroomStairs", "新校舍3F_音楽室裏階段"},
        {"New_3FBulletinBoardArea", "新校舍3F_掲示板エリア"},
        {"RooftopPool", "屋上プール"},
        {"RooftopPool_East", "屋上プール東"},
        {"RooftopPool_Machineroom", "屋上プール_機械室"},
        {"RooftopPool_Dressingroom", "屋上プール_女子更衣室"},
        {"RooftopPool_Equipmentroom", "屋上プール_用具入れ"},
        {"RooftopPool_EquipmentroomFurther", "屋上プール_用具入れ奥"},
        {"New_3FStaircase", "新校舍3F_階段通路"},
        {"New_3FLounge", "新校舍3F_ラウンジ"},
        {"New_3FMidSizeLectureroom", "新校舍3F_中講義室"},
        {"New_2FStaircase", "新校舍2F_階段"},
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
        {"New_1FLectureroom2", "新校舍1F_講義室 (2)"},   // 與 New_1FLectureroom 同名，加 (2) 區分
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
        {"Ebasement_OldBldgConnectingStairs", "旧校舍接続階段"},
        {"Old_1FEntrance", "旧校舍1F_下駄箱"},
        {"Old_1FClassroom", "旧校舍1F_教室"},
        {"Old_1FBroadcastroomFront", "旧校舍1F_放送室前"},
        {"Old_1FBroadcastroom", "旧校舍1F_放送室"},
        {"Old_1FNaproom", "旧校舍1F_仮眠室"},
        {"Old_1FWarehouse", "旧校舍1F_倉庫"},
        {"Old_2FHallway", "旧校舍2F_廊下"},
        {"Old_2FMWC", "旧校舍2F_男子トイレ"},
        {"Old_2F2ndGradeClassroom", "旧校舍2F_2年生教室"},
        {"Old_2FArtroom", "旧校舍2F_美術室"},
        {"Old_2FOldBldgStair", "旧校舍2F_階段"},
        {"Old_3FCentralPassage", "旧校舍3F_中央通路"},
        {"Old_3FHallway", "旧校舍3F_廊下"},
        {"Old_3FArtworkDryingroom", "旧校舍3F_作品乾燥室"},
        {"Old_3FOldMechanismroom", "旧校舍3F_古仕掛部屋"},
        {"Old_3FJapanstyleroom", "旧校舍3F_和室"},
        {"Old_3FImitationHiroen", "旧校舍3F_ラウンジ"},
        {"OldRooftopFront_Passage", "旧校舍屋上前_通路"},
        {"OldRooftopFront_Staircase", "旧校舍屋上前_階段"},
        {"OldRooftopFront_Penthouse", "旧校舍屋上前_塔屋"},
        {"OldRooftop", "旧校舍屋上"},
        {"OldRooftop_Lounge", "旧校舍屋上_ラウンジ"},
        {"OldRooftop_GalleryFront", "旧校舍屋上_ギャラリー前"},
        {"OldRooftop_MachineroomUnderPenthouse", "旧校舍屋上_塔屋下機械室"},
        {"OldRooftop_SecretGallery", "旧校舍屋上_秘密のギャラリー"},
        {"OldRooftop_EmergencyStaircaseFront", "旧校舍屋上_非常階段前"},
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

    var names = (Dictionary<string, string>)vars.SceneNames;

    foreach (var kv in names)
        settings.Add(kv.Key, false, kv.Value);

    vars.SplitDone = new HashSet<string>();

    vars.toName = (Func<string, string>)(asset =>
        asset != null && names.ContainsKey(asset) ? names[asset] : asset);
}

init
{
    vars.Instance = vars.Uhara.CreateTool("Unity", "IL2CPP", "Instance");

    var ptr = vars.Instance.Get("GameScene", "Instance", "<CurrentMap>k__BackingField",
                                "<MapData>k__BackingField", "0x20", "0x14");
    vars.Resolver.WatchString("CurrentSceneName", ptr.Base, ptr.Offsets);
}

update
{
    vars.Uhara.Update();

    if (current.CurrentSceneName != old.CurrentSceneName)
        print(vars.toName(old.CurrentSceneName) + " → " + vars.toName(current.CurrentSceneName));
}

start
{
    var s = current.CurrentSceneName;
    return s != old.CurrentSceneName
        && (s == "Op_NewBldgFront" || s == "SS_Op_Beach_Daytime");
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
