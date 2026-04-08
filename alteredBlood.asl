state("Rakimia-Win64-Shipping"){}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
}

init
{
    vars.Events = vars.Uhara.CreateTool("UnrealEngine", "Events");

    vars.Events.FunctionFlag("start", "WBP_StartMenu_C", "WBP_StartMenu_C", "Destruct");
    vars.Events.FunctionFlag("finish", "WBP_ScoreMenu_C", "WBP_ScoreMenu_C", "Finished_*");
}

start
{
    if (vars.Resolver.CheckFlag("start"))
    {
        return true;
    }
}

split
{
    if (vars.Resolver.CheckFlag("finish"))
    {
        return true;
    }
}

update
{
    vars.Uhara.Update(); 
}
