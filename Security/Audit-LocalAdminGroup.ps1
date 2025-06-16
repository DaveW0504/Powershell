$admins = Get-LocalGroupMember -Group "Administrators"
$admins | Select-Object Name, ObjectClass | Export-Csv "AdminsAudit.csv" -NoTypeInformation