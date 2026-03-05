state("Super Battle Golf") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
}

init
{   
    vars.Instance = vars.Uhara.CreateTool("Unity", "DotNet", "Instance");
    vars.JitSave = vars.Uhara.CreateTool("Unity", "DotNet", "JitSave");
    vars.Utils = vars.Uhara.CreateTool("Unity", "Utils");

    vars.JitSave.SetOuter("GameAssembly.dll", "");

    // Register Method Hooks (Flags)
    IntPtr hBallDispenser = vars.JitSave.AddFlag("BallDispenser", "LocalPlayerInteract");
    IntPtr hGolfBall = vars.JitSave.AddFlag("GolfBall", "OnWasHitByGolfSwing");
    IntPtr hGolfHole = vars.JitSave.AddFlag("GolfHole", "ServerInformFellIn");

    // Process all registered hooks
    vars.JitSave.ProcessQueue();

    // Link hook addresses to LiveSplit variables for monitoring
    vars.Resolver.Watch<int>("ballDispensed", hBallDispenser);
    vars.Resolver.Watch<int>("ballHit", hGolfBall);
    vars.Resolver.Watch<int>("ballHoled", hGolfHole);
}

update
{
    // Update Uhara Framework internal state
    vars.Uhara.Update();

    // Retrieve the name of the currently active scene
    current.activeScene = vars.Utils.GetActiveSceneName() ?? current.activeScene;

    /*
    // --- Debug Logging ---
    if (current.ballDispensed != old.ballDispensed)
        vars.Uhara.Log("Event: Ball Dispensed (Count: " + current.ballDispensed + ")");

    if (current.ballHit != old.ballHit)
        vars.Uhara.Log("Event: Ball Hit (Count: " + current.ballHit + ")");

    if (current.ballHoled != old.ballHoled)
        vars.Uhara.Log("Event: Ball in Hole (Count: " + current.ballHoled + ")");
    */
}

start
{
    // Start logic for "Driving range" scene: Trigger on ball dispensed
    if (current.activeScene == "Driving range")
    {
        if (current.ballDispensed != old.ballDispensed)
        {
            // vars.Uhara.Log("Practice Started!");
            return true;
        }
    }
    // Start logic for other scenes: Trigger on first ball hit
    else
    {
        if (current.ballHit != old.ballHit)
        {
            // vars.Uhara.Log("Match Started!");
            return true;
        }
    }
}

split
{
    // Split when the ball enters the hole
    if (current.ballHoled != old.ballHoled)
    {
        // vars.Uhara.Log("Split: Goal reached!");
        return true;
    }
}

