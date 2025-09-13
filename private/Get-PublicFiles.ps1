
function Get-PublicFiles {
<#
.SYNOPSIS
Retrieves the base names of all PowerShell script files (*.ps1) in the 'Public' subfolder of a specified root path.

.DESCRIPTION
The Get-PublicFiles function searches for a 'Public' folder within the provided root path. If the folder exists, it lists all PowerShell script files (*.ps1) within that folder and returns their base names (file names without extensions).

.PARAMETER ModulePath
The root directory path that contains the 'Public' subfolder to search for PowerShell script files.

.EXAMPLE
PS C:\> Get-PublicFiles -ModulePath 'C:\Projects\MyModule'
Lists all .ps1 file base names in 'C:\Projects\MyModule\Public'.

.INPUTS
System.String

.OUTPUTS
System.String

.NOTES
Throws an error if the 'Public' folder does not exist under the specified root path.
#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$ModulePath
    )

    $publicFolder = Join-Path -Path $ModulePath -ChildPath 'Public'
    if (-not (Test-Path $publicFolder)) {
        Throw "Public folder not found: $publicFolder"
    }

    Get-ChildItem -Path $publicFolder -Filter '*.ps1' -File | Select-Object -ExpandProperty BaseName
}