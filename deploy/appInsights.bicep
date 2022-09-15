param location string = resourceGroup().location
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

//Donot use output params to pass keys for other resources
//output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
