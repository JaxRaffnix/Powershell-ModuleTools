function Generate-Manifest {
    <#
    .SYNOPSIS
    Generates a PowerShell module manifest (.psd1) from a JSON Config file.

    .DESCRIPTION
    Reads a JSON Config file containing module metadata and generates
    a .psd1 manifest file in the module folder. The module name is
    automatically derived from the folder name.

    .PARAMETER ConfigPath
    Path to the JSON Config file describing the module manifest.

    .EXAMPLE
    Generate-Manifest -ConfigPath ".\module.manifest.json"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModulePath,
    
        [Parameter(Mandatory)]
        [PSCustomObject]$Config,

        [string]$ModuleName = (Split-Path $ModulePath -Leaf)
    )

    # Automatically detect module folder
    $ManifestPath = Join-Path $ModulePath "$ModuleName.psd1"

    $manifestParams = @{
        Path = $ManifestPath
        RootModule = "$ModuleName.psm1"
    }
    
    if ($Config.Author) { $manifestParams.Author = $Config.Author }
    if ($Config.Description) { $manifestParams.Description = $Config.Description }
    if ($Config.ProjectUri) { $manifestParams.ProjectUri = $Config.ProjectUri }
    if ($Config.FunctionsToExport) { $manifestParams.FunctionsToExport = $Config.FunctionsToExport }
    if ($Config.PowerShellVersion) { $manifestParams.PowerShellVersion = $Config.PowerShellVersion } else { $manifestParams.PowerShellVersion = "5.1" }
    if ($Config.ModuleVersion) { $manifestParams.ModuleVersion = $Config.ModuleVersion } else { $manifestParams.ModuleVersion = "1.0.0" }

    # Generate the module manifest
    try {
        New-ModuleManifest @manifestParams
        Write-Host "Manifest created at: '$ManifestPath'" 
    } catch {
        Write-Error "Failed to create manifest: $_"
    }
}
