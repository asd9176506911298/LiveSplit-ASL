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
        var output    = vars.ReadUtf32String(stringPtr);
        if (String.IsNullOrEmpty(output))
            output = game.ReadString(stringPtr, 255);
        return output;
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
        var gameInstance = game.ReadValue<IntPtr>((IntPtr)(vars.GameGame + vars.OBJECT_SCRIPT_INSTANCE_OFFSET));
        var members      = game.ReadValue<IntPtr>((IntPtr)(gameInstance + vars.SCRIPTINSTANCE_MEMBERS_OFFSET));
        return game.ReadValue<IntPtr>((IntPtr)(members + vars.gameOffsets["climber"] + 0x10));
    });

    // 讀取目前場景的某個 int 成員
    vars.GetCurrentSceneIntMember = (Func<string, int>)((memberName) =>
    {
        var currentSceneNode     = game.ReadValue<IntPtr>((IntPtr)(vars.sceneTree + vars.SCENETREE_CURRENT_SCENE_OFFSET));
        var currentSceneInstance = game.ReadValue<IntPtr>((IntPtr)(currentSceneNode + vars.OBJECT_SCRIPT_INSTANCE_OFFSET));
        if (currentSceneInstance == IntPtr.Zero) return -1;

        var script  = game.ReadValue<IntPtr>((IntPtr)(currentSceneInstance + vars.SCRIPTINSTANCE_SCRIPT_REF_OFFSET));
        var offsets = vars.GetMemberOffsets(script);
        if (!offsets.ContainsKey(memberName)) return -1;

        var members = game.ReadValue<IntPtr>((IntPtr)(currentSceneInstance + vars.SCRIPTINSTANCE_MEMBERS_OFFSET));
        return game.ReadValue<int>((IntPtr)(members + offsets[memberName] + 0x8));
    });

    // --- 初始化 ---
    var scn          = new SignatureScanner(game, game.MainModule.BaseAddress, game.MainModule.ModuleMemorySize);
    var sceneTreeTrg = new SigScanTarget(3, "48 83 3D ?? ?? ?? ?? ?? C6 83")
                       { OnFound = (p, s, ptr) => ptr + 0x5 + game.ReadValue<int>(ptr) };
    var sceneTreePtr = scn.Scan(sceneTreeTrg);

    var sceneTree  = game.ReadValue<IntPtr>((IntPtr)(sceneTreePtr));
    var rootWindow = game.ReadValue<IntPtr>((IntPtr)(sceneTree + vars.SCENETREE_ROOT_WINDOW_OFFSET));
    var GameGame   = vars.FindChild(rootWindow, "Game");

    var GameGameInstance = game.ReadValue<IntPtr>((IntPtr)(GameGame + vars.OBJECT_SCRIPT_INSTANCE_OFFSET));
    vars.gameOffsets     = vars.GetMemberOffsets(game.ReadValue<IntPtr>((IntPtr)(GameGameInstance + vars.SCRIPTINSTANCE_SCRIPT_REF_OFFSET)));

    vars.sceneTree        = sceneTree;
    vars.GameGame         = GameGame;
    vars.climber          = IntPtr.Zero;
    vars.lastClimber      = IntPtr.Zero;
    vars.displayStage     = -1;
    vars.lastDisplayStage = -1;

    print("init done, scene: " + vars.GetCurrentScenePath());
}

update
{
    vars.lastClimber      = vars.climber;
    vars.climber          = vars.GetClimber();

    vars.lastDisplayStage = vars.displayStage;
    vars.displayStage     = vars.GetCurrentScenePath() == "res://scenes/transition_to_credits.tscn"
                            ? vars.GetCurrentSceneIntMember("display_stage")
                            : -1;
}

start
{
    // climber 從空指針變成非空指針，或指針有變化
    bool pointerAppeared = vars.lastClimber == IntPtr.Zero && vars.climber != IntPtr.Zero;
    bool pointerChanged  = vars.climber != IntPtr.Zero     && vars.climber != vars.lastClimber;
    return pointerAppeared || pointerChanged;
}

split
{
    // display_stage 從非1 變成 1 的瞬間 split
    return vars.lastDisplayStage != 1 && vars.displayStage == 1;
}
