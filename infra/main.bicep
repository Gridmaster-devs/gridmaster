param containerapps_gridmaster_editor_name string = 'gridmaster-editor'
param containerapps_gridmaster_client_name string = 'gridmaster-client'
param containerapps_gridmaster_server_name string = 'gridmaster-server'

param commit_SHA string

@description('The Client ID of your Service Principal')
param spClientId string

@description('The Client Secret of your Service Principal')
@secure()
param spClientSecret string

resource existingEnv 'Microsoft.App/managedEnvironments@2025-10-02-preview' existing = {
  name: 'production'
}

// Managed certificates for the custom domains. They were created once by hand
// (CNAME validation) and live in the environment, not in this template.
resource editorCert 'Microsoft.App/managedEnvironments/managedCertificates@2025-10-02-preview' existing = {
  parent: existingEnv
  name: 'mc-production-gridmaster-gd-cs-3296'
}

resource clientCert 'Microsoft.App/managedEnvironments/managedCertificates@2025-10-02-preview' existing = {
  parent: existingEnv
  name: 'mc-production-gridmaster-clien-4082'
}

resource containerapps_gridmaster_editor_name_resource 'Microsoft.App/containerapps@2025-10-02-preview' = {
  name: containerapps_gridmaster_editor_name
  location: 'North Europe'
  identity: {
    type: 'None'
  }
  properties: {
    environmentId: existingEnv.id
    workloadProfileName: 'Consumption'
    configuration: {
      secrets: [
        {
          name: 'registry-password'
          value: spClientSecret
        }
      ]
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 80
        exposedPort: 0
        transport: 'Auto'
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
        allowInsecure: false
        // Bound here so each deploy keeps the custom domain; a Bicep deploy
        // replaces the whole ingress block, so a portal-only binding gets removed.
        customDomains: [
          {
            name: 'gridmaster-gd.cs.aalto.fi'
            certificateId: editorCert.id
            bindingType: 'SniEnabled'
          }
        ]
      }
      registries: [
        {
          server: 'gridmasterprivate.azurecr.io'
          username: spClientId
          passwordSecretRef: 'registry-password'
        }
      ]
      identitySettings: []
      maxInactiveRevisions: 10
    }
    template: {
      containers: [
        {
          image: 'gridmasterprivate.azurecr.io/gridmaster/editor:${commit_SHA}'
          imageType: 'ContainerImage'
          name: containerapps_gridmaster_editor_name
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        maxReplicas: 1
        cooldownPeriod: 300
        pollingInterval: 30
      }
    }
  }
}

resource containerapps_gridmaster_client_name_resource 'Microsoft.App/containerapps@2025-10-02-preview' = {
  name: containerapps_gridmaster_client_name
  location: 'North Europe'
  identity: {
    type: 'None'
  }
  properties: {
    environmentId: existingEnv.id
    workloadProfileName: 'Consumption'
    configuration: {
      secrets: [
        {
          name: 'registry-password'
          value: spClientSecret
        }
      ]
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 80
        exposedPort: 0
        transport: 'Auto'
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
        allowInsecure: false
        // Bound here so each deploy keeps the custom domain; a Bicep deploy
        // replaces the whole ingress block, so a portal-only binding gets removed.
        customDomains: [
          {
            name: 'gridmaster-client.cs.aalto.fi'
            certificateId: clientCert.id
            bindingType: 'SniEnabled'
          }
        ]
      }
      registries: [
        {
          server: 'gridmasterprivate.azurecr.io'
          username: spClientId
          passwordSecretRef: 'registry-password'
        }
      ]
      identitySettings: []
      maxInactiveRevisions: 10
    }
    template: {
      containers: [
        {
          image: 'gridmasterprivate.azurecr.io/gridmaster/client:${commit_SHA}'
          imageType: 'ContainerImage'
          name: containerapps_gridmaster_client_name
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        maxReplicas: 1
        cooldownPeriod: 300
        pollingInterval: 30
      }
    }
  }
}

resource containerapps_gridmaster_client_server_name_resource 'Microsoft.App/containerapps@2025-10-02-preview' = {
  name: containerapps_gridmaster_server_name
  location: 'North Europe'
  identity: {
    type: 'None'
  }
  properties: {
    environmentId: existingEnv.id
    workloadProfileName: 'Consumption'
    configuration: {
      secrets: [
        {
          name: 'registry-password'
          value: spClientSecret
        }
      ]
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 443
        transport: 'Auto'
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
        allowInsecure: false
        stickySessions: {
          affinity: 'sticky'
        }
      }
      registries: [
        {
          server: 'gridmasterprivate.azurecr.io'
          username: spClientId
          passwordSecretRef: 'registry-password'
        }
      ]
      identitySettings: []
      maxInactiveRevisions: 10
    }
    template: {
      containers: [
        {
          image: 'gridmasterprivate.azurecr.io/gridmaster/server:${commit_SHA}'
          imageType: 'ContainerImage'
          name: containerapps_gridmaster_server_name
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
        cooldownPeriod: 300
        pollingInterval: 30
      }
    }
  }
}
