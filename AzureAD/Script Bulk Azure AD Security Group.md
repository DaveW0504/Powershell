### Script: Bulk Azure AD Security Group Creation



This PowerShell script automates the creation of Azure AD Security Groups using data from a CSV file. It uses the AzureADPreview PowerShell module to interact with Azure Active Directory.



##### **Prerequisites**

**PowerShell**



Run the script on a Windows machine with PowerShell installed.



AzureADPreview Module



The script checks for the AzureADPreview module and installs it if missing.



**Azure Tenant ID**



You must provide your Azure Tenant ID when prompted in the script.



**CSV File**



Create a CSV file at the following path:

C:\\entrabulkcreatesecgroup.csv



The CSV file should contain the following column:



DisplayName

Example content:

SG-Azure-\[Application\_Name]-\[GrpName]



##### **How to Use**

Open PowerShell as Administrator (recommended for module installation).



Update the line in the script with your actual Azure Tenant ID:



Connect-AzureAD -TenantId "ENTER AZURE TENANT ID HERE"

Ensure the CSV file C:\\entrabulkcreatesecgroup.csv exists and is properly formatted.



Run the script.



##### **What the Script Does**

Installs the AzureADPreview module if not already present.



Connects to your Azure Active Directory tenant.



Reads the group names from the provided CSV file.



Creates a security group for each entry in the CSV, with:



MailEnabled = false



SecurityEnabled = true



MailNickName based on the group name (spaces removed)



##### **Error Handling**

The script will exit if:



The CSV file is not found.



It fails to connect to Azure AD.



Group creation errors (e.g., duplicates) are logged as warnings and the script continues with the next group.



##### **Notes**

This script does not check for existing groups before creating new ones.



It's a good practice to test in a non-production environment first.

