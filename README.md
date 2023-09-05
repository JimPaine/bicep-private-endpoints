# bicep-private-endpoints

Private endpoints are painful to work with, the documentation is great but key information about group ids and zones are hard to find. This bicep module aims to solve this problem by wrapping everything up in a simple approach that means you are no longer wasting hours finding privatelink zone names at the start of every project.


## Get started

Start of by grabbing the latest module from [here](https://github.com/JimPaine/bicep-private-endpoints/releases)

> It is on the backlog to put into a registry.

Then reference the module and pass the required parameters.

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
    prefix: func.name
    serviceId: func.id
    serviceType: func.type
    subnetId: vnet.outputs.subnetId
    vnetId: vnet.outputs.id
  }
}
```

## Required parameters

| Name        | Type          | Description                                                            |
| ----------- | ------------- | ---------------------------------------------------------------------- |
| location    | string        | The location the resources will be deployed to.                        |
| prefix      | string        | The prefix to use when naming resources.                               |
| serviceId   | resource ID   | The resource ID of the service the endpoint is for.                    |
| serviceType | resource type | The resource type of the service the endpoint is for.                  |
| subnetId    | resource ID   | The resource ID of the subnet that the endpoint will be deployed to.   |
| vnetId      | resource ID   | The resource ID of the vnet the private DNS zones will be attached to. |


## Supported resources

- Microsoft.Web/Sites
- Microsoft.ServiceBus/Namespaces
