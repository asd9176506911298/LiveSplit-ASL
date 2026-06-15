state("BAIONLENJA-Win64-Shipping") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
}

init
{
    vars.Utils = vars.Uhara.CreateTool("UnrealEngine", "Utils");
    vars.Events = vars.Uhara.CreateTool("UnrealEngine", "Events");

    vars.Resolver.Watch<uint>("GWorldName", vars.Utils.GWorld, 0x18);
    current.World = "";
}

start
{
    if(old.World == "MainMenuMap" && current.World != "MainMenuMap")
    {
        vars.Uhara.Log("Start");
        return true;
    }
}

reset
{
    if(old.World != "MainMenuMap" && current.World == "MainMenuMap")
    {
        vars.Uhara.Log("Reset");
        return true;
    }
}

update
{
    vars.Uhara.Update();

    var world = vars.Utils.FNameToString(current.GWorldName);
    if (!string.IsNullOrEmpty(world) && world != "None") current.World = world;
    if (old.World != current.World) vars.Uhara.Log("World: " + current.World);
}