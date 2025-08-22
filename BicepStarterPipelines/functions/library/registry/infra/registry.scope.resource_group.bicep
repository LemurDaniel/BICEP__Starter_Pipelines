targetScope = 'resourceGroup'

////////////////////////////////////////////////
//// Parameters - Naming, Location and Tags

param location string = resourceGroup().location
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
//// Validations

#disable-next-line no-unused-vars
var validation = map(
  [
    {
      details: 'Advanced Network Settings requires sku "Premium"'
      bool: sku != 'Premium' && paramNetworking.access != 'Public'
    }
    {
      details: 'IP Rules requires sku "Premium"'
      bool: sku != 'Premium' && length(paramNetworking.ipRules) > 0
    }
  ],
  err => err.bool ? fail('ERROR | ${err.details}') : null
)

////////////////////////////////////////////////
//// Module Deployment

var varDeploymentName = length(deployment().name) > length('.registry.0.9.1')
  ? uniqueString(deployment().name)
  : deployment().name

resource resManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = if (!empty(name.?identity)) {
  name: any(name.?identity)
  location: location
  tags: tags
}

module modRegistry 'br/public:avm/res/container-registry/registry:0.9.1' = {
  name: format('{0}.registry.0.9.1', varDeploymentName)
  params: {
    name: name.registry
    location: location
    tags: tags

    acrSku: paramSku
    acrAdminUserEnabled: enableAdminUser
    anonymousPullEnabled: enableAnonymousPulls

    exportPolicyStatus: paramNetworking.access != 'Private' ? 'enabled' : 'disabled'
    publicNetworkAccess: paramNetworking.access != 'Private' ? 'Enabled' : 'Disabled'
    networkRuleSetDefaultAction: paramNetworking.access == 'Public' ? 'Allow' : 'Deny'
    networkRuleSetIpRules: [
      for ipRule in paramNetworking.ipRules: {
        action: 'Allow'
        value: ipRule
      }
    ]

    managedIdentities: {
      systemAssigned: paramIdentity.systemAssigned
      userAssignedResourceIds: paramIdentity.userAssigned
    }

    // Authenticates:
    // - deployer SPN for Acr Push
    // - user assigned identity for Acr Pull
    roleAssignments: filter(
      [
        {
          principalId: deployer().objectId
          roleDefinitionIdOrName: 'AcrPush'
        }
        {
          principalId: resManagedIdentity.?id
          roleDefinitionIdOrName: 'AcrPull'
        }
      ],
      item => !empty(item.principalId)
    )

    privateEndpoints: [
      for (endpoint, index) in privateEndpoints: {
        tags: tags
        name: endpoint.name

        subnetResourceId: endpoint.subnetId
        privateDnsZoneGroup: empty(endpoint.?privateDnsZoneId)
          ? null
          : {
              privateDnsZoneGroupConfigs: [
                {
                  privateDnsZoneResourceId: any(endpoint.?privateDnsZoneId)
                }
              ]
            }

        customDnsConfigs: []
      }
    ]
  }
}
