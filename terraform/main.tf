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
# Network Security Groups (NSGs) – Using Your Existing Module
###############################

module "nsg_services" {
  source                        = "./modules/network_security_group"
  name                          = var.nsg_services_name
  resource_group_name           = azurerm_resource_group.main.name
  location                      = var.location
  security_rules                = var.nsg_services_rules
  log_analytics_workspace_id    = var.log_analytics_workspace_id
  tags                          = var.tags
}

resource "azurerm_subnet_network_security_group_association" "services" {
  subnet_id                 = module.vnet.subnet_ids[var.services_subnet_name]
  network_security_group_id = module.nsg_services.id
}

module "nsg_ai" {
  source                        = "./modules/network_security_group"
  name                          = var.nsg_ai_name
  resource_group_name           = azurerm_resource_group.main.name
  location                      = var.location
  security_rules                = var.nsg_ai_rules
  log_analytics_workspace_id    = var.log_analytics_workspace_id
  tags                          = var.tags
}

resource "azurerm_subnet_network_security_group_association" "ai" {
  subnet_id                 = module.vnet.subnet_ids[var.ai_subnet_name]
  network_security_group_id = module.nsg_ai.id
}

###############################
# Private DNS Zones (Reusing Existing Module)
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

###############################
# Services (Azure Functions, Logic Apps, Storage, AI)
###############################

# Azure Functions (Premium, VNet integrated)
module "functions" {
  source              = "./modules/azure_functions"
  functions_name      = var.functions_name
  sku                 = var.functions_sku
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  subnet_id           = module.vnet.subnet_ids[var.services_subnet_name]
  tags                = var.tags
}

# Logic Apps Standard (VNet integrated)
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

# Storage Account
module "storage" {
  source                   = "./modules/storage_account"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = var.location
  name                     = var.storage_account_name
  account_kind             = var.storage_account_kind    // if you have this variable (default "StorageV2")
  account_tier             = var.storage_account_tier
  replication_type         = var.storage_account_replication_type
  is_hns_enabled           = var.is_hns_enabled          // ensure this variable is defined
  default_action           = var.default_action          // ensure this variable is defined
  ip_rules                 = var.ip_rules                // ensure this variable is defined
  virtual_network_subnet_ids = var.virtual_network_subnet_ids  // ensure this variable is defined
  tags                     = var.tags
}


# Azure Cognitive Search
module "search" {
  source              = "./modules/azure_search"
  search_service_name = var.search_service_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  sku                 = var.search_sku
  tags                = var.tags
}

# Azure OpenAI
module "openai" {
  source              = "./modules/azure_openai"
  openai_name         = var.openai_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tags                = var.tags
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