param reference_parameters_resourceName_addonProfiles_aciConnectorLinux_identity_objectId object

resource promitor_kubernetes_landscape_vnet_virtual_node_aci_Microsoft_Authorization_5835ffa3_9aec_441f_b0a9_967c4d23e6a1 'Microsoft.Network/virtualNetworks/subnets/providers/roleAssignments@2018-09-01-preview' = {
  name: 'promitor-kubernetes-landscape-vnet/virtual-node-aci/Microsoft.Authorization/5835ffa3-9aec-441f-b0a9-967c4d23e6a1'
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7'
    principalId: reference_parameters_resourceName_addonProfiles_aciConnectorLinux_identity_objectId.addonProfiles.aciConnectorLinux.identity.objectId
    scope: '/subscriptions/63c590b6-4947-4898-92a3-cae91a31b5e4/resourceGroups/promitor-kubernetes-landscape/providers/Microsoft.Network/virtualNetworks/promitor-kubernetes-landscape-vnet/subnets/virtual-node-aci'
  }
}