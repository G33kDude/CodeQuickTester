#SingleInstance, Off
#NoEnv
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%

global B_Params := []
Loop, %0%
	B_Params.Push(%A_Index%)

Menu, Tray, Icon, %A_AhkPath%, 2
FileEncoding, UTF-8

; TODO: Figure out why it gets sometimes gets stuck on "Kill" when using MultiTester
; TODO: Add right click menu
; TODO: Add params menu

Settings := {"DefaultName": "GeekDude"
, "DefaultDesc": ""
, "FGColor": 0xCDEDED
, "BGColor": 0x3F3F3F
, "TabSize": 4
, "Indent": "`t"
, "TypeFace": "Microsoft Sans Serif"
, "Font": "s8 wNorm"
, "CodeTypeFace": "Consolas"
, "CodeFont": "s9 wBold"}

Tester := new CodeQuickTester(Settings)
Tester.RegisterCloseCallback(Func("TesterClose"))
return

#If Tester.Exec.Status == 0 ; Running
~*Escape::Tester.Exec.Terminate()
#If

TesterClose(Tester)
{
	ExitApp
}

/* MultiTester
	ScriptPID := DllCall("GetCurrentProcessId")
	Testers := []
	Testers[new CodeQuickTester()] := True
	return
	
	#If WinActive("ahk_pid" ScriptPID)
	^n::Testers[new CodeQuickTester()] := True
	#If
	
	~*Escape::
	for Tester in Testers
		Tester.Exec.Terminate()
	return
*/

#Include %A_ScriptDir%
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
		
		Buttons := new this.MenuButtons(this)
		Menus :=
		( Join
		[
			["&File", [
				["&Run`tF5", this.Bound.RunButton],
				["&Save`tCtrl+S", Buttons.Save.Bind(Buttons)],
				["&Open`tCtrl+O", Buttons.Open.Bind(Buttons)],
				["&New`tCtrl+N", Buttons.New.Bind(Buttons)],
				["&Fetch", Buttons.Fetch.Bind(Buttons)]
			]], ["&Tools", [
				["&Paste`tCtrl+P", Buttons.Paste.Bind(Buttons)],
				["Re&indent`tCtrl+I", Buttons.Indent.Bind(Buttons)],
				["&AlwaysOnTop`tAlt+A", Buttons.ToggleOnTop.Bind(Buttons)],
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
		
		; Add code editor
		Gui, Font, % this.Settings.CodeFont, % this.Settings.CodeTypeFace
		this.InitRichEdit()
		Gui, Font, % this.Settings.Font, % this.Settings.TypeFace
		
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
		
		; Set tab size to 4
		VarSetCapacity(TabStops, 4, 0), NumPut(Settings.TabSize*4, TabStops, "UInt")
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
					if (Selected == "")
						SendMessage, 0xC2, 1, &(x:="`t"),, % "ahk_id" this.hCodeEditor ; EM_REPLACESEL
					this.UpdateStatusBar()
					return False
				}
				else if (wParam == GetKeyVK("Escape"))
					return False
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
	
	GuiDropFiles(Files)
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
	
	class Paste
{
	__New(Parent)
	{
		this.Parent := Parent
		
		ParentWnd := this.Parent.hMainWindow
		Gui, New, +Owner%ParentWnd% +ToolWindow +hWndhWnd
		this.hWnd := hWnd
		Gui, Margin, 5, 5
		Gui, Font, % this.Parent.Settings.Font, % this.Parent.Settings.TypeFace
		
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
		
		Gui, Add, ComboBox, x+5 yp w75 hWndhPasteChan, Announce||#ahk|#ahkscript
		this.hPasteChan := hPasteChan
		
		PostMessage, 0x153, -1, 22-6,, ahk_id %hPasteChan% ; Set height of ComboBox
		Gui, Show,, % this.Parent.Title " - Paste"
		
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
		
		Link := Ahkbin(this.Parent.Code, PasteName, PasteDesc, PasteChan)
		
		MsgBox, 292, % this.Parent.Title " - Pasted", Link received:`n%Link%`n`nCopy to clipboard?
		IfMsgBox, Yes
			Clipboard := Link
	}
}

	class MenuButtons
{
	__New(Parent)
	{
		this.Parent := Parent
	}
	
	Save()
	{
		Gui, +OwnDialogs
		FileSelectFile, FilePath, S18,, % this.Parent.Title " - Save Code"
		if ErrorLevel
			return
		
		FileOpen(FilePath, "w").Write(this.Parent.Code)
	}
	
	Open()
	{
		Gui, +OwnDialogs
		FileSelectFile, FilePath, 3,, % this.Parent.Title " - Open Code"
		if !ErrorLevel
			this.Parent.LoadCode(FileOpen(FilePath, "r").Read())
	}
	
	New() ; TODO: Make this work for MultiTester mode
	{
		Run, %A_AhkPath% %A_ScriptFullPath%
	}
	
	Fetch()
	{
		Gui, +OwnDialogs
		InputBox, Url, % this.Parent.Title " - Fetch Code", Enter a URL to fetch code from.
		if (Url := Trim(Url))
			this.Parent.LoadCode(UrlDownloadToVar(Url))
	}
	
	Paste()
	{ ; TODO: Recycle PasteInstance
		if WinExist("ahk_id" this.PasteInstance.hWnd)
			WinActivate, % "ahk_id" this.PasteInstance.hWnd
		else
			this.PasteInstance := new this.Parent.Paste(this.Parent)
	}
	
	Params()
	{
		; TODO
	}
	
	ToggleOnTop()
	{
		if (this.Parent.AlwaysOnTop := !this.Parent.AlwaysOnTop)
		{
			Menu, % this.Parent.Menus[3], Check, &AlwaysOnTop`tAlt+A
			Gui, +AlwaysOnTop
		}
		else
		{
			Menu, % this.Parent.Menus[3], Uncheck, &AlwaysOnTop`tAlt+A
			Gui, -AlwaysOnTop
		}
	}
	
	Indent()
	{
		this.Parent.LoadCode(AutoIndent(this.Parent.Code, this.Parent.Settings.Indent))
	}
	
	Help()
	{
		Run, %A_AhkPath%\..\AutoHotkey.chm
	}
	
	About()
	{
		Gui, +OwnDialogs
		MsgBox,, % this.Parent.Title " - About", CodeQuickTester written by GeekDude
	}
	
	Install()
	{
		Gui, +OwnDialogs
		if ServiceHandler.Installed()
		{
			MsgBox, 36, % this.Parent.Title " - Uninstall Service Handler"
			, Are you sure you want to remove CodeQuickTester from being the default service handler for "ahk:" links?
			IfMsgBox, Yes
				ServiceHandler.Remove()
		}
		else
		{
			MsgBox, 36, % this.Parent.Title " - Install Service Handler"
			, Are you sure you want to install CodeQuickTester as the default service handler for "ahk:" links?
			IfMsgBox, Yes
				ServiceHandler.Install()
		}
	}
}

}

class ServiceHandler ; static class
{
	static Protocol := "ahk"
	
	Install()
	{
		Protocol := this.Protocol
		RegWrite, REG_SZ, HKCU, Software\Classes\%Protocol%,, URL:AHK Script Protocol
		RegWrite, REG_SZ, HKCU, Software\Classes\%Protocol%, URL Protocol
		RegWrite, REG_SZ, HKCU, Software\Classes\%Protocol%\shell\open\command,, "%A_AhkPath%" "%A_ScriptFullPath%" "`%1"
	}
	
	Remove()
	{
		Protocol := this.Protocol
		RegDelete, HKCU, Software\Classes\%Protocol%
	}
	
	Installed()
	{
		Protocol := this.Protocol
		RegRead, Out, HKCU, Software\Classes\%Protocol%
		return !ErrorLevel
	}
}

class WinEvents ; static class
{
	static Table := {}
	
	Register(hWnd, Class, Prefix="Gui")
	{
		Gui, +LabelWinEvents.
		this.Table[hWnd] := {Class: Class, Prefix: Prefix}
	}
	
	Unregister(hWnd)
	{
		this.Table.Delete(hWnd)
	}
	
	Dispatch(hWnd, Type, Params*)
	{
		Info := this.Table[hWnd]
		
		; TODO: Figure out the most efficient way to do [a,b*]*
		return Info.Class[Info.Prefix . Type].Call([Info.Class, Params*]*)
	}
	
	; These *CANNOT* be added dynamically or handled dynamically via __Call
	Close(Params*)
	{
		return WinEvents.Dispatch(this, "Close", Params*)
	}
	
	Escape(Params*)
	{
		return WinEvents.Dispatch(this, "Escape", Params*)
	}
	
	Size(Params*)
	{
		return WinEvents.Dispatch(this, "Size", Params*)
	}
	
	ContextMenu(Params*)
	{
		return WinEvents.Dispatch(this, "ContextMenu", Params*)
	}
	
	DropFiles(Params*)
	{
		return WinEvents.Dispatch(this, "DropFiles", Params*)
	}
}

AutoIndent(Code, Indent = "`t", Newline = "`r`n")
{
	IndentRegEx =
	( LTrim Join
	Catch|else|for|Finally|if|IfEqual|IfExist|
	IfGreater|IfGreaterOrEqual|IfInString|
	IfLess|IfLessOrEqual|IfMsgBox|IfNotEqual|
	IfNotExist|IfNotInString|IfWinActive|IfWinExist|
	IfWinNotActive|IfWinNotExist|Loop|Try|while
	)
	
	; Lock and Block are modified ByRef by Current
	Lock := [], Block := []
	ParentIndent := Braces := 0
	ParentIndentObj := []
	
	for each, Line in StrSplit(Code, "`n", "`r")
	{
		Text := Trim(RegExReplace(Line, "\s;.*")) ; Comment removal
		First := SubStr(Text, 1, 1), Last := SubStr(Text, 0, 1)
		FirstTwo := SubStr(Text, 1, 2)
		
		IsExpCont := (Text ~= "i)^\s*(&&|OR|AND|\.|\,|\|\||:|\?)")
		IndentCheck := (Text ~= "iA)}?\s*\b(" IndentRegEx ")\b")
		
		if (First == "(" && Last != ")")
			Skip := True
		if (Skip)
		{
			if (First == ")")
				Skip := False
			Out .= Newline . RTrim(Line)
			continue
		}
		
		if (FirstTwo == "*/")
			Block := [], ParentIndent := 0
		
		if Block.MinIndex()
			Current := Block, Cur := 1
		else
			Current := Lock, Cur := 0
		
		; Round converts "" to 0
		Braces := Round(Current[Current.MaxIndex()].Braces)
		ParentIndent := Round(ParentIndentObj[Cur])
		
		if (First == "}")
		{
			while ((Found := SubStr(Text, A_Index, 1)) ~= "}|\s")
			{
				if (Found ~= "\s")
					continue
				if (Cur && Current.MaxIndex() <= 1)
					break
				Special := Current.Pop().Ind, Braces--
			}
		}
		
		if (First == "{" && ParentIndent)
			ParentIndent--
		
		Out .= Newline
		Loop, % Special ? Special-1 : Round(Current[Current.MaxIndex()].Ind) + Round(ParentIndent)
			Out .= Indent
		Out .= Trim(Line)
		
		if (FirstTwo == "/*")
		{
			if (!Block.MinIndex())
			{
				Block.Push({ParentIndent: ParentIndent
				, Ind: Round(Lock[Lock.MaxIndex()].Ind) + 1
				, Braces: Round(Lock[Lock.MaxIndex()].Braces) + 1})
			}
			Current := Block, ParentIndent := 0
		}
		
		if (Last == "{")
		{
			Braces++, ParentIndent := (IsExpCont && Last == "{") ? ParentIndent-1 : ParentIndent
			Current.Push({Braces: Braces
			, Ind: ParentIndent + Round(Current[Current.MaxIndex()].ParentIndent) + Braces
			, ParentIndent: ParentIndent + Round(Current[Current.MaxIndex()].ParentIndent)})
			ParentIndent := 0
		}
		
		if ((ParentIndent || IsExpCont || IndentCheck) && (IndentCheck && Last != "{"))
			ParentIndent++
		if (ParentIndent > 0 && !(IsExpCont || IndentCheck))
			ParentIndent := 0
		
		ParentIndentObj[Cur] := ParentIndent
		Special := 0
	}
	
	if Braces
		throw Exception("Segment Open!")
	
	return SubStr(Out, StrLen(Newline)+1)
}

; Modified from https://github.com/cocobelgica/AutoHotkey-Util/blob/master/ExecScript.ahk
ExecScript(Script, Params="", AhkPath="")
{
	Name := "AHK_CQT_" A_TickCount
	Pipe := []
	Loop, 2
	{
		Pipe[A_Index] := DllCall("CreateNamedPipe"
		, "Str", "\\.\pipe\" name
		, "UInt", 2, "UInt", 0
		, "UInt", 255, "UInt", 0
		, "UInt", 0, "UPtr", 0
		, "UPtr", 0, "UPtr")
	}
	if !FileExist(AhkPath)
		throw Exception("AutoHotkey runtime not found: " AhkPath)
	Call = "%AhkPath%" /CP65001 "\\.\pipe\%Name%"
	Shell := ComObjCreate("WScript.Shell")
	Exec := Shell.Exec(Call " " Params)
	DllCall("ConnectNamedPipe", "UPtr", Pipe[1], "UPtr", 0)
	DllCall("CloseHandle", "UPtr", Pipe[1])
	DllCall("ConnectNamedPipe", "UPtr", Pipe[2], "UPtr", 0)
	FileOpen(Pipe[2], "h", "UTF-8").Write(Script)
	DllCall("CloseHandle", "UPtr", Pipe[2])
	return Exec
}

DeHashBang(Script)
{
	AhkPath := A_AhkPath
	if RegExMatch(Script, "`a)^\s*`;#!\s*(.+)", Match)
	{
		AhkPath := Trim(Match1)
		Vars := {"%A_ScriptDir%": A_WorkingDir
		, "%A_WorkingDir%": A_WorkingDir
		, "%A_AppData%": A_AppData
		, "%A_AppDataCommon%": A_AppDataCommon
		, "%A_LineFile%": A_ScriptFullPath
		, "%A_AhkPath%": A_AhkPath
		, "%A_AhkDir%": A_AhkPath "\.."}
		for SearchText, Replacement in Vars
			StringReplace, AhkPath, AhkPath, %SearchText%, %Replacement%, All
	}
	return AhkPath
}

UrlDownloadToVar(Url)
{
	http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	http.Open("GET", Url, false), http.Send()
	return http.ResponseText
}

; Helper function, to make passing in expressions resulting in function objects easier
SetTimer(Label, Period)
{
	SetTimer, %Label%, %Period%
}

SendMessage(Msg, wParam, lParam, hWnd)
{
	; DllCall("SendMessage", "UPtr", hWnd, "UInt", Msg, "UPtr", wParam, "Ptr", lParam, "UPtr")
	SendMessage, Msg, wParam, lParam,, ahk_id %hWnd%
}

Ahkbin(Content, Name="", Desc="", Channel="")
{
	static URL := "http://p.ahkscript.org/"
	Form := "code=" UriEncode(Content)
	if Name
		Form .= "&name=" UriEncode(Name)
	if Desc
		Form .= "&desc=" UriEncode(Desc)
	if Channel
		Form .= "&announce=on&channel=" UriEncode(Channel)
	
	Pbin := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	Pbin.Open("POST", URL, False)
	Pbin.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
	Pbin.Send(Form)
	return Pbin.Option(1)
}

; Modified by GeekDude from http://goo.gl/0a0iJq
UriEncode(Uri, RE="[0-9A-Za-z]") {
	VarSetCapacity(Var, StrPut(Uri, "UTF-8"), 0), StrPut(Uri, &Var, "UTF-8")
	While Code := NumGet(Var, A_Index - 1, "UChar")
		Res .= (Chr:=Chr(Code)) ~= RE ? Chr : Format("%{:02X}", Code)
	Return, Res
}
