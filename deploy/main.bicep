param appname string = 'taskstrackertest'
param location string = resourceGroup().location

param backendApiName string = 'tasksmanager-backend-api'
param backendApiImage string = '${containerRegistry}/${backendApiName}:latest'
param backendApiPort int = 80

param frontendWebAppName string = 'tasksmanager-frontend-webapp'
param frontendWebAppImage string = '${containerRegistry}/${frontendWebAppName}:latest'
param frontendWebAppPort int = 80

param backendSvcName string = 'tasksmanager-backend-processor'
param backendSvcImage string = '${containerRegistry}/${backendSvcName}:latest'
param backendSvcPort int = 80

param containerRegistry string = 'taskstrackeracr.azurecr.io'
param containerRegistryUsername string = 'taskstrackeracr'
@secure()
param containerRegistryPassword string = ''
param registryPassName string = 'registry-password'

@secure()
param sendGridApiKey string = ''

var environmentName = '${appname}-env'

// Cosmosdb
var cosmosDbResName = '${appname}-cosmos'
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
var serviceBusResName = appname
module serviceBus 'serviceBus.bicep' = {
  name: '${deployment().name}--serviceBus'
  params: {
    serviceBusName: serviceBusResName
    location: location
  }
}

//StorageAccount
var storageAccountResName = appname
module storageAccount 'storageAccount.bicep' = {
  name: '${deployment().name}--storageAccount'
  params: {
    storageAccountName: storageAccountResName
    location: location
  }
}

//logAnalyticsWorkspace
var logAnalyticsWorkspaceResName = '${appname}-logs'
module logAnalyticsWorkspace 'logAnalyticsWorkspace.bicep' = {
  name: '${deployment().name}--logAnalyticsWorkspace'
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceResName
    location: location
  }
}

//AppInsights
var appInsightsResName = '${appname}-ai'
module appInsights 'appInsights.bicep' = {
  name: '${deployment().name}--appInsights'
  params: {
    appInsightsName: appInsightsResName
    location: location
    workspaceResourceId: logAnalyticsWorkspace.outputs.workspaceResourceId
  }
}

//Reference to AppInsights resource
resource appInsightsResource 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsResName
}

//Reference to cosmosdb resource
resource cosmosdbResource 'Microsoft.DocumentDB/databaseAccounts@2021-01-15' existing = {
  name: cosmosDbResName
}

//Reference to LogAnalytics resource
resource logAnalyticsWorkspaceResource 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceResName
}

//Reference to ServiceBus resource
resource serviceBusResource 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: serviceBusResName
}

//Reference to ServiceBus resource
resource storageAccountResource 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageAccountResName
}

//Build Svc Bus Connection String
var listKeysEndpoint = '${serviceBusResource.id}/AuthorizationRules/RootManageSharedAccessKey'
var sharedAccessKey = '${listKeys(listKeysEndpoint, serviceBusResource.apiVersion).primaryKey}'
var serviceBusConStringValue = 'Endpoint=sb://${serviceBusResName}.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=${sharedAccessKey}'

// Container Apps Environment 
module environment 'acaEnvironment.bicep' = {
dependsOn: [
appInsights
logAnalyticsWorkspaceResource
]
  name: '${deployment().name}--acaenvironment'
  params: {
    acaEnvironmentName: environmentName
    location: location
    instrumentationKey: appInsightsResource.properties.InstrumentationKey
    logAnalyticsWorkspaceCustomerId: logAnalyticsWorkspace.outputs.logAnalyticsWorkspaceCustomerId
    logAnalyticsWorkspacePrimarySharedKey: listKeys(logAnalyticsWorkspaceResource.id, logAnalyticsWorkspaceResource.apiVersion).primarySharedKey
  }
}

// Backend API App
module backendApiApp 'containerApp.bicep' = {
  name: '${deployment().name}--${backendApiName}'
  dependsOn: [
    environment
    appInsights
    cosmosdb
  ]
  params: {
    enableIngress: true
    isExternalIngress: false
    location: location
    environmentId: environment.outputs.acaEnvironmentId
    containerAppName: backendApiName
    containerImage: backendApiImage
    targetPort: backendApiPort
    isPrivateRegistry: true
    minReplicas: 1
    maxReplicas: 2
    containerRegistry: containerRegistry
    containerRegistryUsername: containerRegistryUsername
    registryPassName: registryPassName
    revisionMode: 'Single'
    secListObj: {
      secArray: [
        {
          name: registryPassName
          value: containerRegistryPassword
        }
        {
          name: 'cosmosdb-key'
          value: listKeys(cosmosdbResource.id, cosmosdbResource.apiVersion).primaryMasterKey
        }
        {
          name: 'appinsights-key'
          value: appInsightsResource.properties.InstrumentationKey
        } ]
    }
    envList: [
      {
        name: 'cosmosDb__accountUrl'
        value: cosmosdb.outputs.documentEndpoint
      }
      {
        name: 'ApplicationInsights__InstrumentationKey'
        secretRef: 'appinsights-key'
      }
      {
        name: 'cosmosDb__key'
        secretRef: 'cosmosdb-key'
      } ]
  }
}

// Frontend WebApp App
module frontendWebAppApp 'containerApp.bicep' = {
  name: '${deployment().name}--${frontendWebAppName}'
  dependsOn: [
    environment
    backendApiApp
    appInsights
    appInsightsResource
  ]
  params: {
    enableIngress: true
    isExternalIngress: true
    location: location
    environmentId: environment.outputs.acaEnvironmentId
    containerAppName: frontendWebAppName
    containerImage: frontendWebAppImage
    targetPort: frontendWebAppPort
    isPrivateRegistry: true
    minReplicas: 1
    maxReplicas: 2
    containerRegistry: containerRegistry
    containerRegistryUsername: containerRegistryUsername
    registryPassName: registryPassName
    revisionMode: 'Single'
    secListObj: {
      secArray: [
        {
          name: registryPassName
          value: containerRegistryPassword
        }
        {
          name: 'appinsights-key'
          value: appInsightsResource.properties.InstrumentationKey
        } ]
    }
    envList: [
      {
        name: 'ApplicationInsights__InstrumentationKey'
        secretRef: 'appinsights-key'
      }
      {
        name: 'BackendApiConfig__BaseUrlExternalHttp'
        value: backendApiApp.outputs.fqdn
      } ]
  }
}

// Backend Svc App
module backendSvcApp 'containerApp.bicep' = {
  name: '${deployment().name}--${backendSvcName}'
  dependsOn: [
    environment
    appInsights
    serviceBus
  ]
  params: {
    enableIngress: false
    isExternalIngress: false
    location: location
    environmentId: environment.outputs.acaEnvironmentId
    containerAppName: backendSvcName
    containerImage: backendSvcImage
    targetPort: backendSvcPort
    isPrivateRegistry: true
    minReplicas: 1
    maxReplicas: 5
    containerRegistry: containerRegistry
    containerRegistryUsername: containerRegistryUsername
    registryPassName: registryPassName
    revisionMode: 'Single'
    useProbes: true
    secListObj: {
      secArray: [
        {
          name: registryPassName
          value: containerRegistryPassword
        }
        {
          name: 'sendgrid-apikey'
          value: sendGridApiKey
        }
        {
          name: 'appinsights-key'
          value: appInsightsResource.properties.InstrumentationKey
        }
        {
          name: 'svcbus-connstring'
          value: serviceBusConStringValue
        } ]
    }
    envList: [
      {
        name: 'ApplicationInsights__InstrumentationKey'
        secretRef: 'appinsights-key'
      }
      {
        name: 'SendGrid__ApiKey'
        secretRef: 'sendgrid-apikey'
      }
      {
        name: 'SendGrid__IntegrationEnabled'
        value: 'true'
      } ]
  }
}

//Statestore Component
resource statestoreDaprComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-03-01' = {
  name: '${environmentName}/statestore'
  dependsOn: [
    environment
    cosmosdb
  ]
  properties: {
    componentType: 'state.azure.cosmosdb'
    version: 'v1'
    secrets: [
      {
        name: 'cosmoskey'
        value: listKeys(cosmosdbResource.id, cosmosdbResource.apiVersion).primaryMasterKey
      }
    ]
    metadata: [
      {
        name: 'url'
        value: cosmosdb.outputs.documentEndpoint
      }
      {
        name: 'database'
        value: 'tasksmanagerdb'
      }
      {
        name: 'collection'
        value: 'taskscollection'
      }
      {
        name: 'masterkey'
        secretRef: 'cosmoskey'
      }
    ]
    scopes: [
      backendApiName
    ]
  }
}

//Scheduled Tasks Manager Component
resource scheduledtasksmanagerDaprComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-03-01' = {
  name: '${environmentName}/scheduledtasksmanager'
  dependsOn: [
    environment
  ]
  properties: {
    componentType: 'bindings.cron'
    version: 'v1'
    metadata: [
      {
        name: 'schedule'
        value: '@every 4h'
      }
    ]
    scopes: [
      backendSvcName
    ]
  }
}

//Periodic job State store Component
resource periodicjobstatestoreDaprComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-03-01' = {
  name: '${environmentName}/periodicjobstatestore'
  dependsOn: [
    environment
    storageAccount
    storageAccountResource
  ]
  properties: {
    componentType: 'state.azure.blobstorage'
    version: 'v1'
    secrets: [
      {
        name: 'storagekey'
        value: storageAccountResource.listKeys().keys[0].value
      }
    ]
    metadata: [
      {
        name: 'accountName'
        value: storageAccount.outputs.storageAccountName
      }
      {
        name: 'containerName'
        value: 'periodicjobcontainer'
      }
      {
        name: 'accountKey'
        secretRef: 'storagekey'
      }
    ]
    scopes: [
      backendSvcName
    ]
  }
}

//External tasks manager Component
resource externaltasksmanagerDaprComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-03-01' = {
  name: '${environmentName}/externaltasksmanager'
  dependsOn: [
    environment
    storageAccount
  ]
  properties: {
    componentType: 'bindings.azure.storagequeues'
    version: 'v1'
    secrets: [
      {
        name: 'storagekey'
        value: storageAccountResource.listKeys().keys[0].value
      }
    ]
    metadata: [
      {
        name: 'storageAccount'
        value: storageAccount.outputs.storageAccountName
      }
      {
        name: 'queue'
        value: 'external-tasks-queue'
      }
      {
        name: 'decodeBase64'
        value: 'true'
      }
      {
        name: 'route'
        value: '/externaltasksprocessor/process'
      }
      {
        name: 'storageAccessKey'
        secretRef: 'storagekey'
      }
    ]
    scopes: [
      backendSvcName
    ]
  }
}

//External tasks blob store Component
resource externaltasksblobstoreDaprComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-03-01' = {
  name: '${environmentName}/externaltasksblobstore'
  dependsOn: [
    environment
    storageAccount
  ]
  properties: {
    componentType: 'bindings.azure.blobstorage'
    version: 'v1'
    secrets: [
      {
        name: 'storagekey'
        value: storageAccountResource.listKeys().keys[0].value
      }
    ]
    metadata: [
      {
        name: 'storageAccount'
        value: storageAccount.outputs.storageAccountName
      }
      {
        name: 'container'
        value: 'externaltaskscontainer'
      }
      {
        name: 'decodeBase64'
        value: 'false'
      }
      {
        name: 'publicAccessLevel'
        value: 'none'
      }
      {
        name: 'storageAccessKey'
        secretRef: 'storagekey'
      }
    ]
    scopes: [
      backendSvcName
    ]
  }
}

//Emaillogs State store Component
resource emaillogsstatestoreDaprComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-03-01' = {
  name: '${environmentName}/emaillogsstatestore'
  dependsOn: [
    environment
    storageAccount
  ]
  properties: {
    componentType: 'state.azure.tablestorage'
    version: 'v1'
    secrets: [
      {
        name: 'storagekey'
        value: storageAccountResource.listKeys().keys[0].value
      }
    ]
    metadata: [
      {
        name: 'accountName'
        value: storageAccount.outputs.storageAccountName
      }
      {
        name: 'tableName'
        value: 'emaillogs'
      }
      {
        name: 'cosmosDbMode'
        value: 'False'
      }
      {
        name: 'accountKey'
        secretRef: 'storagekey'
      }
    ]
    scopes: [
      backendSvcName
    ]
  }
}

//pubsub Service Bus Component
resource pubsubServicebusDaprComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-03-01' = {
  name: '${environmentName}/dapr-pubsub-servicebus'
  dependsOn: [
    environment
    serviceBus
  ]
  properties: {
    componentType: 'pubsub.azure.servicebus'
    version: 'v1'
    secrets: [
      {
        name: 'sb-root-connectionstring'
        value: serviceBusConStringValue
      }
    ]
    metadata: [
      {
        name: 'connectionString'
        secretRef: 'sb-root-connectionstring'
      }
    ]
    scopes: [
      backendSvcName
      backendApiName
    ]
  }
}
