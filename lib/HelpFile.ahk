class HelpFile
{
	static BaseURL := "ms-its:" A_AhkPath "\..\AutoHotkey.chm::/docs/"
	static Cache := {"Syntax": {}}
	
	GetPage(Path)
	{
		static xhttp := ComObjCreate("MSXML2.XMLHTTP.3.0")
		static html := ComObjCreate("htmlfile")
		Path := this.BaseURL . RegExReplace(Path, "[?#].+")
		xhttp.open("GET", Path, True), xhttp.send()
		html.open(), html.write(xhttp.responseText), html.close()
		while html.readyState != "complete"
			Sleep, 50
		return html
	}
	
	GetLookup()
	{
		if this.Lookup
			return this.Lookup
		
		; Scrape the command reference
		this.Commands := {}
		Page := this.GetPage("commands/index.htm")
		rows := Page.querySelectorAll(".info td:first-child a")
		loop, % rows.length
			for i, text in StrSplit((row := rows[A_Index-1]).innerText, "/")
				if RegExMatch(text, "^[\w#]+", Match) && !this.Commands.HasKey(Match)
					this.Commands[Match] := "commands/" row.getAttribute("href")
		
		; Scrape the variables page
		this.Variables := {}
		Page := this.GetPage("Variables.htm")
		rows := html.querySelectorAll(".info td:first-child")
		loop, % rows.length
			if RegExMatch((row := rows[A_Index-1]).innerText, "(A_\w+)", Match)
				this.Variables[Match1] := "Variables.htm#" row.parentNode.getAttribute("id")
		
		; Combine
		this.Lookup := this.Commands.Clone()
		for k, v in Variables
			this.Lookup[k] := v
		
		return this.Lookup
	}
	
	Open(Keyword:="")
	{
		Lookup := this.GetLookup()
		Suffix := Lookup[Keyword] ? Lookup[Keyword] : "AutoHotkey.htm"
		Run, % "hh.exe """ this.BaseURL . Suffix """"
	}
	
	GetSyntax(Keyword:="")
	{
		; Generate this.Commands
		this.GetLookup()
		
		; Only look for Syntax of commands
		if !(Path := this.Commands[Keyword])
			return
		
		; Try to find it in the cache
		if this.Cache.Syntax.HasKey(Keyword)
			return this.Cache.Syntax[Keyword]
		
		; Get the right DOM to search
		Page := this.GetPage(Path)
		if RegExMatch(Path, "#\K.+", ID)
			Page := Page.getElementById(ID)
		
		; Sadly not all commands have accessible syntax tips
		try
			Text := Page.getElementsByClassName("Syntax")[0].innerText
		
		; Cache and return the result
		this.Cache.Syntax[Keyword] := StrSplit(Text, "`n", "`r")[1]
		return this.Cache.Syntax[Keyword]
	}
}
