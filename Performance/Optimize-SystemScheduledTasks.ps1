$tasks = Get-ScheduledTask | Where-Object {$_.TaskName -match "Telemetry|Maps"}
$tasks | Disable-ScheduledTask