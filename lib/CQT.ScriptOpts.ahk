class ScriptOpts
{
    __New(parent)
    {
        this.parent := parent
        this.gui := Gui("+Owner" parent.gui.Hwnd " +ToolWindow", this.parent.Title " - Script Options")
        this.hWnd := this.gui.Hwnd

        ; Add path picker button
        hButton := this.gui.Add("Button", "xm ym w95", "Pick AHK Path").OnEvent("Click", (*) => this.SelectFile())

        ; Add path visualization field
        this.hAhkPath := this.gui.Add("Edit", "ym w250 ReadOnly", "")

        ; Add parameters field
        this.gui.Add("Text", "xm w95 h22 +0x200", "Parameters:")
        this.hParamEdit := this.gui.Add("Edit", "yp x+m w250")
        this.hParamEdit.OnEvent("Change", (*) => this.ParamEdit())

        ; Add Working Directory field
        hWDButton := this.gui.Add("Button", "xm w95", "Pick Working Dir").OnEvent("Click", (*) => this.SelectPath())

        ; Add Working Dir visualization field
        this.hWorkingDir := this.gui.Add("Edit", "x+m w250 ReadOnly", A_WorkingDir)
    }

    ParamEdit()
    {
        ParamEdit := this.hParamEdit.Value
        this.parent.Settings.Params := ParamEdit
        this.UpdateFields()
    }

    SelectFile()
    {
        AhkPath := this.hAhkPath.Value
        AhkPath := FileSelect(1, AhkPath, "Pick an AHK EXE", "Executables (*.exe)")
        if (AhkPath = "")
            return
        this.parent.Settings.AhkPath := AhkPath
        this.hAhkPath.Value := AhkPath
        this.UpdateFields()
    }

    SelectPath()
    {
        WorkingDir := DirSelect("*" A_WorkingDir, 1, "Choose the Working Directory")
        if (WorkingDir = "")
            return
        SetWorkingDir(WorkingDir)
        this.UpdateFields()
    }

    UpdateFields()
    {
        this.hAhkPath.Value := this.parent.Settings.AhkPath
        this.hWorkingDir.Value := A_WorkingDir
    }

    GuiClose()
    {
        this.gui.Destroy()
    }

    GuiEscape()
    {
        this.GuiClose()
    }

    Show()
    {
        this.gui.Show()
    }
}
