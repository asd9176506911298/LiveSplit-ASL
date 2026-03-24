state("Styx3-Win64-Shipping") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
    vars.Uhara.EnableDebug();
}

init
{
    vars.Utils = vars.Uhara.CreateTool("UnrealEngine", "Utils");
	
    vars.Resolver.Watch<uint>("WorldFName", vars.Utils.GWorld, 0x18);
	
	current.WorldName = "";
}

update
{
    vars.Uhara.Update();

	string worldName = vars.Utils.FNameToString(current.WorldFName);
	if (!string.IsNullOrEmpty(worldName) && worldName != "None") current.WorldName = worldName;
    if (current.WorldName != old.WorldName) vars.Uhara.Log(old.WorldName + " -> " + current.WorldName);
}

split
{
	return current.WorldName != old.WorldName && current.WorldName != "MainMenu_P";
}

start
{
	return old.WorldName == "MainMenu_P" && current.WorldName != "MainMenu_P";
}