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
	
	Dispatch(hWnd, Type, Params*)
	{
		Info := this.Table[hWnd]
		
		; TODO: Figure out the most efficient way to do [a,b*]*
		return Info.Class[Info.Prefix . Type].Call([Info.Class, Params*]*)
	}
	
	; These *CANNOT* be added dynamically or handled dynamically via __Call
	Close(Params*)
	{
		return WinEvents.Dispatch(this, "Close", Params*)
	}
	
	Escape(Params*)
	{
		return WinEvents.Dispatch(this, "Escape", Params*)
	}
	
	Size(Params*)
	{
		return WinEvents.Dispatch(this, "Size", Params*)
	}
	
	ContextMenu(Params*)
	{
		return WinEvents.Dispatch(this, "ContextMenu", Params*)
	}
	
	DropFiles(Params*)
	{
		return WinEvents.Dispatch(this, "DropFiles", Params*)
	}
}
