targetScope = 'resourceGroup'

param name string = 'servicebus-test'

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
    prefix: 'sb'
    serviceId: namespace.id
    serviceName: namespace.name
    serviceType: namespace.type
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

resource namespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: 'bus${suffix}'
  location: location
  sku: {
    name: 'Premium'
  }
}
