state("ktane"){}

startup 
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        vars.Helper["opacity"] = mono.Make<float>("LoadingOverlay", "Instance", "NonVRSmallLoadingLabel", "ChildOpacity", "opacity");
        vars.Helper["gameState"] = mono.Make<int>("SceneManager", "Instance", "currentState");
        vars.Helper["result"] = mono.Make<int>("Assets.Scripts.Records.RecordManager", "instance", "currentRecord", "Result");
        return true;
    });
}

update
{
    // if (old.opacity != current.opacity || old.gameState != current.gameState)
    //     print("opacity: " + current.opacity + " | gameState: " + current.gameState);

    // if (old.result != current.result)
    //     print("result: " + current.result);
}

start
{
    if (old.opacity > 0f && current.opacity <= 0.0001f && current.gameState == 0)
        return true;
}

/*
public enum State
{
    Gameplay, = 0
    Setup, = 1
    PostGame, = 2
    Transitioning, = 3
    Unlock, = 4
    ModManager, = 5
    Quitting = 6
}
*/

split
{
    if (old.result == 0 && current.result == 3)
        return true;
}

/*
public enum GameResultEnum
{
	Incomplete,  = 0
	ExplodedDueToStrikes, = 1
	ExplodedDueToTime, = 2
	Defused, = 3
	Quit = 4
}
*/