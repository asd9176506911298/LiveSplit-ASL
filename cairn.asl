state("Cairn") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
}

init
{
    vars.Instance = vars.Uhara.CreateTool("Unity", "IL2CPP", "Instance");

    vars.Instance.Watch<ulong>("someStuff", "TheGameBakers.Cairn.Global::PawnManager","PawnControllerSwitcher","PathRecorder","Path","0x70");
}

update
{
    vars.Uhara.Update();
    
    if(current.someStuff != old.someStuff)
    {
        print(current.someStuff.ToString());
    }
}