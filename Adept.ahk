#SingleInstance Off
#NoEnv
SetBatchLines, -1
SetWorkingDir %A_ScriptDir%

Menu, Tray, Icon, %A_AhkPath%, 2
FileEncoding, UTF-8

config :=
( LTrim Join Comments
{
	; File path for the starting contents
	"DefaultPath": "C:\Windows\ShellNew\Template.ahk",

	; When True, this setting may conflict with other instances of CQT
	"GlobalRun": False,

	; Script options
	"AhkPath": A_AhkPath,
	"Params": "",

	"FilePaneWidth": 200,

	; Editor (colors are 0xBBGGRR)
	"FGColor": 0xEDEDCD,
	"BGColor": 0x3F3F3F,
	"TabSize": 4,
	"Font": {
		"Typeface": "Consolas",
		"Size": 11,
		"Bold": False
	},
	"Gutter": {
		; Width in pixels. Make this larger when using
		; larger fonts. Set to 0 to disable the gutter.
		"Width": 40,

		"FGColor": 0x9FAFAF,
		"BGColor": 0x262626
	},
	"Margins": [3, 3, -3, -3],

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
	"DefaultName": A_UserName,
	"DefaultDesc": "Pasted with CodeQuickTester",

	; AutoComplete
	"UseAutoComplete": True,
	"ACListRebuildDelay": 500 ; Delay until the user is finished typing
}
)

Adept.__Delete := Func("ExitApp")
new Adept(config, A_Args)
return

ExitApp()
{
	ExitApp
}

#Include lib\RichCode.ahk\RichCode.ahk
#Include lib\RichCode.ahk\Highlighters\AHK.ahk
#Include lib\Adept.ahk
#Include lib\Gutter.ahk
#Include lib\Utils.ahk
#Include lib\WinEvents.ahk
