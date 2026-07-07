state("Brotato"){}

startup
{
    // Godot 3.6 Offsets
    vars.SCENETREE_ROOT_WINDOW_OFFSET        = 0x100; // Window*                           SceneTree::root
    vars.SCENETREE_CURRENT_SCENE_OFFSET      = 0x580; // Node*                             SceneTree::current_scene

    vars.OBJECT_SCRIPT_INSTANCE_OFFSET       = 0x058; // ScriptInstance*                   Object::script_instance
    vars.SCRIPTINSTANCE_SCRIPT_REF_OFFSET    = 0x010; // Ref<GDScript>   nochange          GDScriptInstance::script
    vars.SCRIPTINSTANCE_MEMBERS_OFFSET       = 0x020; // Vector<Variant> nochange          GDScriptInstance::members--

    vars.GDSCRIPT_MEMBER_MAP_OFFSET          = 0x1C0; // HashMap<StringName, MemberInfo>   GDScript::member_indices
    vars.GDSCRIPT_MEMBER_MAP_Count_OFFSET    = 0x1D0; 

    vars.NODE_NAME_OFFSET                    = 0x130; // StringName                        Node::Data::name
    vars.NODE_CHILDREN_OFFSET                = 0x108; // HashMap<StringName, Node*>        Node::Data::children

    settings.Add("splitWave", false, "Split on Wave Increase (current_wave)");
}

init
{
    vars.ReadStringName = (Func<IntPtr, string>) ((ptr) => {
        var stringPtr = game.ReadValue<IntPtr>(ptr + 0x10);
        return game.ReadString(stringPtr, 255);
    });

    vars.FindChild = (Func<IntPtr, string, IntPtr>)((node, targetName) =>
    {
        var arrayPtr = game.ReadValue<IntPtr>((IntPtr)(node + vars.NODE_CHILDREN_OFFSET));
        if (arrayPtr == IntPtr.Zero) return IntPtr.Zero;

        int i = 0;
        int safetyCounter = 0;
        while (safetyCounter < 500)
        {
            var child = game.ReadValue<IntPtr>(arrayPtr + (0x8 * i));
            if (child == IntPtr.Zero) break;

            var nameAddress = game.ReadValue<IntPtr>((IntPtr)(child + vars.NODE_NAME_OFFSET));
            var childName = vars.ReadStringName(nameAddress);

            if (childName == targetName) return child;

            i++;
            safetyCounter++;
        }
        return IntPtr.Zero;
    });

    vars.GetMemberOffsets = (Func<IntPtr, Dictionary<string, int>>)((script) =>
    {
        var result = new Dictionary<string, int>();
        IntPtr mapHeaderPtr = game.ReadValue<IntPtr>((IntPtr)(script + vars.GDSCRIPT_MEMBER_MAP_OFFSET));
        if (mapHeaderPtr == IntPtr.Zero) return result;

        IntPtr nil  = game.ReadValue<IntPtr>(mapHeaderPtr + 0x08);
        IntPtr root = game.ReadValue<IntPtr>(mapHeaderPtr + 0x10);

        if (root == IntPtr.Zero || root == nil) return result;

        var queue = new Queue<IntPtr>();
        queue.Enqueue(root);

        int processed = 0;
        while (queue.Count > 0 && processed < 500)
        {
            IntPtr node = queue.Dequeue();
            if (node == IntPtr.Zero || node == nil) continue;

            IntPtr namePtr = game.ReadValue<IntPtr>(node + 0x30);
            string memberName = vars.ReadStringName(namePtr);
            int index = game.ReadValue<int>(node + 0x38);
            if (!string.IsNullOrEmpty(memberName))
            {
                result[memberName] = (index * 0x18) + 0x8;
                // print(string.Format("Member: {0}, Index: {1}, Offset: 0x{2:X}", memberName, index, result[memberName]));
            }

            IntPtr left  = game.ReadValue<IntPtr>(node + 0x08);
            IntPtr right = game.ReadValue<IntPtr>(node + 0x10);

            if (left != nil && left != IntPtr.Zero) queue.Enqueue(left);
            if (right != nil && right != IntPtr.Zero) queue.Enqueue(right);

            processed++;
        }
        return result;
    });

    // sigscan 只做一次，把「存放 SceneTree* 的那個靜態位址」記下來，
    // 之後每一幀都從這個固定位址重新讀取 SceneTree 本體指標，
    // 這樣即使 SceneTree 物件被重建，vars.sceneTreeStaticAddr 依然有效。
    var scn = new SignatureScanner(game, game.MainModule.BaseAddress, game.MainModule.ModuleMemorySize);
    var sceneTreeTrg = new SigScanTarget(3, "48 8B 2D ?? ?? ?? ?? 48 85 ED 74 ?? 48 8D 15")
        { OnFound = (p, s, ptr) => ptr + 0x4 + game.ReadValue<int>(ptr) };
    vars.sceneTreeStaticAddr = scn.Scan(sceneTreeTrg);

    // 修正：先各自取出明確型別的中間值，最後再組合成 IntPtr 傳給 ReadValue
    IntPtr sceneTreePtr0 = (IntPtr)game.ReadValue<IntPtr>((IntPtr)vars.sceneTreeStaticAddr);
    IntPtr rootWindowAddr = (IntPtr)(sceneTreePtr0 + (int)vars.SCENETREE_ROOT_WINDOW_OFFSET);
    vars.rootWindow = game.ReadValue<IntPtr>(rootWindowAddr);

    var runData = vars.FindChild(vars.rootWindow, "RunData");
    var runDataInstance = game.ReadValue<IntPtr>((IntPtr)(runData + vars.OBJECT_SCRIPT_INSTANCE_OFFSET));
    var runDatascriptRef = game.ReadValue<IntPtr>((IntPtr)(runDataInstance + vars.SCRIPTINSTANCE_SCRIPT_REF_OFFSET));
    vars.runDataOffsets = vars.GetMemberOffsets(runDatascriptRef);
    vars.runDataMember  = game.ReadValue<IntPtr>((IntPtr)(runDataInstance + vars.SCRIPTINSTANCE_MEMBERS_OFFSET));

    vars.main = IntPtr.Zero;
    vars.mainOffsets = null;
    vars.mainMember = IntPtr.Zero;

    vars.oldSceneName = "";
    vars.currentSceneName = "";

    vars.currentIsRunWon = (byte)0;
    vars.oldIsRunWon = (byte)0;

    vars.currentWave = 0L;
    vars.oldWave = 0L;
}
update
{
    // === 手動讀 sceneName，取代原本 state() 裡的寫死鏈 ===
    vars.oldSceneName = vars.currentSceneName;

    var sceneTree = (IntPtr)game.ReadValue<IntPtr>((IntPtr)vars.sceneTreeStaticAddr);
    var currentSceneNode = game.ReadValue<IntPtr>((IntPtr)(sceneTree + (int)vars.SCENETREE_CURRENT_SCENE_OFFSET));

    if (currentSceneNode != IntPtr.Zero)
    {
        var nameAddr = game.ReadValue<IntPtr>((IntPtr)(currentSceneNode + vars.NODE_NAME_OFFSET));
        vars.currentSceneName = vars.ReadStringName(nameAddr);
    }
    else
    {
        vars.currentSceneName = "";
    }

    if (vars.currentSceneName != vars.oldSceneName && vars.currentSceneName != "")
    {
        print("SceneName: " + vars.currentSceneName);
    }

    // === Main 節點綁定與 _is_run_won 讀取（跟之前一樣）===
    bool mainValid = false;
    if (vars.main != IntPtr.Zero)
    {
        var nameAddr2 = game.ReadValue<IntPtr>((IntPtr)(vars.main + vars.NODE_NAME_OFFSET));
        var name2 = vars.ReadStringName(nameAddr2);
        if (name2 == "Main") mainValid = true;
    }

    if (!mainValid)
    {
        var main = vars.FindChild(vars.rootWindow, "Main");
        if (main == IntPtr.Zero)
        {
            vars.main = IntPtr.Zero;
            return;
        }

        vars.main = main;
        var mainInstance = game.ReadValue<IntPtr>((IntPtr)(main + vars.OBJECT_SCRIPT_INSTANCE_OFFSET));
        var scriptRef = game.ReadValue<IntPtr>((IntPtr)(mainInstance + vars.SCRIPTINSTANCE_SCRIPT_REF_OFFSET));
        vars.mainOffsets = vars.GetMemberOffsets(scriptRef);
        vars.mainMember  = game.ReadValue<IntPtr>((IntPtr)(mainInstance + vars.SCRIPTINSTANCE_MEMBERS_OFFSET));

        print("Main Binding: " + main.ToString("X"));
    }

    vars.oldIsRunWon = vars.currentIsRunWon;
    if (vars.mainOffsets != null && vars.mainOffsets.ContainsKey("_is_run_won"))
    {
        int runWonOffset = (int)vars.mainOffsets["_is_run_won"];
        vars.currentIsRunWon = game.ReadValue<byte>((IntPtr)(vars.mainMember + runWonOffset));
    }

    if (vars.runDataMember != IntPtr.Zero && vars.runDataOffsets.ContainsKey("current_wave"))
    {
        vars.oldWave = vars.currentWave;
        int waveOffset = vars.runDataOffsets["current_wave"];
        vars.currentWave = game.ReadValue<long>((IntPtr)(vars.runDataMember + waveOffset));
    }
}

split
{
    if (vars.oldIsRunWon == 0 && vars.currentIsRunWon == 1)
    {
        print("Detect Win _is_run_won 0 -> 1 Split!");
        return true;
    }

     if (settings["splitWave"] && vars.currentWave > vars.oldWave)
    {
        print(string.Format("Detect Wave Change!{0} -> {1}，Trigger Split！", vars.oldWave, vars.currentWave));
        return true;
    }
}

start
{
    if (vars.oldSceneName != "Main" && vars.currentSceneName == "Main")
    {
        print("Start");
        return true;
    }
}

reset
{
    if (vars.oldSceneName != "TitleScreen" && vars.currentSceneName == "TitleScreen")
    {
        print("Reset");
        return true;
    }
}
