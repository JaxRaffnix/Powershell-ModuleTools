function Test-PublicExport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ModulePath
    )

    # Validate module path
    $publicFolder = Join-Path -Path $ModulePath -ChildPath 'Public'
    if (-not (Test-Path $publicFolder)) {
        Throw "Public folder not found: $publicFolder"
    }

    # Get all public files
    $publicFiles = Get-ChildItem -Path "$publicFolder\*.ps1" -Recurse -File
    $functionFileMap = @{}

    foreach ($file in $publicFiles) {
        $content = Get-Content $file.FullName -Raw
        $matches = [regex]::Matches($content, '(?m)^\s*function\s+([^\s{(]+)', 'IgnoreCase') |
                   ForEach-Object { $_.Groups[1].Value }
        foreach ($func in $matches) {
            if ($func) {
                $functionFileMap[$func] = $file.FullName
            }
        }
    }

    # Get exported functions (assume Get-PublicFiles returns function names)
    $FunctionsToExport = Get-PublicFiles -ModulePath $ModulePath | Sort-Object -Unique

    # Compare against exported functions
    $missingExports = $functionFileMap.Keys | Where-Object { $_ -notin $FunctionsToExport }

    if ($missingExports) {
        $details = $missingExports | ForEach-Object { "$_ (in $($functionFileMap[$_]))" }
        Write-Error "The following functions exist in public files but are not included in FunctionsToExport:`n$($details -join "`n")"
    } else {
        Write-Information "All public functions are properly exported."
    }
}