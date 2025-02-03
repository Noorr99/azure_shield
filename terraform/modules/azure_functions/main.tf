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
  # Ensure the storage account name is valid (lowercase letters and numbers only, 3-24 characters)
  name                     = lower(replace(var.functions_name, "-", ""))
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

# Create a Service Plan using the new resource.
resource "azurerm_service_plan" "functions_plan" {
  name                = "${var.functions_name}-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"    // Required for Linux Function Apps.
  // Remove the "reserved" attribute—its value is now auto‐configured.

  # Compute sku_name based on the tier:
  # If the tier is "Dynamic", then sku_name is "Y1" (consumption plan);
  # otherwise (e.g. PremiumV2), use the provided app_service_plan_size.
  sku_name = var.app_service_plan_tier == "Dynamic" ? "Y1" : var.app_service_plan_size

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
