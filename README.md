# CodeQuickTester

CodeQuickTester is a portable single-file script editor that allows you to
write code, and then run it without having to save to a temporary file.

It supports many powerful features and is tightly integrated with the
AutoHotkey language and community.

To learn more about what it does, look in
the features section of this document.

![https://i.imgur.com/VvDa2jx.png](https://i.imgur.com/VvDa2jx.png)<br>
<sub>[Old Image](https://i.imgur.com/eEZ4h8v.png) | [Older Image](
https://i.imgur.com/03W28It.png) | [Example script output](
https://i.imgur.com/QYmKnN4.png)</sub>


## Features

* Requires no external dependencies and is completely self contained (one file!)
* Allows you to run code you've written without saving to a temporary file&sup1;
* Uses a pure-AHK code editing control that supports custom syntax highlighting
* Integrates with the help file to provide always up-to-date syntax tips&sup2;
* Provides suggestions for automatic keyword completion using built in keywords
	and ones pulled from your script
* Includes tools to help you format your code, such as an automatic
	re-indentation tool
* Can have multiple instances of it be run at the same time
* Integrates with the forum and [live chat](
	https://autohotkey.com/boards/viewtopic.php?f=5&t=59)&sup3;
* Can open existing scripts from a file, from a link, or by drag and drop
* Can quickly switch between AutoHotkey versions from a simple menu
<sub>
1. Current versions of Wine for Linux do not support this feature<br>
2. If running in a portable environment, make sure AutoHotkey.chm is in
	the same directory as CodeQuickTester<br>
3. Requires some additional setup
</sub>


## Supported Platforms

* AutoHotkey v1.1 or the equivalent AutoHotkey_H
* Known to work with Windows 7 and above
* Help file integration requires Internet Explorer 8 or above


## Additional Setup (Optional)

### Set as the default script editor
<!-- spoiler -->
1. Run CodeQuickTester as administrator
2. Use the menu bar item `Tools > Set as Default Editor`
3. Test that it has been set as the default editor by right clicking a script
	and clicking `Edit`
<!-- /spoiler -->

### Set up forum integration
<!-- spoiler -->
1. Open CodeQuickTester
2. Use the menu bar item `Tools > Install Service Handler`
3. Open a UserScript enabled web browser (if your browser does not support
	UserScripts natively, you can use the [Violentmonkey extension](
	https://violentmonkey.github.io/about/) to add compatibility)
4. Visit the [forum integration userscript installation page](
	https://gist.github.com/G33kDude/d3d9e4fd7c739dab3527/raw/CodeBox2QuickTest.user.js)
	to be prompted to install the integration userscript
5. Once the userscript is installed, test the integration by navigating to a
	forum post with a code box and clicking `Open` as demonstrated in these two
	gifs: https://i.imgur.com/WJNkKXW.gifv and https://i.imgur.com/P0y6mqe.gifv
<!-- /spoiler -->

### Create a separate settings file to save your settings between updates
<!-- spoiler -->
1. Download a copy of the [settings file template](
	https://github.com/G33kDude/CodeQuickTester/blob/master/Settings.ini)
2. Save that file to the same directory as CodeQuickTester
3. Modify the file to suit your tastes
4. Run CodeQuickTester to verify that the updated settings are reflected
<!-- /spoiler -->

### Compilation instructions
<!-- spoiler -->
CodeQuickTester supports compilation only when using AutoHotkey_H, which is
almost 100% compatible with standard AutoHotkey. To compile CodeQuickTester
into a portable exe file, you can follow these steps:

1. Download a copy of [AutoHotkey_H v1](https://hotkeyit.github.io/v2/)
2. Extract it, and open up the AHK_H version of Ahk2Exe
3. Choose the CodeQuickTester script file and an appropriate icon (typically,
	the file `Ahk2Exe.ico` from the Ahk2Exe directory)
4. Set the `Base File (.bin)` to `AutoHotkey v1.1.X.Y AutoHotkey.exe
	(..\Win32w)` (or `..\Win64w`, just **make sure** the file ends in `.exe`)
5. Click `> Compile Executable <`
6. Copy your compiled CodeQuickTester to a computer without AutoHotkey
	installed to verify that it works correctly (optional)
<!-- /spoiler -->


## Related Projects

[MultiTester.ahk - Create responsive desktop applications using HTML, CSS, JS,
and AHK!](https://autohotkey.com/boards/viewtopic.php?p=190819)

[RichCode.ahk - A pure-AHK code editing control that supports custom syntax
highlighting](https://github.com/G33kDude/RichCode.ahk)


---
# Releases

The latest version can always be found on [the GitHub release page](
https://github.com/G33kDude/CodeQuickTester/releases).

### &#9888; IMPORTANT &#9888;

Make sure to download using the link labeled `CodeQuickTester_vX.Y.ahk` or
`CodeQuickTester_vX.Y.exe`.

Downloading from the link `Source Code` will not include critical libraries
required for the script to function.

### &#9888; IMPORTANT &#9888;
