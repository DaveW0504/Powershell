reg export HKLM\SYSTEM\CurrentControlSet\Services services.reg
schtasks /Query /XML > tasks.xml
netsh advfirewall export firewall.wfw
powercfg /query > powerconfig.txt