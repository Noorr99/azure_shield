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


#############################
# Resource Group
#############################
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}


#############################
# Virtual Network & Subnets #
#############################
module "vnet" {
  source              = "./modules/virtual_network"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  vnet_name           = var.vnet_name
  address_space       = var.vnet_address_space

  subnets = [
    {
      name                                          = var.services_subnet_name
      address_prefixes                              = var.services_subnet_prefix
      private_endpoint_network_policies_enabled     = true
      private_link_service_network_policies_enabled = false
    },
    {
      name                                          = var.pe_subnet_name
      address_prefixes                              = var.pe_subnet_prefix
      private_endpoint_network_policies_enabled     = false
      private_link_service_network_policies_enabled = true
    }
  ]
}

#############################
# NSG Modules and Associations
#############################
module "services_nsg" {
  source                     = "./modules/network_security_group"
  name                       = var.services_nsg_name
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = var.location
  security_rules             = var.services_nsg_rules
  tags                       = var.tags
  log_analytics_workspace_id = var.log_analytics_workspace_id
}

module "pe_nsg" {
  source                     = "./modules/network_security_group"
  name                       = var.pe_nsg_name
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = var.location
  security_rules             = var.pe_nsg_rules
  tags                       = var.tags
  log_analytics_workspace_id = var.log_analytics_workspace_id
}

resource "azurerm_subnet_network_security_group_association" "services_assoc" {
  subnet_id                 = module.vnet.subnet_ids[var.services_subnet_name]
  network_security_group_id = module.services_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "pe_assoc" {
  subnet_id                 = module.vnet.subnet_ids[var.pe_subnet_name]
  network_security_group_id = module.pe_nsg.id
}

#############################
# Storage Account & Endpoints
#############################
module "storage_account" {
  source                     = "./modules/storage_account"
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = var.storage_account_name
  location                   = var.location
  account_kind               = var.storage_account_kind
  account_tier               = var.storage_account_tier
  replication_type           = var.storage_replication_type
  is_hns_enabled             = var.storage_is_hns_enabled
  tags                       = var.tags
  default_action             = "Deny"
  ip_rules                   = var.storage_ip_rules
  virtual_network_subnet_ids = [ module.vnet.subnet_ids[var.pe_subnet_name] ]
}

module "storage_blob_private_dns_zone" {
  source                   = "./modules/private_dns_zone"
  name                     = "privatelink.blob.core.windows.net"
  resource_group_name      = azurerm_resource_group.rg.name
  virtual_networks_to_link = {
    (var.vnet_name) = {
      subscription_id     = data.azurerm_client_config.current.subscription_id
      resource_group_name = azurerm_resource_group.rg.name
    }
  }
  tags = var.tags
}

module "storage_table_private_dns_zone" {
  source                   = "./modules/private_dns_zone"
  name                     = "privatelink.table.core.windows.net"
  resource_group_name      = azurerm_resource_group.rg.name
  virtual_networks_to_link = {
    (var.vnet_name) = {
      subscription_id     = data.azurerm_client_config.current.subscription_id
      resource_group_name = azurerm_resource_group.rg.name
    }
  }
  tags = var.tags
}

module "storage_blob_private_endpoint" {
  source                         = "./modules/private_endpoint"
  name                           = "pe-${module.storage_account.name}-blob"
  location                       = var.location
  resource_group_name            = azurerm_resource_group.rg.name
  subnet_id                      = module.vnet.subnet_ids[var.pe_subnet_name]
  tags                           = var.tags
  private_connection_resource_id = module.storage_account.id
  is_manual_connection           = false
  subresource_name               = "blob"
  private_dns_zone_group_name    = "StorageBlobPrivateDnsZoneGroup"
  private_dns_zone_group_ids     = [ module.storage_blob_private_dns_zone.id ]
  depends_on                     = [ module.storage_account ]
}

module "storage_table_private_endpoint" {
  source                         = "./modules/private_endpoint"
  name                           = "pe-${module.storage_account.name}-table"
  location                       = var.location
  resource_group_name            = azurerm_resource_group.rg.name
  subnet_id                      = module.vnet.subnet_ids[var.pe_subnet_name]
  tags                           = var.tags
  private_connection_resource_id = module.storage_account.id
  is_manual_connection           = false
  subresource_name               = "table"
  private_dns_zone_group_name    = "StorageTablePrivateDnsZoneGroup"
  private_dns_zone_group_ids     = [ module.storage_table_private_dns_zone.id ]
  depends_on                     = [ module.storage_account ]
}

#############################
# Azure OpenAI & Endpoints
#############################
module "openai" {
  source                     = "./modules/openai"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = "eastus"  # Use a region where OpenAI is supported.
  name                       = var.openai_name
  sku_name                   = var.openai_sku
  tags                       = var.tags
  custom_subdomain_name      = var.openai_custom_subdomain_name
  public_network_access_enabled = false
  deployments                   = var.openai_deployments
  log_analytics_workspace_id    = var.log_analytics_workspace_id
}

module "openai_private_dns_zone" {
  source                   = "./modules/private_dns_zone"
  name                     = "privatelink.openai.azure.com"
  resource_group_name      = azurerm_resource_group.rg.name
  virtual_networks_to_link = {
    (var.vnet_name) = {
      subscription_id     = data.azurerm_client_config.current.subscription_id
      resource_group_name = azurerm_resource_group.rg.name
    }
  }
  tags = var.tags
}

module "openai_private_endpoint" {
  source                         = "./modules/private_endpoint"
  name                           = "pe-${module.openai.name}"
  location                       = var.location
  resource_group_name            = azurerm_resource_group.rg.name
  subnet_id                      = module.vnet.subnet_ids[var.pe_subnet_name]
  tags                           = var.tags
  private_connection_resource_id = module.openai.id
  is_manual_connection           = false
  subresource_name               = "openai"
  private_dns_zone_group_name    = "OpenAiPrivateDnsZoneGroup"
  private_dns_zone_group_ids     = [ module.openai_private_dns_zone.id ]
}

#############################
# (Manually Deployed) Services
#############################
# Logic Apps, Azure Functions, and Azure Cognitive Search will be deployed manually.
# They should use the "services" subnet: module.vnet.subnet_ids[var.services_subnet_name].
