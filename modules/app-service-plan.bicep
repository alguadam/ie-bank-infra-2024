param appServicePlanName string
param location string
@allowed([
  'dev'
  'uat'
  'prod'
])
param environmentType string

var environmentConfig = {
  dev: {
    sku: 'B1'
    capacity: 1
  }
  uat: {
    sku: 'S1'
    capacity: 2
  }
  prod: {
    sku: 'P1v2'
    capacity: 3
  }
}

var skuName = environmentConfig[environmentType].sku
var capacity = environmentConfig[environmentType].capacity

resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: skuName
    capacity: capacity
  }
  kind: 'linux'
  properties: {
    reserved: true     // for a linux-based AS
  }
}

output planId string = appServicePlan.id
