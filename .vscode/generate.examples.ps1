
Import-Module -Name "./BicepStarterPipelines" -Force

if (Test-Path "./examples/") {
    Remove-Item "./examples/" -Recurse -Force -ErrorAction Break
}

bicep-init "./examples/azure.devops/subs.deploy.cli" -Template deployment -Method 'Normal Deployment' -Scope 'Subscription' -Script 'Azure CLI' -Pipeline 'Azure DevOps'
bicep-init "./examples/azure.devops/subs.deploy.pwsh" -Template deployment -Method 'Normal Deployment' -Scope 'Subscription' -Script 'PowerShell' -Pipeline 'Azure DevOps'
bicep-init "./examples/azure.devops/subs.stack.cli" -Template deployment -Method 'Deployment Stack' -Scope 'Subscription' -Script 'PowerShell' -Pipeline 'Azure DevOps'


bicep-init "./examples/github/subs.deploy.cli" -Template deployment -Method 'Normal Deployment' -Scope 'Subscription' -Script 'Azure CLI' -Pipeline 'Github'
bicep-init "./examples/github/subs.deploy.pwsh" -Template deployment -Method 'Normal Deployment' -Scope 'Subscription' -Script 'PowerShell' -Pipeline 'Github'
bicep-init "./examples/github/subs.stack.cli" -Template deployment -Method 'Deployment Stack' -Scope 'Subscription' -Script 'PowerShell' -Pipeline 'Github'