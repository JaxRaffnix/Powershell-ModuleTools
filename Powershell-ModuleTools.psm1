
# Import all private helpers first
Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -Recurse | ForEach-Object {
    . $_.FullName
}

# Import all public functions
Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -Recurse | ForEach-Object {
    . $_.FullName
}

# Export functions whose names match the public file names and actually exist
$functionsToExport = Get-PublicFiles -ModulePath $PSScriptRoot | Where-Object {
    Get-Command $_ -CommandType Function -ErrorAction SilentlyContinue
}

Export-ModuleMember -Function $functionsToExport
