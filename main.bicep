targetScope = 'resourceGroup'

@description('The location the resource should be deployed to. Defaults to resource group location.')
param location string = resourceGroup().location

param prefix string

param vnetId string

param subnetId string

param serviceId string

@allowed([
  'Microsoft.Web/sites'
])
@description('')
param serviceType string

var groupIds = serviceType == 'Microsoft.Web/sites' ? [
  'sites'
] : []

var zones = serviceType == 'Microsoft.Web/sites' ? [
  'privatelink.azurewebsites.net'
] : []

@batchSize(1)
resource endpoints 'Microsoft.Network/privateEndpoints@2021-05-01' = [for groupId in groupIds: {
  name: '${prefix}-${serviceType}-${groupId}-pe'
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${serviceType}-pe'
        properties: {
          privateLinkServiceId: serviceId
          groupIds: [
            groupId
          ]
        }
      }
    ]
  }
}]

resource dnsZones 'Microsoft.Network/privateDnsZones@2018-09-01' = [for zone in zones: {
  name: zone
  location: 'global'
}]

resource dnsGoups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = [for (groupId, index) in groupIds: {
  name: '${prefix}-${serviceType}-${groupId}-group'
  parent: endpoints[index]
  properties: {
    privateDnsZoneConfigs: [for (zone, i) in zones: {
      name: zone
      properties: {
        privateDnsZoneId: dnsZones[i].id
      }
    }]
  }
}]

resource networkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = [for (zone, index) in zones: {
  name: dnsZones[index].name
  parent: dnsZones[index]
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}]