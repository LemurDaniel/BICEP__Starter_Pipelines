function Invoke-SubscriptionDeployment {
    param(
        <#
        [Required]
        The name used for the deployment and resource group.
        #>
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $DeploymentName,

        <#
        [Required]
        Specifies the path to the Bicep template file.
        #>
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $TemplateFile,

        <#
        [Required]
        Specifies the path to the Bicep parameter file.
        #>
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $ParameterFile,

        <#
        [Optional]
        Specifies the Azure location for the resource group deployment. 

        Defaults:
        - 'Westeurope'.
        #>
        [Parameter()]
        [System.String]
        $Location = 'Westeurope',

        <#
        [Optional]
        Switch parameter to enable What-If analysis for the deployment.
        #>
        [Parameter()]
        [Switch]
        $WhatIf
    )

    if ($WhatIf.IsPresent) {
        $Deployment = @{
            Name                    = $deploymentName
            Location                = $location
            TemplateFile            = $templateFile
            TemplateParameterFile   = $parameterFile
            WhatIfResultFormat      = 'FullResourcePayloads'
            WhatIfExcludeChangeType = 'NoChange' # Ignore | NoChange | Deploy | Create | Modify | Delete
        }
        New-AzSubscriptionDeployment @Deployment -WhatIf -Verbose

        $deployment

        $deployment.outputs 
        | ConvertTo-Json
    }
    else {
        $Deployment = @{
            Name                  = $deploymentName
            Location              = $location
            TemplateFile          = $templateFile
            TemplateParameterFile = $parameterFile
            DenySettingsMode      = 'None' # None, DenyDelete, DenyWriteAndDelete
            ActionOnUnmanage      = 'DeleteAll' # DetachAll, DeleteResources, DeleteAll
        }
        $deployment = New-AzSubscriptionDeploymentStack @Deployment -Verbose -Force -Confirm:$false

        $deployment

        $deployment.outputs 
        | ConvertTo-Json

        Remove-AzSubscriptionDeploymentStack -Name $DeploymentName -Force -ErrorAction Continue
    }
}