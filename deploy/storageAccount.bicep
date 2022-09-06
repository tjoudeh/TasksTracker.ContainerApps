
param storageAccountName string
param location string = 'eastus'

param externalTasksQueueName string = 'external-tasks-queue'


resource storage_account 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource storage_queues 'Microsoft.Storage/storageAccounts/queueServices@2021-09-01' = {
  name: 'default'
  parent: storage_account
}

resource external_queue 'Microsoft.Storage/storageAccounts/queueServices/queues@2021-09-01' = {
  name: externalTasksQueueName
  parent: storage_queues
}

var storageAccountKeyValue = storage_account.listKeys().keys[0].value
//var storageAcountKeyValue = listKeys(storage_account.id, storage_account.apiVersion).keys[0].value

output storageAccountKey string = storageAccountKeyValue
output storageAccountName string = storageAccountName
