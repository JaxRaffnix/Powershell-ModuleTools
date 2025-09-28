# Import all private helpers first
Get-ChildItem -Path "$PSScriptRoot\private\*.ps1" -Recurse | ForEach-Object {
    . $_.FullName
}
. "$PSScriptRoot\public\Install-FromDev.ps1"

Install-FromDev -ModulePath $PSScriptRoot  -InformationAction Continue

# Import module so the commands are available immediately
$moduleName = Split-Path $PSScriptRoot -Leaf
Import-Module (Join-Path $PSScriptRoot "$moduleName.psd1") -Force