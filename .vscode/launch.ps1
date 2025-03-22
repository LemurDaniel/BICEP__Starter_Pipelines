param([System.String]$cwd)

# Overwrite default PowerShell Prompt
function Prompt {
    return "PS> "
}

Remove-Module -Name BicepStarterPipelines -Force -ErrorAction SilentlyContinue
Import-Module -Name .\BicepStarterPipelines -Force

Clear-Host