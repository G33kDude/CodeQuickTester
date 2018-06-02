/*
	Implements functionality necessary for AutoCompletion of keywords in the
	RichCode control. Currently works off of values stored in the provided
	Parent object, but could be modified to work off a provided RichCode
	instance directly.
	
	The class is mostly self contained and could be easily extended to other
	projects, and even other types of controls. The main method of interacting
	with the class is by passing it WM_KEYDOWN messages. Another way to interact
	is by modifying the Fragment property, especially to clear it when you want
	to cancel autocompletion.
	
	Depends on CQT.ahk, and optionally on HelpFile.ahk
*/

class AutoComplete
{
	; Maximum number of suggestions to be displayed in the dialog
	static MaxSuggestions := 9
	
	; Minimum length for a word to be entered into the word list
	static MinWordLen := 4
	
	; Minimum length of fragment before suggestions should be displayed
	static MinSuggestLen := 3
	
	; Stores the initial caret position for newly typed fragments
	static CaretX := 0, CaretY := 0
	
	
	; --- Properties ---
	
	Fragment[]
	{
		get
		{
			return this._Fragment
		}
		
		set
		{
			this._Fragment := Value
			
			; Give suggestions when a fragment of sufficient
			; length has been provided
			if (StrLen(this._Fragment) >= 3)
				this._Suggest()
			else
				this._Hide()
			
			return this._Fragment
		}
	}
	
	Enabled[]
	{
		get
		{
			return this._Enabled
		}
		
		set
		{
			this._Enabled := Value
			if (Value)
				this.BuildWordList()
			else
				this.Fragment := ""
			return Value
		}
	}
	
	
	; --- Constructor, Destructor ---
	
	__New(Parent, Enabled:=True)
	{
		this.Parent := Parent
		this.Enabled := Enabled
		this.WineVer := DllCall("ntdll.dll\wine_get_version", "AStr")
		
		; Create the tool GUI for the floating list
		hParentWnd := this.Parent.hMainWindow
		Gui, +hWndhDefaultWnd
		Relation := this.WineVer ? "Parent" Parent.RichCode.hWnd : "Owner" Parent.hMainWindow
		Gui, New, +%Relation% -Caption +ToolWindow +hWndhWnd
		this.hWnd := hWnd
		Gui, Margin, 0, 0
		
		; Create the ListBox control withe appropriate font and styling
		Font := this.Parent.Settings.Font
		Gui, Font, % "s" Font.Size, % Font.Typeface
		Gui, Add, ListBox, x0 y0 r1 0x100 AltSubmit hWndhListBox, Item
		this.hListBox := hListBox
		
		; Finish GUI creation and restore the default GUI
		Gui, Show, Hide, % this.Parent.Title " - AutoComplete"
		Gui, %hDefaultWnd%:Default
		
		; Get relevant dimensions of the ListBox for later resizing
		SendMessage, 0x1A1, 0, 0,, % "ahk_id" this.hListBox ; LB_GETITEMHEIGHT
		this.ListBoxItemHeight := ErrorLevel
		VarSetCapacity(ListBoxRect, 16, 0)
		DllCall("User32.dll\GetClientRect", "Ptr", this.hListBox, "Ptr", &ListBoxRect)
		this.ListBoxMargins := NumGet(ListBoxRect, 12, "Int") - this.ListBoxItemHeight
		
		; Set up the GDI Device Context for later text measurement in _GetWidth
		this.hDC := DllCall("GetDC", "UPtr", this.hListBox, "UPtr")
		SendMessage, 0x31, 0, 0,, % "ahk_id" this.hListBox ; WM_GETFONT
		this.hFont := DllCall("SelectObject", "UPtr", this.hDC, "UPtr", ErrorLevel, "UPtr")
		
		; Record the total screen width for later user. If the monitors get
		; rearranged while the script is still running this value will be
		; inaccurate. However, this will not likely be a significant issue,
		; and the issues caused by it would be minimal.
		SysGet, ScreenWidth, 78
		this.ScreenWidth := ScreenWidth
		
		; Pull a list of default words from the help file.
		; TODO: Include some kind of hard-coded list for when the help file is
		;       not present, or to supplement the help file.
		for Key in HelpFile.GetLookup()
			this.DefaultWordList .= "|" LTrim(Key, "#")
		
		; Build the initial word list based on the default words and the
		; RichCode's contents at the time of AutoComplete's initialization
		this.BuildWordList()
	}
	
	__Delete()
	{
		Gui, % this.hWnd ":Destroy"
		this.Visible := False
		DllCall("SelectObject", "UPtr", this.hDC, "UPtr", this.hFont, "UPtr")
		DllCall("ReleaseDC", "UPtr", this.hListBox, "UPtr", this.hDC)
	}
	
	
	; --- Private Methods ---
	
	; Gets the pixel-based width of a provided text snippet using the GDI font
	; selected into the ListBox control
	_GetWidth(Text)
	{
		MaxWidth := 0
		Loop, Parse, Text, |
		{
			DllCall("GetTextExtentPoint32", "UPtr", this.hDC, "Str", A_LoopField
			, "Int", StrLen(A_LoopField), "Int64*", Size), Size &= 0xFFFFFFFF
			
			if (Size > MaxWidth)
				MaxWidth := Size
		}
		
		return MaxWidth
	}
	
	; Shows the suggestion dialog with contents of the provided DisplayList
	_Show(DisplayList)
	{
		; Insert the new list
		GuiControl,, % this.hListBox, %DisplayList%
		GuiControl, Choose, % this.hListBox, 1
		
		; Resize to fit contents
		StrReplace(DisplayList, "|",, Rows)
		Height := Rows * this.ListBoxItemHeight + this.ListBoxMargins
		Width := this._GetWidth(DisplayList) + 10
		GuiControl, Move, % this.hListBox, w%Width% h%Height%
		
		; Keep the dialog from running off the screen
		X := this.CaretX, Y := this.CaretY + 20
		if ((X + Width) > this.ScreenWidth)
			X := this.ScreenWidth - Width
		
		; Make the dialog visible
		Gui, % this.hWnd ":Show", x%X% y%Y% AutoSize NoActivate
		this.Visible := True
	}
	
	; Hides the dialog if it is visible
	_Hide()
	{
		if !this.Visible
			return
		
		Gui, % this.hWnd ":Hide"
		this.Visible := False
	}
	
	; Filters the word list for entries starting with the fragment, then
	; shows the dialog with the filtered list as suggestions
	_Suggest()
	{
		; Filter the list for words beginning with the fragment
		Suggestions := LTrim(RegExReplace(this.WordList
			, "i)\|(?!" this.Fragment ")[^\|]+"), "|")
		
		; Fail out if there were no matches
		if !Suggestions
			return true, this._Hide()
		
		; Pull the first MaxSuggestions suggestions
		if (Pos := InStr(Suggestions, "|",,, this.MaxSuggestions))
			Suggestions := SubStr(Suggestions, 1, Pos-1)
		this.Suggestions := Suggestions
		
		this._Show("|" Suggestions)
	}
	
	; Finishes the fragment with the selected suggestion
	_Complete()
	{
		; Get the text of the selected item
		GuiControlGet, Selected,, % this.hListBox
		Suggestion := StrSplit(this.Suggestions, "|")[Selected]
		
		; Replace fragment preceding cursor with selected suggestion
		RC := this.Parent.RichCode
		RC.Selection[1] -= StrLen(this.Fragment)
		RC.SelectedText := Suggestion
		RC.Selection[1] := RC.Selection[2]
		
		; Clear out the fragment in preparation for further typing
		this.Fragment := ""
	}
	
	
	; --- Public Methods ---
	
	; Interpret WM_KEYDOWN messages, the primary means of interfacing with the 
	; class. These messages can be provided by registering an appropriate
	; handler with OnMessage, or by forwarding the events from another handler
	; for the control.
	WM_KEYDOWN(wParam, lParam)
	{
		if (!this._Enabled)
			return
		
		; Get the name of the key using the virtual key code. The key's scan
		; code is not used here, but is available in bits 16-23 of lParam and
		; could be used in future versions for greater reliability.
		Key := GetKeyName(Format("vk{:02x}", wParam))
		
		; Treat Numpad variants the same as the equivalent standard keys
		Key := StrReplace(Key, "Numpad")
		
		; Handle presses meant to interact with the dialog, such as
		; navigational, confirmational, or dismissive commands.
		if (this.Visible)
		{
			if (Key == "Tab" || Key == "Enter")
				return False, this._Complete()
			else if (Key == "Up")
				return False, this.SelectUp()
			else if (Key == "Down")
				return False, this.SelectDown()
		}
		
		; Ignore standalone modifier presses, and some modified regular presses
		if Key in Shift,Control,Alt
			return
		
		; Reset on presses with the control modifier
		if GetKeyState("Control")
			return "", this.Fragment := ""
		
		; Subtract from the end of fragment on backspace
		if (Key == "Backspace")
			return "", this.Fragment := SubStr(this.Fragment, 1, -1)
		
		; Apply Shift and CapsLock
		if GetKeyState("Shift")
			Key := StrReplace(Key, "-", "_")
		if (GetKeyState("Shift") ^ GetKeyState("CapsLock", "T"))
			Key := Format("{:U}", Key)
		
		; Reset on unwanted presses -- Allow numbers but not at beginning
		if !(Key ~= "^[A-Za-z_]$" || (this.Fragment != "" && Key ~= "^[0-9]$"))
			return "", this.Fragment := ""
		
		; Record the starting position of new fragments
		if (this.Fragment == "")
		{
			CoordMode, Caret, % this.WineVer ? "Client" : "Screen"
			
			; Round "" to 0, which can prevent errors in the unlikely case that
			; input is received while the control is not focused.
			this.CaretX := Round(A_CaretX), this.CaretY := Round(A_CaretY)
		}
		
		; Update fragment with the press
		this.Fragment .= Key
	}
	
	; Triggers a rebuild of the word list from the RichCode control's contents
	BuildWordList()
	{
		if (!this._Enabled)
			return
		
		; Replace non-word chunks with delimiters
		List := RegExReplace(this.Parent.RichCode.Value, "\W+", "|")
		
		; Ignore numbers at the beginning of words
		List := RegExReplace(List, "\b[0-9]+")
		
		; Ignore words that are too small
		List := RegExReplace(List, "\b\w{1," this.MinWordLen-1 "}\b")
		
		; Append default entries, remove duplicates, and save the list
		List .= this.DefaultWordList
		Sort, List, U D| Z
		this.WordList := "|" Trim(List, "|")
	}
	
	; Moves the selected item in the dialog up one position
	SelectUp()
	{
		GuiControlGet, Selected,, % this.hListBox
		if (--Selected < 1)
			Selected := this.MaxSuggestions
		GuiControl, Choose, % this.hListBox, %Selected%
	}
	
	; Moves the selected item in the dialog down one position
	SelectDown()
	{
		GuiControlGet, Selected,, % this.hListBox
		if (++Selected > this.MaxSuggestions)
			Selected := 1
		GuiControl, Choose, % this.hListBox, %Selected%
	}
}
