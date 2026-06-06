state("Librarian-Win64-Shipping"){}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
}

init
{
    vars.Events = vars.Uhara.CreateTool("UnrealEngine", "Events");

    vars.Events.FunctionFlag("start", "WBP_Title_C", "TitleUMG", "StartGame");
    vars.Events.FunctionFlag("resetFlag", "WBP_PauseMenu_C", "WBP_PauseMenu_C", "OnBackToTitleMenu");
}

start
{
    if (vars.Resolver.CheckFlag("start"))
    {
        return true;
    }
}

update
{
    vars.Uhara.Update();
}

reset
{
    if (vars.Resolver.CheckFlag("resetFlag"))
    {
        return true;
    }
}