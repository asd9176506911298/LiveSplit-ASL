state("WiiCompiled") {
}

init {
    // Converts a big-endian PPC pointer into a directly readable PC memory address
    vars.ReadPpcPointer = (Func<IntPtr, IntPtr>)(addr => {
        uint raw = game.ReadValue<uint>(addr);
        if (raw == 0) return IntPtr.Zero;
        uint ppcAddr = System.Buffers.Binary.BinaryPrimitives.ReverseEndianness(raw);
        return (IntPtr)(0x100000000000UL + ppcAddr);
    });
}

isLoading {
    // --- SectionMgr: high-level section state (Race / Menu / Channel / WFC etc.) ---
    // func_80634C90
    // 80634c90 SectionMgr::CreateInstance
    // 1. Read SectionMgr::s_Instance (0x809C1E38)
    // 2. Read 'state' at offset 0x30
        // Values: 0 = Active (Race/Menu), 1 = Changing, 2 = Transition, 3 = Loading
    IntPtr sectionMgrPtr = vars.ReadPpcPointer((IntPtr)0x1000809C1E38);
    bool sectionLoading = false;
    if (sectionMgrPtr != IntPtr.Zero) {
        uint state = System.Buffers.Binary.BinaryPrimitives.ReverseEndianness(
            game.ReadValue<uint>(sectionMgrPtr + 0x30));
        sectionLoading = state != 0;
    }

    // --- RKSceneManager: intra-section scene transition busy flag ---
    // rkSystem is a fixed static instance at PPC address 0x802A4080
    // SceneManager pointer = rkSystem + 0x54
    // Busy flag (transition in progress) = SceneManager instance + 0x50
    IntPtr rkSystemAddr = (IntPtr)(0x100000000000UL + 0x802A4080);
    IntPtr sceneMgrPtr = vars.ReadPpcPointer(rkSystemAddr + 0x54);
    bool sceneBusy = false;
    if (sceneMgrPtr != IntPtr.Zero) {
        uint busyFlag = System.Buffers.Binary.BinaryPrimitives.ReverseEndianness(
            game.ReadValue<uint>(sceneMgrPtr + 0x50));
        sceneBusy = busyFlag != 0;
    }

    return sectionLoading || sceneBusy;
}
