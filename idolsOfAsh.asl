state("idols_of_ash"){}

startup
{
    // Godot 4.6 Double Precision Version Offsets by Yuki.kaco
    // Reference Micrologist's ASL Code https://raw.githubusercontent.com/Micrologist/LiveSplit.Bloodthief/refs/heads/main/BloodthiefDemo.asl

    // SceneTree
    vars.SCENETREE_ROOT_WINDOW_OFFSET                  = 0x290; // Window*          SceneTree::root
    vars.SCENETREE_CURRENT_SCENE_OFFSET                = 0x770; // Node*            SceneTree::current_scene
    vars.SCENETREE_CURRENT_SCENE_File_Path_OFFSET      = 0x0E0;

    // Node / Object
    vars.OBJECT_SCRIPT_INSTANCE_OFFSET                 = 0x060; // ScriptInstance*  Object::script_instance
    vars.NODE_CHILDREN_OFFSET                          = 0x13C; // HashMap          Node::Data::children
    vars.NODE_NAME_OFFSET                              = 0x190; // StringName       Node::Data::name

    // GDScriptInstance
    vars.SCRIPTINSTANCE_SCRIPT_REF_OFFSET              = 0x018; // Ref<GDScript>    GDScriptInstance::script
    vars.SCRIPTINSTANCE_MEMBERS_OFFSET                 = 0x028; // Vector<Variant>  GDScriptInstance::members

    // GDScript
    vars.GDSCRIPT_MEMBER_MAP_OFFSET                    = 0x180; // HashMap          GDScript::member_indices
}

init
{
    // 讀 UTF-32 字串
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

    // 讀 StringName
    vars.ReadStringName = (Func<IntPtr, string>)((ptr) =>
    {
        var stringPtr = game.ReadValue<IntPtr>(ptr + 0x8);
        return vars.ReadUtf32String(stringPtr);
    });

    // 取得 GDScript 成員 offset 表
    vars.GetMemberOffsets = (Func<IntPtr, Dictionary<string, int>>)((script) =>
    {
        var result     = new Dictionary<string, int>();
        int memberSize = 0x28;
        var curNode    = game.ReadValue<IntPtr>((IntPtr)(script + vars.GDSCRIPT_MEMBER_MAP_OFFSET));

        while (curNode != IntPtr.Zero)
        {
            var namePtr       = game.ReadValue<IntPtr>(curNode + 0x10);
            string memberName = vars.ReadStringName(namePtr);
            var index         = game.ReadValue<int>(curNode + 0x18);

            // print("memberName: " + memberName + " " + "offset: " + (index * memberSize).ToString("X"));

            if (!string.IsNullOrEmpty(memberName))
                result[memberName] = index * memberSize;

            curNode = game.ReadValue<IntPtr>(curNode);
        }
        return result;
    });

    // 在節點的直接子節點中尋找指定名稱
    vars.FindChild = (Func<IntPtr, string, IntPtr>)((node, targetName) =>
    {
        var count    = game.ReadValue<int>   ((IntPtr)(node + vars.NODE_CHILDREN_OFFSET));
        var arrayPtr = game.ReadValue<IntPtr>((IntPtr)(node + vars.NODE_CHILDREN_OFFSET + 0x4));

        for (int i = 0; i < count; i++)
        {
            var child     = game.ReadValue<IntPtr>(arrayPtr + (0x8 * i));
            var childName = vars.ReadStringName(game.ReadValue<IntPtr>((IntPtr)(child + vars.NODE_NAME_OFFSET)));
            if (childName == targetName)
                return child;
        }
        return IntPtr.Zero;
    });

    // 讀取目前場景的檔案路徑
    vars.GetCurrentScenePath = (Func<string>)(() =>
    {
        var currentSceneNode     = game.ReadValue<IntPtr>((IntPtr)(vars.sceneTree + vars.SCENETREE_CURRENT_SCENE_OFFSET));
        var currentSceneFilePath = game.ReadValue<IntPtr>((IntPtr)(currentSceneNode + vars.SCENETREE_CURRENT_SCENE_File_Path_OFFSET));
        return vars.ReadUtf32String(currentSceneFilePath);
    });

    // 讀取 climber 指針
    vars.GetClimber = (Func<IntPtr>)(() =>
    {
        if (!vars.gameOffsets.ContainsKey("climber"))
            return IntPtr.Zero;

        return game.ReadValue<IntPtr>((IntPtr)(vars.gameMembers + vars.gameOffsets["climber"] + 0x10));
    });

    vars.GetTimeSinceWasTransition = (Func<double>)(() =>
    {
        if (!vars.SceneLoaderOffsets.ContainsKey("time_since_was_transitioning"))
            return 0.0;

        return game.ReadValue<double>((IntPtr)(vars.SceneLoaderMembers + vars.SceneLoaderOffsets["time_since_was_transitioning"] + 0x8));
    });

    // --- 初始化 ---
    var scn          = new SignatureScanner(game, game.MainModule.BaseAddress, game.MainModule.ModuleMemorySize);
    var sceneTreeTrg = new SigScanTarget(3, "48 83 3D ?? ?? ?? ?? ?? 0F 84 ?? ?? ?? ?? 0F 28 05") // 1.24
                       { OnFound = (p, s, ptr) => ptr + 0x5 + game.ReadValue<int>(ptr) };
    var sceneTreePtr = scn.Scan(sceneTreeTrg);
    if (sceneTreePtr == IntPtr.Zero)
    {
        print("new sig not found, trying old sig...");
        sceneTreeTrg = new SigScanTarget(3, "48 83 3D ?? ?? ?? ?? ?? C6 83") // 1.12
                       { OnFound = (p, s, ptr) => ptr + 0x5 + game.ReadValue<int>(ptr) };
        sceneTreePtr = scn.Scan(sceneTreeTrg);
    }

    if (sceneTreePtr == IntPtr.Zero)
    {
        print("ERROR: sceneTree sig not found!");
        return;
    }

    print(sceneTreePtr.ToString("X"));  

    var sceneTree  = game.ReadValue<IntPtr>((IntPtr)(sceneTreePtr));
    var rootWindow = game.ReadValue<IntPtr>((IntPtr)(sceneTree + vars.SCENETREE_ROOT_WINDOW_OFFSET));
    var GameGame   = vars.FindChild(rootWindow, "Game");
    var SceneLoader = vars.FindChild(rootWindow, "SceneLoader");

    vars.GameGameInstance = game.ReadValue<IntPtr>((IntPtr)(GameGame + vars.OBJECT_SCRIPT_INSTANCE_OFFSET));
    vars.gameOffsets     = vars.GetMemberOffsets(game.ReadValue<IntPtr>((IntPtr)(vars.GameGameInstance + vars.SCRIPTINSTANCE_SCRIPT_REF_OFFSET)));
    vars.gameMembers      = game.ReadValue<IntPtr>((IntPtr)(vars.GameGameInstance + vars.SCRIPTINSTANCE_MEMBERS_OFFSET));

    vars.SceneLoaderInstance = game.ReadValue<IntPtr>((IntPtr)(SceneLoader + vars.OBJECT_SCRIPT_INSTANCE_OFFSET));
    vars.SceneLoaderOffsets  = vars.GetMemberOffsets(game.ReadValue<IntPtr>((IntPtr)(vars.SceneLoaderInstance + vars.SCRIPTINSTANCE_SCRIPT_REF_OFFSET)));
    vars.SceneLoaderMembers   = game.ReadValue<IntPtr>((IntPtr)(vars.SceneLoaderInstance + vars.SCRIPTINSTANCE_MEMBERS_OFFSET));

    vars.sceneTree        = sceneTree;
    vars.GameGame         = GameGame;
    vars.SceneLoader      = SceneLoader;
    vars.climber          = IntPtr.Zero;
    vars.lastClimber      = IntPtr.Zero;

    vars.climberOffsets    = null;
    vars.climberMember = IntPtr.Zero;
    vars.lastInjuredState  = false;
    vars.injuredRisingEdge = false;
    vars.currentScene = "";
    vars.lastScene    = "";
    vars.timeSinceWasTransition = 0.0;
    vars.lastTimeSinceWasTransition = 0.0;
    vars.kilnSplitDone = false;
}

update
{
    vars.lastClimber = vars.climber;
    vars.climber     = vars.GetClimber();
    vars.lastScene    = vars.currentScene;
    vars.currentScene = vars.GetCurrentScenePath();

    // 只在指針變動時重新抓 offsets 和 member base
    if (vars.climber != vars.lastClimber)
    {
        if (vars.climber != IntPtr.Zero)
        {
            var climberInstance = game.ReadValue<IntPtr>((IntPtr)(vars.climber + vars.OBJECT_SCRIPT_INSTANCE_OFFSET));

            if (vars.climberOffsets == null)
                vars.climberOffsets = vars.GetMemberOffsets(game.ReadValue<IntPtr>((IntPtr)(climberInstance + vars.SCRIPTINSTANCE_SCRIPT_REF_OFFSET)));

            vars.climberMember = game.ReadValue<IntPtr>((IntPtr)(climberInstance + vars.SCRIPTINSTANCE_MEMBERS_OFFSET));
        }

        vars.lastInjuredState  = false;
        vars.injuredRisingEdge = false;
    }

    // 每幀只做一次輕量讀取
    if (vars.climber != IntPtr.Zero && vars.climberOffsets != null
        && vars.climberOffsets.ContainsKey("injured_state"))
    {
        var climberInjuredState = game.ReadValue<bool>((IntPtr)(vars.climberMember + vars.climberOffsets["injured_state"] + 0x8));
        vars.injuredRisingEdge  = !vars.lastInjuredState && climberInjuredState;
        vars.lastInjuredState   = climberInjuredState;
    }
    else
    {
        vars.injuredRisingEdge = false;
    }

    if (vars.currentScene == "res://scenes/transition_from_first_kiln.tscn")
    {
        vars.lastTimeSinceWasTransition = vars.timeSinceWasTransition;
        vars.timeSinceWasTransition = vars.GetTimeSinceWasTransition();
    }
    else if (vars.lastScene == "res://scenes/transition_from_first_kiln.tscn")
    {
        vars.timeSinceWasTransition = 0.0;
        vars.lastTimeSinceWasTransition = 0.0;
    }
}

start
{
    bool pointerAppeared = vars.lastClimber == IntPtr.Zero && vars.climber != IntPtr.Zero;
    bool pointerChanged  = vars.climber != IntPtr.Zero     && vars.climber != vars.lastClimber;

    if (string.IsNullOrEmpty(vars.lastScene))
        return false;

    if (pointerAppeared || pointerChanged)
    {
        vars.kilnSplitDone = false;
        return true;
    }

    return false;
}

split
{
    if (vars.injuredRisingEdge)
        return true;

    if (vars.currentScene == "res://scenes/transition_from_first_kiln.tscn"
        && vars.lastTimeSinceWasTransition < 2.679
        && vars.timeSinceWasTransition >= 2.679)
    {
        vars.kilnSplitDone = true;
        return true;
    }

    if (!vars.kilnSplitDone
        && vars.currentScene == "res://scenes/credits.tscn"
        && vars.lastScene != "res://scenes/credits.tscn")
        return true;

    return false;
}

onReset
{
    vars.kilnSplitDone = false;
}
