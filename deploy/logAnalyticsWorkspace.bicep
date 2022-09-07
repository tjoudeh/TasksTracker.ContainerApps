param logAnalyticsWorkspaceName string
param location string = 'eastus'


resource logAnalyticsWorkspace'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

var sharedKey = listKeys(logAnalyticsWorkspace.id, logAnalyticsWorkspace.apiVersion).primarySharedKey

output workspaceResourceId string = logAnalyticsWorkspace.id
output logAnalyticsWorkspaceCustomerId string = logAnalyticsWorkspace.properties.customerId
output logAnalyticsWorkspacePrimarySharedKey string = sharedKey
