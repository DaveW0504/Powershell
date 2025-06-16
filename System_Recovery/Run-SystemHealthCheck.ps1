sfc /scannow
DISM /Online /Cleanup-Image /RestoreHealth
Get-Service | Where-Object {$_.Status -ne "Running"}