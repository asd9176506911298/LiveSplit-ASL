state ("Raft")
{
}

startup 
{
	Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
    vars.Uhara.AlertLoadless();

	settings.Add("runType", true, "Run Type");

    settings.Add("fullGame", true, "Full Game (Start on load)", "runType");
    settings.SetToolTip("fullGame", "Starts when player loads into world");

    settings.Add("il", false, "Individual Level (Start on movement)", "runType");
    settings.SetToolTip("il", "Starts on first detected movement (no filtering)");
}

init
{
	vars.JitSave = vars.Uhara.CreateTool("Unity", "DotNet", "JitSave");
	vars.Instance = vars.Uhara.CreateTool("Unity", "DotNet", "Instance");
    vars.Utils = vars.Uhara.CreateTool("Unity", "Utils");

	vars.Instance.Watch<bool>("PlayerStart", "PersonController", "completelyStarted");
	vars.Instance.Watch<bool>("PlayerMoving", "PersonController", "moving");

	IntPtr pPickNoteBook = vars.JitSave.AddFlag("Pickup", "PickupNoteBookNote");
	IntPtr pRelayFinish = vars.JitSave.AddFlag("NoteBook", "UnlockSpecificNoteNetworked");
	IntPtr pFadeToAlpha = vars.JitSave.AddFlag("FadePanel", "FadeToAlpha");

	vars.JitSave.ProcessQueue();

	vars.Resolver.Watch<int>("PickNoteBook",pPickNoteBook);
	vars.Resolver.Watch<int>("RelayFinish",pRelayFinish); // use for balboa finish will trigger triple times
	vars.Resolver.Watch<int>("FadeToAlpha",pFadeToAlpha);

	vars.lastSplitRelayCount = 0;
	vars.playerStartTime = 0.0;
	vars.fadeOffset = 0;
}

start
{
     // Prevent invalid dual-selection
    if (settings["fullGame"] == settings["il"])
        return false;

    // FULL GAME START
    if (settings["fullGame"])
    {
        return current.PlayerStart != old.PlayerStart;
    }

    // IL START
    if (settings["il"])
    {
        return !old.PlayerMoving && current.PlayerMoving;
    }

    return false;
}

update
{
    vars.Uhara.Update();

	if(current.FadeToAlpha != old.FadeToAlpha)
	{
		print("FadeToAlpha: " + old.FadeToAlpha + " - > " + current.FadeToAlpha);
	}

	if(current.PlayerStart != old.PlayerStart)
	{
		print("PlayerStart: " + old.PlayerStart + " - > " + current.PlayerStart);
	}

	if(!old.PlayerStart && current.PlayerStart)
	{
		vars.playerStartTime = (float)timer.CurrentTime.RealTime.Value.TotalSeconds;
		vars.fadeOffset = current.FadeToAlpha; // 記錄基準值，而不是竄改 current
	}

	if(current.RelayFinish != old.RelayFinish)
	{
		print("RelayFinish: " + old.RelayFinish + " - > " + current.RelayFinish);
	}

	if(current.PickNoteBook != old.PickNoteBook)
	{
		print("PickNoteBook: " + old.PickNoteBook + " - > " + current.PickNoteBook);
	}

	// if(current.PlayerMoving != old.PlayerMoving)
	// {
	// 	print("PlayerMoving: " + old.PlayerMoving + " - > " + current.PlayerMoving);
	// }
}

onReset
{
    vars.lastSplitRelayCount = 0;
    vars.fadeOffset = 0;
}

split
{
    float now = (float)timer.CurrentTime.RealTime.Value.TotalSeconds;
    float elapsed = now - (float)vars.playerStartTime;

    if (elapsed <= 20.0f)
    {
        vars.lastSplitRelayCount = current.RelayFinish;
        return false;
    }

    if (current.RelayFinish >= vars.lastSplitRelayCount + 3)
    {
        vars.lastSplitRelayCount = current.RelayFinish;
        return true;
    }

	if (current.PickNoteBook != old.PickNoteBook)
	{
		return true;
	}
}

isLoading
{
    return (current.FadeToAlpha - vars.fadeOffset) % 2 != 0;
}
