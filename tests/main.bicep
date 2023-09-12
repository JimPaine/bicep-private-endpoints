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
}

module function_test 'microsoft_web_sites/function_test.bicep' = {
  scope: group
  name: 'function_test'
  params: {
    cidr: cidrs.function_test
    location: location
  }
}

module webapp_test 'microsoft_web_sites/webapp_test.bicep' = {
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

module servicebus_test 'microsoft_servicebus_namespaces/servicebus_test.bicep' = {
  scope: group
  name: 'servicebus_test'
  params: {
    cidr: cidrs.servicebus_test
    location: location
  }
}

module eventhub_test 'microsoft_eventhub_namespaces/eventhub_test.bicep' = {
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

module storage_test 'microsoft_storage_storageaccounts/blob_file_queue_table_test.bicep' = {
  scope: group
  name: 'storage_test'
  params: {
    cidr: cidrs.storage_test
    location: location
  }
}

module app_config_test 'microsoft_appconfiguration_configurationstores/app_config.bicep' = {
  scope: group
  name: 'app_config_test'
  params: {
    cidr: cidrs.app_config_test
    location: location
  }
}

module static_site_test 'microsoft_web_staticsites/staticsite_test.bicep' = {
  scope: group
  name: 'static_site_test'
  params: {
    cidr: cidrs.static_site_test
    location: location
  }
}
