function New-ModuleStructure {
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
    New-ModuleStructure -ModulePath "C:\Dev\MyModule"
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
    $files = @("README.md")

    Write-Host "Setting up structure for module '$ModuleName' in directory '$ModulePath'..." -ForegroundColor Cyan

    foreach ($dir in $directories) {
        $fullPath = Join-Path $ModulePath $dir
        if (-not (Test-Path $fullPath)) {
            try {
                New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
                Write-Information "Created directory: '$fullPath'"
            } catch {
                throw "Failed to create directory '$fullPath': $_"
            }
        } else {
            Write-Warning "Directory already exists: '$fullPath'"
        }
    }

    foreach ($file in $files) {
        $fullPath = Join-Path $ModulePath $file
        $exists = Test-Path $fullPath

        if (-not $exists -or $Force) {
            try {
                New-Item -ItemType File -Path $fullPath -Force | Out-Null
                if ($exists -and $Force) {
                    Write-Warning ("Overwritten file: '$fullPath'")
                } else {
                    Write-Information ("Created file: '$fullPath'")
                }
            } catch {
                throw "Failed to create or overwrite file '$fullPath': $_"
            }
        } else {
            Write-Warning ("File already exists: '$fullPath'")
        }
    }


    # Copy template files if they exist
    $templateDir = Join-Path (Split-Path $PSScriptRoot -Parent) "templates"

    $templateFiles = @{
        "$templateDir\mymodule.psm1" = (Join-Path $ModulePath "$ModuleName.psm1")
        "$templateDir\mymodule.json" = (Join-Path $ModulePath "$ModuleName.json")
    }

    foreach ($src in $templateFiles.Keys) {
        $dst = $templateFiles[$src]
        if (Test-Path $src) {
            $dstExists = Test-Path $dst
            if (-not $dstExists -or $Force) {
                try {
                    Copy-Item $src -Destination $dst -Force
                    if ($dstExists -and $Force) {
                        Write-Warning "Overwritten template: From '$src' to '$dst'"
                    } else {
                        Write-Information "Copied template: From '$src' to '$dst'"
                    }
                } catch {
                    Throw "Failed to copy template file from '$src' to '$dst': $_"
                }
            } else {
                Write-Warning "Template target already exists: '$dst'"
            }
        } else {
            Throw "Template not found: '$src'"
        }
    }

    Write-Host "Module structure set up successfully." -ForegroundColor Green
}
