state("Agent 64 Spies Never Die")
{
    ulong gom: "UnityPlayer.dll", 0x1A24818; 
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
}

init
{
    vars.CachedTimerManaged = IntPtr.Zero;
    vars.ManagerComponent = IntPtr.Zero;
    vars.StaticField = IntPtr.Zero;

    vars.AccumulatedSeconds = 0.0;
    vars.LevelRetryAccumulated = 0.0;
    vars.HasSpawnedThisLevel = false; // 這一關是否已經生成過一次角色

    current.RawLevelSeconds = 0.0;
    current.MissionPtr = IntPtr.Zero;

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

    vars.GetGameObjectName = (Func<IntPtr, string>)(goPtr => 
    {
        if (goPtr == IntPtr.Zero) return "";

        IntPtr namePtr = game.ReadPointer(goPtr + 0x60); 
        if (namePtr == IntPtr.Zero) return "";

        return game.ReadString(namePtr, 128) ?? "";
    });

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

    vars.GetManagedObject = (Func<IntPtr, IntPtr>)(nativeObjPtr => 
    {
        if (nativeObjPtr == IntPtr.Zero) return IntPtr.Zero;
        return game.ReadPointer(nativeObjPtr + 0x28);
    });

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

        IntPtr listPtr = game.ReadPointer(missionPtr + 0x48);
        if (listPtr == IntPtr.Zero) return false;

        IntPtr itemsArrayPtr = game.ReadPointer(listPtr + 0x10);
        int size = game.ReadValue<int>(listPtr + 0x18);

        if (itemsArrayPtr == IntPtr.Zero || size <= 0) return false;

        bool hasValidObjective = false;

        for (int i = 0; i < size; i++)
        {
            IntPtr objPtr = game.ReadPointer(itemsArrayPtr + 0x20 + (i * 0x8));
            if (objPtr == IntPtr.Zero) continue;

            int currentNumber = game.ReadValue<int>(objPtr + 0x34);
            if (currentNumber == 0) continue;

            bool accomplished = game.ReadValue<bool>(objPtr + 0x30);
            hasValidObjective = true;

            if (!accomplished) return false;
        }

        return hasValidObjective;
    });

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

    vars.GetRawChronoSeconds = (Func<double>)(() =>
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
                return -1.0;
            }

            double seconds = vars.GetInGameTime(cachedPtr);
            if (seconds >= 0)
            {
                return seconds;
            }
        }

        return -1.0;
    });

    vars.Instance = vars.Uhara.CreateTool("Unity", "IL2CPP", "Instance");
    vars.Utils = vars.Uhara.CreateTool("Unity", "Utils");

    vars.Instance.Watch<IntPtr>("Agent", "Agent");
    vars.Instance.Watch<float>("xVel", "Agent", "0xE0", "0x48");
    vars.Instance.Watch<float>("yVel", "Agent", "0xE0", "0x50");

    vars.TryCacheManager();
}

update
{
    vars.Uhara.Update();

    current.ActiveScene = vars.Utils.GetActiveSceneName() ?? current.ActiveScene;

    if (current.ActiveScene != old.ActiveScene)
    {
        print("old.ActiveScene: " + old.ActiveScene + " - > current.ActiveScene: " + current.ActiveScene);
    }

    double speed = Math.Sqrt((current.xVel * current.xVel) + (current.yVel * current.yVel));
    current.Speed = speed;
    timer.Run.Metadata.SetCustomVariable("Speed", speed.ToString("F1"));

    if ((IntPtr)vars.StaticField == IntPtr.Zero)
    {
        vars.TryCacheManager();
    }

    if ((IntPtr)vars.StaticField != IntPtr.Zero && (IntPtr)current.Agent != IntPtr.Zero)
    {
        IntPtr staticField = (IntPtr)vars.StaticField;
        IntPtr mission = vars.GetManagerMissions(staticField);

        current.MissionPtr = mission;
        current.AllObjectivesAccomplished = vars.CheckAllObjectivesAccomplished(mission);
    }
    else
    {
        current.MissionPtr = IntPtr.Zero;
        current.AllObjectivesAccomplished = false;
    }

    double rawSeconds = vars.GetRawChronoSeconds();

    // 用 Agent「從 0 變成非 0」判斷是否為一次新的嘗試 (死亡重生 / 手動 Retry)
    if (current.Agent != IntPtr.Zero && old.Agent == IntPtr.Zero)
    {
        if (vars.HasSpawnedThisLevel)
        {
            vars.LevelRetryAccumulated += old.RawLevelSeconds;
            print("[Retry Detected] Agent respawned: " + ((IntPtr)current.Agent).ToString("X")
                + "  Banked " + old.RawLevelSeconds.ToString("F3")
                + "s. LevelRetryAccumulated: " + vars.LevelRetryAccumulated.ToString("F3") + "s");
        }
        vars.HasSpawnedThisLevel = true;
    }

    current.RawLevelSeconds = rawSeconds >= 0 ? rawSeconds : old.RawLevelSeconds;
}

gameTime
{
    return TimeSpan.FromSeconds(vars.AccumulatedSeconds + vars.LevelRetryAccumulated + current.RawLevelSeconds);
}

start
{
    return current.Agent != old.Agent && current.Agent != IntPtr.Zero;
}

split
{
    bool shouldSplit = current.AllObjectivesAccomplished 
        && !old.AllObjectivesAccomplished 
        && current.ActiveScene != "snd_titre_agent";

    if (shouldSplit)
    {
        vars.AccumulatedSeconds += vars.LevelRetryAccumulated + current.RawLevelSeconds;
        vars.LevelRetryAccumulated = 0.0;
        current.RawLevelSeconds = 0.0;
        vars.HasSpawnedThisLevel = false; // 只有真正過關才重置

        print("[FullRun] Level cleared. Accumulated: " + vars.AccumulatedSeconds.ToString("F3") + "s");
    }

    return shouldSplit;
}

onReset
{
    vars.AccumulatedSeconds = 0.0;
    vars.LevelRetryAccumulated = 0.0;
    vars.HasSpawnedThisLevel = false;
    current.MissionPtr = IntPtr.Zero;
    current.AllObjectivesAccomplished = false;
}

isLoading
{
    return true;
}
