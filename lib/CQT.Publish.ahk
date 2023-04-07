class Publish
{
	__New(parent) {
		this.parent := parent
		
		this.gui := Gui("+Owner" this.parent.gui.hWnd " +ToolWindow")
		this.gui.MarginX := 5
		this.gui.MarginY := 5
		
		; 0x200 for vcenter
		this.gui.AddText "w245 h22 Center +0x200", "Gather all includes and save to file."
		
		this.gui.AddCheckbox "w120 h22 Checked Section Disabled", "Keep Comments"
		this.gui.AddCheckbox "w120 h22 Checked Disabled", "Keep Indentation"
		this.gui.AddCheckbox "w120 h22 Checked Disabled", "Keep Empty Lines"
		
		btn := this.gui.AddButton("w120 h81 ys-1 Default", "Export")
		btn.onEvent "Click", (*) => this.Publish()
		
		this.gui.Title := this.parent.Title " - Publish"

		this.gui.OnEvent "Close", (*) => this.gui.Hide()
		this.gui.OnEvent "Escape", (*) => this.gui.Hide()
	}

	Show() {
		this.gui.Show
	}

	Publish()
	{
		this.gui.Opt "OwnDialogs"
		path := FileSelect("S18",, this.parent.Title " - Publish")
		if !path
			return
		
		FileOpen(path, "w").Write(this.Parent.RichCode.Text)
		PreprocessScript(&text := "", path)
		FileOpen(path, "w").Write(text)
	}
}
