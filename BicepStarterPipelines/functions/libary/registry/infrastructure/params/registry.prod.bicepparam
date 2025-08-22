using '../registry.scope.resource_group.bicep'

// param location = 'westeurope'

param tags = {}

param name = {
  resourceGroup: 'rg-sample-prod'
  registry: 'acr-sample-prod.28342035'

  // Deploys a managed identity with Pull Acess
  // identityName: 'identity-sample-prod.28342035'
}

// NOTE:
// This disables admin access and password. Prefer:
// - Managed Identity with appropriate role assignments
// - Tokens with limited access (Pull, Push, etc.)
param enableAdminUser = false

// NOTE:
// This allows anyone to pull images WITHOUT authentication.
// Doesn't bypass the network rules, only the authentication!
// User still needs to have access via Public-Networking or IP Rules!
param enableAnonymousPulls = false

// NOTE:
// Restricted or Disabled Network requires Premium SKU (~50$ Per Month)
// If you are deploying this in a Sandbox-Subscription you may want to use Public!
param networking = {
  access: 'Restricted' // 'Public' | 'Restricted' | 'Disabled'
  ipRules: [
    // Add your IP rules here
    // '0.0.0.0/0'
    // '10.0.0.0/24'
  ]
}

// When NOT defined: 
// - Will select Standard or Premium based on Network Settings
// - Restricted Access and IP Rules needs Premium Tier (~ 50$ Per Month)
param sku = networking.access == 'Public' ? 'Standard' : 'Premium'

param identity = {
  systemAssigned: false
  userAssigned: [
    // Enter any user assigned identity ids here
    // '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sample-prod/providers/Microsoft.ManagedIdentity/userAssignedIdentities/identity-sample-prod.28342035'
  ]
}

//
// Define private Endpoints when Network Settings is 'Disabled'
//
// param privateEndpoints = [
//   {
//     name: 'pe-acr-sample-prod'
//     subnetId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sample-prod/providers/Microsoft.Network/virtualNetworks/vnet-sample-prod/subnets/subnet-sample-prod'
//     privateDnsZoneId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sample-prod/providers/Microsoft.Network/privateDnsZones/privatelink.azurecr.io'
//   }
// ]
