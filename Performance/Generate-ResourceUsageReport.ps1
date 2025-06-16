$cpu = Get-Counter '\Processor(_Total)\% Processor Time'
$mem = Get-Counter '\Memory\Available MBytes'
$disk = Get-Counter '\LogicalDisk(_Total)\% Free Space'
"{0},{1},{2}" -f $cpu.CounterSamples[0].CookedValue, $mem.CounterSamples[0].CookedValue, $disk.CounterSamples[0].CookedValue | Out-File usage.csv -Append