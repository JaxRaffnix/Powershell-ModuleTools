# PowerShell-ModuleTools

Easily install and update local PowerShell modules during development.

## TODO:

All public functions are exported if they match the filename. If there is a second function in a public file, there will be an error. This is a very hardcoded way of enabling functions.

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

### Install Module from Development Directory

`Install-FromDev` installs and imports a PowerShell module from a development folder into your local modules directory:

```powershell
Install-FromDev -ModulePath <ModulePath> [-ModuleName <ModuleName>, -ConfigPath <ConfigPath>]
```

- **ModulePath:** Path to the module repository (use `.` for the current directory).
- **ModuleName (optional):** Name of the module to export. Defaults to the current folder name.
- **ConfigPath (optional):** Path to a JSON config file describing the module manifest. Supports an `IgnoreFiles` array to exclude files/folders when copying. Other key/value pairs are passed to `New-ModuleManifest`. `Path` and `RootModule` are set automatically. Defaults are used for `ModuleVersion` and `PowerShellVersion` if not provided. See [New-ModuleManifest documentation](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/new-modulemanifest?view=powershell-7.5) for allowed keywords. Defaults to `<ModulePath>\<ModuleName>.json`


This command will:

1. Check if a public function is not exported.
1. Remove any existing version of the module from your local module path.
2. Delete old module files.
3. Copy new module files to the local module path.
4. Import the module into the current session.

#### Example

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
  "PowerShellVersion": "5.1",
  "IgnoreFiles": [".git", ".gitignore", ".vscode", "Powershell-ModuleTools.json", "self-installer.ps1"]
}
```

### Create Project Structure

`New-ModuleStructure` creates a default project structure, including private and public directoriesa and inital template files.

```powershell
New-ModuleStructure -ModulePath <Modulepath> [-ModuleName <ModuleName>, -Force]
```

- **ModulePath:** Path to the module directory.
- **ModuleName: (optional)** Name of the module. Defaults to the folder name.
- **Force (Switch):** If specified, existing data will be overwritten.

This command will:

1. Ensure private/ and public/ directories exist.
2. Create missing files: README.md, manifest.json, and ModuleName.psm1.
3. Copy template versions of manifest.json and MyModule.psm1 from the templates folder.


By following the folder names and using the MyModule.psm1 file, all functions located in the `public` folder with matching file names will be automatically exported, streamlining the module's export process.

> [!Important]
> Only functions with matching filenames in the `public` folder will be exported!

#### Example

```powershell
New-ModuleStructure -Modulepath "MyModule"
```

Result:

```text
MyModule/
│
├── private/               # Internal helpers (not exported)
│
├── public/                # Exported (public) functions
│
├── MyModule.json          # Data for manifest generator
├── MyModule.psd1          # Generated automatically after calling Install-FromDev
├── MyModule.psm1          # Root module (imports/exports functions)
└── README.md
```
