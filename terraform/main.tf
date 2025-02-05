provider "azurerm" {
  features {}
}

provider "azapi" {}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.45"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~>1.3"
    }
  }
}

# Base Infrastructure
resource "azurerm_resource_group" "shield_noor" {
  name     = "shield-noor-resources"
  location = "East US"
}

resource "azurerm_virtual_network" "shield_noor" {
  name                = "shield-noor-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.shield_noor.location
  resource_group_name = azurerm_resource_group.shield_noor.name
}

resource "azurerm_subnet" "ai_services" {
  name                 = "shield-noor-ai-services"
  resource_group_name  = azurerm_resource_group.shield_noor.name
  virtual_network_name = azurerm_virtual_network.shield_noor.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "other_services" {
  name                 = "shield-noor-other-services"
  resource_group_name  = azurerm_resource_group.shield_noor.name
  virtual_network_name = azurerm_virtual_network.shield_noor.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Private DNS Zones
resource "azurerm_private_dns_zone" "openai" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = azurerm_resource_group.shield_noor.name
}

resource "azurerm_private_dns_zone" "search" {
  name                = "privatelink.search.windows.net"
  resource_group_name = azurerm_resource_group.shield_noor.name
}

resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.shield_noor.name
}

resource "azurerm_private_dns_zone" "table" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = azurerm_resource_group.shield_noor.name
}

resource "azurerm_private_dns_zone" "functions" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.shield_noor.name
}

# VNet Links
resource "azurerm_private_dns_zone_virtual_network_link" "openai" {
  name                  = "openai-link"
  resource_group_name   = azurerm_resource_group.shield_noor.name
  private_dns_zone_name = azurerm_private_dns_zone.openai.name
  virtual_network_id    = azurerm_virtual_network.shield_noor.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "search" {
  name                  = "search-link"
  resource_group_name   = azurerm_resource_group.shield_noor.name
  private_dns_zone_name = azurerm_private_dns_zone.search.name
  virtual_network_id    = azurerm_virtual_network.shield_noor.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "blob-link"
  resource_group_name   = azurerm_resource_group.shield_noor.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.shield_noor.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "table" {
  name                  = "table-link"
  resource_group_name   = azurerm_resource_group.shield_noor.name
  private_dns_zone_name = azurerm_private_dns_zone.table.name
  virtual_network_id    = azurerm_virtual_network.shield_noor.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "functions" {
  name                  = "functions-link"
  resource_group_name   = azurerm_resource_group.shield_noor.name
  private_dns_zone_name = azurerm_private_dns_zone.functions.name
  virtual_network_id    = azurerm_virtual_network.shield_noor.id
}

# Azure OpenAI
resource "azapi_resource" "shield_noor_openai" {
  type      = "Microsoft.CognitiveServices/accounts@2023-05-01"
  name      = "shield-noor-openai"
  location  = azurerm_resource_group.shield_noor.location
  parent_id = azurerm_resource_group.shield_noor.id

  body = jsonencode({
    sku = {
      name = "S0"
    }
    kind = "OpenAI"
    properties = {
      networkAcls = {
        defaultAction = "Deny"
        virtualNetworkRules = [
          {
            id = azurerm_subnet.ai_services.id
          }
        ]
      }
    }
  })
}

# Azure Cognitive Search
resource "azurerm_search_service" "shield_noor" {
  name                = "shield-noor-search"
  resource_group_name = azurerm_resource_group.shield_noor.name
  location            = azurerm_resource_group.shield_noor.location
  sku                 = "basic"
  partition_count     = 1
  replica_count       = 1
  public_network_access_enabled = false
}

# Azure Storage Account
resource "azurerm_storage_account" "shield_noor" {
  name                     = "shieldnoorstorageacc"
  resource_group_name      = azurerm_resource_group.shield_noor.name
  location                 = azurerm_resource_group.shield_noor.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  public_network_access_enabled = false
}

# Azure Service Plan
resource "azurerm_service_plan" "shield_noor" {
  name                = "shield-noor-service-plan"
  location            = azurerm_resource_group.shield_noor.location
  resource_group_name = azurerm_resource_group.shield_noor.name
  os_type            = "Linux"
  sku_name           = "Y1"
}

# Azure Function App
resource "azurerm_linux_function_app" "shield_noor" {
  name                       = "shield-noor-function"
  resource_group_name        = azurerm_resource_group.shield_noor.name
  location                   = azurerm_resource_group.shield_noor.location
  service_plan_id            = azurerm_service_plan.shield_noor.id
  storage_account_name       = azurerm_storage_account.shield_noor.name
  storage_account_access_key = azurerm_storage_account.shield_noor.primary_access_key
  https_only                = true

  site_config {
    application_stack {
      node_version = "16"
    }
    
    ip_restriction {
      name       = "AllowOtherServices"
      ip_address = "10.0.2.0/24"
      action     = "Allow"
      priority   = 100
    }

    ip_restriction {
      name       = "DenyAll"
      ip_address = "0.0.0.0/0"
      action     = "Deny"
      priority   = 200
    }
  }
}

# Private Endpoints
resource "azurerm_private_endpoint" "openai" {
  name                = "shield-noor-openai-endpoint"
  location            = azurerm_resource_group.shield_noor.location
  resource_group_name = azurerm_resource_group.shield_noor.name
  subnet_id           = azurerm_subnet.ai_services.id

  private_dns_zone_group {
    name                 = "openai-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.openai.id]
  }

  private_service_connection {
    name                           = "openai-connection"
    private_connection_resource_id = azapi_resource.shield_noor_openai.id
    is_manual_connection           = false
    subresource_names             = ["account"]
  }
}

resource "azurerm_private_endpoint" "search" {
  name                = "shield-noor-search-endpoint"
  location            = azurerm_resource_group.shield_noor.location
  resource_group_name = azurerm_resource_group.shield_noor.name
  subnet_id           = azurerm_subnet.ai_services.id

  private_dns_zone_group {
    name                 = "search-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.search.id]
  }

  private_service_connection {
    name                           = "search-connection"
    private_connection_resource_id = azurerm_search_service.shield_noor.id
    is_manual_connection           = false
    subresource_names             = ["searchService"]
  }
}

resource "azurerm_private_endpoint" "storage_blob" {
  name                = "shield-noor-blob-endpoint"
  location            = azurerm_resource_group.shield_noor.location
  resource_group_name = azurerm_resource_group.shield_noor.name
  subnet_id           = azurerm_subnet.other_services.id

  private_dns_zone_group {
    name                 = "blob-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }

  private_service_connection {
    name                           = "blob-connection"
    private_connection_resource_id = azurerm_storage_account.shield_noor.id
    is_manual_connection           = false
    subresource_names             = ["blob"]
  }
}

resource "azurerm_private_endpoint" "storage_table" {
  name                = "shield-noor-table-endpoint"
  location            = azurerm_resource_group.shield_noor.location
  resource_group_name = azurerm_resource_group.shield_noor.name
  subnet_id           = azurerm_subnet.other_services.id

  private_dns_zone_group {
    name                 = "table-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.table.id]
  }

  private_service_connection {
    name                           = "table-connection"
    private_connection_resource_id = azurerm_storage_account.shield_noor.id
    is_manual_connection           = false
    subresource_names             = ["table"]
  }
}

resource "azurerm_private_endpoint" "function" {
  name                = "shield-noor-function-endpoint"
  location            = azurerm_resource_group.shield_noor.location
  resource_group_name = azurerm_resource_group.shield_noor.name
  subnet_id           = azurerm_subnet.other_services.id

  private_dns_zone_group {
    name                 = "function-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.functions.id]
  }

  private_service_connection {
    name                           = "function-connection"
    private_connection_resource_id = azurerm_linux_function_app.shield_noor.id
    is_manual_connection           = false
    subresource_names             = ["sites"]
  }
}