using '../main.bicep'

var environment = 'dev'

param config = {
  name: 'demo-definition-${environment}'
  demoData: 'demo-data'
}
