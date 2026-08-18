state("Agent 64 Spies Never Die")
{
    // 64-bit UnityPlayer.dll -> GameObjectManager 指針
    ulong gom: "UnityPlayer.dll", 0x1A24818; 
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
}

init
{
    // 緩存變數初始化
    vars.CachedTimerManaged = IntPtr.Zero;

    // 1. 讀取雙向鏈結串列 (x64 BaseLinkedListNode: +0x00 Next, +0x08 BaseObject*)
    vars.ReadGameObjectList = (Func<IntPtr, List<IntPtr>>)(listHeadPtr => 
    {
        var gameObjects = new List<IntPtr>();
        if (listHeadPtr == IntPtr.Zero) return gameObjects;

        IntPtr firstNode = game.ReadPointer(listHeadPtr);
        if (firstNode == IntPtr.Zero) return gameObjects;

        IntPtr currentNode = firstNode;
        int safetyLimit = 5000;

        while (currentNode != IntPtr.Zero && safetyLimit-- > 0)
        {
            IntPtr baseObjectPtr = game.ReadPointer(currentNode + 0x08);
            if (baseObjectPtr != IntPtr.Zero)
            {
                gameObjects.Add(baseObjectPtr);
            }

            currentNode = game.ReadPointer(currentNode + 0x00);
            if (currentNode == firstNode) break;
        }

        return gameObjects;
    });

    // 2. 讀取 GameObject 名稱 (x64: GameObject + 0x60 -> m_Name)
    vars.GetGameObjectName = (Func<IntPtr, string>)(goPtr => 
    {
        if (goPtr == IntPtr.Zero) return "";

        IntPtr namePtr = game.ReadPointer(goPtr + 0x60); 
        if (namePtr == IntPtr.Zero) return "";

        return game.ReadString(namePtr, 128) ?? "";
    });

    // 3. 根據名稱搜尋目標 GameObject*
    vars.FindGameObject = (Func<string, IntPtr>)(targetName => 
    {
        IntPtr gomPtr = (IntPtr)current.gom;
        if (gomPtr == IntPtr.Zero) return IntPtr.Zero;

        int[] searchOffsets = { 0x08, 0x28 };

        foreach (int offset in searchOffsets)
        {
            List<IntPtr> baseObjects = vars.ReadGameObjectList(gomPtr + offset);

            foreach (IntPtr baseObj in baseObjects)
            {
                IntPtr gameObjectPtr = game.ReadPointer(baseObj + 0x10);
                if (gameObjectPtr == IntPtr.Zero) continue;

                if (vars.GetGameObjectName(gameObjectPtr) == targetName)
                {
                    return gameObjectPtr;
                }
            }
        }

        return IntPtr.Zero; 
    });

    // 4. Native Object -> Managed C# Object* (+0x28)
    vars.GetManagedObject = (Func<IntPtr, IntPtr>)(nativeObjPtr => 
    {
        if (nativeObjPtr == IntPtr.Zero) return IntPtr.Zero;

        return game.ReadPointer(nativeObjPtr + 0x28);
    });

    // 5. 從 Managed Object 讀取 Class Name
    vars.GetClassName = (Func<IntPtr, string>)(managedObjPtr => 
    {
        if (managedObjPtr == IntPtr.Zero) return "";

        IntPtr classRegPtr = game.ReadPointer(managedObjPtr + 0x00);
        if (classRegPtr == IntPtr.Zero) return "";

        IntPtr namePtr = game.ReadPointer(classRegPtr + 0x10);
        if (namePtr == IntPtr.Zero) return "";

        return game.ReadString(namePtr, 128) ?? "";
    });

    // 6. 依 Index (0-based) 取得 GameObject 上的 Component Managed Object*
    vars.GetComponentByIndex = (Func<IntPtr, int, IntPtr>)((goPtr, index) => 
    {
        if (goPtr == IntPtr.Zero || index < 0) 
            return IntPtr.Zero;

        int componentCount = game.ReadValue<int>(goPtr + 0x40);
        IntPtr componentsArrayPtr = game.ReadPointer(goPtr + 0x30);

        if (componentsArrayPtr == IntPtr.Zero || index >= componentCount) 
            return IntPtr.Zero;

        IntPtr componentPtr = game.ReadPointer(componentsArrayPtr + 0x08 + (index * 0x10));
        if (componentPtr == IntPtr.Zero) 
            return IntPtr.Zero;

        return vars.GetManagedObject(componentPtr);
    });

    // 7. 讀取 IGT Helper
    vars.GetInGameTime = (Func<IntPtr, double>)(managedObjPtr => 
    {
        if (managedObjPtr == IntPtr.Zero) return 0.0;
        return game.ReadValue<double>(managedObjPtr + 0x20);
    });

    vars.Instance = vars.Uhara.CreateTool("Unity", "IL2CPP", "Instance");
    vars.Instance.Watch<float>("xVel", "Agent", "0xE0", "0x48");
    vars.Instance.Watch<float>("yVel", "Agent", "0xE0", "0x50");
}

update
{
    vars.Uhara.Update();

    double speed = Math.Sqrt((current.xVel * current.xVel) + (current.yVel * current.yVel));
    current.Speed = speed;

    timer.Run.Metadata.SetCustomVariable("Speed", speed.ToString("F1"));
}

gameTime
{
    IntPtr cachedPtr = (IntPtr)(vars.CachedTimerManaged ?? IntPtr.Zero);

    if (cachedPtr == IntPtr.Zero)
    {
        IntPtr chronoGo = vars.FindGameObject("Chrono (TMP)");
        if (chronoGo != IntPtr.Zero)
        {
            cachedPtr = vars.GetComponentByIndex(chronoGo, 3);
            vars.CachedTimerManaged = cachedPtr;
        }
    }

    if (cachedPtr != IntPtr.Zero)
    {
        IntPtr classRegPtr = game.ReadPointer(cachedPtr + 0x00);
        if (classRegPtr == IntPtr.Zero)
        {
            vars.CachedTimerManaged = IntPtr.Zero;
            return null;
        }

        double seconds = vars.GetInGameTime(cachedPtr);
        if (seconds >= 0)
        {
            return TimeSpan.FromSeconds(seconds);
        }
    }
}

isLoading
{
    return true;
}
