class Publish
{
	__New(Parent)
	{
		this.Parent := Parent
		
		ParentWnd := this.Parent.hMainWindow
		Gui, New, +Owner%ParentWnd% +ToolWindow +hWndhWnd
		this.hWnd := hWnd
		Gui, Margin, 5, 5
		
		; 0x200 for vcenter
		Gui, Add, Text, w245 h22 Center +0x200, Gather all includes and save to file.
		
		Gui, Add, Checkbox, hWndhWnd w120 h22 Checked Section, Keep Comments
		this.hComments := hWnd
		Gui, Add, Checkbox, hWndhWnd w120 h22 Checked, Keep Indentation
		this.hIndent := hWnd
		Gui, Add, Checkbox, hWndhWnd w120 h22 Checked, Keep Empty Lines
		this.hEmpties := hWnd
		
		Gui, Add, Button, hWndhWnd w120 h81 ys-1 Default, Export
		this.hButton := hWnd
		BoundPublish := this.Publish.Bind(this)
		GuiControl, +g, %hWnd%, %BoundPublish%
		
		Gui, Show,, % this.Parent.Title " - Publish"
		
		WinEvents.Register(this.hWnd, this)
	}
	
	GuiClose()
	{
		GuiControl, -g, % this.hButton
		WinEvents.Unregister(this.hWnd)
		Gui, Destroy
	}
	
	GuiEscape()
	{
		this.GuiClose()
	}
	
	Publish()
	{
		GuiControlGet, KeepComments,, % this.hComments
		GuiControlGet, KeepIndent,, % this.hIndent
		GuiControlGet, KeepEmpties,, % this.hEmpties
		this.GuiClose()
		
		Gui, % this.Parent.hMainWindow ":+OwnDialogs"
		FileSelectFile, FilePath, S18,, % this.Parent.Title " - Publish Code"
		if ErrorLevel
			return
		
		FileOpen(FilePath, "w").Write(this.Parent.RichCode.Value)
		PreprocessScript(Text, FilePath, KeepComments, KeepIndent, KeepEmpties)
		FileOpen(FilePath, "w").Write(Text)
	}
}
