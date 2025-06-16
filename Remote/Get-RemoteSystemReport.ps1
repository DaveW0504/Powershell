$computers = Get-Content .\computers.txt
foreach ($comp in $computers) {
    Invoke-Command -ComputerName $comp -ScriptBlock {
        Get-ComputerInfo | Select-Object CsName, WindowsVersion, OsBuildNumber, CsTotalPhysicalMemory
    }
}