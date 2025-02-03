variable "functions_name" {
  description = "Name of the Azure Function App. Must be lowercase and 3-24 characters, using only letters and numbers."
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

variable "os_type" {
  description = "OS type for the Function App (e.g., 'linux' or 'windows')."
  type        = string
  default     = "linux"
}

variable "app_service_plan_size" {
  description = "SKU for the Service Plan (e.g., 'Y1' for consumption or 'P1v2' for premium)."
  type        = string
}

variable "function_app_version" {
  description = "Version for the Function App (e.g., '~3' or '~4')."
  type        = string
}

variable "functions_worker_runtime" {
  description = "Worker runtime for the Function App (e.g., dotnet, python, node)."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the resources."
  type        = map(string)
  default     = {}
}
