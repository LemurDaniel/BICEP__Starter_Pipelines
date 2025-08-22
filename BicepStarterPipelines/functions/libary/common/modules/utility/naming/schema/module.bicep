/*

  These are some example naming schema that can be imported in a Bicep file.

  Each naming schema is a separate file, so that they can be maintained separately.

*/

@export()
var schema_default = import_defaultSchema
import { schemaReference as import_defaultSchema } from './defaults/schema.default.bicep'
