param([System.IO.DirectoryInfo] $stagingDir)

<#
    #############################
    #### Deployment Method
#>

$deploymentMethods = [ordered]@{
  'Normal Deployment' = 'deploy'
  'Deployment Stack'  = 'stack'
}

Write-Host -ForegroundColor Magenta "`nSelect deployment method: "
$selectedMethod = Read-UtilsUserOption -Options $deploymentMethods.Keys
$selectedMethod = $deploymentMethods[$selectedMethod]

<#
    #############################
    #### Select Deployment Scope
#>

$deploymentScopes = [ordered]@{
  'Resource Group' = 'resource_group'
  'Subscription'   = 'subscription'
  # 'Management Group' = 'management'
  # 'Tenant Level'     = 'tenant'
}

Write-Host -ForegroundColor Magenta "`nSelect deployment scope: "
$selectedScope = Read-UtilsUserOption -Options $deploymentScopes.Keys
$selectedScope = $deploymentScopes[$selectedScope]

<#
    #############################
    #### Select Deployment Script
#>

$deploymentScripts = [ordered]@{
  'PowerShell' = 'pwsh'
  'Azure CLI'  = 'cli'
}

Write-Host -ForegroundColor Magenta "`nSelect deployment Script: "
$selectedScript = Read-UtilsUserOption -Options $deploymentScripts.Keys
$selectedScript = $deploymentScripts[$selectedScript]

<#
    #############################
    #### Select Deployment Pipeline
#>

$deploymentPipelines = [ordered]@{
  'Azure DevOps' = @{
    source = 'devops_pipelines'
    target = '.devops'
  }
  'Github'       = @{
    source = 'github_workflows'
    target = '.github/workflows'
  }
}

Write-Host -ForegroundColor Magenta "`nSelect Pipeline Template: "
$selectedPipeline = Read-UtilsUserOption -Options $deploymentPipelines.Keys

$selectedPipeline = $deploymentPipelines[$selectedPipeline]
$targetPipelineFolder = [System.IO.DirectoryInfo]::new("$stagingDir/$($selectedPipeline.target)")
$targetPipelineFolder.Create()

<#
    #############################
    #### Write to file
#>

$templateFiles = Get-Item -Path "$stagingDir/_selections"

$bicepMainTemplate = Get-Item -Path "$templateFiles/bicep/*.$selectedScope"
$deployScriptTemplate = Get-Item -Path "$templateFiles/deploy/*.$selectedScope.$selectedMethod"

$bicepMainFilePath = "$stagingDir/$($bicepMainTemplate.Name)".Replace(".$selectedScope", "")
$deployScriptFilePath = "$stagingDir/$($deployScriptTemplate.Name)".Replace(".$selectedScope.$selectedMethod", "")

$null = $deployScriptTemplate.CopyTo($deployScriptFilePath)
$null = $bicepMainTemplate.CopyTo($bicepMainFilePath)


# Pipeline files

$pipelineTemplateFolder = Resolve-Path -Path "$templateFiles/$($selectedPipeline.source)"
$pipelineTemplates = Get-ChildItem -Path $pipelineTemplateFolder -Recurse -Depth 3

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
  $relativePath = $relativePath[0] + ".yaml"

  $pipelineFilePath = "$targetPipelineFolder/$relativePath"
  $directory = [System.IO.FileInfo]::new($pipelineFilePath).Directory
  if (-NOT $directory.Exists) {
    $directory.Create()
  }

  $null = $tmpl.CopyTo($pipelineFilePath)
}

# Delete all templates in the staging directory and only keep selected.
[System.IO.DirectoryInfo]::new($templateFiles).Delete($true)