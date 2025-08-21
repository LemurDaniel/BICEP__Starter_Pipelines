targetScope = 'resourceGroup'

/*

  #################################################
  #### Imports

*/
import {
  demoExportedVariable
  demoTypeDefinition
} from '../modules/utility/demo.bicep'

/*

  #################################################
  #### Parameters

*/
param config demoTypeDefinition


/*

  #################################################
  #### Outputs

*/
output ref demoTypeDefinition = config
