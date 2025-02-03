// Resource Group & Location
variable "resource_group_name" {
  description = "The name of the resource group in which to create the Function App."
  type        = string
}

variable "location" {
  description = "The Azure region for the resources (e.g., 'northeurope')."
  type        = string
}

// Function App Settings
variable "functions_name" {
  description = "Name of the Azure Functions app. Must be 3-24 characters, lowercase letters and numbers only."
  type        = string
}

variable "functions_worker_runtime" {
  description = "The runtime for the Functions app (e.g., 'dotnet', 'node', 'python')."
  type        = string
}

// Service Plan Settings
variable "app_service_plan_tier" {
  description = "Tier for the App Service Plan. Use 'Dynamic' for a Consumption plan or another value (e.g., 'PremiumV2') for a dedicated plan."
  type        = string
}

variable "app_service_plan_size" {
  description = "The size for the App Service Plan. For a Consumption plan, this is usually 'Y1'; for Premium, e.g., 'P1v2'."
  type        = string
}

// Tags to apply to all resources.
variable "tags" {
  description = "A map of tags to apply to resources."
  type        = map(string)
}
