/*
  Bicep Utility Modules Explanation:

  This folder is for local utility modules:
  - custom patterns modules
  - wrapper modules for Azure Verified Modules

  If you want to share utilities across projects, consider using a bicep module registry.

  Utility modules help you implement common tasks or reusable logic by encapsulating parameters, outputs, or resource definitions into standardized templates.

  Typical use cases:
    - Generating resource names or tags
    - Standard exportable variables
    - Providing shared type definitions or variables
    - Implementing helper functions for deployments

*/


@export()
var demoExportedVariable = {
  demoData: 'demoData'
}

@export()
type demoTypeDefinition = {
  name: string
  demoData: string
}
