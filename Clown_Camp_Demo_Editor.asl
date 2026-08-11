state("Godot_v4.6-stable_win64"){}

startup
{
    // Godot 4.6 Double Precision Version Offsets not sure all correct by Yuki.kaco
    // Reference Micrologist's ASL Code https://raw.githubusercontent.com/Micrologist/LiveSplit.Bloodthief/refs/heads/main/BloodthiefDemo.asl

    // SceneTree
    vars.SCENETREE_ROOT_WINDOW_OFFSET        = 0x2D0; // Window*                           SceneTree::root

    // Node / Object
    vars.OBJECT_SCRIPT_INSTANCE_OFFSET       = 0x98; // ScriptInstance*                   Object::script_instance
    vars.NODE_CHILDRENCount_OFFSET           = 0x178; // int
    vars.NODE_CHILDREN_OFFSET                = 0x180; // HashMap<StringName, Node*>        Node::Data::children
    vars.NODE_NAME_OFFSET                    = 0x1D0; // StringName                        Node::Data::name

    // GDScriptInstance
    vars.SCRIPTINSTANCE_SCRIPT_REF_OFFSET    = 0x018; // Ref<GDScript>   nochange          GDScriptInstance::script
    vars.SCRIPTINSTANCE_MEMBERS_OFFSET       = 0x050; // Vector<Variant> nochange          GDScriptInstance::members

    // GDScript
    vars.GDSCRIPT_MEMBER_MAP_OFFSET          = 0x1C8; // HashMap<StringName, MemberInfo>   GDScript::member_indices
}

init
{
    vars.ReadGDString = (Func<IntPtr, string>)((ptr) =>
    {
        var stringPtr = game.ReadValue<IntPtr>(ptr); // 不用 +0x8，直接就是字元陣列指標
        return vars.ReadUtf32String(stringPtr);
    });

    vars.ReadStringName = (Func<IntPtr, string>) ((ptr) => {
        var stringPtr = game.ReadValue<IntPtr>(ptr + 0x8);
        var output = vars.ReadUtf32String(stringPtr);

        if(String.IsNullOrEmpty(output))
        {
            // Read C-String instead
            stringPtr = game.ReadValue<IntPtr>(ptr + 0x8);
            output = game.ReadString(stringPtr, 255);
        }
        return output;
    });

    vars.ReadUtf32String = (Func<IntPtr, string>)((ptr) =>
    {
        var sb = new StringBuilder();
        int utf32char;

        while ((utf32char = game.ReadValue<int>(ptr)) != 0)
        {
            sb.Append(char.ConvertFromUtf32(utf32char));
            ptr += 4;
        }

        return sb.ToString();
    });

    vars.GetMemberOffsets = (Func<IntPtr, Dictionary<string, int>>)((script) =>
{
    var result = new Dictionary<string, int>();
    int memberSize = 0x18;
    var visited = new HashSet<IntPtr>(); // 避免重複節點 / 防止無窮迴圈

    var mapBase = game.ReadValue<IntPtr>((IntPtr)(script + vars.GDSCRIPT_MEMBER_MAP_OFFSET));
    var level1  = game.ReadValue<IntPtr>((IntPtr)(mapBase + 0x0));

    // level1 底下有兩條各自獨立的鏈，要分別走過再合併
    var startNodes = new IntPtr[]
    {
        game.ReadValue<IntPtr>((IntPtr)(level1 + 0x0)),
        game.ReadValue<IntPtr>((IntPtr)(level1 + 0x8)),
    };

    foreach (var start in startNodes)
    {
        var curNode = start;
        int guard = 0;

        while (curNode != IntPtr.Zero && guard < 5000)
        {
            guard++;

            if (!visited.Add(curNode)) // 這個節點已經走過了，跳出避免重複算/卡死
                break;

            var namePtr       = game.ReadValue<IntPtr>(curNode + 0x10);
            string memberName = vars.ReadStringName(namePtr);
            var index         = game.ReadValue<int>(curNode + 0x18);
            var offset = index * memberSize + 0x8;
            print("memberName: " + memberName + " " + "offset: " + offset.ToString("X"));

            if (!string.IsNullOrEmpty(memberName))
                result[memberName] = offset;

            curNode = game.ReadValue<IntPtr>(curNode + 0x8); // 用 +0x8 當 next，這樣才抓得到 puzzle / puzzle_default
        }
    }

    return result;
});

    vars.FindChild = (Func<IntPtr, string, IntPtr>)((node, targetName) =>
    {   
        var count    = game.ReadValue<int>   ((IntPtr)(node + vars.NODE_CHILDRENCount_OFFSET));
        var arrayPtr = game.ReadValue<IntPtr>((IntPtr)(node + vars.NODE_CHILDREN_OFFSET));

        for (int i = 0; i < count; i++)
        {
            var child     = game.ReadValue<IntPtr>(arrayPtr + (0x8 * i));
            var childName = vars.ReadStringName(game.ReadValue<IntPtr>((IntPtr)(child + vars.NODE_NAME_OFFSET)));

            if (childName == targetName)
                return child;
        }
        return IntPtr.Zero;
    });

    var targetProcesses = Process.GetProcessesByName("Godot_v4.6-stable_win64");

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
 
    // var sceneTreePtr = modules.First().BaseAddress + 0xA3C1A60;
    
    // var sceneTree      = game.ReadValue<IntPtr>((IntPtr)(sceneTreePtr));
    // var rootWindow     = game.ReadValue<IntPtr>((IntPtr)(sceneTree  + vars.SCENETREE_ROOT_WINDOW_OFFSET));
    // print(sceneTree.ToString("X"));
    // print(rootWindow.ToString("X"));

    // var SceneSwitcher = vars.FindChild(rootWindow, "SceneSwitcher");
    // print(SceneSwitcher.ToString("X"));
    // var SceneSwitcherInstance = game.ReadValue<IntPtr>((IntPtr)(SceneSwitcher + vars.OBJECT_SCRIPT_INSTANCE_OFFSET));
    // print(SceneSwitcherInstance.ToString("X"));
    // var SceneSwitcherMember = game.ReadValue<IntPtr>((IntPtr)(SceneSwitcherInstance + vars.SCRIPTINSTANCE_MEMBERS_OFFSET));
    // print(SceneSwitcherMember.ToString("X"));
    // var SceneSwitcherOffsets = vars.GetMemberOffsets(game.ReadValue<IntPtr>((IntPtr)(SceneSwitcherInstance + vars.SCRIPTINSTANCE_SCRIPT_REF_OFFSET)));
    // print(SceneSwitcherOffsets["is_switching"].ToString("X"));
    // var isSwitching = game.ReadValue<byte>((IntPtr)(SceneSwitcherMember + SceneSwitcherOffsets["is_switching"]));
    // print(isSwitching.ToString("X"));

    //-- 

    // var GameStats = vars.FindChild(rootWindow, "GameStats");
    // print(GameStats.ToString("X"));
    // var GameStatsInstance = game.ReadValue<IntPtr>((IntPtr)(GameStats + vars.OBJECT_SCRIPT_INSTANCE_OFFSET));
    // print(GameStatsInstance.ToString("X"));
    // var GameStatsMember = game.ReadValue<IntPtr>((IntPtr)(GameStatsInstance + vars.SCRIPTINSTANCE_MEMBERS_OFFSET));
    // print(GameStatsMember.ToString("X"));
    // var GameStatsOffsets = vars.GetMemberOffsets(game.ReadValue<IntPtr>((IntPtr)(GameStatsInstance + vars.SCRIPTINSTANCE_SCRIPT_REF_OFFSET)));
    // print(GameStatsOffsets["dev_mode"].ToString("X"));
    // var dev_mode = game.ReadValue<byte>((IntPtr)(GameStatsMember + GameStatsOffsets["dev_mode"]));
    // print(dev_mode.ToString("X"));
    // var current_scene_key = vars.ReadGDString((IntPtr)(GameStatsMember + GameStatsOffsets["current_scene_key"]));
    // print(current_scene_key);

    var sceneTreePtr = modules.First().BaseAddress + 0xA3C1A60;
    var sceneTree     = game.ReadValue<IntPtr>((IntPtr)(sceneTreePtr));
    var rootWindow    = game.ReadValue<IntPtr>((IntPtr)(sceneTree + vars.SCENETREE_ROOT_WINDOW_OFFSET));
    print(sceneTree.ToString("X"));
    print(rootWindow.ToString("X"));

    // 找到 GameStats 節點與它的 script instance member 區塊，只做一次
    var GameStats = vars.FindChild(rootWindow, "GameStats");
    vars.GameStatsInstance = game.ReadValue<IntPtr>((IntPtr)(GameStats + vars.OBJECT_SCRIPT_INSTANCE_OFFSET));
    vars.GameStatsMember   = game.ReadValue<IntPtr>((IntPtr)(vars.GameStatsInstance + vars.SCRIPTINSTANCE_MEMBERS_OFFSET));
    vars.GameStatsOffsets  = vars.GetMemberOffsets(game.ReadValue<IntPtr>((IntPtr)(vars.GameStatsInstance + vars.SCRIPTINSTANCE_SCRIPT_REF_OFFSET)));

    // 找 SceneSwitcher 節點（isSwitching 在這裡）
    var SceneSwitcher = vars.FindChild(rootWindow, "SceneSwitcher");
    vars.SceneSwitcherInstance = game.ReadValue<IntPtr>((IntPtr)(SceneSwitcher + vars.OBJECT_SCRIPT_INSTANCE_OFFSET));
    vars.SceneSwitcherMember   = game.ReadValue<IntPtr>((IntPtr)(vars.SceneSwitcherInstance + vars.SCRIPTINSTANCE_MEMBERS_OFFSET));
    vars.SceneSwitcherOffsets  = vars.GetMemberOffsets(game.ReadValue<IntPtr>((IntPtr)(vars.SceneSwitcherInstance + vars.SCRIPTINSTANCE_SCRIPT_REF_OFFSET)));

    vars.previousSceneKey = "";
    vars.currentSceneKey  = "";
    vars.isSwitching      = false;
    vars.pendingStart      = false; // 是否正處於「opening2 -> lakeside_beach」這個轉場中，等 isSwitching 變回 false
}

update
{
    try
    {
        vars.previousSceneKey = vars.currentSceneKey;
        vars.currentSceneKey  = vars.ReadGDString((IntPtr)(vars.GameStatsMember + vars.GameStatsOffsets["current_scene_key"]));

        vars.previousIsSwitching = vars.isSwitching;
        vars.isSwitching = game.ReadValue<byte>((IntPtr)(vars.SceneSwitcherMember + vars.SceneSwitcherOffsets["is_switching"])) != 0;
    }
    catch
    {
        return false;
    }

    if (vars.currentSceneKey != vars.previousSceneKey)
    {
        print("sceneKey changed: [" + vars.previousSceneKey + "] -> [" + vars.currentSceneKey + "]  isSwitching=" + vars.isSwitching);
    }

    // isSwitching 狀態變化時印出來，方便確認 loading 判斷準不準
    if (vars.isSwitching != vars.previousIsSwitching)
    {
        print("isSwitching changed: " + vars.previousIsSwitching + " -> " + vars.isSwitching);
    }

    // 偵測 opening2 -> lakeside_beach 切換，標記等待中
    if (vars.previousSceneKey == "opening2" && vars.currentSceneKey == "lakeside_beach")
    {
        vars.pendingStart = true;
    }

    return true;
}

isLoading
{
    // isSwitching = true 代表正在轉場/讀取，這段時間不計時
    return vars.isSwitching;
}

start
{
    if (vars.pendingStart && vars.currentSceneKey == "lakeside_beach" && !vars.isSwitching)
    {
        vars.pendingStart = false;
        return true;
    }
    return false;
}

split
{
    // 場景為 initiation_room，且 isSwitching 從 false -> true 的瞬間 (按下 Exit Slide 的 Yes)
    if (vars.currentSceneKey == "initiation_room"
        && vars.previousIsSwitching == false
        && vars.isSwitching == true)
    {
        print("SPLIT: Exit Slide used in initiation_room");
        return true;
    }

    return false;
}
