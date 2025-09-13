# PowerShell-ModuleTools

Easily install and update local PowerShell modules during development.

## Requirements

- PowerShell 5.1 or PowerShell 7+
- Windows 10 or 11

## Installation

1. Clone or download this repository.
2. Run the installer script:

    ```powershell
    .\self-installer.ps1
    ```

After installation, the `Install-FromDev` function is available system-wide.

## Usage

`Install-FromDev` installs and imports a PowerShell module from a development folder into your local modules directory:

```powershell
Install-FromDev -ModulePath <ModulePath> -ConfigPath <ConfigPath> [-ModuleName <ModuleName>]
```

- **ModulePath:** Path to the module repository (use `.` for the current directory).
- **ConfigPath:** Path to a JSON config file describing the module manifest. Supports an `IgnoreFiles` array to exclude files/folders when copying. Other key/value pairs are passed to `New-ModuleManifest`. `Path` and `RootModule` are set automatically. Defaults are used for `ModuleVersion` and `PowerShellVersion` if not provided. See [New-ModuleManifest documentation](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/new-modulemanifest?view=powershell-7.5) for allowed keywords.
- **ModuleName (optional):** Name of the module to export. Defaults to the current folder name.

This command will:

1. Remove any existing version of the module from your local module path.
2. Delete old module files.
3. Copy new module files to the local module path.
4. Import the module into the current session.

## Example

```powershell
cd MyModule/
Install-FromDev -ModulePath . -ConfigPath ".\manifest.json"
```

Example `manifest.json`:

```json
{
  "ModuleVersion": "1.0.0",
  "Author": "Jan Hoegen",
  "Description": "Installs and imports a PowerShell module from a development folder into the user's module path.",
  "ProjectUri": "https://github.com/JaxRaffnix/Powershell-ModuleTools",
  "FunctionsToExport": ["Install-FromDev"],
  "PowerShellVersion": "5.1",
  "IgnoreFiles": [".git", ".gitignore", ".vscode", "manifest.json", "self-installer.ps1"]
}
```

## Recommended Project Structure

It is recommended to use this default project layout:

```text
MyModule/
│
├── private/               # Internal helpers (not exported)
│   └── Convert-Helper.ps1
│
├── public/                # Exported (public) functions
│   ├── Get-Something.ps1
│   └── Set-Something.ps1
│
├── manifest.json          # Data for manifest generator
├── MyModule.psd1          # Generated automatically
├── MyModule.psm1          # Root module (imports/exports functions)
└── README.md
```

Below you can find the recommended structure for your `.psd1` file. By following this approach, all functions located in the `public` folder with matching file names will be automatically exported, streamlining the module's export process.

> [!Important] 
> Only functions with matching filenames in the `public` folder will be exported!

Example `MyModule.psm1`:

```powershell
# Import all private helpers
Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -Recurse | ForEach-Object {
     . $_.FullName
}

# Import all public functions
Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -Recurse | ForEach-Object {
     . $_.FullName
}

# Export functions whose names match public file names and actually exist
$functionsToExport = Get-ChildItem "$PSScriptRoot\Public\*.ps1" | ForEach-Object {
     $funcName = $_.BaseName
     if (Get-Command $funcName -CommandType Function -ErrorAction SilentlyContinue) {
          $funcName
     }
}
Export-ModuleMember -Function $functionsToExport
```
