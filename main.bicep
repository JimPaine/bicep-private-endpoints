targetScope = 'resourceGroup'

@description('The location the resource should be deployed to. Defaults to resource group location.')
param location string = resourceGroup().location

param prefix string

param vnetId string

param subnetId string

param serviceId string

@allowed([
  'Microsoft.Web/sites'
  'Microsoft.ServiceBus/namespaces'
])
param serviceType string

var cleanedServiceType = toLower(replace(replace(serviceType, '/', '-'), '.', '-'))

var groupIds = serviceType == 'Microsoft.Web/sites' ? [
  'sites'
  'FAILTEST'
] : serviceType == 'Microsoft.ServiceBus/namespaces' ? [
  'namespace'
] : []

var zones = serviceType == 'Microsoft.Web/sites' ? [
  'privatelink.azurewebsites.net'
] :  serviceType == 'Microsoft.ServiceBus/namespaces' ? [
  'privatelink.servicebus.windows.net'
] : []

@batchSize(1)
resource endpoints 'Microsoft.Network/privateEndpoints@2021-05-01' = [for groupId in groupIds: {
  name: '${prefix}-${cleanedServiceType}-${groupId}-pe'
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${cleanedServiceType}-pe'
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
  name: '${prefix}-${cleanedServiceType}-${groupId}-group'
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
