# Script to identify domain users whose passwords are due to expire in the next 7 days - amend line 7 for number of days.

# Import the Active Directory module
Import-Module ActiveDirectory

# Define the threshold for password expiration (7 days)
$threshold = (Get-Date).AddDays(7)

# Get all domain users
$users = Get-ADUser -Filter * -Property DisplayName, PasswordLastSet, PasswordNeverExpires, AccountExpirationDate

# Iterate through users and check password expiration
$expiringUsers = foreach ($user in $users) {
    if (-not $user.PasswordNeverExpires) {
        $passwordLastSet = $user.PasswordLastSet
        if ($passwordLastSet) {
            $passwordExpiryDate = $passwordLastSet.AddDays((Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge.Days)
            if ($passwordExpiryDate -le $threshold -and $passwordExpiryDate -ge (Get-Date)) {
                [PSCustomObject]@{
                    Name               = $user.DisplayName
                    SamAccountName     = $user.SamAccountName
                    PasswordExpiryDate = $passwordExpiryDate
                }
            }
        }
    }
}

# Output the results
if ($expiringUsers) {
    $expiringUsers | Format-Table -AutoSize
} else {
    Write-Host "No users have passwords expiring in the next 7 days."
}
