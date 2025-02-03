###############################################################################
# Configure Terraform and AzureRM Provider
###############################################################################
terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      # IMPORTANT: Must be >= 3.64.0 to support azurerm_openai_account & new logic app
      version = ">= 3.64.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform-storage"
    storage_account_name = "terraformstgaks99"
    container_name       = "tfstatesheilddev"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

###############################################################################
# Resource Groups
###############################################################################
resource "azurerm_resource_group" "rg_networking" {
  name     = "${var.prefix}-rg-networking"
  location = var.location
  tags     = var.tags
}

resource "azurerm_resource_group" "rg_services" {
  name     = "${var.prefix}-rg-services"
  location = var.location
  tags     = var.tags
}

###############################################################################
# Virtual Network and Subnets
###############################################################################
resource "azurerm_virtual_network" "main_vnet" {
  name                = "${var.prefix}-vnet"
  location            = azurerm_resource_group.rg_networking.location
  resource_group_name = azurerm_resource_group.rg_networking.name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

resource "azurerm_subnet" "subnet_services" {
  name                 = "${var.prefix}-subnet-services"
  resource_group_name  = azurerm_resource_group.rg_networking.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = [var.subnet_services_cidr]
}

resource "azurerm_subnet" "subnet_ai" {
  name                 = "${var.prefix}-subnet-ai"
  resource_group_name  = azurerm_resource_group.rg_networking.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = [var.subnet_ai_cidr]
}

###############################################################################
# NSGs for Subnets
###############################################################################
resource "azurerm_network_security_group" "nsg_services" {
  name                = "${var.prefix}-nsg-services"
  location            = azurerm_resource_group.rg_networking.location
  resource_group_name = azurerm_resource_group.rg_networking.name
  tags                = var.tags
}

resource "azurerm_network_security_group" "nsg_ai" {
  name                = "${var.prefix}-nsg-ai"
  location            = azurerm_resource_group.rg_networking.location
  resource_group_name = azurerm_resource_group.rg_networking.name
  tags                = var.tags
}

resource "azurerm_network_security_rule" "rules_nsg_services" {
  for_each = { for rule in var.nsg_rules : rule.name => rule }
  name                        = each.key
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  network_security_group_name = azurerm_network_security_group.nsg_services.name
  resource_group_name         = azurerm_resource_group.rg_networking.name
  description                 = each.value.description
}

resource "azurerm_subnet_network_security_group_association" "services_nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet_services.id
  network_security_group_id = azurerm_network_security_group.nsg_services.id
}

resource "azurerm_network_security_rule" "rules_nsg_ai" {
  for_each = { for rule in var.nsg_rules : rule.name => rule }
  name                        = each.key
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  network_security_group_name = azurerm_network_security_group.nsg_ai.name
  resource_group_name         = azurerm_resource_group.rg_networking.name
  description                 = each.value.description
}

resource "azurerm_subnet_network_security_group_association" "ai_nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet_ai.id
  network_security_group_id = azurerm_network_security_group.nsg_ai.id
}

###############################################################################
# Private DNS Zones
###############################################################################
locals {
  private_dns_zones = [
    "privatelink.blob.core.windows.net",
    "privatelink.table.core.windows.net",
    "privatelink.search.windows.net",
    "privatelink.openai.azure.com",
    "privatelink.vaultcore.azure.net",
    "privatelink.azurewebsites.net"
  ]
}

resource "azurerm_private_dns_zone" "main_zones" {
  for_each            = toset(local.private_dns_zones)
  name                = each.value
  resource_group_name = azurerm_resource_group.rg_networking.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "main_zone_links" {
  for_each                                 = azurerm_private_dns_zone.main_zones
  name                                     = "${each.value.name}-link"
  resource_group_name                      = azurerm_resource_group.rg_networking.name
  private_dns_zone_name                    = each.value.name
  virtual_network_id                       = azurerm_virtual_network.main_vnet.id
  registration_enabled                     = false
}

###############################################################################
# Azure Key Vault (with optional private endpoint)
###############################################################################
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main_kv" {
  name                = "${var.prefix}-kv"
  location            = azurerm_resource_group.rg_services.location
  resource_group_name = azurerm_resource_group.rg_services.name
  sku_name            = "standard"

  # No longer needed: soft_delete_enabled (deprecated/removed)
  # Just keep purge_protection_enabled
  purge_protection_enabled       = true
  public_network_access_enabled  = false

  # Soft delete is always on by default in new KV
  tenant_id = data.azurerm_client_config.current.tenant_id
  tags      = var.tags
}

resource "azurerm_private_endpoint" "kv_pe" {
  name                = "${var.prefix}-pe-kv"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_networking.name
  subnet_id           = azurerm_subnet.subnet_ai.id

  private_service_connection {
    name                           = "kv-priv-connection"
    private_connection_resource_id = azurerm_key_vault.main_kv.id
    subresource_names              = ["vault"]
    # If needed in older provider versions:
    # is_manual_connection         = false
  }

  tags = var.tags
}

resource "azurerm_private_dns_a_record" "kv_private_dns" {
  name                = azurerm_key_vault.main_kv.name
  zone_name           = azurerm_private_dns_zone.main_zones["privatelink.vaultcore.azure.net"].name
  resource_group_name = azurerm_resource_group.rg_networking.name
  records             = [azurerm_private_endpoint.kv_pe.private_service_connection[0].private_ip_address]
  ttl                 = 300
}

###############################################################################
# Azure Storage (with blob, table + private endpoint)
###############################################################################
resource "azurerm_storage_account" "main_sa" {
  name                     = "${var.prefix}sa"
  resource_group_name      = azurerm_resource_group.rg_services.name
  location                 = azurerm_resource_group.rg_services.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Valid in azurerm >= 2.66
  allow_blob_public_access = false

  enable_https_traffic_only = true
  is_hns_enabled            = false
  min_tls_version           = "TLS1_2"
  public_network_access_enabled = false
  tags = var.tags
}

resource "azurerm_private_endpoint" "storage_blob_pe" {
  name                = "${var.prefix}-pe-blob"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_networking.name
  subnet_id           = azurerm_subnet.subnet_ai.id

  private_service_connection {
    name                           = "blob-priv-connection"
    private_connection_resource_id = azurerm_storage_account.main_sa.id
    subresource_names              = ["blob"]
  }

  tags = var.tags
}

resource "azurerm_private_dns_a_record" "storage_blob_a_record" {
  name                = azurerm_storage_account.main_sa.name
  zone_name           = azurerm_private_dns_zone.main_zones["privatelink.blob.core.windows.net"].name
  resource_group_name = azurerm_resource_group.rg_networking.name
  records             = [azurerm_private_endpoint.storage_blob_pe.private_service_connection[0].private_ip_address]
  ttl                 = 300
}

resource "azurerm_private_endpoint" "storage_table_pe" {
  name                = "${var.prefix}-pe-table"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_networking.name
  subnet_id           = azurerm_subnet.subnet_ai.id

  private_service_connection {
    name                           = "table-priv-connection"
    private_connection_resource_id = azurerm_storage_account.main_sa.id
    subresource_names              = ["table"]
  }

  tags = var.tags
}

resource "azurerm_private_dns_a_record" "storage_table_a_record" {
  name                = azurerm_storage_account.main_sa.name
  zone_name           = azurerm_private_dns_zone.main_zones["privatelink.table.core.windows.net"].name
  resource_group_name = azurerm_resource_group.rg_networking.name
  records             = [azurerm_private_endpoint.storage_table_pe.private_service_connection[0].private_ip_address]
  ttl                 = 300
}

###############################################################################
# Azure Cognitive Search (private endpoint)
###############################################################################
resource "azurerm_search_service" "main_search" {
  name                = "${var.prefix}-search"
  resource_group_name = azurerm_resource_group.rg_services.name
  location            = azurerm_resource_group.rg_services.location
  sku                 = "standard"
  replica_count       = 1
  partition_count     = 1

  public_network_access_enabled = false
  tags                          = var.tags
}

resource "azurerm_private_endpoint" "search_pe" {
  name                = "${var.prefix}-pe-search"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_networking.name
  subnet_id           = azurerm_subnet.subnet_ai.id

  private_service_connection {
    name                           = "search-priv-connection"
    private_connection_resource_id = azurerm_search_service.main_search.id
    subresource_names              = ["searchService"]
  }

  tags = var.tags
}

resource "azurerm_private_dns_a_record" "search_a_record" {
  name                = azurerm_search_service.main_search.name
  zone_name           = azurerm_private_dns_zone.main_zones["privatelink.search.windows.net"].name
  resource_group_name = azurerm_resource_group.rg_networking.name
  records             = [azurerm_private_endpoint.search_pe.private_service_connection[0].private_ip_address]
  ttl                 = 300
}

###############################################################################
# Azure OpenAI (private endpoint) - New in provider >= 3.64
###############################################################################
resource "azurerm_openai_account" "main_openai" {
  name                = "${var.prefix}-openai"
  location            = azurerm_resource_group.rg_services.location
  resource_group_name = azurerm_resource_group.rg_services.name

  sku {
    name     = "s0"
    capacity = 1
  }

  public_network_access_enabled = false
  tags                          = var.tags
}

resource "azurerm_private_endpoint" "openai_pe" {
  name                = "${var.prefix}-pe-openai"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_networking.name
  subnet_id           = azurerm_subnet.subnet_ai.id

  private_service_connection {
    name                           = "openai-priv-connection"
    private_connection_resource_id = azurerm_openai_account.main_openai.id
    subresource_names              = ["OpenAi"]
  }

  tags = var.tags
}

resource "azurerm_private_dns_a_record" "openai_a_record" {
  name                = azurerm_openai_account.main_openai.name
  zone_name           = azurerm_private_dns_zone.main_zones["privatelink.openai.azure.com"].name
  resource_group_name = azurerm_resource_group.rg_networking.name
  records             = [azurerm_private_endpoint.openai_pe.private_service_connection[0].private_ip_address]
  ttl                 = 300
}

###############################################################################
# Azure Functions (Premium plan + VNet Integration)
###############################################################################
# Must set os_type="Linux" (capital L)
resource "azurerm_service_plan" "func_plan" {
  name                = "${var.prefix}-func-premium-plan"
  location            = azurerm_resource_group.rg_services.location
  resource_group_name = azurerm_resource_group.rg_services.name
  os_type             = "Linux"
  sku_name            = "EP1" # Premium plan
  tags                = var.tags
}

resource "azurerm_linux_function_app" "main_function" {
  name                       = "${var.prefix}-function"
  resource_group_name        = azurerm_resource_group.rg_services.name
  location                   = azurerm_resource_group.rg_services.location
  service_plan_id            = azurerm_service_plan.func_plan.id
  storage_account_name       = azurerm_storage_account.main_sa.name
  storage_account_access_key = azurerm_storage_account.main_sa.primary_access_key

  identity {
    type = "SystemAssigned"
  }

  https_only                    = true
  public_network_access_enabled = false

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }

  site_config {
    vnet_route_all_enabled = true
    # Additional config if needed
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "function_pe" {
  name                = "${var.prefix}-pe-func"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_networking.name
  subnet_id           = azurerm_subnet.subnet_services.id

  private_service_connection {
    name                           = "function-priv-connection"
    private_connection_resource_id = azurerm_linux_function_app.main_function.id
    subresource_names              = ["sites"]
  }

  tags = var.tags
}

resource "azurerm_private_dns_a_record" "function_a_record" {
  name                = azurerm_linux_function_app.main_function.name
  zone_name           = azurerm_private_dns_zone.main_zones["privatelink.azurewebsites.net"].name
  resource_group_name = azurerm_resource_group.rg_networking.name
  records             = [azurerm_private_endpoint.function_pe.private_service_connection[0].private_ip_address]
  ttl                 = 300
}

###############################################################################
# Logic Apps (Standard) - Updated for Provider >= 3.64
###############################################################################
# 1) Create an App Service Plan that supports "WorkflowStandard" SKU
resource "azurerm_app_service_plan" "logicapp_plan" {
  name                = "${var.prefix}-logicapp-plan"
  location            = azurerm_resource_group.rg_services.location
  resource_group_name = azurerm_resource_group.rg_services.name
  kind                = "functionapp"  # for Linux
  reserved            = true           # needed for Linux
  sku {
    tier = "WorkflowStandard"
    size = "WS1"
  }
  tags = var.tags
}

resource "azurerm_logic_app_standard" "main_logicapp" {
  name                = "${var.prefix}-logicapp"
  location            = azurerm_resource_group.rg_services.location
  resource_group_name = azurerm_resource_group.rg_services.name

  # Must reference an App Service Plan that supports WS SKU
  app_service_plan_id        = azurerm_app_service_plan.logicapp_plan.id
  storage_account_name       = azurerm_storage_account.main_sa.name
  storage_account_access_key = azurerm_storage_account.main_sa.primary_access_key

  sku {
    name     = "WS1"
    capacity = 1
  }

  identity {
    type = "SystemAssigned"
  }

  # If restricting inbound traffic, use ip_restriction
  ip_restriction {
    name           = "Allow-Internal"
    action         = "Allow"
    vnet_subnet_id = azurerm_subnet.subnet_services.id
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "logicapp_pe" {
  name                = "${var.prefix}-pe-logicapp"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_networking.name
  subnet_id           = azurerm_subnet.subnet_services.id

  private_service_connection {
    name                           = "logicapp-priv-connection"
    private_connection_resource_id = azurerm_logic_app_standard.main_logicapp.id
    subresource_names              = ["sites"] 
  }

  tags = var.tags
}

resource "azurerm_private_dns_a_record" "logicapp_a_record" {
  name                = azurerm_logic_app_standard.main_logicapp.name
  zone_name           = azurerm_private_dns_zone.main_zones["privatelink.azurewebsites.net"].name
  resource_group_name = azurerm_resource_group.rg_networking.name
  records             = [azurerm_private_endpoint.logicapp_pe.private_service_connection[0].private_ip_address]
  ttl                 = 300
}

###############################################################################
# Example Azure Policy - Adjusted for Data & Resource Blocks
###############################################################################
# 1) Allowed Locations
data "azurerm_policy_definition" "allowed_locations" {
  # Only specify 'name' or 'display_name'. Using built-in policy by ID:
  name = "c2f7d0aa-6f86-4ac9-90a6-27d3d15163e6"
}

resource "azurerm_policy_assignment" "allowed_locations_assignment" {
  name                 = "${var.prefix}-allowed-locations"
  scope                = azurerm_resource_group.rg_services.id
  policy_definition_id = data.azurerm_policy_definition.allowed_locations.id
  location             = var.location

  parameters = jsonencode({
    listOfAllowedLocations = {
      value = ["northeurope"]
    }
  })
}

# 2) Require Private Endpoints for Storage
data "azurerm_policy_definition" "require_private_endpoints_for_storage" {
  # Built-in policy ID
  name = "c179a8cc-0987-4d6f-a7b4-2d51aa49e8d7"
}

resource "azurerm_policy_assignment" "require_private_endpoints_for_storage_assignment" {
  name                 = "${var.prefix}-require-pe-storage"
  scope                = azurerm_resource_group.rg_services.id
  policy_definition_id = data.azurerm_policy_definition.require_private_endpoints_for_storage.id
  location             = var.location
}

###############################################################################
# Example RBAC Role Assignments for Managed Identities
###############################################################################
resource "azurerm_role_assignment" "function_kv_secrets_user" {
  scope                = azurerm_key_vault.main_kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_function_app.main_function.identity[0].principal_id

  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "logicapp_blob_reader" {
  scope                = azurerm_storage_account.main_sa.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_logic_app_standard.main_logicapp.identity[0].principal_id

  skip_service_principal_aad_check = true
}
