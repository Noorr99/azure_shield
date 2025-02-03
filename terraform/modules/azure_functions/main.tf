terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.50"
    }
  }
}

provider "azurerm" {
  features {}
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

# Create a Service Plan for the Function App.
resource "azurerm_service_plan" "functions_plan" {
  name                = "${var.functions_name}-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"    // Required for Linux Function Apps.

  # Compute sku_name based on the tier:
  # If the tier is "Dynamic", then sku_name is "Y1" (Consumption plan);
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

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = var.functions_worker_runtime
    WEBSITE_RUN_FROM_PACKAGE = "1"
  }

  site_config {
    # The linux_fx_version must be in the format "runtime|version".
    # Adjust this based on your chosen runtime. For example:
    #   - dotnet: "dotnet|6"
    #   - node:   "node|14"
    #   - python: "python|3.8"
    linux_fx_version = "dotnet|6"
  }

  tags = var.tags
}

/*
  Hosting Options Consideration:
  --------------------------------
  In the Azure portal you have several hosting options available:
  
    - Flex Consumption: Offers high scalability, flexible compute choices, and enhanced virtual networking.
    - Consumption: Pure pay-as-you-go model where you pay only when functions run.
    - Functions Premium: Provides premium features (e.g., VNET integration, avoiding cold starts) with event-driven scaling.
    - App Service: Runs function apps and web apps on the same plan with fixed instance pricing.
    - Container Apps Environment: Hosts function apps with other containerized microservices.

  In this configuration, if you choose a Consumption-based model, ensure that:
    - For standard Consumption, use "Dynamic" for var.app_service_plan_tier so that sku_name is set to "Y1".
    - For Flex Consumption (if supported in your region), update var.app_service_plan_tier and var.app_service_plan_size as needed.
*/
