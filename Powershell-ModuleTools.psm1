
# Import all private helpers first
Get-ChildItem -Path "$PSScriptRoot\private\*.ps1" -Recurse | ForEach-Object {
    . $_.FullName
}

# Import all public functions
Get-ChildItem -Path "$PSScriptRoot\public\*.ps1" -Recurse | ForEach-Object {
    . $_.FullName
}
