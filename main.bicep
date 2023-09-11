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

@description('Use existing zones for this resource type.')
param useExistingZones bool = false

@allowed([
  'Microsoft.EventHub/namespaces'
  'Microsoft.ServiceBus/namespaces'
  'Microsoft.Web/sites'
])
@description('The resource type of the service the endpoint is for.')
param serviceType string

var cleanedServiceType = toLower(replace(replace(serviceType, '/', '-'), '.', '-'))

var groupIds = serviceType == 'Microsoft.EventHub/namespaces' ? [
  'namespace'
] : serviceType == 'Microsoft.ServiceBus/namespaces' ? [
  'namespace'
] : serviceType == 'Microsoft.Web/sites' ? [
  'sites'
] : []

var zones = serviceType == 'Microsoft.EventHub/namespaces' ? [
  'privatelink.servicebus.windows.net'
] :  serviceType == 'Microsoft.ServiceBus/namespaces' ? [
  'privatelink.servicebus.windows.net'
] : serviceType == 'Microsoft.Web/sites' ? [
  'privatelink.azurewebsites.net'
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

resource existingDnsZones 'Microsoft.Network/privateDnsZones@2018-09-01' existing = [for zone in zones: if(useExistingZones) {
  name: zone
}]

resource newDnsZones 'Microsoft.Network/privateDnsZones@2018-09-01' = [for zone in zones: if(!useExistingZones) {
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
        privateDnsZoneId: !useExistingZones ? newDnsZones[i].id : existingDnsZones[i].id
      }
    }]
  }
}]

// parent can't be output of condition so have to have condition at top level
resource networkLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = [for (zone, index) in zones: if (!useExistingZones) {
  name: newDnsZones[index].name
  parent: newDnsZones[index]
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
  dependsOn: [
    dnsGoups // slow down due to race condition on zone
  ]
}]

resource networkLinkExistingZones 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = [for (zone, index) in zones: if (useExistingZones) {
  name: existingDnsZones[index].name
  parent: existingDnsZones[index]
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
  dependsOn: [
    dnsGoups // slow down due to race condition on zone
  ]
}]
