@sys.description('The environment type')
@allowed([
  'dev'
  'uat'
  'prod'
])
param environmentType string = 'dev'

@sys.description('The user alias to add to the deployment name')
param userAlias string = 'apayne'

@sys.description('PostgreSQL admin password stored securely in Key Vault')
@secure()
param postgresAdminPassword string = keyVault.getSecret('postgres-admin-password')

@sys.description('The value for the environment variable DBPASS stored securely in Key Vault')
@secure()
param appServiceAPIEnvVarDBPASS string


@sys.description('The PostgreSQL Server name')
param postgreSQLServerName string = 'ie-bank-db-server-${environmentType}'

@sys.description('The PostgreSQL Database name')
param postgreSQLDatabaseName string = 'ie-bank-db'

@sys.description('The App Service Plan name')
param appServicePlanName string = 'ie-bank-app-sp-${environmentType}'

@sys.description('The Web App name (frontend)')
param appServiceAppName string = 'ie-bank-${environmentType}'

@sys.description('The API App name (backend)')
param appServiceAPIAppName string = 'ie-bank-api-${environmentType}'

@sys.description('The Azure location where the resources will be deployed')
param location string = resourceGroup().location

@sys.description('The value for the environment variable ENV')
param appServiceAPIEnvVarENV string = environmentType

@sys.description('The value for the environment variable DBHOST')
param appServiceAPIEnvVarDBHOST string = '${postgreSQLServerName}.postgres.database.azure.com'

@sys.description('The value for the environment variable DBNAME')
param appServiceAPIEnvVarDBNAME string = postgreSQLDatabaseName

@sys.description('The value for the environment variable DBUSER')
param appServiceAPIEnvVarDBUSER string = 'iebankdbadmin@${postgreSQLServerName}'

@sys.description('The value for the environment variable FLASK_APP')
param appServiceAPIDBHostFLASK_APP string = 'app.py'

@sys.description('The value for the environment variable FLASK_DEBUG')
@allowed(['0', '1'])
param appServiceAPIDBHostFLASK_DEBUG string = environmentType == 'prod' ? '0' : '1'


@sys.description('SKU for PostgreSQL (dynamic based on environment)')
var postgresSku = environmentType == 'prod' ? 'GP_B2ms' : (environmentType == 'uat' ? 'Standard_B1ms' : 'Standard_B1ms')

@sys.description('App Service Plan SKU (dynamic based on environment)')
var appServicePlanSku = environmentType == 'prod' ? 'P1v2' : 'B1'

@sys.description('App Service Plan capacity (dynamic based on environment)')
var appServicePlanCapacity = environmentType == 'prod' ? 3 : (environmentType == 'uat' ? 2 : 1)



//MODULE REFERENCES

// PostgreSQL module --> relational database
module postgres 'modules/postgres.bicep' = {
  name: 'postgres-${userAlias}'
  params: {
    serverName: postgreSQLServerName
    databaseName: postgreSQLDatabaseName
    adminPassword: postgresAdminPassword
    location: location
    skuName: postgresSku
  }
}


module keyVault 'modules/key-vault.bicep' = {
    name: 'keyVault-${userAlias}'
    params: {
        location: location
    }
}


module logAnalytics 'modules/log-analytics.bicep' = {
    name: 'logAnalytics-${userAlias}'
    params = {
        location: location
    }
}


module appInsights 'modules/application-insights.bicep' = {
    name: 'appInsights-${userAlias}'
    params = {
        location: location
        logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId

    }
}

// App Service Plan --> WHAT DOES THIS DO?? 
module appServicePlan 'modules/app-service-plan.bicep' = {
  name: 'appServicePlan-${userAlias}'
  params: {
    planName: appServicePlanName
    location: location
    skuName: appServicePlanSku
    capacity: appServicePlanCapacity
  }
}


module containerRegistry 'modules/container-registry.bicep' = {
    name: 'containerRegistry-${user-alias}'
    params = {
        location: location
    }
}

// Azure Static Web App --> frontend
module frontend 'modules/frontend-app-service.bicep' = {
  name: 'frontend-${userAlias}'
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
  name: 'backend-${userAlias}'
  params: {
    appName: appServiceAPIAppName
    planId: appServicePlan.outputs.planId
    location: location
    envVars: {
      ENV: appServiceAPIEnvVarENV
      DBHOST: appServiceAPIEnvVarDBHOST
      DBNAME: appServiceAPIEnvVarDBNAME
      DBUSER: appServiceAPIEnvVarDBUSER
      DBPASS: appServiceAPIEnvVarDBPASS
      FLASK_APP: appServiceAPIDBHostFLASK_APP
      FLASK_DEBUG: appServiceAPIDBHostFLASK_DEBUG
    }
  }
  dependsOn: [
    postgres
    appServicePlan
    appInsights
  ]
}



output frontendHostName string = frontend.outputs.appHostName
output backendHostName string = backend.outputs.appHostName
