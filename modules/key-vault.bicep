param location string = resourceGroup().location 
param keyVaultName string ='anna-kv${uniqueString(resourceGroup().id)}'
// param keyVaultSecretNameAdminUsername string
// param keyVaultSecretNameAdminPassword0 string
param enableVaultForDeployment bool = true
param logAnalyticsWorkspaceId string 
param diagnosticSettingName string = 'myDiagnosticSetting'
param roleAssignments array = []


@allowed([
  'dev'
  'uat'
  'prod'
])
param environmentType string

var keyVaultSku = 'standard'

var builtInRoleNames = {
  Contributor:subscriptionResourceId('Microsoft.Authorization/roleDefinitions','b24988ac-6180-42a0-ab88-20f7382dd24c') 
  'Key Vault Administrator': subscriptionResourceId('Microsoft.Authorization/roleDefinitions','00482a5a-887f-4fb3-b363-3b7fe8e74483')
  'Key Vault Certificates Officer': subscriptionResourceId('Microsoft.Authorization/roleDefinitions','a4417e6f-fecd-4de8-b567-7b0420556985')
  'Key Vault Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions','f25e0fa2-a7c8-4377-a976-54943a77a395')
  'Key Vault Crypto Officer': subscriptionResourceId('Microsoft.Authorization/roleDefinitions','14b46e9e-c2b7-41b4-b07b-48a6ebf60603')
  'Key Vault Crypto Service Encryption User': subscriptionResourceId('Microsoft.Authorization/roleDefinitions','e147488a-f6f5-4113-8e2d-b22465e65bf6')
  'Key Vault Crypto User': subscriptionResourceId('Microsoft.Authorization/roleDefinitions','12338af0-0e69-4776-bea7-57ae8d297424')
  'Key Vault Reader': subscriptionResourceId('Microsoft.Authorization/roleDefinitions','21090545-7ca7-4776-b22c-e363652d74d2')
  'Key Vault Secrets Officer': subscriptionResourceId('Microsoft.Authorization/roleDefinitions','b86a8fe4-44ce-4948-aee5-eccb2c155cd7')
  'Key Vault Secrets User': subscriptionResourceId('Microsoft.Authorization/roleDefinitions','4633458b-17de-408a-b874-0445c86b69e6')
  Owner:subscriptionResourceId('Microsoft.Authorization/roleDefinitions','8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
  Reader:subscriptionResourceId('Microsoft.Authorization/roleDefinitions','acdd72a7-3385-48ef-bd42-f606fba81ae7')
  'Role Based Access Control Administrator (Preview)':subscriptionResourceId('Microsoft.Authorization/roleDefinitions','f58310d9-a9f6-439a-9e8d-f62e7b41a168')
  'User Access Administrator': subscriptionResourceId('Microsoft.Authorization/roleDefinitions','18d7d88d-d35e-4fb5-a5c3-7773c20a72d9')
}


// var networkRules = environmentType == 'dev' ? {
//   defaultAction: 'Allow'
// } : environmentType == 'uat' ? {
//     defaultAction: 'Deny'
//     ipRules: [
//       '0.0.0.0'       //figure this out????
//     ]
// } : {
//   defaultAction: 'Deny'
//     virtualNetworkRules: [
//       {
//         id: '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/{subnetName}'
//       }
//     ]
// }


var accessPolicies = environmentType =='dev' ? [
  {
    tenantId: subscription().tenantId
    objectId: 'daa3436a-d1fb-44fe-b34b-053db433cdb7'     //developer access
    permissions: {
      secrets: ['get', 'list', 'set']
      certificates: ['get', 'list']
      }
    }
] : environmentType =='uat' ? [
  {
    tenantId: subscription().tenantId
    objectId: 'daa3436a-d1fb-44fe-b34b-053db433cdb7'     //developer access
    permissions: {
      secrets: ['get', 'list', 'set']
      certificates: ['get', 'list']
      }
    }
    {
      tenantId: subscription().tenantId
      objectId: 'daa3436a-d1fb-44fe-b34b-053db433cdb7'     //stakeholder access --> NEED TO CHANGE
      permissions: {
        secrets: ['get', 'list']
        certificates: ['get', 'list']
      }
    }
]: [
  {
      tenantId: subscription().tenantId
      objectId: 'daa3436a-d1fb-44fe-b34b-053db433cdb7'           //ADMIN access --> NEED TO CHANGE
      permissions: { 
        secrets: ['get', 'list', 'set', 'delete']
        certificates: ['get', 'list', 'set', 'delete']
        keys: ['get', 'list', 'set', 'delete']
      }
    }
]



resource keyVault 'Microsoft.KeyVault/vaults@2021-07-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    enabledForDeployment: enableVaultForDeployment
    enableRbacAuthorization:true
    enableSoftDelete: true
    enabledForTemplateDeployment: true
    sku: {
      family: 'A'
      name: keyVaultSku
    }
    tenantId: subscription().tenantId
    accessPolicies: accessPolicies
    // networkAcls: networkRules
  }
}



resource keyVault_roleAssignments 'Microsoft.Authorizations/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (roleAssignments ?? []): {
    name: guid(keyVault.id, roleAssignment.principalId, roleAssignment.roleDefinitionIdOrName)
    properties: {
      roleDefinitionId: builtInRoleNames[?roleAssignment.roleDefinitionIdOrName] ?? roleAssignment.roleDefinitionIdOrName
      principalId: roleAssignment.principalId
      description: roleAssignment.?description
      condition: roleAssignment.?condition
      principalType: roleAssignment.?principalType 
      conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0'): null
      delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
    }
    scope: keyVault
  }
]




resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: diagnosticSettingName
  scope: keyVault
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}


// resource dockerRegistryUsernameSecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01' = {
//   name: 'dockerRegistryUsername'
//   parent: keyVault
//   properties: {
//     value: dockerRegistryUsername
//   }
// }

// resource dockerRegistryPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01' = {
//   name: 'dockerRegistryPassword'
//   parent: keyVault
//   properties: {
//     value: dockerRegistryPassword
//   }
// }


// output keyVaultUri string = keyVault.properties.vaultUri
output keyVaultResourceId string = keyVault.id
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
// output dockerRegistryUsernameSecret string = reference(resourceId('Microsoft.KeyVault/vaults/secrets', keyVaultName, keyVaultSecretNameAdminUsername)).value
// output dockerRegistryPasswordSecret string = reference(resourceId('Microsoft.KeyVault/vaults/secrets', keyVaultName, keyVaultSecretNameAdminPassword0)).value

