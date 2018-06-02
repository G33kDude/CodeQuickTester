class HelpFile
{
	static BaseURL := "ms-its:" A_AhkPath "\..\AutoHotkey.chm::/docs/"
	static Cache := {"Syntax": {}}
	
	GetPage(Path)
	{
		static xhttp := ComObjCreate("MSXML2.XMLHTTP.3.0")
		html := ComObjCreate("htmlfile")
		Path := this.BaseURL . RegExReplace(Path, "[?#].+")
		xhttp.open("GET", Path, True), xhttp.send()
		html.open(), html.write(xhttp.responseText), html.close()
		while !(html.readyState = "interactive" || html.readyState = "complete")
			Sleep, 50
		return html
	}
	
	GetLookup()
	{
		if this.Lookup
			return this.Lookup
		
		; Scrape the command reference
		this.Commands := {}
		try
			Page := this.GetPage("commands/index.htm")
		
		try ; Windows
			rows := Page.querySelectorAll(".info td:first-child a")
		catch ; Wine
			try
				rows := Page.body.querySelectorAll(".info td:first-child a")
		catch ; IE8
		{
			rows := new this.HTMLCollection()
			trows := Page.getElementsByTagName("table")[0].children[0].children
			loop, % trows.length
				rows.push(trows.Item(A_Index-1).children[0].children[0])
		}
		
		loop, % rows.length
			for i, text in StrSplit((row := rows.Item(A_Index-1)).innerText, "/")
				if RegExMatch(text, "^[\w#]+", Match) && !this.Commands.HasKey(Match)
					this.Commands[Match] := "commands/" RegExReplace(row.getAttribute("href"), "^about:")
		
		; Scrape the variables page
		this.Variables := {}
		try
			Page := this.GetPage("Variables.htm")
		
		try ; Windows
			rows := Page.querySelectorAll(".info td:first-child")
		catch ; Wine
			try
				rows := Page.body.querySelectorAll(".info td:first-child")
		catch ; IE8
		{
			rows := new this.HTMLCollection()
			tables := Page.getElementsByTagName("table")
			loop, % tables.length
			{
				trows := tables.Item(A_Index-1).children[0].children
				loop, % trows.length
					rows.push(trows.Item(A_Index-1).children[0])
			}
		}
		
		loop, % rows.length
			if RegExMatch((row := rows.Item(A_Index-1)).innerText, "(A_\w+)", Match)
				this.Variables[Match1] := "Variables.htm#" row.parentNode.getAttribute("id")
		
		; Combine
		this.Lookup := this.Commands.Clone()
		for k, v in this.Variables
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
		Root := Page ; Keep the page root in memory or it will be garbage collected
		if RegExMatch(Path, "#\K.+", ID)
			Page := Page.getElementById(ID)
		
		try ; Windows
			Nodes := page.getElementsByClassName("Syntax")
		catch ; Wine
			try
				Nodes := page.body.getElementsByClassName("Syntax")
		catch ; IE8
			Nodes := page.getElementsByTagName("pre")
		
		try ; Windows
			Text := Nodes.Item(0).innerText
		catch ; Some versions of Wine
			Text := Nodes.Item(0).innerHTML
		
		; Cache and return the result
		this.Cache.Syntax[Keyword] := StrSplit(Text, "`n", "`r")[1]
		return this.Cache.Syntax[Keyword]
	}
	
	class HTMLCollection
	{
		length[]
		{
			get
			{
				; Rounding MaxIndex produces a similar effect
				; to this.Length(), but doesn't trigger recursion
				return Round(this.MaxIndex())
			}
		}
		
		Item(i)
		{
			return this[i+1]
		}
	}
}
