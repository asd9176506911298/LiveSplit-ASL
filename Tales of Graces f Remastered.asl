state("Tales of Graces f Remastered")
{   
    //0x8e4450 EX_SHOP_MENU
    byte startFlag: "GameNative.dll", 0x8e4458;
    // + 8 flag
    byte startFlag2: "GameNative.dll", 0x8e445C;
    // + C flag
    int loadingFlag: "GameNative.dll", 0x90284C;
    int blackScreen: "GameNative.dll", 0x7D3B24;
}

startup
{
    if (timer.CurrentTimingMethod != TimingMethod.GameTime)
    {
        var mbox = System.Windows.Forms.MessageBox.Show(
            timer.Form,
            "Removing loads from this game requires comparing against Game Time.\nWould you like to switch to it?",
            "LiveSplit | Tales of Graces f Remastered",
            System.Windows.Forms.MessageBoxButtons.YesNo,
            System.Windows.Forms.MessageBoxIcon.Question
        );

        if (mbox == System.Windows.Forms.DialogResult.Yes)
        {
            timer.CurrentTimingMethod = TimingMethod.GameTime;
        }
    }
}

update
{
    if(current.startFlag != old.startFlag)
    {
        print("Flag: " + old.startFlag + " -> " + current.startFlag);
    }
}

start
{
    return old.startFlag == 6 && current.startFlag == 7 && old.startFlag2 == 0 && current.startFlag2 == 8;
}

isLoading
{
    return current.loadingFlag != 72;
}

split
{
    return old.blackScreen == 2 && current.blackScreen == 0;
}