state("Big Walk"){}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
    vars.Uhara.AlertLoadless();

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

    // --- Player count selector (acts like a radio group: only one can be checked) ---
    settings.Add("playercount", true, "Target Player Count (start when lobby reaches this many)");
    for (int i = 1; i <= 12; i++)
    {
        settings.Add("p" + i, i == 1, i + (i == 1 ? " Player" : " Players"), "playercount");
    }

    settings.Add("SplitPuzzle", false, "Split on Puzzle Finish Local Only");
}

init
{
    vars.Instance = vars.Uhara.CreateTool("Unity", "IL2CPP", "Instance");

    // vars.Instance.Watch<int>("entryMode", "MainMenuManager", "entryMode");
    //                                                       klass->static_fields->entryMode
    vars.Instance.Watch<int>("EntryMode", "MainMenuManager", "0x0", "0xB8", "0x8"); // entryMode
    vars.Instance.Watch<int>("ConnState", "Mirror:Mirror:NetworkClient", "connectState");
    vars.Instance.Watch<bool>("ServerActive", "Mirror:Mirror:NetworkServer", "<active>k__BackingField");
    vars.Instance.Watch<bool>("EndFlag", "MainMenuManager", "congratsMenu", "continueButton", "0x10", "0x20", "0x46");
    vars.Instance.Watch<IntPtr>("allPlayers", "PlayerCharacter", "allPlayerCharacters", "_items");
    vars.Instance.Watch<int>("PlayerCount", "PlayerCharacter", "allPlayerCharacters", "_size");
    vars.Instance.Watch<IntPtr>("PropHomes", "PropHome", "allPropHomes", "_items");
    vars.Instance.Watch<int>("PropHomeCount", "PropHome", "allPropHomes", "_size");

    vars.PrevChecked = new bool[13];
    vars.SelectedCount = 1;
    for (int i = 1; i <= 12; i++)
    {
        bool isChecked = (bool)settings["p" + i];
        vars.PrevChecked[i] = isChecked;
        if (isChecked) vars.SelectedCount = i;
    }

    const int STRIDE = 0x30;
    vars.TransformStride = STRIDE;

    // ===== csObj -> nativePtr -> gameObject -> components -> transformNative =====
    vars.GetTransformNative = (Func<IntPtr, IntPtr>)(csObj =>
    {
        if (csObj == IntPtr.Zero) return IntPtr.Zero;
        IntPtr nativePtr = game.ReadPointer(csObj + 0x10);
        if (nativePtr == IntPtr.Zero) return IntPtr.Zero;
        IntPtr gameObject = game.ReadPointer(nativePtr + 0x20);
        if (gameObject == IntPtr.Zero) return IntPtr.Zero;
        IntPtr components = game.ReadPointer(gameObject + 0x20);
        if (components == IntPtr.Zero) return IntPtr.Zero;
        return game.ReadPointer(components + 0x8);
    });

    // ===== quaternion helpers =====
    vars.QRot = (Func<float[], float[], float[]>)((q, v) =>
    {
        float qx = q[0], qy = q[1], qz = q[2], qw = q[3];
        float tx = 2 * (qy * v[2] - qz * v[1]);
        float ty = 2 * (qz * v[0] - qx * v[2]);
        float tz = 2 * (qx * v[1] - qy * v[0]);
        return new float[] {
            v[0] + qw*tx + (qy*tz - qz*ty),
            v[1] + qw*ty + (qz*tx - qx*tz),
            v[2] + qw*tz + (qx*ty - qy*tx)
        };
    });

    vars.QMul = (Func<float[], float[], float[]>)((a, b) =>
    {
        return new float[] {
            a[3]*b[0] + a[0]*b[3] + a[1]*b[2] - a[2]*b[1],
            a[3]*b[1] - a[0]*b[2] + a[1]*b[3] + a[2]*b[0],
            a[3]*b[2] + a[0]*b[1] - a[1]*b[0] + a[2]*b[3],
            a[3]*b[3] - a[0]*b[0] - a[1]*b[1] - a[2]*b[2]
        };
    });

    vars.ChainToRoot = (Func<IntPtr, int, List<int>>)((parents, index) =>
    {
        var up = new List<int>();
        var seen = new HashSet<int>();
        int i = index;
        while (!seen.Contains(i))
        {
            seen.Add(i);
            up.Add(i);
            if (i == 0) break;
            int p = game.ReadValue<int>(parents + 4 * i);
            if (p < 0 || p > 100000) break;
            i = p;
        }
        up.Reverse();
        return up;
    });

    // ===== 走 skeleton chain 算世界座標 =====
    vars.TryGetWorldPos = (Func<IntPtr, float[]>)(transformNative =>
    {
        if (transformNative == IntPtr.Zero) return null;

        IntPtr state = game.ReadPointer(transformNative + 0x28);
        if (state == IntPtr.Zero) return null;
        IntPtr nodeData = game.ReadPointer(state + 0x18);
        IntPtr parents  = game.ReadPointer(state + 0x20);
        int index = game.ReadValue<int>(transformNative + 0x30);
        if (nodeData == IntPtr.Zero || parents == IntPtr.Zero) return null;

        float[] wp = new float[] { 0, 0, 0 };
        float[] wq = new float[] { 0, 0, 0, 1 };
        float[] ws = new float[] { 1, 1, 1 };

        List<int> chain = (List<int>)vars.ChainToRoot(parents, index);

        foreach (int n in chain)
        {
            IntPtr a = nodeData + n * (int)vars.TransformStride;

            float[] lp = new float[] {
                game.ReadValue<float>(a + 0x00),
                game.ReadValue<float>(a + 0x04),
                game.ReadValue<float>(a + 0x08)
            };
            float[] lq = new float[] {
                game.ReadValue<float>(a + 0x10),
                game.ReadValue<float>(a + 0x14),
                game.ReadValue<float>(a + 0x18),
                game.ReadValue<float>(a + 0x1C)
            };
            float[] ls = new float[] {
                game.ReadValue<float>(a + 0x20),
                game.ReadValue<float>(a + 0x24),
                game.ReadValue<float>(a + 0x28)
            };

            float[] sp = new float[] { lp[0]*ws[0], lp[1]*ws[1], lp[2]*ws[2] };
            float[] rp = (float[])vars.QRot(wq, sp);
            wp = new float[] { wp[0]+rp[0], wp[1]+rp[1], wp[2]+rp[2] };
            wq = (float[])vars.QMul(wq, lq);
            ws = new float[] { ws[0]*ls[0], ws[1]*ls[1], ws[2]*ls[2] };
        }

        return wp;
    });

    vars.FindNearestPlayerIsLocal = (Func<float[], bool?>)(peckPos =>
    {
        if (peckPos == null || current.allPlayers == IntPtr.Zero) return null;

        float bestDistSq = float.MaxValue;
        bool bestIsLocal = false;
        bool found = false;

        for (int i = 0; i < current.PlayerCount; i++)
        {
            IntPtr entryAddr = game.ReadPointer((IntPtr)current.allPlayers + 0x20 + i * 0x8);
            IntPtr playerMover = game.ReadPointer(entryAddr + 0x90);

            float px = game.ReadValue<float>(playerMover + 0x40);
            float py = game.ReadValue<float>(playerMover + 0x44);
            float pz = game.ReadValue<float>(playerMover + 0x48);

            float dx = px - peckPos[0];
            float dy = py - peckPos[1];
            float dz = pz - peckPos[2];
            float distSq = dx*dx + dy*dy + dz*dz;

            if (distSq < bestDistSq)
            {
                bestDistSq = distSq;
                IntPtr netIdentity = game.ReadPointer(entryAddr + 0x40);
                bestIsLocal = game.ReadValue<bool>(netIdentity + 0x22);
                found = true;
            }
        }

        if (!found) return null;

        print(string.Format("Nearest player distSq: {0:F3}", bestDistSq));
        return bestIsLocal;
    });

    vars.GetObjectName = (Func<IntPtr, string>)(managedObj =>
    {
        if (managedObj == IntPtr.Zero) return string.Empty;
        
        IntPtr nativePtr = game.ReadPointer(managedObj + 0x10);
        if (nativePtr == IntPtr.Zero) return string.Empty;
        
        IntPtr gameObject = game.ReadPointer(nativePtr + 0x20);
        if (gameObject == IntPtr.Zero) return string.Empty;
        
        IntPtr namePtr = game.ReadPointer(gameObject + 0x50);
        if (namePtr == IntPtr.Zero) return string.Empty;

        return game.ReadString(namePtr, 64); 
    });

    vars.stateDict = new Dictionary<IntPtr, sbyte>();
    vars.initialized = new HashSet<IntPtr>();

    Func<string, string, int> GetOff = (c, f) => {
        int[] res = vars.Instance.GetPathInt(c, f);
        return (res != null && res.Length > 0) ? res[0] : 0;
    };

    vars.OffCurrentPeckContext = GetOff("TrackedPeckState", "currentPeckContext"); 
    vars.OffOnPin = GetOff("PropHome", "onPin");             // 0x40
    vars.OffpinGroup = GetOff("PropHome", "pinGroup");
    vars.OffpinnedProp = GetOff("PropHome", "pinnedProp");
    vars.OffsaveableHomeName = GetOff("PropHome", "saveableHomeName");
    vars.OffTrackedState = GetOff("PeckSwitch", "trackedStateSystem"); // 0x20
    vars.OffCompressed = vars.OffCurrentPeckContext + GetOff("PeckContext", "compressedState") - 0x10; // 0x48
    vars.OffPlayerId = vars.OffCurrentPeckContext + GetOff("PeckContext", "playerIdentity") - 0x10; // 0x38
    vars.OffIsLocal = GetOff("Mirror:Mirror:NetworkIdentity", "<isLocalPlayer>k__BackingField");

    // ===== Ready-check offsets (all players not pending) =====
    vars.OffPlayerNetworking = GetOff("PlayerCharacter", "playerNetworking");
    vars.OffIsPending = GetOff("PlayerNetworking", "isPending");
    
    vars.PuzzleShouldSplit = false;
    vars.FilledHomes = null;

    vars.IsAllReady = false;
    vars.ReadyTriggered = false;
    vars.IsPaused = false;
    vars.NotReadySincePause = false;
    vars.Ending = false;
}

update
{
    vars.Uhara.Update();
    
    for (int i = 0; i < current.PropHomeCount; i++)
    {
        IntPtr entryAddr = current.PropHomes + 0x20 + i * 0x8;
        IntPtr propHomePtr = game.ReadPointer(entryAddr);
        if (propHomePtr == IntPtr.Zero) continue;

        if (vars.GetObjectName(propHomePtr) == "GourdViceHome")
        {
            IntPtr onPin = game.ReadPointer((IntPtr)(propHomePtr + vars.OffOnPin));
            IntPtr trackedStateSystem = game.ReadPointer((IntPtr)(onPin + vars.OffTrackedState));
            if (trackedStateSystem == IntPtr.Zero) continue;

            sbyte currentState = game.ReadValue<sbyte>((IntPtr)(trackedStateSystem + vars.OffCompressed));
            
            if (!vars.stateDict.ContainsKey(propHomePtr))
            {
                vars.stateDict[propHomePtr] = currentState;
                vars.initialized.Add(propHomePtr);
                continue;
            }

            if (vars.stateDict[propHomePtr] == 1 && currentState == 0)
            {
                IntPtr playerIdentity = game.ReadPointer((IntPtr)(trackedStateSystem + vars.OffPlayerId));
                bool isLocal = false;

                if (playerIdentity != IntPtr.Zero)
                {
                    isLocal = game.ReadValue<bool>((IntPtr)(playerIdentity + vars.OffIsLocal));
                }
                else
                {
                    IntPtr transformNative = vars.GetTransformNative(propHomePtr);
                    float[] pos = vars.TryGetWorldPos(transformNative);
                    bool? localResult = vars.FindNearestPlayerIsLocal(pos);
                    isLocal = localResult.HasValue && localResult.Value;
                }

                if (isLocal)
                {
                    IntPtr transformNative = vars.GetTransformNative(propHomePtr);
                    float[] pos = vars.TryGetWorldPos(transformNative);
                    string posStr = (pos != null) ? string.Format("{0:F2}, {1:F2}, {2:F2}", pos[0], pos[1], pos[2]) : "Unknown";
                    
                    print(string.Format("Local interaction completed at: {0} | State: 1 -> 0", posStr));

                    vars.PuzzleShouldSplit = true; 
                }
            }

            vars.stateDict[propHomePtr] = currentState;
        }
    }

    bool[] prevChecked = (bool[])vars.PrevChecked;
    for (int i = 1; i <= 12; i++)
    {
        bool isChecked = (bool)settings["p" + i];
        if (isChecked && !prevChecked[i])
            vars.SelectedCount = i;

        prevChecked[i] = isChecked;
    }

    if (current.PlayerCount != old.PlayerCount)
        print("PlayerCount: " + current.PlayerCount.ToString());

    // ===== Ready check: lobby reached chosen count AND all players isPending == false =====
    bool currentReady = false;
    if ((IntPtr)current.allPlayers != IntPtr.Zero && current.PlayerCount == (int)vars.SelectedCount)
    {
        bool allPlayersAreReady = true;
        for (int i = 0; i < current.PlayerCount; i++)
        {
            IntPtr entryAddr = game.ReadPointer((IntPtr)current.allPlayers + 0x20 + i * 0x8);
            if (entryAddr == IntPtr.Zero) { allPlayersAreReady = false; break; }

            IntPtr playerNetworking = game.ReadPointer((IntPtr)(entryAddr + vars.OffPlayerNetworking));
            if (playerNetworking == IntPtr.Zero) { allPlayersAreReady = false; break; }

            bool isPending = game.ReadValue<bool>((IntPtr)(playerNetworking + vars.OffIsPending));
            if (isPending)
            {
                allPlayersAreReady = false;
                break;
            }
        }
        currentReady = allPlayersAreReady;
    }

    if (currentReady && !vars.ReadyTriggered)
    {
        print(string.Format(">>> PlayerCount == {0} And All Player isPending is False <<<", vars.SelectedCount));
        vars.ReadyTriggered = true;
        vars.IsAllReady = true;
    }
    else if (!currentReady)
    {
        vars.ReadyTriggered = false;
        vars.IsAllReady = false;
    }

    if (current.EntryMode == 2 && old.EntryMode != 2) vars.Ending = true;

        // ===== Pause events =====
    bool selfLeave   = old.ConnState == 2 && current.ConnState == 3;   // StopClient
    bool passiveDisc = old.ConnState == 2 && current.ConnState == 4;   // client side: host closed the room
    bool hostClosed  = old.ServerActive && !current.ServerActive;      // host side: server stopped
    bool hostStop    = selfLeave && current.ServerActive;              // host side: StopClient while server still active

    if (current.ConnState != old.ConnState)
        print("ConnState: " + old.ConnState + " -> " + current.ConnState);

    if (!vars.Ending && !vars.IsPaused && (passiveDisc || hostClosed || hostStop))
    {
        print(string.Format("Lobby closed, pausing timer (passiveDisc={0}, hostClosed={1}, hostStop={2})",
            passiveDisc, hostClosed, hostStop));
        vars.IsPaused = true;
        vars.NotReadySincePause = false;
    }
    else if (selfLeave && !vars.IsPaused)
    {
        print("Client left by itself, timer keeps running");
    }
    else if (vars.IsPaused)
    {
        // Must see "not ready" first, then "ready again".
        // Right after the disconnect the old player objects still exist for a frame,
        // so currentReady can still be true and would resume immediately.
        if (!currentReady) vars.NotReadySincePause = true;

        if (vars.Ending || (vars.NotReadySincePause && currentReady))
        {
            print("Resuming timer");
            vars.IsPaused = false;
        }
    }

    if (current.PropHomes == IntPtr.Zero || current.PropHomeCount <= 0)
        return;

    int offPinGroup = (int)vars.OffpinGroup;
    int offPinnedProp = (int)vars.OffpinnedProp;
    int offHomeName = (int)vars.OffsaveableHomeName;

    var filledHomes = new HashSet<int>();

    for (int i = 0; i < current.PropHomeCount; i++)
    {
        IntPtr entryAddr = current.PropHomes + 0x20 + i * 0x8;
        IntPtr propHomePtr = game.ReadPointer(entryAddr);
        if (propHomePtr == IntPtr.Zero) continue;

        int pinGroup = game.ReadValue<int>(propHomePtr + offPinGroup);
        if (pinGroup != vars.RewardGourd) continue;

        IntPtr pinnedProp = game.ReadPointer(propHomePtr + offPinnedProp);
        if (pinnedProp == IntPtr.Zero) continue;

        int homeName = game.ReadValue<int>(propHomePtr + offHomeName);
        filledHomes.Add(homeName);
    }

    vars.FilledHomes = filledHomes;
}

start
{
    // wait until the lobby has exactly the chosen number of connected players
    // AND all of them have isPending == false
    if (vars.IsAllReady)
    {
        vars.IsAllReady = false;
        return true;
    }
    return false;
}

split
{
    // step 1: the ending popup (continue button) just appeared -> start waiting
    if (!old.EndFlag && current.EndFlag)
    {
        print("EndFlag Split");
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

    if (settings["SplitPuzzle"] && vars.PuzzleShouldSplit)
    {
        vars.PuzzleShouldSplit = false;
        print("Puzzle Finish Split triggered");
        return true;
    }

    return false;
}

isLoading
{
    return vars.IsPaused;
}

onReset
{
    vars.stateDict.Clear();
    vars.initialized.Clear();
    vars.CompletedGroups.Clear();
    vars.PuzzleShouldSplit = false;
    vars.IsAllReady = false;
    vars.IsPaused = false;
    vars.Ending = false;
    vars.NotReadySincePause = false;
}
