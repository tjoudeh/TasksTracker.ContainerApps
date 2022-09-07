@description('The location where we will deploy our resources to. Default is the location of the resource group')
param location string = resourceGroup().location

@description('The name of the service bus namespace')
param serviceBusName string

var topicName = 'tasksavedtopic'

resource service_bus 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
  name: serviceBusName
  location: location
  sku: {
    name: 'Standard'
  }
}

resource topic 'Microsoft.ServiceBus/namespaces/topics@2021-11-01' = {
  name: topicName
  parent: service_bus
}



var listKeysEndpoint = '${service_bus.id}/AuthorizationRules/RootManageSharedAccessKey'
var sharedAccessKey = '${listKeys(listKeysEndpoint, service_bus.apiVersion).primaryKey}'
var connectionStringValue = 'Endpoint=sb://${service_bus.name}.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=${sharedAccessKey}'
output connectionString string = connectionStringValue
