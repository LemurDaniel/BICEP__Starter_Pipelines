

$deploymentName = "Demo-Deployment-01"
$deploymentLocation = 'Westeurope'

# Log into azure, if not done so already.
# Connect-AzAccount

<#

    Target Subscription is selected via context:

    Either:
    - Connect-AzAccount -Subscription <GUID>
    - Set-AzContext -Subscription <GUID>
    - New-AzSubscriptionDeploymentStack -AzContext <context>

#>

$DeploymentConfig = @{
    <#
        [REQUIRED]

        - Name:                     The deployment stack name.
        - ResourceGroupName:        Target resource group name.
        - TepmplateFile:            Location of Bicep-Template.
        - TemplateParameterFile:    Location of Bicepparam-File.


        [ALTERNATIVES]
        -TemplateUri:               Bicep-Template URL instead of local file path.
        -TemplateParameterUri:      Bicep-Param URL instead of local file path-
        -TemplateParameterObject:   Hashtable of Bicepparams instead of local .bicepparam-File
    #>
    Name                  = $deploymentName
    Location              = $deploymentLocation
    TemplateFile          = "./main.bicep"
    TemplateParameterFile = "./params/main.dev.bicepparam"

    <#
        [OPTIONAL]

        -SkipTemplateParameterPrompt
            For Non-User-Interactive Scripts!
            Changes behaviour to fail on missing parameter, instead of asking for user-input.
            Will fail a pipeline fast instead of blocking and asking for user-input.
    #>
}
    


Write-Host -ForegroundColor Magenta "`n`n------------------------------------------------------"
Write-Host -ForegroundColor Magenta "Deploying '$deploymentName'"

$deployment = New-AzSubscriptionDeployment @DeploymentConfig -Verbose 

$deployment.outputs