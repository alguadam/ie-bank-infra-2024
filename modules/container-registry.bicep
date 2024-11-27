param registryName string
param location string
// @allowed([
//   'dev'
//   'uat'
//   'prod'
// ])
// param environmentType string 
// param enableGeoReplication bool = environmentType == 'prod' // default true for prod
// var containerRegistrySku = environmentType == 'prod' ? 'Standard': 'Basic'
param containerRegistrySku string = 'Basic'

param keyVaultResourceId string
param keyVaultSecretNameAdminUsername string 
param keyVaultSecretNameAdminPassword0 string 
param keyVaultSecretNameAdminPassword1 string 
param containterRegistryDiagnostics string = 'myDiagnosticSetting'
param logAnalyticsWorkspaceId string 



resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: registryName
  location: location
  sku: {
    name: containerRegistrySku 
  }
  properties: {
    adminUserEnabled: true
  }
}



resource adminCredentialsKeyVault 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  name: last(split(keyVaultResourceId, '/'))
}

// stores admin username for CR in KV
resource secretAdminUserName 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: keyVaultSecretNameAdminUsername
  parent: adminCredentialsKeyVault
  properties: {
    value: containerRegistry.listCredentials().username
  }
}


// stores admin password0 for CR in KV
resource secretAdminUserPassword0 'Microsoft.KeyVault/vaults/secrets@2023-07-01' =  {
  name: keyVaultSecretNameAdminPassword0 
  parent: adminCredentialsKeyVault
  properties: {
    value: containerRegistry.listCredentials().passwords[0].value
  }
}

// stores admin password1 for CR in KV
resource secretAdminUserPassword1 'Microsoft.KeyVault/vaults/secrets@2023-07-01' =  {
  name: keyVaultSecretNameAdminPassword1
  parent: adminCredentialsKeyVault
  properties: {
  value: containerRegistry.listCredentials().passwords[1].value
  }
}





resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: containterRegistryDiagnostics
  scope: containerRegistry
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    logs: [
      {
        category: 'ContainerRegistryLoginEvents' 
        enabled: true
      }
      {
        category: 'ContainerRegistryRepositoryEvents' 
        enabled: true
      }
    ]
  }
}


// output registryLoginServer string = containerRegistry.properties.loginServer
