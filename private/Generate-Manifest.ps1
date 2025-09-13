function Generate-Manifest {
    <#
    .SYNOPSIS
    Generates a PowerShell module manifest (.psd1) from a JSON config file.

    .DESCRIPTION
    Reads a JSON config file containing module metadata and generates
    a .psd1 manifest file in the module folder. The module name is
    automatically derived from the folder name.

    .PARAMETER ConfigPath
    Path to the JSON config file describing the module manifest.

    .EXAMPLE
    Generate-Manifest -ConfigPath ".\module.manifest.json"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath,

        [Parameter(Mandatory)]
        [string]$ModulePath,

        [Parameter(Mandatory)]
        [string]$ModuleName
    )

    if (-not (Test-Path $ConfigPath)) {
        throw "Config file not found: $ConfigPath"
    }

    try {
        $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    } catch {
        throw "Failed to read or parse JSON config: $_"
    }

    # Automatically detect module folder
    $ManifestPath = Join-Path $ModulePath "$ModuleName.psd1"

    # Generate the module manifest
    try {
        New-ModuleManifest -Path $ManifestPath `
            -RootModule "$ModuleName.psm1" `
            -ModuleVersion $config.ModuleVersion `
            -Author $config.Author `
            -Description $config.Description `
            -ProjectUri $config.ProjectUri `
            -PowerShellVersion ($(if ($config.PowerShellVersion) { $config.PowerShellVersion } else { "5.1" })) `
            -FunctionsToExport $config.FunctionsToExport

        Write-Host "Manifest created at: $ManifestPath" -ForegroundColor Green
    } catch {
        Write-Error "Failed to create manifest: $_"
    }
}
