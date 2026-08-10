state("Big Walk"){}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
}

init
{
    vars.JitSave = vars.Uhara.CreateTool("Unity", "IL2CPP", "JitSave");

    vars.Resolver.Watch<ulong>("startFlag", vars.JitSave.AddFlag("GameStartBlind", "Awake"));
    
    vars.JitSave.ProcessQueue();
}

update
{
    vars.Uhara.Update();
}

start
{
    if(current.startFlag != old.startFlag)
    {
        return true;
    }
}