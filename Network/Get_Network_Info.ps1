Get-NetAdapter | Where-Object {$_.Status -eq "Up"} |
ForEach-Object {
    Get-NetIPAddress -InterfaceIndex $_.ifIndex
}