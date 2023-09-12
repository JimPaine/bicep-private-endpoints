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
  'Microsoft.EventHub/namespaces'
  'Microsoft.ServiceBus/namespaces'
  'Microsoft.Storage/storageAccounts'
  'Microsoft.Web/sites'
  'Microsoft.Web/staticSites'
])
@description('The resource type of the service the endpoint is for.')
param serviceType string

@description('The group IDs required for the private endpoint.')
param groupIds array

@description('The zones required for the private endpoint.')
param zones array

var cleanedServiceType = toLower(replace(replace(serviceType, '/', '-'), '.', '-'))

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

resource existingDnsZones 'Microsoft.Network/privateDnsZones@2018-09-01' existing = [for zone in zones: {
  name: zone
}]

resource dnsGoups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = [for (groupId, index) in groupIds: {
  name: '${prefix}-${cleanedServiceType}-${groupId}-group'
  parent: endpoints[index]
  properties: {
    privateDnsZoneConfigs: [for (zone, i) in zones: {
      name: zone
      properties: {
        privateDnsZoneId: existingDnsZones[i].id
      }
    }]
  }
}]

resource networkLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = [for (zone, index) in zones: {
  name: '${zone}/${prefix}'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
  dependsOn: existingDnsZones
}]
