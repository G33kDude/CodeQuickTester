; Modified from https://github.com/cocobelgica/AutoHotkey-Util/blob/master/ExecScript.ahk
ExecScript(script, params := "", ahkPath := A_AhkPath) {
	static shell := ComObject("WScript.Shell")
	name := "\\.\pipe\AHK_CQT_" A_TickCount
	cnp := () => DllCall("CreateNamedPipe", "Str", name, "UInt", 2, "UInt", 0,
		"UInt", 255, "UInt", 0, "UInt", 0, "UPtr", 0, "UPtr", 0, "UPtr")
	pipes := [cnp(), cnp(), cnp()]
	if !FileExist(ahkPath)
		throw Error("AutoHotkey runtime not found: " ahkPath)
	if FileExist(name) {
		exec := shell.Exec(ahkPath " /CP65001 " name " " params)
		DllCall("ConnectNamedPipe", "UPtr", pipes[2], "UPtr", 0)
		DllCall("ConnectNamedPipe", "UPtr", pipes[3], "UPtr", 0)
		FileOpen(pipes[3], "h", "UTF-8").Write(script)
	} else { ; Running under WINE with improperly implemented pipes
		FileOpen(name := "AHK_CQT_TMP.ahk", "w").Write(script)
		exec := shell.Exec(ahkPath " /CP65001 " name " " params)
	}
	for v in pipes
		DllCall("CloseHandle", "UPtr", v)
	return exec
}

UrlDownloadToVar(url)
{
	xhr := ComObject("MSXML2.XMLHTTP")
	xhr.Open "GET", url, False
	xhr.Send
	return xhr.ResponseText
}

/**
 * Uploads given content to ahkbin
 * 
 * @param {String} content - The content to upload
 * @param {String} content - The content to upload
 * @param {String} content - The content to upload
 */
Ahkbin(content, name := unset, desc := unset, channel := unset)
{
	form := "code=" UriEncode(content)
	IsSet(name) && form .= "&name=" UriEncode(name)
	IsSet(desc) && form .= "&desc=" UriEncode(desc)
	IsSet(channel) && form .= "&announce=on&channel=" UriEncode(channel)

	xhr := ComObject("MSXML2.XMLHTTP")
	xhr.Open "POST", "https://p.ahkscript.org/", False
	xhr.SetRequestHeader "Content-Type", "application/x-www-form-urlencoded"
	xhr.Send form
	return xhr.getResponseHeader("ahk-location")
}

UriEncode(uri, pattern := "[0-9A-Za-z]") {
	buf := StrBuf(uri, "UTF-8"), out := ""
	while byte := NumGet(buf, A_Index - 1, "UChar") {
		char := Chr(byte)
		out .= char ~= pattern ? char : Format("%{:02x}", byte)
	}
	return out
}

StrBuf(str, encoding) {
	buf := Buffer(StrPut(str, "UTF-8"))
	StrPut(str, buf, "UTF-8")
	return buf
}

class BetterMenuBar extends MenuBar {
	_items := Map()

	__New(structure := []) =>
		BetterMenu.Prototype.__New.Call(this, structure)

	/**
	 * Gets a submenu by name
	 * @param {String} MenuItemName The text of the menu item
	 * @return {BetterMenu}
	 */
	GetSubmenu(MenuItemName) => BetterMenu.Prototype.GetSubmenu.Call(this, MenuItemName)
}

class BetterMenu extends Menu {
	_items := Map()

	__New(structure := []) {
		for entry in structure {
			if entry.Length < 2 {
				this.Add()
				continue
			}
			item := entry[2] is Array ? BetterMenu(entry[2]) : entry[2]
			this.Add(entry[1], item)
			this._items[entry[1]] := item
			if entry.Length >= 3
				this.SetIcon(entry[1], (entry[3] is Array ? entry[3] : [entry[3]])*)
		}
	}

	/**
	 * Gets a submenu by name
	 * @param {String} MenuItemName The text of the menu item
	 * @return {BetterMenu}
	 */
	GetSubmenu(menuItemName) => this._items[menuItemName]
}

iniLoad(Contents)
{
	section := out := Map()
	loop parse contents, "`n", "`r" {
		line := Trim(A_LoopField)
		if line ~= "^;|^$"
			continue
		if RegExMatch(line, "^\[(.+)\]$", &match)
			out[Trim(match.1)] := section := Map()
		else if RegExMatch(line, "^(.+?)=(.*)$", &match)
			section[Trim(match.1)] := Trim(match.2)
	}
	return out
}

GetFullPathName(path) {
	cc := DllCall("GetFullPathName", "Str", path, "UInt", 0, "Ptr", 0, "Ptr", 0, "UInt")
	buf := Buffer(cc * 2)
	DllCall("GetFullPathName", "Str", path, "UInt", cc, "Ptr", buf, "Ptr", 0)
	return StrGet(buf)
}

RichEditAddMargins(hRichEdit, x := 0, y := 0, w := 0, h := 0)
{
	static WINE_VER := 0 ;DllCall("ntdll.dll\wine_get_version", "AStr")
	rect := Buffer(16, 0)
	if !(x || y || w || h)
		return SendMessage(0xB3, 0, rect, hRichEdit)
	; Workaround for bug in Wine 3.0.2.
	; This code will need to be updated this code
	; after future Wine releases that fix it.
	if WINE_VER
		NumPut("Int", x "Int", y, "Int", w, "Int", h, rect)
	else {
		if !DllCall("GetClientRect", "Ptr", hRichEdit, "Ptr", rect, "UInt")
			throw Error("Couldn't get RichEdit Client RECT")
		NumPut(
			"Int", x + NumGet(rect, 0, "Int"),
			"Int", y + NumGet(rect, 4, "Int"),
			"Int", w + NumGet(rect, 8, "Int"),
			"Int", h + NumGet(rect, 12, "Int"),
			rect)
	}
	SendMessage(0xB3, 0, rect, hRichEdit)
}

Print(text) {
	static console := DllCall("AllocConsole")
	FileOpen("CONOUT$", "w", "UTF-8-RAW").Write(text "`n")
}