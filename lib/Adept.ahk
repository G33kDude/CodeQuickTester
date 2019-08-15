
class Adept
{
	; WM_COMMAND, WM_KEYDOWN, WM_KEYUP, WM_LBUTTONDOWN, WM_LBUTTONUP, WM_RBUTTONDOWN
	_messages := [0x111, 0x100, 0x101, 0x201, 0x202, 0x204]
	_title := "Adept"
	
	__New(config, files:="")
	{
		this.config := config
		
		; Set up the boundfunc event handlers
		; TODO: Is there a better way?
		this.bound := []
		this.bound.OnMessage := this.OnMessage.Bind(this)
		this.bound.GuiSize := this.GuiSize.Bind(this)
		this.bound.SyncGutter := this.SyncGutter.Bind(this)
		this.bound.Interacted := this.Interacted.Bind(this)
		
		; Create the GUI
		Gui, New, +hWndhWnd +Resize
		this.hWnd := hWnd
		
		; Register message hooks
		WinEvents.Register(this.hWnd, this)
		for each, msg in this._messages
			OnMessage(msg, this.bound.OnMessage)
		
		; Create menus
		this.menu := new this.MenuBar(this)
		
		; Add status bar
		Gui, Add, StatusBar, hWndhStatusBar
		ControlGetPos,,,, statusBarHeight,, ahk_id %hStatusBar%
		this.statusBarHeight := statusBarHeight
		
		; Set the background and font settings
		fgColor := Format("{:06x}", this.config.FGColor)
		bgColor := Format("{:06x}", this.config.BGColor)
		Gui, Color, % bgColor, % bgColor
		Gui, Font, % "s" this.config.Font.Size "c" fgColor
		, % this.config.Font.Typeface
		
		; Set up default RichCode controls
		this.views := []
		for i, filePath in (files.length() ? files : [""])
			this.views.Push(new this.View(this.config, filePath))
		this.SwitchTo(this.views[1])
		
		this.oFilePane := new this.FilePane(this)
		this.gutter := new Gutter(this.config)
		this.zoom := this.gutter.zoom
		
		this.Interacted()
		Gui, Show, w800 h600
	}
	
	OnMessage(wParam, lParam, msg, hWnd)
	{
		if (hWnd == this.hWnd && msg == 0x111 ; WM_COMMAND
			&& lParam == this.activeView.hWnd)  ; for RichEdit
		{
			command := wParam >> 16
			
			if (command == 0x400) ; An event that fires on scroll
			{
				this.SyncGutter()
				
				; If the user is scrolling too fast it can cause some messages
				; to be dropped. Set a timer to make sure that when the user stops
				; scrolling that the line numbers will be in sync.
				SetTimer(this.bound.SyncGutter, -50)
			}
			else if (command == 0x200) ; EN_KILLFOCUS
			{
				if this.config.UseAutoComplete
					this.AC.Fragment := ""
			}
		}
		else if (msg == 0x100 && wParam == GetKeyVK("Tab") && GetKeyState("Control"))
		{
			if GetKeyState("Shift")
				this.menu.PrevView(this)
			else
				this.menu.NextView(this)
			return False
		}
		else if (hWnd == this.activeView.hWnd)
		{
			; Call Interacted after the control handles the keystroke
			SetTimer(this.bound.Interacted, -1)
			
			if this.config.UseAutoComplete
			{
				;SetTimer(this.Bound.UpdateAutoComplete
				;, -Abs(this.Settings.ACListRebuildDelay))
				;
				;if (Msg == 0x100) ; WM_KEYDOWN
				;return this.AC.WM_KEYDOWN(wParam, lParam)
				;else if (Msg == 0x201) ; WM_LBUTTONDOWN
				;this.AC.Fragment := ""
			}
		}
		else if (hWnd == this.gutter.hWnd
			&& {0x100:1,0x101:1,0x201:1,0x202:1,0x204:1}[msg]) ; WM_KEYDOWN, WM_KEYUP, WM_LBUTTONDOWN, WM_LBUTTONUP, WM_RBUTTONDOWN
		{
			; Disallow interaction with the gutter
			return True
		}
	}
	
	Interacted()
	{
		this.gutter.MatchLines(this.activeView.hWnd)
		this.UpdateStatusBar()
		this.UpdateTitleBar()
		
		; TODO: Use FilePane class update method with diffing
		if (this.activeView.modified)
		{
			TV_GetText(text, this.activeView.fpid)
			if !(text ~= "\*$")
				TV_Modify(this.activeView.fpid,, text "*")
		}
	}
	
	SyncGutter()
	{
		this.gutter.SyncTo(this.activeView.hWnd)
		if (this.gutter.zoom != this.zoom)
		{
			this.zoom := this.gutter.zoom
			SetTimer(this.bound.GuiSize, -1)
		}
	}
	
	UpdateStatusBar()
	{
		; Get the document length and cursor position
		VarSetCapacity(GTL, 8, 0), NumPut(1200, GTL, 4, "UInt")
		len := SendMessage(0x45F, &GTL, 0, this.activeView.hWnd) ; EM_GETTEXTLENGTHEX (Handles newlines better than GuiControlGet on RE)
		ControlGet, row, CurrentLine,,, % "ahk_id" this.activeView.hWnd
		ControlGet, col, CurrentCol,,, % "ahk_id" this.activeView.hWnd
		
		; Get Selected Text Length
		; Subtract 1 if the user has selected the EOF
		sel := this.activeView.Selection
		sel := (sel[2] - sel[1]) - (sel[2] > len)
		
		; Get the syntax tip, if any
		if (SyntaxTip := HelpFile.GetSyntax(this.GetKeywordFromCaret()))
			this.SyntaxTip := SyntaxTip
		
		; Update the Status Bar text
		Gui, % this.hWnd ":Default"
		SB_SetText("Len " len ", Line " row ", Col " col
		. (sel > 0 ? ", Sel " sel : "") "     " this.syntaxTip)
	}
	
	UpdateTitleBar()
	{
		av := this.activeView
		title := this._title
		
		; Show the current file path / name
		title .= " - " (av.filePath != "" ? av.filePath : av.fileName)
		
		; Show the curernt modification status
		if av.modified
			title .= "*"
		
		; Return if the title doesn't need to be updated
		if (title == this.visibleTitle)
			return
		this.visibleTitle := title
		
		; Set the new title text
		hiddenWindows := A_DetectHiddenWindows
		DetectHiddenWindows, On
		WinSetTitle, % "ahk_id" this.hWnd,, %title%
		DetectHiddenWindows, %hiddenWindows%
	}
	
	IndexFromView(targetView)
	{
		for index, view in this.views
			if (view == targetView)
				return index
	}
	
	SwitchTo(targetView)
	{
		; Only switch if the target is not currently active
		; Maybe also focus the target control?
		if (!targetView || targetView == this.activeView)
			return
		
		; Show/Hide each control
		GuiControl, Show, % targetView.hWnd
		for each, view in this.views
			if (view != targetView)
				GuiControl, Hide, % view.hWnd
		
		; Set the active richCode and update the interface
		this.activeView := targetView
		TV_Modify(targetView.fpid, "Select")
		this.GuiSize()
		this.Interacted()
		
		; Focus the target control
		GuiControl, Focus, % this.activeView.hWnd
	}
	
	GetView(filePath:="", updateFilePane:=False)
	{
		if filePath
		{
			; Look for an open view with that file path
			filePath := GetFullPathName(filePath)
			for each, view in this.views
				if (view.filePath == filePath)
					return view
			
			; TODO: Recycle closed views
			; TODO: Check other instances
		}
		
		; Create a new view
		view := new this.View(this.config, filePath)
		this.views.Push(view)
		if updateFilePane
			this.oFilePane.Update(this)
		
		return view
	}
	
	CloseView(view)
	{
		; TODO: Should I assume the view is valid?
		; TODO: Recycle Views
		
		; If this is the last view create a new blank one
		if (this.views.length() == 1)
			this.views.Push(new this.View(this.config))
		
		; Switch away if necessary
		index := this.IndexFromView(view)
		if (view == this.activeView)
			this.SwitchTo(this.views[Mod(index, this.views.length()) + 1])
		
		; Remove the view and update the UI
		this.views.RemoveAt(index)
		this.oFilePane.Update(this)
	}
	
	GuiSize(hWnd:=-1, e:=-1, w:=-1, h:=-1)
	{
		; If not provided, query for width and height
		if (w < 0 || h < 0)
		{
			VarSetCapacity(RECT, 16, 0)
			DllCall("GetClientRect", "UPtr", this.hWnd, "UPtr", &RECT, "UInt")
			w := NumGet(RECT,  8, "Int"), h := NumGet(RECT, 12, "Int")
		}
		
		; Get shorthands for brevity in calculation
		fpw := this.config.FilePaneWidth
		gtw := this.config.Gutter.Width * this.zoom
		sbh := this.statusBarHeight
		
		; Calculate new positions
		GuiControl, MoveDraw, % this.activeView.hWnd, % "x" fpw+gtw "y" 0 "w" w-fpw-gtw "h" h-sbh
		GuiControl, MoveDraw, % this.gutter.hWnd    , % "x" fpw     "y" 0 "w" gtw       "h" h-sbh
		GuiControl, MoveDraw, % this.oFilePane.hWnd , % "x" 0       "y" 0 "w" fpw       "h" h-sbh
	}
	
	GuiClose()
	{
		; Unregister message hooks
		WinEvents.Unregister(this.hWnd)
		for each, msg in this._messages
			OnMessage(msg, this.bound.OnMessage, 0)
		
		; Delete boundfuncs
		for each, boundFunc in this.bound
			SetTimer(boundFunc, "Delete")
		this.bound := []
		
		; Release GUI and associated gLabels
		Gui, Destroy
		this.menu.Destroy()
	}
	
	#IncludeAgain %A_LineFile%\..\Adept.FilePane.ahk
	#IncludeAgain %A_LineFile%\..\Adept.MenuBar.ahk
	#IncludeAgain %A_LineFile%\..\Adept.View.ahk
}
