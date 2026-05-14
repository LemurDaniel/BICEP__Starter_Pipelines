# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

`BicepStarterPipelines` is a PowerShell module (requires PS 7.2+) that scaffolds a complete Azure Bicep project — Bicep infrastructure files, CI/CD pipelines, and optional private Bicep module registries — via an interactive CLI wizard. It is published to the PowerShell Gallery.

## Running and testing

**Run the wizard locally (without installing):**
```powershell
./bicep-init.ps1 ./destinationFolder
```

**Import the module manually:**
```powershell
Import-Module -Name ./BicepStarterPipelines/
Initialize-BicepStarterPipeline -Target ./destinationFolder
```

**Run all Pester tests:**
```powershell
Invoke-Pester -Path ./BicepStarterPipelines.Tests -Output Detailed
```

**Run a single test file:**
```powershell
Invoke-Pester -Path ./BicepStarterPipelines.Tests/Initialize-BicepStartPipeline.Bicep-Init.Tests.ps1 -Output Detailed
```

**Run tests in non-interactive mode** (required for CI — prevents the wizard from prompting):
```powershell
$Global:BicepStarterPipelinesNonInteractive = $true
Invoke-Pester -Path ./BicepStarterPipelines.Tests -Output Detailed
```

**VS Code**: Use the `[Test] Run Pester` task (`tasks.json`) or the `PowerShell: Module Interactive Session` launch config (`.vscode/launch.json`).

## Architecture

### Module entry points

- `BicepStarterPipelines.psm1` — dot-sources the three function files; no logic of its own.
- `Initialize-BicepStarterPipeline.ps1` — the public entry point / wizard. Accepts optional parameters (`-Template`, `-Method`, `-Scope`, `-Pipeline`, `-PipelineOnly`) and prompts interactively for any that are omitted. Delegates to `Initialize-BicepTemplate`.
- `Initialize-BicepTemplate.ps1` — the scaffolding engine. Copies template files to a temp staging directory, runs `init.ps1` in that staging dir to apply selections, flattens `choice.*` folders, then copies the result to the user's target directory.
- `Select-UtilsUserOption.ps1` — reusable interactive single-line menu (arrow-key navigation, colors, pipeline input). Used throughout for all user prompts.

### Template library (`functions/library/`)

```
library/
├── init.ps1           # Selection logic — runs inside staging dir, picks variant files
├── common/            # Copied into every scaffold: bicepconfig.json, naming bicep modules, 
│                      #   shared pipeline step templates (_selections/)
├── deployment/        # Deployment-specific template files + _selections/
└── registry/          # Registry-specific template files + _selections/
```

**How the template system works:**

1. All files from `library/<template>/` and `library/common/` are copied to a temp staging dir (`$TMPDIR/bicep-staging/<guid>`).
2. `init.ps1` runs in the staging dir. Based on the user's choices (`Method`, `Scope`, `Pipeline`), it:
   - Picks exactly one variant file from each `_selections/` subfolder (by matching filename suffixes like `.resource_group`, `.deploy`, `.stack`).
   - Copies selected variants to their final paths (stripping the suffix), then deletes the entire `_selections/` tree.
3. Folders named `choice.<something>` are organizational only — their contents are moved up to the parent folder and the `choice.*` folder is deleted.
4. The staging dir is copied to the user's target directory. On Windows this uses the Shell COM object (shows a progress dialog); on Linux/macOS it uses `Copy-Helper`.
5. The staging dir is always cleaned up in the `CLEAN` block, even on errors.

**Variant file naming convention:**

Files inside `_selections/` carry their selection criteria as filename suffixes after `.yaml`:
- `deploy.infra.yaml.resource_group.deploy` → becomes `deploy.infra.yaml` when scope=`resource_group` and method=`deploy`
- Files matching `.yaml` exactly (no suffix) are always included.

### Publishing

The module is published to PowerShell Gallery via the manually triggered GitHub Actions workflow `.github/workflows/publish-module.yaml`. Publishing requires the `PS_GALLERY_TOKEN` secret. The version comes from `ModuleVersion` in `BicepStarterPipelines.psd1`.
