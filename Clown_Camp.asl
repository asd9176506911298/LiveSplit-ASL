state("clown_camp"){}

startup
{
    // Godot 4.6 Double Precision Version Offsets (accuracy unverified) by Yuki.kaco
    // Reference Micrologist's ASL Code: https://raw.githubusercontent.com/Micrologist/LiveSplit.Bloodthief/refs/heads/main/BloodthiefDemo.asl

    // SceneTree
    vars.SCENETREE_ROOT_WINDOW_OFFSET        = 0x290; // Window*                        SceneTree::root

    // Node / Object
    vars.OBJECT_SCRIPT_INSTANCE_OFFSET       = 0x60;  // ScriptInstance*                 Object::script_instance
    vars.NODE_CHILDRENCount_OFFSET           = 0x138; // int
    vars.NODE_CHILDREN_OFFSET                = 0x140; // HashMap<StringName, Node*>      Node::Data::children
    vars.NODE_NAME_OFFSET                    = 0x190; // StringName                      Node::Data::name

    // GDScriptInstance
    vars.SCRIPTINSTANCE_SCRIPT_REF_OFFSET    = 0x018; // Ref<GDScript>   nochange          GDScriptInstance::script
    vars.SCRIPTINSTANCE_MEMBERS_OFFSET       = 0x028; // Vector<Variant> nochange          GDScriptInstance::members

    // GDScript
    vars.GDSCRIPT_MEMBER_MAP_OFFSET          = 0x178; // HashMap<StringName, MemberInfo>   GDScript::member_indices

    if (timer.CurrentTimingMethod != TimingMethod.GameTime)
    {
        var mbox = System.Windows.Forms.MessageBox.Show(
            timer.Form,
            "Removing loads from this game requires comparing against Game Time.\nWould you like to switch to it?",
            "LiveSplit | Clown Camp",
            System.Windows.Forms.MessageBoxButtons.YesNo,
            System.Windows.Forms.MessageBoxIcon.Question
        );
        if (mbox == System.Windows.Forms.DialogResult.Yes) timer.CurrentTimingMethod = TimingMethod.GameTime;
    }
}

init
{
    vars.ReadGDString = (Func<IntPtr, string>)((ptr) =>
    {
        var stringPtr = game.ReadValue<IntPtr>(ptr); // No +0x8 needed, this is directly a pointer to the character array
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
        var visited = new HashSet<IntPtr>(); // Avoid duplicate nodes / prevent infinite loops

        var mapBase = game.ReadValue<IntPtr>((IntPtr)(script + vars.GDSCRIPT_MEMBER_MAP_OFFSET));
        var level1  = game.ReadValue<IntPtr>((IntPtr)(mapBase + 0x0));

        // level1 contains two independent chains underneath; traverse both separately and merge them
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

                if (!visited.Add(curNode)) // Node has already been traversed; break to prevent duplicate processing/freezing
                    break;

                var namePtr       = game.ReadValue<IntPtr>(curNode + 0x10);
                string memberName = vars.ReadStringName(namePtr);
                var index         = game.ReadValue<int>(curNode + 0x18);
                var offset = index * memberSize + 0x8;
                // print("memberName: " + memberName + " " + "offset: " + offset.ToString("X"));

                if (!string.IsNullOrEmpty(memberName))
                    result[memberName] = offset;

                curNode = game.ReadValue<IntPtr>(curNode + 0x8); // Use +0x8 as next pointer to properly capture puzzle / puzzle_default
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

    var sceneTreePtr = modules.First().BaseAddress + 0x6389C60;
    var sceneTree     = game.ReadValue<IntPtr>((IntPtr)(sceneTreePtr));
    var rootWindow    = game.ReadValue<IntPtr>((IntPtr)(sceneTree + vars.SCENETREE_ROOT_WINDOW_OFFSET));
    print(sceneTree.ToString("X"));
    print(rootWindow.ToString("X"));

    // Find GameStats node and its script instance member block (run only once)
    var GameStats = vars.FindChild(rootWindow, "GameStats");
    vars.GameStatsInstance = game.ReadValue<IntPtr>((IntPtr)(GameStats + vars.OBJECT_SCRIPT_INSTANCE_OFFSET));
    vars.GameStatsMember   = game.ReadValue<IntPtr>((IntPtr)(vars.GameStatsInstance + vars.SCRIPTINSTANCE_MEMBERS_OFFSET));
    vars.GameStatsOffsets  = vars.GetMemberOffsets(game.ReadValue<IntPtr>((IntPtr)(vars.GameStatsInstance + vars.SCRIPTINSTANCE_SCRIPT_REF_OFFSET)));

    // Find SceneSwitcher node (where isSwitching resides)
    var SceneSwitcher = vars.FindChild(rootWindow, "SceneSwitcher");
    vars.SceneSwitcherInstance = game.ReadValue<IntPtr>((IntPtr)(SceneSwitcher + vars.OBJECT_SCRIPT_INSTANCE_OFFSET));
    vars.SceneSwitcherMember   = game.ReadValue<IntPtr>((IntPtr)(vars.SceneSwitcherInstance + vars.SCRIPTINSTANCE_MEMBERS_OFFSET));
    vars.SceneSwitcherOffsets  = vars.GetMemberOffsets(game.ReadValue<IntPtr>((IntPtr)(vars.SceneSwitcherInstance + vars.SCRIPTINSTANCE_SCRIPT_REF_OFFSET)));

    vars.previousSceneKey = "";
    vars.currentSceneKey  = "";
    vars.isSwitching      = false;
    vars.pendingStart      = false; // Flags whether the game is currently transitioning from "opening2 -> lakeside_beach", waiting for isSwitching to return to false
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

    // Log when isSwitching changes state to verify accuracy of loading detection
    if (vars.isSwitching != vars.previousIsSwitching)
    {
        print("isSwitching changed: " + vars.previousIsSwitching + " -> " + vars.isSwitching);
    }

    // Detect opening2 -> lakeside_beach transition and flag it as waiting
    if (vars.previousSceneKey == "opening2" && vars.currentSceneKey == "lakeside_beach")
    {
        vars.pendingStart = true;
    }

    return true;
}

isLoading
{
    // isSwitching = true means a scene transition/loading is occurring; pause the timer during this period
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
    // Triggers when the scene is initiation_room and isSwitching flips from false -> true. Note: exiting from initiation_room back to Menu will also trigger this split.
    if (vars.currentSceneKey == "initiation_room"
        && vars.previousIsSwitching == false
        && vars.isSwitching == true)
    {
        print("SPLIT: Exit Slide used in initiation_room");
        return true;
    }

    return false;
}
