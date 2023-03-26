/*
	Implements functionality necessary for AutoCompletion of keywords in the
	RichCode control. Currently works off of values stored in the provided
	Parent object, but could be modified to work off a provided RichCode
	instance directly.

	The class is mostly self contained and could be easily extended to other
	projects, and even other types of controls. The main method of interacting
	with the class is by passing it WM_KEYDOWN messages. Another way to interact
	is by modifying the Fragment property, especially to clear it when you want
	to cancel autocompletion.
*/

class AutoComplete
{
	/**
	 * The list of words to suggest, before any words are pulled from the active document
	 * @type {String}
	 */
	defaultWordList := (
		"|#ClipboardTimeout|#DllLoad|#ErrorStdOut|#HotIf|#HotIfTimeout|#Hotstring|#Include|#InputLevel|#MaxThreads|"
		"#MaxThreadsBuffer|#MaxThreadsPerHotkey|#NoTrayIcon|#Requires|#SingleInstance|#SuspendExempt|#UseHook|#Warn|"
		"#WinActivateForce|"
		"Abs|ACos|ASin|ATan|BlockInput|Break|Buffer|CallbackCreate|CallbackFree|CaretGetPos|catch|Ceil|Chr|Click|"
		"ClipboardAll|ClipWait|ComCall|ComObjActive|ComObjArray|ComObjConnect|ComObject|ComObjFlags|ComObjFromPtr|"
		"ComObjGet|ComObjQuery|ComObjType|ComObjValue|ComValue|Continue|ControlAddItem|ControlChooseIndex|"
		"ControlChooseString|ControlClick|ControlDeleteItem|ControlFindItem|ControlFocus|ControlGetChecked|"
		"ControlGetChoice|ControlGetClassNN|ControlGetEnabled|ControlGetFocus|ControlGetHwnd|ControlGetIndex|"
		"ControlGetItems|ControlGetPos|ControlGetStyle|ControlGetText|ControlGetVisible|ControlHide|"
		"ControlHideDropDown|ControlMove|ControlSend|ControlSetChecked|ControlSetEnabled|ControlSetStyle|"
		"ControlSetText|ControlShow|ControlShowDropDown|CoordMode|Cos|Critical|DateAdd|DateDiff|DetectHiddenText|"
		"DetectHiddenWindows|DirCopy|DirCreate|DirDelete|DirExist|DirMove|DirSelect|DllCall|Download|DriveEject|"
		"DriveGetCapacity|DriveGetFileSystem|DriveGetLabel|DriveGetList|DriveGetSerial|DriveGetSpaceFree|"
		"DriveGetStatus|DriveGetStatusCD|DriveGetType|DriveLock|DriveRetract|DriveSetLabel|DriveUnlock|Edit|"
		"EditGetCurrentCol|EditGetCurrentLine|EditGetLine|EditGetLineCount|EditGetSelectedText|EditPaste|else|EnvGet|"
		"EnvSet|Exit|ExitApp|Exp|FileAppend|FileCopy|FileCreateShortcut|FileDelete|FileEncoding|FileExist|"
		"FileGetAttrib|FileGetShortcut|FileGetSize|FileGetTime|FileGetVersion|FileInstall|FileMove|FileOpen|FileRead|"
		"FileRecycle|FileRecycleEmpty|FileSelect|FileSetAttrib|FileSetTime|finally|Float|Floor|for|Format|FormatTime|"
		"GetKeyName|GetKeySC|GetKeyState|GetKeyVK|GetMethod|goto|GroupActivate|GroupAdd|GroupClose|GroupDeactivate|Gui|"
		"GuiCtrlFromHwnd|GuiFromHwnd|HasBase|HasMethod|HasProp|HotIf|Hotkey|Hotstring|if|IL_Add|IL_Create|IL_Destroy|"
		"ImageSearch|IniDelete|IniRead|IniWrite|InputBox|InputHook|InstallKeybdHook|InstallMouseHook|InStr|Integer|"
		"IsLabel|IsObject|IsSet|KeyHistory|KeyWait|ListHotkeys|ListLines|ListVars|ListViewGetContent|Ln|LoadPicture|"
		"Log|loop|Map|Max|Menu|MenuBar|MenuFromHandle|MenuSelect|Min|Mod|MonitorGet|MonitorGetCount|MonitorGetName|"
		"MonitorGetPrimary|MonitorGetWorkArea|MouseClick|MouseClickDrag|MouseGetPos|MouseMove|MsgBox|Number|NumGet|"
		"NumPut|ObjAddRef|ObjBindMethod|ObjGetBase|ObjGetCapacity|ObjHasOwnProp|ObjOwnPropCount|ObjOwnProps|ObjSetBase|"
		"ObjSetCapacity|OnClipboardChange|OnError|OnExit|OnMessage|Ord|OutputDebug|Pause|Persistent|PixelGetColor|"
		"PixelSearch|PostMessage|ProcessClose|ProcessExist|ProcessGetName|ProcessGetParent|ProcessGetPath|"
		"ProcessSetPriority|ProcessWait|ProcessWaitClose|Random|RegCreateKey|RegDelete|RegDeleteKey|RegExMatch|"
		"RegExReplace|RegRead|RegWrite|Reload|return|Round|Run|RunAs|RunWait|Send|SendEvent|SendInput|SendLevel|"
		"SendMessage|SendMode|SendPlay|SendText|SetCapsLockState|SetControlDelay|SetDefaultMouseSpeed|SetKeyDelay|"
		"SetMouseDelay|SetNumLockState|SetRegView|SetScrollLockState|SetStoreCapsLockMode|SetTimer|SetTitleMatchMode|"
		"SetWinDelay|SetWorkingDir|Shutdown|Sin|Sleep|Sort|SoundBeep|SoundGetInterface|SoundGetMute|SoundGetName|"
		"SoundGetVolume|SoundPlay|SoundSetMute|SoundSetVolume|SplitPath|Sqrt|StatusBarGetText|StatusBarWait|StrCompare|"
		"StrGet|String|StrLen|StrLower|StrPtr|StrPut|StrReplace|StrSplit|StrUpper|SubStr|Suspend|Switch|SysGet|"
		"SysGetIPAddresses|Tan|Thread|throw|ToolTip|TraySetIcon|TrayTip|Trim|try|Type|until|VarSetStrCapacity|"
		"VerCompare|while|WinActivate|WinActivateBottom|WinActive|WinClose|WinExist|WinGetClass|WinGetClientPos|"
		"WinGetControls|WinGetControlsHwnd|WinGetCount|WinGetID|WinGetIDLast|WinGetList|WinGetMinMax|WinGetPID|"
		"WinGetPos|WinGetProcessName|WinGetProcessPath|WinGetStyle|WinGetText|WinGetTitle|WinGetTransColor|"
		"WinGetTransparent|WinHide|WinKill|WinMaximize|WinMinimize|WinMinimizeAll|WinMove|WinMoveBottom|WinMoveTop|"
		"WinRedraw|WinRestore|WinSetAlwaysOnTop|WinSetEnabled|WinSetRegion|WinSetStyle|WinSetTitle|WinSetTransColor|"
		"WinSetTransparent|WinShow|WinWait|WinWaitActive|WinWaitClose"
	)

	/** @type {Integer} Maximum number of suggestions to be displayed in the dialog */
	maxSuggestions := 9

	/** @type {Integer} Minimum length for a word to be entered into the word list */
	minWordLen := 4

	/** @type {Integer} Minimum length of fragment before suggestions should be displayed */
	minSuggestLen := 3

	/** @type {Integer} Screen X coordinate to display the popup menu window */
	menuX := 0

	/** @type {Integer} Screen Y coordinate to display the popup menu window */
	menuY := 0

	/** @type {Boolean} Whether the popup is currently shown */
	visible := false

	/** @type {String[]} The current list of suggestions */
	suggestions := []

	/** @type {Integer} The height of an item in the listbox */
	itemHeight := unset

	/** @type {Integer} The height of a listbox absent the items */
	margins := unset

	/** @type {Gui} The GUI */
	gui := unset

	/** @type {Gui.ListBox} The ListBox on the GUI */
	listBox := unset

	/** @type {Integer} Retrieve the window handle (HWND) of the GUI window */
	Hwnd => this.gui.Hwnd


	; --- Properties ---

	/** @type {String} Backing field for fragment */
	_fragment := ""
	/** @type {String} The keyword fragment being evaluated for completion */
	fragment {
		get => this._fragment
		set => (
			this._fragment := value,
			StrLen(value) >= this.minSuggestLen ? this._Suggest() : this._Hide(),
			value
		)
	}

	/** @type {Boolean} Backing field for enabled */
	_enabled := true
	/** @type {Boolean} Whether autocompletion is currently enabled */
	enabled {
		get => this._enabled
		set => (value ? this.BuildWordList() : this.fragment := "", value)
	}


	; --- Constructor, Destructor ---

	__New(parent, enabled := True) {
		this.isWine := false
		try DllCall("ntdll.dll\wine_get_version"), this.isWine := true
		this.parent := parent
		this.enabled := enabled

		; Create the tool GUI for the floating list
		this.gui := Gui(
			"-Caption +ToolWindow "
			(this.isWine ? "+Parent" parent.richCode.Hwnd : "+Owner" parent.gui.Hwnd)
		)
		this.gui.MarginX := 0, this.gui.MarginY := 0

		; Create the ListBox control withe appropriate font and styling
		font := parent.Settings.Font
		this.gui.SetFont "s" font.Size, font.Typeface
		this.listBox := this.gui.AddListBox("x0 y0 r1 0x100 AltSubmit")

		; Finish GUI creation and restore the default GUI
		this.gui.Title := parent.title " - AutoComplete"

		; Get relevant dimensions of the ListBox for later resizing
		this.itemHeight := SendMessage(0x1A1, 0, 0, this.listBox) ; LB_GETITEMHEIGHT
		rect := Buffer(16, 0)
		DllCall("GetClientRect", "Ptr", this.listBox.Hwnd, "Ptr", rect)
		this.margins := NumGet(rect, 12, "Int") - this.itemHeight

		; Set up the GDI Device Context for later text measurement in _GetWidth
		this.hDC := DllCall("GetDC", "UPtr", this.listBox.Hwnd, "UPtr")
		this.hFont := DllCall("SelectObject",
			"UPtr", this.hDC,
			"UPtr", SendMessage(0x31, 0, 0, this.listBox.Hwnd), ; WM_GETFONT
			"UPtr")

		; Build the initial word list based on the default words and the
		; RichCode's contents at the time of AutoComplete's initialization
		this.BuildWordList()
	}

	__Delete() {
		DllCall("SelectObject", "UPtr", this.hDC, "UPtr", this.hFont, "UPtr")
		DllCall("ReleaseDC", "UPtr", this.listBox.Hwnd, "UPtr", this.hDC)
	}


	; --- Private Methods ---

	/**
	 * Gets the pixel-width of the widest string using the GDI font of the
	 * ListBox control.
	 * 
	 * @param {String[]} strings - The strings to evaluate
	 * @return {Integer} The width, in pixels
	 */
	_GetWidth(strings) {
		maxWidth := 0
		for text in strings {
			DllCall("GetTextExtentPoint32",
				"UPtr", this.hDC,
				"Str", text,
				"Int", StrLen(text),
				"Int64*", &size := 0)
			size &= 0xFFFFFFFF

			if size > maxWidth
				maxWidth := size
		}
		return maxWidth
	}

	; Shows the suggestion dialog with contents of the provided DisplayList
	_Show() {
		; Insert the new list
		this.listBox.Delete
		this.listBox.Add this.suggestions
		this.listBox.Value := 1

		; Resize to fit contents
		height := this.suggestions.Length * this.itemHeight + this.margins
		width := this._GetWidth(this.suggestions) + 10
		this.listBox.Move unset, unset, width, height

		; Keep the dialog from running off the screen
		x := this.menuX, y := this.menuY + 20
		screenWidth := SysGet(78)
		if x + width > screenWidth
			x := screenWidth - width

		; Make the dialog visible
		this.gui.Show "AutoSize NoActivate x" x "y" y
		this.visible := True
	}

	; Hides the dialog if it is visible
	_Hide() {
		this.gui.Hide
		this.visible := False
	}

	/**
	 * Filters the word list for entries starting with the fragment, then
	 * shows the dialog with the filtered list as suggestions
	 */
	_Suggest() {
		; Filter the list for words beginning with the fragment
		suggestions := LTrim(RegExReplace(this.wordList, "i)\|(?!" this.fragment ")[^\|]+"), "|")

		; Fail out if there were no matches
		if !suggestions {
			this._Hide
			return true
		}

		; Pull the first maxSuggestions suggestions
		if pos := InStr(suggestions, "|", , , this.maxSuggestions)
			suggestions := SubStr(suggestions, 1, pos - 1)

		this.suggestions := StrSplit(suggestions, "|")
		this._Show
	}

	/**
	 * Finishes the fragment with the selected suggestion
	 */
	_Complete() {
		rc := this.parent.RichCode
		rc.Selection[1] -= StrLen(this.fragment)
		rc.SelectedText := this.listBox.Text
		rc.Selection[1] := rc.Selection[2]
		this.fragment := "" ; Clear fragment to prepare for the next completion
	}


	; --- Public Methods ---

	/**
	 * Interpret WM_KEYDOWN messages, the primary means of interfacing with the
	 * class. These messages can be provided by registering an appropriate
	 * handler with OnMessage, or by forwarding the events from another handler
	 * for the control.
	 */
	WM_KEYDOWN(wParam, lParam) {
		if !this._Enabled
			return

		; Get the name of the key using the virtual key code. The key's scan
		; code is not used here, but is available in bits 16-23 of lParam and
		; could be used in future versions for greater reliability.
		key := GetKeyName(Format("vk{:02x}", wParam))

		; Treat Numpad variants the same as the equivalent standard keys
		key := StrReplace(key, "Numpad")

		; Handle presses meant to interact with the dialog, such as
		; navigational, confirmational, or dismissive commands.
		if this.visible {
			if key == "Tab" || key == "Enter" {
				this._Complete
				return false
			} else if key == "Up" {
				this.SelectUp
				return false
			} else if key == "Down" {
				this.SelectDown
				return false
			}
		}

		; Ignore standalone modifier presses, and some modified regular presses
		if key = "Shift" || key = "Control" || key = "Alt"
			return

		; Reset on presses with the control modifier
		if GetKeyState("Control") {
			this.fragment := ""
			return
		}

		; Subtract from the end of fragment on backspace
		if (key == "Backspace") {
			this.fragment := SubStr(this.fragment, 1, -1)
			return
		}

		; Apply Shift and CapsLock
		if GetKeyState("Shift")
			key := StrReplace(StrReplace(key, "-", "_"), "3", "#")
		if GetKeyState("Shift") ^ GetKeyState("CapsLock", "T")
			key := Format("{:U}", key)

		; Reset on unwanted presses -- Allow numbers but not at beginning
		if !(key ~= "^[#A-Za-z_]$" || (this.fragment != "" && key ~= "^[0-9]$")) {
			this.fragment := ""
			return
		}

		; Record the starting position of new fragments
		if this.fragment == "" {
			CoordMode "Caret", "Screen" ;this.isWine ? "Client" : "Screen"

			if CaretGetPos(&x, &y)
				this.menuX := x, this.menuY := y
			else
				this.menuX := 0, this.menuY := 0
		}

		; Update fragment with the press
		this.fragment .= key
	}

	; Triggers a rebuild of the word list from the RichCode control's contents
	BuildWordList() {
		if !this._Enabled
			return

		; Replace non-word chunks with delimiters
		list := RegExReplace(this.parent.richCode.Text, "\W+", "|")

		; Ignore numbers at the beginning of words
		list := RegExReplace(list, "\b[0-9]+")

		; Ignore words that are too small
		list := RegExReplace(list, "\b\w{1," this.minWordLen - 1 "}\b")

		; Append default entries, remove duplicates, and save the list
		list .= this.DefaultWordList
		list := Sort(list, "U D| Z")
		this.wordList := "|" Trim(list, "|")
	}

	/** Moves the selected item in the dialog up one position */
	SelectUp() =>
		this.listBox.Value := Mod(this.listBox.Value + this.suggestions.Length - 2, this.suggestions.Length) + 1

	/** Moves the selected item in the dialog down one position */
	SelectDown() =>
		this.listBox.Value := Mod(this.listBox.Value, this.suggestions.Length) + 1
}