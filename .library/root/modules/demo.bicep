targetScope = 'resourceGroup'

/*

  #################################################
  #### Imports

*/
import {
  demoExportedVariable
  demoTypeDefinition
} from '../export/demo.bicep'

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
