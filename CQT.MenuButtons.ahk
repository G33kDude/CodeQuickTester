class MenuButtons
{
	__New(Parent)
	{
		this.Parent := Parent
	}
	
	Save()
	{
		Gui, +OwnDialogs
		FileSelectFile, FilePath, S18
		if ErrorLevel
			return
		
		FileOpen(FilePath, "w").Write(this.Parent.Code)
	}
	
	Open()
	{
		Gui, +OwnDialogs
		FileSelectFile, FilePath, 3
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
		InputBox, Url, % this.Parent.Title, Enter a URL to fetch code from.
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
		Gui, % this.Parent.hMainWindow ":+OwnDialogs"
		MsgBox,, % this.Parent.Title, CodeQuickTester written by GeekDude
	}
	
	Install()
	{
		Gui, +OwnDialogs
		if ServiceHandler.Installed()
		{
			MsgBox, 36, , Are you sure you want to remove CodeQuickTester from being the default service handler for "ahk:" links?
			IfMsgBox, Yes
				ServiceHandler.Remove()
		}
		else
		{
			MsgBox, 36, , Are you sure you want to install CodeQuickTester as the default service handler for "ahk:" links?
			IfMsgBox, Yes
				ServiceHandler.Install()
		}
	}
}
