targetScope = 'resourceGroup'

param name string = 'function-test'

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
    prefix: 'func'
    serviceId: func.id
    serviceType: func.type
    subnetId: vnet.outputs.subnetId
    vnetId: vnet.outputs.id
  }
}

///////////////////////////////////////
// Required resources
///////////////////////////////////////
module vnet '../_setup/vnet.bicep' = {
  name: 'setup_vnet'
  params: {
    cidr: cidr
    location: location
    name: name
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: 'func${suffix}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_ZRS'
  }
}

var connectionString = 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=core.windows.net'


resource farm 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'farm'
  location: location
  kind: 'linux'
  sku: {
    name: 'EP1'
    tier: 'ElasticPremium'
  }

  properties: {
    reserved: true
    zoneRedundant: true
    targetWorkerCount: 3
    targetWorkerSizeId: 3
    maximumElasticWorkerCount: 20
  }
}


resource func 'Microsoft.Web/sites@2020-12-01' = {
  name: '${name}${suffix}'
  location: location
  kind: 'functionapp,linux'

  properties: {
    serverFarmId: farm.id
    siteConfig: {
      linuxFxVersion: 'Python|3.10'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: connectionString
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: connectionString
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(storage.name)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
      ]
    }
  }
}
