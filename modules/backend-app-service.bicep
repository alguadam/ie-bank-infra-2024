param appName string
param planId string
param location string
param envVars object

@allowed([
  'dev'
  'uat'
  'prod'
])
param environmentType string 

var backendConfig = {
  dev: {
    alwaysOn: false
  }
  uat: {
    alwaysOn: false
  }
  prod: {
    alwaysOn: true
  }
}
var alwaysOnSetting = backendConfig[environmentType].alwaysOn

resource backendApp 'Microsoft.Web/sites@2021-02-01' = {
  name: appName
  location: location
  properties: {
    serverFarmId: planId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.11' 
      alwaysOn: alwaysOnSetting
      ftpsState: 'FtpsOnly'
      appSettings: [
        for key in keys(envVars): {
          name: key
          value: envVars[key]
        }
      ]
    }
  }
}

output appHostName string = backendApp.properties.defaultHostName
