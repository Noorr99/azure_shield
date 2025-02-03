terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.50"
    }
  }
}

resource "azurerm_storage_account" "functions_storage" {
  # Remove hyphens and lowercase the functions name
  name                     = lower(replace(var.functions_name, "-", ""))
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

resource "azurerm_service_plan" "functions_plan" {
  name                = "${var.functions_name}-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = var.os_type
  reserved            = var.os_type == "linux" ? true : false
  sku_name            = var.app_service_plan_size
  tags                = var.tags
}

resource "azurerm_function_app" "functions_app" {
  name                       = var.functions_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  app_service_plan_id        = azurerm_service_plan.functions_plan.id
  storage_account_name       = azurerm_storage_account.functions_storage.name
  storage_account_access_key = azurerm_storage_account.functions_storage.primary_access_key
  os_type                    = var.os_type
  version                    = var.function_app_version

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = var.functions_worker_runtime
    WEBSITE_RUN_FROM_PACKAGE = "1"
  }

  tags = var.tags
}
