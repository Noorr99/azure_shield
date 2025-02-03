variable "resource_group_name" {
  description = "Name of the resource group for all resources."
  type        = string
}

variable "location" {
  description = "Azure region (e.g. northeurope)."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
}

variable "vnet_name" {
  description = "Name of the Virtual Network."
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the Virtual Network."
  type        = list(string)
}

variable "services_subnet_name" {
  description = "Name of the subnet for services (Functions, Logic Apps)."
  type        = string
}

variable "services_subnet_address_prefixes" {
  description = "Address prefixes for the services subnet."
  type        = list(string)
}

variable "ai_subnet_name" {
  description = "Name of the subnet for AI/private endpoints."
  type        = string
}

variable "ai_subnet_address_prefixes" {
  description = "Address prefixes for the AI subnet."
  type        = list(string)
}

variable "nsg_services_name" {
  description = "Name of the NSG for the services subnet."
  type        = string
}

variable "nsg_services_rules" {
  description = "Security rules for the NSG of the services subnet."
  type        = any
  default     = []
}

variable "nsg_ai_name" {
  description = "Name of the NSG for the AI subnet."
  type        = string
}

variable "nsg_ai_rules" {
  description = "Security rules for the NSG of the AI subnet."
  type        = any
  default     = []
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace for NSG diagnostics."
  type        = string
}

variable "functions_name" {
  description = "Name of the Azure Functions app."
  type        = string
}

variable "functions_sku" {
  description = "SKU for the Azure Functions app (e.g., P1v2)."
  type        = string
}

variable "logic_apps_name" {
  description = "Name of the Logic Apps instance."
  type        = string
}

variable "logic_apps_sku" {
  description = "SKU for Logic Apps (Standard)."
  type        = string
}

variable "logic_apps_storage_account_name" {
  description = "Name of the storage account used by Logic Apps."
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account."
  type        = string
}

variable "storage_account_kind" {
  description = "Kind of the storage account (e.g., StorageV2)."
  type        = string
  default     = "StorageV2"
}

variable "storage_account_tier" {
  description = "Tier of the storage account (e.g., Standard or Premium)."
  type        = string
}

variable "storage_account_replication_type" {
  description = "Replication type for the storage account (e.g., LRS, GRS, etc.)."
  type        = string
}

variable "is_hns_enabled" {
  description = "Whether hierarchical namespace is enabled."
  type        = bool
  default     = false
}

variable "default_action" {
  description = "Default network action for storage (Allow or Deny)."
  type        = string
  default     = "Allow"
}

variable "ip_rules" {
  description = "List of IP rules for the storage account."
  type        = list(string)
  default     = []
}

variable "virtual_network_subnet_ids" {
  description = "List of subnet resource IDs for virtual network rules on the storage account."
  type        = list(string)
  default     = []
}

variable "search_service_name" {
  description = "Name of the Azure Cognitive Search service."
  type        = string
}

variable "search_sku" {
  description = "SKU for the Search service (e.g., standard)."
  type        = string
}

variable "openai_name" {
  description = "Name of the Azure OpenAI service."
  type        = string
}
