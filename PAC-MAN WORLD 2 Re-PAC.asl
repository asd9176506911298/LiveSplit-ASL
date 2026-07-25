state("PAC-MAN WORLD 2 Re-PAC") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
}

init
{
    vars.Instance = vars.Uhara.CreateTool("Unity", "IL2CPP", "Instance");

    vars.Instance.Watch<int>("m_step", "Assembly-CSharp:UI.Title.Select:TitleSelectUI", "m_step");
}

update
{
    vars.Uhara.Update();
    
    if(current.m_step != old.m_step)
    {
        print("m_step: " + current.m_step.ToString());
    }
}

start
{
    if(old.m_step != 0 && current.m_step == 0)
    {
        print("Start");
        return true;
    }
}