variable instance_name { type = string }
variable resource_group { type = string }
variable admin_username { type = string }
variable admin_password { type = string }
variable location { type = string }
variable labels { type = map }

locals {
  resource_group = length(var.resource_group) == 0 ? format("rg-%s", var.instance_name) : var.resource_group
}

resource "azurerm_resource_group" "azure_sql" {
  name     = local.resource_group
  location = var.location
  tags     = var.labels
  count    = length(var.resource_group) == 0 ? 1 : 0
}

resource "random_string" "username" {
  length = 16
  special = false
  number = false
}

resource "random_password" "password" {
  length = 64
  override_special = "~_-."
  min_upper = 2
  min_lower = 2
  min_special = 2
}

locals {
  admin_password = length(var.admin_password) == 0 ? random_password.password.result : var.admin_password
  admin_username = length(var.admin_username) == 0 ? random_string.username.result : var.admin_username
}

resource "azurerm_sql_server" "azure_sql_db_server" {
  depends_on = [ azurerm_resource_group.azure_sql ]
  name                         = var.instance_name
  resource_group_name          = local.resource_group
  location                     = var.location
  version                      = "12.0"
  administrator_login          = local.admin_username
  administrator_login_password = local.admin_password
  tags = var.labels
}

resource "azurerm_sql_firewall_rule" "example" {
  depends_on = [ azurerm_resource_group.azure_sql ]
  name                = "FirewallRule1"
  resource_group_name = local.resource_group
  server_name         = azurerm_sql_server.azure_sql_db_server.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

output "sqldbResourceGroup" {value = azurerm_sql_server.azure_sql_db_server.resource_group_name}
output "sqlServerName" {value = azurerm_sql_server.azure_sql_db_server.name}
output "sqlServerFullyQualifiedDomainName" {value = azurerm_sql_server.azure_sql_db_server.fully_qualified_domain_name}
output "hostname" {value = azurerm_sql_server.azure_sql_db_server.fully_qualified_domain_name}
output "port" {value = 1433}
output "username" {value = local.admin_username}
output "password" {value = local.admin_password}
output "databaseLogin" {value = local.admin_username}
output "databaseLoginPassword" {value = local.admin_password}