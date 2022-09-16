
param location string = resourceGroup().location
param cosmosDbResName string 
param serviceBusResName string 
param storageAccountResName string 
param logAnalyticsWorkspaceResName string 
param appInsightsResName string 

// Cosmosdb
module cosmosdb 'cosmosdb.bicep' = {
  name: '${deployment().name}--cosmosdb'
  params: {
    accountName: cosmosDbResName
    location: location
    primaryRegion: location
    databaseName: 'tasksmanagerdb'
    containerName: 'taskscollection'
  }
}

// Servicebus
module serviceBus 'serviceBus.bicep' = {
  name: '${deployment().name}--serviceBus'
  params: {
    serviceBusName: serviceBusResName
    location: location
  }
}

//StorageAccount
module storageAccount 'storageAccount.bicep' = {
  name: '${deployment().name}--storageAccount'
  params: {
    storageAccountName: storageAccountResName
    location: location
  }
}

//logAnalyticsWorkspace
module logAnalyticsWorkspace 'logAnalyticsWorkspace.bicep' = {
  name: '${deployment().name}--logAnalyticsWorkspace'
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceResName
    location: location
  }
}

//AppInsights
module appInsights 'appInsights.bicep' = {
  name: '${deployment().name}--appInsights'
  params: {
    appInsightsName: appInsightsResName
    location: location
    workspaceResourceId: logAnalyticsWorkspace.outputs.workspaceResourceId
  }
}

output cosmosDbDocumentEndpoint string = cosmosdb.outputs.documentEndpoint
output logAnalyticsWorkspaceCustomerId string = logAnalyticsWorkspace.outputs.logAnalyticsWorkspaceCustomerId
