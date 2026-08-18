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
    vars.ManagerComponent = IntPtr.Zero;
    vars.StaticField = IntPtr.Zero;

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

    vars.GetStaticFields = (Func<IntPtr, IntPtr>)(nativeObjPtr => 
    {
        if (nativeObjPtr == IntPtr.Zero) return IntPtr.Zero;

        return game.ReadPointer(nativeObjPtr + 0xB8);
    });

    vars.GetManagerMissions = (Func<IntPtr, IntPtr>)(nativeObjPtr => 
    {
        if (nativeObjPtr == IntPtr.Zero) return IntPtr.Zero;

        return game.ReadPointer(nativeObjPtr + 0x50);
    });

    vars.CheckAllObjectivesAccomplished = (Func<IntPtr, bool>)(missionPtr =>
    {
        if (missionPtr == IntPtr.Zero) return false;

        IntPtr listPtr = game.ReadPointer(missionPtr + 0x48); // List<Objective>
        if (listPtr == IntPtr.Zero) return false;

        IntPtr itemsArrayPtr = game.ReadPointer(listPtr + 0x10); // _items
        int size = game.ReadValue<int>(listPtr + 0x18);          // _size

        if (itemsArrayPtr == IntPtr.Zero || size <= 0) return false;

        bool hasValidObjective = false; // 用來確保至少有一個有效 Objective 被檢查過

        for (int i = 0; i < size; i++)
        {
            IntPtr objPtr = game.ReadPointer(itemsArrayPtr + 0x20 + (i * 0x8));
            if (objPtr == IntPtr.Zero) continue; // 空指標直接跳過，不影響判定

            int currentNumber = game.ReadValue<int>(objPtr + 0x34); // Objective.CurrentNumber
            if (currentNumber == 0) continue; // CurrentNumber == 0 -> 跳過此 Objective

            bool accomplished = game.ReadValue<bool>(objPtr + 0x30); // Objective.Accomplished
            hasValidObjective = true;

            if (!accomplished) return false; // 只要有一個「有效且未完成」就不算
        }

        return hasValidObjective; // 全部有效的都 Accomplished == true 才回傳 true
    });

    // 8. 嘗試快取 managerComponent + staticField (只需成功一次)
    vars.TryCacheManager = (Func<bool>)(() =>
    {
        IntPtr managerObj = vars.FindGameObject("~CodexRPG");
        if (managerObj == IntPtr.Zero) return false;

        IntPtr managerComponent = vars.GetComponentByIndex(managerObj, 1);
        if (managerComponent == IntPtr.Zero) return false;

        IntPtr klassPtr = game.ReadPointer(managerComponent);
        if (klassPtr == IntPtr.Zero) return false;

        IntPtr staticField = vars.GetStaticFields(klassPtr);
        if (staticField == IntPtr.Zero) return false;

        vars.ManagerComponent = managerComponent;
        vars.StaticField = staticField;

        print("[Cached] ManagerComponent: " + managerComponent.ToString("X") + 
            " StaticField: " + staticField.ToString("X"));

        return true;
    });

    vars.Instance = vars.Uhara.CreateTool("Unity", "IL2CPP", "Instance");
    vars.Utils = vars.Uhara.CreateTool("Unity", "Utils");

    vars.Instance.Watch<IntPtr>("Agent", "Agent");
    vars.Instance.Watch<float>("xVel", "Agent", "0xE0", "0x48");
    vars.Instance.Watch<float>("yVel", "Agent", "0xE0", "0x50");

    // 先嘗試抓一次 (若此時遊戲已在場景中)
    vars.TryCacheManager();
}

update
{
    vars.Uhara.Update();

    current.ActiveScene = vars.Utils.GetActiveSceneName() ?? current.ActiveScene;

    if(current.ActiveScene != old.ActiveScene)
    {
        print("old.ActiveScene: " + old.ActiveScene + " - > current.ActiveScene: " + current.ActiveScene);
    }

    double speed = Math.Sqrt((current.xVel * current.xVel) + (current.yVel * current.yVel));
    current.Speed = speed;

    timer.Run.Metadata.SetCustomVariable("Speed", speed.ToString("F1"));

    // 尚未快取成功 -> 每幀重試一次，直到抓到為止
    if ((IntPtr)vars.StaticField == IntPtr.Zero)
    {
        vars.TryCacheManager();
    }

    // 已快取 -> 每幀只重新讀取 mission (因為要進關卡才會生成)
    if ((IntPtr)vars.StaticField != IntPtr.Zero)
    {
        IntPtr staticField = (IntPtr)vars.StaticField;
        IntPtr mission = vars.GetManagerMissions(staticField);

        current.MissionPtr = mission;
        current.AllObjectivesAccomplished = vars.CheckAllObjectivesAccomplished(mission);
    }
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

start
{
    return current.Agent != old.Agent && current.Agent != IntPtr.Zero;
}

split
{
    return current.AllObjectivesAccomplished && !old.AllObjectivesAccomplished;
}

isLoading
{
    return true;
}
