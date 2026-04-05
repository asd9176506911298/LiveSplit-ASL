state("lucid-blocks"){}

startup
{
    // Godot 4.6 Double Precision Version Offsets not sure all correct by Yuki.kaco
    // Reference Micrologist's ASL Code https://raw.githubusercontent.com/Micrologist/LiveSplit.Bloodthief/refs/heads/main/BloodthiefDemo.asl

    // SceneTree
    vars.SCENETREE_ROOT_WINDOW_OFFSET        = 0x328; // Window*                           SceneTree::root

    // Node / Object
    vars.OBJECT_SCRIPT_INSTANCE_OFFSET       = 0x060; // ScriptInstance*                   Object::script_instance
    vars.NODE_CHILDREN_OFFSET                = 0x180; // HashMap<StringName, Node*>        Node::Data::children
    vars.NODE_NAME_OFFSET                    = 0x1D8; // StringName                        Node::Data::name

    // GDScriptInstance
    vars.SCRIPTINSTANCE_SCRIPT_REF_OFFSET    = 0x018; // Ref<GDScript>   nochange          GDScriptInstance::script
    vars.SCRIPTINSTANCE_MEMBERS_OFFSET       = 0x028; // Vector<Variant> nochange          GDScriptInstance::members

    // GDScript
    vars.GDSCRIPT_MEMBER_MAP_OFFSET          = 0x1B8; // HashMap<StringName, MemberInfo>   GDScript::member_indices
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

        var mapBase = game.ReadValue<IntPtr>((IntPtr)(script + vars.GDSCRIPT_MEMBER_MAP_OFFSET));
        var level1  = game.ReadValue<IntPtr>((IntPtr)(mapBase + 0x8));
        var level2  = game.ReadValue<IntPtr>((IntPtr)(level1  + 0x8));
        var curNode = game.ReadValue<IntPtr>((IntPtr)(level2  + 0x8));

        while (curNode != IntPtr.Zero)
        {
            var namePtr       = game.ReadValue<IntPtr>(curNode + 0x10);
            string memberName = vars.ReadStringName(namePtr);
            var index         = game.ReadValue<int>(curNode + 0x18);
            var offset = index * memberSize + 0x8;
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
        var arrayPtr = game.ReadValue<IntPtr>((IntPtr)(node + vars.NODE_CHILDREN_OFFSET + 0x8));

        for (int i = 0; i < count; i++)
        {
            var child     = game.ReadValue<IntPtr>(arrayPtr + (0x8 * i));
            var childName = vars.ReadStringName(game.ReadValue<IntPtr>((IntPtr)(child + vars.NODE_NAME_OFFSET)));

            if (childName == targetName)
                return child;
        }
        return IntPtr.Zero;
    });

    var scn = new SignatureScanner(game, game.MainModule.BaseAddress, game.MainModule.ModuleMemorySize);
    var sceneTreeTrg = new SigScanTarget(3, "48 8B 0D ?? ?? ?? ?? 48 85 C9 74 ?? E8 ?? ?? ?? ?? 84 C0 74 ?? 40 B6") { OnFound = (p, s, ptr) => ptr + 0x4 + game.ReadValue<int>(ptr) };
    var sceneTreePtr = scn.Scan(sceneTreeTrg);

    vars.sceneTreePtr = sceneTreePtr;
    vars.yhvh = IntPtr.Zero; // 先設為零，等 update 去找


    var sceneTree      = game.ReadValue<IntPtr>((IntPtr)(sceneTreePtr));
    var rootWindow     = game.ReadValue<IntPtr>((IntPtr)(sceneTree  + vars.SCENETREE_ROOT_WINDOW_OFFSET));

    var main            = vars.FindChild(rootWindow,     "Main");

    vars.main = main;

    var ui              = vars.FindChild(main,           "UI");
    var worldEditMenu   = vars.FindChild(ui,             "WorldEditMenu");
    var marginContainer = vars.FindChild(worldEditMenu,  "MarginContainer");
    var vbox1           = vars.FindChild(marginContainer,"VBoxContainer");
    var vbox2           = vars.FindChild(vbox1,          "VBoxContainer");
    var createButton    = vars.FindChild(vbox2,          "CreateButton");

    vars.createButton     = createButton;
    vars.prevCreateButton = 0;

    vars.prevYhvhDead = 0;

    vars.yhvhMember = IntPtr.Zero;

    print("Main: " + main.ToString("X"));
}



start
{
    var pressed = game.ReadValue<byte>((IntPtr)(vars.createButton + 0x8D8));
    bool shouldStart = pressed == 1 && vars.prevCreateButton == 0;
    vars.prevCreateButton = pressed;

    if (shouldStart)
    {
        print("Start");
        vars.yhvh = IntPtr.Zero;
        vars.yhvhMember = IntPtr.Zero;
        vars.prevYhvhDead = 0;
    }

    return shouldStart;
}

update
{
    if (vars.yhvh != IntPtr.Zero) return; // 已找到就直接跳過

    var bossManager = vars.FindChild(vars.main, "BossManager");
    if (bossManager == IntPtr.Zero) return;

    var yhvh        = vars.FindChild(bossManager, "Yhvh");
    if (yhvh == IntPtr.Zero) return;
    
    vars.yhvh = yhvh;
    print("Yhvh found: " + yhvh.ToString("X"));

    var yhvhInstance = game.ReadValue<IntPtr>((IntPtr)(yhvh + vars.OBJECT_SCRIPT_INSTANCE_OFFSET));
    var yhvhOffsets = vars.GetMemberOffsets(game.ReadValue<IntPtr>((IntPtr)(yhvhInstance + vars.SCRIPTINSTANCE_SCRIPT_REF_OFFSET)));
    vars.yhvhOffsets = yhvhOffsets;
    
    vars.yhvhMember = game.ReadValue<IntPtr>((IntPtr)(yhvhInstance + vars.SCRIPTINSTANCE_MEMBERS_OFFSET));
}

split
{
    if (vars.yhvhMember == IntPtr.Zero) return false;

    var yhvhDead  = game.ReadValue<byte>((IntPtr)(vars.yhvhMember + vars.yhvhOffsets["dead"]));
    bool shouldSplit = yhvhDead == 1 && vars.prevYhvhDead == 0;
    vars.prevYhvhDead = yhvhDead;

    if(shouldSplit)
        print("Boss Dead Split");

    return shouldSplit;
}
