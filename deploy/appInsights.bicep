param location string = 'eastus'
param workspaceResourceId string 
param appInsightsName string

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId:workspaceResourceId
  }
}

output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
