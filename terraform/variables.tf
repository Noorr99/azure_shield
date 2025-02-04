/*
variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
  default     = "example-rg"
}

variable "location" {
  description = "Location for all resources."
  type        = string
  default     = "northeurope"
}

variable "sites_noor_shields_name" {
  description = "Name of the function app (noor-shields)."
  type        = string
  default     = "noor-shields"
}

variable "sites_sheildnetwork_name" {
  description = "Name of the web app (sheildnetwork)."
  type        = string
  default     = "sheildnetwork"
}

variable "privateEndpoints_pe_blob_name" {
  description = "Name for the blob private endpoint."
  type        = string
  default     = "pe-blob"
}

variable "components_sheildnetwork_name" {
  description = "Name for the Application Insights component."
  type        = string
  default     = "sheildnetwork"
}

variable "virtualNetworks_vnet_prod_name" {
  description = "Name for the virtual network."
  type        = string
  default     = "vnet-prod"
}

variable "privateEndpoints_pe_aisrch_name" {
  description = "Name for the Search private endpoint."
  type        = string
  default     = "pe-aisrch"
}

variable "storageAccounts_sheildnoor_name" {
  description = "Name for the storage account used by sheildnoor."
  type        = string
  default     = "sheildnoor"
}

variable "accounts_noorsheild_name" {
  description = "Name for the Cognitive Account."
  type        = string
  default     = "noorsheild"
}

variable "privateEndpoints_noorfunction_name" {
  description = "Name for the private endpoint for noorfunction."
  type        = string
  default     = "noorfunction"
}

variable "serverfarms_ASP_rgnetworking_81f2_name" {
  description = "Name for the service plan for the Windows web app."
  type        = string
  default     = "ASP-rgnetworking-81f2"
}

variable "serverfarms_ASP_rgnetworking_b8b4_name" {
  description = "Name for the service plan for the Linux function app."
  type        = string
  default     = "ASP-rgnetworking-b8b4"
}

variable "privateEndpoints_pe_noorshield_name" {
  description = "Name for the private endpoint for noorshield (web app)."
  type        = string
  default     = "pe-noorshield"
}

variable "privateEndpoints_pe_openai_east_name" {
  description = "Name for the private endpoint for Cognitive (OpenAI) account."
  type        = string
  default     = "pe-openai-east"
}

variable "searchServices_aisrch_noorsheild_name" {
  description = "Name for the Search service."
  type        = string
  default     = "aisrch-noorsheild"
}

variable "storageAccounts_rgnetworking9b4d_name" {
  description = "Name for one storage account."
  type        = string
  default     = "rgnetworking9b4d"
}

variable "storageAccounts_rgnetworkingb244_name" {
  description = "Name for the second storage account."
  type        = string
  default     = "rgnetworkingb244"
}

variable "networkSecurityGroups_nsg_subnet_ai_name" {
  description = "Name for the NSG for the AI subnet."
  type        = string
  default     = "nsg-subnet-ai"
}

variable "networkSecurityGroups_nsg_subnet_services_name" {
  description = "Name for the NSG for the services subnet."
  type        = string
  default     = "nsg-subnet-services"
}

variable "privateDnsZones_privatelink_openai_azure_com_name" {
  description = "Name for the private DNS zone for openai."
  type        = string
  default     = "privatelink.openai.azure.com"
}

variable "privateDnsZones_privatelink_azurewebsites_net_name" {
  description = "Name for the private DNS zone for azurewebsites."
  type        = string
  default     = "privatelink.azurewebsites.net"
}

variable "privateDnsZones_privatelink_search_windows_net_name" {
  description = "Name for the private DNS zone for search."
  type        = string
  default     = "privatelink.search.windows.net"
}

variable "privateDnsZones_privatelink_vaultcore_azure_net_name" {
  description = "Name for the private DNS zone for vaultcore."
  type        = string
  default     = "privatelink.vaultcore.azure.net"
}

variable "privateDnsZones_privatelink_blob_core_windows_net_name" {
  description = "Name for the private DNS zone for blob."
  type        = string
  default     = "privatelink.blob.core.windows.net"
}

variable "privateDnsZones_privatelink_table_core_windows_net_name" {
  description = "Name for the private DNS zone for table."
  type        = string
  default     = "privatelink.table.core.windows.net"
}

variable "workspaces_DefaultWorkspace_3e169b7b_edb6_4452_94b0_847f2917971a_NEU_externalid" {
  description = "Resource ID of the Log Analytics workspace."
  type        = string
  default     = ""  # supply your workspace resource ID here
}

*/