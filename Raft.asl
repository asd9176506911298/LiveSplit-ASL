state ("raft")
{
}

startup 
{
	Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
    vars.Uhara.AlertLoadless();
}

init
{
	vars.JitSave = vars.Uhara.CreateTool("Unity", "DotNet", "JitSave");

	IntPtr pPlayerStart = vars.JitSave.AddFlag("PersonController", "Start");

	vars.JitSave.ProcessQueue();

	vars.Resolver.Watch<int>("PlayerStart",pPlayerStart);
}

start
{
    return current.PlayerStart != old.PlayerStart;
}


update
{
    vars.Uhara.Update();
}
