param(
    [Parameter(
        Mandatory = $true
    )]
    [System.IO.DirectoryInfo] 
    $Destination
)

Clear-Host

Import-Module -Name .\BicepStarterPipelines\

# Call Template initializer
Initialize-BicepStarterPipeline -Target $Destination