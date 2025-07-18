locals {
  region = "eastus2"
  tags = {
    provisioner = "terraform"
  }
}

variable "project_id" {}

resource "azurerm_resource_group" "rg" {
  name     = "oai-${substr(var.project_id, 0, 6)}"
  location = local.region
}

resource "azurerm_cognitive_account" "openai" {
  name                = "oai-${substr(var.project_id, 0, 6)}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "OpenAI"

  sku_name = "S0"

  tags = local.tags
}

resource "azurerm_cognitive_account_rai_policy" "openai" {
  name                 = "oai-${substr(var.project_id, 0, 6)}"
  cognitive_account_id = azurerm_cognitive_account.openai.id
  base_policy_name     = "Microsoft.Default"
  content_filter {
    name               = "Hate"
    filter_enabled     = true
    block_enabled      = true
    severity_threshold = "High"
    source             = "Prompt"
  }
}


resource "azurerm_cognitive_deployment" "openai" {
  name                   = "oai-${substr(var.project_id, 0, 6)}"
  cognitive_account_id   = azurerm_cognitive_account.openai.id
  version_upgrade_option = "OnceNewDefaultVersionAvailable"

  model {
    format  = "OpenAI"
    name    = "gpt-4"
  }

  sku {
    name     = "GlobalStandard"
#    tier     = "Standard"
    capacity = 1
  }
}
