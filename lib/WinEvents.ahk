class WinEvents ; static class
{
	static _ := WinEvents.AutoInit()
	
	AutoInit()
	{
		this.Table := []
		OnMessage(2, this.Destroy.bind(this))
	}
	
	Register(ID, HandlerClass, Prefix="Gui")
	{
		Gui, %ID%: +hWndhWnd +LabelWinEvents_
		this.Table[hWnd] := {Class: HandlerClass, Prefix: Prefix}
	}
	
	Unregister(ID)
	{
		Gui, %ID%: +hWndhWnd
		this.Table.Delete(hWnd)
	}
	
	Dispatch(Type, Params*)
	{
		Info := this.Table[Params[1]]
		return (Info.Class)[Info.Prefix . Type](Params*)
	}
	
	Destroy(wParam, lParam, Msg, hWnd)
	{
		this.Table.Delete(hWnd)
	}
}

WinEvents_Close(Params*) {
	return WinEvents.Dispatch("Close", Params*)
} WinEvents_Escape(Params*) {
	return WinEvents.Dispatch("Escape", Params*)
} WinEvents_Size(Params*) {
	return WinEvents.Dispatch("Size", Params*)
} WinEvents_ContextMenu(Params*) {
	return WinEvents.Dispatch("ContextMenu", Params*)
} WinEvents_DropFiles(Params*) {
	return WinEvents.Dispatch("DropFiles", Params*)
}
