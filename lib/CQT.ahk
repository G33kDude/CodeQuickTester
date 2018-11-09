class CodeQuickTester
{
	static Msftedit := DllCall("LoadLibrary", "Str", "Msftedit.dll")
	EditorString := """" A_AhkPath """ """ A_ScriptFullPath """ ""%1"""
	OrigEditorString := "notepad.exe %1"
	Title := "CodeQuickTester"
	
	__New(Settings)
	{
		this.Settings := Settings
		
		this.Shell := ComObjCreate("WScript.Shell")
		
		this.Bound := []
		this.Bound.RunButton := this.RunButton.Bind(this)
		this.Bound.GuiSize := this.GuiSize.Bind(this)
		this.Bound.OnMessage := this.OnMessage.Bind(this)
		this.Bound.UpdateStatusBar := this.UpdateStatusBar.Bind(this)
		this.Bound.UpdateAutoComplete := this.UpdateAutoComplete.Bind(this)
		this.Bound.CheckIfRunning := this.CheckIfRunning.Bind(this)
		this.Bound.Highlight := this.Highlight.Bind(this)
		this.Bound.SyncGutter := this.SyncGutter.Bind(this)
		
		Buttons := new this.MenuButtons(this)
		this.Bound.Indent := Buttons.Indent.Bind(Buttons)
		this.Bound.Unindent := Buttons.Unindent.Bind(Buttons)
		Menus :=
		( LTrim Join Comments
		[
			["&File", [
				["&Run`tF5", this.Bound.RunButton],
				[],
				["&New`tCtrl+N", Buttons.New.Bind(Buttons)],
				["&Open`tCtrl+O", Buttons.Open.Bind(Buttons)],
				["Open &Working Dir`tCtrl+Shift+O", Buttons.OpenFolder.Bind(Buttons)],
				["&Save`tCtrl+S", Buttons.Save.Bind(Buttons, False)],
				["&Save as`tCtrl+Shift+S", Buttons.Save.Bind(Buttons, True)],
				["Rename", Buttons.Rename.Bind(Buttons)],
				[],
				["&Publish", Buttons.Publish.Bind(Buttons)],
				["&Fetch", Buttons.Fetch.Bind(Buttons)],
				[],
				["E&xit`tCtrl+W", this.GuiClose.Bind(this)]
			]], ["&Edit", [
				["Find`tCtrl+F", Buttons.Find.Bind(Buttons)],
				[],
				["Comment Lines`tCtrl+K", Buttons.Comment.Bind(Buttons)],
				["Uncomment Lines`tCtrl+Shift+K", Buttons.Uncomment.Bind(Buttons)],
				[],
				["Indent Lines", this.Bound.Indent],
				["Unindent Lines", this.Bound.Unindent],
				[],
				["Include &Relative", Buttons.IncludeRel.Bind(Buttons)],
				["Include &Absolute", Buttons.IncludeAbs.Bind(Buttons)],
				[],
				["Script &Options", Buttons.ScriptOpts.Bind(Buttons)]
			]], ["&Tools", [
				["&Pastebin`tCtrl+P", Buttons.Paste.Bind(Buttons)],
				["Re&indent`tCtrl+I", Buttons.AutoIndent.Bind(Buttons)],
				[],
				["&AlwaysOnTop`tAlt+A", Buttons.ToggleOnTop.Bind(Buttons)],
				["Global Run Hotkeys", Buttons.GlobalRun.Bind(Buttons)],
				[],
				["Install Service Handler", Buttons.ServiceHandler.Bind(Buttons)],
				["Set as Default Editor", Buttons.DefaultEditor.Bind(Buttons)],
				[],
				["&Highlighter", Buttons.Highlighter.Bind(Buttons)],
				["AutoComplete", Buttons.AutoComplete.Bind(Buttons)]
			]], ["&Help", [
				["Open &Help File`tCtrl+H", Buttons.Help.Bind(Buttons)],
				["&About", Buttons.About.Bind(Buttons)]
			]]
		]
		)
		
		Gui, New, +Resize +hWndhMainWindow -AlwaysOnTop
		this.AlwaysOnTop := False
		this.hMainWindow := hMainWindow
		this.Menus := CreateMenus(Menus)
		Gui, Menu, % this.Menus[1]
		
		; If set as default, check the highlighter option
		if this.Settings.UseHighlighter
			Menu, % this.Menus[4], Check, &Highlighter
		
		; If set as default, check the global run hotkeys option
		if this.Settings.GlobalRun
			Menu, % this.Menus[4], Check, Global Run Hotkeys
		
		; If set as default, check the AutoComplete option
		if this.Settings.UseAutoComplete
			Menu, % this.Menus[4], Check, AutoComplete
		
		; If service handler is installed, check the menu option
		if ServiceHandler.Installed()
			Menu, % this.Menus[4], Check, Install Service Handler
		
		RegRead, Editor, HKCR, AutoHotkeyScript\Shell\Edit\Command
		if (Editor == this.EditorString)
			Menu, % this.Menus[4], Check, Set as Default Editor
		
		; Register for events
		WinEvents.Register(this.hMainWindow, this)
		for each, Msg in [0x111, 0x100, 0x101, 0x201, 0x202, 0x204] ; WM_COMMAND, WM_KEYDOWN, WM_KEYUP, WM_LBUTTONDOWN, WM_LBUTTONUP, WM_RBUTTONDOWN
			OnMessage(Msg, this.Bound.OnMessage)
		
		; Add code editor and gutter for line numbers
		this.RichCode := new RichCode(this.Settings, "-E0x20000")
		RichEdit_AddMargins(this.RichCode.hWnd, 3, 3)
		if Settings.Gutter.Width
			this.AddGutter()
		
		if B_Params.HasKey(1)
			FilePath := RegExReplace(B_Params[1], "^ahk:") ; Remove leading service handler
		else
			FilePath := Settings.DefaultPath
		
		if (FilePath ~= "^https?://")
			this.RichCode.Value := UrlDownloadToVar(FilePath)
		else if (FilePath = "Clipboard")
			this.RichCode.Value := Clipboard
		else if InStr(FileExist(FilePath), "A")
		{
			this.RichCode.Value := FileOpen(FilePath, "r").Read()
			this.RichCode.Modified := False
			
			if (FilePath == Settings.DefaultPath)
			{
				; Place cursor after the default template text
				this.RichCode.Selection := [-1, -1]
			}
			else
			{
				; Keep track of the file currently being edited
				this.FilePath := GetFullPathName(FilePath)
				
				; Follow the directory of the most recently opened file
				SetWorkingDir, %FilePath%\..
			}
		}
		else
			this.RichCode.Value := ""
		
		if (this.FilePath == "")
			Menu, % this.Menus[2], Disable, Rename
		
		; Add run button
		Gui, Add, Button, hWndhRunButton, &Run
		this.hRunButton := hRunButton
		BoundFunc := this.Bound.RunButton
		GuiControl, +g, %hRunButton%, %BoundFunc%
		
		; Add status bar
		Gui, Add, StatusBar, hWndhStatusBar
		this.UpdateStatusBar()
		ControlGetPos,,,, StatusBarHeight,, ahk_id %hStatusBar%
		this.StatusBarHeight := StatusBarHeight
		
		; Initialize the AutoComplete
		this.AC := new this.AutoComplete(this, this.settings.UseAutoComplete)
		
		this.UpdateTitle()
		Gui, Show, w640 h480
	}
	
	AddGutter()
	{
		s := this.Settings, f := s.Font, g := s.Gutter
		
		; Add the RichEdit control for the gutter
		Gui, Add, Custom, ClassRichEdit50W hWndhGutter +0x5031b1c6 -HScroll -VScroll
		this.hGutter := hGutter
		
		; Set the background and font settings
		FGColor := RichCode.BGRFromRGB(g.FGColor)
		BGColor := RichCode.BGRFromRGB(g.BGColor)
		VarSetCapacity(CF2, 116, 0)
		NumPut(116,        &CF2+ 0, "UInt") ; cbSize      = sizeof(CF2)
		NumPut(0xE<<28,    &CF2+ 4, "UInt") ; dwMask      = CFM_COLOR|CFM_FACE|CFM_SIZE
		NumPut(f.Size*20,  &CF2+12, "UInt") ; yHeight     = twips
		NumPut(FGColor,    &CF2+20, "UInt") ; crTextColor = 0xBBGGRR
		StrPut(f.Typeface, &CF2+26, 32, "UTF-16") ; szFaceName = TCHAR
		SendMessage(0x444, 0, &CF2,    hGutter) ; EM_SETCHARFORMAT
		SendMessage(0x443, 0, BGColor, hGutter) ; EM_SETBKGNDCOLOR
		
		RichEdit_AddMargins(hGutter, 3, 3, -3, 0)
	}
	
	RunButton()
	{
		if (this.Exec.Status == 0) ; Running
			this.Exec.Terminate() ; CheckIfRunning updates the GUI
		else ; Not running or doesn't exist
		{
			this.Exec := ExecScript(this.RichCode.Value
			, this.Settings.Params
			, this.Settings.AhkPath)
			
			GuiControl,, % this.hRunButton, &Kill
			
			SetTimer(this.Bound.CheckIfRunning, 100)
		}
	}
	
	CheckIfRunning()
	{
		if (this.Exec.Status == 1)
		{
			SetTimer(this.Bound.CheckIfRunning, "Delete")
			GuiControl,, % this.hRunButton, &Run
		}
	}
	
	LoadCode(Code, FilePath:="")
	{
		; Do nothing if nothing is changing
		if (this.FilePath == FilePath && this.RichCode.Value == Code)
			return
		
		; Confirm the user really wants to load new code
		Gui, +OwnDialogs
		MsgBox, 308, % this.Title " - Confirm Overwrite"
		, Are you sure you want to overwrite your code?
		IfMsgBox, No
			return
		
		; If we're changing the open file mark as modified
		; If we're loading a new file mark as unmodified
		this.RichCode.Modified := this.FilePath == FilePath
		this.FilePath := FilePath
		if (this.FilePath == "")
			Menu, % this.Menus[2], Disable, Rename
		else
			Menu, % this.Menus[2], Enable, Rename
		
		; Update the GUI
		this.RichCode.Value := Code
		this.UpdateStatusBar()
	}
	
	OnMessage(wParam, lParam, Msg, hWnd)
	{
		if (hWnd == this.hMainWindow && Msg == 0x111 ; WM_COMMAND
			&& lParam == this.RichCode.hWnd)         ; for RichEdit
		{
			Command := wParam >> 16
			
			if (Command == 0x400) ; An event that fires on scroll
			{
				this.SyncGutter()
				
				; If the user is scrolling too fast it can cause some messages
				; to be dropped. Set a timer to make sure that when the user stops
				; scrolling that the line numbers will be in sync.
				SetTimer(this.Bound.SyncGutter, -50)
			}
			else if (Command == 0x200) ; EN_KILLFOCUS
				if this.Settings.UseAutoComplete
					this.AC.Fragment := ""
		}
		else if (hWnd == this.RichCode.hWnd)
		{
			; Call UpdateStatusBar after the edit handles the keystroke
			SetTimer(this.Bound.UpdateStatusBar, -0)
			
			if this.Settings.UseAutoComplete
			{
				SetTimer(this.Bound.UpdateAutoComplete
					, -Abs(this.Settings.ACListRebuildDelay))
				
				if (Msg == 0x100) ; WM_KEYDOWN
					return this.AC.WM_KEYDOWN(wParam, lParam)
				else if (Msg == 0x201) ; WM_LBUTTONDOWN
					this.AC.Fragment := ""
			}
		}
		else if (hWnd == this.hGutter
			&& {0x100:1,0x101:1,0x201:1,0x202:1,0x204:1}[Msg]) ; WM_KEYDOWN, WM_KEYUP, WM_LBUTTONDOWN, WM_LBUTTONUP, WM_RBUTTONDOWN
		{
			; Disallow interaction with the gutter
			return True
		}
	}
	
	SyncGutter()
	{
		static BUFF, _ := VarSetCapacity(BUFF, 16, 0)
		
		if !this.Settings.Gutter.Width
			return
		
		SendMessage(0x4E0, &BUFF, &BUFF+4, this.RichCode.hwnd) ; EM_GETZOOM
		SendMessage(0x4DD, 0, &BUFF+8, this.RichCode.hwnd)     ; EM_GETSCROLLPOS
		
		; Don't update the gutter unnecessarily
		State := NumGet(BUFF, 0, "UInt") . NumGet(BUFF, 4, "UInt")
		. NumGet(BUFF, 8, "UInt") . NumGet(BUFF, 12, "UInt")
		if (State == this.GutterState)
			return
		
		NumPut(-1, BUFF, 8, "UInt") ; Don't sync horizontal position
		Zoom := [NumGet(BUFF, "UInt"), NumGet(BUFF, 4, "UInt")]
		PostMessage(0x4E1, Zoom[1], Zoom[2], this.hGutter)     ; EM_SETZOOM
		PostMessage(0x4DE, 0, &BUFF+8, this.hGutter)           ; EM_SETSCROLLPOS
		this.ZoomLevel := Zoom[1] / Zoom[2]
		if (this.ZoomLevel != this.LastZoomLevel)
			SetTimer(this.Bound.GuiSize, -0), this.LastZoomLevel := this.ZoomLevel
		
		this.GutterState := State
	}
	
	GetKeywordFromCaret()
	{
		; https://autohotkey.com/boards/viewtopic.php?p=180369#p180369
		static Buffer
		IsUnicode := !!A_IsUnicode
		
		rc := this.RichCode
		sel := rc.Selection
		
		; Get the currently selected line
		LineNum := rc.SendMsg(0x436, 0, sel[1]) ; EM_EXLINEFROMCHAR
		
		; Size a buffer according to the line's length
		Length := rc.SendMsg(0xC1, sel[1], 0) ; EM_LINELENGTH
		VarSetCapacity(Buffer, Length << !!A_IsUnicode, 0)
		NumPut(Length, Buffer, "UShort")
		
		; Get the text from the line
		rc.SendMsg(0xC4, LineNum, &Buffer) ; EM_GETLINE
		lineText := StrGet(&Buffer, Length)
		
		; Parse the line to find the word
		LineIndex := rc.SendMsg(0xBB, LineNum, 0) ; EM_LINEINDEX
		RegExMatch(SubStr(lineText, 1, sel[1]-LineIndex), "[#\w]+$", Start)
		RegExMatch(SubStr(lineText, sel[1]-LineIndex+1), "^[#\w]+", End)
		
		return Start . End
	}
	
	UpdateStatusBar()
	{
		; Delete the timer if it was called by one
		SetTimer(this.Bound.UpdateStatusBar, "Delete")
		
		; Get the document length and cursor position
		VarSetCapacity(GTL, 8, 0), NumPut(1200, GTL, 4, "UInt")
		Len := this.RichCode.SendMsg(0x45F, &GTL, 0) ; EM_GETTEXTLENGTHEX (Handles newlines better than GuiControlGet on RE)
		ControlGet, Row, CurrentLine,,, % "ahk_id" this.RichCode.hWnd
		ControlGet, Col, CurrentCol,,, % "ahk_id" this.RichCode.hWnd
		
		; Get Selected Text Length
		; If the user has selected 1 char further than the end of the document,
		; which is allowed in a RichEdit control, subtract 1 from the length
		Sel := this.RichCode.Selection
		Sel := Sel[2] - Sel[1] - (Sel[2] > Len)
		
		; Get the syntax tip, if any
		if (SyntaxTip := HelpFile.GetSyntax(this.GetKeywordFromCaret()))
			this.SyntaxTip := SyntaxTip
		
		; Update the Status Bar text
		Gui, % this.hMainWindow ":Default"
		SB_SetText("Len " Len ", Line " Row ", Col " Col
		. (Sel > 0 ? ", Sel " Sel : "") "     " this.SyntaxTip)
		
		; Update the title Bar
		this.UpdateTitle()
		
		; Update the gutter to match the document
		if this.Settings.Gutter.Width
		{
			ControlGet, Lines, LineCount,,, % "ahk_id" this.RichCode.hWnd
			if (Lines != this.LineCount)
			{
				Loop, %Lines%
					Text .= A_Index "`n"
				GuiControl,, % this.hGutter, %Text%
				this.SyncGutter()
				this.LineCount := Lines
			}
		}
	}
	
	UpdateTitle()
	{
		Title := this.Title
		
		; Show the current file name
		if this.FilePath
		{
			SplitPath, % this.FilePath, FileName
			Title .= " - " FileName
		}
		
		; Show the curernt modification status
		if this.RichCode.Modified
			Title .= "*"
		
		; Return if the title doesn't need to be updated
		if (Title == this.VisibleTitle)
			return
		this.VisibleTitle := Title
		
		HiddenWindows := A_DetectHiddenWindows
		DetectHiddenWindows, On
		WinSetTitle, % "ahk_id" this.hMainWindow,, %Title%
		DetectHiddenWindows, %HiddenWindows%
	}
	
	UpdateAutoComplete()
	{
		; Delete the timer if it was called by one
		SetTimer(this.Bound.UpdateAutoComplete, "Delete")
		
		this.AC.BuildWordList()
	}
	
	RegisterCloseCallback(CloseCallback)
	{
		this.CloseCallback := CloseCallback
	}
	
	GuiSize()
	{
		static RECT, _ := VarSetCapacity(RECT, 16, 0)
		if A_Gui
			gw := A_GuiWidth, gh := A_GuiHeight
		else
		{
			DllCall("GetClientRect", "UPtr", this.hMainWindow, "Ptr", &RECT, "UInt")
			gw := NumGet(RECT, 8, "Int"), gh := NumGet(RECT, 12, "Int")
		}
		gtw := 3 + Round(this.Settings.Gutter.Width) * (this.ZoomLevel ? this.ZoomLevel : 1), sbh := this.StatusBarHeight
		GuiControl, Move, % this.RichCode.hWnd, % "x" 0+gtw "y" 0         "w" gw-gtw "h" gh-28-sbh
		if this.Settings.Gutter.Width
			GuiControl, Move, % this.hGutter  , % "x" 0     "y" 0         "w" gtw    "h" gh-28-sbh
		GuiControl, Move, % this.hRunButton   , % "x" 0     "y" gh-28-sbh "w" gw     "h" 28
	}
	
	GuiDropFiles(hWnd, Files)
	{
		; TODO: support multiple file drop
		this.LoadCode(FileOpen(Files[1], "r").Read(), Files[1])
	}
	
	GuiClose()
	{
		if this.RichCode.Modified
		{
			Gui, +OwnDialogs
			MsgBox, 308, % this.Title " - Confirm Exit", There are unsaved changes. Are you sure you want to exit?
			IfMsgBox, No
				return true
		}
		
		if (this.Exec.Status == 0) ; Running
		{
			SetTimer(this.Bound.CheckIfRunning, "Delete")
			this.Exec.Terminate()
		}
		
		; Free up the AC class
		this.AC := ""
		
		; Release wm_message hooks
		for each, Msg in [0x100, 0x201, 0x202, 0x204] ; WM_KEYDOWN, WM_LBUTTONDOWN, WM_LBUTTONUP, WM_RBUTTONDOWN
			OnMessage(Msg, this.Bound.OnMessage, 0)
		
		; Delete timers
		SetTimer(this.Bound.SyncGutter, "Delete")
		SetTimer(this.Bound.GuiSize, "Delete")
		
		; Break all the BoundFunc circular references
		this.Delete("Bound")
		
		; Release WinEvents handler
		WinEvents.Unregister(this.hMainWindow)
		
		; Release GUI window and control glabels
		Gui, Destroy
		
		; Release menu bar (Has to be done after Gui, Destroy)
		for each, MenuName in this.Menus
			Menu, %MenuName%, DeleteAll
		
		this.CloseCallback()
	}
	
	#Include CQT.Paste.ahk
	#Include CQT.Publish.ahk
	#Include CQT.Find.ahk
	#Include CQT.ScriptOpts.ahk
	#Include CQT.MenuButtons.ahk
	#Include CQT.AutoComplete.ahk
}
