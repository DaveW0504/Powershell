$threshold = (Get-Date).AddDays(-60)
Get-LocalUser | Where-Object { $_.LastLogon -lt $threshold -and $_.Enabled } | ForEach-Object {
    Disable-LocalUser -Name $_.Name
}