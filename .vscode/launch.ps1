param([System.String]$cwd)

# Overwrite default PowerShell Prompt
function Prompt {
    return "PS> "
}

# Load functions
. $cwd/.scripts/Get-UtilsEscapeCode.ps1
. $cwd/.scripts/Read-UtilsUserOption.ps1
. $cwd/.scripts/Initialize-TemplateDirectory.ps1


Clear-Host