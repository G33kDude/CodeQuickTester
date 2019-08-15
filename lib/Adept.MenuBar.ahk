
class MenuBar
{
	__New(parent)
	{
		this.menus := CreateMenus(
		( LTrim Join Comments
		[
			["&File", [
				["&New`tCtrl+N", this.New.Bind(this, parent)],
				["&Open`tCtrl+O", this.Open.Bind(this, parent)],
				["&Save`tCtrl+S", this.Save.Bind(this, parent, False)],
				["&Close`tCtrl+W", this.Close.Bind(this, parent)],
				["&Clone", this.Clone.Bind(this, parent)],
				["&Reload`tCtrl+R", this.Reload.Bind(this, parent)]
			]], ["&Navigation", [
				["&Next View`tCtrl+Tab", this.NextView.Bind(this, parent)],
				["&Previous View`tCtrl+Shift+Tab", this.PrevView.Bind(this, parent)]
			]]
		]
		))
		
		Gui, Menu, % this.menus[1]
	}
	
	Destroy()
	{
		for each, name in this.menus
			Menu, %name%, DeleteAll
	}
	
	New(p)
	{
		view := new p.View(p.config)
		p.views.Push(view)
		p.filePane.Update(p)
		p.SwitchTo(view)
	}
	
	Open(p)
	{
		; Prompt user to select files
		Gui, +OwnDialogs
		FileSelectFile, filePaths, M3,, % p._title " - Open Code"
		if ErrorLevel
			return
		
		; Get views for each file
		fileNames := StrSplit(filePaths, "`n")
		filePath := fileNames.removeAt(1)
		for each, fileName in fileNames
			view := p.getView(filePath "\" fileName)
		
		; Update the UI
		p.oFilePane.Update(p)
		p.SwitchTo(view)
	}
	
	Save(p, saveAs:=False)
	{
		; TODO: don't save unmodified file
		
		if (saveAs || !p.activeView.filePath)
		{
			Gui, +OwnDialogs
			FileSelectFile, filePath, S18,, % p._title " - Save Code"
			if ErrorLevel
				return
			; TODO: Check if selected file already exists
			p.activeView.filePath := filePath
		}
		
		FileOpen(p.activeView.filePath, "w").Write(p.activeView.value)
		
		p.activeView.modified := False
		p.oFilePane.Update(p)
		p.Interacted()
	}
	
	Close(p)
	{
		p.CloseView(p.activeView)
	}
	
	Run(p)
	{
		; TODO: dynamic, sanity checks
		Run, % p.activeView.filePath
	}
	
	Clone(p)
	{
		paths := []
		for each, view in p.views
			paths.Push(view.filePath)
		return Run(A_ScriptFullPath, paths*)
	}
	
	Reload(p)
	{
		pid := this.Clone(p)
		WinWait, ahk_class AutoHotkeyGUI ahk_pid %pid%,, 2
		if !ErrorLevel
			ExitApp
	}
	
	NextView(p)
	{
		next := p.IndexFromView(p.activeView)
		next := Mod(next, p.views.length()) + 1
		p.SwitchTo(p.views[next])
	}
	
	PrevView(p)
	{
		prev := p.IndexFromView(p.activeView)
		prev := prev > 1 ? prev - 1 : p.views.length()
		p.SwitchTo(p.views[prev])
	}
}