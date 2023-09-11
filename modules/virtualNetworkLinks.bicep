targetScope = 'resourceGroup'


@description('The resource ID of the vnet the private DNS zones will be attached to.')
param vnetId string

param zones array

resource existingDnsZones 'Microsoft.Network/privateDnsZones@2018-09-01' existing = [for zone in zones: {
  name: zone
}]

resource networkLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = [for (zone, index) in zones: {
  name: existingDnsZones[index].name
  parent: existingDnsZones[index]
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}]
