// param adminUsername string = 'iebankdbadmin'
// @secure()
// param adminPassword string 
param location string = resourceGroup().location
param postgresSQLServerName string
param postgresSQLDatabaseName string 
// param postgresSQLAdminServerPrincipalName string
// param postgresSQLAdminServerPrincipalObjectId string
param logsAnalyticsWorkspaceId string 
param appServiceAPIEnvVarDBPASS string

@allowed([
  'dev'
  'uat'
  'prod'
])
param environmentType string

@minValue(32)
@maxValue(1024)
param storageSizeGB int

// var skuName = environmentType == 'prod' ? 'Standard_B1ms' : (environmentType == 'uat' ? 'Standard_B1ms' : 'Standard_B1ms')
var backupRetentionDays = environmentType == 'prod' ? 14 : (environmentType == 'uat' ? 7 : 3)
var allowedIpAddresses = environmentType == 'dev' ? ['0.0.0.0'] : ['0.0.0.0']



resource postgresSQLServer 'Microsoft.DBforPostgreSQL/flexibleServers@2022-12-01' = {
  name: postgresSQLServerName
  location: location
  sku: {
    name: 'Standard_B1ms' 
    tier: 'Burstable'
    }
  properties: {
    administratorLogin: 'iebankdbadmin'
    administratorLoginPassword: appServiceAPIEnvVarDBPASS  
    version: '15'
    createMode: 'Default'
    authConfig: {activeDirectoryAuth: 'Enabled', passwordAuth: 'Enabled', tenantId: subscription().tenantId }
    storage: {
      storageSizeGB: storageSizeGB
    }
    backup: {
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: environmentType == 'prod' ? 'Enabled' : 'Disabled'
    }
  }
  resource firewallRule 'firewallRules@2022-12-01' = {
  name: 'AllowAllAzureServices'
  properties: {
    startIpAddress: allowedIpAddresses[0]
    endIpAddress: allowedIpAddresses[0]
  }
}
}

resource postgresSQLDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2022-12-01' = {
  name: postgresSQLDatabaseName
  parent: postgresSQLServer
  properties: {
    charset: 'UTF8'
    collation: 'en_US.UTF8'
  }
}



// resource postgresSQLAdmins 'Microsoft.DBforPostgreSQL/flexibleServers/administrators@2022-12-01' = {
//   name: postgresSQLAdminServerPrincipalObjectId
//   properties: {
//     principalName: postgresSQLAdminServerPrincipalName
//     principalType: 'ServicePrincipal'
//     tenantId: subscription().tenantId
//   }
//   dependsOn: [
//     firewallRule
//   ]
// }


resource postgresSQLDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'PostGresSQLServerDiagnostics'
  scope: postgresSQLServer
  properties: {
    workspaceId: logsAnalyticsWorkspaceId
    logs: [
      {
        category: 'PostgreSQLFlexSessions'
        enabled: true
      }
      {
        category: 'PostgreSQLFlexQueryStoreRuntime'
        enabled: true
      }
      {
        category: 'PostgreSQLFlexTableStats'
        enabled: true
      }
      {
        category: 'PostgreSQLFlexQueryStoreWaitStats'
        enabled: true
      }
      {
        category: 'PostgreSQLLogs'
        enabled: true
      }
      {
        category: 'PostgreSQLFlexDatabaseXacts'
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


output postgresSQLDatabaseName string = postgresSQLDatabase.name
output postgresSQLServerName string = postgresSQLServer.name
