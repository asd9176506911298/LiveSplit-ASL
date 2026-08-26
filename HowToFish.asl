state("How to Fish")
{
    ulong gom: "UnityPlayer.dll", 0x2274680; 
}

init
{
    // Global variable initialization
    vars.blackScreenImage = IntPtr.Zero;

    // 1. Get GameObject name (+0x50)
    vars.GetGameObjectName = (Func<IntPtr, string>)(goPtr => 
    {
        if (goPtr == IntPtr.Zero) return "";
        IntPtr namePtr = game.ReadPointer(goPtr + 0x50); 
        if (namePtr == IntPtr.Zero) return "";
        return game.ReadString(namePtr, 128) ?? "";
    });

    // 2. Traverse the doubly linked list nodes
    vars.ReadGameObjectList = (Func<IntPtr, List<IntPtr>>)(listHeadPtr =>
    {
        var result = new List<IntPtr>();
        if (listHeadPtr == IntPtr.Zero) return result;

        IntPtr firstNode = game.ReadPointer(listHeadPtr);
        if (firstNode == IntPtr.Zero) return result;

        IntPtr currNode = firstNode;
        int maxGuard = 2000;

        while (currNode != IntPtr.Zero && currNode != listHeadPtr && maxGuard > 0)
        {
            result.Add(currNode);
            currNode = game.ReadPointer(currNode + 0x08);
            maxGuard--;
        }

        return result;
    });

    // 3. Search for a GameObject by target name
    vars.FindGameObject = (Func<string, IntPtr>)(targetName => 
    {
        IntPtr gomPtr = (IntPtr)current.gom;
        if (gomPtr == IntPtr.Zero) return IntPtr.Zero;

        int[] searchOffsets = { 0x18, 0x20 };

        foreach (int offset in searchOffsets)
        {
            List<IntPtr> baseObjects = vars.ReadGameObjectList(gomPtr + offset);

            foreach (IntPtr baseObj in baseObjects)
            {
                IntPtr gameObjectPtr = game.ReadPointer(baseObj + 0x10);
                if (gameObjectPtr == IntPtr.Zero) 
                    gameObjectPtr = baseObj;

                if (vars.GetGameObjectName(gameObjectPtr) == targetName)
                {
                    return gameObjectPtr;
                }
            }
        }

        return IntPtr.Zero; 
    });

    // 4. Get the corresponding GameObject address from Transform address
    vars.GetGameObject = (Func<IntPtr, IntPtr>)(transformPtr =>
    {
        if (transformPtr == IntPtr.Zero) return IntPtr.Zero;
        IntPtr gameObjPtr = game.ReadPointer(transformPtr + 0x20);
        if (gameObjPtr == IntPtr.Zero)
        {
            gameObjPtr = game.ReadPointer(transformPtr + 0x30);
        }
        return gameObjPtr;
    });

    // 5. Search for the corresponding Child Transform
    vars.GetChildByName = (Func<IntPtr, string, IntPtr>)((transformPtr, targetName) =>
    {
        if (transformPtr == IntPtr.Zero || string.IsNullOrEmpty(targetName)) 
            return IntPtr.Zero;

        IntPtr childsPtr = game.ReadPointer(transformPtr + 0x48);
        int childCount = game.ReadValue<int>(transformPtr + 0x58);

        if (childsPtr == IntPtr.Zero || childCount <= 0 || childCount > 1000) 
            return IntPtr.Zero;

        for (int i = 0; i < childCount; i++)
        {
            IntPtr childTransform = game.ReadPointer(childsPtr + (i * 0x8));
            if (childTransform == IntPtr.Zero) continue;

            IntPtr childGameObject = vars.GetGameObject(childTransform);
            if (childGameObject == IntPtr.Zero) continue;

            string childName = vars.GetGameObjectName(childGameObject);
            if (childName == targetName)
            {
                return game.ReadPointer(childTransform + 0x20);
            }
        }

        return IntPtr.Zero;
    });

    vars.GetTransform = (Func<IntPtr, IntPtr>)(gameObjectPtr =>
    {
        if (gameObjectPtr == IntPtr.Zero) return IntPtr.Zero;
        return game.ReadPointer(game.ReadPointer(gameObjectPtr + 0x20) + 0x8);
    });

    vars.GetManagedObject = (Func<IntPtr, IntPtr>)(nativeObjPtr => 
    {
        if (nativeObjPtr == IntPtr.Zero) return IntPtr.Zero;
        return game.ReadPointer(game.ReadPointer(nativeObjPtr + 0x18));
    });

    vars.GetComponentByIndex = (Func<IntPtr, int, IntPtr>)((goPtr, index) => 
    {
        if (goPtr == IntPtr.Zero || index < 0) 
            return IntPtr.Zero;

        int componentCount = game.ReadValue<int>(goPtr + 0x30);
        IntPtr componentsArrayPtr = game.ReadPointer(goPtr + 0x20);

        if (componentsArrayPtr == IntPtr.Zero || index >= componentCount) 
            return IntPtr.Zero;

        IntPtr componentPtr = game.ReadPointer(componentsArrayPtr + 0x08 + (index * 0x10));
        if (componentPtr == IntPtr.Zero) 
            return IntPtr.Zero;

        return vars.GetManagedObject(componentPtr);
    });

    vars.GetAlpha = (Func<IntPtr, float>)(targetPtr =>
    {
        if (targetPtr == IntPtr.Zero) return 0.0f;
        return game.ReadValue<float>(targetPtr + 0x7C);
    });

    // -----------------------------------------------------------
    // Find pointers only once during initialization (or reload):
    // -----------------------------------------------------------
    IntPtr foundObj = vars.FindGameObject("PermaCanvas");
    if (foundObj != IntPtr.Zero)
    {
        IntPtr t = vars.GetTransform(foundObj);
        IntPtr blackScreen = vars.GetChildByName(t, "BlackScreen");
        if (blackScreen != IntPtr.Zero)
        {
            vars.blackScreenImage = vars.GetComponentByIndex(blackScreen, 2);
            print("[ASL] Successfully retrieved BlackScreen Image address: " + ((IntPtr)vars.blackScreenImage).ToString("X"));
        }
    }
}

update
{
    // If not found in init (e.g., screen not loaded yet when game launches), retry once in update
    if (vars.blackScreenImage == IntPtr.Zero)
    {
        IntPtr foundObj = vars.FindGameObject("PermaCanvas");
        if (foundObj != IntPtr.Zero)
        {
            IntPtr t = vars.GetTransform(foundObj);
            IntPtr blackScreen = vars.GetChildByName(t, "BlackScreen");
            if (blackScreen != IntPtr.Zero)
            {
                vars.blackScreenImage = vars.GetComponentByIndex(blackScreen, 2);
            }
        }
    }

    // Write current alpha to current.Alpha for old/new comparison in the start block
    current.Alpha = (vars.blackScreenImage != IntPtr.Zero) 
        ? vars.GetAlpha(vars.blackScreenImage) 
        : 1.0f;
}

start
{
    // Trigger condition: Previous frame Alpha == 1.0f (fully black), and current frame Alpha starts decreasing (< 1.0f)
    if (old.Alpha == 1.0f && current.Alpha < 1.0f)
    {
        print("[ASL] Start Triggered! Alpha decreased from 1.0 to " + current.Alpha);
        return true;
    }

    return false;
}