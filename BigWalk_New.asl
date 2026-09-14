state("Big Walk") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");

    // --- Player count selector (acts like a radio group: only one can be checked) ---
    settings.Add("playercount", true, "Target Player Count (start when lobby reaches this many)");
    for (int i = 1; i <= 12; i++)
    {
        settings.Add("p" + i, i == 1, i + (i == 1 ? " Player" : " Players"), "playercount");
    }
}

init
{
    vars.Instance = vars.Uhara.CreateTool("Unity", "IL2CPP", "Instance");

    vars.Instance.Watch<int>("PlayerCount", "PlayerCharacter", "allPlayerCharacters", "_size");
    vars.Instance.Watch<bool>("EndFlag", "MainMenuManager", "congratsMenu", "continueButton", "0x10", "0x20", "0x46");

    // snapshot of the 12 checkboxes so we can detect which one was *just* checked
    // (settings is read-only outside of "startup", so we can't uncheck the others -
    //  we just track the most recently checked one and use that as the selection)
    vars.PrevChecked = new bool[13];
    vars.SelectedCount = 1;
    for (int i = 1; i <= 12; i++)
    {
        bool isChecked = (bool)settings["p" + i];
        vars.PrevChecked[i] = isChecked;
        if (isChecked) vars.SelectedCount = i;
    }
}

update
{
    vars.Uhara.Update();

    // --- detect which player-count checkbox was most recently checked ---
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
}

start
{
    // wait until the lobby has exactly the chosen number of connected players
    return current.PlayerCount == (int)vars.SelectedCount;
}

split
{
    // step 1: the ending popup (continue button) just appeared -> start waiting
    if (!old.EndFlag && current.EndFlag)
    {
        print("Split");
        return true;
    }
}
