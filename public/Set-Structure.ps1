function Set-Structure {
    <#
    .SYNOPSIS
    Creates a standard PowerShell module folder structure.

    .DESCRIPTION
    Ensures that required directories (private, public) and base files
    (README.md, manifest.json, .psm1) exist. Optionally copies template
    files from a templates folder.

    .PARAMETER ModulePath
    Path to the module root folder.

    .PARAMETER ModuleName
    Name of the module (defaults to folder name).

    .PARAMETER Force
    Overwrite existing files with templates or recreate base files if they already exist.

    .EXAMPLE
    Set-Structure -ModulePath "C:\Dev\MyModule"
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        # [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$ModulePath,

        [string]$ModuleName = (Split-Path $ModulePath -Leaf),

        [switch]$Force
    )

    $directories = @("private", "public")
    $files = @("README.md", "manifest.json", "$ModuleName.psm1")

    Write-Host "Setting up structure for module '$ModuleName' in '$ModulePath'..." -ForegroundColor Cyan

    foreach ($dir in $directories) {
        $fullPath = Join-Path $ModulePath $dir
        if (-not (Test-Path $fullPath)) {
            try {
                New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
                Write-Information "Created directory: $fullPath"
            } catch {
                throw "Failed to create directory '$fullPath': $_"
            }
        } else {
            Write-Warning "Directory already exists: $fullPath"
        }
    }

    foreach ($file in $files) {
        $fullPath = Join-Path $ModulePath $file
        if (-not (Test-Path $fullPath) -or $Force) {
            try {
                New-Item -ItemType File -Path $fullPath -Force | Out-Null
                if (Test-Path $fullPath -and $Force) {
                    Write-Information "Overwritten file: $fullPath"
                } else {
                    Write-Information "Created file: $fullPath"
                }
            } catch {
                throw "Failed to create or overwrite file '$fullPath': $_"
            }
        } else {
            Write-Warning "File already exists: $fullPath"
        }
    }

    # Copy template files if they exist
    $templateDir = Join-Path $PSScriptRoot "templates"

    $templateFiles = @{
        "$templateDir\mymodule.psm1" = (Join-Path $ModulePath "$ModuleName.psm1")
        "$templateDir\manifest.json" = (Join-Path $ModulePath "manifest.json")
    }

    foreach ($src in $templateFiles.Keys) {
        $dst = $templateFiles[$src]
        if (Test-Path $src) {
            if ((-not (Test-Path $dst)) -or $Force) {
                try {
                    Copy-Item $src -Destination $dst -Force
                    if (Test-Path $dst -and $Force) {
                        Write-Information "Overwritten template: $src -> $dst"
                    } else {
                        Write-Information "Copied template: $src -> $dst"
                    }
                } catch {
                    Throw "Failed to copy template file '$src' to '$dst': $_"
                }
            } else {
                Write-Warning "Template target already exists: $dst"
            }
        } else {
            Throw "Template not found: $src"
        }
    }

    Write-Host "Module structure set up successfully." -ForegroundColor Green
}
