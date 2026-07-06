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
    vars.Object_InstListNum  = 0x78;   // total instance count for this object (GM.lua: InstListNum)
    vars.Object_InstOff      = 0x10;
    vars.Object_VarArray     = 0x48;
    vars.Object_VarNum       = 0x08;
    vars.Object_VarData      = 0x10;

    // Minimum variable count for an instance's own var-array to be considered
    // a "real" gameplay obj_PlayerManager, as opposed to the lightweight
    // menu/character-preview decoy instance. Confirmed from logs: decoy's
    // gameWon sits around var-index ~264-269, real gameplay's sits around
    // ~779-781 - so a threshold comfortably between those two ranges filters
    // the decoy out. Print statements below show the actual counts seen;
    // raise/lower this if it doesn't match your observations.
    vars.MinRealVarCount = 400;

    // --- Initialization Variables ---
    vars.resolved = false;
    vars.gameModeOffset = -1;      // dynamic offset inside the GLOBAL var array
    vars.gameWonOffset  = -1;      // dynamic offset inside the PlayerManager INSTANCE var array
    vars.symbolAddr = IntPtr.Zero;
    vars.globalVarsAddr = IntPtr.Zero;
    vars.stringsListAddr = IntPtr.Zero;
    vars.playerManagerObjBase = IntPtr.Zero;
    vars.stringDict = new Dictionary<int, string>();
    vars.lastPmInstance = IntPtr.Zero;
}

init {
    vars.resolved = false;
    vars.gameModeOffset = -1;
    vars.gameWonOffset  = -1;
    vars.lastPmInstance = IntPtr.Zero;

    var scanner = new SignatureScanner(game, game.MainModule.BaseAddress, game.MainModule.ModuleMemorySize);

    var targetObj = new SigScanTarget(3, (string)vars.ObjectArraySig) {
        OnFound = (p, s, ptr) => ptr + 0x4 + game.ReadValue<int>((IntPtr)ptr)
    };
    vars.symbolAddr = scanner.Scan(targetObj);

    var targetGlobal = new SigScanTarget(3, (string)vars.GlobalVarsSig) {
        OnFound = (p, s, ptr) => ptr + 0x4 + game.ReadValue<int>((IntPtr)ptr)
    };
    vars.globalVarsAddr = scanner.Scan(targetGlobal);

    var targetStrings = new SigScanTarget(3, (string)vars.StringsListSig) {
        OnFound = (p, s, ptr) => ptr + 0x4 + game.ReadValue<int>((IntPtr)ptr)
    };
    vars.stringsListAddr = scanner.Scan(targetStrings);

    if (vars.symbolAddr != IntPtr.Zero) print("ObjectArray base found at: " + vars.symbolAddr.ToString("X"));
    if (vars.globalVarsAddr != IntPtr.Zero) print("GlobalVars base found at: " + vars.globalVarsAddr.ToString("X"));
    if (vars.stringsListAddr != IntPtr.Zero) print("StringsList base found at: " + vars.stringsListAddr.ToString("X"));

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
    vars.stringDict = stringDict;
}

update {
    current.playerManagerInstance = IntPtr.Zero;
    current.gameMode = 0.0;
    current.gameWon = 0.0;

    var stringDict = vars.stringDict as Dictionary<int, string>;

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

    // 2. Resolve gameMode's offset - RETRY EVERY TICK until found.
    if (vars.globalVarsAddr != IntPtr.Zero && (int)vars.gameModeOffset == -1 && stringDict != null && stringDict.Count > 0) {
        IntPtr gVarsPtr = game.ReadValue<IntPtr>((IntPtr)vars.globalVarsAddr);
        if (gVarsPtr != IntPtr.Zero) {
            IntPtr varArrayStruct = game.ReadValue<IntPtr>(gVarsPtr + (int)vars.Object_VarArray);
            if (varArrayStruct != IntPtr.Zero) {
                int varNum = game.ReadValue<int>(varArrayStruct + (int)vars.Object_VarNum);
                IntPtr varDataPtr = game.ReadValue<IntPtr>(varArrayStruct + (int)vars.Object_VarData);
                if (varDataPtr != IntPtr.Zero) {
                    for (int i = 0; i < varNum; i++) {
                        int offset = i * 0x10;
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
    }

    // 3. Read gameMode
    if (vars.globalVarsAddr != IntPtr.Zero && (int)vars.gameModeOffset != -1) {
        IntPtr gVarsPtr = game.ReadValue<IntPtr>((IntPtr)vars.globalVarsAddr);
        if (gVarsPtr != IntPtr.Zero) {
            IntPtr varArrayStruct = game.ReadValue<IntPtr>(gVarsPtr + (int)vars.Object_VarArray);
            if (varArrayStruct != IntPtr.Zero) {
                IntPtr varDataPtr = game.ReadValue<IntPtr>(varArrayStruct + (int)vars.Object_VarData);
                if (varDataPtr != IntPtr.Zero) {
                    IntPtr finalValuePtr = game.ReadValue<IntPtr>(varDataPtr + (int)vars.gameModeOffset);
                    if (finalValuePtr != IntPtr.Zero) {
                        current.gameMode = game.ReadValue<double>(finalValuePtr);
                    }
                }
            }
        }
    }

    // 4. Walk ALL current instances of obj_PlayerManager and pick the "real" one -
    //    i.e. the one whose OWN var-array has enough variables to be an actual
    //    gameplay instance, not the lightweight menu/character-preview decoy.
    //    This does NOT depend on gameMode at all.
    IntPtr pmInstance = IntPtr.Zero;
    if ((bool)vars.resolved) {
        IntPtr objBase = (IntPtr)vars.playerManagerObjBase;
        IntPtr propPtr = game.ReadValue<IntPtr>(objBase + (int)vars.Object_PropOff);
        if (propPtr != IntPtr.Zero) {
            int instCount = game.ReadValue<int>(propPtr + (int)vars.Object_InstListNum);
            IntPtr node = game.ReadValue<IntPtr>(propPtr + (int)vars.Object_InstListBase);
            int limit = Math.Min(Math.Max(instCount, 0), 64); // sanity cap
            for (int i = 0; i < limit && node != IntPtr.Zero; i++) {
                IntPtr candidate = game.ReadValue<IntPtr>(node + (int)vars.Object_InstOff);
                if (candidate != IntPtr.Zero) {
                    IntPtr varArrStruct = game.ReadValue<IntPtr>(candidate + (int)vars.Object_VarArray);
                    if (varArrStruct != IntPtr.Zero) {
                        int varCount = game.ReadValue<int>(varArrStruct + (int)vars.Object_VarNum);
                        if (varCount >= (int)vars.MinRealVarCount) {
                            pmInstance = candidate;
                            break; // found the real gameplay instance - stop walking
                        }
                    }
                }
                node = game.ReadValue<IntPtr>(node); // advance to next linked-list node
            }
        }
    }
    current.playerManagerInstance = pmInstance;

    // 5. Detect a NEW real PlayerManager instance (a fresh instance means a
    //    fresh var-array allocation, whose hash table can place "gameWon" at
    //    a different offset).
    if (pmInstance != IntPtr.Zero && pmInstance != (IntPtr)vars.lastPmInstance) {
        vars.gameWonOffset = -1;
        vars.lastPmInstance = pmInstance;
        IntPtr dbgVarArrStruct = game.ReadValue<IntPtr>(pmInstance + (int)vars.Object_VarArray);
        int dbgVarCount = dbgVarArrStruct != IntPtr.Zero ? game.ReadValue<int>(dbgVarArrStruct + (int)vars.Object_VarNum) : -1;
        print("Real PlayerManager instance changed to 0x" + pmInstance.ToString("X") + " (varCount=" + dbgVarCount + ") - rescanning gameWon offset.");
    }

    // 6. Resolve "gameWon"'s offset inside the (already-filtered) real instance's var array.
    if (pmInstance != IntPtr.Zero && (int)vars.gameWonOffset == -1 && stringDict != null && stringDict.Count > 0) {
        IntPtr instVarArrayStruct = game.ReadValue<IntPtr>(pmInstance + (int)vars.Object_VarArray);
        if (instVarArrayStruct != IntPtr.Zero) {
            int instVarNum = game.ReadValue<int>(instVarArrayStruct + (int)vars.Object_VarNum);
            IntPtr instVarDataPtr = game.ReadValue<IntPtr>(instVarArrayStruct + (int)vars.Object_VarData);
            if (instVarDataPtr != IntPtr.Zero) {
                for (int i = 0; i < instVarNum; i++) {
                    int offset = i * 0x10;
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

    // 7. Read gameWon
    if (pmInstance != IntPtr.Zero && (int)vars.gameWonOffset != -1) {
        IntPtr instVarArrayStruct = game.ReadValue<IntPtr>(pmInstance + (int)vars.Object_VarArray);
        if (instVarArrayStruct != IntPtr.Zero) {
            IntPtr instVarDataPtr = game.ReadValue<IntPtr>(instVarArrayStruct + (int)vars.Object_VarData);
            if (instVarDataPtr != IntPtr.Zero) {
                IntPtr finalValuePtr = game.ReadValue<IntPtr>(instVarDataPtr + (int)vars.gameWonOffset);
                if (finalValuePtr != IntPtr.Zero) {
                    current.gameWon = game.ReadValue<double>(finalValuePtr);
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
