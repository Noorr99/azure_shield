
###############################################################################
# Configure Terraform and AzureRM Provider
###############################################################################
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.44.0"
    }
  }
  required_version = ">= 1.3.0"
  
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
  tags               = var.tags
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

# Create NSG rules for 'services' subnet
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

# Associate the NSG with the 'services' subnet
resource "azurerm_subnet_network_security_group_association" "services_nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet_services.id
  network_security_group_id = azurerm_network_security_group.nsg_services.id
}

# Create NSG rules for 'ai' subnet
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

# Associate the NSG with the 'ai' subnet
resource "azurerm_subnet_network_security_group_association" "ai_nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet_ai.id
  network_security_group_id = azurerm_network_security_group.nsg_ai.id
}

###############################################################################
# Private DNS Zones
###############################################################################
# List of private DNS zone names you require
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
resource "azurerm_key_vault" "main_kv" {
  name                = "${var.prefix}-kv"
  location            = azurerm_resource_group.rg_services.location
  resource_group_name = azurerm_resource_group.rg_services.name
  sku_name            = "standard"

  # Turn off public access entirely
  public_network_access_enabled = false 

  tenant_id                      = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled       = true
  soft_delete_enabled            = true
  tags                           = var.tags
}

data "azurerm_client_config" "current" {}

# Private endpoint for Key Vault (optional)
resource "azurerm_private_endpoint" "kv_pe" {
  name                = "${var.prefix}-pe-kv"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_networking.name
  subnet_id           = azurerm_subnet.subnet_ai.id

  private_service_connection {
    name                           = "kv-priv-connection"
    private_connection_resource_id = azurerm_key_vault.main_kv.id
    subresource_names              = ["vault"]
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
  # Disable public access
  allow_blob_public_access = false
  # For advanced networking:
  enable_https_traffic_only          = true
  is_hns_enabled                     = false
  min_tls_version                    = "TLS1_2"
  public_network_access_enabled      = false
  tags = var.tags
}

# Private endpoint for blob
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

# Private endpoint for table
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
# Azure Cognitive Search (with private endpoint)
###############################################################################
resource "azurerm_search_service" "main_search" {
  name                = "${var.prefix}-search"
  resource_group_name = azurerm_resource_group.rg_services.name
  location            = azurerm_resource_group.rg_services.location
  sku                 = "standard"  # adjust as needed
  replica_count       = 1
  partition_count     = 1

  # Restrict public access
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
# Azure OpenAI (with private endpoint)
###############################################################################
# For Azure OpenAI, you must have a valid Azure OpenAI resource already 
# approved in your subscription. This sample is conceptual.

resource "azurerm_openai_account" "main_openai" {
  name                = "${var.prefix}-openai"
  location            = azurerm_resource_group.rg_services.location
  resource_group_name = azurerm_resource_group.rg_services.name

  sku {
    name = "s0"
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
resource "azurerm_service_plan" "func_plan" {
  name                = "${var.prefix}-func-premium-plan"
  location            = azurerm_resource_group.rg_services.location
  resource_group_name = azurerm_resource_group.rg_services.name
  os_type             = "linux"
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

  # System-assigned managed identity
  identity {
    type = "SystemAssigned"
  }

  # Restrict public access 
  https_only              = true
  public_network_access_enabled = false

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    # Additional settings
  }

  site_config {
    # Enable VNet Integration for inbound/outbound
    vnet_route_all_enabled = true
    # If you want to assign a subnet specifically for the integration,
    # you'll likely use a separate Subnet or the same 'services' subnet
  }

  tags = var.tags
}

# Private Endpoint for Azure Functions is optional 
# (since it can integrate over VNet). Shown for completeness:
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
# Logic Apps (Standard) - VNet Integration
###############################################################################
resource "azurerm_logic_app_standard" "main_logicapp" {
  name                = "${var.prefix}-logicapp"
  location            = azurerm_resource_group.rg_services.location
  resource_group_name = azurerm_resource_group.rg_services.name
  sku_name            = "Standard"
  sku_plan_name       = "WorkflowStandardFree"
  sku_plan_capacity   = 1

  identity {
    type = "SystemAssigned"
  }

  # Force private access
  inbound_ip_restriction {
    name                                         = "Allow-Internal"
    action                                       = "Allow"
    service_tag                                  = null
    virtual_network_subnet_id                    = azurerm_subnet.subnet_services.id
  }

  tags = var.tags
}

# Private Endpoint for Logic App (Optional)
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
# Example Azure Policy: Enforce location & private endpoint usage
###############################################################################
data "azurerm_policy_definition" "allowed_locations" {
  # This references a built-in policy. You can also create your own custom definition
  display_name = "Allowed locations"
  name         = "c2f7d0aa-6f86-4ac9-90a6-27d3d15163e6" 
}

resource "azurerm_policy_assignment" "allowed_locations_assignment" {
  name                 = "${var.prefix}-allowed-locations"
  scope                = azurerm_resource_group.rg_services.id
  policy_definition_id = data.azurerm_policy_definition.allowed_locations.id
  location            = var.location

  # We only allow "northeurope" in this example
  parameters = jsonencode({
    listOfAllowedLocations = {
      value = ["northeurope"]
    }
  })
}

# Example built-in policy to require private endpoints for Storage
data "azurerm_policy_definition" "require_private_endpoints_for_storage" {
  display_name = "Storage accounts should use private link"
  name         = "c179a8cc-0987-4d6f-a7b4-2d51aa49e8d7" 
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
# For example: give the Function's identity access to read secrets in Key Vault
resource "azurerm_role_assignment" "function_kv_secrets_user" {
  scope                            = azurerm_key_vault.main_kv.id
  role_definition_name             = "Key Vault Secrets User"
  principal_id                     = azurerm_linux_function_app.main_function.identity[0].principal_id
  skip_service_principal_aad_check = true
}

# For example: give the Logic App identity read blob data from Storage
resource "azurerm_role_assignment" "logicapp_blob_reader" {
  scope                            = azurerm_storage_account.main_sa.id
  role_definition_name             = "Storage Blob Data Reader"
  principal_id                     = azurerm_logic_app_standard.main_logicapp.identity[0].principal_id
  skip_service_principal_aad_check = true
}
