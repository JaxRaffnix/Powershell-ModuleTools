function Install-FromDev {
    <#
    .SYNOPSIS
    Installs and imports a PowerShell module from a development folder into the user's module path.

    .DESCRIPTION
    Copies the module folder into the user’s module path:
    $env:USERPROFILE\Documents\WindowsPowerShell\Modules
    If a module with the same name already exists, it is removed first.
    Afterwards, the module is imported into the current session. 
    The module manifest (.psd1) is generated from a JSON config file.

    .PARAMETER ModulePath
    Path to the module folder to install.

    .PARAMETER ConfigPath
    Path to the JSON config file describing the module manifest. Optionally includes the keyowrd IgnoreFiles with ann array of file/folder names to exclude when copying the module.
    Any key/value pair in the JSON is passed to New-ModuleManifest. Path and RootModule are auto-set. ModuleVersion and PowerShellVersion are set to defaults if not provided.

    .PARAMETER ModuleName
    Name of the module. If not provided, it is derived from the ModulePath.

    .EXAMPLE
    Install-FromDev -ModulePath . -ConfigPath .\manifest.json

    .NOTES
    To check allowed keywords for the manifest generator, see: https://learn.microsoft.com/de-de/powershell/module/microsoft.powershell.core/new-modulemanifest?view=powershell-7.5
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModulePath,

        [Parameter(Mandatory)]
        [string]$ConfigPath,

        [string]$ModuleName = (Split-Path $ModulePath -Leaf)
    )

    if ($PSVersionTable.PSVersion.Major -ge 6) {
        $ModuleDirectory = "$env:USERPROFILE\Documents\PowerShell\Modules"
        Write-Warning "Using PowerShell 6+ module directory path."
    } else {
        $ModuleDirectory = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules"
        Write-Warning "Using Windows PowerShell 5 module directory path."
    }
    $TargetPath = Join-Path $ModuleDirectory $ModuleName

    Write-Host "Installing module '$ModuleName' from '$ModulePath' to '$TargetPath'..." -ForegroundColor Cyan


    # --- Preflight: execution policy and PS version ---
    $RequiredPolicy = "RemoteSigned"
    try {
        $CurrentExecutionPolicy = Get-ExecutionPolicy -Scope CurrentUser
        if ($CurrentExecutionPolicy -ne $RequiredPolicy) {
            Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy $RequiredPolicy -Force
            Write-Information "Execution Policy has been set to '$RequiredPolicy' for the current user."
        }
    } catch {
        Write-Error "Failed to set execution policy: $_"
    }

    

    # --- Read config ---
    if (-not (Test-Path $ConfigPath)) {
        throw "Config file not found: $ConfigPath"
    }

    try {
        $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    } catch {
        throw "Failed to read or parse JSON config: $_"
    }


    # --- Generate manifest ---
    $DefaultIgnoreFiles = @(".git", ".gitignore", ".vscode", "README.md", "LICENSE", "manifest.json")
    $IgnoreFiles = if ($config.IgnoreFiles) { $config.IgnoreFiles } else { $DefaultIgnoreFiles }

    Generate-Manifest -ModulePath $ModulePath -Config $config -ModuleName $ModuleName
    
    # --- Remove existing module ---
    if (Get-Module -Name $ModuleName) {
        try {
            Remove-Module -Name $ModuleName -Force -ErrorAction Stop
            Write-Information "Removed loaded module '$ModuleName' from the current session."
        } catch {
            Write-Error "Failed to remove loaded module $ModuleName : $_"
        }
    }

    if (Test-Path $TargetPath) {
        try {
            Remove-Item -Path $TargetPath -Recurse -Force -ErrorAction Stop
            Write-Information "Removed existing module files at: '$TargetPath'."
        } catch {
            Throw "Failed to remove existing module: $_"
        }
    }

    # --- Copy new module files ---
    New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null

    try {
        Copy-Item -Path "$ModulePath\*" -Destination $TargetPath -Recurse -Force -Exclude $IgnoreFiles
        Write-Information "Copied module files successfully." 
    } catch {
        Throw "Failed to copy module files: $_"
    }


    # --- Import module ---
    try {
        Import-Module $TargetPath -Force -ErrorAction Stop
        Write-Host "Module $ModuleName installed successfully." -ForegroundColor Green
    } catch {
        Throw "Failed to import module '$ModuleName': $_"
    }
}
