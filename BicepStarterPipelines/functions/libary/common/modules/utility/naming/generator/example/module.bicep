param location string = resourceGroup().location
param environment string = 'development'

import { schema_default as schema } from '../../schema/module.bicep'
import { genName, genNameId } from '../module.bicep'

// Use 'genName'-Function for consistent naming.
output kvNamingExample string = genNameId('Microsoft.KeyVault/vaults', 'auth', schema, location, {
  name: 'secrets'
  environment: 'test'
})
output storageAccountNamingExample string = genName('Microsoft.Storage/storageAccounts', schema, location, {
  name: 'objects'
  environment: environment
})
output functionAppNamingExample string = genName('Microsoft.Web/sites::function', schema, location, {
  name: 'apps'
  environment: environment
  index: 1
})
output dataDiskNamingExample string = genName('Microsoft.Compute/disks::data', schema, location, {
  name: 'apps'
  environment: environment
  index: 1
})
output osDiskNamingExample string = genName('Microsoft.Compute/disks::os', schema, location, {
  name: 'apps'
  environment: environment
  index: 1
})
