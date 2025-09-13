New-ModuleManifest -Path .\NVIDIA-Driver-Updater.psd1 `
    -RootModule 'NVIDIA-Driver-Updater.psm1' `
    -ModuleVersion '1.0.0' `
    -Author 'Jan Hoegen' `
    -Description 'Check current NVIDIA driver version and download&install newest release.' `
    -ProjectUri 'https://github.com/JaxRaffnix/NVIDIA-Driver-Updater' `
    -PowerShellVersion '5.1' `
    -ScriptsToProcess "core/Initialize-Module.ps1" `
    -FunctionsToExport  @(
        'Update-NVidiaDriver'
    ) `
