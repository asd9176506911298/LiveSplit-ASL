state("Webhead") 
{
    float TimeSeconds    : "Engine.dll", 0x5EBCA0, 0x34, 0x118, 0x38, 0x0, 0x3E4;
    uint Pauser          : "Engine.dll", 0x5EBCA0, 0x34, 0x118, 0x38, 0x0, 0x468;
    string64 mapName     : "Engine.dll", 0x5EBCA0, 0x34, 0x14C, 0x0;
    
    // 最終 BOSS Split 用的變數
    int CurrentLevel     : "Engine.dll", 0x5EBCA0, 0x34, 0x118, 0x38, 0x0, 0x548, 0x58C, 0x438;
    byte LevelComplete7  : "Engine.dll", 0x5EBCA0, 0x34, 0x118, 0x38, 0x0, 0x548, 0x58C, 0x488;
    string128 GUIPageName: "Engine.dll", 0x4728D0, 0x38, 0x40, 0x64, 0x24C, 0x0;
}

startup
{
    if (timer.CurrentTimingMethod == TimingMethod.RealTime)
    {
        timer.CurrentTimingMethod = TimingMethod.GameTime;
    }
    
    refreshRate = 60;
}

init
{
    vars.TotalGameTime = 0.0;
    vars.LastGUIPageName = "";
    vars.BossSplitTriggered = false;
    
    // 用來追蹤變化的變數
    vars.LastCurrentLevel = -1;
    vars.LastLevelComplete7 = -1;
    vars.LastCleanedGUIPageName = "";
    vars.LastCleanedMapName = "";
}

start
{
    if (current.cleanedMap.Contains("cb3_citystreet") && old.cleanedMap.Contains("startup"))
    {
        vars.TotalGameTime = 0.0;
        vars.BossSplitTriggered = false;
        //print(">>> TIMER STARTED <<<");
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
        //print(">>> mapName CHANGED: [" + vars.LastCleanedMapName + "] -> [" + current.cleanedMap + "]");
        //print("    (Raw: [" + (current.mapName ?? "NULL") + "])");
        vars.LastCleanedMapName = current.cleanedMap;
    }
    
    if (current.CurrentLevel != vars.LastCurrentLevel)
    {
        //print(">>> CurrentLevel CHANGED: " + vars.LastCurrentLevel + " -> " + current.CurrentLevel);
        vars.LastCurrentLevel = current.CurrentLevel;
    }
    
    if (current.LevelComplete7 != vars.LastLevelComplete7)
    {
        //print(">>> LevelComplete7 CHANGED: " + vars.LastLevelComplete7 + " -> " + current.LevelComplete7);
        vars.LastLevelComplete7 = current.LevelComplete7;
    }
    
    if (current.cleanedGUIPageName != vars.LastCleanedGUIPageName)
    {
        //print(">>> GUIPageName CHANGED: [" + vars.LastCleanedGUIPageName + "] -> [" + current.cleanedGUIPageName + "]");
        //print("    (Raw: [" + (current.GUIPageName ?? "NULL") + "])");
        vars.LastCleanedGUIPageName = current.cleanedGUIPageName;
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
    // === 最終 BOSS Split 條件檢查（只在接近條件時印出）===
    if (current.CurrentLevel == 7 && current.LevelComplete7 == 1)
    {
        bool cond1 = !vars.BossSplitTriggered;
        bool cond2 = current.CurrentLevel == 7;
        bool cond3 = current.LevelComplete7 == 1;
        bool cond4 = vars.LastGUIPageName.Contains("pagemissioncomplete");
        bool cond5 = current.cleanedGUIPageName == "";
        
        /*
        print("--- BOSS SPLIT CHECK ---");
        print("  [" + (cond1 ? "✓" : "✗") + "] Not triggered yet");
        print("  [" + (cond2 ? "✓" : "✗") + "] CurrentLevel == 7 (actual: " + current.CurrentLevel + ")");
        print("  [" + (cond3 ? "✓" : "✗") + "] LevelComplete7 == 1 (actual: " + current.LevelComplete7 + ")");
        print("  [" + (cond4 ? "✓" : "✗") + "] LastGUI has 'pagemissioncomplete' (actual: [" + vars.LastGUIPageName + "])");
        print("  [" + (cond5 ? "✓" : "✗") + "] CurrentGUI is empty (actual: [" + current.cleanedGUIPageName + "])");
        */
        
        if (cond1 && cond2 && cond3 && cond4 && cond5)
        {
            //print("!!! FINAL BOSS SPLIT TRIGGERED !!!");
            vars.BossSplitTriggered = true;
            return true;
        }
    }
    
    // 儲存上一幀的 GUI Page Name
    vars.LastGUIPageName = current.cleanedGUIPageName;
    
    // === 一般關卡 Split ===
    if (current.cleanedMap != old.cleanedMap && !string.IsNullOrEmpty(current.cleanedMap))
    {
        if (!current.cleanedMap.Contains("startup"))
        {
            // 排除 wharf_train.whr -> wharf_train 的情況
            if (old.cleanedMap == "wharf_train.whr" && current.cleanedMap == "wharf_train")
            {
                return false;
            }
            
            print("--- Level Split: [" + old.cleanedMap + "] -> [" + current.cleanedMap + "] ---");
            return true;
        }
    }
}

isLoading
{
    return true; 
}
