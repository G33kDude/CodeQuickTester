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
	if (A_IsCompiled && AhkPath == A_ScriptFullPath)
		AhkPath .= " /E"
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
	xhr := ComObjCreate("MSXML2.XMLHTTP")
	xhr.Open("GET", url, false), xhr.Send()
	return xhr.ResponseText
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

PostMessage(Msg, wParam, lParam, hWnd)
{
	PostMessage, Msg, wParam, lParam,, ahk_id %hWnd%
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
	
	Pbin := ComObjCreate("MSXML2.XMLHTTP")
	Pbin.Open("POST", URL, False)
	Pbin.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
	Pbin.Send(Form)
	return Pbin.getResponseHeader("ahk-location")
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

Ini_Load(Contents)
{
	Section := Out := []
	loop, Parse, Contents, `n, `r
	{
		if ((Line := Trim(A_LoopField)) ~= "^;|^$")
			continue
		else if RegExMatch(Line, "^\[(.+)\]$", Match)
			Out[Match1] := (Section := [])
		else if RegExMatch(Line, "^(.+?)=(.*)$", Match)
			Section[Trim(Match1)] := Trim(Match2)
	}
	return Out
}

GetFullPathName(FilePath)
{
	VarSetCapacity(Path, A_IsUnicode ? 520 : 260, 0)
	DllCall("GetFullPathName", "Str", FilePath
	, "UInt", 260, "Str", Path, "Ptr", 0, "UInt")
	return Path
}

RichEdit_AddMargins(hRichEdit, x:=0, y:=0, w:=0, h:=0)
{
    static WineVer := DllCall("ntdll.dll\wine_get_version", "AStr")
    VarSetCapacity(RECT, 16, 0)
    if (x | y | w | h)
    {
        if WineVer
        {
			; Workaround for bug in Wine 3.0.2.
			; This code will need to be updated this code
			; after future Wine releases that fix it.
            NumPut(x, RECT,  0, "Int"), NumPut(y, RECT,  4, "Int")
            NumPut(w, RECT,  8, "Int"), NumPut(h, RECT, 12, "Int")
        }
        else
        {
            if !DllCall("GetClientRect", "UPtr", hRichEdit, "UPtr", &RECT, "UInt")
                throw Exception("Couldn't get RichEdit Client RECT")
            NumPut(x + NumGet(RECT,  0, "Int"), RECT,  0, "Int")
            NumPut(y + NumGet(RECT,  4, "Int"), RECT,  4, "Int")
            NumPut(w + NumGet(RECT,  8, "Int"), RECT,  8, "Int")
            NumPut(h + NumGet(RECT, 12, "Int"), RECT, 12, "Int")
        }
    }
    SendMessage(0xB3, 0, &RECT, hRichEdit)
}
