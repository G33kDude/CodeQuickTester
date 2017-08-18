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
	"Colors": [
		; RRGGBB  ;    ; AHK
		0x7F9F7F, ;  1 ; Comments
		0x7F9F7F, ;  2 ; Multiline comments
		0x7CC8CF, ;  3 ; Directives
		0x97C0EB, ;  4 ; Punctuation
		0xF79B57, ;  5 ; Numbers
		0xCC9893, ;  6 ; Strings
		0xF79B57, ;  7 ; A_Builtins
		0xE4EDED, ;  8 ; Flow
		0xCDBFA3, ;  9 ; Commands
		0x7CC8CF, ; 10 ; Functions
		0xCB8DD9, ; 11 ; Key names
		0xE4EDED  ; 12 ; Other keywords
	],
	
	; Auto-Indenter
	"Indent": "`t",
	
	; Pastebin
	"DefaultName": "GeekDude",
	"DefaultDesc": ""
}
)

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

#Include %A_ScriptDir%\RichCode.ahk\RichCode.ahk
#Include %A_ScriptDir%\RichCode.ahk\Highlighters\AHK.ahk
#Include %A_ScriptDir%\lib
#Include CQT.ahk
#Include ServiceHandler.ahk
#Include WinEvents.ahk
#Include AutoIndent.ahk
#Include Utils.ahk
#Include Publish.ahk