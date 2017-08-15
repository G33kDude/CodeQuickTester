#SingleInstance, Off
#NoEnv
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%

global B_Params := []
Loop, %0%
	B_Params.Push(%A_Index%)

Menu, Tray, Icon, %A_AhkPath%, 2
FileEncoding, UTF-8

; TODO: Figure out why it gets sometimes gets stuck on "Kill" when using MultiTester
; TODO: Add right click menu
; TODO: Add params menu

Settings :=
( LTrim Join Comments
{
	"Font": {
		"Typeface": "Microsoft Sans Serif",
		"Size": 8,
		"Bold": False
	},
	
	; Editor (colors are 0xBBGGRR)
	"FGColor": 0xCDEDED,
	"BGColor": 0x3F3F3F,
	"TabSize": 4,
	"CodeFont": {
		"Typeface": "Consolas",
		"Size": 9,
		"Bold": True
	},
	
	; Highlighter (colors are 0xRRGGBB)
	"UseHighlighter": True,
	"HighlightDelay": 200, ; Delay until the user is finished typing
	"Colors": [
		0x7F9F7F, ; Comments
		0x7F9F7F, ; Multiline comments
		0x7CC8CF, ; Directives
		0x97C0EB, ; Punctuation
		0xF79B57, ; Numbers
		0xCC9893, ; Strings
		0xF79B57, ; A_Builtins
		0xE4EDED, ; Flow
		0xCDBFA3, ; Commands
		0x7CC8CF, ; Functions
		0xCB8DD9, ; Keynames
		0xE4EDED, ; Other keywords
		0xEDEDCD  ; Text
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

/* MultiTester
	ScriptPID := DllCall("GetCurrentProcessId")
	Testers := []
	Testers[new CodeQuickTester()] := True
	return
	
	#If WinActive("ahk_pid" ScriptPID)
	^n::Testers[new CodeQuickTester()] := True
	#If
	
	~*Escape::
	for Tester in Testers
		Tester.Exec.Terminate()
	return
*/

#Include %A_ScriptDir%\lib
#Include CQT.ahk
#Include ServiceHandler.ahk
#Include WinEvents.ahk
#Include AutoIndent.ahk
#Include Utils.ahk
#Include Publish.ahk
#Include Highlight.ahk