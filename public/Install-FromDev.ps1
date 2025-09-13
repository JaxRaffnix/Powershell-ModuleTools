function Install-FromDev {
    <#
    .SYNOPSIS
    Installs and imports the a PowerShell module into the user's module path.

    .DESCRIPTION
    Copies the module folder into the user’s module path:
    $env:USERPROFILE\Documents\WindowsPowerShell\Modules

    If a module with the same name already exists, it is removed first.
    Afterwards, the module is imported into the current session.

    .EXAMPLE
    Install-FromDev -ModulePath .
    Installs the module located in the current folder into the user's PowerShell
    module path and imports it.
    #>


    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModulePath, 

        [Parameter(Mandatory)]
        [string]$ConfigPath

    )


    #________________________________________________________________
    # Check powershell version and execution policy


    $RequiredPolicy = "RemoteSigned"
    try {
        $CurrentExecutionPolicy = Get-ExecutionPolicy -Scope CurrentUser
        if ($CurrentExecutionPolicy -ne $RequiredPolicy) {
            Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy $RequiredPolicy -Force
            Write-Host "Execution Policy has been set to '$RequiredPolicy' for the current user."
        }
    } catch {
        Write-Error "Failed to set execution policy: $_"
    }

    if ($PSVersionTable.PSVersion.Major -ne 5) {
        throw "This function requires PowerShell 5.1. Current version: $($PSVersionTable.PSVersion)"
    }


    #________________________________________________________________
    # Check powershell version and execution policy


    # $ModuleName     = Split-Path (Split-Path $ModulePath -Child) -Leaf  # get name of the current folder excluding the full path
    $TargetPath    = Join-Path $env:USERPROFILE "Documents\WindowsPowerShell\Modules" $ModuleName
    
    Write-Host "Installing module $ModuleName from '$ModulePath' to '$TargetPath'..." -ForegroundColor Cyan


    #________________________________________________________________
    # Call Manifest Generator

    # $ManifestScript = Join-Path $ModulePath "tools\Generate-Manifest.ps1"
    # if (Test-Path $ManifestScript) {
    #     try {
    #         & $ManifestScript
    #         Write-Host "Generate-Manifest.ps1 completed successfully." -ForegroundColor Green
    #     } catch {
    #         Write-Error "Failed to run Generate-Manifest.ps1: $_"
    #     }
    # } else {
    #     Write-Warning "Generate-Manifest.ps1 not found. Skipping manifest generation."
    # }
    Generate-Manifest -ConfigPath $ConfigPath


    #________________________________________________________________
    # Remove existing module amd delete old files

    if (Get-Module -Name $ModuleName) {
        try {
            Remove-Module -Name $ModuleName -Force -ErrorAction Stop
            Write-Host "Removed loaded module $ModuleName from the current session."
        } catch {
            Write-Error "Failed to remove loaded module $ModuleName : $_"
        }
    }

    if (Test-Path $TargetPath) {
        try {
            Remove-Item -Path $TargetPath -Recurse -Force -ErrorAction Stop
            Write-Host "Removed existing module files at: '$TargetPath'."
        } catch {
            Write-Error "Failed to remove existing module: $_"
        }
    }

    #________________________________________________________________
    # Copy new files
    try {
        $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    } catch {
        throw "Failed to read or parse JSON config: $_"
    }

    New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null

    $IgnoreFiles = config.$IgnoreFiles

    $ItemsToCopy = Get-ChildItem -Path $ModulePath -Recurse -Force | Where-Object {
        $relativePath = $_.FullName.Substring($ModulePath.Length + 1)
        foreach ($ignore in $IgnoreFiles) {
            if ($relativePath -like "$ignore*") { return $false }
        }
        return $true
    }

    foreach ($item in $ItemsToCopy) {
        $relativePath = $item.FullName.Substring($ModulePath.Length + 1)
        $target = Join-Path $TargetPath $relativePath

        if ($item.PSIsContainer) {
            New-Item -ItemType Directory -Path $target -Force | Out-Null
        } else {
            $destFolder = Split-Path $target -Parent
            if (-not (Test-Path $destFolder)) {
                New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
            }
            Copy-Item -Path $item.FullName -Destination $target -Force
        }
    }

    #________________________________________________________________
    # Import Module

    try {
        Import-Module $TargetPath -Force -ErrorAction Stop
        Write-Host "Module $ModuleName installed successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to import module '$ModuleName': $_"
    }
}
