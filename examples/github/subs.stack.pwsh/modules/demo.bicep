targetScope = 'resourceGroup'

/*

  #################################################
  #### Imports

*/
import {
  demoExportedVariable
  demoTypeDefinition
} from '../exports/demo.bicep'

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
