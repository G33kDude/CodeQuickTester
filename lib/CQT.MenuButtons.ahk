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
		Run, "%A_AhkPath%" "%A_ScriptFullPath%"
	}
	
	Publish()
	{
		Gui, +OwnDialogs
		FileSelectFile, FilePath, S18,, % this.Parent.Title " - Publish Code"
		if ErrorLevel
			return
		
		FileOpen(FilePath, "w").Write(this.Parent.Code)
		PreprocessScript(Text, FilePath, [])
		FileOpen(FilePath, "w").Write(Text)
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
		this.Parent.Code := this.Parent.Code
	}
	
	AutoIndent()
	{
		this.Parent.LoadCode(AutoIndent(this.Parent.Code, this.Parent.Settings.Indent))
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
	
	Comment()
	{
		hCodeEditor := this.Parent.hCodeEditor
		
		Text := StrSplit(this.Parent.Code, "`n", "`r")
		
		VarSetCapacity(s, 8, 0), SendMessage(0x0B0, &s, &s+4, hCodeEditor) ; EM_GETSEL
		Left := NumGet(s, 0, "UInt"), Right := NumGet(s, 4, "UInt")
		
		Top := SendMessage(0x436, 0, Left, hCodeEditor) ; EM_EXLINEFROMCHAR
		Bottom := SendMessage(0x436, 0, Right, hCodeEditor) ; EM_EXLINEFROMCHAR
		
		Count := Bottom-Top + 1
		Loop, % Count
			Text[A_Index+Top] := ";" Text[A_Index+Top]
		for each, Line in Text
			Out .= "`r`n" Line
		Out := SubStr(Out, 3)
		
		this.Parent.Code := Out
		
		NumPut(NumGet(s, "UInt") + 1, &s, "UInt")
		NumPut(NumGet(s, 4, "UInt") + Count, &s, 4, "UInt")
		SendMessage(0x437, 0, &s, hCodeEditor) ; EM_EXSETSEL
	}
	
	Uncomment()
	{
		hCodeEditor := this.Parent.hCodeEditor
		
		Text := StrSplit(this.Parent.Code, "`n", "`r")
		
		VarSetCapacity(s, 8, 0), SendMessage(0x0B0, &s, &s+4, hCodeEditor) ; EM_GETSEL
		Left := NumGet(s, 0, "UInt"), Right := NumGet(s, 4, "UInt")
		
		Top := SendMessage(0x436, 0, Left, hCodeEditor) ; EM_EXLINEFROMCHAR
		Bottom := SendMessage(0x436, 0, Right, hCodeEditor) ; EM_EXLINEFROMCHAR
		
		Removed := 0
		Loop, % Bottom-Top + 1
			if InStr(Text[A_Index+Top], ";") == 1
				Text[A_Index+Top] := SubStr(Text[A_Index+Top], 2), Removed++
		for each, Line in Text
			Out .= "`r`n" Line
		Out := SubStr(Out, 3)
		
		this.Parent.Code := Out
		
		NumPut(NumGet(s, "UInt") - 1, &s, "UInt")
		NumPut(NumGet(s, 4, "UInt") - Removed, &s, 4, "UInt")
		SendMessage(0x437, 0, &s, hCodeEditor) ; EM_EXSETSEL
	}
	
	Indent()
	{
		hCodeEditor := this.Parent.hCodeEditor
		
		Text := StrSplit(this.Parent.Code, "`n", "`r")
		
		VarSetCapacity(s, 8, 0), SendMessage(0x0B0, &s, &s+4, hCodeEditor) ; EM_GETSEL
		Left := NumGet(s, 0, "UInt"), Right := NumGet(s, 4, "UInt")
		
		Top := SendMessage(0x436, 0, Left, hCodeEditor) ; EM_EXLINEFROMCHAR
		Bottom := SendMessage(0x436, 0, Right, hCodeEditor) ; EM_EXLINEFROMCHAR
		
		Count := Bottom-Top + 1
		Loop, % Count
			Text[A_Index+Top] := "`t" Text[A_Index+Top]
		for each, Line in Text
			Out .= "`r`n" Line
		Out := SubStr(Out, 3)
		
		this.Parent.Code := Out
		
		NumPut(NumGet(s, "UInt") + 1, &s, "UInt")
		NumPut(NumGet(s, 4, "UInt") + Count, &s, 4, "UInt")
		SendMessage(0x437, 0, &s, hCodeEditor) ; EM_EXSETSEL
	}
	
	Unindent()
	{
		hCodeEditor := this.Parent.hCodeEditor
		
		Text := StrSplit(this.Parent.Code, "`n", "`r")
		
		VarSetCapacity(s, 8, 0), SendMessage(0x0B0, &s, &s+4, hCodeEditor) ; EM_GETSEL
		Left := NumGet(s, 0, "UInt"), Right := NumGet(s, 4, "UInt")
		
		Top := SendMessage(0x436, 0, Left, hCodeEditor) ; EM_EXLINEFROMCHAR
		Bottom := SendMessage(0x436, 0, Right, hCodeEditor) ; EM_EXLINEFROMCHAR
		
		Removed := 0
		Loop, % Bottom-Top + 1
			if InStr(Text[A_Index+Top], "`t") == 1
				Text[A_Index+Top] := SubStr(Text[A_Index+Top], 2), Removed++
		for each, Line in Text
			Out .= "`r`n" Line
		Out := SubStr(Out, 3)
		
		this.Parent.Code := Out
		
		NumPut(NumGet(s, "UInt") - 1, &s, "UInt")
		NumPut(NumGet(s, 4, "UInt") - Removed, &s, 4, "UInt")
		SendMessage(0x437, 0, &s, hCodeEditor) ; EM_EXSETSEL
	}
}
