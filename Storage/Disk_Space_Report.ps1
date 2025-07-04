Get-PSDrive -PSProvider 'FileSystem' | 
Select-Object Name, @{Name="Free(GB)";Expression={[math]::round($_.Free/1GB,2)}}, 
@{Name="Used(GB)";Expression={[math]::round(($_.Used)/1GB,2)}}, 
@{Name="Total(GB)";Expression={[math]::round($_.Used/1GB + $_.Free/1GB,2)}}