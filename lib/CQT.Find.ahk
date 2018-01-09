class Find
{
	__New(Parent)
	{
		this.Parent := Parent
		
		ParentWnd := this.Parent.hMainWindow
		Gui, New, +Owner%ParentWnd% +ToolWindow +hWndhWnd
		this.hWnd := hWnd
		Gui, Margin, 5, 5
		
		
		; Search
		Gui, Add, Edit, hWndhWnd w200
		SendMessage, 0x1501, True, &cue := "Search Text",, ahk_id %hWnd% ; EM_SETCUEBANNER
		this.hNeedle := hWnd
		
		Gui, Add, Button, yp-1 x+m w75 Default hWndhWnd, Find Next
		Bound := this.BtnFind.Bind(this)
		GuiControl, +g, %hWnd%, %Bound%
		
		Gui, Add, Button, yp x+m w75 hWndhWnd, Coun&t All
		Bound := this.BtnCount.Bind(this)
		GuiControl, +g, %hWnd%, %Bound%
		
		
		; Replace
		Gui, Add, Edit, hWndhWnd w200 xm Section
		SendMessage, 0x1501, True, &cue := "Replacement",, ahk_id %hWnd% ; EM_SETCUEBANNER
		this.hReplace := hWnd
		
		Gui, Add, Button, yp-1 x+m w75 hWndhWnd, &Replace
		Bound := this.Replace.Bind(this)
		GuiControl, +g, %hWnd%, %Bound%
		
		Gui, Add, Button, yp x+m w75 hWndhWnd, Replace &All
		Bound := this.ReplaceAll.Bind(this)
		GuiControl, +g, %hWnd%, %Bound%
		
		
		; Options
		Gui, Add, Checkbox, hWndhWnd xm, &Case Sensitive
		this.hOptCase := hWnd
		Gui, Add, Checkbox, hWndhWnd, Re&gular Expressions
		this.hOptRegEx := hWnd
		Gui, Add, Checkbox, hWndhWnd, Transform`, &Deref
		this.hOptDeref := hWnd
		
		
		Gui, Show,, % this.Parent.Title " - Find"
		
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
	
	GetNeedle()
	{
		Opts := this.Case ? "`n" : "i`n"
		Opts .= this.Needle ~= "^[^\(]\)" ? "" : ")"
		if this.RegEx
			return Opts . this.Needle
		else
			return Opts "\Q" StrReplace(this.Needle, "\E", "\E\\E\Q") "\E"
	}
	
	Find(StartingPos:=1, WrapAround:=True)
	{
		Needle := this.GetNeedle()
		
		; Search from StartingPos
		NextPos := RegExMatch(this.Haystack, Needle, Match, StartingPos)
		
		; Search from the top
		if (!NextPos && WrapAround)
			NextPos := RegExMatch(this.Haystack, Needle, Match)
		
		return NextPos ? [NextPos, NextPos+StrLen(Match)] : False
	}
	
	Submit()
	{
		; Options
		GuiControlGet, Deref,, % this.hOptDeref
		GuiControlGet, Case,, % this.hOptCase
		this.Case := Case
		GuiControlGet, RegEx,, % this.hOptRegEx
		this.RegEx := RegEx
		
		; Search Text/Needle
		GuiControlGet, Needle,, % this.hNeedle
		if Deref
			Transform, Needle, Deref, %Needle%
		this.Needle := Needle
		
		; Replacement
		GuiControlGet, Replace,, % this.hReplace
		if Deref
			Transform, Replace, Deref, %Replace%
		this.Replace := Replace
		
		; Haystack
		this.Haystack := StrReplace(this.Parent.RichCode.Value, "`r")
	}
	
	BtnFind()
	{
		Gui, +OwnDialogs
		this.Submit()
		
		; Find and select the item or error out
		if (Pos := this.Find(this.Parent.RichCode.Selection[1]+2))
			this.Parent.RichCode.Selection := [Pos[1] - 1, Pos[2] - 1]
		else
			MsgBox, 0x30, % this.Parent.Title " - Find", Search text not found
	}
	
	BtnCount()
	{
		Gui, +OwnDialogs
		this.Submit()
		
		; Find and count all instances
		Count := 0, Start := 1
		while (Pos := this.Find(Start, False))
			Start := Pos[1]+1, Count += 1
		
		MsgBox, 0x40, % this.Parent.Title " - Find", %Count% instances found
	}
	
	Replace()
	{
		this.Submit()
		
		; Get the current selection
		Sel := this.Parent.RichCode.Selection
		
		; Find the next occurrence including the current selection
		Pos := this.Find(Sel[1]+1)
		
		; If the found item is already selected
		if (Sel[1]+1 == Pos[1] && Sel[2]+1 == Pos[2])
		{
			; Replace it
			this.Parent.RichCode.SelectedText := this.Replace
			
			; Update the haystack to include the replacement
			this.Haystack := StrReplace(this.Parent.RichCode.Value, "`r")
			
			; Find the next item *not* including the current selection
			Pos := this.Find(Sel[1]+StrLen(this.Replace)+1)
		}
		
		; Select the next found item or error out
		if Pos
			this.Parent.RichCode.Selection := [Pos[1] - 1, Pos[2] - 1]
		else
			MsgBox, 0x30, % this.Parent.Title " - Find", No more instances found
	}
	
	ReplaceAll()
	{
		rc := this.Parent.RichCode
		this.Submit()
		
		Needle := this.GetNeedle()
		
		; Replace the text in a way that pushes to the undo buffer
		rc.Frozen := True
		Sel := rc.Selection
		rc.Selection := [0, -1]
		rc.SelectedText := RegExReplace(this.Haystack, Needle, this.Replace, Count)
		rc.Selection := Sel
		rc.Frozen := False
		
		MsgBox, 0x40, % this.Parent.Title " - Find", %Count% instances replaced
	}
}
