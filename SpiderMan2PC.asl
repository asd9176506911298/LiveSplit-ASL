// Spider Man 2 (2004) PC

state("Webhead")
{
    byte isLoading : "Engine.dll", 0x5F5908, 0x0;
}


update
{
    if (current.isLoading != old.isLoading)
    {
        // print("Loading state changed: " + current.isLoading.ToString());
    }
}

isLoading
{
    return current.isLoading == 1;
}