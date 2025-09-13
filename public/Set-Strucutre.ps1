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
    Overwrite existing files with templates if they already exist.

    .EXAMPLE
    Set-Structure -ModulePath "C:\Dev\MyModule"
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$ModulePath,

        [string]$ModuleName = (Split-Path $ModulePath -Leaf),

        [switch]$Force
    )

    $directories = @("private", "public")
    $files = @("README.md", "manifest.json", "$ModuleName.psm1")

    foreach ($dir in $directories) {
        $fullPath = Join-Path $ModulePath $dir
        if (-not (Test-Path $fullPath)) {
            if ($PSCmdlet.ShouldProcess($fullPath, "Create directory")) {
                try {
                    New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
                    Write-Verbose "Created directory: $fullPath"
                } catch {
                    throw "Failed to create directory '$fullPath': $_"
                }
            }
        } else {
            Write-Verbose "Directory already exists: $fullPath"
        }
    }

    foreach ($file in $files) {
        $fullPath = Join-Path $ModulePath $file
        if (-not (Test-Path $fullPath)) {
            if ($PSCmdlet.ShouldProcess($fullPath, "Create file")) {
                try {
                    New-Item -ItemType File -Path $fullPath -Force | Out-Null
                    Write-Verbose "Created file: $fullPath"
                } catch {
                    throw "Failed to create file '$fullPath': $_"
                }
            }
        } elseif ($Force -and $PSCmdlet.ShouldProcess($fullPath, "Overwrite file")) {
            Write-Verbose "Overwriting existing file: $fullPath"
        } else {
            Write-Verbose "File already exists: $fullPath"
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
                if ($PSCmdlet.ShouldProcess($dst, "Copy template from $src")) {
                    try {
                        Copy-Item $src -Destination $dst -Force
                        Write-Verbose "Copied template: $src -> $dst"
                    } catch {
                        Write-Warning "Failed to copy template file '$src' to '$dst': $_"
                    }
                }
            } else {
                Write-Verbose "Template target already exists: $dst"
            }
        } else {
            Write-Warning "Template not found: $src"
        }
    }

    Write-Host "Module structure set up successfully at '$ModulePath'." -ForegroundColor Green
}
