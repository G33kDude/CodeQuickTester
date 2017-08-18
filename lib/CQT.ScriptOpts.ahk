class ScriptOpts
{
	__New(Parent)
	{
		this.Parent := Parent
		
		; Create a GUI
		ParentWnd := this.Parent.hMainWindow
		Gui, New, +Owner%ParentWnd% +ToolWindow +hWndhWnd
		this.hWnd := hWnd
		WinEvents.Register(this.hWnd, this)
		
		; Add path picker button
		Gui, Add, Button, xm ym w95 hWndhButton, Pick AHK Path
		BoundSelectFile := this.SelectFile.Bind(this)
		GuiControl, +g, %hButton%, %BoundSelectFile%
		
		; Add path visualization field
		Gui, Add, Edit, ym w250 ReadOnly hWndhAhkPath, % this.Parent.Settings.AhkPath
		this.hAhkPath := hAhkPath
		
		; Add parameters field
		Gui, Add, Text, xm w95, Parameters:
		Gui, Add, Edit, yp x+m w250 hWndhParamEdit
		this.hParamEdit := hParamEdit
		ParamEditBound := this.ParamEdit.Bind(this)
		GuiControl, +g, %hParamEdit%, %ParamEditBound%
		
		; Show the GUI
		Gui, Show,, % this.Parent.Title " - Script Options"
	}
	
	ParamEdit()
	{
		GuiControlGet, ParamEdit,, % this.hParamEdit
		this.Parent.Settings.Params := ParamEdit
	}
	
	SelectFile()
	{
		GuiControlGet, AhkPath,, % this.hAhkPath
		FileSelectFile, AhkPath, 1, %AhkPath%\.., Pick an AHK EXE, Executables (*.exe)
		if !AhkPath
			return
		this.Parent.Settings.AhkPath := AhkPath
		GuiControl,, % this.hAhkPath, %AhkPath%
	}
	
	GuiClose()
	{
		WinEvents.Unregister(this.hWnd)
		Gui, Destroy
	}
	
	GuiEscape()
	{
		this.GuiClose()
	}
}
