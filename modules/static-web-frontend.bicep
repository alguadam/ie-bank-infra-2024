param location string
param name string
@allowed(['dev', 'uat', 'prod'])
param environmentType string
param sku string = (environmentType == 'prod') ? 'Standard' : 'Free'

resource staticWebApp 'Microsoft.Web/staticSites@2022-03-01' = {
  name: name
  location: location
  sku: {
    name: 'Free'
    tier: sku
  }
  properties: {
    repositoryToken: '<REPOSITORY-TOKEN>'
  }
}

output staticWebAppUrl string = staticWebApp.properties.defaultHostname

