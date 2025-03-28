# BICEP Starter Pipelines  

Welcome to my **BICEP Starter Pipelines** repository! 😊  

This is for quickly setting up a bicep project with pipelines

Looks may differ based on which terminal you use.

![Example](./.assets/example.png)

## ⚠️ Attention  

> This repository is currently a **prototype** and is not fully tested.
>
> I may improve on it in the future. Meanwhile I hope you find it helpful in its current state. 😊
>
> I also included [bicep tests](https://github.com/Azure/bicep/issues/11967), which is currently still in development.
>
> Please, don't hate me all again. I just want to share if it helps someone else. 😅🦖
>
>

## ☑️ Platforms  
No guarantee that it will work on other than Windows, though I tested it on my Ubuntu desktop:
- Windows  
- Linux  
- macOS


## 🚀 Usage

### Method 1: Install from [PowerShell Gallery](https://www.powershellgallery.com/packages/BicepStarterPipelines)

1. Install the module from the PowerShell Gallery:
    ```PowerShell
    PS> Install-Module -Name BicepStarterPipelines -Scope CurrentUser
    ```
2. Use the `bicep-init` from terminal:
    ```PowerShell
    PS> bicep-init
    ```

---

### Method 2: Try out without installation

#### VS Code launch task

1. Download an open repository in VSCode
2. Press `F5` to start a Launch Task.
```PowerShell
PS> bicep-init ./destinationFolder
```
--- 
#### PowerShell launch script

1. Download an open repository in any terminal
2. Call the ./bicep-init script
```PowerShell
PS> ./bicep-init ./destinationFolder
```