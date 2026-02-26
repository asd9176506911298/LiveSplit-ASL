state("ch5_pro-Win64-Shipping"){}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
}

init
{
    vars.Utils = vars.Uhara.CreateTool("UnrealEngine", "Utils");
    vars.Events = vars.Uhara.CreateTool("UnrealEngine", "Events");

    // 0xB0 UMobSaveGameObject* CurrentSaveObject
    vars.Resolver.Watch<IntPtr>("SaveObject", vars.Events.FunctionParentPtr("MobSaveSubsystem", "MobSaveSubsystem", ""), 0xB0);

    vars.lastLevelTag = "";
    vars.pendingSplit = false;
}

update
{
    vars.Uhara.Update();

    if (current.SaveObject == IntPtr.Zero) return;
    if (current.SaveObject == old.SaveObject) return;

    /*
    0x28 FGameplayTag CurrentLevelTag;
    struct FGameplayTag
    {
        FName TagName;                                                                    // 0x0000 (size: 0x8)

    };
    */
    
    string tag = vars.Utils.FNameToString(vars.Resolver.Read<int>(current.SaveObject + 0x28));

    if (tag != vars.lastLevelTag)
    {
        print("LevelTag: " + vars.lastLevelTag + " -> " + tag);

        if (vars.lastLevelTag != "")
            vars.pendingSplit = true;

        vars.lastLevelTag = tag;
    }
}

split
{
    if (vars.pendingSplit)
    {
        vars.pendingSplit = false;
        print("Split: " + vars.lastLevelTag);
        return true;
    }
    return false;
}