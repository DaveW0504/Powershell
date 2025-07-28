# Ensure AzureADPreview module is installed
if (-not (Get-Module -ListAvailable -Name AzureADPreview)) {
    Write-Output "Installing AzureADPreview module..."
    Install-Module -Name AzureADPreview -Force -AllowClobber -Scope CurrentUser
}

# Import the module
Import-Module AzureADPreview

# Set the path to the CSV file - you will need to create this CSV file and populate it with the required group information
$csvPath = "C:\entrabulkcreatesecgroup.csv"

# Check if CSV exists
if (-Not (Test-Path $csvPath)) {
    Write-Error "CSV file not found at path: $csvPath"
    exit
}

# Connect to Azure AD
try {
    Connect-AzureAD -TenantId "ENTER AZURE TENANT ID HERE" #Enter your tenant ID here
} catch {
    Write-Error "Failed to connect to Azure AD: $_"
    exit
}

# Import CSV
$Groups = Import-Csv -Path $csvPath

# Create groups
foreach ($Group in $Groups) {
    try {
        Write-Output "Creating group: $($Group.DisplayName)..."
        New-AzureADGroup -DisplayName $Group.DisplayName `
                         -MailEnabled $false `
                         -SecurityEnabled $true `
                         -MailNickName ($Group.DisplayName -replace '\s', '') # better than "NotSet"
    } catch {
        Write-Warning "Failed to create group $($Group.DisplayName): $_"
    }
}
