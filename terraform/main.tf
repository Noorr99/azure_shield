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
# Cognitive Services Account (OpenAI)
#############################################

resource "azurerm_cognitive_services_account" "noorsheild" {
  name                = var.accounts_noorsheild_name
  location            = "eastus"  // as in your ARM template
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "OpenAI"
  sku_name            = "S0"

  api_properties         = {} 
  custom_sub_domain_name = var.accounts_noorsheild_name

  network_acls {
    default_action       = "Allow"
    virtual_network_rules = []  // add if needed
    ip_rules              = []
  }

  public_network_access = "Disabled"
}

# Note: The ARM sub-resources such as DefenderForAISettings and RAI policies are not yet available
# as native Terraform resources. They could be added later via the "azapi_resource" if needed.

#############################################
# Application Insights Component
#############################################

resource "azurerm_application_insights" "sheildnetwork" {
  name                = var.components_sheildnetwork_name
  location            = "northeurope"
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  retention_in_days   = 90

  # If you need to link a Log Analytics workspace, set workspace_id accordingly.
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

  // Additional properties (encryption, auth options) can be added if supported.
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
  allow_blob_public_access = false
  min_tls_version          = "TLS1_2"
  access_tier              = "Hot"

  network_rules {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
}

resource "azurerm_storage_account" "sheildnoor" {
  name                     = var.storageAccounts_sheildnoor_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = "northeurope"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_blob_public_access = false
  min_tls_version          = "TLS1_2"
  access_tier              = "Hot"

  network_rules {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
}

resource "azurerm_storage_account" "rgnetworkingb244" {
  name                     = var.storageAccounts_rgnetworkingb244_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = "northeurope"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_blob_public_access = false
  min_tls_version          = "TLS1_2"
  access_tier              = "Hot"

  network_rules {
    default_action = "Deny"
    bypass         = "AzureServices"
    virtual_network_subnet_ids = [
      azurerm_subnet.subnet_outbound.id
    ]
  }
}

#############################################
# App Service Plans
#############################################

resource "azurerm_app_service_plan" "asp_rgnetworking_81f2" {
  name                = var.serverfarms_ASP_rgnetworking_81f2_name
  location            = "North Europe"
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "functionapp"
  reserved            = true

  sku {
    tier = "FlexConsumption"
    size = "FC1"
  }
}

resource "azurerm_app_service_plan" "asp_rgnetworking_b8b4" {
  name                = var.serverfarms_ASP_rgnetworking_b8b4_name
  location            = "North Europe"
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "elastic"  // for workflow apps
  reserved            = false

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
  app_service_plan_id        = azurerm_app_service_plan.asp_rgnetworking_b8b4.id
  storage_account_name       = azurerm_storage_account.rgnetworking9b4d.name
  storage_account_access_key = azurerm_storage_account.rgnetworking9b4d.primary_access_key

  version    = "~4"
  https_only = true

  site_config {
    always_on         = false
    number_of_workers = 1
    http20_enabled    = false
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_web_app" "sheildnetwork" {
  name                = var.sites_sheildnetwork_name
  location            = "North Europe"
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.asp_rgnetworking_81f2.id

  site_config {
    always_on              = false
    number_of_workers      = 1
    net_framework_version  = "v4.0"
    http20_enabled         = false
    ftps_state             = "FtpsOnly"
    // Additional settings (virtual applications, IP restrictions, etc.) can be added here.
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

  network_security_group_id = azurerm_network_security_group.nsg_subnet_services.id

  # You can disable private endpoint policies if needed:
  enforce_private_link_endpoint_network_policies = false
}

resource "azurerm_subnet" "subnet_ai" {
  name                 = "subnet-ai"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_prod.name
  address_prefixes     = ["10.0.2.0/24"]

  network_security_group_id = azurerm_network_security_group.nsg_subnet_ai.id

  enforce_private_link_endpoint_network_policies = false
}

resource "azurerm_subnet" "subnet_outbound" {
  name                 = "subnet-outbound"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_prod.name
  address_prefixes     = ["10.0.0.0/24"]

  # For outbound delegation (e.g. to App Service environments)
  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.App/environments"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ]
    }
  }

  enforce_private_link_endpoint_network_policies = false
}

#############################################
# Private Endpoints
#############################################

# Private Endpoint for noorfunction (pointing to the sheildnetwork web app)
resource "azurerm_private_endpoint" "noorfunction_pe" {
  name                = var.privateEndpoints_noorfunction_name
  location            = "northeurope"
  resource_group_name = azurerm_resource_group.rg.name

  subnet_id = azurerm_subnet.subnet_services.id

  private_service_connection {
    name                           = var.privateEndpoints_noorfunction_name
    private_connection_resource_id = azurerm_web_app.sheildnetwork.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }
}

# Private Endpoint for Search Service
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

# Private Endpoint for Storage Account (sheildnoor)
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

# Private Endpoint for noorshield (Web App noor_shields)
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

# Private Endpoint for Cognitive Services (OpenAI) – “pe-openai-east”
resource "azurerm_private_endpoint" "pe_openai_east" {
  name                = var.privateEndpoints_pe_openai_east_name
  location            = "northeurope"
  resource_group_name = azurerm_resource_group.rg.name

  subnet_id = azurerm_subnet.subnet_ai.id

  private_service_connection {
    name                           = var.privateEndpoints_pe_openai_east_name
    private_connection_resource_id = azurerm_cognitive_services_account.noorsheild.id
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

# (For the SOA records and A-records you can use the following resources if needed)
# Example: azurerm_private_dns_a_record and azurerm_private_dns_soa_record.

#############################################
# Web App Virtual Network Connection
#############################################

resource "azurerm_web_app_virtual_network_connection" "sheildnetwork_vnet_conn" {
  name                = "${var.sites_sheildnetwork_name}-vnetconn"
  resource_group_name = azurerm_resource_group.rg.name
  web_app_id          = azurerm_web_app.sheildnetwork.id
  subnet_id           = azurerm_subnet.subnet_outbound.id

  // isSwift is available in some versions – adjust if needed.
  is_swift = true
}

#############################################
# (Additional resources)
#############################################
# You can add additional resources for:
# - Storage Blob, File, Queue, and Table service configurations (e.g. using azurerm_storage_container,
#   azurerm_storage_share, azurerm_storage_queue, and azurerm_storage_table).
# - Host name bindings and basic publishing credentials for the web apps (see resource "azurerm_web_app" arguments
#   or use azurerm_app_service_custom_hostname_binding).
# - Proactive Detection configurations for Application Insights are not yet available as native Terraform resources.
# - Private DNS record sets (using azurerm_private_dns_a_record and azurerm_private_dns_soa_record).

