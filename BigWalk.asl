state("Big Walk"){}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
}

init
{
    vars.Instance = vars.Uhara.CreateTool("Unity", "IL2CPP", "Instance");
    vars.Utils = vars.Uhara.CreateTool("Unity", "GameObject");


    vars.Instance.Watch<bool>("startFlag", "PeckManager", "<isReadyForEffects>k__BackingField");
    vars.Instance.Watch<bool>("EndFlag", "CongratsMenu", "continueButton", "0x10", "0x20", "0x46");
}

update
{
    vars.Uhara.Update();

    if(current.startFlag != old.startFlag)
    {
        vars.Uhara.Log("startFlag changed: " + current.startFlag);
    }
    if(current.EndFlag != old.EndFlag)
    {
        vars.Uhara.Log("EndFlag changed: " + current.EndFlag);
    }
}

start
{
    if (!old.startFlag && current.startFlag)
    {
        return true;
    }
}

split
{
    if (!old.EndFlag && current.EndFlag)
    {
        return true;
    }
}
