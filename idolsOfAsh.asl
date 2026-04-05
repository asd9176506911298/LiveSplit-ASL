state("idols_of_ash"){}

startup
{
    // Godot 4.6 Double Precision Version Offsets not sure all correct by Yuki.kaco
    // Reference Micrologist's ASL Code https://raw.githubusercontent.com/Micrologist/LiveSplit.Bloodthief/refs/heads/main/BloodthiefDemo.asl

    // SceneTree
    vars.SCENETREE_ROOT_WINDOW_OFFSET        = 0x290; // Window*                           SceneTree::root

    // Node / Object
    vars.OBJECT_SCRIPT_INSTANCE_OFFSET       = 0x060; // ScriptInstance*                   Object::script_instance
    vars.NODE_CHILDREN_OFFSET                = 0x13C; // HashMap<StringName, Node*>        Node::Data::children
    vars.NODE_NAME_OFFSET                    = 0x190; // StringName                        Node::Data::name

    // GDScriptInstance
    vars.SCRIPTINSTANCE_SCRIPT_REF_OFFSET    = 0x018; // Ref<GDScript>   nochange          GDScriptInstance::script
    vars.SCRIPTINSTANCE_MEMBERS_OFFSET       = 0x028; // Vector<Variant> nochange          GDScriptInstance::members

    // GDScript
    vars.GDSCRIPT_MEMBER_MAP_OFFSET          = 0x180; // HashMap<StringName, MemberInfo>   GDScript::member_indices
}

init
{
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
        int memberSize = 0x28;

        var curNode = game.ReadValue<IntPtr>((IntPtr)(script + vars.GDSCRIPT_MEMBER_MAP_OFFSET));

        while (curNode != IntPtr.Zero)
        {
            var namePtr       = game.ReadValue<IntPtr>(curNode + 0x10);
            string memberName = vars.ReadStringName(namePtr);
            var index         = game.ReadValue<int>(curNode + 0x18);
            var offset = index * memberSize + 0x10;
            // print("memberName: " + memberName + " " + "offset: " + offset.ToString("X"));

            if (!string.IsNullOrEmpty(memberName))
                result[memberName] = offset;

            curNode = game.ReadValue<IntPtr>(curNode);
        }

        return result;
    });

    vars.FindChild = (Func<IntPtr, string, IntPtr>)((node, targetName) =>
    {
        var count    = game.ReadValue<int>   ((IntPtr)(node + vars.NODE_CHILDREN_OFFSET));
        var arrayPtr = game.ReadValue<IntPtr>((IntPtr)(node + vars.NODE_CHILDREN_OFFSET + 0x4));

        for (int i = 0; i < count; i++)
        {
            var child     = game.ReadValue<IntPtr>(arrayPtr + (0x8 * i));
            var childName = vars.ReadStringName(game.ReadValue<IntPtr>((IntPtr)(child + vars.NODE_NAME_OFFSET)));
            // print(childName);
            if (childName == targetName)
                return child;
        }
        return IntPtr.Zero;
    });

    vars.GetClimber = (Func<IntPtr>)(() =>
    {
        var gameInstance = game.ReadValue<IntPtr>((IntPtr)(vars.GameGame + vars.OBJECT_SCRIPT_INSTANCE_OFFSET));
        var members      = game.ReadValue<IntPtr>((IntPtr)(gameInstance + vars.SCRIPTINSTANCE_MEMBERS_OFFSET));
        return game.ReadValue<IntPtr>((IntPtr)(members + vars.gameOffsets["climber"]));
    });

    var scn = new SignatureScanner(game, game.MainModule.BaseAddress, game.MainModule.ModuleMemorySize);
    var sceneTreeTrg = new SigScanTarget(3, "48 83 3D ?? ?? ?? ?? ?? C6 83") { OnFound = (p, s, ptr) => ptr + 0x5 + game.ReadValue<int>(ptr) };
    var sceneTreePtr = scn.Scan(sceneTreeTrg);

    var sceneTree      = game.ReadValue<IntPtr>((IntPtr)(sceneTreePtr));
    var rootWindow     = game.ReadValue<IntPtr>((IntPtr)(sceneTree  + vars.SCENETREE_ROOT_WINDOW_OFFSET));

    var GameGame       = vars.FindChild(rootWindow,     "Game");
    var GameGameInstance = game.ReadValue<IntPtr>((IntPtr)(GameGame + vars.OBJECT_SCRIPT_INSTANCE_OFFSET));

    vars.gameOffsets = vars.GetMemberOffsets(game.ReadValue<IntPtr>((IntPtr)(GameGameInstance + vars.SCRIPTINSTANCE_SCRIPT_REF_OFFSET)));

    vars.GameGame    = vars.FindChild(rootWindow, "Game");  // 存到 vars 讓其他區塊能用
    vars.lastClimber = IntPtr.Zero;
    vars.climber     = IntPtr.Zero;  // ← 加這行
}

update
{
    vars.lastClimber = vars.climber;       // 先存舊值
    vars.climber     = vars.GetClimber();  // 再讀新值
}

start
{
    // 條件一：指針變化（新舊不同且新值不為 null）
    bool pointerChanged = vars.climber != IntPtr.Zero && vars.climber != vars.lastClimber;
    
    // 條件二：從空指針變成非空指針
    bool pointerAppeared = vars.lastClimber == IntPtr.Zero && vars.climber != IntPtr.Zero;
    
    return pointerChanged || pointerAppeared;
}