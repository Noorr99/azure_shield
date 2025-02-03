variable "functions_name" {
  description = "Name of the Azure Functions app."
  type        = string
}

variable "sku" {
  description = "SKU size for the Functions app (e.g., P1v2)."
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
  description = "The subnet ID for VNet integration."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the resources."
  type        = map(string)
  default     = {}
}
