;
; Based on code from fincs' Ahk2Exe - https://github.com/fincs/ahk2exe
;
PreprocessScript(&scriptText, ahkScriptPath, fileList := [], firstScriptDir := "", iOption := 0, derefIncludeVars := unset) {
	NormalizePath(path) {
		cc := DllCall("GetFullPathName", "str", path, "uint", 0, "ptr", 0, "ptr", 0, "uint")
		buf := Buffer(cc * 2)
		DllCall("GetFullPathName", "str", path, "uint", cc, "ptr", buf, "ptr", 0)
		return StrGet(buf)
	}

	IsRealContinuationSection(trimmedLine) {
		loop parse trimmedLine, " `t"
			if !(A_LoopField ~= "i)^Join") && InStr(A_LoopField, ")")
				return false
		return true
	}

	FindLibraryFile(name, ScriptDir) {
		libs := [ScriptDir "\Lib", A_MyDocuments "\AutoHotkey\Lib", A_AhkPath "\..\Lib"] ; TODO: Use target ahk path
		p := InStr(name, "_")
		if p
			name_lib := SubStr(name, 1, p - 1)

		for each, lib in libs {
			file := lib "\" name ".ahk"
			If FileExist(file)
				return file

			if !p
				continue

			file := lib "\" name_lib ".ahk"
			If FileExist(file)
				return file
		}
	}

	DerefIncludePath(path, vars) {
		static SharedVars := Map("A_AhkPath", 1, "A_AppData", 1,
			"A_AppDataCommon", 1, "A_ComputerName", 1, "A_ComSpec", 1,
			"A_Desktop", 1, "A_DesktopCommon", 1, "A_MyDocuments", 1,
			"A_ProgramFiles", 1, "A_Programs", 1, "A_ProgramsCommon", 1,
			"A_Space", 1, "A_StartMenu", 1, "A_StartMenuCommon", 1, "A_Startup", 1,
			"A_StartupCommon", 1, "A_Tab", 1, "A_Temp", 1, "A_UserName", 1,
			"A_WinDir", 1)
		p := StrSplit(path, "%"), path := p[1], n := 2
		while n < p.Length {
			path .= vars.Has(p[n]) ? vars[p[n++]] . p[n++]
				: SharedVars.Has(p[n]) ? %SharedVars[p[n++]]% . p[n++]
					: "%" p[n++]
		}
		return n > p.Length ? path : path "%" p[n]
	}

	isFirstScript := fileList.Length == 0

	; Stage the environment for processing the file
	SplitPath NormalizePath(ahkScriptPath), &scriptName, &scriptDir
	if isFirstScript {
		fileList.Push(ahkScriptPath)
		scriptText := ""
		firstScriptDir := scriptDir
		tempWD := CTempWD(scriptDir)
		derefIncludeVars := Map(
			"A_IsCompiled", true,
			"A_LineFile", "",
			"A_AhkVersion", A_AhkVersion, ; TODO: use target ahk version
			"A_ScriptFullPath", ahkScriptPath,
			"A_ScriptName", scriptName,
			"A_ScriptDir", scriptDir,
		)
	}
	oldLineFile := derefIncludeVars["A_LineFile"]
	derefIncludeVars["A_LineFile"] := ahkScriptPath
	oldWorkingDir := A_WorkingDir
	SetWorkingDir scriptDir

	if !FileExist(ahkScriptPath) {
		if iOption
			throw Error((isFirstScript ? "Script" : "#include") " file cannot be opened.", , ahkScriptPath)
		else
			return
	}

	inCommentBlock := false, inContinuationSection := false
	Loop read ahkScriptPath {
		trimmedLine := Trim(A_LoopReadLine)

		; Handle comment block contents
		if inCommentBlock {
			if trimmedLine ~= "^\*/|\*/$"
				inCommentBlock := false
			scriptText .= A_LoopReadLine "`n"
			continue
		}

		; Handle extraneous text
		if !inContinuationSection {
			if trimmedLine ~= "^;" { ; Single-line comment
				scriptText .= A_LoopReadLine "`n"
				continue
			} else if trimmedLine = "" { ; Blank lines
				scriptText .= A_LoopReadLine "`n"
				continue
			} else if trimmedLine ~= "^/\*" { ; Block comments
				inCommentBlock := !(trimmedLine ~= "\*/$")
				scriptText .= A_LoopReadLine "`n"
				continue
			}
		}

		; Enter a continuation section
		if trimmedLine ~= "^\(" && IsRealContinuationSection(SubStr(trimmedLine, 2))
			inContinuationSection := true
		; Or exit a continuation section
		else if trimmedLine ~= "^\)"
			inContinuationSection := false

		if inContinuationSection {
			scriptText .= A_LoopReadLine "`n"
			continue
		}

		; Remove trailing comment
		trimmedLine := RegExReplace(trimmedLine, "\s+;.*$")

		; #Include lines
		if RegExMatch(trimmedLine, "i)^#Include(?<again>Again)?\s*[,\s]\s*(?<file>.*)$", &match) {
			includeFile := Trim(match.file, "`"' `t")
			includeFile := RegExReplace(includeFile, "i)^\*i\s+", , &ignoreErrors)

			; References to embedded scripts have a filename which starts with *
			; and will be handled by the interpreter
			if SubStr(includeFile, 1, 1) = "*" {
				scriptText .= A_LoopReadLine "`n"
				continue
			}
			if RegExMatch(includeFile, "^<(.+)>$", &match) {
				if foundFile := FindLibraryFile(match.1, firstScriptDir)
					includeFile := foundFile
			} else {
				includeFile := DerefIncludePath(includeFile, derefIncludeVars)
				if FileExist(includeFile) ~= "D" {
					SetWorkingDir includeFile
					scriptText .= A_LoopReadLine "`n"
					continue
				}
			}

			includeFile := NormalizePath(includeFile)

			; Determine whether the file is already included
			alreadyIncluded := false
			for k, v in fileList
				if v = includeFile
					alreadyIncluded := true
			until alreadyIncluded

			; Add to the list
			if !alreadyIncluded
				fileList.Push(includeFile)

			; Include the text where applicable
			if !alreadyIncluded || match.again
				PreprocessScript(&scriptText, includeFile, fileList, firstScriptDir, ignoreErrors, derefIncludeVars)
			continue
		}

		scriptText .= A_LoopReadLine "`n"
	}

	; Restore calling context
	derefIncludeVars["A_LineFile"] := oldLineFile
	SetWorkingDir oldWorkingDir
}

class CTempWD {
	__New(newWD) {
		this.oldWD := A_WorkingDir
		SetWorkingDir newWD
	}
	__Delete() {
		SetWorkingDir this.oldWD
	}
}