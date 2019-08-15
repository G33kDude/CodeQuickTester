
class FilePane
{
	paths := []
	
	__New(parent)
	{
		Gui, Add, TreeView, hWndhWnd -E0x200 -Lines AltSubmit
		this.hWnd := hWnd
		
		eventHandler := this.Event.Bind(this, parent)
		GuiControl, +g, % hWnd, % eventHandler
		this.Update(parent)
	}
	
	ViewFromFPID(parent, fpid)
	{
		for each, view in parent.views
			if (view.fpid == fpid)
				return view
	}
	
	Event(parent, hWnd, event, id)
	{
		if (event == "Normal")
		{
			fpid := TV_GetSelection()
			if this.paths[fpid]
				view := parent.GetView(this.paths[fpid], True)
			else
				view := this.ViewFromFPID(parent, fpid)
			parent.SwitchTo(view)
		}
		else if (event == "RightClick")
		{
			; Show right click menu
		}
	}
	
	Update(parent)
	{
		GuiControl, -Redraw, % this.hWnd

		; TODO: Diff the current tree instead of rebuilding
		TV_Delete()
		
		; TODO: add portions of path until unique
		of := TV_Add("Open Files")
		for i, view in parent.views
			view.fpid := TV_Add(view.FileName . (view.modified ? "*" : ""), of, view == parent.activeView ? "Select"  : "")
		TV_Modify(of, "Expand")
		
		od := TV_Add("Open Folder")
		this.paths := []
		this.UpdateHelper(A_ScriptDir, od)
		TV_Modify(od, "Expand")
		
		GuiControl, +Redraw, % this.hWnd
	}
	
	UpdateHelper(path, parent)
	{
		Loop, Files, %path%\*, D
			this.UpdateHelper(A_LoopFileFullPath, TV_Add(A_LoopFileName, parent))
		Loop, Files, %path%\*, F
			this.paths[TV_Add(A_LoopFileName, parent)] := A_LoopFileFullPath
	}
}
