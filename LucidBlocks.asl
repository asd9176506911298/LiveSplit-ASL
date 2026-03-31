state("lucid-blocks"){}

startup
{
    // Godot 4.6 Double Precision Version Offsets not sure all correct Yuki.kaco
    // SceneTree
    vars.SCENETREE_ROOT_WINDOW_OFFSET        = 0x328; // Window* f                          SceneTree::root
    vars.SCENETREE_CURRENT_SCENE_OFFSET      = 0x830; // Node*   f                          SceneTree::current_scene

    // Node / Object
    vars.OBJECT_SCRIPT_INSTANCE_OFFSET       = 0x060; // ScriptInstance* f                  Object::script_instance
    vars.NODE_CHILDREN_OFFSET                = 0x180; // HashMap<StringName, Node*> f       Node::Data::children
    vars.NODE_NAME_OFFSET                    = 0x1D8; // StringName f                       Node::Data::name

    // GDScriptInstance
    vars.SCRIPTINSTANCE_SCRIPT_REF_OFFSET    = 0x018; // Ref<GDScript>   nochange                  GDScriptInstance::script
    vars.SCRIPTINSTANCE_MEMBERS_OFFSET       = 0x028; // Vector<Variant> nochange                  GDScriptInstance::members

    // GDScript
    vars.GDSCRIPT_MEMBER_MAP_OFFSET          = 0x1C8; // HashMap<StringName, MemberInfo> f  GDScript::member_indices

    // CanvasLayer Didn't use so not check is correct
    // vars.CANVASLAYER_VISIBLE_OFFSET          = 0x454; // bool                              CanvasLayer::visible

    // CharacterBody3D Didn't use so not check is correc
    // vars.CHARACTERBODY3D_VELOCITY_OFFSET     = 0x648; // Vector3                           CharacterBody3D::velocity
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

    Func<IntPtr, Dictionary<string, int>> GetMemberOffsets = (script) =>
    {
        var result = new Dictionary<string, int>();
        var memberPtr     = game.ReadValue<IntPtr>((IntPtr)(script + vars.GDSCRIPT_MEMBER_MAP_OFFSET));
        var lastMemberPtr = game.ReadValue<IntPtr>((IntPtr)(script + vars.GDSCRIPT_MEMBER_MAP_OFFSET + 0x8));
        int memberSize = 0x18;
        
        while (memberPtr != IntPtr.Zero)
        {
            var namePtr = game.ReadValue<IntPtr>(memberPtr + 0x10);
            string memberName = vars.ReadStringName(namePtr);

            var index = game.ReadValue<int>(memberPtr + 0x18);
            print("Ptr: " + memberPtr.ToString("X") + " Name:  " + memberName +" index: "+ index + " offsets: " + (index * memberSize + 0x8).ToString("X"));
            result[memberName] = index * memberSize + 0x8;

            if (memberPtr == lastMemberPtr)
                break;

            memberPtr = game.ReadValue<IntPtr>(memberPtr);
        }

        return result;
    };

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

    var sceneTree      = game.ReadValue<IntPtr>((IntPtr)(sceneTreePtr));
    var rootWindow     = game.ReadValue<IntPtr>((IntPtr)(sceneTree  + vars.SCENETREE_ROOT_WINDOW_OFFSET));
    var childCount     = game.ReadValue<int>   ((IntPtr)(rootWindow + vars.NODE_CHILDREN_OFFSET));
    var childArrayPtr  = game.ReadValue<IntPtr>((IntPtr)(rootWindow + vars.NODE_CHILDREN_OFFSET + 0x8));

    var main            = vars.FindChild(rootWindow,     "Main");
    var ui              = vars.FindChild(main,           "UI");
    var worldEditMenu   = vars.FindChild(ui,             "WorldEditMenu");
    var marginContainer = vars.FindChild(worldEditMenu,  "MarginContainer");
    var vbox1           = vars.FindChild(marginContainer,"VBoxContainer");
    var vbox2           = vars.FindChild(vbox1,          "VBoxContainer");
    var createButton    = vars.FindChild(vbox2,          "CreateButton");

    vars.createButton     = createButton;
    vars.prevCreateButton = 0;

    print("CreateButton: " + createButton.ToString("X"));
}

start
{
    var pressed = game.ReadValue<byte>((IntPtr)(vars.createButton + 0x8D8));
    bool shouldStart = pressed == 1 && vars.prevCreateButton == 0;
    vars.prevCreateButton = pressed;
    return shouldStart;
}
