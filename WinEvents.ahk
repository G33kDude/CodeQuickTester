class WinEvents ; static class
{
	static Table := {}
	
	Register(hWnd, Class, Prefix="Gui")
	{
		Gui, +LabelWinEvents.
		this.Table[hWnd] := {Class: Class, Prefix: Prefix}
	}
	
	Unregister(hWnd)
	{
		this.Table.Delete(hWnd)
	}
	
	Dispatch(hWnd, Type)
	{
		Info := this.Table[hWnd]
		
		return Info.Class[Info.Prefix . Type].Call(Info.Class)
	}
	
	; These *CANNOT* be added dynamically or handled dynamically via __Call
	Close()
	{
		return WinEvents.Dispatch(this, "Close")
	}
	
	Escape()
	{
		return WinEvents.Dispatch(this, "Escape")
	}
	
	Size()
	{
		return WinEvents.Dispatch(this, "Size")
	}
	
	ContextMenu()
	{
		return WinEvents.Dispatch(this, "ContextMenu")
	}
	
	DropFiles()
	{
		return WinEvents.Dispatch(this, "DropFiles")
	}
}
