terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.36.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "2.5.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-core"
    storage_account_name = "sacoreinfrastate"
    container_name       = "terraform"
    key                  = "/sqlcopilot/openai.tfstate"
  }
}

provider "azurerm" {
  features {}
}

provider "random" {
  # Configuration options
}

provider "azapi" {
}
