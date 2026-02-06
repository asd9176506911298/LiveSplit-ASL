state("Webhead") 
{
    float TimeSeconds    : "Engine.dll", 0x5EBCA0, 0x34, 0x118, 0x38, 0x0, 0x3E4;
    uint Pauser          : "Engine.dll", 0x5EBCA0, 0x34, 0x118, 0x38, 0x0, 0x468;
    string64 mapName     : "Engine.dll", 0x5EBCA0, 0x34, 0x14C, 0x0;
    
    // 最終 BOSS Split 用的變數
    int CurrentLevel     : "Engine.dll", 0x5EBCA0, 0x34, 0x118, 0x38, 0x0, 0x548, 0x58C, 0x438;
    int ArrayBase         : "Engine.dll", 0x5EBCA0, 0x34, 0x118, 0x38, 0x0, 0x548, 0x58C, 0x46C;
    int LevelComplete1  : "Engine.dll", 0x5EBCA0, 0x34, 0x118, 0x38, 0x0, 0x548, 0x58C, 0x46C;
    byte LevelComplete7  : "Engine.dll", 0x5EBCA0, 0x34, 0x118, 0x38, 0x0, 0x548, 0x58C, 0x488;
    string128 GUIPageName: "Engine.dll", 0x4728D0, 0x38, 0x40, 0x64, 0x24C, 0x0;
}

startup
{
    if (timer.CurrentTimingMethod == TimingMethod.RealTime)
    {
        timer.CurrentTimingMethod = TimingMethod.GameTime;
    }
    
    refreshRate = 120;
}

init
{
    vars.TotalGameTime = 0.0;
    vars.LastGUIPageName = "";
    vars.BossSplitTriggered = false;
    vars.LastSplitLevel = -1;  // 記錄上次 split 的關卡

    
    // 用來追蹤變化的變數
    vars.LastCurrentLevel = -1;
    vars.LastLevelComplete7 = -1;
    vars.LastCleanedGUIPageName = "";
    vars.LastCleanedMapName = "";
    vars.LevelArrayPtr = new DeepPointer("Engine.dll", 0x5EBCA0, 0x34, 0x118, 0x38, 0x0, 0x548, 0x58C, 0x46C);
}

start
{
    if (current.cleanedMap.Contains("cb3_citystreet") && old.cleanedMap.Contains("startup"))
    {
        vars.TotalGameTime = 0.0;
        vars.BossSplitTriggered = false;
        vars.LastSplitLevel = -1;  // 重置
        print(">>> TIMER STARTED <<<");
        return true;
    }
}

update
{
    current.cleanedMap = (current.mapName ?? "").Trim().ToLower();
    current.cleanedGUIPageName = (current.GUIPageName ?? "").Trim().ToLower();
    
    // === 只在變化時印出 ===
    if (current.cleanedMap != vars.LastCleanedMapName)
    {
        print(">>> mapName CHANGED: [" + vars.LastCleanedMapName + "] -> [" + current.cleanedMap + "]");
        print("    (Raw: [" + (current.mapName ?? "NULL") + "])");
        vars.LastCleanedMapName = current.cleanedMap;
    }
    
    if (current.CurrentLevel != vars.LastCurrentLevel)
    {
        print(">>> CurrentLevel CHANGED: " + vars.LastCurrentLevel + " -> " + current.CurrentLevel);
        vars.LastCurrentLevel = current.CurrentLevel;
    }
    
    if (current.LevelComplete7 != vars.LastLevelComplete7)
    {
        print(">>> LevelComplete7 CHANGED: " + vars.LastLevelComplete7 + " -> " + current.LevelComplete7);
        vars.LastLevelComplete7 = current.LevelComplete7;
    }
    
    if (current.cleanedGUIPageName != vars.LastCleanedGUIPageName)
    {
        print(">>> GUIPageName CHANGED: [" + vars.LastCleanedGUIPageName + "] -> [" + current.cleanedGUIPageName + "]");
        print("    (Raw: [" + (current.GUIPageName ?? "NULL") + "])");
        vars.LastCleanedGUIPageName = current.cleanedGUIPageName;
    }

        // 1. 指標走到陣列基址 (0x58C)
    var basePtr = new DeepPointer("Engine.dll", 0x5EBCA0, 0x34, 0x118, 0x38, 0x0, 0x548, 0x58C, 0x46C);

    // 2. 取得基址後加上動態偏移
    IntPtr baseAddress;
    if (basePtr.DerefOffsets(game, out baseAddress))
    {
        // 3. 計算動態偏移: 0x46C + (CurrentLevel * 4)
        int dynamicOffset = (current.CurrentLevel * 4);
        
        // 4. 讀取值
        int value;
        if (game.ReadValue<int>(baseAddress + dynamicOffset, out value))
        {
            current.LevelCompleteVal = value;
        }
        else
        {
            current.LevelCompleteVal = 0; // 讀取失敗時的預設值
        }
    }
    else
    {
        current.LevelCompleteVal = 0; // 無法取得基址時的預設值
    }

    // 監控變化
    if (current.LevelCompleteVal != old.LevelCompleteVal)
    {
        print(">>> Level " + current.CurrentLevel + " Status: " + current.LevelCompleteVal);
    }
}

gameTime
{
    bool isMenu = current.cleanedMap.Contains("startup") || current.cleanedMap == "";
    
    if (!isMenu)
    {
        if (current.TimeSeconds > old.TimeSeconds)
        {
            double delta = (double)(current.TimeSeconds - old.TimeSeconds);
            if (delta < 1.0) 
            {
                vars.TotalGameTime += delta;
            }
        }
        else if (current.TimeSeconds == old.TimeSeconds && current.Pauser != 0)
        {
            vars.TotalGameTime += (1.0 / refreshRate);
        }
        else if (current.TimeSeconds < old.TimeSeconds && current.TimeSeconds > 0 && current.TimeSeconds < 1.0)
        {
            vars.TotalGameTime += (double)current.TimeSeconds;
        }
    }

    return TimeSpan.FromSeconds(vars.TotalGameTime);
}

split
{
    // === 檢查是否在選單 ===
    bool isInMenu = current.cleanedMap.Contains("startup") || current.cleanedMap == "";
    
    // === 最終 BOSS Split ===
    if (current.CurrentLevel == 7 && current.LevelComplete7 == 1)
    {
        bool cond1 = !vars.BossSplitTriggered;
        bool cond2 = current.CurrentLevel == 7;
        bool cond3 = current.LevelComplete7 == 1;
        bool cond4 = vars.LastGUIPageName.Contains("pagemissioncomplete");
        bool cond5 = current.cleanedGUIPageName == "";
        
        if (cond1 && cond2 && cond3 && cond4 && cond5)
        {
            print("!!! FINAL BOSS SPLIT TRIGGERED !!!");
            vars.BossSplitTriggered = true;
            return true;
        }
    }
    
    vars.LastGUIPageName = current.cleanedGUIPageName;
    
    // === Level 0 教學關 Split（特殊處理）===
    if (current.CurrentLevel == 0 && 
        current.cleanedMap.Contains("cb3_citystreet") &&  // 只在教學關地圖
        current.CurrentLevel != vars.LastSplitLevel &&
        old.LevelCompleteVal == 0 && 
        current.LevelCompleteVal == 1)
    {
        print("--- SPLIT: Level 0 (Tutorial) Complete! ---");
        vars.LastSplitLevel = 0;
        return true;
    }
    
    // === 一般關卡 Split（Level 1-7）===
    if (!isInMenu && 
        current.CurrentLevel > 0 &&  // 排除其他 Level 0 情況
        current.CurrentLevel != 7 &&
        current.CurrentLevel != vars.LastSplitLevel &&
        old.LevelCompleteVal == 0 && 
        current.LevelCompleteVal == 1)
    {
        print("--- SPLIT: Level " + current.CurrentLevel + " Complete! ---");
        vars.LastSplitLevel = current.CurrentLevel;
        return true;
    }
}

isLoading
{
    return true; 
}
