targetScope = 'resourceGroup'

param subDeploymentPrefix string = length(deployment().name) > 50 ? uniqueString(deployment().name) : deployment().name

////////////////////////////////////////////////
//// Main Parameters - Naming, Location and Tags

import { schema } from 'var.naming.bicep'

param location string = resourceGroup().location
param tags object = {}

param naming object

var varNaming = {
  schema: schema
  params: naming
}

////////////////////////////////////////////////
//// Main Deployment - Virtual Network

module modInfraVnet 'infra/demo.bicep' = {
  name: format('{0}.vnet', subDeploymentPrefix)
  params: {
    tags: tags
    location: location
    naming: varNaming

    addressPrefix: '10.0.0.0/22'
    subnets: [
      {
        name: 'default'
        addressPrefix: '10.0.0.0/24'
      }
      {
        name: 'additional'
        addressPrefix: '10.0.1.0/24'
      }
    ]
  }
}

////////////////////////////////////////////////
//// Main Outputs

output identity object = modInfraVnet.outputs.identity
