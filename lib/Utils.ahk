; Modified from https://github.com/cocobelgica/AutoHotkey-Util/blob/master/ExecScript.ahk
ExecScript(Script, Params="", AhkPath="")
{
	static Shell := ComObjCreate("WScript.Shell")
	Name := "\\.\pipe\AHK_CQT_" A_TickCount
	Pipe := []
	Loop, 3
	{
		Pipe[A_Index] := DllCall("CreateNamedPipe"
		, "Str", Name
		, "UInt", 2, "UInt", 0
		, "UInt", 255, "UInt", 0
		, "UInt", 0, "UPtr", 0
		, "UPtr", 0, "UPtr")
	}
	if !FileExist(AhkPath)
		throw Exception("AutoHotkey runtime not found: " AhkPath)
	if FileExist(Name)
	{
		Exec := Shell.Exec(AhkPath " /CP65001 " Name " " Params)
		DllCall("ConnectNamedPipe", "UPtr", Pipe[2], "UPtr", 0)
		DllCall("ConnectNamedPipe", "UPtr", Pipe[3], "UPtr", 0)
		FileOpen(Pipe[3], "h", "UTF-8").Write(Script)
	}
	else ; Running under WINE with improperly implemented pipes
	{
		FileOpen(Name := "AHK_CQT_TMP.ahk", "w").Write(Script)
		Exec := Shell.Exec(AhkPath " /CP65001 " Name " " Params)
	}
	Loop, 3
		DllCall("CloseHandle", "UPtr", Pipe[A_Index])
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
	return ErrorLevel
}

Ahkbin(Content, Name="", Desc="", Channel="")
{
	static URL := "https://p.ahkscript.org/"
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

CreateMenus(Menu)
{
	static MenuName := 0
	Menus := ["Menu_" MenuName++]
	for each, Item in Menu
	{
		Ref := Item[2]
		if IsObject(Ref) && Ref._NewEnum()
		{
			SubMenus := CreateMenus(Ref)
			Menus.Push(SubMenus*), Ref := ":" SubMenus[1]
		}
		Menu, % Menus[1], Add, % Item[1], %Ref%
	}
	return Menus
}
