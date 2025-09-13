# Powershell-ModuleTools

Simplify the installation of local PowerShell modules during development.

## Requirements

- PowerShell 7
- Windows 10 or 11  

## Installation

1. Clone or download this repository.  
2. Run the self-installer script:

```powershell
.\self-installer.ps1
```

After running the installer, the function `Install-FromDev` will be available system-wide.

## Usage

`Install-FromDev` allows you to install and import a PowerShell module from a development folder directly into your local modules directory:

```powershell
Install-FromDev -ModulePath <ModulePath> -ConfigPath <ConfigPath> -ModuleName <ModuleName>
```

- ModulePath: Path to the module repository. Use . for the current directory.
- ConfigPath: Path to a JSON configuration file describing the module manifest and ignored files.
- ModuleName (optional): Name of the module to be exported. Defaults to the name of the current folder.

This command will:

1. Remove any existing version of the module from the local module path.
2. Delete old module files.
3. Copy new module files to the local module path.
4. Import the module into the current session.

### Example Config File (manifest.json)

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

## Additional Information

It is recommended to use this default project layout:

```
MyModule/
│
├── MyModule.psd1          # Is generated automatically
├── MyModule.psm1          # Root module (imports/export functions)
│
├── public/                # Exported (public) functions
│   ├── Get-Something.ps1
│   └── Set-Something.ps1
│
├── private/               # Internal helpers (not exported)
│   └── Convert-Helper.ps1
│
└── README.md              
```

Below you can find the recommended structure for your `.psd1` module manifest file. By following this approach, all functions located in the `public` folder with matching file names will be automatically exported, streamlining the module's export process.

```powershell

# Import all private helpers first
Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -Recurse | ForEach-Object {
    . $_.FullName
}

# Import all public functions
Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -Recurse | ForEach-Object {
    . $_.FullName
}

# Export functions whose names match the public file names and actually exist
$functionsToExport = Get-ChildItem "$PSScriptRoot\Public\*.ps1" | ForEach-Object {
    $funcName = $_.BaseName
    if (Get-Command $funcName -CommandType Function -ErrorAction SilentlyContinue) {
        $funcName
    }
}
Export-ModuleMember -Function $functionsToExport
```