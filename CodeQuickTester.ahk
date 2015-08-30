#SingleInstance, Off
#NoEnv
SetBatchLines, -1

global B_Params := []
Loop, %0%
	B_Params.Push(%A_Index%)

Menu, Tray, Icon, %A_AhkPath%, 2
FileEncoding, UTF-8

; TODO: command line input
; TODO: Figure out why it gets sometimes gets stuck on "Kill" when using MultiTester

Tester := new CodeQuickTester()
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

#Include CQT.ahk
#Include ServiceHandler.ahk
#Include WinEvents.ahk
#Include AutoIndent.ahk
#Include Utils.ahk