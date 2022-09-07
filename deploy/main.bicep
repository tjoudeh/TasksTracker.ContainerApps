
param appname string = 'taskstrackertest'
param location string = 'eastus'


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
param registryPassword string = 'registry-password'

@secure()
param sendGridApiKey string = ''

var environmentName = '${appname}-env'

// Cosmosdb
module cosmosdb 'cosmosdb.bicep' = {
  name: '${deployment().name}--cosmosdb'
  params: {
    accountName: '${appname}-cosmos'
    location: location
    primaryRegion: location
    databaseName: 'tasksmanagerdb'
     containerName: 'taskscollection'
  }
}

// Servicebus
module serviceBus 'serviceBus.bicep' ={
  name: '${deployment().name}--serviceBus'
  params: {
     serviceBusName: appname
      location:location
  }
}

//StorageAccount
module storageAccount 'storageAccount.bicep' ={
  name: '${deployment().name}--storageAccount'
  params: {
     storageAccountName: appname
     location:location
      externalTasksQueueName: 'external-tasks-queue'
 }
}

//logAnalyticsWorkspace
module logAnalyticsWorkspace 'logAnalyticsWorkspace.bicep' = {
  name: '${deployment().name}--logAnalyticsWorkspace'
  params:{
     logAnalyticsWorkspaceName: '${appname}-logs'
      location: location
  }
}

//AppInsights
module appInsights 'appInsights.bicep'={
  name: '${deployment().name}--appInsights'
  params: {
     appInsightsName: '${appname}-ai'
     location: location
      workspaceResourceId: logAnalyticsWorkspace.outputs.workspaceResourceId
  }
}

// Container Apps Environment 
module environment 'acaEnvironment.bicep' = {
  name: '${deployment().name}--acaenvironment'
  params: {
    acaEnvironmentName: environmentName
    location: location
     instrumentationKey: appInsights.outputs.appInsightsInstrumentationKey
      logAnalyticsWorkspaceCustomerId: logAnalyticsWorkspace.outputs.logAnalyticsWorkspaceCustomerId
       logAnalyticsWorkspacePrimarySharedKey: logAnalyticsWorkspace.outputs.logAnalyticsWorkspacePrimarySharedKey
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
    environmentName: environmentName
    containerAppName: backendApiName
    containerImage: backendApiImage
    targetPort: backendApiPort
    isPrivateRegistry: true 
    minReplicas: 1
    maxReplicas: 2
    containerRegistry: containerRegistry
    containerRegistryUsername: containerRegistryUsername
    registryPassword: registryPassword
    revisionMode: 'Single'
    secretsList: [
      {
        name: registryPassword
        value: containerRegistryPassword
      }
      {
        name: 'cosmosdb-key'
        value: cosmosdb.outputs.primaryMasterKey
      }
      {
        name: 'appinsights-key'
        value: appInsights.outputs.appInsightsInstrumentationKey
      }]
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
        }]
  }
}

  // Frontend WebApp App
module frontendWebAppApp 'containerApp.bicep' = {
  name: '${deployment().name}--${frontendWebAppName}'
  dependsOn: [
    environment
    backendApiApp
    appInsights
  ]
  params: {
    enableIngress: true
    isExternalIngress: true
    location: location
    environmentName: environmentName
    containerAppName: frontendWebAppName
    containerImage: frontendWebAppImage
    targetPort: frontendWebAppPort
    isPrivateRegistry: true 
    minReplicas: 1
    maxReplicas: 2
    containerRegistry: containerRegistry
    containerRegistryUsername: containerRegistryUsername
    registryPassword: registryPassword
    revisionMode: 'Single'
    secretsList: [
      {
        name: registryPassword
        value: containerRegistryPassword
      }
      {
        name: 'appinsights-key'
        value: appInsights.outputs.appInsightsInstrumentationKey
      }]
    envList: [
        {
          name: 'ApplicationInsights__InstrumentationKey'
          secretRef: 'appinsights-key'
        }
        {
          name: 'BackendApiConfig__BaseUrlExternalHttp'
          value: backendApiApp.outputs.fqdn
        }]
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
    environmentName: environmentName
    containerAppName: backendSvcName
    containerImage: backendSvcImage
    targetPort: backendSvcPort
    isPrivateRegistry: true 
    minReplicas: 1
    maxReplicas: 5
    containerRegistry: containerRegistry
    containerRegistryUsername: containerRegistryUsername
    registryPassword: registryPassword
    revisionMode: 'Single'
    useProbes: true
    secretsList: [
      {
        name: registryPassword
        value: containerRegistryPassword
      }
      {
        name: 'sendgrid-apikey'
        value: sendGridApiKey
      }
      {
        name: 'appinsights-key'
        value: appInsights.outputs.appInsightsInstrumentationKey
      }
      {
        name: 'svcbus-connstring'
        value: serviceBus.outputs.connectionString
      }]
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
        }]
  }
}

//Statestore Component
resource statestoreDaprComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-03-01' = {
  name: '${environmentName}/statestore'
  dependsOn: [
    environment
  ]
  properties: {
    componentType: 'state.azure.cosmosdb'
    version: 'v1'
    secrets: [
      {
        name: 'cosmoskey'
        value: cosmosdb.outputs.primaryMasterKey
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
  ]
  properties: {
    componentType: 'state.azure.blobstorage'
    version: 'v1'
    secrets: [
      {
        name: 'storagekey'
        value: storageAccount.outputs.storageAccountKey
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
  ]
  properties: {
    componentType: 'bindings.azure.storagequeues'
    version: 'v1'
    secrets: [
      {
        name: 'storagekey'
        value: storageAccount.outputs.storageAccountKey
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
  ]
  properties: {
    componentType: 'bindings.azure.blobstorage'
    version: 'v1'
    secrets: [
      {
        name: 'storagekey'
        value: storageAccount.outputs.storageAccountKey
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
  ]
  properties: {
    componentType: 'state.azure.tablestorage'
    version: 'v1'
    secrets: [
      {
        name: 'storagekey'
        value: storageAccount.outputs.storageAccountKey
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
  ]
  properties: {
    componentType: 'pubsub.azure.servicebus'
    version: 'v1'
    secrets: [
      {
        name: 'sb-root-connectionstring'
        value: serviceBus.outputs.connectionString
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


