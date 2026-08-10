state("Big Walk"){}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
}

init
{
    vars.Instance = vars.Uhara.CreateTool("Unity", "IL2CPP", "Instance");

    vars.Instance.Watch<bool>("isReadyForEffects", "PeckManager", "<isReadyForEffects>k__BackingField");
}

update
{
    vars.Uhara.Update();
}

start
{
    if (!old.isReadyForEffects && current.isReadyForEffects)
    {
        return true;
    }
}
