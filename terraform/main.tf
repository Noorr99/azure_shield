terraform {
  required_version = ">= 1.0.0"
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
#############################################
# Resource Group
#############################################

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

#############################################
# Cognitive Account (OpenAI)
#############################################

resource "azurerm_cognitive_account" "noorsheild" {
  name                = var.accounts_noorsheild_name
  location            = "eastus"  // as in your ARM template
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "OpenAI"
  sku_name            = "S0"

  custom_sub_domain_name = var.accounts_noorsheild_name

  network_acls {
    default_action       = "Allow"
    virtual_network_subnet_ids = []  // add IDs if needed
    ip_rules              = []
  }

  public_network_access_enabled = false
}

#############################################
# Application Insights Component
#############################################

resource "azurerm_application_insights" "sheildnetwork" {
  name                = var.components_sheildnetwork_name
  location            = "northeurope"
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  retention_in_days   = 90

  workspace_id = var.workspaces_DefaultWorkspace_3e169b7b_edb6_4452_94b0_847f2917971a_NEU_externalid
}

#############################################
# Network Security Groups
#############################################

resource "azurerm_network_security_group" "nsg_subnet_ai" {
  name                = var.networkSecurityGroups_nsg_subnet_ai_name
  location            = "northeurope"
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowAllInbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "nsg_subnet_services" {
  name                = var.networkSecurityGroups_nsg_subnet_services_name
  location            = "northeurope"
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowAllInbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

#############################################
# Private DNS Zones
#############################################

resource "azurerm_private_dns_zone" "openai_azure_com" {
  name                = var.privateDnsZones_privatelink_openai_azure_com_name
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone" "azurewebsites" {
  name                = var.privateDnsZones_privatelink_azurewebsites_net_name
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone" "search_windows" {
  name                = var.privateDnsZones_privatelink_search_windows_net_name
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone" "vaultcore_azure_net" {
  name                = var.privateDnsZones_privatelink_vaultcore_azure_net_name
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone" "blob_core_windows" {
  name                = var.privateDnsZones_privatelink_blob_core_windows_net_name
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone" "table_core_windows" {
  name                = var.privateDnsZones_privatelink_table_core_windows_net_name
  resource_group_name = azurerm_resource_group.rg.name
}

#############################################
# Azure Search Service
#############################################

resource "azurerm_search_service" "aisrch_noorsheild" {
  name                = var.searchServices_aisrch_noorsheild_name
  location            = "East US"
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "standard"
  replica_count       = 1
  partition_count     = 1

  public_network_access_enabled = false
  hosting_mode                  = "default"
}

#############################################
# Storage Accounts
#############################################

resource "azurerm_storage_account" "rgnetworking9b4d" {
  name                     = var.storageAccounts_rgnetworking9b4d_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = "northeurope"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  access_tier              = "Hot"

  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }
}

resource "azurerm_storage_account" "sheildnoor" {
  name                     = var.storageAccounts_sheildnoor_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = "northeurope"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  access_tier              = "Hot"

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}

resource "azurerm_storage_account" "rgnetworkingb244" {
  name                     = var.storageAccounts_rgnetworkingb244_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = "northeurope"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  access_tier              = "Hot"

  network_rules {
    default_action           = "Deny"
    bypass                   = ["AzureServices"]
    virtual_network_subnet_ids = [
      azurerm_subnet.subnet_outbound.id
    ]
  }
}

#############################################
# Service Plans (using azurerm_service_plan)
#############################################

resource "azurerm_service_plan" "asp_rgnetworking_81f2" {
  name                = var.serverfarms_ASP_rgnetworking_81f2_name
  location            = "North Europe"
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "Windows"  // For Windows-based web apps
  reserved            = false

  sku {
    tier = "FlexConsumption"
    size = "FC1"
  }
}

resource "azurerm_service_plan" "asp_rgnetworking_b8b4" {
  name                = var.serverfarms_ASP_rgnetworking_b8b4_name
  location            = "North Europe"
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "Linux"  // For Linux function apps
  reserved            = true

  sku {
    tier = "WorkflowStandard"
    size = "WS1"
  }
}

#############################################
# Function and Web Apps
#############################################

resource "azurerm_function_app" "noor_shields" {
  name                       = var.sites_noor_shields_name
  location                   = "North Europe"
  resource_group_name        = azurerm_resource_group.rg.name
  service_plan_id            = azurerm_service_plan.asp_rgnetworking_b8b4.id
  storage_account_name       = azurerm_storage_account.rgnetworking9b4d.name
  storage_account_access_key = azurerm_storage_account.rgnetworking9b4d.primary_access_key

  version    = "~4"
  https_only = true

  site_config {
    always_on         = false
    number_of_workers = 1
    http2_enabled     = false
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_windows_web_app" "sheildnetwork" {
  name                = var.sites_sheildnetwork_name
  location            = "North Europe"
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.asp_rgnetworking_81f2.id

  site_config {
    always_on             = false
    number_of_workers     = 1
    net_framework_version = "v4.0"
    http2_enabled         = false
    ftps_state            = "FtpsOnly"
  }

  identity {
    type = "SystemAssigned"
  }
}

#############################################
# Virtual Network and Subnets
#############################################

resource "azurerm_virtual_network" "vnet_prod" {
  name                = var.virtualNetworks_vnet_prod_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet_services" {
  name                 = "subnet-services"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_prod.name
  address_prefixes     = ["10.0.1.0/24"]

  // Do not set NSG here; use a separate association resource.
  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_subnet" "subnet_ai" {
  name                 = "subnet-ai"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_prod.name
  address_prefixes     = ["10.0.2.0/24"]

  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_subnet" "subnet_outbound" {
  name                 = "subnet-outbound"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_prod.name
  address_prefixes     = ["10.0.0.0/24"]

  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }

  private_endpoint_network_policies = "Disabled"
}

#############################################
# NSG Associations for Subnets
#############################################

resource "azurerm_subnet_network_security_group_association" "assoc_services" {
  subnet_id                 = azurerm_subnet.subnet_services.id
  network_security_group_id = azurerm_network_security_group.nsg_subnet_services.id
}

resource "azurerm_subnet_network_security_group_association" "assoc_ai" {
  subnet_id                 = azurerm_subnet.subnet_ai.id
  network_security_group_id = azurerm_network_security_group.nsg_subnet_ai.id
}

#############################################
# Private Endpoints
#############################################

resource "azurerm_private_endpoint" "noorfunction_pe" {
  name                = var.privateEndpoints_noorfunction_name
  location            = "northeurope"
  resource_group_name = azurerm_resource_group.rg.name

  subnet_id = azurerm_subnet.subnet_services.id

  private_service_connection {
    name                           = var.privateEndpoints_noorfunction_name
    private_connection_resource_id = azurerm_windows_web_app.sheildnetwork.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "pe_aisrch" {
  name                = var.privateEndpoints_pe_aisrch_name
  location            = "northeurope"
  resource_group_name = azurerm_resource_group.rg.name

  subnet_id = azurerm_subnet.subnet_ai.id

  private_service_connection {
    name                           = "${var.privateEndpoints_pe_aisrch_name}-conn"
    private_connection_resource_id = azurerm_search_service.aisrch_noorsheild.id
    subresource_names              = ["searchService"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "pe_blob" {
  name                = var.privateEndpoints_pe_blob_name
  location            = "northeurope"
  resource_group_name = azurerm_resource_group.rg.name

  subnet_id = azurerm_subnet.subnet_services.id

  private_service_connection {
    name                           = "${var.privateEndpoints_pe_blob_name}-conn"
    private_connection_resource_id = azurerm_storage_account.sheildnoor.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "pe_noorshield" {
  name                = var.privateEndpoints_pe_noorshield_name
  location            = "northeurope"
  resource_group_name = azurerm_resource_group.rg.name

  subnet_id = azurerm_subnet.subnet_services.id

  private_service_connection {
    name                           = var.privateEndpoints_pe_noorshield_name
    private_connection_resource_id = azurerm_function_app.noor_shields.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "pe_openai_east" {
  name                = var.privateEndpoints_pe_openai_east_name
  location            = "northeurope"
  resource_group_name = azurerm_resource_group.rg.name

  subnet_id = azurerm_subnet.subnet_ai.id

  private_service_connection {
    name                           = var.privateEndpoints_pe_openai_east_name
    private_connection_resource_id = azurerm_cognitive_account.noorsheild.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }
}

#############################################
# Private DNS Zone Virtual Network Links
#############################################

resource "azurerm_private_dns_zone_virtual_network_link" "link_azurewebsites" {
  name                  = "vnet-link-azurewebsites"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.azurewebsites.name
  virtual_network_id    = azurerm_virtual_network.vnet_prod.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "link_blob_core_windows" {
  name                  = "vnet-link-blob"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.blob_core_windows.name
  virtual_network_id    = azurerm_virtual_network.vnet_prod.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "link_openai_azure_com" {
  name                  = "vnet-link-openai"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.openai_azure_com.name
  virtual_network_id    = azurerm_virtual_network.vnet_prod.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "link_search_windows" {
  name                  = "vnet-link-search"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.search_windows.name
  virtual_network_id    = azurerm_virtual_network.vnet_prod.id
  registration_enabled  = false
}

#############################################
# (Additional resources may be added below)
#############################################