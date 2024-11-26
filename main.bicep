@description('The environment type')
@allowed([
  'dev'
  'uat'
  'prod'
])
param environmentType string = 'dev'

param location string = resourceGroup().location
// var postgresSku = environmentType == 'prod' ? 'GP_B2ms' : (environmentType == 'uat' ? 'Standard_B1ms' : 'Standard_B1ms')

// PostgreSQL Parameters
@secure()
// param postgresAdminPassword string //= keyVault.getSecret('postgres-admin-password')
param postgreSQLServerName string 
param postgreSQLDatabaseName string 
param storageSizeGB int
// param postgresSQLAdminServerPrincipalName string
// param postgresSQLAdminServerPrincipalObjectId string

// App Service Parameters
param appServicePlanName string 
param appServiceAppName string 
param appServiceAPIAppName string 
param appServiceAPIDBHostFLASK_APP string 
@allowed(['0', '1'])
param appServiceAPIDBHostFLASK_DEBUG string 
param appServiceAPIEnvVarENV string 
param appServiceAPIEnvVarDBHOST string 
param appServiceAPIEnvVarDBNAME string 
param appServiceAPIEnvVarDBUSER string 
@secure()
param appServiceAPIEnvVarDBPASS string 

// Container Registry Parameters
param containerRegistryName string 
param dockerRegistryImageName string 
param dockerRegistryImageTag string 
param dockerRegistryUserName string 
param dockerRegistryPassword string 


// Application Insights and Log Analytics Parameters
param appInsightsName string 
param logAnalyticsWorkspaceName string 

// Key Vault Parameters
param keyVaultName string 
param keyVaultRoleAssignments array = []
// param keyVaultSecretNameAdminUsername string 
// param keyVaultSecretNameAdminPassword0 string 
// param keyVaultSecretNameAdminPassword1 string 


// var logAnalyticsWorkspaceId = resourceId('Microsoft.OperationalInsights/workspaces', logAnalyticsWorkspaceName)




//MODULE REFERENCES


module logAnalytics 'modules/log-analytics.bicep' = {
    name: 'logAnalytics-${environmentType}'
    params: {
        location: location
        workspaceName: logAnalyticsWorkspaceName
    }
}


module appInsights 'modules/application-insights.bicep' = {
    name: 'appInsights-${environmentType}'
    params: {
        appInsightsName: appInsightsName
        location: location
        logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    }
    dependsOn: [
      logAnalytics
  ]
}



module keyVault 'modules/key-vault.bicep' = {
    name: 'keyVault-${environmentType}'
    params: {
        keyVaultName: keyVaultName
        location: location
        environmentType: environmentType
        enableVaultForDeployment: true
        roleAssignments: keyVaultRoleAssignments
        // logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    }
    dependsOn: [
    logAnalytics
  ]
}


module postgresSQLDatabase 'modules/postgres.bicep' = {
  name: 'postgres-${environmentType}'
  params: {
    postgresSQLServerName: postgreSQLServerName
    postgresSQLDatabaseName: postgreSQLDatabaseName
    // adminPassword: postgresAdminPassword
    location: location
    environmentType: environmentType
    logsAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    storageSizeGB: storageSizeGB
    appServiceAPIEnvVarDBPASS: appServiceAPIEnvVarDBPASS
  }
  dependsOn: [
    keyVault
  ]
}




module containerRegistry 'modules/container-registry.bicep' = {
    name: 'containerRegistry-${environmentType}'
    params: {
        registryName: containerRegistryName
        location: location
        environmentType: environmentType
        // keyVaultResourceId: keyVault.outputs.keyVaultResourceId
        // keyVaultSecretNameAdminUsername: keyVaultSecretNameAdminUsername
        // keyVaultSecretNameAdminPassword0: keyVaultSecretNameAdminPassword0
        // keyVaultSecretNameAdminPassword1: keyVaultSecretNameAdminPassword1
        logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    }
    dependsOn: [
      keyVault
      logAnalytics
  ]
}


// App Service Plan 
module appServicePlan 'modules/app-service-plan.bicep' = {
  name: 'appServicePlan-${environmentType}'
  params: {
    appServicePlanName: appServicePlanName
    location: location
    environmentType: environmentType
  }
  dependsOn: [
    appInsights
  ]
}

// Azure Static Web App --> frontend
module frontend 'modules/frontend-app-service.bicep' = {
  name: 'frontend-${environmentType}'
  params: {
    appServiceAppName: appServiceAppName
    appServicePlanId: appServicePlan.outputs.planId
    location: location
    environmentType: environmentType
    appInsightsConnectionString: appInsights.outputs.appInsightsConnectionString
    appInsightsInstrumentationKey: appInsights.outputs.appInsightsInstrumentationKey
  }
  dependsOn: [
    appServicePlan
    appInsights
  ]
}


// Linux App Service --> backend 
module backend 'modules/backend-app-service.bicep' = {
  name: 'backend-${environmentType}'
  params: {
    appServiceAPIAppName: appServiceAPIAppName
    appServicePlanId: appServicePlan.outputs.planId
    location: location
    environmentType: environmentType
    containerRegistryName: containerRegistryName
    dockerRegistryImageName: dockerRegistryImageName
    dockerRegistryImageTag: dockerRegistryImageTag
    dockerRegistryUserName: dockerRegistryUserName 
    dockerRegistryPassword: dockerRegistryPassword

    appSettings: [{
      ENV: appServiceAPIEnvVarENV
      DBHOST: appServiceAPIEnvVarDBHOST
      DBNAME: appServiceAPIEnvVarDBNAME
      DBUSER: appServiceAPIEnvVarDBUSER
      DBPASS: appServiceAPIEnvVarDBPASS
      FLASK_APP: appServiceAPIDBHostFLASK_APP
      FLASK_DEBUG: appServiceAPIDBHostFLASK_DEBUG
      SCM_DO_BUILD_DEPLOYMENT: true
      APPINSIGHTS_INSTRUMENTATIONKEY: appInsights.outputs.appInsightsInstrumentationKey
      APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.outputs.appInsightsConnectionString 
    }]
  }
  dependsOn: [
    containerRegistry
    appServicePlan
    keyVault
    appInsights
  ]
}



output frontendHostName string = frontend.outputs.appHostName
output backendHostName string = backend.outputs.appServiceAppHostName
output containerRegistryLoginServer string = containerRegistry.outputs.registryLoginServer
output appInsightsInstrumentationKey string = appInsights.outputs.appInsightsInstrumentationKey
output appInsightsConnectionString string = appInsights.outputs.appInsightsConnectionString 
output logAnalyticsWorkspaceId string = logAnalytics.outputs.workspaceId
output logAnalyticsWorkspaceName string = logAnalytics.outputs.logAnalyticsWorkspaceName
output keyVaultUri string = keyVault.outputs.keyVaultUri
// output postgresConnectionString string = '${postgreSQLServerName}.postgres.database.azure.com'



