param storageAccountName string
param location string = resourceGroup().location

var externalTasksQueueName = 'external-tasks-queue'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource storageQueues 'Microsoft.Storage/storageAccounts/queueServices@2021-09-01' = {
  name: 'default'
  parent: storageAccount
}

resource external_queue 'Microsoft.Storage/storageAccounts/queueServices/queues@2021-09-01' = {
  name: externalTasksQueueName
  parent: storageQueues
}

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2021-09-01' = {
  name: 'default'
  parent: storageAccount
}

resource permanentFileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-05-01' = {
  name: 'permanent-file-share'
  parent: fileServices
  properties: {
    accessTier: 'TransactionOptimized'
    enabledProtocols: 'SMB'
    shareQuota: 1024
  }
}

//var storageAccountKeyValue = storageAccount.listKeys().keys[0].value
//output storageAccountKey string = storageAccountKeyValue
