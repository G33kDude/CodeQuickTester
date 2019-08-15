
class View
{
	hWnd[]
	{
		get
		{
			return this.richCode.hWnd
		}
	}
	
	modified[]
	{
		get
		{
			return this.richCode.Modified
		}
		
		set
		{
			return this.richCode.Modified := Value
		}
	}
	
	; TODO: do I really need this?
	fileName[]
	{
		get
		{
			if (this.filePath)
				SplitPath, % this.filePath, Value
			else
				Value := "Unnamed " this.rand
			return Value
		}
	}
	
	value[]
	{
		get
		{
			return this.richCode.Value
		}
	}
	
	__New(config, filePath:="", fpid:=-1)
	{
		this.filePath := filePath
		this.richCode := new RichCode(config, "-E0x20000")
		this.fpid := fpid
		
		; TODO: Handling of invalid files
		if (filePath)
			this.richCode.Value := FileOpen(filePath, "r").Read()
		else if (filePath == "")
		{
			this.richCode.Value := FileOpen(config.DefaultPath, "r").Read()
			this.richCode.Selection := [-1, -1]
		}
		this.modified := false
		
		; TODO: actual unnamed file code
		Random, rand, 1, 9999
		this.rand := rand
	}
}
