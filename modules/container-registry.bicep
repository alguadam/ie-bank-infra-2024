param registryName string
param location string
@allowed([
  'dev'
  'uat'
  'prod'
])
param environmentType string
param enableGeoReplication bool = environmentType == 'prod' // default true for prod

var containerRegistrySku = environmentType == 'prod' ? 'Standard': 'Basic'
param dynamicRegistryName string = '${registryName}-${environmentType}'

param keyVaultResourceId string
param keyVaultSecreNameAdminUsername string 
param keyVaultSecreNameAdminPassword0 string 
param keyVaultSecreNameAdminPassword1 string 



resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-07-01' = {
  name: dynamicRegistryName
  location: location
  sku: {
    name: containerRegistrySku 
  }
  properties: {
    adminUserEnabled: true
    geoReplication: enableGeoReplication ? {
      regions:[
        'East US'
        'West US'
      ]
    }: null    //enabled for prod only
  }
}

resource adminCredentialsKeyVault 'Microsoft.KeyVault/vaults@2021-10-01' existing = if(!empty(keyVaultResourceId)) {
name: last(split((!empty(keyVaultResourceId) ? keyVaultResourceId : 'dummyVault'), '/'))!
}

resource secretAdminUserName 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = if (!empty(keyVaultSecreNameAdminUsername)) {
  name: !empty(keyVaultSecreNameAdminUsername) ? keyVaultSecreNameAdminUsername
  : 'dummySecret'
  parent: adminCredentialsKeyVault
  properties: {
    value: containerRegistry.listCredentials().username
  }
}
// create a secret to store the container registry admin password 0
resource secretAdminUserPassword0 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = if (!empty(keyVaultSecreNameAdminPassword0)) {
  name: !empty(keyVaultSecreNameAdminPassword0) ? keyVaultSecreNameAdminPassword0 : 'dummySecret'
  parent: adminCredentialsKeyVault
  properties: {
    value: containerRegistry.listCredentials().passwords[0].value
}
}
// create a secret to store the container registry admin password 1
resource secretAdminUserPassword1 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = if (!empty(keyVaultSecreNameAdminPassword1)) {
  name: !empty(keyVaultSecreNameAdminPassword1) ? keyVaultSecreNameAdminPassword1 : 'dummySecret'
  parent: adminCredentialsKeyVault
  properties: {
  value: containerRegistry.listCredentials().passwords[1].value
  }
}


output registryLoginServer string = containerRegistry.properties.loginServer
