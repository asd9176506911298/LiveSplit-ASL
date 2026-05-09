state("BALDI") {}

startup 
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
    vars.Uhara.AlertLoadless();
}

init
{
    vars.Instance = vars.Uhara.CreateTool("Unity", "DotNet", "Instance");

    vars.Instance.Watch<float>("realVelocity", "PlayerMovement", "realVelocity");
}

update
{
    vars.Uhara.Update();

    float cleanVelocity = float.IsNaN(current.realVelocity) ? 0f : current.realVelocity;
    float cleanOldVelocity = float.IsNaN(old.realVelocity) ? 0f : old.realVelocity;

    if (cleanVelocity != cleanOldVelocity)
    {
        print("Cleaned Velocity: " + cleanOldVelocity + " -> " + cleanVelocity);
    }
}

start
{
    float velocity = float.IsNaN(current.realVelocity) ? 0f : current.realVelocity;

    return velocity > 0.1f && velocity < 100f;
}
