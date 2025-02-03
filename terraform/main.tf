terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.50"
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


//////////////////////////////
// Resource Groups         //
//////////////////////////////

resource "azurerm_resource_group" "rg_network" {
  name     = var.network_rg_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_resource_group" "rg_services" {
  name     = var.services_rg_name
  location = var.location
  tags     = var.tags
}

//////////////////////////////
// Virtual Network & Subnets
//////////////////////////////
module "vnet" {
  source = "./modules/virtual_network"

  resource_group_name = azurerm_resource_group.rg_network.name
  location            = var.location
  vnet_name           = var.vnet_name
  address_space       = var.vnet_address_space

  subnets = [
    {
      name                                          = var.subnet_services_name
      address_prefixes                              = var.subnet_services_prefix
      private_endpoint_network_policies_enabled     = true
      private_link_service_network_policies_enabled = false
    },
    {
      name                                          = var.subnet_ai_name
      address_prefixes                              = var.subnet_ai_prefix
      # For private endpoints, typically network policies must be disabled
      # but your module might handle it. Adjust as needed.
      private_endpoint_network_policies_enabled     = false
      private_link_service_network_policies_enabled = true
    }
  ]
}

//////////////////////////////
// Network Security Groups  //
//////////////////////////////

resource "azurerm_network_security_group" "nsg_services" {
  name                = var.nsg_services_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_network.name
  tags                = var.tags

  security_rule {
    name                       = "AllowOutboundInternet"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
  # ... Additional rules as needed ...
}

resource "azurerm_subnet_network_security_group_association" "services_nsg_assoc" {
  subnet_id                 = module.vnet.subnet_ids[var.subnet_services_name]
  network_security_group_id = azurerm_network_security_group.nsg_services.id
}

resource "azurerm_network_security_group" "nsg_ai" {
  name                = var.nsg_ai_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_network.name
  tags                = var.tags

  # Typically for private endpoints, you might have more restrictive rules
  # Example: allow Azure resources or certain whitelists only
  security_rule {
    name                       = "AllowAzureServices"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "AzureFrontDoor.Backend"
    destination_port_range     = "*"
    destination_address_prefix = "*"
    source_port_range          = "*"
  }
  # ... Additional rules ...
}

resource "azurerm_subnet_network_security_group_association" "ai_nsg_assoc" {
  subnet_id                 = module.vnet.subnet_ids[var.subnet_ai_name]
  network_security_group_id = azurerm_network_security_group.nsg_ai.id
}


////////////////////////////////
// Private DNS Zones (New ones)
////////////////////////////////
module "dns_zone_blob" {
  source              = "./modules/private_dns_zone"
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.rg_network.name
  virtual_networks_to_link = {
    (module.vnet.name) = {
      subscription_id     = data.azurerm_client_config.current.subscription_id
      resource_group_name = azurerm_resource_group.rg_network.name
    }
  }
  tags = var.tags
}

module "dns_zone_table" {
  source              = "./modules/private_dns_zone"
  name                = "privatelink.table.core.windows.net"
  resource_group_name = azurerm_resource_group.rg_network.name
  virtual_networks_to_link = {
    (module.vnet.name) = {
      subscription_id     = data.azurerm_client_config.current.subscription_id
      resource_group_name = azurerm_resource_group.rg_network.name
    }
  }
  tags = var.tags
}

module "dns_zone_search" {
  source              = "./modules/private_dns_zone"
  name                = "privatelink.search.windows.net"
  resource_group_name = azurerm_resource_group.rg_network.name
  virtual_networks_to_link = {
    (module.vnet.name) = {
      subscription_id     = data.azurerm_client_config.current.subscription_id
      resource_group_name = azurerm_resource_group.rg_network.name
    }
  }
  tags = var.tags
}

module "dns_zone_openai" {
  source              = "./modules/private_dns_zone"
  name                = "privatelink.openai.azure.com"
  resource_group_name = azurerm_resource_group.rg_network.name
  virtual_networks_to_link = {
    (module.vnet.name) = {
      subscription_id     = data.azurerm_client_config.current.subscription_id
      resource_group_name = azurerm_resource_group.rg_network.name
    }
  }
  tags = var.tags
}

module "dns_zone_webapps" {
  source              = "./modules/private_dns_zone"
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.rg_network.name
  virtual_networks_to_link = {
    (module.vnet.name) = {
      subscription_id     = data.azurerm_client_config.current.subscription_id
      resource_group_name = azurerm_resource_group.rg_network.name
    }
  }
  tags = var.tags
}

# Key Vault DNS zone if you want private endpoint for vault
module "dns_zone_kv" {
  source              = "./modules/private_dns_zone"
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.rg_network.name
  virtual_networks_to_link = {
    (module.vnet.name) = {
      subscription_id     = data.azurerm_client_config.current.subscription_id
      resource_group_name = azurerm_resource_group.rg_network.name
    }
  }
  tags = var.tags
}

////////////////////////////////////////////////////////////
// Azure Storage (Blob & Table) with Private Endpoint
////////////////////////////////////////////////////////////
resource "azurerm_storage_account" "this" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg_services.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  kind                     = "StorageV2"
  allow_blob_public_access = false
  # Force private link usage
  public_network_access_enabled = false

  tags = var.tags
}

# Private endpoint for Blob
module "pe_storage_blob" {
  source                         = "./modules/private_endpoint"
  name                           = "pe-${azurerm_storage_account.this.name}-blob"
  location                       = var.location
  resource_group_name            = azurerm_resource_group.rg_network.name
  subnet_id                      = module.vnet.subnet_ids[var.subnet_ai_name]
  tags                           = var.tags
  private_connection_resource_id = azurerm_storage_account.this.id
  subresource_name               = "blob"
  private_dns_zone_group_name    = "blobPrivateDnsZoneGroup"
  private_dns_zone_group_ids     = [module.dns_zone_blob.id]
}

# Private endpoint for Table
module "pe_storage_table" {
  source                         = "./modules/private_endpoint"
  name                           = "pe-${azurerm_storage_account.this.name}-table"
  location                       = var.location
  resource_group_name            = azurerm_resource_group.rg_network.name
  subnet_id                      = module.vnet.subnet_ids[var.subnet_ai_name]
  tags                           = var.tags
  private_connection_resource_id = azurerm_storage_account.this.id
  subresource_name               = "table"
  private_dns_zone_group_name    = "tablePrivateDnsZoneGroup"
  private_dns_zone_group_ids     = [module.dns_zone_table.id]
}

////////////////////////////////////////////////////////////
// Azure Cognitive Search with Private Endpoint
////////////////////////////////////////////////////////////
resource "azurerm_search_service" "this" {
  name                = var.search_name
  resource_group_name = azurerm_resource_group.rg_services.name
  location            = var.location
  sku                 = var.search_sku

  # This ensures no public endpoint
  public_network_access_disabled = true

  tags = var.tags
}

module "pe_search" {
  source                         = "./modules/private_endpoint"
  name                           = "pe-${azurerm_search_service.this.name}"
  location                       = var.location
  resource_group_name            = azurerm_resource_group.rg_network.name
  subnet_id                      = module.vnet.subnet_ids[var.subnet_ai_name]
  tags                           = var.tags
  private_connection_resource_id = azurerm_search_service.this.id
  subresource_name               = "searchService"
  private_dns_zone_group_name    = "searchPrivateDnsZoneGroup"
  private_dns_zone_group_ids     = [module.dns_zone_search.id]
}

////////////////////////////////////////////////////////////
// Azure OpenAI with Private Endpoint
////////////////////////////////////////////////////////////
resource "azurerm_openai_account" "this" {
  name                = var.openai_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_services.name
  sku_name            = var.openai_sku

  public_network_access_enabled = false
  # Possibly: identity { type = "SystemAssigned" } if you want MI

  tags = var.tags
}

module "pe_openai" {
  source                         = "./modules/private_endpoint"
  name                           = "pe-${azurerm_openai_account.this.name}"
  location                       = var.location
  resource_group_name            = azurerm_resource_group.rg_network.name
  subnet_id                      = module.vnet.subnet_ids[var.subnet_ai_name]
  tags                           = var.tags
  private_connection_resource_id = azurerm_openai_account.this.id
  subresource_name               = "account"
  private_dns_zone_group_name    = "openAIDnsZoneGroup"
  private_dns_zone_group_ids     = [module.dns_zone_openai.id]
}

////////////////////////////////////////////////////////////
// Logic Apps (Standard) with VNet Integration
////////////////////////////////////////////////////////////
resource "azurerm_logic_app_standard" "this" {
  name                = var.logic_app_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_services.name

  # System-assigned managed identity
  identity {
    type = "SystemAssigned"
  }

  # For VNet integration with logic app standard
  # The main property is plan; you can specify sku size
  plan {
    name     = "${var.logic_app_name}-plan"
    sku_name = "S1"
  }

  # If using direct VNet injection, use below:
  # (some logic app standard setups require ASE or setting up
  #  the app settings for WEBSITE_VNET_ROUTE_ALL, etc.)
  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "0"
    "WEBSITE_VNET_ROUTE_ALL"   = "1"
  }

  # If you want to connect to the same subnet as your Azure Functions,
  # you can do so using azurerm_subnet and 'virtual_network_subnet_id'
  # in an App Service environment. For simpler scenarios, you can
  # replicate the approach used by function apps (below).
  #
  # For example, if Logic Apps Standard is allowed to integrate with
  # the same approach as Azure Functions:
  # site_config {
  #   vnet_route_all_enabled = true
  # }
  # ...
  
  tags = var.tags
}

# If you want a private endpoint for the Logic App itself (rare),
# you can do so using "privatelink.azurewebsites.net" subresource:
# module "pe_logic_app" { ... }

////////////////////////////////////////////////////////////
// Azure Functions (Premium) with VNet Integration
////////////////////////////////////////////////////////////

# 1. App Service Plan (Premium)
resource "azurerm_service_plan" "function_plan" {
  name                = var.function_app_plan_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_services.name
  os_type             = "Linux"
  sku_name            = var.function_app_sku  # e.g., "EP1"
  tags                = var.tags
}

# 2. Function App
resource "azurerm_linux_function_app" "this" {
  name                       = var.function_app_name
  location                   = var.location
  resource_group_name        = azurerm_resource_group.rg_services.name
  service_plan_id            = azurerm_service_plan.function_plan.id

  # System assigned managed identity for Key Vault, etc.
  identity {
    type = "SystemAssigned"
  }

  # Force incoming traffic to come through private endpoints or integration
  # e.g., site_config { ftps_state = "Disabled" } to restrict ftp
  site_config {
    # VNet route
    vnet_route_all_enabled = true
    # Additional settings as needed
  }

  # Mark public network disabled
  public_network_access_enabled = false

  # VNet Integration (SWIFT or regional) can be done in multiple ways:
  # For Premium plans, you typically create a "azurerm_app_service_virtual_network_swift_connection"
  # or use 'ip_restriction' + private endpoint. 
  # We'll show a Swift Connection example below.

  tags = var.tags
}

# 3. Swift VNet Integration for the Function
resource "azurerm_app_service_virtual_network_swift_connection" "function_vnet_integration" {
  app_service_id = azurerm_linux_function_app.this.id
  subnet_id      = module.vnet.subnet_ids[var.subnet_services_name]
}

# 4. Private Endpoint (Optional) for the Function:
module "pe_function" {
  source                         = "./modules/private_endpoint"
  name                           = "pe-${azurerm_linux_function_app.this.name}"
  location                       = var.location
  resource_group_name            = azurerm_resource_group.rg_network.name
  subnet_id                      = module.vnet.subnet_ids[var.subnet_ai_name]
  tags                           = var.tags
  private_connection_resource_id = azurerm_linux_function_app.this.id
  subresource_name               = "site" 
  private_dns_zone_group_name    = "functionAppDnsZoneGroup"
  private_dns_zone_group_ids     = [module.dns_zone_webapps.id]
}


////////////////////////////////////////////////////////////
// Key Vault (Optional Private Endpoint) – if needed
////////////////////////////////////////////////////////////
# If you want to store secrets for your Functions/Logic App:
# Reuse your Key Vault module or create a new resource. Example:
/*
module "key_vault" {
  source              = "./modules/key_vault"
  name                = "kv-neu-001"
  resource_group_name = azurerm_resource_group.rg_services.name
  location            = var.location
  tenant_id           = var.tenant_id
  sku_name            = "standard"
  public_network_access_enabled = false
  # ...
}

module "pe_keyvault" {
  source                         = "./modules/private_endpoint"
  name                           = "pe-kv-neu-001"
  location                       = var.location
  resource_group_name            = azurerm_resource_group.rg_network.name
  subnet_id                      = module.vnet.subnet_ids[var.subnet_ai_name]
  tags                           = var.tags
  private_connection_resource_id = module.key_vault.id
  subresource_name               = "vault"
  private_dns_zone_group_name    = "KeyVaultPrivateDnsZoneGroup"
  private_dns_zone_group_ids     = [module.dns_zone_kv.id]
}
*/

data "azurerm_client_config" "current" {}

# If you need role assignments for managed identities:
resource "azurerm_role_assignment" "logicapp_kv_access" {
  principal_id         = azurerm_logic_app_standard.this.identity[0].principal_id
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  depends_on           = [azurerm_logic_app_standard.this, module.key_vault]
}

resource "azurerm_role_assignment" "function_kv_access" {
  principal_id         = azurerm_linux_function_app.this.identity[0].principal_id
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  depends_on           = [azurerm_linux_function_app.this, module.key_vault]
}