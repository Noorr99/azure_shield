variable "resource_group_name" {
  description = "Name of the dedicated resource group."
  type        = string
  default     = "rg-sheildnoor"
}

variable "location" {
  description = "Azure region for all resources. (e.g., eastus, northeurope)"
  type        = string
  default     = "eastus"   # For OpenAI, eastus is a supported region.
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {
    environment = "sheildnoor"
    project     = "sheildnoor"
  }
}

variable "vnet_name" {
  description = "Name of the virtual network."
  type        = string
  default     = "vnet-sheildnoor"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "services_subnet_name" {
  description = "Name of the subnet for services (Logic Apps, Azure Functions, etc.)."
  type        = string
  default     = "snet-sheildnoor-services"
}

variable "services_subnet_prefix" {
  description = "Address prefix(es) for the services subnet."
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "pe_subnet_name" {
  description = "Name of the subnet for private endpoints."
  type        = string
  default     = "snet-sheildnoor-pe"
}

variable "pe_subnet_prefix" {
  description = "Address prefix(es) for the private endpoints subnet."
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace."
  type        = string
  default     = "/subscriptions/<your-subscription-id>/resourceGroups/<rg-name>/providers/Microsoft.OperationalInsights/workspaces/<workspace-name>"
}

variable "services_nsg_name" {
  description = "Name of the NSG for the services subnet."
  type        = string
  default     = "nsg-sheildnoor-services"
}

variable "services_nsg_rules" {
  description = "Security rules for the services subnet NSG."
  type        = list(any)
  default     = []
}

variable "pe_nsg_name" {
  description = "Name of the NSG for the private endpoints subnet."
  type        = string
  default     = "nsg-sheildnoor-pe"
}

variable "pe_nsg_rules" {
  description = "Security rules for the private endpoints subnet NSG."
  type        = list(any)
  default     = []
}

variable "storage_account_name" {
  description = "Name of the storage account (must be all lowercase and globally unique)."
  type        = string
  default     = "stsheildnoor"
}

variable "storage_account_kind" {
  description = "Kind of the storage account (e.g., StorageV2)."
  type        = string
  default     = "StorageV2"
}

variable "storage_account_tier" {
  description = "Account tier for the storage account (e.g., Standard or Premium)."
  type        = string
  default     = "Standard"
}

variable "storage_replication_type" {
  description = "Replication type for the storage account (e.g., LRS, ZRS, etc.)."
  type        = string
  default     = "LRS"
}

variable "storage_is_hns_enabled" {
  description = "Enable hierarchical namespace on the storage account?"
  type        = bool
  default     = false
}

variable "storage_ip_rules" {
  description = "IP rules for the storage account."
  type        = list(string)
  default     = []
}

variable "openai_name" {
  description = "Name of the Azure OpenAI service."
  type        = string
  default     = "openai-sheildnoor"
}

variable "openai_sku" {
  description = "SKU name for the Azure OpenAI service."
  type        = string
  default     = "S0"
}

variable "openai_custom_subdomain_name" {
  description = "Custom subdomain name for the Azure OpenAI service."
  type        = string
  default     = "sheildnoor-openai"
}

variable "openai_deployments" {
  description = "List of deployments for the Azure OpenAI service."
  type = list(object({
    name = string
    model = object({
      name    = string
      version = string
    })
  }))
  default = []
}
