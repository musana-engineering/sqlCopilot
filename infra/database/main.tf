// LOCALS
locals {
  region               = "eastus2"
  tags = {
    provisioner = "terraform"
  }
}

variable "project_id" {}

resource "azurerm_resource_group" "rg" {
  name       = "rg-${substr(var.project_id, 0, 6)}"
  location   = local.region
}

resource "random_password" "mssqlpassword" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_key_vault" "kv" {
  name                        = "kv-${substr(var.project_id, 0, 6)}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  tags = local.tags
}

resource "azurerm_key_vault_secret" "mssqlpassword" {
  name         = "sql-server-admin-password"
  value        = random_password.mssqlpassword.result
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_key_vault.kv]
}

resource "azurerm_mssql_server" "mssql" {
  name                         = "mssql-${substr(var.project_id, 0, 6)}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "mssql${substr(var.project_id, 0, 6)}"
  administrator_login_password = random_password.mssqlpassword.result
  minimum_tls_version          = "1.2"

  tags = local.tags

  depends_on = [azurerm_key_vault.kv]
}

resource "azurerm_mssql_elasticpool" "mssql" {
  name                = "epool-${substr(var.project_id, 0, 6)}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  server_name         = azurerm_mssql_server.mssql.name
  license_type        = "LicenseIncluded"
  max_size_gb         = 4.8828125

  sku {
    name     = "BasicPool"
    tier     = "Basic"
    capacity = 50
  }

  per_database_settings {
    min_capacity = 0
    max_capacity = 5
  }

  depends_on = [azurerm_mssql_server.mssql]
}

resource "azurerm_mssql_database" "db" {
  name            = "AdventureWorks"
  server_id       = azurerm_mssql_server.mssql.id
  elastic_pool_id = azurerm_mssql_elasticpool.mssql.id
  collation       = "SQL_Latin1_General_CP1_CI_AS"
  license_type    = "LicenseIncluded"
  sample_name = "AdventureWorksLT"

  tags = local.tags

  depends_on = [azurerm_mssql_server.mssql, azurerm_mssql_elasticpool.mssql]
}
