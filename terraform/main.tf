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

# Azure OpenAI
resource "azapi_resource" "shield_noor_openai" {
  type      = "Microsoft.CognitiveServices/accounts@2021-04-30"
  name      = "shield-noor-openai"
  location  = azurerm_resource_group.shield_noor.location
  parent_id = azurerm_resource_group.shield_noor.id

  body = jsonencode({
    sku = {
      name = "S0"
    }
    kind     = "OpenAI"
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
}

# Azure Logic Apps
resource "azurerm_logic_app_workflow" "shield_noor" {
  name                = "shield-noor-logicapp"
  resource_group_name = azurerm_resource_group.shield_noor.name
  location            = azurerm_resource_group.shield_noor.location
}

# Azure Functions
resource "azurerm_linux_function_app" "shield_noor" {
  name                = "shield-noor-function"
  resource_group_name = azurerm_resource_group.shield_noor.name
  location            = azurerm_resource_group.shield_noor.location
  service_plan_id     = azurerm_service_plan.shield_noor.id
  storage_account_name = azurerm_storage_account.shield_noor.name
  storage_account_access_key = azurerm_storage_account.shield_noor.primary_access_key

  site_config {
    linux_fx_version = "DOCKER|mcr.microsoft.com/azure-functions/dotnet:3.0"
  }
}

resource "azurerm_service_plan" "shield_noor" {
  name                = "shield-noor-service-plan"
  location            = azurerm_resource_group.shield_noor.location
  resource_group_name = azurerm_resource_group.shield_noor.name
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

# Azure Storage Account
resource "azurerm_storage_account" "shield_noor" {
  name                     = "shieldnoorstorageacc"
  resource_group_name      = azurerm_resource_group.shield_noor.name
  location                 = azurerm_resource_group.shield_noor.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}