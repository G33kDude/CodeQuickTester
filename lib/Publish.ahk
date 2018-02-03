
;
; Based on code from fincs' Ahk2Exe - https://github.com/fincs/ahk2exe
;

PreprocessScript(ByRef ScriptText, AhkScript, KeepComments=1, KeepIndent=1, KeepEmpties=0, FileList="", FirstScriptDir="", Options="", iOption=0)
{
	SplitPath, AhkScript, ScriptName, ScriptDir
	if !IsObject(FileList)
	{
		FileList := [AhkScript]
		; ScriptText := "; <COMPILER: v" A_AhkVersion ">`n"
		FirstScriptDir := A_WorkingDir
		IsFirstScript := true
		Options := { comm: ";", esc: "``" }
		
		OldWorkingDir := A_WorkingDir
		SetWorkingDir, %FirstScriptDir%
	}
	
	IfNotExist, %AhkScript%
		if !iOption
			Util_Error((IsFirstScript ? "Script" : "#include") " file """ AhkScript """ cannot be opened.")
	else return
		
	cmtBlock := false, contSection := false
	Loop, Read, %AhkScript%
	{
		tline := Trim(A_LoopReadLine)
		RegExMatch(A_LoopReadLine, "^[ \t]+", indent)
		if !cmtBlock
		{
			if !contSection
			{
				if StrStartsWith(tline, Options.comm) && !KeepComments
					continue
				else if (tline = "" && !KeepEmpties)
					continue
				else if StrStartsWith(tline, "/*")
				{
					if KeepComments
						ScriptText .= A_LoopReadLine "`n"
					cmtBlock := true
					continue
				}
			}
			if StrStartsWith(tline, "(") && !IsFakeCSOpening(tline)
				contSection := true
			else if StrStartsWith(tline, ")")
				contSection := false
			
			ttline := RegExReplace(tline, "\s+" RegExEscape(Options.comm) ".*$", "")
			if !contSection && RegExMatch(ttline, "i)^#Include(Again)?[ \t]*[, \t]?\s+(.*)$", o)
			{
				IsIncludeAgain := (o1 = "Again")
				IgnoreErrors := false
				IncludeFile := o2
				if RegExMatch(IncludeFile, "\*[iI]\s+?(.*)", o)
					IgnoreErrors := true, IncludeFile := Trim(o1)
				
				if RegExMatch(IncludeFile, "^<(.+)>$", o)
				{
					if IncFile2 := FindLibraryFile(o1, FirstScriptDir)
					{
						IncludeFile := IncFile2
						goto _skip_findfile
					}
				}
				
				StringReplace, IncludeFile, IncludeFile, `%A_ScriptDir`%, %FirstScriptDir%, All
				StringReplace, IncludeFile, IncludeFile, `%A_AppData`%, %A_AppData%, All
				StringReplace, IncludeFile, IncludeFile, `%A_AppDataCommon`%, %A_AppDataCommon%, All
				StringReplace, IncludeFile, IncludeFile, `%A_LineFile`%, %AhkScript%, All
				
				if InStr(FileExist(IncludeFile), "D")
				{
					SetWorkingDir, %IncludeFile%
					continue
				}
				
				_skip_findfile:
				
				IncludeFile := Util_GetFullPath(IncludeFile)
				
				AlreadyIncluded := false
				for k,v in FileList
					if (v = IncludeFile)
					{
						AlreadyIncluded := true
						break
					}
				if(IsIncludeAgain || !AlreadyIncluded)
				{
					if !AlreadyIncluded
						FileList.Insert(IncludeFile)
					PreprocessScript(ScriptText, IncludeFile, KeepComments, KeepIndent, KeepEmpties, FileList, FirstScriptDir, Options, IgnoreErrors)
				}
			}else if !contSection && ttline ~= "i)^FileInstall[, \t]"
			{
				if ttline ~= "^\w+\s+(:=|\+=|-=|\*=|/=|//=|\.=|\|=|&=|\^=|>>=|<<=)"
					continue ; This is an assignment!
				
				; workaround for `, detection
				EscapeChar := Options.esc
				EscapeCharChar := EscapeChar EscapeChar
				EscapeComma := EscapeChar ","
				EscapeTmp := chr(2)
				EscapeTmpD := chr(3)
				StringReplace, ttline, ttline, %EscapeCharChar%, %EscapeTmpD%, All
				StringReplace, ttline, ttline, %EscapeComma%, %EscapeTmp%, All
				
				if !RegExMatch(ttline, "i)^FileInstall[ \t]*[, \t][ \t]*([^,]+?)[ \t]*(,|$)", o) || o1 ~= "[^``]%"
					Util_Error("Error: Invalid ""FileInstall"" syntax found. Note that the first parameter must not be specified using a continuation section.")
				_ := Options.esc
				StringReplace, o1, o1, %_%`%, `%, All
				StringReplace, o1, o1, %_%`,, `,, All
				StringReplace, o1, o1, %_%%_%,, %_%,, All
				
				; workaround for `, detection [END]
				StringReplace, o1, o1, %EscapeTmp%, `,, All
				StringReplace, o1, o1, %EscapeTmpD%, %EscapeChar%, All
				StringReplace, ttline, ttline, %EscapeTmp%, %EscapeComma%, All
				StringReplace, ttline, ttline, %EscapeTmpD%, %EscapeCharChar%, All
				
				ScriptText .= (KeepIndent ? indent : "") (KeepComments ? tline : ttline) "`n"
			}else if !contSection && RegExMatch(tline, "i)^#CommentFlag\s+(.+)$", o)
				Options.comm := o1, ScriptText .= (KeepIndent ? indent : "") (KeepComments ? tline : ttline) "`n"
			else if !contSection && RegExMatch(tline, "i)^#EscapeChar\s+(.+)$", o)
				Options.esc := o1, ScriptText .= (KeepIndent ? indent : "") (KeepComments ? tline : ttline) "`n"
			else if !contSection && RegExMatch(tline, "i)^#DerefChar\s+(.+)$", o)
				Util_Error("Error: #DerefChar is not supported.")
			else if !contSection && RegExMatch(tline, "i)^#Delimiter\s+(.+)$", o)
				Util_Error("Error: #Delimiter is not supported.")
			else
				ScriptText .= (contSection ? A_LoopReadLine : (KeepIndent ? indent : "") (KeepComments ? tline : ttline)) "`n"
		}else{
			if KeepComments
				ScriptText .= A_LoopReadLine "`n"
			if StrStartsWith(tline, "*/")
				cmtBlock := false
		}
	}
	
	Loop, % !!IsFirstScript ; equivalent to "if IsFirstScript" except you can break from the block
	{
		static AhkPath := A_IsCompiled ? A_ScriptDir "\..\AutoHotkey.exe" : A_AhkPath
		IfNotExist, %AhkPath%
			break ; Don't bother with auto-includes because the file does not exist
		
		; Auto-including any functions called from a library...
		ilibfile = %A_Temp%\_ilib.ahk
		IfExist, %ilibfile%, FileDelete, %ilibfile%
			AhkType := AHKType(AhkPath)
		if AhkType = FAIL
			Util_Error("Error: The AutoHotkey build used for auto-inclusion of library functions is not recognized.", 1, AhkPath)
		if AhkType = Legacy
			Util_Error("Error: Legacy AutoHotkey versions (prior to v1.1) are not allowed as the build used for auto-inclusion of library functions.", 1, AhkPath)
		tmpErrorLog := Util_TempFile()
		RunWait, "%AhkPath%" /iLib "%ilibfile%" /ErrorStdOut "%AhkScript%" 2>"%tmpErrorLog%", %FirstScriptDir%, UseErrorLevel
		FileRead,tmpErrorData,%tmpErrorLog%
		FileDelete,%tmpErrorLog%
		if (ErrorLevel = 2)
			Util_Error("Error: The script contains syntax errors.",1,tmpErrorData)
		IfExist, %ilibfile%
		{
			PreprocessScript(ScriptText, ilibfile, KeepComments, KeepIndent, KeepEmpties, FileList, FirstScriptDir, Options)
			FileDelete, %ilibfile%
		}
		StringTrimRight, ScriptText, ScriptText, 1 ; remove trailing newline
	}
	
	if OldWorkingDir
		SetWorkingDir, %OldWorkingDir%
}

IsFakeCSOpening(tline)
{
	Loop, Parse, tline, %A_Space%%A_Tab%
		if !StrStartsWith(A_LoopField, "Join") && InStr(A_LoopField, ")")
			return true
	return false
}

FindLibraryFile(name, ScriptDir)
{
	libs := [ScriptDir "\Lib", A_MyDocuments "\AutoHotkey\Lib", A_ScriptDir "\..\Lib"]
	p := InStr(name, "_")
	if p
		name_lib := SubStr(name, 1, p-1)
	
	for each,lib in libs
	{
		file := lib "\" name ".ahk"
		IfExist, %file%
			return file
		
		if !p
			continue
		
		file := lib "\" name_lib ".ahk"
		IfExist, %file%
			return file
	}
}

StrStartsWith(ByRef v, ByRef w)
{
	return SubStr(v, 1, StrLen(w)) = w
}

RegExEscape(String)
{
	return "\Q" StrReplace(String, "\E", "\E\\E\Q") "\E"
}

Util_TempFile(d:="")
{
	if ( !StrLen(d) || !FileExist(d) )
		d:=A_Temp
	Loop
		tempName := d "\~temp" A_TickCount ".tmp"
	until !FileExist(tempName)
	return tempName
}

Util_GetFullPath(path)
{
	VarSetCapacity(fullpath, 260 * (!!A_IsUnicode + 1))
	if DllCall("GetFullPathName", "str", path, "uint", 260, "str", fullpath, "ptr", 0, "uint")
		return fullpath
	else
		return ""
}

Util_Error(txt, doexit=1, extra="")
{
	throw Exception(txt, -2, extra)
}

; Based on code from SciTEDebug.ahk
AHKType(exeName)
{
	FileGetVersion, vert, %exeName%
	if !vert
		return "FAIL"
	
	StringSplit, vert, vert, .
	vert := vert4 | (vert3 << 8) | (vert2 << 16) | (vert1 << 24)
	
	exeMachine := GetExeMachine(exeName)
	if !exeMachine
		return "FAIL"
	
	if (exeMachine != 0x014C) && (exeMachine != 0x8664)
		return "FAIL"
	
	if !(VersionInfoSize := DllCall("version\GetFileVersionInfoSize", "str", exeName, "uint*", null, "uint"))
		return "FAIL"
	
	VarSetCapacity(VersionInfo, VersionInfoSize)
	if !DllCall("version\GetFileVersionInfo", "str", exeName, "uint", 0, "uint", VersionInfoSize, "ptr", &VersionInfo)
		return "FAIL"
	
	if !DllCall("version\VerQueryValue", "ptr", &VersionInfo, "str", "\VarFileInfo\Translation", "ptr*", lpTranslate, "uint*", cbTranslate)
		return "FAIL"
	
	oldFmt := A_FormatInteger
	SetFormat, IntegerFast, H
	wLanguage := NumGet(lpTranslate+0, "UShort")
	wCodePage := NumGet(lpTranslate+2, "UShort")
	id := SubStr("0000" SubStr(wLanguage, 3), -3, 4) SubStr("0000" SubStr(wCodePage, 3), -3, 4)
	SetFormat, IntegerFast, %oldFmt%
	
	if !DllCall("version\VerQueryValue", "ptr", &VersionInfo, "str", "\StringFileInfo\" id "\ProductName", "ptr*", pField, "uint*", cbField)
		return "FAIL"
	
	; Check it is actually an AutoHotkey executable
	if !InStr(StrGet(pField, cbField), "AutoHotkey")
		return "FAIL"
	
	; We're dealing with a legacy version if it's prior to v1.1
	return vert >= 0x01010000 ? "Modern" : "Legacy"
}

GetExeMachine(exepath)
{
	if !(exe := FileOpen(exepath, "r"))
		return
	
	exe.Seek(60), exe.Seek(exe.ReadUInt()+4)
	return exe.ReadUShort()
}