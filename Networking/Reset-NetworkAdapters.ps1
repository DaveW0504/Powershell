Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Restart-NetAdapter -Confirm:$false
Clear-DnsClientCache
ipconfig /renew