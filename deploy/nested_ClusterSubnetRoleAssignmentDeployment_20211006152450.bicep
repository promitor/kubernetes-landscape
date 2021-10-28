param reference_parameters_resourceName_2021_02_01_Full_identity_principalId object

resource promitor_kubernetes_landscape_vnet_default_Microsoft_Authorization_cf092765_8352_4ee3_9944_7bd1550be619 'Microsoft.Network/virtualNetworks/subnets/providers/roleAssignments@2018-09-01-preview' = {
  name: 'promitor-kubernetes-landscape-vnet/default/Microsoft.Authorization/cf092765-8352-4ee3-9944-7bd1550be619'
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7'
    principalId: reference_parameters_resourceName_2021_02_01_Full_identity_principalId.identity.principalId
    scope: '/subscriptions/63c590b6-4947-4898-92a3-cae91a31b5e4/resourceGroups/promitor-kubernetes-landscape/providers/Microsoft.Network/virtualNetworks/promitor-kubernetes-landscape-vnet/subnets/default'
  }
}