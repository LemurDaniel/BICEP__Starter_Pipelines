<#

This script tests the deployment of a Bicep module.

#>

param(
    <#
    [Required]
    The folder prefix container all modules
    e.g. "modules/"
    #>
    [Parameter(
        Mandatory = $true
    )]
    [System.String]
    $FolderPrefix,

    <#
    [Required]
    The path to the Bicep module. Relative to the folder prefix.
    #>
    [Parameter(
        Mandatory = $true
    )]
    [System.String]
    $ModulePath,

    <#
    [Required]
    The location to use for Azure resources.
    #>
    [Parameter(
        Mandatory = $true 
    )]
    [System.String]
    $location,

    [Parameter()]
    [Switch]
    $WhatIf
)

. $PSScriptRoot/Invoke-ResourceGroupDeployment.ps1
. $PSScriptRoot/Invoke-SubscriptionDeployment.ps1

$examples = Get-ChildItem -Path "$folderPrefix/$ModulePath" -Filter "example*" -Directory
$versionJson = Get-Content -Path "$folderPrefix/$ModulePath/version.json" | ConvertFrom-Json

$exclusions = $versionJson.exclude_from.deployment ?? @()

for ($index = 0; $index -lt $examples.Count; $index++) {

    Write-Host -ForegroundColor Magenta "------------------------------------------------------"

    if (($exclusions | Where-Object { $examples[$index].Name -LIKE $_ }).Count -GT 0) {
        Write-Host -ForegroundColor Magenta "Skipping example due to exclusion: $($examples[$index].Name)"
        continue
    }
    else {
        Write-Host -ForegroundColor Magenta "Deploying example $index for module $ModulePath"
    }

    $formatString = "module.{0}.{1}"
    $adjustedPath = $ModulePath

    if ($adjustedPath.Length + $formatString.Length -GT 64) {
        $allowedLength = 64 - $formatString.Length
        $indexStart = $adjustedPath.Length - $allowedLength
        $adjustedPath = $adjustedPath.Substring($indexStart)
    }

    $deploymentName = [System.String]::Format($formatString,
        $adjustedPath.Replace('/', '.'), $index
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