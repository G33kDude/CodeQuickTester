#SingleInstance, Off
#NoEnv
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%

global B_Params := []
Loop, %0%
	B_Params.Push(%A_Index%)

Menu, Tray, Icon, %A_AhkPath%, 2
FileEncoding, UTF-8

Settings :=
( LTrim Join Comments
{
	; When True, this setting may conflict with other instances of CQT
	"GlobalRun": False,
	
	; Script options
	"AhkPath": A_AhkPath,
	"Params": "",
	
	; Editor (colors are 0xBBGGRR)
	"FGColor": 0xEDEDCD,
	"BGColor": 0x3F3F3F,
	"TabSize": 4,
	"Font": {
		"Typeface": "Consolas",
		"Size": 11,
		"Bold": False
	},
	
	; Highlighter (colors are 0xRRGGBB)
	"UseHighlighter": True,
	"Highlighter": "HighlightAHK",
	"HighlightDelay": 200, ; Delay until the user is finished typing
	"Colors": {
		"Comments":     0x7F9F7F,
		"Functions":    0x7CC8CF,
		"Keywords":     0xE4EDED,
		"Multiline":    0x7F9F7F,
		"Numbers":      0xF79B57,
		"Punctuation":  0x97C0EB,
		"Strings":      0xCC9893,
		"A_Builtins":   0xF79B57,
		"Commands":     0xCDBFA3,
		"Directives":   0x7CC8CF,
		"Flow":         0xE4EDED,
		"KeyNames":     0xCB8DD9
	},
	
	; Auto-Indenter
	"Indent": "`t",
	
	; Pastebin
	"DefaultName": "GeekDude",
	"DefaultDesc": "",
	
	; AutoComplete
	"UseAutoComplete": True,
	"ACListRebuildDelay": 500 ; Delay until the user is finished typing
}
)

Tester := new CodeQuickTester(Settings)
Tester.RegisterCloseCallback(Func("TesterClose"))
return

#If Tester.Exec.Status == 0 ; Running

~*Escape::Tester.Exec.Terminate()

#If (Tester.Settings.GlobalRun && Tester.Exec.Status == 0) ; Running

F5::
!r::
; Reloads
Tester.RunButton()
Tester.RunButton()
return

#If Tester.Settings.GlobalRun

F5::
!r::
Tester.RunButton()
return

#If

TesterClose(Tester)
{
	ExitApp
}

#Include %A_ScriptDir%\RichCode.ahk\RichCode.ahk
#Include %A_ScriptDir%\RichCode.ahk\Highlighters\AHK.ahk
#Include %A_ScriptDir%\lib
#Include CQT.ahk
#Include ServiceHandler.ahk
#Include WinEvents.ahk
#Include AutoIndent.ahk
#Include Utils.ahk
#Include Publish.ahk
#Include HelpFile.ahk
