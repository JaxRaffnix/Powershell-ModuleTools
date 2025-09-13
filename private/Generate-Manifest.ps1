New-ModuleManifest -Path .\NVIDIA-Driver-Updater.psd1 `
    -RootModule 'NVIDIA-Driver-Updater.psm1' `
    -ModuleVersion '1.0.0' `
    -Author 'Jan Hoegen' `
    -Description 'Check current NVIDIA driver version and download&install newest release.' `
    -ProjectUri 'https://github.com/JaxRaffnix/NVIDIA-Driver-Updater' `
    -PowerShellVersion '5.1' `
    -FunctionsToExport  @(
        'Update-NVidiaDriver'
    ) `

# TODO: script should be used globally independent of current module. make this a function with input parameters