state("ActionHenk") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.AlertLoadless();

    vars.GUIScreen_MainMenu    =  1;
    vars.GUIScreen_Loading     =  5;
    vars.GUIScreen_PreGame     =  8;
    vars.GUIScreen_InGame      =  9;
    vars.GUIScreen_PostGame    = 10;
    vars.GUIScreen_Cutscene    = 11;
    vars.GUIScreen_BatchSelect = 37;

    vars.anyMedalsUnlock = new int[] {7, 16, 27, 38, 43, 57, 72, 85};

    vars.classicBatchEnd = new int[] {14, 7, 50, 23, 47, 66, 26, 76, 31};

    vars.levelsCode = new int[][] {
        new int[] {13, 34, 03, 02, 14, 17, 54},
        new int[] {04, 16, 32, 27, 07, 52, 55},
        new int[] {18, 20, 30, 35, 50, 51, 42},
        new int[] {48, 15, 08, 24, 23, 53, 56},
        new int[] {43, 44, 45, 46, 47, 39, 57},
        new int[] {64, 36, 28, 65, 66, 68, 67},
        new int[] {69, 70, 29, 71, 26, 73, 72},
        new int[] {74, 10, 25, 75, 76, 78, 77},
        new int[] {79, 21, 19, 80, 31, 82, 81},
        new int[] {83, 84, 85, 86, 87, 89, 88},
        new int[] {98, 99,100,101,102,104,103}
    };

    settings.Add("category_any", true, "Any% Splitting");
    for (int i = 0; i < vars.anyMedalsUnlock.Length; i++)
        settings.Add("any_"+vars.anyMedalsUnlock[i], true, "Split when unlocking "+vars.anyMedalsUnlock[i]+" medals", "category_any");
    settings.Add("any_the_wall",    true, "Split when beating \"The Wall\"",              "category_any");
    settings.Add("any_pinball",     true, "Split when beating \"Pinball\"",               "category_any");
    settings.Add("any_kentinator",  true, "Split when beating \"Kentinator's Challenge\"","category_any");
    settings.Add("any_credits",     true, "Split when beating \"Credits\"",               "category_any");

    settings.Add("category_all_levels", false, "All Levels Splitting");
    settings.Add("all_levels_batch", true,  "Split at each batch cleared",   "category_all_levels");
    settings.Add("all_levels_track", false, "Split at every track cleared",  "category_all_levels");

    settings.Add("category_all_rainbows", false, "All Rainbows Splitting");
    settings.Add("all_rainbows_batch", true,  "Split at each batch rainbowed",                              "category_all_rainbows");
    settings.Add("all_rainbows_track", false, "Split at every track rainbowed (or completed for specials)", "category_all_rainbows");

    settings.Add("category_hundo", false, "100% Splitting");
    settings.Add("hundo_batch", true,  "Split at each batch fully completed",                       "category_hundo");
    settings.Add("hundo_track", false, "Split at every track rainbowed (or completed for specials)","category_hundo");

    settings.Add("category_45classics", false, "45 Classics Splitting");
    settings.Add("45classics_batch", true,  "Split at each last classic track of each batch","category_45classics");
    settings.Add("45classics_track", false, "Split at every track done",                     "category_45classics");

    settings.Add("reset_tracking", false, "Reset Tracking");
    settings.SetToolTip("reset_tracking", "Tracks the amount of times you reset during a run. Only works on retry, not checkpoint restart");

    settings.Add("medal_tracking", false, "Medal Tracking");
    settings.SetToolTip("medal_tracking", "Tracks the amount of medals (Sp->Special, B->Bronze, S->Silver, G->Gold, R->Rainbow)");

    // ---------- tracker helpers ----------
    vars.textSettingReset = null;
    vars.totalResets      = 0;
    vars.textSettingMedal = null;
    vars.medalsTypeCount  = new int[5];
    vars.medalsTypeName   = new string[5] {"Sp","B","S","G","R"};

    vars.SearchOrCreateComponent = (Func<string, dynamic>)((name) => {
        dynamic textSetting = null;
        foreach (dynamic component in timer.Layout.Components) {
            if (component.GetType().Name == "TextComponent" && component.Settings.Text1 == name) {
                textSetting = component.Settings;
                break;
            }
        }
        if (textSetting == null) textSetting = vars.CreateTextComponent(name);
        return textSetting;
    });

    vars.CreateTextComponent = (Func<string, dynamic>)((name) => {
        var asm = Assembly.LoadFrom("Components\\LiveSplit.Text.dll");
        dynamic tc = Activator.CreateInstance(asm.GetType("LiveSplit.UI.Components.TextComponent"), timer);
        timer.Layout.LayoutComponents.Add(new LiveSplit.UI.Components.LayoutComponent("LiveSplit.Text.dll", tc as LiveSplit.UI.Components.IComponent));
        tc.Settings.Text1 = name;
        return tc.Settings;
    });

    vars.UpdateResetTracker = (Action)(() => {
        if (vars.textSettingReset == null)
            vars.textSettingReset = vars.SearchOrCreateComponent("Resets This Run:");
        vars.textSettingReset.Text2 = vars.totalResets.ToString();
    });

    vars.UpdateMedalTracker = (Action)(() => {
        if (vars.textSettingMedal == null)
            vars.textSettingMedal = vars.SearchOrCreateComponent("Medals Count:");
        string t = "";
        for (int k = 0; k < vars.medalsTypeCount.Length; k++) {
            if (vars.medalsTypeCount[k] == 0) continue;
            t = string.Concat(t, vars.medalsTypeName[k], ": ", vars.medalsTypeCount[k], " ");
        }
        vars.textSettingMedal.Text2 = (t == "" ? "No medals yet" : t);
    });

    // ---------- run-scoped state ----------
    vars.InitVars = (Action)(() => {
        vars.levelsMedals        = Enumerable.Range(0,11).Select(i => new int[7]).ToArray();
        vars.curSumMedals        = vars.oldSumMedals        = 0;
        vars.curFullBatches      = vars.oldFullBatches      = 0;
        vars.curRainbowBatches   = vars.oldRainbowBatches   = 0;
        vars.curCompletedBatches = vars.oldCompletedBatches = 0;
    });
    vars.InitVars();

    vars.ResetVars = (EventHandler)((s, e) => {
        vars.InitVars();
        
        bool medalTracking = settings["medal_tracking"];
        bool resetTracking = settings["reset_tracking"];
        
        if (medalTracking) { vars.medalsTypeCount = new int[5]; vars.UpdateMedalTracker(); }
        if (resetTracking) { vars.totalResets = 0;              vars.UpdateResetTracker(); }
    });
    timer.OnStart += vars.ResetVars;

    vars.ResetDisplay = (LiveSplit.Model.Input.EventHandlerT<TimerPhase>)((s, e) => {
        if (vars.textSettingReset != null) vars.textSettingReset.Text2 = "0";
        if (vars.textSettingMedal != null) vars.textSettingMedal.Text2 = "No medals yet";
    });
    timer.OnReset += vars.ResetDisplay;
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        // GUIManager
        vars.Helper["activeScreen"] = mono.Make<int>("GUIManager", 1, "instance", "ActiveScreen");

        // LevelBatchManager
        vars.Helper["numMedals"]        = mono.Make<int>("LevelBatchManager", 1, "instance", "numMedals");
        vars.Helper["bestMedal"]        = mono.Make<int>("LevelBatchManager", 1, "instance", "currentLevel", "bestMedal");
        vars.Helper["levelCode"]        = mono.Make<int>("LevelBatchManager", 1, "instance", "currentLevel", "levelCode");
        vars.Helper["lookingAtBatchNum"]= mono.Make<int>("LevelBatchManager", 1, "instance", "lookingAtBatchNum");

        // CheckpointManager  (used for 45 Classics medal tracking)
        vars.Helper["finishTime"]       = mono.Make<float>("CheckpointManager", 1, "instance", "FinishTime");

        if (settings["medal_tracking"]) vars.UpdateMedalTracker();
        if (settings["reset_tracking"]) vars.UpdateResetTracker();

        return true;
    });
}

update
{
    if (current.activeScreen == null) return false;

    // ---------- helpers that mirror original IsCurrentLevelCompleted ----------
    vars.IsCurrentLevelCompleted = (Func<bool, bool>)((isRainbow) => {
        if (vars.oldSumMedals == vars.curSumMedals) return false;
        int levelId = Array.IndexOf(vars.levelsCode[current.lookingAtBatchNum], current.levelCode);
        if (levelId < 0) return false;
        return vars.levelsMedals[current.lookingAtBatchNum][levelId] > (isRainbow ? (levelId < 5 ? 3 : 0) : 0);
    });

    // ---------- update old local state ----------
    vars.oldSumMedals        = vars.curSumMedals;
    vars.oldFullBatches      = vars.curFullBatches;
    vars.oldRainbowBatches   = vars.curRainbowBatches;
    vars.oldCompletedBatches = vars.curCompletedBatches;

    // ---------- medal bookkeeping ----------
    if (old.levelCode != 0 && old.bestMedal < current.bestMedal) {
        int batchId   = current.lookingAtBatchNum;
        int levelId   = Array.IndexOf(vars.levelsCode[batchId], current.levelCode);
        if (levelId >= 0) {
            vars.levelsMedals[batchId][levelId] = current.bestMedal;
            vars.curSumMedals += current.bestMedal - old.bestMedal;
        }

        // Recalculate batch counts
        bool bFull, bRainbow, bCompleted;
        vars.curFullBatches = vars.curRainbowBatches = vars.curCompletedBatches = 0;
        for (int b = 0; b < vars.levelsMedals.Length; b++) {
            int[] bm = vars.levelsMedals[b];
            bFull = bRainbow = bCompleted = true;
            for (int l = 0; l < bm.Length; l++) {
                int nm = bm[l];
                if (nm == 0) {
                    if (l < 5 || (l == 5 && (b == 4 || b == 8))) { bFull = bRainbow = bCompleted = false; break; }
                    else { bFull = false; }
                } else if (nm < 4 && l < 5) {
                    bFull = bRainbow = false;
                }
            }
            if (bFull)      ++vars.curFullBatches;
            if (bRainbow)   ++vars.curRainbowBatches;
            if (bCompleted) ++vars.curCompletedBatches;
        }

        // Medal tracker (non-45classics)
        if (settings["medal_tracking"] && !settings["category_45classics"]) {
            if (levelId > 4) {
                ++vars.medalsTypeCount[0];
            } else {
                if (old.bestMedal != 0) --vars.medalsTypeCount[old.bestMedal];
                ++vars.medalsTypeCount[current.bestMedal];
            }
            vars.UpdateMedalTracker();
        }
    }

    // Medal tracker for 45 Classics
    if (settings["medal_tracking"] && settings["category_45classics"]) {
        if (old.finishTime != current.finishTime && current.finishTime != 0) {
            int batchId = current.lookingAtBatchNum;
            int levelId = Array.IndexOf(vars.levelsCode[batchId], current.levelCode);
            // 45 Classics medal tracking requires raw pointer reads — 
            // asl-help can't do offset arithmetic on a pointer value at runtime the same way,
            // so fall back to game.ReadValue like the original script
            if (levelId > 4) {
                // Challenge/Bonus: read bronze/bonus threshold
                float threshold = game.ReadValue<float>((IntPtr)(current.trackTimePtr + (levelId == 5 ? 0x40 : 0x50)));
                if (current.finishTime < threshold) { ++vars.medalsTypeCount[0]; vars.UpdateMedalTracker(); }
            } else {
                int medalNb = 0;
                for (int off = 0; off < 4; off++) {
                    if (current.finishTime < game.ReadValue<float>((IntPtr)(current.trackTimePtr + 0x40 + 0x4 * off)))
                        ++medalNb;
                    else break;
                }
                if (medalNb != 0) { ++vars.medalsTypeCount[medalNb]; vars.UpdateMedalTracker(); }
            }
        }
    }

    // Reset tracker
    if (settings["reset_tracking"] && old.activeScreen == vars.GUIScreen_InGame && current.activeScreen == vars.GUIScreen_PreGame) {
        ++vars.totalResets;
        vars.UpdateResetTracker();
    }
}

start
{
    return old.activeScreen == vars.GUIScreen_MainMenu
        && current.activeScreen == vars.GUIScreen_BatchSelect
        && (old.numMedals == 0 || settings["category_45classics"]);
}

split
{
    if (settings["category_any"]) {
        if (vars.oldSumMedals < vars.curSumMedals) {
            for (int id = 0; id < vars.anyMedalsUnlock.Length; id++) {
                if (vars.oldSumMedals < vars.anyMedalsUnlock[id] && vars.curSumMedals >= vars.anyMedalsUnlock[id])
                    return settings["any_"+vars.anyMedalsUnlock[id]];
            }
        }
        if (current.levelCode == 97 && old.activeScreen == vars.GUIScreen_InGame && current.activeScreen == vars.GUIScreen_PostGame)
            return settings["any_credits"];
        if (vars.IsCurrentLevelCompleted(false)) {
            if (current.levelCode == 19) return settings["any_the_wall"];
            if (current.levelCode == 31) return settings["any_pinball"];
            if (current.levelCode == 82) return settings["any_kentinator"];
        }
    } else if (settings["category_all_levels"]) {
        return (settings["all_levels_track"] && vars.IsCurrentLevelCompleted(false)) ||
               (settings["all_levels_batch"] && vars.oldCompletedBatches < vars.curCompletedBatches);
    } else if (settings["category_all_rainbows"]) {
        return (settings["all_rainbows_track"] && vars.IsCurrentLevelCompleted(true)) ||
               (settings["all_rainbows_batch"] && vars.oldRainbowBatches < vars.curRainbowBatches);
    } else if (settings["category_hundo"]) {
        return (settings["hundo_track"] && vars.IsCurrentLevelCompleted(true)) ||
               (settings["hundo_batch"] && vars.oldFullBatches < vars.curFullBatches);
    } else if (settings["category_45classics"] && old.activeScreen == vars.GUIScreen_InGame && current.activeScreen == vars.GUIScreen_PostGame) {
        return settings["45classics_track"] || (settings["45classics_batch"] && Array.IndexOf(vars.classicBatchEnd, current.levelCode) != -1);
    }
}

reset
{
    return old.activeScreen != current.activeScreen
        && current.activeScreen == vars.GUIScreen_MainMenu
        && (current.numMedals == 0 || settings["category_45classics"]);
}

isLoading
{
    if (current.activeScreen == null) return false;
    
    return current.activeScreen == vars.GUIScreen_Loading
        || current.activeScreen == vars.GUIScreen_PostGame
        || current.activeScreen == vars.GUIScreen_Cutscene;
}

shutdown
{
    timer.OnStart -= vars.ResetVars;
    timer.OnReset -= vars.ResetDisplay;
}
