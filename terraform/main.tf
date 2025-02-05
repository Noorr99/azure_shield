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

# Azure OpenAI – Only allow traffic from the ai_services subnet.
resource "azapi_resource" "shield_noor_openai" {
  type      = "Microsoft.CognitiveServices/accounts@2021-04-30"
  name      = "shield-noor-openai"
  location  = azurerm_resource_group.shield_noor.location
  parent_id = azurerm_resource_group.shield_noor.id

  body = jsonencode({
    sku = {
      name = "S0"
    }
    kind       = "OpenAI"
    properties = {
      networkAcls = {
        defaultAction         = "Deny"
        virtualNetworkRules = [
          {
            id = azurerm_subnet.ai_services.id
          }
        ]
      }
    }
  })
}

# Azure Cognitive Search – disable public network access.
resource "azurerm_search_service" "shield_noor" {
  name                = "shield-noor-search"
  resource_group_name = azurerm_resource_group.shield_noor.name
  location            = azurerm_resource_group.shield_noor.location
  sku                 = "basic"
  partition_count     = 1
  replica_count       = 1

  public_network_access_enabled = false
}

# Azure Logic Apps
resource "azurerm_logic_app_workflow" "shield_noor" {
  name                = "shield-noor-logicapp"
  resource_group_name = azurerm_resource_group.shield_noor.name
  location            = azurerm_resource_group.shield_noor.location
}

resource "azurerm_service_plan" "shield_noor" {
  name                = "shield-noor-service-plan"
  location            = azurerm_resource_group.shield_noor.location
  resource_group_name = azurerm_resource_group.shield_noor.name
  os_type             = "Linux"
  sku_name            = "Y1"  # Consumption plan SKU
}

# Azure Storage Account – enforce HTTPS, disable public network access, and restrict to the other_services subnet.
resource "azurerm_storage_account" "shield_noor" {
  name                          = "shieldnoorstorageacc"
  resource_group_name           = azurerm_resource_group.shield_noor.name
  location                      = azurerm_resource_group.shield_noor.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  https_traffic_only_enabled    = true
  public_network_access_enabled = false

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.other_services.id]
  }
}

# Azure Linux Function App – enforce HTTPS and restrict access via IP rules.
resource "azurerm_linux_function_app" "shield_noor" {
  name                       = "shield-noor-function"
  resource_group_name        = azurerm_resource_group.shield_noor.name
  location                   = azurerm_resource_group.shield_noor.location
  service_plan_id            = azurerm_service_plan.shield_noor.id
  storage_account_name       = azurerm_storage_account.shield_noor.name
  storage_account_access_key = azurerm_storage_account.shield_noor.primary_access_key
  https_only                 = true

  site_config {
    application_stack {
      node_version = "16"
    }

    # Allow inbound requests only from the other_services subnet.
    ip_restriction {
      name       = "AllowOtherServices"
      ip_address = "10.0.2.0/24"
      action     = "Allow"
      priority   = 100
    }

    # Deny all other inbound traffic.
    ip_restriction {
      name       = "DenyAll"
      ip_address = "0.0.0.0/0"
      action     = "Deny"
      priority   = 200
    }
  }
}
