targetScope = 'resourceGroup'

param name string = 'storage-test'

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
    prefix: 'store'
    serviceId: storage.id
    serviceType: storage.type
    subnetId: vnet.outputs.subnetId
    vnetId: vnet.outputs.id
    useExistingZones: true
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

var cleanedName = replace(name, '-', '')
resource storage 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: '${cleanedName}${suffix}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_ZRS'
  }
}
