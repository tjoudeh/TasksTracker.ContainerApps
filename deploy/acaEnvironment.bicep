param acaEnvironmentName string
param location string = resourceGroup().location
@secure()
param instrumentationKey string
param logAnalyticsWorkspaceCustomerId string
@secure()
param logAnalyticsWorkspacePrimarySharedKey string 
param storageAccountResName string
@secure()
param storageAccountResourceKey string 
param storageNameMount string

resource environment 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: acaEnvironmentName
  location: location
  properties: {
    daprAIInstrumentationKey:instrumentationKey
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspaceCustomerId
        sharedKey: logAnalyticsWorkspacePrimarySharedKey
      }
    }
  }
}

//Environment Storages
resource permanentStorageMount 'Microsoft.App/managedEnvironments/storages@2022-03-01' = {
  name: storageNameMount
  parent: environment
  properties: {
    azureFile: {
      accountName: storageAccountResName
      accountKey: storageAccountResourceKey
      shareName: 'permanent-file-share'
      accessMode: 'ReadWrite'
    }
  }
}

output acaEnvironmentId string = environment.id
