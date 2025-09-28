function Generate-Manifest {
    <#
    .SYNOPSIS
    Generates a PowerShell module manifest (.psd1) from a JSON config object.

    .DESCRIPTION
    Reads a parsed JSON object and generates a .psd1 manifest.
    Any key/value pair in the JSON is passed to New-ModuleManifest. Path and RootModule are auto-set. ModuleVersion and PowerShellVersion are set to defaults if not provided.

    .PARAMETER ModulePath
    The path to the module directory where the manifest will be created.

    .PARAMETER Config
    The parsed JSON object containing manifest properties.

    .PARAMETER ModuleName
    The name of the module. If not provided, it is derived from the ModulePath.

    .EXAMPLE
    $config = Get-Content .\manifest.json | ConvertFrom-Json
    Generate-Manifest -ModulePath . -Config $config
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModulePath,

        [Parameter(Mandatory)]
        [PSCustomObject]$Config,

        [string]$ModuleName = (Split-Path $ModulePath -Leaf)
    )

    $ManifestPath = Join-Path $ModulePath "$ModuleName.psd1"

    # check if a function in the public folder is not exported
    Test-PublicExport -ModulePath $ModulePath

    $publicFunctions = Get-PublicFiles -ModulePath $ModulePath

    # Mandatory / auto-set fields
    $manifestParams = @{
        Path            = $ManifestPath
        RootModule      = "$ModuleName.psm1"
        ModuleVersion   =  if ($Config.ModuleVersion) { $Config.ModuleVersion } else { "1.0.0" }
        PowerShellVersion = if ($Config.PowerShellVersion) { $Config.PowerShellVersion } else { "5.1" }
        FunctionsToExport = $publicFunctions
    }

    # Add all other key/value pairs dynamically from JSON
    foreach ($key in $Config.PSObject.Properties.Name) {
        if ($manifestParams.ContainsKey($key)) { continue } # skip already set mandatory fields
        if ($key -eq "IgnoreFiles") { continue } # skip IgnoreFiles, not a manifest param
        $manifestParams[$key] = $Config.$key
    }

    try {
        New-ModuleManifest @manifestParams
        Write-Information "Manifest created at '$ManifestPath'"
    } catch {
        throw "Failed to create manifest: $_"
    }
}
