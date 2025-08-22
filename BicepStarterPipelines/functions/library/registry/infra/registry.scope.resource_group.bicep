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

param deployRoleAssignments bool = true

param sku 'Premium' | 'Standard' | 'Basic'?
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

// param privateEndpoints {
//   name: string
//   subnetId: string
//   privateDnsZoneId: string?
// }[] = []

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

resource resRegistry 'Microsoft.ContainerRegistry/registries@2025-04-01' = {
  name: name.registry
  location: location

  sku: {
    name: any(paramSku)
  }

  properties: {
    adminUserEnabled: enableAdminUser
    anonymousPullEnabled: enableAnonymousPulls

    publicNetworkAccess: paramNetworking.access != 'Private' ? 'Enabled' : 'Disabled'
    networkRuleBypassOptions: paramNetworking.bypass
    networkRuleSet: {
      defaultAction: paramNetworking.access == 'Public' ? 'Allow' : 'Deny'
      ipRules: [
        for ipRule in paramNetworking.ipRules: {
          action: 'Allow'
          value: contains(ipRule, '/') ? ipRule : '${ipRule}/32'
        }
      ]
    }

    policies: {
      exportPolicy: {
        status: paramNetworking.access != 'Private' ? 'enabled' : 'disabled'
      }
    }
  }

  identity: {
    type: filter(
      [
        {
          type: 'None'
          bool: !paramIdentity.systemAssigned && length(paramIdentity.userAssigned) == 0
        }
        {
          type: 'SystemAssigned'
          bool: paramIdentity.systemAssigned && length(paramIdentity.userAssigned) == 0
        }
        {
          type: 'UserAssigned'
          bool: !paramIdentity.systemAssigned && length(paramIdentity.userAssigned) > 0
        }
        {
          type: 'SystemAssigned, UserAssigned'
          bool: paramIdentity.systemAssigned && length(paramIdentity.userAssigned) > 0
        }
      ],
      entry => entry.bool == true
    )[0].type
    userAssignedIdentities: length(paramIdentity.userAssigned) > 0
      ? toObject(paramIdentity.userAssigned, id => id, id => {})
      : {}
  }
}

resource resRoleAssignmentSPN 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (deployRoleAssignments) {
  name: guid(resRegistry.id, 'AcrPush')
  scope: resRegistry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'AcrPush')
    principalId: deployer().objectId
  }
}

resource resManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = if (!empty(name.?identity)) {
  name: any(name.?identity)
  location: location
  tags: tags
}

resource resRoleAssignmentIdentity 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (deployRoleAssignments && !empty(resManagedIdentity.?id)) {
  name: guid(resRegistry.id, 'AcrPull')
  scope: resManagedIdentity
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'AcrPull')
    principalId: any(resManagedIdentity.?properties.principalId)
  }
}
