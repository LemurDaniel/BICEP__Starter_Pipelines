function Initialize-BicepStarterPipeline {
    <#
    .SYNOPSIS
    Initializes a directory with files from a predefined template library.

    .DESCRIPTION
    Generates files based on a selected template from a library of templates into a directory. 

    .OUTPUTS
    None.
    
    #>
    [Alias('bicep-init', 'bicep-deployment', 'bicep-registry')]
    param (
        [Parameter(
            Position = 0
        )]
        [ValidateSet('deployment', 'registry')]
        [System.String]
        $Template,

        [Parameter(
            Position = 1,
            Mandatory = $false
        )]
        [System.String]
        $Target = '.',

        [Parameter()]
        [switch]
        $PipelineOnly,

        [Parameter()]
        [ValidateSet('Normal Deployment', 'Deployment Stack')]
        [System.String]
        $Method = $null,

        [Parameter()]
        [ValidateSet('Resource Group', 'Subscription')]
        [System.String]
        $Scope = $null,

        [Parameter()]
        [ValidateSet('Github', 'Azure DevOps')]
        [System.String]
        $Pipeline = $null
    )

    if ($PSCmdlet.MyInvocation.InvocationName -IEQ 'bicep-deployment') {
        $Template = 'deployment'
    } 
    elseif ($PSCmdlet.MyInvocation.InvocationName -IEQ 'bicep-registry') {
        $Template = 'registry'
    }

    if ([System.String]::IsNullOrEmpty($Template)) {
        Write-Host -ForegroundColor Magenta "Select a template?"
        $Template = @(
            @{
                Display = 'Bicep Deployment'
                Value   = 'deployment'
            }
            @{
                Display = 'Bicep Registry'
                Value   = 'registry'
            }
        ) | Select-UtilsUserOption -Return Value
    }

    $Target = [System.IO.Path]::GetFullPath($Target) 
    $PSBoundParameters['Template'] = $Template
    Initialize-BicepTemplate -Template $Template -Target $Target -InitParameter $PSBoundParameters 
}