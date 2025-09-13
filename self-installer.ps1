. "$PSScriptRoot\private\Generate-Manifest.ps1"
. "$PSScriptRoot\public\Install-FromDev.ps1"

Install-FromDev -ModulePath $PSScriptRoot  -InformationAction Continue