

provider "azurerm" {
  features {}
}

# main.tf
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform-storage"
    storage_account_name = "terraformstgaks99"
    container_name       = "tfstatesheilddev"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-main"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = [var.vnet_address_space]
}

# Subnets
resource "azurerm_subnet" "services" {
  name                 = "subnet-services"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_services_cidr]
  service_endpoints    = ["Microsoft.Web"]
}

resource "azurerm_subnet" "ai" {
  name                 = "subnet-ai"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_ai_cidr]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.KeyVault"]
}

# Network Security Groups
resource "azurerm_network_security_group" "services" {
  name                = "nsg-services"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  security_rule {
    name                       = "AllowVNetInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }
}

resource "azurerm_network_security_group" "ai" {
  name                = "nsg-ai"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSGs with Subnets
resource "azurerm_subnet_network_security_group_association" "services" {
  subnet_id                 = azurerm_subnet.services.id
  network_security_group_id = azurerm_network_security_group.services.id
}

resource "azurerm_subnet_network_security_group_association" "ai" {
  subnet_id                 = azurerm_subnet.ai.id
  network_security_group_id = azurerm_network_security_group.ai.id
}

# Private DNS Zones
resource "azurerm_private_dns_zone" "dns_zones" {
  for_each            = toset(var.private_dns_zones)
  name                = each.value
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
  for_each              = azurerm_private_dns_zone.dns_zones
  name                  = "vnet-link-${each.value.name}"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = each.value.name
  virtual_network_id    = azurerm_virtual_network.main.id
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  public_network_access_enabled = false

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [
      azurerm_subnet.services.id,
      azurerm_subnet.ai.id
    ]
  }
}

# Storage Private Endpoints
resource "azurerm_private_endpoint" "storage_blob" {
  name                = "pe-storage-blob"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id           = azurerm_subnet.ai.id

  private_service_connection {
    name                           = "psc-storage-blob"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_zones["privatelink.blob.core.windows.net"].id]
  }
}

resource "azurerm_private_endpoint" "storage_table" {
  name                = "pe-storage-table"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id           = azurerm_subnet.ai.id

  private_service_connection {
    name                           = "psc-storage-table"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["table"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_zones["privatelink.table.core.windows.net"].id]
  }
}

# Azure Cognitive Search
resource "azurerm_search_service" "main" {
  name                = var.search_service_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "standard"
  public_network_access_enabled = false
}

resource "azurerm_private_endpoint" "search" {
  name                = "pe-search"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id           = azurerm_subnet.ai.id

  private_service_connection {
    name                           = "psc-search"
    private_connection_resource_id = azurerm_search_service.main.id
    subresource_names              = ["searchService"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_zones["privatelink.search.windows.net"].id]
  }
}

# Azure OpenAI
resource "azurerm_cognitive_account" "openai" {
  name                = var.openai_account_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  kind                = "OpenAI"
  sku_name            = "S0"
  public_network_access_enabled = false
}

resource "azurerm_private_endpoint" "openai" {
  name                = "pe-openai"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id           = azurerm_subnet.ai.id

  private_service_connection {
    name                           = "psc-openai"
    private_connection_resource_id = azurerm_cognitive_account.openai.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_zones["privatelink.openai.azure.com"].id]
  }
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                        = var.key_vault_name
  resource_group_name         = azurerm_resource_group.main.name
  location                    = azurerm_resource_group.main.location
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
}

resource "azurerm_private_endpoint" "key_vault" {
  name                = "pe-key-vault"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id           = azurerm_subnet.ai.id

  private_service_connection {
    name                           = "psc-key-vault"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_zones["privatelink.vaultcore.azure.net"].id]
  }
}

# App Service Plans
resource "azurerm_service_plan" "functions" {
  name                = "asp-functions"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Windows"
  sku_name            = "EP1"
}

resource "azurerm_service_plan" "logic_apps" {
  name                = "asp-logic-apps"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Windows"
  sku_name            = "WS1"
}

# Azure Functions
resource "azurerm_windows_function_app" "main" {
  name                = var.function_app_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.functions.id

  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key

  site_config {
    application_stack {
      dotnet_version = "v6.0"
    }
    vnet_route_all_enabled = true
  }

  virtual_network_subnet_id = azurerm_subnet.services.id

  identity {
    type = "SystemAssigned"
  }
}

# Logic Apps
resource "azurerm_logic_app_standard" "main" {
  name                       = var.logic_app_name
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  app_service_plan_id        = azurerm_service_plan.logic_apps.id
  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key
  virtual_network_subnet_id  = azurerm_subnet.services.id

  identity {
    type = "SystemAssigned"
  }
}

# RBAC Assignments
resource "azurerm_role_assignment" "function_storage" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_windows_function_app.main.identity[0].principal_id
}

resource "azurerm_role_assignment" "function_keyvault" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_windows_function_app.main.identity[0].principal_id
}

resource "azurerm_role_assignment" "logicapp_keyvault" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_logic_app_standard.main.identity[0].principal_id
}

# Azure Policies
resource "azurerm_policy_definition" "private_endpoints" {
  name         = "enforce-private-endpoints"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Enforce private endpoints for specified services"

  policy_rule = jsonencode({
    "if" = {
      "anyOf" = [
        {
          "allOf" = [
            {
              "field" = "type",
              "equals" = "Microsoft.Storage/storageAccounts"
            },
            {
              "field" = "Microsoft.Storage/storageAccounts/privateEndpointConnections[*].privateLinkServiceConnectionState.status",
              "notEquals" = "Approved"
            }
          ]
        },
        {
          "allOf" = [
            {
              "field" = "type",
              "equals" = "Microsoft.Search/searchServices"
            },
            {
              "field" = "Microsoft.Search/searchServices/privateEndpointConnections[*].privateLinkServiceConnectionState.status",
              "notEquals" = "Approved"
            }
          ]
        }
      ]
    },
    "then" = {
      "effect" = "deny"
    }
  })
}

resource "azurerm_policy_assignment" "enforce_private_endpoints" {
  name                 = "enforce-private-endpoints-assignment"
  scope                = azurerm_resource_group.main.id
  policy_definition_id = azurerm_policy_definition.private_endpoints.id
}

resource "azurerm_policy_assignment" "region_lock" {
  name                 = "region-lock"
  scope                = azurerm_resource_group.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
  parameters = jsonencode({
    "listOfAllowedLocations" = {
      "value" = [var.location]
    }
  })
}