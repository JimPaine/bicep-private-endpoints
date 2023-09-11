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
}

module function_test 'microsoft_web_sites/function_test.bicep' = {
  scope: group
  name: 'function_test'
  params: {
    cidr: cidrs.function_test
    location: location
  }
}

module servicebus_test 'microsoft_servicebus_namespaces/servicebus_test.bicep' = {
  scope: group
  name: 'servicebus_test'
  params: {
    cidr: cidrs.servicebus_test
    location: location
  }
}

module eventhub_test 'microsoft_servicebus_namespaces/servicebus_test.bicep' = {
  scope: group
  name: 'eventhub_test'
  params: {
    cidr: cidrs.eventhub_test
    location: location
  }
}

