# Resource Group & Region
resource_group_name = "rg-ne-all"
location            = "northeurope"
tags = {
  Environment = "dev"
  Project     = "new-client-ne"
  Owner       = "YourTeam"
}

# Virtual Network
vnet_name          = "vnet-ne-001"
vnet_address_space = ["10.0.0.0/16"]

# Subnets
services_subnet_name             = "subnet-services"
services_subnet_address_prefixes = ["10.0.1.0/24"]

ai_subnet_name             = "subnet-ai"
ai_subnet_address_prefixes = ["10.0.2.0/24"]

# NSG for Services Subnet
nsg_services_name  = "nsg-services-ne"
nsg_services_rules = [
  {
    name                       = "AllowVnetInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    source_port_range          = "*"
    destination_port_range     = "*"
  },
  {
    name                       = "DenyInternetInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
  }
]

# NSG for AI Subnet
nsg_ai_name  = "nsg-ai-ne"
nsg_ai_rules = [
  {
    name                       = "AllowVnetInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    source_port_range          = "*"
    destination_port_range     = "*"
  },
  {
    name                       = "DenyInternetInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
  }
]

# Azure Functions
functions_name = "func-ne"
functions_sku  = "P1v2"

# Logic Apps
logic_apps_name = "logicapps-ne"
logic_apps_sku  = "Standard"
logic_apps_storage_account_name       = "stlogicappsne"
logic_apps_storage_account_access_key = "your_logicapps_storage_access_key_here"

# Storage Account
storage_account_name             = "storne"
storage_account_tier             = "Standard"
storage_account_replication_type = "LRS"

# Azure Cognitive Search
search_service_name = "search-ne"
search_sku          = "standard"

# Azure OpenAI
openai_name = "openai-ne"

/*
# Key Vault (Optional)
key_vault_name = "kv-ne"
tenant_id      = "your-tenant-id-here"
key_vault_sku  = "standard"
key_vault_enabled_for_deployment          = false
key_vault_enabled_for_disk_encryption     = false
key_vault_enabled_for_template_deployment = false
key_vault_enable_rbac_authorization       = false
key_vault_purge_protection_enabled        = false
key_vault_soft_delete_retention_days      = 7
key_vault_bypass           = "AzureServices"
key_vault_default_action   = "Deny"
key_vault_ip_rules         = []
*/