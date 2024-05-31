# The name of the Azure Resource Group that the virtual network belongs to
# You can find the name of your Azure Resource Group in the [Azure Portal on the Overview tab of your Azure Virtual Network](https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.Network%2FvirtualNetworks).
resource_group = "sitta-stinkbug-rg"

# The name of your VNet that you want to connect to Confluent Cloud Cluster
# You can find the name of your Azure VNet in the [Azure Portal on the Overview tab of your Azure Virtual Network](https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.Network%2FvirtualNetworks).
vnet_name = "sitta-vnet"

# The region of your Azure VNet
region = "eastus"

# A map of Zone to Subnet Name
# On Azure, zones are Confluent-chosen names (for example, `1`, `2`, `3`) since Azure does not have universal zone identifiers.
subnet_name_by_zone = {
  "1" = "sitta-subnet",
#  "2" = "default",
#  "3" = "default",
}

# Limitations of Azure Private Link
# https://docs.confluent.io/cloud/current/networking/private-links/azure-privatelink.html#limitations