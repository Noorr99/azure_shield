variable "functions_name" {
  description = "Name of the Azure Function App."
  type        = string
}

variable "sku" {
  description = "SKU size for the Function App (e.g., P1v2)."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
}

variable "location" {
  description = "Azure location (e.g., northeurope)."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the resources."
  type        = map(string)
  default     = {}
}
