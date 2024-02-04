; AutoHotKey v2 script to open and print an SVG file
fileName := "\Routemap-002-003.svg"
; Get the directory where the script is located
scriptDir := A_ScriptDir

; Full path to the file
filePath := scriptDir . fileName

; Start Google Chrome with the SVG file
Run("chrome.exe " . filePath)

; Wait for Chrome to load the file
WinWait("ahk_exe chrome.exe")

; Sleep for .5  seconds to ensure the page has loaded
Sleep(500)

; Press Ctrl+P to open the print dialog
Send("^p")

; Wait for 0.5 seconds
Sleep(500)

; Send the Enter key to confirm the print command
Send("{Enter}")

; Wait for 1.5 seconds
Sleep(1500)

; Press Ctrl+W to close the tab
Send("^p")

; Wait for 1.5 seconds
Sleep(1500)

; Press Alt + Esc to send Chrome to the back
Send("!{Esc}")
