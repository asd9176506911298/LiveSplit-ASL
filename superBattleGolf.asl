state("Super Battle Golf"){}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
}

init
{
    vars.Instance = vars.Uhara.CreateTool("Unity", "DotNet", "Instance");
    
    /*
    // SharedAssembly, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null
    // SingletonNetworkBehaviour<T>
    public class SingletonNetworkBehaviour<T> : SingletonNetworkBehaviourBase where T : NetworkBehaviour
        private static T instance;

    // GameAssembly
    // CourseManager
    public class CourseManager : SingletonNetworkBehaviour<CourseManager>, IBUpdateCallback, IAnyBUpdateCallback
        private readonly SyncList<PlayerState> playerStates = new SyncList<PlayerState>();

    // Mirror
    // Mirror.SyncList<T>
    public class SyncList<T> : SyncObject, IList<T>, ICollection<T>, IEnumerable<T>, IEnumerable, IReadOnlyList<T>, IReadOnlyCollection<T>
        private readonly IList<T> objects;
    */
    
    // 0x10 _items
    // 0x20 First PlayerState
    // 0x34 matchStokes
    // 0x20 + 0x34 = 0x54 Putts
    // 0x58 finishes
    // 0x20 + 0x58 = 0x78 finishes
    vars.Instance.Watch<int>("Putts", "GameAssembly::CourseManager", "playerStates", "objects", "0x10", "0x54");
    vars.Instance.Watch<int>("finishes", "GameAssembly::CourseManager", "playerStates", "objects", "0x10", "0x78");

}

update
{
    vars.Uhara.Update();

    if(current.Putts != old.Putts)
    {
        print("Putts: " + current.Putts.ToString());
    }
    
    if(current.finishes != old.finishes)
    {
        print("Finishes: " + current.finishes.ToString());
    }
}

start
{
    if (current.Putts == 1 && old.Putts == 0)
    {
        print("Game started! (Putts 0 -> 1)");
        return true;
    }
}

split
{
    if(current.finishes != old.finishes)
    {
        print("Hole finished!");
        return true;
    }
}