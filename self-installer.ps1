# Import all private helpers first
Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -Recurse | ForEach-Object {
    . $_.FullName
}
. "$PSScriptRoot\public\Install-FromDev.ps1"

Install-FromDev -ModulePath $PSScriptRoot  -InformationAction Continue