state("Death In Abyss") { }

startup 
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.LoadSceneManager = true;

    // 定義你想要監控的 PlayMaker 變數名稱
    vars.BoolSettings = new Dictionary<string, string>
    {
        { "Ingame", "Ingame" },
    };

    vars.IntSettings = new Dictionary<string, string>
    {
        { "Mission_ID", "Mission_ID" },
    };

    vars.GameObjectSettings = new Dictionary<string, string>
    {
        { "Biome_Manager", "Biome_Manager" },
    };


    // 將 Dictionary 內容自動加入 LiveSplit 設定選單
    foreach (var entry in vars.IntSettings)
    {
        settings.Add(entry.Key, true, entry.Value);
    }

    foreach (var entry in vars.BoolSettings)
    {
        settings.Add(entry.Key, true, entry.Value);
    }

    foreach (var entry in vars.GameObjectSettings)
    {
        settings.Add(entry.Key, true, entry.Value);
    }
}

init
{
    // 初始化儲存舊值的字典
    vars.OldBoolValues = new Dictionary<string, bool>();
    vars.OldIntValues = new Dictionary<string, int>();
    current.BossActiveStateName = "";
    vars.LastStatePtr = IntPtr.Zero;
    vars.BiomeManagerIdx = null;

    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        vars.BiomeManagerIdx = null;

        var pmg = mono["PlayMaker", "PlayMakerGlobals"];

        vars.Helper["IntVariables"] = mono.MakeArray<IntPtr>(pmg, "instance", "variables", "intVariables");
        vars.Helper["IntVariables"].Update(game);


        vars.Helper["BoolVariables"] = mono.MakeArray<IntPtr>(pmg, "instance", "variables", "boolVariables");
        vars.Helper["BoolVariables"].Update(game);

        vars.Helper["GameObjectVariables"] = mono.MakeArray<IntPtr>(pmg, "instance", "variables", "gameObjectVariables");
        vars.Helper["GameObjectVariables"].Update(game);

        IntPtr[] intVariables = vars.Helper["IntVariables"].Current;
        IntPtr[] boolVariables = vars.Helper["BoolVariables"].Current;
        IntPtr[] gameObjectVariables = vars.Helper["GameObjectVariables"].Current;

        vars.OffsetName = mono["PlayMaker", "NamedVariable"]["name"];

        vars.BoolOffsetValue = mono["PlayMaker", "FsmBool"]["value"];
        vars.IntOffsetValue = mono["PlayMaker", "FsmInt"]["value"];
        vars.GameObjectOffsetValue = mono["PlayMaker", "FsmGameObject"]["value"];

        // 讀取名稱清單
        vars.IntVariableNames = intVariables.Select(variable => vars.Helper.ReadString(variable + vars.OffsetName)).ToArray();
        vars.BoolVariablesNames = boolVariables.Select(variable => vars.Helper.ReadString(variable + vars.OffsetName)).ToArray();
        vars.GameObjectVariableNames = gameObjectVariables.Select(variable => vars.Helper.ReadString(variable + vars.OffsetName)).ToArray();

        // 重建索引白名單
        vars.IntVariableIndices = intVariables.Select((_, i) => i).Where(i => vars.IntSettings.ContainsKey(vars.IntVariableNames[i])).ToArray();
        vars.BoolVariablesIndices = boolVariables.Select((_, i) => i).Where(i => vars.BoolSettings.ContainsKey(vars.BoolVariablesNames[i])).ToArray();
        vars.GameObjectVariableIndices = gameObjectVariables.Select((_, i) => i).Where(i => vars.GameObjectSettings.ContainsKey(vars.GameObjectVariableNames[i])).ToArray();

        return true;
    });
}

update
{
    // 確保 PlayMaker 變數陣列已載入
    var GameObjectPointers = vars.Helper["GameObjectVariables"].Current;
    if (GameObjectPointers == null) return;

    // --- 1. 動態尋找 Biome_Manager 索引 (僅在尚未找到或失效時執行) ---
    if (vars.BiomeManagerIdx == null)
    {
        for (int i = 0; i < vars.GameObjectVariableNames.Length; i++)
        {
            if (vars.GameObjectVariableNames[i] == "Biome_Manager")
            {
                vars.BiomeManagerIdx = i;
                // print(">>> [ASL] Get Biome_Manager Index = " + i);
                break;
            }
        }
    }

    // 確保索引合法
    if (vars.BiomeManagerIdx == null || vars.BiomeManagerIdx >= GameObjectPointers.Length) return;

    // --- 2. 逐層讀取記憶體指標 (加上 Null Check 保護) ---
    // 取得 PlayMaker 變數中的 GameObject 指標
    IntPtr fsmGameObjectPtr = vars.Helper.Read<IntPtr>(GameObjectPointers[vars.BiomeManagerIdx] + vars.GameObjectOffsetValue);
    if (fsmGameObjectPtr == IntPtr.Zero) return;

    // 取得 Native GameObject (Unity 底層物件)
    IntPtr nativeGO = game.ReadPointer(fsmGameObjectPtr + 0x10);
    if (nativeGO == IntPtr.Zero) return;

    // 取得 Component List (組件列表)
    IntPtr compList = game.ReadPointer(nativeGO + 0x30);
    if (compList == IntPtr.Zero) return;

    // 取得特定 Index 的組件 (Index 6 = 偏移 0x68)
    // 這裡存放的是該 Biome_Manager 上的 PlayMakerFSM 或相關腳本
    IntPtr componentPtr = game.ReadPointer(compList + 0x68);
    if (componentPtr == IntPtr.Zero) return;

    // 進入 Managed Script 領域
    IntPtr managedScript = game.ReadPointer(componentPtr + 0x28);
    if (managedScript == IntPtr.Zero) return;

    // 取得 FSM 核心結構 (fsmFieldPtr)
    IntPtr fsmFieldPtr = game.ReadPointer(managedScript + 0x18);
    if (fsmFieldPtr == IntPtr.Zero) return;

    // --- 3. 讀取 Boss 狀態名稱 (效能優化版) ---
    // 取得當前活躍狀態名稱的指標 (activeStateNameFieldPtr)
    IntPtr activeStateNameFieldPtr = game.ReadPointer(fsmFieldPtr + 0xE8);
    
    // 核心優化：只有當「狀態指標」改變時，才去重新讀取字串內容
    if (activeStateNameFieldPtr != vars.LastStatePtr) 
    {
        if (activeStateNameFieldPtr != IntPtr.Zero)
        {
            // 讀取 Unity String 的字元長度
            int count = game.ReadValue<int>(activeStateNameFieldPtr + 0x10) * 2;
            
            // 安全限制：避免讀到異常巨大的記憶體區塊
            if (count > 0 && count < 512) 
            {
                current.BossActiveStateName = game.ReadString(activeStateNameFieldPtr + 0x14, count);
                // 解除註解可用於除錯
                // print(">>> [FSM] 狀態切換: " + current.BossActiveStateName);
            }
        }
        else 
        {
            current.BossActiveStateName = "";
        }
        
        // 更新上次的指標位置，避免重複執行 ReadString
        vars.LastStatePtr = activeStateNameFieldPtr; 
    }
}

start
{
    // 取得指標陣列
    var boolPointers = vars.Helper["BoolVariables"].Current;
    if (boolPointers == null) return false;

    foreach (var i in vars.BoolVariablesIndices)
    {
        var name = vars.BoolVariablesNames[i];
        
        // 讀取最新值
        bool val = vars.Helper.Read<bool>(boolPointers[i] + vars.BoolOffsetValue);
        
        // 測試用：我們先拿掉 settings[name] 的判斷，直接硬比對名稱
        if (name == "Ingame" && val)
        {
            // print(">>> [START Trigger] Detect Ingame True！");
            return true; 
        }
    }
}

split
{
    // --- 1. Mission ID 邏輯優化 ---
    var intPointers = vars.Helper["IntVariables"].Current;
    if (intPointers != null)
    {
        foreach (var i in vars.IntVariableIndices)
        {
            var name = vars.IntVariableNames[i];
            int currentValue = vars.Helper.Read<int>(intPointers[i] + vars.IntOffsetValue);
            int oldValue;
            
            if (vars.OldIntValues.TryGetValue(name, out oldValue)) 
            {
                if (currentValue != oldValue)
                {
                    vars.OldIntValues[name] = currentValue; // 立即更新

                    if (name == "Mission_ID" && settings[name])
                    {
                        // print(">>> [Mission Split] Next Mission: " + oldValue + " -> " + currentValue);
                        // 只要 ID 增加（代表進入新關卡或過場結束），就 Split
                        // 或者是只要不等於舊值且不為 0
                        if (currentValue == oldValue + 1 && currentValue != 0)
                        {
                            return true;
                        }
                    }
                }
            }
            else {
                vars.OldIntValues[name] = currentValue;
            }
        }
    }

    // --- 2. Boss 狀態邏輯優化 ---
    if (current.BossActiveStateName != old.BossActiveStateName)
    {
        string state = current.BossActiveStateName.Trim();
        // 增加更多可能的 Boss 啟動或結束狀態名
        if (state == "BabyDetected" || state == "boom!")
        {
            return true;
        }
    }
}
onReset
{
    // 當玩家手動按下 LiveSplit 的 Reset 鍵時，清空緩存
    vars.OldBoolValues.Clear();
    vars.OldIntValues.Clear();
    vars.LastStatePtr = IntPtr.Zero;
    current.BossActiveStateName = "";
    // print(">>> [ASL] Timer Reset: Cache Cleared");
}