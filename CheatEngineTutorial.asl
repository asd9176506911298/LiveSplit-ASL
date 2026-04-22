state("Tutorial-x86_64") {}

startup {
    vars.lastFormCount = 0;
}

init {
    int initialCount = 0;
    IntPtr baseAddr = modules.First().BaseAddress;
    for (int i = 0; i < 12; i++) {
        if (i == 0 || i == 7 || i == 10) continue;
        IntPtr slotAddr = baseAddr + 0x34EC00 + (i * 0x10);
        if (game.ReadValue<long>(slotAddr) != 0) {
            initialCount++;
        }
    }
    
    vars.lastFormCount = initialCount;
    vars.currentCount = initialCount;
}

update {
    int currentFormCount = 0;
    IntPtr baseAddr = modules.First().BaseAddress;

    for (int i = 0; i < 12; i++) {
        if (i == 0 || i == 7 || i == 10) continue;
        IntPtr slotAddr = baseAddr + 0x34EC00 + (i * 0x10);
        long formPtr = game.ReadValue<long>(slotAddr);
        if (formPtr != 0) {
            currentFormCount++;
        }
    }
    vars.currentCount = currentFormCount;
}

start {
    if (vars.currentCount > vars.lastFormCount) {
        vars.lastFormCount = vars.currentCount;
        return true; 
    }
}

split {
    if (vars.currentCount > vars.lastFormCount) {
        vars.lastFormCount = vars.currentCount;
        return true; 
    }
}

exit {
    var model = new TimerModel { CurrentState = timer };
    model.Split();
}