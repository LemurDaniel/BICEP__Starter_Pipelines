param(
  [System.IO.DirectoryInfo] $stagingDir,
  [System.String]$Method = $null,
  [System.String]$Scope = $null,
  [System.String]$Script = $null,
  [System.String]$Pipeline = $null,
  [switch]$PipelineOnly
)

<#
    #############################
    #### Deployment Method
#>

$deploymentMethods = [ordered]@{
  'Normal Deployment' = 'deploy'
  'Deployment Stack'  = 'stack'
}

if ([System.String]::IsNullOrEmpty($Method)) {
  Write-Host -ForegroundColor Magenta "`nSelect deployment method: "
  $Method = Select-UtilsUserOption -Options $deploymentMethods.Keys
} 

$selectedMethod = $deploymentMethods[$Method]

<#
    #############################
    #### Select Deployment Scope
#>

$deploymentScopes = [ordered]@{
  'Resource Group' = 'resource_group'
  'Subscription'   = 'subscription'
}

if ([System.String]::IsNullOrEmpty($Scope)) {
  Write-Host -ForegroundColor Magenta "`nSelect deployment scope:`nIf you want to deploy into a custom resource group, select 'Resource Group'"
  $Scope = Select-UtilsUserOption -Options $deploymentScopes.Keys
} 

$selectedScope = $deploymentScopes[$Scope]

<#
    #############################
    #### Select Deployment Script
#>

$deploymentScripts = [ordered]@{
  'PowerShell' = 'pwsh'
  'Azure CLI'  = 'cli'
}

if ([System.String]::IsNullOrEmpty($Script)) {
  Write-Host -ForegroundColor Magenta "`nSelect deployment Script: "
  $Script = Select-UtilsUserOption -Options $deploymentScripts.Keys
}

$selectedScript = $deploymentScripts[$Script]

<#
    #############################
    #### Select Deployment Pipeline
#>

$deploymentPipelines = [ordered]@{
  'Azure DevOps' = @{
    source = "devops_pipelines"
    target = '.devops'
  }
  'Github'       = @{
    source = "github_workflows"
    target = '.github'
  }
}

if ([System.String]::IsNullOrEmpty($Pipeline)) {
  Write-Host -ForegroundColor Magenta "`nSelect Pipeline Template: "
  $Pipeline = Select-UtilsUserOption -Options $deploymentPipelines.Keys
}

$selectedPipeline = $deploymentPipelines[$Pipeline]

# This is were all pipelines will be copied to
$targetPipelineFolder = [System.IO.DirectoryInfo]::new("$StagingDir/$($selectedPipeline.target)")
$targetPipelineFolder.Create()

<#
    #############################
    #### Write to file
#>

# Pipeline files

$pipelineTemplateFolder = Resolve-Path -Path "$templateFiles/$($selectedPipeline.source)"
$pipelineTemplates = Get-ChildItem -Path $pipelineTemplateFolder -Recurse -Depth 5

foreach ($tmpl in $pipelineTemplates) {
  if (
    $tmpl.Name -NOTLIKE "*.yaml.$selectedMethod" -AND 
    $tmpl.Name -NOTLIKE "*.yaml.$selectedScope" -AND 
    $tmpl.Name -NOTLIKE "*.yaml.$selectedMethod.$selectedScript" -AND 
    $tmpl.Name -NOTLIKE "*.yaml.$selectedScope.$selectedMethod"
  ) {
    continue
  }

  $relativePath = $tmpl.FullName.Replace($pipelineTemplateFolder, "") 
  $relativePath = $relativePath -split ".yaml"
  # Removes all meta identifiers after .yaml, like resource_group, deploy, etc.
  $relativePath = $relativePath[0] + ".yaml" 

  $pipelineFilePath = "$targetPipelineFolder/$relativePath"
  $directory = [System.IO.FileInfo]::new($pipelineFilePath).Directory
  if (-NOT $directory.Exists) {
    $directory.Create()
  }

  $null = $tmpl.CopyTo($pipelineFilePath)
}


# Delete all templates in the staging directory and only keep selected.
# The selected ones were copied from %templateFiles to $pipelineFilePath at this point
[System.IO.DirectoryInfo]::new($templateFiles).Delete($true)

# Remove all non-pipeline files if -PipelineOnly is set.
if ($PipelineOnly.IsPresent) {
  $items = Get-ChildItem -Path $StagingDir
  $items += Get-ChildItem -Path $StagingDir -Hidden
  $items
  | Where-Object -Property Name -INE '.github'
  | Where-Object -Property Name -INE '.devops'
  | Remove-Item -Recurse -Force
}


Write-Host -ForegroundColor Magenta "`nPlease, Adjust the following in your templates:"


if ($Pipeline -EQ 'Azure DevOps') {
  Write-Host -ForegroundColor Magenta "`n"
  Write-Host -ForegroundColor Magenta "Service Connection in .devops/deploy.infrastructure.yaml"
}

if ($Pipeline -EQ 'Github') {
  Write-Host -ForegroundColor Magenta "`n"
  Write-Host -ForegroundColor Magenta "Provide a secret named AZURE_CICDSPN:"
  Write-Host -ForegroundColor Magenta "Set this Secret via GitHub Environments"
  Write-Host -ForegroundColor Magenta @"
  {
      "clientId": "00000000-0000-0000-0000-000000000000",
      "objectId": "00000000-0000-0000-0000-000000000000",
      "clientSecret": "00000000-0000-0000-0000-000000000000",
      "subscriptionId": "00000000-0000-0000-0000-000000000000",
      "tenantId": "00000000-0000-0000-0000-000000000000"
  }
"@
}