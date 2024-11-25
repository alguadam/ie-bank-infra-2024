param appName string
param planId string
param location string
@allowed([
  'dev'
  'uat'
  'prod'
])
param environmentType string

var frontendConfig = {
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
var alwaysOnSetting = frontendConfig[environmentType].alwaysOn


resource frontendApp 'Microsoft.Web/sites@2021-02-01' = {
  name: appName
  location: location
  properties: {
    serverFarmId: planId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|16-lts' 
      alwaysOn: alwaysOnSetting   
      ftpsState: 'FtpsOnly'
      appCommandLine: 'pm2 serve /home/site/wwroot --spa --no-daemon'
    } 
  }
}

output appHostName string = frontendApp.properties.defaultHostName
