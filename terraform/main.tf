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
//    subscription_id      = "00000000-0000-0000-0000-000000000000"
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

###############################
# Single Resource Group
###############################

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

###############################
# Virtual Network & Subnets
###############################

module "vnet" {
  source              = "./modules/virtual_network"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  vnet_name           = var.vnet_name
  address_space       = var.vnet_address_space
  tags                = var.tags

  # Two subnets:
  # 1. Services (for Functions and Logic Apps)
  # 2. AI & private endpoints (for Storage, Cognitive Search, OpenAI, etc.)
  subnets = [
    {
      name                                          = var.services_subnet_name
      address_prefixes                              = var.services_subnet_address_prefixes
      private_endpoint_network_policies_enabled     = true
      private_link_service_network_policies_enabled = false
    },
    {
      name                                          = var.ai_subnet_name
      address_prefixes                              = var.ai_subnet_address_prefixes
      private_endpoint_network_policies_enabled     = false
      private_link_service_network_policies_enabled = true
    }
  ]
}

###############################
# NSG Associations
###############################

module "nsg_services" {
  source              = "./modules/network_security_group"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  nsg_name            = var.nsg_services_name
  security_rules      = var.nsg_services_rules
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "services" {
  subnet_id                 = module.vnet.subnet_ids[var.services_subnet_name]
  network_security_group_id = module.nsg_services.id
}

module "nsg_ai" {
  source              = "./modules/network_security_group"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  nsg_name            = var.nsg_ai_name
  security_rules      = var.nsg_ai_rules
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "ai" {
  subnet_id                 = module.vnet.subnet_ids[var.ai_subnet_name]
  network_security_group_id = module.nsg_ai.id
}

###############################
# Private DNS Zones (Existing Modules)
###############################

module "dns_blob" {
  source              = "./modules/private_dns_zone"
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.main.name
  virtual_networks_to_link = {
    (module.vnet.vnet_name) = {
      virtual_network_id = module.vnet.vnet_id
    }
  }
  tags = var.tags
}

module "dns_table" {
  source              = "./modules/private_dns_zone"
  name                = "privatelink.table.core.windows.net"
  resource_group_name = azurerm_resource_group.main.name
  virtual_networks_to_link = {
    (module.vnet.vnet_name) = {
      virtual_network_id = module.vnet.vnet_id
    }
  }
  tags = var.tags
}

module "dns_search" {
  source              = "./modules/private_dns_zone"
  name                = "privatelink.search.windows.net"
  resource_group_name = azurerm_resource_group.main.name
  virtual_networks_to_link = {
    (module.vnet.vnet_name) = {
      virtual_network_id = module.vnet.vnet_id
    }
  }
  tags = var.tags
}

module "dns_openai" {
  source              = "./modules/private_dns_zone"
  name                = "privatelink.openai.azure.com"
  resource_group_name = azurerm_resource_group.main.name
  virtual_networks_to_link = {
    (module.vnet.vnet_name) = {
      virtual_network_id = module.vnet.vnet_id
    }
  }
  tags = var.tags
}

module "dns_vault" {
  source              = "./modules/private_dns_zone"
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.main.name
  virtual_networks_to_link = {
    (module.vnet.vnet_name) = {
      virtual_network_id = module.vnet.vnet_id
    }
  }
  tags = var.tags
}

module "dns_azurewebsites" {
  source              = "./modules/private_dns_zone"
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.main.name
  virtual_networks_to_link = {
    (module.vnet.vnet_name) = {
      virtual_network_id = module.vnet.vnet_id
    }
  }
  tags = var.tags
}

###############################
# New Services
###############################

# Azure Functions (Premium, VNet integrated with Managed Identity)
module "functions" {
  source              = "./modules/azure_functions"
  functions_name      = var.functions_name
  sku                 = var.functions_sku
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  subnet_id           = module.vnet.subnet_ids[var.services_subnet_name]
  tags                = var.tags
}


# Storage Account (existing module)
module "storage" {
  source                 = "./modules/storage_account"
  resource_group_name    = azurerm_resource_group.main.name
  location               = var.location
  storage_account_name   = var.storage_account_name
  account_tier           = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  tags                   = var.tags
}

# Private Endpoint for Storage Blob
module "storage_private_endpoint_blob" {
  source                         = "./modules/private_endpoint"
  name                           = "pe-${module.storage.storage_account_name}-blob"
  location                       = var.location
  resource_group_name            = azurerm_resource_group.main.name
  subnet_id                      = module.vnet.subnet_ids[var.ai_subnet_name]
  tags                           = var.tags
  private_connection_resource_id = module.storage.id
  is_manual_connection           = false
  subresource_name               = "blob"
  private_dns_zone_group_name    = "StorageBlobPrivateDnsZoneGroup"
  private_dns_zone_group_ids     = [module.dns_blob.id]
}

# Private Endpoint for Storage Table
module "storage_private_endpoint_table" {
  source                         = "./modules/private_endpoint"
  name                           = "pe-${module.storage.storage_account_name}-table"
  location                       = var.location
  resource_group_name            = azurerm_resource_group.main.name
  subnet_id                      = module.vnet.subnet_ids[var.ai_subnet_name]
  tags                           = var.tags
  private_connection_resource_id = module.storage.id
  is_manual_connection           = false
  subresource_name               = "table"
  private_dns_zone_group_name    = "StorageTablePrivateDnsZoneGroup"
  private_dns_zone_group_ids     = [module.dns_table.id]
}

# Logic Apps Standard (VNet integrated with Managed Identity)
module "logic_apps" {
  source                         = "./modules/logic_apps"
  logic_apps_name                = var.logic_apps_name
  sku                            = var.logic_apps_sku
  resource_group_name            = azurerm_resource_group.main.name
  location                       = var.location
  subnet_id                      = module.vnet.subnet_ids[var.services_subnet_name]
  storage_account_name           = var.logic_apps_storage_account_name
  storage_account_access_key     = module.storage.primary_access_key
  tags                           = var.tags
}

# Azure Cognitive Search (with private endpoint)
module "search" {
  source              = "./modules/azure_search"
  search_service_name = var.search_service_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  sku                 = var.search_sku
  tags                = var.tags
}

module "search_private_endpoint" {
  source                         = "./modules/private_endpoint"
  name                           = "pe-${module.search.search_service_name}"
  location                       = var.location
  resource_group_name            = azurerm_resource_group.main.name
  subnet_id                      = module.vnet.subnet_ids[var.ai_subnet_name]
  tags                           = var.tags
  private_connection_resource_id = module.search.id
  is_manual_connection           = false
  subresource_name               = "searchService"
  private_dns_zone_group_name    = "SearchPrivateDnsZoneGroup"
  private_dns_zone_group_ids     = [module.dns_search.id]
}

# Azure OpenAI (with private endpoint)
module "openai" {
  source              = "./modules/azure_openai"
  openai_name         = var.openai_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tags                = var.tags
}

module "openai_private_endpoint" {
  source                         = "./modules/private_endpoint"
  name                           = "pe-${module.openai.openai_name}"
  location                       = var.location
  resource_group_name            = azurerm_resource_group.main.name
  subnet_id                      = module.vnet.subnet_ids[var.ai_subnet_name]
  tags                           = var.tags
  private_connection_resource_id = module.openai.id
  is_manual_connection           = false
  subresource_name               = "openAI"
  private_dns_zone_group_name    = "OpenAIPrivateDnsZoneGroup"
  private_dns_zone_group_ids     = [module.dns_openai.id]
}

/*
# (Optional) Key Vault with Private Endpoint
module "key_vault" {
  source              = "./modules/key_vault"
  name                = var.key_vault_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tenant_id           = var.tenant_id
  sku_name            = var.key_vault_sku
  tags                = var.tags

  enabled_for_deployment          = var.key_vault_enabled_for_deployment
  enabled_for_disk_encryption     = var.key_vault_enabled_for_disk_encryption
  enabled_for_template_deployment = var.key_vault_enabled_for_template_deployment
  enable_rbac_authorization       = var.key_vault_enable_rbac_authorization
  purge_protection_enabled        = var.key_vault_purge_protection_enabled
  soft_delete_retention_days      = var.key_vault_soft_delete_retention_days
  public_network_access_enabled   = false

  bypass         = var.key_vault_bypass
  default_action = var.key_vault_default_action
  ip_rules       = var.key_vault_ip_rules
  virtual_network_subnet_ids = []
}

module "key_vault_private_endpoint" {
  source                         = "./modules/private_endpoint"
  name                           = "pe-${module.key_vault.name}"
  location                       = var.location
  resource_group_name            = azurerm_resource_group.main.name
  subnet_id                      = module.vnet.subnet_ids[var.ai_subnet_name]
  tags                           = var.tags
  private_connection_resource_id = module.key_vault.id
  is_manual_connection           = false
  subresource_name               = "vault"
  private_dns_zone_group_name    = "KeyVaultPrivateDnsZoneGroup"
  private_dns_zone_group_ids     = [module.dns_vault.id]
}

*/