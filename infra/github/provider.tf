terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.6.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-core"
    storage_account_name = "sacoreinfrastate"
    container_name       = "terraform"
    key                  = "/sqlcopilot/github.tfstate"
  }
}

provider "github" {
  token = var.github_token
  owner = var.github_username
}

variable "github_token" {}
variable "github_username" {}