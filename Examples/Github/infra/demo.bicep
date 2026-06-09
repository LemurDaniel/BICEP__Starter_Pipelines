targetScope = 'resourceGroup'

param subDeploymentPrefix string = length(deployment().name) > 50 ? uniqueString(deployment().name) : deployment().name

////////////////////////////////////////////////
//// Infra Parameters - Naming, Location and Tags

import { typeNamingSchema, genName, genNameId, genNameExtraParam } from '../modules/utility/naming/generator/module.bicep'

param location string = resourceGroup().location
param tags object = {}

param naming {
  schema: typeNamingSchema
  params: object
  nameid: string?
}

@description('This can adjust the name of the sub-deployment. Will use a unqiue string when name is too long')
param deploymentId string = length(deployment().name) < 30 ? deployment().name : uniqueString(deployment().name)

////////////////////////////////////////////////
//// Infra Deployment - Virtual Network

param addressPrefix string = '10.144.0.0/25'
param subnets {
  name: string
  addressPrefix: string?
  privateEndpointNetworkPolicies: 'Disabled' | 'Enabled'?
}[]

module modVnet 'br/public:avm/res/network/virtual-network:0.5.3' = {
  name: format('{0}.virtual-network.0.5.3', subDeploymentPrefix)
  params: {
    name: genName('Microsoft.Network/virtualNetworks', naming.schema, location, naming.params)
    location: location
    tags: tags

    addressPrefixes: [
      addressPrefix
    ]

    subnets: [
      for (subnet, index) in subnets: {
        name: genNameExtraParam(
          'Microsoft.Network/virtualNetworks',
          naming.schema,
          location,
          naming.params,
          { index: index, name: subnet.name }
        )
        addressPrefix: subnet.?addressPrefix ?? cidrSubnet(addressPrefix, 27, index)
        privateEndpointNetworkPolicies: subnet.?privateEndpointNetworkPolicies ?? 'Disabled'
      }
    ]
  }
}

module modIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.1' = {
  name: format('{0}.user-assigned-identity.0.4.1', deploymentId)
  params: {
    name: genNameId('Microsoft.ManagedIdentity/userAssignedIdentities', 'vnet', naming.schema, location, naming.params)
    location: location
    tags: tags
  }
}

////////////////////////////////////////////////
//// Infra Outputs

output identity {
  clientId: string
  principalId: string
  resourceId: string
} = {
  clientId: modIdentity.outputs.principalId
  principalId: modIdentity.outputs.principalId
  resourceId: modIdentity.outputs.resourceId
}
