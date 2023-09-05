targetScope = 'subscription'

param name string = deployment().name
param location string = deployment().location

resource group 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: name
  location: location
}

var cidrs = {
  function_test: '10.0.0.0/24'
}

module function_test 'microsoft_web_sites/function_test.bicep' = {
  scope: group
  name: 'function_test'
  params: {
    cidr: cidrs.function_test
    location: location
  }
}
