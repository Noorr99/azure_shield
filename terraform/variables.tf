//////////////////////////////
// Region & Resource Groups //
//////////////////////////////

variable "location" {
  description = "Specifies the Azure region where resources will be created."
  type        = string
  default     = "northeurope"
}

variable "network_rg_name" {
  description = "Name of the resource group to hold networking resources (VNet, subnets, etc.)."
  type        = string
}

variable "services_rg_name" {
  description = "Name of the resource group to hold service resources (Azure Functions, Logic Apps, OpenAI, etc.)."
  type        = string
}

//////////////////////////////
// Networking & Subnets    //
//////////////////////////////

variable "vnet_name" {
  description = "Specifies the name of the Azure virtual network."
  type        = string
}

variable "vnet_address_space" {
  description = "Specifies the address space for the Azure virtual network."
  type        = list(string)
}

variable "subnet_services_name" {
  description = "Specifies the name of the subnet for services (Functions/Logic Apps)."
  type        = string
}

variable "subnet_services_prefix" {
  description = "Address prefix for the services subnet."
  type        = list(string)
}

variable "subnet_ai_name" {
  description = "Specifies the name of the subnet for private endpoints (OpenAI, Cognitive Search, Storage, etc.)."
  type        = string
}

variable "subnet_ai_prefix" {
  description = "Address prefix for the private endpoints subnet."
  type        = list(string)
}

//////////////////////////////
// NSG Variables (Optional) //
//////////////////////////////

variable "nsg_services_name" {
  description = "Name of the NSG for the services subnet."
  type        = string
  default     = "nsg-services"
}

variable "nsg_ai_name" {
  description = "Name of the NSG for the AI/private endpoints subnet."
  type        = string
  default     = "nsg-ai"
}

//////////////////////////////
// Azure OpenAI Variables   //
//////////////////////////////
variable "openai_name" {
  description = "Name of the Azure OpenAI resource."
  type        = string
}

variable "openai_sku" {
  description = "SKU for Azure OpenAI resource."
  type        = string
  default     = "S0"
}

//////////////////////////////
// Cognitive Search         //
//////////////////////////////
variable "search_name" {
  description = "Name of Azure Cognitive Search service."
  type        = string
}

variable "search_sku" {
  description = "SKU for Azure Cognitive Search (e.g., 'standard', 'basic', etc.)."
  type        = string
  default     = "standard"
}

//////////////////////////////
// Storage Account          //
//////////////////////////////
variable "storage_account_name" {
  description = "Name of the Storage Account for blob & table."
  type        = string
}

//////////////////////////////
// Logic Apps (Standard)    //
//////////////////////////////
variable "logic_app_name" {
  description = "Name of the Logic App (Standard)."
  type        = string
}

//////////////////////////////
// Azure Functions (Premium)//
//////////////////////////////
variable "function_app_name" {
  description = "Name of the Azure Function App."
  type        = string
}

variable "function_app_plan_name" {
  description = "Name of the App Service Plan for the function app."
  type        = string
  default     = "asp-function-premium"
}

variable "function_app_sku" {
  description = "SKU for the function app service plan. E.g., 'EP1', 'EP2' for Premium."
  type        = string
  default     = "EP1"
}

//////////////////////////////
// Tags                     //
//////////////////////////////
variable "tags" {
  description = "Specifies tags to apply to all resources."
  type        = map(string)
  default     = {}
}
