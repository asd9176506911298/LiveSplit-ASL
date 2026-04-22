state("Tales of Graces f Remastered") { }

startup
{
    if (timer.CurrentTimingMethod != TimingMethod.GameTime)
    {
        var mbox = System.Windows.Forms.MessageBox.Show(
            timer.Form,
            "Removing loads from this game requires comparing against Game Time.\nWould you like to switch to it?",
            "LiveSplit | Tales of Graces f Remastered",
            System.Windows.Forms.MessageBoxButtons.YesNo,
            System.Windows.Forms.MessageBoxIcon.Question
        );
        if (mbox == System.Windows.Forms.DialogResult.Yes) timer.CurrentTimingMethod = TimingMethod.GameTime;
    }

    settings.Add("enemy_splits", true, "Enemy Defeat Splits (Split on black screen after combat)");

    var enemyList = new Dictionary<int, string> {
        {1, "Asbel(party)"}, {2, "Sophie(party)"}, {3, "Hubert(party)"}, {4, "Cheria(party)"}, {5, "Malik(party)"},
        {6, "Pascal(party)"}, {7, "Richard(party)"}, {8, "Asbel?(kid;ZC)"}, {9, "Hubert?(kid;ZC)"}, {10, "Richard?(kid;ZC)"},
        {11, "Hubert(skit)"}, {12, "Malik(skit)"}, {13, "[empty][crash]"}, {14, "Bryce(Lhant Hill)"}, {15, "Cedric"},
        {16, "Kurt"}, {17, "Emeraude"}, {18, "Victoria"}, {19, "Bryce(Orlen)"}, {20, "Frederic"},
        {21, "Cedric 2.0"}, {22, "Emeraude 2.0"}, {23, "Fourier"}, {24, "Veigue(Warrior Roost)"}, {25, "Amber(ZC3)"},
        {26, "Reala(ZC9)"}, {27, "Centurioid"}, {28, "Richard(Lhant)"}, {29, "Richard(2nd battle)"}, {30, "Richard(3rd battle)"},
        {31, "Richard(Ghardia)"}, {32, "Lambda Angelus"}, {33, "Solomus(ZC10)"}, {34, "Royal Manhunter"}, {35, "Lambda"},
        {36, "Helmcrusher"}, {37, "Polycarpus"}, {38, "Rockgagong"}, {39, "Lambda Theos"}, {40, "Wolf"},
        {41, "Wolf Pup"}, {42, "Snowdrift Wolf"}, {43, "Obsidian Wolf"}, {44, "Uridimmu"}, {45, "Bat"},
        {46, "Elder Bat"}, {47, "Desert Bat"}, {48, "Vampire Bat"}, {49, "???"}, {50, "GentleEel"},
        {51, "Lizard"}, {52, "Fissure Lizard"}, {53, "Progenitor Lizard"}, {54, "Brightpetal Lizard"}, {55, "Veigue(team)"},
        {56, "Tortoise"}, {57, "Granitoise"}, {58, "Basaltoise"}, {59, "Marbletoise"}, {60, "Bedwang"},
        {61, "Giant Bee"}, {62, "Stinger Bee"}, {63, "Stabber Bee"}, {64, "Impaler Bee"}, {65, "Automatillery"},
        {66, "Greavereaper"}, {67, "Scuffler Bear"}, {68, "Bear"}, {69, "Scrapper Bear"}, {70, "Brawler Bear"},
        {71, "Nuparikor"}, {72, "Cursed Swordsman"}, {73, "Boar"}, {74, "Wooly Boar"}, {75, "Sabretusk Boar"},
        {76, "Hildisvini"}, {77, "Sabreista"}, {78, "Scimitarista"}, {79, "Eagle"}, {80, "Knight Eagle"},
        {81, "Desert Eagle"}, {82, "Revenant Eagle"}, {83, "Luvah"}, {84, "Filifolia"}, {85, "Filifolia Bud"},
        {86, "Filifolia Root"}, {87, "Filifolia Cactus"}, {88, "Filifolia Sprite"}, {89, "Filifolia Soma"}, {90, "Water Elemental"},
        {91, "Fire Elemental"}, {92, "Ice Elemental"}, {93, "Urizen"}, {94, "Urthona"}, {95, "Tharmas"},
        {96, "Treant"}, {97, "Elder Treant"}, {98, "Plumsap Treant"}, {99, "Nul Bodej"}, {100, "Royal Soldier"},
        {101, "Torch Elemental"}, {102, "Royal Sergeant"}, {103, "Royal Bowman"}, {104, "Royal Pikeman"}, {105, "Cursed Bowman"},
        {106, "Rifleman"}, {107, "Dragoon"}, {108, "Foot Soldier"}, {109, "Skirmisher"}, {110, "Stinger"},
        {111, "Bandit"}, {112, "Bandit Leader"}, {113, "Hunter"}, {114, "Paddlista"}, {115, "Thief"},
        {116, "Daggerista"}, {117, "Wizard"}, {118, "Scepterista"}, {119, "Butcher"}, {120, "Skinner"},
        {121, "Trapper"}, {122, "Poacher"}, {123, "Axe Beak"}, {124, "Lance Beak"}, {125, "Strahteme"},
        {126, "Auger Beak"}, {127, "Artillerista"}, {128, "Nail Spider"}, {129, "Needle Spider"}, {130, "Sickle Spider"},
        {131, "Polong"}, {132, "Forest Goblin"}, {133, "Dune Goblin"}, {134, "Highland Goblin"}, {135, "Goblin Warchief"},
        {136, "Green Slime"}, {137, "Red Slime"}, {138, "Blue Slime"}, {139, "Black Slime"}, {140, "Puolukka"},
        {141, "Carbinista"}, {142, "Shadow Roper"}, {143, "Roper"}, {144, "Sponge Roper"}, {145, "Gyhldeptis"},
        {146, "Stilettoista"}, {147, "Shamshirista"}, {148, "Local Star"}, {149, "Rising Star"}, {150, "Mega Star"},
        {151, "Cosmic Star"}, {152, "Mokkurkalfe"}, {153, "Braying Golem"}, {154, "Keening Golem"}, {155, "Cackling Golem"},
        {156, "Crooning Golem"}, {157, "Gentleman"}, {158, "Illusionist"}, {159, "Mandragora"}, {160, "Mandragora Sprout"},
        {161, "Mandragora Xerophyte"}, {162, "Mandragora Ancient"}, {163, "Mandragora Chenopod"}, {164, "Pooka Helmite"}, {165, "Taunting Helmite"},
        {166, "Sensor Helmite"}, {167, "Trapper Helmite"}, {168, "Harpy"}, {169, "Cyclone Harpy"}, {170, "Tempest Harpy"},
        {171, "Garuda"}, {172, "Wyvern"}, {173, "Progenitor Wyvern"}, {174, "Terminus Wyvern"}, {175, "Canhel"},
        {176, "Stormheart Dragon"}, {177, "Hoarscale Dragon"}, {178, "Crom Cruach"}, {179, "Gloandrake"}, {180, "Duplewyrm"},
        {181, "Chirpee"}, {182, "Peepit"}, {183, "Cawker"}, {184, "Squawkit"}, {185, "Screechee"},
        {186, "Commander"}, {187, "Captain"}, {188, "Equitoid"}, {189, "Lauerwolf"}, {190, "Veritoid"},
        {191, "Hornblower"}, {192, "Riflista"}, {193, "Forbrawyvern"}, {194, "Dullahan"}, {195, "Cursed Soldier"},
        {196, "Snow Goblin"}, {197, "Amber/Kohaku"}, {198, "Royal Guardsman"}, {199, "Cursed Pikeman"}, {200, "Felonfake"},
        {201, "Clawista"}, {202, "Crimson Scorpion"}, {203, "Duelist Scorpion"}, {204, "Violet Scorpion"}, {205, "Stag Beetle"},
        {206, "Thunder Beetle"}, {207, "Gigas Beetle"}, {208, "Inferno Beetle"}, {209, "???"}, {210, "Marchosias"},
        {211, "Mastema"}, {212, "???"}, {213, "Eye of Gluttony"}, {214, "Balor"}, {215, "Abysseon"},
        {216, "Destinion"}, {217, "Rebirtheon"}, {218, "Vespereon"}, {219, "Phantasion"}, {220, "Symphonion"},
        {221, "Rat Specter"}, {222, "Bat Specter"}, {223, "Mammoth Specter"}, {224, "Dragon Specter"}, {225, "Agathion"},
        {226, "Dusk Shade"}, {227, "Daybreak Shade"}, {228, "Nightfall Shade"}, {229, "Melande Shelt"}, {230, "Applefake"},
        {231, "Melonfake"}, {232, "Fake"}, {233, "Cave Raptor"}, {234, "Glacier Raptor"}, {235, "Wasteland Raptor"},
        {236, "Sanctum Raptor"}, {237, "Intulo"}, {238, "Sapphire Weapon"}, {239, "Emerald Weapon"}, {240, "Diamond Weapon"},
        {241, "Ruby Weapon"}, {242, "Proserpina"}, {243, "Dark Turtlez"}, {244, "Peepit?(ZC6)"}, {245, "Proto Veres(ZC8)"},
        {246, "Bear Hellion"}, {247, "Monarch Bat"}, {248, "Nova Wolf"}, {249, "Queen Slime"}, {250, "Mercurius"},
        {251, "Viscera Parasite"}, {252, "Parasite"}, {253, "Dis Pater"}, {254, "Bladehorn Boar"}, {255, "Veres"},
        {256, "Reala(team)"}, {257, "Prairie Eagle"}, {258, "Entrails Parasite"}, {259, "Empty"}, {260, "Empty"},
        {261, "Jelly Roper"}, {262, "Malevolent Star"}, {263, "Blast Helmite"}, {264, "Filifolia Sagua"}, {265, "Martial Fury"},
        {266, "Halphas"}, {267, "Eye of Helios"}, {268, "Gargantua"}, {269, "Decurioid"}, {270, "Trotzig"},
        {271, "Shulmpfaut"}, {272, "Dantalion"}, {273, "Eye of Wrath"}, {274, "Braid Spider"}, {275, "Ruins Goblin"},
        {276, "Legendary Wyvern"}, {277, "Goliath Bat"}, {278, "Labyrinth Lizard"}, {279, "Eye of Acedia"}, {280, "Pantagruel"},
        {281, "Transfixer Bee"}, {282, "Ovinnik"}, {283, "Horkew Kamuy"}, {284, "Natural Star"}, {285, "Sand Drake"},
        {286, "Core Drake"}, {287, "Sky Treant"}, {288, "Midnight Shade"}, {289, "Evocatoid"}, {290, "Hellstorm Harpy"},
        {291, "Wailing Golem"}, {292, "Auxilioid"}, {293, "Hoploid"}, {294, "Platebreaker"}, {295, "Radiant Eagle"},
        {296, "Quackit"}, {297, "Blitzer Bear"}, {298, "Malachite Beetle"}, {299, "Terrane Boar"}, {300, "Sigma"},
        {301, "Luminescent Roper"}, {302, "Paion Slime"}, {303, "Lairguard Dragon"}, {306, "Lilitina"}, {307, "Little Queen(fist)"},
        {308, "Little Queen(chakram)"}, {309, "Little Queen(gun)"}, {310, "Fodra Queen"}, {311, "Poisson"}, {312, "Titan Beetle"},
        {313, "Conflagrite Hulk"}, {314, "Enervite Hulk"}, {315, "Debilitite Hulk"}, {316, "Oblivite Hulk"}, {317, "Glacite Hulk"},
        {318, "Futilite Hulk"}, {319, "Victoria(swimsuit)"}, {320, "Bear Hellion"}, {321, "Monarch Bat"}, {322, "Nova Wolf"},
        {323, "Queen Slime"}, {324, "Mercurius"}, {325, "Parasite"}, {326, "Entrails Parasite"}, {327, "Dis Pater"},
        {328, "Bladehorn Boar"}, {329, "Solomus"}, {330, "Fodra Queen"}
    };

    vars.enemyList = enemyList;

    foreach (var enemy in enemyList)
    {
        settings.Add(enemy.Key.ToString(), false, enemy.Key + ": " + enemy.Value, "enemy_splits");
    }
}

init
{
    vars.hasMetTargetEnemy = false;

    // --- 初始化前次值（避免 start/split/reset 在第一幀出錯）---
    vars.old_startFlag   = (byte)0;
    vars.old_startFlag2  = (byte)0;
    vars.old_blackScreen = 0;
    vars.old_gameState   = (byte)0;

    vars.cur_startFlag   = (byte)0;
    vars.cur_startFlag2  = (byte)0;
    vars.cur_blackScreen = 0;
    vars.cur_gameState   = (byte)0;
    vars.cur_loadingFlag = 0;

    var gameNative = modules.FirstOrDefault(m => m.ModuleName == "GameNative.dll");
    if (gameNative == null) { print("[SigScan] GameNative.dll not found!"); return false; }

    var scn = new SignatureScanner(game, gameNative.BaseAddress, gameNative.ModuleMemorySize);

    // startFlag（shopMenu +0x8）
    var shopMenuTarget = new SigScanTarget(3,
        "48 8D 15 ?? ?? ?? ?? 48 89 05 ?? ?? ?? ?? 48 8D 0D ?? ?? ?? ?? 48 8D 05")
        { OnFound = (p, s, ptr) => ptr + 0x4 + game.ReadValue<int>(ptr) };
    var shopMenuBase = scn.Scan(shopMenuTarget);
    vars.startFlagAddr  = (IntPtr)((long)shopMenuBase + 0x8);

    // startFlag2 = shopMenu +0xC
    vars.startFlag2Addr = shopMenuBase == IntPtr.Zero
        ? IntPtr.Zero
        : (IntPtr)((long)shopMenuBase + 0xC);

    // loadingFlag
    var loadingTarget = new SigScanTarget(2,
        "8B 05 ?? ?? ?? ?? FF C0 89 05 ?? ?? ?? ?? E9 ?? ?? ?? ?? 48 8D 0D")
        { OnFound = (p, s, ptr) => ptr + 0x4 + game.ReadValue<int>(ptr) };
    vars.loadingFlagAddr = scn.Scan(loadingTarget);

    // blackScreen
    var blackScreenTarget = new SigScanTarget(2,
        "8B 05 ?? ?? ?? ?? 89 3D ?? ?? ?? ?? 83 F8")
        { OnFound = (p, s, ptr) => ptr + 0x4 + game.ReadValue<int>(ptr) };
    vars.blackScreenAddr = scn.Scan(blackScreenTarget);

    // gameState
    var gameStateTarget = new SigScanTarget(2,
        "88 05 ?? ?? ?? ?? 33 C0 89 05")
        { OnFound = (p, s, ptr) => ptr + 0x4 + game.ReadValue<int>(ptr) };
    vars.gameStateAddr = scn.Scan(gameStateTarget);

    // entityList（基礎指標）
    var entityListTarget = new SigScanTarget(3,
        "48 8B 05 ?? ?? ?? ?? 89 1D ?? ?? ?? ?? 89 1D")
        { OnFound = (p, s, ptr) => ptr + 0x4 + game.ReadValue<int>(ptr) };
    vars.entityListAddr = scn.Scan(entityListTarget);

    // entityTable
    var entityTableTarget = new SigScanTarget(3,
        "48 8B 15 ?? ?? ?? ?? 45 33 C0 48 89 5C 24")
        { OnFound = (p, s, ptr) => ptr + 0x4 + game.ReadValue<int>(ptr) };
    vars.entityTableAddr = scn.Scan(entityTableTarget);

    // --- 掃描結果輸出 ---
    print("[SigScan] startFlag    = " + vars.startFlagAddr.ToString("X"));
    print("[SigScan] startFlag2   = " + vars.startFlag2Addr.ToString("X"));
    print("[SigScan] loadingFlag  = " + vars.loadingFlagAddr.ToString("X"));
    print("[SigScan] blackScreen  = " + vars.blackScreenAddr.ToString("X"));
    print("[SigScan] gameState    = " + vars.gameStateAddr.ToString("X"));
    print("[SigScan] entityList   = " + vars.entityListAddr.ToString("X"));
    print("[SigScan] entityTable  = " + vars.entityTableAddr.ToString("X"));

    // 任何一個掃描失敗就回傳 false，讓 LiveSplit 重試
    if (vars.startFlagAddr  == IntPtr.Zero ||
        vars.loadingFlagAddr == IntPtr.Zero ||
        vars.blackScreenAddr == IntPtr.Zero ||
        vars.gameStateAddr   == IntPtr.Zero ||
        vars.entityListAddr  == IntPtr.Zero)
    {
        print("[SigScan] One or more scans FAILED, will retry...");
        return false;
    }
}

update
{
    // ★ 先把上一幀存進 old
    vars.old_startFlag   = (byte)vars.cur_startFlag;
    vars.old_startFlag2  = (byte)vars.cur_startFlag2;
    vars.old_blackScreen = (int)vars.cur_blackScreen;
    vars.old_gameState   = (byte)vars.cur_gameState;

    // 再讀新值
    IntPtr gameStateAddr   = (IntPtr)vars.gameStateAddr;
    IntPtr startFlagAddr   = (IntPtr)vars.startFlagAddr;
    IntPtr startFlag2Addr  = (IntPtr)vars.startFlag2Addr;
    IntPtr loadingFlagAddr = (IntPtr)vars.loadingFlagAddr;
    IntPtr blackScreenAddr = (IntPtr)vars.blackScreenAddr;
    IntPtr entityListAddr  = (IntPtr)vars.entityListAddr;

    byte curGameState   = game.ReadValue<byte>(gameStateAddr);
    byte curStartFlag   = game.ReadValue<byte>(startFlagAddr);
    byte curStartFlag2  = game.ReadValue<byte>(startFlag2Addr);
    int  curLoadingFlag = game.ReadValue<int>(loadingFlagAddr);
    int  curBlackScreen = game.ReadValue<int>(blackScreenAddr);

    vars.cur_gameState   = curGameState;
    vars.cur_startFlag   = curStartFlag;
    vars.cur_startFlag2  = curStartFlag2;
    vars.cur_loadingFlag = curLoadingFlag;
    vars.cur_blackScreen = curBlackScreen;

    if (curGameState == 2 && !vars.hasMetTargetEnemy)
    {
        long entityListBase = game.ReadValue<long>(entityListAddr);
        if (entityListBase != 0)
        {
            byte entityCount = game.ReadValue<byte>((IntPtr)(entityListBase + 0x133828));
            if (entityCount > 0 && entityCount <= 100)
            {
                for (int i = 0; i < entityCount; i++)
                {
                    IntPtr addr = (IntPtr)(entityListBase + (i * 0xDF10) + 0x910 + 0x6E);
                    byte val = 0;
                    if (!game.ReadValue<byte>(addr, out val)) continue;

                    if (val != 0 && settings.ContainsKey(val.ToString()) && settings[val.ToString()])
                    {
                        vars.hasMetTargetEnemy = true;
                        print(">>> [AutoSplit] Target Enemy Detected! ID: " + val);
                        break;
                    }
                }
            }
        }
    }
}

start
{
    byte curStartFlag  = (byte)vars.cur_startFlag;
    byte curStartFlag2 = (byte)vars.cur_startFlag2;
    byte oldStartFlag  = (byte)vars.old_startFlag;
    byte oldStartFlag2 = (byte)vars.old_startFlag2;

    bool isMatch  = curStartFlag == 7 && curStartFlag2 == 8;
    bool wasMatch = oldStartFlag == 7 && oldStartFlag2 == 8;

    if (isMatch && !wasMatch)
    {
        vars.hasMetTargetEnemy = false;
        return true;
    }
}

isLoading
{
    int loadingFlag = (int)vars.cur_loadingFlag;
    return loadingFlag != 72;
}

split
{
    bool metEnemy    = (bool)vars.hasMetTargetEnemy;
    int  oldBlack    = (int)vars.old_blackScreen;
    int  curBlack    = (int)vars.cur_blackScreen;

    if (metEnemy && oldBlack == 2 && curBlack == 0)
    {
        vars.hasMetTargetEnemy = false;
        return true;
    }
}

reset
{
    byte oldState = (byte)vars.old_gameState;
    byte curState = (byte)vars.cur_gameState;

    return oldState != 1 && curState == 1;
}
