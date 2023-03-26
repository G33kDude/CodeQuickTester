class ServiceHandler ; static class
{
	static Protocol := "ahk"

	static Install() {
		RegWrite(
			"URL:AHK Script Protocol",
			"REG_SZ",
			"HKCU\Software\Classes\" this.protocol
		)
		RegWrite(
			"",
			"REG_SZ",
			"HKCU\Software\Classes\" this.protocol, "URL Protocol"
		)
		RegWrite(
			'"' A_AhkPath '" "' A_ScriptFullPath '" "%1"',
			"REG_SZ",
			"HKCU\Software\Classes\" this.protocol "\shell\open\command"
		)
	}

	static Remove() =>
		RegDelete("HKCU\Software\Classes\" this.protocol)

	static Installed() =>
		!!RegRead("HKCU\Software\Classes\" this.protocol, , False)
}