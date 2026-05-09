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

    // 判斷：速度要大於 0.1（開始動了）且 小於 100（排除場景切換的瞬間移動）
    return velocity > 0.1f && velocity < 100f;
}