variable "logic_apps_name" {
  description = "Name of the Logic Apps instance."
  type        = string
}

variable "sku" {
  description = "SKU for Logic Apps (should be Standard)."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "location" {
  description = "Azure location."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for VNet integration."
  type        = string
}

variable "storage_account_name" {
  description = "Storage account name for Logic Apps."
  type        = string
}

variable "storage_account_access_key" {
  description = "Access key for the storage account used by Logic Apps."
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to the Logic Apps resources."
  type        = map(string)
  default     = {}
}
