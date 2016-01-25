class ServiceHandler ; static class
{
	static Protocol := "ahk"
	
	Install()
	{
		Protocol := this.Protocol
		RegWrite, REG_SZ, HKCU, Software\Classes\%Protocol%,, URL:AHK Script Protocol
		RegWrite, REG_SZ, HKCU, Software\Classes\%Protocol%, URL Protocol
		RegWrite, REG_SZ, HKCU, Software\Classes\%Protocol%\shell\open\command,, "%A_AhkPath%" "%A_ScriptFullPath%" "`%1"
	}
	
	Remove()
	{
		Protocol := this.Protocol
		RegDelete, HKCU, Software\Classes\%Protocol%
	}
	
	Installed()
	{
		Protocol := this.Protocol
		RegRead, Out, HKCU, Software\Classes\%Protocol%
		return !ErrorLevel
	}
}
