state("Catgirl") {}

startup {
    // --- Signatures and Offsets ---
    vars.ObjectArraySig = "4c 8b 15 ?? ?? ?? ?? 45 8b f1";
    vars.StringsListSig = "48 8B 05 ?? ?? ?? ?? 48 ?? ?? 0F 85 ?? ?? ?? ?? 48 ?? ?? ?? ?? ?? ?? 8D";

    // Standard GameMaker 64-bit Offsets
    vars.Object_Num          = 0x0C;
    vars.Object_Spacing      = 0x10;
    vars.Object_PropOff      = 0x18;
    vars.Object_NameOff      = 0x00;
    vars.Object_InstListBase = 0x68;
    vars.Object_InstOff      = 0x10;
    vars.Object_VarArray     = 0x48; // Instance + 0x48
    vars.Object_VarNum       = 0x08;
    vars.Object_VarData      = 0x10; // VarArrayStruct + 0x10
    vars.Object_VarIndex     = 0x08; // Variable Name ID
    vars.Object_VarOffMult   = 0x10; // Variable spacing (16 bytes)

    // Data structures
    vars.stringDict = new Dictionary<int, string>();
    vars.startSentence = "Oh well, I should head back to town.";
}

init {
    var scanner = new SignatureScanner(game, game.MainModule.BaseAddress, game.MainModule.ModuleMemorySize);

    // Scan for Base Addresses
    var targetObj = new SigScanTarget(3, (string)vars.ObjectArraySig) {
        OnFound = (p, s, ptr) => ptr + 0x4 + game.ReadValue<int>((IntPtr)ptr)
    };
    vars.symbolAddr = scanner.Scan(targetObj);

    var targetStrings = new SigScanTarget(3, (string)vars.StringsListSig) {
        OnFound = (p, s, ptr) => ptr + 0x4 + game.ReadValue<int>((IntPtr)ptr)
    };
    vars.stringsListAddr = scanner.Scan(targetStrings);

    if (vars.symbolAddr == IntPtr.Zero || vars.stringsListAddr == IntPtr.Zero) {
        print("Searching for game signatures...");
    }

    vars.stringDict.Clear();
}

update {
    if (vars.symbolAddr == IntPtr.Zero || vars.stringsListAddr == IntPtr.Zero) return false;

    // 1. Maintain String Dictionary (ID to String mapping)
    if (vars.stringDict.Count == 0) {
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
                    string strVal = game.ReadString(namePtr, 128);
                    if (!string.IsNullOrEmpty(strVal)) vars.stringDict[stringID] = strVal;
                }
            }
        }
    }

    // 2. Resolve 5-level Pointer Chain to get Current Text
    current.textBoxText = "";
    IntPtr objArrayBase = game.ReadValue<IntPtr>((IntPtr)vars.symbolAddr);
    if (objArrayBase != IntPtr.Zero) {
        int numObjects = game.ReadValue<int>(objArrayBase + (int)vars.Object_Num);
        IntPtr arr = game.ReadValue<IntPtr>(objArrayBase);
        
        // Find pTextBox Object
        for (int i = 0; i < Math.Min(numObjects, 2048); i++) {
            IntPtr oAddr = game.ReadValue<IntPtr>(arr + (i * (int)vars.Object_Spacing));
            if (oAddr == IntPtr.Zero) continue;
            
            IntPtr propPtr = game.ReadValue<IntPtr>(oAddr + (int)vars.Object_PropOff);
            IntPtr namePtr = game.ReadValue<IntPtr>(propPtr + (int)vars.Object_NameOff);
            
            if (game.ReadString(namePtr, 64) == "pTextBox") {
                // Get the first Instance
                IntPtr node = game.ReadValue<IntPtr>(propPtr + (int)vars.Object_InstListBase);
                if (node != IntPtr.Zero) {
                    IntPtr instAddr = game.ReadValue<IntPtr>(node + (int)vars.Object_InstOff);
                    if (instAddr != IntPtr.Zero) {
                        
                        // Level 1: Instance + 0x48 -> VarArrayStruct
                        IntPtr ptr1 = game.ReadValue<IntPtr>(instAddr + (int)vars.Object_VarArray);
                        if (ptr1 != IntPtr.Zero) {
                            
                            // Level 2: ptr1 + 0x10 -> VarData
                            IntPtr varDataPtr = game.ReadValue<IntPtr>(ptr1 + (int)vars.Object_VarData);
                            int varNum = game.ReadValue<int>(ptr1 + (int)vars.Object_VarNum);

                            for (int v = 0; v < Math.Min(varNum, 200); v++) {
                                int offset = v * (int)vars.Object_VarOffMult;
                                int nameID = game.ReadValue<int>(varDataPtr + offset + (int)vars.Object_VarIndex);
                                
                                if (vars.stringDict.ContainsKey(nameID) && vars.stringDict[nameID] == "text") {
                                    
                                    // Levels 3 to 5: Sequential Dereferencing based on ReClass evidence
                                    IntPtr ptr3 = game.ReadValue<IntPtr>(varDataPtr + offset); 
                                    if (ptr3 != IntPtr.Zero) {
                                        IntPtr ptr4 = game.ReadValue<IntPtr>(ptr3); 
                                        if (ptr4 != IntPtr.Zero) {
                                            IntPtr ptr5 = game.ReadValue<IntPtr>(ptr4); 
                                            if (ptr5 != IntPtr.Zero) {
                                                // Read the final string content
                                                current.textBoxText = game.ReadString(ptr5, 512);
                                            }
                                        }
                                    }
                                    break;
                                }
                            }
                        }
                    }
                }
                break;
            }
        }
    }
}

start {
    // Start the timer when the text matches the target sentence
    if (old.textBoxText != current.textBoxText && current.textBoxText == (string)vars.startSentence) {
        print("Starting Timer: " + current.textBoxText);
        return true;
    }
}