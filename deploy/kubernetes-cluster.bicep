var location = resourceGroup().location
var kubernetesClusterSubnetName = 'virtual-nodes'
var virtualNodesSubnetName = 'virtual-nodes'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: 'promitor-kubernetes-landscape-virtual-network'
  location: location
  tags: {}
  properties: {
    subnets: [
      {
        name: kubernetesClusterSubnetName
        id: '/subscriptions/63c590b6-4947-4898-92a3-cae91a31b5e4/resourceGroups/promitor-kubernetes-landscape/providers/Microsoft.Network/virtualNetworks/promitor-kubernetes-landscape-vnet/subnets/default'
        properties: {
          addressPrefix: '10.240.0.0/16'
        }
      }
      {
        name: virtualNodesSubnetName
        id: '/subscriptions/63c590b6-4947-4898-92a3-cae91a31b5e4/resourceGroups/promitor-kubernetes-landscape/providers/Microsoft.Network/virtualNetworks/promitor-kubernetes-landscape-vnet/subnets/virtual-node-aci'
        properties: {
          addressPrefix: '10.241.0.0/16'
          delegations: [
            {
              name: 'aciDelegation'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
        }
      }
    ]
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/8'
      ]
    }
  }
}

resource kubernetesCluster 'Microsoft.ContainerService/managedClusters@2021-02-01' = {
  name: 'promitor-kubernetes-landscape-kubernetes-cluster'
  location: location
  tags: {}
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: '1.21.2'
    enableRBAC: true
    dnsPrefix: 'promitor'
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: 0
        count: 1
        enableAutoScaling: false
        vmSize: 'Standard_B4ms'
        osType: 'Linux'
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        maxPods: 110
        availabilityZones: []
        vnetSubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, kubernetesClusterSubnetName)
      }
    ]
    networkProfile: {
      loadBalancerSku: 'standard'
      networkPlugin: 'azure'
      serviceCidr: '10.0.0.0/16'
      dnsServiceIP: '10.0.0.10'
      dockerBridgeCidr: '172.17.0.1/16'
    }
    apiServerAccessProfile: {
      enablePrivateCluster: false
    }
    addonProfiles: {
      httpApplicationRouting: {
        enabled: false
      }
      azurepolicy: {
        enabled: false
      }
      aciConnectorLinux: {
        enabled: true
        config: {
          SubnetName: virtualNodesSubnetName
        }
      }
    }
  }
  dependsOn: [
    virtualNetwork
  ]
}

var NetworkContibutorRole = '4d97b98b-1d4f-4787-a291-c67834d212e7'
resource clusterNetworkRole 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: guid(resourceGroup().id, kubernetesCluster.id, kubernetesClusterSubnetName, NetworkContibutorRole)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', NetworkContibutorRole)
    principalId: kubernetesCluster.identity.principalId
    scope: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, kubernetesClusterSubnetName)
  }
  dependsOn: [
    virtualNetwork
    kubernetesCluster
  ]
}

resource aciNetworkRole 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: guid(resourceGroup().id, kubernetesCluster.id, virtualNodesSubnetName, NetworkContibutorRole)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', NetworkContibutorRole)
    principalId: kubernetesCluster.properties.addonProfiles.aciConnectorLinux.identity.objectId
    scope: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, virtualNodesSubnetName)
  }
  dependsOn: [
    virtualNetwork
    kubernetesCluster
  ]
}

output controlPlaneFQDN string = kubernetesCluster.properties.fqdn
