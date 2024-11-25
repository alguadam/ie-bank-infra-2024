param location string
param name string
param tenantId string
@description('Array of secrets to be added to the Key Vault')
param secrets array = [
  {
    name: 'PostgresPassword'
    value: '<secure-password>'
  }
  {
    name: 'AcrAdminPassword'
    value: '<secure-arc-password>'
  }
]

resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: name
  location: location
  properties: {
    tenantId: tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: []
  }
}
resource keyVaultSecrets 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = [for secret in secrets: {
  name: '${keyVault.name}/${secret.name}'
  properties: {
    value: secret.value
  }
}]

