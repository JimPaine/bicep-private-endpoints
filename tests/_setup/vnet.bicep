targetScope = 'resourceGroup'

param name string
param location string = resourceGroup().location

param cidr string

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        cidr
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: cidr
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

output id string = vnet.id
output subnetId string = vnet.properties.subnets[0].id
