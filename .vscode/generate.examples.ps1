
Import-Module -Name "./BicepStarterPipelines" -Force

Remove-Item "./examples/" -Recurse -Force

bicep-init "./examples/azure.devops/subs.deploy.cli" -Method 'Normal Deployment' -Scope 'Subscription' -Script 'Azure CLI' -Pipeline 'Azure DevOps'
bicep-init "./examples/azure.devops/subs.deploy.pwsh" -Method 'Normal Deployment' -Scope 'Subscription' -Script 'PowerShell' -Pipeline 'Azure DevOps'
bicep-init "./examples/azure.devops/subs.stack.cli" -Method 'Deployment Stack' -Scope 'Subscription' -Script 'PowerShell' -Pipeline 'Azure DevOps'


bicep-init "./examples/github/subs.deploy.cli" -Method 'Normal Deployment' -Scope 'Subscription' -Script 'Azure CLI' -Pipeline 'Github'
bicep-init "./examples/github/subs.deploy.pwsh" -Method 'Normal Deployment' -Scope 'Subscription' -Script 'PowerShell' -Pipeline 'Github'
bicep-init "./examples/github/subs.stack.cli" -Method 'Deployment Stack' -Scope 'Subscription' -Script 'PowerShell' -Pipeline 'Github'