state("godotsteam.36.editor.windows.64")
{

    //SceneTree -> currentScene -> name
    string100 sceneName : 0x42EE330, 0x268, 0x150, 0x10, 0x0;
}

startup
{
    vars.SCENETREE_ROOT_WINDOW_OFFSET        = 0x168; // Window*                           SceneTree::root

    vars.OBJECT_SCRIPT_INSTANCE_OFFSET       = 0x078; // ScriptInstance*                   Object::script_instance
    vars.SCRIPTINSTANCE_SCRIPT_REF_OFFSET    = 0x010; // Ref<GDScript>   nochange          GDScriptInstance::script
    vars.SCRIPTINSTANCE_MEMBERS_OFFSET       = 0x038; // Vector<Variant> nochange          GDScriptInstance::members

    vars.GDSCRIPT_MEMBER_MAP_OFFSET          = 0x200; // HashMap<StringName, MemberInfo>   GDScript::member_indices
    vars.GDSCRIPT_MEMBER_MAP_Count_OFFSET    = 0x210; 

    vars.NODE_NAME_OFFSET                    = 0x150; // StringName                        Node::Data::name
    vars.NODE_CHILDREN_OFFSET                = 0x128; // HashMap<StringName, Node*>        Node::Data::children
}

init
{
    vars.ReadStringName = (Func<IntPtr, string>) ((ptr) => {
        var stringPtr = game.ReadValue<IntPtr>(ptr + 0x10);
        var output = game.ReadString(stringPtr, 255);
        
        return output;
    });



   vars.FindChild = (Func<IntPtr, string, IntPtr>)((node, targetName) =>
    {
        // 讀取子節點陣列的起點指標
        var arrayPtr = game.ReadValue<IntPtr>((IntPtr)(node + vars.NODE_CHILDREN_OFFSET));
        
        // 如果連陣列起點都是空的，直接結束
        if (arrayPtr == IntPtr.Zero) return IntPtr.Zero;

        int i = 0;
        int safetyCounter = 0; // 安全計數器，防止無窮迴圈

        while (safetyCounter < 500) // 假設一般節點底下的子節點不會超過 500 個
        {
            // 算出下一個子節點指標的記憶體位址，並讀取它
            var child = game.ReadValue<IntPtr>(arrayPtr + (0x8 * i));
            
            // 【結束條件】如果讀出來的子節點指標是 0x0 (Null)，代表陣列結束了
            if (child == IntPtr.Zero) 
            {
                break; 
            }

            // 讀取子節點的名稱
            var nameAddress = game.ReadValue<IntPtr>((IntPtr)(child + vars.NODE_NAME_OFFSET));
            var childName = vars.ReadStringName(nameAddress);
            
            // print("Child [" + i + "]: " + childName);

            // 如果名字符合你要尋找的 targetName，就直接回傳這個子節點的指標
            if (childName == targetName)
            {
                return child;
            }

            i++;
            safetyCounter++;
        }

        return IntPtr.Zero; // 沒找到就回傳空指標
    });

    vars.GetMemberOffsets = (Func<IntPtr, Dictionary<string, int>>)((script) =>
{
    var result = new Dictionary<string, int>();
    
    // 1. 取得 Map 起始點 (GDScript + 0x208)
    IntPtr mapHeaderPtr = game.ReadValue<IntPtr>((IntPtr)(script + vars.GDSCRIPT_MEMBER_MAP_OFFSET));

    if (mapHeaderPtr == IntPtr.Zero) return result;

    // 2. 根據你的 CE 截圖修正 Map 標頭讀取
    IntPtr nil  = game.ReadValue<IntPtr>(mapHeaderPtr + 0x08); // 修正：nil 在 +0x08
    IntPtr root = game.ReadValue<IntPtr>(mapHeaderPtr + 0x10); // 修正：root 在 +0x10
    int count   = game.ReadValue<int>((IntPtr)(script + vars.GDSCRIPT_MEMBER_MAP_Count_OFFSET));    // 這就是你要的【數量】

    print("成員總數 (Count): " + count);
    print("Root 地址: " + root.ToString("X"));
    print("Nil 地址: " + nil.ToString("X"));

    if (root == IntPtr.Zero || root == nil) return result;

    // 3. 使用 Queue 遍歷
    var queue = new Queue<IntPtr>();
    queue.Enqueue(root);

    int processed = 0;
    while (queue.Count > 0 && processed < 500) 
    {
        IntPtr node = queue.Dequeue();
        if (node == IntPtr.Zero || node == nil) continue;

        // 4. 根據 ReClass 截圖讀取節點資料
        IntPtr namePtr = game.ReadValue<IntPtr>(node + 0x30); // Key (StringName)
        string memberName = vars.ReadStringName(namePtr);
        int index = game.ReadValue<int>(node + 0x38);        // Value (int index)

        if (!string.IsNullOrEmpty(memberName))
        {
            result[memberName] = (index * 0x18) + 0x8;
            print(string.Format("找到變數: {0}, Index: {1}, Offset: 0x{2:X}", memberName, index, result[memberName]));
        }

        // 5. 取得左右子節點 (在 +0x08 和 +0x10)
        IntPtr left  = game.ReadValue<IntPtr>(node + 0x08);
        IntPtr right = game.ReadValue<IntPtr>(node + 0x10);

        if (left != nil && left != IntPtr.Zero) queue.Enqueue(left);
        if (right != nil && right != IntPtr.Zero) queue.Enqueue(right);

        processed++;
    }

    return result;
});

    // 1. 撈出所有叫做這個檔名的程序
    var targetProcesses = Process.GetProcessesByName("godotsteam.36.editor.windows.64");

    // 2. 尋找哪一個程序的視窗標題包含了 "(DEBUG)"
    Process realGameProcess = null;
    foreach (var p in targetProcesses)
    {
        if (p.MainWindowTitle.Contains("(DEBUG)"))
        {   
            print(p.MainWindowTitle.ToString());
            realGameProcess = p;
            break;
        }
    }

    // 3. 如果沒找到遊戲視窗（可能遊戲還沒開起來），就回傳 false 讓 LiveSplit 繼續等
    if (realGameProcess == null)
    {
        return false;
    }

    // IntPtr targetAddress = modules.First().BaseAddress + 0x42EE330;
    var scn = new SignatureScanner(game, game.MainModule.BaseAddress, game.MainModule.ModuleMemorySize);
    var sceneTreeTrg = new SigScanTarget(3, "48 8B 3D ?? ?? ?? ?? 48 8B 44 24") { OnFound = (p, s, ptr) => ptr + 0x4 + game.ReadValue<int>(ptr) };
    var sceneTreePtr = scn.Scan(sceneTreeTrg);

    // 讀取該位址的指標
    var sceneTree = game.ReadValue<IntPtr>(sceneTreePtr);
    print(sceneTree.ToString("X"));
    vars.rootWindow     = game.ReadValue<IntPtr>((IntPtr)(sceneTree  + vars.SCENETREE_ROOT_WINDOW_OFFSET));
    print(vars.rootWindow.ToString("X"));
    // var main = vars.FindChild(rootWindow, "Main");
    // print(main.ToString("X"));
    // var mainInstance = game.ReadValue<IntPtr>((IntPtr)(main + vars.OBJECT_SCRIPT_INSTANCE_OFFSET));
    // print(mainInstance.ToString("X"));
    // var mainOffsets = GetMemberOffsets(game.ReadValue<IntPtr>((IntPtr)(main + vars.SCRIPTINSTANCE_SCRIPT_REF_OFFSET)));
    // vars.mainOffsets = mainOffsets;
    // vars.mainMember = game.ReadValue<IntPtr>((IntPtr)(mainInstance + vars.SCRIPTINSTANCE_MEMBERS_OFFSET));
    // print(mainOffsets["_is_run_won"].ToString("X"));
    // var isRunWon = game.ReadValue<byte>((IntPtr)(vars.mainMember + vars.mainOffsets["_is_run_won"]));
    // print(isRunWon.ToString());
    // var TitleScreen = vars.FindChild(rootWindow, "TitleScreen");
    // GetMemberOffsets(game.ReadValue<IntPtr>((IntPtr)(main + vars.SCRIPTINSTANCE_SCRIPT_REF_OFFSET)));

    vars.main = IntPtr.Zero;
    vars.mainOffsets = null;
    vars.mainMember = IntPtr.Zero;

    vars.lastIsRunWon = (byte)255;
    vars.currentIsRunWon = (byte)0;
    vars.oldIsRunWon = (byte)0;
}

update
{
    // 處理場景切換印出
    if (current.sceneName != old.sceneName && current.sceneName != null)
    {
        print("SceneName: " + current.sceneName);
    }

    bool mainValid = false;
    if (vars.main != IntPtr.Zero)
    {
        var nameAddr = game.ReadValue<IntPtr>((IntPtr)(vars.main + vars.NODE_NAME_OFFSET));
        var name = vars.ReadStringName(nameAddr);
        if (name == "Main") mainValid = true;
    }

    if (!mainValid)
    {
        var main = vars.FindChild(vars.rootWindow, "Main");
        if (main == IntPtr.Zero) 
        {
            vars.main = IntPtr.Zero;
            return; // main 還沒生出來，這一輪先跳過
        }

        vars.main = main;
        var mainInstance = game.ReadValue<IntPtr>((IntPtr)(main + vars.OBJECT_SCRIPT_INSTANCE_OFFSET));
        var scriptRef = game.ReadValue<IntPtr>((IntPtr)(mainInstance + vars.SCRIPTINSTANCE_SCRIPT_REF_OFFSET));
        vars.mainOffsets = vars.GetMemberOffsets(scriptRef);
        vars.mainMember  = game.ReadValue<IntPtr>((IntPtr)(mainInstance + vars.SCRIPTINSTANCE_MEMBERS_OFFSET));

        print("Main 重新綁定: " + main.ToString("X"));
    }

    // === main 有效才繼續讀 _is_run_won ===
    vars.oldIsRunWon = vars.currentIsRunWon;
    int runWonOffset = (int)vars.mainOffsets["_is_run_won"];
    vars.currentIsRunWon = game.ReadValue<byte>((IntPtr)(vars.mainMember + runWonOffset));
}

split
{
    // 判斷：舊值是 0，且新值變成了 1
    if (vars.oldIsRunWon == 0 && vars.currentIsRunWon == 1)
    {
        print("檢測到通關！_is_run_won 從 0 變 1，觸發 Split！");
        return true; 
    }
}
start
{
    if (old.sceneName != "Main" && current.sceneName == "Main")
    {
        print("Start");
        return true;
    }
}

reset
{
    if (old.sceneName != "TitleScreen" && current.sceneName == "TitleScreen")
    {
        print("Reset");
        return true;
    }
}