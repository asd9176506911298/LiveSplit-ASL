state("PAC-MAN WORLD 2 Re-PAC") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
}

init
{
    vars.ComponentGetTransform = (Func<IntPtr, IntPtr>)((ptr) =>
    {
        var p = game.ReadValue<IntPtr>(ptr + 0x10);
        p = game.ReadValue<IntPtr>(p + 0x20);
        p = game.ReadValue<IntPtr>(p + 0x20);
        p = game.ReadValue<IntPtr>(p + 0x8);
        p = game.ReadValue<IntPtr>(p + 0x18);
        p = game.ReadValue<IntPtr>(p + 0x0);
        return p;
    });

    vars.TransformGetChildByName = (Func<IntPtr, string, IntPtr>)((transformPtr, name) =>
    {
        // 1. Native Transform object pointer
        var p = game.ReadValue<IntPtr>(transformPtr + 0x10);

        // 2. Child count and child array pointer
        var childCount = game.ReadValue<int>(p + 0x70);
        var childs = game.ReadValue<IntPtr>(p + 0x60);

        // 3. Iterate over each child Transform
        for (int i = 0; i < childCount; i++)
        {
            var childTransform = game.ReadValue<IntPtr>(childs + 0x8 * i);

            // 4. Get the GameObject from the Transform
            var gameObject = game.ReadValue<IntPtr>(childTransform + 0x20);

            // 5. Get the name string pointer from the GameObject
            var namePtr = game.ReadValue<IntPtr>(gameObject + 0x50);

            // 6. Read the string and compare
            var childName = game.ReadString(namePtr, 128);
            if (childName == name)
            {
                return childTransform;
            }
        }

        return IntPtr.Zero; // Not found
    });

    vars.TransformGetGameObject = (Func<IntPtr, IntPtr>)((ptr) =>
    {
        var p = game.ReadValue<IntPtr>(ptr + 0x20);
        p = game.ReadValue<IntPtr>(p + 0x18);
        p = game.ReadValue<IntPtr>(p + 0x0);
        return p;
    });

    vars.getComponentByIndex = (Func<IntPtr, int, IntPtr>)((ptr, index) =>
    {
        // 1. Native GameObject object pointer
        var p = game.ReadValue<IntPtr>(ptr + 0x10);

        // 2. Component count
        var componentCount = game.ReadValue<int>(p + 0x30);

        if (index < 0 || index >= componentCount)
            return IntPtr.Zero; // Bounds check

        // 3. Base address of the m_Component array (array of ComponentPair structs)
        var components = game.ReadValue<IntPtr>(p + 0x20);

        // 4. Each pair is 0x10 bytes, typically structured as { typeIndex(0x8), componentPtr(0x8) }
        //    so the actual component pointer is at offset 0x8 from the pair's start address
        var pairAddr = components + 0x8 + (0x10 * index);
        var component = game.ReadValue<IntPtr>(pairAddr);
        component = game.ReadValue<IntPtr>(component + 0x18);
        component = game.ReadValue<IntPtr>(component + 0x0);

        return component;
    });


    vars.Instance = vars.Uhara.CreateTool("Unity", "IL2CPP", "Instance");

    vars.Instance.Watch<IntPtr>("UICanvas", "TitleScene", "m_sUICanvas");

    vars.gameLevel = IntPtr.Zero;
    vars.uiTransform = IntPtr.Zero;
    vars.currentStep = -1;
    vars.lastStep = -1;
}

update
{
    vars.Uhara.Update();

    // Whenever UICanvas changes, re-fetch the transform root and clear the previously found result
    if(current.UICanvas != old.UICanvas)
    {
        print("UICanvas: " + current.UICanvas.ToString("X"));
        vars.uiTransform = vars.ComponentGetTransform(current.UICanvas);
        vars.gameLevel = IntPtr.Zero; // Scene/UI changed, previously found pointer is now invalid
    }

    // Keep retrying until found (waiting for the Clone to be instantiated)
    if(vars.gameLevel == IntPtr.Zero && vars.uiTransform != IntPtr.Zero)
    {
        var child = vars.TransformGetChildByName(vars.uiTransform, "Common_EasyModeSelect(Clone)");
        if(child != IntPtr.Zero)
        {
            var gameObject = vars.TransformGetGameObject(child);
            var component = vars.getComponentByIndex(gameObject, 1);
            if(component != IntPtr.Zero)
            {
                vars.gameLevel = component;
                print("getComponentByIndex OK: " + component.ToString("X"));
            }
        }
    }

    // Key step: save the "current" value as "last" first, then read the new "current" value
    vars.lastStep = vars.currentStep;

    if(vars.gameLevel != IntPtr.Zero)
    {
        vars.currentStep = game.ReadValue<int>((IntPtr)vars.gameLevel + 0x6C);

        if(vars.currentStep != vars.lastStep)
        {
            print("m_step: " + vars.lastStep + " -> " + vars.currentStep);
        }
    }
}

start
{
    if(vars.gameLevel == IntPtr.Zero)
        return false;

    return vars.lastStep == 4 && vars.currentStep == 6;
}