state("BreakingArmorDemo") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
}

init
{   
    vars.JitSave = vars.Uhara.CreateTool("Unity", "DotNet", "JitSave");

    IntPtr hStartGame = vars.JitSave.AddFlag("PauseMenu", "WejdzNaScene1");
    IntPtr hCredit = vars.JitSave.AddFlag("Napisy", "Zaczynaj");

    vars.JitSave.ProcessQueue();

    vars.Resolver.Watch<int>("StartGame", hStartGame);
    vars.Resolver.Watch<int>("Credit", hCredit);
}

update
{
    vars.Uhara.Update();
}

start
{
    if (current.StartGame != old.StartGame)
    {
        print("Start");
        return true;
    }
}

split
{
    if (current.Credit != old.Credit)
    {
        print("Finish Split");
        return true;
    }
}