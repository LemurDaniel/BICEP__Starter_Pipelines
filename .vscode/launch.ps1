param([System.String]$cwd)

# Overwrite default PowerShell Prompt
function Prompt {
    return "PS> "
}

Import-Module -Name .\BicepStarterPipelines\

Clear-Host