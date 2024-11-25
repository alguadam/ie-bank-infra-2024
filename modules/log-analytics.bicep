@description('The name of the Log Analytics Workspace')
param workspaceName string

@description('The location where the Log Analytics Workspace will be deployed')
param location string

@description('The SKU of the Log Analytics Workspace')
param sku string = 'PerGB2018' // default SKU  suitable for most use cases

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: 30 
  }
}

output workspaceId string = logAnalyticsWorkspace.id
output workspaceKey string = listKeys(logAnalyticsWorkspace.id, logAnalyticsWorkspace.apiVersion).primarySharedKey
