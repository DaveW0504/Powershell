$bitlocker = Get-BitLockerVolume
$defender = Get-MpComputerStatus
$firewall = Get-NetFirewallProfile
$rdp = (Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server").fDenyTSConnections
$report = [PSCustomObject]@{
    BitLocker = $bitlocker.VolumeStatus
    DefenderEnabled = $defender.AntispywareEnabled
    FirewallEnabled = $firewall.Enabled
    RDPTerminalAccess = if ($rdp -eq 0) {"Enabled"} else {"Disabled"}
}
$report | Format-List