class Paste
{
	static Targets := {"IRC": "#ahk", "Discord": "discord"}
	
	__New(Parent)
	{
		this.Parent := Parent
		
		ParentWnd := this.Parent.hMainWindow
		Gui, New, +Owner%ParentWnd% +ToolWindow +hWndhWnd
		this.hWnd := hWnd
		Gui, Margin, 5, 5
		
		Gui, Add, Text, xm ym w30 h22 +0x200, Desc: ; 0x200 for vcenter
		Gui, Add, Edit, x+5 yp w125 h22 hWndhPasteDesc, % this.Parent.Settings.DefaultDesc
		this.hPasteDesc := hPasteDesc
		
		Gui, Add, Button, x+4 yp-1 w52 h24 Default hWndhPasteButton, Paste
		this.hPasteButton := hPasteButton
		BoundPaste := this.Paste.Bind(this)
		GuiControl, +g, %hPasteButton%, %BoundPaste%
		
		Gui, Add, Text, xm y+5 w30 h22 +0x200, Name: ; 0x200 for vcenter
		Gui, Add, Edit, x+5 yp w100 h22 hWndhPasteName, % this.Parent.Settings.DefaultName
		this.hPasteName := hPasteName
		
		Gui, Add, DropDownList, x+5 yp w75 hWndhPasteChan, Announce||IRC|Discord
		this.hPasteChan := hPasteChan
		
		PostMessage, 0x153, -1, 22-6,, ahk_id %hPasteChan% ; Set height of ComboBox
		Gui, Show,, % this.Parent.Title " - Pastebin"
		
		WinEvents.Register(this.hWnd, this)
	}
	
	GuiClose()
	{
		GuiControl, -g, % this.hPasteButton
		WinEvents.Unregister(this.hWnd)
		Gui, Destroy
	}
	
	GuiEscape()
	{
		this.GuiClose()
	}
	
	Paste()
	{
		GuiControlGet, PasteDesc,, % this.hPasteDesc
		GuiControlGet, PasteName,, % this.hPasteName
		GuiControlGet, PasteChan,, % this.hPasteChan
		this.GuiClose()
		
		Link := Ahkbin(this.Parent.RichCode.Value, PasteName, PasteDesc, this.Targets[PasteChan])
		
		MsgBox, 292, % this.Parent.Title " - Pasted", Link received:`n%Link%`n`nCopy to clipboard?
		IfMsgBox, Yes
			Clipboard := Link
	}
}
