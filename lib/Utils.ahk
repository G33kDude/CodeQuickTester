
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

; Helper function, to make passing in expressions resulting in function objects easier
SetTimer(Label, Period)
{
	SetTimer, %Label%, %Period%
}

SendMessage(Msg, wParam, lParam, hWnd)
{
	SendMessage, Msg, wParam, lParam,, ahk_id %hWnd%
	return ErrorLevel
}

PostMessage(Msg, wParam, lParam, hWnd)
{
	PostMessage, Msg, wParam, lParam,, ahk_id %hWnd%
	return ErrorLevel
}

Run(Params*)
{
	for each, Param in Params
	{
		Param := RegExReplace(Param, "(\\*)""", "$1$1\""")
		RunStr .= """" Param """ "
	}
	Run, %RunStr%,,, PID
	return PID
}

GetFullPathName(FilePath)
{
	VarSetCapacity(Path, A_IsUnicode ? 520 : 260, 0)
	DllCall("GetFullPathName", "Str", FilePath
	, "UInt", 260, "Str", Path, "Ptr", 0, "UInt")
	return Path
}
