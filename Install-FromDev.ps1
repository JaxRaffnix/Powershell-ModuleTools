<#
.SYNOPSIS
Installs the current PowerShell module into the user's module path.

.DESCRIPTION
This script automates the installation of a PowerShell module by copying the current folder to the user's module path located at 
'$env:USERPROFILE\Documents\PowerShell\Modules'. If a module with the same name already exists, 
it will be overwritten. After copying, the module is imported to make it immediately available 
for use in the current session.

.NOTES
- Ensure this script is run from the module folder.

.EXAMPLE
.\Install.ps1
This command installs the module located in the current folder into the user's PowerShell 
module path and imports it into the current session.
#>

# Elevate privileges
# if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
#     Write-Warning "This script needs to be run as an administrator in PowerShell 7. Restarting with elevated privileges..."
#     Start-Process pwsh.exe "-NoExit -File `"$PSCommandPath`"" -Verb RunAs
#     exit
# }
# if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
#     Write-Warning "This script needs to be run as an administrator in PowerShell 7. Restarting with elevated privileges..."
#     Start-Process pwsh.exe "-NoExit -File `"$PSCommandPath`"" -Verb RunAs
#     exit
# }

# Fix untrusted script execution
$RequiredPolicy = "RemoteSigned"
try {
    $CurrentExecutionPolicy = Get-ExecutionPolicy -Scope CurrentUser
    if ($CurrentExecutionPolicy -ne $RequiredPolicy) {
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy $RequiredPolicy -Force

        Write-Host "Execution Policy has been set to '$RequiredPolicy' for the current user."
    } 
    # else {
    #     Write-Host "Execution Policy is already set to '$CurrentExecutionPolicy' for the current user."
    # }
} catch {
    Write-Error "Failed to set execution policy: $_"
}

# Ensure PowerShell version is 5.1
if ($PSVersionTable.PSVersion.Major -ne 5) {
    Throw "This script requires PowerShell 5.1. Current version: $($PSVersionTable.PSVersion)"
}

# Define Module name and paths
$ModuleName = Split-Path (Split-Path $PSScriptRoot -Parent) -Leaf
$ModulePath = Split-Path -Path $PSScriptRoot -Parent  
$UserModulesPath = Join-Path -Path $env:USERPROFILE -ChildPath "Documents\WindowsPowerShell\Modules"
$TargetPath = Join-Path -Path $UserModulesPath -ChildPath $ModuleName

Write-Host "Installing module $ModuleName from '$ModulePath' to '$TargetPath'..." -ForegroundColor Cyan

# Run Generate-Manifest.ps1 if it exists
$ManifestScript = Join-Path -Path $ModulePath -ChildPath "tools\Generate-Manifest.ps1"
if (Test-Path $ManifestScript) {
    Write-Host "Running Generate-Manifest.ps1..." -ForegroundColor Cyan
    try {
        & $ManifestScript
        Write-Host "Generate-Manifest.ps1 completed successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to run Generate-Manifest.ps1: $_"
    }
} else {
    Write-Warning "Generate-Manifest.ps1 not found. Skipping manifest generation."
}

# Check if the module is already loaded and remove it
if (Get-Module -Name $ModuleName) {
    try {
        Remove-Module -Name $ModuleName -Force -ErrorAction Stop

        Write-Host "Removed loaded module $ModuleName with older version from the current session."
    } catch {
        Write-Error "Failed to remove loaded module $ModuleName with older version : $_"
    }
}

# Remove the existing module folder if it exists
if (Test-Path $TargetPath) {
    try {
        Remove-Item -Path $TargetPath -Recurse -Force -ErrorAction Stop
        
        Write-Host "Removed existing module files with older version at: '$TargetPath'."
    } catch {
        Write-Error "Failed to remove existing module with older version: $_"
    }
}

# Create the target directory after removal
New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
# Create the target directory after removal
New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null

$IgnoreFiles = @(".git", ".gitignore", "setup", "core/Generate-Manifest.ps1")

$ItemsToCopy = Get-ChildItem -Path $ModulePath -Recurse -Force | Where-Object {
    $relativePath = $_.FullName.Substring($ModulePath.Length + 1)
    foreach ($ignore in $IgnoreFiles) {
        if ($relativePath -like "$ignore*") {
            return $false
        }
    }
    return $true
}

foreach ($item in $ItemsToCopy) {
    $relativePath = $item.FullName.Substring($ModulePath.Length + 1)
    $target = Join-Path $TargetPath $relativePath

    if ($item.PSIsContainer) {
        # Create the folder if it's a directory
        New-Item -ItemType Directory -Path $target -Force | Out-Null
    } else {
        # Ensure the destination folder exists
        $destinationFolder = Split-Path $target -Parent
        if (-not (Test-Path $destinationFolder)) {
            New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null
        }

        # Now copy the file
        Copy-Item -Path $item.FullName -Destination $target -Force
    }
}


$ItemsToCopy = Get-ChildItem -Path $ModulePath -Recurse -Force | Where-Object {
    $relativePath = $_.FullName.Substring($ModulePath.Length + 1)
    foreach ($ignore in $IgnoreFiles) {
        if ($relativePath -like "$ignore*") {
            return $false
        }
    }
    return $true
}

foreach ($item in $ItemsToCopy) {
    $relativePath = $item.FullName.Substring($ModulePath.Length + 1)
    $target = Join-Path $TargetPath $relativePath

    if ($item.PSIsContainer) {
        # Create the folder if it's a directory
        New-Item -ItemType Directory -Path $target -Force | Out-Null
    } else {
        # Ensure the destination folder exists
        $destinationFolder = Split-Path $target -Parent
        if (-not (Test-Path $destinationFolder)) {
            New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null
        }

        # Now copy the file
        Copy-Item -Path $item.FullName -Destination $target -Force
    }
}


# Import the module
try {
    # $env:PSModulePath += ";$UserModulesPath"  # Update the environment variable to include the new module path
    # Import-Module $ModuleName -Force -ErrorAction Stop
    Import-Module $TargetPath -Force -ErrorAction Stop
    # $env:PSModulePath += ";$UserModulesPath"  # Update the environment variable to include the new module path
    # Import-Module $ModuleName -Force -ErrorAction Stop
    Import-Module $TargetPath -Force -ErrorAction Stop

    Write-Host "Module $ModuleName installed successfully." -ForegroundColor Green
} catch {
    Write-Error "Failed to install module '$ModuleName': $_"
}
