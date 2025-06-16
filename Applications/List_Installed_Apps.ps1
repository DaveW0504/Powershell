# Win32
Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | 
Select-Object DisplayName, DisplayVersion, Publisher | Sort DisplayName

# UWP
Get-AppxPackage | Select Name, Version