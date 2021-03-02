@description('Name of the cluster e.g. prd-kub')
param clusterName string

@description('Version number of Kubernetes e.g. 1.8.7')
param kubernetesVersion string

@description('Environment for the cluster e.g. production')
param environment string

@description('DNS prefix for the cluster e.g. prd')
param dnsPrefix string

@description('Name of server pool for the cluster e.g. prdpool')
param poolName string

@description('Number of nodes')
param nodeCount int

@description('VNet name')
param vnet string

@description('Managed AAD Group oject Id')
param groupId string

resource vnet_resource 'Microsoft.Network/virtualNetworks@2018-08-01' = {
  name: vnet
  location: resourceGroup().location
  tags: {
    displayName: vnet
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'aks'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
    ]
  }
}

resource clusterName_resource 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: clusterName
  location: resourceGroup().location
  properties: {
    sku: {
      name: 'Standalone'
    }
  }
}

resource clusterName_ContainerInsights_clusterName 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: '${clusterName}/ContainerInsights(${clusterName})'
  location: resourceGroup().location
  plan: {
    name: 'ContainerInsights(${clusterName})'
    product: 'OMSGallery/ContainerInsights'
    publisher: 'Microsoft'
    promotionCode: ''
  }
  properties: {
    workspaceResourceId: clusterName_resource.id
  }
}

resource Microsoft_ContainerService_managedClusters_clusterName 'Microsoft.ContainerService/managedClusters@2020-12-01' = {
  name: clusterName
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  tags: {
    environment: environment
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: dnsPrefix
    agentPoolProfiles: [
      {
        name: poolName
        mode: 'System'
        count: nodeCount
        vmSize: 'Standard_DS3_v2'
        type: 'VirtualMachineScaleSets'
        scaleSetEvictionPolicy: 'Delete'
        minCount: nodeCount
        maxCount: 5
        enableAutoScaling: true
        osDiskType: 'Ephemeral'
        vnetSubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet, 'aks')
      }
    ]
    linuxProfile: {
      adminUsername: 'cluadmin'
      ssh: {
        publicKeys: [
          {
            keyData: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC3VjzfskyBxohOmvkI+lmAVB1cdMiXzKH3Gb541NUVeezwRgekIhYv+JyKn+/04xPi7ByX8rSZna3ouM/1u6ydbtIYR5hMoKSkAF58V/y1QBzStRwvba93Ugpuu2FXEpI1tY5ZMCS9Tu9ZD7h4Yb1POX1dEFUhLLbOX9dDFk/YCFdN/Vd+e27w6ii6xbOPS0g7tb0zGsvmLuC0qLzsNnKedtvF7UHLnMDNZqQEmCrYbp123/2RoRSHPISbYZBkXv5WmQg5lGsnHenbrNwubdCelymQeTKwJxqVdRhZt08SOTkDVnUJ8c5H99Qp7fe+FxW+2aSWnXZd3sPlXvcQ85qR'
          }
        ]
      }
    }
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: clusterName_resource.id
        }
      }
    }
    enableRBAC: true
    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'standard'
      serviceCidr: '10.1.0.0/16'
      dnsServiceIP: '10.1.0.10'
    }
    aadProfile: {
      managed: true
      adminGroupObjectIDs: [
        groupId
      ]
    }
  }
}