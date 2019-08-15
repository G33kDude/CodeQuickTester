
# Style Guide

## General

* Indentation should be performed using tab characters, and should not
	rely on tabs being set at a specific width.
	* Spaces SHOULD NOT be added after the tabs to push something out to line
		up with the lines above/below it.
	* Additional tabs SHOULD NOT be added for alignment purposes either
* Inter-line alignment in general is discouraged, because
	* It makes future maintenance more difficult, having to update multiple (not always relevant) lines
	* Updating irrelevant lines makes source control diffs less usable, inhibiting collaboration
	* The method of alignment is often arbitrary without consistent rules
* Commas should always be used immediatly after a command, except for flow control
	* Good: `SetTimer, 1`, `if condition`
	* Bad: `SetTimer 1`, `if, condition`
* Parentheses should be used around expressional if statements in most circumstances, except
	* Single term boolean checks (e.g. `if value`, `if !value`, `if ~bits`, `if -negative`)
	* Outside Boolean NOT negating an already parenthetical expression
		* Good: `if !(valueA - valueB == valueC)`
		* Bad: `if (!(conditionOne && conditionTwo))`
* An if statement with two branches should be arranged to avoid Boolean NOT
	* UNLESS one branch is very large while the other is less than around five lines, in which case
		the small branch should be arranged first.
* Globals should be avoided, but when used should be underscore prefixed CapWords (e.g. `_ThatVar`)
* Global constants should be CAPITALIZED_WITH_UNDERSCORES
* Continued expressions should be indented with one tab
* Shorthand in naming should be avoided.

## Braces

* If the block contains only one line, braces should be omitted.
* In the case that braces are necessary, Allman-style braces should be used.
* If one part of an if/else if block has braces, all parts should.
* For nested single-line blocks, no braces should be used.

```ahk
if conditionOne
	MsgBox, No braces
else if conditionTwo
	MsgBox, Still no braces

if conditionThree
{
	; Perform the actions
	MsgBox, Braces
	MsgBox, are fun
}
else if conditionFour
{
	MsgBox, Braces with only one line
}

; Nested single-line blocks
if conditionFive
	if conditionSix
		while True
			MsgBox, hi

; Nested blocks with outermost braces
if conditionSeven
{
	MsgBox, One
	MsgBox, Two
}
else
{
	if conditionEight
		while conditionNine
			ToolTip, Flow control
}
```

## Classes

Names are CapWords
Properties are CapWords
Methods are CapWords
Variables are camelCase
	For internal use only, they're underscore prefixed

# Run Behavior

1. Check if active file is in the open folder
	a. If yes, Check if there's a config file in the root
		i. Use defined main project file
		ii. exit
	b. If no, Check if there's a script matching the folder name
		i. Use matching script
		ii. exit
2. Use active file