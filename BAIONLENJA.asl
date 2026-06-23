state("BAIONLENJA-Win64-Shipping") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
}

init
{
    vars.Utils = vars.Uhara.CreateTool("UnrealEngine", "Utils");
    vars.Events = vars.Uhara.CreateTool("UnrealEngine", "Events");

    vars.Events.FunctionFlag("finish", "LevelChangeDoor_C", "LevelchangeTrigger*", "ReceiveBeginPlay");

    IntPtr playerPtr = vars.Events.FunctionParentPtr("BP_FirstPersonCharacter_C", "BP_FirstPersonCharacter_C*", "");

    /*
        ABP_FirstPersonCharacter_C : ACharacter -> UCharacterMovementComponent -> Velocity
                                      playerPtr -> 0x330 -> 0xB0
    */
    vars.Resolver.Watch<double>("velocityX", playerPtr, 0x330, 0xB8);
    vars.Resolver.Watch<double>("velocityY", playerPtr, 0x330, 0xC0);
    vars.Resolver.Watch<uint>("GWorldName", vars.Utils.GWorld, 0x18);
    current.World = "";
}

start
{
    double vx = current.velocityX;
    double vy = current.velocityY;
    double oldVx = old.velocityX;
    double oldVy = old.velocityY;
    double speed = Math.Sqrt(vx * vx + vy * vy);
    double oldSpeed = Math.Sqrt(oldVx * oldVx + oldVy * oldVy);

    if (speed > 0 && oldSpeed <= 0)
    {
        // vars.Uhara.Log("Start, speed: " + speed);
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

    // if(current.currentSpeed != old.currentSpeed)
    // {
    //     vars.Uhara.Log("Speed: " + current.currentSpeed);
    // }

    // if(current.finish != old.finish)
    // {
    //     vars.Uhara.Log(old.finish + " -> " + current.finish);
    // }

    var world = vars.Utils.FNameToString(current.GWorldName);
    if (!string.IsNullOrEmpty(world) && world != "None") current.World = world;
    if (old.World != current.World) vars.Uhara.Log("World: " + current.World);
}

split
{
    if (old.World != current.World 
        && old.World != "MainMenuMap"
        && old.World != "HUB1"
        && current.World != "HUB1")
    {
        vars.Uhara.Log("Split");
        return true;
    }

    if(current.finish != old.finish)
    {
        vars.Uhara.Log("Split Finish Level");
        return true;
    }
}
