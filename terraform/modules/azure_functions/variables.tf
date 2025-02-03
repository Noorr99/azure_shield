variable "functions_name" {
  description = "Name of the Azure Function App."
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
  description = "Tier for the App Service Plan (e.g., Dynamic or PremiumV2)."
  type        = string
}

variable "app_service_plan_size" {
  description = "Size for the App Service Plan (e.g., Y1 for consumption, P1v2 for premium)."
  type        = string
}

variable "function_app_version" {
  description = "Function App runtime version (e.g., ~3 or ~4)."
  type        = string
}

variable "functions_worker_runtime" {
  description = "Functions worker runtime (e.g., dotnet, node, python)."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the resources."
  type        = map(string)
  default     = {}
}
