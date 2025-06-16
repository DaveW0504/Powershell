$servers = @("8.8.8.8", "1.1.1.1", "9.9.9.9")
foreach ($server in $servers) {
    $ping = Test-Connection -ComputerName $server -Count 4 -Quiet
    Write-Output "$server reachable: $ping"
}