targetScope = 'resourceGroup'

param name string = 'webapp-test'

@description('Location to deploy test resources to. Defaults to resource group location')
param location string = resourceGroup().location

@description('The CIDR to use for the vnet. The same block will be used for a vnet with a single subnet.')
param cidr string

var suffix = uniqueString(subscription().id, resourceGroup().id)

///////////////////////////////////////
// TEST
///////////////////////////////////////
module endpoints '../../main.bicep' = {
  name: '${name}-endpoints'
  params: {
    location: location
    prefix: 'web'
    serviceId: app.id
    serviceType: app.type
    subnetId: vnet.outputs.subnetId
    vnetId: vnet.outputs.id
  }
}

///////////////////////////////////////
// Required resources
///////////////////////////////////////
module vnet '../_setup/vnet.bicep' = {
  name: '${name}-setup-vnet'
  params: {
    cidr: cidr
    location: location
    name: name
  }
}

resource farm 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'appfarm'
  location: location
  kind: 'linux'
  sku: {
    name: 'P1V3'
    tier: 'PremiumV3'
  }

  properties: {
    reserved: true
    zoneRedundant: false
    targetWorkerCount: 3
    targetWorkerSizeId: 3
  }
}


resource app 'Microsoft.Web/sites@2020-12-01' = {
  name: '${name}${suffix}'
  location: location

  properties: {
    serverFarmId: farm.id
    siteConfig: {
      appSettings: []
    }
  }
}
