$service = Get-Service -Name "Spooler"
if ($service.Status -ne 'Running') {
    Restart-Service -Name "Spooler"
}