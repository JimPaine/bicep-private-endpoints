targetScope = 'subscription'

param name string = deployment().name
param location string = deployment().location

resource group 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: name
  location: location
}

var cidrs = {
  function_test: '10.0.0.0/24'
  servicebus_test: '10.0.1.0/24'
  eventhub_test: '10.0.2.0/24'
  storage_test: '10.0.3.0/24'
  webapp_test: '10.0.4.0/24'
  app_config_test: '10.0.5.0/24'
  static_site_test: '10.0.6.0./24'
  signal_r_test: '10.0.7.0/24'
  vault_test: '10.0.8.0/24'
}

module function_test 'microsoft_web/sites_function.bicep' = {
  scope: group
  name: 'function_test'
  params: {
    cidr: cidrs.function_test
    location: location
  }
}

module webapp_test 'microsoft_web/sites.bicep' = {
  scope: group
  name: 'webapp_test'
  params: {
    cidr: cidrs.webapp_test
    location: location
  }
  dependsOn: [
    function_test
  ]
}

module servicebus_test 'microsoft_servicebus/namespaces.bicep' = {
  scope: group
  name: 'servicebus_test'
  params: {
    cidr: cidrs.servicebus_test
    location: location
  }
}

module eventhub_test 'microsoft_eventhub/namespaces.bicep' = {
  scope: group
  name: 'eventhub_test'
  params: {
    cidr: cidrs.eventhub_test
    location: location
  }
  dependsOn: [
    servicebus_test // they share the same dns zone, so create the zone and links in SB and then add additional groups
  ]
}

module storage_test 'microsoft_storage/storageaccounts.bicep' = {
  scope: group
  name: 'storage_test'
  params: {
    cidr: cidrs.storage_test
    location: location
  }
}

module app_config_test 'microsoft_appconfiguration/configurationstores.bicep' = {
  scope: group
  name: 'app_config_test'
  params: {
    cidr: cidrs.app_config_test
    location: location
  }
}

// exclude due to capacity issues
// module static_site_test 'microsoft_web/staticSites.bicep' = {
//   scope: group
//   name: 'static_site_test'
//   params: {
//     cidr: cidrs.static_site_test
//     location: location
//   }
// }

module signal_r_test 'microsoft_signalrservice/signalr.bicep' = {
  scope: group
  name: 'signal_r_test'
  params: {
    cidr: cidrs.signal_r_test
    location: location
  }
}

module vault_test 'microsoft_keyvault/vaults.bicep' = {
  scope: group
  name: 'vault_test'
  params: {
    cidr: cidrs.vault_test
    location: location
  }
}
