
; To be used in conjunction with RichCode.ahk
class Gutter
{
	Width[]
	{
		get {
			return this.config.Gutter.Width * this.zoom
		}
	}
	
	__New(config)
	{
		this.config := config, f := config.Font, g := config.Gutter
		this.lines := 0, this.zoom := 1
		
		; Add the RichEdit control for the gutter
		Gui, Add, Custom, ClassRichEdit50W hWndhWnd +0x5031b1c6 -HScroll -VScroll
		this.hWnd := hWnd
		
		; Set the background and font settings
		fgc := RichCode.BGRFromRGB(g.FGColor)
		bgc := RichCode.BGRFromRGB(g.BGColor)
		VarSetCapacity(CF2, 116, 0)
		NumPut(116,        &CF2+ 0, "UInt") ; cbSize      = sizeof(CF2)
		NumPut(0xE<<28,    &CF2+ 4, "UInt") ; dwMask      = CFM_COLOR|CFM_FACE|CFM_SIZE
		NumPut(f.Size*20,  &CF2+12, "UInt") ; yHeight     = twips
		NumPut(fgc,        &CF2+20, "UInt") ; crTextColor = 0xBBGGRR
		StrPut(f.Typeface, &CF2+26, 32, "UTF-16") ; szFaceName = TCHAR
		SendMessage(0x444, 0, &CF2, this.hWnd) ; EM_SETCHARFORMAT
		SendMessage(0x443, 0,  bgc, this.hWnd) ; EM_SETBKGNDCOLOR
		
		RichCode.SetMargins(hWnd, config.Margins*)
	}
	
	SyncTo(hTarget)
	{
		static BUFF, _ := VarSetCapacity(BUFF, 16, 1)
		
		SendMessage(0x4E0, &BUFF, &BUFF+4, hTarget) ; EM_GETZOOM
		SendMessage(0x4DD,     0, &BUFF+8, hTarget) ; EM_GETSCROLLPOS
		
		; Don't update the gutter unnecessarily
		; TODO: Better state hash
		state := NumGet(BUFF, 0, "UInt") . NumGet(BUFF, 4, "UInt")
		. NumGet(BUFF, 8, "UInt") . NumGet(BUFF, 12, "UInt")
		if (state == this.state)
			return
		this.state := state
		
		NumPut(-1, BUFF, 8, "UInt") ; Don't sync horizontal position
		zoom := [NumGet(BUFF, "UInt"), NumGet(BUFF, 4, "UInt")]
		PostMessage(0x4E1, zoom[1], zoom[2], this.hWnd) ; EM_SETZOOM
		PostMessage(0x4DE,       0, &BUFF+8, this.hWnd) ; EM_SETSCROLLPOS
		this.zoom := zoom[2] ? zoom[1] / zoom[2] : 1
	}
	
	MatchLines(hTarget)
	{
		; Check our line count against the target control's
		ControlGet, lines, LineCount,,, % "ahk_id" hTarget
		if (lines == this.lines)
			return
		
		; Update our line count to match
		Loop, %lines%
			text .= A_Index "`n"
		GuiControl,, % this.hWnd, %text%
		this.lines := lines
		
		; Update scrolling, etc. to match
		this.SyncTo(hTarget)
	}
}
