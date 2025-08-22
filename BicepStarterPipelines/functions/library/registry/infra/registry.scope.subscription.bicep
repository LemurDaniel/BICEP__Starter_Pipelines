targetScope = 'subscription'

////////////////////////////////////////////////
//// Parameters - Naming, Location and Tags

param location string?
param tags object = {}

param name {
  resourceGroup: string
  registry: string

  identity: string?
}

////////////////////////////////////////////////
//// Parameters - Container Registry

param enableAdminUser bool = false

param enableAnonymousPulls bool = false

param sku 'Basic' | 'Premium' | 'Standard'?
var paramSku = !empty(sku) ? sku : (paramNetworking.access == 'Public' ? 'Standard' : 'Premium')

param networking {
  access: 'Public' | 'Restricted' | 'Private'?
  bypass: 'AzureServices' | 'None'?
  ipRules: string[]?
}?

var paramNetworking = {
  access: networking.?access ?? 'Public'
  bypass: networking.?bypass ?? 'AzureServices'
  ipRules: networking.?ipRules ?? []
}

param privateEndpoints {
  name: string
  subnetId: string
  privateDnsZoneId: string?
}[] = []

param identity {
  systemAssigned: bool?
  userAssigned: string[]?
}?
var paramIdentity = {
  systemAssigned: identity.?systemAssigned ?? false
  userAssigned: identity.?userAssigned ?? []
}

////////////////////////////////////////////////
//// Module Deployment

resource resResourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' existing = {
  name: name.resourceGroup
}

module modRegistry 'registry.scope.resource_group.bicep' = {
  name: format('{0}.rg', deployment().name)
  scope: resResourceGroup
  params: {
    location: location
    name: name
    tags: tags

    sku: paramSku

    enableAdminUser: enableAdminUser
    enableAnonymousPulls: enableAnonymousPulls

    networking: paramNetworking
    identity: paramIdentity

    privateEndpoints: privateEndpoints
  }
}
