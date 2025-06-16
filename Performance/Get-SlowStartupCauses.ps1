Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Diagnostics-Performance/Operational'; Id=100} | 
Select-Object TimeCreated, Message -First 10