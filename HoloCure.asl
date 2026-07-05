state("HoloCure") {}

startup {
    // Signature for the GameMaker Object Array (gml_ObjectArray)
    vars.ObjectArraySig = "4c 8b 15 ?? ?? ?? ?? 45 8b f1";
    
    // Offsets based on the successful Lua dump results
    vars.Object_Num          = 0x0C;
    vars.Object_Spacing      = 0x10;
    vars.Object_PropOff      = 0x18;
    vars.Object_NameOff      = 0x00;
    vars.Object_InstListBase = 0x68;
    vars.Object_InstOff      = 0x10;

    vars.resolved = false;
    vars.symbolAddr = IntPtr.Zero;
    vars.playerManagerObjBase = IntPtr.Zero;
}

init {
    vars.resolved = false;
    vars.playerManagerObjBase = IntPtr.Zero;

    var scanner = new SignatureScanner(game, game.MainModule.BaseAddress, game.MainModule.ModuleMemorySize);
    
    // Relative addressing for LEA/MOV instruction (r8, [rip+disp32])
    var target = new SigScanTarget(3, (string)vars.ObjectArraySig)
    {
        OnFound = (p, s, ptr) => ptr + 0x4 + game.ReadValue<int>((IntPtr)ptr)
    };

    vars.symbolAddr = scanner.Scan(target);
    if (vars.symbolAddr == IntPtr.Zero) {
        print("ObjectArray signature NOT found");
    } else {
        print("ObjectArray symbol found at: " + vars.symbolAddr.ToString("X"));
    }
}

update {
    // Default current instance to Zero to avoid stale data
    current.playerManagerInstance = IntPtr.Zero;

    // 1. Search for obj_PlayerManager if not yet found
    if (!(bool)vars.resolved) {
        if (vars.symbolAddr == IntPtr.Zero) return true;

        IntPtr objArrayBase = game.ReadValue<IntPtr>((IntPtr)vars.symbolAddr);
        if (objArrayBase == IntPtr.Zero) return true;

        int numObjects = game.ReadValue<int>(objArrayBase + (int)vars.Object_Num);
        IntPtr arr = game.ReadValue<IntPtr>(objArrayBase);

        if (arr == IntPtr.Zero || numObjects <= 0) return true;

        // Iterate through the object array (searching up to index 1024)
        int limit = Math.Min(numObjects, 1024);

        for (int i = 0; i < limit; i++) {
            IntPtr oAddr = game.ReadValue<IntPtr>(arr + (i * (int)vars.Object_Spacing));
            if (oAddr == IntPtr.Zero) continue;

            IntPtr findPropPtr = game.ReadValue<IntPtr>(oAddr + (int)vars.Object_PropOff);
            if (findPropPtr == IntPtr.Zero) continue;

            IntPtr findNamePtr = game.ReadValue<IntPtr>(findPropPtr + (int)vars.Object_NameOff);
            if (findNamePtr == IntPtr.Zero) continue;

            string name = game.ReadString(findNamePtr, 64);
            
            // Name must match the dump "obj_PlayerManager"
            if (name == "obj_PlayerManager") {
                vars.playerManagerObjBase = oAddr;
                vars.resolved = true;
                print("Confirmed: obj_PlayerManager found at Index [" + i + "]");
                break;
            }
        }
        
        // Skip further logic if searching is still in progress
        if (!(bool)vars.resolved) return true;
    }

    // 2. Resolve the live instance from the object definition
    IntPtr objBase = (IntPtr)vars.playerManagerObjBase;
    IntPtr finalPropPtr = game.ReadValue<IntPtr>(objBase + (int)vars.Object_PropOff);
    if (finalPropPtr == IntPtr.Zero) return true;
    
    // Get the instance list pointer (0x68)
    IntPtr instList = game.ReadValue<IntPtr>(finalPropPtr + (int)vars.Object_InstListBase);
    if (instList == IntPtr.Zero) return true;
        
    // Get the first active instance pointer (0x10)
    IntPtr instance = game.ReadValue<IntPtr>(instList + (int)vars.Object_InstOff);

    current.playerManagerInstance = instance;
    return true;
}

start {
    // Ensure the dynamic dictionary contains our property before checking
    var oldDict = old as IDictionary<string, object>;
    if (!oldDict.ContainsKey("playerManagerInstance")) return false;

    // Start timer when the PlayerManager instance is created (transition from Null to Address)
    bool started = old.playerManagerInstance == IntPtr.Zero && current.playerManagerInstance != IntPtr.Zero;
    if (started) {
        print("Timer Start: PlayerManager instance detected at " + current.playerManagerInstance.ToString("X"));
    }
    
    return started;
}