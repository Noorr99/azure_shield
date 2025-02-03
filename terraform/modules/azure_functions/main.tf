terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.50"
    }
  }
}

# Create a storage account for the Function App.
resource "azurerm_storage_account" "functions_storage" {
  # Remove hyphens from the functions name so that the resulting storage account name is valid.
  name                     = lower(replace(var.functions_name, "-", ""))
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

# Create a service plan using the new resource.
resource "azurerm_service_plan" "functions_plan" {
  name                = "${var.functions_name}-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = var.app_service_plan_tier   // e.g., "Dynamic" or "PremiumV2"
    size = var.app_service_plan_size     // e.g., "Y1" for consumption or "P1v2" for premium
  }

  tags = var.tags
}

# Create a Linux Function App.
resource "azurerm_linux_function_app" "functions_app" {
  name                       = var.functions_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  service_plan_id            = azurerm_service_plan.functions_plan.id
  storage_account_name       = azurerm_storage_account.functions_storage.name
  storage_account_access_key = azurerm_storage_account.functions_storage.primary_access_key
  os_type                    = "linux"
  version                    = var.function_app_version

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = var.functions_worker_runtime
    WEBSITE_RUN_FROM_PACKAGE = "1"
  }

  tags = var.tags
}
