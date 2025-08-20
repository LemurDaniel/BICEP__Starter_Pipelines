<#

This script tests the deployment of a Bicep module.

#>

param(
    [Parameter(
        Mandatory = $true
    )]
    [System.String]
    $ModulePath,

    [Parameter()]
    [Switch]
    $WhatIf
)

. $PSScriptRoot/Invoke-ResourceGroupDeployment.ps1
. $PSScriptRoot/Invoke-SubscriptionDeployment.ps1


$location = 'Westeurope'

$examples = Get-ChildItem -Path $ModulePath -Filter "example*"

for ($index = 0; $index -lt $examples.Count; $index++) {

    Write-Host -ForegroundColor Magenta "------------------------------------------------------"
    Write-Host -ForegroundColor Magenta "Deploying example $index for module $ModulePath"

    $deploymentName = [System.String]::Format('module.{0}.{1}',
        $ModulePath.Replace('/', '.'), $index
    )

    $basePath = $examples[$index].FullName

    $templateFile = Get-Item -Path "$basePath/module.bicep" 
    $parameterFile = Get-Item -Path "$basePath/module.bicepparam"

    Write-Host -ForegroundColor Magenta ""
    Write-Host -ForegroundColor Magenta ""

    Write-Host -ForegroundColor Magenta "------------------------------------------------------"
    Write-Host -ForegroundColor Magenta "Deploying $deploymentName"

    $targetScope = Get-Content -Path $templateFile | Select-String targetScope -Raw

    if ($targetScope -LIKE "*'subscription'*") {
        Invoke-SubscriptionDeployment -DeploymentName $deploymentName `
            -TemplateFile $templateFile `
            -ParameterFile $parameterFile `
            -Location $location `
            -WhatIf:$WhatIf
    } 

    else {
        Invoke-ResourceGroupDeployment -DeploymentName $deploymentName `
            -TemplateFile $templateFile `
            -ParameterFile $parameterFile `
            -Location $location `
            -WhatIf:$WhatIf
    }

}