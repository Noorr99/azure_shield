resource "azurerm_app_service_plan" "functions_plan" {
  name                = "${var.functions_name}-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "FunctionApp"
  
  sku {
    tier = "PremiumV2"
    size = var.sku
  }
  
  tags = var.tags
}

resource "azurerm_storage_account" "functions_storage" {
  name                     = lower("${var.functions_name}sa")
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

resource "azurerm_function_app" "functions_app" {
  name                       = var.functions_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  app_service_plan_id        = azurerm_app_service_plan.functions_plan.id
  storage_account_name       = azurerm_storage_account.functions_storage.name
  storage_account_access_key = azurerm_storage_account.functions_storage.primary_access_key
  version                    = "~4"
  
  identity {
    type = "SystemAssigned"
  }
  
  site_config {
    # For Premium plans you can specify the subnet for VNet integration.
    virtual_network_subnet_id = var.subnet_id
  }
  
  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "dotnet"
    WEBSITE_RUN_FROM_PACKAGE = "1"
  }
  
  tags = var.tags
}
