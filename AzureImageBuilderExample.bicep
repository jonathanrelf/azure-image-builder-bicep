param identityName string = 'aibBuilderUser-${utcNow('yyyyMMddTHHmmss')}'

var location = 'UK South'
var imageName = 'vmiFirstImage'
var runOutputName = 'aibWindows'
var roleDefinitionId = guid(resourceGroup().id)
var roleAssignmentId = guid(resourceGroup().id)

resource userIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: identityName
  location: location
}

resource imageBuilderRole 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: roleDefinitionId
  properties: {
    roleName: identityName
    description: ''
    assignableScopes: [
      resourceGroup().id
    ]
    permissions: [
      {
        actions: [
          'Microsoft.Compute/galleries/read'
          'Microsoft.Compute/galleries/images/read'
          'Microsoft.Compute/galleries/images/versions/read'
          'Microsoft.Compute/galleries/images/versions/write'
          'Microsoft.Compute/images/write'
          'Microsoft.Compute/images/read'
          'Microsoft.Compute/images/delete'
        ]
      }
    ]
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: roleAssignmentId
  scope: resourceGroup()
  properties: {
    roleDefinitionId: imageBuilderRole.id
    principalId: userIdentity.properties.principalId
  }
}

resource ExampleImageBuild 'Microsoft.VirtualMachineImages/imageTemplates@2020-02-14' = {
  name: 'ExampleImageBuild'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userIdentity.id}' : {}
    }
  }
  tags: {
    imageBuilderTemplate: 'windows2019'
    userIdentity: 'enabled'
  }
  properties: {
    buildTimeoutInMinutes: 100
    vmProfile: {
      vmSize: 'Standard_D2_v2'
      osDiskSizeGB: 127
    }
    source: {
      type: 'PlatformImage'
      publisher: 'MicrosoftWindowsServer'
      offer: 'WindowsServer'
      sku: '2019-Datacenter'
      version: 'latest'
    }
    customize: [
      {
        type: 'WindowsUpdate'
        searchCriteria: 'IsInstalled=0'
        filters: [
          'exclude:$_.Title -like \'*Preview*\''
          'include:$true'
        ]
        updateLimit: 20
      }
    ]
    distribute: [
      {
        type: 'ManagedImage'
        imageId: '${resourceGroup().id}/providers/Microsoft.Compute/images/${imageName}'
        location: location
        runOutputName: runOutputName
        artifactTags: {
          source: 'azVmImageBuilder'
          baseosimg: 'windows2019'
        }
      }
    ]
  }
}
