state("Death In Abyss") { }

startup 
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.LoadSceneManager = true;

    vars.BoolSettings = new Dictionary<string, string> { { "Ingame", "Ingame" } };
    vars.IntSettings = new Dictionary<string, string> { { "Mission_ID", "Mission_ID" } };
    vars.GameObjectSettings = new Dictionary<string, string> { { "Biome_Manager", "Biome_Manager" } };

    foreach (var entry in vars.IntSettings) settings.Add(entry.Key, true, entry.Value);
    foreach (var entry in vars.BoolSettings) settings.Add(entry.Key, true, entry.Value);
    foreach (var entry in vars.GameObjectSettings) settings.Add(entry.Key, true, entry.Value);
}

init
{
    vars.OldIntValues = new Dictionary<string, int>();
    current.BossActiveStateName = "";
    vars.LastStatePtr = IntPtr.Zero;
    vars.FsmFieldPtr = IntPtr.Zero; 
    vars.BiomeManagerIdx = null;
    
    // 初始化
    vars.BoolVariablesIndices = new int[0];
    vars.IntVariableIndices = new int[0];
    vars.BoolVariablesNames = new string[0];
    vars.IntVariableNames = new string[0];
    vars.Initialized = false;

    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        var pmg = mono["PlayMaker", "PlayMakerGlobals"];
        vars.Helper["IntVariables"] = mono.MakeArray<IntPtr>(pmg, "instance", "variables", "intVariables");
        vars.Helper["BoolVariables"] = mono.MakeArray<IntPtr>(pmg, "instance", "variables", "boolVariables");
        vars.Helper["GameObjectVariables"] = mono.MakeArray<IntPtr>(pmg, "instance", "variables", "gameObjectVariables");

        vars.OffsetName = mono["PlayMaker", "NamedVariable"]["name"];
        vars.BoolOffsetValue = mono["PlayMaker", "FsmBool"]["value"];
        vars.IntOffsetValue = mono["PlayMaker", "FsmInt"]["value"];
        vars.GameObjectOffsetValue = mono["PlayMaker", "FsmGameObject"]["value"];

        return true;
    });
}

update
{
    // 如果索引還沒準備好，在 update 裡嘗試掃描（直到成功抓到變數）
    if (!vars.Initialized)
    {
        vars.Helper["IntVariables"].Update(game);
        vars.Helper["BoolVariables"].Update(game);
        IntPtr[] intVars = vars.Helper["IntVariables"].Current;
        IntPtr[] boolVars = vars.Helper["BoolVariables"].Current;

        if (intVars != null && boolVars != null && intVars.Length > 0 && boolVars.Length > 0)
        {
            vars.IntVariableNames = intVars.Select((Func<IntPtr, string>)(v => vars.Helper.ReadString(v + (int)vars.OffsetName))).ToArray();
            vars.BoolVariablesNames = boolVars.Select((Func<IntPtr, string>)(v => vars.Helper.ReadString(v + (int)vars.OffsetName))).ToArray();

            vars.IntVariableIndices = intVars.Select((_, i) => i).Where(i => vars.IntSettings.ContainsKey(vars.IntVariableNames[i])).ToArray();
            vars.BoolVariablesIndices = boolVars.Select((_, i) => i).Where(i => vars.BoolSettings.ContainsKey(vars.BoolVariablesNames[i])).ToArray();

            if (vars.BoolVariablesIndices.Length > 0)
            {
                // print(">>> [ASL] 成功偵測到 PlayMaker 全域變數！");
                vars.Initialized = true;
            }
        }
    }

    var GameObjectPointers = vars.Helper["GameObjectVariables"].Current;
    if (GameObjectPointers == null) return;

    // 尋找 Biome_Manager
    if (vars.BiomeManagerIdx == null)
    {
        vars.Helper["GameObjectVariables"].Update(game);
        IntPtr[] ptrs = vars.Helper["GameObjectVariables"].Current;
        if (ptrs != null) {
            var names = ptrs.Select((Func<IntPtr, string>)(v => vars.Helper.ReadString(v + (int)vars.OffsetName))).ToArray();
            for (int i = 0; i < names.Length; i++)
            {
                if (names[i] == "Biome_Manager") { vars.BiomeManagerIdx = i; break; }
            }
        }
    }

    // 讀取 Boss 狀態 (FSM)
    if (vars.BiomeManagerIdx != null && vars.BiomeManagerIdx < GameObjectPointers.Length)
    {
        if (vars.FsmFieldPtr == IntPtr.Zero)
        {
            IntPtr fsmGameObjectPtr = vars.Helper.Read<IntPtr>(GameObjectPointers[vars.BiomeManagerIdx] + (int)vars.GameObjectOffsetValue);
            if (fsmGameObjectPtr != IntPtr.Zero)
            {
                IntPtr nativeGO = vars.Helper.Read<IntPtr>(fsmGameObjectPtr + 0x10);
                if (nativeGO != IntPtr.Zero) {
                    IntPtr compList = vars.Helper.Read<IntPtr>(nativeGO + 0x30);
                    IntPtr componentPtr = vars.Helper.Read<IntPtr>(compList + 0x68);
                    IntPtr managedScript = vars.Helper.Read<IntPtr>(componentPtr + 0x28);
                    vars.FsmFieldPtr = vars.Helper.Read<IntPtr>(managedScript + 0x18);
                }
            }
        }

        if (vars.FsmFieldPtr != IntPtr.Zero)
        {
            IntPtr activeStateNameFieldPtr = vars.Helper.Read<IntPtr>(vars.FsmFieldPtr + 0xE8);
            if (activeStateNameFieldPtr != vars.LastStatePtr) 
            {
                if (activeStateNameFieldPtr != IntPtr.Zero)
                {
                    int count = game.ReadValue<int>(activeStateNameFieldPtr + 0x10) * 2;
                    if (count > 0 && count < 512) 
                    {
                        current.BossActiveStateName = game.ReadString(activeStateNameFieldPtr + 0x14, count);
                    }
                }
                else 
                {
                    current.BossActiveStateName = "";
                    vars.FsmFieldPtr = IntPtr.Zero;
                }
                vars.LastStatePtr = activeStateNameFieldPtr; 
            }
        }
    }
}

start
{
    if (!vars.Initialized) return false;
    var boolPointers = vars.Helper["BoolVariables"].Current;
    
    foreach (int i in vars.BoolVariablesIndices)
    {
        if (vars.BoolVariablesNames[i] == "Ingame")
        { 
            bool val = vars.Helper.Read<bool>(boolPointers[i] + (int)vars.BoolOffsetValue);
            if (val) return true;
        }
    }
    return false;
}

split
{
    if (!vars.Initialized) return false;

    // Mission ID 邏輯
    var intPointers = vars.Helper["IntVariables"].Current;
    foreach (int i in vars.IntVariableIndices)
    {
        var name = vars.IntVariableNames[i];
        if (name == "Mission_ID")
        {
            int val = vars.Helper.Read<int>(intPointers[i] + (int)vars.IntOffsetValue);
            int oldVal;
            vars.OldIntValues.TryGetValue(name, out oldVal);
            
            if (val != oldVal) 
            {
                // 印出數值變化：例如 [ASL] Mission_ID 變更: 1 -> 2
                // print(">>> [ASL] Mission_ID 變更: " + oldVal + " -> " + val);
                
                vars.OldIntValues[name] = val;

                // 觸發 Split 的條件：數值 +1 且不是 0，且設定勾選
                if (settings[name] && val == oldVal + 1 && val != 0) 
                {
                    // print(">>> [ASL] 觸發 Split (Mission_ID 增加)");
                    return true;
                }
            }
        }
    }
    // Boss 狀態邏輯
    if (current.BossActiveStateName != old.BossActiveStateName)
    {
        string s = current.BossActiveStateName.Trim();
        if (s == "BabyDetected" || s == "boom!") return true;
    }
}

onReset
{
    vars.OldBoolValues.Clear();
    vars.OldIntValues.Clear();
    vars.LastStatePtr = IntPtr.Zero;
    current.BossActiveStateName = "";
}
