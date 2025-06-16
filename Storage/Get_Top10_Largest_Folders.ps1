$path = "C:\"
Get-ChildItem $path -Directory | ForEach-Object {
    $_ | Add-Member -NotePropertyName SizeGB -NotePropertyValue (
        "{0:N2}" -f ((Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB)
    ) -PassThru
} | Sort-Object SizeGB -Descending | Select-Object Name, SizeGB -First 10