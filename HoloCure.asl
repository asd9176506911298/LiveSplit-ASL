state("HoloCure") {}

startup {
    // --- Signatures ---
    vars.ObjectArraySig = "4c 8b 15 ?? ?? ?? ?? 45 8b f1";
    vars.GlobalVarsSig   = "48 ?? ?? ?? ?? ?? ?? E8 ?? ?? ?? ?? 90 4C ?? ?? ?? ?? ?? ?? 41 ?? ?? ?? ?? 76";
    vars.StringsListSig  = "48 ?? ?? ?? ?? ?? ?? 48 ?? ?? 0F 85 ?? ?? ?? ?? 48 ?? ?? ?? ?? ?? ?? 8D";

    // --- Constant Offsets (Standard GameMaker 64-bit) ---
    vars.Object_Num          = 0x0C;
    vars.Object_Spacing      = 0x10;
    vars.Object_PropOff      = 0x18;
    vars.Object_NameOff      = 0x00;
    vars.Object_InstListBase = 0x68;
    vars.Object_InstOff      = 0x10;

    // Instance -> VarArray is only ONE dereference (unlike global's nested +48/+10 struct)
    vars.Instance_VarArrayOff = 0x10;

    // --- Initialization Variables ---
    vars.resolved = false;
    vars.gameModeOffset = -1;      // dynamic offset inside the GLOBAL var array
    vars.gameWonOffset  = -1;      // dynamic offset inside the PlayerManager INSTANCE var array
    vars.symbolAddr = IntPtr.Zero;
    vars.globalVarsAddr = IntPtr.Zero;
    vars.stringsListAddr = IntPtr.Zero;
    vars.playerManagerObjBase = IntPtr.Zero;
    vars.stringDict = new Dictionary<int, string>(); // reused later for gameWon lookup
}

init {
    vars.resolved = false;
    vars.gameWonOffset = -1; // reset so we re-scan for the new instance's var array
    var scanner = new SignatureScanner(game, game.MainModule.BaseAddress, game.MainModule.ModuleMemorySize);

    // 1. Resolve Object Array Base Address
    var targetObj = new SigScanTarget(3, (string)vars.ObjectArraySig) {
        OnFound = (p, s, ptr) => ptr + 0x4 + game.ReadValue<int>((IntPtr)ptr)
    };
    vars.symbolAddr = scanner.Scan(targetObj);

    // 2. Resolve Global Variables Pointer
    var targetGlobal = new SigScanTarget(3, (string)vars.GlobalVarsSig) {
        OnFound = (p, s, ptr) => ptr + 0x4 + game.ReadValue<int>((IntPtr)ptr)
    };
    vars.globalVarsAddr = scanner.Scan(targetGlobal);

    // 3. Resolve Strings List Pointer
    var targetStrings = new SigScanTarget(3, (string)vars.StringsListSig) {
        OnFound = (p, s, ptr) => ptr + 0x4 + game.ReadValue<int>((IntPtr)ptr)
    };
    vars.stringsListAddr = scanner.Scan(targetStrings);

    if (vars.symbolAddr != IntPtr.Zero) print("ObjectArray base found at: " + vars.symbolAddr.ToString("X"));
    if (vars.globalVarsAddr != IntPtr.Zero) print("GlobalVars base found at: " + vars.globalVarsAddr.ToString("X"));
    if (vars.stringsListAddr != IntPtr.Zero) print("StringsList base found at: " + vars.stringsListAddr.ToString("X"));

    // --- Build the String Dictionary (used for BOTH global "gameMode" and instance "gameWon" name lookup) ---
    var stringDict = new Dictionary<int, string>();
    if (vars.stringsListAddr != IntPtr.Zero) {
        IntPtr sListPtr = game.ReadValue<IntPtr>((IntPtr)vars.stringsListAddr);
        if (sListPtr != IntPtr.Zero) {
            int strNum = game.ReadValue<int>(sListPtr + 0x4C);
            IntPtr strArrayPtr = game.ReadValue<IntPtr>(sListPtr + 0x58);
            for (int i = 0; i < strNum; i++) {
                IntPtr entryAddr = game.ReadValue<IntPtr>(strArrayPtr + (i * 0x08));
                if (entryAddr == IntPtr.Zero) continue;
                int stringID = game.ReadValue<int>(entryAddr + 0x08);
                IntPtr namePtr = game.ReadValue<IntPtr>(entryAddr);
                if (namePtr != IntPtr.Zero) {
                    string strVal = game.ReadString(namePtr, 64);
                    if (!string.IsNullOrEmpty(strVal)) stringDict[stringID] = strVal;
                }
            }
        }
    }
    vars.stringDict = stringDict; // saved for use in update() when resolving gameWon

    // --- Dynamic "gameMode" Offset Resolution (this one IS global) ---
    if (vars.globalVarsAddr != IntPtr.Zero) {
        IntPtr gVarsPtr = game.ReadValue<IntPtr>((IntPtr)vars.globalVarsAddr);
        if (gVarsPtr != IntPtr.Zero) {
            // According to CE: gml_GlobalVariables -> +48
            IntPtr varArrayStruct = game.ReadValue<IntPtr>(gVarsPtr + 0x48);
            if (varArrayStruct != IntPtr.Zero) {
                int varNum = game.ReadValue<int>(varArrayStruct + 0x08);
                // According to CE: varArrayStruct -> +10 (Start of VarData)
                IntPtr varDataPtr = game.ReadValue<IntPtr>(varArrayStruct + 0x10);
                for (int i = 0; i < varNum; i++) {
                    int offset = i * 0x10; // Standard YYValue 16-byte multiplier
                    int nameID = game.ReadValue<int>(varDataPtr + offset + 0x08);
                    string varName;
                    if (stringDict.TryGetValue(nameID, out varName) && varName == "gameMode") {
                        vars.gameModeOffset = offset;
                        print("Success: Dynamic gameMode offset resolved at 0x" + offset.ToString("X"));
                        break;
                    }
                }
            }
        }
    }
    // NOTE: gameWon is NOT resolved here — it lives in the PlayerManager INSTANCE's
    // own var array, which only exists once the instance is spawned. It gets
    // resolved dynamically in update(), once current.playerManagerInstance != Zero.
}

update {
    // Default current values to zero/empty to avoid property errors in old object
    current.playerManagerInstance = IntPtr.Zero;
    current.gameMode = 0.0;
    current.gameWon = 0.0;

    // 1. Search for obj_PlayerManager until found in memory
    if (!(bool)vars.resolved && vars.symbolAddr != IntPtr.Zero) {
        IntPtr objArrayBase = game.ReadValue<IntPtr>((IntPtr)vars.symbolAddr);
        if (objArrayBase != IntPtr.Zero) {
            int numObjects = game.ReadValue<int>(objArrayBase + (int)vars.Object_Num);
            IntPtr arr = game.ReadValue<IntPtr>(objArrayBase);
            if (arr != IntPtr.Zero && numObjects > 0) {
                int limit = Math.Min(numObjects, 1024);
                for (int i = 0; i < limit; i++) {
                    IntPtr oAddr = game.ReadValue<IntPtr>(arr + (i * (int)vars.Object_Spacing));
                    if (oAddr == IntPtr.Zero) continue;
                    IntPtr findPropPtr = game.ReadValue<IntPtr>(oAddr + (int)vars.Object_PropOff);
                    if (findPropPtr == IntPtr.Zero) continue;
                    IntPtr findNamePtr = game.ReadValue<IntPtr>(findPropPtr + (int)vars.Object_NameOff);
                    if (findNamePtr == IntPtr.Zero) continue;
                    if (game.ReadString(findNamePtr, 64) == "obj_PlayerManager") {
                        vars.playerManagerObjBase = oAddr;
                        vars.resolved = true;
                        print("Confirmed: obj_PlayerManager object resolved.");
                        break;
                    }
                }
            }
        }
    }

    // 2. Read gameMode (Global Variable, Pointer Chain: Base -> +48 -> +10 -> +Offset -> +0)
    if (vars.globalVarsAddr != IntPtr.Zero && (int)vars.gameModeOffset != -1) {
        IntPtr gVarsPtr = game.ReadValue<IntPtr>((IntPtr)vars.globalVarsAddr);
        if (gVarsPtr != IntPtr.Zero) {
            IntPtr varArrayStruct = game.ReadValue<IntPtr>(gVarsPtr + 0x48); // Chain +48
            if (varArrayStruct != IntPtr.Zero) {
                IntPtr varDataPtr = game.ReadValue<IntPtr>(varArrayStruct + 0x10); // Chain +10
                if (varDataPtr != IntPtr.Zero) {
                    IntPtr finalValuePtr = game.ReadValue<IntPtr>(varDataPtr + (int)vars.gameModeOffset); // Chain +Offset
                    if (finalValuePtr != IntPtr.Zero) {
                        current.gameMode = game.ReadValue<double>(finalValuePtr);
                    }
                }
            }
        }
    }

    // 3. Resolve active Instance for PlayerManager
    if ((bool)vars.resolved) {
        IntPtr objBase = (IntPtr)vars.playerManagerObjBase;
        IntPtr propPtr = game.ReadValue<IntPtr>(objBase + (int)vars.Object_PropOff);
        if (propPtr != IntPtr.Zero) {
            IntPtr instList = game.ReadValue<IntPtr>(propPtr + (int)vars.Object_InstListBase);
            if (instList != IntPtr.Zero) {
                current.playerManagerInstance = game.ReadValue<IntPtr>(instList + (int)vars.Object_InstOff);
            }
        }
    }

    // 4. Once the PlayerManager instance exists, resolve "gameWon"'s offset
    //    inside ITS OWN var array (same 2-level structure as the global var array: +0x48 -> +0x10)
    IntPtr pmInstance = (IntPtr)current.playerManagerInstance; // explicit cast: avoid dynamic dispatch on extension methods
    if (pmInstance != IntPtr.Zero && (int)vars.gameWonOffset == -1) {
        var stringDict = vars.stringDict as Dictionary<int, string>;
        if (stringDict != null && stringDict.Count > 0) {
            IntPtr instVarArrayStruct = game.ReadValue<IntPtr>(pmInstance + 0x48); // Chain +48 (same as global)
            if (instVarArrayStruct != IntPtr.Zero) {
                int instVarNum = game.ReadValue<int>(instVarArrayStruct + 0x08); // actual variable count
                IntPtr instVarDataPtr = game.ReadValue<IntPtr>(instVarArrayStruct + 0x10); // Chain +10 (real var data)
                if (instVarDataPtr != IntPtr.Zero) {
                    for (int i = 0; i < instVarNum; i++) {
                        int offset = i * 0x10; // Standard YYValue 16-byte multiplier
                        int nameID = game.ReadValue<int>(instVarDataPtr + offset + 0x08);
                        string varName;
                        if (stringDict.TryGetValue(nameID, out varName) && varName == "gameWon") {
                            vars.gameWonOffset = offset;
                            print("Success: Dynamic gameWon offset resolved at 0x" + offset.ToString("X"));
                            break;
                        }
                    }
                }
            }
        }
    }

    // 5. Read gameWon (PlayerManager INSTANCE variable, Pointer Chain: instance -> +0x48 -> +0x10 -> +Offset -> +0)
    if (pmInstance != IntPtr.Zero && (int)vars.gameWonOffset != -1) {
        IntPtr instVarArrayStruct = game.ReadValue<IntPtr>(pmInstance + 0x48); // Chain +48
        if (instVarArrayStruct != IntPtr.Zero) {
            IntPtr instVarDataPtr = game.ReadValue<IntPtr>(instVarArrayStruct + 0x10); // Chain +10
            if (instVarDataPtr != IntPtr.Zero) {
                IntPtr finalValuePtr = game.ReadValue<IntPtr>(instVarDataPtr + (int)vars.gameWonOffset); // Chain +Offset
                if (finalValuePtr != IntPtr.Zero) {
                    current.gameWon = game.ReadValue<double>(finalValuePtr); // Dereference to get the actual double value (+0)
                }
            }
        }
    }
}

start {
    var oldDict = old as IDictionary<string, object>;
    if (!oldDict.ContainsKey("playerManagerInstance")) return false;

    bool started = old.playerManagerInstance == IntPtr.Zero && current.playerManagerInstance != IntPtr.Zero;
    if (started) print("Timer Started: PlayerManager instance detected.");
    return started;
}

split {
    var oldDict = old as IDictionary<string, object>;
    if (!oldDict.ContainsKey("gameWon")) return false;

    // Split when gameWon changes from 0 to 1 (victory achieved)
    bool shouldSplit = old.gameWon == 0.0 && current.gameWon == 1.0;
    if (shouldSplit) print("Split: gameWon switched from 0 to 1.");
    return shouldSplit;
}

reset {
    var oldDict = old as IDictionary<string, object>;
    if (!oldDict.ContainsKey("gameMode")) return false;

    bool shouldReset = old.gameMode != -1.0 && current.gameMode == -1.0;
    if (shouldReset) print("Timer Reset: gameMode switched to -1.0.");
    return shouldReset;
}
