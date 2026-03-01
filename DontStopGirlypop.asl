state("INCOLATUS-Win64-Shipping"){}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
}

init
{
    vars.Events = vars.Uhara.CreateTool("UnrealEngine", "Events");

    vars.Events.FunctionFlag("start", "BP_CutSceneManager_C", "BP_CutSceneManager_C", "ReceiveBeginPlay");
    vars.Events.FunctionFlag("finish", "BP_EndScreen_C", "BP_EndScreen_C", "ReceiveBeginPlay");

    IntPtr Global = vars.Events.FunctionParentPtr("GI_Global_C", "GI_Global_C", "");
    vars.Resolver.Watch<double>("IGT", Global, 0x2D0); // time
    vars.Resolver.WatchString("Map", Global, 0x298, 0x0);  // CurrentMap

    vars.AccumulatedTime = 0.0;
    vars.LastIGT = 0.0;
    vars.Frozen = false;
    vars.MapChanged = false;
}

start
{
    if (vars.Resolver.CheckFlag("start"))
    {
        vars.AccumulatedTime = 0.0;
        vars.LastIGT = 0.0;
        vars.Frozen = false;
        return true;
    }
}

update
{
    vars.Uhara.Update();

    if (vars.Resolver.CheckFlag("finish"))
    {
        vars.Frozen = true;
        vars.MapChanged = false;
        print("Frozen at: " + vars.LastIGT.ToString());
    }

    if (current.Map != old.Map && old.Map != null && old.Map != "")
    {
        // Entering L_EndScreen: accumulate time and freeze (handles E2M5 "press any button" prompt)
        if (current.Map == "L_EndScreen")
        {
            vars.AccumulatedTime += vars.LastIGT;
            vars.LastIGT = 0.0;
            vars.Frozen = true;
            vars.MapChanged = true;
            print("Entering EndScreen, frozen. Accumulated: " + vars.AccumulatedTime.ToString());
        }
        // Leaving L_EndScreen: skip accumulation, time was already added on entry
        else if (old.Map == "L_EndScreen")
        {
            vars.LastIGT = 0.0;
            vars.MapChanged = true;
            print("Leaving EndScreen, skipping accumulation. Old Accumulated: " + vars.AccumulatedTime.ToString());
        }
        else
        {
            vars.AccumulatedTime += vars.LastIGT;
            vars.LastIGT = 0.0;
            vars.MapChanged = true;
            print("Map changed! Accumulated: " + vars.AccumulatedTime.ToString());
        }
        print("Old Map: " + old.Map + " New Map: " + current.Map);
    }

    if (vars.MapChanged && vars.Resolver.CheckFlag("start"))
    {
        vars.Frozen = false;
        vars.MapChanged = false;
        print("Unfrozen, new level started");
    }

    if (!vars.Frozen && current.IGT > 0.0)
    {
        vars.LastIGT = current.IGT;
    }
}

split
{
    // E2M5: split when entering L_EndScreen instead of relying on BP_EndScreen_C::ReceiveBeginPlay
    if (current.Map != old.Map && current.Map == "L_EndScreen")
    {
        // print("Split triggered via EndScreen map");
        return true;
    }

    if (vars.Resolver.CheckFlag("finish"))
    {
        // print("Split triggered");
        return true;
    }
}

gameTime
{
    return TimeSpan.FromSeconds(vars.AccumulatedTime + vars.LastIGT);
}

isLoading
{
    return true;
}
