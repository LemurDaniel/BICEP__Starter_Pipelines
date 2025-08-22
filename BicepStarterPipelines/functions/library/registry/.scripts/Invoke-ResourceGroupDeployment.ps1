function Invoke-ResourceGroupDeployment {
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


    New-AzResourceGroup -Name $DeploymentName -Location $Location -Force

    if ($WhatIf.IsPresent) {
        $Deployment = @{
            Name                    = $DeploymentName
            ResourceGroupName       = $DeploymentName
            TemplateFile            = $TemplateFile
            TemplateParameterFile   = $ParameterFile
            WhatIfResultFormat      = 'FullResourcePayloads'
            WhatIfExcludeChangeType = 'NoChange'
        }
        $deployment = New-AzResourceGroupDeployment @Deployment -WhatIf -Verbose

        $deployment

        $deployment.outputs 
        | ConvertTo-Json
    }
    else {
        $Deployment = @{
            Name                  = $DeploymentName
            ResourceGroupName     = $DeploymentName
            TemplateFile          = $TemplateFile
            TemplateParameterFile = $ParameterFile
            DenySettingsMode      = 'None'
            ActionOnUnmanage      = 'DeleteAll'
        }
        $deployment = New-AzResourceGroupDeploymentStack @Deployment -Verbose -Force -Confirm:$false

        $deployment

        $deployment.outputs 
        | ConvertTo-Json
    }

    Remove-AzResourceGroup -Name $DeploymentName -Force -ErrorAction Continue
}