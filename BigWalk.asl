state("Big Walk"){}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");

    vars.RewardGourd = 19; // PropGroup.RewardGourd

    // Tower key -> target SaveableHomeName values
    vars.GroupHomes = new Dictionary<string, int[]>
    {
        { "TutorialTower", new int[] { 150, 151, 152, 153 } },
        { "RedTower",      new int[] { 100, 101, 102, 103, 104 } },
        { "GreenTower",    new int[] { 110, 111, 112, 113, 114 } },
        { "YellowTower",   new int[] { 130, 131, 132, 133, 134 } },
        { "BlueTower",     new int[] { 120, 121, 122, 123, 124 } },
        { "FinalTower",    new int[] { 140, 141, 142, 143, 144, 145 } },
        { "ScrewTower",    new int[] { 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174 } },
    };

    vars.GroupNames = new Dictionary<string, string>
    {
        { "TutorialTower", "Tutorial Tower" },
        { "RedTower",      "Red Tower" },
        { "GreenTower",    "Green Tower" },
        { "YellowTower",   "Yellow Tower" },
        { "BlueTower",     "Blue Tower" },
        { "FinalTower",    "Final Tower" },
        { "ScrewTower",    "Screw Tower" },
    };

    vars.GroupOrder = new List<string>
    {
        "TutorialTower", "RedTower", "GreenTower", "YellowTower", "BlueTower", "FinalTower", "ScrewTower"
    };

    vars.CompletedGroups = new HashSet<string>();

    // ===== Settings tree =====
    settings.Add("SplitGourd", true, "Split on Gourd Placement");

    foreach (string key in vars.GroupOrder)
    {
        settings.Add(key, true, vars.GroupNames[key], "SplitGourd");
    }

    // Independent option: split every time a gourd becomes Loose (Locked -> Loose transition)
    settings.Add("PuzzleCompleted", false, "Split on Puzzle Completed Gourd(Locked -> Loose)");
}

init
{
    vars.Instance = vars.Uhara.CreateTool("Unity", "IL2CPP", "Instance");

    vars.Instance.Watch<bool>("startFlag", "PeckManager", "<isReadyForEffects>k__BackingField");
    vars.Instance.Watch<bool>("EndFlag", "MainMenuManager", "congratsMenu", "continueButton", "0x10", "0x20", "0x46");

    vars.Instance.Watch<IntPtr>("PropHomes", "PropHome", "allPropHomes", "_items");
    vars.Instance.Watch<int>("PropHomeCount", "PropHome", "allPropHomes", "_size");

    // ===== JitSave hook: capture newValue (r8) from OnChangeGourdState(oldValue, newValue) =====
    vars.JitSave = vars.Uhara.CreateTool("Unity", "IL2CPP", "JitSave");

    // "mov [rip-8], r8" — captures newValue (rdx/oldValue is already destroyed by this offset, r8/newValue survives intact)
    byte[] AsmMovR8RelativeStorage = new byte[] { 0x4C, 0x89, 0x05, 0xF1, 0xFF, 0xFF, 0xFF, 0x90 };

    IntPtr pGourdNewState = vars.JitSave.Add("Assembly-CSharp", "", "RewardGourd", "OnChangeGourdState", 2, 11, 0, AsmMovR8RelativeStorage);

    vars.Resolver.Watch<int>("gourdNewState", pGourdNewState);

    vars.JitSave.ProcessQueue();
}

update
{
    vars.Uhara.Update();

    if (current.PropHomes == IntPtr.Zero || current.PropHomeCount <= 0)
        return;

    var filledHomes = new HashSet<int>();

    for (int i = 0; i < current.PropHomeCount; i++)
    {
        IntPtr entryAddr = current.PropHomes + 0x20 + i * 0x8;
        IntPtr propHomePtr = game.ReadPointer(entryAddr);
        if (propHomePtr == IntPtr.Zero) continue;

        int pinGroup = game.ReadValue<int>(propHomePtr + 0x60);
        if (pinGroup != vars.RewardGourd) continue;

        IntPtr pinnedProp = game.ReadPointer(propHomePtr + 0xD0);
        if (pinnedProp == IntPtr.Zero) continue;

        int homeName = game.ReadValue<int>(propHomePtr + 0x98);
        filledHomes.Add(homeName);
    }

    vars.FilledHomes = filledHomes;
}

start
{
    if (!old.startFlag && current.startFlag)
    {
        return true;
    }
}

split
{
    if (!old.EndFlag && current.EndFlag)
    {
        return true;
    }

    // ===== Hook-based split: fires only on the moment newState transitions TO Loose(1) =====
    if (settings["PuzzleCompleted"] && current.gourdNewState == 1 && old.gourdNewState != 1)
    {
        return true;
    }

    if (!settings["SplitGourd"]) return false;
    if (vars.FilledHomes == null) return false;

    foreach (string key in vars.GroupOrder)
    {
        if (vars.CompletedGroups.Contains(key)) continue;
        if (!settings[key]) continue;

        int[] homes = vars.GroupHomes[key];

        bool allFilled = true;
        foreach (int homeName in homes)
        {
            if (!vars.FilledHomes.Contains(homeName))
            {
                allFilled = false;
                break;
            }
        }

        if (allFilled)
        {
            vars.CompletedGroups.Add(key);
            return true;
        }
    }

    return false;
}

onReset
{
    vars.CompletedGroups.Clear();
}
