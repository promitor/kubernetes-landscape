@description('The name of the Managed Cluster resource.')
param resourceName string

@description('The location of AKS resource.')
param location string

@description('Optional DNS prefix to use with hosted Kubernetes API server FQDN.')
param dnsPrefix string

@description('Disk size (in GiB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 will apply the default disk size for that agentVMSize.')
@minValue(0)
@maxValue(1023)
param osDiskSizeGB int = 0

@description('The version of Kubernetes.')
param kubernetesVersion string = '1.7.7'

@description('Network plugin used for building Kubernetes network.')
@allowed([
  'azure'
  'kubenet'
])
param networkPlugin string

@description('Boolean flag to turn on and off of RBAC.')
param enableRBAC bool = true

@description('Boolean flag to turn on and off of virtual machine scale sets')
param vmssNodePool bool = false

@description('Boolean flag to turn on and off of virtual machine scale sets')
param windowsProfile bool = false

@description('Enable private network access to the Kubernetes cluster.')
param enablePrivateCluster bool = false

@description('Boolean flag to turn on and off http application routing.')
param enableHttpApplicationRouting bool = true

@description('Boolean flag to turn on and off Azure Policy addon.')
param enableAzurePolicy bool = false

@description('Resource ID of virtual network subnet used for nodes and/or pods IP assignment.')
param vnetSubnetID string

@description('A CIDR notation IP range from which to assign service cluster IPs.')
param serviceCidr string

@description('Containers DNS server IP address.')
param dnsServiceIP string

@description('A CIDR notation IP for Docker bridge.')
param dockerBridgeCidr string

@description('Name of virtual network subnet used for the ACI Connector.')
param aciVnetSubnetName string

@description('Enables the Linux ACI Connector.')
param aciConnectorLinuxEnabled bool

resource resourceName_resource 'Microsoft.ContainerService/managedClusters@2021-02-01' = {
  name: resourceName
  location: location
  tags: {}
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    enableRBAC: enableRBAC
    dnsPrefix: dnsPrefix
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: osDiskSizeGB
        count: 1
        enableAutoScaling: false
        vmSize: 'Standard_B4ms'
        osType: 'Linux'
        storageProfile: 'ManagedDisks'
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        maxPods: 110
        availabilityZones: []
        vnetSubnetID: vnetSubnetID
      }
    ]
    networkProfile: {
      loadBalancerSku: 'standard'
      networkPlugin: networkPlugin
      serviceCidr: serviceCidr
      dnsServiceIP: dnsServiceIP
      dockerBridgeCidr: dockerBridgeCidr
    }
    apiServerAccessProfile: {
      enablePrivateCluster: enablePrivateCluster
    }
    addonProfiles: {
      httpApplicationRouting: {
        enabled: enableHttpApplicationRouting
      }
      azurepolicy: {
        enabled: enableAzurePolicy
      }
      aciConnectorLinux: {
        enabled: aciConnectorLinuxEnabled
        config: {
          SubnetName: aciVnetSubnetName
        }
      }
    }
  }
  dependsOn: [
    promitor_kubernetes_landscape_vnet
  ]
}

resource promitor_kubernetes_landscape_vnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: 'promitor-kubernetes-landscape-vnet'
  location: 'westeurope'
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

module ClusterSubnetRoleAssignmentDeployment_20211006152450 './nested_ClusterSubnetRoleAssignmentDeployment_20211006152450.bicep' = {
  name: 'ClusterSubnetRoleAssignmentDeployment-20211006152450'
  scope: resourceGroup('63c590b6-4947-4898-92a3-cae91a31b5e4', 'promitor-kubernetes-landscape')
  params: {
    reference_parameters_resourceName_2021_02_01_Full_identity_principalId: reference(resourceName, '2021-02-01', 'Full')
  }
  dependsOn: [
    promitor_kubernetes_landscape_vnet
  ]
}

module AciSubnetRoleAssignmentDeployment_20211006152450 './nested_AciSubnetRoleAssignmentDeployment_20211006152450.bicep' = {
  name: 'AciSubnetRoleAssignmentDeployment-20211006152450'
  scope: resourceGroup('63c590b6-4947-4898-92a3-cae91a31b5e4', 'promitor-kubernetes-landscape')
  params: {
    reference_parameters_resourceName_addonProfiles_aciConnectorLinux_identity_objectId: resourceName_resource.properties
  }
  dependsOn: [
    promitor_kubernetes_landscape_vnet
  ]
}

output controlPlaneFQDN string = resourceName_resource.properties.fqdn