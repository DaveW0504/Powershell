$pass = [System.Web.Security.Membership]::GeneratePassword(16,3)
New-LocalUser "SecAdmin" -Password (ConvertTo-SecureString $pass -AsPlainText -Force) -FullName "Secure Admin" -Description "Managed Account"
Add-LocalGroupMember -Group "Administrators" -Member "SecAdmin"
$pass | Out-File "C:\SecAdminPassword.txt"