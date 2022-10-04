param containerAppName string
param location string = resourceGroup().location
param environmentId string 
param containerImage string
param targetPort int
param isExternalIngress bool
param containerRegistry string
param containerRegistryUsername string
param isPrivateRegistry bool
param enableIngress bool 
param registryPassName string
param minReplicas int = 0
param maxReplicas int = 1
@secure()
param secListObj object
param envList array = []
param revisionMode string = 'Single'
param useProbes bool = false
param storageNameMount string

resource containerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: environmentId
    configuration: {
      activeRevisionsMode: revisionMode
      secrets: secListObj.secArray
      registries: isPrivateRegistry ? [
        {
          server: containerRegistry
          username: containerRegistryUsername
          passwordSecretRef: registryPassName
        }
      ] : null
      ingress: enableIngress ? {
        external: isExternalIngress
        targetPort: targetPort
        transport: 'auto'
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      } : null
      dapr: {
        enabled: true
        appPort: targetPort
        appId: containerAppName
        appProtocol: 'http'
      }
    }
    template: {
      containers: [
        {
          image: containerImage
          name: containerAppName
          env: envList
          probes: useProbes? [
            {
              type: 'Readiness'
               httpGet: {
                 port: 80
                 path: '/api/health/readiness'
                  scheme: 'HTTP'
               }
              periodSeconds: 240
               timeoutSeconds: 5
               initialDelaySeconds: 5
                successThreshold: 1
                failureThreshold: 3
            }
          ] : null
          volumeMounts: [
            { 
               mountPath:'/app/attachments'
               volumeName:'azure-file-volume'
            }
          ]
        }
      ]
      volumes: [
        {
           name: 'azure-file-volume'
           storageName: storageNameMount
           storageType: 'AzureFile'
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }
  }
}

output fqdn string = enableIngress ? containerApp.properties.configuration.ingress.fqdn : 'Ingress not enabled'
