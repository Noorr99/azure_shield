###############################
# General
###############################

variable "resource_group_name" {
  description = "Name of the resource group for all resources."
  type        = string
}

variable "location" {
  description = "Azure region (for example, northeurope)."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
}

###############################
# Virtual Network & Subnets
###############################

variable "vnet_name" {
  description = "Name of the Virtual Network."
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the Virtual Network."
  type        = list(string)
}

variable "services_subnet_name" {
  description = "Name of the subnet for services (Azure Functions, Logic Apps)."
  type        = string
}

variable "services_subnet_address_prefixes" {
  description = "Address prefix(es) for the services subnet."
  type        = list(string)
}

variable "ai_subnet_name" {
  description = "Name of the subnet for AI and private endpoints."
  type        = string
}

variable "ai_subnet_address_prefixes" {
  description = "Address prefix(es) for the AI subnet."
  type        = list(string)
}

###############################
# NSG Variables
###############################

variable "nsg_services_name" {
  description = "Name of the NSG for the services subnet."
  type        = string
}

variable "nsg_services_rules" {
  description = "Security rules for the services NSG."
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_address_prefix      = string
    destination_address_prefix = string
    source_port_range          = string
    destination_port_range     = string
  }))
}

variable "nsg_ai_name" {
  description = "Name of the NSG for the AI subnet."
  type        = string
}

variable "nsg_ai_rules" {
  description = "Security rules for the AI NSG."
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_address_prefix      = string
    destination_address_prefix = string
    source_port_range          = string
    destination_port_range     = string
  }))
}

###############################
# Azure Functions
###############################

variable "functions_name" {
  description = "Name of the Azure Functions app."
  type        = string
}

variable "functions_sku" {
  description = "SKU for the Azure Functions app (for example, P1v2)."
  type        = string
}

###############################
# Logic Apps
###############################

variable "logic_apps_name" {
  description = "Name of the Logic Apps instance."
  type        = string
}

variable "logic_apps_sku" {
  description = "SKU for Logic Apps (should be Standard)."
  type        = string
}

variable "logic_apps_storage_account_name" {
  description = "Name of the storage account for Logic Apps."
  type        = string
}

variable "logic_apps_storage_account_access_key" {
  description = "Access key for the Logic Apps storage account."
  type        = string
  sensitive   = true
}

###############################
# Storage Account
###############################

variable "storage_account_name" {
  description = "Name of the Storage Account."
  type        = string
}

variable "storage_account_tier" {
  description = "Tier for the Storage Account."
  type        = string
}

variable "storage_account_replication_type" {
  description = "Replication type for the Storage Account."
  type        = string
}

###############################
# Azure Cognitive Search
###############################

variable "search_service_name" {
  description = "Name of the Azure Cognitive Search service."
  type        = string
}

variable "search_sku" {
  description = "SKU for the Search service (for example, standard)."
  type        = string
}

###############################
# Azure OpenAI
###############################

variable "openai_name" {
  description = "Name of the Azure OpenAI service."
  type        = string
}

/*

###############################
# Key Vault (Optional)
###############################

variable "key_vault_name" {
  description = "Name of the Key Vault."
  type        = string
}

variable "tenant_id" {
  description = "Tenant ID for Key Vault."
  type        = string
  sensitive   = true
}

variable "key_vault_sku" {
  description = "SKU for Key Vault (for example, standard)."
  type        = string
}

variable "key_vault_enabled_for_deployment" {
  description = "Allow deployment access to the Key Vault."
  type        = bool
}

variable "key_vault_enabled_for_disk_encryption" {
  description = "Allow disk encryption access to the Key Vault."
  type        = bool
}

variable "key_vault_enabled_for_template_deployment" {
  description = "Allow template deployment access to the Key Vault."
  type        = bool
}

variable "key_vault_enable_rbac_authorization" {
  description = "Enable RBAC for Key Vault."
  type        = bool
}

variable "key_vault_purge_protection_enabled" {
  description = "Enable purge protection on the Key Vault."
  type        = bool
}

variable "key_vault_soft_delete_retention_days" {
  description = "Soft delete retention days for Key Vault."
  type        = number
}

variable "key_vault_bypass" {
  description = "Bypass option for Key Vault."
  type        = string
}

variable "key_vault_default_action" {
  description = "Default network action for Key Vault (Allow or Deny)."
  type        = string
}

variable "key_vault_ip_rules" {
  description = "IP rules for Key Vault."
  type        = list(string)
}

*/