param(
    [Parameter(
        Mandatory = $true
    )]
    [System.IO.DirectoryInfo] 
    $Destination
)

# Load Functions
. $PSScriptRoot/.scripts/Get-UtilsEscapeCode.ps1
. $PSScriptRoot/.scripts/Read-UtilsUserOption.ps1
. $PSScriptRoot/.scripts/Initialize-TemplateDirectory.ps1


# Call Template initializer
Initialize-TemplateDirectory -Target $Destination