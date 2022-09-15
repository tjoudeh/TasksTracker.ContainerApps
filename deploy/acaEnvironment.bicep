param acaEnvironmentName string
param location string = resourceGroup().location
@secure()
param instrumentationKey string
param logAnalyticsWorkspaceCustomerId string
@secure()
param logAnalyticsWorkspacePrimarySharedKey string 

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

output acaEnvironmentId string = environment.id
