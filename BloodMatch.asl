state("Game")
{
    string64 mapName: "Game.exe", 0x53EF78, 0x84, 0x0;
    byte startFlag: "Game.exe", 0x53EF7C, 0x29;
    float loadTimer: "Game.exe", 0x53EF78, 0x8;
    float startTimer: "Game.exe", 0x53EF7C, 0x2C; 
}

init
{
    // 建立一個紀錄已訪問地圖的清單
    vars.visitedMaps = new List<string>();
}

onStart
{
    // 重置紀錄
    vars.visitedMaps.Clear();
    if (current.mapName != null)
    {
        vars.visitedMaps.Add(current.mapName);
    }
}

update
{
    if(current.startFlag != old.startFlag)
    {
        print("Flag: " + old.startFlag + " -> " + current.startFlag);
    }
}

start
{
    if (old.startFlag == 1 && current.startFlag == 0)
    {
        print(">>> START! <<<");
        return true;
    }
}

split
{
    // 只有在地圖名稱改變且不為空時才判斷
    if (old.mapName != current.mapName && !string.IsNullOrEmpty(current.mapName))
    {
        // 1. 排除進出死亡地圖
        if (current.mapName == "Data/Maps/DeathMap.eem" || old.mapName == "Data/Maps/DeathMap.eem")
        {
            return false; 
        }

        // 2. 關鍵條件：只有地圖名稱包含 "Match" 才允許 Split
        if (!current.mapName.Contains("Match"))
        {
            print(">>> IGNORED: [" + current.mapName + "] is not a Match map. <<<");
            return false;
        }

        // 3. 檢查是否是重複的地圖（死掉重跑）
        if (vars.visitedMaps.Contains(current.mapName))
        {
            print(">>> REPLAY DETECTED: [" + current.mapName + "] already split. <<<");
            return false;
        }

        // 4. 通過以上所有檢查，紀錄並執行 Split
        vars.visitedMaps.Add(current.mapName);
        print(">>> MATCH SPLIT: [" + current.mapName + "] <<<");
        return true;
    }
}

isLoading
{
    // 第一關（未 Split 過）用 startTimer，之後用 loadTimer
    if (timer.CurrentSplitIndex == 0)
    {
        return current.startTimer > 0.0;
    }
    else
    {
        return current.loadTimer > 0.0;
    }
}