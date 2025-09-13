. "$PSScriptRoot\private\Generate-Manifest.ps1"
. "$PSScriptRoot\public\Install-FromDev.ps1"

Install-FromDev -ModulePath $PSScriptRoot -ConfigPath "$PSScriptRoot\manifest.json"