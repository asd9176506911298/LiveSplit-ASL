state("PAC-MAN WORLD 2 Re-PAC") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
}

init
{
    vars.Instance = vars.Uhara.CreateTool("Unity", "IL2CPP", "Instance");

    vars.Instance.Watch<int>("m_step", "Assembly-CSharp:UI:GameLevelSelect", "m_step");
    vars.Instance.Watch<int>("m_selectIdx", "Assembly-CSharp:UI:GameLevelSelect", "m_selectIdx");
}

update
{
    vars.Uhara.Update();
    
    if(current.m_step != old.m_step)
    {
        print("m_step: " + current.m_step.ToString());
    }

    if(current.m_selectIdx != old.m_selectIdx)
    {
        print("m_selectIdx: " + current.m_selectIdx.ToString());
    }
}

start
{
    if(old.m_step != 0 && current.m_step == 6 && current.m_selectIdx == 0)
    {
        print("Start");
        return true;
    }
}
