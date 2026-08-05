state("Nightripper 0.4.2") 
{ 
    int gom: 0x10A7058;
}

init
{
    // 儲存快取與讀取的變數
    vars.motorControllerPtr = IntPtr.Zero;

    // 1. 雙向鏈表遍歷函式
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

    // 2. 讀取 GameObject 名稱
    vars.GetGameObjectName = (Func<IntPtr, string>)(goPtr => 
    {
        if (goPtr == IntPtr.Zero) return "";
        IntPtr namePtr = game.ReadPointer(goPtr + 0x48); 
        if (namePtr == IntPtr.Zero) return "";

        var name = game.ReadString(namePtr, 128); 
        return name ?? "";
    });

    // 3. 根據名稱尋找特定 GameObject* 指標
    vars.FindGameObject = (Func<string, IntPtr>)(targetName => 
    {
        IntPtr gomPtr = (IntPtr)current.gom;
        if (gomPtr == IntPtr.Zero) return IntPtr.Zero;

        List<IntPtr> activeObjects = vars.ReadGameObjectList(gomPtr + 0x04);
        foreach (IntPtr go in activeObjects)
        {
            if (vars.GetGameObjectName(go) == targetName)
            {
                return go; 
            }
        }
        return IntPtr.Zero; 
    });

    // 4. 根據 Index 取得 Component 指標
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

    // 5. 核心：更新 MotorController 位址快取
    vars.GetMotorController = (Func<IntPtr>)(() =>
    {
        IntPtr playerAddress = vars.FindGameObject("Player");
        if (playerAddress == IntPtr.Zero) return IntPtr.Zero;

        IntPtr playerComponent = vars.GetComponentByIndex(playerAddress, 2);
        if (playerComponent == IntPtr.Zero) return IntPtr.Zero;

        return game.ReadPointer(playerComponent + 0x3C);
    });
}

update
{
    // 初始化預設值
    current.MoveHorizontal = 0f;
    current.MoveVertical = 0f;

    // 驗證快取的 motorControllerPtr 是否有效 (試讀第一個浮點數，若無效則代表場景已更換或物件被釋放)
    if (vars.motorControllerPtr != IntPtr.Zero)
    {
        // 嘗試讀取，若讀取失敗則重置指標
        try {
            current.MoveHorizontal = game.ReadValue<float>((IntPtr)vars.motorControllerPtr + 0x10);
            current.MoveVertical = game.ReadValue<float>((IntPtr)vars.motorControllerPtr + 0x14);
        } catch {
            vars.motorControllerPtr = IntPtr.Zero;
        }
    }

    // 若快取無效，嘗試重新搜尋 Player (重新鏈表遍歷)
    if (vars.motorControllerPtr == IntPtr.Zero)
    {
        vars.motorControllerPtr = vars.GetMotorController();

        // 重新尋找到位址後立即更新一次當前值
        if (vars.motorControllerPtr != IntPtr.Zero)
        {
            current.MoveHorizontal = game.ReadValue<float>((IntPtr)vars.motorControllerPtr + 0x10);
            current.MoveVertical = game.ReadValue<float>((IntPtr)vars.motorControllerPtr + 0x14);
        }
    }
}

start
{
    // 移動鍵有任何輸入時自動觸發計時器 Start
    return current.MoveHorizontal != 0f || current.MoveVertical != 0f;
}