state("Catgirl") {}

startup {
    // --- Signatures and Offsets ---
    vars.ObjectArraySig = "4c 8b 15 ?? ?? ?? ?? 45 8b f1";
    vars.StringsListSig = "48 8B 05 ?? ?? ?? ?? 48 ?? ?? 0F 85 ?? ?? ?? ?? 48 ?? ?? ?? ?? ?? ?? 8D";

    vars.Object_Num          = 0x0C;
    vars.Object_Spacing      = 0x10;
    vars.Object_PropOff      = 0x18;
    vars.Object_NameOff      = 0x00;
    vars.Object_InstListBase = 0x68;
    vars.Object_InstOff      = 0x10;
    vars.Object_VarArray     = 0x48; 
    vars.Object_VarNum       = 0x08;
    vars.Object_VarData      = 0x10; 
    vars.Object_VarIndex     = 0x08; 
    vars.Object_VarOffMult   = 0x10;

    // --- Configuration ---
    vars.startSentence = "Oh well, I should head back to town.";
    vars.splitThreshold = 479.0;

    vars.stringDict = new Dictionary<int, string>();
    vars.lastLogTime = 0;
}

init {
    var scanner = new SignatureScanner(game, game.MainModule.BaseAddress, game.MainModule.ModuleMemorySize);

    var targetObj = new SigScanTarget(3, (string)vars.ObjectArraySig) {
        OnFound = (p, s, ptr) => ptr + 0x4 + game.ReadValue<int>((IntPtr)ptr)
    };
    vars.symbolAddr = scanner.Scan(targetObj);

    var targetStrings = new SigScanTarget(3, (string)vars.StringsListSig) {
        OnFound = (p, s, ptr) => ptr + 0x4 + game.ReadValue<int>((IntPtr)ptr)
    };
    vars.stringsListAddr = scanner.Scan(targetStrings);

    vars.stringDict.Clear();
}

update {
    if (vars.symbolAddr == IntPtr.Zero || vars.stringsListAddr == IntPtr.Zero) return false;

    // 1. Maintain String Dictionary
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

    current.textBoxText = "";
    current.timeAlive = 0.0;

    IntPtr objArrayBase = game.ReadValue<IntPtr>((IntPtr)vars.symbolAddr);
    if (objArrayBase == IntPtr.Zero) return false;

    int numObjects = game.ReadValue<int>(objArrayBase + (int)vars.Object_Num);
    IntPtr arr = game.ReadValue<IntPtr>(objArrayBase);
    
    for (int i = 0; i < Math.Min(numObjects, 2048); i++) {
        IntPtr oAddr = game.ReadValue<IntPtr>(arr + (i * (int)vars.Object_Spacing));
        if (oAddr == IntPtr.Zero) continue;
        
        IntPtr propPtr = game.ReadValue<IntPtr>(oAddr + (int)vars.Object_PropOff);
        IntPtr namePtr = game.ReadValue<IntPtr>(propPtr + (int)vars.Object_NameOff);
        string objName = game.ReadString(namePtr, 64);

        // --- Start Logic: pTextBox ---
        if (objName == "pTextBox") {
            IntPtr node = game.ReadValue<IntPtr>(propPtr + (int)vars.Object_InstListBase);
            if (node != IntPtr.Zero) {
                IntPtr instAddr = game.ReadValue<IntPtr>(node + (int)vars.Object_InstOff);
                IntPtr ptrVarArr = game.ReadValue<IntPtr>(instAddr + (int)vars.Object_VarArray);
                if (ptrVarArr != IntPtr.Zero) {
                    IntPtr varDataPtr = game.ReadValue<IntPtr>(ptrVarArr + (int)vars.Object_VarData);
                    int varNum = game.ReadValue<int>(ptrVarArr + (int)vars.Object_VarNum);
                    for (int v = 0; v < Math.Min(varNum, 256); v++) {
                        int offset = v * (int)vars.Object_VarOffMult;
                        int nameID = game.ReadValue<int>(varDataPtr + offset + (int)vars.Object_VarIndex);
                        if (vars.stringDict.ContainsKey(nameID) && vars.stringDict[nameID] == "text") {
                            IntPtr ptr3 = game.ReadValue<IntPtr>(varDataPtr + offset); 
                            IntPtr ptr4 = game.ReadValue<IntPtr>(ptr3); 
                            IntPtr ptr5 = game.ReadValue<IntPtr>(ptr4); 
                            if (ptr5 != IntPtr.Zero) current.textBoxText = game.ReadString(ptr5, 512);
                            break;
                        }
                    }
                }
            }
        }

        // --- Split Logic: oCreditsPainting ---
        if (objName == "oCreditsPainting") {
            IntPtr node = game.ReadValue<IntPtr>(propPtr + (int)vars.Object_InstListBase);
            if (node != IntPtr.Zero) {
                IntPtr instAddr = game.ReadValue<IntPtr>(node + (int)vars.Object_InstOff);
                IntPtr ptrVarArr = game.ReadValue<IntPtr>(instAddr + (int)vars.Object_VarArray);
                if (ptrVarArr != IntPtr.Zero) {
                    IntPtr varDataPtr = game.ReadValue<IntPtr>(ptrVarArr + (int)vars.Object_VarData);
                    int varNum = game.ReadValue<int>(ptrVarArr + (int)vars.Object_VarNum);
                    for (int v = 0; v < Math.Min(varNum, 256); v++) {
                        int offset = v * (int)vars.Object_VarOffMult;
                        int nameID = game.ReadValue<int>(varDataPtr + offset + (int)vars.Object_VarIndex);
                        if (vars.stringDict.ContainsKey(nameID) && vars.stringDict[nameID] == "timeAlive") {
                            IntPtr valPtr = game.ReadValue<IntPtr>(varDataPtr + offset);
                            if (valPtr != IntPtr.Zero) {
                                current.timeAlive = game.ReadValue<double>(valPtr);
                            }
                            break;
                        }
                    }
                }
            }
        }
    }

    // --- Logging ---

    /*
    // Log timeAlive every 2000ms
    if (Environment.TickCount - (int)vars.lastLogTime > 2000) {
        if (current.timeAlive > 0) {
            print("oCreditsPainting.timeAlive: " + current.timeAlive.ToString("F2"));
        }
        vars.lastLogTime = Environment.TickCount;
    }

    // Log textBoxText when it changes
    if (current.textBoxText != old.textBoxText && !string.IsNullOrEmpty(current.textBoxText)) {
        print("pTextBox.text changed: " + current.textBoxText);
    }
    */
}

start {
    if (old.textBoxText != current.textBoxText && current.textBoxText == (string)vars.startSentence) {
        print("Start Sentence detected: " + current.textBoxText);
        return true;
    }
}

split {
    if (old.timeAlive < (double)vars.splitThreshold && current.timeAlive >= (double)vars.splitThreshold) {
        print("Split threshold reached: " + current.timeAlive);
        return true;
    }
}
