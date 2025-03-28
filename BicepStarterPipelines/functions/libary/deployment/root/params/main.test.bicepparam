using '../main.bicep'

var environment = 'test'

param config = {
  name: 'demo-definition-${environment}'
  demoData: 'demo-data'
}
