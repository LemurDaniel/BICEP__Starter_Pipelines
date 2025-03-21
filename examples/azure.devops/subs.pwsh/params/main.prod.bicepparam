using '../main.bicep'

var environment = 'prod'

param config = {
  name: 'demo-definition-${environment}'
  demoData: 'demo-data'
}
