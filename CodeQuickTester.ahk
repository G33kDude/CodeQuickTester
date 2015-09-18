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

Settings := {"DefaultName": "GeekDude"
, "DefaultDesc": ""
, "FGColor": 0xCDEDED
, "BGColor": 0x3F3F3F
, "TabSize": 4
, "Indent": "`t"
, "TypeFace": "Microsoft Sans Serif"
, "Font": "s8 wNorm"
, "CodeTypeFace": "Consolas"
, "CodeFont": "s9 wBold"}

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

#Include %A_ScriptDir%
#Include CQT.ahk
#Include ServiceHandler.ahk
#Include WinEvents.ahk
#Include AutoIndent.ahk
#Include Utils.ahk