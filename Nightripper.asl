state("Nightripper 0.4.2") 
{ 
    int gom: 0x10A7058;
}

init
{
    vars.playerGO = IntPtr.Zero;
    vars.motorControllerPtr = IntPtr.Zero;
    vars.videoGO = IntPtr.Zero;
    vars.titleTransform = IntPtr.Zero;

    // 1. Traverse the doubly linked list of GameObjects
    vars.ReadGameObjectList = (Func<IntPtr, List<IntPtr>>)(listHeadPtr => 
    {
        var gameObjects = new List<IntPtr>();
        if (listHeadPtr == IntPtr.Zero) return gameObjects;

        IntPtr firstNode = game.ReadPointer(listHeadPtr);
        IntPtr currentNode = firstNode;
        int safetyLimit = 5000;

        while (currentNode != IntPtr.Zero && safetyLimit-- > 0)
        {
            IntPtr gameObjectPtr = game.ReadPointer(currentNode + 0x08);
            if (gameObjectPtr != IntPtr.Zero)
            {
                gameObjects.Add(gameObjectPtr);
            }

            currentNode = game.ReadPointer(currentNode + 0x00);
            if (currentNode == firstNode) break;
        }

        return gameObjects;
    });

    // 2. Read a GameObject's name
    vars.GetGameObjectName = (Func<IntPtr, string>)(goPtr => 
    {
        if (goPtr == IntPtr.Zero) return "";
        IntPtr namePtr = game.ReadPointer(goPtr + 0x48); 
        if (namePtr == IntPtr.Zero) return "";

        var name = game.ReadString(namePtr, 128); 
        return name ?? "";
    });

    // 3. Find a specific GameObject* pointer by name
    vars.FindGameObject = (Func<string, IntPtr>)(targetName => 
    {
        IntPtr gomPtr = (IntPtr)current.gom;
        if (gomPtr == IntPtr.Zero) return IntPtr.Zero;

        // Search both Tagged (0x04) and UnTagged (0x0C) lists
        int[] searchOffsets = { 0x04, 0x0C };

        foreach (int offset in searchOffsets)
        {
            List<IntPtr> objects = vars.ReadGameObjectList(gomPtr + offset);
            foreach (IntPtr go in objects)
            {
                if (vars.GetGameObjectName(go) == targetName) return go;
            }
        }
        return IntPtr.Zero; 
    });

    // 4. Get a Component pointer by index
    vars.GetComponentByIndex = (Func<IntPtr, int, IntPtr>)((goPtr, index) =>
    {
        if (goPtr == IntPtr.Zero || index < 0) return IntPtr.Zero;

        int componentCount = game.ReadValue<int>(goPtr + 0x24);
        if (index >= componentCount) return IntPtr.Zero;

        IntPtr componentsArray = game.ReadPointer(goPtr + 0x1C);
        if (componentsArray == IntPtr.Zero) return IntPtr.Zero;

        IntPtr entryPtr = componentsArray + (index * 0x8);
        IntPtr compPtr = game.ReadPointer(entryPtr + 0x4);
        return game.ReadPointer(compPtr + 0x18);
    });

    // 5. Core: get MotorController pointer from a known playerGO
    vars.GetMotorControllerFromPlayer = (Func<IntPtr, IntPtr>)((playerAddress) =>
    {
        if (playerAddress == IntPtr.Zero) return IntPtr.Zero;

        IntPtr playerComponent = vars.GetComponentByIndex(playerAddress, 2);
        if (playerComponent == IntPtr.Zero) return IntPtr.Zero;

        return game.ReadPointer(playerComponent + 0x3C);
    });

    vars.GameObjectGetTransform = (Func<IntPtr, IntPtr>)((ptr) =>
    {
        var p = game.ReadPointer(ptr + 0x1C);
        p = game.ReadPointer(p + 0x4);
        p = game.ReadPointer(p + 0x18);
        return p;
    });

    vars.TransformGetChildByName = (Func<IntPtr, string, IntPtr>)((transformPtr, name) =>
    {
        var p = game.ReadPointer(transformPtr + 0x8);
        var childCount = game.ReadValue<int>(p + 0x58);
        var childs = game.ReadPointer(p + 0x50);

        for (int i = 0; i < childCount; i++)
        {
            var childTransform = game.ReadPointer(childs + (i * 0x4));
            var gameObject = game.ReadPointer(childTransform + 0x1C);
            var namePtr = game.ReadPointer(gameObject + 0x48);
            var childName = game.ReadString(namePtr, 128);
            if (childName == name)
            {
                return childTransform;
            }
        }

        return IntPtr.Zero;
    });

    vars.TransformGetIsActive = (Func<IntPtr, bool>)((ptr) =>
    {
        if (ptr == IntPtr.Zero) return false;
        var p = game.ReadPointer(ptr + 0x1C);
        if (p == IntPtr.Zero) return false;
        var isActive = game.ReadValue<bool>(p + 0x3F);
        return isActive;
    });
}

update
{
    // ---- Movement input detection ----
    current.MoveHorizontal = 0f;
    current.MoveVertical = 0f;

    // Re-validate playerGO's name every frame; a mismatch means the scene was reloaded
    bool playerValid = false;
    if (vars.playerGO != IntPtr.Zero)
    {
        try
        {
            playerValid = vars.GetGameObjectName(vars.playerGO) == "Player";
        }
        catch
        {
            playerValid = false;
        }
    }

    if (!playerValid)
    {
        vars.playerGO = vars.FindGameObject("Player");
        vars.motorControllerPtr = IntPtr.Zero; // reset downstream cache to force a fresh lookup
    }

    if (vars.playerGO != IntPtr.Zero && vars.motorControllerPtr == IntPtr.Zero)
    {
        vars.motorControllerPtr = vars.GetMotorControllerFromPlayer(vars.playerGO);
    }

    if (vars.motorControllerPtr != IntPtr.Zero)
    {
        try
        {
            current.MoveHorizontal = game.ReadValue<float>((IntPtr)vars.motorControllerPtr + 0x10);
            current.MoveVertical = game.ReadValue<float>((IntPtr)vars.motorControllerPtr + 0x14);
        }
        catch
        {
            vars.motorControllerPtr = IntPtr.Zero;
        }
    }

    // ---- Ending Credits / Title visibility detection ----
    bool videoValid = false;
    if (vars.videoGO != IntPtr.Zero)
    {
        try
        {
            videoValid = vars.GetGameObjectName(vars.videoGO) == "Ending Credits";
        }
        catch
        {
            videoValid = false;
        }
    }

    if (!videoValid)
    {
        vars.videoGO = vars.FindGameObject("Ending Credits");
        vars.titleTransform = IntPtr.Zero;
    }

    if (vars.videoGO != IntPtr.Zero && vars.titleTransform == IntPtr.Zero)
    {
        IntPtr transform = vars.GameObjectGetTransform(vars.videoGO);
        if (transform != IntPtr.Zero)
        {
            vars.titleTransform = vars.TransformGetChildByName(transform, "Title");
        }
    }

    current.titleActive = false;
    if (vars.titleTransform != IntPtr.Zero)
    {
        try
        {
            current.titleActive = vars.TransformGetIsActive(vars.titleTransform);
        }
        catch
        {
            vars.videoGO = IntPtr.Zero;
            vars.titleTransform = IntPtr.Zero;
        }
    }

    return true;
}

start
{
    // Auto-start the timer when any movement input is detected
    return current.MoveHorizontal != 0f || current.MoveVertical != 0f;
}

split
{
    // Trigger a split the instant Title goes from hidden to visible
    return !old.titleActive && current.titleActive;
}
