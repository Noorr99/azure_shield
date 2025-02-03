///////////////////////////////
// Backend Configuration
///////////////////////////////
variable "backend_resource_group" {
  description = "Resource group name for storing Terraform state."
  type        = string
}

variable "backend_storage_account" {
  description = "Storage account name for the Terraform state backend."
  type        = string
}

variable "backend_container" {
  description = "Container name for the Terraform state backend."
  type        = string
}

variable "backend_key" {
  description = "The key for the Terraform state file."
  type        = string
}

variable "backend_subscription_id" {
  description = "Subscription ID for the Terraform state backend."
  type        = string
}

///////////////////////////////
// General Resource Group & Location
///////////////////////////////
variable "resource_group_name" {
  description = "Name of the dedicated resource group."
  type        = string
}

variable "location" {
  description = "Azure region for all resources. (e.g., northeurope)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
}

///////////////////////////////
// Virtual Network & Subnets
///////////////////////////////
variable "vnet_name" {
  description = "Name of the virtual network."
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the virtual network."
  type        = list(string)
}

variable "services_subnet_name" {
  description = "Name of the subnet for services (Logic Apps, Azure Functions, etc.)."
  type        = string
}

variable "services_subnet_prefix" {
  description = "Address prefix(es) for the services subnet."
  type        = list(string)
}

variable "pe_subnet_name" {
  description = "Name of the subnet for private endpoints."
  type        = string
}

variable "pe_subnet_prefix" {
  description = "Address prefix(es) for the private endpoints subnet."
  type        = list(string)
}

///////////////////////////////
// Log Analytics Workspace (for NSG diagnostics, etc.)
///////////////////////////////
variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace."
  type        = string
}

///////////////////////////////
// NSG Variables for Subnets
///////////////////////////////
variable "services_nsg_name" {
  description = "Name of the NSG for the services subnet."
  type        = string
}

variable "services_nsg_rules" {
  description = "Security rules for the services subnet NSG."
  type        = list(any)
  default     = []
}

variable "pe_nsg_name" {
  description = "Name of the NSG for the private endpoints subnet."
  type        = string
}

variable "pe_nsg_rules" {
  description = "Security rules for the private endpoints subnet NSG."
  type        = list(any)
  default     = []
}

///////////////////////////////
// Azure Storage Account Variables
///////////////////////////////
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

///////////////////////////////
// Azure OpenAI Variables
///////////////////////////////
variable "openai_name" {
  description = "Name of the Azure OpenAI service."
  type        = string
}

variable "openai_sku" {
  description = "SKU name for the Azure OpenAI service."
  type        = string
  default     = "S0"
}

variable "openai_custom_subdomain_name" {
  description = "Custom subdomain name for the Azure OpenAI service."
  type        = string
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
