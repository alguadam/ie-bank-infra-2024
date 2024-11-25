@description('The environment type')
@allowed([
  'dev'
  'uat'
  'prod'
])
param environmentType string = 'dev'

@secure()
param postgresAdminPassword string = keyVault.getSecret('postgres-admin-password')
var postgresSku = environmentType == 'prod' ? 'GP_B2ms' : (environmentType == 'uat' ? 'Standard_B1ms' : 'Standard_B1ms')
param postgreSQLServerName string = 'ie-bank-db-server-${environmentType}'
param postgreSQLDatabaseName string = 'ie-bank-db'


@description('The Azure location where the resources will be deployed')
param location string = resourceGroup().location


@description('The value for the environment variable DBPASS stored in Key Vault')
@secure()
param appServiceAPIEnvVarDBPASS string  
@description('The App Service Plan name')
param appServicePlanName string = 'ie-bank-app-sp-${environmentType}'
@description('The Web App name- frontend')
param appServiceAppName string = 'ie-bank-${environmentType}'
@description('The API App name - backend')
param appServiceAPIAppName string = 'ie-bank-api-${environmentType}'
param appServiceAPIDBHostFLASK_APP string = 'app.py'
@allowed(['0', '1'])
param appServiceAPIDBHostFLASK_DEBUG string = environmentType == 'prod' ? '0' : '1'
param appServiceAPIEnvVarENV string = environmentType
param appServiceAPIEnvVarDBHOST string = '${postgreSQLServerName}.postgres.database.azure.com'
param appServiceAPIEnvVarDBNAME string = postgreSQLDatabaseName
param appServiceAPIEnvVarDBUSER string = 'iebankdbadmin@${postgreSQLServerName}'
var appServicePlanSku = environmentType == 'prod' ? 'P1v2' : 'B1'
var appServicePlanCapacity = environmentType == 'prod' ? 3 : (environmentType == 'uat' ? 2 : 1)
param appServiceWebsiteBeName string = 'ie-bank-api-dev'
param appServiceWebsiteBeAppSettings array

param containerRegistryName string = 'ie-bank-acr-${environmentType}'
param dockerRegistryImageName string 
param dockerRegistryImageVersion string = 'latest'
param dockerRegistryImageTag string

param appInsightsInstrumentationKey string
param appInsightsConnectionString string

param keyVaultName string = 'apayne-kv-dev'
param keyVaultRoleAssignments array = []
param keyVaultResourceId string
param keyVaultSecretNameAdminUsername string
param keyVaultSecretNameAdminPassword0 string
param keyVaultSecretNameAdminPassword1 string


param logAnalyticsWorkspaceId string



//MODULE REFERENCES

// PostgreSQL module --> relational database
module postgresSQLDatabase 'modules/postgres.bicep' = {
  name: 'postgres'
  params: {
    serverName: postgreSQLServerName
    databaseName: postgreSQLDatabaseName
    adminPassword: postgresAdminPassword
    location: location
    skuName: postgresSku
    environmentType: environmentType
  }
}


module keyVault 'modules/key-vault.bicep' = {
    name: 'keyVault'
    params: {
        keyVaultName: keyVaultName
        location: location
        environmentType: environmentType
        enableVaultForDeployment: true
        roleAssignments: keyVaultRoleAssignments
    }
}


module logAnalytics 'modules/log-analytics.bicep' = {
    name: 'logAnalytics'
    params: {
        location: location
    }
}


module appInsights 'modules/application-insights.bicep' = {
    name: 'appInsights'
    params: {
        location: location
        logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId

    }
}



module containerRegistry 'modules/container-registry.bicep' = {
    name: 'containerRegistry'
    params: {
        registryName: containerRegistryName
        location: location
        environmentType: environmentType
        keyVaultResourceId: keyVaultResourceId
        keyVaultSecreNameAdminUsername: keyVaultSecretNameAdminUsername
        keyVaultSecreNameAdminPassword0: keyVaultSecretNameAdminPassword0
        keyVaultSecreNameAdminPassword1: keyVaultSecretNameAdminPassword1
        logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    }
}


// App Service Plan 
module appServicePlan 'modules/app-service-plan.bicep' = {
  name: 'appServicePlan'
  params: {
    appServicePlanName: appServicePlanName
    location: location
    skuName: appServicePlanSku
    capacity: appServicePlanCapacity
    environmentType: environmentType
  }
}

// Azure Static Web App --> frontend
module frontend 'modules/frontend-app-service.bicep' = {
  name: 'frontend'
  params: {
    appName: appServiceAppName
    planId: appServicePlan.outputs.planId
    location: location
  }
  dependsOn: [
    appServicePlan
  ]
}


// Linux App Service --> backend 
module backend 'modules/backend-app-service.bicep' = {
  name: 'backend'
  params: {
    appServiceName: appServiceAppName
    appServiceAPIName: appServiceAPIAppName
    planId: appServicePlan.outputs.planId
    location: location
    environmentType: environmentType
    containerRegistryName: containerRegistryName
    dockerRegistryImageName: dockerRegistryImageName
    dockerRegistryImageTag: dockerRegistryImageTag
    envVars: {
      ENV: appServiceAPIEnvVarENV
      DBHOST: appServiceAPIEnvVarDBHOST
      DBNAME: appServiceAPIEnvVarDBNAME
      DBUSER: appServiceAPIEnvVarDBUSER
      DBPASS: appServiceAPIEnvVarDBPASS
      FLASK_APP: appServiceAPIDBHostFLASK_APP
      FLASK_DEBUG: appServiceAPIDBHostFLASK_DEBUG
      SCM_DO_BUILD_DEPLOYMENT: true
      APPINSIGHTS_INSTRUMENTATIONKEY: appInsightsInstrumentationKey
      APPLICATIONINSIGHTS_CONNECTION_STRING: appInsightsConnectionString 
    }
  }
  dependsOn: [
    containerRegistry
    appServicePlan
    keyVault
  ]
}



output frontendHostName string = frontend.outputs.appHostName
output backendHostName string = backend.outputs.appHostName
output containerRegistryLoginServer string = containerRegistry.outputs.registryLoginServer

