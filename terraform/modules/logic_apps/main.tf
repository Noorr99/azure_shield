resource "azurerm_app_service_plan" "logicapps_plan" {
  name                = "${var.logic_apps_name}-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "Linux"
  reserved            = true
  
  sku {
    tier = "Standard"
    size = var.sku
  }
  
  tags = var.tags
}

resource "azurerm_logic_app_standard" "logic_app" {
  name                = var.logic_apps_name
  location            = var.location
  resource_group_name = var.resource_group_name
  app_service_plan_id = azurerm_app_service_plan.logicapps_plan.id
  
  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key
  
  identity {
    type = "SystemAssigned"
  }
  
  tags = var.tags
}

resource "azurerm_app_service_virtual_network_swift_connection" "logicapps_vnet" {
  app_service_id = azurerm_logic_app_standard.logic_app.id
  subnet_id      = var.subnet_id
}
