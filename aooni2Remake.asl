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
    vars.Instance = vars.Uhara.CreateTool("Unity", "IL2CPP", "Instance");

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
    return old.CurrentSceneName != "Op_NewBldgFront" && current.CurrentSceneName == "Op_NewBldgFront";
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

onReset
{
    foreach (var scene in vars.Scenes)
    {
        vars.SplitDone[scene] = false;
    }
}