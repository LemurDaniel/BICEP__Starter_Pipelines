function Initialize-BicepStarterPipeline {
    <#
    .SYNOPSIS
    Initializes a directory with files from a predefined template library.

    .DESCRIPTION
    Generates files based on a selected template from a library of templates into a directory. 

    .OUTPUTS
    None.
    
    #>
    [Alias('bicep-starter', 'bicep-registry')]
    param (
        [Parameter(
            Position = 1,
            Mandatory = $false
        )]
        [System.IO.DirectoryInfo]
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
        [ValidateSet('PowerShell', 'Azure CLI')]
        [System.String]
        $Script = $null,

        [Parameter()]
        [ValidateSet('Github', 'Azure DevOps')]
        [System.String]
        $Pipeline = $null
    )

    if ($PSCmdlet.MyInvocation.InvocationName -IEQ 'bicep-starter') {
        Initialize-BicepTemplate -Template 'deployment' -Target $Target -InitParameter $PSBoundParameters
    } 
    elseif ($PSCmdlet.MyInvocation.InvocationName -IEQ 'bicep-registry') {
        Initialize-BicepTemplate -Template 'registry' -Target $Target -InitParameter $PSBoundParameters
    }
    else {
        throw [System.Exception]::new(@"
        Please use either alias:
        - bicep-starter     for deployment templates
        - bicep-registry    for registry templates
"@)
    }
}