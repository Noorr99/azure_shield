# variables.tf
variable "location" {
  description = "Azure region for resources"
  default     = "northeurope"
}

variable "resource_group_name" {
  description = "Name for the main resource group"
  default     = "rg-ai-main-neu"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  default     = "10.0.0.0/16"
}

variable "subnet_services_cidr" {
  description = "CIDR for services subnet"
  default     = "10.0.1.0/24"
}

variable "subnet_ai_cidr" {
  description = "CIDR for AI subnet"
  default     = "10.0.2.0/24"
}

variable "private_dns_zones" {
  description = "List of private DNS zones"
  type        = list(string)
  default = [
    "privatelink.blob.core.windows.net",
    "privatelink.table.core.windows.net",
    "privatelink.search.windows.net",
    "privatelink.openai.azure.com",
    "privatelink.vaultcore.azure.net",
    "privatelink.azurewebsites.net"
  ]
}

variable "storage_account_name" {
  description = "Name for the storage account"
  default     = "staiexample001"
}

variable "search_service_name" {
  description = "Name for Azure Cognitive Search"
  default     = "srch-ai-example"
}

variable "openai_account_name" {
  description = "Name for Azure OpenAI account"
  default     = "openai-example-account"
}

variable "function_app_name" {
  description = "Name for Azure Function App"
  default     = "func-ai-example"
}

variable "logic_app_name" {
  description = "Name for Logic App"
  default     = "logic-ai-example"
}

variable "key_vault_name" {
  description = "Name for Key Vault"
  default     = "kv-ai-example"
}