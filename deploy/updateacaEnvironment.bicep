param location string = resourceGroup().location
param environmentName string = 'tasks-tracker-containerapps-env'
param appInsightsName string = 'taskstracker-ai'
param logAnalyticsWorkspaceName string ='workspace-taskstrackerrgRItW'


resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
    name: appInsightsName
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource environment 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: environmentName
  location: location
  properties: {
    daprAIInstrumentationKey:appInsights.properties.InstrumentationKey
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: listKeys(logAnalyticsWorkspace.id, logAnalyticsWorkspace.apiVersion).primarySharedKey
      }
    }
  }
}

