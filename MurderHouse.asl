state("Murder House") 
{ 
    int gom: "UnityPlayer.dll", 0xFE07B0;
}

init
{
    vars.videoGO = IntPtr.Zero;
    vars.titleTransform = IntPtr.Zero;
    vars.tomDeathTransform = IntPtr.Zero;
    vars.tomDeathWasActive = false;
    vars.CarEndTransform = IntPtr.Zero;
    vars.CarEndWasActive = false;
    vars.isStart1985 = false;

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

start
{
    // Only search once, then reuse the cached pointer
    if (vars.videoGO == IntPtr.Zero)
        // Path: Scripted House OFF/Section 1 - Break into house/Scene 1 Intro House OFF/Van/Present Day Canvas OFF
        vars.videoGO = vars.FindGameObject("Van");

    if (vars.titleTransform == IntPtr.Zero)
        // Path: Scriped Mall OFF/Easter Photo Intro ON/Presents Canvas
        vars.titleTransform = vars.FindGameObject("Easter Photo Intro ON");

    bool vanTriggered = false;
    if (vars.videoGO != IntPtr.Zero)
    {
        var vanTransform = vars.GameObjectGetTransform(vars.videoGO);
        var vanChild = vars.TransformGetChildByName(vanTransform, "Present Day Canvas OFF");
        vanTriggered = vars.TransformGetIsActive(vanChild);
    }

    bool easterTriggered = false;
    if (vars.titleTransform != IntPtr.Zero)
    {
        var easterTransform = vars.GameObjectGetTransform(vars.titleTransform);
        var easterChild = vars.TransformGetChildByName(easterTransform, "Presents Canvas");
        easterTriggered = vars.TransformGetIsActive(easterChild);
        if(easterTriggered)
          vars.isStart1985 = true;
    }

    // Start triggers if either branch fires (Van branch OR Easter Mall branch)
    return vanTriggered || easterTriggered;
}

update
{
    if ((IntPtr)vars.tomDeathTransform == IntPtr.Zero)
    {
        var sectionGO = vars.FindGameObject("Section 5 - Escaping");
        if (sectionGO != IntPtr.Zero)
        {
            var sectionTransform = vars.GameObjectGetTransform(sectionGO);
            vars.tomDeathTransform = vars.TransformGetChildByName(sectionTransform, "Tom Death End OFF");
        }
    }
    
    if ((IntPtr)vars.CarEndTransform == IntPtr.Zero)
    {
        var CarParentGO = vars.FindGameObject("Section 6 - Post Credits OFF");
        if (CarParentGO != IntPtr.Zero)
        {
            var sectionTransform = vars.GameObjectGetTransform(CarParentGO);
            vars.CarEndTransform = vars.TransformGetChildByName(sectionTransform, "Cutscene 12 - Driving End OFF");
        }
    }
}

split
{   
    if(!vars.isStart1985)
    {
        bool isActive = vars.TransformGetIsActive(vars.tomDeathTransform);
        bool triggered = isActive && !vars.tomDeathWasActive;

        vars.tomDeathWasActive = isActive;
        return triggered;
    }
    else
    {
        bool isActive = vars.TransformGetIsActive(vars.CarEndTransform);
        bool triggered = isActive && !vars.CarEndWasActive;

        vars.CarEndWasActive = isActive;
        return triggered;
    }
}

onReset
{
    vars.videoGO = IntPtr.Zero;
    vars.titleTransform = IntPtr.Zero;
    vars.tomDeathTransform = IntPtr.Zero;
    vars.tomDeathWasActive = false;
    vars.CarEndTransform = IntPtr.Zero;
    vars.CarEndWasActive = false;
    vars.isStart1985 = false;
}
