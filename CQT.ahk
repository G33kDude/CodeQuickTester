class CodeQuickTester
{
	static Msftedit := DllCall("LoadLibrary", "Str", "Msftedit.dll")
	DefaultPath := "C:\Windows\ShellNew\Template.ahk"
	Title := "CodeQuickTester"
	
	__New()
	{
		; TODO: Settings passed in
		this.DefaultName := "GeekDude"
		this.DefaultDesc := ""
		this.FGColor := 0xCDEDED
		this.BGColor := 0x3F3F3F
		this.TabSize := 4
		this.Indent := "`t"
		this.TypeFace := "Microsoft Sans Serif"
		this.Font := "s8 wNorm"
		this.CodeTypeFace := "Consolas"
		this.CodeFont := "s9 wBold"
		
		this.Shell := ComObjCreate("WScript.Shell")
		
		this.Bound := []
		this.Bound.RunButton := this.RunButton.Bind(this)
		this.Bound.OnMessage := this.OnMessage.Bind(this)
		this.Bound.UpdateStatusBar := this.UpdateStatusBar.Bind(this)
		this.Bound.CheckIfRunning := this.CheckIfRunning.Bind(this)
		
		Buttons := new this.MenuButtons(this)
		Menus :=
		( Join
		[
			["&File", [
				["&Save`tCtrl+S", Buttons.Save.Bind(Buttons)],
				["&Open`tCtrl+O", Buttons.Open.Bind(Buttons)],
				["&New`tCtrl+N", Buttons.New.Bind(Buttons)],
				["&Fetch", Buttons.Fetch.Bind(Buttons)]
			]], ["&Tools", [
				["&Paste`tCtrl+P", Buttons.Paste.Bind(Buttons)],
				["Re&indent`tCtrl+I", Buttons.Indent.Bind(Buttons)],
				["Parameters", Buttons.Params.Bind(Buttons)],
				["Install", Buttons.Install.Bind(Buttons)]
			]], ["&Help", [
				["Open &Help File`tCtrl+H", Buttons.Help.Bind(Buttons)],
				["&About", Buttons.About.Bind(Buttons)]
			]]
		]
		)
		
		Gui, New, +Resize +hWndhMainWindow
		this.hMainWindow := hMainWindow
		this.Menus := this.CreateMenuBar(Menus)
		Gui, Menu, % this.Menus[1]
		Gui, Margin, 5, 5
		
		; Add code editor
		Gui, Font, % this.CodeFont, % this.CodeTypeFace
		this.InitRichEdit()
		Gui, Font, % this.Font, % this.TypeFace
		
		; Get starting tester contents
		FilePath := B_Params[1] ? RegExReplace(B_Params[1], "^ahk:") : this.DefaultPath
		this.Code := FileExist(FilePath) ? FileOpen(FilePath, "r").Read() : UrlDownloadToVar(FilePath)
		if (FilePath == this.DefaultPath)
			SendMessage, 0x0B1, -1, -1,, % "ahk_id" this.hCodeEditor ; EM_SETSEL bottom of document
		
		; Add run button
		Gui, Add, Button, hWndhRunButton, &Run
		this.hRunButton := hRunButton
		BoundFunc := this.Bound.RunButton
		GuiControl, +g, %hRunButton%, %BoundFunc%
		
		; Add status bar
		Gui, Add, StatusBar
		SB_SetParts(70, 70, 70)
		this.UpdateStatusBar()
		
		; Register for events
		WinEvents.Register(this.hMainWindow, this)
		for each, Msg in [0x100, 0x201, 0x202, 0x204] ; WM_KEYDOWN, WM_LBUTTONDOWN, WM_LBUTTONUP, WM_RBUTTONDOWN
			OnMessage(Msg, this.Bound.OnMessage)
		
		Gui, Show, w640 h480, % this.Title
	}
	
	InitRichEdit()
	{
		Gui, Add, Custom, ClassRichEdit50W hWndhCodeEditor +0x5031b1c4 +E0x20000
		this.hCodeEditor := hCodeEditor
		
		; Set background color
		SendMessage, 0x443, 0, this.BGColor,, ahk_id %hCodeEditor% ; EM_SETBKGNDCOLOR
		
		; Set FG color
		VarSetCapacity(CharFormat, 116, 0)
		NumPut(116, CharFormat, 0, "UInt") ; cbSize := sizeOf(CHARFORMAT2)
		NumPut(0x40000000, CharFormat, 4, "UInt") ; dwMask := CFM_COLOR
		NumPut(this.FGColor, CharFormat, 20, "UInt") ; crTextColor := 0xBBGGRR
		SendMessage, 0x444, 0, &CharFormat,, ahk_id %hCodeEditor% ; EM_SETCHARFORMAT
		
		; Set tab size to 4
		VarSetCapacity(TabStops, 4, 0), NumPut(this.TabSize*4, TabStops, "UInt")
		SendMessage, 0x0CB, 1, &TabStops,, ahk_id %hCodeEditor% ; EM_SETTABSTOPS
		
		; Change text limit from 32,767 to max
		SendMessage, 0x435, 0, -1,, ahk_id %hCodeEditor% ; EM_EXLIMITTEXT
		
		; Disable inconsistent formatting
		SendMessage, 0x4CC, 1, 1,, ahk_id %hCodeEditor% ; EM_SETEDITSTYLE SES_EMULATESYSEDIT
	}
	
	Code[]
	{
		get {
			GuiControlGet, CodeEditor,, % this.hCodeEditor
			return CodeEditor
		}
		
		set {
			GuiControl,, % this.hCodeEditor, %Value%
			return Value
		}
	}
	
	CreateMenuBar(Menu)
	{
		static MenuName := 0
		Menus := ["CQT_" MenuName++]
		for each, Item in Menu
		{
			Ref := Item[2]
			if IsObject(Ref) && Ref._NewEnum()
			{
				SubMenus := this.CreateMenuBar(Ref)
				Menus.Push(SubMenus*), Ref := ":" SubMenus[1]
			}
			Menu, % Menus[1], Add, % Item[1], %Ref%
		}
		return Menus
	}
	
	RunButton()
	{
		if (this.Exec.Status == 0) ; Running
			this.Exec.Terminate() ; CheckIfRunning updates the GUI
		else ; Not running or doesn't exist
		{
			; GuiControlGet, Params, Params:
			
			Code := this.Code ; A temp var to avoid duplication of GuiControlGet
			this.Exec := ExecScript(Code, "", DeHashBang(Code)) ; TODO: Implement Params
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
	
	LoadCode(Code)
	{
		GuiControlGet, CodeEditor,, % this.hCodeEditor
		if (CodeEditor && CodeEditor != Code) ; TODO: Do I need to Trim() here?
		{
			MsgBox, 308, %Title%, Are you sure you want to overwrite your code?
			IfMsgBox, No
				return
		}
		this.Code := Code, this.UpdateStatusBar()
	}
	
	OnMessage(wParam, lParam, Msg, hWnd)
	{
		if (hWnd == this.hCodeEditor)
		{
			if (Msg == 0x100 && Chr(wParam) == "`t")
			{
				ControlGet, Selected, Selected,,, % "ahk_id" this.hCodeEditor
				if (Selected == "")
					SendMessage, 0xC2, 1, &(x:="`t"),, % "ahk_id" this.hCodeEditor ; EM_REPLACESEL
				this.UpdateStatusBar()
				return False
			}
			
			; Call UpdateStatusBar after the edit handles the keystroke
			SetTimer(this.Bound.UpdateStatusBar, -0)
			return
		}
	}
	
	UpdateStatusBar()
	{
		; Delete the timer if it was called by one
		SetTimer(this.Bound.UpdateStatusBar, "Delete")
		
		hCodeEditor := this.hCodeEditor
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
		
		VarSetCapacity(s, 8, 0)
		SendMessage, 0x0B0, &s+0, &s+4,, ahk_id %hCodeEditor% ; EM_GETSEL
		Left := NumGet(s, 0, "UInt"), Right := NumGet(s, 4, "UInt")
		Len := Right - Left - (Right > Len) ; > is a workaround for being able to select the end of the document with RE
		SB_SetText(Len > 0 ? "Selection Length: " Len : "", 4) ; >0 because sometimes it comes up as -1 if you hold down paste
	}
	
	RegisterCloseCallback(CloseCallback)
	{
		this.CloseCallback := CloseCallback
	}
	
	GuiSize()
	{
		GuiControl, Move, % this.hCodeEditor, % "x" 5 "y" 5 "w" A_GuiWidth-10 "h" A_GuiHeight-60
		GuiControl, Move, % this.hRunButton, % "x" 5 "y" A_GuiHeight-50 "w" A_GuiWidth-10 "h" 22
	}
	
	GuiClose()
	{
		; TODO: Finish auto-script-kill
		if (this.Exec.Status == 0) ; Runnning
		{
			SetTimer(this.Bound.CheckIfRunning, "Delete")
			this.Exec.Terminate()
		}
		
		; Relase wm_message hooks
		for each, Msg in [0x100, 0x201, 0x202, 0x204] ; WM_KEYDOWN, WM_LBUTTONDOWN, WM_LBUTTONUP, WM_RBUTTONDOWN
			OnMessage(Msg, this.Bound.OnMessage, 0)
		
		; Break all the BoundFunc circular references
		this.Delete("Bound")
		
		; Release WinEvents handler
		WinEvents.Unregister(this.hMainWindow)
		
		; Relase GUI window and control glabels
		GuiControl, -g, % this.hRunButton ; TODO: Remove once -g bug is fixed
		Gui, Destroy
		
		; Release menu bar (Has to be done after Gui, Destroy)
		for each, MenuName in this.Menus
			Menu, %MenuName%, DeleteAll
		
		this.CloseCallback()
	}
	
	#Include CQT.Paste.ahk
	#Include CQT.MenuButtons.ahk
}
