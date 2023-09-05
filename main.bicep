targetScope = 'resourceGroup'

@description('The location the resources will be deployed to.')
param location string = resourceGroup().location

@description('The prefix to use when naming resources.')
param prefix string

@description('The resource ID of the vnet the private DNS zones will be attached to.')
param vnetId string

@description('The resource ID of the subnet that the endpoint will be deployed to.')
param subnetId string

@description('The resource ID of the service the endpoint is for.')
param serviceId string

@allowed([
  'Microsoft.Web/sites'
  'Microsoft.ServiceBus/namespaces'
])
@description('The resource type of the service the endpoint is for.')
param serviceType string

var cleanedServiceType = toLower(replace(replace(serviceType, '/', '-'), '.', '-'))

var groupIds = serviceType == 'Microsoft.Web/sites' ? [
  'sites'
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
