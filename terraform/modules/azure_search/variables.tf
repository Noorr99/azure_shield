variable "search_service_name" {
  description = "Name of the Azure Cognitive Search service."
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

variable "sku" {
  description = "SKU for the Search service (e.g., standard)."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the Azure Search service."
  type        = map(string)
  default     = {}
}
