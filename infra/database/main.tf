locals {
  region = "eastus2"
  sqlserver_username = "mssql${substr(var.project_id, 0, 6)}"
  tags = {
    provisioner = "terraform"
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${substr(var.project_id, 0, 6)}"
  location = local.region
}

resource "azurerm_user_assigned_identity" "mi" {
  location            = azurerm_resource_group.rg.location
  name                = "mi-${substr(var.project_id, 0, 6)}"
  resource_group_name = azurerm_resource_group.rg.name
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
  enable_rbac_authorization = true 
  enabled_for_deployment = true 
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  network_acls {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    ip_rules                   = ["8.29.228.126", "20.81.155.16"]
    virtual_network_subnet_ids = [data.azurerm_subnet.subnet.id]
  }

  tags = local.tags
}

resource "azurerm_key_vault_secret" "mssqlpassword" {
  name         = "sqlserver-admin-password"
  value        = random_password.mssqlpassword.result
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_key_vault.kv]
}

resource "azurerm_key_vault_secret" "mssqlusername" {
  name         = "sqlserver-admin-username"
  value        = local.sqlserver_username
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_key_vault.kv]
}

resource "azurerm_mssql_server" "mssql" {
  name                         = "mssql-${substr(var.project_id, 0, 6)}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = local.sqlserver_username
  administrator_login_password = random_password.mssqlpassword.result
  minimum_tls_version          = "1.2"

  tags = local.tags

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.mi.id]
  }

  depends_on = [azurerm_key_vault.kv]
}

resource "azurerm_mssql_virtual_network_rule" "subnet" {
  name      = data.azurerm_subnet.subnet.name
  server_id = azurerm_mssql_server.mssql.id
  subnet_id = data.azurerm_subnet.subnet.id

  depends_on = [ azurerm_mssql_elasticpool.mssql ]
}

resource "azurerm_mssql_firewall_rule" "bastion" {
  name             = "BastionHost"
  server_id        = azurerm_mssql_server.mssql.id
  start_ip_address = "20.81.155.16"
  end_ip_address   = "20.81.155.16"
}

resource "azurerm_mssql_firewall_rule" "cloudflare" {
  name             = "CloudflareVPN"
  server_id        = azurerm_mssql_server.mssql.id
  start_ip_address = "8.29.228.126"
  end_ip_address   = "8.29.228.126"

depends_on = [ azurerm_mssql_database.db ]
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

resource "azurerm_key_vault_secret" "mssql-connstring" {
  name         = "sqlserver-connection-string"
  value        = "Server=tcp:${azurerm_mssql_server.mssql.fully_qualified_domain_name},1433;Initial Catalog=AdventureWorks;Persist Security Info=False;User ID=${local.sqlserver_username};Password=${random_password.mssqlpassword.result};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_key_vault.kv, azurerm_mssql_server.mssql]
}


resource "azurerm_mssql_database" "db" {
  name            = "AdventureWorks"
  server_id       = azurerm_mssql_server.mssql.id
  elastic_pool_id = azurerm_mssql_elasticpool.mssql.id
  collation       = "SQL_Latin1_General_CP1_CI_AS"
  license_type    = "LicenseIncluded"
  sample_name     = "AdventureWorksLT"

  tags = local.tags

  depends_on = [azurerm_mssql_server.mssql, azurerm_mssql_elasticpool.mssql]
}
