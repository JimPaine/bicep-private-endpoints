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
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  name: 'subnet'
  parent: vnet
  properties: {
    addressPrefix: cidr
    privateEndpointNetworkPolicies: 'Disabled'
  }
}

output id string = vnet.id
output subnetId string = subnet.id
