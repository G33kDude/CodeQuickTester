class CodeQuickTester
{
	#DllLoad "msftedit.dll"

	static __New() => this.Prototype.__Static := this

	/** @type {String} The string to use for the script editor registry key */
	editorString => '"' A_AhkPath '" "' A_ScriptFullPath '" "%1"'

	/** @type {String} The original string for the script editor registry key */
	origEditorString => "notepad.exe %1"

	/** @type {String} The title of the window */
	title => this.__Class

	/** @type {ComObject} The WshShell.Exec object for the running child */
	exec := unset

	/** @type {Boolean} Whether the tester has a running script */
	running => this.HasOwnProp("exec") ? this.exec.Status == 0 : False

	/** @type {Object} The settings */
	settings := {}

	/** @type {Gui} The underlying GUI */
	gui := Gui("Resize")

	/** @type {Gui.Button} The run button */
	runButton := unset

	/** @type {Gui.StatusBar} The status bar */
	statusBar := unset

	/** @type {RichCode} The code editor */
	richCode := unset

	/** @type {Gui.Custom} The gutter */
	gutter := unset

	/** The open file's path */
	filePath := ""

	lastZoomLevel := 1

	/** @type {HelpFile} */
	helpFile := unset

	/** @type {Object} Bound functions to be released before garbage collection */
	bound := {
		CheckIfRunning: this.CheckIfRunning.Bind(this),
		SyncGutter: this.SyncGutter.Bind(this),
		UpdateStatusBar: this.UpdateStatusBar.Bind(this),
		UpdateAutoComplete: this.UpdateAutoComplete.Bind(this),
		GuiSize: this.GuiSize.Bind(this),
		OnMessage: this.OnMessage.Bind(this),
	}

	/** @type {Integer[]} Array of messages to bind to OnMessage */
	messages => [
		0x111, ; WM_COMMAND
		0x100, ; WM_KEYDOWN
		0x101, ; WM_KEYUP
		0x201, ; WM_LBUTTONDOWN
		0x202, ; WM_LBUTTONUP
		0x204 ; WM_RBUTTONDOWN
	]

	/** @type {Float} The current zoom level */
	zoomLevel := 1.0

	/** @type {Integer} number of lines in the editor */
	lineCount := 0

	/** @type {Boolean} Holds the state of always on top */
	AlwaysOnTop := False

	subWindows := {
		find: this.__Static.Find(this),
		publish: this.__Static.Publish(this),
		scriptOpts: this.__Static.ScriptOpts(this),
	}

	syntaxTip := ""

	__New(settings)
	{
		this.settings := settings

		this.helpFile := HelpFile(this.settings.ChmPath)

		this.gui.MenuBar := BetterMenuBar([
			["&File", [
				["&Run`tF5", (*) => this.OnRunButton(), ["imageres.dll", 283]],
				[],
				["&New Window`tCtrl+N", (*) => this.New(), ["shell32.dll", 3]],
				["&Open...`tCtrl+O", (*) => this.Open(), [A_AhkPath, 2]],
				["&Explore Working Dir`tCtrl+Shift+O", (*) => this.OpenFolder], ; ["shell32.dll", 4]
				["&Save`tCtrl+S", (*) => this.Save(), ["shell32.dll", 7]],
				["Save &As...`tCtrl+Shift+S", (*) => this.Save(true)],
				["Rename...", (*) => this.Rename(), ["shell32.dll", 134]],
				[],
				["&Publish...", (*) => this.Publish(), ["imageres.dll", 166]],
				["&Fetch...", (*) => this.Fetch(), ["imageres.dll", 176]],
				[],
				["E&xit`tCtrl+W", (*) => this.GuiClose()], ; ["shell32.dll", 132]
			]],
			["&Edit", [
				["Find...`tCtrl+F", (*) => this.Find(), ["shell32.dll", 23]],
				[],
				["Comment Selection`tCtrl+K", (*) => this.Comment()],
				["Uncomment Selection`tCtrl+Shift+K", (*) => this.Uncomment()],
				[],
				["Indent Selection", (*) => this.Indent()],
				["Unindent Selection", (*) => this.Unindent()],
				[],
				["Include &Relative", (*) => this.IncludeRel()],
				["Include &Absolute", (*) => this.IncludeAbs()],
				[],
				["Script &Options...", (*) => this.ShowScriptOpts(), ["shell32.dll", 22]],
			]],
			["&Tools", [
				["&Pastebin...`tCtrl+P", (*) => this.Paste(), ["imageres.dll", 242]],
				["Re&indent`tCtrl+I", (*) => this.AutoIndent()],
				[],
				["&AlwaysOnTop`tAlt+A", (*) => this.ToggleOnTop(), ["imageres.dll", 234]],
				["Global Run Hotkeys", (*) => this.GlobalRun(), ["imageres.dll", 174]],
				[],
				["Install Service Handler", (*) => this.ServiceHandler()],
				["Set as Default Editor", (*) => this.DefaultEditor()],
				[],
				["&Highlighter", (*) => this.Highlighter()],
				["AutoComplete", (*) => this.ToggleAutoComplete()],
			]],
			["&Help", [
				["Open &Help File`tCtrl+H", (*) => this.Help(), ["shell32.dll", 24]],
				["&About", (*) => this.About()]
			]]])

		; If set as default, check the highlighter option
		if this.settings.UseHighlighter
			this.gui.MenuBar.GetSubmenu("&Tools").Check("&Highlighter")

		; If set as default, check the global run hotkeys option
		if this.settings.GlobalRun
			this.gui.MenuBar.GetSubmenu("&Tools").Check("Global Run Hotkeys")

		; If set as default, check the AutoComplete option
		if this.settings.UseAutoComplete
			this.gui.MenuBar.GetSubmenu("&Tools").Check("AutoComplete")

		; If service handler is installed, check the menu option
		if ServiceHandler.installed
			this.gui.MenuBar.GetSubmenu("&Tools").Check("Install Service Handler")

		editor := RegRead("HKCR\AutoHotkeyScript\Shell\Edit\Command", , "")
		if editor == this.EditorString
			this.gui.MenuBar.GetSubmenu("&Tools").Check("Set as Default Editor")

		; Register for events
		this.gui.OnEvent("Close", (gui) => this.GuiClose())
		this.gui.OnEvent("DropFiles", (gui, control, files, x, y) => this.GuiDropFiles(files))
		this.gui.OnEvent("Size", (gui, minmax, w, h) => this.GuiSize(w, h, minmax))

		for msg in this.messages
			OnMessage(msg, this.bound.OnMessage)

		; Add code editor and gutter for line numbers
		this.richCode := RichCode(this.gui, this.settings, "-E0x20000")
		RichEditAddMargins this.richCode.Hwnd, 3, 3
		if this.settings.Gutter.Width
			this.AddGutter()

		codeSource := A_Args.Has(1)
			? RegExReplace(A_Args[1], "^ahk:") ; Remove leading service handler
			: this.settings.DefaultPath

		if (codeSource ~= "^https?://")
			this.richCode.Text := UrlDownloadToVar(codeSource)
		else if (codeSource = "Clipboard")
			this.richCode.Text := A_Clipboard
		else if InStr(FileExist(codeSource), "A") {
			this.richCode.Text := FileOpen(codeSource, "r").Read()
			this.richCode.Modified := False

			if (codeSource == this.settings.DefaultPath) {
				; Place cursor after the default template text
				this.richCode.Selection := [-1, -1]
			} else {
				; Keep track of the file currently being edited
				this.FilePath := GetFullPathName(codeSource)

				; Follow the directory of the most recently opened file
				SetWorkingDir codeSource "\.."
			}
		} else {
			this.richCode.Text := "#Requires AutoHotkey v2.0`n`n"
			this.richCode.Selection := [-1, -1]
		}

		if (this.FilePath == "")
			this.gui.MenuBar.GetSubmenu("&File").Disable("Rename...")

		this.runButton := this.gui.AddButton(, "&Run")
		this.runButton.OnEvent("Click", (*) => this.OnRunButton())

		; Add status bar
		this.statusBar := this.gui.AddStatusBar()
		this.UpdateStatusBar()
		ControlGetPos , , , &statusBarHeight, this.statusBar

		/** todo: type or change to parameter */
		this.statusBarHeight := statusBarHeight

		; Initialize the AutoComplete
		this.autoComplete := AutoComplete(this, this.settings.UseAutoComplete)

		this.UpdateTitle()

		this.gui.Show("w640 h480")
	}

	AddGutter()
	{
		s := this.settings
		f := this.settings.Font
		g := this.settings.Gutter

		; Add the RichEdit control for the gutter
		this.gutter := this.gui.AddCustom("ClassRichEdit50W +0x5031b1c6 -HScroll -VScroll")

		; Set the background and font settings
		fgColor := RichCode.BGRFromRGB(g.FGColor)
		bgColor := RichCode.BGRFromRGB(g.BGColor)

		cf2 := Buffer(116, 0)
		NumPut("UInt", 116, cf2, 0)  ; cbSize      = sizeof(CF2)
		NumPut("UInt", 0xE << 28, cf2, 4)  ; dwMask      = CFM_COLOR|CFM_FACE|CFM_SIZE
		NumPut("UInt", f.Size * 20, cf2, 12) ; yHeight     = twips
		NumPut("UInt", fgColor, cf2, 20) ; crTextColor = 0xBBGGRR
		StrPut(f.Typeface, cf2.Ptr + 26, 32, "UTF-16") ; szFaceName = TCHAR
		SendMessage(0x444, 0, cf2, this.gutter) ; EM_SETCHARFORMAT
		SendMessage(0x443, 0, bgColor, this.gutter) ; EM_SETBKGNDCOLOR

		RichEditAddMargins(this.gutter.Hwnd, 3, 3, -3, 0)
	}

	OnRunButton() {
		if this.running {
			this.exec.Terminate() ; CheckIfRunning updates the GUI
			return
		}

		this.exec := ExecScript(this.RichCode.Text
			, this.Settings.Params
			, this.Settings.AhkPath)

		this.runButton.Text := "&Kill"

		SetTimer this.bound.CheckIfRunning, 100
	}

	CheckIfRunning() {
		if !this.running {
			SetTimer this.Bound.CheckIfRunning, 0
			this.runButton.Text := "&Run"
		}
	}

	LoadCode(code, filePath := "")
	{
		; Do nothing if nothing is changing
		if (
			GetFullPathName(this.filePath) == GetFullPathName(filePath) &&
			this.RichCode.Text == code
		)
			return

		; Confirm the user really wants to load new code
		this.gui.Opt("OwnDialogs")
		if "No" == MsgBox(
			"You have unsaved changes, are you sure you want to proceed?",
			this.title " - Confirm Overwrite",
			308
		)
			return

		; If we're changing the open file mark as modified
		; If we're loading a new file mark as unmodified
		this.richCode.Modified := this.filePath == filePath
		this.filePath := filePath
		if (this.filePath == "")
			this.gui.MenuBar.GetSubmenu("&File").Disable("Rename...")
		else
			this.gui.MenuBar.GetSubmenu("&File").Enable("Rename...")

		; Update the GUI
		this.richCode.Text := code
		this.UpdateStatusBar()
	}

	OnMessage(wParam, lParam, msg, hWnd)
	{
		if (
			hWnd == this.gui.Hwnd &&
			msg == 0x111 && ; WM_COMMAND
			lParam == this.RichCode.hWnd
		) { ; for RichEdit
			command := wParam >> 16

			if command == 0x400 { ; An event that fires on scroll
				this.SyncGutter()

				; If the user is scrolling too fast it can cause some messages
				; to be dropped. Set a timer to make sure that when the user stops
				; scrolling that the line numbers will be in sync.
				SetTimer this.bound.SyncGutter, -50
			} else if (Command == 0x200) { ; EN_KILLFOCUS
				if this.Settings.UseAutoComplete
					this.autoComplete.Fragment := ""
			}
		} else if (hWnd == this.richCode.hWnd) {
			; Call UpdateStatusBar after the edit handles the keystroke
			SetTimer this.Bound.UpdateStatusBar, -1

			if this.Settings.UseAutoComplete
			{
				SetTimer this.Bound.UpdateAutoComplete, -Abs(this.settings.ACListRebuildDelay)

				if (msg == 0x100) ; WM_KEYDOWN
					return this.autoComplete.WM_KEYDOWN(wParam, lParam)
				else if (msg == 0x201) ; WM_LBUTTONDOWN
					this.autoComplete.Fragment := ""
			}
		}
		else if hWnd == this.gutter.Hwnd && (
			msg == 0x100 || ; WM_KEYDOWN
			msg == 0x101 || ; WM_KEYUP
			msg == 0x201 || ; WM_LBUTTONDOWN
			msg == 0x202 || ; WM_LBUTTONUP
			msg == 0x204    ; WM_RBUTTONDOWN
		) {
			; Disallow interaction with the gutter
			; TODO: Catch dropped text
			return True
		}
	}

	SyncGutter()
	{
		static buf := Buffer(16, 0)
		if !this.settings.Gutter.Width
			return

		SendMessage(0x4E0, buf.Ptr, buf.Ptr + 4, this.RichCode.hwnd) ; EM_GETZOOM
		SendMessage(0x4DD, 0, buf.Ptr + 8, this.RichCode.hwnd) ; EM_GETSCROLLPOS

		NumPut("UInt", -1, buf, 8) ; Don't sync horizontal position
		zoom := [NumGet(buf, 0, "UInt"), NumGet(buf, 4, "UInt")]
		PostMessage(0x4E1, zoom[1], zoom[2], this.gutter) ; EM_SETZOOM
		SendMessage(0x4DE, 0, buf.ptr + 8, this.gutter) ; EM_SETSCROLLPOS
		this.zoomLevel := zoom[2] == 0 ? 1 : zoom[1] / zoom[2]

		if (this.zoomLevel != this.lastZoomLevel) {
			this.lastZoomLevel := this.zoomLevel
			SetTimer this.bound.GuiSize, -1
		}
	}

	GetKeywordFromCaret() {
		; https://autohotkey.com/boards/viewtopic.php?p=180369#p180369
		rc := this.RichCode
		sel := rc.Selection

		; Get the currently selected line
		LineNum := rc.SendMsg(0x436, 0, sel[1]) ; EM_EXLINEFROMCHAR

		; Size a buffer according to the line's length
		Length := rc.SendMsg(0xC1, sel[1], 0) ; EM_LINELENGTH
		buf := Buffer(length * 2 + 4, 0)
		NumPut("UShort", Length, buf)

		; Get the text from the line
		try rc.SendMsg(0xC4, LineNum, buf) ; EM_GETLINE
		lineText := StrGet(buf, Length)

		; Parse the line to find the word
		LineIndex := rc.SendMsg(0xBB, LineNum, 0) ; EM_LINEINDEX
		start := ""
		if RegExMatch(SubStr(lineText, 1, sel[1] - LineIndex), "[#\w]+$", &Start)
			start := start.0
		end := ""
		if RegExMatch(SubStr(lineText, sel[1] - LineIndex + 1), "^[#\w]+", &End)
			end := end.0

		return start . end
	}

	UpdateStatusBar() {
		; Get the document length and cursor position
		gtl := Buffer(8, 0)
		NumPut("UInt", 1200, gtl, 4)
		len := this.RichCode.SendMsg(0x45F, gtl, 0) ; EM_GETTEXTLENGTHEX (Handles newlines better than GuiControlGet on RE)
		row := EditGetCurrentLine(this.richCode.hWnd)
		col := EditGetCurrentCol(this.richCode.hWnd) ; TODO: expand to tab width

		; Get Selected Text Length
		; If the user has selected 1 char further than the end of the document,
		; which is allowed in a RichEdit control, subtract 1 from the length
		sel := this.RichCode.Selection
		sel := sel[2] - sel[1] - (sel[2] > Len)

		; Get the syntax tip, if any
		if (syntaxTip := this.helpFile.GetSyntax(this.GetKeywordFromCaret()))
			this.syntaxTip := syntaxTip

		; Update the Status Bar text
		this.statusBar.Text := (
			"Len " len
			", "
			"Line " row
			", "
			"Col " col
			(sel > 0 ? ", Sel " sel : "")
			"     "
			StrReplace(this.SyntaxTip, "`n", " | ")
		)

		; Update the title Bar
		this.UpdateTitle()

		; Update the gutter to match the document
		if this.settings.Gutter.Width {
			lines := EditGetLineCount(this.richCode.hWnd)
			if lines > 0 && lines != this.lineCount {
				text := ""
				Loop lines
					text .= A_Index "`n"
				this.gutter.Text := text
				this.LineCount := lines
				this.SyncGutter()
			}
		}
	}

	UpdateTitle() {
		this.gui.Title := (
			this.title
			(this.filePath ? " - " StrSplit(this.filePath, "\").Pop() : "")
			(this.richCode.Modified ? "*" : "")
		)
	}

	UpdateAutoComplete() {
		this.autoComplete.BuildWordList()
	}

	RegisterCloseCallback(callback) {
		this.closeCallback := callback
	}

	GuiSize(w := unset, h := unset, minmax := unset) {
		if !(IsSet(w) && IsSet(h)) {
			rect := Buffer(16, 0)
			DllCall("GetClientRect", "Ptr", this.gui.Hwnd, "Ptr", rect, "UInt")
			w := NumGet(rect, 8, "Int")
			h := NumGet(rect, 12, "Int")
		}

		wGutter := 3 + Round(this.settings.Gutter.Width) * this.zoomLevel

		hStatusBar := this.statusBarHeight

		this.richCode.Move 0 + wGutter, 0, w - wGutter, h - 28 - hStatusBar

		if this.settings.Gutter.Width
			this.gutter.Move 0, 0, wGutter, h - 28 - hStatusBar

		this.runButton.Move 0, h - 28 - hStatusBar, w, 28
	}

	GuiDropFiles(files) {
		; TODO: support multiple file drop
		this.LoadCode FileOpen(files[1], "r").Read(), files[1]
	}

	GuiClose() {
		if this.richCode.Modified {
			this.gui.Opt "OwnDialogs"
			if "No" == MsgBox(
				"There are unsaved changes. Are you sure you want to exit?",
				this.title " - Confirm Exit",
				308)
				return true
		}

		; Free any timers
		for name, boundFunc in this.bound.OwnProps()
			SetTimer boundFunc, 0

		; Release message hooks
		for msg in this.messages
			OnMessage msg, this.bound.OnMessage, 0

		if this.running ; Running
			this.exec.Terminate()

		; Break all the BoundFunc circular references
		this.bound := unset

		; Free up the AC class
		this.autoComplete := unset

		; Release GUI window and control glabels
		this.gui.Destroy()
		this.gui := unset

		ExitApp
	}

	Save(saveAs := false) {
		if saveAs || !this.filePath {
			this.gui.Opt "OwnDialogs"
			path := FileSelect("S18", ,
				this.title " - Save Code", "Script (*.ahk)")
			if !path
				return
			this.filePath := path
		}

		FileOpen(this.FilePath, "w").Write(this.richCode.Text)
		this.richCode.Modified := False
		this.UpdateStatusBar()
	}

	Rename() {
		; Make sure the opened file still exists
		if !InStr(FileExist(this.filePath), "A")
			throw Error("Opened file no longer exists")

		; Ask where to move it to
		this.gui.Opt "OwnDialogs"
		path := FileSelect(
			"S10",
			this.filePath,
			this.title " - Rename As", "Script (*.ahk)")
		if !path
			return
		if InStr(FileExist(path), "A")
			throw Error("Destination file already exists")

		; Attempt to move it
		FileMove this.filePath, path
		this.filePath := path
	}

	Open() {
		this.gui.Opt "OwnDialogs"
		path := FileSelect(3, , this.title " - Open Code", "Script (*.ahk)")
		if !path
			return

		this.LoadCode FileOpen(path, "r").Read(), path

		; Follow the directory of the most recently opened file
		SetWorkingDir path "\.."
		MsgBox "TODO"
		this.subWindows.scriptOpts.UpdateFields()
	}

	OpenFolder() {
		Run 'explorer.exe "' A_WorkingDir '"'
	}

	New() {
		Run A_IsCompiled
			? '"' A_ScriptFullPath '"'
			: '"' A_AhkPath '" "' A_ScriptFullPath '"'
	}

	Publish() {
		this.subWindows.publish.Show()
	}

	Fetch() {
		this.gui.Opt "OwnDialogs"
		if url := Trim(
			InputBox(
				"Enter a URL to fetch code from.",
				this.title " - Fetch Code"
			).value
		)
			this.LoadCode UrlDownloadToVar(url)
	}

	Find() {
		this.subWindows.find.Show()
	}

	Paste() { ; TODO: Recycle PasteInstance
		; if WinExist("ahk_id" this.PasteInstance.hWnd)
		; 	WinActivate "ahk_id" this.PasteInstance.hWnd
		; else
		; 	this.PasteInstance := CQT.Paste(this)
	}

	ShowScriptOpts() {
		this.subWindows.scriptOpts.Show()
	}

	ToggleOnTop() {
		if this.AlwaysOnTop := !this.AlwaysOnTop {
			this.gui.MenuBar.GetSubmenu("&Tools").Check("&AlwaysOnTop`tAlt+A")
			this.gui.Opt("+AlwaysOnTop")
		} else {
			this.gui.MenuBar.GetSubmenu("&Tools").Uncheck("&AlwaysOnTop`tAlt+A")
			this.gui.Opt("-AlwaysOnTop")
		}
	}

	Highlighter() {
		if this.settings.UseHighlighter := !this.Settings.UseHighlighter
			this.gui.MenuBar.GetSubmenu("&Tools").Check("&Highlighter")
		else
			this.gui.MenuBar.GetSubmenu("&Tools").Uncheck("&Highlighter")

		; Force refresh the code, adding/removing any highlighting
		this.richCode.Text := this.richCode.Text
	}

	GlobalRun() {
		if (this.settings.GlobalRun := !this.settings.GlobalRun)
			this.gui.MenuBar.GetSubmenu("&Tools").Check("Global Run Hotkeys")
		else
			this.gui.MenuBar.GetSubmenu("&Tools").Uncheck("Global Run Hotkeys")
	}

	AutoIndent() {
		; this.LoadCode(
		; 	AutoIndent(this.richCode.Value, this.settings.Indent),
		; 	this.filePath
		; )
	}

	Help() {
		this.helpFile.Open(this.GetKeywordFromCaret())
	}

	About() {
		this.gui.Opt "OwnDialogs"
		MsgBox "CodeQuickTester written by GeekDude", this.title " - About"
	}

	ServiceHandler()
	{
		this.gui.Opt "OwnDialogs"

		if ServiceHandler.installed {
			if "Yes" == MsgBox(
				"Are you sure you want to remove CodeQuickTester from being"
				'the default service handler for "ahk:" links ?',
				this.title " - Uninstall Service Handler",
				36
			) {
				ServiceHandler.Remove()
				this.gui.MenuBar.GetSubmenu("&Tools").Uncheck("Install Service Handler")
			}
		} else {
			if "Yes" == MsgBox(
				"Are you sure you want to install CodeQuickTester as the "
				'default service handler for "ahk:" links ?',
				this.title " - Install Service Handler",
				36
			) {
				ServiceHandler.Install()
				this.gui.MenuBar.GetSubmenu("&Tools").Check("Install Service Handler")
			}
		}
	}

	DefaultEditor() {
		this.gui.Opt "OwnDialogs"

		if !A_IsAdmin {
			MsgBox "You must be running as administrator to use this feature",
				this.title " - Change Editor", 48
			return
		}

		editor := RegRead("HKCR\AutoHotkeyScript\Shell\Edit\Command", , "")
		if editor == this.editorString {
			if "Yes" == MsgBox(
				"Are you sure you want to restore the original default editor "
				"for .ahk files?",
				this.Title " - Remove as Default Editor",
				36
			) {
				RegWrite this.origEditorString, "REG_SZ",
					"HKCR\AutoHotkeyScript\Shell\Edit\Command"
				this.gui.MenuBar.GetSubmenu("&Tools").Uncheck("Set as Default Editor")
			}
		} else {
			if "Yes" == MsgBox(
				"Are you sure you want to install CodeQuickTester as the"
				" default editor for .ahk files?",
				this.Title " - Remove as Default Editor",
				36
			) {
				RegWrite this.editorString, "REG_SZ",
					"HKCR\AutoHotkeyScript\Shell\Edit\Command"
				this.gui.MenuBar.GetSubmenu("&Tools").check("Set as Default Editor")
			}
		}
	}

	Comment() => this.richCode.IndentSelection(False, ";")

	Uncomment() => this.richCode.IndentSelection(True, ";")

	Indent() => this.RichCode.IndentSelection()

	Unindent() => this.RichCode.IndentSelection(True)

	Include(relative := false) {
		path := FileSelect(1, , "Pick a script to include", "Script (*.ahk)")
		if !path
			return

		; Get the relative path
		if (relative) {
			VarSetStrCapacity(&relPath, 520) ; MAX_PATH
			if !DllCall("Shlwapi.dll\PathRelativePathTo",
				"Str", &relPath,
				"Str", A_WorkingDir,
				"UInt", 0x10,
				"Str", path,
				"UInt", 0x10
			)
				throw Error("Relative path could not be found")
			path := relPath
		}

		; Select the start of the line
		rc := this.richCode
		top := rc.SendMsg(0x436, 0, rc.Selection[1]) ; EM_EXLINEFROMCHAR
		topLineIndex := rc.SendMsg(0xBB, top, 0) ; EM_LINEINDEX
		rc.Selection := [topLineIndex, topLineIndex]

		; Insert the include
		rc.SelectedText := "#Include " path "`n"
		rc.Selection[1] := rc.Selection[2]
	}

	ToggleAutoComplete() {
		if (this.autoComplete.enabled := !this.autoComplete.enabled)
			this.gui.MenuBar.GetSubmenu("&Tools").Check("AutoComplete")
		else
			this.gui.MenuBar.GetSubmenu("&Tools").Uncheck("AutoComplete")
	}

	; #Include CQT.Paste.ahk
	#Include CQT.Publish.ahk
	#Include CQT.Find.ahk
	#Include CQT.ScriptOpts.ahk
}
