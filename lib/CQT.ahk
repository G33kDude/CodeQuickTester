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
		Gui, Margin, 5, 5
		
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
		this.RichCode := new RichCode(this.Settings)
		if Settings.GutterWidth
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
		
		; Add run button
		Gui, Add, Button, hWndhRunButton, &Run
		this.hRunButton := hRunButton
		BoundFunc := this.Bound.RunButton
		GuiControl, +g, %hRunButton%, %BoundFunc%
		
		; Add status bar
		Gui, Add, StatusBar
		SB_SetParts(70, 70, 60, 70)
		this.UpdateStatusBar()
		
		; Initialize the AutoComplete
		this.AC := new this.AutoComplete(this, this.settings.UseAutoComplete)
		
		this.UpdateTitle()
		Gui, Show, w640 h480
	}
	
	AddGutter()
	{
		s := this.Settings, f := s.Font
		
		; Add the RichEdit control for the gutter
		Gui, Add, Custom, ClassRichEdit50W hWndhGutter +0x5031b1c4 +E0x20000 +HScroll -VScroll
		this.hGutter := hGutter
		
		; Set the background and font settings
		FGColor := RichCode.BGRFromRGB(s.FGColor)
		BGColor := RichCode.BGRFromRGB(s.BGColor)
		VarSetCapacity(CF2, 116, 0)
		NumPut(116,        &CF2+ 0, "UInt") ; cbSize      = sizeof(CF2)
		NumPut(0xE<<28,    &CF2+ 4, "UInt") ; dwMask      = CFM_COLOR|CFM_FACE|CFM_SIZE
		NumPut(f.Size*20,  &CF2+12, "UInt") ; yHeight     = twips
		NumPut(FGColor,    &CF2+20, "UInt") ; crTextColor = 0xBBGGRR
		StrPut(f.Typeface, &CF2+26, 32, "UTF-16") ; szFaceName = TCHAR
		SendMessage(0x444, 0, &CF2,    hGutter) ; EM_SETCHARFORMAT
		SendMessage(0x443, 0, BGColor, hGutter) ; EM_SETBKGNDCOLOR
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
		CodeEditor := this.RichCode.Value
		if (CodeEditor && CodeEditor != Code) ; TODO: Do I need to Trim() here?
		{
			Gui, +OwnDialogs
			MsgBox, 308, % this.Title " - Confirm Overwrite", Are you sure you want to overwrite your code?
			IfMsgBox, No
				return
		}
		
		; Keep track of the file currently being edited
		this.FilePath := FilePath
		
		; Update the GUI
		this.RichCode.Value := Code
		this.RichCode.Modified := False
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
		static POINT := 0, _ := VarSetCapacity(POINT, 8, 0)
		
		if !this.Settings.GutterWidth
			return
		
		SendMessage(0x4DD, 0, &POINT, this.RichCode.hwnd) ; EM_GETSCROLLPOS
		PostMessage(0x4DE, 0, &POINT, this.hGutter)       ; EM_SETSCROLLPOS
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
		
		hCodeEditor := this.RichCode.hWnd
		hMainWindow := this.hMainWindow
		Gui, %hMainWindow%:Default
		
		VarSetCapacity(GTL, 8, 0), NumPut(1200, GTL, 4, "UInt")
		SendMessage, 0x45F, &GTL, 0,, ahk_id %hCodeEditor% ; EM_GETTEXTLENGTHEX (Handles newlines better than GuiControlGet on RE)
		Len := ErrorLevel
		
		ControlGet, Row, CurrentLine,,, ahk_id %hCodeEditor%
		ControlGet, Col, CurrentCol,,, ahk_id %hCodeEditor%
		SB_SetText("Len " Len, 1)
		SB_SetText("Line " Row, 2)
		SB_SetText("Col " Col, 3)
		
		Selection := this.RichCode.Selection
		; If the user has selected 1 char further than the end of the document,
		; which is allowed in a RichEdit control, subtract 1 from the length
		Len := Selection[2] - Selection[1] - (Selection[2] > Len)
		SB_SetText("Sel: " (Len > 0 ? Len : 0), 4) ; >0 because sometimes it comes up as -1 if you hold down paste
		
		this.UpdateTitle()
		
		if (Syntax := HelpFile.GetSyntax(this.GetKeywordFromCaret()))
			SB_SetText(Syntax, 5)

		if this.Settings.GutterWidth
		{
			ControlGet, Lines, LineCount,,, ahk_id %hCodeEditor%
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
		gw := A_GuiWidth, gh := A_GuiHeight, gtw := Round(this.Settings.GutterWidth)
		GuiControl, Move, % this.RichCode.hWnd, % "x" 5+gtw "y" 5     "w" gw-10-gtw "h" gh-60
		if this.Settings.GutterWidth
			GuiControl, Move, % this.hGutter  , % "x" 5     "y" 5     "w" gtw       "h" gh-60
		GuiControl, Move, % this.hRunButton   , % "x" 5     "y" gh-50 "w" gw-10     "h" 22
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
