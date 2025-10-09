function Install-FromDev {
<#
.SYNOPSIS
Installs and imports a PowerShell module from a development folder.

.DESCRIPTION
Copies the module folder into the user’s module path.  
Removes any existing copy before installation.  
Calls a custom Generate-Manifest function with config from JSON.  

.PARAMETER ModulePath
Path to the module folder.

.PARAMETER ModuleName
Module name. Defaults to folder name.

.PARAMETER ConfigPath
Path to JSON config file. Defaults to "$ModulePath\$ModuleName.json".
#>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModulePath,

        [string]$ModuleName = (Split-Path $ModulePath -Leaf),

        [string]$ConfigPath = (Join-Path $ModulePath "$ModuleName.json")
    )

    # --- Read config ---
    if (-not (Test-Path $ConfigPath)) {
        throw "Config file not found: $ConfigPath"
    }
    try {
        $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    } catch {
        throw "Failed to parse config JSON: $_"
    }

    # --- Ignore list ---
    $DefaultIgnoreFiles = @(".git", ".gitignore", ".vscode", "README.md", "LICENSE", "manifest.json")
    $IgnoreFiles = if ($config.IgnoreFiles) { $config.IgnoreFiles } else { $DefaultIgnoreFiles }

    # --- Generate manifest via your custom function ---
    Generate-Manifest -ModulePath $ModulePath -Config $config -ModuleName $ModuleName

    # --- Module directories ---
    $ModuleDirectories = @(
    "$env:USERPROFILE\Documents\WindowsPowerShell\Modules",
    "$env:USERPROFILE\Documents\PowerShell\Modules"
) | Where-Object { Test-Path $_ }

foreach ($ModuleDirectory in $ModuleDirectories) {

    $TargetPath = Join-Path $ModuleDirectory $ModuleName
    Write-Host "Installing module '$ModuleName' to '$TargetPath'..." -ForegroundColor Cyan

    # Remove loaded module
    if (Get-Module -Name $ModuleName) {
        Remove-Module -Name $ModuleName -Force -ErrorAction SilentlyContinue
    }

    # Remove old files
    if (Test-Path $TargetPath) {
        Remove-Item -Path $TargetPath -Recurse -Force -ErrorAction Stop
    }

    # Copy files safely
    $ModulePathFull = (Resolve-Path $ModulePath).ProviderPath.TrimEnd('\')

    Get-ChildItem -Path $ModulePathFull -Recurse -Force |
        Where-Object {
            # Skip ignored files/folders
            $name = $_.Name
            $parentDir = $_.PSParentPath.Split('\')[-1]  # immediate parent folder
            -not ($IgnoreFiles -contains $name -or $IgnoreFiles -contains $parentDir)
        } |
        ForEach-Object {
            # Compute relative path
            $relative = $_.FullName.Substring($ModulePathFull.Length).TrimStart('\','/')
            $dest = Join-Path $TargetPath $relative

            # Ensure parent directory exists
            $destParent = Split-Path $dest -Parent
            if ($destParent -and -not (Test-Path $destParent)) {
                New-Item -ItemType Directory -Path $destParent -Force | Out-Null
            }

            # Copy file
            Copy-Item -Path $_.FullName -Destination $dest -Force
        }

    # Import module after copy
    Import-Module $TargetPath -Force -Global -ErrorAction Stop
    Write-Host "Installed module '$ModuleName'." -ForegroundColor Green
}
}