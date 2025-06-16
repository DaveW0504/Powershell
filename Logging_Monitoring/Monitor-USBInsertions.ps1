Register-WmiEvent -Query "SELECT * FROM __InstanceCreationEvent WITHIN 5 WHERE TargetInstance ISA 'Win32_USBControllerDevice'" -SourceIdentifier "USBInsert" -Action {
    Write-Host "USB device inserted at: $(Get-Date)"
}