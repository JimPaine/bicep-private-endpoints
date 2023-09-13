# bicep-private-endpoints

Private endpoints are painful to work with, the documentation is great but key information about group ids and zones are hard to find. This bicep module aims to solve this problem by wrapping everything up in a simple approach that means you are no longer wasting hours finding privatelink zone names at the start of every project.


## Get started

Start of by grabbing the latest module from [here](https://github.com/JimPaine/bicep-private-endpoints/releases)

> It is on the backlog to put into a registry.

Then reference the module and pass the required parameters and that is it! The module will create all the required group IDs, zones and endpoints and then associate them to your network and resource of choice.

```bicep
resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: name
  location: location
  properties: {
    // simplified for ease of consumption
  }
}

resource func 'Microsoft.Web/sites@2020-12-01' = {
  name: '${name}${suffix}'
  location: location
  kind: 'functionapp,linux'

  properties: {
    // simplified for ease of consumption
  }
}

module endpoints 'main.json' = {
  name: '${name}-endpoints'
  params: {
    location: location
    serviceId: func.id
    serviceName: func.name
    serviceType: func.type
    subnetId: vnet.properties.subnets[0].id
    vnetId: vnet.id
  }
}
```

## Required parameters

| Name        | Type          | Description                                                            |
| ----------- | ------------- | ---------------------------------------------------------------------- |
| location    | string        | The location the resources will be deployed to.                        |
| serviceId   | resource ID   | The resource ID of the service the endpoint is for.                    |
| serviceName | string        | The name of the resource the endpoint is for.                          |
| serviceType | resource type | The resource type of the service the endpoint is for.                  |
| subnetId    | resource ID   | The resource ID of the subnet that the endpoint will be deployed to.   |
| vnetId      | resource ID   | The resource ID of the vnet the private DNS zones will be attached to. |

## Optional parameters

| Name                     | Type   | Description                                                      |
| ------------------------ | ------ | ---------------------------------------------------------------- |
| useExistingZones         | bool   | The Use existing zones for this resource type.                   |
| serviceResourceGroupName | string | The name of the resource group the service has been deployed to. |

## Supported resources

- Microsoft.AppConfiguration/configurationStores
- Microsoft.ContainerRegistry/registries
- Microsoft.EventHub/namespaces
- Microsoft.KeyVault/vaults
- Microsoft.ServiceBus/Namespaces
- Microsoft.SignalRService/signalR
- Microsoft.Storage/storageAccounts
- Microsoft.Web/Sites
- Microsoft.Web/staticSites