terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-storage"
    storage_account_name = "terraformstgaks99"
    container_name       = "tfstatesheilddev"
    key                  = "terraform.tfstate"
  }
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

######################
# Resource Groups
######################

resource "azurerm_resource_group" "networking" {
  name     = "rg-networking"
  location = "northeurope"
}

resource "azurerm_resource_group" "services" {
  name     = "rg-services"
  location = "northeurope"
}

######################
# Virtual Network & Subnets
######################

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-prod"
  location            = azurerm_resource_group.networking.location
  resource_group_name = azurerm_resource_group.networking.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet_services" {
  name                 = "subnet-services"
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "subnet_ai" {
  name                 = "subnet-ai"
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

######################
# Network Security Groups & Associations
######################

resource "azurerm_network_security_group" "nsg_subnet_services" {
  name                = "nsg-subnet-services"
  location            = azurerm_resource_group.networking.location
  resource_group_name = azurerm_resource_group.networking.name
}

resource "azurerm_network_security_group" "nsg_subnet_ai" {
  name                = "nsg-subnet-ai"
  location            = azurerm_resource_group.networking.location
  resource_group_name = azurerm_resource_group.networking.name
}

resource "azurerm_subnet_network_security_group_association" "assoc_services" {
  subnet_id                 = azurerm_subnet.subnet_services.id
  network_security_group_id = azurerm_network_security_group.nsg_subnet_services.id
}

resource "azurerm_subnet_network_security_group_association" "assoc_ai" {
  subnet_id                 = azurerm_subnet.subnet_ai.id
  network_security_group_id = azurerm_network_security_group.nsg_subnet_ai.id
}

######################
# Private DNS Zones & VNet Links
######################

# Blob DNS Zone
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.networking.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob_vnet_link" {
  name                  = "vnet-link-blob"
  resource_group_name   = azurerm_resource_group.networking.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = true
}

# Table DNS Zone
resource "azurerm_private_dns_zone" "table" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = azurerm_resource_group.networking.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "table_vnet_link" {
  name                  = "vnet-link-table"
  resource_group_name   = azurerm_resource_group.networking.name
  private_dns_zone_name = azurerm_private_dns_zone.table.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = true
}

# Search DNS Zone
resource "azurerm_private_dns_zone" "search" {
  name                = "privatelink.search.windows.net"
  resource_group_name = azurerm_resource_group.networking.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "search_vnet_link" {
  name                  = "vnet-link-search"
  resource_group_name   = azurerm_resource_group.networking.name
  private_dns_zone_name = azurerm_private_dns_zone.search.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = true
}

# OpenAI DNS Zone
resource "azurerm_private_dns_zone" "openai" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = azurerm_resource_group.networking.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "openai_vnet_link" {
  name                  = "vnet-link-openai"
  resource_group_name   = azurerm_resource_group.networking.name
  private_dns_zone_name = azurerm_private_dns_zone.openai.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = true
}

# Key Vault DNS Zone
resource "azurerm_private_dns_zone" "vault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.networking.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vault_vnet_link" {
  name                  = "vnet-link-vault"
  resource_group_name   = azurerm_resource_group.networking.name
  private_dns_zone_name = azurerm_private_dns_zone.vault.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = true
}

# Azure Websites DNS Zone
resource "azurerm_private_dns_zone" "azurewebsites" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.networking.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "azurewebsites_vnet_link" {
  name                  = "vnet-link-azurewebsites"
  resource_group_name   = azurerm_resource_group.networking.name
  private_dns_zone_name = azurerm_private_dns_zone.azurewebsites.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = true
}

######################
# Services in rg-services
######################

######################################
# Azure OpenAI Service with Private Endpoint
######################################

resource "azurerm_openai_service" "openai" {
  name                = "openaiexample"  # update to a globally unique name as needed
  resource_group_name = azurerm_resource_group.services.name
  location            = azurerm_resource_group.services.location

  sku_name = "S0"
}

resource "azurerm_private_endpoint" "pe_openai" {
  name                = "pe-openai"
  location            = azurerm_resource_group.services.location
  resource_group_name = azurerm_resource_group.services.name
  subnet_id           = azurerm_subnet.subnet_ai.id

  private_service_connection {
    name                           = "openai-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_openai_service.openai.id
    subresource_names              = ["openai"]  # confirm the correct subresource name per provider documentation
  }
}

resource "azurerm_private_dns_zone_group" "openai_dns" {
  name                = "openai-dns"
  private_endpoint_id = azurerm_private_endpoint.pe_openai.id

  private_dns_zone_ids = [
    azurerm_private_dns_zone.openai.id
  ]
}

######################################
# Azure Cognitive Search Service with Private Endpoint
######################################

resource "azurerm_search_service" "search" {
  name                = "searchexample"  # update to a unique name
  resource_group_name = azurerm_resource_group.services.name
  location            = azurerm_resource_group.services.location
  sku                 = "standard"
  replica_count       = 1
  partition_count     = 1
}

resource "azurerm_private_endpoint" "pe_search" {
  name                = "pe-search"
  location            = azurerm_resource_group.services.location
  resource_group_name = azurerm_resource_group.services.name
  subnet_id           = azurerm_subnet.subnet_ai.id

  private_service_connection {
    name                           = "search-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_search_service.search.id
    subresource_names              = ["searchService"]  # confirm correct subresource name
  }
}

resource "azurerm_private_dns_zone_group" "search_dns" {
  name                = "search-dns"
  private_endpoint_id = azurerm_private_endpoint.pe_search.id

  private_dns_zone_ids = [
    azurerm_private_dns_zone.search.id
  ]
}

######################################
# Azure Storage Account (Blobs & Tables) with Private Endpoints
######################################

resource "azurerm_storage_account" "storage" {
  name                     = "storagestgexample"  # update to a unique name
  resource_group_name      = azurerm_resource_group.services.name
  location                 = azurerm_resource_group.services.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_blob_public_access = false

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.subnet_ai.id]
  }
}

# Private Endpoint for Blob
resource "azurerm_private_endpoint" "pe_storage_blob" {
  name                = "pe-storage-blob"
  location            = azurerm_resource_group.services.location
  resource_group_name = azurerm_resource_group.services.name
  subnet_id           = azurerm_subnet.subnet_ai.id

  private_service_connection {
    name                           = "storage-blob-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.storage.id
    subresource_names              = ["blob"]
  }
}

resource "azurerm_private_dns_zone_group" "storage_blob_dns" {
  name                = "storage-blob-dns"
  private_endpoint_id = azurerm_private_endpoint.pe_storage_blob.id

  private_dns_zone_ids = [
    azurerm_private_dns_zone.blob.id
  ]
}

# Private Endpoint for Table
resource "azurerm_private_endpoint" "pe_storage_table" {
  name                = "pe-storage-table"
  location            = azurerm_resource_group.services.location
  resource_group_name = azurerm_resource_group.services.name
  subnet_id           = azurerm_subnet.subnet_ai.id

  private_service_connection {
    name                           = "storage-table-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.storage.id
    subresource_names              = ["table"]
  }
}

resource "azurerm_private_dns_zone_group" "storage_table_dns" {
  name                = "storage-table-dns"
  private_endpoint_id = azurerm_private_endpoint.pe_storage_table.id

  private_dns_zone_ids = [
    azurerm_private_dns_zone.table.id
  ]
}

######################################
# Logic Apps Standard with VNet Integration
######################################

resource "azurerm_logic_app_standard" "logicapps" {
  name                = "logicapps-example"
  resource_group_name = azurerm_resource_group.services.name
  location            = azurerm_resource_group.services.location
  sku_name            = "Standard"

  identity {
    type = "SystemAssigned"
  }

  # NOTE: VNet integration for Logic Apps Standard is typically achieved via integration service environment (ISE)
  # or through specific network configuration within your workflows. Adjust as needed.
}

######################################
# Azure Functions (Premium Plan) with VNet Integration
######################################

resource "azurerm_app_service_plan" "function_plan" {
  name                = "function-plan"
  location            = azurerm_resource_group.services.location
  resource_group_name = azurerm_resource_group.services.name
  kind                = "FunctionApp"
  reserved            = false

  sku {
    tier = "PremiumV2"
    size = "P1v2"
  }
}

resource "azurerm_function_app" "functions" {
  name                       = "functionappexample"  # update to a unique name
  location                   = azurerm_resource_group.services.location
  resource_group_name        = azurerm_resource_group.services.name
  app_service_plan_id        = azurerm_app_service_plan.function_plan.id
  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key

  identity {
    type = "SystemAssigned"
  }

  site_config {
    vnet_route_all_enabled    = true
    virtual_network_subnet_id = azurerm_subnet.subnet_services.id
  }
}

######################################
# Key Vault with Private Endpoint
######################################

resource "azurerm_key_vault" "kv" {
  name                     = "keyvaultexample"  # update to a unique name
  location                 = azurerm_resource_group.services.location
  resource_group_name      = azurerm_resource_group.services.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  sku_name                 = "standard"
  soft_delete_enabled      = true
  purge_protection_enabled = false

  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = [azurerm_subnet.subnet_ai.id]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "get",
      "list",
    ]
  }
}

resource "azurerm_private_endpoint" "pe_kv" {
  name                = "pe-keyvault"
  location            = azurerm_resource_group.services.location
  resource_group_name = azurerm_resource_group.services.name
  subnet_id           = azurerm_subnet.subnet_ai.id

  private_service_connection {
    name                           = "keyvault-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_key_vault.kv.id
    subresource_names              = ["vault"]
  }
}

resource "azurerm_private_dns_zone_group" "kv_dns" {
  name                = "kv-dns"
  private_endpoint_id = azurerm_private_endpoint.pe_kv.id

  private_dns_zone_ids = [
    azurerm_private_dns_zone.vault.id
  ]
}

######################
# Example: Azure Policy Assignment (Allowed Locations)
######################

resource "azurerm_policy_assignment" "allowed_locations" {
  name                 = "allowed-locations"
  scope                = azurerm_resource_group.networking.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/allowed-locations"
  parameters = <<PARAMS
{
  "listOfAllowedLocations": {
    "value": ["northeurope"]
  }
}
PARAMS
}
