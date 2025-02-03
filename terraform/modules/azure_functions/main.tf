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
    # VNet integration is removed here. If needed, configure VNet integration using a separate resource.
  }
  
  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "dotnet"
    WEBSITE_RUN_FROM_PACKAGE = "1"
  }
  
  tags = var.tags
}
