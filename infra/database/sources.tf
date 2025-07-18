variable "project_id" {}
data "azurerm_client_config" "current" {}

data "azurerm_subnet" "subnet" {
  name                 = "snet-dev-compute"
  virtual_network_name = "vnet-dev"
  resource_group_name  = "rg-network"
}
