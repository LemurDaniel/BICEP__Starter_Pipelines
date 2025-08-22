using '../registry.scope.resource_group.bicep'

// param location = 'westeurope'

param tags = {}

param name = {
  resourceGroup: 'rg-sample-test'
  registry: 'acrsampletest'

  // Deploys a managed identity with Pull Acess
  // identityName: 'identity-sample-test'
}

// NOTE:
// Required User Access Permissions
// Disable if you want to set role assignments yourself
param deployRoleAssignments = true 

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
    // '0.0.0.0/32'
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
