state("XF ExtremeFormula"){}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
}

init
{
    vars.Instance = vars.Uhara.CreateTool("Unity", "DotNet", "Instance");

    // m_CachedPtr -> activeSelf
    // 0x10        -> 0x46
    vars.Instance.Watch<Byte>("PauseUIActive", "CarCamera", "MainCamera", "Pause", "PauseUI", "0x10", "0x46");
}

update
{
    vars.Uhara.Update();

    if(current.PauseUIActive != old.PauseUIActive)
    {
        print("PauseUIActive: " + current.PauseUIActive.ToString());
    }
}