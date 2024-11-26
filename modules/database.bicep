param postgresSQLServerName string
param postgresSQLDatabaseName string
param postgreSQLAdminServicePrincipalObjectId string
param postgreSQLAdminServicePrincipalName string
param logAnalyticsWorkspaceId string


param location string = resourceGroup().location
@allowed([
  'dev'
  'uat'
  'prod'
])
param environmentType string


module postgresSQLServer './db/postgres-server.bicep' = {
  name: 'postgresSQLServer'
  params: {
    location: location
    environmentType: environmentType
    postgresSQLServerName: postgresSQLServerName
    postgresSQLAdminServerPrincipalObjectId: postgreSQLAdminServicePrincipalObjectId
    postgresSQLAdminServerPrincipalName: postgreSQLAdminServicePrincipalName
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}


module postgresSQLDatabase './db/postgres-db.bicep' = {
  name: 'postgresSQLDatabase'
  params: {
    postgresSQLServerName: postgresSQLServer.outputs.postgresSQLServerName
    postgresSQLDatabaseName: postgresSQLDatabaseName
  }
  dependsOn: [
    postgresSQLServer
  ]
}


output postgresSQLServerName string = postgresSQLServer.outputs.postgresSQLServerName
