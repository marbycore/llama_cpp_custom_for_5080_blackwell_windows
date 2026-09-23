Set WshShell = CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")
strScriptPath = FSO.GetParentFolderName(WScript.ScriptFullName)
strDesktop = WshShell.SpecialFolders("Desktop")

Set oShellLink = WshShell.CreateShortcut(strDesktop & "\Llama-Server_RTX5080.lnk")
oShellLink.TargetPath = strScriptPath & "\Llama-Server_RTX5080.bat"
oShellLink.WorkingDirectory = strScriptPath
oShellLink.WindowStyle = 1
oShellLink.Description = "Lanzador Llama-Server RTX 5080"
oShellLink.Save
