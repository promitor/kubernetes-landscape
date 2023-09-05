var location = resourceGroup().location

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: 'promitor-kubernetes-landscape-virtual-network'
  location: location
  tags: {}
  properties: {
    subnets: [
      {
        name: 'default'
        id: '/subscriptions/63c590b6-4947-4898-92a3-cae91a31b5e4/resourceGroups/promitor-kubernetes-landscape/providers/Microsoft.Network/virtualNetworks/promitor-kubernetes-landscape-vnet/subnets/default'
        properties: {
          addressPrefix: '10.240.0.0/16'
        }
      }
      {
        name: 'virtual-node-aci'
        id: '/subscriptions/63c590b6-4947-4898-92a3-cae91a31b5e4/resourceGroups/promitor-kubernetes-landscape/providers/Microsoft.Network/virtualNetworks/promitor-kubernetes-landscape-vnet/subnets/virtual-node-aci'
        properties: {
          addressPrefix: '10.241.0.0/16'
          delegations: [
            {
              name: 'aciDelegation'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
                actions: [
                  'Microsoft.Network/virtualNetworks/subnets/action'
                ]
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

resource kubernetesCluster 'Microsoft.ContainerService/managedClusters@2023-07-01' = {
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
        storageProfile: 'ManagedDisks'
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        maxPods: 110
        availabilityZones: []
        vnetSubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'default')
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
          SubnetName: 'virtual-node-aci'
        }
      }
    }
  }
  dependsOn: [
    virtualNetwork
  ]
}

resource clusterNetworkRole 'Microsoft.Network/virtualNetworks/subnets/providers/roleAssignments@2018-09-01-preview' = {
  name: 'promitor-kubernetes-landscape-vnet/default/Microsoft.Authorization/cf092765-8352-4ee3-9944-7bd1550be619'
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7'
    principalId: kubernetesCluster.identity.principalId
    scope: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'default')
  }
  dependsOn: [
    virtualNetwork
    kubernetesCluster
  ]
}

resource aciNetworkRole 'Microsoft.Network/virtualNetworks/subnets/providers/roleAssignments@2018-09-01-preview' = {
  name: 'promitor-kubernetes-landscape-vnet/virtual-node-aci/Microsoft.Authorization/5835ffa3-9aec-441f-b0a9-967c4d23e6a1'
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7'
    principalId: kubernetesCluster.properties.addonProfiles.aciConnectorLinux.identity.objectId
    scope: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'virtual-node-aci')
  }
  dependsOn: [
    virtualNetwork
    kubernetesCluster
  ]
}

output controlPlaneFQDN string = kubernetesCluster.properties.fqdn
