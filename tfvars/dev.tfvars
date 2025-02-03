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

# Log Analytics Workspace ID (update with your actual workspace resource ID)
log_analytics_workspace_id = "/subscriptions/your_subscription_id/resourceGroups/your_rg/providers/Microsoft.OperationalInsights/workspaces/your_workspace"

# Azure Functions
# Note: Ensure functions_name contains only lowercase letters and numbers.
functions_name           = "funcnesa"
functions_sku            = "P1v2"
app_service_plan_tier    = "Dynamic"    # or "PremiumV2" as needed
app_service_plan_size    = "Y1"         # e.g., Y1 for consumption; P1v2 for premium
function_app_version     = "~4"         # or "~3", depending on your requirement
functions_worker_runtime = "dotnet"     # or "python", "node", etc.

# Logic Apps
logic_apps_name                           = "logicappsne"
logic_apps_sku                            = "Standard"
logic_apps_storage_account_name           = "stlogicappsne"
logic_apps_storage_account_access_key     = "your_logicapps_storage_access_key_here"

# Storage Account
storage_account_name             = "storne"
storage_account_kind             = "StorageV2"
storage_account_tier             = "Standard"
storage_account_replication_type = "LRS"
is_hns_enabled                   = false
default_action                   = "Allow"
ip_rules                         = []
virtual_network_subnet_ids       = []

# Azure Cognitive Search
search_service_name = "searchne"
search_sku          = "standard"

# Azure OpenAI
openai_name = "openaine"
