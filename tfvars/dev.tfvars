location            = "northeurope"

network_rg_name     = "rg-proj-neu-network"
services_rg_name    = "rg-proj-neu-services"

vnet_name           = "vnet-proj-neu-001"
vnet_address_space  = ["10.0.0.0/16"]

subnet_services_name   = "subnet-services"
subnet_services_prefix = ["10.0.1.0/24"]

subnet_ai_name         = "subnet-ai"
subnet_ai_prefix       = ["10.0.2.0/24"]

nsg_services_name = "nsg-services"
nsg_ai_name       = "nsg-ai"

# OpenAI
openai_name  = "openai-neu-001"
openai_sku   = "S0"

# Cognitive Search
search_name = "search-neu-001"
search_sku  = "standard"

# Storage
storage_account_name = "stneu001"

# Logic Apps
logic_app_name = "logicapp-neu-001"

# Azure Functions
function_app_name     = "func-neu-001"
function_app_plan_name= "asp-func-neu-premium"
function_app_sku      = "EP1"

tags = {
  environment = "dev"
  owner       = "my-team"
}
