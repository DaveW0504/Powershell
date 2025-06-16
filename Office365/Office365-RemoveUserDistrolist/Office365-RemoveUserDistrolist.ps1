# Office365 -remove-distrolist.ps1
# This script checks what distribution lists and shared mailboxes a user is a member of and allows you to remove a user from that group or mailbox

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

# Function to remove user from distribution list or shared mailbox
function Remove-FromResource {
    param (
        [string]$UserEmail,
        [string]$ResourceName,
        [string]$ResourceType
    )
    
    $confirmation = Read-Host "Are you sure you want to remove $UserEmail from $ResourceType '$ResourceName'? (Y/N)"
    if ($confirmation -ne 'Y' -and $confirmation -ne 'y') {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        return
    }
    
    try {
        if ($ResourceType -eq "Distribution List") {
            Remove-DistributionGroupMember -Identity $ResourceName -Member $UserEmail -Confirm:$false
            Write-Host "$UserEmail has been removed from Distribution List '$ResourceName'." -ForegroundColor Green
        } elseif ($ResourceType -eq "Shared Mailbox") {
            Remove-MailboxPermission -Identity $ResourceName -User $UserEmail -AccessRights FullAccess -Confirm:$false
            Write-Host "$UserEmail has been removed from Shared Mailbox '$ResourceName'." -ForegroundColor Green
        }
    }
    catch {
        Write-Error "Failed to remove $UserEmail from $ResourceType '$ResourceName'. Error: $_"
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
    $distributionLists = @()
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
    $sharedMailboxes = @()
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

    # Prompt for action: Remove user from a specific distribution list/shared mailbox or all resources
    $ActionChoice = Read-Host "Choose the action: (1) Remove from a specific distribution list/shared mailbox (2) Remove from all distribution lists/shared mailboxes the user is a member of"

    if ($ActionChoice -eq '1') {
        $ResourceChoice = Read-Host "Enter the name of the distribution list/shared mailbox to remove the user from"
        $ResourceType = Read-Host "Enter the resource type (either 'Distribution List' or 'Shared Mailbox')"
        Remove-FromResource -UserEmail $UserEmailAddress -ResourceName $ResourceChoice -ResourceType $ResourceType
    } elseif ($ActionChoice -eq '2') {
        # Remove user from all distribution lists
        $distributionLists | ForEach-Object {
            Remove-FromResource -UserEmail $UserEmailAddress -ResourceName $_.DisplayName -ResourceType "Distribution List"
        }

        # Remove user from all shared mailboxes
        $sharedMailboxes | ForEach-Object {
            Remove-FromResource -UserEmail $UserEmailAddress -ResourceName $_.Name -ResourceType "Shared Mailbox"
        }
    } else {
        Write-Host "Invalid choice. Please enter 1 or 2." -ForegroundColor Red
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
