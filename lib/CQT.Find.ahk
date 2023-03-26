class Find
{
	title => this.parent.title " - Find"

	__New(parent) {
		this.parent := parent

		this.gui := Gui("+Owner" this.parent.gui.hWnd " +ToolWindow")
		this.gui.MarginX := 5
		this.gui.MarginY := 5

		; Search
		this.editNeedle := this.gui.AddEdit("w200")
		SendMessage 0x1501, true, StrPtr("Search Text"), this.editNeedle ; EM_SETCUEBANNER

		this.gui.AddButton("yp-1 x+m w75 Default", "Find Next")
			.OnEvent("Click", (*) => this.BtnFind())

		this.gui.AddButton("yp x+m w75", "Coun&t All")
			.OnEvent("Click", (*) => this.BtnCount())

		; Replace
		this.editReplace := this.gui.AddEdit("w200 xm Section")
		SendMessage 0x1501, True, StrPtr("Replacement"), this.editReplace ; EM_SETCUEBANNER

		this.gui.AddButton("yp-1 x+m w75", "&Replace")
			.onEvent("Click", (*) => this.Replace())

		this.gui.AddButton("yp1 x+m w75", "Replace &All")
			.onEvent("Click", (*) => this.ReplaceAll())

		; Options
		this.optCase := this.gui.AddCheckbox("xm", "&Case Sensitive")
		this.optRegEx := this.gui.AddCheckbox("xm", "Regular E&xpression")

		this.gui.Title := this.title

		this.gui.OnEvent "Close", (*) => this.gui.Hide()
		this.gui.OnEvent "Escape", (*) => this.gui.Hide()
	}

	Show() {
		this.editNeedle.Focus
		this.gui.Show
	}

	GetNeedle() {
		needle := this.editNeedle.Text
		options := this.optCase.Value ? "`n" : "i`n"
		options .= needle ~= "^[^\(]\)" ? "" : ")"
		if this.optRegEx.Value
			return options . needle
		else
			return options "\Q" StrReplace(needle, "\E", "\E\\E\Q") "\E"
	}

	Find(startingPos := 1, wrapAround := True) {
		needle := this.GetNeedle()

		; Search from StartingPos
		nextPos := RegExMatch(this.parent.RichCode.Text, needle, &Match, startingPos)

		; Search from the top
		if (!nextPos && wrapAround)
			nextPos := RegExMatch(this.parent.RichCode.Text, needle, &Match)

		return nextPos ? [nextPos, nextPos + Match.Len] : False
	}

	BtnFind() {
		this.gui.Opt("OwnDialogs")

		; Find and select the item or error out
		if (pos := this.Find(this.parent.RichCode.Selection[1] + 2))
			this.parent.RichCode.Selection := [pos[1] - 1, pos[2] - 1]
		else
			MsgBox "Search text not found", this.title, 0x30
	}

	BtnCount()
	{
		this.gui.Opt("OwnDialogs")

		; Find and count all instances
		count := 0, start := 1
		while (pos := this.Find(start, False))
			start := pos[1] + 1, count += 1

		MsgBox count " instances found", this.title, 0x40
	}

	Replace()
	{
		; Get the current selection
		sel := this.parent.RichCode.Selection

		; Find the next occurrence including the current selection
		pos := this.Find(sel[1] + 1)

		; If the found item is already selected
		if (sel[1] + 1 == pos[1] && sel[2] + 1 == pos[2]) {
			; Replace it
			if this.optRegEx.Value {
				this.parent.RichCode.SelectedText := RegExReplace(
					this.parent.RichCode.SelectedText,
					this.editNeedle.Text,
					this.editReplace.Text
				)
			} else
				this.parent.RichCode.SelectedText := this.editReplace.Text

			; Find the next item *not* including the current selection
			pos := this.Find(sel[1] + StrLen(this.editReplace.Text) + 1)
		}

		; Select the next found item or error out
		if pos
			this.parent.RichCode.Selection := [pos[1] - 1, pos[2] - 1]
		else
			MsgBox "No more instances found", this.title, 0x30
	}

	ReplaceAll() {
		rc := this.parent.richCode

		; Replace the text in a way that pushes to the undo buffer
		rc.Frozen := True
		sel := rc.Selection
		rc.Selection := [0, -1]
		rc.SelectedText := RegExReplace(
			rc.Text,
			this.GetNeedle(),
			this.editReplace.Text,
			&Count
		)
		rc.Selection := sel
		rc.Frozen := False

		MsgBox Count " instances replaced", this.title, 0x40
	}
}