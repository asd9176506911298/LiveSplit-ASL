state("PAC-MAN WORLD 2 Re-PAC") {}
startup {
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
}

init {
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

        // 3. Iterate through each child Transform
        for (int i = 0; i < childCount; i++)
        {
            var childTransform = game.ReadValue<IntPtr>(childs + 0x8 * i);

            // 4. Get GameObject from Transform
            var gameObject = game.ReadValue<IntPtr>(childTransform + 0x20);

            // 5. Get the name string pointer from GameObject
            var namePtr = game.ReadValue<IntPtr>(gameObject + 0x50);

            // 6. Read and compare the string
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
            return IntPtr.Zero; // Bounds check protection

        // 3. Base address of the m_Component array (array of ComponentPair structs)
        var components = game.ReadValue<IntPtr>(p + 0x20);

        // 4. Each pair is 0x10 in size; the pair structure is typically { typeIndex(0x8), componentPtr(0x8) }
        //    so the actual component pointer is at pair address + 0x8
        var pairAddr = components + 0x8 + (0x10 * index);
        var component = game.ReadValue<IntPtr>(pairAddr);
        component = game.ReadValue<IntPtr>(component + 0x18);
        component = game.ReadValue<IntPtr>(component + 0x0);

        return component;
    });

    vars.Instance = vars.Uhara.CreateTool("Unity", "IL2CPP", "Instance");

    vars.Instance.Watch<IntPtr>("test", "TitleScene", "m_sUICanvas");
}

update {
    vars.Uhara.Update();

    if(current.test != old.test)
    {
        print("test: " + current.test.ToString("X"));
        var transform = vars.ComponentGetTransform(current.test);
        print("componentGetTransform: " + transform.ToString("X"));
        var child = vars.TransformGetChildByName(transform, "Common_EasyModeSelect(Clone)");
        print("transformGetChildByName: " + child.ToString("X"));
        var gameObject = vars.TransformGetGameObject(child);
        print("transformGetGameObject: " + gameObject.ToString("X"));
        var component = vars.getComponentByIndex(gameObject, 1);
        print("getComponentByIndex: " + component.ToString("X"));
    }
}