targetScope = 'resourceGroup'

@description('The name of the resource the endpoint is for.')
param serviceName string

@description('The name of the resource group the service has been deployed to.')
param serviceResourceGroupName string = resourceGroup().name

@allowed([
  'Microsoft.AppConfiguration/configurationStores'
  'Microsoft.EventHub/namespaces'
  'Microsoft.ServiceBus/namespaces'
  'Microsoft.SignalRService/signalR'
  'Microsoft.Storage/storageAccounts'
  'Microsoft.Web/sites'
  'Microsoft.Web/staticSites'
])
@description('The resource type of the service the endpoint is for.')
param serviceType string

var zones = serviceType == 'Microsoft.AppConfiguration/configurationStores' ? [
  'privatelink.azconfig.io'
] : serviceType == 'Microsoft.EventHub/namespaces' ? [
  'privatelink.servicebus.windows.net'
] :  serviceType == 'Microsoft.ServiceBus/namespaces' ? [
  'privatelink.servicebus.windows.net'
] : serviceType == 'Microsoft.Storage/storageAccounts' ? [
  'privatelink.blob.${environment().suffixes.storage}'
  'privatelink.file.${environment().suffixes.storage}'
  'privatelink.queue.${environment().suffixes.storage}'
  'privatelink.table.${environment().suffixes.storage}'
] : serviceType == 'Microsoft.Web/sites' ? [
  'privatelink.azurewebsites.net'
] : serviceType == 'Microsoft.Web/staticSites' ? [
  'privatelink.${replace(static.properties.defaultHostname,static.name,'')}' // parition ID is generated at deploy time, so work around to find zone
] : []

resource static 'Microsoft.Web/staticSites@2022-09-01' existing = if (serviceType == 'Microsoft.Web/staticSites') {
  name: serviceName
  scope: resourceGroup(serviceResourceGroupName)
}

var groupIds = serviceType == 'Microsoft.AppConfiguration/configurationStores' ? [
  'configurationStores'
] : serviceType == 'Microsoft.EventHub/namespaces' ? [
  'namespace'
] : serviceType == 'Microsoft.ServiceBus/namespaces' ? [
  'namespace'
] : serviceType == 'Microsoft.Storage/storageAccounts' ? [
  'blob'
  'file'
  'queue'
  'table'
] : serviceType == 'Microsoft.Web/sites' ? [
  'sites'
] : serviceType == 'Microsoft.Web/staticSites' ? [
  'staticSites'
] : []

output zones array = zones
output groupIds array = groupIds
