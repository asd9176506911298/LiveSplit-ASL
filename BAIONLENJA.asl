state("BAIONLENJA-Win64-Shipping") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
    vars.Uhara.AlertLoadless();
}

init
{
    vars.Utils = vars.Uhara.CreateTool("UnrealEngine", "Utils");
    vars.Events = vars.Uhara.CreateTool("UnrealEngine", "Events");

    vars.Events.FunctionFlag("enterDoor", "LevelEntry_C", "LevelEntry_C*", "ReceiveActorBeginOverlap");

    IntPtr playerPtr = vars.Events.FunctionParentPtr("BP_FirstPersonCharacter_C", "BP_FirstPersonCharacter_C*", "");
    IntPtr levelCompletePtr = vars.Events.FunctionParentPtr("LevelSetupActor_C", "LevelSetupActor_C*", "");

    /*
        ABP_FirstPersonCharacter_C : ACharacter -> UCharacterMovementComponent -> Velocity
                                      playerPtr -> 0x330 -> 0xB0
    */
    vars.Resolver.Watch<double>("velocityX", playerPtr, 0x330, 0xB8);
    vars.Resolver.Watch<double>("velocityY", playerPtr, 0x330, 0xC0);
    vars.Resolver.Watch<bool>("levelComplete", levelCompletePtr, 0x339);
    vars.Resolver.Watch<bool>("Loading", vars.Utils.GSync);
    vars.Resolver.Watch<uint>("GWorldName", vars.Utils.GWorld, 0x18);
    current.World = "";

    vars.finishTutorial = false;
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
        vars.finishTutorial = false;
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

    // if(current.enterDoor != old.enterDoor)
    // {
    //     vars.Uhara.Log("EnterDoor: " + old.enterDoor + " -> " + current.enterDoor);
    // }

    // if(current.levelComplete != old.levelComplete)
    // {
    //     vars.Uhara.Log("LevelComplete: " + old.levelComplete + " -> " + current.levelComplete);
    // }

    // if(current.Loading != old.Loading)
    // {
    //     vars.Uhara.Log("Loading: " + old.Loading + " -> " + current.Loading);
    // }

    var world = vars.Utils.FNameToString(current.GWorldName);
    if (!string.IsNullOrEmpty(world) && world != "None") current.World = world;
    if (old.World != current.World) vars.Uhara.Log("World: " + current.World);
}

split
{
    if(old.World == "INTRO_TUTORIAL" && current.World == "CARGO_PLATFORM")
    {
        vars.Uhara.Log("Split");
        return true;
    }

    if (old.World == "CARGO_PLATFORM" && current.World == "HUB1" && !vars.finishTutorial)
    {
        vars.finishTutorial = true;
        vars.Uhara.Log("Split Finish Tutorial");
        return true;
    }

    if(current.enterDoor != old.enterDoor && current.levelComplete)
    {
        vars.Uhara.Log("Split Finish Level");
        return true;
    }
}

isLoading
{
    return current.Loading;
}

onReset
{
    vars.finishTutorial = false;
}
