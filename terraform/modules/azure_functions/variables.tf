variable "functions_name" {
  description = "Name of the Azure Function App. Must be between 3 and 24 lowercase alphanumeric characters."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "location" {
  description = "Azure location (e.g., northeurope)."
  type        = string
}

variable "app_service_plan_tier" {
  description = "Tier for the Service Plan (e.g., Dynamic for Consumption or PremiumV2 for Premium)."
  type        = string
}

variable "app_service_plan_size" {
  description = "Size for the Service Plan (e.g., Y1 for Consumption; P1v2 for Premium)."
  type        = string
}

variable "function_app_version" {
  description = "Version for the Function App (e.g., ~3 or ~4)."
  type        = string
}

variable "functions_worker_runtime" {
  description = "Functions worker runtime (e.g., dotnet, python, node)."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the resources."
  type        = map(string)
  default     = {}
}
