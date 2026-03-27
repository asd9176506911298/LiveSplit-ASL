state("Missing Entity")
{
    
}

startup 
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
}

init
{
    vars.Instance = vars.Uhara.CreateTool("Unity", "DotNet", "Instance");
    vars.JitSave = vars.Uhara.CreateTool("Unity", "DotNet", "JitSave");
    vars.Utils = vars.Uhara.CreateTool("Unity", "Utils");

    IntPtr ExecuteAction = vars.JitSave.AddInst("TimedObjectController", "ExecuteAction");

    vars.JitSave.ProcessQueue();

    vars.Resolver.Watch<IntPtr>("funcExecuteAction", ExecuteAction);
}

update
{
    vars.Uhara.Update();
    
    current.activeScene = vars.Utils.GetActiveSceneName() ?? current.activeScene;
    
    if (old.activeScene != current.activeScene)
    {
        print(old.activeScene + " -> " + current.activeScene);
    }

    if (current.funcExecuteAction != old.funcExecuteAction && 
    current.funcExecuteAction != IntPtr.Zero)
    {      
        // 在這裡讀 instance 欄位來過濾
        long addr = current.funcExecuteAction.ToInt64();
        int action  = game.ReadValue<int>((IntPtr)(addr + 0x30));
        float delay = game.ReadValue<float>((IntPtr)(addr + 0x34));
        
        print(addr.ToString("X") + " " + action.ToString() + " " + delay);
    }
}

start
{
    return old.activeScene == "Demo1" && current.activeScene != "Demo1";
}

split
{
    if(old.activeScene == "Chapter2" && current.activeScene == "Chapter2 1")
    {
        return true;
    }

    if (current.funcExecuteAction != old.funcExecuteAction && 
        current.funcExecuteAction != IntPtr.Zero)
    {      
        long addr       = current.funcExecuteAction.ToInt64();
        int action      = game.ReadValue<int>((IntPtr)(addr + 0x30));
        float delay     = game.ReadValue<float>((IntPtr)(addr + 0x34));

        long oldAddr    = old.funcExecuteAction.ToInt64();
        int oldAction   = oldAddr != 0 ? game.ReadValue<int>((IntPtr)(oldAddr + 0x30)) : -1;
        float oldDelay  = oldAddr != 0 ? game.ReadValue<float>((IntPtr)(oldAddr + 0x34)) : -1f;
        
        print(addr.ToString("X") + " " + action.ToString() + " " + delay);

        if (current.activeScene == "Chapter2 1" &&
            oldAction == 0 && Math.Abs(oldDelay - 0f) < 0.01f &&
            action    == 1 && Math.Abs(delay    - 3f)   < 0.01f)
        {
            return true;
        }
    }
    return false;
}