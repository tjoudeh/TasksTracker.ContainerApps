param containerAppName string
param location string 
param environmentName string 
param containerImage string
param targetPort int
param isExternalIngress bool
param containerRegistry string
param containerRegistryUsername string
param isPrivateRegistry bool
param enableIngress bool 
param registryPassword string
param minReplicas int = 0
param maxReplicas int = 1
param secretsList array = []
param envList array = []
param revisionMode string = 'Single'
param useProbes bool = false


resource environment 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: environmentName
}

resource containerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: environment.id
    configuration: {
      activeRevisionsMode: revisionMode
      secrets: secretsList
      registries: isPrivateRegistry ? [
        {
          server: containerRegistry
          username: containerRegistryUsername
          passwordSecretRef: registryPassword
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
