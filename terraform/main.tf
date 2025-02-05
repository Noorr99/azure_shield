provider "azurerm" {
  features {}
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

# Azure OpenAI (Example)
resource "azurerm_openai" "shield_noor" {
  name                = "shield-noor-openai"
  resource_group_name = azurerm_resource_group.shield_noor.name
  location            = azurerm_resource_group.shield_noor.location
  subnet_id           = azurerm_subnet.ai_services.id
  private_endpoint {
    subnet_id = azurerm_subnet.ai_services.id
  }
}

# Azure Cognitive Search
resource "azurerm_search_service" "shield_noor" {
  name                = "shield-noor-search"
  resource_group_name = azurerm_resource_group.shield_noor.name
  location            = azurerm_resource_group.shield_noor.location
  sku                 = "basic"
  partition_count     = 1
  replica_count       = 1
  subnet_id           = azurerm_subnet.ai_services.id
  private_endpoint {
    subnet_id = azurerm_subnet.ai_services.id
  }
}

# Azure Logic Apps
resource "azurerm_logic_app_workflow" "shield_noor" {
  name                = "shield-noor-logicapp"
  resource_group_name = azurerm_resource_group.shield_noor.name
  location            = azurerm_resource_group.shield_noor.location
  subnet_id           = azurerm_subnet.other_services.id
  private_endpoint {
    subnet_id = azurerm_subnet.other_services.id
  }
}

# Azure Functions
resource "azurerm_function_app" "shield_noor" {
  name                = "shield-noor-function"
  resource_group_name = azurerm_resource_group.shield_noor.name
  location            = azurerm_resource_group.shield_noor.location
  subnet_id           = azurerm_subnet.other_services.id
  private_endpoint {
    subnet_id = azurerm_subnet.other_services.id
  }
}

# Azure Storage Account
resource "azurerm_storage_account" "shield_noor" {
  name                     = "shieldnoorstorageacc"
  resource_group_name      = azurerm_resource_group.shield_noor.name
  location                 = azurerm_resource_group.shield_noor.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  subnet_id                = azurerm_subnet.other_services.id
  private_endpoint {
    subnet_id = azurerm_subnet.other_services.id
  }
}