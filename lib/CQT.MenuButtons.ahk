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
		
		FileOpen(FilePath, "w").Write(this.Parent.RichCode.Value)
		
		this.Parent.RichCode.Modified := False
		this.Parent.UpdateStatusBar()
	}
	
	Open()
	{
		Gui, +OwnDialogs
		FileSelectFile, FilePath, 3,, % this.Parent.Title " - Open Code"
		if ErrorLevel
			return
		this.Parent.LoadCode(FileOpen(FilePath, "r").Read())
		
		; Follow the directory of the most recently opened file
		SetWorkingDir, %FilePath%\..
		this.Parent.ScriptOpts.UpdateFields()
	}
	
	New()
	{
		Run, "%A_AhkPath%" "%A_ScriptFullPath%"
	}
	
	Publish()
	{ ; TODO: Recycle PubInstance
		if WinExist("ahk_id" this.PubInstance.hWnd)
			WinActivate, % "ahk_id" this.PubInstance.hWnd
		else
			this.PubInstance := new this.Parent.Publish(this.Parent)
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
	
	ScriptOpts()
	{
		if WinExist("ahk_id" this.Parent.ScriptOptsInstance.hWnd)
			WinActivate, % "ahk_id" this.Parent.ScriptOptsInstance.hWnd
		else
			this.Parent.ScriptOptsInstance := new this.Parent.ScriptOpts(this.Parent)
	}
	
	ToggleOnTop()
	{
		if (this.Parent.AlwaysOnTop := !this.Parent.AlwaysOnTop)
		{
			Menu, % this.Parent.Menus[4], Check, &AlwaysOnTop`tAlt+A
			Gui, +AlwaysOnTop
		}
		else
		{
			Menu, % this.Parent.Menus[4], Uncheck, &AlwaysOnTop`tAlt+A
			Gui, -AlwaysOnTop
		}
	}
	
	Highlighter()
	{
		if (this.Parent.Settings.UseHighlighter := !this.Parent.Settings.UseHighlighter)
			Menu, % this.Parent.Menus[4], Check, &Highlighter
		else
			Menu, % this.Parent.Menus[4], Uncheck, &Highlighter
		
		; Force refresh the code, adding/removing any highlighting
		this.Parent.RichCode.Value := this.Parent.RichCode.Value
	}
	
	GlobalRun()
	{
		if (this.Parent.Settings.GlobalRun := !this.Parent.Settings.GlobalRun)
			Menu, % this.Parent.Menus[4], Check, Global Run Hotkeys
		else
			Menu, % this.Parent.Menus[4], Uncheck, Global Run Hotkeys
	}
	
	AutoIndent()
	{
		this.Parent.LoadCode(AutoIndent(this.Parent.RichCode.Value, this.Parent.Settings.Indent))
	}
	
	Help()
	{
		Run, hh %A_AhkPath%\..\AutoHotkey.chm
	}
	
	About()
	{
		Gui, +OwnDialogs
		MsgBox,, % this.Parent.Title " - About", CodeQuickTester written by GeekDude
	}
	
	ServiceHandler()
	{
		Gui, +OwnDialogs
		if ServiceHandler.Installed()
		{
			MsgBox, 36, % this.Parent.Title " - Uninstall Service Handler"
			, Are you sure you want to remove CodeQuickTester from being the default service handler for "ahk:" links?
			IfMsgBox, Yes
			{
				ServiceHandler.Remove()
				Menu, % this.Parent.Menus[4], Uncheck, Install Service Handler
			}
		}
		else
		{
			MsgBox, 36, % this.Parent.Title " - Install Service Handler"
			, Are you sure you want to install CodeQuickTester as the default service handler for "ahk:" links?
			IfMsgBox, Yes
			{
				ServiceHandler.Install()
				Menu, % this.Parent.Menus[4], Check, Install Service Handler
			}
		}
	}
	
	DefaultEditor()
	{
		Gui, +OwnDialogs
		
		if !A_IsAdmin
		{
			MsgBox, 48, % this.Parent.Title " - Change Editor", You must be running as administrator to use this feature.
			return
		}
		
		RegRead, Editor, HKCR, AutoHotkeyScript\Shell\Edit\Command
		if (Editor == this.Parent.EditorString)
		{
			MsgBox, 36, % this.Parent.Title " - Remove as Default Editor"
			, % "Are you sure you want to restore the original default editor for .ahk files?"
			. "`n`n" this.Parent.OrigEditorString
			IfMsgBox, Yes
			{
				RegWrite REG_SZ, HKCR, AutoHotkeyScript\Shell\Edit\Command,, % this.Parent.OrigEditorString
				Menu, % this.Parent.Menus[4], Uncheck, Set as Default Editor
			}
		}
		else
		{
			MsgBox, 36, % this.Parent.Title " - Set as Default Editor"
			, % "Are you sure you want to install CodeQuickTester as the default editor for .ahk files?"
			. "`n`n" this.Parent.EditorString
			IfMsgBox, Yes
			{
				RegWrite REG_SZ, HKCR, AutoHotkeyScript\Shell\Edit\Command,, % this.Parent.EditorString
				MsgBox, %ErrorLevel%
				Menu, % this.Parent.Menus[4], Check, Set as Default Editor
			}
		}
		
		
	}
	
	Comment()
	{
		this.Parent.RichCode.IndentSelection(False, ";")
	}
	
	Uncomment()
	{
		this.Parent.RichCode.IndentSelection(True, ";")
	}
	
	Indent()
	{
		this.Parent.RichCode.IndentSelection()
	}
	
	Unindent()
	{
		this.Parent.RichCode.IndentSelection(True)
	}
}
