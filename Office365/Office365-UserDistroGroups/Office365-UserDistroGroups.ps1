# Office365-userdistrogroups.ps1
# This script checks what distribution lists and shared mailboxes a user is a member of

# Parameters
param (
    [Parameter(Mandatory=$true)]
    [string]$UserEmailAddress,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeSharedMailboxes = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeDistributionLists = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$ExportToCSV,
    
    [Parameter(Mandatory=$false)]
    [string]$CSVPath = ".\UserMailboxMemberships.csv"
)

# Function to check if Exchange Online PowerShell module is installed and connected
function Test-ExchangeOnlineConnection {
    # Check if the module is installed
    if (!(Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        Write-Host "Exchange Online Management module is not installed. Installing..." -ForegroundColor Yellow
        try {
            Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber -Scope CurrentUser
        }
        catch {
            Write-Error "Failed to install Exchange Online Management module. Please install it manually with: Install-Module -Name ExchangeOnlineManagement"
            exit
        }
    }
    
    # Check if connected to Exchange Online
    try {
        Get-EXOMailbox -ResultSize 1 -ErrorAction Stop
    }
    catch {
        Write-Host "Connecting to Exchange Online..." -ForegroundColor Yellow
        Connect-ExchangeOnline
    }
}

# Function to get all distribution lists a user is member of
function Get-UserDistributionGroups {
    param (
        [string]$UserEmail
    )
    
    Write-Host "Finding distribution lists for $UserEmail..." -ForegroundColor Cyan
    
    try {
        # Get all distribution groups the user is a member of
        $groups = Get-Recipient -ResultSize Unlimited -RecipientTypeDetails MailUniversalDistributionGroup, MailUniversalSecurityGroup | Where-Object {
            (Get-DistributionGroupMember -Identity $_.DistinguishedName -ResultSize Unlimited | ForEach-Object { $_.PrimarySmtpAddress }) -contains $UserEmail
        }
        
        return $groups
    }
    catch {
        Write-Error "Error retrieving distribution groups: $_"
        return $null
    }
}

# Function to get all shared mailboxes a user has access to
function Get-UserSharedMailboxes {
    param (
        [string]$UserEmail
    )
    
    Write-Host "Finding shared mailboxes for $UserEmail..." -ForegroundColor Cyan
    
    try {
        # Get all shared mailboxes
        $sharedMailboxes = Get-EXOMailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited
        $userMailboxes = @()
        
        foreach ($mailbox in $sharedMailboxes) {
            # Get mailbox permissions
            $permissions = Get-EXOMailboxPermission -Identity $mailbox.PrimarySmtpAddress | 
                Where-Object { ($_.User -like "*$UserEmail*" -or $_.User -like "*$($UserEmail.Split('@')[0])*") -and $_.IsInherited -eq $false }
            
            if ($permissions) {
                $userPermission = [PSCustomObject]@{
                    Name = $mailbox.DisplayName
                    Email = $mailbox.PrimarySmtpAddress
                    AccessRights = ($permissions.AccessRights -join ', ')
                }
                $userMailboxes += $userPermission
            }
        }
        
        return $userMailboxes
    }
    catch {
        Write-Error "Error retrieving shared mailboxes: $_"
        return $null
    }
}

# Main script execution
try {
    # Ensure Exchange Online connection
    Ensure-ExchangeOnlineConnection
    
    # Create results array
    $results = @()
    
    # Check if user exists
    try {
        $user = Get-EXORecipient -Identity $UserEmailAddress -ErrorAction Stop
        Write-Host "User found: $($user.DisplayName) ($($user.PrimarySmtpAddress))" -ForegroundColor Green
    }
    catch {
        Write-Error "User with email address '$UserEmailAddress' not found. Please verify the email address and try again."
        exit
    }
    
    # Get distribution lists if requested
    if ($IncludeDistributionLists) {
        $distributionLists = Get-UserDistributionGroups -UserEmail $UserEmailAddress
        
        if ($distributionLists) {
            Write-Host "Distribution Lists membership:" -ForegroundColor Green
            $distributionLists | ForEach-Object {
                Write-Host "  - $($_.DisplayName) ($($_.PrimarySmtpAddress))" -ForegroundColor White
                
                $results += [PSCustomObject]@{
                    UserEmail = $UserEmailAddress
                    ResourceType = "Distribution List"
                    ResourceName = $_.DisplayName
                    ResourceEmail = $_.PrimarySmtpAddress
                    AccessRights = "Member"
                }
            }
        }
        else {
            Write-Host "No distribution list memberships found." -ForegroundColor Yellow
        }
    }
    
    # Get shared mailboxes if requested
    if ($IncludeSharedMailboxes) {
        $sharedMailboxes = Get-UserSharedMailboxes -UserEmail $UserEmailAddress
        
        if ($sharedMailboxes) {
            Write-Host "`nShared Mailboxes access:" -ForegroundColor Green
            $sharedMailboxes | ForEach-Object {
                Write-Host "  - $($_.Name) ($($_.Email)) - Access: $($_.AccessRights)" -ForegroundColor White
                
                $results += [PSCustomObject]@{
                    UserEmail = $UserEmailAddress
                    ResourceType = "Shared Mailbox"
                    ResourceName = $_.Name
                    ResourceEmail = $_.Email
                    AccessRights = $_.AccessRights
                }
            }
        }
        else {
            Write-Host "No shared mailbox access found." -ForegroundColor Yellow
        }
    }
    
    # Export to CSV if requested
    if ($ExportToCSV -and $results.Count -gt 0) {
        $results | Export-Csv -Path $CSVPath -NoTypeInformation
        Write-Host "`nResults exported to $CSVPath" -ForegroundColor Green
    }
    
    Write-Host "`nScript execution completed." -ForegroundColor Green
}
catch {
    Write-Error "An error occurred: $_"
}
