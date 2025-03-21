# BICEP Starter Pipelines  

Welcome to my **BICEP Starter Pipelines** repository! 😊  

This is supposed to be a central place for starting with a new bicep project.


## ⚠️ Attention  

> This repository is currently a **prototype** and is not fully tested, especially the bash scripts.
>
> I may improve on it in the future. Meanwhile I hope you find it helpful in its current state. 😊
>
> I also included [bicep tests](https://github.com/Azure/bicep/issues/11967), which is currently still in development.
>
> Please, don't hate me all again. I just want to share if it helps someone else. 😅🦖


## Usage  

### Method 1: VS Code Launch-Task (F5)

1. Open the repository in Visual Studio Code.
2. Press `F5` to start a Launch Task.
```PowerShell
PS> init ./destinationFolder
```

### Method 2: Directly call from PowerShell Terminal

```PowerShell
PS> . \init.ps1 ./destinationFolder
```

### Method 3: Put in PowerShell Profile and use whenever needed

1. Copy .library and .scripts at $PROFILE location
2. Add following in Microsoft.PowerShell_profile.ps1
```PowerShell
# Load Functions
. $PSScriptRoot/.scripts/Get-UtilsEscapeCode.ps1
. $PSScriptRoot/.scripts/Read-UtilsUserOption.ps1
. $PSScriptRoot/.scripts/Select-UtilsConsoleMenu.ps1
. $PSScriptRoot/.scripts/Initialize-TemplateDirectory.ps1
```

![Example](./.assets/example.01.png)