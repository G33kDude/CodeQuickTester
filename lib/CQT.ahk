class CodeQuickTester
{
	static Msftedit := DllCall("LoadLibrary", "Str", "Msftedit.dll")
	DefaultPath := "C:\Windows\ShellNew\Template.ahk"
	Title := "CodeQuickTester"
	
	__New(Settings)
	{
		this.Settings := Settings
		
		this.Shell := ComObjCreate("WScript.Shell")
		
		this.Bound := []
		this.Bound.RunButton := this.RunButton.Bind(this)
		this.Bound.OnMessage := this.OnMessage.Bind(this)
		this.Bound.UpdateStatusBar := this.UpdateStatusBar.Bind(this)
		this.Bound.CheckIfRunning := this.CheckIfRunning.Bind(this)
		this.Bound.Highlight := this.Highlight.Bind(this)
		
		Buttons := new this.MenuButtons(this)
		this.Bound.Indent := Buttons.Indent.Bind(Buttons)
		this.Bound.Unindent := Buttons.Unindent.Bind(Buttons)
		Menus :=
		( Join
		[
			["&File", [
				["&Run`tF5", this.Bound.RunButton],
				["&Save`tCtrl+S", Buttons.Save.Bind(Buttons)],
				["&Open`tCtrl+O", Buttons.Open.Bind(Buttons)],
				["&New`tCtrl+N", Buttons.New.Bind(Buttons)],
				["&Publish", Buttons.Publish.Bind(Buttons)],
				["&Fetch", Buttons.Fetch.Bind(Buttons)]
			]], ["&Edit", [
				["Comment Lines`tCtrl+k", Buttons.Comment.Bind(Buttons)],
				["Uncomment Lines`tCtrl+Shift+k", Buttons.Uncomment.Bind(Buttons)],
				["Indent Lines", this.Bound.Indent],
				["Unindent Lines", this.Bound.Unindent]
			]], ["&Tools", [
				["&Pastebin`tCtrl+P", Buttons.Paste.Bind(Buttons)],
				["Re&indent`tCtrl+I", Buttons.AutoIndent.Bind(Buttons)],
				["&AlwaysOnTop`tAlt+A", Buttons.ToggleOnTop.Bind(Buttons)],
				["&Highlighter", Buttons.Highlighter.Bind(Buttons)],
				["Parameters", Buttons.Params.Bind(Buttons)],
				["Install", Buttons.Install.Bind(Buttons)]
			]], ["&Help", [
				["Open &Help File`tCtrl+H", Buttons.Help.Bind(Buttons)],
				["&About", Buttons.About.Bind(Buttons)]
			]]
		]
		)
		
		Gui, New, +Resize +hWndhMainWindow -AlwaysOnTop
		this.AlwaysOnTop := False
		this.hMainWindow := hMainWindow
		this.Menus := this.CreateMenuBar(Menus)
		Gui, Menu, % this.Menus[1]
		Gui, Margin, 5, 5
		
		; If set as default, check the highlighter option
		if this.Settings.UseHighlighter
			Menu, % this.Menus[4], Check, &Highlighter
		
		; Add code editor
		Gui, Font
		, % "s" this.Settings.CodeFont.Size
		. " w" (this.Settings.CodeFont.Bold ? "Bold" : "Norm")
		, % this.Settings.CodeFont.Typeface
		this.InitRichEdit()
		Gui, Font
		, % "s" this.Settings.Font.Size
		. " w" (this.Settings.Font.Bold ? "Bold" : "Norm")
		, % this.Settings.Font.Typeface
		
		; Get starting tester contents
		FilePath := B_Params[1] ? RegExReplace(B_Params[1], "^ahk:") : this.DefaultPath
		try
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
		Settings := this.Settings
		Gui, Add, Custom, ClassRichEdit50W hWndhCodeEditor +0x5031b1c4 +E0x20000
		this.hCodeEditor := hCodeEditor
		
		; Set background color
		SendMessage, 0x443, 0, Settings.BGColor,, ahk_id %hCodeEditor% ; EM_SETBKGNDCOLOR
		
		; Set FG color
		VarSetCapacity(CharFormat, 116, 0)
		NumPut(116, CharFormat, 0, "UInt") ; cbSize := sizeOf(CHARFORMAT2)
		NumPut(0x40000000, CharFormat, 4, "UInt") ; dwMask := CFM_COLOR
		NumPut(Settings.FGColor, CharFormat, 20, "UInt") ; crTextColor := 0xBBGGRR
		SendMessage, 0x444, 0, &CharFormat,, ahk_id %hCodeEditor% ; EM_SETCHARFORMAT
		
		; Set tab size to 4 for non-highlighted code
		VarSetCapacity(TabStops, 4, 0), NumPut(Settings.TabSize*4, TabStops, "UInt")
		SendMessage, 0x0CB, 1, &TabStops,, ahk_id %hCodeEditor% ; EM_SETTABSTOPS
		
		; Change text limit from 32,767 to max
		SendMessage, 0x435, 0, -1,, ahk_id %hCodeEditor% ; EM_EXLIMITTEXT
	}
	
	Code[]
	{
		get {
			GuiControlGet, CodeEditor,, % this.hCodeEditor
			return CodeEditor
		}
		
		set {
			; TODO: Make more efficient by sending text directly to highlighter
			GuiControl,, % this.hCodeEditor, %Value%
			this.Highlight()
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
		CodeEditor := this.Code
		if (CodeEditor && CodeEditor != Code) ; TODO: Do I need to Trim() here?
		{
			Gui, +OwnDialogs
			MsgBox, 308, % this.Title " - Confirm Overwrite", Are you sure you want to overwrite your code?
			IfMsgBox, No
				return
		}
		this.Code := Code
		this.UpdateStatusBar()
	}
	
	OnMessage(wParam, lParam, Msg, hWnd)
	{
		if (hWnd == this.hCodeEditor)
		{
			if (Msg == 0x100) ; WM_KEYDOWN
			{
				if (wParam == GetKeyVK("Tab"))
				{
					ControlGet, Selected, Selected,,, % "ahk_id" this.hCodeEditor
					if (Selected == "" && !GetKeyState("Shift"))
						SendMessage, 0xC2, 1, &(x:="`t"),, % "ahk_id" this.hCodeEditor ; EM_REPLACESEL
					else if GetKeyState("Shift")
						this.Bound.Unindent()
					else
						this.Bound.Indent()
					this.UpdateStatusBar()
					return False
				}
				else if (wParam == GetKeyVK("Escape"))
					return False
				else if (wParam == GetKeyVK("v") && GetKeyState("Ctrl"))
				{
					SendMessage, 0xC2, 1, &(x:=Clipboard),, % "ahk_id" this.hCodeEditor ; EM_REPLACESEL
					return False
				}
			}
			
			; Call UpdateStatusBar after the edit handles the keystroke
			SetTimer(this.Bound.UpdateStatusBar, -0)
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
		
		SetTimer(this.Bound.Highlight, -200)
	}
	
	Highlight()
	{
		if !this.Settings.UseHighlighter
			return
		
		hCodeEditor := this.hCodeEditor
		
		; Buffer any input events while the highlighter is running
		Crit := A_IsCritical
		Critical, 1000
		
		; Run the highlighter
		Text := Highlight(this.Code, this.Settings)
		
		; "TRichEdit suspend/resume undo function"
		; https://stackoverflow.com/a/21206620
		
		; Get the ITextDocument object
		EM_GETOLEINTERFACE:=(0x400 + 60)
		VarSetCapacity(pIRichEditOle, A_PtrSize, 0)
		SendMessage, EM_GETOLEINTERFACE, 0, &pIRichEditOle,, ahk_id %hCodeEditor%
		pIRichEditOle := NumGet(pIRichEditOle, 0, "UPtr")
		IID_ITextDocument := "{8CC497C0-A1DF-11CE-8098-00AA0047BE5D}"
		IRichEditOle := ComObject(9, pIRichEditOle, 1), ObjAddRef(pIRichEditOle)
		pITextDocument := ComObjQuery(IRichEditOle, IID_ITextDocument)
		ITextDocument := ComObject(9, pITextDocument, 1), ObjAddRef(pITextDocument)
		
		; Freeze the renderer and suspend the undo buffer
		ITextDocument.Freeze()
		ITextDocument.Undo(-9999995) ; tomSuspend
		
		; Save the text to a UTF-8 buffer
		VarSetCapacity(Buf, StrPut(Text, "UTF-8"), 0)
		StrPut(Text, &Buf, "UTF-8")
		
		; Set up the necessary structs
		VarSetCapacity(POINT    , 8, 0) ; Scroll position
		VarSetCapacity(CHARRANGE, 8, 0) ; Selection
		VarSetCapacity(SETTEXTEX, 8, 0) ; SetText Settings
		NumPut(1, SETTEXTEX, 0, "UInt") ; flags = ST_KEEPUNDO
		
		; Save the scroll and cursor positions, update the text,
		; then restore the scroll and cursor positions
		SendMessage, 0x4DD, 0, &POINT,, ahk_id %hCodeEditor% ; EM_GETSCROLLPOS
		SendMessage, 0x434, 0, &CHARRANGE,, ahk_id %hCodeEditor% ; EM_EXGETSEL
		SendMessage, 0x461, &SETTEXTEX, &Buf,, ahk_id %hCodeEditor% ; EM_SETTEXTEX
		SendMessage, 0x437, 0, &CHARRANGE,, ahk_id %hCodeEditor% ; EM_EXSETSEL
		SendMessage, 0x4DE, 0, &POINt,, ahk_id %hCodeEditor% ; EM_SETSCROLLPOS
		
		; Resume the undo buffer and unfreeze the renderer
		ITextDocument.Undo(-9999994) ; tomResume
		ITextDocument.Unfreeze()
		
		; Release the ITextDocument object
		ITextDocument := "", IRichEditOle := ""
		ObjRelease(pIRichEditOle), ObjRelease(pITextDocument)
		
		; Resume event processing
		Critical, %Crit%
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
	
	GuiDropFiles(hWnd, Files)
	{
		; TODO: support multiple file drop
		this.LoadCode(FileOpen(Files[1], "r").Read())
	}
	
	GuiClose()
	{
		if Trim(this.Code, " `t`r`n") ; TODO: Check against last saved code
		{
			Gui, +OwnDialogs
			MsgBox, 308, % this.Title " - Confirm Exit", Are you sure you want to exit?
			IfMsgBox, No
				return true
		}
		
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
