state("knock")
{
    
}

startup 
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");

    vars.Helper.GameName = "Knock-Knock";
    vars.Helper.AlertLoadless();
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        var world = mono["World"];
        
        // States
        IntPtr statePtr = world.Static + 0x1C;

        vars.Helper["state"] = vars.Helper.Make<int>(statePtr);

        return true;
    });
}

start
{
    return (old.state == 5 || old.state == 9) && current.state == 6;
}

update
{
    if (current.state != old.state)
    {
        print("State changed from " + old.state + " to " + current.state);
    }
}

split
{
    if (current.state == 6 || current.state == 2) return false;
    
    if (current.state == 4 || old.state == 4) return false;
    
    if (current.state == 9) return false;
    
    if (old.state == 14) return false;
    
    return current.state != old.state;
}

isLoading
{
    return current.state == 9 || current.state == 14;
}

/*
public enum States
	{
		AUTH_FORM,
		START,
		MOVIE,
		DISCLAIMER,
		MAIN_MENU, = 4
		NEW_GAME, = 5
		HOUSE, = 6
		FOREST,
		CORRIDOR,
		SCREEN_DARKEN, = 9
		TIMELINE,
		DREAM,
		DIARY,
		DAWN,
		CHANGE_LEVEL = 14
	}
*/